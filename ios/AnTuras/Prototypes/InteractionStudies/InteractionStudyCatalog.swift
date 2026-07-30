import SwiftUI

enum InteractionStudyID: String, CaseIterable, Identifiable, Hashable {
    case soundMatch = "sound-match"
    case sentenceFlow = "sentence-flow"
    case coastPlacement = "coast-placement"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .soundMatch:
            "Sound Match"
        case .sentenceFlow:
            "Sentence Flow"
        case .coastPlacement:
            "Coast Placement"
        }
    }

    var prompt: String {
        switch self {
        case .soundMatch:
            "Can sound, one prompt and three large targets make recall feel immediate?"
        case .sentenceFlow:
            "Can every correct touch build the Irish line without a separate Check button?"
        case .coastPlacement:
            "Can the words settle into a coast model, then survive after its labels disappear?"
        }
    }

    var shortSummary: String {
        switch self {
        case .soundMatch:
            "Hear one coast word, choose its meaning and repair a miss in place."
        case .sentenceFlow:
            "Tap four words into one sentence track as the structural cues recede."
        case .coastPlacement:
            "Place sea, bay and place on the coast, then repeat against the unlabeled shape."
        }
    }

    var symbol: String {
        switch self {
        case .soundMatch:
            "waveform"
        case .sentenceFlow:
            "rectangle.connected.to.line.below"
        case .coastPlacement:
            "water.waves"
        }
    }
}

struct InteractionStudyPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var motionReduced: Bool {
        reduceMotion
            || ProcessInfo.processInfo.arguments.contains("--interaction-study-reduce-motion")
            || ProcessInfo.processInfo.arguments.contains("--prototype-reduce-motion")
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !motionReduced ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.78 : 1)
            .animation(
                motionReduced ? nil : .easeOut(duration: 0.14),
                value: configuration.isPressed
            )
    }
}
