import SwiftUI

// The opening moment: the stone carves itself, then the words settle in after it,
// the way dust settles after the chisel.

struct CoverView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onBegin: () -> Void

    @State private var appeared = false

    /// A learner with strokes behind them is greeted as a returner, not a
    /// stranger — the cover is the first breath of the retention loop.
    private var returning: Bool { state.done.contains(true) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    Spacer()
                    OghamStoneView(word: "failte", width: 132, carve: true)
                        .opacity(appeared ? 1 : 0)
                    Spacer()
                }
                .padding(.top, 24)

                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "An Turas · Caibidil a hAon")
                    Text(state.chapter.title)
                        .font(.system(size: 34, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text(state.chapter.subtitle)
                        .font(.system(size: 17, design: .serif))
                        .foregroundStyle(Theme.inkSoft)
                }
                .cascade(1, appeared: appeared, reduceMotion: reduceMotion)

                Text("Before Ireland wrote on vellum, she wrote on stone — names, carved in strokes along an edge, meant to outlast the people who spoke them. In this chapter you learn Irish the way it first survived: one name at a time. Five short sessions. Every correct answer carves a stroke.")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(4)
                    .cascade(2, appeared: appeared, reduceMotion: reduceMotion)

                if returning {
                    Text(state.allDone
                         ? "Tá tú ar ais — agus tá do chloch ag fanacht sa mhúsaem."
                         : "Tá tú ar ais — you're back. Dáire is at the stone already; he kept your place.")
                        .font(.system(size: 15, design: .serif))
                        .italic()
                        .foregroundStyle(Theme.ink)
                        .lineSpacing(4)
                        .cascade(2, appeared: appeared, reduceMotion: reduceMotion)
                }

                Button {
                    Haptics.tap()
                    onBegin()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(returning ? "Lean ort — continue" : "Tosaigh an turas")
                            .font(.system(size: 17, weight: .semibold))
                        Text(returning
                             ? "Back to the path · your strokes are safe"
                             : "Begin the journey · 5 sessions · ~10 min each")
                            .font(.system(size: 11))
                            .opacity(0.75)
                    }
                    .foregroundStyle(Theme.bg)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(CarvePress())
                .cascade(3, appeared: appeared, reduceMotion: reduceMotion)

                Text("Prototype for playtesting. Draft content awaiting native-speaker review. Draft TTS: Gemini 3.1 Flash (Azure ga-IE follow-up).")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.top, 12)
                    .overlay(Rectangle().fill(Theme.line).frame(height: 1), alignment: .top)
                    .cascade(4, appeared: appeared, reduceMotion: reduceMotion)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 48)
            .frame(maxWidth: 640)
        }
        .onAppear {
            guard !appeared else { return }
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.easeOut(duration: 0.4)) { appeared = true }
            }
        }
    }
}

private extension View {
    /// Staggered entrance: each element rises in a beat after the one before.
    @ViewBuilder
    func cascade(_ order: Int, appeared: Bool, reduceMotion: Bool) -> some View {
        if reduceMotion {
            opacity(appeared ? 1 : 0)
        } else {
            self
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(Motion.rise.delay(0.35 + Double(order) * 0.12), value: appeared)
        }
    }
}
