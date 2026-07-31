import XCTest

/// D29 freeze: the nine-step Clew Bay Learning run through the shared county
/// shell. Covers wrong→repair→complete on the changed families, the C1 branch
/// and exact resume, the mic-denied escape, C5 fixture isolation, and C3
/// deterministic targeting.
final class FreezeRunUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: Full nine-step walk with deliberate wrongs and in-place repairs

    func testFreezeRunWalksAllNineStepsWithRepairsInPlace() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--freeze-run",
            "--fresh-county-pack",
            "--transient-test-state",
            "--microphone-denied",
            "--appearance", "light",
        ]
        app.launch()

        // Step 1 — F1 listen and choose: answerable cold open, repair window,
        // struggle on the second wrong, next-touch repair (D1/D3/F1).
        XCTAssertTrue(app.staticTexts["Tap what you hear"].waitForExistence(timeout: 5))
        tapChoice("island", in: app)
        XCTAssertTrue(app.staticTexts["That's land, not water."].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Not quite"].exists)
        tapChoice("castle", in: app)
        XCTAssertTrue(app.staticTexts["Not quite"].waitForExistence(timeout: 2))
        tapChoice("sea", in: app)
        finishExercise(in: app)

        // Step 2 — F5 matching: a wrong pair keeps a brief on-target note and
        // the next tap repairs; never a board lock (D3/D5/F5).
        XCTAssertTrue(app.staticTexts["Tap the matching pairs"].waitForExistence(timeout: 5))
        tapButton("farraige", in: app)
        tapButton("bay", in: app)
        XCTAssertTrue(app.staticTexts["Not a match."].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Not quite"].exists)
        tapButton("sea", in: app)
        XCTAssertFalse(app.staticTexts["Not a match."].exists)
        tapButton("bá", in: app)
        tapButton("bay", in: app)
        tapButton("áit", in: app)
        tapButton("place", in: app)
        finishExercise(in: app)

        // Step 3 — F2 construction: explicit Check; wrong units stay editable
        // and correct work survives (F2/D3).
        XCTAssertTrue(app.staticTexts["Build the sentence"].waitForExistence(timeout: 5))
        for token in ["as", "Is", "Maigh Eo", "mé."] { tapButton(token, in: app) }
        tapButton("Check the order", in: app)
        XCTAssertTrue(app.staticTexts["Not quite"].waitForExistence(timeout: 2))
        for token in ["as", "Maigh Eo", "mé."] { tapButton(token, in: app) }
        for token in ["as", "Maigh Eo", "mé."] { tapButton(token, in: app) }
        tapButton("Check the order", in: app)
        finishExercise(in: app)

        // Step 4 — F3 unsupported typing: fada aids present; a failed Check
        // keeps the text; repair in place (F3/D3/D6). The bottom-bar Check
        // keeps field focus, so the cursor stays at the end for the repair.
        XCTAssertTrue(app.staticTexts["Type the sentence"].waitForExistence(timeout: 5))
        _ = irishAnswerField(in: app)
        app.typeText("Is as Maigh Eo me.")
        tapButton("Check the sentence", in: app)
        XCTAssertTrue(app.staticTexts["Not quite"].waitForExistence(timeout: 2))
        app.buttons["exercise-recovery-button"].tap()
        let field = irishAnswerField(in: app)
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
        app.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3))
        app.typeText("m")
        tapButton("Insert é from keyboard toolbar", in: app)
        app.typeText(".")
        tapButton("Check the sentence", in: app)
        finishExercise(in: app)

        // Step 5 — C1 conversation: a mismatched turn carries its diagnostic
        // and never advances; the branch changes a later partner line (C1/D3).
        XCTAssertTrue(app.staticTexts["Meeting on the shore"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Cárb as tú?"].exists)
        tapReply(beginning: "Slán go fóill.", in: app)
        XCTAssertTrue(app.staticTexts["That says goodbye, and the conversation has only begun. Answer the question instead."].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Cárb as tú?"].exists, "The mismatched turn must not advance the graph")
        tapReply(beginning: "Is as Maigh Eo mé.", in: app)
        XCTAssertTrue(app.staticTexts["Cén t-ainm atá ort?"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["You said: Is as Maigh Eo mé."].exists)
        tapReply(beginning: "Cé thusa?", in: app)
        XCTAssertTrue(app.staticTexts["Is as Maigh Eo mé."].waitForExistence(timeout: 2), "Asking back must change the partner's next line")
        tapReply(beginning: "Slán go fóill.", in: app)
        finishExercise(in: app)

        // Step 6 — F7 record and compare with the microphone denied: the
        // escape becomes the primary and never traps progress (D7/F7).
        XCTAssertTrue(app.staticTexts["Say the line"].waitForExistence(timeout: 5))
        for _ in 0..<4 where !app.staticTexts["Microphone access is off."].exists { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["Microphone access is off."].exists)
        waitForPrimaryBar("Continue", in: app).tap()
        finishExercise(in: app)

        // Step 7 — F6 read or listen and respond: the Irish line and listen
        // control are on screen (F6).
        XCTAssertTrue(app.staticTexts["Choose what it means"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Is as Maigh Eo mé."].exists)
        XCTAssertTrue(app.buttons["Listen"].exists)
        tapChoice("I am from Mayo.", in: app)
        finishExercise(in: app)

        // Step 8 — C5 completion: capabilities and the fixture collection
        // handoff, no points theatre (C5/D10).
        XCTAssertTrue(app.staticTexts["What you can now do"].waitForExistence(timeout: 5))
        assertText(containing: "You can hear farraige as the sea.", in: app)
        assertText(containing: "You can keep farraige, bá and áit distinct.", in: app)
        assertText(containing: "You can say where you are from.", in: app)
        app.swipeUp()
        for word in ["farraige", "bá", "áit", "as"] {
            let row = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", word)).firstMatch
            XCTAssertTrue(row.waitForExistence(timeout: 3), "Missing collected word row: \(word)")
        }
        XCTAssertTrue(app.staticTexts["Words you carry from this run"].exists)
        assertText(containing: "fixture collection only — no county gold", in: app)
        finishExercise(in: app)

        // Step 9 — C3 contextual review: the step-1 struggle selects the sea
        // word, re-entered from its original sound (C3).
        XCTAssertTrue(app.staticTexts["Quick review"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Listen"].exists)
        tapChoice("sea", in: app)
        finishExercise(in: app, continueLabel: "Complete this chapter path")

        // The run closes on the fixture boundary — no county effects (D29).
        XCTAssertTrue(app.staticTexts["Clew Bay fixture run complete"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["The words sit in a fixture collection; this run awards no county gold, made objects or scheduled words."].exists)
    }

    // MARK: C1 branch + exact resume after backgrounding

    func testFreezeRunConversationBranchesAndResumesAtTheExactNode() throws {
        let first = XCUIApplication()
        first.launchArguments = [
            "--freeze-run",
            "--fresh-county-pack",
            "--page", "mayo.clew-bay.conversation-origin",
        ]
        first.launch()

        XCTAssertTrue(first.staticTexts["Meeting on the shore"].waitForExistence(timeout: 5))
        tapReply(beginning: "Is as Maigh Eo mé.", in: first)
        XCTAssertTrue(first.staticTexts["Cén t-ainm atá ort?"].waitForExistence(timeout: 2))
        Thread.sleep(forTimeInterval: 1)
        first.terminate()

        // Relaunch: the conversation restores mid-graph with its transcript.
        let second = XCUIApplication()
        second.launchArguments = ["--freeze-run"]
        second.launch()

        XCTAssertTrue(second.staticTexts["Meeting on the shore"].waitForExistence(timeout: 5))
        XCTAssertTrue(second.staticTexts["You said: Is as Maigh Eo mé."].exists, "The transcript must survive the interruption")
        XCTAssertTrue(second.staticTexts["Cén t-ainm atá ort?"].exists, "Resume must land on the exact current node")

        // The branch changes the partner's next line.
        tapReply(beginning: "Cé thusa?", in: second)
        XCTAssertTrue(second.staticTexts["Is as Maigh Eo mé."].waitForExistence(timeout: 2))
        Thread.sleep(forTimeInterval: 1)
        second.terminate()

        // Third launch: both turns persist; the close completes the graph.
        let third = XCUIApplication()
        third.launchArguments = ["--freeze-run"]
        third.launch()

        XCTAssertTrue(third.staticTexts["You said: Cé thusa?"].waitForExistence(timeout: 5))
        XCTAssertTrue(third.staticTexts["You said: Is as Maigh Eo mé."].exists)
        XCTAssertTrue(third.staticTexts["Is as Maigh Eo mé."].exists)
        tapReply(beginning: "Slán go fóill.", in: third)
        let continueButton = third.buttons["Continue"]
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: continueButton)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 5), .completed, "Completing the conversation must enable Continue")
    }

    // MARK: F7 record and compare path (mic available)

    func testFreezeRunSpeakOriginRecordsAndCompares() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--freeze-run",
            "--fresh-county-pack",
            "--transient-test-state",
            "--page", "mayo.clew-bay.speak-origin",
        ]
        addUIInterruptionMonitor(withDescription: "Microphone permission") { alert in
            for label in ["Allow", "OK"] where alert.buttons[label].exists {
                alert.buttons[label].tap()
                return true
            }
            return false
        }
        app.launch()

        XCTAssertTrue(app.staticTexts["Say the line"].waitForExistence(timeout: 5))
        tapButton("Record", in: app)
        waitForPrimaryBar("Stop", in: app).tap()
        waitForPrimaryBar("Continue", in: app).tap()
    }

    // MARK: C3 default target when nothing slipped

    func testFreezeRunReviewDefaultsToTheAuthoredTargetWhenNothingSlipped() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--freeze-run",
            "--fresh-county-pack",
            "--transient-test-state",
            "--page", "mayo.clew-bay.review-struggle",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Quick review"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Listen"].exists)
        tapChoice("sea", in: app)
        // The review is the run's last page, so completing it promotes the bar
        // to the chapter-path label.
        let completeButton = app.buttons["Complete this chapter path"]
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: completeButton)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 5), .completed)
    }

    // MARK: Largest Dynamic Type on the conversation

    func testFreezeRunConversationSurvivesLargestAccessibilityText() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--freeze-run",
            "--fresh-county-pack",
            "--transient-test-state",
            "--page", "mayo.clew-bay.conversation-origin",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Cárb as tú?"].waitForExistence(timeout: 5))
        let origin = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Is as Maigh Eo mé.")).firstMatch
        XCTAssertTrue(origin.waitForExistence(timeout: 3))
        for _ in 0..<6 where !origin.isHittable { app.swipeUp() }
        XCTAssertTrue(origin.isHittable, "The origin reply stays reachable at the largest text size")
    }

    // MARK: Helpers

    private func assertText(
        containing substring: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let match = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", substring)).firstMatch
        XCTAssertTrue(match.waitForExistence(timeout: 5), "Missing text: \(substring)", file: file, line: line)
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

    private func tapReply(
        beginning prefix: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let reply = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
        XCTAssertTrue(reply.waitForExistence(timeout: 5), "Missing reply: \(prefix)", file: file, line: line)
        // A growing transcript can push the active replies under the bottom
        // bar; XCUI still reports them hittable there, but taps land on the
        // bar overlay. Scroll until the row is genuinely clear of it.
        let barTop = app.frame.maxY - 130
        for _ in 0..<6 where reply.frame.maxY > barTop { app.swipeUp() }
        XCTAssertLessThanOrEqual(reply.frame.maxY, barTop, "Reply never scrolled clear of the bar: \(prefix)", file: file, line: line)
        reply.tap()
    }

    private func waitForPrimaryBar(
        _ label: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let button = app.buttons[label]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing bar action: \(label)", file: file, line: line)
        let enabled = NSPredicate(format: "enabled == true")
        XCTAssertEqual(
            XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: enabled, object: button)], timeout: 5),
            .completed,
            "Bar action never enabled: \(label)",
            file: file,
            line: line
        )
        return button
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
