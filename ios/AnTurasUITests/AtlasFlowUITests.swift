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

    func testEpisodeFourIdentityBeatSupportsLargestAccessibilityText() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--grainne-story-step", "11",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Ainm. Mise. Tar."].waitForExistence(timeout: 5))
        let nameField = app.textFields["Your name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        if !nameField.isHittable { app.swipeUp() }
        XCTAssertTrue(nameField.isHittable)

        nameField.tap()
        nameField.typeText("Conor\n")
        let placeField = app.textFields["The place you are from"]
        XCTAssertTrue(placeField.waitForExistence(timeout: 3))
        placeField.typeText("London")

        let keepButton = app.buttons["Make the lines yours"]
        XCTAssertTrue(keepButton.waitForExistence(timeout: 3))
        XCTAssertTrue(keepButton.isEnabled)
    }

    func testCinematicEpisodeFourAndReturnScreensAreReachable() throws {
        let crossing = XCUIApplication()
        crossing.launchArguments = ["--grainne-story-step", "9"]
        crossing.launch()

        XCTAssertTrue(crossing.staticTexts["Episode 4 of 6"].waitForExistence(timeout: 5))
        XCTAssertTrue(crossing.staticTexts["The sea road ends in rooms of paper"].exists)
        XCTAssertFalse(crossing.staticTexts["The route so far"].exists)

        crossing.terminate()

        let returning = XCUIApplication()
        returning.launchArguments = ["--grainne-story-step", "15"]
        returning.launch()

        XCTAssertTrue(returning.staticTexts["Episode 6 of 6"].waitForExistence(timeout: 5))
        XCTAssertTrue(returning.staticTexts["The line home does not close"].exists)
    }

    func testEpisodeFourNameFindUsesTNAInterrogatory() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--grainne-story-step", "10"]
        app.launch()

        XCTAssertTrue(app.staticTexts["There she is: “Grany Ne Malley”"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Interrogatory and answers, July 1593"].exists)
        XCTAssertTrue(app.staticTexts["The National Archives, SP 63/170, ff. 201–202. Folio 201 is shown under the app’s free, exclusively educational use policy."].exists)
        XCTAssertTrue(app.images["Original manuscript page. The first page of the July 1593 interrogatory, The National Archives, SP 63/170, folio 201."].exists)
        XCTAssertFalse(app.staticTexts["September 1593 draft instruction"].exists)
    }

    func testLanguageBeatStartsWithBundledAudioAndActiveRecall() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--grainne-story-step", "2"]
        app.launch()

        let hear = app.buttons["Hear farraige"]
        XCTAssertTrue(hear.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["sea"].exists, "Meaning should remain covered before listening")

        hear.tap()
        XCTAssertTrue(app.buttons["sea"].waitForExistence(timeout: 2))
    }

    func testCompletedLanguageBeatRemainsReplayable() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--grainne-story-step", "5",
            "--completed-story-beat", "5",
        ]
        app.launch()

        let hearCastle = app.buttons["Hear caisleán"]
        XCTAssertTrue(hearCastle.waitForExistence(timeout: 5))
        hearCastle.tap()

        let castle = app.buttons["castle"]
        XCTAssertTrue(castle.waitForExistence(timeout: 2))
        XCTAssertTrue(castle.isEnabled, "Completed language answers must remain replayable")
        castle.tap()

        XCTAssertTrue(
            app.buttons["Hear teaghlach"].waitForExistence(timeout: 2),
            "A correct answer on a completed beat should advance the replay"
        )
    }

    func testEpisodeFiveRequiresTheUnsupportedClaim() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--grainne-story-step", "13"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Which claim goes beyond the surviving evidence?"].waitForExistence(timeout: 5))
        let continueButton = app.buttons["Name what remains unfinished"]
        XCTAssertTrue(continueButton.exists)
        XCTAssertFalse(continueButton.isEnabled)

        app.buttons["The government ordered relief"].tap()
        XCTAssertTrue(app.staticTexts["The draft supports that claim. Look for what the paper cannot prove."].waitForExistence(timeout: 2))
        XCTAssertFalse(continueButton.isEnabled)

        app.buttons["The order ended the conflict"].tap()
        XCTAssertTrue(app.staticTexts["Difference marked"].waitForExistence(timeout: 2))
        XCTAssertTrue(continueButton.isEnabled)
    }

    func testOffalyEditorialPreviewSurvivesLargestAccessibilityText() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--county-dossier", "offaly.cross-of-the-scriptures",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["The cross at Ireland’s crossroads"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Editorial preview"].exists)
        let evidence = app.buttons["Open the evidence record"]
        XCTAssertTrue(evidence.waitForExistence(timeout: 3))
        for _ in 0..<5 where !evidence.isHittable { app.swipeUp() }
        XCTAssertTrue(evidence.isHittable)
    }

    func testSharedCountyStoryRequiresRecoveryBeforeAdvancing() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--county-story", "offaly.cross-of-the-scriptures",
            "--county-story-beat", "5",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Which statement is secure?"].waitForExistence(timeout: 5))
        let next = app.buttons["Enter the next episode"]
        XCTAssertTrue(next.exists)
        XCTAssertFalse(next.isEnabled)

        app.buttons["A named scribe recorded his whole day here"].tap()
        XCTAssertTrue(app.staticTexts["That claim asks the stone to preserve more than it does."].waitForExistence(timeout: 2))
        XCTAssertFalse(next.isEnabled)

        app.buttons["The surviving cross carries carved panels and a damaged inscription"].tap()
        XCTAssertTrue(app.staticTexts["The surviving object stays at the centre."].waitForExistence(timeout: 2))
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
        XCTAssertTrue(app.buttons["Continue"].isEnabled)
        XCTAssertFalse(app.buttons["Hear the Irish"].exists)
        XCTAssertTrue(app.staticTexts["Story"].exists)
    }

    func testRockfleetWrongAnswerRequiresExplicitRecovery() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--county-pack", "mayo.grainne-1593",
            "--mode", "learning",
            "--page", "mayo.rockfleet.listen-caislean",
        ]
        app.launch()

        let hear = app.buttons["Hear the Irish"]
        XCTAssertTrue(hear.waitForExistence(timeout: 5))
        hear.tap()
        for _ in 0..<3 where !app.buttons["ship"].exists { app.swipeUp() }
        app.buttons["ship"].tap()

        XCTAssertTrue(app.staticTexts["Try again"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["Continue"].isEnabled)
        for _ in 0..<3 where !app.buttons["Retry"].isHittable { app.swipeUp() }
        app.buttons["Retry"].tap()
        for _ in 0..<3 where !app.buttons["Hear the Irish"].isHittable { app.swipeDown() }
        app.buttons["Hear the Irish"].tap()
        for _ in 0..<3 where !app.buttons["castle"].exists { app.swipeUp() }
        app.buttons["castle"].tap()

        XCTAssertTrue(app.staticTexts["Corrected"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["Continue"].isEnabled)
        for _ in 0..<3 where !app.buttons["Keep this answer"].isHittable { app.swipeUp() }
        app.buttons["Keep this answer"].tap()
        XCTAssertTrue(app.buttons["Continue"].isEnabled)
    }

    func testRockfleetDeniedMicrophoneNeverTrapsProgress() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--county-pack", "mayo.grainne-1593",
            "--mode", "learning",
            "--page", "mayo.rockfleet.speaking",
            "--microphone-denied",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Put the household in your own voice"].waitForExistence(timeout: 5))
        for _ in 0..<4 where !app.staticTexts["Microphone access is off. You can keep listening and continue without recording."].exists { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["Microphone access is off. You can keep listening and continue without recording."].exists)
        let continueWithout = app.buttons["Continue without recording"]
        XCTAssertTrue(continueWithout.exists)
        for _ in 0..<3 where !continueWithout.isHittable { app.swipeUp() }
        XCTAssertTrue(continueWithout.isEnabled)
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

        XCTAssertTrue(app.staticTexts["One feedback model, twelve mechanics"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Listen and identify"].exists)
        for _ in 0..<10 where !app.staticTexts["Failure and edge states"].exists { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["Failure and edge states"].exists)
        XCTAssertTrue(app.staticTexts["Long copy accessibility size state"].exists)
    }
}
