import SwiftUI
import UIKit

struct CoastPlacementInteractionStudy: View {
    private enum Pass {
        case labelled
        case unlabelled
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject private var speech = SpeechService.shared

    @State private var pass: Pass = .labelled
    @State private var round = 0
    @State private var placements: [InteractionStudyCoastRegion: String] = [:]
    @State private var wrongRegion: InteractionStudyCoastRegion?
    @State private var isSettling = false
    @State private var voiceOverAdvancePending = false
    @State private var passFinished = false

    private let words = ClewBayInteractionStudyFixture.words

    private var currentWord: InteractionStudyWord? {
        guard !passFinished, round < words.count else { return nil }
        return words[round]
    }

    private var passComplete: Bool {
        passFinished
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

    private var labelsVisible: Bool {
        pass == .labelled
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                scaffoldProgress

                if let currentWord {
                    wordPrompt(currentWord)
                } else {
                    passVerdict
                }

                coastInteraction

                if let currentWord, let wrongRegion {
                    localRecovery(word: currentWord, region: wrongRegion)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, passComplete || voiceOverAdvancePending ? 120 : 30)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier(
            pass == .unlabelled && passComplete
                ? "interaction-study-coast-placement-complete"
                : "interaction-study-coast-placement-task-\(min(round + 1, words.count))"
        )
        .safeAreaInset(edge: .bottom) {
            if passComplete || voiceOverAdvancePending {
                bottomAction
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Coast Placement")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: "\(labelsVisible)-\(round)") {
            guard let currentWord, !forcedAudioUnavailable else { return }
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
            if speech.canSpeak(currentWord.irish) {
                speech.speak(currentWord.irish)
            }
        }
        .onDisappear {
            if let currentWord, speech.isSpeaking(currentWord.irish) {
                speech.stop()
            }
        }
    }

    private var scaffoldProgress: some View {
        HStack(spacing: 10) {
            Label(
                pass == .labelled ? "Labels visible" : "Labels removed",
                systemImage: pass == .labelled ? "tag" : "tag.slash"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.moss)

            Spacer()

            if !passComplete {
                Text("\(round + 1) of \(words.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .monospacedDigit()
            }
        }
        .frame(minHeight: 32)
        .accessibilityElement(children: .combine)
    }

    private func wordPrompt(_ word: InteractionStudyWord) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Where does this word belong?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.inkSoft)

                Text(word.irish)
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button {
                play(word)
            } label: {
                Image(
                    systemName: audioAvailable(for: word)
                        ? "speaker.wave.2.fill"
                        : "speaker.slash.fill"
                )
                .font(.title3.weight(.semibold))
                .foregroundStyle(audioAvailable(for: word) ? Theme.salt : Theme.inkSoft)
                .frame(width: 54, height: 54)
                .background(audioAvailable(for: word) ? Theme.atlantic : Theme.sunk)
                .clipShape(Circle())
            }
            .buttonStyle(InteractionStudyPressStyle())
            .disabled(!audioAvailable(for: word))
            .accessibilityLabel(
                audioAvailable(for: word)
                    ? "Play \(word.irish)"
                    : "Audio unavailable. The Irish word is visible."
            )
            .accessibilityIdentifier("interaction-study-coast-placement-audio")
        }
        .accessibilityElement(children: .contain)
    }

    private var passVerdict: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(pass == .labelled ? "The words found the coast." : "The coast still holds.")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.ink)
            Text(
                pass == .labelled
                    ? "Remove the labels and place the same three words by shape alone."
                    : "Sea, bay and place remained distinct without written region cues."
            )
            .font(.body)
            .foregroundStyle(Theme.inkSoft)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var coastInteraction: some View {
        if dynamicTypeSize.isAccessibilitySize {
            accessibleRegionStack
        } else {
            CoastPlacementCanvas(
                labelsVisible: labelsVisible,
                placements: placements,
                wrongRegion: wrongRegion,
                enabled: !passComplete && !isSettling,
                onSelect: select
            )
            .frame(height: 390)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(
                "Simplified coast with open water, a sheltered bay and named land"
            )
        }
    }

    private var accessibleRegionStack: some View {
        VStack(spacing: 10) {
            ForEach(InteractionStudyCoastRegion.allCases) { region in
                Button {
                    select(region)
                } label: {
                    HStack(spacing: 13) {
                        Image(systemName: symbol(for: region))
                            .font(.title3)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(labelsVisible ? region.title : "Coast region")
                                .font(.headline)
                            if let word = placements[region] {
                                Text(word)
                                    .font(.system(.title3, design: .serif, weight: .semibold))
                            }
                        }

                        Spacer()

                        if wrongRegion == region {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Theme.rust)
                                .accessibilityHidden(true)
                        }
                    }
                    .foregroundStyle(foreground(for: region))
                    .padding(16)
                    .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                    .background(background(for: region))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .contentShape(Rectangle())
                }
                .buttonStyle(InteractionStudyPressStyle())
                .disabled(passComplete || isSettling)
                .accessibilityLabel(region.title)
                .accessibilityValue(regionAccessibilityValue(region))
                .accessibilityHint("Places the current Irish word in this region")
                .accessibilityIdentifier(
                    "interaction-study-coast-placement-region-\(region.rawValue)"
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Coast regions")
    }

    private func localRecovery(
        word: InteractionStudyWord,
        region: InteractionStudyCoastRegion
    ) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "arrow.uturn.left.circle.fill")
                .font(.title3)
                .foregroundStyle(Theme.rust)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("\(region.title) is not \(word.irish).")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text(correctiveCue(for: word))
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("interaction-study-coast-placement-feedback-incorrect")
    }

    private var bottomAction: some View {
        VStack(alignment: .leading, spacing: 10) {
            if voiceOverAdvancePending, let currentWord {
                Text("\(currentWord.irish) is placed.")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
            }

            Button(bottomActionTitle) {
                performBottomAction()
            }
            .font(.headline)
            .foregroundStyle(Theme.bg)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Theme.ink)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .buttonStyle(InteractionStudyPressStyle())
            .accessibilityIdentifier(bottomActionIdentifier)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity)
        .background(Theme.bg)
    }

    private var bottomActionTitle: String {
        if voiceOverAdvancePending {
            return round == words.count - 1 ? "Finish this pass" : "Next word"
        }
        if pass == .labelled {
            return "Remove the labels"
        }
        return "Again"
    }

    private var bottomActionIdentifier: String {
        if voiceOverAdvancePending {
            return "interaction-study-coast-placement-next"
        }
        if pass == .labelled {
            return "interaction-study-coast-placement-remove-labels"
        }
        return "interaction-study-coast-placement-restart"
    }

    private func performBottomAction() {
        if voiceOverAdvancePending {
            advance()
        } else if pass == .labelled {
            removeLabels()
        } else {
            restart()
        }
    }

    private func select(_ region: InteractionStudyCoastRegion) {
        guard let currentWord, !isSettling else { return }

        if region == currentWord.region {
            let isFinalWord = round == words.count - 1
            Haptics.chisel()
            withStudyAnimation {
                wrongRegion = nil
                placements[region] = currentWord.irish
                isSettling = !isFinalWord
                if isFinalWord {
                    round = words.count
                    passFinished = true
                    voiceOverAdvancePending = false
                }
            }
            if speech.canSpeak(currentWord.irish) {
                speech.speak(currentWord.irish)
            }
            prototypeAnnouncement("\(currentWord.irish), \(currentWord.english), placed.")

            if isFinalWord {
                Haptics.flourish()
                prototypeAnnouncement(
                    pass == .labelled
                        ? "Labelled coast pass complete."
                        : "Unlabelled coast pass complete."
                )
                return
            }

            if UIAccessibility.isVoiceOverRunning {
                voiceOverAdvancePending = true
                isSettling = false
            } else {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(motionReduced ? 80 : 460))
                    guard isSettling else { return }
                    advance()
                }
            }
        } else {
            Haptics.error()
            withStudyAnimation {
                wrongRegion = region
            }
            prototypeAnnouncement(
                "\(region.title) is not \(currentWord.irish). \(correctiveCue(for: currentWord))"
            )
        }
    }

    private func advance() {
        let nextRound = min(round + 1, words.count)
        let completesPass = nextRound == words.count
        withStudyAnimation {
            round = nextRound
            wrongRegion = nil
            isSettling = false
            voiceOverAdvancePending = false
            passFinished = completesPass
        }

        if completesPass {
            Haptics.flourish()
            prototypeAnnouncement(
                pass == .labelled
                    ? "Labelled coast pass complete."
                    : "Unlabelled coast pass complete."
            )
        }
    }

    private func removeLabels() {
        withStudyAnimation {
            pass = .unlabelled
            round = 0
            placements = [:]
            wrongRegion = nil
            isSettling = false
            voiceOverAdvancePending = false
            passFinished = false
        }
        prototypeAnnouncement("Region labels removed. Place the three words again.")
    }

    private func restart() {
        withStudyAnimation {
            pass = .labelled
            round = 0
            placements = [:]
            wrongRegion = nil
            isSettling = false
            voiceOverAdvancePending = false
            passFinished = false
        }
        prototypeAnnouncement("Coast Placement restarted with labels.")
    }

    private func play(_ word: InteractionStudyWord) {
        guard audioAvailable(for: word) else { return }
        speech.speak(word.irish)
    }

    private func audioAvailable(for word: InteractionStudyWord) -> Bool {
        !forcedAudioUnavailable && speech.canSpeak(word.irish)
    }

    private func correctiveCue(for word: InteractionStudyWord) -> String {
        switch word.region {
        case .openWater:
            "Farraige names the open sea beyond the shelter of the bay."
        case .shelteredBay:
            "Bá is the water gathered inside the coast."
        case .namedLand:
            "Áit names a place, not the water beside it."
        }
    }

    private func regionAccessibilityValue(_ region: InteractionStudyCoastRegion) -> String {
        var values: [String] = []
        if let word = placements[region] {
            values.append("\(word) placed")
        }
        if wrongRegion == region {
            values.append("incorrect for the current word")
        }
        return values.isEmpty ? "Empty" : values.joined(separator: ", ")
    }

    private func symbol(for region: InteractionStudyCoastRegion) -> String {
        switch region {
        case .openWater:
            "water.waves"
        case .shelteredBay:
            "drop.fill"
        case .namedLand:
            "mappin"
        }
    }

    private func foreground(for region: InteractionStudyCoastRegion) -> Color {
        region == .namedLand ? Theme.ink : Theme.salt
    }

    private func background(for region: InteractionStudyCoastRegion) -> Color {
        switch region {
        case .openWater:
            Theme.atlantic
        case .shelteredBay:
            Theme.storm
        case .namedLand:
            Theme.raised
        }
    }

    private func withStudyAnimation(_ changes: () -> Void) {
        withAnimation(motionReduced ? nil : .easeOut(duration: 0.22), changes)
    }
}

private struct CoastPlacementCanvas: View {
    let labelsVisible: Bool
    let placements: [InteractionStudyCoastRegion: String]
    let wrongRegion: InteractionStudyCoastRegion?
    let enabled: Bool
    let onSelect: (InteractionStudyCoastRegion) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CoastPlacementArtwork()

                regionButton(.openWater)
                    .frame(width: geometry.size.width * 0.34, height: 126)
                    .position(
                        x: geometry.size.width * 0.20,
                        y: geometry.size.height * 0.52
                    )

                regionButton(.shelteredBay)
                    .frame(width: geometry.size.width * 0.30, height: 112)
                    .position(
                        x: geometry.size.width * 0.56,
                        y: geometry.size.height * 0.66
                    )

                regionButton(.namedLand)
                    .frame(width: geometry.size.width * 0.34, height: 126)
                    .position(
                        x: geometry.size.width * 0.80,
                        y: geometry.size.height * 0.24
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func regionButton(_ region: InteractionStudyCoastRegion) -> some View {
        let word = placements[region]
        let isWrong = wrongRegion == region

        return Button {
            onSelect(region)
        } label: {
            VStack(spacing: 6) {
                if let word {
                    Text(word)
                        .font(.system(.title2, design: .serif, weight: .semibold))
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline)
                        .accessibilityHidden(true)
                } else if labelsVisible {
                    Text(region.title)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                } else {
                    Image(systemName: symbol(for: region))
                        .font(.title3)
                        .accessibilityHidden(true)
                }

                if isWrong {
                    Label("Try another region", systemImage: "xmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .multilineTextAlignment(.center)
                }
            }
            .foregroundStyle(foreground(for: region, isWrong: isWrong))
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(minWidth: 88, minHeight: 52)
            .background(labelBackground(for: region, isWrong: isWrong))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(InteractionStudyPressStyle())
        .disabled(!enabled)
        .accessibilityLabel(region.title)
        .accessibilityValue(
            word.map { "\($0) placed" }
                ?? (isWrong ? "Incorrect for the current word" : "Empty")
        )
        .accessibilityHint("Places the current Irish word in this coast region")
        .accessibilityIdentifier(
            "interaction-study-coast-placement-region-\(region.rawValue)"
        )
    }

    private func symbol(for region: InteractionStudyCoastRegion) -> String {
        switch region {
        case .openWater:
            "water.waves"
        case .shelteredBay:
            "drop.fill"
        case .namedLand:
            "mappin"
        }
    }

    private func foreground(
        for region: InteractionStudyCoastRegion,
        isWrong: Bool
    ) -> Color {
        if isWrong {
            return region == .namedLand ? Theme.rust : Theme.salt
        }
        return region == .namedLand ? Theme.ink : Theme.salt
    }

    private func labelBackground(
        for region: InteractionStudyCoastRegion,
        isWrong: Bool
    ) -> Color {
        if isWrong {
            return region == .namedLand ? Theme.rustTint : Theme.rust.opacity(0.78)
        }

        switch region {
        case .openWater:
            return Theme.atlantic.opacity(0.78)
        case .shelteredBay:
            return Theme.storm.opacity(0.9)
        case .namedLand:
            return Theme.raised.opacity(0.9)
        }
    }
}

private struct CoastPlacementArtwork: View {
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Theme.atlantic)
            )

            var land = Path()
            land.move(to: CGPoint(x: size.width * 0.66, y: 0))
            land.addLine(to: CGPoint(x: size.width, y: 0))
            land.addLine(to: CGPoint(x: size.width, y: size.height))
            land.addLine(to: CGPoint(x: size.width * 0.63, y: size.height))
            land.addCurve(
                to: CGPoint(x: size.width * 0.48, y: size.height * 0.72),
                control1: CGPoint(x: size.width * 0.55, y: size.height * 0.94),
                control2: CGPoint(x: size.width * 0.44, y: size.height * 0.88)
            )
            land.addCurve(
                to: CGPoint(x: size.width * 0.64, y: size.height * 0.56),
                control1: CGPoint(x: size.width * 0.50, y: size.height * 0.60),
                control2: CGPoint(x: size.width * 0.60, y: size.height * 0.64)
            )
            land.addCurve(
                to: CGPoint(x: size.width * 0.58, y: size.height * 0.34),
                control1: CGPoint(x: size.width * 0.68, y: size.height * 0.46),
                control2: CGPoint(x: size.width * 0.54, y: size.height * 0.43)
            )
            land.addCurve(
                to: CGPoint(x: size.width * 0.66, y: 0),
                control1: CGPoint(x: size.width * 0.68, y: size.height * 0.22),
                control2: CGPoint(x: size.width * 0.63, y: size.height * 0.12)
            )
            land.closeSubpath()

            context.fill(land, with: .color(Theme.raised))
            context.stroke(
                land,
                with: .color(Theme.stone),
                lineWidth: contrast == .increased ? 3 : 1.5
            )

            let islands = [
                CGRect(
                    x: size.width * 0.40,
                    y: size.height * 0.38,
                    width: size.width * 0.08,
                    height: size.height * 0.07
                ),
                CGRect(
                    x: size.width * 0.48,
                    y: size.height * 0.47,
                    width: size.width * 0.06,
                    height: size.height * 0.05
                ),
                CGRect(
                    x: size.width * 0.35,
                    y: size.height * 0.58,
                    width: size.width * 0.05,
                    height: size.height * 0.045
                ),
            ]

            for island in islands {
                context.fill(Path(ellipseIn: island), with: .color(Theme.stone))
            }

            for index in 0..<3 {
                let y = size.height * (0.22 + CGFloat(index) * 0.11)
                var wave = Path()
                wave.move(to: CGPoint(x: size.width * 0.08, y: y))
                wave.addCurve(
                    to: CGPoint(x: size.width * 0.31, y: y),
                    control1: CGPoint(x: size.width * 0.15, y: y - 7),
                    control2: CGPoint(x: size.width * 0.24, y: y + 7)
                )
                context.stroke(
                    wave,
                    with: .color(Theme.salt.opacity(0.18)),
                    lineWidth: 1.2
                )
            }
        }
        .background(Theme.atlantic)
    }
}
