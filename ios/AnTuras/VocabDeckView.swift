import SwiftUI

// MARK: - Na Focail: vocabulary at volume (DRILL.md §1)
// Due earned lexemes assembled into a retrieval deck — match, listen, or
// type-in, recall-first. Optional-but-invited: a peer of Ar Ais and Na
// Patrúin on the hub, and an offer at session close when fresh phrases from
// the yard are ready. Coverage, not points.

struct VocabDeckView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    /// Frozen on arrival so cards don't vanish mid-run as the scheduler moves
    /// them into the future.
    @State private var queue: [LexemeDeckItem] = []
    @State private var index = 0
    @State private var solvedCount = 0
    @State private var appeared = false
    @State private var done = false

    private var lexicon: [Lexeme] {
        ContentLoader.lexicon(throughChapter: state.activeChapterN)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                    .padding(.top, 12)

                if queue.isEmpty {
                    emptyState
                } else if done {
                    closeCard
                        .transition(.offset(y: 10).combined(with: .opacity))
                } else if index < queue.count {
                    CarveBarView(total: queue.count, done: solvedCount)
                        .frame(height: 20)
                        .padding(.vertical, 2)

                    cardView(queue[index])
                        .id(queue[index].id)
                        .cascade(0, appeared: appeared, reduceMotion: reduceMotion)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 48)
            .frame(maxWidth: 640)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if queue.isEmpty {
                let due = state.dueLexemes()
                queue = LexemeDeck.items(due: due, in: lexicon)
            }
            guard !appeared else { return }
            if reduceMotion { appeared = true }
            else { withAnimation(.easeOut(duration: 0.4)) { appeared = true } }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Cleachtadh · na focail", color: Theme.lichen)
            Text(headline)
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            Text(subline)
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(4)
        }
    }

    private var headline: String {
        if queue.isEmpty { return "Níl frása ar bith fós" }
        if done { return "Snoite arís" }
        return "Na focail ón gcosán"
    }

    private var subline: String {
        if queue.isEmpty {
            return "Walk the path a little further. When a session earns phrases, they land here for a quick return — never a gate, always an offer."
        }
        if done {
            return "Every phrase you produced sits deeper than it did. That's the only score here."
        }
        return "Phrases the story already earned — recall them before the wind works on the grooves."
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let next = state.nextLexemeReturn() {
                Text("Fillfidh \(next.lexeme.ga) \(Turas.until(next.due)) — \(next.lexeme.en) will be ready to revisit \(untilEn(next.due)).")
                    .font(.system(size: 15, design: .serif))
                    .italic()
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(4)
            } else {
                Text("Finish a session and its phrases will offer themselves here — a quick return to the yard, never a debt.")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.sunk.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: Cards

    @ViewBuilder
    private func cardView(_ item: LexemeDeckItem) -> some View {
        switch item {
        case .typein(_, let block):
            TypeInView(block: block, onSolved: { finish(item, struggled: $0) })
        case .listen(_, let block):
            ListenView(block: block, onSolved: { finish(item, struggled: $0) })
        case .match(_, let block):
            MatchView(block: block, onSolved: { finish(item, struggled: $0) })
        }
    }

    private func finish(_ item: LexemeDeckItem, struggled: Bool) {
        for id in item.lexemeIds {
            if let lexeme = lexicon.first(where: { $0.id == id }) {
                state.completeLexeme(lexeme, struggled: struggled)
            }
        }
        solvedCount += 1
        let isLast = index + 1 >= queue.count
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(Motion.pop) {
                if isLast {
                    done = true
                    Haptics.flourish()
                } else {
                    index += 1
                }
            }
        }
    }

    // MARK: Close

    private var closeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: "Clúdach · coverage", color: Theme.lichen)
            Text("Rinne tú \(queue.count) frása ar ais.")
                .font(.system(size: 19, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            Text("How much of the lexicon you can produce — not points, not streaks. That's the honest signal.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(4)

            let produced = state.producedLexemes(inChapter: state.activeChapterN)
            let total = ContentLoader.lexicon(forChapter: state.activeChapterN)
                .filter { state.hasEarned($0.earnedAt) }.count
            if total > 0 {
                Text("\(produced) de \(total) focal as Caibidil \(state.activeChapterN) — produced at least once.")
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.top, 2)
            }

            FlowLayout(spacing: 8) {
                ForEach(coveredLexemes) { lexeme in
                    Text(lexeme.ga)
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(Theme.ink)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 12)
                        .background(Theme.raised)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.lichen.opacity(0.4), lineWidth: 1))
                }
            }

            PrimaryButton(title: "Ar ais →", fullWidth: true) {
                Haptics.tap()
                dismiss()
            }
            .padding(.top, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.lichen.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.lichen.opacity(0.35), lineWidth: 1))
    }

    private var coveredLexemes: [Lexeme] {
        queue.flatMap { item -> [Lexeme] in
            switch item {
            case .typein(let lexeme, _), .listen(let lexeme, _):
                return [lexeme]
            case .match(let lexemes, _):
                return lexemes
            }
        }
    }

    private func untilEn(_ due: Date) -> String {
        let days = Int(ceil(due.timeIntervalSince(Date()) / 86400))
        switch days {
        case ..<1: return "later today"
        case 1: return "tomorrow"
        default: return "in \(days) days"
        }
    }
}

private extension View {
    @ViewBuilder
    func cascade(_ order: Int, appeared: Bool, reduceMotion: Bool) -> some View {
        if reduceMotion {
            opacity(appeared ? 1 : 0)
        } else {
            self
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(Motion.rise.delay(0.1 + Double(order) * 0.08), value: appeared)
        }
    }
}
