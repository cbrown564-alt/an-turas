import SwiftUI

// MARK: - An logainm — the placename lens.
// An anglicized townland name is chalk: flat sans, sound without story.
// Tap it and it peels back to the Irish carved underneath — serif, groove,
// sayable — then the morphemes step out one by one with their meanings.
// Tap again to lay the English spelling back over it; the peel is
// reversible because the point is that both are the same word.

struct LensView: View {
    let block: LensBlock
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false

    var body: some View {
        VStack(spacing: 20) {
            EditorialContextLabel(text: "Logainm · placename", color: Theme.lichen)

            Button {
                Haptics.tap()
                withAnimation(reduceMotion ? .easeOut(duration: 0.2) : Motion.settle) {
                    revealed.toggle()
                }
            } label: {
                VStack(spacing: 10) {
                    if revealed {
                        Text(block.ga)
                            .font(.system(size: 36, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Theme.stone)
                                    .frame(width: 3)
                            }
                            .transition(.opacity.combined(with: .offset(y: 6)))
                    } else {
                        Text(block.en)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .overlay(alignment: .bottom) {
                                // Chalk underline: the dashes invite the peel.
                                DashLine()
                                    .stroke(Theme.stone,
                                            style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                                    .frame(height: 1.5)
                            }
                            .transition(.opacity.combined(with: .offset(y: -6)))
                    }
                    Text(revealed
                         ? "an English spelling was laid over this — tap to see it again"
                         : "an Irish poem is hiding in this spelling — tap to peel it back")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.inkFaint)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(CarvePress())
            .accessibilityLabel(revealed
                ? "\(block.ga). Tap to show the English spelling \(block.en)."
                : "\(block.en). Tap to reveal the Irish form.")

            if revealed {
                SoundRow(text: block.ga, hint: nil, label: "éist — hear it whole")

                VStack(alignment: .leading, spacing: 9) {
                    ForEach(Array(block.parts.enumerated()), id: \.element.id) { index, part in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(part.ga)
                                .font(.system(size: 18, weight: .semibold, design: .serif))
                                .foregroundStyle(Theme.moss)
                            Text("— \(part.en)")
                                .font(.system(size: 14.5))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        .modifier(RiseIn(order: index + 1, reduceMotion: reduceMotion))
                    }
                }
                .padding(.leading, 14)
                .padding(.vertical, 4)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Theme.lichen.opacity(0.55))
                        .frame(width: 2)
                }

                Text("“\(block.meaning)”")
                    .font(.system(size: 17, design: .serif))
                    .italic()
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .modifier(RiseIn(order: block.parts.count + 1, reduceMotion: reduceMotion))

                if let note = block.note {
                    Text(note)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkFaint)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .frame(maxWidth: 340)
                        .modifier(RiseIn(order: block.parts.count + 2, reduceMotion: reduceMotion))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DashLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}
