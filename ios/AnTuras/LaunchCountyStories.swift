import SwiftUI

// MARK: - Phase 3 county-story format

enum LaunchStoryClearance: String, Codable, Equatable {
    case cleared = "Reviewed story"
    case editorialPreview = "Editorial preview"
}

struct LaunchCountyStory: Identifiable, Codable {
    let id: String
    let countyGa: String
    let countyEn: String
    let province: String
    let title: String
    let era: String
    let anchor: String
    let question: String
    let opening: String
    let objectKind: LaunchObjectKind
    let sourceTitle: String
    let sourceDetail: String
    let sourceFacts: [LaunchSourceFact]
    let evidenceLimit: String
    let clearance: LaunchStoryClearance
    let reviewGate: String
    let tegLevel: String
    let tegCanDo: String
    let artifactTitle: String
    let artifactPrompt: String
    let words: [AtlasWord]
    let episodes: [LaunchEpisode]

    var beats: [LaunchStoryBeat] { episodes.flatMap(\.beats) }
}

enum LaunchObjectKind: String, Codable, Equatable {
    case cross, penny, castle
}

struct LaunchSourceFact: Identifiable, Codable {
    let id: String
    let certainty: EvidenceCertainty
    let text: String
}

struct AtlasReviewCandidate: Identifiable {
    let storyID: String
    let county: String
    let word: AtlasWord

    var id: String { "\(storyID)|\(word.ga)" }
}

struct LaunchEpisode: Identifiable, Codable {
    let id: String
    let title: String
    let place: String
    let beats: [LaunchStoryBeat]
}

struct LaunchStoryBeat: Identifiable, Codable {
    let id: String
    let title: String
    let body: String
    let action: LaunchStoryAction
}

enum LaunchStoryAction: Codable {
    case none
    case listen(wordIndex: Int, options: [String], correctIndex: Int)
    case choose(prompt: String, options: [String], correctIndex: Int, success: String, retry: String)
    case inspect(prompt: String)
    case make(prompt: String, options: [String])

    var requiresCompletion: Bool {
        if case .none = self { return false }
        return true
    }
}

enum LaunchCountyCatalog {
    /// Installed packs are read once at process start. A successfully installed
    /// reviewed pack takes effect on the next launch; bundled previews remain a
    /// complete offline fallback.
    static let stories: [LaunchCountyStory] = LaunchCountyPackStore.merged(
        fallback: [offaly, dublin, meath]
    )

    static func story(id: String) -> LaunchCountyStory? {
        stories.first { $0.id == id }
    }

    static func story(county: String) -> LaunchCountyStory? {
        stories.first { $0.countyEn == county }
    }

    static let offaly = LaunchCountyStory(
        id: "offaly.cross-of-the-scriptures",
        countyGa: "Uíbh Fhailí",
        countyEn: "Offaly",
        province: "Leinster",
        title: "The cross at Ireland’s crossroads",
        era: "c. 900",
        anchor: "Cross of the Scriptures · Flann Sinna · Clonmacnoise",
        question: "A damaged inscription asks for a prayer involving an abbot and a king. What can the stone still tell us?",
        opening: "The Shannon meets a long east–west road. Around that meeting place, Clonmacnoise became a settlement of worship, craft, burial, learning and political connection. The cross stands inside that larger world.",
        objectKind: .cross,
        sourceTitle: "Cross of the Scriptures",
        sourceDetail: "Early tenth century · original kept indoors; replica on the historic site",
        sourceFacts: [
            .init(id: "O01", certainty: .material, text: "The surviving sculpture and damaged inscription are material evidence at Clonmacnoise."),
            .init(id: "O02", certainty: .documented, text: "The conventional reading connects Abbot Colmán and King Flann Sinna."),
            .init(id: "O03", certainty: .disputed, text: "The exact expansion of damaged letters and some panel identifications need specialist review."),
        ],
        evidenceLimit: "The stone supports patronage, prayer and a politically connected settlement. It does not give us a witnessed day in a named scribe’s life.",
        clearance: .editorialPreview,
        reviewGate: "Before public release: medieval historian and art-historian reading, pedagogue approval of the 20-word weave, image rights and native-speaker audio QA.",
        tegLevel: "TEG A1",
        tegCanDo: "Describe a place and simple activity; understand familiar words for location, size and work.",
        artifactTitle: "Your cross-panel study",
        artifactPrompt: "Choose the detail you would carry into a field note. This is your study, never a substitute for the surviving cross.",
        words: offalyWords,
        episodes: [
            .init(id: "offaly-1", title: "Where roads meet", place: "Shannon · esker road", beats: [
                .init(id: "offaly-1a", title: "Water and road", body: "Clonmacnoise occupies a meeting point: the Shannon runs north and south while a raised east–west route crosses the midlands. Movement helps explain why this place mattered.", action: .none),
                .init(id: "offaly-1b", title: "A settlement, not a still picture", body: "By about 900 the place held churches, graves, carved stone and evidence of making and exchange. ‘Monastery’ alone is too narrow for the life gathered here.", action: .none),
                .init(id: "offaly-1c", title: "Hear the place word", body: "The river gives the first orientation word.", action: .listen(wordIndex: 0, options: ["river", "stone", "road"], correctIndex: 0)),
            ]),
            .init(id: "offaly-2", title: "Meet the cross", place: "Clonmacnoise · c. 900", beats: [
                .init(id: "offaly-2a", title: "The original is indoors", body: "The carved cross now protected inside is the historical object. The cross outdoors is a replica. The distinction matters whenever the learner meets evidence through a site.", action: .none),
                .init(id: "offaly-2b", title: "Stone carries more than decoration", body: "Figure panels and an inscription make the cross a public object of scripture, patronage and memory. Its damaged surface also sets limits.", action: .none),
                .init(id: "offaly-2c", title: "Object or reconstruction?", body: "Keep the evidence boundary visible.", action: .choose(prompt: "Which statement is secure?", options: ["A named scribe recorded his whole day here", "The surviving cross carries carved panels and a damaged inscription", "Every panel has one uncontested reading"], correctIndex: 1, success: "The surviving object stays at the centre.", retry: "That claim asks the stone to preserve more than it does.")),
            ]),
            .init(id: "offaly-3", title: "An abbot and a king", place: "Inscription zone", beats: [
                .init(id: "offaly-3a", title: "Names under damage", body: "A conventional reading links Abbot Colmán and King Flann Sinna. The relationship between prayer and patronage is strong enough for the main story; damaged letters remain inspectable.", action: .none),
                .init(id: "offaly-3b", title: "Power beside prayer", body: "Flann’s association with Clonmacnoise places royal authority beside an ecclesiastical settlement. The cross does not turn that relationship into a simple ownership claim.", action: .none),
                .init(id: "offaly-3c", title: "Open the source guide", body: "See the secure reading, the damaged zone and the unresolved specialist work together.", action: .inspect(prompt: "Inspect the cross record")),
            ]),
            .init(id: "offaly-4", title: "Carry the place", place: "Clonmacnoise · now", beats: [
                .init(id: "offaly-4a", title: "Useful Irish comes from attention", body: "River, road, stone, work, here and now describe more than this site. The story gives them a first place to hold.", action: .none),
                .init(id: "offaly-4b", title: "One honest study", body: "A learner-made panel study can record what drew your eye without pretending to restore missing sculpture or inscription.", action: .none),
                .init(id: "offaly-4c", title: "Make the field note yours", body: "Choose one observed feature to carry into the collection.", action: .make(prompt: "What will your study attend to?", options: ["The damaged inscription", "The meeting of river and road", "One surviving figure panel"])),
            ]),
        ]
    )

    static let dublin = LaunchCountyStory(
        id: "dublin.sihtric-penny",
        countyGa: "Baile Átha Cliath",
        countyEn: "Dublin",
        province: "Leinster",
        title: "A king puts Dublin on silver",
        era: "c. 995–997",
        anchor: "Sihtric Silkbeard · Dublin mint · silver penny",
        question: "When a port begins striking coins, whose name and authority travel with the silver?",
        opening: "Dublin was already a Norse-Gaelic port and market when locally struck coinage appeared under Sihtric. A small silver penny makes the city, the ruler and a wider trading world tangible.",
        objectKind: .penny,
        sourceTitle: "Hiberno-Norse Phase I silver penny",
        sourceDetail: "Dublin mint · c. 995–997 · learner-facing specimen still to be selected",
        sourceFacts: [
            .init(id: "D01", certainty: .material, text: "Surviving silver pennies are the first locally struck Irish coinage known from Dublin."),
            .init(id: "D02", certainty: .documented, text: "Early issues name Sihtric and Dublin on suitable examples and draw on contemporary English coin designs."),
            .init(id: "D03", certainty: .unknown, text: "The exact learner-facing type, legend reading and licensed image remain release gates."),
        ],
        evidenceLimit: "A coin can show names, design choices and a minting economy. It cannot by itself prove one motive for founding the mint or describe an ordinary market day.",
        clearance: .editorialPreview,
        reviewGate: "Before public release: numismatist specimen and legend selection, historian and pedagogue review, image rights and native-speaker audio QA.",
        tegLevel: "TEG A1",
        tegCanDo: "Use familiar words for movement and exchange; recognise simple past forms in a supported story.",
        artifactTitle: "Your mint mark",
        artifactPrompt: "Choose the idea your own clearly labelled mark will carry. It is inspired by the encounter, not presented as a historical coin.",
        words: dublinWords,
        episodes: [
            .init(id: "dublin-1", title: "The port before the penny", place: "Dubhlinn · Áth Cliath", beats: [
                .init(id: "dublin-1a", title: "Two names hold the city", body: "Dubhlinn names the dark pool; Áth Cliath names the hurdled ford. The modern city carries both histories without collapsing them into one origin story.", action: .none),
                .init(id: "dublin-1b", title: "A connected market", body: "Archaeology and historical synthesis support a significant port and market before the mint. The coin enters a city already moving goods, people and silver.", action: .none),
                .init(id: "dublin-1c", title: "Hear the city", body: "The place-name arrives before the ruler’s silver.", action: .listen(wordIndex: 3, options: ["town / homestead", "ship", "market"], correctIndex: 0)),
            ]),
            .init(id: "dublin-2", title: "The first mint", place: "Dublin · c. 995–997", beats: [
                .init(id: "dublin-2a", title: "Small object, large claim", body: "Under Sihtric, Dublin produced the first locally struck Irish coinage known to numismatists. The date remains a range rather than one theatrical minting day.", action: .none),
                .init(id: "dublin-2b", title: "A design already understood", body: "Early pennies draw on contemporary English types. Reusing a recognised design language can signal connection and authority; ‘forgery’ is too simple.", action: .none),
                .init(id: "dublin-2c", title: "Read the object honestly", body: "Separate what survives from what historians infer.", action: .choose(prompt: "What can a selected penny directly show?", options: ["A name and coin design struck in silver", "Why every person accepted it", "The exact day the mint opened"], correctIndex: 0, success: "The material claim is enough.", retry: "That would require evidence beyond the coin itself.")),
            ]),
            .init(id: "dublin-3", title: "Name and city", place: "Coin legend", beats: [
                .init(id: "dublin-3a", title: "Sihtric travels in a pocket", body: "On a clear Phase I example, the ruler’s name and Dublin travel beyond the mint. The final app must bind this interaction to one specialist-approved specimen and reading.", action: .none),
                .init(id: "dublin-3b", title: "Authority is an interpretation", body: "Paying men and displaying royal authority are plausible motives in the scholarship. The story keeps them as interpretations rather than words stamped by the coin.", action: .none),
                .init(id: "dublin-3c", title: "Open the coin record", body: "Inspect what a specimen can establish and what the release packet still needs.", action: .inspect(prompt: "Inspect the penny record")),
            ]),
            .init(id: "dublin-4", title: "Carry exchange forward", place: "The road from Dublin", beats: [
                .init(id: "dublin-4a", title: "Words that move", body: "Go, come, buy, sell, give and take make exchange usable beyond a historical market. Past forms stay tied to actions the story has already shown.", action: .none),
                .init(id: "dublin-4b", title: "Make without copying", body: "A personal mint mark can hold your name or a place that matters. It remains on the ‘made by you’ shelf, separate from the historical penny.", action: .none),
                .init(id: "dublin-4c", title: "Choose your mark", body: "Decide what your mark will stand for.", action: .make(prompt: "What should the mark carry?", options: ["My name", "A place that matters", "A word I want to remember"])),
            ]),
        ]
    )

    static let meath = LaunchCountyStory(
        id: "meath.trim-de-lacy",
        countyGa: "An Mhí",
        countyEn: "Meath",
        province: "Leinster",
        title: "A grant, a ford and a rising castle",
        era: "from 1172",
        anchor: "Hugh de Lacy · Áth Troim · Trim Castle",
        question: "When a king grants a lordship, how do paper, earth and stone show who gains power—and who bears its cost?",
        opening: "Henry II’s grant of Meath to Hugh de Lacy survives through later copies. At the ford of Trim, an early fortification and the later stone castle make conquest administration visible, but the building cannot be told as empty-land progress.",
        objectKind: .castle,
        sourceTitle: "Later grant copies and Trim Castle fabric",
        sourceDetail: "Grant dated 1172 · early ringwork and later stone phases require specialist bounds",
        sourceFacts: [
            .init(id: "M01", certainty: .documented, text: "Later manuscript copies preserve the tradition of Henry II’s 1172 grant of Meath to Hugh de Lacy."),
            .init(id: "M02", certainty: .material, text: "Earthwork, castle fabric and the ford show Trim becoming the lordship’s centre."),
            .init(id: "M03", certainty: .disputed, text: "Exact early building phases and any single foundation moment require specialist care."),
        ],
        evidenceLimit: "Grant and castle show imposed authority; neither makes conquest consent, erases Gaelic Meath or supports an invented foundation-day scene.",
        clearance: .editorialPreview,
        reviewGate: "Before public release: grant-copy citation, castle specialist, conquest-sensitivity review, pedagogue approval, image rights and native-speaker audio QA.",
        tegLevel: "TEG A1 → A2",
        tegCanDo: "Say what you have, locate familiar things and describe a place with simple old/new and here/there contrasts.",
        artifactTitle: "Your place-and-power plan",
        artifactPrompt: "Choose the relationship your plan should preserve. It is an interpretive study, not a reconstruction of one undocumented day.",
        words: meathWords,
        episodes: [
            .init(id: "meath-1", title: "The grant", place: "1172 · surviving in later copies", beats: [
                .init(id: "meath-1a", title: "A country written as a gift", body: "Henry II granted Meath to Hugh de Lacy in 1172. The text reaches us through later manuscript copies, so the app distinguishes the historical act from the age of the surviving witness.", action: .none),
                .init(id: "meath-1b", title: "Possession has a grammar", body: "Irish expresses ‘I have’ through something being at me: tá … agam. The form becomes meaningful beside a document that claims possession on an enormous scale.", action: .none),
                .init(id: "meath-1c", title: "Hear possession", body: "The learner keeps their own ordinary possession separate from the grant’s political claim.", action: .listen(wordIndex: 0, options: ["at me / I have", "at you / you have", "land"], correctIndex: 0)),
            ]),
            .init(id: "meath-2", title: "Why this ford?", place: "Áth Troim · River Boyne", beats: [
                .init(id: "meath-2a", title: "Crossing becomes centre", body: "Trim’s ford and routes help explain its choice as the caput, or administrative centre, of the new lordship. Geography supports the claim without pretending the site was empty.", action: .none),
                .init(id: "meath-2b", title: "Names outlast regimes", body: "Áth Troim carries the ford in Irish. The later castle does not erase the place-name or the communities and power structures the conquest confronted.", action: .none),
                .init(id: "meath-2c", title: "Hold place and power together", body: "Do not let one monument swallow the county.", action: .choose(prompt: "Why does the story begin at the ford?", options: ["The castle appeared before anyone used the place", "Route and river help explain why authority was fixed here", "The grant proves everyone welcomed the new lordship"], correctIndex: 1, success: "Place explains the choice without excusing the conquest.", retry: "That version erases evidence or people the story must keep visible.")),
            ]),
            .init(id: "meath-3", title: "Timber, earth, stone", place: "Trim Castle · phases over time", beats: [
                .init(id: "meath-3a", title: "No single foundation-day picture", body: "Literary evidence and archaeology support an early fortification after the grant. The large stone complex developed through later work under Hugh and Walter de Lacy.", action: .none),
                .init(id: "meath-3b", title: "A castle is also pressure", body: "Walls organise defence and administration, but they also materialise conquest and dispossession. Architectural achievement cannot be the only voice in the episode.", action: .none),
                .init(id: "meath-3c", title: "Open the evidence record", body: "Keep grant-copy status, physical fabric and contested phasing together.", action: .inspect(prompt: "Inspect the Trim record")),
            ]),
            .init(id: "meath-4", title: "Describe without possessing", place: "Trim · now", beats: [
                .init(id: "meath-4a", title: "Old and new share the town", body: "The castle, river, streets and present community let the learner use old, new, here and there without reducing Trim to a conquest monument.", action: .none),
                .init(id: "meath-4b", title: "A plan keeps relationships visible", body: "Your plan can connect ford, river, earthwork and stone while marking which parts survive and which are interpretation.", action: .none),
                .init(id: "meath-4c", title: "Choose the plan’s centre", body: "Name the relationship you want to remember.", action: .make(prompt: "What will your plan connect?", options: ["Ford and route", "Grant and imposed authority", "Earthwork and later stone"])),
            ]),
        ]
    )

    private static let offalyWords: [AtlasWord] = [
        .init(ga: "abhainn", en: "river", sound: "ow-in", anchor: "The Shannon route"),
        .init(ga: "cloch", en: "stone", sound: "klukh", anchor: "The carved cross"),
        .init(ga: "cros", en: "cross", sound: "kruss", anchor: "The Cross of the Scriptures"),
        .init(ga: "rí", en: "king", sound: "ree", anchor: "Flann Sinna"),
        .init(ga: "mainistir", en: "monastery", sound: "man-ish-tir", anchor: "The ecclesiastical settlement"),
        .init(ga: "baile", en: "settlement / town", sound: "bal-ya", anchor: "Life gathered at Clonmacnoise"),
        .init(ga: "obair", en: "work", sound: "ub-ir", anchor: "Craft and daily activity"),
        .init(ga: "lá", en: "day", sound: "law", anchor: "Time at the settlement"),
        .init(ga: "anseo", en: "here", sound: "un-shuh", anchor: "Standing at the crossroads"),
        .init(ga: "anois", en: "now", sound: "uh-nish", anchor: "The surviving place today"),
        .init(ga: "mór", en: "big", sound: "more", anchor: "Scale without exaggeration"),
        .init(ga: "beag", en: "small", sound: "byug", anchor: "A detail in the carving"),
        .init(ga: "féach", en: "look", sound: "faykh", anchor: "Attending to the object"),
        .init(ga: "seas", en: "stand", sound: "shass", anchor: "The cross standing in place"),
        .init(ga: "déan", en: "make / do", sound: "djayn", anchor: "Making and patronage"),
        .init(ga: "foghlaim", en: "learn", sound: "foh-lim", anchor: "Learning at the settlement"),
        .init(ga: "léigh", en: "read", sound: "lay", anchor: "Reading damaged letters"),
        .init(ga: "guí", en: "pray", sound: "gwee", anchor: "The inscription’s request"),
        .init(ga: "bád", en: "boat", sound: "bawd", anchor: "Movement on the Shannon"),
        .init(ga: "bóthar", en: "road", sound: "boh-hur", anchor: "The east–west route"),
    ]

    private static let dublinWords: [AtlasWord] = [
        .init(ga: "airgead", en: "money / silver", sound: "arr-igid", anchor: "The penny’s material"),
        .init(ga: "pingin", en: "penny", sound: "ping-in", anchor: "The minted object"),
        .init(ga: "rí", en: "king", sound: "ree", anchor: "Sihtric’s authority"),
        .init(ga: "baile", en: "town / homestead", sound: "bal-ya", anchor: "Baile Átha Cliath"),
        .init(ga: "linn", en: "pool", sound: "lin", anchor: "Dubhlinn"),
        .init(ga: "dubh", en: "black", sound: "duv", anchor: "The dark pool"),
        .init(ga: "long", en: "ship", sound: "lung", anchor: "The connected port"),
        .init(ga: "margadh", en: "market", sound: "mar-guh", anchor: "Exchange in the city"),
        .init(ga: "ceannaigh", en: "buy", sound: "kan-ee", anchor: "A market action"),
        .init(ga: "díol", en: "sell", sound: "djeel", anchor: "A market action"),
        .init(ga: "tabhair", en: "give", sound: "toor", anchor: "Passing silver"),
        .init(ga: "tóg", en: "take / lift", sound: "tohg", anchor: "Handling an object"),
        .init(ga: "téigh", en: "go", sound: "tay", anchor: "Movement through the port"),
        .init(ga: "tar", en: "come", sound: "tar", anchor: "Arrival into the city"),
        .init(ga: "chuaigh", en: "went", sound: "khoo-ig", anchor: "A supported past action"),
        .init(ga: "tháinig", en: "came", sound: "haw-nig", anchor: "A supported past action"),
        .init(ga: "ainm", en: "name", sound: "an-im", anchor: "The coin legend"),
        .init(ga: "cathair", en: "city", sound: "kah-hir", anchor: "Dublin’s urban world"),
        .init(ga: "abhainn", en: "river", sound: "ow-in", anchor: "The Liffey route"),
        .init(ga: "trádáil", en: "trade", sound: "traw-dawl", anchor: "The wider exchange network"),
    ]

    private static let meathWords: [AtlasWord] = [
        .init(ga: "agam", en: "at me / I have", sound: "ug-um", anchor: "Possession without an English have-verb"),
        .init(ga: "agat", en: "at you / you have", sound: "ug-ut", anchor: "Asking about possession"),
        .init(ga: "talamh", en: "land", sound: "tal-uv", anchor: "The granted lordship"),
        .init(ga: "caisleán", en: "castle", sound: "kash-lawn", anchor: "Trim Castle"),
        .init(ga: "áth", en: "ford", sound: "aw", anchor: "Áth Troim"),
        .init(ga: "abhainn", en: "river", sound: "ow-in", anchor: "The Boyne"),
        .init(ga: "balla", en: "wall", sound: "bal-uh", anchor: "Built authority"),
        .init(ga: "cloch", en: "stone", sound: "klukh", anchor: "Later castle fabric"),
        .init(ga: "baile", en: "town", sound: "bal-ya", anchor: "Trim beside the castle"),
        .init(ga: "tóg", en: "build / raise", sound: "tohg", anchor: "Phases of building"),
        .init(ga: "cónaí", en: "living / residence", sound: "koh-nee", anchor: "A lived town"),
        .init(ga: "mór", en: "big", sound: "more", anchor: "The castle’s scale"),
        .init(ga: "sean", en: "old", sound: "shan", anchor: "Older fabric and names"),
        .init(ga: "nua", en: "new", sound: "noo-uh", anchor: "Later phases and present life"),
        .init(ga: "anseo", en: "here", sound: "un-shuh", anchor: "At the ford"),
        .init(ga: "ansiúd", en: "there", sound: "un-shood", anchor: "Reading across the site"),
        .init(ga: "féach", en: "look", sound: "faykh", anchor: "Inspecting fabric"),
        .init(ga: "seas", en: "stand", sound: "shass", anchor: "The castle in the town"),
        .init(ga: "ainm", en: "name", sound: "an-im", anchor: "Áth Troim and Trim"),
        .init(ga: "teach", en: "house / home", sound: "chakh", anchor: "Life beyond the monument"),
    ]
}

// MARK: - Offline county-pack installation

struct LaunchCountyPackEnvelope: Codable {
    let schemaVersion: Int
    let story: LaunchCountyStory
}

enum LaunchCountyPackError: LocalizedError {
    case unsupportedSchema
    case invalidStoryID
    case invalidWordContract
    case invalidEpisodeContract
    case missingEvidenceContract

    var errorDescription: String? {
        switch self {
        case .unsupportedSchema: return "This county pack uses an unsupported schema."
        case .invalidStoryID: return "The county pack has no stable story id."
        case .invalidWordContract: return "A county pack must contain exactly twenty unique Irish headwords."
        case .invalidEpisodeContract: return "A legacy county pack needs non-empty chapters and unique page ids."
        case .missingEvidenceContract: return "The county pack is missing its evidence or review boundary."
        }
    }
}

enum LaunchCountyPackStore {
    static let schemaVersion = 1

    static func validate(_ envelope: LaunchCountyPackEnvelope) throws {
        guard envelope.schemaVersion == schemaVersion else {
            throw LaunchCountyPackError.unsupportedSchema
        }
        let story = envelope.story
        guard !story.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              story.id.contains(".") else {
            throw LaunchCountyPackError.invalidStoryID
        }
        guard story.words.count == 20,
              Set(story.words.map(\.ga)).count == 20 else {
            throw LaunchCountyPackError.invalidWordContract
        }
        guard !story.episodes.isEmpty,
              story.episodes.allSatisfy({ !$0.beats.isEmpty }),
              Set(story.beats.map(\.id)).count == story.beats.count else {
            throw LaunchCountyPackError.invalidEpisodeContract
        }
        guard !story.sourceFacts.isEmpty,
              !story.sourceTitle.isEmpty,
              !story.reviewGate.isEmpty else {
            throw LaunchCountyPackError.missingEvidenceContract
        }
    }

    static func merged(fallback: [LaunchCountyStory]) -> [LaunchCountyStory] {
        let installed = installedOverrides()
        return fallback.map { installed[$0.id] ?? $0 }
    }

    /// Installs a previously downloaded JSON envelope atomically. Transport and
    /// entitlement are intentionally outside this store; the content boundary
    /// remains testable without a live service.
    @discardableResult
    static func install(data: Data) throws -> URL {
        let envelope = try JSONDecoder().decode(LaunchCountyPackEnvelope.self, from: data)
        try validate(envelope)
        let folder = try packsFolder()
        let destination = folder
            .appendingPathComponent(safeFilename(for: envelope.story.id))
            .appendingPathExtension("json")
        try data.write(to: destination, options: [.atomic])
        return destination
    }

    private static func installedOverrides() -> [String: LaunchCountyStory] {
        guard let folder = try? packsFolder(),
              let urls = try? FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
              ) else { return [:] }

        var result: [String: LaunchCountyStory] = [:]
        for url in urls where url.pathExtension.lowercased() == "json" {
            guard let data = try? Data(contentsOf: url),
                  let envelope = try? JSONDecoder().decode(LaunchCountyPackEnvelope.self, from: data),
                  (try? validate(envelope)) != nil else { continue }
            result[envelope.story.id] = envelope.story
        }
        return result
    }

    private static func packsFolder() throws -> URL {
        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = root.appendingPathComponent("CountyPacks", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private static func safeFilename(for storyID: String) -> String {
        storyID.map { character in
            character.isLetter || character.isNumber || character == "." || character == "-"
                ? String(character)
                : "-"
        }.joined()
    }
}

// MARK: - Shared county dossier

struct LaunchCountyDossierView: View {
    @EnvironmentObject private var atlas: AtlasPrototypeModel
    let story: LaunchCountyStory
    let onBegin: () -> Void
    let onEvidence: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EditorialLayout.sectionGap) {
                EditorialScreenHeader(
                    context: "\(story.countyGa) · \(story.countyEn) · \(story.era)",
                    title: story.title,
                    detail: story.anchor,
                    accent: atlas.isCountyComplete(story.id) ? Theme.atlasGold : Theme.atlasGreen
                )

                objectOpening

                EditorialSectionHeader(
                    context: "The question",
                    title: story.question,
                    detail: story.opening
                )

                launchState

                VStack(alignment: .leading, spacing: 12) {
                    Text("Four episodes · twenty useful words")
                        .font(.system(.title2, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    ForEach(Array(story.episodes.enumerated()), id: \.element.id) { index, episode in
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.monospacedDigit().weight(.bold))
                                .foregroundStyle(Theme.inkFaint)
                                .frame(width: 20, alignment: .leading)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(episode.title).font(.headline).foregroundStyle(Theme.ink)
                                Text(episode.place).font(.caption).foregroundStyle(Theme.inkSoft)
                            }
                        }
                        .padding(.vertical, 6)
                        if index < story.episodes.count - 1 { EditorialRule() }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    EditorialContextLabel(text: "External progress", color: Theme.moss)
                    Text(story.tegLevel)
                        .font(.system(.title2, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(story.tegCanDo).font(.body).foregroundStyle(Theme.inkSoft)
                }

                PrimaryButton(
                    title: atlas.isCountyComplete(story.id) ? "Return to the story" : "Begin in \(story.countyEn)",
                    fullWidth: true,
                    action: onBegin
                )
            }
            .padding(EditorialLayout.pageInset)
            .padding(.bottom, 34)
            .frame(maxWidth: EditorialLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(story.countyEn)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var objectOpening: some View {
        Button(action: onEvidence) {
            HStack(spacing: 20) {
                LaunchObjectMark(kind: story.objectKind)
                    .frame(width: 116, height: 116)
                VStack(alignment: .leading, spacing: 7) {
                    Text(story.sourceTitle)
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(story.sourceDetail)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                    Label("Open the evidence record", systemImage: "doc.text.magnifyingglass")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.moss)
                        .frame(minHeight: 44)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(CarvePress())
        .accessibilityLabel("Open the evidence record")
        .accessibilityHint("Opens provenance, certainty and release status")
    }

    private var launchState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(story.clearance.rawValue, systemImage: story.clearance == .cleared ? "checkmark.seal" : "person.2.badge.gearshape")
                .font(.headline)
                .foregroundStyle(story.clearance == .cleared ? Theme.moss : Theme.rust)
            Text(story.reviewGate)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(3)
        }
        .padding(16)
        .background(story.clearance == .cleared ? Theme.mossTint : Theme.rustTint)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Shared county story

struct LaunchCountyStoryView: View {
    @EnvironmentObject private var atlas: AtlasPrototypeModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let story: LaunchCountyStory
    let onOpenEvidence: () -> Void
    let onComplete: () -> Void

    @State private var actionComplete = false
    @State private var wrongChoice = false
    @State private var chosenMaking: String?

    private var beats: [LaunchStoryBeat] { story.beats }
    private var step: Int { min(max(atlas.countyStep(for: story.id), 0), max(beats.count - 1, 0)) }
    private var beat: LaunchStoryBeat { beats[step] }
    private var episodeIndex: Int { step / 3 }
    private var episode: LaunchEpisode { story.episodes[episodeIndex] }
    private var durableComplete: Bool { atlas.isCountyBeatComplete(story.id, step: step) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                progressHeader

                LaunchObjectMark(kind: story.objectKind, compact: true)
                    .frame(height: 92)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)

                EditorialScreenHeader(
                    context: episode.place,
                    title: beat.title,
                    detail: beat.body,
                    accent: Theme.moss
                )

                actionView

                navigation
            }
            .padding(EditorialLayout.pageInset)
            .padding(.bottom, 34)
            .frame(maxWidth: EditorialLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(story.countyEn)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            atlas.activeCountyStoryID = story.id
            syncActionState()
        }
        .onChange(of: step) { _, _ in syncActionState() }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Episode \(episodeIndex + 1) of \(story.episodes.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text("\((step % 3) + 1) / 3")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.inkFaint)
            }
            ProgressView(value: Double(step + 1), total: Double(max(beats.count, 1)))
                .tint(Theme.moss)
                .accessibilityLabel("Story progress")
                .accessibilityValue("Beat \(step + 1) of \(beats.count)")
            Text(episode.title)
                .font(.headline)
                .foregroundStyle(Theme.ink)
        }
    }

    @ViewBuilder
    private var actionView: some View {
        switch beat.action {
        case .none:
            EmptyView()
        case .listen(let wordIndex, let options, let correctIndex):
            let word = story.words[wordIndex]
            VStack(alignment: .leading, spacing: 12) {
                AtlasAudioLine(ga: word.ga, en: word.en, sound: word.sound)
                Text("What does \(word.ga) mean here?")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                choiceButtons(options: options, correctIndex: correctIndex, success: "Meaning carried", retry: "Listen or read the line again, then choose once more.")
            }
        case .choose(let prompt, let options, let correctIndex, let success, let retry):
            VStack(alignment: .leading, spacing: 12) {
                Text(prompt).font(.headline).foregroundStyle(Theme.ink)
                choiceButtons(options: options, correctIndex: correctIndex, success: success, retry: retry)
            }
        case .inspect(let prompt):
            Button {
                atlas.markEvidenceInspected(story.id)
                completeCurrentAction()
                onOpenEvidence()
            } label: {
                Label(durableComplete ? "Evidence inspected" : prompt, systemImage: durableComplete ? "checkmark" : "doc.text.magnifyingglass")
                    .font(.headline)
                    .foregroundStyle(Theme.moss)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(14)
                    .background(Theme.mossTint)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(CarvePress())
        case .make(let prompt, let options):
            VStack(alignment: .leading, spacing: 12) {
                Text(prompt).font(.headline).foregroundStyle(Theme.ink)
                ForEach(options, id: \.self) { option in
                    Button {
                        chosenMaking = option
                        atlas.markArtifactMade(story.id)
                        completeCurrentAction()
                    } label: {
                        HStack {
                            Text(option).font(.body.weight(.semibold)).foregroundStyle(Theme.ink)
                            Spacer()
                            Image(systemName: chosenMaking == option || durableComplete ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(chosenMaking == option || durableComplete ? Theme.moss : Theme.stone)
                        }
                        .frame(minHeight: 44)
                        .padding(.horizontal, 14)
                        .background(Theme.raised)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(CarvePress())
                    .disabled(actionComplete)
                }
                if actionComplete {
                    Text("Saved under What you made · \(story.artifactTitle)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.moss)
                }
            }
        }
    }

    private func choiceButtons(options: [String], correctIndex: Int, success: String, retry: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button {
                    guard !actionComplete else { return }
                    if index == correctIndex {
                        wrongChoice = false
                        completeCurrentAction()
                    } else {
                        wrongChoice = true
                        Haptics.error()
                    }
                } label: {
                    HStack {
                        Text(option).font(.body.weight(.semibold)).foregroundStyle(Theme.ink)
                        Spacer()
                        if actionComplete && index == correctIndex {
                            Image(systemName: "checkmark").foregroundStyle(Theme.moss)
                        }
                    }
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(.horizontal, 14)
                    .background(Theme.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(CarvePress())
                .disabled(actionComplete)
            }
            if wrongChoice {
                Label(retry, systemImage: "arrow.counterclockwise")
                    .font(.subheadline)
                    .foregroundStyle(Theme.rust)
            } else if actionComplete {
                Label(success, systemImage: "checkmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.moss)
            }
        }
        .shake(wrongChoice ? 1 : 0)
    }

    private var navigation: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button("Back") { move(to: step - 1) }
                    .font(.headline)
                    .foregroundStyle(Theme.moss)
                    .frame(minHeight: 44)
            }
            Spacer()
            if step == beats.count - 1 {
                PrimaryButton(title: atlas.isCountyComplete(story.id) ? "Story carried" : "Carry \(story.countyEn) into the atlas") {
                    if !beat.action.requiresCompletion || actionComplete || durableComplete {
                        atlas.completeCountyStory(story)
                        onComplete()
                    }
                }
                .opacity(canContinue ? 1 : 0.46)
                .disabled(!canContinue)
            } else {
                PrimaryButton(title: (step + 1) % 3 == 0 ? "Enter the next episode" : "Continue") {
                    guard canContinue else { return }
                    if !beat.action.requiresCompletion { atlas.markCountyBeatComplete(story.id, step: step) }
                    move(to: step + 1)
                }
                .opacity(canContinue ? 1 : 0.46)
                .disabled(!canContinue)
            }
        }
    }

    private var canContinue: Bool {
        !beat.action.requiresCompletion || actionComplete || durableComplete
    }

    private func move(to newStep: Int) {
        if !beat.action.requiresCompletion { atlas.markCountyBeatComplete(story.id, step: step) }
        if reduceMotion {
            atlas.setCountyStep(story.id, step: newStep)
        } else {
            withAnimation(Motion.settle) { atlas.setCountyStep(story.id, step: newStep) }
        }
    }

    private func completeCurrentAction() {
        atlas.markCountyBeatComplete(story.id, step: step)
        actionComplete = true
        wrongChoice = false
        Haptics.chisel()
    }

    private func syncActionState() {
        actionComplete = atlas.isCountyBeatComplete(story.id, step: step)
        wrongChoice = false
        chosenMaking = nil
    }
}

// MARK: - Evidence record

struct LaunchEvidenceView: View {
    @EnvironmentObject private var atlas: AtlasPrototypeModel
    let story: LaunchCountyStory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EditorialLayout.sectionGap) {
                EditorialScreenHeader(
                    context: "Evidence record · \(story.countyEn)",
                    title: story.sourceTitle,
                    detail: story.sourceDetail,
                    accent: Theme.lichen
                )

                LaunchObjectMark(kind: story.objectKind)
                    .frame(height: 190)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Interpretive diagram identifying the evidence type; not the historical object")

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(story.sourceFacts) { fact in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: fact.certainty.icon)
                                .foregroundStyle(fact.certainty.color)
                                .frame(width: 24, height: 44, alignment: .top)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(fact.text).font(.body).foregroundStyle(Theme.ink)
                                Text(fact.certainty.rawValue.capitalized)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    EditorialContextLabel(text: "What this does not prove", color: Theme.rust)
                    Text(story.evidenceLimit)
                        .font(.body)
                        .foregroundStyle(Theme.ink)
                        .lineSpacing(4)
                }
                .padding(16)
                .background(Theme.rustTint)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 8) {
                    Label(story.clearance.rawValue, systemImage: story.clearance == .cleared ? "checkmark.seal" : "person.2.badge.gearshape")
                        .font(.headline)
                        .foregroundStyle(story.clearance == .cleared ? Theme.moss : Theme.rust)
                    Text(story.reviewGate).font(.subheadline).foregroundStyle(Theme.inkSoft)
                }

                Button {
                    atlas.markEvidenceInspected(story.id)
                    Haptics.tap()
                } label: {
                    Label(atlas.hasInspectedEvidence(story.id) ? "Evidence record inspected" : "Mark this record inspected", systemImage: atlas.hasInspectedEvidence(story.id) ? "checkmark" : "eye")
                        .font(.headline)
                        .foregroundStyle(Theme.moss)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(CarvePress())
            }
            .padding(EditorialLayout.pageInset)
            .padding(.bottom, 34)
            .frame(maxWidth: EditorialLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Evidence")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { atlas.markEvidenceInspected(story.id) }
    }
}

// MARK: - Rights-safe object diagrams

struct LaunchObjectMark: View {
    let kind: LaunchObjectKind
    var compact = false

    var body: some View {
        Canvas { context, size in
            let bounds = CGRect(origin: .zero, size: size).insetBy(dx: compact ? 12 : 10, dy: compact ? 8 : 10)
            let side = min(bounds.width, bounds.height)
            let rect = CGRect(x: bounds.midX - side / 2, y: bounds.midY - side / 2, width: side, height: side)
            switch kind {
            case .cross:
                var cross = Path()
                let width = rect.width * 0.17
                cross.addRoundedRect(in: CGRect(x: rect.midX - width / 2, y: rect.minY, width: width, height: rect.height), cornerSize: .init(width: 3, height: 3))
                cross.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.28, width: rect.width * 0.64, height: width), cornerSize: .init(width: 3, height: 3))
                context.fill(cross, with: .color(Theme.stone.opacity(0.82)))
                context.stroke(cross, with: .color(Theme.ink.opacity(0.34)), lineWidth: 1)
            case .penny:
                let coin = Path(ellipseIn: rect.insetBy(dx: rect.width * 0.08, dy: rect.height * 0.08))
                context.fill(coin, with: .color(Theme.weatheredGold.opacity(0.28)))
                context.stroke(coin, with: .color(Theme.weatheredGold), lineWidth: 2)
                let inner = Path(ellipseIn: rect.insetBy(dx: rect.width * 0.20, dy: rect.height * 0.20))
                context.stroke(inner, with: .color(Theme.inkSoft), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                var cross = Path()
                cross.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.31))
                cross.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.31))
                cross.move(to: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.midY))
                cross.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.34, y: rect.midY))
                context.stroke(cross, with: .color(Theme.inkSoft), lineWidth: 2)
            case .castle:
                var castle = Path()
                let base = CGRect(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.40, width: rect.width * 0.64, height: rect.height * 0.48)
                castle.addRect(base)
                let towerWidth = rect.width * 0.18
                castle.addRect(CGRect(x: base.minX - towerWidth * 0.35, y: rect.minY + rect.height * 0.24, width: towerWidth, height: rect.height * 0.64))
                castle.addRect(CGRect(x: base.maxX - towerWidth * 0.65, y: rect.minY + rect.height * 0.24, width: towerWidth, height: rect.height * 0.64))
                context.fill(castle, with: .color(Theme.stone.opacity(0.62)))
                context.stroke(castle, with: .color(Theme.inkSoft), lineWidth: 1.2)
                var ford = Path()
                ford.move(to: CGPoint(x: rect.minX, y: rect.maxY - 8))
                ford.addCurve(to: CGPoint(x: rect.maxX, y: rect.maxY - 3), control1: CGPoint(x: rect.width * 0.34, y: rect.maxY - 22), control2: CGPoint(x: rect.width * 0.66, y: rect.maxY + 8))
                context.stroke(ford, with: .color(Theme.moss), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
        }
    }
}

private extension EvidenceCertainty {
    var icon: String {
        switch self {
        case .documented: return "doc.text"
        case .material: return "cube"
        case .later: return "clock"
        case .tradition: return "quote.bubble"
        case .disputed: return "arrow.triangle.branch"
        case .reconstruction: return "scope"
        case .unknown: return "questionmark.circle"
        }
    }
}
