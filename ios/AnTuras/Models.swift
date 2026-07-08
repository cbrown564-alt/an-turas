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
    /// The amárach tease shown on this session's completion page — the
    /// cliffhanger that names tomorrow's reason to return.
    let hook: String?
    let pages: [Page]

    var exerciseCount: Int {
        pages.filter(\.isExercise).count
    }
}

struct Gloss: Decodable, Identifiable, Equatable {
    let t: String
    let g: String
    let s: String?
    /// Optional id into the shared lexicon (see DRILL.md). A gloss is a *view*
    /// of a lexeme; this ties its appearances together. Defaulted so existing
    /// content decodes unchanged.
    var ref: String? = nil
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
    /// Optional id into the shared lexicon (see DRILL.md). Defaulted so existing
    /// content decodes unchanged.
    var ref: String? = nil

    var gloss: Gloss { Gloss(t: s, g: g, s: ph, ref: ref) }
}

struct ScenePage: Decodable {
    /// Slugline — set when the scene's place or time changes.
    let place: String?
    let image: String?
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
    /// Stable handle so a `Pattern.note` (and, later, a `discover`) can point at
    /// the An Nóta Gramadaí page that teaches it in prose. Optional and absent on
    /// most notes — only the ones a pattern references need one (see DRILL.md).
    let id: String?
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

/// One weathered phrase on the path back: the learner re-types it (fadas
/// and all) to restore the groove. Vowels erode first — in ogham they are
/// the smallest notches on the stemline — so the weathered display drops
/// them and the English cue plus what remains carries the retrieval.
struct RecarveItem: Decodable, Identifiable {
    let answer: String
    let en: String
    let from: String?
    var id: String { answer }
}

/// Review dressed as return, never as card debt (SPINE rule 6): sessions
/// 2–5 open on the path back past earlier stones, weathered by the wind.
struct RecarveBlock: Decodable {
    let intro: String?
    let items: [RecarveItem]
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

/// The placename lens: an anglicized name peels back to the Irish poem
/// hiding inside it — the single best culture↔language bridge we have
/// (STRATEGY §5). English spelling is chalk; the Irish beneath is carved.
struct LensPart: Decodable, Identifiable {
    let ga: String
    let en: String
    var id: String { ga }
}

struct LensBlock: Decodable {
    let en: String
    let ga: String
    let parts: [LensPart]
    let meaning: String
    let note: String?
}

struct SeanfhocalBlock: Decodable {
    let ga: String
    let en: String
    let note: String
}

struct FinBlock: Decodable {
    let paras: [String]
}

// MARK: Discover — rules learned by induction (Brilliant model; see DRILL.md)

/// One step of a discovery sequence. A step with `prompt` is a *produce* step —
/// the learner completes the case before the rule is named. Otherwise it `show`s
/// a worked case. Reveal, reveal, then withhold: the learner induces the rule.
struct DiscoverStep: Decodable, Identifiable {
    /// A worked transformation shown to the learner ("cat → mo chat").
    let show: String?
    /// A withheld case the learner completes ("garraí → mo ___").
    let prompt: String?
    /// Expected production for a `prompt` step.
    let answer: String?
    var id: String { show ?? prompt ?? answer ?? "" }
}

/// A guided-discovery page: the learner produces the pattern before it is
/// stated. `teach` (the plain rule) is revealed only after the produce step.
struct DiscoverBlock: Decodable {
    /// Id into the pattern bank this sequence teaches (see DRILL.md).
    let pattern: String?
    /// Plain statement of the rule — shown only after the learner has produced it.
    let teach: String
    let context: String?
    let steps: [DiscoverStep]
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
    case recarve(RecarveBlock)
    case discover(DiscoverBlock)
    case lens(LensBlock)
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
        case "recarve":     self = .recarve(try RecarveBlock(from: decoder))
        case "discover":    self = .discover(try DiscoverBlock(from: decoder))
        case "lens":        self = .lens(try LensBlock(from: decoder))
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
        case .choice, .assemble, .typein, .match, .listen, .echo, .turn, .recarve, .discover:
            return true
        default:
            return false
        }
    }

    var register: PageRegister {
        switch self {
        // A turn reads as story, not drill — it composes like a scene.
        case .scene, .turn: return .scene
        case .note: return .note
        case .choice, .assemble, .typein, .match, .listen, .echo, .recarve, .discover:
            return .exercise
        case .lens, .inscription, .seanfhocal, .artifact, .fin: return .feature
        }
    }
}

// MARK: - The journey (journey.json — the 13-chapter spine as data)

/// One chapter of the historical spine as it appears on the island map and
/// in the museum: a place, an era, a promise, and the artifact it leaves.
struct JourneyChapter: Decodable, Identifiable {
    let n: Int
    let ga: String
    let en: String
    let placeGa: String
    let placeEn: String
    let era: String
    let lat: Double
    let lon: Double
    /// Which side of the waypoint its label sits on: above/below/left/right.
    let side: String
    let hook: String
    let payload: String
    let artifactGa: String
    let artifactEn: String
    let glyph: String

    var id: Int { n }
}

// MARK: - Ar Ais visits (authored in chapter1.json beside the content they review)

/// One person or place that will ask for the learner again. The scheduler
/// underneath is plumbing; this is the clothing — review as visiting,
/// never as card debt (SPINE rule 6).
struct Visit: Decodable, Identifiable {
    let id: String
    /// Session index (0-based) whose completion puts this visit on the road.
    let session: Int
    let who: String
    let `where`: String
    let frame: String
    let en: String
    let answer: String
    let check: TypeCheck
    /// How the phrase is shown before weathering when the answer is a
    /// pattern, not a fixed string ("Is mise …"). Defaults to the answer.
    let display: String?

    var displayPhrase: String { display ?? answer }
}

// MARK: - The shared item spine (lexicon + patterns — see DRILL.md)

/// Where the story first earns an item — the backlink a drill card shows and the
/// invariant that keeps drill downstream of story ("from Dáire's yard, s.3").
struct ContentRef: Decodable, Equatable {
    let chapter: Int
    let session: Int?
}

/// A single vocabulary item with a stable id — the atom both surfaces share.
/// Story beats reference these (via `Gloss.ref` / `SpeechBeat.ref`); the drill
/// deck schedules them. Authored per chapter beside the scene that earns it and
/// merged into one bank at load, mirroring how `Visit`s are handled.
struct Lexeme: Decodable, Identifiable {
    let id: String
    let ga: String
    let en: String
    let ph: String?
    /// word · phrase · pattern-instance — shapes how the deck drills it.
    let kind: String?
    let tags: [String]?
    /// Dialect this form belongs to; variants share a `lemma`. Connacht ships
    /// first (SPINE rule 5 / STRATEGY D2).
    let dialect: String?
    let lemma: String?
    let earnedAt: ContentRef?
}

/// How a pattern slot is filled: an explicit list, or every lexeme carrying a
/// given tag (so fills stay in sync with the lexicon).
struct PatternSlot: Decodable {
    let options: [String]?
    let fromTag: String?
}

/// A grammatical rule with a fillable frame. The drill surface generates
/// substitution items by rotating slot fills drawn from the lexicon, so grammar
/// practice reinforces vocabulary. `note` is a forward reference to the
/// An Nóta Gramadaí page that teaches it once notes carry ids (see DRILL.md).
struct Pattern: Decodable, Identifiable {
    let id: String
    let note: String?
    let teach: String
    /// Template with {slot} placeholders, e.g. "Is mise {x}".
    let frame: String
    let slots: [String: PatternSlot]?
    /// A minimal-pair frame that makes the rule click by contrast.
    let contrast: String?
    /// The production prompt a generated drill item shows — the *intent* in
    /// English (with the slot as `{…}`), so the learner retrieves the frame
    /// rather than reading it back ("Say where you're from: {x}"). Optional;
    /// the drill falls back to a bare assemble cue when absent (see DRILL.md).
    let cue: String?
    let earnedAt: ContentRef?
}

enum ContentLoader {
    /// Highest chapter number shipped in bundled JSON.
    static let maxChapter = 3

    static func chapter(_ n: Int) -> Chapter {
        switch n {
        case 3: return chapter3()
        case 2: return chapter2()
        default: return chapter1()
        }
    }

    static func chapter1() -> Chapter {
        decode(Chapter.self, from: "chapter1")
    }

    static func chapter2() -> Chapter {
        decode(Chapter.self, from: "chapter2")
    }

    static func chapter3() -> Chapter {
        decode(Chapter.self, from: "chapter3")
    }

    static func journey() -> [JourneyChapter] {
        struct Journey: Decodable { let chapters: [JourneyChapter] }
        return decode(Journey.self, from: "journey").chapters
    }

    /// Visits authored in one chapter's JSON (session indices are chapter-local).
    static func visits(forChapter n: Int) -> [Visit] {
        struct Visits: Decodable { let visits: [Visit] }
        return decode(Visits.self, from: "chapter\(n)").visits
    }

    /// All visits from chapters 1…n — Ar Ais draws from every road walked so far.
    static func visits(throughChapter n: Int) -> [Visit] {
        guard n >= 1 else { return [] }
        return (1...min(n, maxChapter)).flatMap { visits(forChapter: $0) }
    }

    /// Backward-compatible alias — chapter 1 visits only.
    static func visits() -> [Visit] {
        visits(forChapter: 1)
    }

    // MARK: The shared item spine

    /// Lexemes authored in one chapter's JSON (co-located with the scenes that
    /// earn them). A missing "lexicon" key decodes to empty, so already-shipped
    /// chapters need no rewrite.
    static func lexicon(forChapter n: Int) -> [Lexeme] {
        struct Bank: Decodable { let lexicon: [Lexeme]? }
        return decode(Bank.self, from: "chapter\(n)").lexicon ?? []
    }

    /// The whole lexicon earned across chapters 1…n — all the drill deck may draw
    /// from. Drill can only ever schedule items the story has already earned.
    static func lexicon(throughChapter n: Int) -> [Lexeme] {
        guard n >= 1 else { return [] }
        return (1...min(n, maxChapter)).flatMap { lexicon(forChapter: $0) }
    }

    /// Grammar patterns authored in one chapter's JSON. Missing key → empty.
    static func patterns(forChapter n: Int) -> [Pattern] {
        struct Bank: Decodable { let patterns: [Pattern]? }
        return decode(Bank.self, from: "chapter\(n)").patterns ?? []
    }

    /// Every pattern earned across chapters 1…n.
    static func patterns(throughChapter n: Int) -> [Pattern] {
        guard n >= 1 else { return [] }
        return (1...min(n, maxChapter)).flatMap { patterns(forChapter: $0) }
    }

    private static func decode<T: Decodable>(_ type: T.Type, from resource: String) -> T {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode(T.self, from: data)
        else {
            fatalError("\(resource).json missing or malformed — content is the product; fail loudly.")
        }
        return value
    }
}
