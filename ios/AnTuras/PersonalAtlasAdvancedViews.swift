import SwiftUI
import CoreLocation
import MapKit

// MARK: - Phase 2–4 personal-atlas surfaces

struct PersonalAtlasFeedbackView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let subject: OriginSubject
    let assertionId: String?

    @State private var kind: PersonalAtlasFeedback.Kind = .localForm
    @State private var context = ""
    @State private var sourceURL = ""
    @State private var submitted = false

    var body: some View {
        Form {
            Section {
                Picker("What would you like us to review?", selection: $kind) {
                    Text("Another local form").tag(PersonalAtlasFeedback.Kind.localForm)
                    Text("A different place").tag(PersonalAtlasFeedback.Kind.wrongPlace)
                    Text("A factual correction").tag(PersonalAtlasFeedback.Kind.correction)
                }
                TextField("What should the editor know?", text: $context, axis: .vertical)
                    .lineLimit(4...8)
                TextField("Source link, archive reference, or local context (optional)", text: $sourceURL, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
            } header: {
                Text(subject.canonicalDisplay)
            } footer: {
                Text("Your note stays on this device in this build. A future editorial export may send it only with your explicit action. It never changes the public account automatically.")
            }

            Section {
                Button("Send to private review queue") {
                    appState.submitPersonalAtlasFeedback(
                        subjectId: subject.id,
                        assertionId: assertionId,
                        kind: kind,
                        context: context,
                        sourceURL: sourceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : sourceURL
                    )
                    submitted = true
                    Haptics.tap()
                }
                .disabled(context.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
            }

            if submitted {
                Section {
                    Label("Saved for editorial review", systemImage: "checkmark.circle")
                        .foregroundStyle(Theme.moss)
                    Button("Done") { dismiss() }
                }
            }
        }
        .navigationTitle("Suggest a correction")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PersonalKeepsakeView: View {
    let subject: OriginSubject

    private var forms: [HistoricalForm] {
        subject.nameProfile?.historicalForms ?? subject.placeProfile?.historicalForms ?? []
    }

    private var shareText: String {
        let journey = forms.map(\.display).joined(separator: " → ")
        return "\(subject.canonicalDisplay) — forms encountered in An Turas: \(journey). A learning record, not a crest or family-history claim."
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(subject.canonicalDisplay)
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text("A record of what you encountered")
                    .font(.headline)
                    .foregroundStyle(Theme.moss)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(forms.enumerated()), id: \.element.id) { index, form in
                        HStack(alignment: .firstTextBaseline, spacing: 14) {
                            Text(form.year.map(String.init) ?? "—")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(Theme.inkFaint)
                                .frame(minWidth: 58, alignment: .leading)
                            Text(form.display)
                                .font(.system(.title3, design: .serif, weight: .semibold))
                                .foregroundStyle(index == forms.indices.last ? Theme.moss : Theme.ink)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 14)
                        if index != forms.indices.last { AtlasRule() }
                    }
                }

                Text("This time-strip uses only forms you encountered in the current content pack. It does not claim a family line, ancestry, ownership, or heraldry.")
                    .font(.callout)
                    .foregroundStyle(Theme.inkSoft)
                    .padding(14)
                    .background(Theme.sunk)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                ShareLink(item: shareText) {
                    Label("Share this learning record", systemImage: "square.and.arrow.up")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(Theme.moss)
            }
            .padding(20)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Keepsake")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PersonalFieldModeView: View {
    let subject: OriginSubject

    private var place: PlaceProfile? { subject.placeProfile }

    var body: some View {
        List {
            Section {
                Text(subject.canonicalDisplay)
                    .font(.system(.title2, design: .serif, weight: .semibold))
                Text(place?.hierarchy ?? subject.subtitle)
                    .foregroundStyle(Theme.inkSoft)
            } header: {
                Text("Offline place pack")
            }

            if let place {
                if let coordinates = place.coordinates {
                    Section("Walking-scale map") {
                        Map(
                            initialPosition: .region(
                                MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(
                                        latitude: coordinates.lat,
                                        longitude: coordinates.lon
                                    ),
                                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                )
                            ),
                            interactionModes: [.pan, .zoom]
                        ) {
                            Marker(
                                subject.canonicalDisplay,
                                coordinate: CLLocationCoordinate2D(
                                    latitude: coordinates.lat,
                                    longitude: coordinates.lon
                                )
                            )
                            .tint(Theme.moss)
                        }
                        .frame(minHeight: 260)
                        .accessibilityHidden(true)
                        Text("\(subject.canonicalDisplay), \(place.placeKind), \(place.hierarchy)")
                            .font(.callout)
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Section("Notice on the ground") {
                    ForEach(place.featureLinks) { feature in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(feature.label)
                                .font(.headline)
                            if let note = feature.note {
                                Text(note).foregroundStyle(Theme.inkSoft)
                            }
                        }
                    }
                    if place.featureLinks.isEmpty {
                        Text("No landscape prompt has passed editorial review for this place yet.")
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }

            Section("Safety and privacy") {
                Label("The bundled pack works without a connection.", systemImage: "arrow.down.circle")
                Label("Your location is not stored in this pack.", systemImage: "location.slash")
                Label("Stop looking at the phone near roads, water, cliffs, or private land.", systemImage: "exclamationmark.triangle")
            }

            Section("Content freshness") {
                Text("Pack content date: \(PersonalAtlasLoader.pack().contentDate)")
                Text("Live source updates wait until you reconnect; an upstream outage never removes this saved result.")
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .navigationTitle("Field mode")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PersonalHistoricMapAlignmentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let subject: OriginSubject
    let layer: PersonalHistoricMapLayer
    @State private var historicOpacity = 0.5

    private var coordinates: PersonalCoordinates? { subject.placeProfile?.coordinates }

    var body: some View {
        if layer.rightsState == "cleared",
           let coordinates,
           let image = UIImage(named: layer.assetName) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    Map(
                        initialPosition: .region(
                            MKCoordinateRegion(
                                center: CLLocationCoordinate2D(
                                    latitude: coordinates.lat,
                                    longitude: coordinates.lon
                                ),
                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                            )
                        ),
                        interactionModes: []
                    ) {
                        Marker(
                            subject.canonicalDisplay,
                            coordinate: CLLocationCoordinate2D(
                                latitude: coordinates.lat,
                                longitude: coordinates.lon
                            )
                        )
                    }
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .opacity(historicOpacity)
                }
                .frame(minHeight: 240)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)

                Slider(
                    value: Binding(
                        get: { historicOpacity },
                        set: { value in
                            if reduceMotion {
                                historicOpacity = value
                            } else {
                                withAnimation(Motion.settle) { historicOpacity = value }
                            }
                        }
                    ),
                    in: 0...1
                ) {
                    Text("Historic map visibility")
                } minimumValueLabel: {
                    Text("Now").font(.caption)
                } maximumValueLabel: {
                    Text(layer.year.map(String.init) ?? "Then").font(.caption)
                }
                .tint(Theme.moss)
                .accessibilityValue("\(Int(historicOpacity * 100)) percent historic map")

                Text(layer.title)
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Theme.ink)
                ForEach(layer.featureNotes, id: \.self) { note in
                    Label(note, systemImage: "mappin.and.ellipse")
                        .font(.callout)
                        .foregroundStyle(Theme.inkSoft)
                }
                Text("\(layer.sourceCitation) · \(layer.attribution)")
                    .font(.caption)
                    .foregroundStyle(Theme.inkFaint)
            }
        }
    }
}

struct FamilyResearchWorksheetView: View {
    let subject: OriginSubject

    @State private var knownPerson = ""
    @State private var knownPlace = ""
    @State private var knownDate = ""
    @State private var source = ""

    private var exportText: String {
        """
        Private family research notes for \(subject.canonicalDisplay)
        Person already known: \(knownPerson)
        Place already known: \(knownPlace)
        Date or period already known: \(knownDate)
        Source or family context: \(source)

        This worksheet records what I supplied. An Turas has not inferred a relationship, migration path, or ancestry.
        """
    }

    var body: some View {
        Form {
            Section {
                Text("A surname history is not your family history. Begin only with facts you already know, then verify them in official records.")
                    .foregroundStyle(Theme.inkSoft)
            }
            Section("What you already know") {
                TextField("Person", text: $knownPerson)
                TextField("Place", text: $knownPlace)
                TextField("Date or period", text: $knownDate)
                TextField("Source or family context", text: $source, axis: .vertical)
                    .lineLimit(3...6)
            }
            Section("Continue with official archives") {
                Link("National Archives census search", destination: URL(string: "https://nationalarchives.ie/collections/search-the-census/")!)
                Link("Irish Genealogy civil and church records", destination: URL(string: "https://www.irishgenealogy.ie/")!)
                Link("National Library parish registers", destination: URL(string: "https://registers.nli.ie/")!)
            }
            Section {
                ShareLink(item: exportText) {
                    Label("Export my worksheet", systemImage: "square.and.arrow.up")
                }
            } footer: {
                Text("Nothing entered here is used to infer relatives or added to product analytics.")
            }
        }
        .navigationTitle("Family research")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PersonalAtlasMethodologyView: View {
    var body: some View {
        List {
            Section("What we can tell") {
                Text("A name page can explain documented forms, language, grammar, likely origins, and patterns in named records. A place page can explain official forms, recorded variants, derivation, and landscape context.")
            }
            Section("What we cannot tell") {
                Text("A surname alone cannot establish your clan, crest, family tree, migration path, or genetic ancestry. A neat modern translation is not automatically a place-name’s historical origin.")
            }
            Section("How claims are reviewed") {
                Text("Every material claim has an evidence state, source reference, scope, reviewer, review date, rights state, and room for competing readings. Disputed, traditional, and unknown material stays visibly qualified.")
            }
            Section("Privacy") {
                Text("Search runs against the local pack. Product events may contain a published subject ID or a coarse no-result reason; they never contain the raw name, a genealogy query, or exact coordinates.")
            }
            Section("Corrections") {
                Text("A correction is a lead for an editor, never a public edit. Conflicting readings remain private until their sources and context have been reviewed.")
            }
            Section("Credits") {
                Text(PersonalAtlasLoader.pack().attribution)
            }
        }
        .navigationTitle("Method and limits")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor
final class CoarseLocationProvider: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    @Published private(set) var coarseCoordinate: CLLocationCoordinate2D?
    @Published private(set) var authorization: CLAuthorizationStatus
    @Published private(set) var errorMessage: String?

    private let manager = CLLocationManager()

    override init() {
        authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    func requestOnce() {
        errorMessage = nil
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            errorMessage = "Location is off. You can still search by place name."
        @unknown default:
            errorMessage = "Location is not available."
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        if authorization == .authorizedAlways || authorization == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let value = locations.last?.coordinate else { return }
        // About 5 km in latitude: useful for nearby suggestions, not a retained fix.
        coarseCoordinate = CLLocationCoordinate2D(
            latitude: (value.latitude * 20).rounded() / 20,
            longitude: (value.longitude * 20).rounded() / 20
        )
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "We couldn’t find nearby places just now. Search still works offline."
    }
}

struct NearbyPersonalPlacesView: View {
    @StateObject private var location = CoarseLocationProvider()
    let onOpenSubject: (String) -> Void

    private var nearby: [OriginSubject] {
        guard let here = location.coarseCoordinate else { return [] }
        let origin = CLLocation(latitude: here.latitude, longitude: here.longitude)
        return PersonalAtlasLoader.pack().subjects
            .filter { $0.kind == .place && $0.placeProfile?.coordinates != nil }
            .sorted { lhs, rhs in
                distance(from: origin, to: lhs) < distance(from: origin, to: rhs)
            }
            .prefix(8)
            .map { $0 }
    }

    var body: some View {
        List {
            Section {
                Text("An Turas asks only after you tap below, reduces the fix to a coarse area, and does not save it.")
                    .foregroundStyle(Theme.inkSoft)
                Button {
                    location.requestOnce()
                } label: {
                    Label("Suggest places near me", systemImage: "location")
                }
            }

            if let message = location.errorMessage {
                Section { Text(message).foregroundStyle(Theme.rust) }
            }

            if !nearby.isEmpty {
                Section("Nearby in the offline place index") {
                    ForEach(nearby) { subject in
                        Button {
                            onOpenSubject(subject.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(subject.canonicalDisplay)
                                    .font(.system(.headline, design: .serif))
                                    .foregroundStyle(Theme.ink)
                                Text(subject.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Places near me")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func distance(from origin: CLLocation, to subject: OriginSubject) -> CLLocationDistance {
        guard let point = subject.placeProfile?.coordinates else { return .greatestFiniteMagnitude }
        return origin.distance(from: CLLocation(latitude: point.lat, longitude: point.lon))
    }
}
