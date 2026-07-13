import XCTest

final class AtlasFlowUITests: XCTestCase {
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

    func testNamingStepSupportsLargestAccessibilityText() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--grainne-story-step", "3",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["A name can cross centuries."].waitForExistence(timeout: 5))
        let nameField = app.textFields["What is your name?"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        if !nameField.isHittable { app.swipeUp() }
        XCTAssertTrue(nameField.isHittable)

        nameField.tap()
        nameField.typeText("Conor")
        let keepButton = app.buttons["Keep this phrase"]
        XCTAssertTrue(keepButton.waitForExistence(timeout: 3))
        XCTAssertTrue(keepButton.isEnabled)
    }
}
