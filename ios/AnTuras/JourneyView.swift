import SwiftUI

// MARK: - An Turas: the journey across the island.
// The big-picture view the chapter map can't give: thirteen chapters laid
// over Ireland itself, moving through place *and* time — Mayo in the 5th
// century to Belfast today. The design language extends "chalk before
// carve" to the whole course: the road behind you is carved in moss, the
// road ahead is only chalk dots until you walk it.

struct JourneyView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onOpenChapter: () -> Void
    let onOpenMuseum: () -> Void
    let onOpenArAis: () -> Void
    let onOpenVocabDeck: () -> Void
    let onOpenPatrun: () -> Void

    @State private var selected: JourneyChapter?
    @State private var selectedCounty: County?
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                    .padding(.top, 12)
                    .padding(.horizontal, 22)

                JourneyMap(
                    counties: ContentLoader.counties(),
                    trail: ContentLoader.countyTrail(),
                    journey: state.journey,
                    currentN: state.currentChapterN
                ) { county in
                    Haptics.tap()
                    selectedCounty = county
                }
                .padding(.horizontal, 10)
                .opacity(appeared ? 1 : 0)

                VStack(spacing: 10) {
                    arAisRow
                    vocabRow
                    patrunRow
                    museumRow
                }
                .padding(.horizontal, 22)
                .cascade(1, appeared: appeared, reduceMotion: reduceMotion)
            }
            .padding(.bottom, 48)
            .frame(maxWidth: 640)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            #if DEBUG
            // `--card N` opens chapter N's preview card for screenshots.
            let args = ProcessInfo.processInfo.arguments
            if let flagIndex = args.firstIndex(of: "--card"),
               args.indices.contains(flagIndex + 1),
               let n = Int(args[flagIndex + 1]),
               let chapter = state.journey.first(where: { $0.n == n }) {
                selected = chapter
            }
            #endif
            guard !appeared else { return }
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            }
        }
        .sheet(item: $selected) { chapter in
            ChapterCard(chapter: chapter,
                        status: status(of: chapter)) {
                selected = nil
                onOpenChapter()
            }
        }
        .sheet(item: $selectedCounty) { county in
            CountyCard(county: county,
                       chapter: state.journey.first(where: { $0.countyEn == county.en }),
                       story: ContentLoader.stories().first(where: { $0.countyEn == county.en }),
                       status: countyStatus(county)) {
                selectedCounty = nil
                if let chapter = state.journey.first(where: { $0.countyEn == county.en }),
                   chapter.n == state.currentChapterN,
                   chapter.n <= ContentLoader.maxChapter {
                    onOpenChapter()
                }
            }
        }
    }

    private func status(of chapter: JourneyChapter) -> ChapterStatus {
        if chapter.n < state.currentChapterN { return .done }
        if chapter.n == state.currentChapterN { return .current }
        return .ahead
    }

    private var dueCount: Int { state.dueVisits().count }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Éire · 32 contae · c. 400 — inniu")
            Text("An turas — one county at a time")
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            Text("Every county opens with a real person, myth or monument. Read a story rooted there, then take 20 useful words onward.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(4)
            CountyLegend()
        }
    }

    private func countyStatus(_ county: County) -> CountyStatus {
        let chapters = state.journey.filter { $0.countyEn == county.en }
        let shipped = chapters.filter { $0.n <= ContentLoader.maxChapter }
        if state.currentChapterN <= ContentLoader.maxChapter,
           shipped.contains(where: { $0.n == state.currentChapterN }) { return .active }
        if !shipped.isEmpty && shipped.allSatisfy({ $0.n < state.currentChapterN }) { return .complete }
        return .waiting
    }

    // MARK: Rows beneath the map

    @ViewBuilder
    private var arAisRow: some View {
        // The row only exists once someone is (or will be) on the road —
        // before the first session is done there is nobody to come back to.
        if dueCount > 0 {
            JourneyRow(
                title: "Ar Ais — tá \(Turas.people(dueCount)) ag fiafraí fút",
                sub: visitorNames + " — answer them and the grooves stay sharp.",
                accent: Theme.rust,
                showDot: true,
                glyph: { ArtifactGlyphView(glyph: "fainne", color: Theme.rust) },
                action: { Haptics.tap(); onOpenArAis() })
        } else if let next = state.nextReturn() {
            JourneyRow(
                title: "Ar Ais — níl éinne fós",
                sub: "Fillfidh \(next.visit.who) \(Turas.until(next.due)) — \(next.visit.who) will come asking.",
                accent: Theme.stone,
                showDot: false,
                glyph: { ArtifactGlyphView(glyph: "fainne", color: Theme.inkFaint) },
                action: { Haptics.tap(); onOpenArAis() })
        }
    }

    private var visitorNames: String {
        let names = state.dueVisits().map(\.who)
        var seen: Set<String> = []
        let unique = names.filter { seen.insert($0).inserted }
        return unique.joined(separator: ", ")
    }

    private var dueLexemeCount: Int { state.dueLexemes().count }

    /// The vocabulary-at-volume invitation — phrases the story has earned and
    /// that are ready to revisit. Optional-but-invited, never a gate (DRILL.md).
    @ViewBuilder
    private var vocabRow: some View {
        if dueLexemeCount > 0 {
            JourneyRow(
                title: "Na Focail — \(dueLexemeCount) frása réidh le hathbhreithniú",
                sub: "Phrases from the path, ready to produce again — coverage, not points.",
                accent: Theme.lichen,
                showDot: true,
                glyph: { ArtifactGlyphView(glyph: "hornbook", color: Theme.lichen) },
                action: { Haptics.tap(); onOpenVocabDeck() })
        } else if let next = state.nextLexemeReturn() {
            JourneyRow(
                title: "Na Focail — níl frása ar bith fós",
                sub: "Fillfidh \(next.lexeme.ga) \(Turas.until(next.due)) — \(next.lexeme.en) will be ready to revisit.",
                accent: Theme.stone,
                showDot: false,
                glyph: { ArtifactGlyphView(glyph: "hornbook", color: Theme.inkFaint) },
                action: { Haptics.tap(); onOpenVocabDeck() })
        }
    }

    /// Patterns whose earning session is behind the learner and that generate
    /// variations to run.
    private var patternCount: Int {
        let lexicon = ContentLoader.lexicon(throughChapter: state.activeChapterN)
        return ContentLoader.patterns(throughChapter: state.activeChapterN)
            .filter { state.hasEarned($0.earnedAt) && PatternDrill.items(for: $0, in: lexicon).count >= 2 }
            .count
    }

    /// The grammar-at-volume invitation — only once a scene has earned a
    /// pattern worth running. A groove to make sure, never a gate (DRILL.md).
    @ViewBuilder
    private var patrunRow: some View {
        if patternCount > 0 {
            JourneyRow(
                title: "Na Patrúin",
                sub: "\(patternCount) réidh le rith — run a rule with every word you've earned.",
                accent: Theme.moss,
                showDot: false,
                glyph: { ArtifactGlyphView(glyph: "hornbook", color: Theme.moss) },
                action: { Haptics.tap(); onOpenPatrun() })
        }
    }

    private var museumRow: some View {
        JourneyRow(
            title: "An Músaem",
            sub: "\(state.completedChapterCount) de 13 bailithe — one artifact per chapter, each with your name on it somewhere.",
            accent: Theme.lichen,
            showDot: false,
            glyph: { ArtifactGlyphView(glyph: "stone", color: Theme.lichen) },
            action: { Haptics.tap(); onOpenMuseum() })
    }
}

// MARK: - One row: museum / ar ais entries under the map

private struct JourneyRow<Glyph: View>: View {
    let title: String
    let sub: String
    let accent: Color
    let showDot: Bool
    @ViewBuilder let glyph: Glyph
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 14) {
                glyph
                    .frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16.5, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading)
                        .accessibilityLabel(showDot ? "\(title). Visits waiting." : title)
                    Text(sub)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 15)
            .background(Theme.raised)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(accent.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(CarvePress())
    }
}

// MARK: - The map itself

private struct JourneyMap: View {
    let counties: [County]
    let trail: [String]
    let journey: [JourneyChapter]
    let currentN: Int
    let onTap: (County) -> Void

    /// Margin inside the map frame so sea-side labels have room to breathe
    /// without falling off the page.
    private let inset = CGSize(width: 44, height: 10)

    /// How far a tap can land from a waypoint and still count as hitting it.
    private let maxTapDistance: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
                .insetBy(dx: inset.width, dy: inset.height)
            ZStack {
                Canvas { ctx, size in
                    let full = CGRect(origin: .zero, size: size)
                        .insetBy(dx: inset.width, dy: inset.height)
                    let island = IrelandOutline().path(in: full)

                    // The island as a raised slab: a soft under-shadow,
                    // then the limestone surface, then the carved coast.
                    ctx.translateBy(x: 1.5, y: 2.5)
                    ctx.fill(island, with: .color(Theme.ink.opacity(0.08)))
                    ctx.translateBy(x: -1.5, y: -2.5)
                    ctx.fill(island, with: .color(Theme.raised))
                    ctx.drawLayer { layer in
                        layer.clip(to: island)

                        // Counties are the map now: no waypoint dots, only the
                        // lined territories a learner is travelling through.
                        for county in counties {
                            guard let path = CountyBoundaryAtlas.path(for: county, in: full) else { continue }
                            let state = status(county)
                            layer.fill(path, with: .color(fill(for: state)))
                            layer.stroke(path, with: .color(border(for: state)),
                                         style: StrokeStyle(lineWidth: state == .active ? 1.7 : 0.72,
                                                            lineJoin: .round))
                        }

                        // One road, 32 counties, no repeats. It is drawn over
                        // the boundary map so movement reads as travel through
                        // places rather than a second set of chapter markers.
                        let route = trail.compactMap { name in counties.first(where: { $0.en == name }) }
                        let active = activeTrailIndex(in: route)
                        for index in 0..<max(route.count - 1, 0) {
                            let from = point(for: route[index], in: full)
                            let to = point(for: route[index + 1], in: full)
                            var leg = Path()
                            leg.move(to: from)
                            leg.addQuadCurve(to: to,
                                             control: control(from, to, flip: index.isMultiple(of: 2)))
                            if index < active {
                                layer.stroke(leg, with: .color(Theme.atlasGold),
                                             style: StrokeStyle(lineWidth: 2.3, lineCap: .round))
                            } else if index == active {
                                layer.stroke(leg, with: .color(Theme.atlasGreen),
                                             style: StrokeStyle(lineWidth: 2.3, lineCap: .round, dash: [0.1, 5]))
                            } else {
                                layer.stroke(leg, with: .color(Theme.stone.opacity(0.58)),
                                             style: StrokeStyle(lineWidth: 1.15, lineCap: .round, dash: [0.1, 5]))
                            }
                        }
                    }
                    ctx.stroke(island, with: .color(Theme.stone),
                               style: StrokeStyle(lineWidth: 1.2, lineJoin: .round))
                }

                // The Atlantic, named in the empty north-west sea. Two lines,
                // because the sea pocket between Donegal and the frame edge
                // is too narrow for the name set on one.
                Text("AN tAIGÉAN\nATLANTACH")
                    .font(.system(size: 7.5, weight: .semibold))
                    .kerning(1.8)
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.inkFaint.opacity(0.65))
                    .position(sea(x: 0.115, y: 0.165, in: rect))

            }
            // Tap the territory itself; a nearest-centre fallback makes the
            // small eastern counties practical to select on a phone.
            .contentShape(Rectangle())
            .gesture(tapGesture(in: rect))
        }
        .aspectRatio(0.93, contentMode: .fit)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Map of Ireland divided into \(counties.count) counties. Gold is completed, green is active, white is waiting. The road connects the counties in journey order.")
    }

    private func tapGesture(in rect: CGRect) -> some Gesture {
        SpatialTapGesture().onEnded { value in
            if let selected = counties.first(where: {
                CountyBoundaryAtlas.path(for: $0, in: rect)?.contains(value.location) == true
            }) {
                onTap(selected)
                return
            }
            let nearest = counties.min { a, b in
                distance(point(for: a, in: rect), value.location)
                    < distance(point(for: b, in: rect), value.location)
            }
            if let nearest, distance(point(for: nearest, in: rect), value.location) <= maxTapDistance {
                onTap(nearest)
            }
        }
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    private func status(_ county: County) -> CountyStatus {
        let chapters = journey.filter { $0.countyEn == county.en }
        let shipped = chapters.filter { $0.n <= ContentLoader.maxChapter }
        if currentN <= ContentLoader.maxChapter,
           shipped.contains(where: { $0.n == currentN }) { return .active }
        if !shipped.isEmpty && shipped.allSatisfy({ $0.n < currentN }) { return .complete }
        return .waiting
    }

    private func activeTrailIndex(in route: [County]) -> Int {
        guard let activeCounty = journey.first(where: { $0.n == currentN })?.countyEn,
              let index = route.firstIndex(where: { $0.en == activeCounty })
        else { return -1 }
        return index
    }

    private func point(for county: County, in rect: CGRect) -> CGPoint {
        let box = Ireland.fit(in: rect)
        let n = Ireland.point(lat: county.lat, lon: county.lon)
        return CGPoint(x: box.minX + n.x * box.height, y: box.minY + n.y * box.height)
    }

    private func sea(x: CGFloat, y: CGFloat, in rect: CGRect) -> CGPoint {
        let box = Ireland.fit(in: rect)
        return CGPoint(x: box.minX + x * box.height, y: box.minY + y * box.height)
    }

    private func fill(for status: CountyStatus) -> Color {
        switch status {
        case .complete: return Theme.atlasGold.opacity(0.30)
        case .active: return Theme.atlasGreen.opacity(0.34)
        case .waiting: return Theme.atlasWhite.opacity(0.97)
        }
    }

    private func border(for status: CountyStatus) -> Color {
        switch status {
        case .complete: return Theme.atlasGold.opacity(0.9)
        case .active: return Theme.atlasGreen
        case .waiting: return Theme.line.opacity(0.9)
        }
    }

    /// Bow each leg of the road a little, alternating sides, so the route
    /// wanders like a road and not like a survey line.
    private func control(_ a: CGPoint, _ b: CGPoint, flip: Bool) -> CGPoint {
        let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        let dx = b.x - a.x, dy = b.y - a.y
        let len = max(sqrt(dx * dx + dy * dy), 1)
        let bow: CGFloat = 0.14 * (flip ? 1 : -1)
        return CGPoint(x: mid.x - dy / len * len * bow,
                       y: mid.y + dx / len * len * bow)
    }
}

enum ChapterStatus { case done, current, ahead }
enum CountyStatus { case complete, active, waiting }

private struct CountyLegend: View {
    var body: some View {
        HStack(spacing: 14) {
            key(Theme.atlasGold, "bailithe · completed")
            key(Theme.atlasGreen, "anois · active")
            key(Theme.atlasWhite, "ag fanacht · waiting", stroke: Theme.stone)
        }
        .font(.system(size: 10.5, weight: .semibold))
        .foregroundStyle(Theme.inkSoft)
        .padding(.top, 4)
    }

    private func key(_ color: Color, _ label: String, stroke: Color = .clear) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 12, height: 8)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(stroke, lineWidth: 1))
            Text(label)
        }
    }
}

private struct CountyCard: View {
    let county: County
    let chapter: JourneyChapter?
    let story: CountyStory?
    let status: CountyStatus
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: "\(county.province) · \(county.ga)", color: color)
            Text(county.en)
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            if let story {
                Text(story.titleGa)
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(color)
                Text("\(story.anchorName) · \(story.anchorKind)")
                    .font(.system(size: 14.5, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text(story.readingPromise)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(4)
                Text("READ THE INSCRIPTION · LEARN \(story.vocabularyTarget) WORDS")
                    .font(.system(size: 11, weight: .semibold))
                    .kerning(1.1)
                    .foregroundStyle(Theme.inkFaint)
                if story.legacyChapter != nil, status == .active {
                    PrimaryButton(title: "Oscail an scéal — open story",
                                  fullWidth: true, action: onOpen)
                } else if status == .complete {
                    Text("Snoite · you have already carried this county’s story onward.")
                        .font(.system(size: 13.5, design: .serif))
                        .italic()
                        .foregroundStyle(Theme.atlasGold)
                } else {
                    waitingCopy
                }
            } else if let chapter {
                Text("\(chapter.anchorName) · \(chapter.anchorKind)")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(color)
                Text(chapter.readingPromise)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(4)
                Text("LEARN \(chapter.vocabularyTarget) WORDS · \(chapter.era)")
                    .font(.system(size: 11, weight: .semibold))
                    .kerning(1.1)
                    .foregroundStyle(Theme.inkFaint)
                if chapter.n <= ContentLoader.maxChapter, status == .active {
                    PrimaryButton(title: "Oscail an scéal — open story",
                                  fullWidth: true, action: onOpen)
                } else if status == .complete {
                    Text("Snoite · you have already carried this county’s story onward.")
                        .font(.system(size: 13.5, design: .serif))
                        .italic()
                        .foregroundStyle(Theme.atlasGold)
                } else {
                    waitingCopy
                }
            } else {
                waitingCopy
            }
        }
        .padding(22)
        .presentationDetents([.height(330)])
        .presentationBackground(Theme.bg)
        .presentationCornerRadius(20)
        .presentationDragIndicator(.visible)
    }

    private var color: Color {
        switch status {
        case .complete: return Theme.atlasGold
        case .active: return Theme.atlasGreen
        case .waiting: return Theme.inkFaint
        }
    }

    private var waitingCopy: some View {
        Text("The story for this county is still being researched with Irish-language and historical reviewers. Its territory stays visible so the whole journey is clear.")
            .font(.system(size: 14))
            .foregroundStyle(Theme.inkSoft)
            .lineSpacing(3)
    }
}

// MARK: - The time axis: the spine the map's zigzag route can't show

/// The map is chaotic in space (Mayo → Offaly → Dublin → Meath → Kerry →
/// Donegal → Kerry → Galway…) but perfectly linear in time. This strip
/// gives fifteen centuries a line of their own: the same three depths as
/// the road above (moss walked, chalk ahead), evenly spaced by chapter
/// rather than by calendar year — a true year-proportional axis would
/// crowd chapters 8–13 into the last tenth of the strip, which trades one
/// crowding problem for another. Endpoints and the current era are
/// captioned; other eras are a tap away via the same chapter card.
private struct TimeAxis: View {
    let journey: [JourneyChapter]
    let currentN: Int
    let onTap: (JourneyChapter) -> Void

    private let inset: CGFloat = 11
    private let trackHeight: CGFloat = 22

    var body: some View {
        VStack(spacing: 5) {
            GeometryReader { geo in
                let count = journey.count
                let span = max(geo.size.width - inset * 2, 1)
                let y = trackHeight / 2
                ZStack(alignment: .topLeading) {
                    Canvas { ctx, _ in
                        var walked = Path()
                        var next = Path()
                        var thread = Path()
                        for i in 0..<(count - 1) {
                            var seg = Path()
                            seg.move(to: CGPoint(x: x(i, span), y: y))
                            seg.addLine(to: CGPoint(x: x(i + 1, span), y: y))
                            if journey[i].n < currentN {
                                walked.addPath(seg)
                            } else if journey[i].n == currentN {
                                next.addPath(seg)
                            } else {
                                thread.addPath(seg)
                            }
                        }
                        ctx.stroke(thread, with: .color(Theme.stone.opacity(0.55)),
                                   style: StrokeStyle(lineWidth: 1.4, lineCap: .round, dash: [0.1, 5]))
                        ctx.stroke(next, with: .color(Theme.stone),
                                   style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0.1, 6]))
                        ctx.stroke(walked, with: .color(Theme.moss),
                                   style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    }
                    ForEach(Array(journey.enumerated()), id: \.element.id) { i, chapter in
                        dot(for: chapter)
                            .frame(width: 26, height: 26)
                            .contentShape(Circle())
                            .position(x: x(i, span), y: y)
                            .onTapGesture { onTap(chapter) }
                    }
                }
            }
            .frame(height: trackHeight)
            .accessibilityHidden(true)

            HStack {
                Text("c. 400").foregroundStyle(Theme.inkFaint)
                Spacer(minLength: 8)
                Text(currentEraLabel).foregroundStyle(Theme.moss).lineLimit(1)
                Spacer(minLength: 8)
                Text("inniu").foregroundStyle(Theme.inkFaint)
            }
            .font(.system(size: 9.5, weight: .semibold))
            .kerning(0.4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Timeline, c. 400 to today, \(journey.count) chapters. \(currentEraLabel).")
    }

    private func x(_ i: Int, _ span: CGFloat) -> CGFloat {
        inset + span * CGFloat(i) / CGFloat(journey.count - 1)
    }

    private var currentEraLabel: String {
        guard let chapter = journey.first(where: { $0.n == currentN }) else { return "" }
        return "tá tú anseo · \(chapter.era)"
    }

    @ViewBuilder
    private func dot(for chapter: JourneyChapter) -> some View {
        if chapter.n < currentN {
            Circle().fill(Theme.moss).frame(width: 7, height: 7)
        } else if chapter.n == currentN {
            ZStack {
                Circle().fill(Theme.ink).frame(width: 10, height: 10)
                Circle().stroke(Theme.moss, lineWidth: 1.4).frame(width: 10, height: 10)
            }
        } else {
            Circle()
                .stroke(Theme.stone, style: StrokeStyle(lineWidth: 1.3, dash: [1.4, 2]))
                .background(Circle().fill(Theme.bg))
                .frame(width: 7, height: 7)
        }
    }
}

// MARK: - The chapter card: what a waypoint promises

struct ChapterCard: View {
    let chapter: JourneyChapter
    let status: ChapterStatus
    /// Present only when this chapter can actually be opened (chapter 1).
    var onOpen: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Eyebrow(text: "Caibidil \(chapter.n) · \(chapter.era)")
                    Spacer()
                    statusChip
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(chapter.ga)
                        .font(.system(size: 25, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text(chapter.en)
                        .font(.system(size: 15, design: .serif))
                        .foregroundStyle(Theme.inkSoft)
                }
                Text("\(chapter.placeGa) · \(chapter.placeEn)")
                    .font(.system(size: 13))
                    .italic()
                    .foregroundStyle(Theme.inkSoft)

                Text(chapter.hook)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(4)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "An scéal fíor · the real story", color: Theme.atlasGreen)
                    Text("\(chapter.anchorName) · \(chapter.anchorKind)")
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text(chapter.readingPromise)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(3)
                    Text("\(chapter.vocabularyTarget) focal · \(chapter.vocabularyTarget) words to take with you")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.atlasGreen)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.mossTint)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 5) {
                    Eyebrow(text: "Sa chaibidil seo", color: Theme.inkFaint)
                    Text(chapter.payload)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(3)
                }
                .padding(.top, 4)

                HStack(spacing: 12) {
                    ArtifactGlyphView(glyph: chapter.glyph,
                                      color: status == .ahead ? Theme.inkFaint : Theme.lichen)
                        .frame(width: 30, height: 30)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Déantán · \(chapter.artifactGa)")
                            .font(.system(size: 14, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.ink)
                        Text(chapter.artifactEn)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.sunk.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.top, 4)

                footer
                    .padding(.top, 6)
            }
            .padding(22)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Theme.bg)
        .presentationCornerRadius(20)
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var statusChip: some View {
        switch status {
        case .done:
            Text("SNOITE ✓").chipStyle(Theme.moss)
        case .current:
            Text("TÁ TÚ ANSEO").chipStyle(Theme.moss)
        case .ahead:
            Text("CAILC FÓS").chipStyle(Theme.stone)
        }
    }

    @ViewBuilder
    private var footer: some View {
        if chapter.n == 1, let onOpen {
            PrimaryButton(title: status == .done
                          ? "Athchuairt — revisit the path"
                          : "Oscail an chonair — open the path",
                          fullWidth: true, action: onOpen)
        } else if status == .current {
            Text("Á scríobh fós — this chapter is being written. The road ends here for now, and picks up where you left it.")
                .font(.system(size: 12.5))
                .italic()
                .foregroundStyle(Theme.inkFaint)
                .lineSpacing(3)
        } else {
            Text("Níl an bóthar chomh fada seo fós — the road hasn't reached here yet. Every chapter carves the way to the next.")
                .font(.system(size: 12.5))
                .italic()
                .foregroundStyle(Theme.inkFaint)
                .lineSpacing(3)
        }
    }
}

private extension Text {
    func chipStyle(_ color: Color) -> some View {
        font(.system(size: 10, weight: .bold))
            .kerning(1.2)
            .foregroundStyle(color)
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .overlay(Capsule().stroke(color.opacity(0.5), lineWidth: 1))
    }
}

private extension View {
    @ViewBuilder
    func cascade(_ order: Int, appeared: Bool, reduceMotion: Bool) -> some View {
        if reduceMotion {
            opacity(appeared ? 1 : 0)
        } else {
            self
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)
                .animation(Motion.rise.delay(0.15 + Double(order) * 0.08), value: appeared)
        }
    }
}
