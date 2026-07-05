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

    @State private var selected: JourneyChapter?
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                    .padding(.top, 12)
                    .padding(.horizontal, 22)

                JourneyMap(
                    journey: state.journey,
                    currentN: state.currentChapterN,
                    sessionsDone: state.done.filter { $0 }.count,
                    sessionCount: state.done.count,
                    reduceMotion: reduceMotion
                ) { chapter in
                    Haptics.tap()
                    selected = chapter
                }
                .padding(.horizontal, 10)
                .opacity(appeared ? 1 : 0)

                VStack(spacing: 10) {
                    arAisRow
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
    }

    private func status(of chapter: JourneyChapter) -> ChapterStatus {
        if chapter.n < state.currentChapterN { return .done }
        if chapter.n == state.currentChapterN { return .current }
        return .ahead
    }

    private var dueCount: Int { state.dueVisits().count }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Éire · c. 400 — inniu")
            Text("An turas — the journey")
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            Text("Thirteen chapters, fifteen centuries, one language. The road behind you is carved in moss; the road ahead is chalk until you walk it.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(4)
        }
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

    private var museumRow: some View {
        JourneyRow(
            title: "An Músaem",
            sub: "\(state.allDone ? 1 : 0) de 13 bailithe — one artifact per chapter, each with your name on it somewhere.",
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
    let journey: [JourneyChapter]
    let currentN: Int
    let sessionsDone: Int
    let sessionCount: Int
    let reduceMotion: Bool
    let onTap: (JourneyChapter) -> Void

    /// Margin inside the map frame so sea-side labels have room to breathe
    /// without falling off the page.
    private let inset = CGSize(width: 44, height: 10)

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
                    ctx.stroke(island, with: .color(Theme.stone),
                               style: StrokeStyle(lineWidth: 1.2, lineJoin: .round))

                    // The road, told at three depths so thirteen zig-zagging
                    // centuries don't turn into a scribble: moss where you've
                    // been, clear chalk for the one leg in front of you, and
                    // the faintest thread beyond that — the future is mostly
                    // waypoints, because the road doesn't exist until it's
                    // walked.
                    let pts = journey.map { point(for: $0, in: full) }
                    var walked = Path()
                    var next = Path()
                    var thread = Path()
                    for i in 0..<(pts.count - 1) {
                        var seg = Path()
                        seg.move(to: pts[i])
                        seg.addQuadCurve(to: pts[i + 1],
                                         control: control(pts[i], pts[i + 1], flip: i.isMultiple(of: 2)))
                        // Segment i joins chapter i+1 to i+2 (1-based): it is
                        // walked once chapter i+1 is finished.
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
                               style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: [0.1, 6]))
                    ctx.stroke(walked, with: .color(Theme.moss),
                               style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
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

                ForEach(journey) { chapter in
                    let p = point(for: chapter, in: rect)
                    WaypointMark(chapter: chapter,
                                 status: status(chapter),
                                 sessionsDone: sessionsDone,
                                 sessionCount: sessionCount,
                                 reduceMotion: reduceMotion)
                        .position(p)
                        .onTapGesture { onTap(chapter) }
                }
            }
        }
        .aspectRatio(0.93, contentMode: .fit)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Map of Ireland showing the journey through \(journey.count) chapters.")
    }

    private func status(_ chapter: JourneyChapter) -> ChapterStatus {
        if chapter.n < currentN { return .done }
        if chapter.n == currentN { return .current }
        return .ahead
    }

    private func point(for chapter: JourneyChapter, in rect: CGRect) -> CGPoint {
        let box = Ireland.fit(in: rect)
        let n = Ireland.point(lat: chapter.lat, lon: chapter.lon)
        return CGPoint(x: box.minX + n.x * box.height, y: box.minY + n.y * box.height)
    }

    private func sea(x: CGFloat, y: CGFloat, in rect: CGRect) -> CGPoint {
        let box = Ireland.fit(in: rect)
        return CGPoint(x: box.minX + x * box.height, y: box.minY + y * box.height)
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

// MARK: - One waypoint: marker + label

private struct WaypointMark: View {
    let chapter: JourneyChapter
    let status: ChapterStatus
    let sessionsDone: Int
    let sessionCount: Int
    let reduceMotion: Bool

    @State private var pulsing = false

    var body: some View {
        ZStack {
            marker
            label
        }
        .contentShape(Circle().scale(3.2))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var marker: some View {
        switch status {
        case .done:
            Circle().fill(Theme.moss).frame(width: 8, height: 8)
        case .current:
            ZStack {
                if !reduceMotion {
                    Circle()
                        .stroke(Theme.moss, lineWidth: 1.4)
                        .frame(width: 11, height: 11)
                        .scaleEffect(pulsing ? 2.8 : 1)
                        .opacity(pulsing ? 0 : 0.8)
                        .onAppear {
                            withAnimation(.easeOut(duration: 2.2).repeatForever(autoreverses: false)) {
                                pulsing = true
                            }
                        }
                } else {
                    Circle().stroke(Theme.moss, lineWidth: 1.4)
                        .frame(width: 17, height: 17)
                }
                Circle().fill(Theme.ink).frame(width: 11, height: 11)
            }
        case .ahead:
            // Chalk: a guide-mark waiting for the chisel.
            Circle()
                .stroke(Theme.stone, style: StrokeStyle(lineWidth: 1.4, dash: [1.6, 2.2]))
                .background(Circle().fill(Theme.bg))
                .frame(width: 8, height: 8)
        }
    }

    private var label: some View {
        VStack(alignment: alignment.horizontal, spacing: 1) {
            (Text("\(chapter.n) · ").foregroundStyle(Theme.inkFaint)
             + Text(chapter.placeGa).foregroundStyle(labelColor))
                .font(.system(size: 10, weight: status == .current ? .bold : .semibold))
            if status == .current {
                Text(progressLine)
                    .font(.system(size: 8.5, weight: .semibold))
                    .italic()
                    .foregroundStyle(Theme.moss)
            }
        }
        .fixedSize()
        .frame(width: 170, alignment: Alignment(horizontal: alignment.horizontal, vertical: .center))
        .offset(labelOffset)
        .allowsHitTesting(false)
    }

    /// Sea-side labels hug the marker instead of centring 85pt away.
    private var alignment: (horizontal: HorizontalAlignment, offset: CGFloat) {
        switch chapter.side {
        case "left":  return (.trailing, -85 - 11)
        case "right": return (.leading, 85 + 11)
        default:      return (.center, 0)
        }
    }

    private var progressLine: String {
        if sessionsDone == 0 { return "tá tú anseo" }
        return "tá tú anseo · \(sessionsDone) de \(sessionCount) snoite"
    }

    /// Ahead labels stay readable (inkSoft, not inkFaint) — the chalk/moss
    /// distinction lives in the markers; the place names have to be legible
    /// at 10pt either way.
    private var labelColor: Color {
        switch status {
        case .done: return Theme.inkSoft
        case .current: return Theme.ink
        case .ahead: return Theme.inkSoft
        }
    }

    private var labelOffset: CGSize {
        let lift: CGFloat = status == .current ? 9 : 0
        switch chapter.side {
        case "above": return CGSize(width: 0, height: -14 - lift)
        case "below": return CGSize(width: 0, height: 14 + lift)
        default:      return CGSize(width: alignment.offset, height: 0)
        }
    }

    private var accessibilityText: String {
        let state: String
        switch status {
        case .done: state = "Carved."
        case .current: state = "You are here."
        case .ahead: state = "Still ahead."
        }
        return "Caibidil \(chapter.n), \(chapter.ga), \(chapter.placeGa), \(chapter.era). \(state)"
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
