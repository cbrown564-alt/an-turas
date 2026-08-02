import XCTest
@testable import AnTuras

final class CountyLearnerMemoryTests: XCTestCase {
    func testRecordsEachKindOncePerExercise() {
        var events: [CountyPersistedMemoryEvent] = []
        var flags: [String: CountyTargetMemoryFlags] = [:]
        let event = CountyMemoryEvent(kind: .hint, exerciseID: "ex.1", targetIDs: ["lex.farraige"])

        XCTAssertTrue(CountyLearnerMemory.record(event, packID: "mayo.demo", into: &events, flags: &flags))
        XCTAssertFalse(CountyLearnerMemory.record(event, packID: "mayo.demo", into: &events, flags: &flags))
        XCTAssertEqual(events.count, 1)
        XCTAssertTrue(flags["mayo.demo|lex.farraige"]?.hint == true)
    }

    func testCleanSuccessSeedIsDebtFreeAndExplainable() {
        var flags = CountyTargetMemoryFlags()
        flags.success = true
        let seed = CountyLearnerMemory.reviewSeed(from: flags)
        XCTAssertGreaterThanOrEqual(seed.intervalDays, 1)
        XCTAssertTrue(seed.explanation.contains("clean success"))
        XCTAssertFalse(seed.explanation.contains("overdue"))
    }

    func testStruggleRaisesDifficultyWithoutPastDue() {
        var flags = CountyTargetMemoryFlags()
        flags.struggle = true
        flags.success = true
        let seed = CountyLearnerMemory.reviewSeed(from: flags)
        XCTAssertEqual(seed.intervalDays, 1)
        XCTAssertGreaterThan(seed.difficulty, 5)
        XCTAssertTrue(seed.explanation.contains("struggle"))
    }

    func testHintedCompletionIsSofterThanCleanSuccess() {
        var clean = CountyTargetMemoryFlags(); clean.success = true
        var hinted = CountyTargetMemoryFlags(); hinted.success = true; hinted.hint = true
        let cleanSeed = CountyLearnerMemory.reviewSeed(from: clean)
        let hintedSeed = CountyLearnerMemory.reviewSeed(from: hinted)
        XCTAssertGreaterThan(cleanSeed.stability, hintedSeed.stability)
        XCTAssertTrue(hintedSeed.explanation.contains("hinted"))
    }

    func testMatchesHeadwordThroughFadaFoldedLexemeStem() {
        var flags: [String: CountyTargetMemoryFlags] = [
            "mayo.demo|lex.caislean": CountyTargetMemoryFlags(success: true, struggle: false, hint: false, recovery: false),
        ]
        let word = AtlasWord(ga: "caisleán", en: "castle", sound: "", anchor: "")
        let matched = CountyLearnerMemory.flags(for: word, packID: "mayo.demo", in: flags)
        XCTAssertTrue(matched.success)
    }

    @MainActor
    func testMemoryEventsSurviveProgressJSONAndSeedReviews() throws {
        let pack = try XCTUnwrap(CountyFreezeRunFixture.pack())
        let model = AtlasPrototypeModel()
        model.recordMemoryEvent(
            CountyMemoryEvent(kind: .struggle, exerciseID: "mayo.clew-bay.listen-farraige", targetIDs: ["lex.farraige"]),
            in: pack
        )
        model.recordMemoryEvent(
            CountyMemoryEvent(kind: .success, exerciseID: "mayo.clew-bay.listen-farraige", targetIDs: ["lex.farraige"]),
            in: pack
        )

        let data = try JSONEncoder().encode(model.progressSnapshot)
        let decoded = try JSONDecoder().decode(AppState.AtlasProgress.self, from: data)
        XCTAssertEqual(decoded.countyMemoryEvents.count, 2)
        XCTAssertTrue(decoded.countyTargetMemory["mayo.clew-bay-freeze|lex.farraige"]?.struggle == true)

        // Older saves without memory keys still decode.
        let legacy = #"{"hasOpenedAtlas":true}"#.data(using: .utf8)!
        let legacyProgress = try JSONDecoder().decode(AppState.AtlasProgress.self, from: legacy)
        XCTAssertTrue(legacyProgress.countyMemoryEvents.isEmpty)
        XCTAssertTrue(legacyProgress.countyTargetMemory.isEmpty)

        model.restore(decoded)
        // Fixture packs must not award scheduled reviews via finish(); seed path is unit-checked here.
        let seed = CountyLearnerMemory.reviewSeed(
            from: CountyLearnerMemory.flags(
                for: AtlasWord(ga: "farraige", en: "sea", sound: "", anchor: ""),
                packID: pack.id,
                in: Dictionary(uniqueKeysWithValues: model.targetMemoryFlags(for: pack).map { ($0.key, $0.value) })
            )
        )
        XCTAssertEqual(seed.intervalDays, 1)
        XCTAssertTrue(model.struggledPageIDs(in: pack).contains("mayo.clew-bay.listen-farraige"))
        XCTAssertEqual(model.memoryEvents(for: pack).count, 2)
    }
}
