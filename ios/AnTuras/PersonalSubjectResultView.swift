import SwiftUI

// MARK: - Personal subject result shell

struct PersonalSubjectResultView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let subjectId: String
    var onHandoff: (String) -> Void

    @State private var revealedFormIndex = 0
    @State private var showSources = false

    private var subject: OriginSubject? { PersonalAtlasLoader.subject(id: subjectId) }
    private var pack: PersonalAtlasPack { PersonalAtlasLoader.pack() }

    var body: some View {
        Group {
            if let subject {
                resultBody(subject)
            } else {
                Text("This subject is missing from the pilot pack.")
                    .font(.system(size: 16, design: .serif))
                    .foregroundStyle(Theme.rust)
                    .padding(20)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let subject {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        toggleSave(subject.id)
                    } label: {
                        Image(systemName: appState.isPersonalSubjectSaved(subject.id) ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(Theme.moss)
                    }
                    .accessibilityLabel(appState.isPersonalSubjectSaved(subject.id) ? "Remove from what matters to you" : "Save to what matters to you")
                }
            }
        }
        .sheet(isPresented: $showSources) {
            if let subject {
                NavigationStack {
                    PersonalSourcesSheet(subject: subject, packAttribution: pack.attribution)
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    @ViewBuilder
    private func resultBody(_ subject: OriginSubject) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header(subject)
                shortAnswer(subject)
                pronunciations(subject)
                historicalForms(subject)
                branches(subject)
                if let place = subject.placeProfile {
                    placeGround(place)
                }
                languageMoment(subject)
                familyBoundary(subject)
                deeperOrHandoff(subject)
                people(subject)
                saveRow(subject)
                footer(subject)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
    }

    private func header(_ subject: OriginSubject) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Eyebrow(text: subject.kind == .name ? "BEHIND A NAME" : "BEHIND A PLACE", color: Theme.moss)
                DepthChip(depth: subject.depth)
            }
            Text(subject.canonicalDisplay)
                .font(.system(size: 34, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
            Text(subject.subtitle)
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSoft)
            if !subject.variants.isEmpty {
                Text(subject.variants.filter { $0 != subject.canonicalDisplay }.prefix(4).joined(separator: " · "))
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(Theme.lichen)
            }
        }
    }

    private func shortAnswer(_ subject: OriginSubject) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(subject.editorial.shortAnswer)
                .font(.system(size: 18, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineSpacing(5)

            if let first = subject.assertions.first {
                PersonalCertaintyPill(certainty: first.certainty)
            }

            ForEach(Array(subject.editorial.storyBeats.enumerated()), id: \.offset) { _, beat in
                Text(beat)
                    .font(.system(size: 14.5))
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(3)
            }
        }
    }

    @ViewBuilder
    private func pronunciations(_ subject: OriginSubject) -> some View {
        let items = subject.nameProfile?.pronunciations ?? subject.placeProfile?.pronunciations ?? []
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Hear it")
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    pronunciationRow(item)
                }
            }
        }
    }

    private func pronunciationRow(_ item: PersonalPronunciation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.text)
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.moss)
            if let phonetic = item.phonetic {
                Text(phonetic)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.inkFaint)
            }
            Text(audioCaption(item))
                .font(.system(size: 12))
                .foregroundStyle(item.audioState == .unavailable ? Theme.rust : Theme.inkSoft)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.mossTint)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.text). \(audioCaption(item))")
    }

    private func audioCaption(_ item: PersonalPronunciation) -> String {
        switch item.audioState {
        case .verified:
            return "Verified \(item.dialect) pronunciation"
        case .unverified:
            return "Pronunciation guide · \(item.dialect) · not yet verified audio"
        case .unavailable:
            return "Audio unavailable — typography carries the name"
        }
    }

    @ViewBuilder
    private func historicalForms(_ subject: OriginSubject) -> some View {
        let forms = subject.nameProfile?.historicalForms ?? subject.placeProfile?.historicalForms ?? []
        if !forms.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel(subject.kind == .name ? "How the form travelled" : "Older shapes")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(Array(forms.enumerated()), id: \.element.id) { index, form in
                            formChip(form, selected: index == revealedFormIndex)
                                .onTapGesture {
                                    if reduceMotion {
                                        revealedFormIndex = index
                                    } else {
                                        withAnimation(Motion.settle) { revealedFormIndex = index }
                                    }
                                    Haptics.tap()
                                }
                        }
                    }
                    .padding(.vertical, 2)
                }
                if forms.indices.contains(revealedFormIndex) {
                    let form = forms[revealedFormIndex]
                    VStack(alignment: .leading, spacing: 4) {
                        Text(form.display)
                            .font(.system(size: 28, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.ink)
                            .id(form.id)
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .trailing)))
                        if let year = form.year {
                            Text(String(year))
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Theme.lichen)
                        }
                        if let note = form.note {
                            Text(note)
                                .font(.system(size: 13.5))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private func formChip(_ form: HistoricalForm, selected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(form.display)
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .foregroundStyle(selected ? Theme.ink : Theme.inkSoft)
            Text(form.language.uppercased())
                .font(.system(size: 9.5, weight: .bold))
                .kerning(0.9)
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(selected ? Theme.raised : Theme.sunk)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(selected ? Theme.moss.opacity(0.55) : Theme.line.opacity(0.5), lineWidth: 0.8)
        )
    }

    @ViewBuilder
    private func branches(_ subject: OriginSubject) -> some View {
        let items = subject.nameProfile?.etymologyBranches ?? subject.placeProfile?.derivationBranches ?? []
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel(subject.kind == .name ? "Origins and readings" : "The name beneath the name")
                ForEach(items) { branch in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(branch.label)
                                .font(.system(size: 16, weight: .semibold, design: .serif))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            PersonalCertaintyPill(certainty: branch.certainty)
                        }
                        Text(branch.summary)
                            .font(.system(size: 14.5))
                            .foregroundStyle(Theme.inkSoft)
                            .lineSpacing(3)
                        if !branch.components.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(Array(branch.components.enumerated()), id: \.offset) { _, part in
                                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                                        Text(part.ga)
                                            .font(.system(size: 16, weight: .semibold, design: .serif))
                                            .foregroundStyle(Theme.moss)
                                        Text(part.en)
                                            .font(.system(size: 14))
                                            .foregroundStyle(Theme.inkSoft)
                                    }
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 8)
                    AtlasRule()
                }
            }
        }
    }

    private func placeGround(_ place: PlaceProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("On the ground")
            Text(place.hierarchy)
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(Theme.ink)
            Text(place.placeKind.capitalized)
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkSoft)
            if let coords = place.coordinates {
                Text(String(format: "%.3f, %.3f", coords.lat, coords.lon))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.inkFaint)
                    .accessibilityLabel("Coordinates \(coords.lat), \(coords.lon)")
            }
            ForEach(place.featureLinks) { feature in
                Text(feature.label + (feature.note.map { " — \($0)" } ?? ""))
                    .font(.system(size: 13.5))
                    .foregroundStyle(Theme.lichen)
            }
            if let logainm = place.logainmId {
                Link("Open Logainm record \(logainm)", destination: URL(string: "https://www.logainm.ie/en/\(logainm)")!)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.moss)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.sunk)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func languageMoment(_ subject: OriginSubject) -> some View {
        if let moment = subject.editorial.languageMoment {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Carry a little Irish")
                Text(moment.ga)
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.moss)
                Text(moment.en)
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(Theme.inkSoft)
                if let note = moment.note {
                    Text(note)
                        .font(.system(size: 13.5))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
        }
    }

    @ViewBuilder
    private func familyBoundary(_ subject: OriginSubject) -> some View {
        if let note = subject.editorial.familyHistoryNote {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle")
                    .foregroundStyle(Theme.rust)
                Text(note)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(3)
            }
            .padding(14)
            .background(Theme.rustTint)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private func deeperOrHandoff(_ subject: OriginSubject) -> some View {
        if let message = subject.editorial.deeperStoryMessage {
            Text(message)
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(Theme.inkSoft)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        if let handoff = subject.editorial.storyHandoff {
            PrimaryButton(title: handoff.label, fullWidth: true) {
                Haptics.tap()
                onHandoff(handoff.route)
            }
        }
    }

    @ViewBuilder
    private func people(_ subject: OriginSubject) -> some View {
        let links = subject.nameProfile?.peopleLinks ?? []
        if !links.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("A bearer, not a celebrity list")
                ForEach(links, id: \.resolvedId) { link in
                    if let route = link.route {
                        Button {
                            Haptics.tap()
                            onHandoff(route)
                        } label: {
                            HStack {
                                Text(link.label)
                                    .font(.system(size: 16, weight: .semibold, design: .serif))
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .foregroundStyle(Theme.moss)
                            }
                            .padding(14)
                            .background(Theme.raised)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(CarvePress())
                    }
                }
            }
        }
    }

    private func saveRow(_ subject: OriginSubject) -> some View {
        Button {
            toggleSave(subject.id)
        } label: {
            HStack {
                Image(systemName: appState.isPersonalSubjectSaved(subject.id) ? "bookmark.fill" : "bookmark")
                Text(appState.isPersonalSubjectSaved(subject.id) ? "Saved under What matters to you" : "Save to What matters to you")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(Theme.moss)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Theme.mossTint)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(CarvePress())
    }

    private func footer(_ subject: OriginSubject) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                showSources = true
            } label: {
                Label("Sources and certainty", systemImage: "building.columns")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
            Text("Pilot pack \(subject.editorial.contentVersion) · dated \(pack.contentDate)")
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .kerning(1.3)
            .foregroundStyle(Theme.inkFaint)
    }

    private func toggleSave(_ id: String) {
        Haptics.tap()
        appState.togglePersonalSubject(id)
    }
}

struct PersonalSourcesSheet: View {
    let subject: OriginSubject
    let packAttribution: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(subject.canonicalDisplay)
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                Text(packAttribution)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)

                ForEach(subject.assertions) { assertion in
                    VStack(alignment: .leading, spacing: 8) {
                        PersonalCertaintyPill(certainty: assertion.certainty)
                        Text(assertion.statement)
                            .font(.system(size: 15, design: .serif))
                        Text("Scope · \(assertion.scope)")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkFaint)
                        Text("Reviewed \(assertion.reviewedAt) · \(assertion.reviewer) · \(assertion.rightsState)")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.inkFaint)
                    }
                    AtlasRule()
                }

                ForEach(subject.evidence) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.sourceType.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .kerning(1.0)
                            .foregroundStyle(Theme.lichen)
                        Text(item.citation)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.ink)
                        Text(item.attribution)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkSoft)
                        if let url = item.stableURL, let link = URL(string: url) {
                            Link(url, destination: link)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.moss)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Sources")
        .navigationBarTitleDisplayMode(.inline)
    }
}
