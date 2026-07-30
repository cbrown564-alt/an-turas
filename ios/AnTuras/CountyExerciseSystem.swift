import SwiftUI

enum CountyExercisePhase: String, CaseIterable {
    case unanswered
    case incorrect
    case hint
    case complete
}

/// Bottom-bar state published by an exercise page to the county story shell.
struct CountyExerciseBarState: Equatable {
    var title: String
    var isEnabled: Bool
    var isCheck: Bool
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
    let onBarUpdate: (CountyExerciseBarState, (() -> Void)?) -> Void

    @State private var feedback: CountyExerciseFeedbackState
    @State private var responseLocked: Bool
    @State private var checkReady = false
    @State private var speakingCanContinue = false

    init(
        page: CountyStoryPage,
        alreadyComplete: Bool,
        onComplete: @escaping () -> Void,
        onBarUpdate: @escaping (CountyExerciseBarState, (() -> Void)?) -> Void
    ) {
        self.page = page
        self.alreadyComplete = alreadyComplete
        self.onComplete = onComplete
        self.onBarUpdate = onBarUpdate
        _feedback = State(initialValue: CountyExerciseFeedbackState(alreadyComplete: alreadyComplete))
        _responseLocked = State(initialValue: alreadyComplete)
    }

    private var exercise: CountyExercise { page.exercise! }
    private var locksResponse: Bool { responseLocked }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 9) {
                Text(page.title)
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(exercise.prompt)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if !exercise.objective.isEmpty {
                    Text(exercise.objective)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            responseSurface

            feedbackPanel
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task { syncBarState() }
        .onAppear { syncBarState() }
        .onChange(of: feedback.phase) { _, _ in syncBarState() }
        .onChange(of: checkReady) { _, _ in syncBarState() }
        .onChange(of: speakingCanContinue) { _, _ in syncBarState() }
        .onChange(of: responseLocked) { _, _ in syncBarState() }
    }

    @ViewBuilder
    private var responseSurface: some View {
        switch exercise.family {
        case .listenChoose:
            CountyListenChoiceSurface(exercise: exercise, locked: locksResponse, onPick: grade)
        case .sentenceConstruction:
            CountyBuilderSurface(
                exercise: exercise,
                locked: locksResponse,
                startsWithAudio: exercise.audioText != nil,
                onCheck: gradeText,
                onCheckReadyChange: { ready, handler in
                    checkReady = ready
                    syncBarState(checkHandler: ready ? handler : nil)
                }
            )
        case .matching:
            CountyMatchingSurface(exercise: exercise, locked: locksResponse, onWrong: markWrong, onComplete: markCorrect)
        case .freeTyping:
            CountyTypingSurface(
                exercise: exercise,
                locked: locksResponse,
                onCheck: gradeText,
                onCheckReadyChange: { ready, handler in
                    checkReady = ready
                    syncBarState(checkHandler: ready ? handler : nil)
                }
            )
        case .conversation:
            CountyConversationSurface(exercise: exercise, locked: locksResponse, onPick: grade)
        case .grammarDiscovery:
            CountyGrammarDiscoverySurface(exercise: exercise, locked: locksResponse, onPick: grade)
        case .fillGap, .readRespond:
            CountyChoiceSurface(
                exercise: exercise,
                locked: locksResponse,
                onPick: grade,
                optionFont: exercise.family == .readRespond ? .body : .system(.body, design: .serif)
            )
        case .recordCompare:
            CountySpeakingSurface(
                exercise: exercise,
                locked: locksResponse,
                onComplete: markCorrect,
                onContinueReadyChange: { ready in
                    speakingCanContinue = ready
                }
            )
        }
    }

    @ViewBuilder
    private var feedbackPanel: some View {
        switch feedback.phase {
        case .unanswered:
            QuietHintButton(title: "Show a hint") {
                withAnimation(feedbackAnimation) {
                    feedback.phase = .hint
                    feedback.message = exercise.hint
                }
            }
        case .hint:
            feedbackMessage(icon: "lightbulb", title: "Hint", text: feedback.message ?? exercise.hint, color: Theme.lichen)
        case .incorrect:
            feedbackMessage(
                icon: "arrow.uturn.left",
                title: "Not quite",
                text: feedback.message ?? exercise.recovery,
                color: Theme.rust
            )
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
        .background(title == "Not quite" ? Theme.rustTint : Theme.raised)
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
            feedback.phase = .complete
            onComplete()
        }
        syncBarState()
    }

    private func syncBarState(checkHandler: (() -> Void)? = nil) {
        if feedback.phase == .complete || alreadyComplete {
            onBarUpdate(CountyExerciseBarState(title: "Continue", isEnabled: true, isCheck: false), nil)
            return
        }

        switch exercise.family {
        case .recordCompare:
            let title = speakingCanContinue ? "I compared both" : "Continue without recording"
            onBarUpdate(
                CountyExerciseBarState(title: title, isEnabled: true, isCheck: false),
                { markCorrect(exercise.feedback) }
            )
        case .sentenceConstruction, .freeTyping:
            let title = exercise.family == .sentenceConstruction ? "Check the order" : "Check the sentence"
            onBarUpdate(
                CountyExerciseBarState(title: title, isEnabled: checkReady, isCheck: true),
                checkHandler
            )
        default:
            onBarUpdate(CountyExerciseBarState(title: "Continue", isEnabled: false, isCheck: false), nil)
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

            if !heard {
                Text("Listen once, then choose a meaning.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
            }

            CountyChoiceSurface(
                exercise: exercise,
                locked: locked,
                interactionEnabled: heard,
                onPick: onPick,
                optionFont: .system(.body, design: .serif)
            )
            .opacity(heard ? 1 : 0.72)
            .accessibilityHint(heard ? "" : "Choices unlock after you hear the Irish once.")
        }
    }
}

private struct MissingAudioNotice: View {
    var body: some View {
        Label {
            Text("The model recording is missing. You can still read the task, but listening is unavailable on this device.")
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
    var interactionEnabled: Bool = true
    let onPick: (CountyExerciseOption) -> Void
    var optionFont: Font = .body

    @State private var wrongOptionIDs: Set<String> = []
    @State private var chosenCorrectID: String?

    private var canInteract: Bool { interactionEnabled && !locked }

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
                choiceRow(option)
            }
        }
    }

    @ViewBuilder
    private func choiceRow(_ option: CountyExerciseOption) -> some View {
        Button {
            guard canInteract else { return }
            if option.isCorrect {
                chosenCorrectID = option.id
                wrongOptionIDs.removeAll()
            } else {
                wrongOptionIDs.insert(option.id)
            }
            onPick(option)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(option.text)
                    .font(optionFont)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if chosenCorrectID == option.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(Theme.moss)
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(Theme.ink)
            .padding(.vertical, 13)
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background(rowBackground(for: option))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(rowBorder(for: option), lineWidth: chosenCorrectID == option.id || wrongOptionIDs.contains(option.id) ? 2 : 1)
            }
        }
        .buttonStyle(CarvePress())
        .allowsHitTesting(canInteract)
        .accessibilityLabel(option.text)
        .accessibilityAddTraits(choiceTraits(for: option))
    }

    private func choiceTraits(for option: CountyExerciseOption) -> AccessibilityTraits {
        chosenCorrectID == option.id ? .isSelected : []
    }

    private func rowBackground(for option: CountyExerciseOption) -> Color {
        if chosenCorrectID == option.id { return Theme.mossTint }
        if wrongOptionIDs.contains(option.id) { return Theme.rustTint }
        return Theme.raised
    }

    private func rowBorder(for option: CountyExerciseOption) -> Color {
        if chosenCorrectID == option.id { return Theme.moss }
        if wrongOptionIDs.contains(option.id) { return Theme.rust }
        return Theme.line
    }
}

private struct CountyConversationSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onPick: (CountyExerciseOption) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("They ask")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkSoft)
                Text(conversationPrompt)
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.sunk)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text("Your reply")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSoft)

            CountyChoiceSurface(
                exercise: exercise,
                locked: locked,
                onPick: onPick,
                optionFont: .system(.body, design: .serif)
            )
        }
    }

    private var conversationPrompt: String {
        let prompt = exercise.prompt
        if let range = prompt.range(of: ". Choose", options: [.caseInsensitive]) {
            return String(prompt[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let question = prompt.split(separator: "?").first, prompt.contains("?") {
            return "\(question)?"
        }
        return prompt
    }
}

private struct CountyGrammarDiscoverySurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onPick: (CountyExerciseOption) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !workedExamples.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(workedExamples, id: \.self) { line in
                        Text(line)
                            .font(.system(.title3, design: .serif, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.sunk)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if let question = discoveryQuestion {
                Text(question)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            CountyChoiceSurface(exercise: exercise, locked: locked, onPick: onPick, optionFont: .body)
        }
    }

    private var workedExamples: [String] {
        if let model = exercise.modelText, !model.isEmpty {
            return model.components(separatedBy: "\n").filter { !$0.isEmpty }
        }
        let prompt = exercise.prompt
        if let range = prompt.range(of: " What ", options: [.caseInsensitive]) {
            return String(prompt[..<range.lowerBound])
                .components(separatedBy: ". ")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        return []
    }

    private var discoveryQuestion: String? {
        let prompt = exercise.prompt
        if let range = prompt.range(of: " What ", options: [.caseInsensitive]) {
            return String(prompt[range.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
}

private struct CountyBuilderSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let startsWithAudio: Bool
    let onCheck: (String) -> Void
    let onCheckReadyChange: (Bool, @escaping () -> Void) -> Void

    @ObservedObject private var speech = SpeechService.shared
    @State private var bank: [String]
    @State private var chosen: [String] = []
    @State private var heard = false

    init(
        exercise: CountyExercise,
        locked: Bool,
        startsWithAudio: Bool,
        onCheck: @escaping (String) -> Void,
        onCheckReadyChange: @escaping (Bool, @escaping () -> Void) -> Void
    ) {
        self.exercise = exercise
        self.locked = locked
        self.startsWithAudio = startsWithAudio
        self.onCheck = onCheck
        self.onCheckReadyChange = onCheckReadyChange
        _bank = State(initialValue: exercise.tokens)
    }

    private var tokenFont: Font {
        exercise.operatesOnSentence ? .system(.body, design: .serif) : .body
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if startsWithAudio, let audioText = exercise.audioText {
                if speech.canSpeak(audioText) {
                    Button {
                        speech.speak(audioText)
                        heard = true
                        publishCheckState()
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
                        publishCheckState()
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .padding(10)
            .background(Theme.sunk)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityLabel("Your answer: \(chosen.joined(separator: " "))")

            FlowLayout(spacing: 8) {
                ForEach(Array(bank.enumerated()), id: \.offset) { index, token in
                    tile(token) {
                        bank.remove(at: index)
                        chosen.append(token)
                        publishCheckState()
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        }
        .onAppear { publishCheckState() }
        .onChange(of: locked) { _, _ in publishCheckState() }
    }

    private func publishCheckState() {
        let ready = chosen.count == exercise.tokens.count && !locked && (!startsWithAudio || heard)
        onCheckReadyChange(ready, performCheck)
    }

    private func performCheck() {
        let separator = exercise.authoredUse == "ordering" ? " | " : " "
        onCheck(chosen.joined(separator: separator))
    }

    private func tile(_ token: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(token)
                .font(tokenFont)
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
    @State private var flashingRightID: String?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 9) {
                ForEach(exercise.pairs) { pair in
                    matchButton(
                        pair.left,
                        isIrish: true,
                        selected: selectedLeft?.id == pair.id,
                        complete: matched.contains(pair.id)
                    ) {
                        selectedLeft = pair
                        if speech.canSpeak(pair.left) { speech.speak(pair.left) }
                    }
                }
            }
            VStack(spacing: 9) {
                ForEach(Array(exercise.pairs.reversed())) { pair in
                    matchButton(
                        pair.right,
                        isIrish: false,
                        selected: false,
                        complete: matched.contains(pair.id),
                        flashing: flashingRightID == pair.id
                    ) {
                        guard let selectedLeft else { return }
                        if selectedLeft.id == pair.id {
                            matched.insert(pair.id)
                            self.selectedLeft = nil
                            flashingRightID = nil
                            if matched.count == exercise.pairs.count {
                                onComplete(exercise.feedback)
                            }
                        } else {
                            flashingRightID = pair.id
                            onWrong(exercise.recovery)
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(500))
                                if flashingRightID == pair.id { flashingRightID = nil }
                            }
                        }
                    }
                }
            }
        }
    }

    private func matchButton(
        _ text: String,
        isIrish: Bool,
        selected: Bool,
        complete: Bool,
        flashing: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(isIrish ? .system(.body, design: .serif) : .body)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                if complete {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.moss)
                } else if selected {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(Theme.moss)
                }
            }
            .foregroundStyle(complete ? Theme.moss : Theme.ink)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background(flashing ? Theme.rustTint : (selected ? Theme.mossTint : Theme.raised))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        flashing ? Theme.rust : (selected ? Theme.moss : Theme.line),
                        lineWidth: selected || flashing ? 2 : 1
                    )
            }
        }
        .buttonStyle(CarvePress())
        .disabled(locked || complete)
        .accessibilityLabel(text)
        .accessibilityAddTraits(selected || complete ? .isSelected : [])
    }
}

private struct CountyTypingSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onCheck: (String) -> Void
    let onCheckReadyChange: (Bool, @escaping () -> Void) -> Void

    @State private var text = ""
    @FocusState private var focused: Bool

    init(
        exercise: CountyExercise,
        locked: Bool,
        onCheck: @escaping (String) -> Void,
        onCheckReadyChange: @escaping (Bool, @escaping () -> Void) -> Void
    ) {
        self.exercise = exercise
        self.locked = locked
        self.onCheck = onCheck
        self.onCheckReadyChange = onCheckReadyChange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let translation = exercise.translation {
                Text(translation)
                    .font(.headline)
                    .foregroundStyle(Theme.inkSoft)
            }
            TextField("Type in Irish", text: $text, axis: .vertical)
                .font(.system(.body, design: .serif))
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .focused($focused)
                .padding(14)
                .frame(minHeight: 52)
                .background(Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .disabled(locked)
                .accessibilityLabel("Your Irish answer")
                .accessibilityIdentifier("irish-answer-field")
                .onChange(of: text) { _, _ in publishCheckState() }
            FadaKeyRow(text: $text, disabled: locked)
        }
        .onAppear { publishCheckState() }
        .onChange(of: locked) { _, _ in publishCheckState() }
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

    private func publishCheckState() {
        let ready = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !locked
        onCheckReadyChange(ready, { onCheck(text) })
    }
}

private struct CountySpeakingSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onComplete: (String?) -> Void
    let onContinueReadyChange: (Bool) -> Void

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
        }
        .onAppear {
            onContinueReadyChange(true)
        }
        .onChange(of: compared) { _, _ in
            onContinueReadyChange(true)
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
        (.incorrect, "Not quite", "Diagnostic feedback names the mismatch while the response stays editable."),
        (.hint, "Hint", "A hint supports another attempt without revealing a score."),
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
                Text("Long-copy and accessibility-size check: a diagnostic explanation can wrap across several lines without covering the response or pushing the only primary action beneath the home indicator.")
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
