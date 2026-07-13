import XCTest

final class KeyboardPerformanceUITests: XCTestCase {
    func testEpisodeFourIdentityAcceptsFirstCharacterWithoutRebuildingStory() throws {
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["--grainne-story-step", "11"]
        app.launch()

        let field = app.textFields["Your name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        if !field.isHittable { app.swipeUp() }

        let keyboardStarted = ProcessInfo.processInfo.systemUptime
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2.5))
        let keyboardElapsed = ProcessInfo.processInfo.systemUptime - keyboardStarted

        let firstCharacterStarted = ProcessInfo.processInfo.systemUptime
        field.typeText("C")
        let firstCharacterElapsed = ProcessInfo.processInfo.systemUptime - firstCharacterStarted

        let timings = String(
            format: "episode4 keyboard=%.3fs first=%.3fs",
            keyboardElapsed,
            firstCharacterElapsed
        )
        print("KEYBOARD_PERFORMANCE \(timings)")

        XCTAssertEqual(field.value as? String, "C")
        // A cold Simulator keyboard service is measurably slower than a warm
        // hardware keyboard. The release-blocking app regression is first-key
        // acceptance; still cap cold focus-to-keyboard latency well below the
        // reported 10–15 second freeze.
        XCTAssertLessThan(keyboardElapsed, 2.5, "Preparing the Episode 4 keyboard regressed: \(timings)")
        XCTAssertLessThan(firstCharacterElapsed, 1.25, "Episode 4 rebuilt too much work on input: \(timings)")
    }

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
