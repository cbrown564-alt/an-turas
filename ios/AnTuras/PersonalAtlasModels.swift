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
    private static var cached: PersonalAtlasPack?

    static func pack() -> PersonalAtlasPack {
        if let cached { return cached }
        let loaded: PersonalAtlasPack = decode("personal-atlas-subjects")
        cached = loaded
        return loaded
    }

    static func subject(id: String) -> OriginSubject? {
        pack().subjects.first { $0.id == id }
    }

    static func indexEntry(id: String) -> PersonalIndexEntry? {
        pack().index.first { $0.id == id }
    }

    private static func decode<T: Decodable>(_ resource: String) -> T {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode(T.self, from: data)
        else {
            fatalError("\(resource).json missing or malformed — personal atlas content is the product; fail loudly.")
        }
        return value
    }
}
