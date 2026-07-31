import Foundation

// MARK: - Shared activity state engine (D26/D27/D29, rebuild plan step 3)

/// The pure lifecycle engine every Learning-mode activity renders through
/// (rebuild plan, "Shared runtime and state model"). A response component
/// supplies a typed response and reports graded outcomes; the correctness
/// lifecycle, support, retry, completion, and exactly-once memory credit live
/// here — never in a SwiftUI view. The engine stores bounded signals only: no
/// recordings, no verbatim free text, and no option history for scheduling.

/// The visible lifecycle: unanswered, attempt, diagnostic, hint, recovery,
/// retry, complete. Selection-graded families reach `diagnostic` with the D27
/// repair window still open; explicit-Check families reach it with struggle
/// already recorded.
enum CountyActivityPhase: String, CaseIterable, Equatable {
    case unanswered
    case attempt
    case diagnostic
    case hint
    case recovery
    case retry
    case complete
}

enum CountyActivityOutcome: String, Equatable {
    case correct
    case incorrect
}

/// How a family's wrong response is graded (D27): a selection touch opens the
/// repair window before any struggle signal; an explicit Check records
/// struggle on the first failed check.
enum CountyActivityGrading: Equatable {
    case selectionTouch
    case explicitCheck
}

/// The typed response a component hands the runtime: family-agnostic, opaque,
/// and bounded. The engine records only the kind; the marker is component
/// bookkeeping and is never stored or persisted.
struct CountyActivityResponse: Equatable {
    enum Kind: String, CaseIterable, Equatable {
        case selection
        case arrangement
        case typedText
        case pairing
        case dialogueTurn
        case spokenComparison
        case containerAction
    }

    let kind: Kind
    /// Opaque per-family marker (an option or pair id). Never stored by the
    /// engine and never persisted.
    let marker: String?

    init(_ kind: Kind, marker: String? = nil) {
        self.kind = kind
        self.marker = marker
    }
}

/// The declared completion-evidence kinds from the rebuild plan's authored
/// learning contract. Raw values are the future schema vocabulary: runtime
/// and validators must share this one list.
enum CountyCompletionEvidence: String, CaseIterable, Codable, Equatable {
    case correctSelection
    case correctConstruction
    case correctedConstruction
    case reconstructedResponse
    case validDialogueTurn
    case orderedSequence
    case completedRecordCompare
}

/// Support narrows or restructures the same objective; neither kind completes
/// the exercise by itself.
enum CountyActivitySupport: String, Equatable {
    case hint
    case recovery
}

/// The four independent memory signals emitted per completed target (rebuild
/// plan, "Learner memory and scheduled review"). `struggle` fires eagerly when
/// the D27 repair window closes uncorrected because the run's contextual
/// review targets it; the rest fire at completion.
enum CountyMemoryEventKind: String, CaseIterable, Equatable {
    case success
    case struggle
    case hint
    case recovery
}

/// One exactly-once memory signal against an exercise's stable target ids.
struct CountyMemoryEvent: Equatable {
    let kind: CountyMemoryEventKind
    let exerciseID: String
    let targetIDs: [String]
}

/// Completion and memory-credit status recorded on an attempt event.
enum CountyActivityCredit: String, Equatable {
    /// The attempt did not complete the exercise.
    case pending
    /// The attempt completed the exercise; completion and memory credit recorded.
    case credited
    /// Practice on an already-completed exercise; credit stays with the original completion.
    case suppressedRevisit
}

/// The immutable record one checked attempt leaves behind (rebuild plan:
/// "Checking the response creates an immutable attempt event"). Bounded
/// signals only — never the response itself. The credit fields are written
/// once, at completion, onto the completing attempt.
struct CountyAttemptEvent: Equatable {
    let exerciseID: String
    let ordinal: Int
    let outcome: CountyActivityOutcome
    let diagnosticShown: Bool
    let hintUsed: Bool
    let recoveryUsed: Bool
    let completionEvidence: CountyCompletionEvidence?
    var completionCredit: CountyActivityCredit
    var memoryCredit: CountyActivityCredit
}

enum CountyActivityAction: String, Equatable {
    case updateResponse
    case check
    case requestHint
    case beginRecovery
    case retry
    case registerRepair
    case complete
    case interrupt
}

/// The result of one engine action. A rejected transition keeps `from == to`,
/// emits nothing, and leaves the engine untouched. Practice after completion
/// is accepted but records no credit and emits no memory event.
struct CountyActivityTransition: Equatable {
    let action: CountyActivityAction
    let accepted: Bool
    let from: CountyActivityPhase
    let to: CountyActivityPhase
    let isPractice: Bool
    let memoryEvents: [CountyMemoryEvent]
}

struct CountyActivityStateEngine: Equatable {

    // MARK: Configuration

    let exerciseID: String
    /// Stable lexeme/pattern ids every memory event credits.
    let targetIDs: [String]
    let grading: CountyActivityGrading
    /// The declared completion-evidence kind. `nil` for containers whose
    /// completion states capabilities rather than target-language evidence.
    let completionEvidence: CountyCompletionEvidence?
    /// True when the page's completion was credited before this engine opened
    /// (a revisit): practice is allowed, completion cannot be removed, and no
    /// memory credit can duplicate.
    let restoringCompletion: Bool

    // MARK: Readable state

    private(set) var phase: CountyActivityPhase
    private(set) var attempts: [CountyAttemptEvent]
    /// D27 repair window: after one wrong selection the attempt stays open and
    /// only the affected target carries the diagnostic. Struggle is signalled
    /// solely when the next checked touch fails to self-correct, or on leave.
    private(set) var repairWindowOpen: Bool
    private(set) var struggleSignalled: Bool
    private(set) var hintUsed: Bool
    private(set) var recoveryUsed: Bool
    /// Whether the active diagnostic escalated past the on-target note to the
    /// shared recovery panel. An explicit-Check failure always escalates; a
    /// window-closing selection wrong escalates only for families whose
    /// contract raises the panel — matching and conversation keep their brief
    /// on-target note.
    private(set) var diagnosticEscalated: Bool
    private(set) var lastResponseKind: CountyActivityResponse.Kind?

    private var hintContext: HintContext
    private var emittedMemoryKinds: Set<CountyMemoryEventKind> = []

    private enum HintContext: Equatable {
        case none
        /// Opened before any diagnostic: the next response lands via updateResponse.
        case early
        /// Opened from a diagnostic: the path back runs through retry.
        case afterDiagnostic
    }

    init(
        exerciseID: String,
        targetIDs: [String] = [],
        grading: CountyActivityGrading,
        completionEvidence: CountyCompletionEvidence?,
        restoringCompletion: Bool = false
    ) {
        self.exerciseID = exerciseID
        self.targetIDs = targetIDs
        self.grading = grading
        self.completionEvidence = completionEvidence
        self.restoringCompletion = restoringCompletion
        phase = restoringCompletion ? .complete : .unanswered
        attempts = []
        repairWindowOpen = false
        struggleSignalled = false
        hintUsed = false
        recoveryUsed = false
        diagnosticEscalated = false
        lastResponseKind = nil
        hintContext = .none
    }

    var isComplete: Bool { phase == .complete }

    /// A completion after support is a real completion, but not clean recall.
    var completedWithSupport: Bool { hintUsed || recoveryUsed || struggleSignalled }

    /// True when the response is closed and must be reopened by `retry`
    /// before the next response lands (diagnostic, recovery, or a hint taken
    /// from a diagnostic).
    var requiresRetry: Bool {
        switch phase {
        case .diagnostic, .recovery:
            return true
        case .hint:
            return hintContext == .afterDiagnostic
        default:
            return false
        }
    }

    // MARK: Contract actions

    /// Form or edit the response: unanswered → attempt, hint → attempt,
    /// retry → attempt. A formed-but-unchecked response stays editable.
    @discardableResult
    mutating func updateResponse(_ response: CountyActivityResponse) -> CountyActivityTransition {
        let from = phase
        switch phase {
        case .unanswered, .attempt, .retry:
            phase = .attempt
        case .hint where hintContext == .early:
            hintContext = .none
            phase = .attempt
        case .hint, .diagnostic, .recovery:
            // The response is closed; retry reopens it first.
            return reject(.updateResponse, from: from)
        case .complete:
            return practice(.updateResponse, from: from)
        }
        lastResponseKind = response.kind
        return accept(.updateResponse, from: from)
    }

    /// Check the formed response, creating an immutable attempt event. A
    /// correct check closes an open repair window with no struggle (the D27
    /// self-repair). An incorrect check moves to diagnostic: explicit-Check
    /// families signal struggle at once; selection families open the repair
    /// window first and signal struggle only when it closes unrepaired.
    @discardableResult
    mutating func check(
        outcome: CountyActivityOutcome,
        diagnosticShown: Bool,
        escalatesDiagnostic: Bool = false
    ) -> CountyActivityTransition {
        let from = phase
        switch phase {
        case .attempt:
            var events: [CountyMemoryEvent] = []
            attempts.append(
                CountyAttemptEvent(
                    exerciseID: exerciseID,
                    ordinal: attempts.count + 1,
                    outcome: outcome,
                    diagnosticShown: diagnosticShown,
                    hintUsed: hintUsed,
                    recoveryUsed: recoveryUsed,
                    completionEvidence: completionEvidence,
                    completionCredit: .pending,
                    memoryCredit: .pending
                )
            )
            if outcome == .incorrect {
                switch grading {
                case .explicitCheck:
                    struggleSignalled = true
                    events.append(contentsOf: emit(.struggle))
                    diagnosticEscalated = true
                case .selectionTouch:
                    if repairWindowOpen {
                        repairWindowOpen = false
                        struggleSignalled = true
                        events.append(contentsOf: emit(.struggle))
                        diagnosticEscalated = escalatesDiagnostic
                    } else if !struggleSignalled {
                        repairWindowOpen = true
                        diagnosticEscalated = false
                    } else {
                        diagnosticEscalated = escalatesDiagnostic
                    }
                }
                phase = .diagnostic
            } else {
                repairWindowOpen = false
            }
            return accept(.check, from: from, events: events)
        case .complete:
            attempts.append(
                CountyAttemptEvent(
                    exerciseID: exerciseID,
                    ordinal: attempts.count + 1,
                    outcome: outcome,
                    diagnosticShown: diagnosticShown,
                    hintUsed: hintUsed,
                    recoveryUsed: recoveryUsed,
                    completionEvidence: completionEvidence,
                    completionCredit: .suppressedRevisit,
                    memoryCredit: .suppressedRevisit
                )
            )
            return practice(.check, from: from)
        default:
            return reject(.check, from: from)
        }
    }

    /// unanswered → hint → attempt, or diagnostic → hint → retry → attempt. A
    /// hint narrows attention without silently answering the task.
    @discardableResult
    mutating func requestHint() -> CountyActivityTransition {
        let from = phase
        switch phase {
        case .unanswered, .attempt:
            hintContext = .early
        case .diagnostic:
            hintContext = .afterDiagnostic
            diagnosticEscalated = false
        case .hint, .recovery, .retry:
            return reject(.requestHint, from: from)
        case .complete:
            return practice(.requestHint, from: from)
        }
        hintUsed = true
        phase = .hint
        return accept(.requestHint, from: from)
    }

    /// diagnostic → recovery → retry → attempt. Recovery restructures the same
    /// objective; it never completes the exercise by itself.
    @discardableResult
    mutating func beginRecovery() -> CountyActivityTransition {
        let from = phase
        switch phase {
        case .diagnostic:
            recoveryUsed = true
            diagnosticEscalated = false
            phase = .recovery
            return accept(.beginRecovery, from: from)
        case .complete:
            return practice(.beginRecovery, from: from)
        default:
            return reject(.beginRecovery, from: from)
        }
    }

    /// diagnostic → retry, hint → retry, recovery → retry: the response
    /// becomes editable again with the diagnostic or chosen support reachable.
    @discardableResult
    mutating func retry() -> CountyActivityTransition {
        let from = phase
        switch phase {
        case .diagnostic, .recovery:
            phase = .retry
            return accept(.retry, from: from)
        case .hint where hintContext == .afterDiagnostic:
            hintContext = .none
            phase = .retry
            return accept(.retry, from: from)
        case .complete:
            return practice(.retry, from: from)
        default:
            return reject(.retry, from: from)
        }
    }

    /// D27: the next touch repairs in place. For families whose correct
    /// progression is not a checked attempt (a matched pair, a fitting
    /// dialogue turn), this closes an open repair window with no struggle
    /// signal and lets the attempt continue.
    @discardableResult
    mutating func registerRepair() -> CountyActivityTransition {
        let from = phase
        guard phase != .complete else { return practice(.registerRepair, from: from) }
        if repairWindowOpen {
            repairWindowOpen = false
            if phase == .diagnostic {
                diagnosticEscalated = false
                phase = .retry
            }
        }
        return accept(.registerRepair, from: from)
    }

    /// Complete the exercise against its declared evidence. Completion lands
    /// only from a formed, current response — every path in the plan ends
    /// attempt → complete, so diagnostic, hint, recovery, and retry must run
    /// their course back to attempt first. Exactly once: a second completion
    /// is rejected, and a revisited-complete engine can neither lose
    /// completion nor duplicate memory credit.
    @discardableResult
    mutating func complete() -> CountyActivityTransition {
        let from = phase
        guard phase == .attempt else { return reject(.complete, from: from) }
        var events = emit(.success)
        if struggleSignalled { events.append(contentsOf: emit(.struggle)) }
        if hintUsed { events.append(contentsOf: emit(.hint)) }
        if recoveryUsed { events.append(contentsOf: emit(.recovery)) }
        if let last = attempts.indices.last, attempts[last].outcome == .correct {
            attempts[last].completionCredit = .credited
            attempts[last].memoryCredit = .credited
        }
        diagnosticEscalated = false
        phase = .complete
        return accept(.complete, from: from, events: events)
    }

    /// Back navigation, backgrounding, and permission interruption must not
    /// invent a new attempt or lose a completed one. Per D27, leaving with the
    /// repair window open closes it as an unrepaired struggle. The current
    /// shell does not call this yet; page-lifecycle wiring lands with the
    /// shared shell in rebuild plan step 4.
    @discardableResult
    mutating func interrupt() -> CountyActivityTransition {
        let from = phase
        var events: [CountyMemoryEvent] = []
        if repairWindowOpen {
            repairWindowOpen = false
            struggleSignalled = true
            events.append(contentsOf: emit(.struggle))
        }
        return accept(.interrupt, from: from, events: events)
    }

    // MARK: Emission and transition helpers

    private mutating func emit(_ kind: CountyMemoryEventKind) -> [CountyMemoryEvent] {
        guard !emittedMemoryKinds.contains(kind) else { return [] }
        emittedMemoryKinds.insert(kind)
        return [CountyMemoryEvent(kind: kind, exerciseID: exerciseID, targetIDs: targetIDs)]
    }

    private func accept(
        _ action: CountyActivityAction,
        from: CountyActivityPhase,
        events: [CountyMemoryEvent] = []
    ) -> CountyActivityTransition {
        CountyActivityTransition(
            action: action, accepted: true, from: from, to: phase,
            isPractice: false, memoryEvents: events
        )
    }

    private func reject(
        _ action: CountyActivityAction,
        from: CountyActivityPhase
    ) -> CountyActivityTransition {
        CountyActivityTransition(
            action: action, accepted: false, from: from, to: from,
            isPractice: false, memoryEvents: []
        )
    }

    private func practice(
        _ action: CountyActivityAction,
        from: CountyActivityPhase
    ) -> CountyActivityTransition {
        CountyActivityTransition(
            action: action, accepted: true, from: from, to: from,
            isPractice: true, memoryEvents: []
        )
    }
}
