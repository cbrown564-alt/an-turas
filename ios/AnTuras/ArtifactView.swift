import SwiftUI
import UIKit

// The chapter's closing artifact: the learner's name carved in ogham — by
// their own hand. Dáire chalks the guides; every stroke is theirs to cut.
// Once cut, the stone can leave the app as an image: the first thing a
// learner can show someone else, and the chapter's thesis in one card —
// the words outlast the app that carved them.
// Also shown standalone from the map as "Do Mhúsaem" (already carved).

struct ArtifactView: View {
    @EnvironmentObject var state: AppState
    @State private var name = ""
    @State private var carvedName: String?
    /// True while the learner still owes the stone their own strokes.
    @State private var handMode = false
    @State private var stoneFinished = false
    @State private var shareImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Déantán · Artifact", color: Theme.lichen)
                Text("Do chloch féin — your own stone")
                    .font(.system(size: 23, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.bottom, 2)
            Text("Dáire owes you a wage for the week. He takes a small slab of the same grey stone, chalks the guide-marks for whatever name you give him — and hands you the chisel. Your name, your strokes.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(4)

            HStack(spacing: 8) {
                TextField("Your name", text: $name)
                    .font(.system(size: 17, design: .serif))
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit { carve() }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Theme.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line, lineWidth: 1))
                Button("Cuir chalc air — chalk it") { carve() }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.bg)
                    .padding(.vertical, 13)
                    .padding(.horizontal, 16)
                    .background(Theme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .buttonStyle(CarvePress())
            }
            .padding(.top, 4)

            if let carved = carvedName {
                HStack {
                    Spacer()
                    // The payoff of the chapter: your own name, cut stroke by
                    // stroke — by the thumb that's been learning all week.
                    OghamStoneView(word: carved, width: 160,
                                   carve: !handMode, ticks: true,
                                   handCarve: handMode,
                                   onCarved: { finishedCarving(carved) })
                        .id("\(carved)-\(handMode ? "hand" : "auto")")
                    Spacer()
                }
                .transition(.offset(y: 14).combined(with: .opacity))

                if handMode && !stoneFinished {
                    Text("Leag do mhéar ag an mbun — set your finger at the base and draw it up the edge, the direction ogham is read. Every chalk mark you pass, you cut.")
                        .font(.system(size: 13))
                        .italic()
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                } else {
                    Text("\(carved.uppercased()) — read upward from the base")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkFaint)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    Text(notesText(for: carved))
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(3)
                }

                if stoneFinished, let shareImage {
                    HStack {
                        Spacer()
                        ShareLink(
                            item: Image(uiImage: shareImage),
                            preview: SharePreview("\(carved) — in ogham",
                                                  image: Image(uiImage: shareImage))) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Roinn do chloch — share your stone")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(Theme.bg)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 18)
                            .background(Theme.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(CarvePress())
                        Spacer()
                    }
                    .padding(.top, 6)
                    .transition(.offset(y: 10).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            // Museum revisit: the stone was cut in-session; it stands finished.
            if name.isEmpty, !state.learnerName.isEmpty {
                name = state.learnerName
                carvedName = state.learnerName
                handMode = false
                stoneFinished = true
                renderShareCard(for: state.learnerName)
            }
        }
    }

    private func carve() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Haptics.tap()
        withAnimation(Motion.settle) {
            carvedName = trimmed
            handMode = true
            stoneFinished = false
            shareImage = nil
        }
    }

    private func finishedCarving(_ carved: String) {
        Haptics.flourish()
        withAnimation(Motion.pop) { stoneFinished = true }
        renderShareCard(for: carved)
    }

    /// The stone as a card that can leave the app. Always rendered in the
    /// limestone day-palette: the share is a photograph of the stone in
    /// daylight, whatever theme the app happens to be in.
    private func renderShareCard(for carved: String) {
        let renderer = ImageRenderer(content:
            ShareCard(name: carved)
                .environment(\.colorScheme, .light))
        renderer.scale = 3
        shareImage = renderer.uiImage
    }

    private func notesText(for carved: String) -> String {
        let notes = Ogham.letters(for: carved).notes
        if notes.isEmpty {
            return "Every letter of your name existed in the ogham alphabet — no substitutions needed."
        }
        return "Carver's notes: " + notes.joined(separator: " · ")
            + ". Ogham was cut for Primitive Irish — letters it never had borrow later signs."
    }
}

// MARK: - The card that travels

private struct ShareCard: View {
    let name: String

    var body: some View {
        VStack(spacing: 20) {
            Text("AN TURAS")
                .font(.system(size: 12, weight: .semibold))
                .kerning(2.2)
                .foregroundStyle(Theme.inkFaint)
            OghamStoneView(word: name, width: 190)
            VStack(spacing: 6) {
                Text(name)
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text("my name in ogham — read upward from the base")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
                Text("the first written Irish · c. 400 AD")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .padding(44)
        .frame(width: 480)
        .background(Theme.bg)
    }
}
