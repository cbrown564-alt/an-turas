import XCTest

final class AtlasFlowUITests: XCTestCase {
    func testGrainnePersonPageUsesEditorialHeroAtLargestAccessibilityText() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--grainne-person",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Gráinne Ní Mháille"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["What survives"].exists)
        XCTAssertTrue(app.staticTexts["Places and consequences"].exists)

        let sourceGuide = app.buttons["Open the 1593 source guide"]
        XCTAssertTrue(sourceGuide.waitForExistence(timeout: 3))
        for _ in 0..<6 where !sourceGuide.isHittable { app.swipeUp() }
        XCTAssertTrue(sourceGuide.isHittable)
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFirstTakeawayContinuesToAuthoredRoad() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--first-takeaway"]
        app.launch()

        let continueButton = app.buttons["Continue the authored road"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()

        let openingRoad = app.staticTexts["THE OPENING ROAD"]
        XCTAssertTrue(openingRoad.waitForExistence(timeout: 5))
        XCTAssertTrue(openingRoad.isHittable, "The authored road should be scrolled into view")
    }

    func testOffalyReviewDraftSurvivesLargestAccessibilityText() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--county-dossier", "offaly.cross-of-the-scriptures",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["The Cross of the Scriptures: river, king and carved prayer"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Review draft"].exists)
        let evidence = app.buttons["Open the evidence record"]
        XCTAssertTrue(evidence.waitForExistence(timeout: 3))
        for _ in 0..<5 where !evidence.isHittable { app.swipeUp() }
        XCTAssertTrue(evidence.isHittable)
    }

    func testOffalyReviewOpeningExposesItsAuthoredVisual() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--county-pack", "offaly.cross-of-the-scriptures",
            "--fresh-county-pack",
            "--mode", "story",
            "--page", "offaly.river-road.opening",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["A river running through the middle"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.descendants(matching: .any)["county-visual-offaly.river-road.opening"]
                .waitForExistence(timeout: 3)
        )
        XCTAssertTrue(
            app.staticTexts[
                "Generated editorial interpretation of the Shannon callows · not documentary evidence"
            ].exists
        )
    }

    func testReviewDraftOpensThePackBackedRecoveryModel() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--county-pack", "offaly.cross-of-the-scriptures",
            "--fresh-county-pack",
            "--mode", "learning",
            "--page", "offaly.inscription.read-limit",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Which statement fits the surviving inscription?"].waitForExistence(timeout: 5))
        let next = app.buttons["Continue"]
        XCTAssertTrue(next.exists)
        XCTAssertFalse(next.isEnabled)

        // First wrong selection: the diagnostic attaches to the row and the
        // attempt stays open — no struggle chrome yet (D27 repair window).
        app.buttons["Every letter survives clearly and scholars agree on one translation."].tap()
        XCTAssertTrue(app.staticTexts["The inscription is damaged and debated."].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Not quite"].exists)
        XCTAssertFalse(next.isEnabled)

        // A second wrong without self-correcting fires the struggle signal.
        app.buttons["It records Flann's spoken instructions to the carvers."].tap()
        XCTAssertTrue(app.staticTexts["Not quite"].waitForExistence(timeout: 2))
        XCTAssertFalse(next.isEnabled)

        let correct = "It links prayer, Flann, Colmán and the making of the cross, but damaged letters affect the exact reading."
        let correctButton = app.buttons[correct]
        XCTAssertTrue(correctButton.waitForExistence(timeout: 2))
        let enabled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"),
            object: correctButton
        )
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 2), .completed)
        for _ in 0..<3 where !correctButton.isHittable { app.swipeDown() }
        XCTAssertTrue(correctButton.isHittable)
        correctButton.tap()
        XCTAssertTrue(next.isEnabled)
    }

    func testLaunchRoadCollectionCarriesEightyWordsAndTEGContext() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--atlas-open", "--launch-road-complete"]
        app.launch()

        app.tabBars.buttons["An Cnuasach"].tap()
        XCTAssertTrue(app.staticTexts["Evidence, making, language."].waitForExistence(timeout: 5))
        app.segmentedControls.buttons["Words"].tap()

        XCTAssertTrue(app.staticTexts["80 WORDS · 4 COUNTIES"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["A1 foundations carried into an A2 bridge"].exists)
        let disclaimer = app.staticTexts["You have added possession, location and old/new description. This is product guidance, not an awarded TEG qualification."]
        for _ in 0..<3 where !disclaimer.exists { app.swipeUp() }
        XCTAssertTrue(disclaimer.exists)
    }

    func testCalendarHasARealRitualWithoutMissedDayDebt() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--atlas-open"]
        app.launch()

        app.tabBars.buttons["An Féilire"].tap()

        XCTAssertTrue(app.staticTexts["Let one word last"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No missed days"].exists)
        XCTAssertTrue(app.staticTexts["The calendar opens again whenever you do."].exists)
    }

    func testRockfleetModeOpeningSurvivesLargestAccessibilityText() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--county-pack", "mayo.grainne-1593",
            "--mode-opening",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Rockfleet: harbour, household, stronghold"].waitForExistence(timeout: 5))
        let story = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Story mode'")).firstMatch
        XCTAssertTrue(story.waitForExistence(timeout: 3))
        for _ in 0..<4 where !story.isHittable { app.swipeUp() }
        XCTAssertTrue(story.isHittable)
    }

    func testRockfleetStoryModeHasNoLanguageGate() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--county-pack", "mayo.grainne-1593",
            "--mode", "story",
            "--page", "mayo.rockfleet.arrival",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["A castle where the road is water"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Follow the tide"].isEnabled)
        XCTAssertFalse(app.buttons["Hear the Irish"].exists)
        XCTAssertTrue(app.staticTexts["Story"].exists)
    }

    func testRockfleetStoryModeCompletesEveryPageInDarkAppearance() throws {
        let app = freshRockfleetApp(mode: "story", appearance: "dark")
        app.launch()

        let pages = [
            ("A castle where the road is water", "Follow the tide"),
            ("The tide changes the threshold", "Read the water"),
            ("Boats extend the walls across the bay", "Trace the water road"),
            ("The stronghold held people as well as stone", "Enter the household"),
            ("Relationships were part of authority", "Widen the circle"),
            ("Harbour, household and stronghold worked together", "Test the connection"),
            ("The papers show a political household, not a private scene", "Read against the record"),
            ("The walls do not tell a whole life", "Keep the boundary visible"),
            ("A connected system can be pressured at several points", "See what is at stake"),
            ("The coast becomes a set of stakes", "Carry the question onward"),
        ]

        for (title, action) in pages {
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5), "Missing Story page: \(title)")
            tapButton(action, in: app)
        }

        XCTAssertTrue(app.staticTexts["Rockfleet chapter proof complete"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["You followed the complete chapter account without a language gate."].exists)
        keepScreenshot(named: "Rockfleet Story completion — dark", from: app)
    }

    func testRockfleetTypingUsesTheKeyboardFadaToolbar() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--county-pack", "mayo.grainne-1593",
            "--mode", "learning",
            "--page", "mayo.rockfleet.type-castle",
            "--appearance", "light",
            "--fresh-county-pack",
            "--transient-test-state",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Write the place with its fada"].waitForExistence(timeout: 5))
        typeCastleSentence(in: app)
        let field = irishAnswerField(in: app)
        XCTAssertEqual(field.value as? String, "Tá an caisleán anseo.")
        tapButton("Check answer from keyboard", in: app)
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Retry"].exists, "The exact visible answer was graded as incorrect")
        XCTAssertTrue(continueButton.isEnabled)
    }

    func testRockfleetLearningModeCompletesEveryPageInLightAppearance() throws {
        let app = freshRockfleetApp(mode: "learning", appearance: "light", extra: ["--microphone-denied"])
        app.launch()

        XCTAssertTrue(app.staticTexts["A castle where the road is water"].waitForExistence(timeout: 5))
        tapButton("Follow the tide", in: app)

        XCTAssertTrue(app.staticTexts["Hear the place before translating it"].waitForExistence(timeout: 5))
        tapButton("Hear the Irish", in: app)
        tapChoice("castle", in: app)
        finishExercise(in: app)

        XCTAssertTrue(app.staticTexts["The stronghold held people as well as stone"].waitForExistence(timeout: 5))
        tapButton("Enter the household", in: app)

        XCTAssertTrue(app.staticTexts["Keep people and place distinct"].waitForExistence(timeout: 5))
        for pair in [
            ("caisleán", "castle"),
            ("teaghlach", "family / household"),
            ("mac", "son"),
            ("bean", "woman"),
        ] {
            tapButton(pair.0, in: app)
            tapButton(pair.1, in: app)
        }
        finishExercise(in: app)

        XCTAssertTrue(app.staticTexts["Hear a complete thought"].waitForExistence(timeout: 5))
        tapButton("Play the model", in: app)
        for token in ["Tá", "muid", "go", "léir."] { tapButton(token, in: app) }
        tapButton("Check the order", in: app)
        finishExercise(in: app)

        XCTAssertTrue(app.staticTexts["Build the household line"].waitForExistence(timeout: 5))
        for token in ["Tá", "an", "teaghlach", "anseo."] { tapButton(token, in: app) }
        tapButton("Check the order", in: app)
        finishExercise(in: app)

        XCTAssertTrue(app.staticTexts["Write the place with its fada"].waitForExistence(timeout: 5))
        typeCastleSentence(in: app)
        tapButton("Check answer from keyboard", in: app)
        finishExercise(in: app)

        XCTAssertTrue(app.staticTexts["Harbour, household and stronghold worked together"].waitForExistence(timeout: 5))
        tapButton("Test the connection", in: app)

        XCTAssertTrue(app.staticTexts["Answer from the place in front of you"].waitForExistence(timeout: 5))
        tapButton("Tá an caisleán anseo.", in: app)
        finishExercise(in: app)

        XCTAssertTrue(app.staticTexts["Rebuild the system"].waitForExistence(timeout: 5))
        for event in [
            "The inlet gives boats a landing.",
            "The castle protects a base.",
            "The household turns the base into lived authority.",
        ] {
            tapButton(event, in: app)
        }
        tapButton("Check the order", in: app)
        finishExercise(in: app)

        XCTAssertTrue(app.staticTexts["Ask only what the evidence can answer"].waitForExistence(timeout: 5))
        tapButton("Rockfleet, boats and family relationships were connected parts of Gráinne's authority.", in: app)
        finishExercise(in: app)

        XCTAssertTrue(app.staticTexts["Notice what stays in place"].waitForExistence(timeout: 5))
        tapButton("Tá + the person or thing + anseo.", in: app)
        finishExercise(in: app)

        XCTAssertTrue(app.staticTexts["The walls do not tell a whole life"].waitForExistence(timeout: 5))
        tapButton("Keep the boundary visible", in: app)

        XCTAssertTrue(app.staticTexts["Put the household in your own voice"].waitForExistence(timeout: 5))
        waitForPrimaryBar("Continue without recording", in: app).tap()
        finishExercise(in: app)

        XCTAssertTrue(app.staticTexts["A connected system can be pressured at several points"].waitForExistence(timeout: 5))
        tapButton("See what is at stake", in: app)

        XCTAssertTrue(app.staticTexts["Bring the place word back"].waitForExistence(timeout: 5))
        tapChoice("caisleán", in: app)
        finishExercise(in: app)

        XCTAssertTrue(app.buttons["Bring the words back"].waitForExistence(timeout: 5))
        tapButton("Bring the words back", in: app)

        XCTAssertTrue(app.staticTexts["Retrieve the household line without tiles"].waitForExistence(timeout: 5))
        typeHouseholdSentence(in: app)
        tapButton("Check answer from keyboard", in: app)
        finishExercise(in: app, continueLabel: "Complete this chapter path")

        XCTAssertTrue(app.staticTexts["Rockfleet chapter proof complete"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["You followed the shorter causal account and completed all twelve exercise families in their authored positions."].exists)
        keepScreenshot(named: "Rockfleet Learning completion — light", from: app)
    }

    func testRockfleetWrongAnswerStaysRepairableInPlace() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--county-pack", "mayo.grainne-1593",
            "--mode", "learning",
            "--page", "mayo.rockfleet.listen-caislean",
            "--fresh-county-pack",
        ]
        app.launch()

        // The response area answers from cold open — no play-first gate (D1/F1).
        tapChoice("ship", in: app)

        // First wrong: rationale on the affected row, attempt open, no struggle chrome.
        XCTAssertTrue(app.staticTexts["Long is the word for ship; the sound is different."].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Not quite"].exists)
        XCTAssertFalse(app.buttons["Continue"].isEnabled)
        XCTAssertFalse(app.buttons["Retry"].exists)

        // A second wrong without self-correcting fires the struggle signal (D27).
        tapChoice("coast", in: app)
        XCTAssertTrue(app.staticTexts["Not quite"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["Continue"].isEnabled)

        // Repair is still the next touch.
        tapChoice("castle", in: app)

        XCTAssertTrue(app.buttons["Continue"].isEnabled)
    }

    func testRockfleetMatchingWrongPairStaysBriefAndRepairable() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--county-pack", "mayo.grainne-1593",
            "--mode", "learning",
            "--page", "mayo.rockfleet.match-household",
            "--fresh-county-pack",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Keep people and place distinct"].waitForExistence(timeout: 5))
        tapButton("caisleán", in: app)
        tapButton("son", in: app)

        // A wrong pair keeps a plain-language note on the attempted meaning —
        // never mastery-failure chrome or a locked board (D3/D5/F5).
        XCTAssertTrue(app.staticTexts["“son” does not belong with “caisleán”. Choose another meaning."].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Not quite"].exists)

        // The word stays selected; the next tap repairs the pair in place.
        tapButton("castle", in: app)
        XCTAssertFalse(app.staticTexts["“son” does not belong with “caisleán”. Choose another meaning."].exists)

        for pair in [("teaghlach", "family / household"), ("mac", "son"), ("bean", "woman")] {
            tapButton(pair.0, in: app)
            tapButton(pair.1, in: app)
        }

        XCTAssertTrue(app.buttons["Continue"].isEnabled)
        XCTAssertFalse(app.staticTexts["Not quite"].exists)
    }

    func testRockfleetRecordKeepsInkPrimaryUntilCompare() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--county-pack", "mayo.grainne-1593",
            "--mode", "learning",
            "--page", "mayo.rockfleet.speaking",
            "--fresh-county-pack",
        ]
        addUIInterruptionMonitor(withDescription: "Microphone permission") { alert in
            for label in ["Allow", "OK"] where alert.buttons[label].exists {
                alert.buttons[label].tap()
                return true
            }
            return false
        }
        app.launch()

        XCTAssertTrue(app.staticTexts["Put the household in your own voice"].waitForExistence(timeout: 5))

        // Cold open: Record owns the one ink primary; the escape stays quiet (D2/F7).
        waitForPrimaryBar("Record your voice", in: app).tap()
        app.swipeUp()

        waitForPrimaryBar("Stop recording", in: app).tap()

        // After Stop the primary is the post-compare continue, held until playback.
        let compared = app.buttons["I compared both"]
        XCTAssertTrue(compared.waitForExistence(timeout: 5))
        XCTAssertFalse(compared.isEnabled)

        tapButton("Play your voice", in: app)
        waitForPrimaryBar("I compared both", in: app).tap()

        finishExercise(in: app)
        XCTAssertTrue(app.staticTexts["A connected system can be pressured at several points"].waitForExistence(timeout: 5))
    }

    func testRockfleetDeniedMicrophoneNeverTrapsProgress() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--county-pack", "mayo.grainne-1593",
            "--mode", "learning",
            "--page", "mayo.rockfleet.speaking",
            "--microphone-denied",
            "--fresh-county-pack",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Put the household in your own voice"].waitForExistence(timeout: 5))
        for _ in 0..<4 where !app.staticTexts["Microphone access is off. You can keep listening and continue without recording."].exists { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["Microphone access is off. You can keep listening and continue without recording."].exists)
        let continueWithout = waitForPrimaryBar("Continue without recording", in: app)
        continueWithout.tap()
        XCTAssertTrue(app.buttons["Continue"].isEnabled)
    }

    func testExerciseGalleryCoversTwelveFamiliesAndFailureStates() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--exercise-gallery",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["One feedback model across the activity layers"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Listen and identify"].exists)
        for _ in 0..<10 where !app.staticTexts["Failure and edge states"].exists { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["Failure and edge states"].exists)
        XCTAssertTrue(app.staticTexts["Long copy accessibility size state"].exists)
    }

    private func freshRockfleetApp(mode: String, appearance: String, extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--county-pack", "mayo.grainne-1593",
            "--mode", mode,
            "--page", "mayo.rockfleet.arrival",
            "--appearance", appearance,
            "--fresh-county-pack",
            "--transient-test-state",
        ] + extra
        return app
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
        XCTAssertTrue(
            button.waitForExistence(timeout: 5),
            "Missing exercise action: \(continueLabel)",
            file: file,
            line: line
        )
        let enabled = NSPredicate(format: "enabled == true")
        XCTAssertEqual(
            XCTWaiter.wait(
                for: [XCTNSPredicateExpectation(predicate: enabled, object: button)],
                timeout: 5
            ),
            .completed,
            "Exercise action never enabled: \(continueLabel)",
            file: file,
            line: line
        )
        button.tap()
    }

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

    private func typeCastleSentence(in app: XCUIApplication) {
        _ = irishAnswerField(in: app)
        app.typeText("T")
        tapButton("Insert á from keyboard toolbar", in: app)
        app.typeText(" an caisle")
        tapButton("Insert á from keyboard toolbar", in: app)
        app.typeText("n anseo.")
    }

    private func typeHouseholdSentence(in app: XCUIApplication) {
        _ = irishAnswerField(in: app)
        app.typeText("T")
        tapButton("Insert á from keyboard toolbar", in: app)
        app.typeText(" an teaghlach anseo.")
    }

    private func keepScreenshot(named name: String, from app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
