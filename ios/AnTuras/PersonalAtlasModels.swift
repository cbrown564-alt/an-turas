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

struct PersonalIndexEntry: Decodable, Identifiable, Hashable {
    let id: String
    let kind: PersonalSubjectKind
    let canonicalDisplay: String
    let subtitle: String
    let variants: [String]
    let searchKeys: [String]
    let depth: PersonalContentDepth
    let nameKind: NameKind?
    let hierarchy: String?
    let placeKind: String?
}

struct OriginSubject: Decodable, Identifiable, Hashable {
    let id: String
    let kind: PersonalSubjectKind
    let canonicalDisplay: String
    let variants: [String]
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
}

struct PersonalPronunciation: Decodable, Hashable {
    let text: String
    let phonetic: String?
    let dialect: String
    let audioState: PersonalAudioState
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
    var id: String { label }
}

struct NameDistribution: Decodable, Hashable {
    let dataset: String
    let year: Int?
    let note: String
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

struct Assertion: Decodable, Hashable, Identifiable {
    let statement: String
    let scope: String
    let certainty: PersonalCertainty
    let evidenceIds: [String]
    let competingAssertionIds: [String]
    let reviewer: String
    let reviewedAt: String
    let rightsState: String
    var id: String { statement }
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
        let key = normalize(query)
        guard !key.isEmpty else { return [] }

        let scored: [(PersonalIndexEntry, Int)] = pack.index.compactMap { entry in
            let keys = entry.searchKeys.map(normalize)
            if keys.contains(key) { return (entry, 0) }
            if keys.contains(where: { $0.hasPrefix(key) }) { return (entry, 1) }
            if keys.contains(where: { $0.contains(key) }) { return (entry, 2) }
            if normalize(entry.canonicalDisplay) == key { return (entry, 0) }
            if entry.variants.map(normalize).contains(key) { return (entry, 0) }
            return nil
        }

        return scored
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 < rhs.1 }
                return lhs.0.canonicalDisplay.localizedCaseInsensitiveCompare(rhs.0.canonicalDisplay) == .orderedAscending
            }
            .map(\.0)
    }
}

// MARK: - Loader

enum PersonalAtlasLoader {
    private static let loaded: Result<PersonalAtlasPack, PersonalAtlasLoadError> = {
        guard let url = Bundle.main.url(forResource: "personal-atlas-subjects", withExtension: "json") else {
            return .failure(.missingResource)
        }
        do {
            let data = try Data(contentsOf: url)
            let pack = try decode(data)
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
        pack().subjects.first { $0.id == id }
    }

    static func indexEntry(id: String) -> PersonalIndexEntry? {
        pack().index.first { $0.id == id }
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
        if indexSet != subjectSet { issues.append("The search index and subject pack do not contain the same ids.") }

        for subject in pack.subjects {
            let evidenceIds = Set(subject.evidence.map(\.id))
            if evidenceIds.count != subject.evidence.count {
                issues.append("\(subject.id) contains duplicate evidence ids.")
            }
            for assertion in subject.assertions {
                let missing = assertion.evidenceIds.filter { !evidenceIds.contains($0) }
                if !missing.isEmpty {
                    issues.append("\(subject.id) references missing evidence: \(missing.joined(separator: ", ")).")
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
