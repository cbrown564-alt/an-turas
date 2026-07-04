import CoreHaptics
import UIKit

// MARK: - The chisel: one haptic vocabulary for the whole app.
// Every physical event speaks stone-carving: the chisel strike (correct answer),
// the faint tick of a stroke appearing, the finishing flourish, the dull knock
// of a mis-strike. CoreHaptics where available, UIKit generators as fallback.

enum Haptics {
    private static var engine: CHHapticEngine?
    private static var engineReady = false

    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private static let notify = UINotificationFeedbackGenerator()

    static func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        guard engine == nil else { return }
        do {
            let e = try CHHapticEngine()
            e.resetHandler = {
                try? e.start()
            }
            e.stoppedHandler = { _ in engineReady = false }
            try e.start()
            engine = e
            engineReady = true
        } catch {
            engine = nil
        }
        lightImpact.prepare()
        rigidImpact.prepare()
    }

    /// A single chisel strike with a faint stone echo — a correct answer carves.
    static func chisel() {
        play(events: [
            transient(at: 0, intensity: 1.0, sharpness: 0.9),
            transient(at: 0.06, intensity: 0.35, sharpness: 0.55),
        ], fallback: { rigidImpact.impactOccurred() })
    }

    /// Faint tick — one ogham stroke appears while an inscription carves itself.
    static func tick() {
        play(events: [
            transient(at: 0, intensity: 0.4, sharpness: 0.85),
        ], fallback: { lightImpact.impactOccurred(intensity: 0.55) })
    }

    /// tap-tap-TAP — the carver finishing a piece. Session complete.
    static func flourish() {
        play(events: [
            transient(at: 0, intensity: 0.55, sharpness: 0.85),
            transient(at: 0.12, intensity: 0.75, sharpness: 0.9),
            transient(at: 0.27, intensity: 1.0, sharpness: 0.95),
        ], fallback: { notify.notificationOccurred(.success) })
    }

    /// Dull double knock — the chisel skips. Wrong answer.
    static func error() {
        play(events: [
            transient(at: 0, intensity: 0.6, sharpness: 0.2),
            transient(at: 0.09, intensity: 0.45, sharpness: 0.15),
        ], fallback: { notify.notificationOccurred(.error) })
    }

    /// Light touch — picking up or placing a tile, advancing the story.
    static func tap() {
        lightImpact.impactOccurred(intensity: 0.7)
    }

    // MARK: - Internals

    private static func transient(at time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: time)
    }

    private static func play(events: [CHHapticEvent], fallback: () -> Void) {
        prepare()
        guard engineReady, let engine else { fallback(); return }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            fallback()
        }
    }
}
