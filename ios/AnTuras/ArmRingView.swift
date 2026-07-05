import SwiftUI
import UIKit

// MARK: - Viking hack-silver arm-ring
// An open silver ring with bossed terminals — cut by weight, not gift.
// Sigur marks the deal with a tiny notch bearing the trader's name.
// Hand mode: drag along the left terminal to cut the notch; each tick is
// the shears biting silver. Reduce Motion finishes on arrival.

struct ArmRingView: View {
    let name: String
    var width: CGFloat = 220
    var carve = false
    var ticks = false
    var handCarve = false
    var onCarved: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start: Date?
    @State private var carveDone = false
    @State private var autoTicked = 0
    /// Hand mode: how far the notch has been cut, 0…1.
    @State private var notchProgress: CGFloat = 0
    @State private var handTicked = 0
    @State private var handDone = false

    private let height: CGFloat = 130
    private let notchLeadIn = 0.4
    private let notchDuration = 0.55

    private var animating: Bool { carve && !reduceMotion && !carveDone }

    private var displayProgress: CGFloat {
        if handCarve && !reduceMotion { return notchProgress }
        if !carve && !handCarve { return 1 }
        if carveDone || !animating { return 1 }
        return 0
    }

    var body: some View {
        Group {
            if handCarve && !reduceMotion {
                ringCanvas(progress: notchProgress, showGuide: notchProgress < 1)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Cut inward along the left terminal — shears
                                // travel from the boss toward the ring body.
                                let origin = CGPoint(x: width * 0.18, y: height * 0.72)
                                let dx = value.location.x - origin.x
                                let dy = origin.y - value.location.y
                                let reach = min(max((dx + dy * 0.35) / (width * 0.22), 0), 1)
                                if reach > notchProgress {
                                    notchProgress = reach
                                    handProgressed()
                                }
                            })
            } else {
                TimelineView(.animation(minimumInterval: 1 / 40, paused: !animating)) { timeline in
                    let elapsed = elapsedTime(at: timeline.date)
                    let progress = notchProgress(at: elapsed)
                    ringCanvas(progress: progress, showGuide: progress < 1)
                        .onChange(of: progress) { _, p in
                            guard animating else { return }
                            let ticksTotal = 6
                            let started = Int(p * CGFloat(ticksTotal))
                            if ticks, started > autoTicked, started < ticksTotal {
                                autoTicked = started
                                Haptics.tick()
                            }
                            if p >= 1, !carveDone {
                                carveDone = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    onCarved?()
                                }
                            }
                        }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if displayProgress >= 0.85, !name.isEmpty {
                Text(name)
                    .font(.system(size: min(14, width * 0.065), weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink.opacity(0.85))
                    .offset(y: 18)
                    .opacity(Double(min((displayProgress - 0.85) / 0.15, 1)))
            }
        }
        .frame(width: width, height: height + 28)
        .onAppear {
            if start == nil { start = Date() }
            if handCarve, reduceMotion, !handDone {
                notchProgress = 1
                handDone = true
                onCarved?()
            }
        }
        .accessibilityLabel("Hack-silver arm-ring marked for \(name)")
    }

    private func handProgressed() {
        let ticksTotal = 6
        let started = Int(notchProgress * CGFloat(ticksTotal))
        if started > handTicked {
            handTicked = started
            if ticks { Haptics.tick() }
        }
        if notchProgress >= 1, !handDone {
            handDone = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                onCarved?()
            }
        }
    }

    private func elapsedTime(at date: Date) -> Double {
        guard animating, let start else { return .greatestFiniteMagnitude }
        return date.timeIntervalSince(start)
    }

    private func notchProgress(at elapsed: Double) -> CGFloat {
        guard elapsed < .greatestFiniteMagnitude else { return 1 }
        guard elapsed > notchLeadIn else { return 0 }
        return min(max(CGFloat((elapsed - notchLeadIn) / notchDuration), 0), 1)
    }

    private func ringCanvas(progress: CGFloat, showGuide: Bool) -> some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height - 28) / 220
            ctx.translateBy(x: (size.width - 220 * s) / 2, y: 8 * s)
            ctx.scaleBy(x: s, y: s)

            let cx: CGFloat = 110
            let cy: CGFloat = 78
            let radius: CGFloat = 52
            let band: CGFloat = 7

            // Subtle shadow beneath the silver.
            var shadow = Path()
            shadow.addArc(center: CGPoint(x: cx, y: cy + 3), radius: radius,
                          startAngle: .degrees(200), endAngle: .degrees(-20), clockwise: false)
            ctx.stroke(shadow, with: .color(Theme.inkFaint.opacity(0.18)),
                       style: StrokeStyle(lineWidth: band + 4, lineCap: .round))

            // The open ring — hack-silver: cut from a larger arm-ring.
            var ring = Path()
            ring.addArc(center: CGPoint(x: cx, y: cy), radius: radius,
                        startAngle: .degrees(200), endAngle: .degrees(-20), clockwise: false)
            ctx.stroke(ring,
                       with: .linearGradient(
                        Gradient(colors: [
                            Color(light: 0xD8DADF, dark: 0x8A9098),
                            Color(light: 0xF4F5F7, dark: 0xB8BEC6),
                            Color(light: 0xC4C8CE, dark: 0x7A8088),
                        ]),
                        startPoint: CGPoint(x: cx - radius, y: cy - radius),
                        endPoint: CGPoint(x: cx + radius, y: cy + radius)),
                       style: StrokeStyle(lineWidth: band, lineCap: .round))

            // Bossed terminals — the weights Sigur sets on the scales.
            drawTerminal(ctx: &ctx, at: terminalPoint(angle: 200, cx: cx, cy: cy, r: radius), progress: 1)
            drawTerminal(ctx: &ctx, at: terminalPoint(angle: -20, cx: cx, cy: cy, r: radius), progress: 1)

            // Notch on the left terminal — the deal-mark.
            let notchBase = terminalPoint(angle: 200, cx: cx, cy: cy, r: radius - 2)
            if showGuide, progress < 1 {
                var guide = Path()
                guide.move(to: notchBase)
                guide.addLine(to: CGPoint(x: notchBase.x + 18, y: notchBase.y - 10))
                ctx.stroke(guide, with: .color(Theme.ink.opacity(0.16)),
                           style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [3, 4]))
            }
            if progress > 0 {
                var notch = Path()
                let tip = CGPoint(x: notchBase.x + 18 * progress, y: notchBase.y - 10 * progress)
                notch.move(to: notchBase)
                notch.addLine(to: tip)
                notch.addLine(to: CGPoint(x: notchBase.x + 6 * progress, y: notchBase.y - 4 * progress))
                notch.closeSubpath()
                ctx.fill(notch, with: .color(Theme.sunk))
                ctx.stroke(notch, with: .color(Theme.ink.opacity(0.45 + 0.4 * Double(progress))),
                           style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
        }
    }

    private func terminalPoint(angle: Double, cx: CGFloat, cy: CGFloat, r: CGFloat) -> CGPoint {
        let rad = angle * .pi / 180
        return CGPoint(x: cx + r * cos(rad), y: cy + r * sin(rad))
    }

    private func drawTerminal(ctx: inout GraphicsContext, at point: CGPoint, progress: CGFloat) {
        let rect = CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)
        ctx.fill(Path(ellipseIn: rect),
                 with: .radialGradient(
                    Gradient(colors: [
                        Color(light: 0xECEEF1, dark: 0xA8AEB6),
                        Color(light: 0xB0B5BC, dark: 0x6E747C),
                    ]),
                    center: point, startRadius: 0, endRadius: 6))
        ctx.stroke(Path(ellipseIn: rect), with: .color(Theme.inkFaint.opacity(0.5)), lineWidth: 1)
        _ = progress // reserved for future terminal animation
    }
}
