import XCTest
@testable import AnTuras

final class CountyFarraigeFamilyCFixtureTests: XCTestCase {
    func testFixtureLoadsWithDelayedReuseTyping() throws {
        let pack = try XCTUnwrap(CountyFarraigeFamilyCFixture.pack())
        XCTAssertEqual(pack.id, "mayo.farraige-family-c")
        XCTAssertEqual(pack.scope, .editorialPreview)
        XCTAssertEqual(CountyFarraigeFamilyCFixture.stepPageIDs.count, 3)

        let encounter = try XCTUnwrap(pack.page(id: CountyFarraigeFamilyCFixture.encounterPageID)?.exercise)
        XCTAssertEqual(encounter.family, .sentenceConstruction)
        XCTAssertEqual(encounter.answer, "Tá an fharraige anseo.")

        let delay = try XCTUnwrap(pack.page(id: "mayo.farraige-family-c.bay-delay"))
        XCTAssertEqual(delay.kind, .narrative)
        XCTAssertNil(delay.exercise)

        let delayed = try XCTUnwrap(pack.page(id: CountyFarraigeFamilyCFixture.delayedPageID)?.exercise)
        XCTAssertEqual(delayed.family, .freeTyping)
        XCTAssertEqual(delayed.authoredUse, "delayedRecall")
        XCTAssertEqual(delayed.answer, "Cá bhfuil an fharraige?")
        XCTAssertEqual(delayed.lexemeIDs, ["lex.farraige"])
        XCTAssertNil(delayed.audioText)
        XCTAssertEqual(delayed.learningContract?.completionEvidence, .correctConstruction)
    }

    func testDelayedMemberDiffersFromEncounterMember() throws {
        let pack = try XCTUnwrap(CountyFarraigeFamilyCFixture.pack())
        let encounter = try XCTUnwrap(pack.page(id: CountyFarraigeFamilyCFixture.encounterPageID)?.exercise)
        let delayed = try XCTUnwrap(pack.page(id: CountyFarraigeFamilyCFixture.delayedPageID)?.exercise)
        XCTAssertNotEqual(encounter.answer, delayed.answer)
        XCTAssertTrue(encounter.answer.localizedCaseInsensitiveContains("fharraige"))
        XCTAssertTrue(delayed.answer.localizedCaseInsensitiveContains("fharraige"))
        XCTAssertTrue(delayed.answer.hasPrefix("Cá") || delayed.answer.hasPrefix("Ca"))
    }

    func testLearningPathOrdersEncounterThenDelayThenReuse() throws {
        let pack = try XCTUnwrap(CountyFarraigeFamilyCFixture.pack())
        let learningIDs = pack.pages(for: .learning).map(\.id)
        XCTAssertEqual(learningIDs, CountyFarraigeFamilyCFixture.stepPageIDs)
        let encounterIndex = try XCTUnwrap(learningIDs.firstIndex(of: CountyFarraigeFamilyCFixture.encounterPageID))
        let delayIndex = try XCTUnwrap(learningIDs.firstIndex(of: "mayo.farraige-family-c.bay-delay"))
        let reuseIndex = try XCTUnwrap(learningIDs.firstIndex(of: CountyFarraigeFamilyCFixture.delayedPageID))
        XCTAssertLessThan(encounterIndex, delayIndex)
        XCTAssertLessThan(delayIndex, reuseIndex)
    }
}
