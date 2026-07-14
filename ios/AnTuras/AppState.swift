import Foundation
import Combine

struct PersonalAtlasFeedback: Codable, Identifiable, Hashable {
    enum Kind: String, Codable, CaseIterable {
        case localForm
        case wrongPlace
        case correction
    }

    let id: UUID
    let subjectId: String
    let assertionId: String?
    let kind: Kind
    let context: String
    let sourceURL: String?
    let createdAt: Date
}

struct PersonalAtlasQueryEvent: Codable, Identifiable, Hashable {
    enum Outcome: String, Codable {
        case openedSubject
        case unresolved
        case ambiguityShown
        case continued
    }

    let id: UUID
    let subjectId: String?
    let outcome: Outcome
    let unresolvedReason: String?
    let selectedAmbiguityBranchId: String?
    let timeToAnswerMilliseconds: Int?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        subjectId: String?,
        outcome: Outcome,
        unresolvedReason: String? = nil,
        selectedAmbiguityBranchId: String? = nil,
        timeToAnswerMilliseconds: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.subjectId = subjectId
        self.outcome = outcome
        self.unresolvedReason = unresolvedReason
        self.selectedAmbiguityBranchId = selectedAmbiguityBranchId
        self.timeToAnswerMilliseconds = timeToAnswerMilliseconds
        self.createdAt = createdAt
    }
}

// MARK: - Progress persistence (prototype-grade: UserDefaults JSON)

final class AppState: ObservableObject {
    /// Durable review state for one word carried out of a county story. The
    /// learner never sees these scheduling values; Ar Ais presents the return
    /// as another encounter with a place, object or phrase.
    struct AtlasReviewProgress: Codable, Equatable {
        var due: Date
        var stability: Double
        var difficulty: Double
        var reps: Int
        var lapses: Int

        init(
            due: Date = Date(),
            stability: Double = 1,
            difficulty: Double = 5,
            reps: Int = 0,
            lapses: Int = 0
        ) {
            self.due = due
            self.stability = stability
            self.difficulty = difficulty
            self.reps = reps
            self.lapses = lapses
        }
    }

    /// Durable state for the living-atlas prototype. This is intentionally
    /// separate from the legacy chapter/session progress so an interrupted
    /// documentary encounter can resume without inventing chapter completion.
    struct AtlasProgress: Codable, Equatable {
        var hasOpenedAtlas = false
        var evidenceInspected = false
        var storyCompleted = false
        var fieldNoteVisited = false
        var returnAnswered = false
        var storyInProgress = false
        var storyStep = 0
        var storyFoundName = false
        /// Version 1 was the four-step first encounter. Version 2 is the
        /// six-episode / three-beat arc. The model migrates an interrupted v1
        /// encounter into Episode 4, where the approved first encounter lives.
        var storyArcVersion = 2
        var completedStoryBeats: [Int] = []
        /// Phase 3 county stories use durable story ids. Mayo's historical
        /// booleans remain above for a lossless migration from the prototype.
        var activeCountyStoryID: String?
        var completedCountyStoryIDs: [String] = []
        var countyStorySteps: [String: Int] = [:]
        var completedCountyStoryBeats: [String: [Int]] = [:]
        var inspectedEvidenceIDs: [String] = []
        var madeArtifactIDs: [String] = []
        var atlasReviews: [String: AtlasReviewProgress] = [:]
        var calendarDaysVisited: [String] = []

        init(
            hasOpenedAtlas: Bool = false,
            evidenceInspected: Bool = false,
            storyCompleted: Bool = false,
            fieldNoteVisited: Bool = false,
            returnAnswered: Bool = false,
            storyInProgress: Bool = false,
            storyStep: Int = 0,
            storyFoundName: Bool = false,
            storyArcVersion: Int = 2,
            completedStoryBeats: [Int] = [],
            activeCountyStoryID: String? = nil,
            completedCountyStoryIDs: [String] = [],
            countyStorySteps: [String: Int] = [:],
            completedCountyStoryBeats: [String: [Int]] = [:],
            inspectedEvidenceIDs: [String] = [],
            madeArtifactIDs: [String] = [],
            atlasReviews: [String: AtlasReviewProgress] = [:],
            calendarDaysVisited: [String] = []
        ) {
            self.hasOpenedAtlas = hasOpenedAtlas
            self.evidenceInspected = evidenceInspected
            self.storyCompleted = storyCompleted
            self.fieldNoteVisited = fieldNoteVisited
            self.returnAnswered = returnAnswered
            self.storyInProgress = storyInProgress
            self.storyStep = storyStep
            self.storyFoundName = storyFoundName
            self.storyArcVersion = storyArcVersion
            self.completedStoryBeats = completedStoryBeats
            self.activeCountyStoryID = activeCountyStoryID
            self.completedCountyStoryIDs = completedCountyStoryIDs
            self.countyStorySteps = countyStorySteps
            self.completedCountyStoryBeats = completedCountyStoryBeats
            self.inspectedEvidenceIDs = inspectedEvidenceIDs
            self.madeArtifactIDs = madeArtifactIDs
            self.atlasReviews = atlasReviews
            self.calendarDaysVisited = calendarDaysVisited
        }

        private enum CodingKeys: String, CodingKey {
            case hasOpenedAtlas, evidenceInspected, storyCompleted, fieldNoteVisited
            case returnAnswered, storyInProgress, storyStep, storyFoundName
            case storyArcVersion, completedStoryBeats
            case activeCountyStoryID, completedCountyStoryIDs, countyStorySteps
            case completedCountyStoryBeats, inspectedEvidenceIDs, madeArtifactIDs
            case atlasReviews, calendarDaysVisited
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            hasOpenedAtlas = try values.decodeIfPresent(Bool.self, forKey: .hasOpenedAtlas) ?? false
            evidenceInspected = try values.decodeIfPresent(Bool.self, forKey: .evidenceInspected) ?? false
            storyCompleted = try values.decodeIfPresent(Bool.self, forKey: .storyCompleted) ?? false
            fieldNoteVisited = try values.decodeIfPresent(Bool.self, forKey: .fieldNoteVisited) ?? false
            returnAnswered = try values.decodeIfPresent(Bool.self, forKey: .returnAnswered) ?? false
            storyInProgress = try values.decodeIfPresent(Bool.self, forKey: .storyInProgress) ?? false
            storyStep = try values.decodeIfPresent(Int.self, forKey: .storyStep) ?? 0
            storyFoundName = try values.decodeIfPresent(Bool.self, forKey: .storyFoundName) ?? false
            storyArcVersion = try values.decodeIfPresent(Int.self, forKey: .storyArcVersion) ?? 1
            completedStoryBeats = try values.decodeIfPresent([Int].self, forKey: .completedStoryBeats) ?? []
            activeCountyStoryID = try values.decodeIfPresent(String.self, forKey: .activeCountyStoryID)
            completedCountyStoryIDs = try values.decodeIfPresent([String].self, forKey: .completedCountyStoryIDs) ?? []
            countyStorySteps = try values.decodeIfPresent([String: Int].self, forKey: .countyStorySteps) ?? [:]
            completedCountyStoryBeats = try values.decodeIfPresent([String: [Int]].self, forKey: .completedCountyStoryBeats) ?? [:]
            inspectedEvidenceIDs = try values.decodeIfPresent([String].self, forKey: .inspectedEvidenceIDs) ?? []
            madeArtifactIDs = try values.decodeIfPresent([String].self, forKey: .madeArtifactIDs) ?? []
            atlasReviews = try values.decodeIfPresent([String: AtlasReviewProgress].self, forKey: .atlasReviews) ?? [:]
            calendarDaysVisited = try values.decodeIfPresent([String].self, forKey: .calendarDaysVisited) ?? []
        }
    }

    /// Scheduling state for one Ar Ais visit. FSRS faoin gcraiceann — the
    /// scheduler is boring, solved technology; the learner only ever sees
    /// people asking for them, never these numbers.
    struct VisitProgress: Codable {
        var due: Date
        /// Current interval in days; grows on an easy recall, resets when
        /// the phrase needed more than one strike.
        var interval: Double
        var reps: Int
    }

    /// Scheduling state for one lexeme in the vocab deck — same interval math
    /// as Ar Ais visits, keyed by unified lexeme id (DRILL.md §1).
    typealias LexemeProgress = VisitProgress

    /// Scheduling state for one generated pattern item — composite key
    /// `pat.copula-origin:lex.gaillimh` (DRILL.md).
    typealias PatternItemProgress = VisitProgress

    struct Saved: Codable {
        var activeChapter: Int = 1
        /// Session completion per chapter, keyed by chapter number.
        var doneByChapter: [Int: [Bool]] = [:]
        /// Story-keyed completion; chapter completion remains during migration.
        var doneByStory: [String: [Bool]] = [:]
        var name: String = ""
        var visits: [String: VisitProgress] = [:]
        var lexemes: [String: LexemeProgress] = [:]
        var patternItems: [String: PatternItemProgress] = [:]
        /// Device-local personal atlas saves — published subject IDs only.
        var savedPersonalSubjects: [String] = []
        /// Opt-in recent personal-atlas subject IDs (never raw query text).
        var recentPersonalSubjects: [String] = []
        var savePersonalSearchHistory: Bool = false
        /// Private, device-local correction leads. Never public without review.
        var personalAtlasFeedback: [PersonalAtlasFeedback] = []
        /// Privacy-safe product events: published ids and coarse outcomes only.
        var personalAtlasQueryLedger: [PersonalAtlasQueryEvent] = []
        /// Resume state for the current living-atlas encounter.
        var atlasProgress = AtlasProgress()

        init() {}

        private enum Keys: String, CodingKey {
            case activeChapter, doneByChapter, doneByStory, name, visits, lexemes, patternItems, done
            case savedPersonalSubjects, recentPersonalSubjects, savePersonalSearchHistory
            case personalAtlasFeedback, personalAtlasQueryLedger
            case atlasProgress
        }

        // Custom decode: migrate single-chapter saves and pre-Ar-Ais writes.
        init(from decoder: Decoder) throws {
            let keys = try decoder.container(keyedBy: Keys.self)
            activeChapter = try keys.decodeIfPresent(Int.self, forKey: .activeChapter) ?? 1
            doneByChapter = try keys.decodeIfPresent([Int: [Bool]].self, forKey: .doneByChapter) ?? [:]
            doneByStory = try keys.decodeIfPresent([String: [Bool]].self, forKey: .doneByStory) ?? [:]
            name = try keys.decodeIfPresent(String.self, forKey: .name) ?? ""
            visits = try keys.decodeIfPresent([String: VisitProgress].self, forKey: .visits) ?? [:]
            lexemes = try keys.decodeIfPresent([String: LexemeProgress].self, forKey: .lexemes) ?? [:]
            patternItems = try keys.decodeIfPresent([String: PatternItemProgress].self, forKey: .patternItems) ?? [:]
            savedPersonalSubjects = try keys.decodeIfPresent([String].self, forKey: .savedPersonalSubjects) ?? []
            recentPersonalSubjects = try keys.decodeIfPresent([String].self, forKey: .recentPersonalSubjects) ?? []
            savePersonalSearchHistory = try keys.decodeIfPresent(Bool.self, forKey: .savePersonalSearchHistory) ?? false
            personalAtlasFeedback = try keys.decodeIfPresent([PersonalAtlasFeedback].self, forKey: .personalAtlasFeedback) ?? []
            personalAtlasQueryLedger = try keys.decodeIfPresent([PersonalAtlasQueryEvent].self, forKey: .personalAtlasQueryLedger) ?? []
            atlasProgress = try keys.decodeIfPresent(AtlasProgress.self, forKey: .atlasProgress) ?? AtlasProgress()

            if doneByChapter.isEmpty,
               let legacyDone = try keys.decodeIfPresent([Bool].self, forKey: .done) {
                doneByChapter[1] = legacyDone
                if legacyDone.allSatisfy({ $0 }), activeChapter < 2 {
                    activeChapter = 2
                }
            }
        }

        func encode(to encoder: Encoder) throws {
            var keys = encoder.container(keyedBy: Keys.self)
            try keys.encode(activeChapter, forKey: .activeChapter)
            try keys.encode(doneByChapter, forKey: .doneByChapter)
            try keys.encode(doneByStory, forKey: .doneByStory)
            try keys.encode(name, forKey: .name)
            try keys.encode(visits, forKey: .visits)
            try keys.encode(lexemes, forKey: .lexemes)
            try keys.encode(patternItems, forKey: .patternItems)
            try keys.encode(savedPersonalSubjects, forKey: .savedPersonalSubjects)
            try keys.encode(recentPersonalSubjects, forKey: .recentPersonalSubjects)
            try keys.encode(savePersonalSearchHistory, forKey: .savePersonalSearchHistory)
            try keys.encode(personalAtlasFeedback, forKey: .personalAtlasFeedback)
            try keys.encode(personalAtlasQueryLedger, forKey: .personalAtlasQueryLedger)
            try keys.encode(atlasProgress, forKey: .atlasProgress)
        }
    }

    @Published var activeChapterN: Int
    @Published var done: [Bool]
    @Published var learnerName: String {
        didSet { persist() }
    }
    @Published var visitProgress: [String: VisitProgress]
    @Published var lexemeProgress: [String: LexemeProgress]
    @Published var patternProgress: [String: PatternItemProgress]
    @Published var artBranch: String? = nil
    @Published var savedPersonalSubjects: [String] {
        didSet { persist() }
    }
    @Published var recentPersonalSubjects: [String] {
        didSet { persist() }
    }
    @Published var savePersonalSearchHistory: Bool {
        didSet { persist() }
    }
    @Published var personalAtlasFeedback: [PersonalAtlasFeedback] {
        didSet { persist() }
    }
    @Published var personalAtlasQueryLedger: [PersonalAtlasQueryEvent] {
        didSet { persist() }
    }
    @Published var atlasProgress: AtlasProgress {
        didSet { persist() }
    }

    let journey: [JourneyChapter]

    /// Per-chapter session flags — the road behind you, chapter by chapter.
    private var doneByChapter: [Int: [Bool]]
    /// The county-story progress key introduced by the story-first migration.
    private var doneByStory: [String: [Bool]]

    private static let key = "turas_progress"
    private static let legacyKey = "turas_c1"

    /// The chapter the learner is working through (1-based).
    var chapterN: Int { activeChapterN }

    var chapter: Chapter { ContentLoader.chapter(activeChapterN) }

    /// The migrated county story now in hand, if this chapter has one.
    var activeStory: CountyStory? { ContentLoader.story(forLegacyChapter: activeChapterN) }

    /// Visits from every chapter walked so far — session indices stay local.
    var visits: [Visit] {
        ContentLoader.visits(throughChapter: activeChapterN)
    }

    /// Earned lexemes from every chapter walked so far.
    var lexicon: [Lexeme] {
        ContentLoader.lexicon(throughChapter: activeChapterN)
            .filter { hasEarned($0.earnedAt) }
    }

    init() {
        journey = ContentLoader.journey()

        let saved: Saved
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(Saved.self, from: data) {
            saved = decoded
        } else if let legacy = UserDefaults.standard.data(forKey: Self.legacyKey),
                  let decoded = try? JSONDecoder().decode(LegacySaved.self, from: legacy) {
            saved = Self.migrateLegacy(decoded)
        } else {
            saved = Saved()
        }

        var activeChapter = saved.activeChapter
        var progressByChapter = saved.doneByChapter
        var progressByStory = saved.doneByStory
        var name = saved.name
        var progress = saved.visits
        var lexProgress = saved.lexemes
        var patProgress = saved.patternItems
        var chapterOverride = false

        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        chapterOverride = args.contains("--chapter")
        if let flagIndex = args.firstIndex(of: "--chapter"),
           args.indices.contains(flagIndex + 1),
           let n = Int(args[flagIndex + 1]) {
            activeChapter = min(max(n, 1), ContentLoader.maxChapter)
        }
        if let flagIndex = args.firstIndex(of: "--name"),
           args.indices.contains(flagIndex + 1) {
            name = args[flagIndex + 1]
        }
        #endif

        activeChapter = min(max(activeChapter, 1), ContentLoader.maxChapter)

        // Preserve every legacy Chapter 1 save by writing the same flags under
        // Mayo's durable story id. This runs once and is safe to repeat.
        var storyMigrationAdded = false
        for story in ContentLoader.stories() {
            guard let legacyChapter = story.legacyChapter,
                  progressByStory[story.storyId] == nil,
                  let legacyDone = progressByChapter[legacyChapter]
            else { continue }
            progressByStory[story.storyId] = legacyDone
            storyMigrationAdded = true
        }

        if !chapterOverride {
            while activeChapter < ContentLoader.maxChapter {
                let flags = Self.normalizedDone(
                    progressByChapter[activeChapter],
                    sessionCount: ContentLoader.chapter(activeChapter).sessions.count)
                guard !flags.isEmpty, flags.allSatisfy({ $0 }) else { break }
                activeChapter += 1
            }
        }

        doneByChapter = progressByChapter
        doneByStory = progressByStory

        let activeProgress = ContentLoader.story(forLegacyChapter: activeChapter)
            .flatMap { progressByStory[$0.storyId] }
            ?? progressByChapter[activeChapter]
        var doneFlags = Self.normalizedDone(
            activeProgress,
            sessionCount: ContentLoader.chapter(activeChapter).sessions.count)

        #if DEBUG
        let debugArgs = ProcessInfo.processInfo.arguments
        if let flagIndex = debugArgs.firstIndex(of: "--done"),
           debugArgs.indices.contains(flagIndex + 1),
           let count = Int(debugArgs[flagIndex + 1]) {
            for index in doneFlags.indices { doneFlags[index] = index < count }
            progressByChapter[activeChapter] = doneFlags
            if let story = ContentLoader.story(forLegacyChapter: activeChapter) {
                progressByStory[story.storyId] = doneFlags
            }
            doneByChapter = progressByChapter
            doneByStory = progressByStory
        }
        if let flagIndex = debugArgs.firstIndex(of: "--due"),
           debugArgs.indices.contains(flagIndex + 1),
           let count = Int(debugArgs[flagIndex + 1]) {
            let allVisits = ContentLoader.visits(throughChapter: activeChapter)
            for (offset, visit) in allVisits.prefix(count).enumerated() {
                progress[visit.id] = VisitProgress(
                    due: Date().addingTimeInterval(-Double(offset) * 2 * 86400),
                    interval: 1, reps: 0)
            }
            let allLexemes = ContentLoader.lexicon(throughChapter: activeChapter)
            for (offset, lexeme) in allLexemes.prefix(count).enumerated() {
                lexProgress[lexeme.id] = LexemeProgress(
                    due: Date().addingTimeInterval(-Double(offset) * 86400),
                    interval: 1, reps: 0)
            }
            let allPatterns = ContentLoader.patterns(throughChapter: activeChapter)
            var patOffset = 0
            for pattern in allPatterns {
                let items = PatternDrill.items(for: pattern, in: allLexemes)
                for item in items.prefix(max(1, count - patOffset)) {
                    let key = PatternDrill.scheduleKey(pattern: pattern, item: item)
                    patProgress[key] = PatternItemProgress(
                        due: Date().addingTimeInterval(-Double(patOffset) * 86400),
                        interval: 1, reps: 0)
                    patOffset += 1
                }
            }
        }
        if let flagIndex = debugArgs.firstIndex(of: "--art"),
           debugArgs.indices.contains(flagIndex + 1) {
            artBranch = debugArgs[flagIndex + 1]
        }
        #endif

        // Migration: sessions finished before Ar Ais existed still owe their
        // people a visit — schedule across every chapter walked so far.
        var migrationAdded = false
        for chapterNum in 1...activeChapter {
            let chapterDone = progressByChapter[chapterNum]
                ?? (chapterNum == activeChapter ? doneFlags : [])
            let chapterVisits = ContentLoader.visits(forChapter: chapterNum)
            for (index, isDone) in chapterDone.enumerated() where isDone {
                for visit in chapterVisits where visit.session == index && progress[visit.id] == nil {
                    progress[visit.id] = VisitProgress(
                        due: Date().addingTimeInterval(86400), interval: 1, reps: 0)
                    migrationAdded = true
                }
                let chapterLexicon = ContentLoader.lexicon(forChapter: chapterNum)
                for lexeme in chapterLexicon where lexeme.earnedAt?.session == index
                    && lexProgress[lexeme.id] == nil {
                    lexProgress[lexeme.id] = LexemeProgress(due: Date(), interval: 1, reps: 0)
                    migrationAdded = true
                }
                let chapterPatterns = ContentLoader.patterns(forChapter: chapterNum)
                let chapterLex = ContentLoader.lexicon(forChapter: chapterNum)
                for pattern in chapterPatterns where pattern.earnedAt?.session == index {
                    for item in PatternDrill.items(for: pattern, in: chapterLex) {
                        let key = PatternDrill.scheduleKey(pattern: pattern, item: item)
                        if patProgress[key] == nil {
                            patProgress[key] = PatternItemProgress(due: Date(), interval: 1, reps: 0)
                            migrationAdded = true
                        }
                    }
                }
            }
        }

        activeChapterN = activeChapter
        done = doneFlags
        learnerName = name
        visitProgress = progress
        lexemeProgress = lexProgress
        patternProgress = patProgress
        savedPersonalSubjects = saved.savedPersonalSubjects
        recentPersonalSubjects = saved.recentPersonalSubjects
        savePersonalSearchHistory = saved.savePersonalSearchHistory
        personalAtlasFeedback = saved.personalAtlasFeedback
        personalAtlasQueryLedger = saved.personalAtlasQueryLedger
        atlasProgress = saved.atlasProgress

        let migratedFromLegacy = UserDefaults.standard.data(forKey: Self.key) == nil
            && UserDefaults.standard.data(forKey: Self.legacyKey) != nil

        var seeded = false
        #if DEBUG
        seeded = ProcessInfo.processInfo.arguments.contains("--done")
            || ProcessInfo.processInfo.arguments.contains("--due")
        #endif
        if (migrationAdded || storyMigrationAdded || migratedFromLegacy) && !seeded {
            persist()
        }
    }

    var allDone: Bool { done.allSatisfy { $0 } }

    /// The chapter highlighted on the island map (1-based).
    var currentChapterN: Int {
        isChapterComplete(activeChapterN)
            ? min(activeChapterN + 1, ContentLoader.maxChapter + 1)
            : activeChapterN
    }

    /// Chapters whose five sessions are all carved.
    var completedChapterCount: Int {
        (1...ContentLoader.maxChapter).filter(isChapterComplete).count
    }

    func isChapterComplete(_ chapterN: Int) -> Bool {
        if let story = ContentLoader.story(forLegacyChapter: chapterN),
           let flags = doneByStory[story.storyId] {
            return !flags.isEmpty && flags.allSatisfy { $0 }
        }
        guard let flags = doneByChapter[chapterN] else { return false }
        return !flags.isEmpty && flags.allSatisfy { $0 }
    }

    func isStoryComplete(_ story: CountyStory) -> Bool {
        guard let flags = doneByStory[story.storyId] else { return false }
        return !flags.isEmpty && flags.allSatisfy { $0 }
    }

    func markDone(_ index: Int) {
        guard done.indices.contains(index) else { return }
        done[index] = true
        doneByChapter[activeChapterN] = done
        if let story = activeStory {
            doneByStory[story.storyId] = done
        }

        let chapterVisits = ContentLoader.visits(forChapter: activeChapterN)
        for visit in chapterVisits where visit.session == index && visitProgress[visit.id] == nil {
            visitProgress[visit.id] = VisitProgress(
                due: Date().addingTimeInterval(86400), interval: 1, reps: 0)
        }

        let chapterLexicon = ContentLoader.lexicon(forChapter: activeChapterN)
        for lexeme in chapterLexicon where lexeme.earnedAt?.session == index
            && lexemeProgress[lexeme.id] == nil {
            // Available immediately for the optional first pass — the session
            // hook and hub offer, never a gate (DRILL.md).
            lexemeProgress[lexeme.id] = LexemeProgress(due: Date(), interval: 1, reps: 0)
        }

        let earnedLexicon = ContentLoader.lexicon(forChapter: activeChapterN)
        let chapterPatterns = ContentLoader.patterns(forChapter: activeChapterN)
        for pattern in chapterPatterns where pattern.earnedAt?.session == index {
            for item in PatternDrill.items(for: pattern, in: earnedLexicon) {
                let key = PatternDrill.scheduleKey(pattern: pattern, item: item)
                if patternProgress[key] == nil {
                    patternProgress[key] = PatternItemProgress(due: Date(), interval: 1, reps: 0)
                }
            }
        }

        persist()
    }

    /// Move to the next chapter once the current one is fully carved — called
    /// when leaving a session or opening the map so the completion page can
    /// still read `allDone` on the chapter just finished.
    func advanceToNextChapterIfNeeded() {
        guard isChapterComplete(activeChapterN),
              activeChapterN < ContentLoader.maxChapter else { return }
        activeChapterN += 1
        let nextProgress = ContentLoader.story(forLegacyChapter: activeChapterN)
            .flatMap { doneByStory[$0.storyId] }
            ?? doneByChapter[activeChapterN]
        done = Self.normalizedDone(
            nextProgress,
            sessionCount: chapter.sessions.count)
        persist()
    }

    /// Whether the story has completed the session that earns an item — the
    /// invariant that keeps the drill surface downstream of the narrative
    /// (DRILL.md). A pattern is only offered once its scene is behind you.
    func hasEarned(_ ref: ContentRef?) -> Bool {
        guard let ref, ref.chapter <= activeChapterN else { return false }
        if ref.chapter < activeChapterN { return true }
        guard let session = ref.session else { return true }
        return done.indices.contains(session) && done[session]
    }

    // MARK: Ar Ais scheduling

    func dueVisits(now: Date = Date()) -> [Visit] {
        visits
            .filter { visit in
                guard let p = visitProgress[visit.id] else { return false }
                return p.due <= now
            }
            .sorted { (visitProgress[$0.id]?.due ?? now) < (visitProgress[$1.id]?.due ?? now) }
    }

    /// The soonest future visit — powers "fillfidh Dáire amárach" copy.
    func nextReturn(now: Date = Date()) -> (visit: Visit, due: Date)? {
        visits
            .compactMap { visit -> (Visit, Date)? in
                guard let p = visitProgress[visit.id], p.due > now else { return nil }
                return (visit, p.due)
            }
            .min { $0.1 < $1.1 }
    }

    /// A visit was answered. One clean strike widens the interval; a
    /// struggle brings them back tomorrow. Never shown as a number.
    func completeVisit(_ visit: Visit, struggled: Bool, now: Date = Date()) {
        var p = visitProgress[visit.id]
            ?? VisitProgress(due: now, interval: 1, reps: 0)
        p.interval = struggled ? 1 : max(p.interval * 2.5, 2.5)
        p.due = now.addingTimeInterval(p.interval * 86400)
        p.reps += 1
        visitProgress[visit.id] = p
        persist()
    }

    // MARK: Vocab deck scheduling (DRILL.md §1)

    func dueLexemes(now: Date = Date()) -> [Lexeme] {
        lexicon
            .filter { lexeme in
                guard let p = lexemeProgress[lexeme.id] else { return false }
                return p.due <= now
            }
            .sorted { (lexemeProgress[$0.id]?.due ?? now) < (lexemeProgress[$1.id]?.due ?? now) }
    }

    /// Lexemes from a session ready for the optional first-pass deck offer at
    /// session close — due now and not yet produced in the deck.
    func deckOfferLexemes(forSession session: Int) -> [Lexeme] {
        dueLexemes()
            .filter {
                guard let earned = $0.earnedAt,
                      earned.chapter == activeChapterN,
                      earned.session == session else { return false }
                return (lexemeProgress[$0.id]?.reps ?? 0) == 0
            }
    }

    func nextLexemeReturn(now: Date = Date()) -> (lexeme: Lexeme, due: Date)? {
        lexicon
            .compactMap { lexeme -> (Lexeme, Date)? in
                guard let p = lexemeProgress[lexeme.id], p.due > now else { return nil }
                return (lexeme, p.due)
            }
            .min { $0.1 < $1.1 }
    }

    func completeLexeme(_ lexeme: Lexeme, struggled: Bool, now: Date = Date()) {
        var p = lexemeProgress[lexeme.id]
            ?? LexemeProgress(due: now, interval: 1, reps: 0)
        p.interval = struggled ? 1 : max(p.interval * 2.5, 2.5)
        p.due = now.addingTimeInterval(p.interval * 86400)
        p.reps += 1
        lexemeProgress[lexeme.id] = p
        persist()
    }

    /// Cross-surface recall credit — inline exercise success advances the same
    /// groove as the vocab deck when the block carries a lexeme `ref`.
    func creditLexeme(id: String, struggled: Bool, inSession sessionIndex: Int, now: Date = Date()) {
        guard let lexeme = ContentLoader.lexicon(throughChapter: activeChapterN)
            .first(where: { $0.id == id }),
              let earned = lexeme.earnedAt else { return }
        if earned.chapter < activeChapterN {
            completeLexeme(lexeme, struggled: struggled, now: now)
        } else if earned.chapter == activeChapterN, let session = earned.session, session <= sessionIndex {
            completeLexeme(lexeme, struggled: struggled, now: now)
        }
    }

    func creditLexemes(ids: [String], struggled: Bool, inSession sessionIndex: Int, now: Date = Date()) {
        for id in ids { creditLexeme(id: id, struggled: struggled, inSession: sessionIndex, now: now) }
    }

    // MARK: Pattern drill scheduling (DRILL.md — composite keys)

    func duePatternItems(for pattern: Pattern, now: Date = Date()) -> [SubstitutionItem] {
        let lexicon = ContentLoader.lexicon(throughChapter: activeChapterN)
        return PatternDrill.dueItems(
            for: pattern,
            in: lexicon,
            progress: patternProgress,
            now: now)
    }

    func duePatternItemCount(now: Date = Date()) -> Int {
        ContentLoader.patterns(throughChapter: activeChapterN)
            .filter { hasEarned($0.earnedAt) }
            .reduce(0) { $0 + duePatternItems(for: $1, now: now).count }
    }

    func completePatternItem(
        pattern: Pattern,
        item: SubstitutionItem,
        struggled: Bool,
        now: Date = Date()
    ) {
        let key = PatternDrill.scheduleKey(pattern: pattern, item: item)
        var p = patternProgress[key]
            ?? PatternItemProgress(due: now, interval: 1, reps: 0)
        p.interval = struggled ? 1 : max(p.interval * 2.5, 2.5)
        p.due = now.addingTimeInterval(p.interval * 86400)
        p.reps += 1
        patternProgress[key] = p
        if let lexeme = item.source {
            completeLexeme(lexeme, struggled: struggled, now: now)
        }
        persist()
    }

    /// How many earned lexemes in a chapter have been produced in the deck at
    /// least once — the honest coverage signal (DRILL.md).
    func producedLexemes(inChapter chapterN: Int) -> Int {
        ContentLoader.lexicon(forChapter: chapterN)
            .filter { hasEarned($0.earnedAt) && (lexemeProgress[$0.id]?.reps ?? 0) > 0 }
            .count
    }

    private func persist() {
        doneByChapter[activeChapterN] = done
        if let story = activeStory {
            doneByStory[story.storyId] = done
        }
        var saved = Saved()
        saved.activeChapter = activeChapterN
        saved.doneByChapter = doneByChapter
        saved.doneByStory = doneByStory
        saved.name = learnerName
        saved.visits = visitProgress
        saved.lexemes = lexemeProgress
        saved.patternItems = patternProgress
        saved.savedPersonalSubjects = savedPersonalSubjects
        saved.recentPersonalSubjects = recentPersonalSubjects
        saved.savePersonalSearchHistory = savePersonalSearchHistory
        saved.personalAtlasFeedback = personalAtlasFeedback
        saved.personalAtlasQueryLedger = personalAtlasQueryLedger
        saved.atlasProgress = atlasProgress
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    // MARK: Personal atlas (device-local)

    func isPersonalSubjectSaved(_ id: String) -> Bool {
        savedPersonalSubjects.contains(id)
    }

    func togglePersonalSubject(_ id: String) {
        if let idx = savedPersonalSubjects.firstIndex(of: id) {
            savedPersonalSubjects.remove(at: idx)
        } else {
            savedPersonalSubjects.insert(id, at: 0)
        }
    }

    /// Records a published subject ID only — never the raw query string.
    func recordPersonalQuery(subjectId: String) {
        guard savePersonalSearchHistory else { return }
        recentPersonalSubjects.removeAll { $0 == subjectId }
        recentPersonalSubjects.insert(subjectId, at: 0)
        if recentPersonalSubjects.count > 12 {
            recentPersonalSubjects = Array(recentPersonalSubjects.prefix(12))
        }
    }

    func submitPersonalAtlasFeedback(
        subjectId: String,
        assertionId: String?,
        kind: PersonalAtlasFeedback.Kind,
        context: String,
        sourceURL: String?
    ) {
        personalAtlasFeedback.insert(
            PersonalAtlasFeedback(
                id: UUID(),
                subjectId: subjectId,
                assertionId: assertionId,
                kind: kind,
                context: context.trimmingCharacters(in: .whitespacesAndNewlines),
                sourceURL: sourceURL?.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: Date()
            ),
            at: 0
        )
    }

    /// Deliberately accepts no raw query or coordinates. This API makes the privacy
    /// boundary enforceable at the call site rather than relying on convention.
    func recordPersonalAtlasEvent(
        subjectId: String?,
        outcome: PersonalAtlasQueryEvent.Outcome,
        unresolvedReason: String? = nil,
        selectedAmbiguityBranchId: String? = nil,
        timeToAnswerMilliseconds: Int? = nil
    ) {
        personalAtlasQueryLedger.insert(
            PersonalAtlasQueryEvent(
                subjectId: subjectId,
                outcome: outcome,
                unresolvedReason: unresolvedReason,
                selectedAmbiguityBranchId: selectedAmbiguityBranchId,
                timeToAnswerMilliseconds: timeToAnswerMilliseconds
            ),
            at: 0
        )
        personalAtlasQueryLedger = Array(personalAtlasQueryLedger.prefix(200))
    }

    // MARK: - Save migration

    /// Pre-multi-chapter save shape (`turas_c1`).
    private struct LegacySaved: Codable {
        var done: [Bool] = []
        var name: String = ""
        var visits: [String: VisitProgress] = [:]
    }

    private static func migrateLegacy(_ legacy: LegacySaved) -> Saved {
        var saved = Saved()
        saved.name = legacy.name
        saved.visits = legacy.visits
        saved.doneByChapter[1] = legacy.done
        if legacy.done.allSatisfy({ $0 }) {
            saved.activeChapter = 2
        }
        return saved
    }

    private static func normalizedDone(_ flags: [Bool]?, sessionCount: Int) -> [Bool] {
        var out = flags ?? []
        if out.count != sessionCount {
            out = Array(repeating: false, count: sessionCount)
        }
        return out
    }
}

extension AppState.Saved {
    init(activeChapter: Int,
         doneByChapter: [Int: [Bool]],
         name: String,
         visits: [String: AppState.VisitProgress],
         lexemes: [String: AppState.LexemeProgress] = [:],
         patternItems: [String: AppState.PatternItemProgress] = [:]) {
        self.init()
        self.activeChapter = activeChapter
        self.doneByChapter = doneByChapter
        self.name = name
        self.visits = visits
        self.lexemes = lexemes
        self.patternItems = patternItems
    }
}

// MARK: - Time, spoken the way the app speaks

enum Turas {
    /// "inniu" / "1 lá ó shin" / "3 lá ó shin" — how long someone has been
    /// waiting at the stone.
    static func ago(_ due: Date, now: Date = Date()) -> String {
        let days = max(0, Int(now.timeIntervalSince(due) / 86400))
        switch days {
        case 0: return "inniu"
        case 1: return "1 lá ó shin"
        default: return "\(days) lá ó shin"
        }
    }

    /// "níos deireanaí inniu" / "amárach" / "i gceann 3 lá" — when the next
    /// visitor will come asking.
    static func until(_ due: Date, now: Date = Date()) -> String {
        let days = Int(ceil(due.timeIntervalSince(now) / 86400))
        switch days {
        case ..<1: return "níos deireanaí inniu"
        case 1: return "amárach"
        default: return "i gceann \(days) lá"
        }
    }

    /// Counting people the Irish way: duine amháin, beirt, triúr…
    static func people(_ count: Int) -> String {
        switch count {
        case 1: return "duine amháin"
        case 2: return "beirt"
        case 3: return "triúr"
        case 4: return "ceathrar"
        case 5: return "cúigear"
        case 6: return "seisear"
        case 7: return "seachtar"
        default: return "\(count) duine"
        }
    }
}
