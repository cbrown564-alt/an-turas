import XCTest
import UIKit
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

    func testAtlasPresentationCatalogIsProjectedFromVersionTwoPacks() {
        XCTAssertEqual(LaunchCountyCatalog.stories.map(\.countyEn), ["Offaly", "Dublin", "Meath"])

        for story in LaunchCountyCatalog.stories {
            XCTAssertEqual(story.words.count, 20, "\(story.countyEn) must carry exactly twenty words")
            XCTAssertEqual(Set(story.words.map(\.ga)).count, 20, "\(story.countyEn) headwords must be unique")
            XCTAssertFalse(story.episodes.isEmpty)
            XCTAssertEqual(story.title, story.pack.title)
            XCTAssertEqual(story.sourceTitle, story.pack.presentation.sourceTitle)
            XCTAssertFalse(story.sourceFacts.isEmpty)
            XCTAssertEqual(story.clearance, .reviewDraft)
            XCTAssertTrue(story.pack.isReviewDraft)
            XCTAssertFalse(story.pack.isReleaseCleared)
            XCTAssertEqual(story.episodes.count, 6)
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

    func testPromotedCountyChapterOpeningVisualsResolve() throws {
        let expectedVisualCounts = [
            "offaly.cross-of-the-scriptures": 2,
            "dublin.sihtric-penny": 6,
            "meath.trim-de-lacy": 3,
        ]
        for (packID, expectedCount) in expectedVisualCounts {
            let pack = try XCTUnwrap(CountyStoryPackCatalog.pack(id: packID))
            let visualPages = pack.pages.filter { $0.visualResourceID != nil }
            XCTAssertEqual(
                visualPages.count,
                expectedCount,
                "\(packID) should expose \(expectedCount) chapter-opening heroes (D28)"
            )

            var videoCount = 0
            for page in visualPages {
                let visual = try XCTUnwrap(pack.visual(for: page))
                XCTAssertFalse((page.visualCaption ?? "").isEmpty)
                switch visual {
                case .image(let name):
                    XCTAssertTrue(
                        bundledStillExists(named: name),
                        "Missing bundled still \(name) for \(page.id)"
                    )
                case .video(let videoName, let fallbackName):
                    videoCount += 1
                    XCTAssertNotNil(
                        Bundle.main.url(forResource: videoName, withExtension: "mp4")
                            ?? Bundle.main.url(
                                forResource: videoName,
                                withExtension: "mp4",
                                subdirectory: "video"
                            ),
                        "Missing bundled video \(videoName)"
                    )
                    XCTAssertTrue(
                        bundledStillExists(named: fallbackName),
                        "Missing bundled fallback image \(fallbackName)"
                    )
                }
            }
            XCTAssertGreaterThan(videoCount, 0, "\(packID) should keep at least one Flow loop")
        }
    }

    private func bundledStillExists(named name: String) -> Bool {
        if UIImage(named: name) != nil { return true }
        return ["png", "jpg", "jpeg"].contains { ext in
            Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "art") != nil
                || Bundle.main.url(forResource: name, withExtension: ext) != nil
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

    func testRockfleetStoryCarriesAuthoredVisualPacingInThePack() throws {
        let pack = try XCTUnwrap(CountyStoryPackCatalog.pack(id: "mayo.grainne-1593"))
        let storyPages = pack.pages(for: .story)
        let presentations = storyPages.compactMap(\.presentation)

        XCTAssertEqual(storyPages.count, 10)
        XCTAssertEqual(presentations.count, storyPages.count)
        XCTAssertEqual(Set(presentations).count, storyPages.count, "Every Rockfleet story beat should change composition")
        XCTAssertTrue(storyPages.allSatisfy { !($0.advanceLabel ?? "").isEmpty })
        XCTAssertFalse(storyPages.contains { $0.id == "mayo.rockfleet.learning-consequence" })

        for page in storyPages where page.visualResourceID != nil {
            let resource = pack.resources.first { $0.id == page.visualResourceID }
            XCTAssertTrue(resource?.kind == .image || resource?.kind == .video)
            XCTAssertTrue(page.resourceIDs.contains(page.visualResourceID!))
            XCTAssertFalse((page.visualCaption ?? "").isEmpty)
            if resource?.kind == .video {
                let visual = try XCTUnwrap(pack.visual(for: page))
                guard case .video(let videoName, let fallbackName) = visual else {
                    return XCTFail("\(page.id) should resolve as video with fallback")
                }
                XCTAssertEqual(videoName, "video.mayo-rockfleet-sea-surge")
                XCTAssertEqual(fallbackName, "mayo-rockfleet-sea-surge")
            }
        }
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
        let envelope = try XCTUnwrap(
            CountyStoryPackCatalog.envelopes.first {
                $0.pack.id == "offaly.cross-of-the-scriptures"
            }
        )
        let data = try JSONEncoder().encode(envelope)
        let decoded = try JSONDecoder().decode(CountyStoryPackEnvelope.self, from: data)

        XCTAssertNoThrow(try CountyStoryPackStore.validate(data: data))
        XCTAssertEqual(decoded.pack.id, envelope.pack.id)
        XCTAssertEqual(decoded.pack.targetWords.count, 20)
        XCTAssertEqual(decoded.pack.pages.count, 68)
        XCTAssertTrue(decoded.pack.isReviewDraft)
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
    func testReviewDraftCannotAwardGoldArtifactOrReviews() throws {
        let model = AtlasPrototypeModel()
        let story = try XCTUnwrap(
            LaunchCountyCatalog.story(id: "offaly.cross-of-the-scriptures")
        )

        XCTAssertEqual(story.clearance, .reviewDraft)
        model.completeCountyStory(story)

        XCTAssertFalse(model.isCountyComplete(story.id))
        XCTAssertFalse(model.hasInspectedEvidence(story.id))
        XCTAssertFalse(model.madeArtifactIDs.contains(story.id))
        XCTAssertTrue(model.reviewCandidates().filter { $0.storyID == story.id }.isEmpty)
        XCTAssertTrue(model.atlasReviews.keys.filter { $0.hasPrefix(story.id) }.isEmpty)
    }

    @MainActor
    func testReviewRecoveryReturnsSoonerThanCleanRecall() throws {
        let model = AtlasPrototypeModel()
        let story = try XCTUnwrap(LaunchCountyCatalog.story(id: "dublin.sihtric-penny"))
        let candidate = AtlasReviewCandidate(
            storyID: story.id,
            county: story.countyEn,
            word: try XCTUnwrap(story.words.first)
        )
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

/// D27: the activity layers, the legacy-vocabulary migration, and the commit model.
final class CountyExerciseFamilyLayerTests: XCTestCase {
    func testLegacyFamiliesMigrateDeterministically() {
        XCTAssertEqual(CountyExerciseFamily.migratingLegacyRawValue("listenIdentify"), .listenChoose)
        XCTAssertEqual(CountyExerciseFamily.migratingLegacyRawValue("comprehension"), .readRespond)
        XCTAssertEqual(CountyExerciseFamily.migratingLegacyRawValue("speaking"), .recordCompare)
        // Absorbed as authored uses rather than surviving as families.
        XCTAssertEqual(CountyExerciseFamily.migratingLegacyRawValue("sequencing"), .sentenceConstruction)
        XCTAssertEqual(CountyExerciseFamily.migratingLegacyRawValue("listenBuildSentence"), .sentenceConstruction)
        XCTAssertEqual(CountyExerciseFamily.migratingLegacyRawValue("delayedRetrieval"), .freeTyping)
        // Dialogue and roleplay are one container.
        XCTAssertEqual(CountyExerciseFamily.migratingLegacyRawValue("dialogue"), .conversation)
        XCTAssertNil(CountyExerciseFamily.migratingLegacyRawValue("mascotCheer"))
    }

    func testLegacyRawValueDecodesThroughTheMigration() throws {
        let decoded = try JSONDecoder().decode(
            [CountyExerciseFamily].self,
            from: Data(#"["listenIdentify","sequencing","dialogue"]"#.utf8)
        )
        XCTAssertEqual(decoded, [.listenChoose, .sentenceConstruction, .conversation])
    }

    func testUnknownFamilyIsRejectedRatherThanDefaulted() {
        XCTAssertThrowsError(
            try JSONDecoder().decode(
                [CountyExerciseFamily].self,
                from: Data(#"["hearts"]"#.utf8)
            )
        )
    }

    func testConversationIsTheOnlyContainerAndStillCountsAsProduction() {
        let containers = CountyExerciseFamily.allCases.filter(\.isContainer)
        XCTAssertEqual(containers, [.conversation])
        // A container carries real production load even though it is not a family.
        XCTAssertTrue(CountyExerciseFamily.conversation.isActiveProduction)
        XCTAssertEqual(CountyExerciseFamily.allCases.filter { !$0.isContainer }.count, 8)
    }

    func testOnlySingleChoiceFamiliesCheckOnSelection() {
        XCTAssertTrue(CountyExerciseFamily.listenChoose.checksOnSelection)
        XCTAssertTrue(CountyExerciseFamily.readRespond.checksOnSelection)
        // Multi-part responses stay editable until an explicit Check.
        XCTAssertFalse(CountyExerciseFamily.sentenceConstruction.checksOnSelection)
        XCTAssertFalse(CountyExerciseFamily.matching.checksOnSelection)
        XCTAssertFalse(CountyExerciseFamily.freeTyping.checksOnSelection)
        XCTAssertFalse(CountyExerciseFamily.conversation.checksOnSelection)
    }
}
