import SwiftUI
import MapKit

// MARK: - Personal subject result shell

struct PersonalSubjectResultView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var speech = SpeechService.shared

    let subjectId: String
    var onHandoff: (String) -> Void

    @State private var revealedFormIndex = 0
    @State private var showSources = false
    @State private var focusedAssertionId: String?
    @State private var showsDeeperRecord = false
    @State private var showsUtilities = false

    private var subject: OriginSubject? { PersonalAtlasLoader.subject(id: subjectId) }
    private var pack: PersonalAtlasPack { PersonalAtlasLoader.pack() }

    var body: some View {
        Group {
            if let subject {
                resultBody(subject)
            } else {
                Text("This subject is not available in this content pack.")
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
            VStack(alignment: .leading, spacing: 0) {
                openingFolio(subject)

                learningChapter(subject)

                etymologyChapter(subject)

                if let place = subject.placeProfile {
                    placeGround(place, subject: subject)
                }

                closingChapter(subject)
            }
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
    }

    private func openingFolio(_ subject: OriginSubject) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            header(subject)
            shortAnswer(subject)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 34)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func learningChapter(_ subject: OriginSubject) -> some View {
        if hasPronunciationGuides(subject) || hasHistoricalForms(subject) {
            VStack(alignment: .leading, spacing: 28) {
                pronunciations(subject)
                historicalForms(subject)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.mossTint)
        }
    }

    @ViewBuilder
    private func etymologyChapter(_ subject: OriginSubject) -> some View {
        if hasEtymologyBranches(subject) {
            branches(subject)
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.raised)
        }
    }

    private func closingChapter(_ subject: OriginSubject) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            languageMoment(subject)
                .padding(.bottom, 30)
            familyBoundary(subject)
                .padding(.bottom, 24)
            deeperOrHandoff(subject)
                .padding(.bottom, 26)
            people(subject)
                .padding(.bottom, 32)

            deeperRecord(subject)

            AtlasRule()
                .padding(.top, 28)

            utilities(subject)
        }
        .padding(.horizontal, 20)
        .padding(.top, 34)
        .padding(.bottom, 48)
        .frame(maxWidth: .infinity, alignment: .leading)
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
            if !hasHistoricalForms(subject),
               let typedVariants = subject.variantRelationships,
               !typedVariants.isEmpty {
                ForEach(Array(typedVariants.prefix(4).enumerated()), id: \.offset) { _, variant in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(variant.display)
                            .font(.system(.callout, design: .serif))
                            .foregroundStyle(Theme.lichen)
                        Text(variant.relationship.label)
                            .font(.caption)
                            .foregroundStyle(Theme.inkFaint)
                    }
                    .accessibilityElement(children: .combine)
                }
            } else if !hasHistoricalForms(subject), !subject.variants.isEmpty {
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
            if let first = shortAnswerAssertion(for: subject) {
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
            if item.audioState == .verified, item.audio != nil { return true }
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
            if item.audioState == .verified,
               let audio = item.audio,
               speech.canPlayVerifiedAsset(named: audio.assetName) {
                Button {
                    if speech.isSpeaking(item.text) {
                        speech.stop()
                    } else {
                        speech.playVerifiedAsset(named: audio.assetName, displayText: item.text)
                    }
                } label: {
                    Label(
                        speech.isSpeaking(item.text) ? "Stop" : "Hear \(audio.speaker)",
                        systemImage: speech.isSpeaking(item.text) ? "stop.fill" : "speaker.wave.2"
                    )
                    .font(.callout.weight(.semibold))
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.moss)
                Text("\(audio.dialect) · recorded \(audio.recordedAt) · \(audio.permissionState)")
                    .font(.caption)
                    .foregroundStyle(Theme.inkFaint)
            } else if item.audioState == .unverified {
                Text("Approximate pronunciation · awaiting speaker review")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
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
                if forms.indices.contains(revealedFormIndex),
                   shouldShowFormDetail(forms[revealedFormIndex], subject: subject) {
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
        .background(selected ? Theme.raised : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(selected ? Theme.moss.opacity(0.55) : Color.clear, lineWidth: 0.8)
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

    private func placeGround(_ place: PlaceProfile, subject: OriginSubject) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("On the ground")
                Text(place.hierarchy)
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text(place.placeKind.capitalized)
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)
            .padding(.bottom, 16)

            if let coords = place.coordinates {
                Map(
                    initialPosition: .region(
                        MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: coords.lat, longitude: coords.lon),
                            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                        )
                    ),
                    interactionModes: [.pan, .zoom]
                ) {
                    Marker(
                        subject.canonicalDisplay,
                        coordinate: CLLocationCoordinate2D(latitude: coords.lat, longitude: coords.lon)
                    )
                    .tint(Theme.moss)
                }
                .frame(minHeight: 250)
                .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 10) {
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
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.sunk)
    }

    @ViewBuilder
    private func historicalDistribution(_ subject: OriginSubject) -> some View {
        if let distributions = subject.nameProfile?.distributions, !distributions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("In surviving records")
                ForEach(Array(distributions.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.dataset)
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                            Spacer(minLength: 12)
                            if let year = item.year {
                                Text(String(year))
                                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                                    .foregroundStyle(Theme.lichen)
                            }
                        }
                        if let geography = item.geography {
                            Text(geography)
                                .font(.caption)
                                .foregroundStyle(Theme.inkFaint)
                        }
                        if item.suppressed == true {
                            Label("Value suppressed by the source dataset", systemImage: "eye.slash")
                                .font(.callout)
                                .foregroundStyle(Theme.inkSoft)
                        } else if let count = item.count {
                            Text("\(count.formatted()) records in this dataset and geography")
                                .font(.system(.title3, design: .serif, weight: .semibold))
                                .foregroundStyle(Theme.moss)
                        }
                        Text(item.note)
                            .font(.callout)
                            .foregroundStyle(Theme.inkSoft)
                        if let rawURL = item.sourceURL, let url = URL(string: rawURL) {
                            Link("Open distribution source", destination: url)
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(Theme.moss)
                                .frame(minHeight: 44)
                        }
                    }
                    .padding(.vertical, 4)
                    AtlasRule()
                }

                Text("These are patterns in a named record set, not evidence that your family came from a place.")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
                    .padding(12)
                    .background(Theme.sunk)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    @ViewBuilder
    private func historicMapLayers(_ place: PlaceProfile, subject: OriginSubject) -> some View {
        if let layers = place.historicMapLayers, !layers.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("The same ground, another time")
                ForEach(layers) { layer in
                    PersonalHistoricMapAlignmentView(subject: subject, layer: layer)
                }
            }
        }
    }

    @ViewBuilder
    private func nameTravelling(_ subject: OriginSubject) -> some View {
        if let moments = subject.nameProfile?.travelMoments, !moments.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("A name travelling")
                ForEach(moments) { moment in
                    HStack(alignment: .top, spacing: 14) {
                        Text(moment.year.map(String.init) ?? "—")
                            .font(.system(.caption, design: .monospaced, weight: .semibold))
                            .foregroundStyle(Theme.lichen)
                            .frame(minWidth: 48, alignment: .leading)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(moment.form)
                                .font(.system(.headline, design: .serif))
                                .foregroundStyle(Theme.ink)
                            Text("\(moment.place) · \(moment.sourceLabel)")
                                .font(.caption)
                                .foregroundStyle(Theme.inkFaint)
                            Text(moment.note)
                                .font(.callout)
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    AtlasRule()
                }
                Text("This follows forms in named records. It does not describe your ancestry or a personal migration route.")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
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
                let analyticsId = subject.editorial.releaseState == "public" ? subject.id : nil
                appState.recordPersonalAtlasEvent(subjectId: analyticsId, outcome: .continued)
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

    @ViewBuilder
    private func deeperRecord(_ subject: OriginSubject) -> some View {
        if hasDeeperRecord(subject) {
            DisclosureGroup(isExpanded: $showsDeeperRecord) {
                VStack(alignment: .leading, spacing: 34) {
                    historicalDistribution(subject)
                    nameTravelling(subject)
                    if let place = subject.placeProfile {
                        historicMapLayers(place, subject: subject)
                    }
                    communityEdition(subject)
                }
                .padding(.top, 24)
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Explore the record")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text(subject.kind == .name ? "Records, journeys, and editorial context" : "Older maps and editorial context")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .tint(Theme.moss)
            .animation(reduceMotion ? nil : Motion.settle, value: showsDeeperRecord)
        }
    }

    private func advancedActions(_ subject: OriginSubject) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            NavigationLink {
                PersonalKeepsakeView(subject: subject)
            } label: {
                actionRow("Make a learning keepsake", systemImage: "rectangle.and.pencil.and.ellipsis")
            }

            if subject.kind == .place {
                NavigationLink {
                    PersonalFieldModeView(subject: subject)
                } label: {
                    actionRow("Open field mode", systemImage: "figure.walk")
                }
            }

            if subject.nameProfile?.nameKind == .surname {
                NavigationLink {
                    FamilyResearchWorksheetView(subject: subject)
                } label: {
                    actionRow("Begin a private research worksheet", systemImage: "list.clipboard")
                }
            }

            if subject.editorial.releaseState == "public",
               let url = PersonalAtlasDeepLink.webURL(for: subject.id) {
                ShareLink(item: url, subject: Text(subject.canonicalDisplay), message: Text(shareText(for: subject))) {
                    actionRow("Share a sourced excerpt", systemImage: "square.and.arrow.up")
                }
            } else {
                ShareLink(item: shareText(for: subject)) {
                    actionRow("Share a sourced excerpt", systemImage: "square.and.arrow.up")
                }
            }
        }
        .background(Theme.raised)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func communityEdition(_ subject: OriginSubject) -> some View {
        if let edition = subject.editorial.communityEdition,
           edition.consentState == "agreed" {
            VStack(alignment: .leading, spacing: 6) {
                Text(edition.title)
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text(edition.credit)
                    .font(.callout)
                    .foregroundStyle(Theme.inkSoft)
                Text("Edited by \(edition.editor) · reviewed by \(edition.reviewer)")
                    .font(.caption)
                    .foregroundStyle(Theme.inkFaint)
                if let url = URL(string: edition.correctionURL) {
                    Link("Edition corrections policy", destination: url)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Theme.moss)
                        .frame(minHeight: 44)
                }
            }
            .padding(.vertical, 4)
        }
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

            NavigationLink {
                PersonalAtlasFeedbackView(subject: subject, assertionId: focusedAssertionId)
            } label: {
                Label("Suggest a correction or local form", systemImage: "text.bubble")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(minHeight: 44)
            }

            NavigationLink {
                PersonalAtlasMethodologyView()
            } label: {
                Label("Method, privacy, and limits", systemImage: "info.circle")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(minHeight: 44)
            }
        }
    }

    private func utilities(_ subject: OriginSubject) -> some View {
        DisclosureGroup(isExpanded: $showsUtilities) {
            VStack(alignment: .leading, spacing: 18) {
                advancedActions(subject)
                footer(subject)
            }
            .padding(.top, 18)
        } label: {
            Text("More")
                .font(.callout.weight(.semibold))
                .foregroundStyle(Theme.inkSoft)
                .frame(minHeight: 44, alignment: .leading)
        }
        .tint(Theme.moss)
        .animation(reduceMotion ? nil : Motion.settle, value: showsUtilities)
    }

    private func actionRow(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(Theme.moss)
                .frame(width: 24)
            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }

    private func shareText(for subject: OriginSubject) -> String {
        let status = subject.editorial.releaseState == "public" ? "Published" : "Editorial draft"
        return "\(subject.canonicalDisplay) — \(subject.editorial.saveExcerpt) Source path and evidence are available in An Turas. \(status), content version \(subject.editorial.contentVersion)."
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(.headline, design: .serif, weight: .semibold))
            .foregroundStyle(Theme.moss)
    }

    private func hasHistoricalForms(_ subject: OriginSubject) -> Bool {
        let forms = subject.nameProfile?.historicalForms ?? subject.placeProfile?.historicalForms ?? []
        return !forms.isEmpty
    }

    private func shouldShowFormDetail(_ form: HistoricalForm, subject: OriginSubject) -> Bool {
        form.display != subject.canonicalDisplay || form.year != nil
    }

    private func hasPronunciationGuides(_ subject: OriginSubject) -> Bool {
        let items = subject.nameProfile?.pronunciations ?? subject.placeProfile?.pronunciations ?? []
        return items.contains { item in
            if item.audioState == .verified, item.audio != nil { return true }
            guard let phonetic = item.phonetic else { return false }
            return !phonetic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func hasEtymologyBranches(_ subject: OriginSubject) -> Bool {
        let branches = subject.nameProfile?.etymologyBranches ?? subject.placeProfile?.derivationBranches ?? []
        return !branches.isEmpty
    }

    private func hasDeeperRecord(_ subject: OriginSubject) -> Bool {
        let distributions = subject.nameProfile?.distributions ?? []
        let travelMoments = subject.nameProfile?.travelMoments ?? []
        let mapLayers = subject.placeProfile?.historicMapLayers ?? []
        let hasCommunityEdition = subject.editorial.communityEdition?.consentState == "agreed"
        return !distributions.isEmpty || !travelMoments.isEmpty || !mapLayers.isEmpty || hasCommunityEdition
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
        if let assertionId = branch.assertionId,
           let exact = subject.assertions.first(where: { $0.id == assertionId }) {
            return exact
        }
        return subject.assertions.first { $0.certainty == branch.certainty } ?? subject.assertions.first
    }

    private func shortAnswerAssertion(for subject: OriginSubject) -> Assertion? {
        if let assertionId = subject.editorial.shortAnswerAssertionId,
           let exact = subject.assertions.first(where: { $0.id == assertionId }) {
            return exact
        }
        return subject.assertions.first
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
                        reviewHistory(assertion)
                        let competitors = competingAssertions(for: assertion)
                        if !competitors.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Competing readings")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Theme.rust)
                                ForEach(competitors) { competitor in
                                    Text(competitor.statement)
                                        .font(.callout)
                                        .foregroundStyle(Theme.inkSoft)
                                }
                            }
                            .padding(12)
                            .background(Theme.sunk)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
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
            return "Editorial note · specialist and rights review pending"
        }
        return "Reviewed \(assertion.reviewedAt) · \(assertion.reviewer) · \(assertion.rightsState)"
    }

    @ViewBuilder
    private func reviewHistory(_ assertion: Assertion) -> some View {
        if let history = assertion.reviewHistory, !history.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Review history")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkSoft)
                ForEach(history) { review in
                    Text("\(review.reviewedAt) · \(review.reviewer) · \(review.decision)")
                        .font(.caption)
                        .foregroundStyle(Theme.inkFaint)
                }
            }
        } else {
            Text(reviewLine(assertion))
                .font(.caption)
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private func competingAssertions(for assertion: Assertion) -> [Assertion] {
        let ids = Set(assertion.competingAssertionIds)
        return subject.assertions.filter { ids.contains($0.id) }
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
