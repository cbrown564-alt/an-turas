import SwiftUI

// MARK: - Living atlas prototype shell

/// The new product vessel. A first-time learner gets one authored encounter before
/// the wider atlas navigation is revealed. The legacy lesson path remains available
/// with `--legacy`.
struct AtlasPrototypeView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var atlas = AtlasPrototypeModel()
    @State private var path: [AtlasRoute] = []
    @State private var restoredProgress = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if atlas.hasOpenedAtlas {
                    atlasTabs
                } else {
                    FirstRunIslandView(
                        onBegin: beginStory,
                        onOpenName: { path.append(.personalSearch(.name)) },
                        onOpenPlace: { path.append(.personalSearch(.place)) }
                    )
                }
            }
            .navigationDestination(for: AtlasRoute.self) { route in
                destination(route)
            }
        }
        .environmentObject(atlas)
        .background(Theme.bg.ignoresSafeArea())
        .onChange(of: atlas.tab) { _, _ in
            if !path.isEmpty { path.removeAll() }
        }
        .onChange(of: atlas.learnerName) { _, name in
            if !name.isEmpty, appState.learnerName != name {
                appState.learnerName = name
            }
        }
        .onChange(of: atlas.progressSnapshot) { _, progress in
            #if DEBUG
            guard !ProcessInfo.processInfo.arguments.contains("--transient-test-state") else { return }
            #endif
            guard restoredProgress, appState.atlasProgress != progress else { return }
            appState.atlasProgress = progress
        }
        .onAppear {
            guard !restoredProgress else { return }
            atlas.restore(appState.atlasProgress)
            restoredProgress = true
            if atlas.learnerName.isEmpty { atlas.learnerName = appState.learnerName }
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if args.contains("--launch-road-complete") {
                atlas.storyCompleted = true
                atlas.storyInProgress = false
                if !atlas.completedCountyStoryIDs.contains("mayo.grainne-1593") {
                    atlas.completedCountyStoryIDs.append("mayo.grainne-1593")
                }
                for story in LaunchCountyCatalog.stories where !atlas.completedCountyStoryIDs.contains(story.id) {
                    atlas.completedCountyStoryIDs.append(story.id)
                    atlas.inspectedEvidenceIDs.append(story.id)
                    atlas.madeArtifactIDs.append(story.id)
                }
            }
            if let flag = args.firstIndex(of: "--county-story"),
               args.indices.contains(flag + 1),
               let pack = CountyStoryPackCatalog.pack(id: args[flag + 1]),
               let beatFlag = args.firstIndex(of: "--county-story-beat"),
               args.indices.contains(beatFlag + 1),
               let beat = Int(args[beatFlag + 1]) {
                _ = atlas.begin(pack, mode: .learning)
                if let page = pack.pages(for: .learning)
                    .first(where: { $0.legacyBeatIndex == beat }) {
                    atlas.setActivePage(page.id, in: pack)
                    if !args.contains("--completed-county-beat") {
                        atlas.completedCountyPageIDs[pack.id, default: []].removeAll { $0 == page.id }
                    }
                }
            }
            if args.contains("--atlas-due") {
                if !atlas.storyCompleted { atlas.completeStory() }
                if let candidate = atlas.reviewCandidates().first {
                    atlas.atlasReviews[candidate.id] = .init(due: Date().addingTimeInterval(-60))
                }
            }
            // D29 freeze run: the nine-step Clew Bay fixture through the shared
            // county shell. Fixture-only; never touches production promotion.
            if args.contains("--freeze-run"), let pack = CountyFreezeRunFixture.pack() {
                atlas.hasOpenedAtlas = true
                atlas.storyInProgress = true
                if args.contains("--fresh-county-pack") {
                    atlas.countyStoryModes.removeValue(forKey: pack.id)
                    atlas.activeCountyPageIDs.removeValue(forKey: pack.id)
                    atlas.completedCountyPageIDs.removeValue(forKey: pack.id)
                    atlas.clearRunRecords(for: pack)
                }
                _ = atlas.begin(pack, mode: .learning)
                if let pageFlag = args.firstIndex(of: "--page"),
                   args.indices.contains(pageFlag + 1),
                   pack.page(id: args[pageFlag + 1]) != nil {
                    atlas.setActivePage(args[pageFlag + 1], in: pack)
                    if !args.contains("--completed-page") {
                        atlas.completedCountyPageIDs[pack.id, default: []].removeAll { $0 == args[pageFlag + 1] }
                    }
                }
                path = [.freezeRun]
            } else if args.contains("--exercise-gallery") {
                atlas.hasOpenedAtlas = true
                path = [.exerciseGallery]
            } else if let flag = args.firstIndex(of: "--county-pack"),
                      args.indices.contains(flag + 1),
                      let pack = CountyStoryPackCatalog.pack(id: args[flag + 1]) {
                atlas.hasOpenedAtlas = true
                atlas.storyInProgress = true
                if args.contains("--fresh-county-pack") {
                    atlas.countyStoryModes.removeValue(forKey: pack.id)
                    atlas.activeCountyPageIDs.removeValue(forKey: pack.id)
                    atlas.completedCountyPageIDs.removeValue(forKey: pack.id)
                    atlas.storyReadCountyIDs.removeAll { $0 == pack.id }
                    atlas.completedCountyStoryIDs.removeAll { $0 == pack.id }
                    atlas.clearRunRecords(for: pack)
                }
                if args.contains("--mode-opening") {
                    atlas.countyStoryModes.removeValue(forKey: pack.id)
                    atlas.activeCountyPageIDs.removeValue(forKey: pack.id)
                }
                let modeFlag = args.firstIndex(of: "--mode")
                let requestedMode = modeFlag.flatMap { index in
                    args.indices.contains(index + 1) ? CountyStoryMode(rawValue: args[index + 1]) : nil
                }
                let pageFlag = args.firstIndex(of: "--page")
                let requestedPageID = pageFlag.flatMap { index in
                    args.indices.contains(index + 1) ? args[index + 1] : nil
                }
                if let requestedMode {
                    atlas.countyStoryModes[pack.id] = requestedMode.rawValue
                    atlas.activeCountyStoryID = pack.id
                }
                if let requestedPageID, pack.page(id: requestedPageID) != nil {
                    atlas.setActivePage(requestedPageID, in: pack)
                    if !args.contains("--completed-page") {
                        atlas.completedCountyPageIDs[pack.id, default: []].removeAll { $0 == requestedPageID }
                    }
                } else if let requestedMode {
                    _ = atlas.begin(pack, mode: requestedMode)
                }
                path = [.countyPack(pack.id)]
            } else if args.contains("--mayo-dossier") {
                atlas.hasOpenedAtlas = true
                path = [.mayoDossier]
            } else if args.contains("--grainne-person") {
                atlas.hasOpenedAtlas = true
                path = [.grainnePerson]
            } else if args.contains("--first-takeaway") {
                atlas.storyCompleted = true
                path = [.firstTakeaway]
            } else if args.contains("--atlas-open") {
                atlas.hasOpenedAtlas = true
                atlas.storyInProgress = false
            } else if let flag = args.firstIndex(of: "--county-story"),
                      args.indices.contains(flag + 1),
                      let pack = CountyStoryPackCatalog.pack(id: args[flag + 1]) {
                atlas.hasOpenedAtlas = true
                path = [.countyPack(pack.id)]
            } else if let flag = args.firstIndex(of: "--county-dossier"),
                      args.indices.contains(flag + 1),
                      let story = LaunchCountyCatalog.story(id: args[flag + 1]) {
                atlas.hasOpenedAtlas = true
                path = [.launchCountyDossier(story.id)]
            } else if let flag = args.firstIndex(of: "--county-evidence"),
                      args.indices.contains(flag + 1),
                      let story = LaunchCountyCatalog.story(id: args[flag + 1]) {
                atlas.hasOpenedAtlas = true
                path = [.launchEvidence(story.id)]
            } else if let flag = args.firstIndex(of: "--personal"),
               args.indices.contains(flag + 1),
               PersonalAtlasLoader.subject(id: args[flag + 1]) != nil {
                atlas.hasOpenedAtlas = true
                path = [.personalSubject(args[flag + 1])]
            } else if args.contains("--personal-search") {
                atlas.hasOpenedAtlas = true
                path = [.personalSearch(.either)]
            }
            #endif
            if path.isEmpty, atlas.storyCompleted, !atlas.hasOpenedAtlas {
                path = [.firstTakeaway]
            } else if path.isEmpty, atlas.storyInProgress {
                path = [.countyPack("mayo.grainne-1593")]
            }
        }
        .onOpenURL { url in
            guard let id = PersonalAtlasDeepLink.subjectID(from: url),
                  PersonalAtlasLoader.subject(id: id) != nil else { return }
            atlas.hasOpenedAtlas = true
            path = [.personalSubject(id)]
        }
    }

    private var atlasTabs: some View {
        TabView(selection: $atlas.tab) {
            IslandAtlasView(
                onOpenMayo: { path.append(.mayoDossier) },
                onOpenCounty: { path.append(.county($0)) },
                onOpenFieldNote: { path.append(.fieldNote) },
                onOpenPersonalSearch: { path.append(.personalSearch(.either)) },
                onOpenName: { path.append(.personalSearch(.name)) },
                onOpenPlace: { path.append(.personalSearch(.place)) }
            )
            .tag(AtlasTab.island)
            .tabItem { Label("An tOileán", systemImage: "map") }

            CurrentStoryView(
                onOpenMayoStory: beginStory,
                onOpenMayoDossier: { path.append(.mayoDossier) },
                onOpenCountyStory: { path.append(.launchCountyStory($0)) },
                onOpenCountyDossier: { path.append(.launchCountyDossier($0)) }
            )
            .tag(AtlasTab.story)
            .tabItem { Label("An Scéal", systemImage: "book.pages") }

            AtlasCollectionView(
                onOpenEvidence: { path.append(.evidence) },
                onOpenLaunchEvidence: { path.append(.launchEvidence($0)) },
                onOpenFieldNote: { path.append(.fieldNote) },
                onOpenPersonalSubject: { path.append(.personalSubject($0)) },
                onOpenPersonalSearch: { path.append(.personalSearch(.either)) }
            )
            .tag(AtlasTab.collection)
            .tabItem { Label("An Cnuasach", systemImage: "square.grid.2x2") }

            AtlasReturnView(onOpenEvidence: { path.append(.evidence) })
                .tag(AtlasTab.returning)
                .tabItem { Label("Ar Ais", systemImage: "arrow.uturn.backward") }

            AtlasCalendarView()
                .tag(AtlasTab.calendar)
                .tabItem { Label("An Féilire", systemImage: "calendar") }
        }
        .tint(Theme.moss)
        .toolbarBackground(Theme.bg, for: .tabBar)
    }

    @ViewBuilder
    private func destination(_ route: AtlasRoute) -> some View {
        switch route {
        case .mayoDossier:
            MayoDossierView(
                onMeetGrainne: { path.append(.grainnePerson) },
                onBegin: beginStory,
                onFieldNote: { path.append(.fieldNote) },
                onOpenEvidence: { path.append(.evidence) }
            )
        case .grainnePerson:
            GrainnePersonView(
                onBegin: beginStory,
                onOpenEvidence: { path.append(.evidence) }
            )
        case .countyPack(let id):
            if let pack = CountyStoryPackCatalog.pack(id: id) {
                CountyStoryExperienceView(
                    pack: pack,
                    onOpenEvidence: { path.append(.evidence) },
                    onExit: {
                        atlas.hasOpenedAtlas = true
                        atlas.storyInProgress = false
                        atlas.tab = .island
                        atlas.shouldFocusOpeningRoad = true
                        path.removeAll()
                    }
                )
            }
        case .freezeRun:
            if let pack = CountyFreezeRunFixture.pack() {
                CountyStoryExperienceView(
                    pack: pack,
                    onOpenEvidence: { path.append(.evidence) },
                    onExit: {
                        atlas.hasOpenedAtlas = true
                        atlas.storyInProgress = false
                        atlas.tab = .island
                        atlas.shouldFocusOpeningRoad = true
                        path.removeAll()
                    }
                )
            }
        case .exerciseGallery:
            CountyExerciseGalleryView()
        case .firstTakeaway:
            FirstEncounterTakeawayView {
                atlas.hasOpenedAtlas = true
                atlas.storyInProgress = false
                atlas.tab = .island
                atlas.shouldFocusOpeningRoad = true
                path.removeAll()
            }
        case .evidence:
            PetitionEvidenceView()
        case .fieldNote:
            BreastaghFieldNoteView()
        case .county(let name):
            if let story = LaunchCountyCatalog.story(county: name) {
                LaunchCountyDossierView(
                    story: story,
                    onBegin: { path.append(.launchCountyStory(story.id)) },
                    onEvidence: { path.append(.launchEvidence(story.id)) }
                )
            } else {
                AtlasCountyPreviewView(countyName: name)
            }
        case .launchCountyDossier(let id):
            if let story = LaunchCountyCatalog.story(id: id) {
                LaunchCountyDossierView(
                    story: story,
                    onBegin: { path.append(.launchCountyStory(story.id)) },
                    onEvidence: { path.append(.launchEvidence(story.id)) }
                )
            }
        case .launchCountyStory(let id):
            if let pack = CountyStoryPackCatalog.pack(id: id) {
                CountyStoryExperienceView(
                    pack: pack,
                    onOpenEvidence: { path.append(.launchEvidence(pack.id)) },
                    onExit: {
                        atlas.tab = .island
                        atlas.shouldFocusOpeningRoad = true
                        path.removeAll()
                    }
                )
            }
        case .launchEvidence(let id):
            if let story = LaunchCountyCatalog.story(id: id) {
                LaunchEvidenceView(story: story)
            }
        case .personalSearch(let focus):
            PersonalAtlasSearchView(focus: focus) { subjectId in
                path.append(.personalSubject(subjectId))
            }
        case .personalSubject(let id):
            PersonalSubjectResultView(subjectId: id) { handoff in
                appendHandoff(handoff)
            }
        }
    }

    private func appendHandoff(_ routeName: String) {
        switch routeName {
        case "mayoDossier":
            path.append(.mayoDossier)
        case "grainnePerson":
            path.append(.grainnePerson)
        case "grainneStory":
            beginStory()
        default:
            break
        }
    }

    private func beginStory() {
        atlas.storyInProgress = true
        path.append(.countyPack("mayo.grainne-1593"))
    }
}

enum AtlasTab: Hashable {
    case island, story, collection, returning, calendar
}

enum AtlasRoute: Hashable {
    case mayoDossier
    case grainnePerson
    case countyPack(String)
    case freezeRun
    case exerciseGallery
    case firstTakeaway
    case evidence
    case fieldNote
    case county(String)
    case launchCountyDossier(String)
    case launchCountyStory(String)
    case launchEvidence(String)
    case personalSearch(PersonalSearchFocus)
    case personalSubject(String)
}

@MainActor
final class AtlasPrototypeModel: ObservableObject {
    @Published var tab: AtlasTab = .island
    @Published var hasOpenedAtlas = false
    @Published var learnerName = ""
    @Published var evidenceInspected = false
    @Published var storyCompleted = false
    @Published var fieldNoteVisited = false
    @Published var returnAnswered = false
    @Published var storyInProgress = false
    @Published var storyStep = 0
    @Published var storyFoundName = false
    @Published var completedStoryBeats: [Int] = []
    @Published var shouldFocusOpeningRoad = false
    @Published var activeCountyStoryID: String?
    @Published var completedCountyStoryIDs: [String] = []
    @Published var countyStorySteps: [String: Int] = [:]
    @Published var completedCountyStoryBeats: [String: [Int]] = [:]
    @Published var countyStoryModes: [String: String] = [:]
    @Published var activeCountyPageIDs: [String: String] = [:]
    @Published var completedCountyPageIDs: [String: [String]] = [:]
    @Published var storyReadCountyIDs: [String] = []
    @Published var countyPackVersions: [String: Int] = [:]
    @Published var inspectedEvidenceIDs: [String] = []
    @Published var madeArtifactIDs: [String] = []
    @Published var atlasReviews: [String: AppState.AtlasReviewProgress] = [:]
    @Published var calendarDaysVisited: [String] = []
    /// D27/C3: ordered exercise-page struggles per pack, feeding contextual
    /// mistake review. Ordered so the earliest slip can win deterministically.
    @Published var countyExerciseStruggles: [String: [String]] = [:]
    /// C1: turn-graph position per conversation page, keyed by page id.
    @Published var countyConversationStates: [String: CountyConversationState] = [:]
    /// D29 fixture boundary: fixture completion handoffs (pack id -> word ga),
    /// kept apart from county gold and the review scheduler.
    @Published var fixtureCollections: [String: [String]] = [:]

    var carriedWords: [AtlasWord] {
        CountyStoryPackCatalog.pack(id: "mayo.grainne-1593")?.targetWords ?? []
    }

    func completeStory() {
        evidenceInspected = true
        storyCompleted = true
        storyInProgress = false
        if !completedCountyStoryIDs.contains("mayo.grainne-1593") {
            completedCountyStoryIDs.append("mayo.grainne-1593")
        }
        seedReviews(storyID: "mayo.grainne-1593", words: carriedWords)
        Haptics.flourish()
    }

    var completedCountyNames: Set<String> {
        var names = Set<String>()
        if storyCompleted || completedCountyStoryIDs.contains("mayo.grainne-1593") {
            names.insert("Mayo")
        }
        for story in LaunchCountyCatalog.stories where completedCountyStoryIDs.contains(story.id) {
            names.insert(story.countyEn)
        }
        return names
    }

    var currentCountyName: String {
        if !storyCompleted { return "Mayo" }
        return LaunchCountyCatalog.stories.first(where: { !isCountyComplete($0.id) })?.countyEn ?? "Meath"
    }

    var completedLaunchCountyCount: Int { completedCountyNames.count }

    func isCountyComplete(_ storyID: String) -> Bool {
        completedCountyStoryIDs.contains(storyID)
    }

    func countyStep(for storyID: String) -> Int {
        countyStorySteps[storyID] ?? 0
    }

    func setCountyStep(_ storyID: String, step: Int) {
        countyStorySteps[storyID] = max(step, 0)
        activeCountyStoryID = storyID
    }

    func isCountyBeatComplete(_ storyID: String, step: Int) -> Bool {
        completedCountyStoryBeats[storyID, default: []].contains(step)
    }

    func markCountyBeatComplete(_ storyID: String, step: Int) {
        var beats = completedCountyStoryBeats[storyID, default: []]
        if !beats.contains(step) {
            beats.append(step)
            completedCountyStoryBeats[storyID] = beats.sorted()
        }
    }

    // MARK: Stable county-pack progress

    func mode(for packID: String) -> CountyStoryMode? {
        countyStoryModes[packID].flatMap(CountyStoryMode.init(rawValue:))
    }

    @discardableResult
    func begin(_ pack: CountyStoryPack, mode: CountyStoryMode) -> String? {
        countyStoryModes[pack.id] = mode.rawValue
        activeCountyStoryID = pack.id
        let pageID = resumePageID(for: pack, mode: mode)
        if let pageID { activeCountyPageIDs[pack.id] = pageID }
        return pageID
    }

    @discardableResult
    func switchMode(in pack: CountyStoryPack, to mode: CountyStoryMode) -> String? {
        countyStoryModes[pack.id] = mode.rawValue
        let pageID = nextIncompleteVisiblePageID(in: pack, mode: mode)
            ?? pack.pages(for: mode).last?.id
        if let pageID { activeCountyPageIDs[pack.id] = pageID }
        return pageID
    }

    func setActivePage(_ pageID: String, in pack: CountyStoryPack) {
        guard pack.page(id: pageID) != nil else { return }
        activeCountyStoryID = pack.id
        activeCountyPageIDs[pack.id] = pageID
    }

    func isPageComplete(_ pageID: String, in packID: String) -> Bool {
        completedCountyPageIDs[packID, default: []].contains(pageID)
    }

    func markPageComplete(_ pageID: String, in pack: CountyStoryPack) {
        guard pack.page(id: pageID) != nil else { return }
        var pages = completedCountyPageIDs[pack.id, default: []]
        if !pages.contains(pageID) {
            pages.append(pageID)
            completedCountyPageIDs[pack.id] = pages
        }
    }

    func nextIncompleteVisiblePageID(in pack: CountyStoryPack, mode: CountyStoryMode) -> String? {
        let completed = Set(completedCountyPageIDs[pack.id, default: []])
        return pack.pages(for: mode).first { !completed.contains($0.id) }?.id
    }

    func resumePageID(for pack: CountyStoryPack, mode: CountyStoryMode) -> String? {
        let visible = pack.pages(for: mode)
        if let current = activeCountyPageIDs[pack.id], visible.contains(where: { $0.id == current }) {
            return current
        }
        return nextIncompleteVisiblePageID(in: pack, mode: mode) ?? visible.last?.id
    }

    func completedRequiredPages(in pack: CountyStoryPack, mode: CountyStoryMode) -> Int {
        let completed = Set(completedCountyPageIDs[pack.id, default: []])
        return pack.requiredPageIDs(for: mode).filter { completed.contains($0) }.count
    }

    func hasCompleted(_ pack: CountyStoryPack, mode: CountyStoryMode) -> Bool {
        let completed = Set(completedCountyPageIDs[pack.id, default: []])
        return Set(pack.requiredPageIDs(for: mode)).isSubset(of: completed)
    }

    /// Review drafts can be read end to end, but only a complete county pack with
    /// every recorded review gate closed can open the route or award gold.
    func finish(_ pack: CountyStoryPack, mode: CountyStoryMode) {
        guard hasCompleted(pack, mode: mode), pack.isReleaseCleared else { return }
        if mode == .story {
            if !storyReadCountyIDs.contains(pack.id) { storyReadCountyIDs.append(pack.id) }
            markEvidenceInspected(pack.id)
        } else {
            if !completedCountyStoryIDs.contains(pack.id) { completedCountyStoryIDs.append(pack.id) }
            markEvidenceInspected(pack.id)
            markArtifactMade(pack.id)
            seedReviews(storyID: pack.id, words: pack.targetWords)
        }
    }

    func hasReadStory(_ packID: String) -> Bool {
        storyReadCountyIDs.contains(packID)
    }

    func markEvidenceInspected(_ storyID: String) {
        if !inspectedEvidenceIDs.contains(storyID) {
            inspectedEvidenceIDs.append(storyID)
        }
    }

    func hasInspectedEvidence(_ storyID: String) -> Bool {
        inspectedEvidenceIDs.contains(storyID)
    }

    func markArtifactMade(_ storyID: String) {
        if !madeArtifactIDs.contains(storyID) {
            madeArtifactIDs.append(storyID)
        }
    }

    func completeCountyStory(_ story: LaunchCountyStory) {
        let pack = story.pack
        for pageID in pack.completion.learningPageIDs {
            markPageComplete(pageID, in: pack)
        }
        finish(pack, mode: .learning)
        activeCountyStoryID = LaunchCountyCatalog.stories
            .first(where: { !completedCountyStoryIDs.contains($0.id) })?.id
    }

    func carriedWordsByCounty() -> [(county: String, words: [AtlasWord])] {
        var result: [(String, [AtlasWord])] = []
        if storyCompleted { result.append(("Mayo", carriedWords)) }
        for story in LaunchCountyCatalog.stories where isCountyComplete(story.id) {
            result.append((story.countyEn, story.words))
        }
        return result
    }

    func evidenceStories() -> [LaunchCountyStory] {
        LaunchCountyCatalog.stories.filter { hasInspectedEvidence($0.id) || isCountyComplete($0.id) }
    }

    func reviewCandidates() -> [AtlasReviewCandidate] {
        var candidates: [AtlasReviewCandidate] = []
        if storyCompleted {
            candidates += carriedWords.map { .init(storyID: "mayo.grainne-1593", county: "Mayo", word: $0) }
        }
        for story in LaunchCountyCatalog.stories where isCountyComplete(story.id) {
            candidates += story.words.map { .init(storyID: story.id, county: story.countyEn, word: $0) }
        }
        return candidates
    }

    func dueReviewCandidates(now: Date = Date()) -> [AtlasReviewCandidate] {
        reviewCandidates()
            .filter { atlasReviews[$0.id]?.due ?? .distantPast <= now }
            .sorted { (atlasReviews[$0.id]?.due ?? .distantPast) < (atlasReviews[$1.id]?.due ?? .distantPast) }
    }

    func nextReviewCandidate(now: Date = Date()) -> AtlasReviewCandidate? {
        let candidates = reviewCandidates()
        return candidates.min { (atlasReviews[$0.id]?.due ?? now) < (atlasReviews[$1.id]?.due ?? now) }
    }

    /// A compact, deterministic scheduler using the FSRS memory variables
    /// (stability and difficulty). The interface presents place and meaning;
    /// these values remain entirely underneath that experience.
    func completeReview(_ candidate: AtlasReviewCandidate, struggled: Bool, now: Date = Date()) {
        var progress = atlasReviews[candidate.id] ?? .init(due: now)
        progress.reps += 1
        if struggled {
            progress.lapses += 1
            progress.difficulty = min(10, progress.difficulty + 0.8)
            progress.stability = max(0.6, progress.stability * 0.55)
        } else {
            progress.difficulty = max(1, progress.difficulty - 0.25)
            let growth = progress.reps == 1 ? 2.5 : max(1.35, 2.15 - progress.difficulty * 0.06)
            progress.stability = max(1, progress.stability * growth)
        }
        let intervalDays = struggled ? 1 : max(1, min(180, Int(progress.stability.rounded())))
        progress.due = Calendar.current.date(byAdding: .day, value: intervalDays, to: now)
            ?? now.addingTimeInterval(Double(intervalDays) * 86_400)
        atlasReviews[candidate.id] = progress
    }

    func markCalendarDayVisited(_ key: String) {
        if !calendarDaysVisited.contains(key) {
            calendarDaysVisited.append(key)
        }
    }

    func hasVisitedCalendarDay(_ key: String) -> Bool {
        calendarDaysVisited.contains(key)
    }

    // MARK: Run-scoped activity records (struggles, conversations, fixture collection)

    /// D27 struggle memory event, recorded once per exercise page in run order.
    func recordStruggle(_ pageID: String, in pack: CountyStoryPack) {
        guard pack.page(id: pageID) != nil else { return }
        var struggles = countyExerciseStruggles[pack.id, default: []]
        guard !struggles.contains(pageID) else { return }
        struggles.append(pageID)
        countyExerciseStruggles[pack.id] = struggles
    }

    func struggledPageIDs(in pack: CountyStoryPack) -> [String] {
        countyExerciseStruggles[pack.id, default: []]
    }

    /// C1: persist the turn-graph position after every fitting reply so an
    /// interrupted conversation resumes at the exact node with its transcript.
    func saveConversationState(_ state: CountyConversationState, for pageID: String) {
        countyConversationStates[pageID] = state
    }

    func conversationState(for pageID: String) -> CountyConversationState? {
        countyConversationStates[pageID]
    }

    /// C5 fixture handoff: the completion container files its words into the
    /// fixture collection only — no county gold, no scheduled reviews.
    func recordFixtureCollection(_ words: [String], in pack: CountyStoryPack) {
        var collected = fixtureCollections[pack.id, default: []]
        for word in words where !collected.contains(word) {
            collected.append(word)
        }
        fixtureCollections[pack.id] = collected
    }

    /// Debug resets (`--fresh-county-pack`) clear every run-scoped record for
    /// one pack alongside its page progress.
    func clearRunRecords(for pack: CountyStoryPack) {
        countyExerciseStruggles.removeValue(forKey: pack.id)
        fixtureCollections.removeValue(forKey: pack.id)
        let pageIDs = Set(pack.pages.map(\.id))
        countyConversationStates = countyConversationStates.filter { !pageIDs.contains($0.key) }
    }

    private func seedReviews(storyID: String, words: [AtlasWord], now: Date = Date()) {
        for (index, word) in words.enumerated() {
            let key = "\(storyID)|\(word.ga)"
            guard atlasReviews[key] == nil else { continue }
            atlasReviews[key] = .init(
                due: now.addingTimeInterval(86_400 + Double(index) * 90),
                stability: 1,
                difficulty: 5,
                reps: 0,
                lapses: 0
            )
        }
    }

    var progressSnapshot: AppState.AtlasProgress {
        AppState.AtlasProgress(
            hasOpenedAtlas: hasOpenedAtlas,
            evidenceInspected: evidenceInspected,
            storyCompleted: storyCompleted,
            fieldNoteVisited: fieldNoteVisited,
            returnAnswered: returnAnswered,
            storyInProgress: storyInProgress,
            storyStep: storyStep,
            storyFoundName: storyFoundName,
            storyArcVersion: 2,
            completedStoryBeats: completedStoryBeats,
            activeCountyStoryID: activeCountyStoryID,
            completedCountyStoryIDs: completedCountyStoryIDs,
            countyStorySteps: countyStorySteps,
            completedCountyStoryBeats: completedCountyStoryBeats,
            countyStoryModes: countyStoryModes,
            activeCountyPageIDs: activeCountyPageIDs,
            completedCountyPageIDs: completedCountyPageIDs,
            storyReadCountyIDs: storyReadCountyIDs,
            countyPackVersions: countyPackVersions,
            inspectedEvidenceIDs: inspectedEvidenceIDs,
            madeArtifactIDs: madeArtifactIDs,
            atlasReviews: atlasReviews,
            calendarDaysVisited: calendarDaysVisited,
            countyExerciseStruggles: countyExerciseStruggles,
            countyConversationStates: countyConversationStates,
            fixtureCollections: fixtureCollections
        )
    }

    func restore(_ progress: AppState.AtlasProgress) {
        hasOpenedAtlas = progress.hasOpenedAtlas
        evidenceInspected = progress.evidenceInspected
        storyCompleted = progress.storyCompleted
        fieldNoteVisited = progress.fieldNoteVisited
        returnAnswered = progress.returnAnswered
        storyInProgress = progress.storyInProgress
        if progress.storyArcVersion < 2, progress.storyInProgress {
            // The approved four-step encounter became Episode 4. Resume old
            // in-flight saves at the corresponding beat instead of restarting.
            storyStep = min(max(9 + min(max(progress.storyStep, 0), 2), 0), 17)
        } else {
            storyStep = min(max(progress.storyStep, 0), 17)
        }
        storyFoundName = progress.storyFoundName
        completedStoryBeats = progress.completedStoryBeats
            .filter { (0..<18).contains($0) }
            .uniqued()
            .sorted()
        activeCountyStoryID = progress.activeCountyStoryID
        completedCountyStoryIDs = progress.completedCountyStoryIDs.uniqued()
        if storyCompleted, !completedCountyStoryIDs.contains("mayo.grainne-1593") {
            completedCountyStoryIDs.append("mayo.grainne-1593")
        }
        countyStorySteps = progress.countyStorySteps
        completedCountyStoryBeats = progress.completedCountyStoryBeats
        countyStoryModes = progress.countyStoryModes
        activeCountyPageIDs = progress.activeCountyPageIDs
        completedCountyPageIDs = progress.completedCountyPageIDs
        storyReadCountyIDs = progress.storyReadCountyIDs.uniqued()
        countyPackVersions = progress.countyPackVersions
        inspectedEvidenceIDs = progress.inspectedEvidenceIDs.uniqued()
        madeArtifactIDs = progress.madeArtifactIDs.uniqued()
        atlasReviews = progress.atlasReviews
        calendarDaysVisited = progress.calendarDaysVisited.uniqued()
        countyExerciseStruggles = progress.countyExerciseStruggles
        countyConversationStates = progress.countyConversationStates
        fixtureCollections = progress.fixtureCollections
        if storyCompleted { seedReviews(storyID: "mayo.grainne-1593", words: carriedWords) }
        for story in LaunchCountyCatalog.stories where completedCountyStoryIDs.contains(story.id) {
            seedReviews(storyID: story.id, words: story.words)
        }
        for pack in CountyStoryPackCatalog.packs {
            migrateLegacyProgress(into: pack)
        }
    }

    /// Maps old flat beat indexes to stable page ids once. Legacy progress,
    /// evidence, artifacts and review schedules remain untouched alongside it.
    private func migrateLegacyProgress(into pack: CountyStoryPack) {
        guard countyPackVersions[pack.id, default: 0] < pack.revision else { return }
        var completed = completedCountyPageIDs[pack.id, default: []]

        let legacyCompleted: [Int]
        let legacyCurrent: Int?
        if pack.id == "mayo.grainne-1593" {
            legacyCompleted = completedStoryBeats
            legacyCurrent = storyInProgress ? storyStep : nil
        } else {
            legacyCompleted = completedCountyStoryBeats[pack.id, default: []]
            legacyCurrent = countyStorySteps[pack.id]
        }

        for page in pack.pages {
            if let legacy = page.legacyBeatIndex,
               legacyCompleted.contains(legacy),
               !completed.contains(page.id) {
                completed.append(page.id)
            }
        }

        // The old contract awarded gold after its whole beat path. Preserve
        // that earned state through the reset without awarding it to new saves.
        if completedCountyStoryIDs.contains(pack.id) || (pack.id == "mayo.grainne-1593" && storyCompleted) {
            for id in pack.completion.learningPageIDs where !completed.contains(id) {
                completed.append(id)
            }
            if !storyReadCountyIDs.contains(pack.id) { storyReadCountyIDs.append(pack.id) }
        }

        completedCountyPageIDs[pack.id] = completed
        if activeCountyPageIDs[pack.id] == nil,
           let legacyCurrent,
           let mapped = pack.pages.first(where: { $0.legacyBeatIndex == legacyCurrent }) {
            activeCountyPageIDs[pack.id] = mapped.id
        }
        countyPackVersions[pack.id] = pack.revision
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

struct AtlasWord: Identifiable, Codable, Equatable {
    let ga: String
    let en: String
    let sound: String
    let anchor: String
    var id: String { ga }
}

// MARK: - Shared atlas language

enum EvidenceCertainty: String, CaseIterable, Codable {
    case documented = "DOCUMENTED"
    case material = "MATERIAL EVIDENCE"
    case later = "LATER ACCOUNT"
    case tradition = "TRADITION"
    case disputed = "DISPUTED"
    case reconstruction = "RECONSTRUCTION"
    case unknown = "UNKNOWN"

    var color: Color {
        switch self {
        case .documented: return Theme.atlasGreen
        case .material: return Theme.lichen
        case .later: return Color(light: 0x476B7A, dark: 0x8BB8C8)
        case .tradition: return Color(light: 0x75568B, dark: 0xBDA0CF)
        case .disputed: return Theme.rust
        case .reconstruction: return Theme.inkFaint
        case .unknown: return Theme.stone
        }
    }
}

struct CertaintyPill: View {
    let certainty: EvidenceCertainty
    var body: some View {
        Text(certainty.rawValue)
            .font(.caption2.weight(.bold))
            .kerning(1.05)
            .foregroundStyle(certainty.color)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(certainty.color.opacity(0.11))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(certainty.color.opacity(0.45), lineWidth: 0.8))
            .accessibilityLabel("Evidence status: \(certainty.rawValue.lowercased())")
    }
}

struct AtlasScreenHeader: View {
    let eyebrow: String
    let title: String
    let detail: String?

    init(_ eyebrow: String, _ title: String, detail: String? = nil) {
        self.eyebrow = eyebrow
        self.title = title
        self.detail = detail
    }

    var body: some View {
        EditorialScreenHeader(context: eyebrow, title: title, detail: detail)
    }
}

struct AtlasCard<Content: View>: View {
    var accent: Color = Theme.line
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.raised)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accent.opacity(0.45), lineWidth: 0.8))
    }
}

struct AtlasRule: View {
    var body: some View {
        EditorialRule()
    }
}

struct AtlasAudioLine: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let ga: String
    let en: String
    let sound: String
    @State private var heard = false

    private var canPlay: Bool { SpeechService.shared.canSpeak(ga) }

    var body: some View {
        Button {
            guard canPlay else { return }
            Haptics.tap()
            SpeechService.shared.speak(ga)
            withAnimation(reduceMotion ? nil : Motion.pop) { heard = true }
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(ga)
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.moss)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Image(systemName: canPlay ? (heard ? "speaker.wave.2.fill" : "speaker.wave.2") : "waveform.slash")
                        .foregroundStyle(canPlay ? Theme.moss : Theme.inkFaint)
                }
                Text("Say it like · \(sound)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.inkFaint)
                Text(en)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Theme.inkSoft)
                if !canPlay {
                    Text("Audio coming soon")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.rust)
                }
            }
            .padding(18)
            .background(Theme.mossTint)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.moss.opacity(0.45)).frame(height: 1)
                    .padding(.horizontal, 18)
            }
        }
        .buttonStyle(CarvePress())
        .disabled(!canPlay)
        .accessibilityLabel(canPlay ? "Hear \(ga), meaning \(en)" : "Audio unavailable for \(ga), meaning \(en)")
        .accessibilityHint(canPlay ? "Plays the Irish Cultural Guide recording" : "The written form and meaning remain available")
    }
}

struct SourceFooter: View {
    var compact = false
    var onOpen: (() -> Void)?

    var body: some View {
        Group {
            if let onOpen {
                Button(action: onOpen) { content }
                    .buttonStyle(CarvePress())
                    .accessibilityHint("Opens the source guide and provenance")
            } else {
                content
            }
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "building.columns")
                .foregroundStyle(Theme.inkFaint)
            Text(compact
                 ? "Source: National Library of Ireland record MS_UR_010761."
                 : "Source · National Library of Ireland record MS_UR_010761.")
                .font(.caption)
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(3)
        }
        .padding(13)
        .background(Theme.sunk)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}
