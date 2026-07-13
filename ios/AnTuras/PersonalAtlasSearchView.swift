import SwiftUI
import UIKit

// MARK: - Personal atlas search

struct PersonalAtlasSearchView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var initialQuery: String = ""
    var focus: PersonalSearchFocus = .either
    var onOpenSubject: (String) -> Void

    @State private var query = ""
    @State private var announcementTask: Task<Void, Never>?
    @State private var searchStartedAt: Date?
    @StateObject private var searchModel = PersonalAtlasSearchModel()
    @FocusState private var fieldFocused: Bool

    private let resultLimit = 12

    private var visibleResults: [PersonalIndexEntry] {
        Array(searchModel.results.prefix(resultLimit))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AtlasScreenHeader(
                    focus.eyebrow,
                    focus.title,
                    detail: searchModel.coverageNote
                )

                if let message = searchModel.loadErrorMessage {
                    contentError(message)
                } else {
                    searchField

                    if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        invitation
                    } else if searchModel.isSearching {
                        searchingState
                    } else if searchModel.results.isEmpty {
                        emptyState
                    } else if searchModel.results.count > 1 {
                        ambiguityList
                    } else if let only = searchModel.results.first {
                        singleMatch(only)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 36)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(focus.navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            searchModel.prepare()
            if query.isEmpty, !initialQuery.isEmpty {
                query = initialQuery
            }
            // Let navigation and the first layout commit before asking UIKit to
            // present the keyboard. Atlas resources are loaded off the main actor.
            Task { @MainActor in
                await Task.yield()
                fieldFocused = true
            }
        }
        .onChange(of: query) { oldValue, newValue in
            if oldValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                searchStartedAt = Date()
            }
            runSearch(query: newValue)
        }
        .onChange(of: searchModel.results) { _, results in
            scheduleResultAnnouncement(count: results.count)
        }
        .onDisappear {
            announcementTask?.cancel()
            searchModel.cancel()
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.moss)
            TextField(focus.placeholder, text: $query)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($fieldFocused)
                .font(.body)
                .foregroundStyle(Theme.ink)
                .submitLabel(.search)
                .onSubmit { recordSearchOutcome() }
            if !query.isEmpty {
                Button {
                    query = ""
                    searchModel.clear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.inkFaint)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Theme.raised)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.moss.opacity(0.35), lineWidth: 0.8)
        )
    }

    private var invitation: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Give us a name or a place that matters to you. We’ll follow its forms through time.")
                .font(.system(.body, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineSpacing(4)

            if focus == .either || focus == .name {
                suggestionRow(title: "A name you carry", examples: ["Gráinne", "Ó Briain", "Walsh", "Smith"])
            }
            if focus == .either || focus == .place {
                suggestionRow(title: "A place you know", examples: ["Killala", "Doire", "Baile Átha Cliath", "Trim"])
                NavigationLink {
                    NearbyPersonalPlacesView(onOpenSubject: onOpenSubject)
                } label: {
                    Label("Find a place near me", systemImage: "location")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Theme.moss)
                        .frame(minHeight: 44)
                }
            }

            if searchModel.isReady, appState.savePersonalSearchHistory {
                let recent = appState.recentPersonalSubjects.compactMap(PersonalAtlasLoader.indexEntry)
                if !recent.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent pages")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.inkSoft)
                        ForEach(recent.prefix(5)) { entry in
                            Button {
                                open(entry)
                            } label: {
                                HStack {
                                    Text(entry.canonicalDisplay)
                                        .font(.system(.callout, design: .serif, weight: .medium))
                                        .foregroundStyle(Theme.ink)
                                    Spacer()
                                    Text(entry.kind == .name ? "Name" : "Place")
                                        .font(.caption)
                                        .foregroundStyle(Theme.inkFaint)
                                }
                                .frame(minHeight: 44)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Toggle("Remember opened atlas pages on this device", isOn: $appState.savePersonalSearchHistory)
                .font(.footnote)
                .tint(Theme.moss)
                .onChange(of: appState.savePersonalSearchHistory) { _, enabled in
                    if !enabled { appState.recentPersonalSubjects.removeAll() }
                }
        }
    }

    private func suggestionRow(title: String, examples: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSoft)
            FlowWrap(items: examples) { example in
                Button {
                    query = example
                    Haptics.tap()
                } label: {
                    Text(example)
                        .font(.system(.callout, design: .serif, weight: .medium))
                        .foregroundStyle(Theme.moss)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.mossTint)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .frame(minHeight: 44)
                }
                .buttonStyle(CarvePress())
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No match yet.")
                .font(.system(.headline, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text("Try another spelling, or add or remove a fada or prefix. Places outside Ireland are not covered yet. Your search stays on this device.")
                .font(.callout)
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(3)
            Text("We won’t guess at an origin.")
                .font(.system(.callout, design: .serif))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.sunk)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var searchingState: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(Theme.moss)
            Text("Searching the offline atlas…")
                .font(.callout)
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private var ambiguityList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(resultSummary)
                .font(.callout)
                .foregroundStyle(Theme.inkSoft)
                .accessibilityAddTraits(.isHeader)

            ForEach(visibleResults) { entry in
                Button {
                    open(entry)
                } label: {
                    resultRow(entry)
                }
                .buttonStyle(CarvePress())
            }
        }
    }

    private func singleMatch(_ entry: PersonalIndexEntry) -> some View {
        Button {
            open(entry)
        } label: {
            resultRow(entry)
        }
        .buttonStyle(CarvePress())
    }

    private func resultRow(_ entry: PersonalIndexEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(entry.canonicalDisplay)
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text(entry.subtitle)
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
                if let alt = entry.variants.first(where: { $0 != entry.canonicalDisplay }) {
                    Text(alt)
                        .font(.system(.footnote, design: .serif))
                        .foregroundStyle(Theme.lichen)
                }
                if let context = resultContext(entry) {
                    Text(context)
                        .font(.caption)
                        .foregroundStyle(Theme.inkFaint)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.inkFaint)
                .padding(.top, 6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.raised)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.line.opacity(0.8), lineWidth: 0.8)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityResultLabel(entry))
    }

    private func open(_ entry: PersonalIndexEntry) {
        Haptics.tap()
        let analyticsId = PersonalAtlasLoader.subject(id: entry.id)?.editorial.releaseState == "public"
            ? entry.id
            : nil
        let elapsed = searchStartedAt.map {
            max(0, Int(Date().timeIntervalSince($0) * 1_000))
        }
        appState.recordPersonalAtlasEvent(
            subjectId: analyticsId,
            outcome: .openedSubject,
            selectedAmbiguityBranchId: searchModel.results.count > 1 ? analyticsId : nil,
            timeToAnswerMilliseconds: elapsed
        )
        if appState.savePersonalSearchHistory {
            appState.recordPersonalQuery(subjectId: entry.id)
        }
        onOpenSubject(entry.id)
    }

    private func recordSearchOutcome() {
        if searchModel.results.isEmpty {
            appState.recordPersonalAtlasEvent(
                subjectId: nil,
                outcome: .unresolved,
                unresolvedReason: "no-published-match"
            )
        } else if searchModel.results.count > 1 {
            appState.recordPersonalAtlasEvent(subjectId: nil, outcome: .ambiguityShown)
        }
    }

    private func runSearch(query: String) {
        searchModel.search(
            query: query,
            focus: focus,
            animateResults: !reduceMotion
        )
    }

    private var resultSummary: String {
        if searchModel.results.count > resultLimit {
            return "Showing the first \(resultLimit) of \(searchModel.results.count) matches. Add more letters to narrow them."
        }
        return "\(searchModel.results.count) matches. Use the place or name details to choose."
    }

    private func resultContext(_ entry: PersonalIndexEntry) -> String? {
        if entry.kind == .place { return nil }
        guard let nameKind = entry.nameKind else { return nil }
        return nameKind == .given ? "Given name" : "Surname"
    }

    private func accessibilityResultLabel(_ entry: PersonalIndexEntry) -> String {
        let variants = entry.variants
            .filter { $0 != entry.canonicalDisplay }
            .prefix(2)
            .joined(separator: ", ")
        return [entry.canonicalDisplay, entry.subtitle, resultContext(entry), variants.isEmpty ? nil : "Also \(variants)"]
            .compactMap { $0 }
            .joined(separator: ". ")
    }

    private func scheduleResultAnnouncement(count: Int) {
        announcementTask?.cancel()
        guard UIAccessibility.isVoiceOverRunning,
              !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        announcementTask = Task {
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            let message = count == 0 ? "No matches" : "\(count) matches"
            await MainActor.run {
                UIAccessibility.post(notification: .announcement, argument: message)
            }
        }
    }

    private func contentError(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("The personal atlas is unavailable", systemImage: "exclamationmark.triangle")
                .font(.headline)
                .foregroundStyle(Theme.rust)
            Text(message)
                .font(.body)
                .foregroundStyle(Theme.inkSoft)
            Text("The rest of An Turas is still available. Try again after updating or reinstalling this build.")
                .font(.callout)
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.sunk)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// Search owns a 49 MB on-disk index. Keeping its initialization and SQLite work
// behind an actor prevents either operation from blocking keyboard presentation or
// the TextField's first binding update.
private actor PersonalAtlasSearchWorker {
    struct LoadState {
        let coverageNote: String
        let errorMessage: String?
    }

    private var searchEngine: PersonalSearchEngine?

    func prepare() -> LoadState {
        let pack = PersonalAtlasLoader.pack()
        searchEngine = PersonalSearchEngine(pack: pack)
        return LoadState(
            coverageNote: pack.coverageNote,
            errorMessage: PersonalAtlasLoader.loadErrorMessage
        )
    }

    func matches(query: String, includeFoundation: Bool) -> [PersonalIndexEntry] {
        searchEngine?.matches(query: query, includeFoundation: includeFoundation) ?? []
    }
}

@MainActor
private final class PersonalAtlasSearchModel: ObservableObject {
    @Published private(set) var results: [PersonalIndexEntry] = []
    @Published private(set) var coverageNote = "Search names and places held in the offline atlas."
    @Published private(set) var loadErrorMessage: String?
    @Published private(set) var isReady = false
    @Published private(set) var isSearching = false

    private let worker = PersonalAtlasSearchWorker()
    private var prepareTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?
    private var generation = 0

    func prepare() {
        guard prepareTask == nil, !isReady else { return }
        prepareTask = Task { [weak self] in
            guard let self else { return }
            let state = await worker.prepare()
            guard !Task.isCancelled else { return }
            coverageNote = state.coverageNote
            loadErrorMessage = state.errorMessage
            isReady = true
        }
    }

    func search(query: String, focus: PersonalSearchFocus, animateResults: Bool) {
        generation += 1
        let requestedGeneration = generation
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            isSearching = false
            setResults([], animated: false)
            return
        }

        isSearching = true
        prepare()
        searchTask = Task { [weak self] in
            guard let self else { return }
            // Coalesce normal typing bursts while letting the TextField paint the
            // character immediately. Initial resource loading continues in parallel.
            try? await Task.sleep(for: .milliseconds(140))
            guard !Task.isCancelled else { return }
            await prepareTask?.value
            guard !Task.isCancelled else { return }
            guard loadErrorMessage == nil else {
                isSearching = false
                return
            }

            let matches = await worker.matches(
                query: query,
                includeFoundation: focus != .name
            )
            guard !Task.isCancelled, requestedGeneration == generation else { return }
            let filtered = matches.filter { entry in
                switch focus {
                case .either: return true
                case .name: return entry.kind == .name
                case .place: return entry.kind == .place
                }
            }
            isSearching = false
            setResults(filtered, animated: animateResults)
        }
    }

    func clear() {
        generation += 1
        searchTask?.cancel()
        isSearching = false
        setResults([], animated: false)
    }

    func cancel() {
        generation += 1
        searchTask?.cancel()
        isSearching = false
    }

    private func setResults(_ newResults: [PersonalIndexEntry], animated: Bool) {
        if animated {
            withAnimation(Motion.settle) { results = newResults }
        } else {
            results = newResults
        }
    }
}

enum PersonalSearchFocus: Hashable {
    case either, name, place

    var eyebrow: String {
        switch self {
        case .either: return "PERSONAL ATLAS"
        case .name: return "BEHIND A NAME"
        case .place: return "BEHIND A PLACE"
        }
    }

    var title: String {
        switch self {
        case .either: return "A name or a place that matters."
        case .name: return "Which name shall we look at?"
        case .place: return "Which place shall we open?"
        }
    }

    var placeholder: String {
        switch self {
        case .either: return "Name, surname, or place"
        case .name: return "A given name or surname"
        case .place: return "A place, townland, or Irish form"
        }
    }

    var navTitle: String {
        switch self {
        case .either: return "Search"
        case .name: return "A name"
        case .place: return "A place"
        }
    }
}

/// Simple wrapping chip row without a third-party layout dependency.
struct FlowWrap<Item: Hashable, Content: View>: View {
    let items: [Item]
    @ViewBuilder let content: (Item) -> Content

    var body: some View {
        // Flexible wrap via LazyVGrid of adaptive columns.
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                content(item)
            }
        }
    }
}
