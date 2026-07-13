import SwiftUI

// MARK: - Living atlas prototype shell

/// The new product vessel. A first-time learner gets one authored encounter before
/// the wider atlas navigation is revealed. The legacy lesson path remains available
/// with `--legacy`.
struct AtlasPrototypeView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var atlas = AtlasPrototypeModel()
    @State private var path: [AtlasRoute] = []
    @State private var restoredProgress = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if atlas.hasOpenedAtlas {
                    atlasTabs
                } else {
                    FirstRunIslandView(
                        onBegin: beginStory,
                        onOpenName: { path.append(.personalSearch(.name)) },
                        onOpenPlace: { path.append(.personalSearch(.place)) }
                    )
                }
            }
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
            if !name.isEmpty, appState.learnerName != name {
                appState.learnerName = name
            }
        }
        .onChange(of: atlas.progressSnapshot) { _, progress in
            guard restoredProgress, appState.atlasProgress != progress else { return }
            appState.atlasProgress = progress
        }
        .onAppear {
            guard !restoredProgress else { return }
            atlas.restore(appState.atlasProgress)
            restoredProgress = true
            if atlas.learnerName.isEmpty { atlas.learnerName = appState.learnerName }
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if let flag = args.firstIndex(of: "--completed-story-beat"),
               args.indices.contains(flag + 1),
               let completedBeat = Int(args[flag + 1]),
               (0..<18).contains(completedBeat) {
                atlas.completedStoryBeats = [completedBeat]
            }
            if let flag = args.firstIndex(of: "--grainne-story-step"),
               args.indices.contains(flag + 1),
               let step = Int(args[flag + 1]) {
                atlas.storyInProgress = true
                atlas.storyStep = min(max(step, 0), 17)
                path = [.grainneStory]
            } else if args.contains("--mayo-dossier") {
                atlas.hasOpenedAtlas = true
                path = [.mayoDossier]
            } else if args.contains("--grainne-person") {
                atlas.hasOpenedAtlas = true
                path = [.grainnePerson]
            } else if args.contains("--first-takeaway") {
                atlas.storyCompleted = true
                path = [.firstTakeaway]
            } else if args.contains("--atlas-open") {
                atlas.hasOpenedAtlas = true
            } else if let flag = args.firstIndex(of: "--personal"),
               args.indices.contains(flag + 1),
               PersonalAtlasLoader.subject(id: args[flag + 1]) != nil {
                atlas.hasOpenedAtlas = true
                path = [.personalSubject(args[flag + 1])]
            } else if args.contains("--personal-search") {
                atlas.hasOpenedAtlas = true
                path = [.personalSearch(.either)]
            }
            #endif
            if path.isEmpty, atlas.storyCompleted, !atlas.hasOpenedAtlas {
                path = [.firstTakeaway]
            } else if path.isEmpty, atlas.storyInProgress {
                path = [.grainneStory]
            }
        }
        .onOpenURL { url in
            guard let id = PersonalAtlasDeepLink.subjectID(from: url),
                  PersonalAtlasLoader.subject(id: id) != nil else { return }
            atlas.hasOpenedAtlas = true
            path = [.personalSubject(id)]
        }
    }

    private var atlasTabs: some View {
        TabView(selection: $atlas.tab) {
            IslandAtlasView(
                onOpenMayo: { path.append(.mayoDossier) },
                onOpenCounty: { path.append(.county($0)) },
                onOpenFieldNote: { path.append(.fieldNote) },
                onOpenPersonalSearch: { path.append(.personalSearch(.either)) },
                onOpenName: { path.append(.personalSearch(.name)) },
                onOpenPlace: { path.append(.personalSearch(.place)) }
            )
            .tag(AtlasTab.island)
            .tabItem { Label("An tOileán", systemImage: "map") }

            CurrentStoryView(
                onOpenStory: beginStory,
                onOpenDossier: { path.append(.mayoDossier) }
            )
            .tag(AtlasTab.story)
            .tabItem { Label("An Scéal", systemImage: "book.pages") }

            AtlasCollectionView(
                onOpenEvidence: { path.append(.evidence) },
                onOpenFieldNote: { path.append(.fieldNote) },
                onOpenPersonalSubject: { path.append(.personalSubject($0)) },
                onOpenPersonalSearch: { path.append(.personalSearch(.either)) }
            )
            .tag(AtlasTab.collection)
            .tabItem { Label("An Cnuasach", systemImage: "square.grid.2x2") }

            AtlasReturnView(onOpenEvidence: { path.append(.evidence) })
                .tag(AtlasTab.returning)
                .tabItem { Label("Ar Ais", systemImage: "arrow.uturn.backward") }
        }
        .tint(Theme.moss)
        .toolbarBackground(Theme.bg, for: .tabBar)
    }

    @ViewBuilder
    private func destination(_ route: AtlasRoute) -> some View {
        switch route {
        case .mayoDossier:
            MayoDossierView(
                onMeetGrainne: { path.append(.grainnePerson) },
                onBegin: beginStory,
                onFieldNote: { path.append(.fieldNote) },
                onOpenEvidence: { path.append(.evidence) }
            )
        case .grainnePerson:
            GrainnePersonView(
                onBegin: beginStory,
                onOpenEvidence: { path.append(.evidence) }
            )
        case .grainneStory:
            GrainneStoryView(
                onOpenEvidence: { path.append(.evidence) },
                onComplete: {
                    let atlasWasOpen = atlas.hasOpenedAtlas
                    atlas.completeStory()
                    path = atlasWasOpen ? [] : [.firstTakeaway]
                }
            )
        case .firstTakeaway:
            FirstEncounterTakeawayView {
                atlas.hasOpenedAtlas = true
                atlas.storyInProgress = false
                atlas.tab = .island
                atlas.shouldFocusOpeningRoad = true
                path.removeAll()
            }
        case .evidence:
            PetitionEvidenceView()
        case .fieldNote:
            BreastaghFieldNoteView()
        case .county(let name):
            AtlasCountyPreviewView(countyName: name)
        case .personalSearch(let focus):
            PersonalAtlasSearchView(focus: focus) { subjectId in
                path.append(.personalSubject(subjectId))
            }
        case .personalSubject(let id):
            PersonalSubjectResultView(subjectId: id) { handoff in
                appendHandoff(handoff)
            }
        }
    }

    private func appendHandoff(_ routeName: String) {
        switch routeName {
        case "mayoDossier":
            path.append(.mayoDossier)
        case "grainnePerson":
            path.append(.grainnePerson)
        case "grainneStory":
            beginStory()
        default:
            break
        }
    }

    private func beginStory() {
        atlas.storyInProgress = true
        path.append(.grainneStory)
    }
}

enum AtlasTab: Hashable {
    case island, story, collection, returning
}

enum AtlasRoute: Hashable {
    case mayoDossier
    case grainnePerson
    case grainneStory
    case firstTakeaway
    case evidence
    case fieldNote
    case county(String)
    case personalSearch(PersonalSearchFocus)
    case personalSubject(String)
}

@MainActor
final class AtlasPrototypeModel: ObservableObject {
    @Published var tab: AtlasTab = .island
    @Published var hasOpenedAtlas = false
    @Published var learnerName = ""
    @Published var evidenceInspected = false
    @Published var storyCompleted = false
    @Published var fieldNoteVisited = false
    @Published var returnAnswered = false
    @Published var storyInProgress = false
    @Published var storyStep = 0
    @Published var storyFoundName = false
    @Published var completedStoryBeats: [Int] = []
    @Published var shouldFocusOpeningRoad = false

    let carriedWords = [
        AtlasWord(ga: "farraige", en: "sea", sound: "far-ig-eh", anchor: "Clew Bay as a maritime world"),
        AtlasWord(ga: "bá", en: "bay", sound: "baw", anchor: "The geography that opens Mayo"),
        AtlasWord(ga: "long", en: "ship", sound: "lung", anchor: "The fleet as livelihood and reach"),
        AtlasWord(ga: "áit", en: "place", sound: "awtch", anchor: "A place that matters"),
        AtlasWord(ga: "as", en: "from", sound: "ass", anchor: "Origin on the Mayo coast"),
        AtlasWord(ga: "caisleán", en: "castle", sound: "kash-lawn", anchor: "Rockfleet at the tide line"),
        AtlasWord(ga: "teaghlach", en: "family", sound: "chai-lukh", anchor: "Household as authority"),
        AtlasWord(ga: "mac", en: "son", sound: "mock", anchor: "Tibbott held as part of the crisis"),
        AtlasWord(ga: "bean", en: "woman", sound: "ban", anchor: "A woman recognised as a leader"),
        AtlasWord(ga: "caill", en: "lose", sound: "kyle", anchor: "Livelihood and safety under pressure"),
        AtlasWord(ga: "deartháir", en: "brother", sound: "djar-hawr", anchor: "Donal named among the stakes"),
        AtlasWord(ga: "iarr", en: "ask", sound: "eer", anchor: "The petition as remaining action"),
        AtlasWord(ga: "téigh", en: "go", sound: "tay", anchor: "The decision to go to London"),
        AtlasWord(ga: "ainm", en: "name", sound: "an-im", anchor: "Her name in the September draft"),
        AtlasWord(ga: "mise", en: "me / I", sound: "mish-eh", anchor: "Identifying yourself without borrowing her story"),
        AtlasWord(ga: "tar", en: "come", sound: "tar", anchor: "Arrival into the court record"),
        AtlasWord(ga: "freagair", en: "answer", sound: "frag-ir", anchor: "The royal answer"),
        AtlasWord(ga: "tabhair", en: "give", sound: "toor", anchor: "Relief ordered and withheld"),
        AtlasWord(ga: "arís", en: "again", sound: "uh-reesh", anchor: "The unfinished second asking"),
        AtlasWord(ga: "cósta", en: "coast", sound: "koh-sta", anchor: "The present shore that closes Mayo")
    ]

    func completeStory() {
        evidenceInspected = true
        storyCompleted = true
        storyInProgress = false
        Haptics.flourish()
    }

    var progressSnapshot: AppState.AtlasProgress {
        AppState.AtlasProgress(
            hasOpenedAtlas: hasOpenedAtlas,
            evidenceInspected: evidenceInspected,
            storyCompleted: storyCompleted,
            fieldNoteVisited: fieldNoteVisited,
            returnAnswered: returnAnswered,
            storyInProgress: storyInProgress,
            storyStep: storyStep,
            storyFoundName: storyFoundName,
            storyArcVersion: 2,
            completedStoryBeats: completedStoryBeats
        )
    }

    func restore(_ progress: AppState.AtlasProgress) {
        hasOpenedAtlas = progress.hasOpenedAtlas
        evidenceInspected = progress.evidenceInspected
        storyCompleted = progress.storyCompleted
        fieldNoteVisited = progress.fieldNoteVisited
        returnAnswered = progress.returnAnswered
        storyInProgress = progress.storyInProgress
        if progress.storyArcVersion < 2, progress.storyInProgress {
            // The approved four-step encounter became Episode 4. Resume old
            // in-flight saves at the corresponding beat instead of restarting.
            storyStep = min(max(9 + min(max(progress.storyStep, 0), 2), 0), 17)
        } else {
            storyStep = min(max(progress.storyStep, 0), 17)
        }
        storyFoundName = progress.storyFoundName
        completedStoryBeats = progress.completedStoryBeats
            .filter { (0..<18).contains($0) }
            .uniqued()
            .sorted()
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
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
            .font(.caption2.weight(.bold))
            .kerning(1.05)
            .foregroundStyle(certainty.color)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(certainty.color.opacity(0.11))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(certainty.color.opacity(0.45), lineWidth: 0.8))
            .accessibilityLabel("Evidence status: \(certainty.rawValue.lowercased())")
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
        EditorialScreenHeader(context: eyebrow, title: title, detail: detail)
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
        EditorialRule()
    }
}

struct AtlasAudioLine: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
            withAnimation(reduceMotion ? nil : Motion.pop) { heard = true }
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(ga)
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.moss)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Image(systemName: canPlay ? (heard ? "speaker.wave.2.fill" : "speaker.wave.2") : "waveform.slash")
                        .foregroundStyle(canPlay ? Theme.moss : Theme.inkFaint)
                }
                Text(sound)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.inkFaint)
                Text(en)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Theme.inkSoft)
                if !canPlay {
                    Text("Audio coming soon")
                        .font(.caption2.weight(.semibold))
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
        .accessibilityLabel(canPlay ? "Hear \(ga), meaning \(en)" : "Audio unavailable for \(ga), meaning \(en)")
        .accessibilityHint(canPlay ? "Plays the Irish Cultural Guide recording" : "The written form and meaning remain available")
    }
}

struct SourceFooter: View {
    var compact = false
    var onOpen: (() -> Void)?

    var body: some View {
        Group {
            if let onOpen {
                Button(action: onOpen) { content }
                    .buttonStyle(CarvePress())
                    .accessibilityHint("Opens the source guide and provenance")
            } else {
                content
            }
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "building.columns")
                .foregroundStyle(Theme.inkFaint)
            Text(compact
                 ? "Source: National Library of Ireland record MS_UR_010761."
                 : "Source · National Library of Ireland record MS_UR_010761.")
                .font(.caption)
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(3)
        }
        .padding(13)
        .background(Theme.sunk)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}
