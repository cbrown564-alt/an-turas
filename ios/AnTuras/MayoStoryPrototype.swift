import SwiftUI

// MARK: - Mayo editorial dossier

struct MayoDossierView: View {
    let onMeetGrainne: () -> Void
    let onBegin: () -> Void
    let onFieldNote: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AtlasScreenHeader("CONNACHT · MAIGH EO", "Mayo", detail: "Listen: Maigh Eo · ‘plain of the yew trees’")

                ClewBayMiniature()
                    .frame(height: 270)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 0.8))

                HStack(spacing: 8) {
                    CertaintyPill(certainty: .documented)
                    Text("1593 · document · person · sea route")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(Theme.inkFaint)
                }

                Button(action: onMeetGrainne) {
                    HStack(spacing: 16) {
                        GrainnePortraitMark()
                            .frame(width: 86, height: 104)
                        VStack(alignment: .leading, spacing: 5) {
                            Eyebrow(text: "THE HEADLINE PERSON", color: Theme.atlasGreen)
                            Text("Gráinne Ní Mháille")
                                .font(.system(size: 24, weight: .semibold, design: .serif))
                                .foregroundStyle(Theme.ink)
                            Text("A maritime leader from Mayo whose dealings with the English state left a documentary record.")
                                .font(.system(size: 13.5))
                                .foregroundStyle(Theme.inkSoft)
                                .lineSpacing(3)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                    }
                    .padding(15)
                    .background(Theme.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(CarvePress())

                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "THE HISTORICAL QUESTION")
                    Text("What did Gráinne actually ask for?")
                        .font(.system(size: 30, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text("Begin with the state record. Only then compare the famous image of the ‘pirate queen’ with what can be supported.")
                        .font(.system(size: 15.5))
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(4)
                }
                .padding(.vertical, 4)

                HStack(alignment: .top, spacing: 12) {
                    DossierPromise(icon: "doc.text.magnifyingglass", eyebrow: "WHAT SURVIVES", text: "A 1593 state-paper trail concerning Gráinne and members of her family.", accent: Theme.lichen)
                    DossierPromise(icon: "quote.bubble", eyebrow: "WHAT YOU CAN SAY", text: "Identify yourself: Is mise… Then say your name and where you are from.", accent: Theme.moss)
                }

                routeSection

                SourceFooter()

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
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.inkFaint)
                .lineSpacing(3)
        }
        .padding(15)
        .background(Theme.sunk)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct DossierPromise: View {
    let icon: String
    let eyebrow: String
    let text: String
    let accent: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: icon).font(.system(size: 23, weight: .light)).foregroundStyle(accent)
            Eyebrow(text: eyebrow, color: accent)
            Text(text)
                .font(.system(size: 13.5, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .bottom, spacing: 18) {
                    GrainnePortraitMark().frame(width: 130, height: 170)
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow(text: "PERSON · MAYO · 16TH CENTURY")
                        Text("Gráinne Ní Mháille")
                            .font(.system(size: 31, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.ink)
                        Text("Grace O’Malley")
                            .font(.system(size: 16, design: .serif))
                            .foregroundStyle(Theme.inkSoft)
                        Text("c. 1530 – c. 1603")
                            .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.inkFaint)
                    }
                }

                AtlasAudioLine(ga: "Gráinne Ní Mháille", en: "A Connacht Irish name form", sound: "grawn-ya nee wawl-ya")

                AtlasCard(accent: Theme.atlasGreen) {
                    VStack(alignment: .leading, spacing: 9) {
                        CertaintyPill(certainty: .documented)
                        Text("A maritime leader with power rooted around the Mayo coast; English administrative records preserve dealings concerning her and her family.")
                            .font(.system(size: 15.5, design: .serif))
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
                    Eyebrow(text: "CLAIMS THIS PROTOTYPE DOES NOT MAKE", color: Theme.rust)
                    ClaimBoundary(text: "That she refused to bow to Elizabeth I.")
                    ClaimBoundary(text: "That Latin was certainly the language of their meeting.")
                    ClaimBoundary(text: "That the familiar hair-cutting story is a documented origin for her name.")
                    Text("These popular claims require source-specific support before they can enter factual narration.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(16)
                .background(Theme.rustTint)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                SourceFooter()
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
}

private struct GrainnePortraitMark: View {
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
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "xmark.circle").font(.system(size: 12)).foregroundStyle(Theme.rust).padding(.top, 2)
            Text(text).font(.system(size: 13.5, design: .serif)).foregroundStyle(Theme.ink)
        }
    }
}

// MARK: - Documentary story registers

struct GrainneStoryView: View {
    @EnvironmentObject private var atlas: AtlasPrototypeModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onInspectEvidence: () -> Void
    let onComplete: () -> Void

    @State private var step = 0
    @State private var documentZoom: Double = 1
    @State private var showAnnotations = true
    @State private var chosenClaim: String?

    private let stepNames = ["Cold open", "Person", "Place", "Evidence", "Source reading", "Certainty", "Language", "Afterlife"]

    var body: some View {
        VStack(spacing: 0) {
            storyChrome
            ScrollView {
                Group {
                    switch step {
                    case 0: coldOpen
                    case 1: personRegister
                    case 2: placeRegister
                    case 3: evidenceRegister
                    case 4: sourceReading
                    case 5: certaintyRegister
                    case 6: languageRegister
                    default: afterlifeRegister
                    }
                }
                .id(step)
                .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                .padding(20)
                .padding(.bottom, 100)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { storyControls }
    }

    private var storyChrome: some View {
        VStack(spacing: 7) {
            HStack {
                Text("\(step + 1) / \(stepNames.count)")
                Spacer()
                Text(stepNames[step].uppercased())
            }
            .font(.system(size: 9.5, weight: .bold))
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
    }

    private var storyControls: some View {
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
            }
            PrimaryButton(title: step == stepNames.count - 1 ? "Carry it into the collection" : nextTitle, fullWidth: true) {
                if step == stepNames.count - 1 { onComplete() }
                else { move(to: step + 1) }
            }
            .disabled(step == 6 && atlas.learnerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(step == 6 && atlas.learnerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var nextTitle: String {
        switch step {
        case 0: return "Meet Gráinne"
        case 1: return "Follow the coast"
        case 2: return "Open the evidence"
        case 3: return "Read the record"
        case 4: return "Test the claims"
        case 5: return "Use your first Irish"
        default: return "See what survives now"
        }
    }

    private func move(to newStep: Int) {
        Haptics.tap()
        withAnimation(reduceMotion ? .linear(duration: 0.15) : Motion.settle) { step = newStep }
    }

    private var coldOpen: some View {
        VStack(alignment: .leading, spacing: 22) {
            ZStack(alignment: .bottomLeading) {
                ClewBayMiniature().frame(height: 350)
                LinearGradient(colors: [.clear, Color.black.opacity(0.72)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 4) {
                    Text("MAYO · 1593")
                        .font(.system(size: 11, weight: .bold)).kerning(1.7)
                    Text("The invitation")
                        .font(.system(size: 34, weight: .semibold, design: .serif))
                    Text("A leader leaves the western coast for the centre of English power.")
                        .font(.system(size: 14.5)).lineSpacing(3)
                }
                .foregroundStyle(.white)
                .padding(20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("What did she ask for?")
                .font(.system(size: 33, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            Text("Not what later storytellers wanted her to have asked. Not what a dramatic reconstruction might put in her mouth. Begin with the thing that survives.")
                .font(.system(size: 17, design: .serif))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(5)
            CertaintyPill(certainty: .documented)
        }
    }

    private var personRegister: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .bottom, spacing: 18) {
                GrainnePortraitMark().frame(width: 145, height: 190)
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(text: "A NAMED PERSON")
                    Text("Gráinne\nNí Mháille")
                        .font(.system(size: 34, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text("c. 1530 – c. 1603")
                        .font(.system(size: 12.5, design: .monospaced))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
            AtlasAudioLine(ga: "Gráinne Ní Mháille", en: "Her name in Irish", sound: "grawn-ya nee wawl-ya")
            Text("Her consequences reach beyond biography: family power, coastal lordship and negotiations with a state extending its control into Connacht.")
                .font(.system(size: 17, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineSpacing(5)
            HStack { CertaintyPill(certainty: .documented); CertaintyPill(certainty: .later) }
            Text("This is an interpretive mark, not a surviving portrait. The interface names that boundary instead of letting atmosphere impersonate evidence.")
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private var placeRegister: some View {
        VStack(alignment: .leading, spacing: 18) {
            AtlasScreenHeader("PLACE · CAUSAL GEOGRAPHY", "Power had a coastline.", detail: "Clew Bay was not scenery behind Gráinne’s story. Islands, water and strongholds shaped movement and authority.")
            ClewBayMiniature().frame(height: 360).clipShape(RoundedRectangle(cornerRadius: 14))
            AtlasCard(accent: Theme.atlasGold) {
                VStack(alignment: .leading, spacing: 9) {
                    Text("Trace the route with your finger.")
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                    Text("Clare Island → Kildavnet → Rockfleet")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.atlasGold)
                    Text("The line connects story places; it does not claim one documented journey in this exact sequence.")
                        .font(.system(size: 12.5)).foregroundStyle(Theme.inkSoft)
                }
            }
        }
    }

    private var evidenceRegister: some View {
        VStack(alignment: .leading, spacing: 18) {
            AtlasScreenHeader("EVIDENCE · WHAT SURVIVES", "A state paper, not a legend.", detail: "Zoom the explanatory facsimile and reveal the editorial annotations. The final product would use a cleared image or historian-approved transcription.")
            PetitionInspectionPanel(zoom: $documentZoom, showAnnotations: $showAnnotations)
            SourceFooter(compact: true)
            Button {
                atlas.evidenceInspected = true
                onInspectEvidence()
            } label: {
                Label("Open the full evidence inspector", systemImage: "viewfinder")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.moss)
            }
            .buttonStyle(CarvePress())
            .onAppear { atlas.evidenceInspected = true }
        }
    }

    private var sourceReading: some View {
        VStack(alignment: .leading, spacing: 20) {
            AtlasScreenHeader("SOURCE READING", "Read what the record can carry.", detail: "This prototype paraphrases the source packet rather than presenting an uncleared transcription.")
            VStack(alignment: .leading, spacing: 0) {
                SourceLine(number: "01", text: "The record identifies Gráinne Ní Mháille and members of her family.", certainty: .documented)
                SourceLine(number: "02", text: "It concerns requests for state action affecting her and those family members.", certainty: .documented)
                SourceLine(number: "03", text: "The exact learner-facing wording and list of requests must follow historian review of the selected document.", certainty: .unknown)
            }
            .background(Theme.raised)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            Text("The important change is methodological: the learner sees the limits of the current packet instead of receiving invented precision.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(5)
        }
    }

    private var certaintyRegister: some View {
        VStack(alignment: .leading, spacing: 18) {
            AtlasScreenHeader("CERTAINTY · CLAIM BY CLAIM", "Which account are you looking at?", detail: "Choose a claim. The interface responds with its evidence register, not a generic disclaimer.")
            ClaimChoice(text: "A 1593 record concerns Gráinne and her family.", selected: chosenClaim == "record", certainty: .documented) { chosenClaim = "record" }
            ClaimChoice(text: "She was known simply as Ireland’s ‘pirate queen.’", selected: chosenClaim == "queen", certainty: .later) { chosenClaim = "queen" }
            ClaimChoice(text: "She refused to bow before Elizabeth I.", selected: chosenClaim == "bow", certainty: .disputed) { chosenClaim = "bow" }
            if let chosenClaim {
                AtlasCard(accent: chosenClaim == "record" ? Theme.atlasGreen : Theme.rust) {
                    Text(explanation(for: chosenClaim))
                        .font(.system(size: 15, design: .serif))
                        .foregroundStyle(Theme.ink)
                        .lineSpacing(4)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
    }

    private func explanation(for id: String) -> String {
        switch id {
        case "record": return "Documented: the state-paper record is the secure centre of this encounter. Final copy still needs a historian-approved document selection."
        case "queen": return "Later account: the famous image can be studied as an afterlife, but it is not the same thing as the language or categories of the 1593 record."
        default: return "Disputed / unsupported here: this prototype deliberately does not narrate the bowing story as fact without source-specific support."
        }
    }

    private var languageRegister: some View {
        VStack(alignment: .leading, spacing: 20) {
            AtlasScreenHeader("LANGUAGE LENS", "The story turns toward you.", detail: "You do not become a historical character. You use Irish now, as yourself, to answer the first question any dossier asks: who are you?")
            AtlasAudioLine(ga: "Is mise…", en: "I am… / I’m…", sound: "iss mish-eh")
            VStack(alignment: .leading, spacing: 9) {
                Text("Cén t-ainm atá ort?")
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text("What is your name?")
                    .font(.system(size: 12.5)).foregroundStyle(Theme.inkFaint)
                TextField("Your name", text: $atlas.learnerName)
                    .textInputAutocapitalization(.words)
                    .font(.system(size: 21, design: .serif))
                    .padding(14)
                    .background(Theme.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line, lineWidth: 0.8))
            }
            if !atlas.learnerName.trimmingCharacters(in: .whitespaces).isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(text: "TUSA · YOU")
                    Text("Is mise \(atlas.learnerName).")
                        .font(.system(size: 32, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.moss)
                    Text("This phrase leaves the story with you. It belongs in introductions anywhere, not only in Mayo.")
                        .font(.system(size: 13.5)).foregroundStyle(Theme.inkSoft)
                }
                .padding(18)
                .background(Theme.mossTint)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private var afterlifeRegister: some View {
        VStack(alignment: .leading, spacing: 20) {
            AtlasScreenHeader("AFTERLIFE · MAYO NOW", "The coast remains.", detail: "The story returns to real places, surviving records and the language you can carry beyond them.")
            ClewBayMiniature().frame(height: 280).clipShape(RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 12) {
                OutcomeRow(icon: "person.crop.circle", title: "Who you met", text: "Gráinne Ní Mháille, a maritime leader from Mayo.")
                OutcomeRow(icon: "doc.text", title: "What you examined", text: "An explanatory prototype for a 1593 state-paper record.")
                OutcomeRow(icon: "checkmark.seal", title: "What remains uncertain", text: "The exact final document reading and several famous later claims.")
                OutcomeRow(icon: "quote.bubble", title: "What you can use", text: "Is mise \(atlas.learnerName.isEmpty ? "…" : atlas.learnerName).")
            }
            Text("Next, the road rewinds to Offaly, c. 900 — so the long chronological journey can begin.")
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.atlasGreen)
                .lineSpacing(4)
        }
    }
}

private struct SourceLine: View {
    let number: String
    let text: String
    let certainty: EvidenceCertainty
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number).font(.system(size: 11, design: .monospaced)).foregroundStyle(Theme.inkFaint)
            VStack(alignment: .leading, spacing: 8) {
                Text(text).font(.system(size: 16, design: .serif)).foregroundStyle(Theme.ink).lineSpacing(4)
                CertaintyPill(certainty: certainty)
            }
        }
        .padding(16)
        .overlay(alignment: .bottom) { AtlasRule() }
    }
}

private struct ClaimChoice: View {
    let text: String
    let selected: Bool
    let certainty: EvidenceCertainty
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? certainty.color : Theme.inkFaint)
                VStack(alignment: .leading, spacing: 8) {
                    Text(text).font(.system(size: 15, design: .serif)).foregroundStyle(Theme.ink).multilineTextAlignment(.leading)
                    CertaintyPill(certainty: certainty)
                }
                Spacer(minLength: 0)
            }
            .padding(15)
            .background(selected ? certainty.color.opacity(0.10) : Theme.raised)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(selected ? certainty.color : Theme.line, lineWidth: 0.8))
        }
        .buttonStyle(CarvePress())
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
                AtlasScreenHeader("WHAT SURVIVES · DOCUMENT", "The 1593 record", detail: "An evidence object keeps provenance, rights state, certainty and the question it helped answer.")
                HStack { CertaintyPill(certainty: .documented); Text("EXPLANATORY FACSIMILE · NOT THE SOURCE IMAGE").font(.system(size: 9, weight: .bold)).kerning(1).foregroundStyle(Theme.inkFaint) }
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
                    MetadataRow(label: "Rights", value: "No manuscript image bundled; clearance pending")
                    MetadataRow(label: "Historical review", value: "Required before public-release copy")
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
        .navigationTitle("Evidence inspector")
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
            Toggle("Show editorial annotations", isOn: $showAnnotations)
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
                Text("1593 · EXPLANATORY FACSIMILE")
                    .font(.system(size: 10, weight: .bold, design: .serif)).kerning(1.5).foregroundStyle(Color.black.opacity(0.58))
                    .padding(.top, 24)
                Spacer()
                Text("No source image reproduced")
                    .font(.system(size: 9, weight: .medium)).foregroundStyle(Color.black.opacity(0.48)).padding(.bottom, 20)
            }
            if showAnnotations {
                VStack {
                    HStack {
                        AnnotationFlag(text: "NAME / IDENTITY", certainty: .documented)
                        Spacer()
                    }
                    .padding(.top, 80)
                    Spacer()
                    HStack {
                        Spacer()
                        AnnotationFlag(text: "REQUESTS / FAMILY", certainty: .documented)
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
