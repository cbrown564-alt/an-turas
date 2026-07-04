import Foundation

// MARK: - Content models (mirror chapter1.json — the content-as-data pipeline)
// A session is a sequence of authored pages. The page break is an editorial
// decision — a beat the learner sits with — not a rendering heuristic.

struct Chapter: Decodable {
    let title: String
    let subtitle: String
    let sessions: [Session]
}

struct Session: Decodable {
    let ga: String
    let en: String
    let pages: [Page]

    var exerciseCount: Int {
        pages.filter(\.isExercise).count
    }
}

struct Gloss: Decodable, Identifiable, Equatable {
    let t: String
    let g: String
    let s: String?
    var id: String { t }
}

// MARK: Scene pages — narration and spoken Irish are different materials

/// One paragraph of a scene. Speech beats are reserved for Irish said aloud —
/// they carry speaker, meaning and rough sound as data so the UI can set the
/// line large and make it tappable. English dialogue stays inside narration.
enum Beat: Decodable {
    case narration(NarrationBeat)
    case speech(SpeechBeat)

    private enum Keys: String, CodingKey { case n, s }

    init(from decoder: Decoder) throws {
        let keys = try decoder.container(keyedBy: Keys.self)
        if keys.contains(.s) {
            self = .speech(try SpeechBeat(from: decoder))
        } else {
            self = .narration(try NarrationBeat(from: decoder))
        }
    }
}

struct NarrationBeat: Decodable {
    let n: String
    let glosses: [Gloss]?
}

struct SpeechBeat: Decodable {
    let s: String
    let who: String?
    let g: String
    let ph: String?

    var gloss: Gloss { Gloss(t: s, g: g, s: ph) }
}

struct ScenePage: Decodable {
    /// Slugline — set when the scene's place or time changes.
    let place: String?
    let beats: [Beat]
}

// MARK: Turn pages — the scene pauses on your line

/// One reply the learner can give. Every reply is acceptable Irish — the
/// choice is social, not right/wrong — and the scene answers each one
/// differently. `{name}` interpolates the learner's captured name.
struct TurnReply: Decodable, Identifiable {
    let s: String
    let ph: String?
    let g: String
    let reaction: [Beat]
    var id: String { s }
}

/// A scene page whose last beat belongs to the learner: lead-in beats, then
/// chalk-outlined replies. Choosing carves your line into the dialogue and
/// the conversation answers. Gates the page turn like an exercise — the
/// scene cannot continue until you have spoken.
struct TurnBlock: Decodable {
    let place: String?
    let beats: [Beat]
    let cue: String?
    let replies: [TurnReply]
}

// MARK: Other page payloads

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
    let context: String?
    let prompt: String
    let opts: [ChoiceOption]
}

struct AssembleBlock: Decodable {
    let context: String?
    let prompt: String
    let tiles: [String]
    let answer: String
}

enum TypeCheck: String, Decodable {
    case ismise, isas, exact
}

struct TypeInBlock: Decodable {
    let context: String?
    let prompt: String
    let placeholder: String
    let check: TypeCheck
    let answer: String?
    let fada: Bool
    let hint: String?
    let capture: Bool?
}

struct MatchBlock: Decodable {
    let context: String?
    let prompt: String
    let pairs: [[String]]
}

/// Ear before eye: the prompt is audio — the learner picks the written form
/// they heard. Falls back to a skip affordance when the device has no voice.
struct ListenBlock: Decodable {
    let context: String?
    let prompt: String
    let say: String
    let opts: [ChoiceOption]
}

/// Say it aloud, hear yourself beside the model. No grading — carvers learn
/// by ear, and pronunciation scoring is deliberately punted (STRATEGY U8).
struct EchoBlock: Decodable {
    let context: String?
    let s: String
    let who: String?
    let g: String
    let ph: String?

    var beat: SpeechBeat { SpeechBeat(s: s, who: who, g: g, ph: ph) }
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

// MARK: The page

/// Which of the app's registers a page belongs to. Each register has its own
/// composition: scenes read like a book page, notes like a manual page,
/// exercises put your hand on the chisel, features stand alone.
enum PageRegister {
    case scene, note, exercise, feature
}

enum Page: Decodable {
    case scene(ScenePage)
    case note(NoteBlock)
    case choice(ChoiceBlock)
    case assemble(AssembleBlock)
    case typein(TypeInBlock)
    case match(MatchBlock)
    case listen(ListenBlock)
    case echo(EchoBlock)
    case turn(TurnBlock)
    case inscription(InscriptionBlock)
    case seanfhocal(SeanfhocalBlock)
    case artifact
    case fin(FinBlock)

    private enum TypeKey: String, CodingKey { case type }

    init(from decoder: Decoder) throws {
        let kind = try decoder.container(keyedBy: TypeKey.self).decode(String.self, forKey: .type)
        switch kind {
        case "scene":       self = .scene(try ScenePage(from: decoder))
        case "note":        self = .note(try NoteBlock(from: decoder))
        case "choice":      self = .choice(try ChoiceBlock(from: decoder))
        case "assemble":    self = .assemble(try AssembleBlock(from: decoder))
        case "typein":      self = .typein(try TypeInBlock(from: decoder))
        case "match":       self = .match(try MatchBlock(from: decoder))
        case "listen":      self = .listen(try ListenBlock(from: decoder))
        case "echo":        self = .echo(try EchoBlock(from: decoder))
        case "turn":        self = .turn(try TurnBlock(from: decoder))
        case "inscription": self = .inscription(try InscriptionBlock(from: decoder))
        case "seanfhocal":  self = .seanfhocal(try SeanfhocalBlock(from: decoder))
        case "artifact":    self = .artifact
        case "fin":         self = .fin(try FinBlock(from: decoder))
        default:
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Unknown page type: \(kind)"))
        }
    }

    var isExercise: Bool {
        switch self {
        case .choice, .assemble, .typein, .match, .listen, .echo, .turn: return true
        default: return false
        }
    }

    var register: PageRegister {
        switch self {
        // A turn reads as story, not drill — it composes like a scene.
        case .scene, .turn: return .scene
        case .note: return .note
        case .choice, .assemble, .typein, .match, .listen, .echo: return .exercise
        case .inscription, .seanfhocal, .artifact, .fin: return .feature
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
