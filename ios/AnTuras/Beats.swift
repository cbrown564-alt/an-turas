import SwiftUI

// MARK: - Shared beat furniture
// Speech beats appear in scene pages, echo pages and dialogue turns, so they
// live here rather than inside any one page's file.

/// Slugline — where and when, set the way a carver would chalk a label:
/// small, spaced, with a short rule underneath.
struct Slugline: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(text.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .kerning(1.8)
                .foregroundStyle(Theme.inkFaint)
                .lineSpacing(4)
            Rectangle()
                .fill(Theme.stone)
                .frame(width: 44, height: 1.5)
        }
    }
}

/// A line of spoken Irish — the reason the learner is here, so it gets the
/// display type. Tap the line for its meaning; tap the sound row underneath
/// to hear it. When the device has no Irish voice the sound row stays a
/// plain pronunciation hint, exactly as before.
struct SpeechBeatView: View {
    let beat: SpeechBeat
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let who = beat.who {
                Text(who.uppercased())
                    .font(.system(size: 10.5, weight: .semibold))
                    .kerning(1.5)
                    .foregroundStyle(Theme.inkFaint)
            }
            Button {
                Haptics.tap()
                onTap()
            } label: {
                (Text("“")
                 + Text(beat.s).underline(true, pattern: .dot, color: Theme.moss.opacity(0.45))
                 + Text("”"))
                    .font(.system(size: 25, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(5)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(CarvePress())
            .accessibilityLabel("\(beat.who ?? "Spoken"): \(beat.s)")
            .accessibilityHint("Shows the meaning")
            SoundRow(text: beat.s, hint: beat.ph)
        }
        .padding(.leading, 17)
        // The carved groove sizes to the words, like a stroke to its letter.
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Theme.stone)
                .frame(width: 3)
                .padding(.vertical, 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

/// The sound row under a spoken line: the rough respelling, and — when the
/// device can speak Irish — the ear that says it aloud.
struct SoundRow: View {
    let text: String
    let hint: String?
    var label: String?

    @ObservedObject private var speech = SpeechService.shared

    var body: some View {
        if speech.canSpeak(text) {
            Button {
                Haptics.tap()
                speech.speak(text)
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: speech.isSpeaking(text)
                          ? "speaker.wave.2.fill" : "speaker.wave.2")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.moss)
                        .contentTransition(.symbolEffect(.replace))
                    Text(label ?? hint ?? "éist")
                        .font(.system(size: 12.5, weight: .medium))
                        .kerning(0.4)
                        .foregroundStyle(Theme.inkFaint)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(CarvePress())
            .accessibilityLabel("Listen: \(text)")
        } else if let hint {
            Text(hint)
                .font(.system(size: 12.5, weight: .medium))
                .kerning(0.4)
                .foregroundStyle(Theme.inkFaint)
        }
    }
}
