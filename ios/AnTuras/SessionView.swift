import SwiftUI

// MARK: - Session as pages
// A session reads as a sequence of authored pages, turned by swiping — the
// page turn replaces "Ar aghaidh" everywhere in narrative. Exercises gate the
// turn: pages beyond an unsolved exercise simply don't exist yet, so the swipe
// rubber-bands off the wall (with a dull knock). Solving carves the stroke and
// the page turns itself. The next page is trailed as faint chalk marks — the
// carver chalks before he cuts.
//
// Each register composes its page differently:
//   scene    — a book page: content sits at the optical centre; spoken Irish
//              is the hero, set large against a carved groove.
//   note     — a manual page: lichen-washed, top-anchored like a chapter start.
//   exercise — the hand on the chisel: no container, the tappable elements are
//              the raised objects; a register mark of chalk strokes up top.
//   feature  — inscription, seanfhocal, artifact, fin: stand-alone moments.

final class SessionVM: ObservableObject {
    let session: Session
    let sessionIndex: Int

    @Published var currentPage: Int?
    @Published var solved: Set<Int> = []
    @Published var finished = false

    var initialPage = 0

    var pages: [Page] { session.pages }
    var exercisesTotal: Int { session.exerciseCount }
    /// Index of the synthetic completion page, one past the content pages.
    var completionIndex: Int { pages.count }

    init(session: Session, sessionIndex: Int) {
        self.session = session
        self.sessionIndex = sessionIndex
        // Debug: --reveal N jumps to page N, pre-solving exercises before it.
        let args = ProcessInfo.processInfo.arguments
        if let flagIndex = args.firstIndex(of: "--reveal"),
           args.indices.contains(flagIndex + 1),
           let target = Int(args[flagIndex + 1]) {
            for index in pages.indices.prefix(min(target, pages.count))
            where pages[index].isExercise {
                solved.insert(index)
            }
            initialPage = min(max(target, 0), completionIndex)
        }
    }

    func isPageSolved(_ page: Int) -> Bool {
        guard pages.indices.contains(page) else { return true }
        return !pages[page].isExercise || solved.contains(page)
    }

    /// The furthest page that exists right now: everything up to (and including)
    /// the first unsolved exercise page, or the completion page if none remain.
    var furthestUnlocked: Int {
        for page in pages.indices where !isPageSolved(page) { return page }
        return completionIndex
    }
}

struct SessionView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var vm: SessionVM
    @State private var activeGloss: Gloss?
    @State private var visited: Set<Int> = []
    @State private var launched = false

    init(chapter: Chapter, sessionIndex: Int) {
        let session = chapter.sessions[sessionIndex]
        _vm = StateObject(wrappedValue:
            SessionVM(session: session, sessionIndex: sessionIndex))
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(0...vm.furthestUnlocked, id: \.self) { page in
                    pageView(page)
                        .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $vm.currentPage)
        .scrollIndicators(.hidden)
        .modifier(OverscrollKnock(active: vm.furthestUnlocked < vm.completionIndex))
        .onAppear {
            guard !launched else { return }
            launched = true
            visited.insert(vm.initialPage)
            vm.currentPage = vm.initialPage
        }
        .onChange(of: vm.currentPage) { old, new in
            guard let new else { return }
            visited.insert(new)
            if let old, old != new { Haptics.tick() }   // the page settles
            if new == vm.completionIndex, !vm.finished {
                vm.finished = true
                if !state.done[vm.sessionIndex] { state.markDone(vm.sessionIndex) }
                Haptics.flourish()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                CarveBarView(total: vm.exercisesTotal, done: vm.solved.count)
                    .frame(width: 170)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Text("Seisiún \(vm.sessionIndex + 1)")
                    .font(.system(size: 11, weight: .semibold))
                    .kerning(1.2)
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .sheet(item: $activeGloss) { GlossSheet(gloss: $0) }
    }

    // MARK: - Pages

    @ViewBuilder
    private func pageView(_ page: Int) -> some View {
        ZStack {
            // Pages render on first visit, so a freshly turned page inks itself
            // in — and inscriptions don't carve while offscreen.
            if visited.contains(page) {
                if page == vm.completionIndex {
                    CompletionPage(sessionIndex: vm.sessionIndex,
                                   hook: vm.session.hook) {
                        Haptics.tap()
                        state.advanceToNextChapterIfNeeded()
                        dismiss()
                    }
                } else {
                    contentPage(page)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func contentPage(_ page: Int) -> some View {
        PageScaffold(register: vm.pages[page].register) {
            pageBody(page)
        }
        .overlay(alignment: .bottomTrailing) {
            if let label = teaseLabel(after: page) {
                ChalkTease(label: label)
            }
        }
    }

    @ViewBuilder
    private func pageBody(_ page: Int) -> some View {
        switch vm.pages[page] {
        case .scene(let scene):
            // Scene beats stagger in individually; other registers rise whole.
            ScenePageView(page: scene, activeGloss: $activeGloss)
        case .note(let note):
            NotePageView(note: note)
                .modifier(RiseIn(order: 0, reduceMotion: reduceMotion))
        case .choice(let choice):
            ChoiceView(block: choice, onSolved: { solved(page) })
                .modifier(RiseIn(order: 0, reduceMotion: reduceMotion))
        case .assemble(let assemble):
            AssembleView(block: assemble, onSolved: { solved(page) })
                .modifier(RiseIn(order: 0, reduceMotion: reduceMotion))
        case .typein(let typein):
            TypeInView(block: typein, onSolved: { solved(page) })
                .modifier(RiseIn(order: 0, reduceMotion: reduceMotion))
        case .match(let match):
            MatchView(block: match, onSolved: { solved(page) })
                .modifier(RiseIn(order: 0, reduceMotion: reduceMotion))
        case .listen(let listen):
            ListenView(block: listen, onSolved: { solved(page) })
                .modifier(RiseIn(order: 0, reduceMotion: reduceMotion))
        case .echo(let echo):
            EchoView(block: echo, activeGloss: $activeGloss, onSolved: { solved(page) })
                .modifier(RiseIn(order: 0, reduceMotion: reduceMotion))
        case .turn(let turn):
            // The reaction deserves reading at the learner's pace: the stroke
            // is earned on speaking, but the page waits to be turned by hand.
            TurnView(block: turn, activeGloss: $activeGloss,
                     onSolved: { solved(page, autoTurn: false) })
        case .recarve(let recarve):
            RecarveView(block: recarve, onSolved: { solved(page) })
                .modifier(RiseIn(order: 0, reduceMotion: reduceMotion))
        case .lens(let lens):
            LensView(block: lens)
                .modifier(RiseIn(order: 0, reduceMotion: reduceMotion))
        case .inscription(let inscription):
            InscriptionPageView(block: inscription)
                .modifier(RiseIn(order: 0, reduceMotion: reduceMotion))
        case .seanfhocal(let seanfhocal):
            SeanfhocalPageView(block: seanfhocal)
                .modifier(RiseIn(order: 0, reduceMotion: reduceMotion))
        case .artifact:
            ArtifactView(chapterN: state.chapterN)
                .modifier(RiseIn(order: 0, reduceMotion: reduceMotion))
        case .fin(let fin):
            FinPageView(block: fin)
                .modifier(RiseIn(order: 0, reduceMotion: reduceMotion))
        }
    }

    /// What the chalk marks trail: the next page's nature, if it exists yet.
    private func teaseLabel(after page: Int) -> String? {
        let next = page + 1
        guard next <= vm.furthestUnlocked else { return nil }
        guard next < vm.completionIndex else { return "críoch" }
        switch vm.pages[next] {
        case .scene:        return "an scéal"
        case .note:         return "nóta gramadaí"
        case .choice, .assemble, .typein, .match:
                            return "cleachtadh"
        case .listen:       return "éist"
        case .echo:         return "abair é"
        case .turn:         return "do líne"
        case .recarve:      return "athsnoí"
        case .lens:         return "logainm"
        case .inscription:  return "an chloch"
        case .seanfhocal:   return "seanfhocal"
        case .artifact:     return "déantán"
        case .fin:          return "críoch"
        }
    }

    private func solved(_ page: Int, autoTurn: Bool = true) {
        Haptics.chisel()
        withAnimation(Motion.pop) {
            _ = vm.solved.insert(page)
        }
        guard autoTurn else { return }
        // Let the verdict land, then the page turns itself.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak vm] in
            guard let vm, vm.currentPage == page, vm.isPageSolved(page) else { return }
            withAnimation(.easeInOut(duration: 0.5)) {
                vm.currentPage = page + 1
            }
        }
    }
}

// MARK: - Page scaffold
// One composition engine for all pages: a readable column, register-specific
// vertical placement, and room at the foot for the chalk tease. Centred
// registers carry more padding below than above, so the content sits at the
// optical centre — slightly high, like text on a well-set title page.

private struct PageScaffold<Content: View>: View {
    let register: PageRegister
    @ViewBuilder var content: () -> Content

    private var centred: Bool { register != .note }

    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 0) { content() }
                    .frame(maxWidth: 560, alignment: .leading)
                    .padding(.horizontal, 26)
                    .padding(.top, centred ? 24 : max(geo.size.height * 0.08, 36))
                    .padding(.bottom, centred ? 104 : 90)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: centred ? geo.size.height : nil)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background {
            if register == .note {
                Theme.lichen.opacity(0.05).ignoresSafeArea()
            }
        }
    }
}

/// Staggered entrance for a freshly turned page: rows settle like dust.
struct RiseIn: ViewModifier {
    let order: Int
    let reduceMotion: Bool
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 14)
            .onAppear {
                withAnimation(reduceMotion
                    ? .easeOut(duration: 0.2)
                    : Motion.rise.delay(Double(order) * 0.12)) { shown = true }
            }
    }
}

// MARK: - Scene pages
// Narration and speech are different materials: narration is set as quiet
// serif prose; Irish said aloud is the hero — speaker, the line at display
// size against a carved groove, the rough sound beneath. Tap for the meaning.

struct IllustrationView: View {
    let branch: String?
    let name: String

    var body: some View {
        if let uiImage = loadImage() {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1.5)
                .padding(.vertical, 4)
        } else {
            // Graceful fallback if image is missing
            Text("Missing illustration: \(branch ?? "default")/\(name)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
        }
    }

    private func loadImage() -> UIImage? {
        if let branch = branch {
            let folder: String
            switch branch.lowercased() {
            case "b1", "b1-gearrtha": folder = "b1-gearrtha"
            case "b2", "b2-cailc":     folder = "b2-cailc"
            case "b3", "b3-clo":       folder = "b3-clo"
            case "b4", "b4-solas":     folder = "b4-solas"
            case "b5", "b5-scath":     folder = "b5-scath"
            case "b6", "b6-lamh":      folder = "b6-lamh"
            default:                   folder = branch
            }
            if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "art-exploration/\(folder)") {
                return UIImage(contentsOfFile: url.path)
            }
        } else {
            // Load from canonical default art bundle
            if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "art") {
                return UIImage(contentsOfFile: url.path)
            }
        }
        return nil
    }
}

private struct ScenePageView: View {
    let page: ScenePage
    @Binding var activeGloss: Gloss?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            if let place = page.place {
                Slugline(text: place)
                    .padding(.bottom, 6)
                    .modifier(RiseIn(order: 0, reduceMotion: reduceMotion))
            }
            
            if let imageName = activeImageName {
                IllustrationView(branch: state.artBranch, name: imageName)
                    .modifier(RiseIn(order: 1, reduceMotion: reduceMotion))
            }

            ForEach(Array(page.beats.enumerated()), id: \.offset) { index, beat in
                beatView(beat)
                    .modifier(RiseIn(order: index + (page.place == nil ? 0 : 1) + (activeImageName != nil ? 1 : 0),
                                     reduceMotion: reduceMotion))
            }
        }
    }

    @ViewBuilder
    private func beatView(_ beat: Beat) -> some View {
        BeatRow(beat: beat, activeGloss: $activeGloss)
    }

    private var activeImageName: String? {
        if state.artBranch != nil {
            // Revert to old debug lookup if a specific art override is requested
            if page.place == "Maigh Eo · c. 480 AD" {
                return "t1-pillar"
            } else if page.beats.contains(where: {
                switch $0 {
                case .narration(let n): return n.n.contains("Bríd runs her thumb")
                default: return false
                }
            }) {
                return "t2-hands"
            } else if page.place == "An trá — the strand, morning" {
                return "t3-strand"
            } else if page.place == "Breastagh · fifteen centuries later" {
                return "t4-today"
            }
            return nil
        } else {
            // Default canonical behavior: read image directly from the page
            return page.image
        }
    }
}

// Slugline and SpeechBeatView live in Beats.swift — echo pages and dialogue
// turns set the same type a scene does.

// MARK: - Note pages
// The manual register: a lichen-washed page (applied by the scaffold), title
// set as a proper heading, example pairs as a specimen block on a hanging rule.

private struct NotePageView: View {
    let note: NoteBlock
    @State private var unusedGloss: Gloss?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "An Nóta Gramadaí", color: Theme.lichen)
                Text(note.title)
                    .font(.system(size: 23, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(3)
            }
            .padding(.bottom, 8)
            ForEach(Array(note.paras.enumerated()), id: \.offset) { index, para in
                GlossText(markdown: para, glosses: [], activeGloss: $unusedGloss,
                          font: .system(size: 15.5), lineSpacing: 5)
                    .foregroundStyle(Theme.ink)
                // Example pairs sit after the second-to-last paragraph: the
                // last paragraph reads as a kicker under the specimens.
                if index == max(note.paras.count - 2, 0), let pairs = note.pairs {
                    specimenBlock(pairs)
                }
            }
        }
    }

    private func specimenBlock(_ pairs: [String]) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(pairs, id: \.self) { line in
                GlossText(markdown: line, glosses: [], activeGloss: $unusedGloss,
                          font: .system(size: 17.5, design: .serif), lineSpacing: 4)
                    .foregroundStyle(Theme.ink)
            }
        }
        .padding(.leading, 14)
        .padding(.vertical, 4)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Theme.lichen.opacity(0.55))
                .frame(width: 2)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Feature pages

private struct InscriptionPageView: View {
    let block: InscriptionBlock

    var body: some View {
        VStack(spacing: 18) {
            // The inscription carves itself in, stroke by stroke, with the
            // faint tap-tap-tap of Dáire's chisel under your fingers.
            OghamStoneView(word: block.word, width: 160, carve: true, ticks: true)
            Text(block.caption)
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkFaint)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SeanfhocalPageView: View {
    let block: SeanfhocalBlock

    var body: some View {
        VStack(spacing: 16) {
            Eyebrow(text: "Seanfhocal · collected", color: Theme.lichen)
            Text(block.ga)
                .font(.system(size: 25, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
            Text(block.en)
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            SoundRow(text: block.ga, hint: nil, label: "éist — hear it said")
            Rectangle()
                .fill(Theme.lichen)
                .frame(width: 44, height: 1.5)
                .padding(.vertical, 4)
            Text(block.note)
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkFaint)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 340)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct FinPageView: View {
    let block: FinBlock
    @State private var unusedGloss: Gloss?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(block.paras.enumerated()), id: \.offset) { _, para in
                GlossText(markdown: para, glosses: [], activeGloss: $unusedGloss,
                          font: .system(size: 15.5), lineSpacing: 5)
                    .foregroundStyle(Theme.inkSoft)
            }
            Text("An Turas — prototype, Caibidil 1 vertical slice · Connacht Irish first · Draft content awaiting native-speaker review · Draft TTS (Gemini 3.1) · Your progress lives only on this device.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.inkFaint)
                .lineSpacing(3)
                .padding(.top, 12)
                .overlay(Rectangle().fill(Theme.line).frame(height: 1), alignment: .top)
        }
    }
}

// MARK: - Page furniture

/// Faint chalked stroke-guides at the turn edge — the carver chalks before he
/// cuts. Appearing is the invitation: the next page already exists.
private struct ChalkTease: View {
    let label: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    var body: some View {
        HStack(spacing: 10) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .kerning(1.4)
                .foregroundStyle(Theme.inkFaint)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    ChalkGuide()
                        .stroke(Theme.stone, style: StrokeStyle(
                            lineWidth: 2.5, lineCap: .round, dash: [3, 3]))
                        .frame(width: 9, height: 15)
                }
            }
        }
        .padding(.trailing, 22)
        .padding(.bottom, 20)
        .opacity(breathing ? 0.95 : 0.5)
        .onAppear {
            if reduceMotion {
                breathing = true
            } else {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    breathing = true
                }
            }
        }
        .transition(.opacity.combined(with: .offset(x: 10)))
        .allowsHitTesting(false)
        .accessibilityLabel("Next: \(label). Swipe left to continue.")
    }
}

/// One slanted chalk guide-mark, waiting for the chisel.
private struct ChalkGuide: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}

/// The dull knock of the chisel skipping: swiping at a gated page. iOS 18+
/// (overscroll detection); iOS 17 still gets the visual rubber-band.
private struct OverscrollKnock: ViewModifier {
    let active: Bool
    @State private var fired = false

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.x + geo.containerSize.width - geo.contentSize.width
            } action: { _, overshoot in
                if overshoot > 28, active, !fired {
                    fired = true
                    Haptics.error()
                } else if overshoot < 6, fired {
                    fired = false
                }
            }
        } else {
            content
        }
    }
}

/// The final page: the session sets, the flourish has already sounded — and
/// the hook names tomorrow's reason to come back before the door closes.
private struct CompletionPage: View {
    let sessionIndex: Int
    let hook: String?
    let onExit: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { _ in
                    TickMark(variant: 2)
                        .stroke(Theme.moss, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 12, height: 22)
                }
            }
            .modifier(RiseIn(order: 0, reduceMotion: reduceMotion))
            Text(sessionIndex < 4
                 ? "Seisiún \(sessionIndex + 1) — snoite"
                 : "Caibidil a hAon — críochnaithe")
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
                .modifier(RiseIn(order: 1, reduceMotion: reduceMotion))
            Text(sessionIndex < 4
                 ? "Carved. The next stone on the path is waiting."
                 : "Complete. Do mhúsaem awaits on the map.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .modifier(RiseIn(order: 2, reduceMotion: reduceMotion))
            if let hook {
                VStack(spacing: 10) {
                    Eyebrow(text: "Amárach", color: Theme.lichen)
                    Text(hook)
                        .font(.system(size: 15.5, design: .serif))
                        .italic()
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: 340)
                }
                .padding(.top, 18)
                .modifier(RiseIn(order: 3, reduceMotion: reduceMotion))
            }
            Spacer()
            PrimaryButton(title: "Ar ais chuig an léarscáil →", fullWidth: true, action: onExit)
                .modifier(RiseIn(order: 4, reduceMotion: reduceMotion))
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 24)
        .frame(maxWidth: 640)
    }
}
