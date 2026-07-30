import SwiftUI

struct EarFirstRetrievalPrototype: View {
    private enum Stage: Int {
        case introduction = 1
        case listening
        case origin
        case coast
        case complete
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var feedbackFocused: Bool
    @AccessibilityFocusState private var listeningPromptFocused: Bool
    @AccessibilityFocusState private var originFieldAccessibilityFocused: Bool

    @State private var stage: Stage = .introduction

    @State private var listeningCueAvailable = false
    @State private var selectedListeningOptionID: String?
    @State private var listeningState: PrototypeAnswerState = .unanswered

    @State private var originText = ""
    @State private var originState: PrototypeAnswerState = .unanswered
    @State private var originSupportVisible = false
    @FocusState private var originFieldFocused: Bool

    @State private var coastDiagnosticVisible = false
    @State private var coastComplete = false

    private let totalSteps = 5

    private var motionReduced: Bool {
        reduceMotion || ProcessInfo.processInfo.arguments.contains("--prototype-reduce-motion")
    }

    var body: some View {
        Group {
            switch stage {
            case .introduction:
                LearningPrototypeIntroduction(
                    direction: .earFirst,
                    totalSteps: totalSteps
                ) {
                    move(to: .listening)
                }
            case .listening:
                listeningPage
            case .origin:
                originPage
            case .coast:
                coastPage
            case .complete:
                LearningPrototypeCompletion(
                    direction: .earFirst,
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
            direction: .earFirst,
            step: Stage.listening.rawValue,
            total: totalSteps,
            stageContext: exercise.context,
            title: exercise.title,
            detail: exercise.objective
        ) {
            VStack(alignment: .leading, spacing: 18) {
                Text(exercise.prompt)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityFocused($listeningPromptFocused)

                PrototypeAudioControl(
                    text: exercise.audioText ?? "",
                    translation: exercise.translation ?? "",
                    cueAvailable: $listeningCueAvailable,
                    identifier: "ear-first-audio"
                )

                if listeningCueAvailable {
                    PrototypeChoiceGroup(
                        options: exercise.options,
                        locked: listeningState.isLocked,
                        selectedID: selectedListeningOptionID,
                        onChoose: gradeListening,
                        identifierPrefix: "ear-first-listen"
                    )
                } else {
                    Text("The meanings stay covered until you hear the word or open its text alternative.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
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
                identifier: "ear-first-listen-feedback"
            )
            .accessibilityFocused($feedbackFocused)
        case .correct(let message):
            PrototypeFeedbackPanel(
                tone: .success,
                message: message,
                identifier: "ear-first-listen-feedback"
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
                accessibilityIdentifier: "ear-first-listen-waiting"
            ) {}
                .disabled(true)
                .opacity(0.45)
        case .incorrect:
            PrimaryButton(
                title: "Retry the listening",
                fullWidth: true,
                accessibilityIdentifier: "ear-first-listen-retry"
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
                title: "Use it from memory",
                fullWidth: true,
                accessibilityIdentifier: "ear-first-listen-continue"
            ) {
                move(to: .origin)
                Task { @MainActor in
                    await Task.yield()
                    originFieldFocused = true
                }
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
            listeningState = .incorrect("\(option.rationale) \(exercise.recovery)")
            announce("\(option.rationale) \(exercise.recovery)")
        }
    }

    private var originPage: some View {
        let exercise = ClewBayLearningPrototypeFixture.origin

        return LearningPrototypeScaffold(
            direction: .earFirst,
            step: Stage.origin.rawValue,
            total: totalSteps,
            stageContext: "Clew Bay · unsupported retrieval",
            title: "Now place yourself here",
            detail: exercise.objective
        ) {
            VStack(alignment: .leading, spacing: 18) {
                Text(exercise.prompt)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if let translation = exercise.translation {
                    Text(translation)
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .accessibilityLabel("Meaning: \(translation)")
                }

                if originSupportVisible {
                    PrototypeFeedbackPanel(
                        tone: .support,
                        message: exercise.hint,
                        identifier: "ear-first-origin-support"
                    )
                }

                TextField("Type the complete Irish sentence", text: $originText, axis: .vertical)
                    .font(.body)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled()
                    .focused($originFieldFocused)
                    .padding(14)
                    .frame(minHeight: 54)
                    .background(Theme.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .disabled(originState.isLocked)
                    .accessibilityLabel("Your complete Irish sentence")
                    .accessibilityHint("Include the full origin line and its punctuation")
                    .accessibilityIdentifier("ear-first-origin-field")
                    .accessibilityFocused($originFieldAccessibilityFocused)
                    .submitLabel(.done)
                    .onSubmit(checkOrigin)

                FadaKeyRow(text: $originText, disabled: originState.isLocked)

                originFeedback
            }
        } footer: {
            originFooter
        }
    }

    @ViewBuilder
    private var originFeedback: some View {
        switch originState {
        case .unanswered:
            EmptyView()
        case .incorrect(let message):
            PrototypeFeedbackPanel(
                tone: .diagnostic,
                message: message,
                identifier: "ear-first-origin-feedback"
            )
            .accessibilityFocused($feedbackFocused)
        case .correct(let message):
            PrototypeFeedbackPanel(
                tone: .success,
                message: message,
                identifier: "ear-first-origin-feedback"
            )
            .accessibilityFocused($feedbackFocused)
        }
    }

    @ViewBuilder
    private var originFooter: some View {
        switch originState {
        case .unanswered:
            PrimaryButton(
                title: "Check the sentence",
                fullWidth: true,
                accessibilityIdentifier: "ear-first-origin-check",
                action: checkOrigin
            )
                .disabled(originText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(originText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        case .incorrect:
            PrimaryButton(
                title: "Retry with one cue",
                fullWidth: true,
                accessibilityIdentifier: "ear-first-origin-retry"
            ) {
                originText = ""
                originSupportVisible = true
                originState = .unanswered
                feedbackFocused = false
                originFieldFocused = true
                prototypeMoveAccessibilityFocus {
                    originFieldAccessibilityFocused = true
                }
            }
        case .correct:
            PrimaryButton(
                title: "Check the coast's words",
                fullWidth: true,
                accessibilityIdentifier: "ear-first-origin-continue"
            ) {
                originFieldFocused = false
                move(to: .coast)
            }
        }
    }

    private func checkOrigin() {
        let exercise = ClewBayLearningPrototypeFixture.origin
        originFieldFocused = false
        if ClewBayLearningPrototypeFixture.isOriginAnswer(originText) {
            Haptics.chisel()
            originState = .correct(exercise.feedback)
            announce(exercise.feedback)
        } else {
            Haptics.error()
            originState = .incorrect(exercise.recovery)
            announce(exercise.recovery)
        }
    }

    private var coastPage: some View {
        let exercise = ClewBayLearningPrototypeFixture.coast

        return LearningPrototypeScaffold(
            direction: .earFirst,
            step: Stage.coast.rawValue,
            total: totalSteps,
            stageContext: exercise.context,
            title: exercise.title,
            detail: exercise.objective
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
                    identifierPrefix: "ear-first-coast"
                )

                if coastDiagnosticVisible {
                    PrototypeFeedbackPanel(
                        tone: .diagnostic,
                        message: exercise.recovery,
                        identifier: "ear-first-coast-feedback"
                    )
                    .accessibilityFocused($feedbackFocused)
                } else if coastComplete {
                    PrototypeFeedbackPanel(
                        tone: .success,
                        message: exercise.feedback,
                        identifier: "ear-first-coast-feedback"
                    )
                    .accessibilityFocused($feedbackFocused)
                }
            }
        } footer: {
            PrimaryButton(
                title: coastComplete ? "Complete this run" : "Match all three words",
                fullWidth: true,
                accessibilityIdentifier: "ear-first-coast-continue"
            ) {
                move(to: .complete)
            }
            .disabled(!coastComplete)
            .opacity(coastComplete ? 1 : 0.45)
        }
    }

    private func move(to next: Stage) {
        feedbackFocused = false
        listeningPromptFocused = false
        originFieldAccessibilityFocused = false
        withAnimation(motionReduced ? nil : Motion.settle) {
            stage = next
        }
    }

    private func announce(_ message: String) {
        listeningPromptFocused = false
        originFieldAccessibilityFocused = false
        prototypeStateChange(message) {
            feedbackFocused = true
        }
    }
}
