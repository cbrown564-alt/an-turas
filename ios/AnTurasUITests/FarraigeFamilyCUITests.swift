import XCTest

/// D30 phrase-family C: build sea-here → bay delay → type where-sea.
/// Captures delayed-typing craft under
/// `tmp/exercise-screenshots/farraige-family-c-2026-08-01/`.
final class FarraigeFamilyCUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private var shotsFolder: URL {
        let folder = URL(fileURLWithPath: "/Users/cobro/code/irish/tmp/exercise-screenshots/farraige-family-c-2026-08-01")
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
            "--farraige-family-c",
            "--fresh-county-pack",
            "--transient-test-state",
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

    private func tapCheckWhenReady(_ label: String, in app: XCUIApplication) {
        let button = app.buttons[label]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing check: \(label)")
        let enabled = NSPredicate(format: "enabled == true")
        XCTAssertEqual(
            XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: enabled, object: button)], timeout: 8),
            .completed,
            "Check never enabled: \(label)"
        )
        for _ in 0..<7 where !button.isHittable { app.swipeUp() }
        button.tap()
    }

    private func irishAnswerField(in app: XCUIApplication) -> XCUIElement {
        let field = app.textFields["irish-answer-field"]
        let area = app.textViews["irish-answer-field"]
        let match = field.waitForExistence(timeout: 2) ? field : area
        XCTAssertTrue(match.waitForExistence(timeout: 5), "Missing irish-answer-field")
        match.tap()
        return match
    }

    private func finishExercise(in app: XCUIApplication) {
        let complete = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Complete'")).firstMatch
        let continueBtn = app.buttons["Continue"]
        if complete.waitForExistence(timeout: 3) {
            complete.tap()
        } else if continueBtn.waitForExistence(timeout: 2) {
            continueBtn.tap()
        }
    }

    func testDelayedReuseWalksEncounterDelayAndTyping() throws {
        let app = launch([
            "--appearance", "light",
            "--page", "mayo.farraige-family-c.encounter-sea-here",
        ])
        XCTAssertTrue(app.staticTexts["Keep farraige"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["The sea is here."].waitForExistence(timeout: 3))
        shot("01-encounter-cold")

        for token in ["Tá", "an", "fharraige", "anseo."] { tapButton(token, in: app) }
        tapCheckWhenReady("Check the order", in: app)
        finishExercise(in: app)

        XCTAssertTrue(app.staticTexts["The bay holds the question"].waitForExistence(timeout: 5))
        shot("02-bay-delay")
        tapButton("Ask for the sea", in: app)

        XCTAssertTrue(app.staticTexts["Type the question"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Where is the sea?"].waitForExistence(timeout: 3))
        shot("03-type-cold")

        _ = irishAnswerField(in: app)
        // Wrong: replay the earlier location line (surround change residual).
        app.typeText("Ta an fharraige anseo.")
        shot("03-type-filled-wrong")
        tapButton("Check the sentence", in: app)
        XCTAssertTrue(app.staticTexts["Not quite"].waitForExistence(timeout: 3))
        shot("03-type-wrong")

        app.buttons["exercise-recovery-button"].tap()
        let field = irishAnswerField(in: app)
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
        app.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 40))
        app.typeText("C")
        tapButton("Insert á from keyboard toolbar", in: app)
        app.typeText(" bhfuil an fharraige?")
        tapButton("Check the sentence", in: app)
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Complete'")).firstMatch
                .waitForExistence(timeout: 3)
        )
        app.swipeDown()
        shot("03-type-complete")
    }

    func testDelayedTypingColdDark() throws {
        let app = launch([
            "--appearance", "dark",
            "--page", "mayo.farraige-family-c.delayed-where-sea",
        ])
        XCTAssertTrue(app.staticTexts["Type the question"].waitForExistence(timeout: 5))
        shot("03-type-cold-dark")
    }
}
