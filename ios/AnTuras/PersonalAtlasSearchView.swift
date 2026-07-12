import SwiftUI

// MARK: - Personal atlas search

struct PersonalAtlasSearchView: View {
    @EnvironmentObject private var appState: AppState
    var initialQuery: String = ""
    var focus: PersonalSearchFocus = .either
    var onOpenSubject: (String) -> Void

    @State private var query = ""
    @State private var results: [PersonalIndexEntry] = []
    @FocusState private var fieldFocused: Bool

    private let pack = PersonalAtlasLoader.pack()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AtlasScreenHeader(
                    focus.eyebrow,
                    focus.title,
                    detail: pack.coverageNote
                )

                searchField

                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    invitation
                } else if results.isEmpty {
                    emptyState
                } else if results.count > 1 {
                    ambiguityList
                } else if let only = results.first {
                    singleMatch(only)
                }

                Text("Content dated \(pack.contentDate) · \(pack.attribution)")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.top, 8)
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
            if query.isEmpty, !initialQuery.isEmpty {
                query = initialQuery
                runSearch()
            }
            fieldFocused = true
        }
        .onChange(of: query) { _, _ in
            runSearch()
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
                .font(.system(size: 17))
                .foregroundStyle(Theme.ink)
                .submitLabel(.search)
            if !query.isEmpty {
                Button {
                    query = ""
                    results = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.inkFaint)
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
            Text("Give us a name or a place that matters to you. We will take you as far back as the evidence allows.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineSpacing(4)

            if focus == .either || focus == .name {
                suggestionRow(title: "A name you carry", examples: ["Gráinne", "Ó Briain", "Walsh", "Smith"])
            }
            if focus == .either || focus == .place {
                suggestionRow(title: "A place you know", examples: ["Killala", "Doire", "Baile Átha Cliath", "Trim"])
            }
        }
    }

    private func suggestionRow(title: String, examples: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.inkSoft)
            FlowWrap(items: examples) { example in
                Button {
                    query = example
                    Haptics.tap()
                } label: {
                    Text(example)
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundStyle(Theme.moss)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.mossTint)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(CarvePress())
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nothing in the pilot index matches that spelling.")
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            Text("Check fadas and prefixes, or try another form. If the place is outside Ireland, this atlas does not cover it yet. Unresolved searches stay on your device.")
                .font(.system(size: 14.5))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(3)
            Text("We do not invent an Irish derivation to fill the gap.")
                .font(.system(size: 13.5, design: .serif))
                .foregroundStyle(Theme.rust)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.sunk)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var ambiguityList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Several matches — choose by the evidence that distinguishes them.")
                .font(.system(size: 14.5))
                .foregroundStyle(Theme.inkSoft)

            ForEach(results) { entry in
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
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text(entry.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
                if let alt = entry.variants.first(where: { $0 != entry.canonicalDisplay }) {
                    Text(alt)
                        .font(.system(size: 13, design: .serif))
                        .foregroundStyle(Theme.lichen)
                }
                HStack(spacing: 8) {
                    DepthChip(depth: entry.depth)
                    if entry.kind == .name, let nk = entry.nameKind {
                        Text(nk == .given ? "GIVEN" : "SURNAME")
                            .font(.system(size: 9.5, weight: .bold))
                            .kerning(1.0)
                            .foregroundStyle(Theme.inkFaint)
                    }
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
        .accessibilityLabel("\(entry.canonicalDisplay), \(entry.subtitle)")
    }

    private func open(_ entry: PersonalIndexEntry) {
        Haptics.tap()
        if appState.savePersonalSearchHistory {
            appState.recordPersonalQuery(subjectId: entry.id)
        }
        onOpenSubject(entry.id)
    }

    private func runSearch() {
        let filtered = PersonalSearch.matches(query: query, in: pack).filter { entry in
            switch focus {
            case .either: return true
            case .name: return entry.kind == .name
            case .place: return entry.kind == .place
            }
        }
        withAnimation(Motion.settle) {
            results = Array(filtered.prefix(12))
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

struct DepthChip: View {
    let depth: PersonalContentDepth
    var body: some View {
        Text(depth == .authored ? "AUTHORED" : "FOUNDATION")
            .font(.system(size: 9.5, weight: .bold))
            .kerning(1.0)
            .foregroundStyle(depth == .authored ? Theme.moss : Theme.inkFaint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background((depth == .authored ? Theme.moss : Theme.inkFaint).opacity(0.12))
            .clipShape(Capsule())
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

struct PersonalCertaintyPill: View {
    let certainty: PersonalCertainty
    var body: some View {
        Text(certainty.label)
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
