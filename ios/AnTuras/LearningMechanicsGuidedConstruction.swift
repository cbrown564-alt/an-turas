import SwiftUI

struct GuidedConstructionPrototype: View {
    private enum Stage: Int {
        case introduction = 1
        case listening
        case coast
        case supportedBuild
        case recall
        case complete
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var feedbackFocused: Bool
    @AccessibilityFocusState private var listeningPromptFocused: Bool
    @AccessibilityFocusState private var buildSupportFocused: Bool
    @AccessibilityFocusState private var recallSupportFocused: Bool

    @State private var stage: Stage = .introduction

    @State private var listeningCueAvailable = false
    @State private var selectedListeningOptionID: String?
    @State private var listeningState: PrototypeAnswerState = .unanswered

    @State private var coastDiagnosticVisible = false
    @State private var coastComplete = false

    @State private var supportedBank = ClewBayLearningPrototypeFixture.origin.tokens
    @State private var supportedChosen: [String] = []
    @State private var supportedState: PrototypeAnswerState = .unanswered
    @State private var workedStartVisible = false

    @State private var recallBank = ClewBayLearningPrototypeFixture.origin.tokens
    @State private var recallChosen: [String] = []
    @State private var recallState: PrototypeAnswerState = .unanswered
    @State private var recallHintVisible = false

    private let totalSteps = 6

    private var motionReduced: Bool {
        reduceMotion || ProcessInfo.processInfo.arguments.contains("--prototype-reduce-motion")
    }

    var body: some View {
        Group {
            switch stage {
            case .introduction:
                LearningPrototypeIntroduction(
                    direction: .guidedConstruction,
                    totalSteps: totalSteps
                ) {
                    move(to: .listening)
                }
            case .listening:
                listeningPage
            case .coast:
                coastPage
            case .supportedBuild:
                supportedBuildPage
            case .recall:
                recallPage
            case .complete:
                LearningPrototypeCompletion(
                    direction: .guidedConstruction,
                    step: Stage.complete.rawValue,
                    total: totalSteps
                )
            }
        }
        .transition(motionReduced ? .opacity : .move(edge: .trailing).combined(with: .opacity))
    }

    private var listeningPage: some View {
        let exercise = ClewBayLearningPrototypeFixture.listening

        return LearningPrototypeScaffold(
            direction: .guidedConstruction,
            step: Stage.listening.rawValue,
            total: totalSteps,
            stageContext: exercise.context,
            title: "Listen with one sound cue",
            detail: exercise.objective
        ) {
            VStack(alignment: .leading, spacing: 18) {
                PrototypeFeedbackPanel(
                    tone: .support,
                    message: exercise.hint,
                    identifier: "guided-listen-support"
                )

                Text(exercise.prompt)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityFocused($listeningPromptFocused)

                PrototypeAudioControl(
                    text: exercise.audioText ?? "",
                    translation: exercise.translation ?? "",
                    cueAvailable: $listeningCueAvailable,
                    identifier: "guided-audio"
                )

                if listeningCueAvailable {
                    PrototypeChoiceGroup(
                        options: exercise.options,
                        locked: listeningState.isLocked,
                        selectedID: selectedListeningOptionID,
                        onChoose: gradeListening,
                        identifierPrefix: "guided-listen"
                    )
                }

                listeningFeedback
            }
        } footer: {
            listeningFooter
        }
    }

    @ViewBuilder
    private var listeningFeedback: some View {
        switch listeningState {
        case .unanswered:
            EmptyView()
        case .incorrect(let message):
            PrototypeFeedbackPanel(
                tone: .diagnostic,
                message: message,
                identifier: "guided-listen-feedback"
            )
            .accessibilityFocused($feedbackFocused)
        case .correct(let message):
            PrototypeFeedbackPanel(
                tone: .success,
                message: message,
                identifier: "guided-listen-feedback"
            )
            .accessibilityFocused($feedbackFocused)
        }
    }

    @ViewBuilder
    private var listeningFooter: some View {
        switch listeningState {
        case .unanswered:
            PrimaryButton(
                title: "Choose a meaning above",
                fullWidth: true,
                accessibilityIdentifier: "guided-listen-waiting"
            ) {}
                .disabled(true)
                .opacity(0.45)
        case .incorrect:
            PrimaryButton(
                title: "Replay and retry",
                fullWidth: true,
                accessibilityIdentifier: "guided-listen-retry"
            ) {
                selectedListeningOptionID = nil
                listeningState = .unanswered
                feedbackFocused = false
                prototypeMoveAccessibilityFocus {
                    listeningPromptFocused = true
                }
            }
        case .correct:
            PrimaryButton(
                title: "Set the coast's words",
                fullWidth: true,
                accessibilityIdentifier: "guided-listen-continue"
            ) {
                move(to: .coast)
            }
        }
    }

    private func gradeListening(_ option: PrototypeExerciseOption) {
        let exercise = ClewBayLearningPrototypeFixture.listening
        selectedListeningOptionID = option.id
        if option.isCorrect {
            Haptics.chisel()
            listeningState = .correct(exercise.feedback)
            announce(exercise.feedback)
        } else {
            Haptics.error()
            let message = "\(option.rationale) \(exercise.recovery)"
            listeningState = .incorrect(message)
            announce(message)
        }
    }

    private var coastPage: some View {
        let exercise = ClewBayLearningPrototypeFixture.coast

        return LearningPrototypeScaffold(
            direction: .guidedConstruction,
            step: Stage.coast.rawValue,
            total: totalSteps,
            stageContext: exercise.context,
            title: exercise.title,
            detail: "Secure the three meanings before using the sentence frame."
        ) {
            VStack(alignment: .leading, spacing: 18) {
                Text(exercise.prompt)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                PrototypeMatchingBoard(
                    pairs: exercise.pairs,
                    locked: coastComplete,
                    onWrong: {
                        Haptics.error()
                        coastDiagnosticVisible = true
                        announce(exercise.recovery)
                    },
                    onComplete: {
                        Haptics.chisel()
                        coastDiagnosticVisible = false
                        coastComplete = true
                        announce(exercise.feedback)
                    },
                    identifierPrefix: "guided-coast"
                )

                if coastDiagnosticVisible {
                    PrototypeFeedbackPanel(
                        tone: .diagnostic,
                        message: exercise.recovery,
                        identifier: "guided-coast-feedback"
                    )
                    .accessibilityFocused($feedbackFocused)
                } else if coastComplete {
                    PrototypeFeedbackPanel(
                        tone: .success,
                        message: exercise.feedback,
                        identifier: "guided-coast-feedback"
                    )
                    .accessibilityFocused($feedbackFocused)
                }
            }
        } footer: {
            PrimaryButton(
                title: coastComplete ? "Build with the frame" : "Match all three words",
                fullWidth: true,
                accessibilityIdentifier: "guided-coast-continue"
            ) {
                move(to: .supportedBuild)
            }
            .disabled(!coastComplete)
            .opacity(coastComplete ? 1 : 0.45)
        }
    }

    private var supportedBuildPage: some View {
        let exercise = ClewBayLearningPrototypeFixture.origin

        return LearningPrototypeScaffold(
            direction: .guidedConstruction,
            step: Stage.supportedBuild.rawValue,
            total: totalSteps,
            stageContext: "Is as Maigh Eo mé · meaningful units",
            title: exercise.title,
            detail: exercise.objective
        ) {
            VStack(alignment: .leading, spacing: 18) {
                Text(exercise.prompt)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)

                sentenceRoles

                if workedStartVisible {
                    PrototypeFeedbackPanel(
                        tone: .support,
                        message: "The opening unit is worked for you. Complete the same sentence from the remaining roles.",
                        identifier: "guided-build-worked-start"
                    )
                    .accessibilityFocused($buildSupportFocused)
                }

                GuidedTokenBuilder(
                    bank: $supportedBank,
                    chosen: $supportedChosen,
                    locked: supportedState.isLocked,
                    showsRoles: true,
                    identifierPrefix: "guided-build"
                )

                supportedFeedback
            }
        } footer: {
            supportedFooter
        }
    }

    private var sentenceRoles: some View {
        FlowLayout(spacing: 8) {
            role("Is", "identity")
            role("as", "from")
            role("[place]", "origin")
            role("mé", "self")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sentence roles: Is, identity; as, from; place, origin; mé, self")
        .accessibilityIdentifier("guided-sentence-roles")
    }

    private func role(_ word: String, _ meaning: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(word)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.ink)
            Text(meaning)
                .font(.caption)
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.sunk)
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    @ViewBuilder
    private var supportedFeedback: some View {
        switch supportedState {
        case .unanswered:
            EmptyView()
        case .incorrect(let message):
            PrototypeFeedbackPanel(
                tone: .diagnostic,
                message: message,
                identifier: "guided-build-feedback"
            )
            .accessibilityFocused($feedbackFocused)
        case .correct(let message):
            PrototypeFeedbackPanel(
                tone: .success,
                message: message,
                identifier: "guided-build-feedback"
            )
            .accessibilityFocused($feedbackFocused)
        }
    }

    @ViewBuilder
    private var supportedFooter: some View {
        switch supportedState {
        case .unanswered:
            PrimaryButton(
                title: "Check the construction",
                fullWidth: true,
                accessibilityIdentifier: "guided-build-check"
            ) {
                checkSupportedBuild()
            }
            .disabled(supportedBank.isEmpty == false)
            .opacity(supportedBank.isEmpty ? 1 : 0.45)
        case .incorrect:
            PrimaryButton(
                title: "Retry from a worked start",
                fullWidth: true,
                accessibilityIdentifier: "guided-build-retry"
            ) {
                supportedChosen = ["Is"]
                supportedBank = ClewBayLearningPrototypeFixture.origin.tokens.filter { $0 != "Is" }
                supportedState = .unanswered
                workedStartVisible = true
                feedbackFocused = false
                prototypeMoveAccessibilityFocus {
                    buildSupportFocused = true
                }
            }
        case .correct:
            PrimaryButton(
                title: "Remove the support",
                fullWidth: true,
                accessibilityIdentifier: "guided-build-continue"
            ) {
                recallChosen = []
                recallBank = ClewBayLearningPrototypeFixture.origin.tokens
                move(to: .recall)
            }
        }
    }

    private func checkSupportedBuild() {
        let exercise = ClewBayLearningPrototypeFixture.origin
        let response = supportedChosen.joined(separator: " ")
        if ClewBayLearningPrototypeFixture.isOriginAnswer(response) {
            Haptics.chisel()
            supportedState = .correct(exercise.feedback)
            announce(exercise.feedback)
        } else {
            Haptics.error()
            supportedState = .incorrect(exercise.recovery)
            announce(exercise.recovery)
        }
    }

    private var recallPage: some View {
        let exercise = ClewBayLearningPrototypeFixture.origin

        return LearningPrototypeScaffold(
            direction: .guidedConstruction,
            step: Stage.recall.rawValue,
            total: totalSteps,
            stageContext: "Clew Bay · support removed",
            title: "Build the line again",
            detail: "The role labels are gone. Retrieve the same complete origin sentence once more."
        ) {
            VStack(alignment: .leading, spacing: 18) {
                Text(exercise.prompt)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)

                if recallHintVisible {
                    PrototypeFeedbackPanel(
                        tone: .support,
                        message: exercise.hint,
                        identifier: "guided-recall-support"
                    )
                    .accessibilityFocused($recallSupportFocused)
                }

                GuidedTokenBuilder(
                    bank: $recallBank,
                    chosen: $recallChosen,
                    locked: recallState.isLocked,
                    showsRoles: false,
                    identifierPrefix: "guided-recall"
                )

                recallFeedback
            }
        } footer: {
            recallFooter
        }
    }

    @ViewBuilder
    private var recallFeedback: some View {
        switch recallState {
        case .unanswered:
            EmptyView()
        case .incorrect(let message):
            PrototypeFeedbackPanel(
                tone: .diagnostic,
                message: message,
                identifier: "guided-recall-feedback"
            )
            .accessibilityFocused($feedbackFocused)
        case .correct(let message):
            PrototypeFeedbackPanel(
                tone: .success,
                message: message,
                identifier: "guided-recall-feedback"
            )
            .accessibilityFocused($feedbackFocused)
        }
    }

    @ViewBuilder
    private var recallFooter: some View {
        switch recallState {
        case .unanswered:
            PrimaryButton(
                title: "Check the recalled line",
                fullWidth: true,
                accessibilityIdentifier: "guided-recall-check"
            ) {
                checkRecall()
            }
            .disabled(recallBank.isEmpty == false)
            .opacity(recallBank.isEmpty ? 1 : 0.45)
        case .incorrect:
            PrimaryButton(
                title: "Use the frame and retry",
                fullWidth: true,
                accessibilityIdentifier: "guided-recall-retry"
            ) {
                recallChosen = []
                recallBank = ClewBayLearningPrototypeFixture.origin.tokens
                recallHintVisible = true
                recallState = .unanswered
                feedbackFocused = false
                prototypeMoveAccessibilityFocus {
                    recallSupportFocused = true
                }
            }
        case .correct:
            PrimaryButton(
                title: "Complete this run",
                fullWidth: true,
                accessibilityIdentifier: "guided-recall-continue"
            ) {
                move(to: .complete)
            }
        }
    }

    private func checkRecall() {
        let exercise = ClewBayLearningPrototypeFixture.origin
        let response = recallChosen.joined(separator: " ")
        if ClewBayLearningPrototypeFixture.isOriginAnswer(response) {
            Haptics.chisel()
            recallState = .correct(exercise.feedback)
            announce(exercise.feedback)
        } else {
            Haptics.error()
            recallState = .incorrect(exercise.recovery)
            announce(exercise.recovery)
        }
    }

    private func move(to next: Stage) {
        feedbackFocused = false
        listeningPromptFocused = false
        buildSupportFocused = false
        recallSupportFocused = false
        withAnimation(motionReduced ? nil : Motion.settle) {
            stage = next
        }
    }

    private func announce(_ message: String) {
        listeningPromptFocused = false
        buildSupportFocused = false
        recallSupportFocused = false
        prototypeStateChange(message) {
            feedbackFocused = true
        }
    }
}

private struct GuidedTokenBuilder: View {
    @Binding var bank: [String]
    @Binding var chosen: [String]

    let locked: Bool
    let showsRoles: Bool
    let identifierPrefix: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(showsRoles ? "Sentence slots" : "Your sentence")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkSoft)

                FlowLayout(spacing: 8) {
                    ForEach(Array(chosen.enumerated()), id: \.element) { index, token in
                        Button {
                            chosen.remove(at: index)
                            bank.append(token)
                            prototypeAnnouncement(
                                "Removed \(token). \(chosen.count) units remain in your sentence."
                            )
                        } label: {
                            tokenLabel(token, selected: true)
                        }
                        .buttonStyle(CarvePress())
                        .disabled(locked)
                        .accessibilityLabel("\(token), position \(index + 1)")
                        .accessibilityHint("Double-tap to return this unit to the bank")
                        .accessibilityAction(named: "Move earlier") {
                            guard index > 0 else { return }
                            chosen.swapAt(index, index - 1)
                            prototypeAnnouncement(
                                "\(token), position \(index) of \(chosen.count)."
                            )
                        }
                        .accessibilityAction(named: "Move later") {
                            guard index + 1 < chosen.count else { return }
                            chosen.swapAt(index, index + 1)
                            prototypeAnnouncement(
                                "\(token), position \(index + 2) of \(chosen.count)."
                            )
                        }
                        .accessibilityIdentifier("\(identifierPrefix)-chosen-\(token)")
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
                .padding(10)
                .background(Theme.sunk)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityElement(children: .contain)
                .accessibilityLabel(
                    chosen.isEmpty
                        ? "Your sentence is empty"
                        : "Your sentence: \(chosen.joined(separator: " "))"
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Meaningful units")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkSoft)

                FlowLayout(spacing: 8) {
                    ForEach(bank, id: \.self) { token in
                        Button {
                            guard let index = bank.firstIndex(of: token) else { return }
                            bank.remove(at: index)
                            chosen.append(token)
                            prototypeAnnouncement(
                                "Added \(token), position \(chosen.count) "
                                    + "of \(chosen.count + bank.count)."
                            )
                        } label: {
                            tokenLabel(token, selected: false)
                        }
                        .buttonStyle(CarvePress())
                        .disabled(locked)
                        .accessibilityLabel("Add \(token)")
                        .accessibilityHint("Adds this unit to the end of your sentence")
                        .accessibilityIdentifier("\(identifierPrefix)-bank-\(token)")
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            }

            Text("Tap to add or remove a unit. VoiceOver actions move a chosen unit earlier or later. Dragging is not required.")
                .font(.footnote)
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("\(identifierPrefix)-non-drag-note")
        }
    }

    private func tokenLabel(_ token: String, selected: Bool) -> some View {
        Text(token)
            .font(.body)
            .foregroundStyle(Theme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 13)
            .frame(minHeight: 44)
            .background(selected ? Theme.mossTint : Theme.raised)
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}
