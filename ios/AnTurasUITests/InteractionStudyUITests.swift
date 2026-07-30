import XCTest

final class InteractionStudyUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testGalleryPresentsThreeNewLoopsAsDisposableStudies() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--interaction-studies",
            "--transient-test-state",
        ]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Three small learning loops"]
                .waitForExistence(timeout: 5)
        )

        for slug in ["sound-match", "sentence-flow", "coast-placement"] {
            XCTAssertTrue(
                identified("interaction-study-card-\(slug)", in: app).exists,
                "Missing interaction study \(slug)"
            )
        }

        let fixedMaterial = identified("interaction-study-fixed-material", in: app)
        for _ in 0..<4 where !fixedMaterial.exists {
            app.swipeUp()
        }
        XCTAssertTrue(fixedMaterial.waitForExistence(timeout: 2))
        XCTAssertTrue(fixedMaterial.label.contains("farraige, bá, áit"))
        XCTAssertTrue(fixedMaterial.label.contains("Is as Maigh Eo mé."))
    }

    func testSoundMatchRepairsInPlaceAndCompletesThreeFastRounds() {
        let app = studyApp(.soundMatch, appearance: "light")
        app.launch()

        XCTAssertTrue(
            identified("interaction-study-sound-match-audio-fallback", in: app)
                .waitForExistence(timeout: 5)
        )

        tap("interaction-study-sound-match-option-place", in: app)
        XCTAssertTrue(
            identified("interaction-study-sound-match-feedback-incorrect", in: app)
                .waitForExistence(timeout: 2)
        )
        tap("interaction-study-sound-match-option-sea", in: app)
        tap("interaction-study-sound-match-continue", in: app)

        tap("interaction-study-sound-match-option-sea", in: app)
        tap("interaction-study-sound-match-option-bay", in: app)
        tap("interaction-study-sound-match-continue", in: app)

        tap("interaction-study-sound-match-option-bay", in: app)
        tap("interaction-study-sound-match-option-place", in: app)
        tap("interaction-study-sound-match-continue", in: app)

        XCTAssertTrue(
            identified("interaction-study-sound-match-complete", in: app)
                .waitForExistence(timeout: 3)
        )
        XCTAssertTrue(identified("interaction-study-sound-match-restart", in: app).exists)
        keepScreenshot(named: "Sound Match complete", from: app)
    }

    func testSentenceFlowKeepsCorrectWorkAndVisiblyRemovesTheCues() {
        let app = studyApp(.sentenceFlow, appearance: "dark")
        app.launch()

        tap("interaction-study-sentence-flow-tile-as", in: app)
        XCTAssertTrue(
            identified("interaction-study-sentence-flow-feedback-incorrect", in: app)
                .waitForExistence(timeout: 2)
        )

        buildSentence(in: app)
        tap("interaction-study-sentence-flow-remove-cues", in: app)

        XCTAssertTrue(app.staticTexts["The route is yours now."].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["statement"].exists)
        buildSentence(in: app)

        XCTAssertTrue(
            identified("interaction-study-sentence-flow-complete", in: app)
                .waitForExistence(timeout: 3)
        )
        XCTAssertTrue(identified("interaction-study-sentence-flow-restart", in: app).exists)
        keepScreenshot(named: "Sentence Flow complete", from: app)
    }

    func testCoastPlacementChangesFromLabelledToUnlabelledMapAfterRecovery() {
        let app = studyApp(.coastPlacement, appearance: "light")
        app.launch()

        tap("interaction-study-coast-placement-region-sheltered-bay", in: app)
        XCTAssertTrue(
            identified("interaction-study-coast-placement-feedback-incorrect", in: app)
                .waitForExistence(timeout: 2)
        )
        tap("interaction-study-coast-placement-region-open-water", in: app)
        waitForTask(2, in: app)
        tap("interaction-study-coast-placement-region-sheltered-bay", in: app)
        waitForTask(3, in: app)
        tap("interaction-study-coast-placement-region-named-land", in: app)

        tap("interaction-study-coast-placement-remove-labels", in: app)
        XCTAssertTrue(app.staticTexts["Labels removed"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["Open water"].exists)

        tap("interaction-study-coast-placement-region-open-water", in: app)
        waitForTask(2, in: app)
        tap("interaction-study-coast-placement-region-sheltered-bay", in: app)
        waitForTask(3, in: app)
        tap("interaction-study-coast-placement-region-named-land", in: app)

        XCTAssertTrue(
            identified("interaction-study-coast-placement-complete", in: app)
                .waitForExistence(timeout: 4)
        )
        XCTAssertTrue(identified("interaction-study-coast-placement-restart", in: app).exists)
        keepScreenshot(named: "Coast Placement complete", from: app)
    }

    func testEveryStudyKeepsItsFirstResponseReachableAtLargestType() {
        let expectations: [(Study, String)] = [
            (.soundMatch, "interaction-study-sound-match-option-sea"),
            (.sentenceFlow, "interaction-study-sentence-flow-tile-is"),
            (
                .coastPlacement,
                "interaction-study-coast-placement-region-open-water"
            ),
        ]

        for (study, responseID) in expectations {
            for appearance in ["light", "dark"] {
                let app = studyApp(
                    study,
                    appearance: appearance,
                    extra: [
                        "--interaction-study-reduce-motion",
                        "-UIPreferredContentSizeCategoryName",
                        "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
                    ]
                )
                app.launch()

                let response = identified(responseID, in: app)
                XCTAssertTrue(
                    response.waitForExistence(timeout: 5),
                    "\(study.rawValue) lost its first response in \(appearance)"
                )
                for _ in 0..<6 where !response.isHittable {
                    app.swipeUp()
                }
                XCTAssertTrue(
                    response.isHittable,
                    "\(study.rawValue) first response is not reachable in \(appearance)"
                )
                app.terminate()
            }
        }
    }

    private enum Study: String {
        case soundMatch = "sound-match"
        case sentenceFlow = "sentence-flow"
        case coastPlacement = "coast-placement"
    }

    private func studyApp(
        _ study: Study,
        appearance: String,
        extra: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--interaction-study", study.rawValue,
            "--interaction-study-missing-audio",
            "--transient-test-state",
            "--appearance", appearance,
        ] + extra
        return app
    }

    private func buildSentence(in app: XCUIApplication) {
        for token in ["is", "as", "maigh-eo", "me"] {
            tap("interaction-study-sentence-flow-tile-\(token)", in: app)
        }
    }

    private func waitForTask(_ number: Int, in app: XCUIApplication) {
        XCTAssertTrue(
            identified("interaction-study-coast-placement-task-\(number)", in: app)
                .waitForExistence(timeout: 4),
            "Coast Placement did not advance to task \(number)"
        )
    }

    private func tap(
        _ identifier: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let element = identified(identifier, in: app)
        XCTAssertTrue(
            element.waitForExistence(timeout: 5),
            "Missing control \(identifier)",
            file: file,
            line: line
        )
        for _ in 0..<8 where !element.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(
            element.isHittable,
            "Control is not hittable: \(identifier)",
            file: file,
            line: line
        )
        element.tap()
    }

    private func identified(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func keepScreenshot(named name: String, from app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
