import Foundation

// MARK: - Vocabulary at volume: retrieval deck, generated (DRILL.md §1)
// The third drill projection. Due earned lexemes assemble into a deck and run
// through the existing match / listen / typein formats — recall-first, no new
// mechanics. Every card carries a backlink to the session that earned it; the
// scheduler underneath is the same boring interval math as Ar Ais, operating
// over unified lexeme ids instead of per-block strings.

/// One card in a vocabulary deck — either a single-lexeme retrieval or a batched
/// match over a tag group.
enum LexemeDeckItem: Identifiable {
    case typein(Lexeme, TypeInBlock)
    case listen(Lexeme, ListenBlock)
    case match([Lexeme], MatchBlock)

    var id: String {
        switch self {
        case .typein(let lexeme, _): return "typein:\(lexeme.id)"
        case .listen(let lexeme, _): return "listen:\(lexeme.id)"
        case .match(let lexemes, _): return "match:\(lexemes.map(\.id).joined(separator: "+"))"
        }
    }

    /// Lexeme ids this card schedules forward when answered.
    var lexemeIds: [String] {
        switch self {
        case .typein(let lexeme, _), .listen(let lexeme, _):
            return [lexeme.id]
        case .match(let lexemes, _):
            return lexemes.map(\.id)
        }
    }
}

enum LexemeDeck {
    /// Maximum cards per deck run — enough volume without turning into card debt.
    static let deckCap = 8

    /// Assemble due lexemes into deck items. Match batches groups of three or
    /// more sharing a tag; minimal-pair lemmas prefer listen; everything else
    /// is recall-first type-in (English → Irish).
    static func items(due: [Lexeme], in lexicon: [Lexeme]) -> [LexemeDeckItem] {
        var remaining = Array(due.prefix(deckCap))
        var out: [LexemeDeckItem] = []

        if let batch = matchBatch(from: &remaining) {
            out.append(.match(batch, matchBlock(for: batch)))
        }

        for lexeme in remaining {
            switch format(for: lexeme, in: lexicon) {
            case .listen:
                out.append(.listen(lexeme, listenBlock(for: lexeme, in: lexicon)))
            case .typein:
                out.append(.typein(lexeme, typeinBlock(for: lexeme)))
            }
        }
        return out
    }

    /// Human backlink shown on every card — where the story first earned this item.
    static func backlink(for lexeme: Lexeme) -> String {
        guard let earned = lexeme.earnedAt else { return "Ón gcosán" }
        if let session = earned.session {
            return "Ó Sheisiún \(session + 1), Caibidil \(earned.chapter)"
        }
        return "Ó Chaibidil \(earned.chapter)"
    }

    // MARK: Format selection

    private enum Format { case listen, typein }

    private static func format(for lexeme: Lexeme, in lexicon: [Lexeme]) -> Format {
        if !lemmaSiblings(of: lexeme, in: lexicon).isEmpty { return .listen }
        if (lexeme.tags ?? []).contains("minimal-pair") { return .listen }
        if (lexeme.tags ?? []).contains("fada"), lexeme.ph != nil { return .listen }
        return .typein
    }

    // MARK: Block builders

    private static func typeinBlock(for lexeme: Lexeme) -> TypeInBlock {
        TypeInBlock(
            context: backlink(for: lexeme),
            prompt: "What is “\(lexeme.en)” in Irish?",
            placeholder: "Type the Irish…",
            check: .exact,
            answer: lexeme.ga,
            fada: lexeme.ga.contains { "áéíóúÁÉÍÓÚ".contains($0) },
            hint: lexeme.ph.map { "Sounds like: \($0)" },
            capture: nil,
            ref: nil)
    }

    private static func listenBlock(for lexeme: Lexeme, in lexicon: [Lexeme]) -> ListenBlock {
        let siblings = lemmaSiblings(of: lexeme, in: lexicon)
        var distractors = siblings.map { sibling in
            ChoiceOption(txt: "\(sibling.ga) — \(sibling.en)", ok: false,
                         why: "Not that one — listen for the length and the vowel.")
        }
        if distractors.isEmpty {
            distractors = lexicon
                .filter { $0.id != lexeme.id && $0.ga.split(separator: " ").count <= 2 }
                .shuffled()
                .prefix(2)
                .map { other in
                    ChoiceOption(txt: "\(other.ga) — \(other.en)", ok: false,
                                 why: "Not that one — listen again.")
                }
        }
        let correct = ChoiceOption(
            txt: "\(lexeme.ga) — \(lexeme.en)",
            ok: true,
            why: "You heard it — the ear knew before the eye did.")
        let opts = (distractors + [correct]).shuffled()
        return ListenBlock(
            context: backlink(for: lexeme),
            prompt: "Éist — which word did you hear?",
            say: lexeme.ga,
            opts: opts,
            ref: nil)
    }

    private static func matchBlock(for lexemes: [Lexeme]) -> MatchBlock {
        let pairs = lexemes.map { [$0.ga, shortEnglish($0.en)] }
        let context = lexemes.first.map { backlink(for: $0) } ?? "Ón gcosán"
        return MatchBlock(
            context: context,
            prompt: "Match the Irish to its meaning.",
            pairs: pairs,
            refs: nil)
    }

    /// Trim parenthetical glosses so match tiles stay scannable.
    private static func shortEnglish(_ en: String) -> String {
        if let paren = en.firstIndex(of: "(") {
            return String(en[..<paren]).trimmingCharacters(in: .whitespaces)
        }
        return en
    }

    // MARK: Match batching

    private static func matchBatch(from remaining: inout [Lexeme]) -> [Lexeme]? {
        let grouped = Dictionary(grouping: remaining) { lexeme -> String in
            (lexeme.tags ?? []).first { tag in
                tag != "minimal-pair" && tag != "fada" && tag != "pattern-instance"
            } ?? lexeme.kind ?? "other"
        }
        guard let (_, group) = grouped.max(by: { $0.value.count < $1.value.count }),
              group.count >= 3 else { return nil }
        let batch = Array(group.prefix(4))
        remaining.removeAll { lex in batch.contains { $0.id == lex.id } }
        return batch
    }

    private static func lemmaSiblings(of lexeme: Lexeme, in lexicon: [Lexeme]) -> [Lexeme] {
        guard let lemma = lexeme.lemma else { return [] }
        return lexicon.filter { $0.id != lexeme.id && $0.lemma == lemma }
    }
}
