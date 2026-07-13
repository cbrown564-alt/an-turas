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

                EditorialScreenHeader(
                    context: "An Turas · 32 contae",
                    title: state.chapter.title,
                    detail: state.chapter.subtitle
                )
                .cascade(1, appeared: appeared, reduceMotion: reduceMotion)

                Text("Take a trip around all 32 counties of Ireland. At every stop, a real person, myth or monument opens the door to a place and time that matter. You will read its story, learn 20 useful Irish words, and carry them on to the next county.")
                    .font(.body)
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(4)
                    .cascade(2, appeared: appeared, reduceMotion: reduceMotion)

                if returning {
                    Text(state.allDone
                         ? "Tá tú ar ais — agus tá do chloch ag fanacht sa mhúsaem."
                         : "Tá tú ar ais — you're back. Dáire is at the stone already; he kept your place.")
                        .font(.system(.body, design: .serif))
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
                            .font(.headline)
                        Text(returning
                             ? "Back to the path · your strokes are safe"
                             : "Begin in Mayo · 20 words · 5 short sessions")
                            .font(.caption)
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

                Text("Irish Cultural Guide audio · Generated Irish clips await language review · Your progress stays on this device.")
                    .font(.caption)
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
