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

        let keepButton = app.buttons["Carry these lines"]
        XCTAssertTrue(keepButton.waitForExistence(timeout: 3))
        XCTAssertTrue(keepButton.isEnabled)
    }

    func testCinematicEpisodeFourAndReturnScreensAreReachable() throws {
        let crossing = XCUIApplication()
        crossing.launchArguments = ["--grainne-story-step", "9"]
        crossing.launch()

        XCTAssertTrue(crossing.staticTexts["Episode 4 of 6"].waitForExistence(timeout: 5))
        XCTAssertTrue(crossing.staticTexts["To be heard, she must enter another system"].exists)
        XCTAssertFalse(crossing.staticTexts["Your voyage chart"].exists)

        crossing.terminate()

        let returning = XCUIApplication()
        returning.launchArguments = ["--grainne-story-step", "15"]
        returning.launch()

        XCTAssertTrue(returning.staticTexts["Episode 6 of 6"].waitForExistence(timeout: 5))
        XCTAssertTrue(returning.staticTexts["She must ask again"].exists)
    }

    func testLanguageBeatStartsWithReviewedAudioAndActiveRecall() throws {
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
}
