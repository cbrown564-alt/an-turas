import XCTest
@testable import AnTuras

final class LearningMechanicsPrototypeTests: XCTestCase {
    func testFixedClewBayExerciseCopiesMatchRevisionSixPayloadsExactly() {
        XCTAssertEqual(
            ClewBayLearningPrototypeFixture.learningQuestion,
            "Can Clew Bay help you connect farraige to place and produce the Mayo origin line without reading the answer?"
        )
        XCTAssertEqual(
            ClewBayLearningPrototypeFixture.storyContext,
            "Mayo's western edge opens onto the farraige — the sea. Here the water is not a border at the end of the land. It is the road, the larder and the source of power. To understand Gráinne Ní Mháille, begin with the sea her people worked."
        )
        XCTAssertEqual(
            ClewBayLearningPrototypeFixture.placeContext,
            "The territory around the bay had a name: Umhaill, the Owles. It was a specific áit — a place — with its own people, boundaries and loyalties. Naming it matters: the story is not about a coast in general but about this one, and who held it."
        )
        XCTAssertEqual(
            ClewBayLearningPrototypeFixture.originContext,
            "In Irish you can place yourself with a small frame: as, meaning 'from'. Is as Maigh Eo mé — I am from Mayo. Gráinne's world begins with origin: which coast, which people, which bay you belong to."
        )

        let expected = [
            ClewBayPrototypeExercise(
                id: "mayo.clew-bay.listen-farraige",
                title: "Hear the sea before you read it",
                context: "Farraige · sea",
                body: "The word belongs to the water you are looking at.",
                objective: "Recognise farraige by sound as the sea that defines this coast.",
                prompt: "Listen, then choose the meaning that belongs to this coast.",
                answer: "sea",
                options: [
                    .init(
                        id: "sea",
                        text: "sea",
                        isCorrect: true,
                        rationale: "Farraige means the sea."
                    ),
                    .init(
                        id: "island",
                        text: "island",
                        isCorrect: false,
                        rationale: "That names the land in the water, not the water itself."
                    ),
                    .init(
                        id: "castle",
                        text: "castle",
                        isCorrect: false,
                        rationale: "Caisleán means castle; this word names the open water."
                    ),
                ],
                tokens: [],
                pairs: [],
                translation: "sea",
                audioText: "farraige",
                modelText: nil,
                feedback: "Farraige is the sea that makes this coast a working world.",
                hint: "Listen for the rolling middle sound: far-ig-eh.",
                recovery: "That answer names something on the water rather than the water. Replay farraige and try again.",
                lexemeIDs: ["lex.farraige"]
            ),
            ClewBayPrototypeExercise(
                id: "mayo.clew-bay.build-origin",
                title: "Build a line of origin",
                context: "Is as Maigh Eo mé · I am from Mayo",
                body: "Use the frame to place yourself on this coast.",
                objective: "Produce a complete origin sentence with the as … mé frame.",
                prompt: "Build: I am from Mayo.",
                answer: "Is as Maigh Eo mé.",
                options: [],
                tokens: ["as", "Maigh Eo", "Is", "mé."],
                pairs: [],
                translation: "I am from Mayo.",
                audioText: nil,
                modelText: "Is as Maigh Eo mé.",
                feedback: "Is as Maigh Eo mé — origin stated in one clean frame.",
                hint: "The frame runs Is as [place] mé.",
                recovery: "Every word is needed. Keep the order Is · as · the place · mé.",
                lexemeIDs: ["lex.as"]
            ),
            ClewBayPrototypeExercise(
                id: "mayo.clew-bay.match-coast",
                title: "Keep the coast's words distinct",
                context: "Three words · one coast",
                body: "Match each Irish word to what it names on this coast.",
                objective: "Connect the opening headwords to their meanings.",
                prompt: "Choose an Irish word, then the meaning that belongs with it.",
                answer: "all pairs",
                options: [],
                tokens: [],
                pairs: [
                    .init(id: "farraige", left: "farraige", right: "sea"),
                    .init(id: "ba", left: "bá", right: "bay"),
                    .init(id: "ait", left: "áit", right: "place"),
                ],
                translation: nil,
                audioText: nil,
                modelText: nil,
                feedback: "Sea, bay and place — the coast now has three distinct names.",
                hint: "Replay the words. Farraige is the open water; bá is the sheltered inlet; áit is the named coast.",
                recovery: "Those two do not belong together. Keep the first word selected and try another meaning.",
                lexemeIDs: ["lex.farraige", "lex.ba", "lex.ait"]
            ),
        ]

        XCTAssertEqual(ClewBayLearningPrototypeFixture.exercises, expected)
        XCTAssertEqual(
            Set(ClewBayLearningPrototypeFixture.exercises.map(\.id)).count,
            expected.count,
            "The comparison fixture must preserve three unique source ids."
        )
    }

    func testThreeDirectionsDeclareMateriallyDistinctMechanics() {
        let directions = LearningPrototypeDirection.allCases

        XCTAssertEqual(
            directions.map(\.rawValue),
            ["ear-first", "guided-construction", "coastline-reasoning"]
        )
        XCTAssertEqual(
            directions.map(\.title),
            ["Ear-first Retrieval", "Guided Construction", "Coastline Reasoning"]
        )
        XCTAssertEqual(Set(directions.map(\.shortSummary)).count, directions.count)
        XCTAssertEqual(Set(directions.map(\.tradeoff)).count, directions.count)

        for direction in directions {
            XCTAssertGreaterThanOrEqual(
                direction.changedDimensions.count,
                2,
                "\(direction.title) must change at least two pedagogical mechanic dimensions."
            )
            XCTAssertGreaterThanOrEqual(
                direction.reusablePrimitives.count,
                2,
                "\(direction.title) must name reusable mechanics beyond this Mayo slice."
            )
        }

        for firstIndex in directions.indices {
            for secondIndex in directions.indices where secondIndex > firstIndex {
                let first = directions[firstIndex]
                let second = directions[secondIndex]
                let difference = first.changedDimensions.symmetricDifference(
                    second.changedDimensions
                )
                XCTAssertGreaterThanOrEqual(
                    difference.count,
                    2,
                    "\(first.title) and \(second.title) must differ across at least two mechanic dimensions."
                )
            }
        }
    }

    func testOriginAnswerNormalizationPreservesIrishWhileIgnoringPresentationNoise() {
        XCTAssertTrue(
            ClewBayLearningPrototypeFixture.isOriginAnswer(
                "\n  is   as\tMAIGH EO   me\u{301}.  "
            ),
            "Canonical Unicode, case and surrounding whitespace should not change a correct answer."
        )
        XCTAssertEqual(
            ClewBayLearningPrototypeFixture.normalizedSentence(
                "  IS  AS \n Maigh Eo\tmé. "
            ),
            "is as maigh eo mé."
        )
        XCTAssertFalse(
            ClewBayLearningPrototypeFixture.isOriginAnswer("Is as Maigh Eo me."),
            "A missing fada changes the Irish answer."
        )
        XCTAssertFalse(
            ClewBayLearningPrototypeFixture.isOriginAnswer("Is as Maigh Eo mé"),
            "The fixed fixture requires its authored punctuation."
        )
        XCTAssertFalse(
            ClewBayLearningPrototypeFixture.isOriginAnswer("As Maigh Eo mé."),
            "Normalization must not hide a missing word."
        )
    }

    func testFixedSliceTeachingAudioIsBundled() {
        let expectedClips = [
            ("farraige", "farraige.mp3"),
            ("bá", "baa.mp3"),
            ("áit", "aait.mp3"),
            ("Is as Maigh Eo mé.", "is-as-maigh-eo-mee.mp3"),
        ]

        for (text, expectedFile) in expectedClips {
            let url = SpeechService.bundledURL(for: text)
            XCTAssertNotNil(url, "Missing bundled prototype audio for \(text)")
            XCTAssertEqual(url?.lastPathComponent, expectedFile)
        }
    }
}
