import Foundation
import SwiftUI

// MARK: - Personal atlas content graph
// Mirrors docs/PERSONAL-HISTORIES-FEATURE-PLAN.md — typed subjects, assertions,
// evidence, and editorial layers. Pilot packs ship as bundled JSON.

enum PersonalSubjectKind: String, Codable, Hashable {
    case name
    case place
}

enum PersonalContentDepth: String, Codable, Hashable {
    case authored
    case foundation
}

enum NameKind: String, Codable, Hashable {
    case given
    case surname
}

enum PersonalVariantRelationship: String, Codable, Hashable {
    case anglicised
    case translated
    case genderedForm
    case historicSpelling
    case localForm
    case contestedForm
    case relatedForm

    var label: String {
        switch self {
        case .anglicised: return "Anglicised form"
        case .translated: return "Translated form"
        case .genderedForm: return "Gendered form"
        case .historicSpelling: return "Historic spelling"
        case .localForm: return "Local form"
        case .contestedForm: return "Contested public form"
        case .relatedForm: return "Related form"
        }
    }
}

struct PersonalVariant: Codable, Hashable {
    let display: String
    let relationship: PersonalVariantRelationship
    let note: String?
}

/// Evidence labels for personal histories — moss/lichen/rust, not atlas progress colours.
enum PersonalCertainty: String, Codable, CaseIterable, Hashable {
    case recorded
    case supportedInterpretation
    case possible
    case localTradition
    case disputed
    case unknown

    var label: String {
        switch self {
        case .recorded: return "RECORDED"
        case .supportedInterpretation: return "SUPPORTED INTERPRETATION"
        case .possible: return "POSSIBLE"
        case .localTradition: return "LOCAL TRADITION"
        case .disputed: return "DISPUTED"
        case .unknown: return "UNKNOWN"
        }
    }

    var color: Color {
        switch self {
        case .recorded: return Theme.moss
        case .supportedInterpretation: return Theme.lichen
        case .possible: return Color(light: 0x476B7A, dark: 0x8BB8C8)
        case .localTradition: return Color(light: 0x75568B, dark: 0xBDA0CF)
        case .disputed: return Theme.rust
        case .unknown: return Theme.stone
        }
    }

    var symbolName: String {
        switch self {
        case .recorded: return "doc.text"
        case .supportedInterpretation: return "info.circle"
        case .possible, .unknown: return "questionmark.circle"
        case .localTradition: return "quote.bubble"
        case .disputed: return "arrow.triangle.branch"
        }
    }

    var detail: String {
        switch self {
        case .recorded:
            return "The cited source records this directly."
        case .supportedInterpretation:
            return "This is an editorial reading of the cited evidence."
        case .possible:
            return "The evidence allows this reading, but does not settle it."
        case .localTradition:
            return "This comes from a named tradition rather than a direct historical record."
        case .disputed:
            return "More than one consequential reading remains in use."
        case .unknown:
            return "The available evidence does not support a settled reading."
        }
    }
}

enum PersonalAudioState: String, Codable, Hashable {
    case verified
    case unverified
    case unavailable
}

struct PersonalAtlasPack: Decodable {
    let version: String
    let contentDate: String
    let attribution: String
    let coverageNote: String
    let index: [PersonalIndexEntry]
    let subjects: [OriginSubject]
}

struct PersonalFoundationPlace: Decodable, Hashable {
    let logainmId: Int
    let irishForm: String?
    let englishForm: String?
    let placeKind: String
    let hierarchy: String
    let coordinates: PersonalCoordinates?
    let permalink: String
    let modifiedAt: String?
    let attribution: String
    let hierarchyRepairs: [PersonalHierarchyRepair]?
}

struct PersonalHierarchyRepair: Decodable, Hashable {
    let county: String
    let method: String
    let sources: [String]
}

struct PersonalIndexEntry: Decodable, Identifiable, Hashable {
    let id: String
    let kind: PersonalSubjectKind
    let canonicalDisplay: String
    let subtitle: String
    let variants: [String]
    let variantRelationships: [PersonalVariant]?
    let searchKeys: [String]
    let depth: PersonalContentDepth
    let nameKind: NameKind?
    let hierarchy: String?
    let placeKind: String?
    let foundation: PersonalFoundationPlace?
}

struct OriginSubject: Decodable, Identifiable, Hashable {
    let id: String
    let kind: PersonalSubjectKind
    let canonicalDisplay: String
    let variants: [String]
    let variantRelationships: [PersonalVariant]?
    let languages: [String]
    let searchKeys: [String]
    let subtitle: String
    let depth: PersonalContentDepth
    let nameProfile: NameProfile?
    let placeProfile: PlaceProfile?
    let editorial: EditorialLayer
    let assertions: [Assertion]
    let evidence: [Evidence]

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: OriginSubject, rhs: OriginSubject) -> Bool { lhs.id == rhs.id }
}

struct NameProfile: Decodable, Hashable {
    let nameKind: NameKind
    let grammar: String?
    let pronunciations: [PersonalPronunciation]
    let historicalForms: [HistoricalForm]
    let etymologyBranches: [EtymologyBranch]
    let distributions: [NameDistribution]
    let peopleLinks: [PersonalLink]
    let travelMoments: [NameTravelMoment]?
}

struct NameTravelMoment: Decodable, Hashable, Identifiable {
    let id: String
    let form: String
    let year: Int?
    let place: String
    let sourceLabel: String
    let evidenceId: String
    let note: String
}

struct PlaceProfile: Decodable, Hashable {
    let logainmId: Int?
    let placeKind: String
    let hierarchy: String
    let coordinates: PersonalCoordinates?
    let pronunciations: [PersonalPronunciation]
    let historicalForms: [HistoricalForm]
    let derivationBranches: [EtymologyBranch]
    let featureLinks: [FeatureLink]
    let storyLinks: [PersonalLink]
    let historicMapLayers: [PersonalHistoricMapLayer]?
}

struct PersonalHistoricMapLayer: Decodable, Hashable, Identifiable {
    let id: String
    let title: String
    let year: Int?
    let assetName: String
    let sourceCitation: String
    let attribution: String
    let rightsState: String
    let featureNotes: [String]
}

struct PersonalPronunciation: Decodable, Hashable {
    let text: String
    let phonetic: String?
    let dialect: String
    let audioState: PersonalAudioState
    let audio: PersonalAudioAsset?
}

struct PersonalAudioAsset: Decodable, Hashable {
    let assetName: String
    let speaker: String
    let dialect: String
    let recordedAt: String
    let permissionState: String
    let transcript: String
    let translation: String?
}

struct HistoricalForm: Decodable, Hashable, Identifiable {
    let display: String
    let year: Int?
    let note: String?
    let language: String
    var id: String { "\(display)-\(year.map(String.init) ?? "x")-\(language)" }
}

struct WordComponent: Decodable, Hashable {
    let ga: String
    let en: String
}

struct EtymologyBranch: Decodable, Hashable, Identifiable {
    let label: String
    let certainty: PersonalCertainty
    let summary: String
    let components: [WordComponent]
    let assertionId: String?
    var id: String { label }
}

struct NameDistribution: Decodable, Hashable {
    let dataset: String
    let year: Int?
    let note: String
    let geography: String?
    let count: Int?
    let suppressed: Bool?
    let sourceURL: String?
}

struct PersonalLink: Decodable, Hashable, Identifiable {
    let id: String?
    let label: String
    let route: String?
    var resolvedId: String { id ?? "\(label)-\(route ?? "")" }
}

struct FeatureLink: Decodable, Hashable, Identifiable {
    let label: String
    let note: String?
    var id: String { label }
}

struct PersonalCoordinates: Decodable, Hashable {
    let lat: Double
    let lon: Double
}

struct EditorialLayer: Decodable, Hashable {
    let shortAnswer: String
    let storyBeats: [String]
    let languageMoment: LanguageMoment?
    let saveExcerpt: String
    let contentVersion: String
    let releaseState: String
    let storyHandoff: StoryHandoff?
    let deeperStoryMessage: String?
    let familyHistoryNote: String?
    let shortAnswerAssertionId: String?
    let communityEdition: PersonalCommunityEdition?
}

struct PersonalCommunityEdition: Decodable, Hashable {
    let title: String
    let partner: String
    let editor: String
    let reviewer: String
    let credit: String
    let consentState: String
    let agreementReference: String
    let correctionURL: String
}

struct LanguageMoment: Decodable, Hashable {
    let ga: String
    let en: String
    let note: String?
}

struct StoryHandoff: Decodable, Hashable {
    let route: String
    let label: String
}

struct AssertionReview: Codable, Hashable, Identifiable {
    let reviewer: String
    let reviewedAt: String
    let decision: String
    let note: String?
    var id: String { "\(reviewer)-\(reviewedAt)-\(decision)" }
}

struct Assertion: Decodable, Hashable, Identifiable {
    let assertionId: String?
    let statement: String
    let scope: String
    let certainty: PersonalCertainty
    let evidenceIds: [String]
    let competingAssertionIds: [String]
    let reviewer: String
    let reviewedAt: String
    let rightsState: String
    let reviewHistory: [AssertionReview]?
    var id: String { assertionId ?? statement }
}

struct Evidence: Decodable, Hashable, Identifiable {
    let id: String
    let sourceType: String
    let citation: String
    let stableURL: String?
    let dateBounds: String?
    let attribution: String
    let transcription: String?
    let translation: String?
    let imageRights: String?
    let audioRights: String?
}

// MARK: - Search

enum PersonalSearch {
    /// Diacritic-insensitive match that preserves the entered form for display.
    static func normalize(_ raw: String) -> String {
        let folded = raw.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_IE"))
        let scalars = folded.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) || scalar == " " {
                return Character(scalar)
            }
            // Keep apostrophes out of the key but allow Mac/Mc continuity via letters only.
            return Character(" ")
        }
        return String(scalars)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .lowercased()
    }

    static func matches(query: String, in pack: PersonalAtlasPack) -> [PersonalIndexEntry] {
        PersonalSearchEngine(pack: pack).matches(query: query)
    }
}

struct PersonalSearchEngine {
    private struct Document {
        let entry: PersonalIndexEntry
        let keys: Set<String>
    }

    private let documents: [Document]
    private let exact: [String: [PersonalIndexEntry]]
    private let foundationStore: PersonalFoundationStore?

    init(pack: PersonalAtlasPack, foundationStore: PersonalFoundationStore? = PersonalAtlasLoader.foundationStore) {
        let builtDocuments = pack.index.map { entry in
            let values = entry.searchKeys + entry.variants + [entry.canonicalDisplay]
            return Document(entry: entry, keys: Set(values.map(PersonalSearch.normalize)))
        }
        var exact: [String: [PersonalIndexEntry]] = [:]
        for document in builtDocuments {
            for key in document.keys where !key.isEmpty {
                exact[key, default: []].append(document.entry)
            }
        }
        self.documents = builtDocuments
        self.exact = exact
        self.foundationStore = foundationStore
    }

    func matches(query: String, includeFoundation: Bool = true) -> [PersonalIndexEntry] {
        let key = PersonalSearch.normalize(query)
        guard !key.isEmpty else { return [] }
        let exactIds = Set((exact[key] ?? []).map(\.id))
        let scored: [(PersonalIndexEntry, Int)] = documents.compactMap { document in
            if exactIds.contains(document.entry.id) { return (document.entry, 0) }
            if document.keys.contains(where: { $0.hasPrefix(key) }) { return (document.entry, 1) }
            if document.keys.contains(where: { $0.contains(key) }) { return (document.entry, 2) }
            return nil
        }
        let core = scored.sorted { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 < rhs.1 }
            return lhs.0.canonicalDisplay.localizedCaseInsensitiveCompare(rhs.0.canonicalDisplay) == .orderedAscending
        }.map(\.0)
        let coreIds = Set(core.map(\.id))
        guard includeFoundation else { return core }
        return core + (foundationStore?.matches(query: query) ?? []).filter { !coreIds.contains($0.id) }
    }
}

// MARK: - Share and app deep links

enum PersonalAtlasDeepLink {
    static func webURL(for subjectId: String) -> URL? {
        var components = URLComponents(string: "https://anturas.ie/personal-atlas/")
        components?.queryItems = [URLQueryItem(name: "subject", value: subjectId)]
        return components?.url
    }

    static func subjectID(from url: URL) -> String? {
        if url.scheme?.lowercased() == "anturas", url.host?.lowercased() == "personal" {
            let id = url.pathComponents.dropFirst().joined(separator: "/")
            return id.isEmpty ? nil : id
        }

        guard ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              url.host?.lowercased() == "anturas.ie",
              url.path.hasPrefix("/personal-atlas")
        else { return nil }
        return URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "subject" })?
            .value
    }
}

// MARK: - Loader

enum PersonalAtlasLoader {
    static let foundationStore = PersonalFoundationStore.bundled()

    private static let loaded: Result<PersonalAtlasPack, PersonalAtlasLoadError> = {
        guard let url = Bundle.main.url(forResource: "personal-atlas-subjects", withExtension: "json") else {
            return .failure(.missingResource)
        }
        do {
            let data = try Data(contentsOf: url)
            var pack = try decode(data)
            if let foundation = foundationStore?.metadata {
                pack = PersonalAtlasPack(
                    version: pack.version,
                    contentDate: max(pack.contentDate, foundation.contentDate),
                    attribution: pack.attribution + " " + foundation.attribution,
                    coverageNote: pack.coverageNote,
                    index: pack.index,
                    subjects: pack.subjects
                )
            }
            let issues = validate(pack)
            guard issues.isEmpty else { return .failure(.invalidContent(issues)) }
            return .success(pack)
        } catch let error as PersonalAtlasLoadError {
            return .failure(error)
        } catch {
            return .failure(.malformedContent(error.localizedDescription))
        }
    }()

    static func pack() -> PersonalAtlasPack {
        switch loaded {
        case .success(let pack): return pack
        case .failure: return fallbackPack
        }
    }

    static var loadErrorMessage: String? {
        guard case .failure(let error) = loaded else { return nil }
        return error.errorDescription
    }

    static func subject(id: String) -> OriginSubject? {
        if let subject = pack().subjects.first(where: { $0.id == id }) {
            return subject
        }
        guard let entry = indexEntry(id: id), let foundation = entry.foundation else {
            return nil
        }
        return foundationSubject(entry: entry, place: foundation)
    }

    static func indexEntry(id: String) -> PersonalIndexEntry? {
        pack().index.first { $0.id == id } ?? foundationStore?.entry(id: id)
    }

    static func decode(_ data: Data) throws -> PersonalAtlasPack {
        do {
            return try JSONDecoder().decode(PersonalAtlasPack.self, from: data)
        } catch {
            throw PersonalAtlasLoadError.malformedContent(error.localizedDescription)
        }
    }

    static func validate(_ pack: PersonalAtlasPack) -> [String] {
        var issues: [String] = []
        let indexIds = pack.index.map(\.id)
        let subjectIds = pack.subjects.map(\.id)
        let indexSet = Set(indexIds)
        let subjectSet = Set(subjectIds)

        if indexSet.count != indexIds.count { issues.append("The search index contains duplicate ids.") }
        if subjectSet.count != subjectIds.count { issues.append("The subject pack contains duplicate ids.") }
        if !subjectSet.isSubset(of: indexSet) {
            issues.append("The search index is missing one or more bundled subjects.")
        }
        for entry in pack.index where !subjectSet.contains(entry.id) && entry.foundation == nil {
            issues.append("\(entry.id) has neither a bundled subject nor a foundation record.")
        }

        for subject in pack.subjects {
            let evidenceIds = Set(subject.evidence.map(\.id))
            let assertionIds = Set(subject.assertions.map(\.id))
            if evidenceIds.count != subject.evidence.count {
                issues.append("\(subject.id) contains duplicate evidence ids.")
            }
            for assertion in subject.assertions {
                if assertion.statement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    issues.append("\(subject.id) contains an empty assertion.")
                }
                if assertion.evidenceIds.isEmpty {
                    issues.append("\(subject.id) contains an assertion without evidence.")
                }
                if assertion.reviewer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || assertion.reviewedAt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || assertion.rightsState.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    issues.append("\(subject.id) contains an assertion without review or rights metadata.")
                }
                let missing = assertion.evidenceIds.filter { !evidenceIds.contains($0) }
                if !missing.isEmpty {
                    issues.append("\(subject.id) references missing evidence: \(missing.joined(separator: ", ")).")
                }
                let missingCompetitors = assertion.competingAssertionIds.filter { !assertionIds.contains($0) }
                if !missingCompetitors.isEmpty {
                    issues.append("\(subject.id) references missing competing assertions: \(missingCompetitors.joined(separator: ", ")).")
                }
            }
            if subject.depth == .foundation,
               subject.editorial.deeperStoryMessage?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                issues.append("\(subject.id) is a foundation result without an honest deeper-story state.")
            }
            let pronunciations = subject.nameProfile?.pronunciations
                ?? subject.placeProfile?.pronunciations
                ?? []
            for pronunciation in pronunciations where pronunciation.audioState == .verified {
                guard let audio = pronunciation.audio,
                      !audio.assetName.isEmpty,
                      !audio.speaker.isEmpty,
                      !audio.dialect.isEmpty,
                      !audio.recordedAt.isEmpty,
                      !audio.permissionState.isEmpty,
                      !audio.transcript.isEmpty else {
                    issues.append("\(subject.id) marks audio verified without complete speaker, permission, and transcript metadata.")
                    continue
                }
            }
            if subject.editorial.releaseState == "public" {
                let typed = Set(subject.variantRelationships?.map { PersonalSearch.normalize($0.display) } ?? [])
                let untyped = subject.variants
                    .filter { PersonalSearch.normalize($0) != PersonalSearch.normalize(subject.canonicalDisplay) }
                    .filter { !typed.contains(PersonalSearch.normalize($0)) }
                if !untyped.isEmpty {
                    issues.append("\(subject.id) has untyped public variants: \(untyped.joined(separator: ", ")).")
                }
                if let shortAnswerId = subject.editorial.shortAnswerAssertionId {
                    if !assertionIds.contains(shortAnswerId) {
                        issues.append("\(subject.id) has a missing short-answer assertion.")
                    }
                } else {
                    issues.append("\(subject.id) has no short-answer assertion mapping.")
                }
                let branches = subject.nameProfile?.etymologyBranches
                    ?? subject.placeProfile?.derivationBranches
                    ?? []
                for branch in branches where branch.assertionId == nil
                    || !assertionIds.contains(branch.assertionId ?? "") {
                    issues.append("\(subject.id) has an unmapped public branch: \(branch.label).")
                }
                for moment in subject.nameProfile?.travelMoments ?? []
                    where !evidenceIds.contains(moment.evidenceId) {
                    issues.append("\(subject.id) has a name-travel moment without evidence: \(moment.id).")
                }
                for assertion in subject.assertions where assertion.reviewHistory?.isEmpty != false {
                    issues.append("\(subject.id) has no public review history for assertion \(assertion.id).")
                }
                for layer in subject.placeProfile?.historicMapLayers ?? []
                    where layer.rightsState != "cleared" {
                    issues.append("\(subject.id) has an uncleared historic map layer: \(layer.id).")
                }
                if let edition = subject.editorial.communityEdition,
                   edition.consentState != "agreed"
                    || edition.partner.isEmpty
                    || edition.editor.isEmpty
                    || edition.reviewer.isEmpty
                    || edition.credit.isEmpty
                    || edition.agreementReference.isEmpty
                    || edition.correctionURL.isEmpty {
                    issues.append("\(subject.id) has an incomplete community-edition agreement.")
                }
            }
        }
        return issues
    }

    private static let fallbackPack = PersonalAtlasPack(
        version: "unavailable",
        contentDate: "",
        attribution: "",
        coverageNote: "The personal atlas could not be opened.",
        index: [],
        subjects: []
    )

    static func foundationSubject(
        entry: PersonalIndexEntry,
        place: PersonalFoundationPlace
    ) -> OriginSubject {
        let forms = [place.irishForm, place.englishForm].compactMap { $0 }
        let statement = "Logainm records \(forms.joined(separator: " / ")) as a \(place.placeKind) in \(place.hierarchy)."
        let assertionId = "assertion.\(entry.id).official-forms"
        let evidenceId = "evidence.\(entry.id).logainm"
        return OriginSubject(
            id: entry.id,
            kind: .place,
            canonicalDisplay: entry.canonicalDisplay,
            variants: entry.variants,
            variantRelationships: entry.variantRelationships,
            languages: [place.irishForm == nil ? nil : "ga", place.englishForm == nil ? nil : "en"].compactMap { $0 },
            searchKeys: entry.searchKeys,
            subtitle: entry.subtitle,
            depth: .foundation,
            nameProfile: nil,
            placeProfile: PlaceProfile(
                logainmId: place.logainmId,
                placeKind: place.placeKind,
                hierarchy: place.hierarchy,
                coordinates: place.coordinates,
                pronunciations: [],
                historicalForms: [],
                derivationBranches: [],
                featureLinks: [],
                storyLinks: [],
                historicMapLayers: nil
            ),
            editorial: EditorialLayer(
                shortAnswer: statement + " The deeper story is still being researched.",
                storyBeats: [],
                languageMoment: nil,
                saveExcerpt: statement,
                contentVersion: entry.id + "@" + (place.modifiedAt ?? "foundation"),
                releaseState: "foundation",
                storyHandoff: nil,
                deeperStoryMessage: "The deeper story is still being researched.",
                familyHistoryNote: nil,
                shortAnswerAssertionId: assertionId,
                communityEdition: nil
            ),
            assertions: [
                Assertion(
                    assertionId: assertionId,
                    statement: statement,
                    scope: place.hierarchy,
                    certainty: .recorded,
                    evidenceIds: [evidenceId],
                    competingAssertionIds: [],
                    reviewer: "Logainm foundation import",
                    reviewedAt: place.modifiedAt ?? "Source record date unavailable",
                    rightsState: "CC BY 4.0",
                    reviewHistory: nil
                )
            ],
            evidence: [
                Evidence(
                    id: evidenceId,
                    sourceType: "official-place-index",
                    citation: "Logainm record \(place.logainmId)",
                    stableURL: place.permalink,
                    dateBounds: place.modifiedAt,
                    attribution: place.attribution,
                    transcription: nil,
                    translation: nil,
                    imageRights: nil,
                    audioRights: nil
                )
            ]
        )
    }
}

enum PersonalAtlasLoadError: Error, LocalizedError {
    case missingResource
    case malformedContent(String)
    case invalidContent([String])

    var errorDescription: String? {
        switch self {
        case .missingResource:
            return "The personal atlas is not included in this build."
        case .malformedContent:
            return "The personal atlas could not be read."
        case .invalidContent:
            return "The personal atlas did not pass its content checks."
        }
    }
}
