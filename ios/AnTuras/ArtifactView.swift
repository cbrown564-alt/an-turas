import SwiftUI
import UIKit

// MARK: - Chapter artifact router
// Each chapter closes with a collectible register. Chapter 1: ogham stone.
// Chapter 3: Viking hack-silver arm-ring with a name notch. Chapter 2:
// illuminated vellum initial. The JSON page is chapter-blind — the app
// chooses the register from chapter number.

struct ArtifactView: View {
    var chapterN: Int = 1
    @EnvironmentObject var state: AppState

    var body: some View {
        switch ArtifactKind.forChapter(chapterN) {
        case .oghamStone:
            OghamArtifactView()
        case .illuminatedInitial:
            IlluminatedInitialArtifactView()
        case .hackSilver:
            HackSilverArtifactView()
        }
    }
}

private enum ArtifactKind {
    case oghamStone
    case illuminatedInitial
    case hackSilver

    static func forChapter(_ n: Int) -> ArtifactKind {
        switch n {
        case 2: return .illuminatedInitial
        case 3: return .hackSilver
        default: return .oghamStone
        }
    }
}

// MARK: - Chapter 1: ogham stone

private struct OghamArtifactView: View {
    @EnvironmentObject var state: AppState
    @State private var name = ""
    @State private var carvedName: String?
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

            ArtifactNameRow(name: $name, actionLabel: "Cuir chalc air — chalk it", action: carve)

            if let carved = carvedName {
                ArtifactStage {
                    OghamStoneView(word: carved, width: 160,
                                   carve: !handMode, ticks: true,
                                   handCarve: handMode,
                                   onCarved: { finishedCarving(carved) })
                        .id("\(carved)-\(handMode ? "hand" : "auto")")
                }

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
                    Text(oghamNotes(for: carved))
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(3)
                }

                ArtifactShareRow(image: shareImage,
                                 preview: "\(carved) — in ogham",
                                 label: "Roinn do chloch — share your stone",
                                 visible: stoneFinished)
            }
        }
        .onAppear { restoreSavedName() }
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
        shareImage = renderOghamShareCard(for: carved)
    }

    private func restoreSavedName() {
        guard name.isEmpty, !state.learnerName.isEmpty else { return }
        name = state.learnerName
        carvedName = state.learnerName
        handMode = false
        stoneFinished = true
        shareImage = renderOghamShareCard(for: state.learnerName)
    }
}

// MARK: - Chapter 2: illuminated initial

private struct IlluminatedInitialArtifactView: View {
    @EnvironmentObject var state: AppState
    @State private var name = ""
    @State private var gildedName: String?
    @State private var handMode = false
    @State private var initialFinished = false
    @State private var shareImage: UIImage?

    private var initialLetter: String {
        guard let gildedName else { return "?" }
        guard let first = gildedName.trimmingCharacters(in: .whitespaces).first else { return "?" }
        return String(first).uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Déantán · Artifact", color: Theme.lichen)
                Text("Do litir féin — your own initial")
                    .font(.system(size: 23, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.bottom, 2)
            Text("Murchadh leaves one blank initial on the vellum — yours. Corcra vine, gorm interlace, the first letter of whatever name you give him. He hands you the gold; the first stroke is yours.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(4)

            ArtifactNameRow(name: $name, actionLabel: "Leag an ór — lay the gold", action: gild)

            if let gilded = gildedName {
                ArtifactStage {
                    IlluminatedInitialView(name: gilded, width: 200,
                                           carve: !handMode, ticks: true,
                                           handCarve: handMode,
                                           onCarved: { finishedGilding(gilded) })
                        .id("\(gilded)-\(handMode ? "hand" : "auto")")
                }

                if handMode && !initialFinished {
                    Text("Tarraing an ór síos — drag the gold down the letter, stroke by stroke. Every chalk line you cross, you gild.")
                        .font(.system(size: 13))
                        .italic()
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                } else {
                    Text("\(initialLetter) — the first letter of \(gilded), glowing on vellum")
                        .font(.system(size: 13, design: .serif))
                        .italic()
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    Text("Ní neart go cur le chéile — many hands, one book · Cluain Mhic Nóis.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkFaint)
                        .lineSpacing(3)
                }

                ArtifactShareRow(image: shareImage,
                                 preview: "\(initialLetter) — illuminated initial",
                                 label: "Roinn do litir — share your initial",
                                 visible: initialFinished)
            }
        }
        .onAppear { restoreSavedName() }
    }

    private func gild() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Haptics.tap()
        withAnimation(Motion.settle) {
            gildedName = trimmed
            handMode = true
            initialFinished = false
            shareImage = nil
        }
    }

    private func finishedGilding(_ gilded: String) {
        Haptics.flourish()
        withAnimation(Motion.pop) { initialFinished = true }
        shareImage = renderIlluminatedShareCard(for: gilded)
    }

    private func restoreSavedName() {
        guard name.isEmpty, !state.learnerName.isEmpty else { return }
        name = state.learnerName
        gildedName = state.learnerName
        handMode = false
        initialFinished = true
        shareImage = renderIlluminatedShareCard(for: state.learnerName)
    }
}

// MARK: - Chapter 3: hack-silver arm-ring

private struct HackSilverArtifactView: View {
    @EnvironmentObject var state: AppState
    @State private var name = ""
    @State private var markedName: String?
    @State private var handMode = false
    @State private var ringFinished = false
    @State private var shareImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Déantán · Artifact", color: Theme.lichen)
                Text("Do fháinne féin — your own ring")
                    .font(.system(size: 23, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.bottom, 2)
            Text("Sigur cuts the ring by weight, not as a gift — silver measured on the scales, trust sealed by handshake. He hands you the shears for one mark: a tiny notch bearing your name, your deal, your weight in **airgead**.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(4)

            ArtifactNameRow(name: $name, actionLabel: "Marcáil — mark it", action: mark)

            if let marked = markedName {
                ArtifactStage {
                    ArmRingView(name: marked, width: 220,
                                carve: !handMode, ticks: true,
                                handCarve: handMode,
                                onCarved: { finishedMarking(marked) })
                        .id("\(marked)-\(handMode ? "hand" : "auto")")
                }

                if handMode && !ringFinished {
                    Text("Tarraing na deimhse ón mbos — drag the shears from the boss toward the ring. Every chalk line you cross, you cut.")
                        .font(.system(size: 13))
                        .italic()
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Is le \(marked) an fáinne seo — this ring belongs to \(marked)")
                        .font(.system(size: 13, design: .serif))
                        .italic()
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    Text("Hack-silver: cut by weight at Dubhlinn — the Norse **longphort** that became Baile Átha Cliath.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkFaint)
                        .lineSpacing(3)
                }

                ArtifactShareRow(image: shareImage,
                                 preview: "\(marked) — on hack-silver",
                                 label: "Roinn do fháinne — share your ring",
                                 visible: ringFinished)
            }
        }
        .onAppear { restoreSavedName() }
    }

    private func mark() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Haptics.tap()
        withAnimation(Motion.settle) {
            markedName = trimmed
            handMode = true
            ringFinished = false
            shareImage = nil
        }
    }

    private func finishedMarking(_ marked: String) {
        Haptics.flourish()
        withAnimation(Motion.pop) { ringFinished = true }
        shareImage = renderHackSilverShareCard(for: marked)
    }

    private func restoreSavedName() {
        guard name.isEmpty, !state.learnerName.isEmpty else { return }
        name = state.learnerName
        markedName = state.learnerName
        handMode = false
        ringFinished = true
        shareImage = renderHackSilverShareCard(for: state.learnerName)
    }
}

// MARK: - Shared artifact furniture

private struct ArtifactNameRow: View {
    @Binding var name: String
    let actionLabel: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("Your name", text: $name)
                .font(.system(size: 17, design: .serif))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit(action)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line, lineWidth: 1))
            Button(actionLabel, action: action)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.bg)
                .padding(.vertical, 13)
                .padding(.horizontal, 16)
                .background(Theme.ink)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .buttonStyle(CarvePress())
        }
        .padding(.top, 4)
    }
}

private struct ArtifactStage<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack {
            Spacer()
            content()
            Spacer()
        }
        .transition(.offset(y: 14).combined(with: .opacity))
    }
}

private struct ArtifactShareRow: View {
    let image: UIImage?
    let preview: String
    let label: String
    let visible: Bool

    var body: some View {
        if visible, let image {
            HStack {
                Spacer()
                ShareLink(
                    item: Image(uiImage: image),
                    preview: SharePreview(preview, image: Image(uiImage: image))) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .semibold))
                        Text(label)
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

private func oghamNotes(for carved: String) -> String {
    let notes = Ogham.letters(for: carved).notes
    if notes.isEmpty {
        return "Every letter of your name existed in the ogham alphabet — no substitutions needed."
    }
    return "Carver's notes: " + notes.joined(separator: " · ")
        + ". Ogham was cut for Primitive Irish — letters it never had borrow later signs."
}

@MainActor
private func renderOghamShareCard(for carved: String) -> UIImage? {
    let renderer = ImageRenderer(content:
        OghamShareCard(name: carved)
            .environment(\.colorScheme, .light))
    renderer.scale = 3
    return renderer.uiImage
}

@MainActor
private func renderHackSilverShareCard(for marked: String) -> UIImage? {
    let renderer = ImageRenderer(content:
        HackSilverShareCard(name: marked)
            .environment(\.colorScheme, .light))
    renderer.scale = 3
    return renderer.uiImage
}

@MainActor
private func renderIlluminatedShareCard(for gilded: String) -> UIImage? {
    let renderer = ImageRenderer(content:
        IlluminatedShareCard(name: gilded)
            .environment(\.colorScheme, .light))
    renderer.scale = 3
    return renderer.uiImage
}

// MARK: - Share cards

private struct OghamShareCard: View {
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

private struct HackSilverShareCard: View {
    let name: String

    var body: some View {
        VStack(spacing: 20) {
            Text("AN TURAS")
                .font(.system(size: 12, weight: .semibold))
                .kerning(2.2)
                .foregroundStyle(Theme.inkFaint)
            ArmRingView(name: name, width: 240)
            VStack(spacing: 6) {
                Text(name)
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text("my name on hack-silver — Is le \(name) an fáinne seo")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                Text("Dubhlinn · the black pool · c. 850 AD")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .padding(44)
        .frame(width: 480)
        .background(Theme.bg)
    }
}

private struct IlluminatedShareCard: View {
    let name: String

    private var initialLetter: String {
        guard let first = name.trimmingCharacters(in: .whitespaces).first else { return "?" }
        return String(first).uppercased()
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("AN TURAS")
                .font(.system(size: 12, weight: .semibold))
                .kerning(2.2)
                .foregroundStyle(Theme.inkFaint)
            IlluminatedInitialView(name: name, width: 220)
            VStack(spacing: 6) {
                Text(initialLetter)
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text("my initial illuminated — the first letter of \(name)")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                Text("Cluain Mhic Nóis · island of saints · c. 780 AD")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .padding(44)
        .frame(width: 480)
        .background(Theme.bg)
    }
}
