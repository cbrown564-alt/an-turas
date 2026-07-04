import SwiftUI

// MARK: - Session as pages
// A session reads as a sequence of scene-pages, turned by swiping — the page
// turn replaces "Ar aghaidh" everywhere in narrative. Exercises gate the turn:
// pages beyond an unsolved exercise simply don't exist yet, so the swipe
// rubber-bands off the wall (with a dull knock). Solving carves the stroke and
// the page turns itself. The next page is trailed as faint chalk marks — the
// carver chalks before he cuts.

final class SessionVM: ObservableObject {
    let session: Session
    let sessionIndex: Int

    @Published var pages: [[Int]]
    @Published var currentPage: Int?
    @Published var solvedBlocks: Set<Int> = []
    @Published var finished = false

    var initialPage = 0

    var exercisesTotal: Int { session.exerciseCount }
    /// Index of the synthetic completion page, one past the content pages.
    var completionIndex: Int { pages.count }

    init(session: Session, sessionIndex: Int, mode: PagingMode) {
        self.session = session
        self.sessionIndex = sessionIndex
        pages = session.pageGroups(mode)
        // Debug: --reveal N jumps to page N, pre-solving exercises before it.
        let args = ProcessInfo.processInfo.arguments
        if let flagIndex = args.firstIndex(of: "--reveal"),
           args.indices.contains(flagIndex + 1),
           let target = Int(args[flagIndex + 1]) {
            for page in pages.prefix(min(target, pages.count)) {
                for blockIndex in page where session.blocks[blockIndex].isExercise {
                    solvedBlocks.insert(blockIndex)
                }
            }
            initialPage = min(max(target, 0), completionIndex)
        }
    }

    func isPageSolved(_ page: Int) -> Bool {
        guard pages.indices.contains(page) else { return true }
        return pages[page].allSatisfy { !session.blocks[$0].isExercise || solvedBlocks.contains($0) }
    }

    /// The furthest page that exists right now: everything up to (and including)
    /// the first unsolved exercise page, or the completion page if none remain.
    var furthestUnlocked: Int {
        for page in pages.indices where !isPageSolved(page) { return page }
        return completionIndex
    }

    func regroup(_ mode: PagingMode) {
        pages = session.pageGroups(mode)
        currentPage = min(currentPage ?? 0, furthestUnlocked)
    }
}

struct SessionView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var vm: SessionVM
    @AppStorage("turas_paging") private var pagingRaw = PagingMode.scenes.rawValue
    @State private var activeGloss: Gloss?
    @State private var visited: Set<Int> = []
    @State private var launched = false

    init(sessionIndex: Int) {
        // Content is loaded once by AppState; load again here only to seed the VM
        // before the environment object is available (prototype-grade shortcut).
        let session = ContentLoader.chapter1().sessions[sessionIndex]
        let mode = PagingMode(rawValue:
            UserDefaults.standard.string(forKey: "turas_paging") ?? "") ?? .scenes
        _vm = StateObject(wrappedValue:
            SessionVM(session: session, sessionIndex: sessionIndex, mode: mode))
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
        .onChange(of: pagingRaw) { _, raw in
            vm.regroup(PagingMode(rawValue: raw) ?? .scenes)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                CarveBarView(total: vm.exercisesTotal, done: vm.solvedBlocks.count)
                    .frame(width: 170)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Text("Seisiún \(vm.sessionIndex + 1)")
                    .font(.system(size: 11, weight: .semibold))
                    .kerning(1.2)
                    .foregroundStyle(Theme.inkFaint)
            }
            #if DEBUG
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Grouping", selection: $pagingRaw) {
                        Text("Scene pages").tag(PagingMode.scenes.rawValue)
                        Text("Block pages").tag(PagingMode.blocks.rawValue)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
            #endif
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
                    CompletionPage(sessionIndex: vm.sessionIndex) {
                        Haptics.tap()
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
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(Array(vm.pages[page].enumerated()), id: \.element) { row, blockIndex in
                    BlockView(
                        block: vm.session.blocks[blockIndex],
                        isLast: false,
                        activeGloss: $activeGloss,
                        onContinue: {},
                        onSolved: { solved(block: blockIndex, page: page) })
                        .modifier(RiseIn(order: row, reduceMotion: reduceMotion))
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 90)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .overlay(alignment: .bottomTrailing) {
            if let label = teaseLabel(after: page) {
                ChalkTease(label: label)
            }
        }
    }

    /// What the chalk marks trail: the next page's nature, if it exists yet.
    private func teaseLabel(after page: Int) -> String? {
        let next = page + 1
        guard next <= vm.furthestUnlocked else { return nil }
        guard next < vm.completionIndex else { return "críoch" }
        switch vm.session.blocks[vm.pages[next][0]] {
        case .scene:        return "an scéal"
        case .note:         return "nóta gramadaí"
        case .choice, .assemble, .typein, .match:
                            return "cleachtadh"
        case .inscription:  return "an chloch"
        case .seanfhocal:   return "seanfhocal"
        case .artifact:     return "déantán"
        case .fin:          return "críoch"
        }
    }

    private func solved(block blockIndex: Int, page: Int) {
        Haptics.chisel()
        withAnimation(Motion.pop) {
            _ = vm.solvedBlocks.insert(blockIndex)
        }
        // Let the verdict land, then the page turns itself.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak vm] in
            guard let vm, vm.currentPage == page, vm.isPageSolved(page) else { return }
            withAnimation(.easeInOut(duration: 0.5)) {
                vm.currentPage = page + 1
            }
        }
    }
}

// MARK: - Page furniture

/// Staggered entrance for a freshly turned page: rows settle like dust.
private struct RiseIn: ViewModifier {
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

/// The final page: the session sets, the flourish has already sounded.
private struct CompletionPage: View {
    let sessionIndex: Int
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
            Spacer()
            PrimaryButton(title: "Ar ais chuig an léarscáil →", fullWidth: true, action: onExit)
                .modifier(RiseIn(order: 3, reduceMotion: reduceMotion))
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 24)
        .frame(maxWidth: 640)
    }
}

// MARK: - Block dispatch

struct BlockView: View {
    let block: Block
    let isLast: Bool
    @Binding var activeGloss: Gloss?
    let onContinue: () -> Void
    let onSolved: () -> Void

    var body: some View {
        switch block {
        case .scene(let scene):
            SceneBlockView(scene: scene, isLast: isLast, activeGloss: $activeGloss, onContinue: onContinue)
        case .note(let note):
            NoteBlockView(note: note, isLast: isLast, onContinue: onContinue)
        case .choice(let choice):
            ChoiceView(block: choice, isLast: isLast, onContinue: onContinue, onSolved: onSolved)
        case .assemble(let assemble):
            AssembleView(block: assemble, isLast: isLast, onContinue: onContinue, onSolved: onSolved)
        case .typein(let typein):
            TypeInView(block: typein, isLast: isLast, onContinue: onContinue, onSolved: onSolved)
        case .match(let match):
            MatchView(block: match, isLast: isLast, onContinue: onContinue, onSolved: onSolved)
        case .inscription(let inscription):
            InscriptionView(block: inscription, isLast: isLast, onContinue: onContinue)
        case .seanfhocal(let seanfhocal):
            SeanfhocalView(block: seanfhocal, isLast: isLast, onContinue: onContinue)
        case .artifact:
            ArtifactView(isLast: isLast, onContinue: onContinue)
        case .fin(let fin):
            FinView(block: fin, isLast: isLast, onContinue: onContinue)
        }
    }
}

// MARK: - Static blocks

struct SceneBlockView: View {
    let scene: SceneBlock
    let isLast: Bool
    @Binding var activeGloss: Gloss?
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let who = scene.who {
                Eyebrow(text: who, color: Theme.inkFaint)
            }
            ForEach(Array(scene.paras.enumerated()), id: \.offset) { _, para in
                GlossText(markdown: para, glosses: scene.glosses ?? [], activeGloss: $activeGloss)
                    .foregroundStyle(Theme.ink)
            }
            if isLast { ContinueButton(action: onContinue) }
        }
    }
}

struct NoteBlockView: View {
    let note: NoteBlock
    let isLast: Bool
    let onContinue: () -> Void
    @State private var unusedGloss: Gloss?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "An Nóta Gramadaí · \(note.title)", color: Theme.lichen)
                ForEach(Array(note.paras.enumerated()), id: \.offset) { index, para in
                    GlossText(markdown: para, glosses: [], activeGloss: $unusedGloss,
                              font: .system(size: 15))
                        .foregroundStyle(Theme.ink)
                    // Example pairs sit after the second-to-last paragraph, as in the design.
                    if index == max(note.paras.count - 2, 0), let pairs = note.pairs {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(pairs, id: \.self) { line in
                                GlossText(markdown: line, glosses: [], activeGloss: $unusedGloss,
                                          font: .system(size: 17, design: .serif))
                                    .foregroundStyle(Theme.ink)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .padding(18)
            .background(Theme.raised)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8).stroke(Theme.line, lineWidth: 1))
            .overlay(
                Rectangle().fill(Theme.lichen.opacity(0.7)).frame(width: 3),
                alignment: .leading)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            if isLast { ContinueButton(title: "Tuigim — got it →", action: onContinue) }
        }
    }
}

struct InscriptionView: View {
    let block: InscriptionBlock
    let isLast: Bool
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Spacer()
                // The inscription carves itself in, stroke by stroke, with the
                // faint tap-tap-tap of Dáire's chisel under your fingers.
                OghamStoneView(word: block.word, width: 160, carve: true, ticks: true)
                Spacer()
            }
            Text(block.caption)
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkFaint)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            if isLast { ContinueButton(action: onContinue) }
        }
    }
}

struct SeanfhocalView: View {
    let block: SeanfhocalBlock
    let isLast: Bool
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Seanfhocal · collected", color: Theme.lichen)
                Text(block.ga)
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text(block.en)
                    .font(.system(size: 16, design: .serif))
                    .foregroundStyle(Theme.inkSoft)
                Text(block.note)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(Rectangle().fill(Theme.lichen).frame(height: 2), alignment: .top)
            .overlay(Rectangle().fill(Theme.line).frame(height: 1), alignment: .bottom)
            if isLast { ContinueButton(action: onContinue) }
        }
    }
}

struct FinView: View {
    let block: FinBlock
    let isLast: Bool
    let onContinue: () -> Void
    @State private var unusedGloss: Gloss?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(block.paras.enumerated()), id: \.offset) { _, para in
                GlossText(markdown: para, glosses: [], activeGloss: $unusedGloss,
                          font: .system(size: 15))
                    .foregroundStyle(Theme.inkSoft)
            }
            Text("An Turas — prototype, Caibidil 1 vertical slice · Connacht Irish first · Draft content awaiting native-speaker review · Audio pending ABAIR licensing · Your progress lives only on this device.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.inkFaint)
                .padding(.top, 10)
                .overlay(Rectangle().fill(Theme.line).frame(height: 1), alignment: .top)
            if isLast { ContinueButton(title: "Críochnaigh — finish →", action: onContinue) }
        }
        .padding(.top, 6)
    }
}
