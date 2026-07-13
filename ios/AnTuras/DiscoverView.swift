import SwiftUI

// MARK: - Faigh amach: rules learned by discovery (the Brilliant model; DRILL.md)
// Reveal, reveal, then withhold. The learner watches worked cases land one at a
// time, forms the hypothesis themselves, produces the next case before the rule
// is named — and only then does the rule carve in, as *their* finding. The
// opposite of a note that states the law up front. Best home for Irish's
// classification rules (broad/slender, Mac/Nic), which have no fillable frame.

struct DiscoverView: View {
    let block: DiscoverBlock
    let onSolved: () -> Void

    /// How many steps the learner has worked through — shown cases plus any
    /// produce step they have answered. Steps below this stay settled on the page.
    @State private var revealed = 0
    @State private var text = ""
    @State private var shakeCount = 0
    @State private var verdict: String?
    @State private var done = false
    @FocusState private var focused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var current: DiscoverStep? {
        guard revealed < block.steps.count else { return nil }
        return block.steps[revealed]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if let context = block.context {
                Text(context)
                    .font(.system(size: 16, design: .serif))
                    .italic()
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(4)
                    .padding(.bottom, 2)
            }

            // Worked cases already read stay on the page — the evidence the
            // learner is reasoning from doesn't scroll away.
            ForEach(0..<revealed, id: \.self) { i in
                settledStep(block.steps[i])
            }

            if let step = current {
                if step.show != nil {
                    activeShow(step)
                } else if step.prompt != nil {
                    produce(step)
                }
            }

            if done {
                theRule
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            HStack(spacing: 3.5) {
                ForEach(0..<3, id: \.self) { _ in
                    TickMark(variant: 2)
                        .stroke(Theme.lichen.opacity(0.75),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .frame(width: 8, height: 14)
                }
            }
            EditorialContextLabel(text: "Faigh amach · discover", color: Theme.inkFaint)
        }
        .padding(.bottom, 2)
    }

    // MARK: Steps

    /// A freshly revealed worked case, with the affordance to take in the next.
    /// After the last show step it hands straight over to the produce step.
    private func activeShow(_ step: DiscoverStep) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            workedCase(step.show ?? "")
                .transition(.offset(y: 8).combined(with: .opacity))
            Button {
                Haptics.tap()
                withAnimation(Motion.settle) {
                    revealed += 1
                    verdict = nil
                }
            } label: {
                HStack(spacing: 8) {
                    Text(nextIsProduce ? "Tuigim — I see it" : "Lean ort — go on")
                    Image(systemName: "arrow.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.inkSoft)
                .padding(.vertical, 9)
                .padding(.horizontal, 15)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
            }
            .buttonStyle(CarvePress())
        }
    }

    /// The withheld case: the learner produces it before the rule is named.
    private func produce(_ step: DiscoverStep) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            GlossText(markdown: step.prompt ?? "", glosses: [], activeGloss: .constant(nil),
                      font: .system(size: 17, design: .serif), lineSpacing: 4)
                .foregroundStyle(Theme.ink)
            HStack(spacing: 8) {
                TextField("Do fhreagra…", text: $text)
                    .font(.system(size: 17, design: .serif))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($focused)
                    .onSubmit { grade(step) }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Theme.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(focused ? Theme.lichen.opacity(0.6) : Theme.line, lineWidth: 1))
                Button("Seiceáil") { grade(step) }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.bg)
                    .padding(.vertical, 13)
                    .padding(.horizontal, 16)
                    .background(Theme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .buttonStyle(CarvePress())
            }
            .shake(shakeCount)
            if answerHasFada {
                FadaKeyRow(text: $text)
            }
            if let verdict {
                Text(verdict)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.rust)
                    .lineSpacing(3)
                    .transition(.offset(y: 6).combined(with: .opacity))
            }
        }
    }

    /// A step the learner has already worked, left settled on the page as evidence.
    @ViewBuilder
    private func settledStep(_ step: DiscoverStep) -> some View {
        if let show = step.show {
            workedCase(show)
        } else if let prompt = step.prompt {
            VStack(alignment: .leading, spacing: 4) {
                GlossText(markdown: prompt, glosses: [], activeGloss: .constant(nil),
                          font: .system(size: 15, design: .serif), lineSpacing: 4)
                    .foregroundStyle(Theme.inkSoft)
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                    Text(step.answer ?? text)
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                }
                .foregroundStyle(Theme.moss)
            }
            .padding(.leading, 15)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Theme.moss.opacity(0.6))
                    .frame(width: 3)
                    .padding(.vertical, 3)
            }
            .padding(.vertical, 2)
        }
    }

    /// One shown transformation ("Dáire — the r sits between i and e…"), carved
    /// against a lichen groove like a specimen in a note.
    private func workedCase(_ markdown: String) -> some View {
        GlossText(markdown: markdown, glosses: [], activeGloss: .constant(nil),
                  font: .system(size: 18, design: .serif), lineSpacing: 4)
            .foregroundStyle(Theme.ink)
            .padding(.leading, 15)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Theme.lichen.opacity(0.55))
                    .frame(width: 2)
                    .padding(.vertical, 2)
            }
            .padding(.vertical, 2)
    }

    /// The payoff: the rule the learner just produced, named at last — as theirs.
    private var theRule: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "An riail a d'aimsigh tú · the rule you found", color: Theme.moss)
            Text(block.teach)
                .font(.system(size: 17, weight: .medium, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineSpacing(5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.mossTint)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.moss.opacity(0.45), lineWidth: 1))
        .transition(.offset(y: 10).combined(with: .opacity))
        .padding(.top, 2)
    }

    // MARK: Logic

    /// True when advancing past the current show step lands on the produce step —
    /// so the "go on" affordance can change its tone from browsing to committing.
    private var nextIsProduce: Bool {
        let next = revealed + 1
        return next < block.steps.count && block.steps[next].prompt != nil
    }

    private var answerHasFada: Bool {
        (current?.answer ?? "").contains { "áéíóúÁÉÍÓÚ".contains($0) }
    }

    private func grade(_ step: DiscoverStep) {
        let value = text.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        guard !value.isEmpty, let answer = step.answer else { return }

        // Grade the taught variable, not typing trivia: case- and fada-insensitive,
        // so grasping the rule counts even if a length mark slips.
        if Self.normalise(value) == Self.normalise(answer) {
            Haptics.chisel()
            focused = false
            withAnimation(Motion.pop) {
                revealed += 1
                verdict = nil
                text = ""
                done = revealed == block.steps.count
            }
            if done { onSolved() }
        } else {
            Haptics.error()
            shakeCount += 1
            withAnimation(Motion.settle) {
                verdict = "Not yet — read the worked cases again and let them decide it for you."
            }
        }
    }

    private static func normalise(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: "á", with: "a")
            .replacingOccurrences(of: "é", with: "e")
            .replacingOccurrences(of: "í", with: "i")
            .replacingOccurrences(of: "ó", with: "o")
            .replacingOccurrences(of: "ú", with: "u")
    }
}
