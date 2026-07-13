import SwiftUI

// MARK: - Mayo editorial dossier

struct MayoDossierView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let onMeetGrainne: () -> Void
    let onBegin: () -> Void
    let onFieldNote: () -> Void
    let onOpenEvidence: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AtlasScreenHeader("CONNACHT · MAIGH EO", "Mayo", detail: "Listen: Maigh Eo · ‘plain of the yew trees’")

                ClewBayMiniature()
                    .frame(height: 270)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 0.8))

                Label("1593 · state paper · person · sea route", systemImage: "doc.text")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.inkFaint)

                Button(action: onMeetGrainne) {
                    Group {
                        if dynamicTypeSize.isAccessibilitySize {
                            VStack(alignment: .leading, spacing: 12) {
                                GrainnePortraitMark()
                                    .frame(width: 110, height: 132)
                                headlinePersonText
                                Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                            }
                        } else {
                            HStack(spacing: 16) {
                                GrainnePortraitMark()
                                    .frame(width: 86, height: 104)
                                headlinePersonText
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                            }
                        }
                    }
                    .padding(15)
                    .background(Theme.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(CarvePress())

                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "THE HISTORICAL QUESTION")
                    Text("What did Gráinne actually ask for?")
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("Begin with the state record. Only then compare the famous image of the ‘pirate queen’ with what can be supported.")
                        .font(.body)
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(4)
                }
                .padding(.vertical, 4)

                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(spacing: 12) { dossierPromises }
                    } else {
                        HStack(alignment: .top, spacing: 12) { dossierPromises }
                    }
                }

                routeSection

                SourceFooter(onOpen: onOpenEvidence)

                PrimaryButton(title: "Begin · What did she ask for?", fullWidth: true, action: onBegin)

                AtlasRule()

                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow(text: "ANOTHER MAYO ENCOUNTER")
                    Button(action: onFieldNote) {
                        HStack(spacing: 13) {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 24, weight: .light))
                                .foregroundStyle(Theme.inkFaint)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Breastagh · a damaged name")
                                    .font(.system(size: 17, weight: .semibold, design: .serif))
                                    .foregroundStyle(Theme.ink)
                                Text("A short field note. Reconstruction is entered through a visible boundary and earns no county completion.")
                                    .font(.system(size: 12.5))
                                    .foregroundStyle(Theme.inkSoft)
                                    .lineSpacing(3)
                            }
                            Spacer()
                            CertaintyPill(certainty: .reconstruction)
                        }
                    }
                    .buttonStyle(CarvePress())
                }
            }
            .padding(20)
            .padding(.bottom, 36)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Mayo dossier")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headlinePersonText: some View {
        VStack(alignment: .leading, spacing: 5) {
            Eyebrow(text: "THE HEADLINE PERSON", color: Theme.atlasGreen)
            Text("Gráinne Ní Mháille")
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("A maritime leader from Mayo whose dealings with the English state left a documentary record.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(3)
        }
    }

    @ViewBuilder
    private var dossierPromises: some View {
        DossierPromise(icon: "doc.text.magnifyingglass", eyebrow: "WHAT SURVIVES", text: "A 1593 state-paper trail concerning Gráinne and members of her family.", accent: Theme.lichen)
        DossierPromise(icon: "quote.bubble", eyebrow: "WHAT YOU CAN SAY", text: "Identify yourself: Is mise… Then say your name and where you are from.", accent: Theme.moss)
    }

    private var routeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "THE STORY GEOGRAPHY")
            HStack(spacing: 0) {
                RoutePlace(name: "Oileán Chliara", en: "Clare Island", first: true)
                RouteLine()
                RoutePlace(name: "Cill Damhnait", en: "Kildavnet")
                RouteLine()
                RoutePlace(name: "Carraig an Chabhlaigh", en: "Rockfleet")
            }
            Text("These places locate a Mayo life. The route is editorial and not a claim that every movement shown is documented.")
                .font(.caption)
                .foregroundStyle(Theme.inkFaint)
                .lineSpacing(3)
        }
        .padding(15)
        .background(Theme.sunk)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Story geography: Oileán Chliara, Clare Island; Cill Damhnait, Kildavnet; Carraig an Chabhlaigh, Rockfleet. This is an editorial route, not a documented movement map.")
    }
}

private struct DossierPromise: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let icon: String
    let eyebrow: String
    let text: String
    let accent: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: icon).font(.system(size: 23, weight: .light)).foregroundStyle(accent)
            Eyebrow(text: eyebrow, color: accent)
            Text(text)
                .font(.system(.body, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? nil : 170, alignment: .topLeading)
        .background(Theme.raised)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.35), lineWidth: 0.8))
    }
}

private struct RoutePlace: View {
    let name: String
    let en: String
    var first = false
    var body: some View {
        VStack(spacing: 5) {
            Circle().fill(first ? Theme.atlasGreen : Theme.atlasGold).frame(width: 9, height: 9)
            Text(name).font(.system(size: 10.5, weight: .semibold, design: .serif)).foregroundStyle(Theme.ink).lineLimit(1).minimumScaleFactor(0.7)
            Text(en).font(.system(size: 8.5)).foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct RouteLine: View {
    var body: some View {
        Rectangle().fill(Theme.atlasGold.opacity(0.6)).frame(width: 24, height: 1).offset(y: -18)
    }
}

// MARK: - Person layer

struct GrainnePersonView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let onBegin: () -> Void
    let onOpenEvidence: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 14) {
                            GrainnePortraitMark().frame(width: 130, height: 170)
                            personHeading
                        }
                    } else {
                        HStack(alignment: .bottom, spacing: 18) {
                            GrainnePortraitMark().frame(width: 130, height: 170)
                            personHeading
                        }
                    }
                }

                AtlasAudioLine(ga: "Gráinne Ní Mháille", en: "A Connacht Irish name form", sound: "grawn-ya nee wawl-ya")

                AtlasCard(accent: Theme.atlasGreen) {
                    VStack(alignment: .leading, spacing: 9) {
                        Eyebrow(text: "FROM THE 1593 RECORD", color: Theme.atlasGreen)
                        Text("A maritime leader with power rooted around the Mayo coast; English administrative records preserve dealings concerning her and her family.")
                            .font(.system(.body, design: .serif))
                            .foregroundStyle(Theme.ink)
                            .lineSpacing(4)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow(text: "PLACES AND CONSEQUENCES")
                    PersonLink(icon: "water.waves", title: "Clew Bay and Clare Island", detail: "The geography that makes the story a Mayo story.")
                    PersonLink(icon: "person.2", title: "Her family", detail: "The 1593 record concerns more than one individual and makes family power part of the question.")
                    PersonLink(icon: "building.columns", title: "The English state", detail: "The record survives because her demands entered an administrative system.")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "RECORD AND AFTERLIFE", color: Theme.rust)
                    ClaimBoundary(icon: "doc.text", text: "The 1593 record names Gráinne and members of her family.")
                    ClaimBoundary(icon: "book.closed", text: "Later stories remember a refusal to bow to Elizabeth I.")
                    ClaimBoundary(icon: "questionmark.circle", text: "The meeting language and the hair-cutting origin story are not established by this record.")
                    Text("The source guide keeps those different kinds of claim apart.")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft)
                    Button(action: onOpenEvidence) {
                        Label("Open the 1593 source guide", systemImage: "building.columns")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(Theme.rust)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(CarvePress())
                }
                .padding(16)
                .background(Theme.rustTint)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                SourceFooter(onOpen: onOpenEvidence)
                PrimaryButton(title: "Enter the 1593 story", fullWidth: true, action: onBegin)
            }
            .padding(20)
            .padding(.bottom, 36)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Gráinne Ní Mháille")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var personHeading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(text: "PERSON · MAYO · 16TH CENTURY")
            Text("Gráinne Ní Mháille")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Grace O’Malley")
                .font(.system(.body, design: .serif))
                .foregroundStyle(Theme.inkSoft)
            Text("c. 1530 – c. 1603")
                .font(.caption.monospaced().weight(.medium))
                .foregroundStyle(Theme.inkFaint)
        }
    }
}

struct GrainnePortraitMark: View {
    var body: some View {
        Canvas { ctx, size in
            let bg = Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 8)
            ctx.fill(bg, with: .linearGradient(Gradient(colors: [Theme.moss.opacity(0.28), Theme.sunk]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))

            var sea = Path()
            sea.move(to: CGPoint(x: 0, y: size.height * 0.75))
            sea.addCurve(to: CGPoint(x: size.width, y: size.height * 0.68), control1: CGPoint(x: size.width * 0.3, y: size.height * 0.62), control2: CGPoint(x: size.width * 0.7, y: size.height * 0.84))
            ctx.stroke(sea, with: .color(Theme.moss.opacity(0.55)), lineWidth: 1)

            let head = CGRect(x: size.width * 0.36, y: size.height * 0.22, width: size.width * 0.29, height: size.height * 0.25)
            ctx.fill(Path(ellipseIn: head), with: .color(Theme.ink.opacity(0.83)))
            var shoulders = Path()
            shoulders.move(to: CGPoint(x: size.width * 0.18, y: size.height * 0.85))
            shoulders.addQuadCurve(to: CGPoint(x: size.width * 0.82, y: size.height * 0.85), control: CGPoint(x: size.width * 0.5, y: size.height * 0.46))
            shoulders.closeSubpath()
            ctx.fill(shoulders, with: .color(Theme.ink.opacity(0.83)))

            var hair = Path()
            hair.move(to: CGPoint(x: size.width * 0.38, y: size.height * 0.32))
            hair.addCurve(to: CGPoint(x: size.width * 0.26, y: size.height * 0.69), control1: CGPoint(x: size.width * 0.25, y: size.height * 0.37), control2: CGPoint(x: size.width * 0.37, y: size.height * 0.57))
            ctx.stroke(hair, with: .color(Theme.lichen), style: StrokeStyle(lineWidth: max(size.width * 0.035, 2), lineCap: .round))
        }
        .overlay(alignment: .bottomLeading) {
            Text("INTERPRETIVE MARK")
                .font(.system(size: 6.5, weight: .bold))
                .kerning(0.8)
                .foregroundStyle(Theme.bg.opacity(0.8))
                .padding(7)
        }
        .accessibilityLabel("An interpretive silhouette representing Gráinne Ní Mháille, not a historical portrait")
    }
}

private struct PersonLink: View {
    let icon: String
    let title: String
    let detail: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundStyle(Theme.moss).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .semibold, design: .serif)).foregroundStyle(Theme.ink)
                Text(detail).font(.system(size: 12.5)).foregroundStyle(Theme.inkSoft).lineSpacing(3)
            }
        }
    }
}

private struct ClaimBoundary: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).font(.caption).foregroundStyle(Theme.rust).padding(.top, 2)
            Text(text).font(.system(.body, design: .serif)).foregroundStyle(Theme.ink)
        }
    }
}

// MARK: - Documentary story registers

struct GrainneStoryView: View {
    @EnvironmentObject private var atlas: AtlasPrototypeModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let onOpenEvidence: () -> Void
    let onComplete: () -> Void

    @State private var learnerNameDraft = ""

    private let stepNames = ["Rockfleet", "Gráinne", "The letter", "Your name"]
    private let storyTop = "grainne-story-top"
    private var step: Int { atlas.storyStep }
    private var foundName: Bool { atlas.storyFoundName }

    var body: some View {
        VStack(spacing: 0) {
            storyChrome
            ScrollViewReader { proxy in
                ScrollView {
                    Color.clear
                        .frame(height: 0)
                        .id(storyTop)
                    Group {
                        switch step {
                        case 0: rockfleet
                        case 1: meetGrainne
                        case 2: whatSurvives
                        default: yourIrish
                        }
                    }
                    .id(step)
                    .transition(reduceMotion ? .identity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    .padding(20)
                    .padding(.bottom, 100)
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
        .background(Theme.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { storyControls }
        .onAppear {
            if learnerNameDraft.isEmpty {
                learnerNameDraft = atlas.learnerName
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { commitLearnerName() }
        }
        .onChange(of: foundName) { _, found in
            if found { atlas.evidenceInspected = true }
        }
    }

    private var storyChrome: some View {
        VStack(spacing: 7) {
            HStack {
                Text("\(step + 1) / \(stepNames.count)")
                Spacer()
                Text(stepNames[step].uppercased())
            }
            .font(.caption2.weight(.bold))
            .kerning(1.25)
            .foregroundStyle(Theme.inkFaint)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.line).frame(height: 2)
                    Capsule().fill(Theme.moss).frame(width: geo.size.width * CGFloat(step + 1) / CGFloat(stepNames.count), height: 2)
                }
            }
            .frame(height: 2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Theme.bg)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Story step \(step + 1) of \(stepNames.count): \(stepNames[step])")
    }

    private var storyControls: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let blockedReason {
                Text(blockedReason)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
                    .accessibilityLabel("To continue: \(blockedReason)")
            }
            HStack(spacing: 12) {
                if step > 0 {
                    Button { move(to: step - 1) } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 44, height: 44)
                            .background(Theme.raised)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .buttonStyle(CarvePress())
                    .accessibilityLabel("Previous story step")
                }
                PrimaryButton(title: step == stepNames.count - 1 ? "Keep this phrase" : nextTitle, fullWidth: true) {
                    if step == stepNames.count - 1 { completeStory() }
                    else { move(to: step + 1) }
                }
                .disabled(blockedReason != nil)
                .opacity(blockedReason == nil ? 1 : 0.45)
                .accessibilityHint(blockedReason ?? "Continues to the next story step")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var blockedReason: String? {
        if step == 2, !foundName { return "Find Gráinne’s name in the record." }
        if step == 3, learnerNameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Enter your name."
        }
        return nil
    }

    private var nextTitle: String {
        switch step {
        case 0: return "Meet Gráinne"
        case 1: return "Follow her to London"
        default: return "Use your first Irish"
        }
    }

    private func move(to newStep: Int) {
        Haptics.tap()
        withAnimation(reduceMotion ? nil : Motion.settle) {
            atlas.storyStep = newStep
        }
    }

    private func completeStory() {
        commitLearnerName()
        onComplete()
    }

    private func commitLearnerName() {
        let name = learnerNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty, atlas.learnerName != name {
            atlas.learnerName = name
        }
    }

    private var rockfleet: some View {
        VStack(alignment: .leading, spacing: 22) {
            ZStack(alignment: .bottomLeading) {
                ClewBayMiniature().frame(height: 350)
                LinearGradient(colors: [.clear, Color.black.opacity(0.72)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 4) {
                    Text("MAYO · 1593")
                        .font(.caption.weight(.bold)).kerning(1.7)
                    Text("Rockfleet")
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    Text("At high tide, Clew Bay reaches the castle walls.")
                        .font(.body).lineSpacing(3)
                }
                .foregroundStyle(.white)
                .padding(20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("Her fleet was gone. Her lands had been taken. Her youngest son was a prisoner.")
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .lineSpacing(6)

            Text("So she went to the queen.")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text("From this western inlet, Gráinne Ní Mháille sought an audience with Elizabeth I — and secured one.")
                .font(.system(.body, design: .serif))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(5)

        }
    }

    private var meetGrainne: some View {
        VStack(alignment: .leading, spacing: 22) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 14) {
                        GrainnePortraitMark().frame(width: 145, height: 190)
                        storyPersonHeading
                    }
                } else {
                    HStack(alignment: .bottom, spacing: 18) {
                        GrainnePortraitMark().frame(width: 145, height: 190)
                        storyPersonHeading
                    }
                }
            }

            AtlasAudioLine(ga: "Gráinne Ní Mháille", en: "Her name in Irish", sound: "grawn-ya nee wawl-ya")

            Text("She grew up in the O’Malley world of Clare Island and Clew Bay, where boats connected castles, families and trade. She became a leader in her own right — at sea and on land.")
                .font(.system(.title3, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineSpacing(6)

            ClewBayMiniature()
                .frame(height: 290)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("Clare Island. Kildavnet. Rockfleet. The castles associated with her still hold the edges of the bay.")
                .font(.system(.body, design: .serif))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(5)

            AtlasCard(accent: Theme.atlasGold) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("“She thinketh herself to be no small lady.”")
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineSpacing(4)
                    Text("Sir Nicholas Malby, Governor of Connaught")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
        }
    }

    private var storyPersonHeading: some View {
        VStack(alignment: .leading, spacing: 7) {
            Eyebrow(text: "A LIFE SHAPED BY THE SEA")
            Text("Gráinne Ní Mháille")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("c. 1530 – c. 1603")
                .font(.caption.monospaced())
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private var whatSurvives: some View {
        VStack(alignment: .leading, spacing: 18) {
            AtlasScreenHeader("LONDON · 6 SEPTEMBER 1593", "Her name enters the record.", detail: "A draft letter leaves the queen’s government. Gráinne is in London, and the people named with her reveal what this journey is really about.")
            FamilyRecordReveal(
                foundName: $atlas.storyFoundName,
                onOpenEvidence: onOpenEvidence
            )

            if foundName {
                Text("Her requests were not hers alone. The letter reaches back across the sea to her sons, her brother and the struggle for her family’s future.")
                    .font(.system(.title3, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(6)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                AtlasCard(accent: Theme.rust) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("What later stories remember")
                            .font(.system(.headline, design: .serif, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("Later stories tell of Gráinne refusing to bow to Elizabeth. The letter holds its own act of defiance: she crossed from Clew Bay to the heart of English power and made the state answer her.")
                            .font(.system(.body, design: .serif))
                            .foregroundStyle(Theme.inkSoft)
                            .lineSpacing(4)
                    }
                }
                .transition(.opacity)
            }
            SourceFooter(compact: true, onOpen: onOpenEvidence)
        }
    }

    private var yourIrish: some View {
        VStack(alignment: .leading, spacing: 20) {
            AtlasScreenHeader("YOUR NAME", "A name can cross centuries.", detail: "The letter wrote hers as “Grany ne Maly.” In Irish, she is Gráinne Ní Mháille. Now make the first Irish sentence about yourself.")
            AtlasAudioLine(ga: "Is mise…", en: "I am… / I’m…", sound: "iss mish-eh")
            VStack(alignment: .leading, spacing: 9) {
                Text("Cén t-ainm atá ort?")
                    .font(.system(.headline, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text("What is your name?")
                    .font(.caption).foregroundStyle(Theme.inkFaint)
                TextField("Your name", text: $learnerNameDraft)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit { commitLearnerName() }
                    .accessibilityLabel("What is your name?")
                    .accessibilityHint("Enter your name to make the Irish phrase Is mise")
                    .font(.system(.title3, design: .serif))
                    .padding(14)
                    .background(Theme.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line, lineWidth: 0.8))
            }
            if !learnerNameDraft.trimmingCharacters(in: .whitespaces).isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(text: "TUSA · YOU")
                    Text("Is mise \(learnerNameDraft).")
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.moss)
                    Text("This is yours to use in any introduction.")
                        .font(.subheadline).foregroundStyle(Theme.inkSoft)
                }
                .padding(18)
                .background(Theme.mossTint)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

}

private struct FamilyRecordReveal: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var foundName: Bool
    let onOpenEvidence: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Eyebrow(text: "ANNOTATED TRANSCRIPTION · ORIGINAL MANUSCRIPT NOT SHOWN", color: Theme.lichen)
            ZStack {
                Color(light: 0xE4D7B2, dark: 0xA4936C)
                Canvas { ctx, size in
                    for i in 0..<16 {
                        let y = size.height * (0.13 + CGFloat(i) * 0.047)
                        let inset = size.width * (0.09 + CGFloat((i * 11) % 6) * 0.009)
                        var line = Path()
                        line.move(to: CGPoint(x: inset, y: y))
                        line.addLine(to: CGPoint(x: size.width * (0.72 + CGFloat((i * 7) % 16) / 100), y: y))
                        ctx.stroke(line, with: .color(Color.black.opacity(0.34)), style: StrokeStyle(lineWidth: 1.1, lineCap: .round, dash: [3, 1.5]))
                    }
                }
                if foundName {
                    VStack(spacing: 7) {
                        Text("Grany ne Maly")
                            .font(.system(.title2, design: .serif, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.74))
                        Image(systemName: "arrow.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.atlasGreen)
                        Text("Gráinne Ní Mháille")
                            .font(.system(.title3, design: .serif, weight: .semibold))
                            .foregroundStyle(Theme.atlasGreen)
                    }
                    .padding(18)
                    .background(Theme.bg.opacity(0.94))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
                }
            }
            .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 420 : 300)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel(foundName
                ? "Annotated transcription view. The record writes Gráinne's name as Grany ne Maly and also names members of her family. This is not the manuscript image."
                : "Annotated transcription view, not the manuscript image. Find Gráinne's name to continue.")

            Button(action: onOpenEvidence) {
                Label("About this transcription and source", systemImage: "doc.text.magnifyingglass")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Theme.moss)
                    .frame(minHeight: 44)
            }
            .buttonStyle(CarvePress())

            if foundName {
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "HER FAMILY")
                    Text("Her sons Morogh O’Flaherty and Tibbut Burke, and her brother Donell O’Piper, are named too.")
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(Theme.ink)
                        .lineSpacing(4)
                    SoundRow(text: "Gráinne Ní Mháille", hint: "grawn-ya nee wawl-ya")
                }
                .transition(.opacity)
            } else {
                PrimaryButton(title: "Find Gráinne’s name", fullWidth: true) {
                    Haptics.chisel()
                    withAnimation(reduceMotion ? nil : Motion.settle) { foundName = true }
                }
            }
        }
    }
}

private struct OutcomeRow: View {
    let icon: String
    let title: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundStyle(Theme.moss).frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title.uppercased()).font(.system(size: 9.5, weight: .bold)).kerning(1.1).foregroundStyle(Theme.inkFaint)
                Text(text).font(.system(size: 14.5, design: .serif)).foregroundStyle(Theme.ink).lineSpacing(3)
            }
        }
    }
}

// MARK: - Evidence primitive

struct PetitionEvidenceView: View {
    @EnvironmentObject private var atlas: AtlasPrototypeModel
    @State private var zoom: Double = 1
    @State private var annotations = true
    @State private var compareAfterlife = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AtlasScreenHeader("WHAT SURVIVES · DOCUMENT", "The 1593 record", detail: "This annotated transcription helps you read what the state paper records. The original manuscript image is not shown here.")
                HStack {
                    CertaintyPill(certainty: .documented)
                    Text("ANNOTATED TRANSCRIPTION · ORIGINAL MANUSCRIPT NOT SHOWN")
                        .font(.caption2.weight(.bold))
                        .kerning(1)
                        .foregroundStyle(Theme.inkFaint)
                }
                PetitionInspectionPanel(zoom: $zoom, showAnnotations: $annotations)

                Toggle(isOn: $compareAfterlife) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Compare with the ‘pirate queen’ afterlife").font(.system(size: 14, weight: .semibold, design: .serif))
                        Text("Keeps later storytelling in a separate register.").font(.system(size: 11.5)).foregroundStyle(Theme.inkSoft)
                    }
                }
                .tint(Theme.rust)
                .padding(14)
                .background(Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: 9))

                if compareAfterlife {
                    AtlasCard(accent: Theme.rust) {
                        VStack(alignment: .leading, spacing: 9) {
                            CertaintyPill(certainty: .later)
                            Text("The popular image is historically consequential: it shaped how Gráinne is remembered. It is not allowed to rewrite the document beside it.")
                                .font(.system(size: 15, design: .serif)).foregroundStyle(Theme.ink).lineSpacing(4)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "PROVENANCE AND REVIEW")
                    MetadataRow(label: "Repository", value: "National Library of Ireland · starting-point record")
                    MetadataRow(label: "Reference", value: "MS_UR_010761")
                    MetadataRow(label: "Image status", value: "No manuscript image is included; this is a transcription-based guide")
                    MetadataRow(label: "Reading rule", value: "Archival record and later storytelling remain separate")
                    MetadataRow(label: "Question answered", value: "What did Gráinne put before the state?")
                }
                .padding(16)
                .background(Theme.sunk)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                SourceFooter()
            }
            .padding(20)
            .padding(.bottom, 36)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Source guide")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { atlas.evidenceInspected = true }
    }
}

struct PetitionInspectionPanel: View {
    @Binding var zoom: Double
    @Binding var showAnnotations: Bool

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    PetitionFacsimileView(showAnnotations: showAnnotations)
                        .frame(width: max(geo.size.width * zoom, geo.size.width), height: max(geo.size.height * zoom, geo.size.height))
                }
                .background(Color(light: 0xCABF9E, dark: 0x554D3C))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .frame(height: 390)

            HStack(spacing: 12) {
                Image(systemName: "minus.magnifyingglass").foregroundStyle(Theme.inkFaint)
                Slider(value: $zoom, in: 1...2.4).tint(Theme.moss)
                Image(systemName: "plus.magnifyingglass").foregroundStyle(Theme.inkFaint)
            }
            Toggle("Show what the record tells us", isOn: $showAnnotations)
                .font(.system(size: 13, weight: .semibold))
                .tint(Theme.moss)
        }
    }
}

private struct PetitionFacsimileView: View {
    let showAnnotations: Bool
    var body: some View {
        ZStack {
            Color(light: 0xE4D7B2, dark: 0xA4936C)
            Canvas { ctx, size in
                for i in 0..<26 {
                    let y = size.height * (0.12 + CGFloat(i) * 0.028)
                    let inset = size.width * (0.10 + CGFloat((i * 17) % 8) * 0.006)
                    var line = Path()
                    line.move(to: CGPoint(x: inset, y: y))
                    line.addCurve(to: CGPoint(x: size.width * (0.74 + CGFloat((i * 13) % 18) / 100), y: y + CGFloat((i % 3) - 1) * 2), control1: CGPoint(x: size.width * 0.32, y: y - 3), control2: CGPoint(x: size.width * 0.57, y: y + 3))
                    ctx.stroke(line, with: .color(Color.black.opacity(0.44)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [CGFloat(2 + i % 5), 1.3]))
                }
                let margin = CGRect(x: size.width * 0.075, y: size.height * 0.07, width: size.width * 0.85, height: size.height * 0.82)
                ctx.stroke(Path(margin), with: .color(Color.black.opacity(0.18)), lineWidth: 0.7)
            }
            VStack {
                Text("1593 · STATE RECORD")
                    .font(.system(size: 10, weight: .bold, design: .serif)).kerning(1.5).foregroundStyle(Color.black.opacity(0.58))
                    .padding(.top, 24)
                Spacer()
                Text("Gráinne · family · requests")
                    .font(.system(size: 9, weight: .medium)).foregroundStyle(Color.black.opacity(0.48)).padding(.bottom, 20)
            }
            if showAnnotations {
                VStack {
                    HStack {
                        AnnotationFlag(text: "GRÁINNE IS NAMED", certainty: .documented)
                        Spacer()
                    }
                    .padding(.top, 80)
                    Spacer()
                    HStack {
                        Spacer()
                        AnnotationFlag(text: "REQUESTS FOR HER FAMILY", certainty: .documented)
                    }
                    .padding(.bottom, 110)
                }
                .padding(.horizontal, 18)
            }
        }
    }
}

private struct AnnotationFlag: View {
    let text: String
    let certainty: EvidenceCertainty
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(certainty.color).frame(width: 6, height: 6)
            Text(text).font(.system(size: 8.5, weight: .bold)).kerning(0.8)
        }
        .foregroundStyle(certainty.color)
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(Theme.bg.opacity(0.93)).clipShape(Capsule())
    }
}

private struct MetadataRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label.uppercased()).font(.system(size: 9, weight: .bold)).kerning(0.8).foregroundStyle(Theme.inkFaint).frame(width: 90, alignment: .leading)
            Text(value).font(.system(size: 12.5)).foregroundStyle(Theme.ink).frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Breastagh field note and reconstruction boundary

struct BreastaghFieldNoteView: View {
    @EnvironmentObject private var atlas: AtlasPrototypeModel
    @State private var stage = 0
    @State private var traced = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if stage == 0 { fieldNoteEntry }
                else if stage == 1 { evidenceStage }
                else if stage == 2 { reconstructionStage }
                else { fieldNoteExit }
            }
            .padding(20)
            .padding(.bottom, 36)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(stage == 2 ? Theme.sunk.ignoresSafeArea() : Theme.bg.ignoresSafeArea())
        .navigationTitle("Breastagh field note")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var fieldNoteEntry: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack { CertaintyPill(certainty: .reconstruction); Spacer(); Text("FIELD NOTE · 4 MIN").font(.system(size: 9.5, weight: .bold)).kerning(1.1).foregroundStyle(Theme.inkFaint) }
            AtlasScreenHeader("BREASTAGH · MAYO", "A name survives. A life does not.", detail: "This short encounter is about the limit itself: how much can one damaged inscription tell us?")
            StoneInscriptionView(progress: 1).frame(height: 330)
            AtlasCard(accent: Theme.inkFaint) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Before you enter")
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                    Text("The stone, its location and a damaged scholarly transcription belong to the evidence register. Any voice, motive or scene built around it belongs to reconstruction.")
                        .font(.system(size: 15, design: .serif)).foregroundStyle(Theme.inkSoft).lineSpacing(4)
                    Text("This field note does not complete Mayo and contains no assessed invented facts.")
                        .font(.system(size: 12.5, weight: .semibold)).foregroundStyle(Theme.rust)
                }
            }
            PrimaryButton(title: "Show me the evidence first", fullWidth: true) { withAnimation(Motion.settle) { stage = 1 } }
        }
    }

    private var evidenceStage: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack { CertaintyPill(certainty: .material); Spacer(); Text("EVIDENCE REGISTER").font(.system(size: 9.5, weight: .bold)).kerning(1.1).foregroundStyle(Theme.inkFaint) }
            AtlasScreenHeader("WHAT THE STONE CAN SAY", "Marks, damage, place.", detail: "Trace from the base upward — the direction in which Ogham is read on a pillar stone.")
            StoneInscriptionView(progress: traced ? 1 : 0.35)
                .frame(height: 390)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 8).onChanged { value in
                    if value.translation.height < -80, !traced { traced = true; Haptics.tick() }
                })
            Text(traced ? "The groove is under your hand. Damage remains visible; missing marks are not silently repaired." : "Drag upward along the stemline.")
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundStyle(traced ? Theme.moss : Theme.inkSoft)
            VStack(alignment: .leading, spacing: 9) {
                EvidenceFact(certainty: .documented, text: "Breastagh is recorded as an Ogham stone in Mayo.")
                EvidenceFact(certainty: .material, text: "The surviving marks are incomplete and damaged.")
                EvidenceFact(certainty: .unknown, text: "The lives and motives of the people named cannot be recovered from the inscription alone.")
            }
            PrimaryButton(title: "Enter one possible reconstruction", fullWidth: true) { withAnimation(Motion.settle) { stage = 2 } }
        }
    }

    private var reconstructionStage: some View {
        VStack(alignment: .leading, spacing: 20) {
            ReconstructionGate(label: "ENTERING RECONSTRUCTION")
            AtlasScreenHeader("ONE POSSIBLE HAND", "Imagine the making, not a recovered scene.", detail: "A tool meets stone. Repetition, resistance and sound can be explored without inventing a named carver or a recorded conversation.")
            ZStack {
                StoneInscriptionView(progress: traced ? 1 : 0.55)
                VStack {
                    Spacer()
                    Text("tap · pause · strike")
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.bg)
                        .padding(12)
                        .background(Theme.ink.opacity(0.8))
                        .clipShape(Capsule())
                        .padding(.bottom, 24)
                }
            }
            .frame(height: 360)
            .onTapGesture { Haptics.chisel() }
            Text("No person here is presented as historical. No reason for the inscription is supplied. The reconstruction is tactile, bounded and optional.")
                .font(.system(size: 14, design: .serif)).foregroundStyle(Theme.inkSoft).lineSpacing(4)
            ReconstructionGate(label: "LEAVING RECONSTRUCTION")
            PrimaryButton(title: "Return to what is known", fullWidth: true) {
                atlas.fieldNoteVisited = true
                withAnimation(Motion.settle) { stage = 3 }
            }
        }
    }

    private var fieldNoteExit: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack { CertaintyPill(certainty: .material); Spacer(); Text("FIELD NOTE COMPLETE · NO COUNTY PROGRESS").font(.system(size: 8.5, weight: .bold)).kerning(0.8).foregroundStyle(Theme.inkFaint) }
            AtlasScreenHeader("BACK IN THE FIELD", "The uncertainty is part of the object.", detail: "You handled a reconstruction of carving after first seeing the evidence boundary. Nothing imagined was promoted into the historical account.")
            StoneInscriptionView(progress: 1).frame(height: 330)
            VStack(alignment: .leading, spacing: 12) {
                OutcomeRow(icon: "checkmark", title: "Known", text: "A recorded Mayo Ogham stone and damaged marks.")
                OutcomeRow(icon: "questionmark", title: "Unknown", text: "A recoverable biography, exact motive or witnessed scene.")
                OutcomeRow(icon: "hand.draw", title: "Reconstructed", text: "The feel and rhythm of a possible carving action.")
            }
            SourceFooter(compact: true)
        }
    }
}

private struct ReconstructionGate: View {
    let label: String
    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(Theme.inkFaint).frame(height: 1)
            Text(label).font(.system(size: 9.5, weight: .bold)).kerning(1.2).foregroundStyle(Theme.inkFaint).fixedSize()
            Rectangle().fill(Theme.inkFaint).frame(height: 1)
        }
        .padding(.vertical, 8)
    }
}

private struct EvidenceFact: View {
    let certainty: EvidenceCertainty
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            CertaintyPill(certainty: certainty)
            Text(text).font(.system(size: 13.5, design: .serif)).foregroundStyle(Theme.ink).lineSpacing(3)
        }
    }
}

private struct StoneInscriptionView: View {
    let progress: CGFloat
    var body: some View {
        Canvas { ctx, size in
            let stoneRect = CGRect(x: size.width * 0.23, y: size.height * 0.04, width: size.width * 0.54, height: size.height * 0.92)
            let stone = Path(roundedRect: stoneRect, cornerRadius: 18)
            ctx.fill(stone, with: .linearGradient(Gradient(colors: [Theme.stone.opacity(0.82), Theme.inkSoft.opacity(0.55)]), startPoint: stoneRect.origin, endPoint: CGPoint(x: stoneRect.maxX, y: stoneRect.maxY)))
            ctx.stroke(stone, with: .color(Theme.ink.opacity(0.25)), lineWidth: 1)

            let x = stoneRect.midX
            let bottom = stoneRect.maxY - 30
            let top = bottom - (stoneRect.height - 70) * progress
            var stem = Path(); stem.move(to: CGPoint(x: x, y: bottom)); stem.addLine(to: CGPoint(x: x, y: top))
            ctx.stroke(stem, with: .color(Theme.bg.opacity(0.75)), style: StrokeStyle(lineWidth: 2, lineCap: .round))

            let marks = 15
            for i in 0..<Int(CGFloat(marks) * progress) {
                let y = bottom - CGFloat(i) * (stoneRect.height - 80) / CGFloat(marks)
                var mark = Path()
                if i % 5 == 4 {
                    mark.addEllipse(in: CGRect(x: x - 4, y: y - 4, width: 8, height: 8))
                } else if i % 3 == 0 {
                    mark.move(to: CGPoint(x: x - 23, y: y + 7)); mark.addLine(to: CGPoint(x: x + 4, y: y - 7))
                } else {
                    mark.move(to: CGPoint(x: x - 4, y: y)); mark.addLine(to: CGPoint(x: x + 24, y: y - CGFloat((i % 2) * 5)))
                }
                ctx.stroke(mark, with: .color(Theme.bg.opacity(i == 8 ? 0.23 : 0.78)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            }
        }
        .background(Theme.sunk)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .topLeading) {
            Text("BREASTAGH · EXPLANATORY DRAWING")
                .font(.system(size: 8.5, weight: .bold)).kerning(1.1).foregroundStyle(Theme.inkFaint).padding(12)
        }
    }
}
