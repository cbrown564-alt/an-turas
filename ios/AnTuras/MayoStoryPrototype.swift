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
            VStack(alignment: .leading, spacing: 0) {
                MayoDossierHero()

                VStack(alignment: .leading, spacing: 24) {
                    Label("A Mayo leader · a family in danger · a case carried to London", systemImage: "doc.text")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.inkFaint)

                    Button(action: onMeetGrainne) {
                        HStack(alignment: .center, spacing: 16) {
                            headlinePersonText
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Theme.atlasGreen)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .padding(.vertical, 18)
                        .contentShape(Rectangle())
                        .overlay(alignment: .top) { EditorialRule() }
                        .overlay(alignment: .bottom) { EditorialRule() }
                    }
                    .buttonStyle(CarvePress())

                    EditorialSectionHeader(
                        context: "The historical question",
                        title: "What did Gráinne actually ask for?",
                        detail: "Begin with the state record. Only then compare the famous image of the ‘pirate queen’ with what can be supported."
                    )

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
                        EditorialContextLabel(text: "Another Mayo encounter")
                        Button(action: onFieldNote) {
                            HStack(spacing: 13) {
                                Image(systemName: "line.3.horizontal.decrease")
                                    .font(.system(size: 24, weight: .light))
                                    .foregroundStyle(Theme.inkFaint)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Breastagh · a damaged name")
                                        .font(.system(.headline, design: .serif))
                                        .foregroundStyle(Theme.ink)
                                    Text("A short field note. Reconstruction is entered through a visible boundary and earns no county completion.")
                                        .font(.caption)
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
                .padding(.horizontal, EditorialLayout.pageInset)
                .padding(.top, 22)
                .padding(.bottom, 36)
            }
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Mayo dossier")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headlinePersonText: some View {
        EditorialSectionHeader(
            context: "The headline person",
            title: "Gráinne Ní Mháille",
            detail: "A Mayo leader whose family, livelihood and authority were under pressure in 1593.",
            accent: Theme.atlasGreen
        )
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

private struct MayoDossierHero: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// The image opening stays a light composition in both appearances. Using
    /// Theme.ink here made the text turn pale in Dark Mode over a pale cloud.
    private let imageInk = Color(light: 0x172019, dark: 0x172019)

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 0) {
                    coast(height: 230)
                    copy
                        .padding(.horizontal, EditorialLayout.pageInset)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.atlantic)
                }
            } else {
                ZStack(alignment: .topLeading) {
                    coast(height: 330)
                    LinearGradient(
                        colors: [Theme.salt.opacity(0.92), Theme.salt.opacity(0.48), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                    copy
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                }
                .frame(height: 330)
            }
        }
        .clipped()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Mayo, Maigh Eo, in Connacht. Clew Bay editorial landscape. Listen: Maigh Eo, plain of the yew trees.")
    }

    private func coast(height: CGFloat) -> some View {
        GeometryReader { geometry in
            StoryArtImage(name: "grainne-clew-bay")
                .scaledToFill()
                .frame(width: geometry.size.width, height: height)
                .clipped()
        }
        .frame(height: height)
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("CONNACHT · MAIGH EO")
                .font(.caption.weight(.semibold))
                .kerning(1.05)
            Text("Mayo")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
            Text("Listen: Maigh Eo · ‘plain of the yew trees’")
                .font(.body)
        }
        .foregroundStyle(dynamicTypeSize.isAccessibilitySize ? Theme.salt : imageInk)
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
    let onBegin: () -> Void
    let onOpenEvidence: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                GrainnePersonHero()

                VStack(alignment: .leading, spacing: 32) {
                    AtlasAudioLine(ga: "Gráinne Ní Mháille", en: "A Connacht Irish name form", sound: "grawn-ya nee wawl-ya")

                    recordSection
                    placesSection
                    afterlifeSection

                    SourceFooter(onOpen: onOpenEvidence)
                    PrimaryButton(title: "Enter the 1593 story", fullWidth: true, action: onBegin)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 36)
            }
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Gráinne Ní Mháille")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var recordSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            PersonSectionHeading(context: "The 1593 record", title: "What survives", color: Theme.atlasGreen)
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "doc.text")
                    .font(.title3)
                    .foregroundStyle(Theme.atlasGreen)
                    .frame(width: 28)
                Text("Her boats, followers, lands and family formed one source of power. In 1593, the papers show what was at stake when that whole household came under pressure.")
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(4)
            }
        }
        .padding(.vertical, 18)
        .overlay(alignment: .top) { Divider().overlay(Theme.line) }
        .overlay(alignment: .bottom) { Divider().overlay(Theme.line) }
    }

    private var placesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            PersonSectionHeading(context: "Mayo and the state", title: "Places and consequences", color: Theme.moss)
            VStack(alignment: .leading, spacing: 14) {
                PersonLink(icon: "water.waves", title: "Clew Bay and Clare Island", detail: "The geography that makes the story a Mayo story.")
                PersonLink(icon: "person.2", title: "Her family", detail: "The 1593 record concerns more than one individual and makes family power part of the question.")
                PersonLink(icon: "building.columns", title: "The English state", detail: "The record survives because her demands entered an administrative system.")
            }
        }
    }

    private var afterlifeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            PersonSectionHeading(context: "Evidence and memory", title: "Record and afterlife", color: Theme.rust)
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
        .padding(18)
        .background(Theme.rustTint)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct GrainnePersonHero: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 0) {
                    portrait(height: 250)
                    identity
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.atlantic)
                }
            } else {
                ZStack(alignment: .topTrailing) {
                    portrait(height: 340)
                    LinearGradient(
                        colors: [.clear, Theme.atlantic.opacity(0.22), Theme.atlantic.opacity(0.94)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    identity
                        .frame(maxWidth: 205, alignment: .leading)
                        .padding(.horizontal, 22)
                        .padding(.top, 26)
                }
                .frame(height: 340)
            }
        }
        .clipped()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Gráinne Ní Mháille, also known as Grace O’Malley, circa 1530 to circa 1603. Interpretive generated portrait; no historical portrait from life is known.")
    }

    private func portrait(height: CGFloat) -> some View {
        GeometryReader { geometry in
            StoryArtImage(name: "grainne-crossing")
                .scaledToFill()
                .frame(width: geometry.size.width, height: height)
                .clipped()
        }
        .frame(height: height)
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("PERSON · MAYO · 16TH CENTURY")
                .font(.caption.weight(.semibold))
                .kerning(1.15)
                .foregroundStyle(Theme.salt.opacity(0.76))
            Text("Gráinne Ní Mháille")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.salt)
                .fixedSize(horizontal: false, vertical: true)
            Text("Grace O’Malley")
                .font(.system(.body, design: .serif))
                .foregroundStyle(Theme.salt.opacity(0.82))
            Text("c. 1530 – c. 1603")
                .font(.caption.monospaced().weight(.medium))
                .foregroundStyle(Theme.salt.opacity(0.68))
        }
    }
}

private struct PersonSectionHeading: View {
    let context: String
    let title: String
    let color: Color

    var body: some View {
        EditorialSectionHeader(context: context, title: title, accent: color)
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
                Text(title).font(.system(.headline, design: .serif)).foregroundStyle(Theme.ink)
                Text(detail).font(.subheadline).foregroundStyle(Theme.inkSoft).lineSpacing(3)
            }
        }
        .frame(minHeight: 44, alignment: .top)
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

struct LegacyGrainneStoryView: View {
    @EnvironmentObject private var atlas: AtlasPrototypeModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
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
            GrainnePersonHero()

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
            AtlasScreenHeader("YOUR NAME", "A name can cross centuries.", detail: "The State Papers calendar renders the July heading as “Grany Ne Malley.” In Irish, she is Gráinne Ní Mháille. Now make the first Irish sentence about yourself.")
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var foundName: Bool
    let onOpenEvidence: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Eyebrow(text: "ORIGINAL MANUSCRIPT · TNA SP 63/170 F. 201", color: Theme.lichen)
            ZStack {
                TNAInterrogatoryFolio(highlightName: foundName)
                if foundName {
                    VStack(spacing: 7) {
                        Text("Grany Ne Malley")
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
                    .padding(.bottom, 22)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel(foundName
                ? "Original manuscript page with Gráinne's name highlighted. The State Papers calendar renders the heading as Grany Ne Malley."
                : "Original first page of the July 1593 interrogatory. Find Gráinne's name to continue.")

            Button(action: onOpenEvidence) {
                Label("About this transcription and source", systemImage: "doc.text.magnifyingglass")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Theme.moss)
                    .frame(minHeight: 44)
            }
            .buttonStyle(CarvePress())

            if foundName {
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "HER ANSWERS")
                    Text("The answers name her parents, marriages and children, then describe the lands and maintenance that sustained her people.")
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
                AtlasScreenHeader("WHAT SURVIVES · DOCUMENT", "The July 1593 questions and answers", detail: "The original first page shows how the English state questioned Gráinne. The accompanying transcription helps read what her answers preserve.")
                HStack {
                    CertaintyPill(certainty: .documented)
                    Text("ORIGINAL MANUSCRIPT · EDUCATIONAL USE")
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
                    MetadataRow(label: "Repository", value: "The National Archives, Kew")
                    MetadataRow(label: "Reference", value: "SP 63/170, f. 201 questions · f. 202 answers")
                    MetadataRow(label: "Image status", value: "TNA web-resolution f. 201 bundled for free, exclusively educational use")
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
            TNAInterrogatoryFolio(highlightName: showAnnotations)
            if showAnnotations {
                VStack {
                    HStack {
                        AnnotationFlag(text: "HER NAME HEADS THE QUESTIONS", certainty: .documented)
                        Spacer()
                    }
                    .padding(.top, 64)
                    Spacer()
                    HStack {
                        Spacer()
                        AnnotationFlag(text: "18 QUESTIONS SHAPE THE RECORD", certainty: .documented)
                    }
                    .padding(.bottom, 72)
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
