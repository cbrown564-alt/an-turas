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

/// The D27 activity layers. Response families satisfy the shared response contract;
/// containers host or end activities and declare their own.
///
/// Families and containers not yet implemented — picture or map selection, listen and
/// type, radio, contextual mistake review, **Words you carry** practice, and completion —
/// arrive with their surfaces in the staged order in `STORY-LEARNING-REBUILD-PLAN.md`.
/// They are deliberately absent here rather than declared without a surface.
enum CountyExerciseFamily: String, Codable, CaseIterable {
    case listenChoose
    case sentenceConstruction
    case fillGap
    case matching
    case freeTyping
    case readRespond
    case recordCompare
    case grammarDiscovery
    case conversation
    case completion
    case contextualReview

    /// D27: containers host or end activities rather than being a way to answer, so they
    /// do not satisfy the response contract and do not count toward family diversity.
    var isContainer: Bool {
        switch self {
        case .conversation, .completion, .contextualReview: return true
        default: return false
        }
    }

    var title: String {
        switch self {
        case .listenChoose: return "Listen and identify"
        case .sentenceConstruction: return "Build a sentence"
        case .fillGap: return "Complete the sentence"
        case .matching: return "Match related language"
        case .freeTyping: return "Type the line"
        case .readRespond: return "Read the evidence"
        case .recordCompare: return "Record and compare"
        case .grammarDiscovery: return "Notice the pattern"
        case .conversation: return "Take your turn"
        case .completion: return "See what you can do"
        case .contextualReview: return "Quick review"
        }
    }

    /// D27: single-choice families check on selection and carry Continue as the primary
    /// action. Multi-part responses stay editable until an explicit Check.
    var checksOnSelection: Bool {
        switch self {
        case .listenChoose, .readRespond, .grammarDiscovery:
            return true
        case .fillGap:
            // Only the choice-backed variant; a typed gap keeps its Check.
            return true
        case .sentenceConstruction, .matching, .freeTyping, .recordCompare, .conversation,
             .completion, .contextualReview:
            return false
        }
    }

    var isActiveProduction: Bool {
        switch self {
        case .sentenceConstruction, .freeTyping, .recordCompare, .grammarDiscovery,
             .conversation, .contextualReview:
            return true
        case .listenChoose, .fillGap, .matching, .readRespond, .completion:
            return false
        }
    }

    /// Deterministic migration from the pre-D27 schema-2 vocabulary. `sequencing` and
    /// `delayedRetrieval` were absorbed as authored uses, `listenBuildSentence` folds into
    /// audio-prompted construction, and `dialogue` merges into `conversation`.
    static func migratingLegacyRawValue(_ raw: String) -> CountyExerciseFamily? {
        switch raw {
        case "listenIdentify": return .listenChoose
        case "listenBuildSentence", "sequencing": return .sentenceConstruction
        case "typing", "delayedRetrieval": return .freeTyping
        case "dialogue": return .conversation
        case "comprehension": return .readRespond
        case "speaking": return .recordCompare
        default: return CountyExerciseFamily(rawValue: raw)
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard let migrated = Self.migratingLegacyRawValue(raw) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath,
                      debugDescription: "unknown exercise family \(raw)")
            )
        }
        self = migrated
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum CountyResourceKind: String, Codable {
    case audio
    case evidence
    case source
    case image
    case video
    case grammarPattern
}

struct CountyPackResource: Identifiable, Codable, Equatable {
    let id: String
    let kind: CountyResourceKind
    let value: String
    let status: String
    let fallbackResourceID: String?
}

enum CountyVisual: Equatable {
    case image(name: String)
    case video(name: String, fallbackImageName: String)
}

struct CountyExerciseOption: Identifiable, Codable, Equatable {
    let id: String
    let text: String
    let isCorrect: Bool
    let rationale: String
    /// The named misconception this distractor tests, when the exercise's
    /// learning contract declares one. Absent on correct options and on flat
    /// pre-contract packs.
    let misconceptionID: String?
}

struct CountyExercisePair: Identifiable, Codable, Equatable {
    let id: String
    let left: String
    let right: String
}

// MARK: - D27 container payloads

/// One learner reply inside a conversation node. A fitting reply advances the
/// graph (`next`) or ends the conversation (`next == nil`); a mismatched reply
/// carries its diagnostic on that turn and never advances.
struct CountyConversationReply: Identifiable, Codable, Equatable {
    let id: String
    let text: String
    let gloss: String?
    let isFitting: Bool
    let diagnostic: String?
    let next: String?
    let audioText: String?
}

struct CountyConversationNode: Identifiable, Codable, Equatable {
    let id: String
    let partner: String
    let partnerGloss: String?
    let audioText: String?
    let replies: [CountyConversationReply]
}

/// C1: a finite, authored conversation — no runtime-generated Irish. `setting`
/// is authored metadata (`present-day` or `historical-bounded`), not a
/// structural difference (D27).
struct CountyConversationGraph: Codable, Equatable {
    let setting: String
    let start: String
    let nodes: [CountyConversationNode]

    func node(id: String) -> CountyConversationNode? {
        nodes.first { $0.id == id }
    }
}

/// One durable record of a completed learner turn, so an interrupted
/// conversation restores its transcript and current node exactly (C1 resume).
struct CountyConversationTurnRecord: Codable, Equatable {
    let nodeID: String
    let replyID: String
}

struct CountyConversationState: Codable, Equatable {
    var turns: [CountyConversationTurnRecord]
    var currentNodeID: String
}

enum CountyConversationStep: Equatable {
    case advanced(CountyConversationState)
    case misfit(String)
    case completed(CountyConversationState)
}

/// Pure turn-graph walk — kept free of SwiftUI so branch, resume and
/// completion are unit-testable without a simulator.
enum CountyConversationEngine {
    static func initialState(for graph: CountyConversationGraph) -> CountyConversationState {
        CountyConversationState(turns: [], currentNodeID: graph.start)
    }

    static func choose(
        replyID: String,
        in state: CountyConversationState,
        graph: CountyConversationGraph
    ) -> CountyConversationStep {
        guard let node = graph.node(id: state.currentNodeID),
              let reply = node.replies.first(where: { $0.id == replyID }) else {
            return .misfit("That reply is not on this turn.")
        }
        guard reply.isFitting else {
            return .misfit(reply.diagnostic ?? "That does not fit this turn.")
        }
        var next = state
        next.turns.append(CountyConversationTurnRecord(nodeID: node.id, replyID: reply.id))
        guard let nextNodeID = reply.next else {
            return .completed(next)
        }
        next.currentNodeID = nextNodeID
        return .advanced(next)
    }

    /// The partner line the learner faces at the resumed or advanced node.
    static func currentNode(
        in state: CountyConversationState,
        graph: CountyConversationGraph
    ) -> CountyConversationNode? {
        graph.node(id: state.currentNodeID)
    }
}

/// C5: one capability the completion container can honestly state.
struct CountyCompletionCapability: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
}

/// C3: one authored re-entry into an earlier task. The embedded exercise keeps
/// the original sound, sentence and response method; `pageID` ties the target
/// to the struggle that selects it.
struct CountyReviewCandidate: Identifiable, Codable, Equatable {
    let id: String
    let pageID: String
    let label: String
    let exercise: CountyExercise
}

/// Deterministic struggle targeting for contextual mistake review: the
/// earliest struggled page with an authored candidate wins; with no recorded
/// struggle the first candidate is the authored default.
enum CountyContextualReviewTargeting {
    static func candidate(
        from candidates: [CountyReviewCandidate],
        struggledPageIDs: [String]
    ) -> CountyReviewCandidate? {
        for pageID in struggledPageIDs {
            if let match = candidates.first(where: { $0.pageID == pageID }) {
                return match
            }
        }
        return candidates.first
    }
}

struct CountyExercise: Codable, Equatable {
    let family: CountyExerciseFamily
    /// D27: a pedagogical purpose achieved by configuring an existing family rather than
    /// by introducing a new one — `ordering`, `audioPrompted`, `delayedRecall`. It counts
    /// separately from its parent family in the monotony cap, because it is not the same
    /// experience for the learner.
    let authoredUse: String?
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
    /// C1 turn graph. Absent on legacy thin multiple-choice conversations.
    let conversation: CountyConversationGraph?
    /// C5 capabilities the completion container states.
    let capabilities: [CountyCompletionCapability]?
    /// C3 authored re-entry targets, selected by the run's struggle record.
    let reviewCandidates: [CountyReviewCandidate]?
    /// The authored learning contract. Absent on flat pre-contract packs;
    /// `resolvedContract` adapts one from the flat fields instead.
    let learningContract: CountyLearningContract?
}

// MARK: - Authored learning contract (D27, rebuild plan step 5)

/// The declared completion-evidence kinds from the rebuild plan's authored
/// learning contract. Raw values are the schema vocabulary: payload, engine,
/// and validators share this one list.
enum CountyCompletionEvidence: String, CaseIterable, Codable, Equatable {
    case correctSelection
    case correctConstruction
    case correctedConstruction
    case reconstructedResponse
    case validDialogueTurn
    case orderedSequence
    case completedRecordCompare
}

/// Whether a target is being recognised, recalled, produced, interpreted, or
/// spoken for comparison (rebuild plan, "Target language").
enum CountyTargetCapability: String, Codable, CaseIterable, Equatable {
    case recognised
    case recalled
    case produced
    case interpreted
    case spokenForComparison
}

struct CountyContractTarget: Identifiable, Codable, Equatable {
    let id: String
    let capability: CountyTargetCapability
}

/// One plausible confusion the exercise tests, with its plain-language
/// diagnostic. Choice distractors point here through `misconceptionID`;
/// constructed responses name their diagnostic cases and keep a fallback for
/// an unclassified response.
struct CountyMisconception: Identifiable, Codable, Equatable {
    let id: String
    let rationale: String
    let feedback: String
}

/// A supported version of the same objective, including the response the
/// learner must still make after support.
struct CountyRecoveryContract: Codable, Equatable {
    let guidance: String
    let requiredResponse: String
    /// Declared only when recovery narrows the target set; absent means the
    /// recovery works the contract's targets unchanged. A present but
    /// different set fails `targetChangingRecovery`.
    let targetIDs: [String]?

    init(guidance: String, requiredResponse: String, targetIDs: [String]? = nil) {
        self.guidance = guidance
        self.requiredResponse = requiredResponse
        self.targetIDs = targetIDs
    }
}

/// Why an exercise's response data exists and what completion means (rebuild
/// plan, "Authored learning contract"). The runtime reads the declared
/// contract only — it never infers pedagogy from family or display copy (D27).
/// Packs authored before the contract carry the flat fields instead; the
/// deterministic adapter below derives the same shape, so authored and adapted
/// contracts share one runtime path.
struct CountyLearningContract: Codable, Equatable {
    let objective: String
    let targets: [CountyContractTarget]
    let misconceptions: [CountyMisconception]
    let successFeedback: String
    let hint: String
    let recovery: CountyRecoveryContract
    /// `nil` for containers whose completion states capabilities rather than
    /// target-language evidence.
    let completionEvidence: CountyCompletionEvidence?
}

extension CountyExerciseFamily {
    /// The capability the adapter assigns a target when no authored contract
    /// declares one.
    var adaptedTargetCapability: CountyTargetCapability {
        switch self {
        case .listenChoose, .fillGap, .matching, .completion:
            return .recognised
        case .readRespond, .grammarDiscovery:
            return .interpreted
        case .sentenceConstruction, .conversation:
            return .produced
        case .freeTyping, .contextualReview:
            return .recalled
        case .recordCompare:
            return .spokenForComparison
        }
    }

    /// The completion evidence the adapter declares from the family and its
    /// authored use — the mapping the shell inferred at render time before the
    /// contract landed. The completion container states capabilities, so it
    /// declares no target evidence.
    func adaptedCompletionEvidence(
        authoredUse: String?,
        reviewCandidate: CountyReviewCandidate?
    ) -> CountyCompletionEvidence? {
        switch self {
        case .listenChoose, .fillGap, .readRespond, .grammarDiscovery:
            return .correctSelection
        case .sentenceConstruction:
            return authoredUse == "ordering" ? .orderedSequence : .correctConstruction
        case .freeTyping:
            return .correctConstruction
        case .matching:
            return .reconstructedResponse
        case .conversation:
            return .validDialogueTurn
        case .recordCompare:
            return .completedRecordCompare
        case .contextualReview:
            return reviewCandidate?.exercise.family == .freeTyping ? .correctedConstruction : .correctSelection
        case .completion:
            return nil
        }
    }

    /// The completion-evidence kinds an authored contract may declare for this
    /// family — the adapter's mapping widened to the response methods the
    /// family actually offers (a typed gap constructs where a choice-backed
    /// gap selects; an ordering use sequences). The completion container
    /// states capabilities, so it supports no target evidence. Mirrors
    /// `FAMILY_COMPLETION_EVIDENCE` in tools/validate_county_pack.py.
    var compatibleCompletionEvidence: Set<CountyCompletionEvidence> {
        switch self {
        case .listenChoose, .readRespond, .grammarDiscovery:
            return [.correctSelection]
        case .fillGap:
            return [.correctSelection, .correctConstruction]
        case .sentenceConstruction:
            return [.correctConstruction, .orderedSequence]
        case .freeTyping:
            return [.correctConstruction]
        case .matching:
            return [.reconstructedResponse]
        case .conversation:
            return [.validDialogueTurn]
        case .recordCompare:
            return [.completedRecordCompare]
        case .contextualReview:
            return [.correctSelection, .correctedConstruction]
        case .completion:
            return []
        }
    }
}

extension CountyLearningContract {
    /// Deterministic adaptation of the pre-contract flat fields (rebuild plan
    /// step 5): the single feedback string becomes the fallback misconception
    /// diagnostic, lexeme ids become targets with a family-derived capability,
    /// and the family's declared evidence carries over. The same exercise
    /// always adapts to the same contract.
    static func adapting(
        exercise: CountyExercise,
        reviewCandidate: CountyReviewCandidate? = nil
    ) -> CountyLearningContract {
        CountyLearningContract(
            objective: exercise.objective,
            targets: exercise.lexemeIDs.map {
                CountyContractTarget(id: $0, capability: exercise.family.adaptedTargetCapability)
            },
            misconceptions: [
                CountyMisconception(
                    id: "fallback",
                    rationale: "A response the authored diagnostics do not name.",
                    feedback: exercise.feedback
                ),
            ],
            successFeedback: exercise.feedback,
            hint: exercise.hint,
            recovery: CountyRecoveryContract(
                guidance: exercise.recovery,
                requiredResponse: "Make the response again after the support."
            ),
            completionEvidence: exercise.family.adaptedCompletionEvidence(
                authoredUse: exercise.authoredUse,
                reviewCandidate: reviewCandidate
            )
        )
    }
}

extension CountyExercise {
    /// The authored contract when the payload declares one, otherwise the
    /// deterministic adaptation of the flat fields — one runtime path either
    /// way. A contextual review passes its resolved candidate so the adapted
    /// evidence follows the re-entered task.
    func resolvedContract(reviewCandidate: CountyReviewCandidate? = nil) -> CountyLearningContract {
        learningContract ?? CountyLearningContract.adapting(
            exercise: self,
            reviewCandidate: reviewCandidate
        )
    }
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

    func visual(for page: CountyStoryPage) -> CountyVisual? {
        guard let visualResourceID = page.visualResourceID,
              page.resourceIDs.contains(visualResourceID),
              let resource = resources.first(where: { $0.id == visualResourceID }) else {
            return nil
        }
        switch resource.kind {
        case .image:
            return .image(name: resource.value)
        case .video:
            guard let fallbackID = resource.fallbackResourceID,
                  let fallback = resources.first(where: {
                      $0.id == fallbackID && $0.kind == .image
                  }) else {
                return nil
            }
            return .video(name: resource.value, fallbackImageName: fallback.value)
        default:
            return nil
        }
    }

    var openReviewGateTitles: [String] {
        reviewGates.filter { $0.status != "complete" }.map(\.title)
    }

    /// Complete authoring can be reviewed in-app before it is allowed to award
    /// county completion. Release effects stay locked until every gate is closed.
    var isReleaseCleared: Bool {
        scope == .completeCounty && openReviewGateTitles.isEmpty
    }

    var isReviewDraft: Bool {
        scope == .completeCounty && !openReviewGateTitles.isEmpty
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
    /// Exercises carrying an authored learning contract versus contracts the
    /// deterministic adapter derives from the flat fields.
    let contractAuthoredCount: Int
    let contractAdaptedCount: Int
    /// Distractors mapped to a named misconception, over all distractors.
    let distractorsMapped: Int
    let distractorCount: Int
    /// The completion-evidence kinds the pack declares (authored) or derives
    /// (adapted), sorted by raw value.
    let completionEvidenceKinds: [CountyCompletionEvidence]
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
    case invalidMatchingBoard(String)
    case invalidConversationGraph(String)
    case invalidCompletionPayload(String)
    case invalidReviewPayload(String)
    case legacyBeatStructure
    case exerciseDistribution(String)
    case missingMisconceptionMapping(String)
    case missingDiagnosticCases(String)
    case answerRevealingHint(String)
    case targetChangingRecovery(String)
    case unsupportedCompletionEvidence(String)
    case offTargetMemoryCredit(String)
    case untraceableReviewTarget(String)
    case unsupportedCapabilityClaim(String)

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
        case .invalidMatchingBoard(let id): return "Matching exercise \(id) must board two to four pairs (F5)."
        case .invalidConversationGraph(let id): return "Conversation exercise \(id) fails the C1 turn-graph contract."
        case .invalidCompletionPayload(let id): return "Completion page \(id) states no capabilities (C5)."
        case .invalidReviewPayload(let id): return "Contextual review \(id) has no authored re-entry candidates (C3)."
        case .legacyBeatStructure: return "The pack still depends on a fixed three-page chapter structure."
        case .exerciseDistribution(let issue): return issue
        case .missingMisconceptionMapping(let id): return "Exercise \(id) has a distractor with no declared misconception mapping."
        case .missingDiagnosticCases(let id): return "Constructed-response exercise \(id) declares no diagnostic cases."
        case .answerRevealingHint(let id): return "Exercise \(id) has a hint that reveals the complete accepted answer."
        case .targetChangingRecovery(let id): return "Exercise \(id) has a recovery that changes the declared target set."
        case .unsupportedCompletionEvidence(let id): return "Exercise \(id) declares completion evidence its response method cannot produce."
        case .offTargetMemoryCredit(let id): return "Exercise \(id) credits memory to a target the exercise does not target."
        case .untraceableReviewTarget(let id): return "Contextual review \(id) cannot trace a candidate back to its origin exercise (C3)."
        case .unsupportedCapabilityClaim(let id): return "Completion page \(id) claims a capability no completed-target evidence supports (C5)."
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
                      let visualResource = resources[visualResourceID],
                      visualResource.kind == .image || visualResource.kind == .video else {
                    throw CountyStoryPackError.missingResource(visualResourceID)
                }
                if visualResource.kind == .video {
                    guard let fallbackID = visualResource.fallbackResourceID,
                          let fallback = resources[fallbackID],
                          fallback.kind == .image else {
                        throw CountyStoryPackError.missingResource(
                            visualResource.fallbackResourceID ?? visualResourceID
                        )
                    }
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
                let audioFamilies: Set<CountyExerciseFamily> = [.listenChoose, .recordCompare]
                if audioFamilies.contains(exercise.family) {
                    let audioResources = page.resourceIDs.compactMap { resources[$0] }.filter { $0.kind == .audio }
                    guard exercise.audioText != nil, !audioResources.isEmpty else {
                        throw CountyStoryPackError.missingRequiredAudio(page.id)
                    }
                }
                if exercise.family == .matching, !(2...4).contains(exercise.pairs.count) {
                    throw CountyStoryPackError.invalidMatchingBoard(page.id)
                }
                if exercise.family == .conversation, let graph = exercise.conversation {
                    try validateConversationGraph(graph, pageID: page.id)
                }
                if exercise.family == .completion,
                   exercise.capabilities?.isEmpty != false {
                    throw CountyStoryPackError.invalidCompletionPayload(page.id)
                }
                if exercise.family == .contextualReview,
                   exercise.reviewCandidates?.isEmpty != false {
                    throw CountyStoryPackError.invalidReviewPayload(page.id)
                }
                // Authored learning-contract rules (rebuild plan, "Automated
                // enforcement"). Flat pre-contract packs never enter here — the
                // deterministic adapter covers them until the production-slice
                // migration makes contracts mandatory.
                if let contract = exercise.learningContract {
                    try validateLearningContract(contract, exercise: exercise, pageID: page.id)
                }
                // C3: a review candidate must trace its target back to the
                // origin page's exercise.
                for candidate in exercise.reviewCandidates ?? [] {
                    guard let originLexemes = pack.page(id: candidate.pageID)?.exercise?.lexemeIDs,
                          Set(candidate.exercise.lexemeIDs) == Set(originLexemes) else {
                        throw CountyStoryPackError.untraceableReviewTarget(page.id)
                    }
                }
                // C5: a stated capability needs completed-target evidence behind
                // it. Conservative heuristic: a claim passes when any other
                // exercise shares a declared target and declares any completion
                // evidence — capability-to-evidence mapping is fuzzy, so when in
                // doubt the claim stands.
                if exercise.family == .completion, exercise.capabilities?.isEmpty == false {
                    let claimedTargets = Set(exercise.resolvedContract().targets.map(\.id))
                    if !claimedTargets.isEmpty {
                        let supported = pack.pages.contains { otherPage in
                            guard otherPage.id != page.id, let other = otherPage.exercise else { return false }
                            let contract = other.resolvedContract()
                            return contract.completionEvidence != nil
                                && !Set(contract.targets.map(\.id)).isDisjoint(with: claimedTargets)
                        }
                        guard supported else {
                            throw CountyStoryPackError.unsupportedCapabilityClaim(page.id)
                        }
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
            // D27: percentages run over every activity page, containers included, because
            // a conversation genuinely carries production load. Diversity counts response
            // families only, so a pack cannot satisfy it by stacking containers.
            let familyDiversity = distribution.keys.filter { !$0.isContainer }.count
            guard familyDiversity >= 7 else {
                throw CountyStoryPackError.exerciseDistribution("A learning path needs at least seven response families.")
            }
            let total = Double(exercises.count)
            // The monotony cap measures what the learner actually does, so it counts a
            // declared authored use separately from its parent family (D27).
            let byUse = Dictionary(grouping: exercises, by: { $0.authoredUse ?? $0.family.rawValue })
                .mapValues(\.count)
            guard Double(byUse.values.max() ?? 0) / total <= 0.25 else {
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
            let singleWordListening = exercises.filter { $0.family == .listenChoose && !$0.operatesOnSentence }.count
            guard Double(singleWordListening) / total <= 0.1 else {
                throw CountyStoryPackError.exerciseDistribution("Single-word listen-and-pick exceeds 10 percent of the path.")
            }
        }

        let distribution = Dictionary(grouping: exercises, by: \.family).mapValues(\.count)
        let referencedResources = pack.pages.flatMap(\.resourceIDs).compactMap { resources[$0] }
        let audio = referencedResources.filter { $0.kind == .audio }
        let distractors = exercises.flatMap { $0.options.filter { !$0.isCorrect } }
        let evidenceKinds = Set(exercises.compactMap { $0.resolvedContract().completionEvidence })
            .sorted { $0.rawValue < $1.rawValue }
        return CountyPackReport(
            storyMinutes: Double(pack.pages(for: .story).reduce(0) { $0 + $1.estimatedSeconds }) / 60,
            learningMinutes: Double(pack.pages(for: .learning).reduce(0) { $0 + $1.estimatedSeconds }) / 60,
            exerciseDistribution: distribution,
            lifecycleComplete: pack.lifecycle.count,
            lifecycleTotal: pack.lifecycle.count,
            requiredAudioCount: audio.count,
            missingAudioIDs: audio.filter { $0.status != "bundled" }.map(\.id),
            evidenceReferenceCount: referencedResources.filter { $0.kind == .evidence || $0.kind == .source }.count,
            openReviewGates: pack.reviewGates.filter { $0.status != "complete" }.map(\.title),
            contractAuthoredCount: exercises.filter { $0.learningContract != nil }.count,
            contractAdaptedCount: exercises.filter { $0.learningContract == nil }.count,
            distractorsMapped: distractors.filter { $0.misconceptionID != nil }.count,
            distractorCount: distractors.count,
            completionEvidenceKinds: evidenceKinds
        )
    }

    /// Authored learning-contract rules (rebuild plan, "Automated
    /// enforcement"): every distractor maps to a declared misconception, a
    /// constructed response names diagnostic cases, the hint never reveals the
    /// whole accepted answer, recovery keeps the declared targets, the declared
    /// evidence is one the family's response method can produce, and memory
    /// credit names a target the exercise targets. Mirrors
    /// `_validate_learning_contract` in tools/validate_county_pack.py.
    static func validateLearningContract(
        _ contract: CountyLearningContract,
        exercise: CountyExercise,
        pageID: String
    ) throws {
        let declared = Set(contract.misconceptions.map(\.id))
        for option in exercise.options where !option.isCorrect {
            guard let misconceptionID = option.misconceptionID,
                  declared.contains(misconceptionID) else {
                throw CountyStoryPackError.missingMisconceptionMapping(pageID)
            }
        }
        let isConstructedResponse = exercise.family == .sentenceConstruction
            || exercise.family == .freeTyping
            || (exercise.family == .fillGap && exercise.options.isEmpty)
        if isConstructedResponse, contract.misconceptions.isEmpty {
            throw CountyStoryPackError.missingDiagnosticCases(pageID)
        }
        let answer = foldingFadas(exercise.answer)
        let hint = foldingFadas(contract.hint)
        if !answer.isEmpty, !hint.isEmpty, hint == answer || hint.contains(answer) {
            throw CountyStoryPackError.answerRevealingHint(pageID)
        }
        if let recoveryTargets = contract.recovery.targetIDs,
           Set(recoveryTargets) != Set(contract.targets.map(\.id)) {
            throw CountyStoryPackError.targetChangingRecovery(pageID)
        }
        if let evidence = contract.completionEvidence,
           !exercise.family.compatibleCompletionEvidence.contains(evidence) {
            throw CountyStoryPackError.unsupportedCompletionEvidence(pageID)
        }
        let lexemes = Set(exercise.lexemeIDs)
        if contract.targets.contains(where: { !lexemes.contains($0.id) }) {
            throw CountyStoryPackError.offTargetMemoryCredit(pageID)
        }
    }

    /// Case-insensitive, fada-folded comparison form — the same convention as
    /// `_FADA` in tools/validate_county_pack.py.
    static func foldingFadas(_ text: String) -> String {
        String(text.lowercased().map { character in
            switch character {
            case "á": return "a"
            case "é": return "e"
            case "í": return "i"
            case "ó": return "o"
            case "ú": return "u"
            default: return character
            }
        })
    }

    /// C1 contract: an authored conversation is a finite turn graph with a
    /// declared setting, a resolvable start and next references, at least two
    /// nodes, one genuine branch (a node with two fitting replies), and at
    /// least one terminal fitting reply — never a bare multiple-choice list.
    static func validateConversationGraph(
        _ graph: CountyConversationGraph,
        pageID: String
    ) throws {
        let nodeIDs = Set(graph.nodes.map(\.id))
        let replies = graph.nodes.flatMap(\.replies)
        let valid = !graph.setting.isEmpty
            && graph.nodes.count >= 2
            && nodeIDs.contains(graph.start)
            && graph.nodes.allSatisfy { !$0.replies.isEmpty }
            && replies.allSatisfy { $0.next == nil || nodeIDs.contains($0.next!) }
            && replies.contains { $0.isFitting && $0.next == nil }
            && graph.nodes.contains { $0.replies.filter(\.isFitting).count >= 2 }
        guard valid else {
            throw CountyStoryPackError.invalidConversationGraph(pageID)
        }
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

/// D29 freeze: the representative Clew Bay Learning run. This fixture is
/// decoded straight from the bundle and is never installed, promoted, or run
/// through the production twenty-word county gate — it proves the shared shell
/// on nine frozen steps without mutating production Mayo content.
enum CountyFreezeRunFixture {
    static let packID = "mayo.clew-bay-freeze"

    /// The nine frozen steps in their fixed order (D29).
    static let stepPageIDs = [
        "mayo.clew-bay.listen-farraige",
        "mayo.clew-bay.match-coast",
        "mayo.clew-bay.build-origin",
        "mayo.clew-bay.type-origin",
        "mayo.clew-bay.conversation-origin",
        "mayo.clew-bay.speak-origin",
        "mayo.clew-bay.comprehend-coast",
        "mayo.clew-bay.completion",
        "mayo.clew-bay.review-struggle",
    ]

    static func pack() -> CountyStoryPack? {
        CountyFixturePackLoader.pack(id: packID)
    }
}

/// D30 phrase-family B proof: hear one *farraige* member, build another.
/// Sibling fixture — does not mutate the D29 Clew Bay freeze or production Mayo.
enum CountyFarraigeFamilyBFixture {
    static let packID = "mayo.farraige-family-b"

    static let stepPageIDs = [
        "mayo.farraige-family.shoreline",
        "mayo.farraige-family.build-sea-here",
    ]

    static func pack() -> CountyStoryPack? {
        CountyFixturePackLoader.pack(id: packID)
    }
}

enum CountyFixturePackLoader {
    static func pack(id: String) -> CountyStoryPack? {
        let url = Bundle.main.url(
            forResource: id,
            withExtension: "json",
            subdirectory: "Fixtures"
        ) ?? Bundle.main.url(forResource: id, withExtension: "json")
        guard let url,
              let data = try? Data(contentsOf: url),
              let envelope = try? JSONDecoder().decode(CountyStoryPackEnvelope.self, from: data) else {
            return nil
        }
        return envelope.pack
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
