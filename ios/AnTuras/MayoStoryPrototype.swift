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

                Label("Clew Bay editorial landscape · interpretive image", systemImage: "photo")
                    .font(.caption)
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.horizontal, EditorialLayout.pageInset)
                    .padding(.top, 10)

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

private struct OutcomeRow: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.moss)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title.uppercased())
                    .font(.system(size: 9.5, weight: .bold))
                    .kerning(1.1)
                    .foregroundStyle(Theme.inkFaint)
                Text(text)
                    .font(.system(size: 14.5, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(3)
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
