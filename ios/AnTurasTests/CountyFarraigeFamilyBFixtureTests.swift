import XCTest
@testable import AnTuras

final class CountyFarraigeFamilyBFixtureTests: XCTestCase {
    func testFixtureLoadsWithSurroundChangeConstruction() throws {
        let pack = try XCTUnwrap(CountyFarraigeFamilyBFixture.pack())
        XCTAssertEqual(pack.id, "mayo.farraige-family-b")
        XCTAssertEqual(pack.scope, .editorialPreview)
        XCTAssertEqual(CountyFarraigeFamilyBFixture.stepPageIDs.count, 2)

        let build = try XCTUnwrap(pack.page(id: "mayo.farraige-family.build-sea-here")?.exercise)
        XCTAssertEqual(build.family, .sentenceConstruction)
        XCTAssertEqual(build.audioText, "Tá an long ar an bhfarraige.")
        XCTAssertEqual(build.answer, "Tá an fharraige anseo.")
        XCTAssertNotEqual(build.audioText, build.answer)
        XCTAssertEqual(build.lexemeIDs, ["lex.farraige"])
        XCTAssertEqual(build.tokens, ["Tá", "an", "fharraige", "anseo."])
        XCTAssertEqual(build.learningContract?.completionEvidence, .correctConstruction)
    }

    func testHeardAndBuiltMembersAreDistinctFamilyUtterances() throws {
        let pack = try XCTUnwrap(CountyFarraigeFamilyBFixture.pack())
        let build = try XCTUnwrap(pack.page(id: "mayo.farraige-family.build-sea-here")?.exercise)
        let heard = try XCTUnwrap(build.audioText)
        let built = build.answer
        XCTAssertTrue(heard.localizedCaseInsensitiveContains("farraige")
            || heard.localizedCaseInsensitiveContains("bhfarraige"))
        XCTAssertTrue(built.localizedCaseInsensitiveContains("fharraige"))
        XCTAssertFalse(heard.caseInsensitiveCompare(built) == .orderedSame)
    }
}
