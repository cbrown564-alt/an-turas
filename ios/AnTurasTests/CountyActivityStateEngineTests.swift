import XCTest
@testable import AnTuras

/// Rebuild plan step 3: the pure shared state engine for Learning-mode
/// activities. Covers every legal lifecycle transition, rejected illegal
/// transitions, interruption and revisit, the D27 repair window for
/// selection families versus explicit-Check families, and exactly-once
/// completion and memory credit.
final class CountyActivityStateEngineTests: XCTestCase {

    private func selectionEngine(
        evidence: CountyCompletionEvidence? = .correctSelection,
        restoring: Bool = false
    ) -> CountyActivityStateEngine {
        CountyActivityStateEngine(
            exerciseID: "mayo.clew-bay.listen-farraige",
            targetIDs: ["lex.farraige"],
            grading: .selectionTouch,
            completionEvidence: evidence,
            restoringCompletion: restoring
        )
    }

    private func checkEngine() -> CountyActivityStateEngine {
        CountyActivityStateEngine(
            exerciseID: "mayo.clew-bay.type-origin",
            targetIDs: ["lex.as", "lex.maigh-eo"],
            grading: .explicitCheck,
            completionEvidence: .correctConstruction,
            restoringCompletion: false
        )
    }

    // MARK: Legal transitions

    func testUnansweredToAttempt() {
        var engine = selectionEngine()
        let transition = engine.updateResponse(CountyActivityResponse(.selection, marker: "opt-1"))

        XCTAssertTrue(transition.accepted)
        XCTAssertEqual(transition.from, .unanswered)
        XCTAssertEqual(transition.to, .attempt)
        XCTAssertEqual(engine.phase, .attempt)
        XCTAssertEqual(engine.lastResponseKind, .selection)
        XCTAssertTrue(transition.memoryEvents.isEmpty)
    }

    func testFormedResponseStaysEditableUntilChecked() {
        var engine = selectionEngine()
        engine.updateResponse(CountyActivityResponse(.selection, marker: "opt-1"))
        let edit = engine.updateResponse(CountyActivityResponse(.selection, marker: "opt-2"))

        XCTAssertTrue(edit.accepted)
        XCTAssertEqual(edit.to, .attempt)
        XCTAssertEqual(engine.phase, .attempt)
    }

    func testAttemptToCompleteEmitsSuccessOnce() {
        var engine = selectionEngine()
        engine.updateResponse(CountyActivityResponse(.selection))
        let check = engine.check(outcome: .correct, diagnosticShown: false)
        let completion = engine.complete()

        XCTAssertTrue(check.accepted)
        XCTAssertTrue(completion.accepted)
        XCTAssertEqual(completion.from, .attempt)
        XCTAssertEqual(completion.to, .complete)
        XCTAssertTrue(engine.isComplete)
        XCTAssertEqual(completion.memoryEvents.map(\.kind), [.success])
        XCTAssertEqual(completion.memoryEvents.first?.exerciseID, "mayo.clew-bay.listen-farraige")
        XCTAssertEqual(completion.memoryEvents.first?.targetIDs, ["lex.farraige"])
        XCTAssertFalse(engine.completedWithSupport, "A clean success carries no support signal")
    }

    func testAttemptToDiagnosticOnIncorrectCheck() {
        var engine = checkEngine()
        engine.updateResponse(CountyActivityResponse(.typedText))
        let check = engine.check(outcome: .incorrect, diagnosticShown: true)

        XCTAssertTrue(check.accepted)
        XCTAssertEqual(check.from, .attempt)
        XCTAssertEqual(check.to, .diagnostic)
        XCTAssertEqual(engine.phase, .diagnostic)
        XCTAssertEqual(engine.attempts.count, 1)
        XCTAssertEqual(engine.attempts.first?.outcome, .incorrect)
        XCTAssertEqual(engine.attempts.first?.diagnosticShown, true)
    }

    func testUnansweredToHintToAttempt() {
        var engine = selectionEngine()
        let hint = engine.requestHint()
        let response = engine.updateResponse(CountyActivityResponse(.selection))

        XCTAssertTrue(hint.accepted)
        XCTAssertEqual(hint.from, .unanswered)
        XCTAssertEqual(hint.to, .hint)
        XCTAssertTrue(engine.hintUsed)
        XCTAssertTrue(response.accepted)
        XCTAssertEqual(response.from, .hint)
        XCTAssertEqual(response.to, .attempt)
    }

    func testDiagnosticToRetryToAttempt() {
        var engine = checkEngine()
        engine.updateResponse(CountyActivityResponse(.typedText))
        engine.check(outcome: .incorrect, diagnosticShown: true)

        let retry = engine.retry()
        let response = engine.updateResponse(CountyActivityResponse(.typedText))

        XCTAssertTrue(retry.accepted)
        XCTAssertEqual(retry.from, .diagnostic)
        XCTAssertEqual(retry.to, .retry)
        XCTAssertTrue(response.accepted)
        XCTAssertEqual(response.from, .retry)
        XCTAssertEqual(response.to, .attempt)
    }

    func testDiagnosticToHintToRetryToAttempt() {
        var engine = checkEngine()
        engine.updateResponse(CountyActivityResponse(.typedText))
        engine.check(outcome: .incorrect, diagnosticShown: true)

        let hint = engine.requestHint()
        XCTAssertTrue(hint.accepted)
        XCTAssertEqual(hint.to, .hint)
        XCTAssertTrue(engine.requiresRetry, "A hint taken from a diagnostic returns through retry")

        // The response stays closed until retry reopens it.
        let early = engine.updateResponse(CountyActivityResponse(.typedText))
        XCTAssertFalse(early.accepted)

        let retry = engine.retry()
        let response = engine.updateResponse(CountyActivityResponse(.typedText))
        XCTAssertEqual(retry.to, .retry)
        XCTAssertEqual(response.to, .attempt)
    }

    func testDiagnosticToRecoveryToRetryToAttempt() {
        var engine = checkEngine()
        engine.updateResponse(CountyActivityResponse(.typedText))
        engine.check(outcome: .incorrect, diagnosticShown: true)

        let recovery = engine.beginRecovery()
        XCTAssertTrue(recovery.accepted)
        XCTAssertEqual(recovery.from, .diagnostic)
        XCTAssertEqual(recovery.to, .recovery)
        XCTAssertTrue(engine.recoveryUsed)

        // Recovery never completes the exercise by itself: the path back runs
        // through retry to a fresh attempt.
        XCTAssertFalse(engine.complete().accepted)

        let retry = engine.retry()
        let response = engine.updateResponse(CountyActivityResponse(.typedText))
        XCTAssertEqual(retry.to, .retry)
        XCTAssertEqual(response.to, .attempt)
    }

    func testAttemptToDiagnosticThroughRetryToComplete() {
        var engine = checkEngine()
        engine.updateResponse(CountyActivityResponse(.typedText))
        engine.check(outcome: .incorrect, diagnosticShown: true)
        engine.retry()
        engine.updateResponse(CountyActivityResponse(.typedText))
        engine.check(outcome: .correct, diagnosticShown: false)
        let completion = engine.complete()

        XCTAssertTrue(completion.accepted)
        XCTAssertTrue(engine.isComplete)
        XCTAssertTrue(engine.completedWithSupport, "Completion after a failed check is not clean recall")
        XCTAssertEqual(engine.attempts.map(\.ordinal), [1, 2])
        // Struggle fired eagerly on the failed explicit check; completion adds
        // success only — no duplicate struggle.
        XCTAssertEqual(completion.memoryEvents.map(\.kind), [.success])
        XCTAssertEqual(engine.attempts.last?.completionCredit, .credited)
        XCTAssertEqual(engine.attempts.last?.memoryCredit, .credited)
        XCTAssertEqual(engine.attempts.first?.completionCredit, .pending)
    }

    // MARK: Rejected illegal transitions

    func testCheckWithoutAFormedResponseIsRejected() {
        var engine = selectionEngine()
        let check = engine.check(outcome: .correct, diagnosticShown: false)

        XCTAssertFalse(check.accepted)
        XCTAssertEqual(check.from, .unanswered)
        XCTAssertEqual(check.to, .unanswered)
        XCTAssertEqual(engine.phase, .unanswered)
        XCTAssertTrue(engine.attempts.isEmpty)
    }

    func testCheckFromDiagnosticIsRejectedUntilRetry() {
        var engine = checkEngine()
        engine.updateResponse(CountyActivityResponse(.typedText))
        engine.check(outcome: .incorrect, diagnosticShown: true)

        let check = engine.check(outcome: .correct, diagnosticShown: false)

        XCTAssertFalse(check.accepted)
        XCTAssertEqual(engine.phase, .diagnostic)
        XCTAssertEqual(engine.attempts.count, 1)
    }

    func testCompleteWithoutAFormedResponseIsRejected() {
        var engine = selectionEngine()
        let completion = engine.complete()

        XCTAssertFalse(completion.accepted)
        XCTAssertFalse(engine.isComplete)
        XCTAssertTrue(completion.memoryEvents.isEmpty)
    }

    func testCompleteFromAnEarlyHintIsRejected() {
        var engine = selectionEngine()
        engine.requestHint()

        let completion = engine.complete()

        XCTAssertFalse(completion.accepted, "A hint alone never completes the exercise")
        XCTAssertEqual(engine.phase, .hint)
    }

    func testDuplicateCompletionIsRejectedAndEmitsNothing() {
        var engine = selectionEngine()
        engine.updateResponse(CountyActivityResponse(.selection))
        engine.check(outcome: .correct, diagnosticShown: false)
        engine.complete()

        let again = engine.complete()

        XCTAssertFalse(again.accepted)
        XCTAssertTrue(again.memoryEvents.isEmpty)
        XCTAssertTrue(engine.isComplete)
    }

    func testUpdateResponseFromDiagnosticOrRecoveryIsRejected() {
        var engine = checkEngine()
        engine.updateResponse(CountyActivityResponse(.typedText))
        engine.check(outcome: .incorrect, diagnosticShown: true)

        XCTAssertFalse(engine.updateResponse(CountyActivityResponse(.typedText)).accepted)

        engine.beginRecovery()
        XCTAssertFalse(engine.updateResponse(CountyActivityResponse(.typedText)).accepted)
        XCTAssertEqual(engine.phase, .recovery)
    }

    func testRetryFromUnansweredAttemptOrRetryIsRejected() {
        var engine = selectionEngine()
        XCTAssertFalse(engine.retry().accepted)

        engine.updateResponse(CountyActivityResponse(.selection))
        XCTAssertFalse(engine.retry().accepted)
    }

    func testSecondHintAndHintFromRecoveryAreRejected() {
        var engine = checkEngine()
        engine.updateResponse(CountyActivityResponse(.typedText))
        engine.check(outcome: .incorrect, diagnosticShown: true)
        engine.requestHint()

        XCTAssertFalse(engine.requestHint().accepted, "Already in hint")

        var recovering = checkEngine()
        recovering.updateResponse(CountyActivityResponse(.typedText))
        recovering.check(outcome: .incorrect, diagnosticShown: true)
        recovering.beginRecovery()

        XCTAssertFalse(recovering.requestHint().accepted, "Hint does not stack on recovery")
    }

    func testCompleteFromDiagnosticOrRetryIsRejected() {
        var engine = checkEngine()
        engine.updateResponse(CountyActivityResponse(.typedText))
        engine.check(outcome: .incorrect, diagnosticShown: true)

        XCTAssertFalse(engine.complete().accepted, "Diagnostic must run back through retry to attempt")

        engine.retry()
        XCTAssertFalse(engine.complete().accepted, "A retry without a fresh response is not completion")
    }

    func testRecoveryWithoutDiagnosticIsRejected() {
        var engine = selectionEngine()
        XCTAssertFalse(engine.beginRecovery().accepted)

        engine.updateResponse(CountyActivityResponse(.selection))
        XCTAssertFalse(engine.beginRecovery().accepted)
    }

    // MARK: D27 repair window — selection families

    func testFirstWrongSelectionOpensTheRepairWindowWithoutStruggle() {
        var engine = selectionEngine()
        engine.updateResponse(CountyActivityResponse(.selection))
        let check = engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: true)

        XCTAssertTrue(check.accepted)
        XCTAssertEqual(engine.phase, .diagnostic)
        XCTAssertTrue(engine.repairWindowOpen, "The attempt stays open for the next touch")
        XCTAssertFalse(engine.struggleSignalled)
        XCTAssertTrue(check.memoryEvents.isEmpty, "No struggle on the first wrong selection")
        XCTAssertFalse(engine.diagnosticEscalated, "The diagnostic stays on the affected target")
        XCTAssertEqual(engine.attempts.count, 1, "The wrong selection is still a checked attempt")
    }

    func testSecondWrongSelectionClosesTheWindowAndSignalsStruggleOnce() {
        var engine = selectionEngine()
        engine.updateResponse(CountyActivityResponse(.selection))
        engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: true)

        engine.retry()
        engine.updateResponse(CountyActivityResponse(.selection))
        let second = engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: true)

        XCTAssertFalse(engine.repairWindowOpen)
        XCTAssertTrue(engine.struggleSignalled)
        XCTAssertEqual(second.memoryEvents.map(\.kind), [.struggle])
        XCTAssertTrue(engine.diagnosticEscalated, "Choice families raise the recovery panel")

        // A third wrong never duplicates the memory event.
        engine.retry()
        engine.updateResponse(CountyActivityResponse(.selection))
        let third = engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: true)
        XCTAssertTrue(third.memoryEvents.isEmpty, "Struggle is exactly once")
        XCTAssertEqual(engine.attempts.count, 3)
    }

    func testSelfCorrectingNextTouchClosesTheWindowWithoutStruggle() {
        var engine = selectionEngine()
        engine.updateResponse(CountyActivityResponse(.selection))
        engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: true)

        engine.retry()
        engine.updateResponse(CountyActivityResponse(.selection))
        let repair = engine.check(outcome: .correct, diagnosticShown: false)

        XCTAssertTrue(repair.accepted)
        XCTAssertFalse(engine.repairWindowOpen)
        XCTAssertFalse(engine.struggleSignalled, "Self-repair inside the window never signals struggle")

        let completion = engine.complete()
        XCTAssertEqual(completion.memoryEvents.map(\.kind), [.success])
        XCTAssertFalse(engine.completedWithSupport)
    }

    func testRegisterRepairClosesTheWindowForUncheckedProgress() {
        // Matching-style: a correct pair is not a checked attempt, but the
        // next touch still repairs in place (D27).
        var engine = CountyActivityStateEngine(
            exerciseID: "mayo.clew-bay.match-coast",
            targetIDs: ["lex.farraige", "lex.ba"],
            grading: .selectionTouch,
            completionEvidence: .reconstructedResponse,
            restoringCompletion: false
        )
        engine.updateResponse(CountyActivityResponse(.pairing))
        engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: false)
        XCTAssertTrue(engine.repairWindowOpen)

        let repair = engine.registerRepair()

        XCTAssertTrue(repair.accepted)
        XCTAssertFalse(engine.repairWindowOpen)
        XCTAssertFalse(engine.struggleSignalled)
        XCTAssertEqual(repair.to, .retry, "The attempt continues after the repair")
        XCTAssertTrue(engine.attempts.count == 1, "A repair touch records no new attempt")
    }

    func testNonEscalatingFamiliesSignalStruggleWithoutRaisingThePanel() {
        // Matching and conversation keep the on-target note on the second
        // wrong; struggle is still signalled exactly once.
        var engine = CountyActivityStateEngine(
            exerciseID: "mayo.clew-bay.match-coast",
            targetIDs: ["lex.farraige"],
            grading: .selectionTouch,
            completionEvidence: .reconstructedResponse,
            restoringCompletion: false
        )
        engine.updateResponse(CountyActivityResponse(.pairing))
        engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: false)
        engine.retry()
        engine.updateResponse(CountyActivityResponse(.pairing))
        let second = engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: false)

        XCTAssertEqual(second.memoryEvents.map(\.kind), [.struggle])
        XCTAssertFalse(engine.diagnosticEscalated, "The shared recovery panel stays down")
    }

    // MARK: Explicit-Check families

    func testExplicitCheckSignalsStruggleOnTheFirstFailure() {
        var engine = checkEngine()
        engine.updateResponse(CountyActivityResponse(.typedText))
        let check = engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: true)

        XCTAssertTrue(engine.struggleSignalled)
        XCTAssertFalse(engine.repairWindowOpen, "Explicit Check has no repair window")
        XCTAssertEqual(check.memoryEvents.map(\.kind), [.struggle])
        XCTAssertTrue(engine.diagnosticEscalated)
        XCTAssertEqual(engine.phase, .diagnostic)
    }

    func testExplicitCheckRetryThenSuccessKeepsExactlyOneStruggle() {
        var engine = checkEngine()
        engine.updateResponse(CountyActivityResponse(.typedText))
        engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: true)
        engine.retry()
        engine.updateResponse(CountyActivityResponse(.typedText))
        let secondWrong = engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: true)

        XCTAssertTrue(secondWrong.memoryEvents.isEmpty, "Struggle already fired")

        engine.retry()
        engine.updateResponse(CountyActivityResponse(.typedText))
        engine.check(outcome: .correct, diagnosticShown: false)
        let completion = engine.complete()

        XCTAssertEqual(completion.memoryEvents.map(\.kind), [.success])
        XCTAssertTrue(engine.completedWithSupport)
    }

    // MARK: Support signals at completion

    func testCompletionAfterHintAndRecoveryEmitsEachSignalOnce() {
        var engine = checkEngine()
        engine.requestHint()
        engine.updateResponse(CountyActivityResponse(.typedText))
        engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: true)
        engine.beginRecovery()
        engine.retry()
        engine.updateResponse(CountyActivityResponse(.typedText))
        engine.check(outcome: .correct, diagnosticShown: false)
        let completion = engine.complete()

        XCTAssertEqual(completion.memoryEvents.map(\.kind), [.success, .hint, .recovery])
        XCTAssertTrue(engine.completedWithSupport)

        // Nothing more can be emitted for this exercise.
        XCTAssertTrue(engine.complete().memoryEvents.isEmpty)
    }

    func testAttemptEventsCarryTheSupportFlagsAtAttemptTime() {
        var engine = checkEngine()
        engine.requestHint()
        engine.updateResponse(CountyActivityResponse(.typedText))
        engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: true)
        engine.beginRecovery()
        engine.retry()
        engine.updateResponse(CountyActivityResponse(.typedText))
        engine.check(outcome: .correct, diagnosticShown: false)

        XCTAssertEqual(engine.attempts.count, 2)
        XCTAssertEqual(engine.attempts[0].hintUsed, true)
        XCTAssertEqual(engine.attempts[0].recoveryUsed, false)
        XCTAssertEqual(engine.attempts[1].hintUsed, true)
        XCTAssertEqual(engine.attempts[1].recoveryUsed, true)
        XCTAssertEqual(engine.attempts[0].exerciseID, "mayo.clew-bay.type-origin")
        XCTAssertEqual(engine.attempts[0].completionEvidence, .correctConstruction)
    }

    // MARK: Interruption

    func testInterruptPreservesPhaseAndAttempts() {
        var engine = checkEngine()
        engine.updateResponse(CountyActivityResponse(.typedText))
        engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: true)

        let interrupt = engine.interrupt()

        XCTAssertTrue(interrupt.accepted)
        XCTAssertEqual(interrupt.from, .diagnostic)
        XCTAssertEqual(interrupt.to, .diagnostic, "Interruption invents no transition")
        XCTAssertEqual(engine.attempts.count, 1)
        XCTAssertTrue(interrupt.memoryEvents.isEmpty, "No open repair window, no new signal")
    }

    func testInterruptWithAnOpenRepairWindowSignalsStruggle() {
        var engine = selectionEngine()
        engine.updateResponse(CountyActivityResponse(.selection))
        engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: true)
        XCTAssertTrue(engine.repairWindowOpen)

        let interrupt = engine.interrupt()

        XCTAssertEqual(interrupt.memoryEvents.map(\.kind), [.struggle], "D27: leaving unrepaired signals struggle")
        XCTAssertFalse(engine.repairWindowOpen)
        XCTAssertEqual(engine.phase, .diagnostic, "The attempt itself is not lost")
    }

    func testInterruptAfterCompletionLosesNothing() {
        var engine = selectionEngine()
        engine.updateResponse(CountyActivityResponse(.selection))
        engine.check(outcome: .correct, diagnosticShown: false)
        engine.complete()

        let interrupt = engine.interrupt()

        XCTAssertTrue(interrupt.memoryEvents.isEmpty)
        XCTAssertTrue(engine.isComplete)
        XCTAssertEqual(engine.attempts.count, 1)
    }

    // MARK: Revisit of a completed page

    func testRevisitedCompletionStartsCompleteAndCannotBeRemoved() {
        var engine = selectionEngine(restoring: true)

        XCTAssertTrue(engine.isComplete)
        XCTAssertEqual(engine.phase, .complete)

        let completion = engine.complete()
        XCTAssertFalse(completion.accepted, "Duplicate completion is rejected")
        XCTAssertTrue(engine.isComplete, "Practice cannot remove completion")
    }

    func testRevisitedCompletionAllowsPracticeWithoutCredit() {
        var engine = selectionEngine(restoring: true)

        let response = engine.updateResponse(CountyActivityResponse(.selection))
        let check = engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: true)
        let hint = engine.requestHint()

        XCTAssertTrue(response.isPractice)
        XCTAssertTrue(check.isPractice)
        XCTAssertTrue(hint.isPractice)
        XCTAssertTrue(response.memoryEvents.isEmpty)
        XCTAssertTrue(check.memoryEvents.isEmpty, "No struggle credit on a revisited page")
        XCTAssertTrue(hint.memoryEvents.isEmpty)
        XCTAssertTrue(engine.isComplete)
        XCTAssertEqual(engine.attempts.last?.completionCredit, .suppressedRevisit)
        XCTAssertEqual(engine.attempts.last?.memoryCredit, .suppressedRevisit)
    }

    func testPracticeAfterCompletionInSessionEmitsNoDuplicateCredit() {
        var engine = selectionEngine()
        engine.updateResponse(CountyActivityResponse(.selection))
        engine.check(outcome: .correct, diagnosticShown: false)
        let completion = engine.complete()
        XCTAssertEqual(completion.memoryEvents.map(\.kind), [.success])

        // The learner keeps practising on the completed page.
        let response = engine.updateResponse(CountyActivityResponse(.selection))
        let check = engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: true)
        let completionAgain = engine.complete()

        XCTAssertTrue(response.isPractice)
        XCTAssertTrue(check.isPractice)
        XCTAssertTrue(check.memoryEvents.isEmpty, "Practice struggle earns no memory credit")
        XCTAssertFalse(completionAgain.accepted)
        XCTAssertTrue(engine.isComplete)
        XCTAssertEqual(engine.attempts.count, 2)
        XCTAssertEqual(engine.attempts[0].completionCredit, .credited)
        XCTAssertEqual(engine.attempts[1].completionCredit, .suppressedRevisit)
    }

    // MARK: Memory event identity

    func testMemoryEventsNameTheExerciseAndItsTargets() {
        var engine = checkEngine()
        engine.updateResponse(CountyActivityResponse(.typedText))
        let check = engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: true)

        let struggle = check.memoryEvents.first
        XCTAssertEqual(struggle?.kind, .struggle)
        XCTAssertEqual(struggle?.exerciseID, "mayo.clew-bay.type-origin")
        XCTAssertEqual(struggle?.targetIDs, ["lex.as", "lex.maigh-eo"])
    }
}
