import SwiftUI

struct SentenceFlowInteractionStudy: View {
    private enum Pass {
        case guided
        case unsupported
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var speech = SpeechService.shared
    @Namespace private var sentenceMotion

    @State private var pass: Pass = .guided
    @State private var placedIDs: [String] = []
    @State private var wrongTokenID: String?
    @State private var sentenceFinished = false

    private let tokens = ClewBayInteractionStudyFixture.sentenceTokens

    private var motionReduced: Bool {
        reduceMotion
            || ProcessInfo.processInfo.arguments.contains("--interaction-study-reduce-motion")
            || ProcessInfo.processInfo.arguments.contains("--prototype-reduce-motion")
    }

    private var sentenceComplete: Bool {
        sentenceFinished
    }

    private var currentToken: InteractionStudySentenceToken? {
        guard placedIDs.count < tokens.count else { return nil }
        return tokens[placedIDs.count]
    }

    private var availableTokens: [InteractionStudySentenceToken] {
        let remaining = tokens.filter { !placedIDs.contains($0.id) }
        let preferredOrder: [String]

        switch pass {
        case .guided:
            preferredOrder = ["as", "maigh-eo", "is", "me"]
        case .unsupported:
            preferredOrder = ["me", "is", "maigh-eo", "as"]
        }

        return preferredOrder.compactMap { id in
            remaining.first { $0.id == id }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                passProgress

                VStack(alignment: .leading, spacing: 7) {
                    Text("Build the Irish line")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(ClewBayInteractionStudyFixture.sentenceTranslation)
                        .font(.title3)
                        .foregroundStyle(Theme.inkSoft)
                }

                sentenceTrack

                VStack(alignment: .leading, spacing: 12) {
                    Text(sentenceComplete ? "The line is complete." : "Tap the next word.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.inkSoft)
                        .accessibilityIdentifier("interaction-study-sentence-flow-instruction")

                    FlowLayout(spacing: 10) {
                        ForEach(availableTokens) { token in
                            tokenButton(token)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Available words")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, sentenceComplete ? 126 : 34)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier(
            pass == .unsupported && sentenceComplete
                ? "interaction-study-sentence-flow-complete"
                : "interaction-study-sentence-flow-task"
        )
        .safeAreaInset(edge: .bottom) {
            if sentenceComplete {
                completionBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Sentence Flow")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var passProgress: some View {
        HStack(spacing: 10) {
            progressPart(
                title: "With cues",
                symbol: pass == .guided ? "circle.inset.filled" : "checkmark.circle.fill",
                active: true
            )
            Rectangle()
                .fill(pass == .unsupported ? Theme.moss : Theme.line)
                .frame(height: 2)
                .accessibilityHidden(true)
            progressPart(
                title: "Without cues",
                symbol: pass == .unsupported ? "circle.inset.filled" : "circle",
                active: pass == .unsupported
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            pass == .guided
                ? "First pass, structural cues visible"
                : "Second pass, structural cues removed"
        )
    }

    private func progressPart(title: String, symbol: String, active: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .accessibilityHidden(true)
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(active ? Theme.moss : Theme.inkFaint)
    }

    private var sentenceTrack: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: pass == .guided ? "point.3.connected.trianglepath.dotted" : "eye.slash")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.weatheredGold)
                    .accessibilityHidden(true)

                Text(pass == .guided ? "The roles show the route." : "The route is yours now.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.salt.opacity(0.84))
            }

            FlowLayout(spacing: 9) {
                ForEach(Array(tokens.enumerated()), id: \.element.id) { index, token in
                    sentenceSlot(token, index: index)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let currentToken, let wrongTokenID {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "arrow.turn.down.right")
                        .foregroundStyle(Theme.weatheredGold)
                        .accessibilityHidden(true)
                    Text(recoveryCue(for: currentToken, wrongTokenID: wrongTokenID))
                        .font(.subheadline)
                        .foregroundStyle(Theme.salt)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .transition(.opacity)
                .accessibilityIdentifier("interaction-study-sentence-flow-feedback-incorrect")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .leading)
        .background(Theme.atlantic)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Irish sentence track")
    }

    private func sentenceSlot(
        _ token: InteractionStudySentenceToken,
        index: Int
    ) -> some View {
        let placed = placedIDs.contains(token.id)
        let isNext = placedIDs.count == index

        return VStack(alignment: .leading, spacing: 7) {
            Group {
                if placed {
                    Text(token.text)
                        .matchedGeometryEffect(id: token.id, in: sentenceMotion)
                        .foregroundStyle(Theme.salt)
                } else {
                    Text("···")
                        .foregroundStyle(isNext ? Theme.weatheredGold : Theme.salt.opacity(0.34))
                }
            }
            .font(.system(.title3, design: .serif, weight: .semibold))
            .frame(minHeight: 30)

            Rectangle()
                .fill(
                    placed
                        ? Theme.weatheredGold
                        : (isNext ? Theme.salt.opacity(0.82) : Theme.salt.opacity(0.24))
                )
                .frame(width: slotWidth(for: token), height: 2)

            if pass == .guided && !placed {
                Text(token.role)
                    .font(.caption)
                    .foregroundStyle(isNext ? Theme.salt.opacity(0.86) : Theme.salt.opacity(0.5))
                    .transition(.opacity)
            }
        }
        .frame(minWidth: slotWidth(for: token), minHeight: 65, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            placed
                ? "\(token.text), placed"
                : (
                    pass == .guided
                        ? "Empty \(token.role) position"
                        : "Empty position \(index + 1)"
                )
        )
    }

    private func tokenButton(_ token: InteractionStudySentenceToken) -> some View {
        let isWrong = wrongTokenID == token.id

        return Button {
            choose(token)
        } label: {
            HStack(spacing: 8) {
                Text(token.text)
                    .font(.title3.weight(.semibold))
                    .matchedGeometryEffect(id: token.id, in: sentenceMotion)

                if isWrong {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.rust)
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 18)
            .frame(minHeight: 58)
            .background(isWrong ? Theme.rustTint : Theme.raised)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(InteractionStudyPressStyle())
        .accessibilityLabel(token.text)
        .accessibilityValue(isWrong ? "Not the next word" : "Available")
        .accessibilityHint("Places this word into the next sentence position")
        .accessibilityIdentifier("interaction-study-sentence-flow-tile-\(token.id)")
    }

    private var completionBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 11) {
                Image(systemName: pass == .guided ? "checkmark.circle" : "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.moss)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(ClewBayInteractionStudyFixture.sentence)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text(
                        pass == .guided
                            ? "Now build the same line after the role cues disappear."
                            : "You rebuilt the line without the rails."
                    )
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button(pass == .guided ? "Remove the cues" : "Again") {
                pass == .guided ? removeCues() : restart()
            }
            .font(.headline)
            .foregroundStyle(Theme.bg)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Theme.ink)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .buttonStyle(InteractionStudyPressStyle())
            .accessibilityIdentifier(
                pass == .guided
                    ? "interaction-study-sentence-flow-remove-cues"
                    : "interaction-study-sentence-flow-restart"
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: 660)
        .frame(maxWidth: .infinity)
        .background(Theme.bg)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("interaction-study-sentence-flow-feedback-correct")
    }

    private func choose(_ token: InteractionStudySentenceToken) {
        guard let currentToken else { return }

        if token.id == currentToken.id {
            let willComplete = placedIDs.count + 1 == tokens.count
            Haptics.tick()
            withStudyAnimation {
                wrongTokenID = nil
                placedIDs.append(token.id)
                sentenceFinished = willComplete
            }
            prototypeAnnouncement("\(token.text), placed.")

            if willComplete {
                Haptics.flourish()
                if speech.canSpeak(ClewBayInteractionStudyFixture.sentence) {
                    speech.speak(ClewBayInteractionStudyFixture.sentence)
                }
                prototypeAnnouncement(
                    pass == .guided
                        ? "Sentence complete. Structural cues can now be removed."
                        : "Sentence complete without structural cues."
                )
            }
        } else {
            Haptics.error()
            wrongTokenID = token.id
            prototypeAnnouncement(
                "\(token.text) is not next. \(recoveryCue(for: currentToken, wrongTokenID: token.id))"
            )
        }
    }

    private func recoveryCue(
        for expected: InteractionStudySentenceToken,
        wrongTokenID: String
    ) -> String {
        let attempted = tokens.first { $0.id == wrongTokenID }?.text ?? "That word"

        if pass == .guided {
            return "\(attempted) returns to the bank. The next position is \(expected.role)."
        }

        return "\(attempted) returns. Listen to the line: \(expected.text) comes next."
    }

    private func removeCues() {
        withStudyAnimation {
            pass = .unsupported
            placedIDs = []
            wrongTokenID = nil
            sentenceFinished = false
        }
        prototypeAnnouncement("Role cues removed. Build the same Irish line again.")
    }

    private func restart() {
        withStudyAnimation {
            pass = .guided
            placedIDs = []
            wrongTokenID = nil
            sentenceFinished = false
        }
        prototypeAnnouncement("Sentence Flow restarted with structural cues.")
    }

    private func slotWidth(for token: InteractionStudySentenceToken) -> CGFloat {
        switch token.id {
        case "maigh-eo":
            92
        default:
            58
        }
    }

    private func withStudyAnimation(_ changes: () -> Void) {
        withAnimation(motionReduced ? nil : .easeOut(duration: 0.2), changes)
    }
}
