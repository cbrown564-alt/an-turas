import XCTest

/// Rebuild plan step 4: the shared activity shell owns interruption, recovery,
/// announcements, and focus. These tests prove the two engine paths the shell
/// newly wires — `interrupt()` closing an open D27 repair window as an
/// unrepaired struggle (picked up by the C3 contextual review), and
/// `beginRecovery()` restructuring a failed explicit Check into a fresh
/// response — without touching the frozen nine-step sequence.
final class CountyActivityShellUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: interrupt(): leaving with the repair window open signals struggle

    func testInterruptWithOpenRepairWindowFeedsTheContextualReview() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--freeze-run",
            "--fresh-county-pack",
            "--transient-test-state",
        ]
        app.launch()

        // Step 1 — one wrong selection opens the D27 repair window without
        // escalating the panel.
        XCTAssertTrue(app.staticTexts["Tap what you hear"].waitForExistence(timeout: 5))
        tapChoice("island", in: app)
        XCTAssertTrue(app.staticTexts["That names the land in the water, not the water itself."].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Not quite"].exists)

        // Leave mid-window: the page dismantle calls engine.interrupt(), which
        // closes the window as an unrepaired struggle on the run's record.
        jumpToPage("Tap the matching pairs", in: app)
        XCTAssertTrue(app.staticTexts["Tap the matching pairs"].waitForExistence(timeout: 5))

        // Return and answer cleanly; the struggle record must survive.
        jumpToPage("Tap what you hear", in: app)
        XCTAssertTrue(app.staticTexts["Tap what you hear"].waitForExistence(timeout: 5))
        tapChoice("sea", in: app)
        finishExercise(in: app)

        // Step 9 — C3: the interrupted step's struggle selects the sea word.
        jumpToPage("Return to what slipped", in: app)
        XCTAssertTrue(app.staticTexts["Return to what slipped"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.staticTexts["the sea word slipped — meet it again from the original sound."].waitForExistence(timeout: 3),
            "The interrupt-emitted struggle must target the contextual review"
        )
        tapChoice("sea", in: app)
        let completeButton = app.buttons["Complete this chapter path"]
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: completeButton)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 5), .completed)
    }

    // MARK: beginRecovery(): a failed Check restructures, then requires a fresh response

    func testRecoveryRestructuresAndRequiresAFreshResponse() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--freeze-run",
            "--fresh-county-pack",
            "--transient-test-state",
            "--page", "mayo.clew-bay.type-origin",
        ]
        app.launch()

        // Step 4 — free typing with an explicit Check. A fada-less line fails.
        XCTAssertTrue(app.staticTexts["Type the sentence"].waitForExistence(timeout: 5))
        _ = irishAnswerField(in: app)
        app.typeText("Is as Maigh Eo me.")
        tapButton("Check the sentence", in: app)
        XCTAssertTrue(app.staticTexts["Not quite"].waitForExistence(timeout: 2))

        // The shell's recovery affordance restructures the same objective.
        let recovery = app.buttons["exercise-recovery-button"]
        XCTAssertTrue(recovery.waitForExistence(timeout: 3), "The escalated panel must offer recovery")
        recovery.tap()
        let steadier = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "A steadier step")).firstMatch
        XCTAssertTrue(steadier.waitForExistence(timeout: 3), "Recovery must show its own panel state")

        // Recovery never completes by itself: the learner repairs the text and
        // Checks again (engine: recovery → retry → attempt → complete).
        let field = irishAnswerField(in: app)
        // The recovery tap re-raises the keyboard; anchor the cursor at the
        // end of the kept text so the repair edits the tail.
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
        app.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3))
        app.typeText("m")
        tapButton("Insert é from keyboard toolbar", in: app)
        app.typeText(".")
        tapButton("Check the sentence", in: app)

        let complete = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Complete")).firstMatch
        XCTAssertTrue(complete.waitForExistence(timeout: 3), "A fresh correct response after recovery completes")
        finishExercise(in: app)
        XCTAssertTrue(app.staticTexts["Meeting on the shore"].waitForExistence(timeout: 5), "Continue advances to the next step")
    }

    // MARK: Recovery at the largest Dynamic Type keeps the field reachable (D9)

    func testRecoveryKeepsTheAnswerFieldReachableAtLargestText() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--freeze-run",
            "--fresh-county-pack",
            "--transient-test-state",
            "--page", "mayo.clew-bay.type-origin",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Type the sentence"].waitForExistence(timeout: 5))
        _ = irishAnswerField(in: app)
        app.typeText("Is as Maigh Eo me.")
        tapButton("Check the sentence", in: app)
        XCTAssertTrue(app.staticTexts["Not quite"].waitForExistence(timeout: 2))

        let recovery = app.buttons["exercise-recovery-button"]
        XCTAssertTrue(recovery.waitForExistence(timeout: 3), "The escalated panel must offer recovery")
        recovery.tap()
        let steadier = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "A steadier step")).firstMatch
        XCTAssertTrue(steadier.waitForExistence(timeout: 3), "Recovery must show its own panel state")

        // The keyboard yields on recovery, so the field keeps a valid frame in
        // the recomposed scroll view and scrolls back into reach.
        let field = app.textFields["irish-answer-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        for _ in 0..<6 where !field.isHittable { app.swipeUp() }
        XCTAssertTrue(field.isHittable, "The answer field stays reachable after recovery at the largest text size")
    }

    // MARK: Helpers

    private func jumpToPage(
        _ title: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let menu = app.buttons["Chapter menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 5), "Missing chapter menu", file: file, line: line)
        menu.tap()
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", title)).firstMatch
        // The chapter list materializes rows lazily: below-fold rows are absent
        // from the accessibility tree until the menu is scrolled to them.
        let list = app.collectionViews.firstMatch
        for _ in 0..<12 where !row.exists {
            list.swipeUp()
        }
        XCTAssertTrue(row.waitForExistence(timeout: 2), "Missing chapter row: \(title)", file: file, line: line)
        row.tap()
    }

    private func tapChoice(
        _ label: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let choice = app.buttons[label]
        XCTAssertTrue(choice.waitForExistence(timeout: 5), "Missing choice: \(label)", file: file, line: line)
        let hittable = NSPredicate(format: "hittable == true")
        XCTAssertEqual(
            XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: hittable, object: choice)], timeout: 5),
            .completed,
            "Choice never hittable: \(label)",
            file: file,
            line: line
        )
        choice.tap()
    }

    private func tapButton(
        _ label: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let button = app.buttons[label]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing button: \(label)", file: file, line: line)
        for _ in 0..<7 where !button.isHittable { app.swipeUp() }
        XCTAssertTrue(button.isHittable, "Button is not hittable: \(label)", file: file, line: line)
        button.tap()
    }

    private func finishExercise(
        in app: XCUIApplication,
        continueLabel: String = "Continue",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let button = app.buttons[continueLabel]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing exercise action: \(continueLabel)", file: file, line: line)
        let enabled = NSPredicate(format: "enabled == true")
        XCTAssertEqual(
            XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: enabled, object: button)], timeout: 5),
            .completed,
            "Exercise action never enabled: \(continueLabel)",
            file: file,
            line: line
        )
        button.tap()
    }

    @discardableResult
    private func irishAnswerField(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let field = app.textFields["irish-answer-field"]
        let area = app.textViews["irish-answer-field"]
        let match = field.waitForExistence(timeout: 2) ? field : area
        XCTAssertTrue(match.waitForExistence(timeout: 5), "Missing Irish answer field", file: file, line: line)
        match.tap()
        return match
    }
}
