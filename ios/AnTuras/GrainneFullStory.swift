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
            Text(beat.question)
                .font(.system(.title3, design: .serif))
                .foregroundStyle(palette.secondaryInk)
                .lineSpacing(5)
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
                    Text("Castle, fleet, household.")
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
            if hasGeneratedHero {
                Text(beat.question)
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
        case .words(let words, let prompt):
            WordCarryAction(
                words: words,
                prompt: prompt,
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
        default: return "Complete this story action."
        }
    }

    private var nextTitle: String {
        if step == GrainneStoryBeat.all.count - 1 { return "Carry Mayo with you" }
        if beat.beatInEpisode == 3 { return "Begin Episode \(beat.episode + 1)" }
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
        case words([GrainneWord], String)
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
    let question: String
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
        .init(episode: 1, episodeTitle: "An Bá · Clew Bay", beatInEpisode: 1, location: "Clew Bay · before 1593", title: "A coast that works like a road", question: "What kind of power lives on this coast?", body: "Clew Bay is not a backdrop. Its islands, inlets and landing places connect households, boats, trade and authority.", detail: "To hold power here is to know what the water joins—and what weather can cut off.", hero: .generated("grainne-clew-bay", "Generated editorial interpretation of Clew Bay"), source: nil, action: .none, nextTitle: "Trace the bay"),
        .init(episode: 1, episodeTitle: "An Bá · Clew Bay", beatInEpisode: 2, location: "Umhaill · the maritime world", title: "The bay makes leaders who live by boats", question: "What survives of that reputation?", body: "English officials recognised Gráinne as a sea captain. Their descriptions are interested and hostile at once: evidence of her standing, not a neutral portrait.", detail: "The coast supported maintenance, movement and force. Calling it simply piracy hides the political world around it.", hero: .none, source: .init(title: "Sidney’s official recognition", detail: "A period English description, read with its political bias visible."), action: .none, nextTitle: "Hear the coast"),
        .init(episode: 1, episodeTitle: "An Bá · Clew Bay", beatInEpisode: 3, location: "The words of the bay", title: "Farraige. Bá. Long. Áit.", question: "Say where this story begins.", body: "The first words are not a list. They name the system beneath the story: sea, bay, ship and place.", detail: "Use as for origin now; the same construction returns when Gráinne’s name reaches London.", hero: .none, source: nil, action: .words([.farraige, .ba, .long, .ait, .asWord], "Listen to the bay. Match each Irish word to what it names."), nextTitle: "Enter Rockfleet"),

        .init(episode: 2, episodeTitle: "Carraig a Chabhlaigh · Rockfleet", beatInEpisode: 1, location: "Rockfleet · the tide line", title: "Power has walls, boats and names", question: "What does Gráinne actually hold?", body: "Rockfleet makes authority spatial. The castle stands where the tide can reach it; the fleet extends that household across the bay.", detail: "This is not a romantic ruin. It is a harbour, a defended place and part of a family system.", hero: .rockfleet, source: nil, action: .none, nextTitle: "Meet the household"),
        .init(episode: 2, episodeTitle: "Carraig a Chabhlaigh · Rockfleet", beatInEpisode: 2, location: "Castle · fleet · kin", title: "A household you can lose", question: "Why do the names in 1593 matter?", body: "Her children, brother, followers, lands and boats are not separate stakes. Together they are the working structure of her authority.", detail: "The later state papers name this family because the petition concerns survival, not personal legend.", hero: .none, source: .init(title: "Family named in the 1593 papers", detail: "The record gives the household political weight without telling every private story."), action: .none, nextTitle: "Name what is held"),
        .init(episode: 2, episodeTitle: "Carraig a Chabhlaigh · Rockfleet", beatInEpisode: 3, location: "Inside Rockfleet", title: "Caisleán. Teaghlach. Mac. Bean.", question: "What belongs to this held place?", body: "Castle, family, son, woman. These words turn a stone tower into the human structure the next episode will place under pressure.", detail: nil, hero: .none, source: nil, action: .words([.caislean, .teaghlach, .mac, .bean], "Listen for stone and household. Find what each word holds."), nextTitle: "Feel the pressure"),

        .init(episode: 3, episodeTitle: "An Brú · The squeeze", beatInEpisode: 1, location: "Clew Bay · pressure closing", title: "Kin held. Livelihood broken.", question: "What forces her hand?", body: "Bingham’s administration closes around the coast. Tibbott and Donal are held; boats, maintenance and authority are put at risk.", detail: "The story does not tour every year of conflict. It stays with the tipping point: the remaining path runs toward a petition.", hero: .pressure, source: nil, action: .none, nextTitle: "Hear both voices"),
        .init(episode: 3, episodeTitle: "An Brú · The squeeze", beatInEpisode: 2, location: "Two accounts · one coast", title: "Troublemaker or maintained leader?", question: "What changes when power describes the same shore?", body: "Bingham presents severity as necessary. Gráinne presents the loss of maintenance and the confinement of her family as wrongs requiring relief.", detail: "Neither voice is scenery. Their purposes help us read what each account can and cannot settle.", hero: .none, source: .init(title: "Hostile letters and petition pleas", detail: "Compare purpose, audience and what each speaker needs the state to believe."), action: .pairedVoices, nextTitle: "Choose the remaining path"),
        .init(episode: 3, episodeTitle: "An Brú · The squeeze", beatInEpisode: 3, location: "The decision", title: "Caill. Deartháir. Iarr. Téigh.", question: "When loss closes one road, what action remains?", body: "Lose. Brother. Ask. Go. The verbs are attached to the decision: she will take the case across the sea.", detail: "The learner examines that choice; they do not defeat Bingham or enter invented history.", hero: .none, source: nil, action: .words([.caill, .dearthair, .iarr, .teigh], "Hear the chain of action: loss, family, asking, departure."), nextTitle: "Cross to London"),

        .init(episode: 4, episodeTitle: "An Litir · The crossing & record", beatInEpisode: 1, location: "Clew Bay → London · 1593", title: "To be heard, she must enter another system", question: "What does the English record reveal?", body: "Gráinne reaches the machinery of petition, articles, answers and draft instructions. The crossing is geographical—and administrative.", detail: "No conversation with Elizabeth is invented. The surviving papers carry the encounter.", hero: .generated("grainne-crossing", "Generated interpretive portrait of Gráinne on the Atlantic crossing"), source: nil, action: .none, nextTitle: "Open the September draft"),
        .init(episode: 4, episodeTitle: "An Litir · The crossing & record", beatInEpisode: 2, location: "London · 6 September 1593", title: "Her name enters the record", question: "Can you find the person inside the state spelling?", body: "The draft writes her name in English administrative form and names members of her family. Finding it is the climax because the record suddenly becomes personal.", detail: nil, hero: .none, source: .init(title: "September 1593 draft instruction", detail: "Annotated transcription for the prototype; the manuscript image is not represented here."), action: .findName, nextTitle: "Say who you are"),
        .init(episode: 4, episodeTitle: "An Litir · The crossing & record", beatInEpisode: 3, location: "A name across languages", title: "Ainm. Mise. Tar.", question: "Now make the first full line about yourself.", body: "The record writes hers as “Grany ne Maly.” In Irish, she is Gráinne Ní Mháille. Use Is mise… and as … mé without borrowing her identity.", detail: nil, hero: .none, source: nil, action: .identity, nextTitle: "Receive the answer"),

        .init(episode: 5, episodeTitle: "An Freagra · The answer", beatInEpisode: 1, location: "The court · September 1593", title: "An answer takes physical form", question: "What does the Queen give?", body: "Instructions go toward Bingham: release and relief are ordered in response to the case Gráinne has put before the state.", detail: "Paper can redirect power. It cannot guarantee that power will obey.", hero: .document, source: .init(title: "Royal instructions to Bingham", detail: "A draft order supports the answer; its implementation remains a separate question."), action: .none, nextTitle: "Follow the order home"),
        .init(episode: 5, episodeTitle: "An Freagra · The answer", beatInEpisode: 2, location: "London → Connacht", title: "Relief on paper. Compliance unfinished.", question: "What does Bingham withhold?", body: "The instruction travels, but full effect does not arrive with it. The dramatic answer is partial: the state has spoken, and the coast is still under pressure.", detail: nil, hero: .none, source: nil, action: .answer, nextTitle: "Name the unfinished action"),
        .init(episode: 5, episodeTitle: "An Freagra · The answer", beatInEpisode: 3, location: "The unfinished verb", title: "Freagair. Tabhair. Arís.", question: "Answer, give, again.", body: "These are not abstract exercise verbs. They distinguish the response from the relief still withheld—and prepare the second asking.", detail: nil, hero: .none, source: nil, action: .words([.freagair, .tabhair, .aris], "Listen for what the court did, what was withheld and what must happen again."), nextTitle: "Return to the coast"),

        .init(episode: 6, episodeTitle: "Ar Ais · Return and coast", beatInEpisode: 1, location: "Mayo · the return line", title: "She must ask again", question: "What remains on the shore?", body: "Later pressure brings further petitions. The coast has not become a solved ending; it remains the place from which the claim must be renewed.", detail: "The chart’s return line is still open.", hero: .generated("grainne-return", "Generated editorial interpretation of the Mayo coast and the return route"), source: .init(title: "The later petition trail", detail: "The 1595 pressure beat is kept short so it does not turn Mayo into a chronology tour."), action: .none, nextTitle: "Stand on the present shore"),
        .init(episode: 6, episodeTitle: "Ar Ais · Return and coast", beatInEpisode: 2, location: "Clew Bay · today", title: "The place carries more than one kind of memory", question: "What can the coast hold honestly?", body: "Rockfleet and Clew Bay hold material place. Later stories hold an image of refusal. The 1593 papers hold the documentary act: she crossed and made the state answer.", detail: "Those registers can sit together without becoming the same claim.", hero: .none, source: nil, action: .words([.costa], "Hear cósta for the present shore. Let the sound bring you back to the bay."), nextTitle: "Complete the voyage"),
        .init(episode: 6, episodeTitle: "Ar Ais · Return and coast", beatInEpisode: 3, location: "Clew Bay → London → Mayo", title: "The voyage completes. The story continues.", question: "What do you carry from Mayo?", body: "Twenty words now belong to one remembered route: coast, family, loss, asking, answer and return.", detail: "Mayo turns gold quietly. The next county is authored by the journey, not chosen from a reward picker.", hero: .none, source: nil, action: .finishChart, nextTitle: "Carry Mayo with you")
    ]
}

private struct GrainneSource {
    let title: String
    let detail: String
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
    static let asWord = Self(ga: "as", en: "from", sound: "ass")
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
    let palette: GrainneEpisodePalette
    let completed: Bool
    let onComplete: () -> Void

    @State private var currentIndex = 0
    @State private var heardWords: Set<String> = []
    @State private var wrongMeaning: String?

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
                .accessibilityHint("Plays the approved Irish Cultural Guide recording")
            }

            if hasHeardCurrentWord {
                Text("rough sound · \(currentWord.sound)")
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
        if currentIndex == words.count - 1 {
            onComplete()
        } else {
            withAnimation(Motion.settle) { currentIndex += 1 }
        }
    }
}

private struct PairedVoicesAction: View {
    let completed: Bool
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            voice("Bingham’s purpose", "To justify severity and present resistance as disorder.", "exclamationmark.bubble")
            Divider()
            voice("Gráinne’s purpose", "To secure maintenance, release and a path for her family.", "quote.bubble")
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

private struct FullArcNameFind: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var found: Bool
    let onOpenEvidence: () -> Void
    let onFound: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("ANNOTATED TRANSCRIPTION · MANUSCRIPT IMAGE NOT SHOWN")
                .font(.caption2.weight(.semibold)).kerning(1.1)
                .foregroundStyle(Color.white.opacity(0.72))
            ZStack {
                Color(light: 0xD8CBA7, dark: 0x8E7E59)
                VStack(spacing: 18) {
                    Text(found ? "Grany ne Maly" : "Gr—  ne  M—")
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.72))
                    if found {
                        Text("Gráinne Ní Mháille")
                            .font(.system(.title2, design: .serif, weight: .semibold))
                            .foregroundStyle(Theme.atlasGreen)
                            .transition(.opacity)
                    }
                }
            }
            .frame(minHeight: 230)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityLabel(found ? "The transcription writes Gráinne's name as Grany ne Maly" : "An obscured name in the annotated transcription")
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
            Text("Now keep the pattern and change the person.")
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
            Text("Keep as and mé; change only the place.")
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
            Button {
                focusedField = nil
                onComplete(
                    name.trimmingCharacters(in: .whitespacesAndNewlines),
                    place.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            } label: {
                Label(completed ? "Identity carried" : "Carry these lines", systemImage: completed ? "checkmark" : "person.text.rectangle")
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
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            OutcomeLine(icon: "doc.text", title: "The answer", text: "The Queen’s government orders relief.", color: Theme.weatheredGold)
            OutcomeLine(icon: "pause.circle", title: "What remains open", text: "Bingham does not give the order full effect.", color: Theme.rust)
            Button(action: onComplete) {
                Label(completed ? "Distinction carried" : "Mark the unfinished effect", systemImage: completed ? "checkmark" : "line.diagonal.arrow")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .tint(Theme.rust)
            .disabled(completed)
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
            Text("The chart keeps the documented journey and your own language act together without making them the same story.")
                .font(.body).foregroundStyle(Theme.inkSoft).lineSpacing(4)
            Button(action: onComplete) {
                Label(completed ? "Return line complete" : "Complete the return line", systemImage: completed ? "checkmark" : "pencil.and.scribble")
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
                Text("Your voyage chart").font(.headline)
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
