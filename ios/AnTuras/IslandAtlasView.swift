import SwiftUI

// MARK: - First encounter

struct FirstRunIslandView: View {
    let onBegin: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AtlasScreenHeader(
                    "AN tOILEÁN · THE ISLAND",
                    "Every place has something to tell you.",
                    detail: "In 1593, a woman from the Mayo coast went directly to the English queen. Begin where she began."
                )

                IslandMapSurface(
                    mode: .journey,
                    time: 1593,
                    theme: "Power",
                    storyComplete: false,
                    showsFutureSignals: false,
                    onSelect: { county in
                        guard county == "Mayo" else { return }
                        Haptics.tap()
                        onBegin()
                    }
                )
                .frame(height: 500)
                .accessibilityHidden(true)

                Button {
                    Haptics.tap()
                    onBegin()
                } label: {
                    AtlasCard(accent: Theme.atlasGreen) {
                        HStack(spacing: 14) {
                            GrainnePortraitMark()
                                .frame(width: 76, height: 96)
                            VStack(alignment: .leading, spacing: 5) {
                                Eyebrow(text: "MAYO · 1593", color: Theme.atlasGreen)
                                Text("Begin at Rockfleet")
                                    .font(.system(size: 22, weight: .semibold, design: .serif))
                                    .foregroundStyle(Theme.ink)
                                Text("Why did Gráinne leave Mayo?")
                                    .font(.system(size: 14.5))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.right")
                                .foregroundStyle(Theme.atlasGreen)
                        }
                    }
                }
                .buttonStyle(CarvePress())
                .accessibilityLabel("Begin the story of Gráinne Ní Mháille in Mayo")
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 36)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
    }
}

enum IslandMode: String, CaseIterable, Identifiable {
    case journey = "Journey"
    case time = "Time"
    case theme = "Theme"
    var id: String { rawValue }
}

struct IslandAtlasView: View {
    @EnvironmentObject private var atlas: AtlasPrototypeModel
    let onOpenMayo: () -> Void
    let onOpenCounty: (String) -> Void
    let onOpenFieldNote: () -> Void

    @State private var mode: IslandMode = .journey
    @State private var time: Double = 1593
    @State private var theme = "Power"
    @State private var showCountyList = false

    private let themes = ["Power", "Sea routes", "Writing", "Women’s lives", "Language"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AtlasScreenHeader(
                    "AN tOILEÁN · THE ISLAND",
                    "Every place has something to tell you.",
                    detail: "Look around before you choose a road. Irish brings the names, evidence and people closer."
                )

                Picker("Map mode", selection: $mode) {
                    ForEach(IslandMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                modeControl

                IslandMapSurface(
                    mode: mode,
                    time: Int(time),
                    theme: theme,
                    storyComplete: atlas.storyCompleted,
                    showsFutureSignals: true,
                    onSelect: { county in
                        Haptics.tap()
                        if county == "Mayo" { onOpenMayo() } else { onOpenCounty(county) }
                    }
                )
                .frame(height: 430)
                .accessibilityHidden(true)

                Button {
                    showCountyList = true
                } label: {
                    Label("Open the accessible county list", systemImage: "list.bullet")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.raised)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(CarvePress())

                openingRoad

                fieldNoteInvitation
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 36)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showCountyList) {
            CountyListSheet(onSelect: { county in
                showCountyList = false
                if county.en == "Mayo" { onOpenMayo() } else { onOpenCounty(county.en) }
            })
        }
    }

    @ViewBuilder
    private var modeControl: some View {
        switch mode {
        case .journey:
            AtlasCard(accent: Theme.atlasGreen) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Mayo, 1593 — the invitation")
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.ink)
                        Text("Then rewind to Offaly, c. 900 — the long road begins.")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Image(systemName: "arrow.turn.down.left")
                        .foregroundStyle(Theme.atlasGreen)
                }
            }
        case .time:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Eyebrow(text: "WHAT ELSE WAS HAPPENING?")
                    Spacer()
                    Text(timeLabel)
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.moss)
                }
                Slider(value: $time, in: 850...2026, step: 1)
                    .tint(Theme.moss)
                HStack {
                    Text("c. 900")
                    Spacer()
                    Text("inniu · today")
                }
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(Theme.inkFaint)
            }
            .padding(15)
            .background(Theme.raised)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        case .theme:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(themes, id: \.self) { item in
                        Button(item) { withAnimation(Motion.settle) { theme = item } }
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(theme == item ? Theme.bg : Theme.inkSoft)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 9)
                            .background(theme == item ? Theme.ink : Theme.raised)
                            .clipShape(Capsule())
                            .buttonStyle(CarvePress())
                    }
                }
            }
        }
    }

    private var timeLabel: String {
        let year = Int(time)
        if year < 1000 { return "c. \(year)" }
        if year == 2026 { return "inniu" }
        return "\(year)"
    }

    private var openingRoad: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "THE OPENING ROAD")
            RoadStop(number: 1, county: "Maigh Eo · Mayo", title: "Gráinne’s petition", era: "1593", state: atlas.storyCompleted ? .complete : .active)
            RoadStop(number: 2, county: "Uíbh Fhailí · Offaly", title: "Cross of the Scriptures", era: "c. 900 · rewind", state: .ahead)
            RoadStop(number: 3, county: "Baile Átha Cliath · Dublin", title: "Sihtric’s penny", era: "c. 997", state: .ahead)
        }
    }

    private var fieldNoteInvitation: some View {
        Button {
            Haptics.tap()
            onOpenFieldNote()
        } label: {
            AtlasCard(accent: Theme.inkFaint) {
                HStack(spacing: 14) {
                    Image(systemName: "scope")
                        .font(.system(size: 25, weight: .light))
                        .foregroundStyle(Theme.inkFaint)
                        .frame(width: 40)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Field note · Breastagh")
                                .font(.system(size: 17, weight: .semibold, design: .serif))
                                .foregroundStyle(Theme.ink)
                            CertaintyPill(certainty: .reconstruction)
                        }
                        Text("A damaged name in a Mayo field. See exactly where evidence ends and imagination begins.")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.inkSoft)
                            .lineSpacing(3)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
        }
        .buttonStyle(CarvePress())
    }
}

private enum RoadState { case complete, active, ahead }

private struct RoadStop: View {
    let number: Int
    let county: String
    let title: String
    let era: String
    let state: RoadState

    var color: Color {
        switch state {
        case .complete: return Theme.atlasGold
        case .active: return Theme.atlasGreen
        case .ahead: return Theme.stone
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(state == .ahead ? 0.12 : 0.22))
                Circle().stroke(color, lineWidth: 1.4)
                Text("\(number)")
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .foregroundStyle(color)
            }
            .frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(county)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
            }
            Spacer()
            Text(era)
                .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(12)
        .background(Theme.raised)
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }
}

// MARK: - Island map

private struct IslandMapSurface: View {
    let mode: IslandMode
    let time: Int
    let theme: String
    let storyComplete: Bool
    let showsFutureSignals: Bool
    let onSelect: (String) -> Void

    private let counties = ContentLoader.counties()
    private let inset = CGSize(width: 28, height: 10)

    var body: some View {
        GeometryReader { geo in
            let full = CGRect(origin: .zero, size: geo.size).insetBy(dx: inset.width, dy: inset.height)
            ZStack {
                Canvas { ctx, size in
                    let rect = CGRect(origin: .zero, size: size).insetBy(dx: inset.width, dy: inset.height)
                    let island = IrelandOutline().path(in: rect)

                    ctx.translateBy(x: 2, y: 3)
                    ctx.fill(island, with: .color(Theme.ink.opacity(0.09)))
                    ctx.translateBy(x: -2, y: -3)
                    ctx.fill(island, with: .color(Theme.raised))

                    ctx.drawLayer { layer in
                        layer.clip(to: island)
                        for county in counties {
                            guard let path = CountyBoundaryAtlas.path(for: county, in: rect) else { continue }
                            let selected = highlighted(county.en)
                            let isMayo = county.en == "Mayo"
                            let fill = isMayo
                                ? (storyComplete ? Theme.atlasGold.opacity(0.32) : Theme.atlasGreen.opacity(0.34))
                                : (selected ? Theme.moss.opacity(0.20) : Theme.atlasWhite.opacity(0.95))
                            layer.fill(path, with: .color(fill))
                            layer.stroke(path, with: .color(isMayo ? Theme.atlasGreen : Theme.line),
                                         style: StrokeStyle(lineWidth: isMayo ? 1.7 : 0.65, lineJoin: .round))
                        }

                        if mode == .journey && showsFutureSignals {
                            let road = [
                                Ireland.point(lat: 53.90, lon: -9.25),
                                Ireland.point(lat: 53.33, lon: -7.99),
                                Ireland.point(lat: 53.34, lon: -6.27)
                            ].map { point($0, in: rect) }
                            var p = Path()
                            if let first = road.first { p.move(to: first) }
                            for next in road.dropFirst() { p.addLine(to: next) }
                            layer.stroke(p, with: .color(Theme.atlasGreen.opacity(0.85)),
                                         style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 6]))
                        }
                    }
                    ctx.stroke(island, with: .color(Theme.stone), lineWidth: 1.1)
                }

                ForEach(signals, id: \.title) { signal in
                    StorySignal(signal: signal)
                        .position(mapPoint(lat: signal.lat, lon: signal.lon, in: full))
                }

                Text(mode == .time ? timeCaption : mode == .theme ? theme.uppercased() : "MAYO, 1593")
                    .font(.system(size: 9, weight: .bold))
                    .kerning(1.4)
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Theme.bg.opacity(0.88))
                    .clipShape(Capsule())
                    .position(x: 74, y: 32)
            }
            .contentShape(Rectangle())
            .gesture(SpatialTapGesture().onEnded { value in select(at: value.location, rect: full) })
        }
    }

    private var signals: [MapSignal] {
        switch mode {
        case .journey:
            let grainne = MapSignal(title: "Gráinne", detail: "1593 · document", icon: "person.crop.circle", lat: 53.88, lon: -9.58, active: true)
            guard showsFutureSignals else { return [grainne] }
            return [
                grainne,
                MapSignal(title: "A cross", detail: "c. 900", icon: "plus", lat: 53.33, lon: -7.99, active: false),
                MapSignal(title: "A penny", detail: "c. 997", icon: "circle", lat: 53.34, lon: -6.27, active: false)
            ]
        case .time:
            if time < 1000 {
                return [
                    MapSignal(title: "Clonmacnoise", detail: "roads meet", icon: "plus", lat: 53.33, lon: -7.99, active: true),
                    MapSignal(title: "Dubhlinn", detail: "settlement", icon: "house", lat: 53.34, lon: -6.27, active: false)
                ]
            } else if time < 1650 {
                return [
                    MapSignal(title: "Gráinne", detail: "Mayo", icon: "person.crop.circle", lat: 53.88, lon: -9.58, active: true),
                    MapSignal(title: "Rathmullan", detail: "departure", icon: "sailboat", lat: 55.02, lon: -7.65, active: false)
                ]
            } else {
                return [
                    MapSignal(title: "Shaw’s Road", detail: "community", icon: "house.and.flag", lat: 54.58, lon: -5.98, active: true),
                    MapSignal(title: "Joe Heaney", detail: "song", icon: "waveform", lat: 53.38, lon: -9.61, active: false)
                ]
            }
        case .theme:
            if theme == "Sea routes" {
                return [
                    MapSignal(title: "Clew Bay", detail: "power at sea", icon: "sailboat", lat: 53.88, lon: -9.58, active: true),
                    MapSignal(title: "Rathmullan", detail: "leaving", icon: "sailboat", lat: 55.02, lon: -7.65, active: false),
                    MapSignal(title: "Dubhlinn", detail: "trade", icon: "shippingbox", lat: 53.34, lon: -6.27, active: false)
                ]
            }
            return [
                MapSignal(title: "Gráinne", detail: theme.lowercased(), icon: "person.crop.circle", lat: 53.88, lon: -9.58, active: true),
                MapSignal(title: "A connected story", detail: "future route", icon: "point.3.connected.trianglepath.dotted", lat: 53.27, lon: -9.06, active: false)
            ]
        }
    }

    private var timeCaption: String {
        if time < 1000 { return "c. \(time)" }
        if time >= 2026 { return "INNIU" }
        return "\(time)"
    }

    private func highlighted(_ county: String) -> Bool {
        guard mode == .theme else { return false }
        switch theme {
        case "Sea routes": return ["Mayo", "Donegal", "Dublin", "Cork"].contains(county)
        case "Writing": return ["Offaly", "Galway", "Dublin"].contains(county)
        case "Women’s lives": return ["Mayo", "Cork", "Offaly"].contains(county)
        case "Language": return ["Galway", "Kerry", "Donegal", "Antrim"].contains(county)
        default: return ["Mayo", "Meath", "Armagh", "Dublin"].contains(county)
        }
    }

    private func select(at location: CGPoint, rect: CGRect) {
        if let county = counties.first(where: { CountyBoundaryAtlas.path(for: $0, in: rect)?.contains(location) == true }) {
            onSelect(county.en)
            return
        }
        if let nearest = counties.min(by: {
            distance(mapPoint(lat: $0.lat, lon: $0.lon, in: rect), location)
                < distance(mapPoint(lat: $1.lat, lon: $1.lon, in: rect), location)
        }), distance(mapPoint(lat: nearest.lat, lon: nearest.lon, in: rect), location) < 28 {
            onSelect(nearest.en)
        }
    }

    private func point(_ p: CGPoint, in rect: CGRect) -> CGPoint {
        let box = Ireland.fit(in: rect)
        return CGPoint(x: box.minX + p.x * box.height, y: box.minY + p.y * box.height)
    }

    private func mapPoint(lat: Double, lon: Double, in rect: CGRect) -> CGPoint {
        point(Ireland.point(lat: lat, lon: lon), in: rect)
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
}

private struct MapSignal {
    let title: String
    let detail: String
    let icon: String
    let lat: Double
    let lon: Double
    let active: Bool
}

private struct StorySignal: View {
    let signal: MapSignal
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: signal.icon)
                .font(.system(size: 12, weight: .semibold))
            Text(signal.title)
                .font(.system(size: 9.5, weight: .bold))
            Text(signal.detail)
                .font(.system(size: 7.5))
                .opacity(0.78)
        }
        .foregroundStyle(signal.active ? Theme.bg : Theme.ink)
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(signal.active ? Theme.atlasGreen : Theme.raised.opacity(0.93))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.line, lineWidth: signal.active ? 0 : 0.7))
        .shadow(color: Theme.ink.opacity(0.08), radius: 4, y: 2)
    }
}

private struct CountyListSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (County) -> Void
    private let counties = ContentLoader.counties().sorted { $0.en < $1.en }

    var body: some View {
        NavigationStack {
            List(counties) { county in
                Button { onSelect(county) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(county.ga)
                                .font(.system(size: 16, weight: .semibold, design: .serif))
                                .foregroundStyle(Theme.ink)
                            Text("\(county.en) · \(county.province)")
                                .font(.system(size: 12.5))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Text(county.en == "Mayo" ? "ACTIVE STORY" : "OPEN TO INSPECT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(county.en == "Mayo" ? Theme.atlasGreen : Theme.inkFaint)
                    }
                }
                .listRowBackground(Theme.bg)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("32 counties")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationBackground(Theme.bg)
    }
}

// MARK: - Story tab and unresearched county state

struct CurrentStoryView: View {
    @EnvironmentObject private var atlas: AtlasPrototypeModel
    let onOpenStory: () -> Void
    let onOpenDossier: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AtlasScreenHeader("AN SCÉAL · THE STORY", atlas.storyCompleted ? "The invitation, carried." : "Mayo, 1593 — the invitation", detail: atlas.storyCompleted ? "Return to the evidence, language and places from the documentary journey." : "A document survives. Before legend takes over, ask what Gráinne Ní Mháille put before the English state.")

                ClewBayMiniature()
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                AtlasCard(accent: atlas.storyCompleted ? Theme.atlasGold : Theme.atlasGreen) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack { CertaintyPill(certainty: .documented); Spacer(); Text("1593").font(.system(size: 13, design: .monospaced)).foregroundStyle(Theme.inkFaint) }
                        Text("What did she actually ask for?")
                            .font(.system(size: 26, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.ink)
                        Text("Meet the person, follow the Mayo coastline, inspect an explanatory facsimile, separate record from afterlife, then use your first Irish to identify yourself.")
                            .font(.system(size: 14.5))
                            .foregroundStyle(Theme.inkSoft)
                            .lineSpacing(4)
                        PrimaryButton(title: atlas.storyCompleted ? "Return to the story" : "Begin the documentary", fullWidth: true, action: onOpenStory)
                    }
                }

                Button(action: onOpenDossier) {
                    Label("Open the full Mayo dossier", systemImage: "map")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.moss)
                }
                .buttonStyle(CarvePress())
            }
            .padding(20)
            .padding(.bottom, 28)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
    }
}

struct AtlasCountyPreviewView: View {
    let countyName: String
    private var county: County? { ContentLoader.counties().first { $0.en == countyName } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AtlasScreenHeader("\(county?.province ?? "IRELAND") · COUNTY DOSSIER", county?.ga ?? countyName, detail: countyName)
                AtlasCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 44, weight: .ultraLight))
                            .foregroundStyle(Theme.stone)
                        Text("The county is visible before its story is finished.")
                            .font(.system(size: 23, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.ink)
                        Text("Research will add a named person, object or community; a historical question; surviving evidence; and useful Irish. There is no empty lock and no fictional placeholder.")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.inkSoft)
                            .lineSpacing(4)
                    }
                }
                HStack { CertaintyPill(certainty: .unknown); Text("Headline story · editorial research in progress").font(.system(size: 12.5)).foregroundStyle(Theme.inkSoft) }
            }
            .padding(22)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(countyName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Reusable Clew Bay drawing

struct ClewBayMiniature: View {
    var showRoute = true
    var body: some View {
        Canvas { ctx, size in
            let water = Path(CGRect(origin: .zero, size: size))
            ctx.fill(water, with: .linearGradient(
                Gradient(colors: [Color(light: 0x9EB7B8, dark: 0x294044), Color(light: 0xD8D6C4, dark: 0x26332D)]),
                startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))

            var coast = Path()
            coast.move(to: CGPoint(x: 0, y: size.height * 0.70))
            coast.addCurve(to: CGPoint(x: size.width, y: size.height * 0.32),
                           control1: CGPoint(x: size.width * 0.22, y: size.height * 0.47),
                           control2: CGPoint(x: size.width * 0.67, y: size.height * 0.58))
            coast.addLine(to: CGPoint(x: size.width, y: size.height))
            coast.addLine(to: CGPoint(x: 0, y: size.height))
            coast.closeSubpath()
            ctx.fill(coast, with: .color(Color(light: 0x839378, dark: 0x364437)))

            for i in 0..<18 {
                let x = CGFloat((i * 47) % 100) / 100 * size.width
                let y = (0.33 + CGFloat((i * 29) % 32) / 100) * size.height
                let r = CGFloat(2 + (i % 4))
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2.2, height: r)), with: .color(Theme.bg.opacity(0.62)))
            }

            if showRoute {
                let points = [CGPoint(x: size.width * 0.18, y: size.height * 0.55), CGPoint(x: size.width * 0.49, y: size.height * 0.46), CGPoint(x: size.width * 0.77, y: size.height * 0.39)]
                var route = Path(); route.move(to: points[0]); route.addCurve(to: points[2], control1: points[1], control2: points[1])
                ctx.stroke(route, with: .color(Theme.atlasGold), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [3, 5]))
                for p in points { ctx.fill(Path(ellipseIn: CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)), with: .color(Theme.atlasGold)) }
            }
        }
        .overlay(alignment: .topLeading) {
            Text("CLEW BAY · MAYO")
                .font(.system(size: 9, weight: .bold))
                .kerning(1.5)
                .foregroundStyle(Theme.bg.opacity(0.9))
                .padding(12)
        }
        .overlay(alignment: .bottom) {
            if showRoute {
                HStack { Text("Clare Island"); Spacer(); Text("Kildavnet"); Spacer(); Text("Rockfleet") }
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.bg)
                    .padding(12)
            }
        }
    }
}
