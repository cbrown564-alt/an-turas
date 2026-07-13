import XCTest

final class KeyboardPerformanceUITests: XCTestCase {
    func testTypeInFirstCharacterIsAcceptedWithVisitedPagesMounted() throws {
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["--legacy", "--session", "0", "--reveal", "8"]
        app.launch()

        let field = app.textFields["Is mise …"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))

        let keyboardStarted = ProcessInfo.processInfo.systemUptime
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 1.25))
        let keyboardElapsed = ProcessInfo.processInfo.systemUptime - keyboardStarted

        let firstCharacterStarted = ProcessInfo.processInfo.systemUptime
        field.typeText("I")
        let firstCharacterElapsed = ProcessInfo.processInfo.systemUptime - firstCharacterStarted

        let nextCharacterStarted = ProcessInfo.processInfo.systemUptime
        field.typeText("s")
        let nextCharacterElapsed = ProcessInfo.processInfo.systemUptime - nextCharacterStarted

        let timings = String(
            format: "keyboard=%.3fs first=%.3fs next=%.3fs",
            keyboardElapsed,
            firstCharacterElapsed,
            nextCharacterElapsed
        )
        print("KEYBOARD_PERFORMANCE \(timings)")

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Type-in exercise with keyboard"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        XCTAssertEqual(field.value as? String, "Is")
        XCTAssertLessThan(keyboardElapsed, 1.25, "Preparing the keyboard regressed: \(timings)")
        XCTAssertLessThan(firstCharacterElapsed, 1.25, "Accepting the first character regressed: \(timings)")
    }
}
