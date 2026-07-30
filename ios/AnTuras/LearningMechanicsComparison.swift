import SwiftUI
import UIKit

// MARK: - Comparison definition

enum LearningPrototypeMechanicDimension: String, CaseIterable, Hashable {
    case recallDemand
    case supportTiming
    case responseMethod
    case misconceptionDiagnosis
    case recoveryShape
    case storyMotivation
}

enum LearningPrototypeDirection: String, CaseIterable, Identifiable, Hashable {
    case earFirst = "ear-first"
    case guidedConstruction = "guided-construction"
    case coastlineReasoning = "coastline-reasoning"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .earFirst: "Ear-first Retrieval"
        case .guidedConstruction: "Guided Construction"
        case .coastlineReasoning: "Coastline Reasoning"
        }
    }

    var shortSummary: String {
        switch self {
        case .earFirst:
            "Hear the sea, retrieve the origin line before support appears, then verify the coast words."
        case .guidedConstruction:
            "Build meaning from labelled units, receive structural recovery, then rebuild without the labels."
        case .coastlineReasoning:
            "Place sea, bay and place on one coast, apply the sound distinction, then produce the origin line after the map is removed."
        }
    }

    var tradeoff: String {
        switch self {
        case .earFirst:
            "Strongest early recall signal; the first unsupported response may feel demanding to a hesitant learner."
        case .guidedConstruction:
            "Clearest path into the sentence; visible roles may over-support learners who already remember the frame."
        case .coastlineReasoning:
            "Makes place carry the meaning; the visual model is more bespoke and must prove that it transfers beyond this coast."
        }
    }

    var reusablePrimitives: [String] {
        switch self {
        case .earFirst:
            [
                "Audio-or-text cue gate",
                "Unsupported recall prompt",
                "Targeted scaffold after a miss",
            ]
        case .guidedConstruction:
            [
                "Semantic sentence slots",
                "Tap ordering with VoiceOver move actions",
                "Scaffold removal and immediate retrieval",
            ]
        case .coastlineReasoning:
            [
                "Accessible place-relation model",
                "Tap-to-assign concept matching",
                "Visual scaffold withdrawal before production",
            ]
        }
    }

    var changedDimensions: Set<LearningPrototypeMechanicDimension> {
        switch self {
        case .earFirst:
            [.recallDemand, .supportTiming, .responseMethod, .recoveryShape]
        case .guidedConstruction:
            [.supportTiming, .responseMethod, .misconceptionDiagnosis, .recoveryShape]
        case .coastlineReasoning:
            [.recallDemand, .storyMotivation, .responseMethod, .misconceptionDiagnosis]
        }
    }

    var symbol: String {
        switch self {
        case .earFirst: "ear"
        case .guidedConstruction: "square.split.2x1"
        case .coastlineReasoning: "map"
        }
    }
}

struct PrototypeExerciseOption: Identifiable, Equatable {
    let id: String
    let text: String
    let isCorrect: Bool
    let rationale: String
}

struct PrototypeExercisePair: Identifiable, Equatable {
    let id: String
    let left: String
    let right: String
}

struct ClewBayPrototypeExercise: Identifiable, Equatable {
    let id: String
    let title: String
    let context: String
    let body: String
    let objective: String
    let prompt: String
    let answer: String
    let options: [PrototypeExerciseOption]
    let tokens: [String]
    let pairs: [PrototypeExercisePair]
    let translation: String?
    let audioText: String?
    let modelText: String?
    let feedback: String
    let hint: String
    let recovery: String
    let lexemeIDs: [String]
}

/// Disposable, prototype-only copies of the three revision-6 Clew Bay exercises.
/// These values intentionally stay outside the production county-pack catalogue.
/// Copy changes here must be checked against the source ids before comparison.
enum ClewBayLearningPrototypeFixture {
    static let learningQuestion =
        "Can Clew Bay help you connect farraige to place and produce the Mayo origin line without reading the answer?"

    static let storyContext =
        "Mayo's western edge opens onto the farraige — the sea. Here the water is not a border at the end of the land. It is the road, the larder and the source of power. To understand Gráinne Ní Mháille, begin with the sea her people worked."

    static let placeContext =
        "The territory around the bay had a name: Umhaill, the Owles. It was a specific áit — a place — with its own people, boundaries and loyalties. Naming it matters: the story is not about a coast in general but about this one, and who held it."

    static let originContext =
        "In Irish you can place yourself with a small frame: as, meaning 'from'. Is as Maigh Eo mé — I am from Mayo. Gráinne's world begins with origin: which coast, which people, which bay you belong to."

    static let listening = ClewBayPrototypeExercise(
        id: "mayo.clew-bay.listen-farraige",
        title: "Hear the sea before you read it",
        context: "Farraige · sea",
        body: "The word belongs to the water you are looking at.",
        objective: "Recognise farraige by sound as the sea that defines this coast.",
        prompt: "Listen, then choose the meaning that belongs to this coast.",
        answer: "sea",
        options: [
            .init(
                id: "sea",
                text: "sea",
                isCorrect: true,
                rationale: "Farraige means the sea."
            ),
            .init(
                id: "island",
                text: "island",
                isCorrect: false,
                rationale: "That names the land in the water, not the water itself."
            ),
            .init(
                id: "castle",
                text: "castle",
                isCorrect: false,
                rationale: "Caisleán means castle; this word names the open water."
            ),
        ],
        tokens: [],
        pairs: [],
        translation: "sea",
        audioText: "farraige",
        modelText: nil,
        feedback: "Farraige is the sea that makes this coast a working world.",
        hint: "Listen for the rolling middle sound: far-ig-eh.",
        recovery: "That answer names something on the water rather than the water. Replay farraige and try again.",
        lexemeIDs: ["lex.farraige"]
    )

    static let origin = ClewBayPrototypeExercise(
        id: "mayo.clew-bay.build-origin",
        title: "Build a line of origin",
        context: "Is as Maigh Eo mé · I am from Mayo",
        body: "Use the frame to place yourself on this coast.",
        objective: "Produce a complete origin sentence with the as … mé frame.",
        prompt: "Build: I am from Mayo.",
        answer: "Is as Maigh Eo mé.",
        options: [],
        tokens: ["as", "Maigh Eo", "Is", "mé."],
        pairs: [],
        translation: "I am from Mayo.",
        audioText: nil,
        modelText: "Is as Maigh Eo mé.",
        feedback: "Is as Maigh Eo mé — origin stated in one clean frame.",
        hint: "The frame runs Is as [place] mé.",
        recovery: "Every word is needed. Keep the order Is · as · the place · mé.",
        lexemeIDs: ["lex.as"]
    )

    static let coast = ClewBayPrototypeExercise(
        id: "mayo.clew-bay.match-coast",
        title: "Keep the coast's words distinct",
        context: "Three words · one coast",
        body: "Match each Irish word to what it names on this coast.",
        objective: "Connect the opening headwords to their meanings.",
        prompt: "Choose an Irish word, then the meaning that belongs with it.",
        answer: "all pairs",
        options: [],
        tokens: [],
        pairs: [
            .init(id: "farraige", left: "farraige", right: "sea"),
            .init(id: "ba", left: "bá", right: "bay"),
            .init(id: "ait", left: "áit", right: "place"),
        ],
        translation: nil,
        audioText: nil,
        modelText: nil,
        feedback: "Sea, bay and place — the coast now has three distinct names.",
        hint: "Replay the words. Farraige is the open water; bá is the sheltered inlet; áit is the named coast.",
        recovery: "Those two do not belong together. Keep the first word selected and try another meaning.",
        lexemeIDs: ["lex.farraige", "lex.ba", "lex.ait"]
    )

    static let exercises = [listening, origin, coast]

    static func isOriginAnswer(_ value: String) -> Bool {
        normalizedSentence(value) == normalizedSentence(origin.answer)
    }

    static func normalizedSentence(_ value: String) -> String {
        value.precomposedStringWithCanonicalMapping
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .lowercased()
    }
}

// MARK: - Comparison gallery

struct LearningMechanicsComparisonView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                EditorialScreenHeader(
                    context: "Internal comparison · Mayo fixture",
                    title: "Three ways to learn from Clew Bay",
                    detail: ClewBayLearningPrototypeFixture.learningQuestion,
                    accent: Theme.moss
                )

                commonRun

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(LearningPrototypeDirection.allCases) { direction in
                        NavigationLink {
                            LearningPrototypeDestination(direction: direction)
                        } label: {
                            directionRow(direction)
                        }
                        .buttonStyle(CarvePress())
                        .accessibilityIdentifier("prototype-direction-\(direction.rawValue)")
                    }
                }

                comparisonRubric

                Text("Prototype status: fixture-only, local to this run, and deliberately disposable. No county progress, carried words or review schedule is changed.")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(3)
                    .accessibilityIdentifier("prototype-isolation-note")
            }
            .padding(.horizontal, EditorialLayout.pageInset)
            .padding(.vertical, 26)
            .frame(maxWidth: EditorialLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Learning prototypes")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("learning-mechanics-comparison")
    }

    private var commonRun: some View {
        VStack(alignment: .leading, spacing: 12) {
            EditorialSectionHeader(
                context: "Same in every direction",
                title: "One story setup, one error path, one goal",
                detail: "Each run starts clean. It uses the same audio, accepted sentence, coast pairs, authored feedback and recovery."
            )

            VStack(alignment: .leading, spacing: 8) {
                fixtureLine(ClewBayLearningPrototypeFixture.listening.id, "farraige → sea")
                fixtureLine(ClewBayLearningPrototypeFixture.origin.id, "origin line · Irish production")
                fixtureLine(ClewBayLearningPrototypeFixture.coast.id, "farraige · bá · áit")
            }
            .padding(16)
            .background(Theme.sunk)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func fixtureLine(_ id: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.ink)
            Text(id)
                .font(.caption.monospaced())
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func directionRow(_ direction: LearningPrototypeDirection) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: direction.symbol)
                .font(.title2)
                .foregroundStyle(Theme.moss)
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 7) {
                Text(direction.title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text(direction.shortSummary)
                    .font(.body)
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(3)
                Text(direction.tradeoff)
                    .font(.footnote)
                    .foregroundStyle(Theme.inkFaint)
                    .lineSpacing(2)
            }
            Spacer(minLength: 6)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.inkFaint)
                .accessibilityHidden(true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(Theme.raised)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(direction.title). \(direction.shortSummary) Tradeoff: \(direction.tradeoff)"
        )
    }

    private var comparisonRubric: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 10) {
                rubricLine("Clarity of task", "Can you tell what to attend to, do and check?")
                rubricLine("Story connection", "Does Clew Bay make the Irish necessary and memorable?")
                rubricLine("Recall and production", "How much must you retrieve or construct?")
                rubricLine("Recovery", "Does a miss lead to a useful changed attempt?")
                rubricLine("Tone", "Does the work feel calm, adult and encouraging?")
                rubricLine("Native iOS use", "Are input, audio and navigation dependable?")
                rubricLine("Accessibility", "Does the task survive type size, VoiceOver, motion, sound and non-drag use?")
            }
            .padding(.top, 12)
        } label: {
            Text("Comparison rubric")
                .font(.headline)
                .foregroundStyle(Theme.ink)
                .frame(minHeight: 44)
        }
        .tint(Theme.moss)
    }

    private func rubricLine(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.ink)
            Text(detail).font(.subheadline).foregroundStyle(Theme.inkSoft)
        }
    }
}

struct LearningPrototypeDestination: View {
    let direction: LearningPrototypeDirection

    var body: some View {
        switch direction {
        case .earFirst:
            EarFirstRetrievalPrototype()
        case .guidedConstruction:
            GuidedConstructionPrototype()
        case .coastlineReasoning:
            CoastlineReasoningPrototype()
        }
    }
}

// MARK: - Shared prototype frame

struct LearningPrototypeScaffold<Content: View, Footer: View>: View {
    let direction: LearningPrototypeDirection
    let step: Int
    let total: Int
    let stageContext: String
    let title: String
    let detail: String?
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer

    init(
        direction: LearningPrototypeDirection,
        step: Int,
        total: Int,
        stageContext: String,
        title: String,
        detail: String? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.direction = direction
        self.step = step
        self.total = total
        self.stageContext = stageContext
        self.title = title
        self.detail = detail
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        VStack(spacing: 0) {
            prototypeChrome

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 9) {
                        EditorialContextLabel(text: stageContext, color: Theme.moss)
                            .accessibilitySortPriority(5)
                        Text(title)
                            .font(.system(.title2, design: .serif, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilitySortPriority(4.8)
                        if let detail {
                            Text(detail)
                                .font(.body)
                                .foregroundStyle(Theme.inkSoft)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilitySortPriority(4.6)
                        }
                    }

                    content
                        .accessibilitySortPriority(3)
                }
                .padding(.horizontal, EditorialLayout.pageInset)
                .padding(.top, 24)
                .padding(.bottom, 28)
                .frame(maxWidth: EditorialLayout.readingWidth)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom) {
            footer
                .padding(.horizontal, EditorialLayout.pageInset)
                .padding(.vertical, 12)
                .frame(maxWidth: EditorialLayout.readingWidth)
                .frame(maxWidth: .infinity)
                .background(Theme.bg.opacity(0.98))
                .accessibilitySortPriority(1)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(direction.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var prototypeChrome: some View {
        VStack(spacing: 8) {
            HStack {
                Text(direction.title)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Text("\(step)/\(total)")
                    .monospacedDigit()
                    .fixedSize()
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.inkSoft)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.line).frame(height: 3)
                    Capsule().fill(Theme.moss)
                        .frame(
                            width: geometry.size.width * CGFloat(step) / CGFloat(max(total, 1)),
                            height: 3
                        )
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, EditorialLayout.pageInset)
        .padding(.vertical, 11)
        .background(Theme.bg)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(direction.title), step \(step) of \(total)")
        .accessibilityIdentifier("prototype-\(direction.rawValue)-step-\(step)")
    }
}

struct LearningPrototypeIntroduction: View {
    let direction: LearningPrototypeDirection
    let totalSteps: Int
    let onBegin: () -> Void

    var body: some View {
        LearningPrototypeScaffold(
            direction: direction,
            step: 1,
            total: totalSteps,
            stageContext: "Clew Bay · common starting point",
            title: "Begin with the coast",
            detail: ClewBayLearningPrototypeFixture.storyContext
        ) {
            VStack(alignment: .leading, spacing: 20) {
                ClewBayMiniature(showRoute: false)
                    .frame(height: 190)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        "Simplified Clew Bay field drawing showing open water, islands and the Mayo coast"
                    )

                VStack(alignment: .leading, spacing: 8) {
                    EditorialContextLabel(text: "Teaching approach")
                    Text(direction.title)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text(direction.shortSummary)
                        .font(.body)
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(3)
                }

                EditorialRule()

                VStack(alignment: .leading, spacing: 16) {
                    introductionPassage(
                        "The named coast",
                        ClewBayLearningPrototypeFixture.placeContext
                    )
                    introductionPassage(
                        "The origin line",
                        ClewBayLearningPrototypeFixture.originContext
                    )
                }

                Text("Comparison fixture: this composition is temporary. The historical and Irish exercise payloads are copied unchanged from the non-bundled Mayo review draft.")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkFaint)
                    .lineSpacing(3)
                    .accessibilityIdentifier("prototype-fixture-disclosure")
            }
        } footer: {
            PrimaryButton(
                title: beginTitle,
                fullWidth: true,
                accessibilityIdentifier: "prototype-begin",
                action: onBegin
            )
        }
    }

    private var beginTitle: String {
        switch direction {
        case .earFirst: "Begin with sound"
        case .guidedConstruction: "Begin with support"
        case .coastlineReasoning: "Begin with the coastline"
        }
    }

    private func introductionPassage(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Text(detail)
                .font(.body)
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct LearningPrototypeCompletion: View {
    @Environment(\.dismiss) private var dismiss

    let direction: LearningPrototypeDirection
    let step: Int
    let total: Int

    var body: some View {
        LearningPrototypeScaffold(
            direction: direction,
            step: step,
            total: total,
            stageContext: "Clew Bay · run complete",
            title: "The same learning goal, reached this way",
            detail: "This records no score or county progress. Return to the comparison and try another direction from a clean start."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                completionLine("ear", "Recognised farraige as the sea.")
                completionLine("text.quote", "Produced Is as Maigh Eo mé.")
                completionLine("water.waves", "Kept farraige, bá and áit distinct.")

                EditorialRule().padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Reusable pieces this direction tests")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    ForEach(direction.reusablePrimitives, id: \.self) { primitive in
                        Label(primitive, systemImage: "circle")
                            .font(.body)
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }
            .accessibilityIdentifier("prototype-complete-\(direction.rawValue)")
        } footer: {
            PrimaryButton(
                title: "Back to comparison",
                fullWidth: true,
                accessibilityIdentifier: "prototype-back-to-comparison"
            ) {
                dismiss()
            }
        }
    }

    private func completionLine(_ symbol: String, _ text: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.body)
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }
}

// MARK: - Shared response pieces

enum PrototypeFeedbackTone {
    case diagnostic
    case support
    case success

    var title: String {
        switch self {
        case .diagnostic: "Look again"
        case .support: "A smaller next step"
        case .success: "That fits"
        }
    }

    var symbol: String {
        switch self {
        case .diagnostic: "arrow.uturn.left"
        case .support: "lightbulb"
        case .success: "checkmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .diagnostic: Theme.rust
        case .support: Theme.lichen
        case .success: Theme.moss
        }
    }

    var background: Color {
        switch self {
        case .diagnostic: Theme.rustTint
        case .support: Theme.sunk
        case .success: Theme.raised
        }
    }
}

enum PrototypeAnswerState: Equatable {
    case unanswered
    case incorrect(String)
    case correct(String)

    var isLocked: Bool {
        switch self {
        case .unanswered: false
        case .incorrect, .correct: true
        }
    }
}

struct PrototypeFeedbackPanel: View {
    let tone: PrototypeFeedbackTone
    let message: String
    var identifier: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: tone.symbol)
                .font(.headline)
                .foregroundStyle(tone.color)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(tone.title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text(message)
                    .font(.body)
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tone.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tone.title). \(message)")
        .accessibilityIdentifier(identifier)
        .accessibilitySortPriority(2)
    }
}

struct PrototypeAudioControl: View {
    @ObservedObject private var speech = SpeechService.shared

    let text: String
    let translation: String
    @Binding var cueAvailable: Bool
    var identifier = "prototype-audio"

    @State private var played = false
    @State private var showsTextAlternative = false
    @State private var playbackFailed = false

    private var forcedUnavailable: Bool {
        ProcessInfo.processInfo.arguments.contains("--prototype-missing-audio")
    }

    private var audioAvailable: Bool {
        !forcedUnavailable && !playbackFailed && speech.canSpeak(text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if audioAvailable {
                Button {
                    speech.speak(text)
                    if speech.isSpeaking(text) {
                        played = true
                    } else {
                        playbackFailed = true
                        showsTextAlternative = true
                    }
                    cueAvailable = true
                } label: {
                    Label(
                        played ? "Replay the Irish" : "Hear the Irish",
                        systemImage: played ? "speaker.wave.2.fill" : "speaker.wave.2"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.bordered)
                .tint(Theme.moss)
                .accessibilityLabel(played ? "Replay farraige" : "Play farraige")
                .accessibilityHint("Plays the bundled model recording")
                .accessibilityIdentifier(identifier)

                Button(showsTextAlternative ? "Text alternative shown" : "Use the text alternative") {
                    showsTextAlternative = true
                    cueAvailable = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.moss)
                .frame(minHeight: 44)
                .accessibilityIdentifier("\(identifier)-fallback")
            } else {
                Label(
                    "The model recording is unavailable. Use the readable version and continue.",
                    systemImage: "speaker.slash"
                )
                .font(.body)
                .foregroundStyle(Theme.rust)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.rustTint)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("\(identifier)-missing")
            }

            if showsTextAlternative || !audioAvailable {
                VStack(alignment: .leading, spacing: 4) {
                    Text(text)
                        .font(.system(.title2, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(translation)
                        .font(.body)
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.sunk)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Text alternative. \(text), \(translation)")
                .accessibilityIdentifier("\(identifier)-text-alternative")
            }
        }
        .onAppear {
            if !audioAvailable {
                cueAvailable = true
                showsTextAlternative = true
            }
        }
        .onDisappear {
            if speech.isSpeaking(text) { speech.stop() }
        }
    }
}

struct PrototypeChoiceGroup: View {
    let options: [PrototypeExerciseOption]
    let locked: Bool
    let selectedID: String?
    let onChoose: (PrototypeExerciseOption) -> Void
    var identifierPrefix = "prototype-option"

    var body: some View {
        VStack(spacing: 10) {
            ForEach(options) { option in
                Button {
                    onChoose(option)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(option.text)
                            .font(.body)
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        Image(systemName: selectedID == option.id ? "circle.inset.filled" : "circle")
                            .font(.caption)
                            .foregroundStyle(selectedID == option.id ? Theme.moss : Theme.inkFaint)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, 13)
                    .padding(.horizontal, 15)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .background(selectedID == option.id ? Theme.mossTint : Theme.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(CarvePress())
                .disabled(locked)
                .accessibilityLabel(option.text)
                .accessibilityValue(selectedID == option.id ? "Selected" : "Not selected")
                .accessibilityIdentifier("\(identifierPrefix)-\(option.id)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Answer choices")
    }
}

struct PrototypeMatchingBoard: View {
    let pairs: [PrototypeExercisePair]
    let locked: Bool
    let onWrong: () -> Void
    let onComplete: () -> Void
    var identifierPrefix = "prototype-match"

    @State private var selectedLeftID: String?
    @State private var matchedIDs: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Irish")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSoft)

            FlowLayout(spacing: 8) {
                ForEach(pairs) { pair in
                    Button {
                        selectedLeftID = pair.id
                        if SpeechService.shared.canSpeak(pair.left) {
                            SpeechService.shared.speak(pair.left)
                        }
                    } label: {
                        matchLabel(
                            pair.left,
                            selected: selectedLeftID == pair.id,
                            complete: matchedIDs.contains(pair.id)
                        )
                    }
                    .buttonStyle(CarvePress())
                    .disabled(locked || matchedIDs.contains(pair.id))
                    .accessibilityLabel("\(pair.left), Irish word")
                    .accessibilityValue(
                        matchedIDs.contains(pair.id)
                            ? "Matched"
                            : (selectedLeftID == pair.id ? "Selected" : "Not selected")
                    )
                    .accessibilityHint("Double-tap, then choose its English meaning")
                    .accessibilityIdentifier("\(identifierPrefix)-word-\(pair.id)")
                }
            }

            Text("Meaning")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSoft)
                .padding(.top, 4)

            FlowLayout(spacing: 8) {
                ForEach(Array(pairs.reversed())) { pair in
                    Button {
                        guard let selectedLeftID else { return }
                        if selectedLeftID == pair.id {
                            matchedIDs.insert(pair.id)
                            self.selectedLeftID = nil
                            if matchedIDs.count == pairs.count {
                                onComplete()
                            } else {
                                prototypeAnnouncement(
                                    "Matched \(pair.left) with \(pair.right). "
                                        + "\(matchedIDs.count) of \(pairs.count) complete."
                                )
                            }
                        } else {
                            onWrong()
                        }
                    } label: {
                        matchLabel(
                            pair.right,
                            selected: false,
                            complete: matchedIDs.contains(pair.id)
                        )
                    }
                    .buttonStyle(CarvePress())
                    .disabled(locked || matchedIDs.contains(pair.id) || selectedLeftID == nil)
                    .accessibilityLabel("\(pair.right), English meaning")
                    .accessibilityValue(matchedIDs.contains(pair.id) ? "Matched" : "Not matched")
                    .accessibilityHint("Matches this meaning to the selected Irish word")
                    .accessibilityIdentifier("\(identifierPrefix)-meaning-\(pair.id)")
                }
            }

            Text("Tap an Irish word, then its meaning. Dragging is not required.")
                .font(.footnote)
                .foregroundStyle(Theme.inkFaint)
                .accessibilityIdentifier("\(identifierPrefix)-non-drag-note")
        }
    }

    private func matchLabel(_ text: String, selected: Bool, complete: Bool) -> some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.body)
                .foregroundStyle(complete ? Theme.moss : Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            if complete {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.moss)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 13)
        .frame(minHeight: 46)
        .background(selected ? Theme.mossTint : Theme.raised)
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

func prototypeStateChange(_ message: String, focus: @escaping () -> Void) {
    prototypeAnnouncement(message)
    prototypeMoveAccessibilityFocus(focus)
}

func prototypeMoveAccessibilityFocus(_ focus: @escaping () -> Void) {
    Task { @MainActor in
        await Task.yield()
        focus()
    }
}

func prototypeAnnouncement(_ message: String) {
    UIAccessibility.post(notification: .announcement, argument: message)
}
