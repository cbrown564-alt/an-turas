import SwiftUI

// MARK: - The turn: the scene pauses on your line.
// Lead-in beats, then two ways to speak — both acceptable Irish, chalked in
// dashed outline because they are not yet said. Choosing one carves it into
// the dialogue as your line (who: TUSA) and the conversation answers.
// No fail state: the choice is social, and the scene acknowledges each
// reply differently. Chalk before carve, applied to speech.

struct TurnView: View {
    let block: TurnBlock
    @Binding var activeGloss: Gloss?
    let onSolved: () -> Void

    @EnvironmentObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var chosen: TurnReply?

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            if let place = block.place {
                Slugline(text: place)
                    .padding(.bottom, 6)
                    .modifier(RiseIn(order: 0, reduceMotion: reduceMotion))
            }
            ForEach(Array(block.beats.enumerated()), id: \.offset) { index, beat in
                BeatRow(beat: beat, activeGloss: $activeGloss)
                    .modifier(RiseIn(order: index + (block.place == nil ? 0 : 1),
                                     reduceMotion: reduceMotion))
            }

            if let chosen {
                spokenLine(chosen)
                ForEach(Array(chosen.reaction.enumerated()), id: \.offset) { index, beat in
                    BeatRow(beat: beat, activeGloss: $activeGloss)
                        .modifier(RiseIn(order: index + 1, reduceMotion: reduceMotion))
                }
            } else {
                choiceBlock
                    .modifier(RiseIn(order: block.beats.count + 1,
                                     reduceMotion: reduceMotion))
            }
        }
    }

    // MARK: Your options, in chalk

    private var choiceBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let cue = block.cue {
                Text(cue)
                    .font(.system(size: 15, design: .serif))
                    .italic()
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(4)
                    .padding(.bottom, 2)
            }
            EditorialContextLabel(text: "Do líne — your line", color: Theme.moss)
            ForEach(block.replies) { reply in
                replyChip(reply)
            }
        }
        .padding(.top, 6)
    }

    private func replyChip(_ reply: TurnReply) -> some View {
        Button {
            choose(reply)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text("“\(fill(reply.s))”")
                    .font(.system(size: 19, weight: .medium, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(4)
                Text(fill(reply.g))
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.inkFaint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 13)
            .padding(.horizontal, 15)
            // Chalk, not stone: dashed guide-lines waiting for the chisel.
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.stone,
                            style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
            .contentShape(Rectangle())
        }
        .buttonStyle(CarvePress())
    }

    // MARK: The line, carved

    private func spokenLine(_ reply: TurnReply) -> some View {
        SpeechBeatView(beat: SpeechBeat(
            s: fill(reply.s),
            who: "Tusa — you",
            g: fill(reply.g),
            ph: reply.ph))
        { activeGloss = Gloss(t: fill(reply.s), g: fill(reply.g), s: reply.ph) }
            .transition(.opacity.combined(with: .offset(y: 8)))
    }

    private func choose(_ reply: TurnReply) {
        guard chosen == nil else { return }
        Haptics.chisel()
        withAnimation(Motion.settle) { chosen = reply }
        onSolved()
    }

    // MARK: {name}

    private func fill(_ text: String) -> String {
        text.replacingOccurrences(
            of: "{name}",
            with: state.learnerName.isEmpty ? "…" : state.learnerName)
    }
}
