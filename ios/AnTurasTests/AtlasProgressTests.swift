import XCTest
@testable import AnTuras

final class AtlasProgressTests: XCTestCase {
    func testAtlasProgressRoundTripsThroughSavedState() throws {
        var saved = AppState.Saved()
        saved.atlasProgress = AppState.AtlasProgress(
            hasOpenedAtlas: false,
            evidenceInspected: true,
            storyCompleted: false,
            fieldNoteVisited: true,
            returnAnswered: false,
            storyInProgress: true,
            storyStep: 2,
            storyFoundName: true
        )

        let data = try JSONEncoder().encode(saved)
        let decoded = try JSONDecoder().decode(AppState.Saved.self, from: data)

        XCTAssertEqual(decoded.atlasProgress, saved.atlasProgress)
    }

    func testOlderSavedStateDefaultsAtlasProgress() throws {
        let decoded = try JSONDecoder().decode(
            AppState.Saved.self,
            from: Data("{}".utf8)
        )

        XCTAssertEqual(decoded.atlasProgress, AppState.AtlasProgress())
    }

    @MainActor
    func testAtlasModelRestoresAndClampsStoryStep() {
        let model = AtlasPrototypeModel()
        model.restore(
            AppState.AtlasProgress(
                storyInProgress: true,
                storyStep: 99,
                storyFoundName: true
            )
        )

        XCTAssertTrue(model.storyInProgress)
        XCTAssertEqual(model.storyStep, 17)
        XCTAssertTrue(model.storyFoundName)
    }

    @MainActor
    func testFourStepEncounterMigratesIntoEpisodeFour() {
        let model = AtlasPrototypeModel()
        model.restore(
            AppState.AtlasProgress(
                storyInProgress: true,
                storyStep: 2,
                storyFoundName: true,
                storyArcVersion: 1
            )
        )

        XCTAssertEqual(model.storyStep, 11)
        XCTAssertTrue(model.storyFoundName)
    }

    @MainActor
    func testSixEpisodeProgressFiltersInvalidAndDuplicateBeats() {
        let model = AtlasPrototypeModel()
        model.restore(
            AppState.AtlasProgress(
                storyInProgress: true,
                storyStep: 14,
                storyArcVersion: 2,
                completedStoryBeats: [0, 2, 2, 14, 18, -1]
            )
        )

        XCTAssertEqual(model.storyStep, 14)
        XCTAssertEqual(model.completedStoryBeats, [0, 2, 14])
    }

    @MainActor
    func testCompletingStoryPreservesVoyageProgressForRevisit() {
        let model = AtlasPrototypeModel()
        model.storyInProgress = true
        model.storyStep = 17
        model.storyFoundName = true
        model.completedStoryBeats = [2, 5, 8, 11, 14, 17]

        model.completeStory()

        XCTAssertTrue(model.storyCompleted)
        XCTAssertFalse(model.storyInProgress)
        XCTAssertEqual(model.storyStep, 17)
        XCTAssertTrue(model.storyFoundName)
        XCTAssertEqual(model.completedStoryBeats, [2, 5, 8, 11, 14, 17])
    }

    @MainActor
    func testMayoCarriesTheApprovedTwentyHeadwords() {
        let model = AtlasPrototypeModel()

        XCTAssertEqual(
            model.carriedWords.map(\.ga),
            [
                "farraige", "bá", "long", "áit", "as",
                "caisleán", "teaghlach", "mac", "bean", "caill",
                "deartháir", "iarr", "téigh", "ainm", "mise", "tar",
                "freagair", "tabhair", "arís", "cósta",
            ]
        )
        XCTAssertEqual(Set(model.carriedWords.map(\.ga)).count, 20)
    }

    func testLegacyCountyCatalogRemainsReadableDuringPagePackMigration() {
        XCTAssertEqual(LaunchCountyCatalog.stories.map(\.countyEn), ["Offaly", "Dublin", "Meath"])

        for story in LaunchCountyCatalog.stories {
            XCTAssertEqual(story.words.count, 20, "\(story.countyEn) must carry exactly twenty words")
            XCTAssertEqual(Set(story.words.map(\.ga)).count, 20, "\(story.countyEn) headwords must be unique")
            XCTAssertFalse(story.episodes.isEmpty)
            XCTAssertTrue(story.episodes.allSatisfy { !$0.beats.isEmpty })
            XCTAssertEqual(Set(story.beats.map(\.id)).count, story.beats.count)
            XCTAssertFalse(story.sourceFacts.isEmpty)
            XCTAssertEqual(story.clearance, .editorialPreview)
            XCTAssertFalse(story.reviewGate.isEmpty)
            XCTAssertTrue(story.tegLevel.hasPrefix("TEG"))
        }
    }

    func testVersionTwoCatalogLoadsAndValidatesAllFourCountyPacks() throws {
        XCTAssertEqual(
            CountyStoryPackCatalog.packs.map(\.id),
            [
                "mayo.grainne-1593",
                "offaly.cross-of-the-scriptures",
                "dublin.sihtric-penny",
                "meath.trim-de-lacy",
            ]
        )

        for envelope in CountyStoryPackCatalog.envelopes {
            let report = try CountyStoryPackValidator.validate(envelope)
            XCTAssertGreaterThan(report.storyMinutes, 0)
            XCTAssertGreaterThan(report.learningMinutes, 0)
            XCTAssertEqual(envelope.pack.targetWords.count, 20)
            XCTAssertEqual(Set(envelope.pack.pages.map(\.id)).count, envelope.pack.pages.count)
        }
    }

    func testRockfleetPackProjectsOneSequenceIntoTwoHonestModes() throws {
        let pack = try XCTUnwrap(CountyStoryPackCatalog.pack(id: "mayo.grainne-1593"))
        let envelope = try XCTUnwrap(CountyStoryPackCatalog.envelopes.first { $0.pack.id == pack.id })
        let report = try CountyStoryPackValidator.validate(envelope)

        XCTAssertEqual(pack.scope, .representativeChapter)
        XCTAssertTrue(pack.pages(for: .story).allSatisfy { $0.kind == .narrative })
        XCTAssertEqual(Set(pack.pages.compactMap(\.exercise).map(\.family)), Set(CountyExerciseFamily.allCases))
        XCTAssertGreaterThanOrEqual(pack.pages(for: .story).count, 10)
        XCTAssertGreaterThanOrEqual(pack.pages(for: .learning).count, 15)
        XCTAssertGreaterThan(report.storyMinutes, 14)
        XCTAssertGreaterThan(report.learningMinutes, 20)
        XCTAssertEqual(report.lifecycleComplete, 2)
        XCTAssertTrue(report.missingAudioIDs.isEmpty)
    }

    func testRockfleetBundledAudioReferencesExist() throws {
        let pack = try XCTUnwrap(CountyStoryPackCatalog.pack(id: "mayo.grainne-1593"))
        let audio = pack.resources.filter { $0.kind == .audio && $0.status == "bundled" }

        XCTAssertFalse(audio.isEmpty)
        for resource in audio {
            XCTAssertNotNil(
                SpeechService.bundledURL(for: resource.value),
                "Missing bundled audio for \(resource.value)"
            )
        }
    }

    @MainActor
    func testModeSwitchKeepsSharedProgressAndMovesToNextIncompletePage() throws {
        let pack = try XCTUnwrap(CountyStoryPackCatalog.pack(id: "mayo.grainne-1593"))
        let model = AtlasPrototypeModel()
        let firstStory = try XCTUnwrap(model.begin(pack, mode: .story))

        XCTAssertEqual(firstStory, "mayo.rockfleet.arrival")
        model.markPageComplete(firstStory, in: pack)
        let learningPage = try XCTUnwrap(model.switchMode(in: pack, to: .learning))

        XCTAssertEqual(learningPage, "mayo.rockfleet.listen-caislean")
        XCTAssertTrue(model.isPageComplete("mayo.rockfleet.arrival", in: pack.id))
        XCTAssertEqual(model.mode(for: pack.id), .learning)
    }

    @MainActor
    func testStablePageResumeRoundTripsExactly() throws {
        let pack = try XCTUnwrap(CountyStoryPackCatalog.pack(id: "mayo.grainne-1593"))
        let pageID = "mayo.rockfleet.build-household"
        let model = AtlasPrototypeModel()
        _ = model.begin(pack, mode: .learning)
        model.setActivePage(pageID, in: pack)
        model.markPageComplete("mayo.rockfleet.arrival", in: pack)

        let restored = AtlasPrototypeModel()
        restored.restore(model.progressSnapshot)

        XCTAssertEqual(restored.mode(for: pack.id), .learning)
        XCTAssertEqual(restored.resumePageID(for: pack, mode: .learning), pageID)
        XCTAssertTrue(restored.isPageComplete("mayo.rockfleet.arrival", in: pack.id))
    }

    @MainActor
    func testLegacyMayoBeatProgressMigratesToStableRockfleetPages() throws {
        let pack = try XCTUnwrap(CountyStoryPackCatalog.pack(id: "mayo.grainne-1593"))
        let model = AtlasPrototypeModel()
        model.restore(
            AppState.AtlasProgress(
                storyInProgress: true,
                storyStep: 5,
                storyArcVersion: 2,
                completedStoryBeats: [3, 5]
            )
        )

        XCTAssertTrue(model.isPageComplete("mayo.rockfleet.arrival", in: pack.id))
        XCTAssertTrue(model.isPageComplete("mayo.rockfleet.listen-caislean", in: pack.id))
        XCTAssertEqual(model.activeCountyPageIDs[pack.id], "mayo.rockfleet.listen-caislean")
        XCTAssertEqual(model.countyPackVersions[pack.id], pack.revision)
        XCTAssertEqual(model.completedStoryBeats, [3, 5], "Legacy evidence must remain intact")
    }

    @MainActor
    func testRepresentativeChapterCannotAwardMayoGoldOrWords() throws {
        let pack = try XCTUnwrap(CountyStoryPackCatalog.pack(id: "mayo.grainne-1593"))
        let model = AtlasPrototypeModel()
        for id in pack.completion.learningPageIDs { model.markPageComplete(id, in: pack) }

        model.finish(pack, mode: .learning)

        XCTAssertFalse(model.completedCountyStoryIDs.contains(pack.id))
        XCTAssertFalse(model.storyReadCountyIDs.contains(pack.id))
        XCTAssertTrue(model.atlasReviews.keys.filter { $0.hasPrefix(pack.id) }.isEmpty)
    }

    func testCountyPackEnvelopeRoundTripsAndPassesOfflineValidation() throws {
        let envelope = LaunchCountyPackEnvelope(
            schemaVersion: LaunchCountyPackStore.schemaVersion,
            story: LaunchCountyCatalog.offaly
        )
        let data = try JSONEncoder().encode(envelope)
        let decoded = try JSONDecoder().decode(LaunchCountyPackEnvelope.self, from: data)

        XCTAssertNoThrow(try LaunchCountyPackStore.validate(decoded))
        XCTAssertEqual(decoded.story.id, LaunchCountyCatalog.offaly.id)
        XCTAssertEqual(decoded.story.words.count, 20)
        XCTAssertEqual(decoded.story.beats.count, 12)
    }

    func testPhaseThreeProgressRoundTripsWithoutLosingCountyState() throws {
        let review = AppState.AtlasReviewProgress(
            due: Date(timeIntervalSince1970: 1_800_000_000),
            stability: 3.5,
            difficulty: 4.2,
            reps: 2,
            lapses: 1
        )
        let progress = AppState.AtlasProgress(
            storyCompleted: true,
            activeCountyStoryID: "dublin.sihtric-penny",
            completedCountyStoryIDs: ["mayo.grainne-1593", "offaly.cross-of-the-scriptures"],
            countyStorySteps: ["dublin.sihtric-penny": 5],
            completedCountyStoryBeats: ["dublin.sihtric-penny": [0, 1, 2]],
            countyStoryModes: ["mayo.grainne-1593": "learning"],
            activeCountyPageIDs: ["mayo.grainne-1593": "mayo.rockfleet.household"],
            completedCountyPageIDs: ["mayo.grainne-1593": ["mayo.rockfleet.arrival"]],
            storyReadCountyIDs: ["mayo.grainne-1593"],
            countyPackVersions: ["mayo.grainne-1593": 3],
            inspectedEvidenceIDs: ["offaly.cross-of-the-scriptures"],
            madeArtifactIDs: ["offaly.cross-of-the-scriptures"],
            atlasReviews: ["review": review],
            calendarDaysVisited: ["2026-07-14"]
        )

        let data = try JSONEncoder().encode(progress)
        let decoded = try JSONDecoder().decode(AppState.AtlasProgress.self, from: data)

        XCTAssertEqual(decoded, progress)
    }

    @MainActor
    func testCompletingCountyCarriesWordsEvidenceArtifactAndReviews() {
        let model = AtlasPrototypeModel()
        let story = LaunchCountyCatalog.offaly

        model.completeCountyStory(story)

        XCTAssertTrue(model.isCountyComplete(story.id))
        XCTAssertTrue(model.hasInspectedEvidence(story.id))
        XCTAssertTrue(model.madeArtifactIDs.contains(story.id))
        XCTAssertEqual(model.completedCountyStoryBeats[story.id], Array(0..<12))
        XCTAssertEqual(model.reviewCandidates().filter { $0.storyID == story.id }.count, 20)
        XCTAssertEqual(model.atlasReviews.keys.filter { $0.hasPrefix(story.id) }.count, 20)
    }

    @MainActor
    func testReviewRecoveryReturnsSoonerThanCleanRecall() throws {
        let model = AtlasPrototypeModel()
        let story = LaunchCountyCatalog.dublin
        model.completeCountyStory(story)
        let candidate = try XCTUnwrap(model.reviewCandidates().first { $0.storyID == story.id })
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        model.completeReview(candidate, struggled: true, now: now)
        let recovery = try XCTUnwrap(model.atlasReviews[candidate.id])
        XCTAssertEqual(recovery.lapses, 1)
        XCTAssertEqual(Calendar.current.dateComponents([.day], from: now, to: recovery.due).day, 1)

        model.completeReview(candidate, struggled: false, now: recovery.due)
        let clean = try XCTUnwrap(model.atlasReviews[candidate.id])
        XCTAssertGreaterThan(clean.stability, recovery.stability)
        XCTAssertGreaterThan(clean.due, recovery.due)
    }
}
