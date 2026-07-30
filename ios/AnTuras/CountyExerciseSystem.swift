import SwiftUI

enum CountyExercisePhase: String, CaseIterable {
    case unanswered
    case incorrect
    case hint
    case corrected
    case complete
}

private struct CountyExerciseFeedbackState {
    var phase: CountyExercisePhase
    var message: String?
    var misses: Int

    init(alreadyComplete: Bool) {
        phase = alreadyComplete ? .complete : .unanswered
        message = alreadyComplete ? "This exercise is complete. You can still revisit the task." : nil
        misses = 0
    }
}

/// One calm task shell for every county-pack mechanic. Correctness, retry,
/// hints and completion live here rather than being reinvented by each task.
struct CountyExerciseView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let page: CountyStoryPage
    let alreadyComplete: Bool
    let onComplete: () -> Void

    @State private var feedback: CountyExerciseFeedbackState
    @State private var responseLocked: Bool

    init(page: CountyStoryPage, alreadyComplete: Bool, onComplete: @escaping () -> Void) {
        self.page = page
        self.alreadyComplete = alreadyComplete
        self.onComplete = onComplete
        _feedback = State(initialValue: CountyExerciseFeedbackState(alreadyComplete: alreadyComplete))
        _responseLocked = State(initialValue: alreadyComplete)
    }

    private var exercise: CountyExercise { page.exercise! }
    private var locksResponse: Bool {
        responseLocked
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 9) {
                EditorialContextLabel(text: exercise.family.title, color: Theme.moss)
                Text(page.title)
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(exercise.prompt)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(exercise.objective)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            responseSurface

            feedbackPanel
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var responseSurface: some View {
        switch exercise.family {
        case .listenChoose:
            CountyListenChoiceSurface(exercise: exercise, locked: locksResponse, onPick: grade)
        case .sentenceConstruction:
            CountyBuilderSurface(exercise: exercise, locked: locksResponse, startsWithAudio: exercise.audioText != nil, onCheck: gradeText)
        case .matching:
            CountyMatchingSurface(exercise: exercise, locked: locksResponse, onWrong: markWrong, onComplete: markCorrect)
        case .freeTyping:
            CountyTypingSurface(exercise: exercise, locked: locksResponse, onCheck: gradeText)
        case .fillGap, .conversation, .readRespond, .grammarDiscovery:
            CountyChoiceSurface(exercise: exercise, locked: locksResponse, onPick: grade)
        case .recordCompare:
            CountySpeakingSurface(exercise: exercise, locked: locksResponse, onComplete: markCorrect)
        }
    }

    @ViewBuilder
    private var feedbackPanel: some View {
        switch feedback.phase {
        case .unanswered:
            Button("Show a hint") {
                withAnimation(feedbackAnimation) {
                    feedback.phase = .hint
                    feedback.message = exercise.hint
                }
            }
            .buttonStyle(.bordered)
            .tint(Theme.moss)
            .frame(minHeight: 44)
        case .hint:
            feedbackMessage(icon: "lightbulb", title: "Hint", text: feedback.message ?? exercise.hint, color: Theme.lichen)
        case .incorrect:
            feedbackMessage(icon: "arrow.uturn.left", title: "Try again", text: feedback.message ?? exercise.recovery, color: Theme.rust)
            PrimaryButton(title: "Retry", fullWidth: true) { retry() }
                .accessibilityHint("Clears this attempt and keeps you on the same task")
        case .corrected:
            feedbackMessage(icon: "checkmark.circle", title: "Corrected", text: feedback.message ?? exercise.feedback, color: Theme.moss)
            PrimaryButton(title: "Keep this answer", fullWidth: true) { finishCorrectedAnswer() }
        case .complete:
            feedbackMessage(icon: "checkmark", title: "Complete", text: feedback.message ?? exercise.feedback, color: Theme.moss)
        }
    }

    private func feedbackMessage(icon: String, title: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(Theme.ink)
                Text(text).font(.body).foregroundStyle(Theme.inkSoft).lineSpacing(3)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(title == "Try again" ? Theme.rustTint : Theme.raised)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
    }

    private func grade(_ option: CountyExerciseOption) {
        if option.isCorrect {
            markCorrect(option.rationale)
        } else {
            markWrong("\(option.rationale) \(exercise.recovery)")
        }
    }

    private func gradeText(_ value: String) {
        if normalized(value) == normalized(exercise.answer) {
            markCorrect(exercise.feedback)
        } else {
            markWrong(exercise.recovery)
        }
    }

    private func markWrong(_ message: String) {
        Haptics.error()
        responseLocked = true
        withAnimation(feedbackAnimation) {
            feedback.misses += 1
            feedback.phase = .incorrect
            feedback.message = message
        }
    }

    private func markCorrect(_ message: String? = nil) {
        Haptics.chisel()
        responseLocked = true
        withAnimation(feedbackAnimation) {
            feedback.message = message ?? exercise.feedback
            if feedback.misses > 0 {
                feedback.phase = .corrected
            } else {
                feedback.phase = .complete
                onComplete()
            }
        }
    }

    private func retry() {
        let misses = feedback.misses
        responseLocked = false
        withAnimation(feedbackAnimation) {
            feedback = CountyExerciseFeedbackState(alreadyComplete: false)
            feedback.misses = misses
        }
    }

    private func finishCorrectedAnswer() {
        responseLocked = true
        withAnimation(feedbackAnimation) {
            feedback.phase = .complete
            feedback.message = exercise.feedback
            onComplete()
        }
    }

    private var feedbackAnimation: Animation? {
        reduceMotion ? nil : Motion.settle
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: " | ", with: " | ")
            .lowercased()
    }
}

private struct CountyListenChoiceSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onPick: (CountyExerciseOption) -> Void

    @ObservedObject private var speech = SpeechService.shared
    @State private var heard = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let audioText = exercise.audioText, speech.canSpeak(audioText) {
                Button {
                    Haptics.tap()
                    speech.speak(audioText)
                    heard = true
                } label: {
                    Label(heard ? "Replay the Irish" : "Hear the Irish", systemImage: heard ? "speaker.wave.2.fill" : "speaker.wave.2")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.bordered)
                .tint(Theme.moss)
                .disabled(locked)
            } else {
                MissingAudioNotice()
            }

            if heard {
                CountyChoiceSurface(exercise: exercise, locked: locked, onPick: onPick)
            } else {
                Text("The meanings stay covered until you listen once.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }
}

private struct MissingAudioNotice: View {
    var body: some View {
        Label {
            Text("The model recording is missing. A readable task remains, but this audio exercise cannot be marked release-ready.")
        } icon: {
            Image(systemName: "speaker.slash")
        }
        .font(.body)
        .foregroundStyle(Theme.rust)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.rustTint)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
    }
}

private struct CountyChoiceSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onPick: (CountyExerciseOption) -> Void

    var body: some View {
        VStack(spacing: 10) {
            if let template = exercise.sentenceTemplate {
                Text(template)
                    .font(.system(.title, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 4)
            }
            ForEach(exercise.options) { option in
                Button { onPick(option) } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(option.text)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        Image(systemName: "circle")
                            .font(.caption)
                            .foregroundStyle(Theme.inkFaint)
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(.vertical, 13)
                    .padding(.horizontal, 15)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .background(Theme.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(CarvePress())
                .disabled(locked)
            }
        }
    }
}

private struct CountyBuilderSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let startsWithAudio: Bool
    let onCheck: (String) -> Void

    @ObservedObject private var speech = SpeechService.shared
    @State private var bank: [String]
    @State private var chosen: [String] = []
    @State private var heard = false

    init(exercise: CountyExercise, locked: Bool, startsWithAudio: Bool, onCheck: @escaping (String) -> Void) {
        self.exercise = exercise
        self.locked = locked
        self.startsWithAudio = startsWithAudio
        self.onCheck = onCheck
        _bank = State(initialValue: exercise.tokens)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if startsWithAudio, let audioText = exercise.audioText {
                if speech.canSpeak(audioText) {
                    Button {
                        speech.speak(audioText)
                        heard = true
                    } label: {
                        Label(heard ? "Replay the model" : "Play the model", systemImage: "speaker.wave.2")
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.moss)
                } else {
                    MissingAudioNotice()
                }
            }

            FlowLayout(spacing: 8) {
                ForEach(Array(chosen.enumerated()), id: \.offset) { index, token in
                    tile(token) {
                        chosen.remove(at: index)
                        bank.append(token)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .padding(10)
            .background(Theme.sunk)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel("Your answer: \(chosen.joined(separator: " "))")

            FlowLayout(spacing: 8) {
                ForEach(Array(bank.enumerated()), id: \.offset) { index, token in
                    tile(token) {
                        bank.remove(at: index)
                        chosen.append(token)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)

            PrimaryButton(title: "Check the order", fullWidth: true) {
                // D27: ordering is an authored use of sentence construction, and joins
                // its units with a visible separator rather than as running Irish.
                let separator = exercise.authoredUse == "ordering" ? " | " : " "
                onCheck(chosen.joined(separator: separator))
            }
            .disabled(chosen.count != exercise.tokens.count || locked || (startsWithAudio && !heard))
            .opacity(chosen.count == exercise.tokens.count && !locked && (!startsWithAudio || heard) ? 1 : 0.45)
        }
    }

    private func tile(_ token: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(token)
                .font(.body)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 13)
                .frame(minHeight: 44)
                .background(Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(CarvePress())
        .disabled(locked)
    }
}

private struct CountyMatchingSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onWrong: (String) -> Void
    let onComplete: (String?) -> Void

    @ObservedObject private var speech = SpeechService.shared
    @State private var selectedLeft: CountyExercisePair?
    @State private var matched: Set<String> = []

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 9) {
                ForEach(exercise.pairs) { pair in
                    matchButton(pair.left, selected: selectedLeft?.id == pair.id, complete: matched.contains(pair.id)) {
                        selectedLeft = pair
                        if speech.canSpeak(pair.left) { speech.speak(pair.left) }
                    }
                }
            }
            VStack(spacing: 9) {
                ForEach(Array(exercise.pairs.reversed())) { pair in
                    matchButton(pair.right, selected: false, complete: matched.contains(pair.id)) {
                        guard let selectedLeft else { return }
                        if selectedLeft.id == pair.id {
                            matched.insert(pair.id)
                            self.selectedLeft = nil
                            if matched.count == exercise.pairs.count {
                                onComplete(exercise.feedback)
                            }
                        } else {
                            onWrong(exercise.recovery)
                        }
                    }
                }
            }
        }
    }

    private func matchButton(_ text: String, selected: Bool, complete: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(text).font(.body).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                if complete { Image(systemName: "checkmark").font(.caption.weight(.bold)) }
            }
            .foregroundStyle(complete ? Theme.moss : Theme.ink)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background(selected ? Theme.mossTint : Theme.raised)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(CarvePress())
        .disabled(locked || complete)
    }
}

private struct CountyTypingSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onCheck: (String) -> Void

    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let translation = exercise.translation {
                Text(translation)
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }
            TextField("Type in Irish", text: $text, axis: .vertical)
                .font(.body)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .focused($focused)
                .padding(14)
                .frame(minHeight: 52)
                .background(Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .disabled(locked)
                .accessibilityLabel("Your Irish answer")
            FadaKeyRow(text: $text, disabled: locked)
            PrimaryButton(title: "Check the sentence", fullWidth: true) { onCheck(text) }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || locked)
                .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || locked ? 0.45 : 1)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                ForEach(["á", "é", "í", "ó", "ú"], id: \.self) { fada in
                    Button(fada) {
                        Haptics.tap()
                        text.append(fada)
                    }
                    .disabled(locked)
                    .accessibilityLabel("Insert \(fada) from keyboard toolbar")
                }
                Button("Check") {
                    focused = false
                    onCheck(text)
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || locked)
                .accessibilityLabel("Check answer from keyboard")
            }
        }
    }
}

private struct CountySpeakingSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onComplete: (String?) -> Void

    @StateObject private var recorder = EchoRecorder()
    @ObservedObject private var speech = SpeechService.shared
    @State private var compared = false

    private var forcedDenied: Bool {
        ProcessInfo.processInfo.arguments.contains("--microphone-denied")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let model = exercise.audioText, speech.canSpeak(model) {
                Button {
                    recorder.stopPlayback()
                    speech.speak(model)
                } label: {
                    Label("Play the model", systemImage: speech.isSpeaking(model) ? "speaker.wave.2.fill" : "speaker.wave.2")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
                .tint(Theme.moss)
            } else {
                MissingAudioNotice()
            }

            if recorder.denied || forcedDenied {
                Label("Microphone access is off. You can keep listening and continue without recording.", systemImage: "mic.slash")
                    .font(.body)
                    .foregroundStyle(Theme.inkSoft)
                    .padding(16)
                    .background(Theme.sunk)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                recordingControls
            }

            if compared {
                Text("No score is produced. The recording stays in the app's temporary local storage and is discarded when you leave this task.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(3)
            }

            Button(compared ? "I compared both" : "Continue without recording") {
                recorder.discard()
                onComplete(exercise.feedback)
            }
            .buttonStyle(.bordered)
            .tint(Theme.moss)
            .frame(minHeight: 44)
            .disabled(locked)
        }
        .onDisappear { recorder.discard() }
    }

    @ViewBuilder
    private var recordingControls: some View {
        switch recorder.state {
        case .idle, .recording:
            Button {
                if recorder.state == .recording {
                    recorder.stop()
                } else {
                    speech.stop()
                    recorder.toggle()
                }
            } label: {
                Label(recorder.state == .recording ? "Stop recording" : "Record your voice", systemImage: recorder.state == .recording ? "stop.fill" : "mic.fill")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.bordered)
            .tint(recorder.state == .recording ? Theme.rust : Theme.moss)
            .disabled(locked)
        case .recorded:
            HStack(spacing: 10) {
                Button {
                    speech.stop()
                    recorder.playBack()
                    compared = true
                } label: {
                    Label("Play your voice", systemImage: recorder.playing ? "waveform" : "play.fill")
                        .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)
                Button("Record again") { recorder.toggle() }
                    .buttonStyle(.bordered)
                    .frame(minHeight: 44)
            }
            .tint(Theme.moss)
        }
    }
}

// MARK: - Internal exercise gallery

struct CountyExerciseGalleryView: View {
    private let states: [(CountyExercisePhase, String, String)] = [
        (.unanswered, "Unanswered", "One clear task and a visible response area."),
        (.incorrect, "Incorrect", "Diagnostic feedback names the error and offers an explicit retry."),
        (.hint, "Hint", "A hint supports another attempt without revealing a score."),
        (.corrected, "Corrected", "A recovered answer is acknowledged before completion."),
        (.complete, "Complete", "Completion is quiet and does not add points or celebration."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                EditorialScreenHeader(
                    context: "Internal exercise gallery",
                    title: "One feedback model, twelve mechanics",
                    detail: "Use this screen to inspect copy length, state language, missing resources and accessibility recomposition."
                )

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(CountyExerciseFamily.allCases, id: \.self) { family in
                        Label(family.title, systemImage: "circle")
                            .font(.body)
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                }

                EditorialSectionHeader(context: nil, title: "Feedback states", detail: nil)
                ForEach(states, id: \.0) { state in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: state.0 == .incorrect ? "arrow.uturn.left" : "checkmark.circle")
                            .foregroundStyle(state.0 == .incorrect ? Theme.rust : Theme.moss)
                            .frame(width: 28, height: 28)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(state.1).font(.headline)
                            Text(state.2).font(.body).foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .padding(16)
                    .background(Theme.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                EditorialSectionHeader(context: nil, title: "Failure and edge states", detail: nil)
                MissingAudioNotice()
                Label("Denied microphone: listening remains available and progress is never trapped.", systemImage: "mic.slash")
                    .font(.body)
                    .foregroundStyle(Theme.inkSoft)
                    .padding(16)
                    .background(Theme.sunk)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text("Long-copy and accessibility-size check: a diagnostic explanation can wrap across several lines without covering the response, hiding the retry, or pushing the only primary action beneath the home indicator.")
                    .font(.body)
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(4)
                    .padding(16)
                    .background(Theme.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .accessibilityLabel("Long copy accessibility size state")
            }
            .padding(.horizontal, EditorialLayout.pageInset)
            .padding(.vertical, 24)
            .frame(maxWidth: EditorialLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Exercise gallery")
        .navigationBarTitleDisplayMode(.inline)
    }
}
