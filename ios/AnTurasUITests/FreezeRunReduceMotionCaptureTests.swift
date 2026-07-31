import XCTest

/// Reduce Motion craft evidence for the freeze run: state changes must
/// communicate without custom movement (D8). Run with the simulator's
/// Reduce Motion accessibility setting enabled.
final class FreezeRunReduceMotionCaptureTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private var shotsFolder: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folder = docs.appendingPathComponent("freeze-shots", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private func shot(_ name: String, from app: XCUIApplication) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        try? data.write(to: shotsFolder.appendingPathComponent("\(name).png"))
    }

    private func tapReply(_ prefix: String, in app: XCUIApplication) {
        let reply = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
        guard reply.waitForExistence(timeout: 5) else { return }
        let barTop = app.frame.maxY - 130
        for _ in 0..<6 where reply.frame.maxY > barTop { app.swipeUp() }
        reply.tap()
    }

    func testCaptureReduceMotionStates() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--freeze-run",
            "--fresh-county-pack",
            "--transient-test-state",
            "--page", "mayo.clew-bay.conversation-origin",
        ]
        app.launch()
        XCTAssertTrue(app.staticTexts["Meeting on the shore"].waitForExistence(timeout: 5))

        tapReply("Is as Maigh Eo mé.", in: app)
        XCTAssertTrue(app.staticTexts["Cén t-ainm atá ort?"].waitForExistence(timeout: 2))
        shot("05-conversation-turn-two-reduce-motion", from: app)

        let match = XCUIApplication()
        match.launchArguments = [
            "--freeze-run",
            "--fresh-county-pack",
            "--transient-test-state",
            "--page", "mayo.clew-bay.match-coast",
        ]
        match.launch()
        XCTAssertTrue(match.staticTexts["Keep the coast's words distinct"].waitForExistence(timeout: 5))
        let word = match.buttons["farraige"]
        XCTAssertTrue(word.waitForExistence(timeout: 3))
        word.tap()
        let meaning = match.buttons["sea"]
        meaning.tap()
        shot("02-match-pair-locked-reduce-motion", from: match)
    }
}
