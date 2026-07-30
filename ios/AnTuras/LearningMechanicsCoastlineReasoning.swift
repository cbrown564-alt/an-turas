import SwiftUI

struct CoastlineReasoningPrototype: View {
    private enum Stage: Int {
        case introduction = 1
        case coast
        case listening
        case origin
        case complete
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var feedbackFocused: Bool
    @AccessibilityFocusState private var listeningPromptFocused: Bool
    @AccessibilityFocusState private var originSupportFocused: Bool

    @State private var stage: Stage = .introduction

    @State private var coastDiagnosticVisible = false
    @State private var coastComplete = false

    @State private var listeningCueAvailable = false
    @State private var selectedListeningOptionID: String?
    @State private var listeningState: PrototypeAnswerState = .unanswered

    @State private var originText = ""
    @State private var originState: PrototypeAnswerState = .unanswered
    @State private var originRecoveryVisible = false
    @FocusState private var originFieldFocused: Bool

    private let totalSteps = 5

    private var motionReduced: Bool {
        reduceMotion || ProcessInfo.processInfo.arguments.contains("--prototype-reduce-motion")
    }

    var body: some View {
        Group {
            switch stage {
            case .introduction:
                LearningPrototypeIntroduction(
                    direction: .coastlineReasoning,
                    totalSteps: totalSteps
                ) {
                    move(to: .coast)
                }
            case .coast:
                coastPage
            case .listening:
                listeningPage
            case .origin:
                originPage
            case .complete:
                LearningPrototypeCompletion(
                    direction: .coastlineReasoning,
                    step: Stage.complete.rawValue,
                    total: totalSteps
                )
            }
        }
        .transition(motionReduced ? .opacity : .move(edge: .trailing).combined(with: .opacity))
    }

    private var coastPage: some View {
        let exercise = ClewBayLearningPrototypeFixture.coast

        return LearningPrototypeScaffold(
            direction: .coastlineReasoning,
            step: Stage.coast.rawValue,
            total: totalSteps,
            stageContext: "Clew Bay · visual place model",
            title: "Read the coast from water to land",
            detail: exercise.objective
        ) {
            VStack(alignment: .leading, spacing: 18) {
                Text(exercise.prompt)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityFocused($listeningPromptFocused)

                CoastlineReasoningBoard(
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
                    }
                )

                if coastDiagnosticVisible {
                    PrototypeFeedbackPanel(
                        tone: .diagnostic,
                        message: exercise.recovery,
                        identifier: "coastline-map-feedback"
                    )
                    .accessibilityFocused($feedbackFocused)
                } else if coastComplete {
                    PrototypeFeedbackPanel(
                        tone: .success,
                        message: exercise.feedback,
                        identifier: "coastline-map-feedback"
                    )
                    .accessibilityFocused($feedbackFocused)
                }

                Text("Prototype-only visual scaffold: the Irish, meanings and pairs above are the unchanged fixture; this coast profile is disposable comparison composition.")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkFaint)
                    .lineSpacing(3)
            }
        } footer: {
            PrimaryButton(
                title: coastComplete ? "Apply the distinction by sound" : "Place all three words",
                fullWidth: true,
                accessibilityIdentifier: "coastline-map-continue"
            ) {
                move(to: .listening)
            }
            .disabled(!coastComplete)
            .opacity(coastComplete ? 1 : 0.45)
        }
    }

    private var listeningPage: some View {
        let exercise = ClewBayLearningPrototypeFixture.listening

        return LearningPrototypeScaffold(
            direction: .coastlineReasoning,
            step: Stage.listening.rawValue,
            total: totalSteps,
            stageContext: exercise.context,
            title: "Find the open water by sound",
            detail: exercise.objective
        ) {
            VStack(alignment: .leading, spacing: 18) {
                Text(exercise.prompt)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                PrototypeAudioControl(
                    text: exercise.audioText ?? "",
                    translation: exercise.translation ?? "",
                    cueAvailable: $listeningCueAvailable,
                    identifier: "coastline-audio"
                )

                if listeningCueAvailable {
                    PrototypeChoiceGroup(
                        options: exercise.options,
                        locked: listeningState.isLocked,
                        selectedID: selectedListeningOptionID,
                        onChoose: gradeListening,
                        identifierPrefix: "coastline-listen"
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
                identifier: "coastline-listen-feedback"
            )
            .accessibilityFocused($feedbackFocused)
        case .correct(let message):
            PrototypeFeedbackPanel(
                tone: .success,
                message: message,
                identifier: "coastline-listen-feedback"
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
                accessibilityIdentifier: "coastline-listen-waiting"
            ) {}
                .disabled(true)
                .opacity(0.45)
        case .incorrect:
            PrimaryButton(
                title: "Replay and retry",
                fullWidth: true,
                accessibilityIdentifier: "coastline-listen-retry"
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
                title: "Leave the map behind",
                fullWidth: true,
                accessibilityIdentifier: "coastline-listen-continue"
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
            let message = "\(option.rationale) \(exercise.recovery)"
            listeningState = .incorrect(message)
            announce(message)
        }
    }

    private var originPage: some View {
        let exercise = ClewBayLearningPrototypeFixture.origin

        return LearningPrototypeScaffold(
            direction: .coastlineReasoning,
            step: Stage.origin.rawValue,
            total: totalSteps,
            stageContext: "Clew Bay · visual scaffold removed",
            title: "Name your origin without the coast profile",
            detail: exercise.objective
        ) {
            VStack(alignment: .leading, spacing: 18) {
                Text(exercise.prompt)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)

                if let translation = exercise.translation {
                    Text(translation)
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .accessibilityLabel("Meaning: \(translation)")
                }

                if originRecoveryVisible {
                    VStack(alignment: .leading, spacing: 12) {
                        PrototypeFeedbackPanel(
                            tone: .support,
                            message: exercise.hint,
                            identifier: "coastline-origin-support"
                        )
                        .accessibilityFocused($originSupportFocused)
                        Label("Maigh Eo · the named place", systemImage: "mappin")
                            .font(.body)
                            .foregroundStyle(Theme.ink)
                            .padding(14)
                            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                            .background(Theme.sunk)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Mayo, Maigh Eo, is the named place")
                    }
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
                    .accessibilityIdentifier("coastline-origin-field")
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
                identifier: "coastline-origin-feedback"
            )
            .accessibilityFocused($feedbackFocused)
        case .correct(let message):
            PrototypeFeedbackPanel(
                tone: .success,
                message: message,
                identifier: "coastline-origin-feedback"
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
                accessibilityIdentifier: "coastline-origin-check",
                action: checkOrigin
            )
                .disabled(originText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(originText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        case .incorrect:
            PrimaryButton(
                title: "Bring back one place cue",
                fullWidth: true,
                accessibilityIdentifier: "coastline-origin-retry"
            ) {
                originText = ""
                originRecoveryVisible = true
                originState = .unanswered
                feedbackFocused = false
                originFieldFocused = true
                prototypeMoveAccessibilityFocus {
                    originSupportFocused = true
                }
            }
        case .correct:
            PrimaryButton(
                title: "Complete this run",
                fullWidth: true,
                accessibilityIdentifier: "coastline-origin-continue"
            ) {
                originFieldFocused = false
                move(to: .complete)
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

    private func move(to next: Stage) {
        feedbackFocused = false
        listeningPromptFocused = false
        originSupportFocused = false
        withAnimation(motionReduced ? nil : Motion.settle) {
            stage = next
        }
    }

    private func announce(_ message: String) {
        listeningPromptFocused = false
        originSupportFocused = false
        prototypeStateChange(message) {
            feedbackFocused = true
        }
    }
}

private struct CoastlineReasoningBoard: View {
    private struct Region: Identifiable {
        let id: String
        let title: String
        let detail: String
        let pairID: String
        let symbol: String
    }

    let pairs: [PrototypeExercisePair]
    let locked: Bool
    let onWrong: () -> Void
    let onComplete: () -> Void

    @State private var selectedPairID: String?
    @State private var assignedPairIDs: Set<String> = []

    /// Prototype-only visual relationships. The answer vocabulary and meanings
    /// remain the exact `mayo.clew-bay.match-coast` pairs.
    private let regions: [Region] = [
        .init(
            id: "open-water",
            title: "Open water",
            detail: "The Atlantic road beyond the inlet",
            pairID: "farraige",
            symbol: "water.waves"
        ),
        .init(
            id: "sheltered-inlet",
            title: "Sheltered inlet",
            detail: "The bay gathered by islands and headlands",
            pairID: "ba",
            symbol: "drop"
        ),
        .init(
            id: "named-coast",
            title: "Named coast",
            detail: "Umhaill, a particular place held by people",
            pairID: "ait",
            symbol: "mappin"
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Irish words")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkSoft)

                FlowLayout(spacing: 8) {
                    ForEach(pairs.filter { !assignedPairIDs.contains($0.id) }) { pair in
                        Button {
                            selectedPairID = pair.id
                            if SpeechService.shared.canSpeak(pair.left) {
                                SpeechService.shared.speak(pair.left)
                            }
                            prototypeAnnouncement(
                                "Selected \(pair.left). Choose its coast meaning."
                            )
                        } label: {
                            Text(pair.left)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                                .padding(.horizontal, 13)
                                .frame(minHeight: 46)
                                .background(
                                    selectedPairID == pair.id ? Theme.mossTint : Theme.raised
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                        }
                        .buttonStyle(CarvePress())
                        .disabled(locked)
                        .accessibilityLabel("\(pair.left), Irish word")
                        .accessibilityValue(
                            selectedPairID == pair.id ? "Selected" : "Not selected"
                        )
                        .accessibilityHint(
                            "Double-tap, then choose its meaning on the coast profile"
                        )
                        .accessibilityIdentifier("coastline-word-\(pair.id)")
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Coast meanings")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkSoft)

                VStack(spacing: 0) {
                    ForEach(Array(regions.enumerated()), id: \.element.id) { index, region in
                        regionButton(region)
                        if index < regions.count - 1 {
                            EditorialRule()
                        }
                    }
                }
                .background(Theme.sunk)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Coast profile from open water to named land")
            }

            Text("Select an Irish word, then its literal meaning on the coast profile. Dragging and color are not required.")
                .font(.footnote)
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("coastline-non-drag-note")
        }
    }

    private func regionButton(_ region: Region) -> some View {
        let assigned = assignedPairIDs.contains(region.pairID)
        let pair = pairs.first { $0.id == region.pairID }
        let assignedLabel = assigned ? pair.map { ". Assigned \($0.left)" } ?? "" : ""

        return Button {
            assignSelectedWord(to: region)
        } label: {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: region.symbol)
                    .font(.title3)
                    .foregroundStyle(assigned ? Theme.moss : Theme.inkSoft)
                    .frame(width: 32, height: 32)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(pair?.right ?? region.title)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text("\(region.title) · \(region.detail)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                if assigned, let pair {
                    Text(pair.left)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.moss)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
            .background(assigned ? Theme.mossTint : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(CarvePress())
        .disabled(locked || assigned || selectedPairID == nil)
        .accessibilityLabel(
            "\(pair?.right ?? region.title). \(region.title). \(region.detail)\(assignedLabel)"
        )
        .accessibilityValue(assigned ? "Complete" : "Not matched")
        .accessibilityHint("Matches this meaning to the selected Irish word")
        .accessibilityIdentifier("coastline-region-\(region.id)")
    }

    private func assignSelectedWord(to region: Region) {
        guard
            let selectedPairID,
            let pair = pairs.first(where: { $0.id == selectedPairID })
        else { return }

        if region.pairID == pair.id {
            assignedPairIDs.insert(pair.id)
            self.selectedPairID = nil
            if assignedPairIDs.count == pairs.count {
                onComplete()
            } else {
                prototypeAnnouncement(
                    "Assigned \(pair.left) to \(pair.right), \(region.title). "
                        + "\(assignedPairIDs.count) of \(pairs.count) complete."
                )
            }
        } else {
            onWrong()
        }
    }
}
