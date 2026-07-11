import SwiftUI

// MARK: - Living atlas prototype shell

/// The new product vessel. The legacy lesson path remains available with
/// `--legacy`; the default launch now proves the island -> dossier -> evidence ->
/// Irish -> collection loop described in EXPANSIVE-INTERFACE-VISION.md.
struct AtlasPrototypeView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var atlas = AtlasPrototypeModel()
    @State private var path: [AtlasRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            TabView(selection: $atlas.tab) {
                IslandAtlasView(
                    onOpenMayo: { path.append(.mayoDossier) },
                    onOpenCounty: { path.append(.county($0)) },
                    onOpenFieldNote: { path.append(.fieldNote) }
                )
                .tag(AtlasTab.island)
                .tabItem { Label("An tOileán", systemImage: "map") }

                CurrentStoryView(
                    onOpenStory: { path.append(.grainneStory) },
                    onOpenDossier: { path.append(.mayoDossier) }
                )
                .tag(AtlasTab.story)
                .tabItem { Label("An Scéal", systemImage: "book.pages") }

                AtlasCollectionView(
                    onOpenEvidence: { path.append(.evidence) },
                    onOpenFieldNote: { path.append(.fieldNote) }
                )
                .tag(AtlasTab.collection)
                .tabItem { Label("An Cnuasach", systemImage: "square.grid.2x2") }

                AtlasReturnView(onOpenEvidence: { path.append(.evidence) })
                    .tag(AtlasTab.returning)
                    .tabItem { Label("Ar Ais", systemImage: "arrow.uturn.backward") }
            }
            .tint(Theme.moss)
            .toolbarBackground(Theme.bg, for: .tabBar)
            .navigationDestination(for: AtlasRoute.self) { route in
                destination(route)
            }
        }
        .environmentObject(atlas)
        .background(Theme.bg.ignoresSafeArea())
        .onChange(of: atlas.tab) { _, _ in
            if !path.isEmpty { path.removeAll() }
        }
        .onChange(of: atlas.learnerName) { _, name in
            if !name.isEmpty { appState.learnerName = name }
        }
        .onAppear {
            if atlas.learnerName.isEmpty { atlas.learnerName = appState.learnerName }
        }
    }

    @ViewBuilder
    private func destination(_ route: AtlasRoute) -> some View {
        switch route {
        case .mayoDossier:
            MayoDossierView(
                onMeetGrainne: { path.append(.grainnePerson) },
                onBegin: { path.append(.grainneStory) },
                onFieldNote: { path.append(.fieldNote) }
            )
        case .grainnePerson:
            GrainnePersonView(onBegin: { path.append(.grainneStory) })
        case .grainneStory:
            GrainneStoryView(
                onInspectEvidence: { path.append(.evidence) },
                onComplete: {
                    atlas.completeStory()
                    path.removeAll()
                    atlas.tab = .collection
                }
            )
        case .evidence:
            PetitionEvidenceView()
        case .fieldNote:
            BreastaghFieldNoteView()
        case .county(let name):
            AtlasCountyPreviewView(countyName: name)
        }
    }
}

enum AtlasTab: Hashable {
    case island, story, collection, returning
}

enum AtlasRoute: Hashable {
    case mayoDossier
    case grainnePerson
    case grainneStory
    case evidence
    case fieldNote
    case county(String)
}

@MainActor
final class AtlasPrototypeModel: ObservableObject {
    @Published var tab: AtlasTab = .island
    @Published var learnerName = ""
    @Published var evidenceInspected = false
    @Published var storyCompleted = false
    @Published var fieldNoteVisited = false
    @Published var returnAnswered = false

    let carriedWords = [
        AtlasWord(ga: "Is mise…", en: "I am…", sound: "iss mish-eh", anchor: "The first response in Gráinne’s Mayo story"),
        AtlasWord(ga: "mé", en: "me / I", sound: "may", anchor: "Naming yourself beside the petition"),
        AtlasWord(ga: "ainm", en: "name", sound: "an-im", anchor: "Names in the state record"),
        AtlasWord(ga: "as", en: "from", sound: "ass", anchor: "Saying where you are from"),
        AtlasWord(ga: "fiafraigh", en: "ask", sound: "fee-ah-ree", anchor: "The question at the heart of the petition")
    ]

    func completeStory() {
        evidenceInspected = true
        storyCompleted = true
        Haptics.flourish()
    }
}

struct AtlasWord: Identifiable {
    let ga: String
    let en: String
    let sound: String
    let anchor: String
    var id: String { ga }
}

// MARK: - Shared atlas language

enum EvidenceCertainty: String, CaseIterable {
    case documented = "DOCUMENTED"
    case material = "MATERIAL EVIDENCE"
    case later = "LATER ACCOUNT"
    case tradition = "TRADITION"
    case disputed = "DISPUTED"
    case reconstruction = "RECONSTRUCTION"
    case unknown = "UNKNOWN"

    var color: Color {
        switch self {
        case .documented: return Theme.atlasGreen
        case .material: return Theme.lichen
        case .later: return Color(light: 0x476B7A, dark: 0x8BB8C8)
        case .tradition: return Color(light: 0x75568B, dark: 0xBDA0CF)
        case .disputed: return Theme.rust
        case .reconstruction: return Theme.inkFaint
        case .unknown: return Theme.stone
        }
    }
}

struct CertaintyPill: View {
    let certainty: EvidenceCertainty
    var body: some View {
        Text(certainty.rawValue)
            .font(.system(size: 9.5, weight: .bold))
            .kerning(1.05)
            .foregroundStyle(certainty.color)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(certainty.color.opacity(0.11))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(certainty.color.opacity(0.45), lineWidth: 0.8))
    }
}

struct AtlasScreenHeader: View {
    let eyebrow: String
    let title: String
    let detail: String?

    init(_ eyebrow: String, _ title: String, detail: String? = nil) {
        self.eyebrow = eyebrow
        self.title = title
        self.detail = detail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Eyebrow(text: eyebrow)
            Text(title)
                .font(.system(size: 31, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            if let detail {
                Text(detail)
                    .font(.system(size: 15.5))
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AtlasCard<Content: View>: View {
    var accent: Color = Theme.line
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.raised)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accent.opacity(0.45), lineWidth: 0.8))
    }
}

struct AtlasRule: View {
    var body: some View {
        Rectangle().fill(Theme.line).frame(height: 0.7)
    }
}

struct AtlasAudioLine: View {
    let ga: String
    let en: String
    let sound: String
    @State private var heard = false

    private var canPlay: Bool { SpeechService.shared.canSpeak(ga) }

    var body: some View {
        Button {
            guard canPlay else { return }
            Haptics.tap()
            SpeechService.shared.speak(ga)
            withAnimation(Motion.pop) { heard = true }
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(ga)
                        .font(.system(size: 31, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.moss)
                    Spacer()
                    Image(systemName: canPlay ? (heard ? "speaker.wave.2.fill" : "speaker.wave.2") : "waveform.slash")
                        .foregroundStyle(canPlay ? Theme.moss : Theme.inkFaint)
                }
                Text(sound)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.inkFaint)
                Text(en)
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(Theme.inkSoft)
                if !canPlay {
                    Text("native-speaker audio pending review")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(Theme.rust)
                }
            }
            .padding(18)
            .background(Theme.mossTint)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.moss.opacity(0.45)).frame(height: 1)
                    .padding(.horizontal, 18)
            }
        }
        .buttonStyle(CarvePress())
        .disabled(!canPlay)
        .accessibilityLabel("Hear \(ga), meaning \(en)")
    }
}

struct SourceFooter: View {
    var compact = false
    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "building.columns")
                .foregroundStyle(Theme.inkFaint)
            Text(compact
                 ? "Source starting point: NLI record MS_UR_010761. Prototype copy; historian and rights review pending."
                 : "Source starting point · National Library of Ireland record MS_UR_010761. This explanatory prototype does not reproduce the manuscript. Final selection, transcription and context require historian and rights review.")
                .font(.system(size: compact ? 11.5 : 12.5))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(3)
        }
        .padding(13)
        .background(Theme.sunk)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
