import XCTest
@testable import AnTuras

final class InteractionStudyTests: XCTestCase {
    func testStudyCatalogKeepsThreeMateriallyDifferentDirections() {
        let studies = InteractionStudyID.allCases

        XCTAssertEqual(
            studies.map(\.rawValue),
            ["sound-match", "sentence-flow", "coast-placement"]
        )
        XCTAssertEqual(Set(studies.map(\.title)).count, studies.count)
        XCTAssertEqual(Set(studies.map(\.prompt)).count, studies.count)
        XCTAssertEqual(Set(studies.map(\.shortSummary)).count, studies.count)
    }

    func testNarrowStudyFixtureProjectsOnlyTheFrozenWordsAndPhrase() {
        XCTAssertEqual(
            ClewBayInteractionStudyFixture.words.map(\.irish),
            ClewBayLearningPrototypeFixture.coast.pairs.map(\.left)
        )
        XCTAssertEqual(
            ClewBayInteractionStudyFixture.words.map(\.english),
            ClewBayLearningPrototypeFixture.coast.pairs.map(\.right)
        )
        XCTAssertEqual(
            ClewBayInteractionStudyFixture.sentence,
            ClewBayLearningPrototypeFixture.origin.answer
        )
        XCTAssertEqual(
            ClewBayInteractionStudyFixture.sentenceTokens.map(\.text),
            ["Is", "as", "Maigh Eo", "mé."]
        )
        XCTAssertEqual(
            ClewBayInteractionStudyFixture.sentenceTokens.map(\.text).joined(separator: " "),
            ClewBayInteractionStudyFixture.sentence
        )
    }

    func testEachCoastWordOwnsOneDistinctSpatialRegion() {
        let words = ClewBayInteractionStudyFixture.words

        XCTAssertEqual(words.count, InteractionStudyCoastRegion.allCases.count)
        XCTAssertEqual(Set(words.map(\.id)).count, words.count)
        XCTAssertEqual(Set(words.map(\.region.rawValue)).count, words.count)
        XCTAssertEqual(
            words.map(\.region),
            [.openWater, .shelteredBay, .namedLand]
        )
    }
}
