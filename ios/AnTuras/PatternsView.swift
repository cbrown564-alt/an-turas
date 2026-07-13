import SwiftUI

// MARK: - Na Patrúin: grammar at volume (DRILL.md §2)
// The story teaches a rule once, in a nóta, then a scene lets you use it. This
// surface lets you *run* it — one earned pattern cast through every word you've
// earned, until the frame is a groove your hand knows. Optional-but-invited: a
// peer of Ar Ais and the museum on the hub, never a gate on the road. Honest by
// construction — only patterns the story has already earned appear, and every
// fill is an earned lexeme, so this can never become a context-free grind.

struct PatternsView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onOpenPattern: (String) -> Void

    @State private var appeared = false

    private var lexicon: [Lexeme] { ContentLoader.lexicon(throughChapter: state.activeChapterN) }

    /// Patterns whose earning session is behind the learner — show due counts
    /// from the composite-key scheduler (DRILL.md).
    private var runnable: [(pattern: Pattern, due: Int, total: Int)] {
        ContentLoader.patterns(throughChapter: state.activeChapterN)
            .filter { state.hasEarned($0.earnedAt) }
            .map { pattern in
                let total = PatternDrill.items(for: pattern, in: lexicon).count
                let due = state.duePatternItems(for: pattern).count
                return (pattern, due, total)
            }
            .filter { $0.total >= 2 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                    .padding(.top, 12)

                if runnable.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(runnable.enumerated()), id: \.element.pattern.id) { i, entry in
                        PatternCard(pattern: entry.pattern, due: entry.due, total: entry.total) {
                            Haptics.tap()
                            onOpenPattern(entry.pattern.id)
                        }
                        .cascade(i, appeared: appeared, reduceMotion: reduceMotion)
                    }
                }

                Text("Ní cluiche é — a groove, not a game. Run a pattern when you want it surer; leave it when you don't. Nothing here is owed.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.inkFaint)
                    .lineSpacing(3)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 48)
            .frame(maxWidth: 640)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !appeared else { return }
            if reduceMotion { appeared = true }
            else { withAnimation(.easeOut(duration: 0.4)) { appeared = true } }
        }
    }

    private var header: some View {
        EditorialScreenHeader(
            context: "Cleachtadh · na patrúin",
            title: "Na patrúin — the grooves you know",
            detail: "Rules you've already met, each one to run with every word you've earned. One idea, many words — until the frame comes without thinking.",
            accent: Theme.moss
        )
    }

    private var emptyState: some View {
        Text("Walk the path a little further. When a scene teaches a pattern — the copula, the way a name states where it's from — it lands here as a groove to run.")
            .font(.system(size: 15, design: .serif))
            .italic()
            .foregroundStyle(Theme.inkSoft)
            .lineSpacing(4)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.sunk.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - One pattern on the shelf

private struct PatternCard: View {
    let pattern: Pattern
    let due: Int
    let total: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(backlink)
                        .font(.system(size: 11, weight: .semibold))
                        .kerning(0.6)
                        .foregroundStyle(Theme.moss)
                        .textCase(.uppercase)
                    Spacer(minLength: 0)
                    if due > 0 {
                        Text("\(due) réidh")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.moss)
                    }
                    Text("\(total) focal")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.inkFaint)
                }
                Text(PatternFrame.blanked(pattern.frame))
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .padding(.leading, 12)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Theme.moss.opacity(0.6))
                            .frame(width: 3)
                            .padding(.vertical, 2)
                    }
                Text(pattern.teach)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 6) {
                    Text("Rith é — run it")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.moss)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.moss)
                }
                .padding(.top, 2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.raised)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(Theme.moss.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(CarvePress())
        .accessibilityLabel("\(pattern.teach). \(due > 0 ? "\(due) due. " : "")\(total) words to run it with. \(backlink).")
    }

    private var backlink: String {
        guard let earned = pattern.earnedAt else { return "Patrún" }
        if let session = earned.session {
            return "Caibidil \(earned.chapter) · Seisiún \(session + 1)"
        }
        return "Caibidil \(earned.chapter)"
    }
}

// MARK: - The runner: one pattern, at volume

struct PatternDrillView: View {
    let pattern: Pattern

    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var queue: [SubstitutionItem] = []
    @State private var index = 0
    @State private var solvedCount = 0
    @State private var done = false

    private var current: SubstitutionItem? { queue.indices.contains(index) ? queue[index] : nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ruleStrip

                if queue.isEmpty {
                    emptyState
                } else {
                    CarveBarView(total: queue.count, done: solvedCount)
                        .frame(height: 20)
                        .padding(.vertical, 2)

                    if done {
                        closeCard
                            .transition(.offset(y: 10).combined(with: .opacity))
                    } else if let item = current {
                        VStack(alignment: .leading, spacing: 12) {
                            AssembleView(block: block(for: item), onSolved: { advance(struggled: $0) })
                                .id(item.id)
                            if let source = item.source, let gloss = glossLine(source) {
                                Text(gloss)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.inkFaint)
                            }
                        }
                        .id(item.id)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 48)
            .frame(maxWidth: 640)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if queue.isEmpty {
                queue = state.duePatternItems(for: pattern)
            }
        }
    }

    private var emptyState: some View {
        Text("Nothing due for this groove right now — walk on, and it'll offer itself when the interval opens.")
            .font(.system(size: 15, design: .serif))
            .italic()
            .foregroundStyle(Theme.inkSoft)
            .lineSpacing(4)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.sunk.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: The known groove, kept in view while you run it

    private var ruleStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                HStack(spacing: 3.5) {
                    ForEach(0..<3, id: \.self) { _ in
                        TickMark(variant: 2)
                            .stroke(Theme.moss.opacity(0.7),
                                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .frame(width: 8, height: 14)
                    }
                }
                Eyebrow(text: "An patrún · the groove", color: Theme.inkFaint)
            }
            Text(pattern.teach)
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineSpacing(4)
            VStack(alignment: .leading, spacing: 6) {
                Text(PatternFrame.blanked(pattern.frame))
                    .font(.system(size: 21, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.moss)
                if let contrast = pattern.contrast {
                    HStack(spacing: 8) {
                        Text("SEACHAIN")
                            .font(.system(size: 9, weight: .bold))
                            .kerning(1)
                            .foregroundStyle(Theme.stone)
                        Text(PatternFrame.blanked(contrast))
                            .font(.system(size: 16, design: .serif))
                            .foregroundStyle(Theme.stone)
                            .strikethrough(true, color: Theme.stone.opacity(0.5))
                    }
                }
            }
            .padding(.leading, 12)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Theme.moss.opacity(0.55))
                    .frame(width: 3)
                    .padding(.vertical, 2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.mossTint)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.moss.opacity(0.35), lineWidth: 1))
    }

    // MARK: The coverage close — what you can produce, not points

    private var closeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: "Snoite · carved", color: Theme.moss)
            Text("Rith tú an patrún seo le \(queue.count) focal.")
                .font(.system(size: 19, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            Text("You ran the groove through every word you've earned for it. That — how much of the pattern you can produce — is the only score here.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(4)
            FlowLayout(spacing: 8) {
                ForEach(queue) { item in
                    Text(item.answer)
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(Theme.ink)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 12)
                        .background(Theme.raised)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.moss.opacity(0.4), lineWidth: 1))
                }
            }
            PrimaryButton(title: "Ar ais chuig na patrúin →", fullWidth: true) {
                Haptics.tap()
                dismiss()
            }
            .padding(.top, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.mossTint)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.moss.opacity(0.4), lineWidth: 1))
    }

    // MARK: Logic

    private func block(for item: SubstitutionItem) -> AssembleBlock {
        AssembleBlock(context: item.source?.en,
                      prompt: PatternDrill.prompt(for: item, pattern: pattern),
                      tiles: item.tiles,
                      answer: item.answer,
                      ref: nil)
    }

    private func glossLine(_ lexeme: Lexeme) -> String? {
        guard let earned = lexeme.earnedAt else { return nil }
        if let session = earned.session {
            return "\(lexeme.ga) · \(lexeme.en) — ó Sheisiún \(session + 1)"
        }
        return "\(lexeme.ga) · \(lexeme.en)"
    }

    /// Let the verdict land, then rotate the next word in — or carve the close.
    private func advance(struggled: Bool) {
        if let item = current {
            state.completePatternItem(pattern: pattern, item: item, struggled: struggled)
        }
        solvedCount += 1
        let isLast = index + 1 >= queue.count
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(Motion.pop) {
                if isLast { done = true } else { index += 1 }
            }
            if isLast { Haptics.flourish() }
        }
    }
}

// MARK: - Rendering a frame with its slot as a blank

enum PatternFrame {
    /// "Is as {x} mé" → "Is as ___ mé": the pattern shown as a shape to fill.
    static func blanked(_ frame: String) -> String {
        frame.replacingOccurrences(of: #"\{[^}]*\}"#,
                                   with: "___",
                                   options: .regularExpression)
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
