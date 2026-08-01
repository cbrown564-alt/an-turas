import XCTest

/// D30 phrase-family B: hear ship-on-sea, build sea-here on the shared shell.
/// Captures cold / wrong / complete craft evidence under
/// `tmp/exercise-screenshots/farraige-family-b-2026-08-01/`.
final class FarraigeFamilyBUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private var shotsFolder: URL {
        let folder = URL(fileURLWithPath: "/Users/cobro/code/irish/tmp/exercise-screenshots/farraige-family-b-2026-08-01")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private func shot(_ name: String) {
        Thread.sleep(forTimeInterval: 0.5)
        let data = XCUIScreen.main.screenshot().pngRepresentation
        try? data.write(to: shotsFolder.appendingPathComponent("\(name).png"))
    }

    private func launch(_ args: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--farraige-family-b",
            "--fresh-county-pack",
            "--transient-test-state",
            "--page", "mayo.farraige-family.build-sea-here",
        ] + args
        app.launch()
        return app
    }

    private func tapButton(_ label: String, in app: XCUIApplication) {
        let button = app.buttons[label]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing button: \(label)")
        for _ in 0..<10 where !button.isHittable { app.swipeUp() }
        if button.isHittable {
            button.tap()
        } else {
            button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    private func tapCheckWhenReady(in app: XCUIApplication) {
        let button = app.buttons["Check the order"]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing Check the order")
        let enabled = NSPredicate(format: "enabled == true")
        XCTAssertEqual(
            XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: enabled, object: button)], timeout: 8),
            .completed,
            "Check never enabled"
        )
        for _ in 0..<7 where !button.isHittable { app.swipeUp() }
        button.tap()
    }

    private func hearShipLine(in app: XCUIApplication) {
        let listen = app.buttons["Listen"]
        let replay = app.buttons["Listen again"]
        if listen.waitForExistence(timeout: 3) {
            listen.tap()
        } else if replay.waitForExistence(timeout: 2) {
            // Already heard on a prior attempt in this launch.
            return
        } else {
            XCTFail("Missing Listen control for ship-on-sea audio")
        }
        // Allow the played callback to unblock Check readiness.
        Thread.sleep(forTimeInterval: 0.8)
    }

    func testSurroundChangeWalksWrongThenComplete() throws {
        let app = launch(["--appearance", "light"])
        XCTAssertTrue(app.staticTexts["Keep farraige"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["The sea is here."].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Listen"].waitForExistence(timeout: 3))
        shot("01-build-cold")

        // Check stays disabled until the ship line is heard (audio-first gate).
        let check = app.buttons["Check the order"]
        XCTAssertTrue(check.waitForExistence(timeout: 3))
        for token in ["anseo.", "Tá", "an", "fharraige"] { tapButton(token, in: app) }
        XCTAssertFalse(check.isEnabled, "Check must stay disabled until Listen plays")
        hearShipLine(in: app)
        shot("01-build-filled")
        tapCheckWhenReady(in: app)
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Not quite'")).firstMatch
                .waitForExistence(timeout: 3)
        )
        shot("01-build-wrong")

        // Repair in place: return three tiles, rebuild correct order.
        for token in ["anseo.", "an", "fharraige"] { tapButton(token, in: app) }
        for token in ["an", "fharraige", "anseo."] { tapButton(token, in: app) }
        tapCheckWhenReady(in: app)
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Complete'")).firstMatch
                .waitForExistence(timeout: 3)
        )
        XCTAssertFalse(
            app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Not quite'")).firstMatch.exists
        )
        shot("01-build-complete")
    }

    func testSurroundChangeColdDarkAndLargestType() throws {
        let dark = launch(["--appearance", "dark"])
        XCTAssertTrue(dark.buttons["Listen"].waitForExistence(timeout: 5))
        shot("01-build-cold-dark")

        let a11y = launch([
            "--appearance", "light",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
        ])
        XCTAssertTrue(a11y.buttons["Listen"].waitForExistence(timeout: 5))
        XCTAssertTrue(a11y.staticTexts["Keep farraige"].waitForExistence(timeout: 3))
        shot("01-build-cold-a11y")
    }
}
