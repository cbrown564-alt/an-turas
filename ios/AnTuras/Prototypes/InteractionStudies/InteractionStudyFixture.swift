import Foundation

enum InteractionStudyCoastRegion: String, CaseIterable, Identifiable {
    case openWater = "open-water"
    case shelteredBay = "sheltered-bay"
    case namedLand = "named-land"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .openWater:
            "Open water"
        case .shelteredBay:
            "Sheltered bay"
        case .namedLand:
            "Named land"
        }
    }
}

struct InteractionStudyWord: Identifiable, Equatable {
    let id: String
    let irish: String
    let english: String
    let region: InteractionStudyCoastRegion
}

struct InteractionStudySentenceToken: Identifiable, Equatable {
    let id: String
    let text: String
    let role: String
}

/// A deliberately narrow projection of the frozen Clew Bay prototype fixture.
/// It exposes only the words, meanings, phrase and audio needed by the studies.
/// Story and historical exposition stay outside this lab.
enum ClewBayInteractionStudyFixture {
    static let words: [InteractionStudyWord] = [
        .init(id: "farraige", irish: "farraige", english: "sea", region: .openWater),
        .init(id: "ba", irish: "bá", english: "bay", region: .shelteredBay),
        .init(id: "ait", irish: "áit", english: "place", region: .namedLand),
    ]

    static let sentenceTokens: [InteractionStudySentenceToken] = [
        .init(id: "is", text: "Is", role: "statement"),
        .init(id: "as", text: "as", role: "from"),
        .init(id: "maigh-eo", text: "Maigh Eo", role: "place"),
        .init(id: "me", text: "mé.", role: "speaker"),
    ]

    static let sentence = ClewBayLearningPrototypeFixture.origin.answer
    static let sentenceTranslation = ClewBayLearningPrototypeFixture.origin.translation ?? ""
}
