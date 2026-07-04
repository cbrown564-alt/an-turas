import SwiftUI

// MARK: - Athsnoí: the path back.
// Sessions 2–5 open here. Phrases the learner carved in earlier sessions
// stand weathered — vowels erode first, the way the small notches on a real
// stemline go first — and re-typing the whole phrase, fadas and all,
// restores the groove. Review as returning to a place, never as card debt
// (SPINE rule 6). This page is also the return acknowledgment: tá tú ar ais.

struct RecarveView: View {
    let block: RecarveBlock
    let onSolved: () -> Void

    @State private var restored: [RecarveItem] = []
    @State private var text = ""
    @State private var shakeCount = 0
    @State private var verdict: String?
    @State private var allDone = false
    @FocusState private var focused: Bool

    private var current: RecarveItem? {
        guard restored.count < block.items.count else { return nil }
        return block.items[restored.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                HStack(spacing: 3.5) {
                    ForEach(0..<3, id: \.self) { _ in
                        TickMark(variant: 2)
                            .stroke(Theme.lichen.opacity(0.75),
                                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .frame(width: 8, height: 14)
                    }
                }
                Eyebrow(text: "Tá tú ar ais · athsnoí", color: Theme.inkFaint)
            }
            .padding(.bottom, 2)

            if let intro = block.intro {
                Text(intro)
                    .font(.system(size: 16, design: .serif))
                    .italic()
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(4)
                    .padding(.bottom, 4)
            }

            // Already-restored phrases stay on the page, carved deep again.
            ForEach(restored) { item in
                restoredRow(item)
            }

            if let item = current {
                weatheredStone(item)
                entryRow(item)
                FadaKeyRow(text: $text, disabled: allDone)
                if let verdict {
                    Text(verdict)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.rust)
                        .lineSpacing(3)
                        .transition(.offset(y: 6).combined(with: .opacity))
                }
            }

            if allDone {
                Verdict(ok: true,
                        headline: "Athsnoite — restored.",
                        detail: "The groove is deeper for the re-cutting. That's how remembering works here.")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Rows

    private func restoredRow(_ item: RecarveItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.answer)
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            Text("— \(item.en)")
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(.leading, 17)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Theme.moss.opacity(0.6))
                .frame(width: 3)
                .padding(.vertical, 3)
        }
        .padding(.vertical, 4)
        .transition(.opacity)
    }

    private func weatheredStone(_ item: RecarveItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Self.weathered(item.answer))
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .kerning(1.5)
                .foregroundStyle(Theme.stone)
            Text("— \(item.en)\(item.from.map { "  ·  \($0)" } ?? "")")
                .font(.system(size: 13))
                .italic()
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.leading, 17)
        // The groove has silted: the bar is stone, not ink.
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Theme.stone.opacity(0.55))
                .frame(width: 3)
                .padding(.vertical, 3)
        }
        .padding(.vertical, 4)
        .accessibilityLabel("Weathered phrase meaning: \(item.en)")
    }

    private func entryRow(_ item: RecarveItem) -> some View {
        HStack(spacing: 8) {
            TextField("Cut it fresh…", text: $text)
                .font(.system(size: 17, design: .serif))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($focused)
                .onSubmit { grade(item) }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(focused ? Theme.moss.opacity(0.6) : Theme.line, lineWidth: 1))
            Button("Snoigh") { grade(item) }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.bg)
                .padding(.vertical, 13)
                .padding(.horizontal, 16)
                .background(Theme.ink)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .buttonStyle(CarvePress())
        }
        .shake(shakeCount)
    }

    // MARK: Grading

    private func grade(_ item: RecarveItem) {
        let value = text.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        guard !value.isEmpty else { return }

        if value.lowercased() == item.answer.lowercased() {
            Haptics.chisel()
            withAnimation(Motion.pop) {
                restored.append(item)
                text = ""
                verdict = nil
                if restored.count == block.items.count {
                    allDone = true
                    focused = false
                }
            }
            if allDone { onSolved() }
        } else {
            Haptics.error()
            shakeCount += 1
            withAnimation(Motion.settle) {
                verdict = Self.strippedFadas(value) == Self.strippedFadas(item.answer)
                    ? "The letters are right — the fadas eroded first. Put them back with the keys below."
                    : "Not quite — read what's left of the strokes, and the meaning underneath."
            }
        }
    }

    /// Vowels — the small notches — weather away first.
    static func weathered(_ phrase: String) -> String {
        String(phrase.map { "aeiouáéíóúAEIOUÁÉÍÓÚ".contains($0) ? "·" : $0 })
    }

    private static func strippedFadas(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: "á", with: "a")
            .replacingOccurrences(of: "é", with: "e")
            .replacingOccurrences(of: "í", with: "i")
            .replacingOccurrences(of: "ó", with: "o")
            .replacingOccurrences(of: "ú", with: "u")
    }
}
