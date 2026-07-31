import XCTest
@testable import AnTuras

/// D29 freeze: the nine-step Clew Bay representative run on the shared county
/// shell — fixture structure, the C1 turn graph, C3 targeting, C5 fixture
/// isolation, and exact resume persistence.
final class CountyFreezeRunTests: XCTestCase {
    private func fixturePack() throws -> CountyStoryPack {
        try XCTUnwrap(CountyFreezeRunFixture.pack())
    }

    // MARK: Fixture structure

    func testFixtureCarriesTheNineFrozenStepsInOrder() throws {
        let pack = try fixturePack()

        XCTAssertEqual(pack.id, CountyFreezeRunFixture.packID)
        XCTAssertEqual(pack.scope, .editorialPreview)
        XCTAssertFalse(pack.isReleaseCleared)
        XCTAssertEqual(pack.pages(for: .learning).map(\.id), CountyFreezeRunFixture.stepPageIDs)
        XCTAssertEqual(
            pack.pages(for: .learning).compactMap(\.exercise?.family),
            [
                .listenChoose, .matching, .sentenceConstruction, .freeTyping,
                .conversation, .recordCompare, .readRespond, .completion, .contextualReview,
            ]
        )
        XCTAssertEqual(Set(pack.completion.learningPageIDs), Set(CountyFreezeRunFixture.stepPageIDs))
        XCTAssertEqual(pack.targetWords.map(\.ga), ["farraige", "bá", "áit", "as"])
    }

    func testFixtureExercisePayloadsKeepTheFrozenMaterial() throws {
        let pack = try fixturePack()

        let listen = try XCTUnwrap(pack.page(id: "mayo.clew-bay.listen-farraige")?.exercise)
        XCTAssertEqual(listen.audioText, "farraige")
        XCTAssertEqual(listen.options.filter(\.isCorrect).map(\.text), ["sea"])

        let match = try XCTUnwrap(pack.page(id: "mayo.clew-bay.match-coast")?.exercise)
        XCTAssertEqual(match.pairs.map(\.left), ["farraige", "bá", "áit"])
        XCTAssertEqual(match.pairs.map(\.right), ["sea", "bay", "place"])
        XCTAssertTrue((2...4).contains(match.pairs.count))

        let build = try XCTUnwrap(pack.page(id: "mayo.clew-bay.build-origin")?.exercise)
        XCTAssertEqual(build.answer, "Is as Maigh Eo mé.")
        XCTAssertEqual(Set(build.tokens), ["Is", "as", "Maigh Eo", "mé."])

        let type = try XCTUnwrap(pack.page(id: "mayo.clew-bay.type-origin")?.exercise)
        XCTAssertEqual(type.answer, "Is as Maigh Eo mé.")
        XCTAssertNil(type.audioText, "Step 4 stays unsupported: no model replay")

        let speak = try XCTUnwrap(pack.page(id: "mayo.clew-bay.speak-origin")?.exercise)
        XCTAssertEqual(speak.audioText, "Is as Maigh Eo mé.")
    }

    func testFixtureAudioReferencesResolveToBundledClips() throws {
        let pack = try fixturePack()
        for resource in pack.resources where resource.kind == .audio {
            XCTAssertNotNil(
                SpeechService.bundledURL(for: resource.value),
                "Missing bundled clip for \(resource.value)"
            )
        }
    }

    // MARK: C1 conversation graph

    private func conversationGraph() throws -> CountyConversationGraph {
        let pack = try fixturePack()
        return try XCTUnwrap(pack.page(id: "mayo.clew-bay.conversation-origin")?.exercise?.conversation)
    }

    func testConversationGraphMeetsTheC1Contract() throws {
        let graph = try conversationGraph()

        XCTAssertEqual(graph.setting, "present-day")
        XCTAssertEqual(graph.node(id: graph.start)?.partner, "Cárb as tú?")
        XCTAssertGreaterThanOrEqual(graph.nodes.count, 2)
        let replies = graph.nodes.flatMap(\.replies)
        XCTAssertTrue(replies.contains { $0.isFitting && $0.next == nil }, "A terminal fitting reply must exist")
        XCTAssertTrue(graph.nodes.contains { $0.replies.filter(\.isFitting).count >= 2 }, "A genuine branch must exist")
    }

    func testConversationValidatorRejectsBrokenGraphs() throws {
        let graph = try conversationGraph()
        XCTAssertNoThrow(
            try CountyStoryPackValidator.validateConversationGraph(graph, pageID: "test")
        )

        let start = graph.nodes[0]
        let dangling = CountyConversationGraph(
            setting: graph.setting,
            start: graph.start,
            nodes: [
                CountyConversationNode(
                    id: start.id,
                    partner: start.partner,
                    partnerGloss: start.partnerGloss,
                    audioText: start.audioText,
                    replies: [
                        CountyConversationReply(
                            id: "origin", text: "Is as Maigh Eo mé.", gloss: nil,
                            isFitting: true, diagnostic: nil, next: "nowhere", audioText: nil
                        ),
                    ]
                ),
            ] + graph.nodes.dropFirst()
        )
        XCTAssertThrowsError(
            try CountyStoryPackValidator.validateConversationGraph(dangling, pageID: "test")
        )

        let flat = CountyConversationGraph(
            setting: graph.setting,
            start: graph.start,
            nodes: [start]
        )
        XCTAssertThrowsError(
            try CountyStoryPackValidator.validateConversationGraph(flat, pageID: "test")
        )

        let unset = CountyConversationGraph(
            setting: "",
            start: graph.start,
            nodes: graph.nodes
        )
        XCTAssertThrowsError(
            try CountyStoryPackValidator.validateConversationGraph(unset, pageID: "test")
        )
    }

    func testConversationWalksThreeTurnsAndTheBranchChangesALaterPartnerLine() throws {
        let graph = try conversationGraph()
        var state = CountyConversationEngine.initialState(for: graph)
        XCTAssertEqual(state.currentNodeID, "n1")

        // Turn 1: the origin line is the acceptable answer.
        guard case .advanced(let afterOrigin) = CountyConversationEngine.choose(replyID: "origin", in: state, graph: graph) else {
            return XCTFail("The origin line must advance the conversation")
        }
        state = afterOrigin
        XCTAssertEqual(state.currentNodeID, "n2")

        // Turn 2 branch A: asking back changes the next partner line.
        guard case .advanced(let askedBack) = CountyConversationEngine.choose(replyID: "ask-back", in: state, graph: graph) else {
            return XCTFail("Asking back must advance")
        }
        XCTAssertEqual(
            CountyConversationEngine.currentNode(in: askedBack, graph: graph)?.partner,
            "Is as Maigh Eo mé."
        )

        // Turn 2 branch B: giving a name changes it differently.
        guard case .advanced(let named) = CountyConversationEngine.choose(replyID: "name", in: state, graph: graph) else {
            return XCTFail("Giving a name must advance")
        }
        XCTAssertEqual(
            CountyConversationEngine.currentNode(in: named, graph: graph)?.partner,
            "Maith."
        )
        XCTAssertNotEqual(
            CountyConversationEngine.currentNode(in: askedBack, graph: graph)?.partner,
            CountyConversationEngine.currentNode(in: named, graph: graph)?.partner,
            "The branch must change a later partner line"
        )

        // Turn 3: closing completes the conversation.
        guard case .completed(let done) = CountyConversationEngine.choose(replyID: "close-b", in: askedBack, graph: graph) else {
            return XCTFail("The closing reply must complete the conversation")
        }
        XCTAssertEqual(done.turns.map(\.replyID), ["origin", "ask-back", "close-b"])
    }

    func testConversationMisfitNeverAdvancesAndStateRoundTripsForResume() throws {
        let graph = try conversationGraph()
        let start = CountyConversationEngine.initialState(for: graph)

        guard case .misfit(let diagnostic) = CountyConversationEngine.choose(replyID: "goodbye", in: start, graph: graph) else {
            return XCTFail("A mismatched turn must not advance")
        }
        XCTAssertTrue(diagnostic.contains("goodbye"))

        // Resume: one fitting turn persisted, then a relaunch restores the node.
        guard case .advanced(let mid) = CountyConversationEngine.choose(replyID: "origin", in: start, graph: graph) else {
            return XCTFail()
        }
        let data = try JSONEncoder().encode(mid)
        let restored = try JSONDecoder().decode(CountyConversationState.self, from: data)
        XCTAssertEqual(restored, mid)
        XCTAssertEqual(restored.currentNodeID, "n2")
        XCTAssertEqual(restored.turns, [CountyConversationTurnRecord(nodeID: "n1", replyID: "origin")])
        XCTAssertEqual(
            CountyConversationEngine.currentNode(in: restored, graph: graph)?.partner,
            "Cén t-ainm atá ort?"
        )
    }

    // MARK: C3 deterministic targeting

    func testContextualReviewTargetsTheEarliestStruggledCandidate() throws {
        let pack = try fixturePack()
        let review = try XCTUnwrap(pack.page(id: "mayo.clew-bay.review-struggle")?.exercise)
        let candidates = try XCTUnwrap(review.reviewCandidates)

        // No struggle: the authored default is the first candidate.
        XCTAssertEqual(
            CountyContextualReviewTargeting.candidate(from: candidates, struggledPageIDs: [])?.id,
            "sea-word"
        )
        // A typed-line struggle selects the origin-line re-entry.
        XCTAssertEqual(
            CountyContextualReviewTargeting.candidate(
                from: candidates,
                struggledPageIDs: ["mayo.clew-bay.type-origin"]
            )?.id,
            "origin-line"
        )
        // The earliest struggled candidate wins deterministically.
        XCTAssertEqual(
            CountyContextualReviewTargeting.candidate(
                from: candidates,
                struggledPageIDs: ["mayo.clew-bay.type-origin", "mayo.clew-bay.listen-farraige"]
            )?.id,
            "origin-line"
        )
        XCTAssertEqual(
            CountyContextualReviewTargeting.candidate(
                from: candidates,
                struggledPageIDs: ["mayo.clew-bay.listen-farraige", "mayo.clew-bay.type-origin"]
            )?.id,
            "sea-word"
        )
        // The re-entry keeps the original sound and response method.
        let seaWord = try XCTUnwrap(candidates.first { $0.id == "sea-word" })
        XCTAssertEqual(seaWord.exercise.family, .listenChoose)
        XCTAssertEqual(seaWord.exercise.audioText, "farraige")
        let originLine = try XCTUnwrap(candidates.first { $0.id == "origin-line" })
        XCTAssertEqual(originLine.exercise.family, .freeTyping)
        XCTAssertEqual(originLine.exercise.audioText, "Is as Maigh Eo mé.")
    }

    // MARK: Struggle record

    @MainActor
    func testStruggleRecordIsOrderedAndDeduplicated() throws {
        let pack = try fixturePack()
        let model = AtlasPrototypeModel()

        model.recordStruggle("mayo.clew-bay.listen-farraige", in: pack)
        model.recordStruggle("mayo.clew-bay.type-origin", in: pack)
        model.recordStruggle("mayo.clew-bay.listen-farraige", in: pack)
        model.recordStruggle("not.a.page", in: pack)

        XCTAssertEqual(
            model.struggledPageIDs(in: pack),
            ["mayo.clew-bay.listen-farraige", "mayo.clew-bay.type-origin"]
        )
    }

    // MARK: C5 fixture completion isolation

    @MainActor
    func testFixtureCompletionCannotAwardGoldArtifactOrScheduledReviews() throws {
        let pack = try fixturePack()
        let model = AtlasPrototypeModel()
        for id in pack.completion.learningPageIDs {
            model.markPageComplete(id, in: pack)
        }

        model.finish(pack, mode: .learning)

        XCTAssertTrue(model.hasCompleted(pack, mode: .learning))
        XCTAssertFalse(model.completedCountyStoryIDs.contains(pack.id))
        XCTAssertFalse(model.storyReadCountyIDs.contains(pack.id))
        XCTAssertFalse(model.madeArtifactIDs.contains(pack.id))
        XCTAssertFalse(model.inspectedEvidenceIDs.contains(pack.id))
        XCTAssertTrue(model.atlasReviews.keys.filter { $0.hasPrefix(pack.id) }.isEmpty)
        XCTAssertTrue(model.reviewCandidates().isEmpty)
    }

    @MainActor
    func testFixtureCollectionHandoffStaysFixtureScoped() throws {
        let pack = try fixturePack()
        let model = AtlasPrototypeModel()

        model.recordFixtureCollection(["farraige", "bá"], in: pack)
        model.recordFixtureCollection(["bá", "áit", "as"], in: pack)

        XCTAssertEqual(model.fixtureCollections[pack.id], ["farraige", "bá", "áit", "as"])
        XCTAssertTrue(model.atlasReviews.isEmpty, "The fixture handoff must not seed the scheduler")

        // The handoff persists across a restore, still fixture-scoped.
        let restored = AtlasPrototypeModel()
        restored.restore(model.progressSnapshot)
        XCTAssertEqual(restored.fixtureCollections[pack.id], ["farraige", "bá", "áit", "as"])
    }

    // MARK: Resume persistence across a restore

    @MainActor
    func testConversationStateAndStrugglesSurviveARestore() throws {
        let pack = try fixturePack()
        let model = AtlasPrototypeModel()
        let state = CountyConversationState(
            turns: [CountyConversationTurnRecord(nodeID: "n1", replyID: "origin")],
            currentNodeID: "n2"
        )

        _ = model.begin(pack, mode: .learning)
        model.setActivePage("mayo.clew-bay.conversation-origin", in: pack)
        model.saveConversationState(state, for: "mayo.clew-bay.conversation-origin")
        model.recordStruggle("mayo.clew-bay.listen-farraige", in: pack)

        let restored = AtlasPrototypeModel()
        restored.restore(model.progressSnapshot)

        XCTAssertEqual(restored.conversationState(for: "mayo.clew-bay.conversation-origin"), state)
        XCTAssertEqual(restored.struggledPageIDs(in: pack), ["mayo.clew-bay.listen-farraige"])
        XCTAssertEqual(
            restored.resumePageID(for: pack, mode: .learning),
            "mayo.clew-bay.conversation-origin"
        )
    }

    func testRunRecordsRoundTripThroughSavedProgressJSON() throws {
        let state = CountyConversationState(
            turns: [
                CountyConversationTurnRecord(nodeID: "n1", replyID: "origin"),
                CountyConversationTurnRecord(nodeID: "n2", replyID: "ask-back"),
            ],
            currentNodeID: "n3b"
        )
        let progress = AppState.AtlasProgress(
            countyExerciseStruggles: ["mayo.clew-bay-freeze": ["mayo.clew-bay.listen-farraige"]],
            countyConversationStates: ["mayo.clew-bay.conversation-origin": state],
            fixtureCollections: ["mayo.clew-bay-freeze": ["farraige", "bá"]]
        )

        let data = try JSONEncoder().encode(progress)
        let decoded = try JSONDecoder().decode(AppState.AtlasProgress.self, from: data)

        XCTAssertEqual(decoded, progress)
        XCTAssertEqual(decoded.countyConversationStates["mayo.clew-bay.conversation-origin"], state)
        XCTAssertEqual(
            decoded.countyExerciseStruggles["mayo.clew-bay-freeze"],
            ["mayo.clew-bay.listen-farraige"]
        )
        XCTAssertEqual(decoded.fixtureCollections["mayo.clew-bay-freeze"], ["farraige", "bá"])
    }

    @MainActor
    func testClearRunRecordsWipesStrugglesConversationsAndCollection() throws {
        let pack = try fixturePack()
        let model = AtlasPrototypeModel()
        model.recordStruggle("mayo.clew-bay.listen-farraige", in: pack)
        model.saveConversationState(
            CountyConversationState(turns: [], currentNodeID: "n2"),
            for: "mayo.clew-bay.conversation-origin"
        )
        model.recordFixtureCollection(["farraige"], in: pack)

        model.clearRunRecords(for: pack)

        XCTAssertTrue(model.struggledPageIDs(in: pack).isEmpty)
        XCTAssertNil(model.conversationState(for: "mayo.clew-bay.conversation-origin"))
        XCTAssertNil(model.fixtureCollections[pack.id])
    }
}
