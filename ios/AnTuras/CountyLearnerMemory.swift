import Foundation

/// Per-target flags accumulated from the four D27 memory signals during a
/// Learning run. Used to seed atlas review with explainable, debt-free
/// stability/difficulty — never to invent overdue counts or gates.
struct CountyTargetMemoryFlags: Codable, Equatable {
    var success = false
    var struggle = false
    var hint = false
    var recovery = false

    mutating func apply(_ kind: CountyMemoryEventKind) {
        switch kind {
        case .success: success = true
        case .struggle: struggle = true
        case .hint: hint = true
        case .recovery: recovery = true
        }
    }
}

/// One persisted exactly-once memory credit (rebuild plan step 11).
struct CountyPersistedMemoryEvent: Codable, Equatable, Identifiable {
    var id: String { "\(packID)|\(exerciseID)|\(kind.rawValue)" }
    let packID: String
    let kind: CountyMemoryEventKind
    let exerciseID: String
    let targetIDs: [String]
}

/// Deterministic learner-memory handoff: exactly-once ledger + initial review
/// parameters derived from the four signals. Debt-free: hint/recovery never
/// create overdue work or a completion gate; they only soften a later schedule.
enum CountyLearnerMemory {
    /// Initial FSRS-lite values when a county first schedules its words.
    struct ReviewSeed: Equatable {
        let stability: Double
        let difficulty: Double
        let intervalDays: Int
        let explanation: String
    }

    /// Record an engine memory event once per (pack, exercise, kind).
    @discardableResult
    static func record(
        _ event: CountyMemoryEvent,
        packID: String,
        into events: inout [CountyPersistedMemoryEvent],
        flags: inout [String: CountyTargetMemoryFlags]
    ) -> Bool {
        let persisted = CountyPersistedMemoryEvent(
            packID: packID,
            kind: event.kind,
            exerciseID: event.exerciseID,
            targetIDs: event.targetIDs
        )
        guard !events.contains(where: { $0.id == persisted.id }) else { return false }
        events.append(persisted)
        for targetID in event.targetIDs {
            let key = flagKey(packID: packID, targetID: targetID)
            var entry = flags[key, default: CountyTargetMemoryFlags()]
            entry.apply(event.kind)
            flags[key] = entry
        }
        return true
    }

    static func flagKey(packID: String, targetID: String) -> String {
        "\(packID)|\(targetID)"
    }

    /// Match a scheduled headword to memory flags via fada-folded lexeme stem.
    static func flags(
        for word: AtlasWord,
        packID: String,
        in table: [String: CountyTargetMemoryFlags]
    ) -> CountyTargetMemoryFlags {
        let foldedGa = foldingFadas(word.ga)
        for (key, flags) in table where key.hasPrefix(packID + "|") {
            let targetID = String(key.dropFirst(packID.count + 1))
            let stem = targetID.hasPrefix("lex.") ? String(targetID.dropFirst(4)) : targetID
            if foldingFadas(stem) == foldedGa {
                return flags
            }
        }
        return CountyTargetMemoryFlags()
    }

    /// Debt-free initial schedule from Learning-path signals.
    /// - struggle → harder / sooner first interval
    /// - clean success → modest stability
    /// - hint/recovery without struggle → slightly softer than clean (not a clean-recall claim)
    /// - never schedules in the past or invents a gate/overdue count
    static func reviewSeed(from flags: CountyTargetMemoryFlags, staggerIndex: Int = 0) -> ReviewSeed {
        var stability = 1.0
        var difficulty = 5.0
        var reasons: [String] = []

        if flags.struggle {
            difficulty = min(10, difficulty + 0.8)
            stability = max(0.6, stability * 0.55)
            reasons.append("struggle raised difficulty")
        } else if flags.success {
            if flags.hint || flags.recovery {
                stability = 1.35
                difficulty = max(1, difficulty - 0.1)
                reasons.append(flags.recovery ? "recovered completion" : "hinted completion")
            } else {
                stability = 2.5
                difficulty = max(1, difficulty - 0.25)
                reasons.append("clean success")
            }
        } else if flags.hint || flags.recovery {
            stability = 1.2
            reasons.append("support used without recorded success")
        } else {
            reasons.append("no Learning memory signals")
        }

        // First due is always at least tomorrow — debt-free for the learner.
        let baseDays = flags.struggle ? 1 : max(1, Int(stability.rounded()))
        let intervalDays = baseDays + max(0, staggerIndex)
        return ReviewSeed(
            stability: stability,
            difficulty: difficulty,
            intervalDays: intervalDays,
            explanation: reasons.joined(separator: "; ") + "; first due in \(intervalDays)d"
        )
    }

    private static func foldingFadas(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "ga_IE"))
    }
}

extension CountyMemoryEventKind: Codable {}
