import SwiftUI

// MARK: - Personal subject result shell

struct PersonalSubjectResultView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let subjectId: String
    var onHandoff: (String) -> Void

    @State private var revealedFormIndex = 0
    @State private var showSources = false
    @State private var focusedAssertionId: String?

    private var subject: OriginSubject? { PersonalAtlasLoader.subject(id: subjectId) }
    private var pack: PersonalAtlasPack { PersonalAtlasLoader.pack() }

    var body: some View {
        Group {
            if let subject {
                resultBody(subject)
            } else {
                Text("This subject is missing from the pilot pack.")
                    .font(.system(.body, design: .serif))
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
        .sheet(isPresented: $showSources, onDismiss: { focusedAssertionId = nil }) {
            if let subject {
                NavigationStack {
                    PersonalSourcesSheet(
                        subject: subject,
                        packAttribution: pack.attribution,
                        focusedAssertionId: focusedAssertionId
                    )
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
            Text(subject.kind == .name ? "A name you carry" : "A place you know")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.moss)
            Text(subject.canonicalDisplay)
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
            Text(subject.subtitle)
                .font(.callout)
                .foregroundStyle(Theme.inkSoft)
            if !subject.variants.isEmpty {
                Text(subject.variants.filter { $0 != subject.canonicalDisplay }.prefix(4).joined(separator: " · "))
                    .font(.system(.callout, design: .serif))
                    .foregroundStyle(Theme.lichen)
            }
        }
    }

    private func shortAnswer(_ subject: OriginSubject) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(subject.editorial.shortAnswer)
                .font(.system(.title3, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineSpacing(5)
            if let first = subject.assertions.first {
                PersonalEvidenceMark(certainty: first.certainty) {
                    openEvidence(first)
                }
            }
        }
    }

    @ViewBuilder
    private func pronunciations(_ subject: OriginSubject) -> some View {
        let items = subject.nameProfile?.pronunciations ?? subject.placeProfile?.pronunciations ?? []
        let guides = items.filter { item in
            guard let phonetic = item.phonetic else { return false }
            return !phonetic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        if !guides.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Pronunciation guide")
                ForEach(Array(guides.enumerated()), id: \.offset) { _, item in
                    pronunciationRow(item)
                }
            }
        }
    }

    private func pronunciationRow(_ item: PersonalPronunciation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.text)
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.moss)
            if let phonetic = item.phonetic {
                Text(phonetic)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Theme.inkFaint)
            }
            Text(audioCaption(item))
                .font(.caption)
                .foregroundStyle(Theme.inkSoft)
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
            return "\(item.dialect.capitalized) guide"
        case .unverified:
            return "\(item.dialect.capitalized) guide · awaiting speaker review"
        case .unavailable:
            return "Approximate guide · recording in preparation"
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
                            Button {
                                    if reduceMotion {
                                        revealedFormIndex = index
                                    } else {
                                        withAnimation(Motion.settle) { revealedFormIndex = index }
                                    }
                                    Haptics.tap()
                            } label: {
                                formChip(form, selected: index == revealedFormIndex)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(form.display), \(form.language)\(form.year.map { ", \($0)" } ?? "")")
                            .accessibilityValue(index == revealedFormIndex ? "Selected" : "")
                        }
                    }
                    .padding(.vertical, 2)
                }
                if forms.indices.contains(revealedFormIndex) {
                    let form = forms[revealedFormIndex]
                    VStack(alignment: .leading, spacing: 4) {
                        Text(form.display)
                            .font(.system(.title2, design: .serif, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .id(form.id)
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .trailing)))
                        if let year = form.year {
                            Text(String(year))
                                .font(.system(.caption, design: .monospaced, weight: .semibold))
                                .foregroundStyle(Theme.lichen)
                        }
                        if let note = form.note {
                            Text(note)
                                .font(.callout)
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
                .font(.system(.callout, design: .serif, weight: .semibold))
                .foregroundStyle(selected ? Theme.ink : Theme.inkSoft)
            Text(form.language.uppercased())
                .font(.caption2.weight(.bold))
                .kerning(0.9)
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(minHeight: 44)
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
                sectionLabel(subject.kind == .name ? "Inside the name" : "Inside the place-name")
                ForEach(items) { branch in
                    VStack(alignment: .leading, spacing: 8) {
                        if shouldShowBranchLabel(branch, total: items.count) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(branch.label)
                                    .font(.system(.headline, design: .serif))
                                    .foregroundStyle(Theme.ink)
                                Spacer(minLength: 8)
                                if let assertion = matchingAssertion(for: branch, in: subject) {
                                    PersonalEvidenceMark(certainty: branch.certainty) {
                                        openEvidence(assertion)
                                    }
                                }
                            }
                        }
                        if shouldShowBranchSummary(branch, subject: subject) {
                            Text(branch.summary)
                                .font(.callout)
                                .foregroundStyle(Theme.inkSoft)
                                .lineSpacing(3)
                        }
                        if !branch.components.isEmpty {
                            HStack(alignment: .top, spacing: 8) {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(Array(branch.components.enumerated()), id: \.offset) { _, part in
                                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                                            Text(part.ga)
                                                .font(.system(.headline, design: .serif))
                                                .foregroundStyle(Theme.moss)
                                            Text(part.en)
                                                .font(.callout)
                                                .foregroundStyle(Theme.inkSoft)
                                        }
                                    }
                                }
                                Spacer(minLength: 0)
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
                .font(.system(.body, design: .serif))
                .foregroundStyle(Theme.ink)
            Text(place.placeKind.capitalized)
                .font(.footnote)
                .foregroundStyle(Theme.inkSoft)
            if let coords = place.coordinates {
                Text(String(format: "%.3f, %.3f", coords.lat, coords.lon))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.inkFaint)
                    .accessibilityLabel("Coordinates \(coords.lat), \(coords.lon)")
            }
            ForEach(place.featureLinks) { feature in
                Text(feature.label + (feature.note.map { " — \($0)" } ?? ""))
                    .font(.callout)
                    .foregroundStyle(Theme.lichen)
            }
            if let logainm = place.logainmId {
                Link("Open Logainm record \(logainm)", destination: URL(string: "https://www.logainm.ie/en/\(logainm)")!)
                    .font(.callout.weight(.semibold))
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
        if let moment = subject.editorial.languageMoment,
           PersonalSearch.normalize(moment.ga) != PersonalSearch.normalize(subject.canonicalDisplay) {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Carry a little Irish")
                Text(moment.ga)
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.moss)
                Text(moment.en)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Theme.inkSoft)
                if let note = moment.note {
                    Text(note)
                        .font(.callout)
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
                    .foregroundStyle(Theme.moss)
                Text(note)
                    .font(.callout)
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(3)
            }
            .padding(14)
            .background(Theme.sunk)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    @ViewBuilder
    private func deeperOrHandoff(_ subject: OriginSubject) -> some View {
        if let message = subject.editorial.deeperStoryMessage {
            Text(message)
                .font(.system(.body, design: .serif))
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
                                    .font(.system(.headline, design: .serif))
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
                    .font(.callout.weight(.semibold))
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
                Label("Sources", systemImage: "building.columns")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(minHeight: 44)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .kerning(1.3)
            .foregroundStyle(Theme.inkFaint)
    }

    private func toggleSave(_ id: String) {
        Haptics.tap()
        appState.togglePersonalSubject(id)
    }

    private func openEvidence(_ assertion: Assertion) {
        focusedAssertionId = assertion.id
        showSources = true
        Haptics.tap()
    }

    private func matchingAssertion(for branch: EtymologyBranch, in subject: OriginSubject) -> Assertion? {
        subject.assertions.first { $0.certainty == branch.certainty } ?? subject.assertions.first
    }

    private func shouldShowBranchLabel(_ branch: EtymologyBranch, total: Int) -> Bool {
        guard total > 1 else { return false }
        return !["best-supported reading", "supported interpretation"].contains(branch.label.lowercased())
    }

    private func shouldShowBranchSummary(_ branch: EtymologyBranch, subject: OriginSubject) -> Bool {
        PersonalSearch.normalize(branch.summary) != PersonalSearch.normalize(subject.editorial.shortAnswer)
    }
}

struct PersonalSourcesSheet: View {
    @Environment(\.dismiss) private var dismiss

    let subject: OriginSubject
    let packAttribution: String
    let focusedAssertionId: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(subject.canonicalDisplay)
                    .font(.system(.title2, design: .serif, weight: .semibold))
                Text(packAttribution)
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)

                ForEach(orderedAssertions) { assertion in
                    VStack(alignment: .leading, spacing: 8) {
                        PersonalEvidenceDetail(certainty: assertion.certainty)
                        Text(assertion.statement)
                            .font(.system(.body, design: .serif))
                            .foregroundStyle(Theme.ink)
                        Text("Scope · \(assertion.scope)")
                            .font(.caption)
                            .foregroundStyle(Theme.inkFaint)
                        Text(reviewLine(assertion))
                            .font(.caption)
                            .foregroundStyle(Theme.inkFaint)
                        ForEach(supportingEvidence(for: assertion)) { item in
                            evidenceRow(item)
                        }
                    }
                    .id(assertion.id)
                    AtlasRule()
                }

                if !unreferencedEvidence.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Other sources")
                            .font(.headline)
                            .foregroundStyle(Theme.ink)
                        ForEach(unreferencedEvidence) { item in
                            evidenceRow(item)
                        }
                    }
                }

                Text("Content version \(subject.editorial.contentVersion)")
                    .font(.caption)
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Sources")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private var orderedAssertions: [Assertion] {
        guard let focusedAssertionId,
              let focused = subject.assertions.first(where: { $0.id == focusedAssertionId }) else {
            return subject.assertions
        }
        return [focused] + subject.assertions.filter { $0.id != focusedAssertionId }
    }

    private var referencedEvidenceIds: Set<String> {
        Set(subject.assertions.flatMap(\.evidenceIds))
    }

    private var unreferencedEvidence: [Evidence] {
        subject.evidence.filter { !referencedEvidenceIds.contains($0.id) }
    }

    private func supportingEvidence(for assertion: Assertion) -> [Evidence] {
        let ids = Set(assertion.evidenceIds)
        return subject.evidence.filter { ids.contains($0.id) }
    }

    private func reviewLine(_ assertion: Assertion) -> String {
        if assertion.reviewer == "pilot-editorial" {
            return "Pilot editorial note · specialist and rights review pending"
        }
        return "Reviewed \(assertion.reviewedAt) · \(assertion.reviewer) · \(assertion.rightsState)"
    }

    private func evidenceRow(_ item: Evidence) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.sourceType.replacingOccurrences(of: "-", with: " ").capitalized)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.lichen)
            Text(item.citation)
                .font(.callout)
                .foregroundStyle(Theme.ink)
            Text(item.attribution)
                .font(.caption)
                .foregroundStyle(Theme.inkSoft)
            if let url = item.stableURL, let link = URL(string: url) {
                Link("Open source", destination: link)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Theme.moss)
                    .frame(minHeight: 44, alignment: .leading)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PersonalEvidenceMark: View {
    let certainty: PersonalCertainty
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: certainty.symbolName)
                .font(.callout.weight(.semibold))
                .foregroundStyle(certainty.color)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(certainty.label.capitalized). Open evidence details")
    }
}

struct PersonalEvidenceDetail: View {
    let certainty: PersonalCertainty

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: certainty.symbolName)
                .foregroundStyle(certainty.color)
                .frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(certainty.label.capitalized)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text(certainty.detail)
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
