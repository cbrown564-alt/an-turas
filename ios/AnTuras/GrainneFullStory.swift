import SwiftUI

// MARK: - Gráinne / Mayo six-episode prototype

/// The complete Mayo arc: six authored episodes, three beats apiece. `storyStep`
/// is deliberately a flat beat index so an interrupted encounter resumes at the
/// exact screen without introducing a second persistence hierarchy.
struct GrainneStoryView: View {
    @EnvironmentObject private var atlas: AtlasPrototypeModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onOpenEvidence: () -> Void
    let onComplete: () -> Void

    private let storyTop = "grainne-full-story-top"
    private var step: Int { min(max(atlas.storyStep, 0), GrainneStoryBeat.all.count - 1) }
    private var beat: GrainneStoryBeat { GrainneStoryBeat.all[step] }
    private var palette: GrainneEpisodePalette { .init(episode: beat.episode) }
    private var completed: Bool { atlas.completedStoryBeats.contains(step) }
    private var hasGeneratedHero: Bool {
        if case .generated = beat.hero { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            storyChrome
            ScrollViewReader { proxy in
                ScrollView {
                    Color.clear.frame(height: 0).id(storyTop)
                    VStack(alignment: .leading, spacing: 22) {
                        if !hasGeneratedHero { beatHeader }
                        hero
                        storyCopy
                            .padding(.horizontal, hasGeneratedHero ? 20 : 0)
                        actionSurface
                            .padding(.horizontal, hasGeneratedHero ? 20 : 0)
                        if beat.showsVoyageChart {
                            VoyageChartView(completedEpisode: completedEpisode)
                                .padding(.horizontal, hasGeneratedHero ? 20 : 0)
                        }
                    }
                    .id(step)
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .padding(.horizontal, hasGeneratedHero ? 0 : 20)
                    .padding(.top, 18)
                    .padding(.bottom, 110)
                    .frame(maxWidth: 700)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: step) { _, _ in
                    Task { @MainActor in
                        await Task.yield()
                        proxy.scrollTo(storyTop, anchor: .top)
                    }
                }
            }
        }
        .background(palette.surface.ignoresSafeArea())
        .foregroundStyle(palette.ink)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(palette.surface, for: .navigationBar)
        .safeAreaInset(edge: .bottom) { storyControls }
    }

    private var completedEpisode: Int {
        let completedBeats = Set(atlas.completedStoryBeats)
        // Each episode closes on its third beat. Narrative beats do not require
        // an interaction, so the closing beat is the durable completion marker.
        return (1...6).last(where: { episode in
            completedBeats.contains((episode * 3) - 1)
        }) ?? 0
    }

    private var storyChrome: some View {
        VStack(spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text("Episode \(beat.episode) of 6")
                Spacer()
                Text(beat.episodeTitle)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(palette.secondaryInk)

            HStack(spacing: 8) {
                ForEach(1...6, id: \.self) { episode in
                    Capsule()
                        .fill(episode < beat.episode ? palette.completed : (episode == beat.episode ? palette.accent : palette.track))
                        .frame(maxWidth: .infinity)
                        .frame(height: episode == beat.episode ? 4 : 2)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
        .background(palette.surface)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Episode \(beat.episode) of 6, \(beat.episodeTitle), beat \(beat.beatInEpisode) of 3")
    }

    private var beatHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(beat.location.uppercased())
                .font(.caption.weight(.semibold))
                .kerning(1.3)
                .foregroundStyle(palette.accent)
            Text(beat.title)
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let question = beat.question {
                Text(question)
                    .font(.system(.title3, design: .serif))
                    .foregroundStyle(palette.secondaryInk)
                    .lineSpacing(5)
            }
        }
    }

    @ViewBuilder
    private var hero: some View {
        switch beat.hero {
        case .generated(let name, let label):
            StoryGeneratedHero(
                name: name,
                label: label,
                location: beat.location,
                title: beat.title,
                palette: palette
            )
        case .rockfleet:
            ZStack(alignment: .bottomLeading) {
                ClewBayMiniature().frame(height: 330)
                LinearGradient(colors: [.clear, Theme.atlantic.opacity(0.9)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 4) {
                    Text("CARRAIG A CHABHLAIGH")
                        .font(.caption.weight(.semibold)).kerning(1.2)
                    Text("Harbour, household, stronghold.")
                        .font(.system(.title2, design: .serif, weight: .semibold))
                }
                .foregroundStyle(Theme.salt)
                .padding(18)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Editorial map of Clew Bay locating Rockfleet Castle")
        case .pressure:
            GrainnePressureField()
        case .document:
            GrainneOrderField(answered: atlas.completedStoryBeats.contains(14))
        case .none:
            EmptyView()
        }
    }

    private var storyCopy: some View {
        VStack(alignment: .leading, spacing: 14) {
            if hasGeneratedHero, let question = beat.question {
                Text(question)
                    .font(.system(.title3, design: .serif))
                    .foregroundStyle(palette.secondaryInk)
                    .lineSpacing(5)
            }
            Text(beat.body)
                .font(.system(.title3, design: .serif))
                .foregroundStyle(palette.ink)
                .lineSpacing(6)
            if let detail = beat.detail {
                Text(detail)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(palette.secondaryInk)
                    .lineSpacing(5)
            }
            if let source = beat.source {
                Button(action: onOpenEvidence) {
                    HStack(alignment: .top, spacing: 11) {
                        Image(systemName: "doc.text")
                            .frame(width: 26, height: 26)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(source.title).font(.headline)
                            Text(source.detail).font(.subheadline).lineSpacing(3)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(palette.ink)
                    .padding(15)
                    .background(palette.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(CarvePress())
                .accessibilityHint("Opens the complete source guide")
            }
        }
    }

    @ViewBuilder
    private var actionSurface: some View {
        switch beat.action {
        case .none:
            EmptyView()
        case .words(let words, let prompt, let recordedLine):
            WordCarryAction(
                words: words,
                prompt: prompt,
                recordedLine: recordedLine,
                palette: palette,
                completed: completed,
                onComplete: { markCurrentBeatComplete() }
            )
        case .pairedVoices:
            PairedVoicesAction(completed: completed, onComplete: { markCurrentBeatComplete() })
        case .findName:
            FullArcNameFind(
                found: $atlas.storyFoundName,
                onOpenEvidence: onOpenEvidence,
                onFound: { markCurrentBeatComplete() }
            )
        case .identity:
            IdentityAction(
                initialName: atlas.learnerName,
                completed: completed,
                onComplete: { name, _ in
                    atlas.learnerName = name
                    markCurrentBeatComplete()
                }
            )
        case .answer:
            AnswerAction(completed: completed, onComplete: { markCurrentBeatComplete() })
        case .finishChart:
            FinishChartAction(
                learnerName: atlas.learnerName,
                completed: completed,
                onComplete: { markCurrentBeatComplete() }
            )
        }
    }

    private var storyControls: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let reason = blockedReason {
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(palette.secondaryInk)
                    .accessibilityLabel("To continue: \(reason)")
            }
            HStack(spacing: 12) {
                if step > 0 {
                    Button { move(to: step - 1) } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(palette.ink)
                            .frame(width: 44, height: 44)
                            .background(palette.raised)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .buttonStyle(CarvePress())
                    .accessibilityLabel("Previous story beat")
                }
                PrimaryButton(title: nextTitle, fullWidth: true) {
                    if step == GrainneStoryBeat.all.count - 1 {
                        onComplete()
                    } else {
                        move(to: step + 1)
                    }
                }
                .disabled(blockedReason != nil)
                .opacity(blockedReason == nil ? 1 : 0.45)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(palette.surface.opacity(0.96))
    }

    private var blockedReason: String? {
        guard beat.action.requiresCompletion, !completed else { return nil }
        switch beat.action {
        case .findName: return "Find Gráinne’s name in the record."
        case .identity: return "Say your name and where you are from."
        case .answer: return "Mark what the order does not finish."
        case .finishChart: return "Complete the return line on the voyage chart."
        case .words: return "Listen to each word and find its meaning."
        case .pairedVoices: return "Compare what each account needs from the state."
        case .none: return nil
        }
    }

    private var nextTitle: String {
        if step == GrainneStoryBeat.all.count - 1 { return "Carry Mayo with you" }
        return beat.nextTitle
    }

    private func move(to newStep: Int) {
        Haptics.tap()
        withAnimation(reduceMotion ? nil : Motion.settle) {
            atlas.storyStep = min(max(newStep, 0), GrainneStoryBeat.all.count - 1)
        }
    }

    private func markCurrentBeatComplete() {
        guard !atlas.completedStoryBeats.contains(step) else { return }
        Haptics.chisel()
        withAnimation(reduceMotion ? nil : Motion.settle) {
            atlas.completedStoryBeats.append(step)
            atlas.completedStoryBeats.sort()
        }
    }

}

// MARK: - Beat content

private struct GrainneStoryBeat {
    enum Hero {
        case generated(String, String)
        case rockfleet, pressure, document, none
    }

    enum Action {
        case none
        case words([GrainneWord], String, GrainneRecordedLine? = nil)
        case pairedVoices, findName, identity, answer, finishChart

        var requiresCompletion: Bool {
            if case .none = self { return false }
            return true
        }
    }

    let episode: Int
    let episodeTitle: String
    let beatInEpisode: Int
    let location: String
    let title: String
    let question: String?
    let body: String
    let detail: String?
    let hero: Hero
    let source: GrainneSource?
    let action: Action
    let nextTitle: String

    /// The chart is a story object, not persistent navigation chrome. It returns
    /// only when a route or inscription has materially changed.
    var showsVoyageChart: Bool {
        beatInEpisode == 3 && [1, 4, 5, 6].contains(episode)
    }

    static let all: [Self] = [
        .init(episode: 1, episodeTitle: "An Bá · Clew Bay", beatInEpisode: 1, location: "Clew Bay · before 1593", title: "Where the road is water", question: "How do you hold a coast made of islands?", body: "Clew Bay breaks the Mayo shore into water, islands and narrow landings. Here, a boat can join places that a road cannot.", detail: "To know this bay is to know where people, news and force can move—and where weather can stop them.", hero: .generated("grainne-clew-bay", "Generated editorial interpretation of Clew Bay"), source: nil, action: .none, nextTitle: "Follow the water"),
        .init(episode: 1, episodeTitle: "An Bá · Clew Bay", beatInEpisode: 2, location: "Umhaill · the maritime world", title: "They knew her as a captain", question: nil, body: "English officials wrote of Gráinne as a woman who led at sea. Their words are hostile, but the hostility gives something away: they took her power seriously.", detail: "“Pirate queen” is the later legend. The older record shows boats, followers, wealth and force on a contested coast.", hero: .none, source: .init(title: "An English official describes Gráinne at sea", detail: "A period English description, read with its political bias visible."), action: .none, nextTitle: "Hear the bay in Irish"),
        .init(episode: 1, episodeTitle: "An Bá · Clew Bay", beatInEpisode: 3, location: "The words of the bay", title: "Farraige. Bá. Long. Áit.", question: nil, body: "Sea. Bay. Ship. Place. Four words draw the world beneath her story.", detail: nil, hero: .none, source: nil, action: .words([.farraige, .ba, .long, .ait], "Listen first. Then match each sound to the coast in front of you.", .init(ga: "Is as Maigh Eo mé.", en: "I am from Mayo.", sound: "iss ass my-oh may")), nextTitle: "Enter Rockfleet"),

        .init(episode: 2, episodeTitle: "Carraig a Chabhlaigh · Rockfleet", beatInEpisode: 1, location: "Rockfleet · the tide line", title: "A castle at the tide line", question: "What can be held from here?", body: "At Rockfleet, the tide comes close to the walls. Boats extend the castle across the bay; the castle gives those boats a defended home.", detail: "This is not a lonely ruin in Gráinne’s story. It is harbour, household and stronghold together.", hero: .rockfleet, source: nil, action: .none, nextTitle: "Meet the household"),
        .init(episode: 2, episodeTitle: "Carraig a Chabhlaigh · Rockfleet", beatInEpisode: 2, location: "Castle · fleet · kin", title: "Her power had family names", question: nil, body: "Children, brother, followers, land and boats appear together in the crisis of 1593. Harm one part and the whole household feels it.", detail: "The state papers do not give us a private family portrait. They show why these people mattered politically.", hero: .none, source: .init(title: "The 1593 papers name the family in the case", detail: "The record gives the household political weight without telling every private story."), action: .none, nextTitle: "Name what is held"),
        .init(episode: 2, episodeTitle: "Carraig a Chabhlaigh · Rockfleet", beatInEpisode: 3, location: "Inside Rockfleet", title: "Caisleán. Teaghlach. Mac. Bean.", question: nil, body: "The castle is stone. The household is people. The record will put both under pressure.", detail: nil, hero: .none, source: nil, action: .words([.caislean, .teaghlach, .mac, .bean], "Hear each word, then find the person or place it names."), nextTitle: "See what closes in"),

        .init(episode: 3, episodeTitle: "An Brú · The pressure", beatInEpisode: 1, location: "Clew Bay · pressure closing", title: "Her sons are held. Her living is cut away.", question: "What road remains when power closes the others?", body: "Richard Bingham’s government bears down on Gráinne’s family and livelihood. Tibbott and Donal are held. The boats and maintenance that sustain her authority are at risk.", detail: "This is the turn in the story: staying on the coast will not free them.", hero: .pressure, source: nil, action: .none, nextTitle: "Read the two accounts"),
        .init(episode: 3, episodeTitle: "An Brú · The pressure", beatInEpisode: 2, location: "Two accounts · one coast", title: "The same coast, told two ways", question: nil, body: "Bingham writes as a governor defending severity. Gráinne petitions as a leader seeking release and maintenance. Each account wants the state to act.", detail: "Purpose does not make either source useless. It tells us how to read what each one can prove.", hero: .none, source: .init(title: "Hostile letters and petition pleas", detail: "Compare purpose, audience and what each speaker needs the state to believe."), action: .pairedVoices, nextTitle: "Choose the road that remains"),
        .init(episode: 3, episodeTitle: "An Brú · The pressure", beatInEpisode: 3, location: "The decision", title: "Caill. Deartháir. Iarr. Téigh.", question: nil, body: "Lose. Brother. Ask. Go. The words now form a chain: loss makes the asking necessary; asking means going.", detail: nil, hero: .none, source: nil, action: .words([.caill, .dearthair, .iarr, .teigh], "Listen for the action that turns the story toward London."), nextTitle: "Cross to London"),

        .init(episode: 4, episodeTitle: "An Litir · Crossing and record", beatInEpisode: 1, location: "Clew Bay → London · 1593", title: "The sea road ends in rooms of paper", question: "How does a Mayo leader make the English state hear her?", body: "Gráinne crosses to London with a case to press. There, claims become petitions, questions, answers and draft instructions.", detail: "No surviving source gives us her conversation with Elizabeth. The papers show the case moving through government.", hero: .generated("grainne-crossing", "Generated interpretive portrait of Gráinne on the Atlantic crossing"), source: nil, action: .none, nextTitle: "Open the July questions"),
        .init(episode: 4, episodeTitle: "An Litir · Crossing and record", beatInEpisode: 2, location: "London · July 1593", title: "There she is: “Grany Ne Malley”", question: nil, body: "Her name stands at the head of eighteen questions. An English clerk bends it into another spelling, but the person is not lost.", detail: "Her answers name parents, marriages, children, lands and how she maintained her people. The voyage becomes visible in a record shaped by the questions of the state.", hero: .none, source: .init(title: "Interrogatory and answers, July 1593", detail: "The National Archives, SP 63/170, ff. 201–202. Folio 201 is shown under the app’s free, exclusively educational use policy."), action: .findName, nextTitle: "Hear her name restored"),
        .init(episode: 4, episodeTitle: "An Litir · Crossing and record", beatInEpisode: 3, location: "A name across languages", title: "Ainm. Mise. Tar.", question: nil, body: "The calendar renders the heading as “Grany Ne Malley.” Hear the name she carries in Irish: Gráinne Ní Mháille.", detail: "Keep the pattern. Make the lines yours.", hero: .none, source: nil, action: .identity, nextTitle: "See what answer returns"),

        .init(episode: 5, episodeTitle: "An Freagra · The answer", beatInEpisode: 1, location: "The court · September 1593", title: "The answer becomes an order", question: "Can paper change what happens on the Mayo coast?", body: "Instructions leave the court for Bingham. They order release and relief in response to the case Gráinne has brought.", detail: "The state has answered. That is not the same as saying the order will be obeyed.", hero: .document, source: .init(title: "Draft instructions to Bingham, September 1593", detail: "A draft order supports the answer; its implementation remains a separate question."), action: .none, nextTitle: "Follow the paper home"),
        .init(episode: 5, episodeTitle: "An Freagra · The answer", beatInEpisode: 2, location: "London → Connacht", title: "The order travels. Relief does not fully follow.", question: nil, body: "Bingham does not give the instruction full effect. Gráinne has forced an answer from the centre of power, but the pressure on the coast is not over.", detail: nil, hero: .none, source: nil, action: .answer, nextTitle: "Name what remains unfinished"),
        .init(episode: 5, episodeTitle: "An Freagra · The answer", beatInEpisode: 3, location: "The unfinished verb", title: "Freagair. Tabhair. Arís.", question: nil, body: "Answer. Give. Again. One verb names what the court did; another names what was withheld; the last opens the road back.", detail: nil, hero: .none, source: nil, action: .words([.freagair, .tabhair, .aris], "Listen, then place each action on the right side of the order."), nextTitle: "Return to the coast"),

        .init(episode: 6, episodeTitle: "Ar Ais · Return and coast", beatInEpisode: 1, location: "Mayo · the return line", title: "The line home does not close", question: "What remains when the royal answer is not enough?", body: "Further pressure brings further petitions. Gráinne’s journey to London has changed the record, but it has not made the Mayo coast safe or settled.", detail: "The surviving trail asks us to hold achievement and incompletion together.", hero: .generated("grainne-return", "Generated editorial interpretation of the Mayo coast and the return route"), source: .init(title: "The later petition trail", detail: "Further petitions show that the answer did not settle the pressure on the coast."), action: .none, nextTitle: "Stand on the shore today"),
        .init(episode: 6, episodeTitle: "Ar Ais · Return and coast", beatInEpisode: 2, location: "Clew Bay · today", title: "The coast remembers in different ways", question: nil, body: "Rockfleet still stands beside Clew Bay. The state papers preserve a journey and a demand. Later stories preserve an image of defiance.", detail: "Place, document and legend can all matter without being treated as the same kind of evidence.", hero: .none, source: nil, action: .words([.costa, .ba, .ait, .caislean], "Hear cósta—coast—then find the earlier words that still belong here: bá, áit, caisleán."), nextTitle: "Complete the return line"),
        .init(episode: 6, episodeTitle: "Ar Ais · Return and coast", beatInEpisode: 3, location: "Clew Bay → London → Mayo", title: "Back to Mayo, carrying an answer", question: "What will make this story return to you?", body: "The route now joins Clew Bay, London and Mayo again. Along it sit twenty Irish words for sea, family, loss, asking, answer and return.", detail: "The chart records a documented crossing. Your two Irish lines sit beside it as something you made here.", hero: .none, source: nil, action: .finishChart, nextTitle: "Carry Mayo with you")
    ]
}

private struct GrainneSource {
    let title: String
    let detail: String
}

private struct GrainneRecordedLine {
    let ga: String
    let en: String
    let sound: String
}

private struct GrainneWord: Identifiable {
    let ga: String
    let en: String
    let sound: String
    var id: String { ga }

    static let farraige = Self(ga: "farraige", en: "sea", sound: "far-ig-eh")
    static let ba = Self(ga: "bá", en: "bay", sound: "baw")
    static let long = Self(ga: "long", en: "ship", sound: "lung")
    static let ait = Self(ga: "áit", en: "place", sound: "awtch")
    static let caislean = Self(ga: "caisleán", en: "castle", sound: "kash-lawn")
    static let teaghlach = Self(ga: "teaghlach", en: "family", sound: "chai-lukh")
    static let mac = Self(ga: "mac", en: "son", sound: "mock")
    static let bean = Self(ga: "bean", en: "woman", sound: "ban")
    static let caill = Self(ga: "caill", en: "lose", sound: "kyle")
    static let dearthair = Self(ga: "deartháir", en: "brother", sound: "djar-hawr")
    static let iarr = Self(ga: "iarr", en: "ask", sound: "eer")
    static let teigh = Self(ga: "téigh", en: "go", sound: "tay")
    static let freagair = Self(ga: "freagair", en: "answer", sound: "frag-ir")
    static let tabhair = Self(ga: "tabhair", en: "give", sound: "toor")
    static let aris = Self(ga: "arís", en: "again", sound: "uh-reesh")
    static let costa = Self(ga: "cósta", en: "coast", sound: "koh-sta")
}

// MARK: - Episode palette

private struct GrainneEpisodePalette {
    let episode: Int
    var isDark: Bool { episode == 4 || episode == 5 }
    var surface: Color { isDark ? Theme.atlantic : Theme.bg }
    var raised: Color { isDark ? Color(light: 0x24343A, dark: 0x1C2A30) : Theme.raised }
    var ink: Color { isDark ? Theme.salt : Theme.ink }
    var secondaryInk: Color { isDark ? Color.white.opacity(0.76) : Theme.inkSoft }
    var track: Color { isDark ? Color.white.opacity(0.2) : Theme.line }
    var completed: Color { episode >= 5 ? Theme.weatheredGold : Theme.moss }
    var accent: Color {
        switch episode {
        case 1, 2: return Theme.moss
        case 3: return Theme.storm
        case 4, 5: return Theme.rust
        default: return Theme.weatheredGold
        }
    }
}

// MARK: - Story actions

private struct WordCarryAction: View {
    let words: [GrainneWord]
    let prompt: String
    let recordedLine: GrainneRecordedLine?
    let palette: GrainneEpisodePalette
    let completed: Bool
    let onComplete: () -> Void

    @State private var currentIndex = 0
    @State private var heardWords: Set<String> = []
    @State private var wrongMeaning: String?
    @State private var understoodWord: String?

    private var currentWord: GrainneWord {
        words[min(currentIndex, max(words.count - 1, 0))]
    }

    private var hasHeardCurrentWord: Bool {
        heardWords.contains(currentWord.id)
    }

    private var meaningOptions: [String] {
        let fallbacks = ["sea", "family", "ask", "return", "place", "answer"]
        let alternatives = (words.map(\.en) + fallbacks)
            .filter { $0 != currentWord.en }
            .reduce(into: [String]()) { result, value in
                if !result.contains(value) { result.append(value) }
            }
        return ([currentWord.en] + alternatives.prefix(2)).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let recordedLine {
                AtlasAudioLine(ga: recordedLine.ga, en: recordedLine.en, sound: recordedLine.sound)
            }
            Text(prompt)
                .font(.body)
                .foregroundStyle(palette.secondaryInk)
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentWord.ga)
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    Text("\(currentIndex + 1) of \(words.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(palette.secondaryInk)
                }
                Spacer(minLength: 8)
                Button {
                    Haptics.tap()
                    SpeechService.shared.speak(currentWord.ga)
                    heardWords.insert(currentWord.id)
                    wrongMeaning = nil
                } label: {
                    Image(systemName: hasHeardCurrentWord ? "speaker.wave.2.fill" : "speaker.wave.2")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(palette.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(CarvePress())
                .disabled(!SpeechService.shared.canSpeak(currentWord.ga))
                .accessibilityLabel("Hear \(currentWord.ga)")
                .accessibilityHint("Plays the bundled Irish recording")
            }

            if hasHeardCurrentWord {
                Text("Say it like · \(currentWord.sound)")
                    .font(.caption)
                    .foregroundStyle(palette.secondaryInk)
                Text("Which meaning belongs to what you heard?")
                    .font(.headline)
                    .foregroundStyle(palette.ink)
                ForEach(meaningOptions, id: \.self) { meaning in
                    Button {
                        choose(meaning)
                    } label: {
                        HStack {
                            Text(meaning)
                            Spacer()
                            if wrongMeaning == meaning {
                                Image(systemName: "arrow.uturn.left")
                            }
                        }
                        .font(.body.weight(.medium))
                        .foregroundStyle(palette.ink)
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .buttonStyle(CarvePress())
                    .disabled(understoodWord != nil)
                }
                if understoodWord != nil {
                    Label("Heard and understood", systemImage: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.accent)
                        .transition(.opacity)
                        .accessibilityAddTraits(.isStaticText)
                }
                if wrongMeaning != nil {
                    Text("Listen once more. The sound is the clue.")
                        .font(.caption)
                        .foregroundStyle(palette.secondaryInk)
                        .accessibilityLabel("Not that meaning. Listen once more.")
                }
            } else if SpeechService.shared.canSpeak(currentWord.ga) {
                Text("Listen first. The meaning stays covered until the word has a voice.")
                    .font(.caption)
                    .foregroundStyle(palette.secondaryInk)
            } else {
                Text("This recording is missing. Audio is required before this exercise can ship.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.rust)
            }
        }
        .padding(16)
        .background(palette.raised.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func choose(_ meaning: String) {
        guard meaning == currentWord.en else {
            wrongMeaning = meaning
            Haptics.error()
            return
        }

        wrongMeaning = nil
        Haptics.chisel()
        understoodWord = currentWord.id
        let isLastWord = currentIndex == words.count - 1
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            if isLastWord {
                onComplete()
            } else {
                withAnimation(Motion.settle) { currentIndex += 1 }
            }
            understoodWord = nil
        }
    }
}

private struct PairedVoicesAction: View {
    let completed: Bool
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            voice("Bingham needs to justify", "Severity and the treatment of resistance as disorder.", "exclamationmark.bubble")
            Divider()
            voice("Gráinne needs to obtain", "Release, maintenance and a path for her family.", "quote.bubble")
            Button(action: onComplete) {
                Label(completed ? "Purposes marked" : "Keep both purposes visible", systemImage: completed ? "checkmark" : "arrow.triangle.branch")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .tint(Theme.storm)
            .disabled(completed)
        }
        .padding(16)
        .background(Theme.raised)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func voice(_ title: String, _ text: String, _ icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundStyle(Theme.storm).frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(text).font(.system(.body, design: .serif)).foregroundStyle(Theme.inkSoft).lineSpacing(4)
            }
        }
    }
}

struct TNAInterrogatoryFolio: View {
    let highlightName: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image("SP63170F201")
                .resizable()
                .scaledToFit()
                .overlay {
                    GeometryReader { geometry in
                        if highlightName {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Theme.rust, lineWidth: 3)
                                .background(Theme.rust.opacity(0.10))
                                .frame(width: geometry.size.width * 0.58, height: geometry.size.height * 0.065)
                                .offset(x: geometry.size.width * 0.33, y: geometry.size.height * 0.025)
                                .transition(.opacity)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .background(Color.black.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityLabel("Original manuscript page. The first page of the July 1593 interrogatory, The National Archives, SP 63/170, folio 201.")
            Text("The National Archives, SP 63/170, f. 201 · Crown copyright · educational use")
                .font(.caption2)
                .foregroundStyle(Theme.inkSoft)
        }
    }
}

private struct FullArcNameFind: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var found: Bool
    let onOpenEvidence: () -> Void
    let onFound: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("ORIGINAL MANUSCRIPT · TNA SP 63/170 F. 201")
                .font(.caption2.weight(.semibold)).kerning(1.1)
                .foregroundStyle(Color.white.opacity(0.72))
            TNAInterrogatoryFolio(highlightName: found)
            if found {
                VStack(spacing: 7) {
                    Text("Grany Ne Malley")
                        .font(.system(.title2, design: .serif, weight: .semibold))
                    Text("Gráinne Ní Mháille")
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.atlasGreen)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .transition(.opacity)
            }
            if !found {
                Button {
                    withAnimation(reduceMotion ? nil : Motion.settle) { found = true }
                    onFound()
                } label: {
                    Label("Find Gráinne’s name", systemImage: "text.magnifyingglass")
                        .font(.headline)
                        .foregroundStyle(Theme.salt)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(Theme.rust)
            }
            Button(action: onOpenEvidence) {
                Label("About this source", systemImage: "doc.text")
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.salt)
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct IdentityAction: View {
    private enum Field: Hashable { case name, place }
    @FocusState private var focusedField: Field?
    @State private var name: String
    @State private var place = ""
    let completed: Bool
    let onComplete: (String, String) -> Void

    init(initialName: String, completed: Bool, onComplete: @escaping (String, String) -> Void) {
        _name = State(initialValue: initialName)
        self.completed = completed
        self.onComplete = onComplete
    }

    private var ready: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !place.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            AtlasAudioLine(ga: "Is mise Gráinne.", en: "I am Gráinne.", sound: "iss mish-eh grawn-ya")
            Text("Keep the pattern. Change only the name.")
                .font(.body)
                .foregroundStyle(Color.white.opacity(0.76))
            TextField("Your name", text: $name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .font(.system(.title3, design: .serif))
                .padding(13)
                .background(Theme.salt)
                .foregroundStyle(Theme.atlantic)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .accessibilityLabel("Your name")
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
                .onSubmit { focusedField = .place }
            AtlasAudioLine(ga: "Is as Maigh Eo mé.", en: "I am from Mayo.", sound: "iss ass my-oh may")
            Text("Keep the pattern. Change only the place.")
                .font(.body)
                .foregroundStyle(Color.white.opacity(0.76))
            TextField("The place you are from", text: $place)
                .textInputAutocapitalization(.words)
                .font(.system(.title3, design: .serif))
                .padding(13)
                .background(Theme.salt)
                .foregroundStyle(Theme.atlantic)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .accessibilityLabel("The place you are from")
                .focused($focusedField, equals: .place)
                .submitLabel(.done)
                .onSubmit { focusedField = nil }
            if ready {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Is mise \(name).")
                    Text("As \(place) mé.")
                }
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.salt)
            }
            if completed {
                Text("Your name has entered Irish; it has not entered Gráinne’s story.")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.76))
            }
            Button {
                focusedField = nil
                onComplete(
                    name.trimmingCharacters(in: .whitespacesAndNewlines),
                    place.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            } label: {
                Label(completed ? "Lines made" : "Make the lines yours", systemImage: completed ? "checkmark" : "person.text.rectangle")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .tint(Theme.rust)
            .disabled(!ready || completed)
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct AnswerAction: View {
    let completed: Bool
    let onComplete: () -> Void

    @State private var supportedClaimSelected = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Which claim goes beyond the surviving evidence?")
                .font(.headline)
                .foregroundStyle(Theme.salt)

            if completed {
                OutcomeLine(
                    icon: "doc.text",
                    title: "The government ordered relief",
                    text: "The draft instruction supports this claim.",
                    color: Theme.weatheredGold
                )
                OutcomeLine(
                    icon: "questionmark.circle",
                    title: "The order ended the conflict",
                    text: "The surviving evidence cannot support this claim.",
                    color: Theme.rust
                )
                Label("Difference marked", systemImage: "checkmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.weatheredGold)
            } else {
                claimButton("The government ordered relief") {
                    supportedClaimSelected = true
                    Haptics.error()
                }
                claimButton("The order ended the conflict") {
                    supportedClaimSelected = false
                    onComplete()
                }
            }

            if supportedClaimSelected && !completed {
                Label(
                    "The draft supports that claim. Look for what the paper cannot prove.",
                    systemImage: "arrow.uturn.left"
                )
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.76))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func claimButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
            }
            .font(.body.weight(.medium))
            .foregroundStyle(Theme.salt)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(CarvePress())
    }
}

private struct FinishChartAction: View {
    let learnerName: String
    let completed: Bool
    let onComplete: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(learnerName.isEmpty ? "Gráinne Ní Mháille · Mayo · 1593" : "Gráinne Ní Mháille · Is mise \(learnerName)")
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text("The chart records a documented crossing. Your two Irish lines sit beside it as something you made here.")
                .font(.body).foregroundStyle(Theme.inkSoft).lineSpacing(4)
            Button(action: onComplete) {
                Label(completed ? "Final line drawn" : "Draw the final line home", systemImage: completed ? "checkmark" : "pencil.and.scribble")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.weatheredGold)
            .disabled(completed)
        }
        .padding(16)
        .background(Theme.raised)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct OutcomeLine: View {
    let icon: String
    let title: String
    let text: String
    let color: Color
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundStyle(Theme.salt)
                Text(text).font(.system(.body, design: .serif)).foregroundStyle(Color.white.opacity(0.76))
            }
        }
    }
}

// MARK: - Visual fields

private struct StoryGeneratedHero: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let name: String
    let label: String
    let location: String
    let title: String
    let palette: GrainneEpisodePalette

    private var placesTextOnRight: Bool { name == "grainne-crossing" }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 0) {
                    heroImage(height: 250)
                    heroText
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(palette.raised)
                }
            } else {
                ZStack(alignment: placesTextOnRight ? .topTrailing : .topLeading) {
                    heroImage(height: 330)
                    readabilityField
                    heroText
                        .frame(maxWidth: placesTextOnRight ? 190 : 250, alignment: .leading)
                        .padding(.horizontal, 22)
                        .padding(.top, 24)
                }
                .frame(height: 330)
            }
        }
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label + "; this is an interpretation, not documentary evidence")
    }

    private func heroImage(height: CGFloat) -> some View {
        GeometryReader { geometry in
            StoryArtImage(name: name)
                .scaledToFill()
                .frame(width: geometry.size.width, height: height)
                .clipped()
        }
        .frame(height: height)
    }

    @ViewBuilder
    private var readabilityField: some View {
        if palette.isDark {
            LinearGradient(
                colors: [.clear, Theme.atlantic.opacity(0.18), Theme.atlantic.opacity(0.92)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            LinearGradient(
                colors: [palette.surface.opacity(0.80), palette.surface.opacity(0.34), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var heroText: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(placesTextOnRight ? "CLEW BAY →\nLONDON · 1593" : location.uppercased())
                .font(.caption.weight(.semibold))
                .kerning(1.2)
                .foregroundStyle(palette.accent)
            Text(title)
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct GrainnePressureField: View {
    var body: some View {
        ZStack {
            Theme.atlantic
            Canvas { context, size in
                let points = [
                    CGPoint(x: size.width * 0.08, y: size.height * 0.76),
                    CGPoint(x: size.width * 0.31, y: size.height * 0.63),
                    CGPoint(x: size.width * 0.48, y: size.height * 0.70),
                    CGPoint(x: size.width * 0.68, y: size.height * 0.42),
                    CGPoint(x: size.width * 0.91, y: size.height * 0.20)
                ]
                var path = Path()
                path.move(to: points[0])
                points.dropFirst().forEach { path.addLine(to: $0) }
                context.stroke(path, with: .color(Theme.rust), style: StrokeStyle(lineWidth: 2.5, dash: [7, 7]))
                for (index, point) in points.enumerated() {
                    let radius: CGFloat = index == points.count - 1 ? 7 : 4
                    context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)), with: .color(index == points.count - 1 ? Theme.weatheredGold : Theme.storm))
                }
                let closing = CGRect(x: size.width * 0.62, y: 0, width: size.width * 0.38, height: size.height)
                context.fill(Path(closing), with: .color(Theme.rust.opacity(0.12)))
            }
            VStack(alignment: .leading, spacing: 6) {
                Spacer()
                Text("The route narrows.").font(.system(.title2, design: .serif, weight: .semibold))
                Text("The petition becomes the remaining path.").font(.body)
            }
            .foregroundStyle(Theme.salt)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
        }
        .frame(height: 310)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Abstract route field showing pressure closing around the remaining path to London")
    }
}

private struct GrainneOrderField: View {
    let answered: Bool
    var body: some View {
        ZStack {
            Theme.atlantic
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(light: 0xDDD1AE, dark: 0xA89972))
                .frame(width: 220, height: 280)
                .rotationEffect(.degrees(-3))
                .overlay {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("6 SEPTEMBER 1593").font(.caption2.weight(.bold)).kerning(1)
                        Text("Relief is ordered.").font(.system(.title2, design: .serif, weight: .semibold))
                        Divider().overlay(Color.black.opacity(0.4))
                        Text("The effect remains unfinished.").font(.system(.body, design: .serif))
                    }
                    .foregroundStyle(Color.black.opacity(0.72))
                    .padding(22)
                    .frame(width: 220, height: 280, alignment: .topLeading)
                    .rotationEffect(.degrees(-3))
                }
            Path { path in
                path.move(to: CGPoint(x: 0, y: 285))
                path.addLine(to: CGPoint(x: 420, y: answered ? 245 : 310))
            }
            .stroke(Theme.rust, style: StrokeStyle(lineWidth: 3, dash: [9, 7]))
        }
        .frame(height: 330)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel("Interpretive composition of the royal order and an incomplete route back to Mayo")
    }
}

private struct VoyageChartView: View {
    let completedEpisode: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(completedEpisode == 6 ? "Your Mayo chart" : "The route so far").font(.headline)
                Spacer()
                Text("\(completedEpisode) / 6").font(.caption.monospacedDigit()).foregroundStyle(Theme.inkSoft)
            }
            Canvas { context, size in
                let points = [
                    CGPoint(x: size.width * 0.08, y: size.height * 0.70),
                    CGPoint(x: size.width * 0.25, y: size.height * 0.52),
                    CGPoint(x: size.width * 0.42, y: size.height * 0.62),
                    CGPoint(x: size.width * 0.70, y: size.height * 0.20),
                    CGPoint(x: size.width * 0.86, y: size.height * 0.38),
                    CGPoint(x: size.width * 0.62, y: size.height * 0.76)
                ]
                var route = Path()
                route.move(to: points[0])
                for index in 1..<min(max(completedEpisode + 1, 1), points.count) {
                    route.addLine(to: points[index])
                }
                context.stroke(route, with: .color(completedEpisode == 6 ? Theme.weatheredGold : Theme.moss), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                for (index, point) in points.enumerated() where index < completedEpisode {
                    context.fill(Path(ellipseIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)), with: .color(index == 5 ? Theme.weatheredGold : Theme.moss))
                }
            }
            .frame(height: 105)
            .background(Theme.sunk)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(14)
        .background(Theme.raised)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Voyage chart with \(completedEpisode) of 6 episode segments complete")
    }
}

/// Loads loose illustration files from the bundled `art` folder. SwiftUI's
/// asset-name initializer only searches asset catalogs and otherwise logs a
/// misleading missing-image warning for folder resources.
struct StoryArtImage: View {
    let name: String

    var body: some View {
        if let image = load() {
            Image(uiImage: image).resizable()
        } else {
            ZStack {
                Theme.sunk
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(Theme.inkFaint)
            }
            .accessibilityLabel("Illustration unavailable")
        }
    }

    private func load() -> UIImage? {
        for fileExtension in ["png", "jpg", "jpeg"] {
            if let url = Bundle.main.url(forResource: name, withExtension: fileExtension, subdirectory: "art"),
               let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }
        return nil
    }
}
