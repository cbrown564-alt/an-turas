import SwiftUI

struct SoundMatchInteractionStudy: View {
    private enum Resolution {
        case waiting
        case wrong
        case correct
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var speech = SpeechService.shared

    @State private var round = 0
    @State private var selectedID: String?
    @State private var resolution: Resolution = .waiting
    @State private var showSpelling = false
    @State private var playbackFailed = false

    private let words = ClewBayInteractionStudyFixture.words

    private var currentWord: InteractionStudyWord {
        words[min(round, words.count - 1)]
    }

    private var isComplete: Bool {
        round >= words.count
    }

    private var motionReduced: Bool {
        reduceMotion
            || ProcessInfo.processInfo.arguments.contains("--interaction-study-reduce-motion")
            || ProcessInfo.processInfo.arguments.contains("--prototype-reduce-motion")
    }

    private var forcedAudioUnavailable: Bool {
        ProcessInfo.processInfo.arguments.contains("--interaction-study-missing-audio")
            || ProcessInfo.processInfo.arguments.contains("--prototype-missing-audio")
    }

    private var audioAvailable: Bool {
        !forcedAudioUnavailable
            && !playbackFailed
            && speech.canSpeak(currentWord.irish)
    }

    var body: some View {
        Group {
            if isComplete {
                completion
            } else {
                task
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Sound Match")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            if !isComplete, speech.isSpeaking(currentWord.irish) {
                speech.stop()
            }
        }
    }

    private var task: some View {
        ScrollView {
            VStack(spacing: 26) {
                wordProgress

                VStack(spacing: 8) {
                    Text("Which meaning did you hear?")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Tap the sound whenever you need it.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                }

                audioControl

                VStack(spacing: 12) {
                    ForEach(answerOrder) { option in
                        answerButton(option)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Meanings")
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, resolution == .correct ? 116 : 28)
            .frame(maxWidth: 540)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            if resolution == .correct {
                correctBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task(id: round) {
            guard !isComplete else { return }
            if forcedAudioUnavailable {
                showSpelling = true
                return
            }
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
            playCurrentWord()
        }
        .accessibilityIdentifier("interaction-study-sound-match-task-\(round + 1)")
    }

    private var wordProgress: some View {
        HStack(spacing: 8) {
            ForEach(Array(words.enumerated()), id: \.element.id) { index, word in
                HStack(spacing: 6) {
                    Image(
                        systemName: index < round
                            ? "checkmark.circle.fill"
                            : (index == round ? "waveform.circle.fill" : "circle")
                    )
                    .accessibilityHidden(true)

                    if index <= round {
                        Text(index < round ? word.irish : "\(index + 1)")
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(index <= round ? Theme.moss : Theme.inkFaint)
                .frame(maxWidth: .infinity, minHeight: 32)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Word \(round + 1) of \(words.count)")
    }

    private var audioControl: some View {
        VStack(spacing: 12) {
            Button(action: playCurrentWord) {
                ZStack {
                    Circle()
                        .fill(Theme.atlantic)
                        .frame(width: 112, height: 112)

                    Circle()
                        .stroke(Theme.moss.opacity(0.42), lineWidth: 8)
                        .frame(width: speech.isSpeaking(currentWord.irish) ? 136 : 116)
                        .opacity(speech.isSpeaking(currentWord.irish) ? 0.12 : 0)

                    Image(
                        systemName: speech.isSpeaking(currentWord.irish)
                            ? "waveform"
                            : (audioAvailable ? "speaker.wave.2.fill" : "textformat")
                    )
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Theme.salt)
                    .contentTransition(.symbolEffect(.replace))
                }
                .frame(maxWidth: .infinity, minHeight: 136)
                .contentShape(Rectangle())
            }
            .buttonStyle(InteractionStudyPressStyle())
            .accessibilityLabel(audioAvailable ? "Play \(currentWord.irish)" : "Show the Irish word")
            .accessibilityHint(
                audioAvailable
                    ? "Plays the bundled model recording"
                    : "The model recording is unavailable; the written word is shown"
            )
            .accessibilityIdentifier("interaction-study-sound-match-audio")

            if showSpelling || !audioAvailable {
                Text(currentWord.irish)
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .transition(.opacity)
                    .accessibilityIdentifier("interaction-study-sound-match-audio-fallback")
            } else {
                Button("Show the word") {
                    withStudyAnimation {
                        showSpelling = true
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.moss)
                .frame(minHeight: 44)
                .accessibilityIdentifier("interaction-study-sound-match-show-word")
            }
        }
    }

    private var answerOrder: [InteractionStudyWord] {
        switch round {
        case 0:
            [words[2], words[0], words[1]]
        case 1:
            [words[0], words[2], words[1]]
        default:
            [words[1], words[2], words[0]]
        }
    }

    private func answerButton(_ option: InteractionStudyWord) -> some View {
        let isSelected = selectedID == option.id
        let isCorrectSelection = isSelected && resolution == .correct
        let isWrongSelection = isSelected && resolution == .wrong

        return Button {
            choose(option)
        } label: {
            VStack(alignment: .leading, spacing: isWrongSelection ? 7 : 0) {
                HStack(spacing: 12) {
                    Text(option.english)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.ink)

                    Spacer(minLength: 8)

                    if isCorrectSelection {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.moss)
                            .accessibilityHidden(true)
                    } else if isWrongSelection {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.rust)
                            .accessibilityHidden(true)
                    } else {
                        Image(systemName: "circle")
                            .foregroundStyle(Theme.inkFaint)
                            .accessibilityHidden(true)
                    }
                }

                if isWrongSelection {
                    Text(wrongCue(for: option))
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                        .accessibilityIdentifier(
                            "interaction-study-sound-match-feedback-incorrect"
                        )
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
            .background(
                isCorrectSelection
                    ? Theme.mossTint
                    : (isWrongSelection ? Theme.rustTint : Theme.raised)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(InteractionStudyPressStyle())
        .disabled(resolution == .correct)
        .accessibilityLabel(option.english)
        .accessibilityValue(
            isCorrectSelection
                ? "Correct"
                : (isWrongSelection ? "Incorrect. \(wrongCue(for: option))" : "Not selected")
        )
        .accessibilityHint(isWrongSelection ? "Choose another meaning" : "")
        .accessibilityIdentifier("interaction-study-sound-match-option-\(option.english)")
    }

    private var correctBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 11) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.moss)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(currentWord.irish) · \(currentWord.english)")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text("The sound and meaning now travel together.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                }
            }

            Button(round == words.count - 1 ? "Finish the set" : "Next sound") {
                advance()
            }
            .font(.headline)
            .foregroundStyle(Theme.bg)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Theme.ink)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .buttonStyle(InteractionStudyPressStyle())
            .accessibilityIdentifier("interaction-study-sound-match-continue")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: 580)
        .frame(maxWidth: .infinity)
        .background(Theme.bg)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("interaction-study-sound-match-feedback-correct")
    }

    private var completion: some View {
        ScrollView {
            VStack(spacing: 28) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 68))
                    .foregroundStyle(Theme.moss)
                    .accessibilityHidden(true)

                VStack(spacing: 10) {
                    Text("Hear it. Know it.")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)

                    Text("No score. Three sounds connected to three meanings.")
                        .font(.body)
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    ForEach(words) { word in
                        Button {
                            if speech.canSpeak(word.irish) {
                                speech.speak(word.irish)
                            }
                        } label: {
                            HStack {
                                Text(word.irish)
                                    .font(.system(.title2, design: .serif, weight: .semibold))
                                Spacer()
                                Text(word.english)
                                    .font(.headline)
                                Image(systemName: "speaker.wave.1.fill")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 18)
                            .frame(maxWidth: .infinity, minHeight: 62)
                            .background(Theme.raised)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(InteractionStudyPressStyle())
                        .accessibilityLabel("Play \(word.irish), \(word.english)")
                    }
                }

                Button("Again") {
                    restart()
                }
                .font(.headline)
                .foregroundStyle(Theme.bg)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Theme.ink)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .buttonStyle(InteractionStudyPressStyle())
                .accessibilityIdentifier("interaction-study-sound-match-restart")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
            .frame(maxWidth: 540)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("interaction-study-sound-match-complete")
    }

    private func playCurrentWord() {
        guard audioAvailable else {
            withStudyAnimation {
                showSpelling = true
            }
            return
        }

        speech.speak(currentWord.irish)
        if !speech.isSpeaking(currentWord.irish) {
            playbackFailed = true
            withStudyAnimation {
                showSpelling = true
            }
        }
    }

    private func choose(_ option: InteractionStudyWord) {
        selectedID = option.id

        if option.id == currentWord.id {
            Haptics.chisel()
            withStudyAnimation {
                resolution = .correct
            }
            prototypeAnnouncement("\(currentWord.irish) means \(currentWord.english). Correct.")
        } else {
            Haptics.error()
            withStudyAnimation {
                resolution = .wrong
            }
            prototypeAnnouncement("\(option.english) is not \(currentWord.irish). \(wrongCue(for: option))")
        }
    }

    private func wrongCue(for option: InteractionStudyWord) -> String {
        switch option.region {
        case .openWater:
            "That names the open water. Listen once more."
        case .shelteredBay:
            "That is the sheltered water inside the coast. Listen once more."
        case .namedLand:
            "That names a place on land. Listen once more."
        }
    }

    private func advance() {
        withStudyAnimation {
            round += 1
            selectedID = nil
            resolution = .waiting
            showSpelling = false
            playbackFailed = false
        }

        if round == words.count {
            Haptics.flourish()
            prototypeAnnouncement("Sound Match complete.")
        }
    }

    private func restart() {
        withStudyAnimation {
            round = 0
            selectedID = nil
            resolution = .waiting
            showSpelling = false
            playbackFailed = false
        }
    }

    private func withStudyAnimation(_ changes: () -> Void) {
        withAnimation(motionReduced ? nil : .easeOut(duration: 0.22), changes)
    }
}
