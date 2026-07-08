import Foundation
import Combine

// MARK: - Progress persistence (prototype-grade: UserDefaults JSON)

final class AppState: ObservableObject {
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

    struct Saved: Codable {
        var activeChapter: Int = 1
        /// Session completion per chapter, keyed by chapter number.
        var doneByChapter: [Int: [Bool]] = [:]
        var name: String = ""
        var visits: [String: VisitProgress] = [:]

        init() {}

        private enum Keys: String, CodingKey {
            case activeChapter, doneByChapter, name, visits, done
        }

        // Custom decode: migrate single-chapter saves and pre-Ar-Ais writes.
        init(from decoder: Decoder) throws {
            let keys = try decoder.container(keyedBy: Keys.self)
            activeChapter = try keys.decodeIfPresent(Int.self, forKey: .activeChapter) ?? 1
            doneByChapter = try keys.decodeIfPresent([Int: [Bool]].self, forKey: .doneByChapter) ?? [:]
            name = try keys.decodeIfPresent(String.self, forKey: .name) ?? ""
            visits = try keys.decodeIfPresent([String: VisitProgress].self, forKey: .visits) ?? [:]

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
            try keys.encode(name, forKey: .name)
            try keys.encode(visits, forKey: .visits)
        }
    }

    @Published var activeChapterN: Int
    @Published var done: [Bool]
    @Published var learnerName: String {
        didSet { persist() }
    }
    @Published var visitProgress: [String: VisitProgress]
    @Published var artBranch: String? = nil

    let journey: [JourneyChapter]

    /// Per-chapter session flags — the road behind you, chapter by chapter.
    private var doneByChapter: [Int: [Bool]]

    private static let key = "turas_progress"
    private static let legacyKey = "turas_c1"

    /// The chapter the learner is working through (1-based).
    var chapterN: Int { activeChapterN }

    var chapter: Chapter { ContentLoader.chapter(activeChapterN) }

    /// Visits from every chapter walked so far — session indices stay local.
    var visits: [Visit] {
        ContentLoader.visits(throughChapter: activeChapterN)
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
        var name = saved.name
        var progress = saved.visits
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

        var doneFlags = Self.normalizedDone(
            progressByChapter[activeChapter],
            sessionCount: ContentLoader.chapter(activeChapter).sessions.count)

        #if DEBUG
        let debugArgs = ProcessInfo.processInfo.arguments
        if let flagIndex = debugArgs.firstIndex(of: "--done"),
           debugArgs.indices.contains(flagIndex + 1),
           let count = Int(debugArgs[flagIndex + 1]) {
            for index in doneFlags.indices { doneFlags[index] = index < count }
            progressByChapter[activeChapter] = doneFlags
            doneByChapter = progressByChapter
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
            }
        }

        activeChapterN = activeChapter
        done = doneFlags
        learnerName = name
        visitProgress = progress

        let migratedFromLegacy = UserDefaults.standard.data(forKey: Self.key) == nil
            && UserDefaults.standard.data(forKey: Self.legacyKey) != nil

        var seeded = false
        #if DEBUG
        seeded = ProcessInfo.processInfo.arguments.contains("--done")
            || ProcessInfo.processInfo.arguments.contains("--due")
        #endif
        if (migrationAdded || migratedFromLegacy) && !seeded {
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
        guard let flags = doneByChapter[chapterN] else { return false }
        return !flags.isEmpty && flags.allSatisfy { $0 }
    }

    func markDone(_ index: Int) {
        guard done.indices.contains(index) else { return }
        done[index] = true
        doneByChapter[activeChapterN] = done

        let chapterVisits = ContentLoader.visits(forChapter: activeChapterN)
        for visit in chapterVisits where visit.session == index && visitProgress[visit.id] == nil {
            visitProgress[visit.id] = VisitProgress(
                due: Date().addingTimeInterval(86400), interval: 1, reps: 0)
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
        done = Self.normalizedDone(
            doneByChapter[activeChapterN],
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

    private func persist() {
        doneByChapter[activeChapterN] = done
        let saved = Saved(
            activeChapter: activeChapterN,
            doneByChapter: doneByChapter,
            name: learnerName,
            visits: visitProgress)
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
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
         visits: [String: AppState.VisitProgress]) {
        self.init()
        self.activeChapter = activeChapter
        self.doneByChapter = doneByChapter
        self.name = name
        self.visits = visits
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
