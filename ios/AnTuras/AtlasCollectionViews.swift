import SwiftUI

// MARK: - First encounter takeaway

struct FirstEncounterTakeawayView: View {
    @EnvironmentObject private var atlas: AtlasPrototypeModel
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                AtlasScreenHeader(
                    "THE ISLAND OPENS",
                    "You began with a name.",
                    detail: "Gráinne’s name crossed the sea and entered the record. Yours has entered Irish."
                )

                AtlasCard(accent: Theme.moss) {
                    VStack(alignment: .leading, spacing: 13) {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 25, weight: .light))
                            .foregroundStyle(Theme.moss)
                        Text("Is mise \(atlas.learnerName).")
                            .font(.system(size: 36, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.moss)
                        Text("I am \(atlas.learnerName).")
                            .font(.system(size: 16, design: .serif))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .padding(.vertical, 8)
                }

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "doc.text")
                        .foregroundStyle(Theme.atlasGreen)
                        .frame(width: 24)
                    Text("From a castle at the edge of Clew Bay, Gráinne turned loss into a journey to the centre of English power — and made the state answer her.")
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(Theme.ink)
                        .lineSpacing(4)
                }

                PrimaryButton(title: "Return to Ireland", fullWidth: true) {
                    Haptics.tap()
                    onContinue()
                }
            }
            .padding(20)
            .padding(.bottom, 36)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - An Cnuasach

private enum CollectionShelf: String, CaseIterable, Identifiable {
    case matters = "Matters"
    case survives = "Survives"
    case made = "Made"
    case words = "Words"
    var id: String { rawValue }

    var fullTitle: String {
        switch self {
        case .matters: return "What matters to you"
        case .survives: return "What survives"
        case .made: return "What you made"
        case .words: return "Words you carry"
        }
    }
}

struct AtlasCollectionView: View {
    @EnvironmentObject private var atlas: AtlasPrototypeModel
    @EnvironmentObject private var appState: AppState
    let onOpenEvidence: () -> Void
    let onOpenFieldNote: () -> Void
    var onOpenPersonalSubject: (String) -> Void = { _ in }
    var onOpenPersonalSearch: () -> Void = {}
    @State private var shelf: CollectionShelf = .survives

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AtlasScreenHeader("AN CNUASACH · THE COLLECTION", "Evidence, making, language.", detail: "What survived is never confused with what you made. Saved names and places sit apart under what matters to you.")

                Picker("Collection shelf", selection: $shelf) {
                    ForEach(CollectionShelf.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Group {
                    switch shelf {
                    case .matters: mattersShelf
                    case .survives: survivesShelf
                    case .made: madeShelf
                    case .words: wordsShelf
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 34)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private var mattersShelf: some View {
        VStack(alignment: .leading, spacing: 14) {
            ShelfIntroduction(
                number: appState.savedPersonalSubjects.isEmpty ? "WAITING" : "\(appState.savedPersonalSubjects.count) SAVED",
                text: "Names and places you chose to keep. Separate from historical evidence and from learner-made objects."
            )

            if appState.savedPersonalSubjects.isEmpty {
                Button(action: onOpenPersonalSearch) {
                    AtlasCard(accent: Theme.moss) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nothing saved yet")
                                .font(.system(size: 18, weight: .semibold, design: .serif))
                                .foregroundStyle(Theme.ink)
                            Text("Open the personal atlas and save a name or place that matters.")
                                .font(.system(size: 13.5))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                }
                .buttonStyle(CarvePress())
            } else {
                ForEach(appState.savedPersonalSubjects, id: \.self) { id in
                    if let subject = PersonalAtlasLoader.subject(id: id) {
                        Button {
                            onOpenPersonalSubject(id)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(subject.canonicalDisplay)
                                        .font(.system(size: 17, weight: .semibold, design: .serif))
                                        .foregroundStyle(Theme.ink)
                                    Text(subject.subtitle)
                                        .font(.system(size: 12.5))
                                        .foregroundStyle(Theme.inkSoft)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Theme.inkFaint)
                            }
                            .padding(14)
                            .background(Theme.raised)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(CarvePress())
                    }
                }
            }
        }
    }

    private var survivesShelf: some View {
        VStack(alignment: .leading, spacing: 14) {
            ShelfIntroduction(number: atlas.evidenceInspected ? "1 ENCOUNTERED" : "A SHELF WAITING", text: "Documents, objects, places and recordings retain provenance, certainty and the question they answered.")

            Button(action: onOpenEvidence) {
                EvidenceCollectionCard(unlocked: atlas.evidenceInspected)
            }
            .buttonStyle(CarvePress())

            Button(action: onOpenFieldNote) {
                AtlasCard(accent: Theme.stone) {
                    HStack(spacing: 14) {
                        Image(systemName: "line.diagonal")
                            .font(.system(size: 30, weight: .light))
                            .foregroundStyle(Theme.stone)
                            .frame(width: 48)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack { Text("Breastagh Ogham stone").font(.system(size: 17, weight: .semibold, design: .serif)); CertaintyPill(certainty: .material) }
                            Text(atlas.fieldNoteVisited ? "Field note visited · damaged marks and their limits" : "A field note remains available on the island")
                                .font(.system(size: 12.5)).foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                    }
                }
            }
            .buttonStyle(CarvePress())

            futureEvidence
        }
    }

    private var madeShelf: some View {
        VStack(alignment: .leading, spacing: 14) {
            ShelfIntroduction(number: "YOURS, CLEARLY LABELLED", text: "Traces, recordings, maps and crafted responses belong here — beside evidence, never disguised as it.")
            AtlasCard(accent: Theme.moss) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "signature").font(.system(size: 32, weight: .light)).foregroundStyle(Theme.moss)
                        Spacer()
                        Text("MADE BY YOU").font(.system(size: 9, weight: .bold)).kerning(1.1).foregroundStyle(Theme.moss)
                    }
                    Text(atlas.learnerName.isEmpty ? "Your first Irish introduction" : "Is mise \(atlas.learnerName).")
                        .font(.system(size: 25, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text(atlas.storyCompleted ? "Carried from the Mayo story · reusable anywhere" : "Complete the Mayo story to carry your introduction here.")
                        .font(.system(size: 12.5)).foregroundStyle(Theme.inkSoft)
                }
            }
            AtlasCard(accent: Theme.stone) {
                HStack(spacing: 13) {
                    Image(systemName: "hand.draw").font(.system(size: 27, weight: .light)).foregroundStyle(Theme.stone)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Ogham tracing study").font(.system(size: 17, weight: .semibold, design: .serif)).foregroundStyle(Theme.ink)
                        Text(atlas.fieldNoteVisited ? "Made during the Breastagh reconstruction register." : "Available inside the Breastagh field note.")
                            .font(.system(size: 12.5)).foregroundStyle(Theme.inkSoft)
                    }
                }
            }
        }
    }

    private var wordsShelf: some View {
        VStack(alignment: .leading, spacing: 14) {
            ShelfIntroduction(number: atlas.storyCompleted ? "5 OF 20 · MAYO" : "WORDS BEGIN IN STORIES", text: "Vocabulary is a growing personal map: first encounter, later uses, pronunciation and return state.")
            ForEach(atlas.carriedWords) { word in
                WordCarryCard(word: word, unlocked: atlas.storyCompleted || word.ga == "Is mise…")
            }
            AtlasCard(accent: Theme.inkFaint) {
                HStack(spacing: 12) {
                    Text("20")
                        .font(.system(size: 31, weight: .semibold, design: .serif)).foregroundStyle(Theme.inkFaint)
                    Text("The county promise remains visible without becoming a spreadsheet. The production story would earn and retrieve all twenty useful items.")
                        .font(.system(size: 13)).foregroundStyle(Theme.inkSoft).lineSpacing(3)
                }
            }
        }
    }

    private var futureEvidence: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "STILL AHEAD")
            HStack(spacing: 10) {
                FutureObject(icon: "plus", title: "Cross", place: "Offaly · c. 900")
                FutureObject(icon: "circle", title: "Penny", place: "Dublin · c. 997")
                FutureObject(icon: "envelope", title: "Letter", place: "Galway · 1840s")
            }
        }
        .padding(.top, 8)
    }
}

private struct ShelfIntroduction: View {
    let number: String
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Eyebrow(text: number)
            Text(text).font(.system(size: 14)).foregroundStyle(Theme.inkSoft).lineSpacing(3)
        }
        .padding(.vertical, 4)
    }
}

private struct EvidenceCollectionCard: View {
    let unlocked: Bool
    var body: some View {
        AtlasCard(accent: unlocked ? Theme.lichen : Theme.stone) {
            HStack(spacing: 15) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4).fill(Color(light: 0xD9C99E, dark: 0x76694C))
                    VStack(spacing: 5) {
                        ForEach(0..<6, id: \.self) { i in
                            Rectangle().fill(Theme.ink.opacity(0.35)).frame(width: CGFloat(28 + (i % 2) * 7), height: 1)
                        }
                    }
                }
                .frame(width: 70, height: 92)
                VStack(alignment: .leading, spacing: 5) {
                    HStack { CertaintyPill(certainty: .documented); Spacer() }
                    Text("1593 state-paper record")
                        .font(.system(size: 19, weight: .semibold, design: .serif)).foregroundStyle(Theme.ink)
                    Text(unlocked ? "Mayo · Gráinne Ní Mháille · explanatory facsimile inspected" : "Encounter it inside the Mayo documentary")
                        .font(.system(size: 12.5)).foregroundStyle(Theme.inkSoft).lineSpacing(3)
                    Text("Question · What did she ask for?")
                        .font(.system(size: 11.5, weight: .semibold)).foregroundStyle(Theme.lichen)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
            }
        }
    }
}

private struct FutureObject: View {
    let icon: String
    let title: String
    let place: String
    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon).font(.system(size: 25, weight: .ultraLight)).foregroundStyle(Theme.stone)
            Text(title).font(.system(size: 13, weight: .semibold, design: .serif)).foregroundStyle(Theme.ink)
            Text(place).font(.system(size: 8.5)).foregroundStyle(Theme.inkFaint).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 110)
        .background(Theme.sunk)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line, style: StrokeStyle(lineWidth: 0.8, dash: [3, 4])))
    }
}

private struct WordCarryCard: View {
    let word: AtlasWord
    let unlocked: Bool
    @State private var expanded = false
    var body: some View {
        Button {
            guard unlocked else { return }
            Haptics.tap()
            withAnimation(Motion.settle) { expanded.toggle() }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(unlocked ? word.ga : "••••")
                        .font(.system(size: 22, weight: .semibold, design: .serif)).foregroundStyle(unlocked ? Theme.moss : Theme.inkFaint)
                    Text(unlocked ? word.en : "carried after the story")
                        .font(.system(size: 12.5)).foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Image(systemName: unlocked ? (expanded ? "chevron.up" : "chevron.down") : "lock")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.inkFaint)
                }
                if expanded && unlocked {
                    AtlasRule()
                    Text("rough sound · \(word.sound)").font(.system(size: 11.5, weight: .medium)).foregroundStyle(Theme.inkFaint)
                    Label(word.anchor, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 12.5)).foregroundStyle(Theme.inkSoft)
                }
            }
            .padding(15)
            .background(Theme.raised)
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(Theme.line, lineWidth: 0.8))
        }
        .buttonStyle(CarvePress())
    }
}

// MARK: - Ar Ais

struct AtlasReturnView: View {
    @EnvironmentObject private var atlas: AtlasPrototypeModel
    let onOpenEvidence: () -> Void
    @State private var answer = ""
    @State private var pennyRestored = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AtlasScreenHeader("AR AIS · RETURN", atlas.returnAnswered ? "The groove is clear again." : "Return to meaning, not task debt.", detail: "People, places, phrases and sources reappear when a new connection can make them sharper.")

                if atlas.storyCompleted {
                    phraseReturn
                } else {
                    AtlasCard(accent: Theme.atlasGreen) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Nothing is overdue.")
                                .font(.system(size: 24, weight: .semibold, design: .serif)).foregroundStyle(Theme.ink)
                            Text("Complete the Mayo documentary and this place will remember the phrase, question and evidence you carried out.")
                                .font(.system(size: 14.5)).foregroundStyle(Theme.inkSoft).lineSpacing(4)
                        }
                    }
                }

                evidenceReturn
                futureReturn
            }
            .padding(20)
            .padding(.bottom, 34)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private var phraseReturn: some View {
        AtlasCard(accent: Theme.moss) {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    Eyebrow(text: "A NEW INTRODUCTION", color: Theme.moss)
                    Spacer()
                    Text("FROM MAYO").font(.system(size: 9, weight: .bold)).kerning(1).foregroundStyle(Theme.inkFaint)
                }
                Text("You meet someone on the next road. Say who you are.")
                    .font(.system(size: 19, weight: .semibold, design: .serif)).foregroundStyle(Theme.ink)
                TextField("Is mise…", text: $answer)
                    .textInputAutocapitalization(.sentences)
                    .font(.system(size: 18, design: .serif))
                    .padding(13)
                    .background(Theme.bg)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                if atlas.returnAnswered {
                    Text("Tá tú ar ais · the phrase now belongs to another meeting.")
                        .font(.system(size: 13.5, weight: .semibold, design: .serif)).foregroundStyle(Theme.moss)
                } else {
                    PrimaryButton(title: "Say it") {
                        let normalized = answer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                        if normalized.hasPrefix("is mise") {
                            atlas.returnAnswered = true
                            Haptics.chisel()
                        } else { Haptics.error() }
                    }
                }
            }
        }
    }

    private var evidenceReturn: some View {
        Button(action: onOpenEvidence) {
            AtlasCard(accent: Theme.lichen) {
                HStack(spacing: 14) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 30, weight: .light)).foregroundStyle(Theme.lichen).frame(width: 46)
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow(text: "SOURCE RETURN", color: Theme.lichen)
                        Text("Which claim did the 1593 record support?")
                            .font(.system(size: 17, weight: .semibold, design: .serif)).foregroundStyle(Theme.ink)
                        Text("Open the evidence beside the later account again.")
                            .font(.system(size: 12.5)).foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                }
            }
        }
        .buttonStyle(CarvePress())
    }

    private var futureReturn: some View {
        AtlasCard(accent: Theme.stone) {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    Eyebrow(text: "A FUTURE CONNECTION")
                    Spacer()
                    CertaintyPill(certainty: .material)
                }
                Text("Sihtric’s penny has lost part of its legend.")
                    .font(.system(size: 19, weight: .semibold, design: .serif)).foregroundStyle(Theme.ink)
                HStack(spacing: 3) {
                    ForEach(Array("SITRIC REX DUBLIN".enumerated()), id: \.offset) { index, character in
                        Text(pennyRestored || index % 5 != 2 ? String(character) : "·")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced)).foregroundStyle(Theme.inkSoft)
                    }
                }
                .padding(12)
                .background(Theme.sunk)
                .clipShape(Capsule())
                Button(pennyRestored ? "Legend restored" : "Preview the return interaction") {
                    pennyRestored = true
                    Haptics.tick()
                }
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(Theme.moss)
                .buttonStyle(CarvePress())
            }
        }
    }
}
