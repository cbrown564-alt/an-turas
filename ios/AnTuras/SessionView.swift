import SwiftUI

// MARK: - Session view model: beats reveal one at a time; exercises carve strokes.

final class SessionVM: ObservableObject {
    let session: Session
    let sessionIndex: Int

    @Published var visibleCount = 1
    @Published var exercisesDone = 0
    @Published var finished = false

    var exercisesTotal: Int { session.exerciseCount }

    init(session: Session, sessionIndex: Int) {
        self.session = session
        self.sessionIndex = sessionIndex
        // Debug: --reveal N pre-reveals beats for screenshots/snapshot tests.
        let args = ProcessInfo.processInfo.arguments
        if let flagIndex = args.firstIndex(of: "--reveal"),
           args.indices.contains(flagIndex + 1),
           let count = Int(args[flagIndex + 1]) {
            visibleCount = min(max(count, 1), session.blocks.count)
        }
    }

    func advance() {
        if visibleCount < session.blocks.count {
            visibleCount += 1
        } else {
            finished = true
        }
    }

    func exerciseSolved() {
        exercisesDone += 1
    }
}

struct SessionView: View {
    @EnvironmentObject var state: AppState
    @StateObject private var vm: SessionVM
    @State private var activeGloss: Gloss?
    let onExit: () -> Void

    init(sessionIndex: Int, onExit: @escaping () -> Void) {
        self.onExit = onExit
        // Content is loaded once by AppState; load again here only to seed the VM
        // before the environment object is available (prototype-grade shortcut).
        let session = ContentLoader.chapter1().sessions[sessionIndex]
        _vm = StateObject(wrappedValue: SessionVM(session: session, sessionIndex: sessionIndex))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    ForEach(0..<vm.visibleCount, id: \.self) { index in
                        beatRow(index)
                    }
                    if vm.finished {
                        completionBanner.id("fin")
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 60)
                .frame(maxWidth: 640)
            }
            .onChange(of: vm.visibleCount) { _, newCount in
                withAnimation(.easeOut(duration: 0.35)) {
                    proxy.scrollTo(newCount - 1, anchor: .top)
                }
            }
            .onChange(of: vm.finished) { _, isFinished in
                if isFinished {
                    if !state.done[vm.sessionIndex] { state.markDone(vm.sessionIndex) }
                    withAnimation { proxy.scrollTo("fin", anchor: .top) }
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .sheet(item: $activeGloss) { GlossSheet(gloss: $0) }
    }

    private func beatRow(_ index: Int) -> some View {
        BlockView(
            block: vm.session.blocks[index],
            isLast: index == vm.visibleCount - 1 && !vm.finished,
            activeGloss: $activeGloss,
            onContinue: { vm.advance() },
            onSolved: { vm.exerciseSolved() })
            .id(index)
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button(action: onExit) {
                Text("← An léarscáil")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
            }
            CarveBarView(total: vm.exercisesTotal, done: vm.exercisesDone)
                .frame(maxWidth: 280)
            Spacer(minLength: 0)
            Text("Seisiún \(vm.sessionIndex + 1)")
                .font(.system(size: 11, weight: .semibold))
                .kerning(1.2)
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Theme.bg.opacity(0.97))
        .overlay(Rectangle().fill(Theme.line).frame(height: 1), alignment: .bottom)
    }

    private var completionBanner: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(vm.sessionIndex < 4
                 ? "Seisiún \(vm.sessionIndex + 1) carved. The next stone on the path is waiting."
                 : "Caibidil a hAon complete — do mhúsaem awaits on the map.")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.moss)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.mossTint)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.moss.opacity(0.45), lineWidth: 1))
            PrimaryButton(title: "Ar ais chuig an léarscáil →", action: onExit)
        }
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

// MARK: - Shared buttons

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.bg)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(Theme.ink)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
    }
}

struct ContinueButton: View {
    var title = "Ar aghaidh →"
    let action: () -> Void

    var body: some View {
        PrimaryButton(title: title, action: action)
            .padding(.top, 4)
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
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4).stroke(Theme.line, lineWidth: 1))
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
                OghamStoneView(word: block.word, width: 160)
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
