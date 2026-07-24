import Foundation

// MARK: - Versioned county content packs

enum CountyStoryMode: String, Codable, CaseIterable, Identifiable {
    case story
    case learning

    var id: String { rawValue }
    var title: String { self == .story ? "Story" : "Learning" }
}

enum CountyPackScope: String, Codable {
    case representativeChapter
    case editorialPreview
    case completeCounty
}

enum CountyPageVisibility: String, Codable {
    case storyOnly
    case learningOnly
    case both

    func includes(_ mode: CountyStoryMode) -> Bool {
        switch (self, mode) {
        case (.both, _), (.storyOnly, .story), (.learningOnly, .learning): return true
        default: return false
        }
    }
}

enum CountyPageRequirement: String, Codable {
    case storyRequired
    case learningRequired
    case bothRequired
    case optional
}

enum CountyPageKind: String, Codable {
    case narrative
    case exercise
}

/// Authored narrative composition, stored with the county content rather than
/// inferred from a page index. The cases form a reusable pacing vocabulary:
/// place, explanation, language, evidence, pressure and consequence.
enum CountyNarrativePresentation: String, Codable, Hashable {
    case editorial
    case coastalOpening
    case tidalMeasure
    case movementLine
    case languageField
    case relationshipField
    case connectedSystem
    case archive
    case evidenceBoundary
    case pressureField
    case closingQuestion
}

struct CountyNarrativeDisplayItem: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
}

enum CountyExerciseFamily: String, Codable, CaseIterable {
    case listenIdentify
    case listenBuildSentence
    case sentenceConstruction
    case fillGap
    case matching
    case typing
    case dialogue
    case sequencing
    case comprehension
    case speaking
    case grammarDiscovery
    case delayedRetrieval

    var title: String {
        switch self {
        case .listenIdentify: return "Listen and identify"
        case .listenBuildSentence: return "Listen and build"
        case .sentenceConstruction: return "Build a sentence"
        case .fillGap: return "Complete the sentence"
        case .matching: return "Match related language"
        case .typing: return "Type the line"
        case .dialogue: return "Complete the dialogue"
        case .sequencing: return "Put it in order"
        case .comprehension: return "Read the evidence"
        case .speaking: return "Record and compare"
        case .grammarDiscovery: return "Notice the pattern"
        case .delayedRetrieval: return "Bring it back"
        }
    }

    var isActiveProduction: Bool {
        switch self {
        case .listenBuildSentence, .sentenceConstruction, .typing, .dialogue,
             .sequencing, .speaking, .delayedRetrieval:
            return true
        default:
            return false
        }
    }
}

enum CountyResourceKind: String, Codable {
    case audio
    case evidence
    case source
    case image
    case grammarPattern
}

struct CountyPackResource: Identifiable, Codable, Equatable {
    let id: String
    let kind: CountyResourceKind
    let value: String
    let status: String
}

struct CountyExerciseOption: Identifiable, Codable, Equatable {
    let id: String
    let text: String
    let isCorrect: Bool
    let rationale: String
}

struct CountyExercisePair: Identifiable, Codable, Equatable {
    let id: String
    let left: String
    let right: String
}

struct CountyExercise: Codable, Equatable {
    let family: CountyExerciseFamily
    let objective: String
    let prompt: String
    let answer: String
    let options: [CountyExerciseOption]
    let tokens: [String]
    let pairs: [CountyExercisePair]
    let sentenceTemplate: String?
    let translation: String?
    let audioText: String?
    let modelText: String?
    let feedback: String
    let hint: String
    let recovery: String
    let lexemeIDs: [String]
    let operatesOnSentence: Bool
    let recognitionMultipleChoice: Bool
}

struct CountyStoryPage: Identifiable, Codable, Equatable {
    let id: String
    let legacyBeatIndex: Int?
    let title: String
    let context: String
    let body: String
    let detail: String?
    let visibility: CountyPageVisibility
    let requirement: CountyPageRequirement
    let kind: CountyPageKind
    let estimatedSeconds: Int
    let introducedLexemeIDs: [String]
    let resourceIDs: [String]
    let exercise: CountyExercise?
    let presentation: CountyNarrativePresentation?
    let advanceLabel: String?
    let visualResourceID: String?
    let visualCaption: String?
    let displayItems: [CountyNarrativeDisplayItem]?
}

struct CountyStoryChapter: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let place: String
    let pages: [CountyStoryPage]
}

struct CountyPackCompletion: Codable, Equatable {
    let storyPageIDs: [String]
    let learningPageIDs: [String]
}

struct CountyLexemeLifecycle: Identifiable, Codable, Equatable {
    let id: String
    let introducedPageID: String
    let heardPageID: String
    let producedPageID: String
    let reusedPageID: String
}

struct CountyReviewGate: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let status: String
}

struct CountyPackPresentation: Codable, Equatable {
    let countyGa: String
    let countyEn: String
    let province: String
    let era: String
    let anchor: String
    let question: String
    let opening: String
    let evidenceLimit: String
    let sourceTitle: String
    let sourceDetail: String
    let artifactTitle: String
    let artifactPrompt: String
    let tegLevel: String
    let tegCanDo: String
}

struct CountyStoryPack: Identifiable, Codable, Equatable {
    let id: String
    let revision: Int
    let scope: CountyPackScope
    let title: String
    let presentation: CountyPackPresentation
    let targetWords: [AtlasWord]
    let resources: [CountyPackResource]
    let reviewGates: [CountyReviewGate]
    let chapters: [CountyStoryChapter]
    let completion: CountyPackCompletion
    let lifecycle: [CountyLexemeLifecycle]
    let enforceLearningQuality: Bool

    var pages: [CountyStoryPage] { chapters.flatMap(\.pages) }

    func pages(for mode: CountyStoryMode) -> [CountyStoryPage] {
        pages.filter { $0.visibility.includes(mode) }
    }

    func page(id: String) -> CountyStoryPage? {
        pages.first { $0.id == id }
    }

    func chapter(containing pageID: String) -> CountyStoryChapter? {
        chapters.first { chapter in chapter.pages.contains { $0.id == pageID } }
    }

    func requiredPageIDs(for mode: CountyStoryMode) -> [String] {
        mode == .story ? completion.storyPageIDs : completion.learningPageIDs
    }
}

struct CountyStoryPackEnvelope: Codable, Equatable {
    let schemaVersion: Int
    let pack: CountyStoryPack
}

struct CountyPackReport: Equatable {
    let storyMinutes: Double
    let learningMinutes: Double
    let exerciseDistribution: [CountyExerciseFamily: Int]
    let lifecycleComplete: Int
    let lifecycleTotal: Int
    let requiredAudioCount: Int
    let missingAudioIDs: [String]
    let evidenceReferenceCount: Int
    let openReviewGates: [String]
}

enum CountyStoryPackError: LocalizedError, Equatable {
    case unsupportedSchema
    case invalidPackID
    case invalidWordContract
    case duplicateID(String)
    case emptyModeChapter(String)
    case invalidCompletionPage(String)
    case exerciseOnStoryPath(String)
    case missingExercise(String)
    case prematureLexeme(String)
    case missingResource(String)
    case missingRequiredAudio(String)
    case duplicateAnswer(String)
    case invalidLifecycle(String)
    case legacyBeatStructure
    case exerciseDistribution(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedSchema: return "This county pack uses an unsupported schema."
        case .invalidPackID: return "The county pack needs a stable dotted id and a positive revision."
        case .invalidWordContract: return "A county pack must declare exactly twenty unique Irish headwords."
        case .duplicateID(let id): return "The county pack repeats the id \(id)."
        case .emptyModeChapter(let id): return "Chapter \(id) is empty in one of its declared modes."
        case .invalidCompletionPage(let id): return "Completion refers to an invisible or missing page: \(id)."
        case .exerciseOnStoryPath(let id): return "Story mode contains a language exercise: \(id)."
        case .missingExercise(let id): return "Exercise page \(id) has no exercise payload."
        case .prematureLexeme(let id): return "Exercise \(id) uses language before the story introduces it."
        case .missingResource(let id): return "A page refers to an unknown resource: \(id)."
        case .missingRequiredAudio(let id): return "Exercise \(id) has no bundled-audio reference."
        case .duplicateAnswer(let id): return "Exercise \(id) repeats its correct answer among the distractors."
        case .invalidLifecycle(let id): return "Lexeme lifecycle \(id) is missing or out of order."
        case .legacyBeatStructure: return "The pack still depends on a fixed three-page chapter structure."
        case .exerciseDistribution(let issue): return issue
        }
    }
}

enum CountyStoryPackValidator {
    static let schemaVersion = 2

    @discardableResult
    static func validate(_ envelope: CountyStoryPackEnvelope) throws -> CountyPackReport {
        guard envelope.schemaVersion == schemaVersion else {
            throw CountyStoryPackError.unsupportedSchema
        }
        let pack = envelope.pack
        guard pack.revision > 0, pack.id.contains(".") else {
            throw CountyStoryPackError.invalidPackID
        }
        guard pack.targetWords.count == 20,
              Set(pack.targetWords.map(\.ga)).count == 20 else {
            throw CountyStoryPackError.invalidWordContract
        }

        var ids = Set<String>()
        for item in pack.chapters.map(\.id) + pack.pages.map(\.id) + pack.resources.map(\.id) {
            guard ids.insert(item).inserted else { throw CountyStoryPackError.duplicateID(item) }
        }

        for chapter in pack.chapters {
            for mode in CountyStoryMode.allCases where chapter.pages.contains(where: { $0.visibility.includes(mode) }) == false {
                throw CountyStoryPackError.emptyModeChapter(chapter.id)
            }
        }

        let pageIDs = Set(pack.pages.map(\.id))
        for mode in CountyStoryMode.allCases {
            let visible = Set(pack.pages(for: mode).map(\.id))
            for id in pack.requiredPageIDs(for: mode) where !pageIDs.contains(id) || !visible.contains(id) {
                throw CountyStoryPackError.invalidCompletionPage(id)
            }
        }

        if pack.pages(for: .story).contains(where: { $0.kind == .exercise }) {
            let id = pack.pages(for: .story).first(where: { $0.kind == .exercise })!.id
            throw CountyStoryPackError.exerciseOnStoryPath(id)
        }

        let resources = Dictionary(uniqueKeysWithValues: pack.resources.map { ($0.id, $0) })
        for page in pack.pages {
            for resourceID in page.resourceIDs where resources[resourceID] == nil {
                throw CountyStoryPackError.missingResource(resourceID)
            }
            if let visualResourceID = page.visualResourceID {
                guard page.resourceIDs.contains(visualResourceID),
                      resources[visualResourceID]?.kind == .image else {
                    throw CountyStoryPackError.missingResource(visualResourceID)
                }
            }
        }
        var introduced = Set<String>()
        for page in pack.pages(for: .learning) {
            if page.kind == .exercise {
                guard let exercise = page.exercise else { throw CountyStoryPackError.missingExercise(page.id) }
                guard Set(exercise.lexemeIDs).isSubset(of: introduced) else {
                    throw CountyStoryPackError.prematureLexeme(page.id)
                }
                let correctOptions = exercise.options.filter(\.isCorrect)
                if !exercise.options.isEmpty,
                   (correctOptions.count != 1 || Set(exercise.options.map { $0.text.lowercased() }).count != exercise.options.count) {
                    throw CountyStoryPackError.duplicateAnswer(page.id)
                }
                if [.listenIdentify, .listenBuildSentence, .speaking].contains(exercise.family) {
                    let audioResources = page.resourceIDs.compactMap { resources[$0] }.filter { $0.kind == .audio }
                    guard exercise.audioText != nil, !audioResources.isEmpty else {
                        throw CountyStoryPackError.missingRequiredAudio(page.id)
                    }
                }
            }
            introduced.formUnion(page.introducedLexemeIDs)
        }

        let orderedIDs = pack.pages.map(\.id)
        for lifecycle in pack.lifecycle {
            let positions = [
                lifecycle.introducedPageID,
                lifecycle.heardPageID,
                lifecycle.producedPageID,
                lifecycle.reusedPageID,
            ].compactMap { orderedIDs.firstIndex(of: $0) }
            guard positions.count == 4,
                  positions[0] <= positions[1],
                  positions[1] < positions[2],
                  positions[2] < positions[3] else {
                throw CountyStoryPackError.invalidLifecycle(lifecycle.id)
            }
        }

        if pack.scope != .editorialPreview,
           pack.chapters.count > 1,
           pack.chapters.allSatisfy({ $0.pages.count == 3 }) {
            throw CountyStoryPackError.legacyBeatStructure
        }

        let exercises = pack.pages.compactMap(\.exercise)
        if pack.enforceLearningQuality, !exercises.isEmpty {
            let distribution = Dictionary(grouping: exercises, by: \.family).mapValues(\.count)
            guard distribution.count >= 7 else {
                throw CountyStoryPackError.exerciseDistribution("A learning path needs at least seven mechanic families.")
            }
            let total = Double(exercises.count)
            guard Double(distribution.values.max() ?? 0) / total <= 0.25 else {
                throw CountyStoryPackError.exerciseDistribution("One exercise family exceeds 25 percent of the path.")
            }
            guard Double(exercises.filter(\.operatesOnSentence).count) / total >= 0.5 else {
                throw CountyStoryPackError.exerciseDistribution("At least half of exercises must use phrases or sentences.")
            }
            guard Double(exercises.filter { $0.family.isActiveProduction }.count) / total >= 0.4 else {
                throw CountyStoryPackError.exerciseDistribution("At least 40 percent of exercises must require active production.")
            }
            guard Double(exercises.filter(\.recognitionMultipleChoice).count) / total <= 0.25 else {
                throw CountyStoryPackError.exerciseDistribution("Recognition multiple choice exceeds 25 percent of the path.")
            }
            let singleWordListening = exercises.filter { $0.family == .listenIdentify && !$0.operatesOnSentence }.count
            guard Double(singleWordListening) / total <= 0.1 else {
                throw CountyStoryPackError.exerciseDistribution("Single-word listen-and-pick exceeds 10 percent of the path.")
            }
        }

        let distribution = Dictionary(grouping: exercises, by: \.family).mapValues(\.count)
        let referencedResources = pack.pages.flatMap(\.resourceIDs).compactMap { resources[$0] }
        let audio = referencedResources.filter { $0.kind == .audio }
        return CountyPackReport(
            storyMinutes: Double(pack.pages(for: .story).reduce(0) { $0 + $1.estimatedSeconds }) / 60,
            learningMinutes: Double(pack.pages(for: .learning).reduce(0) { $0 + $1.estimatedSeconds }) / 60,
            exerciseDistribution: distribution,
            lifecycleComplete: pack.lifecycle.count,
            lifecycleTotal: pack.lifecycle.count,
            requiredAudioCount: audio.count,
            missingAudioIDs: audio.filter { $0.status != "bundled" }.map(\.id),
            evidenceReferenceCount: referencedResources.filter { $0.kind == .evidence || $0.kind == .source }.count,
            openReviewGates: pack.reviewGates.filter { $0.status != "complete" }.map(\.title)
        )
    }
}

enum CountyStoryPackCatalog {
    private static let bundledNames = [
        "mayo.grainne-1593",
        "offaly.cross-of-the-scriptures",
        "dublin.sihtric-penny",
        "meath.trim-de-lacy",
    ]

    private static let bundledEnvelopes: [CountyStoryPackEnvelope] = bundledNames.compactMap(loadEnvelope(named:))

    /// Installed version-two packs may replace a bundled pack only when they
    /// validate and carry an equal or newer revision. Ordering remains the
    /// authored road order from `bundledNames`.
    static let envelopes: [CountyStoryPackEnvelope] = {
        let installed = CountyStoryPackStore.installedEnvelopes()
        return bundledEnvelopes.map { bundled in
            guard let candidate = installed[bundled.pack.id],
                  candidate.pack.revision >= bundled.pack.revision else {
                return bundled
            }
            return candidate
        }
    }()
    static let packs: [CountyStoryPack] = envelopes.compactMap { envelope in
        guard (try? CountyStoryPackValidator.validate(envelope)) != nil else { return nil }
        return envelope.pack
    }

    static func pack(id: String) -> CountyStoryPack? {
        packs.first { $0.id == id }
    }

    private static func loadEnvelope(named name: String) -> CountyStoryPackEnvelope? {
        let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "CountyStories")
            ?? Bundle.main.url(forResource: name, withExtension: "json")
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(CountyStoryPackEnvelope.self, from: data)
    }
}

enum CountyStoryPackStore {
    @discardableResult
    static func install(data: Data) throws -> URL {
        let envelope = try JSONDecoder().decode(CountyStoryPackEnvelope.self, from: data)
        try CountyStoryPackValidator.validate(envelope)
        let folder = try packsFolder()
        let destination = folder
            .appendingPathComponent(safeFilename(for: envelope.pack.id))
            .appendingPathExtension("json")
        try data.write(to: destination, options: [.atomic])
        return destination
    }

    static func validate(data: Data) throws -> CountyPackReport {
        let envelope = try JSONDecoder().decode(CountyStoryPackEnvelope.self, from: data)
        return try CountyStoryPackValidator.validate(envelope)
    }

    static func installedEnvelopes() -> [String: CountyStoryPackEnvelope] {
        guard let folder = try? packsFolder(),
              let urls = try? FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
              ) else { return [:] }

        var result: [String: CountyStoryPackEnvelope] = [:]
        for url in urls where url.pathExtension.lowercased() == "json" {
            guard let data = try? Data(contentsOf: url),
                  let envelope = try? JSONDecoder().decode(CountyStoryPackEnvelope.self, from: data),
                  (try? CountyStoryPackValidator.validate(envelope)) != nil else { continue }
            if let current = result[envelope.pack.id],
               current.pack.revision > envelope.pack.revision {
                continue
            }
            result[envelope.pack.id] = envelope
        }
        return result
    }

    private static func packsFolder() throws -> URL {
        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = root.appendingPathComponent("CountyPacks", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private static func safeFilename(for packID: String) -> String {
        packID.map { character in
            character.isLetter || character.isNumber || character == "." || character == "-"
                ? String(character)
                : "-"
        }.joined()
    }
}
