import XCTest
@testable import AnTuras

/// Rebuild plan step 5 (schema hardening, phase A): the authored learning
/// contract — backward-compatible decoding, the deterministic adapter that
/// derives a contract from the pre-contract flat fields, authored winning over
/// adapted, and the declared completion evidence reaching the engine unchanged.
final class CountyLearningContractTests: XCTestCase {

    // MARK: Helpers

    /// A flat pre-contract exercise decoded from JSON: no `learningContract`,
    /// no per-option `misconceptionID`.
    private func flatExercise(family: String, authoredUse: String? = nil) throws -> CountyExercise {
        let authoredUseLine = authoredUse.map { #""authoredUse": "\#($0)","# } ?? ""
        let json = """
        {
          "family": "\(family)",
          \(authoredUseLine)
          "objective": "Recall the origin line.",
          "prompt": "Type: I am from Mayo.",
          "answer": "Is as Maigh Eo mé.",
          "options": [
            { "id": "mayo", "text": "I am from Mayo.", "isCorrect": true, "rationale": "The frame places the speaker." }
          ],
          "tokens": [],
          "pairs": [],
          "feedback": "The frame is yours.",
          "hint": "Keep the frame.",
          "recovery": "Keep the order.",
          "lexemeIDs": ["lex.as"],
          "operatesOnSentence": true,
          "recognitionMultipleChoice": false
        }
        """
        return try JSONDecoder().decode(CountyExercise.self, from: Data(json.utf8))
    }

    // MARK: Backward-compatible decoding

    func testFlatExerciseDecodesWithoutAContract() throws {
        let exercise = try flatExercise(family: "freeTyping")

        XCTAssertNil(exercise.learningContract)
        XCTAssertNil(exercise.options.first?.misconceptionID)
        XCTAssertEqual(exercise.feedback, "The frame is yours.")
        XCTAssertEqual(exercise.lexemeIDs, ["lex.as"])
        XCTAssertEqual(exercise.resolvedContract(), CountyLearningContract.adapting(exercise: exercise))
    }

    // MARK: Deterministic adapter

    func testAdapterIsDeterministic() throws {
        let exercise = try flatExercise(family: "freeTyping")

        XCTAssertEqual(
            CountyLearningContract.adapting(exercise: exercise),
            CountyLearningContract.adapting(exercise: exercise)
        )
    }

    func testFlatFieldsBecomeTheFallbackDiagnostic() throws {
        let exercise = try flatExercise(family: "freeTyping")
        let contract = CountyLearningContract.adapting(exercise: exercise)

        XCTAssertEqual(contract.objective, exercise.objective)
        XCTAssertEqual(contract.successFeedback, exercise.feedback)
        XCTAssertEqual(contract.hint, exercise.hint)
        XCTAssertEqual(contract.recovery.guidance, exercise.recovery)
        XCTAssertFalse(contract.recovery.requiredResponse.isEmpty)
        XCTAssertEqual(contract.misconceptions.map(\.id), ["fallback"])
        XCTAssertEqual(contract.misconceptions.first?.feedback, exercise.feedback)
        XCTAssertEqual(contract.targets.map(\.id), exercise.lexemeIDs)
    }

    func testAdapterMapsFamilyToTargetCapability() throws {
        let cases: [(String, CountyTargetCapability)] = [
            ("listenChoose", .recognised),
            ("fillGap", .recognised),
            ("matching", .recognised),
            ("completion", .recognised),
            ("readRespond", .interpreted),
            ("grammarDiscovery", .interpreted),
            ("sentenceConstruction", .produced),
            ("conversation", .produced),
            ("freeTyping", .recalled),
            ("contextualReview", .recalled),
            ("recordCompare", .spokenForComparison),
        ]
        for (family, expected) in cases {
            let exercise = try flatExercise(family: family)
            XCTAssertEqual(
                CountyLearningContract.adapting(exercise: exercise).targets.map(\.capability),
                [expected],
                family
            )
        }
    }

    func testAdapterMapsFamilyAndUseToDeclaredEvidence() throws {
        let cases: [(String, CountyCompletionEvidence?)] = [
            ("listenChoose", .correctSelection),
            ("fillGap", .correctSelection),
            ("readRespond", .correctSelection),
            ("grammarDiscovery", .correctSelection),
            ("sentenceConstruction", .correctConstruction),
            ("freeTyping", .correctConstruction),
            ("matching", .reconstructedResponse),
            ("conversation", .validDialogueTurn),
            ("recordCompare", .completedRecordCompare),
            ("contextualReview", .correctSelection),
            ("completion", nil),
        ]
        for (family, expected) in cases {
            let exercise = try flatExercise(family: family)
            XCTAssertEqual(
                CountyLearningContract.adapting(exercise: exercise).completionEvidence,
                expected,
                family
            )
        }

        let ordering = try flatExercise(family: "sentenceConstruction", authoredUse: "ordering")
        XCTAssertEqual(
            CountyLearningContract.adapting(exercise: ordering).completionEvidence,
            .orderedSequence
        )
    }

    func testAdapterReadsTheResolvedReviewCandidate() throws {
        let container = try flatExercise(family: "contextualReview")
        let typedReentry = try flatExercise(family: "freeTyping")
        let candidate = CountyReviewCandidate(
            id: "origin-line",
            pageID: "mayo.clew-bay.type-origin",
            label: "the origin line",
            exercise: typedReentry
        )

        XCTAssertEqual(
            CountyLearningContract.adapting(exercise: container, reviewCandidate: candidate).completionEvidence,
            .correctedConstruction
        )
        XCTAssertEqual(
            CountyLearningContract.adapting(exercise: container, reviewCandidate: nil).completionEvidence,
            .correctSelection
        )
    }

    // MARK: Authored contract wins over the adapter

    func testAuthoredContractWinsOverTheAdapter() throws {
        let pack = try XCTUnwrap(CountyFreezeRunFixture.pack())
        let exercise = try XCTUnwrap(pack.page(id: "mayo.clew-bay.review-struggle")?.exercise)
        let authored = try XCTUnwrap(exercise.learningContract)

        XCTAssertEqual(exercise.resolvedContract(), authored)
        XCTAssertNotEqual(
            authored.completionEvidence,
            CountyLearningContract.adapting(exercise: exercise).completionEvidence,
            "The freeze review declares evidence its family-derived default would not"
        )
    }

    // MARK: Freeze fixture contracts

    func testFreezeFixtureDeclaresCompleteContractsOnAllNineSteps() throws {
        let pack = try XCTUnwrap(CountyFreezeRunFixture.pack())
        XCTAssertEqual(pack.pages(for: .learning).count, 9)

        for pageID in CountyFreezeRunFixture.stepPageIDs {
            let exercise = try XCTUnwrap(pack.page(id: pageID)?.exercise, pageID)
            let contract = try XCTUnwrap(exercise.learningContract, pageID)

            XCTAssertFalse(contract.objective.isEmpty, pageID)
            XCTAssertFalse(contract.targets.isEmpty, pageID)
            XCTAssertEqual(contract.targets.map(\.id), exercise.lexemeIDs, pageID)
            XCTAssertFalse(contract.successFeedback.isEmpty, pageID)
            XCTAssertFalse(contract.hint.isEmpty, pageID)
            XCTAssertFalse(contract.recovery.guidance.isEmpty, pageID)
            XCTAssertFalse(contract.recovery.requiredResponse.isEmpty, pageID)
            if exercise.family == .completion {
                XCTAssertNil(contract.completionEvidence, pageID)
            } else {
                XCTAssertNotNil(contract.completionEvidence, pageID)
                XCTAssertFalse(contract.misconceptions.isEmpty, pageID)
            }
        }
    }

    func testFreezeFixtureOptionMisconceptionsResolve() throws {
        let pack = try XCTUnwrap(CountyFreezeRunFixture.pack())

        for pageID in CountyFreezeRunFixture.stepPageIDs {
            let exercise = try XCTUnwrap(pack.page(id: pageID)?.exercise, pageID)
            let declared = Set(try XCTUnwrap(exercise.learningContract, pageID).misconceptions.map(\.id))
            for option in exercise.options {
                if option.isCorrect {
                    XCTAssertNil(option.misconceptionID, "\(pageID) option \(option.id)")
                } else {
                    let id = try XCTUnwrap(option.misconceptionID, "\(pageID) distractor \(option.id)")
                    XCTAssertTrue(declared.contains(id), "\(pageID) distractor \(option.id) names undeclared \(id)")
                }
            }
        }
    }

    // MARK: Declared evidence reaches the engine unchanged

    func testEngineReceivesDeclaredEvidenceUnchanged() throws {
        let pack = try XCTUnwrap(CountyFreezeRunFixture.pack())
        let exercise = try XCTUnwrap(pack.page(id: "mayo.clew-bay.review-struggle")?.exercise)
        let candidate = CountyContextualReviewTargeting.candidate(
            from: exercise.reviewCandidates ?? [],
            struggledPageIDs: []
        )
        XCTAssertEqual(candidate?.exercise.family, .listenChoose)
        XCTAssertEqual(
            CountyLearningContract.adapting(exercise: exercise, reviewCandidate: candidate).completionEvidence,
            .correctSelection,
            "The family-derived default for the resolved candidate is a selection"
        )

        let contract = exercise.resolvedContract(reviewCandidate: candidate)
        XCTAssertEqual(contract.completionEvidence, .correctedConstruction)

        var engine = CountyActivityStateEngine(
            exerciseID: "mayo.clew-bay.review-struggle",
            targetIDs: contract.targets.map(\.id),
            grading: .selectionTouch,
            completionEvidence: contract.completionEvidence
        )
        engine.updateResponse(CountyActivityResponse(.selection))
        engine.check(outcome: .correct, diagnosticShown: false)

        XCTAssertEqual(engine.attempts.first?.completionEvidence, .correctedConstruction)
    }
}
