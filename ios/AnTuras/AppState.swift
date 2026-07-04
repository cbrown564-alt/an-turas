import Foundation
import Combine

// MARK: - Progress persistence (prototype-grade: UserDefaults JSON)

final class AppState: ObservableObject {
    struct Saved: Codable {
        var done: [Bool] = [false, false, false, false, false]
        var name: String = ""
    }

    @Published var done: [Bool]
    @Published var learnerName: String {
        didSet { persist() }
    }

    let chapter: Chapter

    private static let key = "turas_c1"

    init() {
        chapter = ContentLoader.chapter1()
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
        done = doneFlags
        learnerName = saved.name
    }

    var allDone: Bool { done.allSatisfy { $0 } }

    func markDone(_ index: Int) {
        guard done.indices.contains(index) else { return }
        done[index] = true
        persist()
    }

    private func persist() {
        let saved = Saved(done: done, name: learnerName)
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
