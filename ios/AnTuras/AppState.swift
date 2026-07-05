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
        var done: [Bool] = [false, false, false, false, false]
        var name: String = ""
        var visits: [String: VisitProgress] = [:]

        init() {}

        // Custom decode so saves written before Ar Ais existed still load.
        private enum Keys: String, CodingKey { case done, name, visits }
        init(from decoder: Decoder) throws {
            let keys = try decoder.container(keyedBy: Keys.self)
            done = try keys.decodeIfPresent([Bool].self, forKey: .done) ?? []
            name = try keys.decodeIfPresent(String.self, forKey: .name) ?? ""
            visits = try keys.decodeIfPresent([String: VisitProgress].self, forKey: .visits) ?? [:]
        }
    }

    @Published var done: [Bool]
    @Published var learnerName: String {
        didSet { persist() }
    }
    @Published var visitProgress: [String: VisitProgress]
    @Published var artBranch: String? = nil

    let chapter: Chapter
    let journey: [JourneyChapter]
    let visits: [Visit]

    private static let key = "turas_c1"

    init() {
        chapter = ContentLoader.chapter1()
        journey = ContentLoader.journey()
        visits = ContentLoader.visits()
        let saved: Saved
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(Saved.self, from: data) {
            saved = decoded
        } else {
            saved = Saved()
        }
        var doneFlags = saved.done
        if doneFlags.count != chapter.sessions.count {
            doneFlags = Array(repeating: false, count: chapter.sessions.count)
        }
        var name = saved.name
        var progress = saved.visits

        // Debug seeding for screenshots/snapshot tests, alongside --map,
        // --session and --reveal: `--name Niamh` sets the learner name,
        // `--done N` marks the first N sessions carved, `--due N` backdates
        // N visits so the Ar Ais queue can be demoed without waiting a day.
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let flagIndex = args.firstIndex(of: "--name"),
           args.indices.contains(flagIndex + 1) {
            name = args[flagIndex + 1]
        }
        if let flagIndex = args.firstIndex(of: "--done"),
           args.indices.contains(flagIndex + 1),
           let count = Int(args[flagIndex + 1]) {
            for index in doneFlags.indices { doneFlags[index] = index < count }
        }
        if let flagIndex = args.firstIndex(of: "--due"),
           args.indices.contains(flagIndex + 1),
           let count = Int(args[flagIndex + 1]) {
            for (offset, visit) in visits.prefix(count).enumerated() {
                // Staggered into the past so the queue reads lived-in:
                // inniu, 2 lá ó shin, 4 lá ó shin…
                progress[visit.id] = VisitProgress(
                    due: Date().addingTimeInterval(-Double(offset) * 2 * 86400),
                    interval: 1, reps: 0)
            }
        }
        if let flagIndex = args.firstIndex(of: "--art"),
           args.indices.contains(flagIndex + 1) {
            artBranch = args[flagIndex + 1]
        }
        #endif

        // Migration: sessions finished before Ar Ais existed (or seeded via
        // --done) still owe the road their people. Schedule them as if the
        // session ended today — they'll come asking tomorrow.
        var migrationAdded = false
        for (index, isDone) in doneFlags.enumerated() where isDone {
            for visit in visits where visit.session == index && progress[visit.id] == nil {
                progress[visit.id] = VisitProgress(
                    due: Date().addingTimeInterval(86400), interval: 1, reps: 0)
                migrationAdded = true
            }
        }

        done = doneFlags
        learnerName = name
        visitProgress = progress

        // Write the migration through so the due dates stop sliding — but
        // never persist state invented by debug seeding.
        var seeded = false
        #if DEBUG
        seeded = ProcessInfo.processInfo.arguments.contains("--done")
            || ProcessInfo.processInfo.arguments.contains("--due")
        #endif
        if migrationAdded && !seeded {
            persist()
        }
    }

    var allDone: Bool { done.allSatisfy { $0 } }

    /// The chapter the learner is standing in (1-based, as on the map).
    /// Only chapter 1 has content; once it's carved the road points at 2.
    var currentChapterN: Int { allDone ? 2 : 1 }

    func markDone(_ index: Int) {
        guard done.indices.contains(index) else { return }
        done[index] = true
        // Finishing a session puts its people on the road: they'll come
        // asking tomorrow, not tonight — the amárach hook stays honest.
        for visit in visits where visit.session == index && visitProgress[visit.id] == nil {
            visitProgress[visit.id] = VisitProgress(
                due: Date().addingTimeInterval(86400), interval: 1, reps: 0)
        }
        persist()
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
        let saved = Saved(done: done, name: learnerName, visits: visitProgress)
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}

extension AppState.Saved {
    init(done: [Bool], name: String, visits: [String: AppState.VisitProgress]) {
        self.init()
        self.done = done
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
