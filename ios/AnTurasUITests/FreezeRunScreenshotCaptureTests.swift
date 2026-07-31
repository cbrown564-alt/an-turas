import XCTest

/// D29 freeze craft evidence: captures the four exercise states (unanswered,
/// wrong, repaired, complete) for the clusters changed in this pass, writing
/// PNGs into the test runner's Documents/freeze-shots. The host then copies
/// them to tmp/exercise-screenshots/freeze-run-2026-07-30/.
final class FreezeRunScreenshotCaptureTests: XCTestCase {
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
        // Settle wait: taps commit SwiftUI state a frame or two later, and an
        // instant screenshot catches the pre-commit frame (selection fills
        // and verdict swaps missing). Every capture must be post-commit.
        Thread.sleep(forTimeInterval: 0.5)
        let data = XCUIScreen.main.screenshot().pngRepresentation
        try? data.write(to: shotsFolder.appendingPathComponent("\(name).png"))
    }

    private func launch(_ args: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--freeze-run", "--fresh-county-pack", "--transient-test-state"] + args
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

    private func tapCheckWhenReady(_ label: String = "Check the order", in app: XCUIApplication) {
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

    private func tapReply(_ prefix: String, in app: XCUIApplication) {
        let reply = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
        guard reply.waitForExistence(timeout: 5) else { return }
        let barTop = app.frame.maxY - 130
        for _ in 0..<6 where reply.frame.maxY > barTop { app.swipeUp() }
        reply.tap()
    }

    // MARK: A — Choice (steps 1 and 7)

    func testCaptureChoiceStates() throws {
        let app = launch(["--page", "mayo.clew-bay.listen-farraige", "--appearance", "light"])
        XCTAssertTrue(app.staticTexts["Tap what you hear"].waitForExistence(timeout: 5))
        shot("01-listen-cold", from: app)

        tapButton("island", in: app)
        shot("01-listen-wrong", from: app)

        tapButton("castle", in: app)
        XCTAssertTrue(app.staticTexts["Not quite"].waitForExistence(timeout: 2))
        shot("01-listen-struggle", from: app)

        tapButton("sea", in: app)
        shot("01-listen-complete", from: app)

        let dark = launch(["--page", "mayo.clew-bay.listen-farraige", "--appearance", "dark"])
        XCTAssertTrue(dark.staticTexts["Tap what you hear"].waitForExistence(timeout: 5))
        shot("01-listen-cold-dark", from: dark)

        let f6 = launch(["--page", "mayo.clew-bay.comprehend-coast", "--appearance", "light"])
        XCTAssertTrue(f6.staticTexts["Choose what it means"].waitForExistence(timeout: 5))
        shot("07-comprehend-cold", from: f6)
        tapButton("I am from the open sea.", in: f6)
        shot("07-comprehend-wrong", from: f6)
        tapButton("I am from Mayo.", in: f6)
        shot("07-comprehend-complete", from: f6)
    }

    // MARK: C — Matching (step 2)

    func testCaptureMatchingStates() throws {
        let app = launch(["--page", "mayo.clew-bay.match-coast", "--appearance", "light"])
        XCTAssertTrue(app.staticTexts["Tap the matching pairs"].waitForExistence(timeout: 5))
        shot("02-match-cold", from: app)

        tapButton("farraige", in: app)
        shot("02-match-word-selected", from: app)
        tapButton("bay", in: app)
        XCTAssertTrue(app.staticTexts["Not a match."].waitForExistence(timeout: 2))
        shot("02-match-wrong-note", from: app)

        tapButton("sea", in: app)
        tapButton("bá", in: app)
        tapButton("bay", in: app)
        tapButton("áit", in: app)
        tapButton("place", in: app)
        shot("02-match-complete", from: app)
    }

    // MARK: B — Construction (step 3)

    func testCaptureConstructionStates() throws {
        let app = launch(["--page", "mayo.clew-bay.build-origin", "--appearance", "light"])
        XCTAssertTrue(app.staticTexts["Build the sentence"].waitForExistence(timeout: 5))
        shot("03-build-cold", from: app)

        for token in ["as", "Is", "Maigh Eo", "mé."] { tapButton(token, in: app) }
        shot("03-build-filled", from: app)
        tapCheckWhenReady(in: app)
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Not quite'")).firstMatch
                .waitForExistence(timeout: 2)
        )
        shot("03-build-wrong", from: app)

        for token in ["as", "Maigh Eo", "mé."] { tapButton(token, in: app) }
        for token in ["as", "Maigh Eo", "mé."] { tapButton(token, in: app) }
        tapCheckWhenReady(in: app)
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Complete'")).firstMatch
                .waitForExistence(timeout: 2)
        )
        XCTAssertFalse(
            app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Not quite'")).firstMatch.exists
        )
        shot("03-build-complete", from: app)

        let out = URL(fileURLWithPath: "/Users/cobro/code/irish/tmp/exercise-screenshots/builder-2026-07-31/03-build-complete.png")
        try? FileManager.default.createDirectory(at: out.deletingLastPathComponent(), withIntermediateDirectories: true)
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: out)
    }

    // MARK: D — Typing (step 4)

    func testCaptureTypingStates() throws {
        let app = launch(["--page", "mayo.clew-bay.type-origin", "--appearance", "light"])
        XCTAssertTrue(app.staticTexts["Type the sentence"].waitForExistence(timeout: 5))
        shot("04-type-cold", from: app)

        let field = app.textFields["irish-answer-field"]
        let area = app.textViews["irish-answer-field"]
        let match = field.waitForExistence(timeout: 2) ? field : area
        match.tap()
        app.typeText("Is as Maigh Eo me.")
        shot("04-type-filled", from: app)
        tapButton("Check the sentence", in: app)
        XCTAssertTrue(app.staticTexts["Not quite"].waitForExistence(timeout: 2))
        shot("04-type-wrong", from: app)

        // The bar Check resigns keyboard focus (intended keyboard-yield);
        // re-tap the field before editing the answer.
        match.tap()
        app.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3))
        app.typeText("m")
        tapButton("Insert é from keyboard toolbar", in: app)
        app.typeText(".")
        tapButton("Check the sentence", in: app)
        app.swipeDown()
        shot("04-type-complete", from: app)

        let a11y = launch([
            "--page", "mayo.clew-bay.type-origin",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
        ])
        XCTAssertTrue(a11y.staticTexts["Type the sentence"].waitForExistence(timeout: 5))
        shot("04-type-a11y", from: a11y)
    }

    // MARK: F — Conversation (step 5)

    func testCaptureConversationStates() throws {
        let app = launch(["--page", "mayo.clew-bay.conversation-origin", "--appearance", "light"])
        XCTAssertTrue(app.staticTexts["Meeting on the shore"].waitForExistence(timeout: 5))
        shot("05-conversation-cold", from: app)

        tapReply("Slán go fóill.", in: app)
        XCTAssertTrue(app.staticTexts["That says goodbye, and the conversation has only begun. Answer the question instead."].waitForExistence(timeout: 2))
        shot("05-conversation-misfit", from: app)

        tapReply("Is as Maigh Eo mé.", in: app)
        XCTAssertTrue(app.staticTexts["Cén t-ainm atá ort?"].waitForExistence(timeout: 2))
        shot("05-conversation-turn-two", from: app)

        tapReply("Cé thusa?", in: app)
        XCTAssertTrue(app.staticTexts["Is as Maigh Eo mé."].waitForExistence(timeout: 2))
        shot("05-conversation-branch", from: app)

        tapReply("Slán go fóill.", in: app)
        app.swipeDown()
        shot("05-conversation-complete", from: app)

        let dark = launch(["--page", "mayo.clew-bay.conversation-origin", "--appearance", "dark"])
        XCTAssertTrue(dark.staticTexts["Meeting on the shore"].waitForExistence(timeout: 5))
        shot("05-conversation-cold-dark", from: dark)

        let a11y = launch([
            "--page", "mayo.clew-bay.conversation-origin",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
        ])
        XCTAssertTrue(a11y.staticTexts["Meeting on the shore"].waitForExistence(timeout: 5))
        shot("05-conversation-a11y", from: a11y)
    }

    // MARK: E — Speaking (step 6)

    func testCaptureSpeakingStates() throws {
        let app = launch(["--page", "mayo.clew-bay.speak-origin", "--appearance", "light"])
        addUIInterruptionMonitor(withDescription: "Microphone permission") { alert in
            for label in ["Allow", "OK"] where alert.buttons[label].exists {
                alert.buttons[label].tap()
                return true
            }
            return false
        }
        XCTAssertTrue(app.staticTexts["Say the line"].waitForExistence(timeout: 5))
        shot("06-speak-cold", from: app)

        let record = app.buttons["Record"]
        XCTAssertTrue(record.waitForExistence(timeout: 3))
        record.tap()
        let stop = app.buttons["Stop"]
        XCTAssertTrue(stop.waitForExistence(timeout: 3))
        stop.tap()
        shot("06-speak-recorded", from: app)

        let cont = app.buttons["Continue"]
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: cont)
        _ = XCTWaiter.wait(for: [enabled], timeout: 5)
        cont.tap()
        shot("06-speak-complete", from: app)

        let denied = launch(["--page", "mayo.clew-bay.speak-origin", "--microphone-denied"])
        XCTAssertTrue(denied.staticTexts["Say the line"].waitForExistence(timeout: 5))
        for _ in 0..<4 where !denied.staticTexts["Microphone access is off."].exists { denied.swipeUp() }
        shot("06-speak-mic-denied", from: denied)
    }

    // MARK: G — Consolidation (steps 8 and 9)

    func testCaptureConsolidationStates() throws {
        let completion = launch(["--page", "mayo.clew-bay.completion", "--appearance", "light"])
        XCTAssertTrue(completion.staticTexts["What you can now do"].waitForExistence(timeout: 5))
        shot("08-completion-top", from: completion)
        completion.swipeUp()
        shot("08-completion-collection", from: completion)

        let review = launch(["--page", "mayo.clew-bay.review-struggle", "--appearance", "light"])
        XCTAssertTrue(review.staticTexts["Quick review"].waitForExistence(timeout: 5))
        shot("09-review-cold", from: review)
        tapButton("sea", in: review)
        review.swipeDown()
        shot("09-review-complete", from: review)

        let end = launch(["--page", "mayo.clew-bay.review-struggle", "--appearance", "dark"])
        XCTAssertTrue(end.staticTexts["Quick review"].waitForExistence(timeout: 5))
        shot("09-review-cold-dark", from: end)
    }
}
