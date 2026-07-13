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
        XCTAssertEqual(model.storyStep, 3)
        XCTAssertTrue(model.storyFoundName)
    }
}
