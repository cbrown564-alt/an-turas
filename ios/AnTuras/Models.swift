import Foundation

// MARK: - Content models (mirror chapter1.json — the content-as-data pipeline)

struct Chapter: Decodable {
    let title: String
    let subtitle: String
    let sessions: [Session]
}

struct Session: Decodable {
    let ga: String
    let en: String
    let blocks: [Block]

    var exerciseCount: Int {
        blocks.filter(\.isExercise).count
    }
}

struct Gloss: Decodable, Identifiable, Equatable {
    let t: String
    let g: String
    let s: String?
    var id: String { t }
}

struct SceneBlock: Decodable {
    let who: String?
    let paras: [String]
    let glosses: [Gloss]?
}

struct NoteBlock: Decodable {
    let title: String
    let paras: [String]
    let pairs: [String]?
}

struct ChoiceOption: Decodable, Identifiable {
    let txt: String
    let ok: Bool
    let why: String
    var id: String { txt }
}

struct ChoiceBlock: Decodable {
    let prompt: String
    let opts: [ChoiceOption]
}

struct AssembleBlock: Decodable {
    let prompt: String
    let tiles: [String]
    let answer: String
}

enum TypeCheck: String, Decodable {
    case ismise, isas, exact
}

struct TypeInBlock: Decodable {
    let prompt: String
    let placeholder: String
    let check: TypeCheck
    let answer: String?
    let fada: Bool
    let hint: String?
    let capture: Bool?
}

struct MatchBlock: Decodable {
    let prompt: String
    let pairs: [[String]]
}

struct InscriptionBlock: Decodable {
    let word: String
    let caption: String
}

struct SeanfhocalBlock: Decodable {
    let ga: String
    let en: String
    let note: String
}

struct FinBlock: Decodable {
    let paras: [String]
}

enum Block: Decodable {
    case scene(SceneBlock)
    case note(NoteBlock)
    case choice(ChoiceBlock)
    case assemble(AssembleBlock)
    case typein(TypeInBlock)
    case match(MatchBlock)
    case inscription(InscriptionBlock)
    case seanfhocal(SeanfhocalBlock)
    case artifact
    case fin(FinBlock)

    private enum TypeKey: String, CodingKey { case type }

    init(from decoder: Decoder) throws {
        let kind = try decoder.container(keyedBy: TypeKey.self).decode(String.self, forKey: .type)
        switch kind {
        case "scene":       self = .scene(try SceneBlock(from: decoder))
        case "note":        self = .note(try NoteBlock(from: decoder))
        case "choice":      self = .choice(try ChoiceBlock(from: decoder))
        case "assemble":    self = .assemble(try AssembleBlock(from: decoder))
        case "typein":      self = .typein(try TypeInBlock(from: decoder))
        case "match":       self = .match(try MatchBlock(from: decoder))
        case "inscription": self = .inscription(try InscriptionBlock(from: decoder))
        case "seanfhocal":  self = .seanfhocal(try SeanfhocalBlock(from: decoder))
        case "artifact":    self = .artifact
        case "fin":         self = .fin(try FinBlock(from: decoder))
        default:
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Unknown block type: \(kind)"))
        }
    }

    var isExercise: Bool {
        switch self {
        case .choice, .assemble, .typein, .match: return true
        default: return false
        }
    }
}

enum ContentLoader {
    static func chapter1() -> Chapter {
        guard let url = Bundle.main.url(forResource: "chapter1", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let chapter = try? JSONDecoder().decode(Chapter.self, from: data)
        else {
            fatalError("chapter1.json missing or malformed — content is the product; fail loudly.")
        }
        return chapter
    }
}
