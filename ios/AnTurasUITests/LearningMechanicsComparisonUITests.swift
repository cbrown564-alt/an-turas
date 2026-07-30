import XCTest

final class LearningMechanicsComparisonUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testComparisonListsTheFixedQuestionFixturesAndDistinctDirections() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--learning-comparison",
            "--transient-test-state",
        ]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Three ways to learn from Clew Bay"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.staticTexts[
                "Can Clew Bay help you connect farraige to place and produce the Mayo origin line without reading the answer?"
            ].exists
        )

        for fixtureID in [
            "mayo.clew-bay.listen-farraige",
            "mayo.clew-bay.build-origin",
            "mayo.clew-bay.match-coast",
        ] {
            XCTAssertTrue(app.staticTexts[fixtureID].exists, "Missing fixed fixture \(fixtureID)")
        }

        for directionID in [
            "prototype-direction-ear-first",
            "prototype-direction-guided-construction",
            "prototype-direction-coastline-reasoning",
        ] {
            XCTAssertTrue(
                identified(directionID, in: app).exists,
                "Missing comparison direction \(directionID)"
            )
        }

        for _ in 0..<8 where !identified("prototype-isolation-note", in: app).exists {
            app.swipeUp()
        }
        XCTAssertTrue(identified("prototype-isolation-note", in: app).exists)
    }

    func testEarFirstRetrievalRequiresRecoveryAndCompletesWithoutAudio() {
        let app = prototypeApp(.earFirst, appearance: "light", missingAudio: true)
        app.launch()

        tap("prototype-begin", in: app)
        XCTAssertTrue(identified("ear-first-audio-missing", in: app).waitForExistence(timeout: 3))
        XCTAssertTrue(identified("ear-first-audio-text-alternative", in: app).exists)

        tap("ear-first-listen-island", in: app)
        XCTAssertTrue(identified("ear-first-listen-feedback", in: app).waitForExistence(timeout: 2))
        tap("ear-first-listen-retry", in: app)
        tap("ear-first-listen-sea", in: app)
        tap("ear-first-listen-continue", in: app)

        type("Is as Mayo me.", into: "ear-first-origin-field", in: app)
        tap("ear-first-origin-check", in: app)
        XCTAssertTrue(identified("ear-first-origin-feedback", in: app).waitForExistence(timeout: 2))
        tap("ear-first-origin-retry", in: app)
        type("Is as Maigh Eo mé.", into: "ear-first-origin-field", in: app)
        tap("ear-first-origin-check", in: app)
        tap("ear-first-origin-continue", in: app)

        tap("ear-first-coast-word-farraige", in: app)
        tap("ear-first-coast-meaning-ba", in: app)
        XCTAssertTrue(identified("ear-first-coast-feedback", in: app).waitForExistence(timeout: 2))
        tap("ear-first-coast-meaning-farraige", in: app)
        tap("ear-first-coast-word-ba", in: app)
        tap("ear-first-coast-meaning-ba", in: app)
        tap("ear-first-coast-word-ait", in: app)
        tap("ear-first-coast-meaning-ait", in: app)
        tap("ear-first-coast-continue", in: app)

        XCTAssertTrue(
            app.descendants(matching: .any)["prototype-complete-ear-first"]
                .waitForExistence(timeout: 3)
        )
        keepScreenshot(named: "Ear-first Retrieval completion", from: app)
    }

    func testGuidedConstructionChangesTheNextAttemptAndRemovesSupport() {
        let app = prototypeApp(.guidedConstruction, appearance: "dark", missingAudio: true)
        app.launch()

        tap("prototype-begin", in: app)
        XCTAssertTrue(identified("guided-listen-support", in: app).waitForExistence(timeout: 3))
        tap("guided-listen-sea", in: app)
        tap("guided-listen-continue", in: app)

        tap("guided-coast-word-farraige", in: app)
        tap("guided-coast-meaning-ba", in: app)
        XCTAssertTrue(identified("guided-coast-feedback", in: app).waitForExistence(timeout: 2))
        tap("guided-coast-meaning-farraige", in: app)
        tap("guided-coast-word-ba", in: app)
        tap("guided-coast-meaning-ba", in: app)
        tap("guided-coast-word-ait", in: app)
        tap("guided-coast-meaning-ait", in: app)
        tap("guided-coast-continue", in: app)

        for token in ["as", "Maigh Eo", "Is", "mé."] {
            tap("guided-build-bank-\(token)", in: app)
        }
        tap("guided-build-check", in: app)
        XCTAssertTrue(identified("guided-build-feedback", in: app).waitForExistence(timeout: 2))
        tap("guided-build-retry", in: app)
        XCTAssertTrue(identified("guided-build-worked-start", in: app).waitForExistence(timeout: 2))

        for token in ["as", "Maigh Eo", "mé."] {
            tap("guided-build-bank-\(token)", in: app)
        }
        tap("guided-build-check", in: app)
        tap("guided-build-continue", in: app)

        XCTAssertTrue(
            app.staticTexts["The role labels are gone. Retrieve the same complete origin sentence once more."]
                .waitForExistence(timeout: 3)
        )
        for token in ["Is", "as", "Maigh Eo", "mé."] {
            tap("guided-recall-bank-\(token)", in: app)
        }
        tap("guided-recall-check", in: app)
        tap("guided-recall-continue", in: app)

        XCTAssertTrue(
            app.descendants(matching: .any)["prototype-complete-guided-construction"]
                .waitForExistence(timeout: 3)
        )
        keepScreenshot(named: "Guided Construction completion", from: app)
    }

    func testCoastlineReasoningWithdrawsTheVisualAfterRecovery() {
        let app = prototypeApp(.coastlineReasoning, appearance: "light", missingAudio: true)
        app.launch()

        tap("prototype-begin", in: app)
        tap("coastline-word-ba", in: app)
        tap("coastline-region-open-water", in: app)
        XCTAssertTrue(identified("coastline-map-feedback", in: app).waitForExistence(timeout: 2))
        tap("coastline-region-sheltered-inlet", in: app)
        tap("coastline-word-farraige", in: app)
        tap("coastline-region-open-water", in: app)
        tap("coastline-word-ait", in: app)
        tap("coastline-region-named-coast", in: app)
        tap("coastline-map-continue", in: app)

        tap("coastline-listen-island", in: app)
        XCTAssertTrue(identified("coastline-listen-feedback", in: app).waitForExistence(timeout: 2))
        tap("coastline-listen-retry", in: app)
        tap("coastline-listen-sea", in: app)
        tap("coastline-listen-continue", in: app)

        XCTAssertFalse(app.staticTexts["Coast profile from open water to named land"].exists)
        type("Is as Mayo me.", into: "coastline-origin-field", in: app)
        tap("coastline-origin-check", in: app)
        XCTAssertTrue(identified("coastline-origin-feedback", in: app).waitForExistence(timeout: 2))
        tap("coastline-origin-retry", in: app)
        XCTAssertTrue(identified("coastline-origin-support", in: app).waitForExistence(timeout: 2))
        type("Is as Maigh Eo mé.", into: "coastline-origin-field", in: app)
        tap("coastline-origin-check", in: app)
        tap("coastline-origin-continue", in: app)

        XCTAssertTrue(
            app.descendants(matching: .any)["prototype-complete-coastline-reasoning"]
                .waitForExistence(timeout: 3)
        )
        keepScreenshot(named: "Coastline Reasoning completion", from: app)
    }

    func testBundledAudioCanReplayAndExposeATextAlternative() {
        let app = prototypeApp(.earFirst, appearance: "light", missingAudio: false)
        app.launch()

        tap("prototype-begin", in: app)
        let audio = identified("ear-first-audio", in: app)
        XCTAssertTrue(audio.waitForExistence(timeout: 3))
        audio.tap()
        XCTAssertEqual(audio.label, "Replay farraige")

        tap("ear-first-audio-fallback", in: app)
        XCTAssertTrue(identified("ear-first-audio-text-alternative", in: app).exists)
        XCTAssertTrue(identified("ear-first-listen-sea", in: app).exists)
    }

    func testEveryDirectionKeepsItsFirstResponseAndSafeActionAtLargestType() {
        for direction in PrototypeDirection.allCases {
            for appearance in ["light", "dark"] {
                let app = prototypeApp(
                    direction,
                    appearance: appearance,
                    missingAudio: true,
                    extra: [
                        "--prototype-reduce-motion",
                        "-UIPreferredContentSizeCategoryName",
                        "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
                    ]
                )
                app.launch()

                let begin = identified("prototype-begin", in: app)
                XCTAssertTrue(
                    begin.waitForExistence(timeout: 5),
                    "\(direction.rawValue) lost its safe-area action in \(appearance)"
                )
                for _ in 0..<4 where !begin.isHittable { app.swipeUp() }
                XCTAssertTrue(begin.isHittable)
                begin.tap()

                switch direction {
                case .earFirst:
                    XCTAssertTrue(
                        identified("ear-first-listen-sea", in: app)
                            .waitForExistence(timeout: 3)
                    )
                case .guidedConstruction:
                    XCTAssertTrue(
                        identified("guided-listen-sea", in: app)
                            .waitForExistence(timeout: 3)
                    )
                case .coastlineReasoning:
                    XCTAssertTrue(
                        identified("coastline-region-open-water", in: app)
                            .waitForExistence(timeout: 3)
                    )
                }

                app.terminate()
            }
        }
    }

    private enum PrototypeDirection: String, CaseIterable {
        case earFirst = "ear-first"
        case guidedConstruction = "guided-construction"
        case coastlineReasoning = "coastline-reasoning"
    }

    private func prototypeApp(
        _ direction: PrototypeDirection,
        appearance: String,
        missingAudio: Bool,
        extra: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--learning-prototype", direction.rawValue,
            "--appearance", appearance,
            "--transient-test-state",
        ] + (missingAudio ? ["--prototype-missing-audio"] : []) + extra
        return app
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
            "Missing button \(identifier)",
            file: file,
            line: line
        )
        for _ in 0..<8 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(
            element.isHittable,
            "Button is not hittable: \(identifier)",
            file: file,
            line: line
        )
        element.tap()
    }

    private func type(
        _ value: String,
        into identifier: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let field = identified(identifier, in: app)
        XCTAssertTrue(
            field.waitForExistence(timeout: 5),
            "Missing field \(identifier)",
            file: file,
            line: line
        )
        for _ in 0..<4 where !field.isHittable { app.swipeUp() }
        XCTAssertTrue(field.isHittable, file: file, line: line)
        field.tap()
        field.typeText(value)
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
