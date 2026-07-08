import Foundation

// MARK: - Grammar across contexts: substitution drills, generated (DRILL.md §2)
// The second drill projection. One earned Pattern × its slot fills produces many
// items — "one core idea, slight variations." The *frame order* is the retrieval
// (the grammar of the copula: `Is mise X`, and `Is as X mé` with mé trailing);
// the fill is an atomic tile, so a multi-word placename never turns ordering
// into a spelling puzzle. Vocabulary rides along for free, because every fill is
// an earned lexeme (or an authored option) — the drill stays downstream of the
// story, exactly as the spine demands.

/// One generated substitution item: the pattern's frame with a single fill
/// rotated in, tokenised for an assemble drill.
struct SubstitutionItem: Identifiable {
    /// The rotated fill, e.g. "Gaillimh" or "Áine".
    let fill: String
    /// The earned lexeme the fill came from — nil for a literal `options` fill.
    /// Carries the English gloss and backlink the item shows.
    let source: Lexeme?
    /// The full framed sentence, e.g. "Is as Gaillimh mé" — the assemble answer.
    let answer: String
    /// Frame tokens with the slot filled, in correct order; the fill is one
    /// tile, so "Baile Átha Cliath" stays whole.
    let tiles: [String]

    var id: String { answer }
}

enum PatternDrill {
    /// Every substitution item a pattern generates against the earned lexicon —
    /// one per fill of its first slot. Fills come from an explicit `options`
    /// list, or from every lexeme carrying the slot's `fromTag` (in lexicon
    /// order, so fills track the vocabulary). Returns `[]` when the frame has no
    /// slot or nothing resolves. Any second slot (none ship today) holds its
    /// first fill; the first slot is the one that rotates.
    static func items(for pattern: Pattern, in lexicon: [Lexeme]) -> [SubstitutionItem] {
        let frameTokens = pattern.frame
            .split(separator: " ", omittingEmptySubsequences: true)
            .map(String.init)

        guard let primary = frameTokens.first(where: isSlot).map(slotName) else { return [] }

        let primaryFills = fills(forSlot: primary, pattern: pattern, lexicon: lexicon)
        guard !primaryFills.isEmpty else { return [] }

        return primaryFills.map { fill in
            let tiles: [String] = frameTokens.map { token in
                guard isSlot(token) else { return token }
                let name = slotName(token)
                if name == primary { return fill.text }
                return fills(forSlot: name, pattern: pattern, lexicon: lexicon).first?.text ?? token
            }
            return SubstitutionItem(fill: fill.text,
                                    source: fill.source,
                                    answer: tiles.joined(separator: " "),
                                    tiles: tiles)
        }
    }

    /// The production prompt for one item: the pattern's `cue` with the slot
    /// replaced by the fill ("Say you're from Gaillimh."). Falls back to a bare
    /// assemble instruction when a pattern carries no cue.
    static func prompt(for item: SubstitutionItem, pattern: Pattern) -> String {
        guard let cue = pattern.cue else { return "Cuir le chéile — assemble: \(item.fill)" }
        return cue.replacingOccurrences(of: #"\{[^}]*\}"#,
                                        with: item.fill,
                                        options: .regularExpression)
    }

    // MARK: Slot resolution

    private struct Fill { let text: String; let source: Lexeme? }

    private static func fills(forSlot name: String, pattern: Pattern, lexicon: [Lexeme]) -> [Fill] {
        guard let slot = pattern.slots?[name] else { return [] }
        if let options = slot.options {
            return options.map { Fill(text: $0, source: nil) }
        }
        if let tag = slot.fromTag {
            return lexicon
                .filter { ($0.tags ?? []).contains(tag) }
                .map { Fill(text: $0.ga, source: $0) }
        }
        return []
    }

    private static func isSlot(_ token: String) -> Bool {
        token.hasPrefix("{") && token.hasSuffix("}") && token.count > 2
    }

    private static func slotName(_ token: String) -> String {
        String(token.dropFirst().dropLast())
    }
}
