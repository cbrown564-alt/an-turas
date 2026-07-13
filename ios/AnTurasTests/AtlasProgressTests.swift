import XCTest
@testable import AnTuras

final class AtlasProgressTests: XCTestCase {
    func testAtlasProgressRoundTripsThroughSavedState() throws {
        var saved = AppState.Saved()
        saved.atlasProgress = AppState.AtlasProgress(
            hasOpenedAtlas: false,
            evidenceInspected: true,
            storyCompleted: false,
            fieldNoteVisited: true,
            returnAnswered: false,
            storyInProgress: true,
            storyStep: 2,
            storyFoundName: true
        )

        let data = try JSONEncoder().encode(saved)
        let decoded = try JSONDecoder().decode(AppState.Saved.self, from: data)

        XCTAssertEqual(decoded.atlasProgress, saved.atlasProgress)
    }

    func testOlderSavedStateDefaultsAtlasProgress() throws {
        let decoded = try JSONDecoder().decode(
            AppState.Saved.self,
            from: Data("{}".utf8)
        )

        XCTAssertEqual(decoded.atlasProgress, AppState.AtlasProgress())
    }

    @MainActor
    func testAtlasModelRestoresAndClampsStoryStep() {
        let model = AtlasPrototypeModel()
        model.restore(
            AppState.AtlasProgress(
                storyInProgress: true,
                storyStep: 99,
                storyFoundName: true
            )
        )

        XCTAssertTrue(model.storyInProgress)
        XCTAssertEqual(model.storyStep, 17)
        XCTAssertTrue(model.storyFoundName)
    }

    @MainActor
    func testFourStepEncounterMigratesIntoEpisodeFour() {
        let model = AtlasPrototypeModel()
        model.restore(
            AppState.AtlasProgress(
                storyInProgress: true,
                storyStep: 2,
                storyFoundName: true,
                storyArcVersion: 1
            )
        )

        XCTAssertEqual(model.storyStep, 11)
        XCTAssertTrue(model.storyFoundName)
    }

    @MainActor
    func testSixEpisodeProgressFiltersInvalidAndDuplicateBeats() {
        let model = AtlasPrototypeModel()
        model.restore(
            AppState.AtlasProgress(
                storyInProgress: true,
                storyStep: 14,
                storyArcVersion: 2,
                completedStoryBeats: [0, 2, 2, 14, 18, -1]
            )
        )

        XCTAssertEqual(model.storyStep, 14)
        XCTAssertEqual(model.completedStoryBeats, [0, 2, 14])
    }

    @MainActor
    func testCompletingStoryPreservesVoyageProgressForRevisit() {
        let model = AtlasPrototypeModel()
        model.storyInProgress = true
        model.storyStep = 17
        model.storyFoundName = true
        model.completedStoryBeats = [2, 5, 8, 11, 14, 17]

        model.completeStory()

        XCTAssertTrue(model.storyCompleted)
        XCTAssertFalse(model.storyInProgress)
        XCTAssertEqual(model.storyStep, 17)
        XCTAssertTrue(model.storyFoundName)
        XCTAssertEqual(model.completedStoryBeats, [2, 5, 8, 11, 14, 17])
    }
}
