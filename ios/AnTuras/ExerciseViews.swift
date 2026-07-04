import SwiftUI

// MARK: - Shared exercise chrome
// No container. The page itself is the working surface; the tappable elements
// are the raised objects on it. Up top, a register mark — three chalk strokes
// and the word — then an optional beat of story, then the prompt in the same
// serif voice the story speaks in.

private struct ExerciseFrame<Content: View>: View {
    let context: String?
    let prompt: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                HStack(spacing: 3.5) {
                    ForEach(0..<3, id: \.self) { _ in
                        TickMark(variant: 2)
                            .stroke(Theme.moss.opacity(0.7),
                                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .frame(width: 8, height: 14)
                    }
                }
                Eyebrow(text: "Cleachtadh", color: Theme.inkFaint)
            }
            .padding(.bottom, 2)
            if let context {
                Text(context)
                    .font(.system(size: 16, design: .serif))
                    .italic()
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(4)
            }
            Text(prompt)
                .font(.system(size: 21, weight: .medium, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineSpacing(4)
                .padding(.bottom, 4)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct Verdict: View {
    let ok: Bool
    let headline: String
    var detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(headline)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(ok ? Theme.moss : Theme.rust)
            if let detail {
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(3)
            }
        }
        .padding(.top, 4)
        .transition(.offset(y: 8).combined(with: .opacity))
    }
}

// MARK: - Choice

struct ChoiceView: View {
    let block: ChoiceBlock
    let onSolved: () -> Void

    @State private var solved = false
    @State private var wrongPicks: Set<String> = []
    @State private var shakes: [String: Int] = [:]
    @State private var verdict: (ok: Bool, why: String)?

    var body: some View {
        ExerciseFrame(context: block.context, prompt: block.prompt) {
            VStack(spacing: 10) {
                ForEach(block.opts) { opt in
                    optionRow(opt)
                }
            }
            if let verdict {
                Verdict(ok: verdict.ok,
                        headline: verdict.ok ? "Maith thú!" : "Ní hea — try again.",
                        detail: verdict.why)
            }
        }
    }

    private func optionRow(_ opt: ChoiceOption) -> some View {
        Button {
            pick(opt)
        } label: {
            Text(opt.txt)
                .font(.system(size: 17, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(background(for: opt))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(border(for: opt), lineWidth: 1))
                .scaleEffect(solved && opt.ok ? 1.02 : 1)
        }
        .disabled(solved || wrongPicks.contains(opt.id))
        .buttonStyle(CarvePress())
        .shake(shakes[opt.id, default: 0])
        .animation(Motion.pop, value: solved)
    }

    private func pick(_ opt: ChoiceOption) {
        guard !solved else { return }
        if opt.ok {
            withAnimation(Motion.pop) {
                solved = true
                verdict = (true, opt.why)
            }
            onSolved()
        } else {
            Haptics.error()
            withAnimation(Motion.settle) {
                wrongPicks.insert(opt.id)
                verdict = (false, opt.why)
            }
            shakes[opt.id, default: 0] += 1
        }
    }

    private func background(for opt: ChoiceOption) -> Color {
        if solved && opt.ok { return Theme.mossTint }
        if wrongPicks.contains(opt.id) { return Theme.rustTint }
        return Theme.raised
    }

    private func border(for opt: ChoiceOption) -> Color {
        if solved && opt.ok { return Theme.moss }
        if wrongPicks.contains(opt.id) { return Theme.rust }
        return Theme.line
    }
}

// MARK: - Assemble (word tiles fly between bank and sentence line)

private struct TileItem: Identifiable, Equatable {
    let id: Int
    let word: String
}

struct AssembleView: View {
    let block: AssembleBlock
    let onSolved: () -> Void

    @Namespace private var tileNS
    @State private var bank: [TileItem]
    @State private var chosen: [TileItem] = []
    @State private var solved = false
    @State private var shakeCount = 0
    @State private var verdict: (ok: Bool, text: String)?

    init(block: AssembleBlock, onSolved: @escaping () -> Void) {
        self.block = block
        self.onSolved = onSolved
        _bank = State(initialValue:
            block.tiles.enumerated().map { TileItem(id: $0.offset, word: $0.element) }.shuffled())
    }

    var body: some View {
        ExerciseFrame(context: block.context, prompt: block.prompt) {
            VStack(alignment: .leading, spacing: 14) {
                FlowLayout(spacing: 8) {
                    ForEach(chosen) { item in
                        tile(item, inBank: false)
                    }
                }
                .frame(minHeight: 46)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(Rectangle().fill(Theme.line).frame(height: 2), alignment: .bottom)
                .shake(shakeCount)

                FlowLayout(spacing: 8) {
                    ForEach(bank) { item in
                        tile(item, inBank: true)
                    }
                }
                .frame(minHeight: 46)
                .frame(maxWidth: .infinity, alignment: .leading)

                Button("Seiceáil — check") { check() }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.bg)
                    .padding(.vertical, 11)
                    .padding(.horizontal, 20)
                    .background(Theme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .buttonStyle(CarvePress())
                    .disabled(solved)
                    .padding(.top, 2)

                if let verdict {
                    Verdict(ok: verdict.ok, headline: verdict.text)
                }
            }
        }
    }

    private func tile(_ item: TileItem, inBank: Bool) -> some View {
        Button {
            guard !solved else { return }
            Haptics.tap()
            withAnimation(Motion.settle) {
                if inBank {
                    bank.removeAll { $0.id == item.id }
                    chosen.append(item)
                } else {
                    chosen.removeAll { $0.id == item.id }
                    bank.append(item)
                }
            }
        } label: {
            Text(item.word)
                .font(.system(size: 17, design: .serif))
                .foregroundStyle(Theme.ink)
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
                .background(Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line, lineWidth: 1))
                .shadow(color: Theme.ink.opacity(inBank ? 0.06 : 0.1), radius: 3, y: 2)
        }
        .buttonStyle(CarvePress())
        .matchedGeometryEffect(id: item.id, in: tileNS)
    }

    private func check() {
        guard !solved else { return }
        if chosen.map(\.word).joined(separator: " ") == block.answer {
            withAnimation(Motion.pop) {
                solved = true
                verdict = (true, "Maith thú! \(block.answer).")
            }
            onSolved()
        } else {
            Haptics.error()
            shakeCount += 1
            withAnimation(Motion.settle) {
                verdict = (false, "Not quite — check the word order and try again.")
            }
        }
    }
}

// MARK: - Type-in (with fada keys)

struct TypeInView: View {
    let block: TypeInBlock
    let onSolved: () -> Void

    @EnvironmentObject var state: AppState
    @State private var text = ""
    @State private var solved = false
    @State private var shakeCount = 0
    @State private var verdict: (ok: Bool, text: String)?
    @FocusState private var focused: Bool

    var body: some View {
        ExerciseFrame(context: block.context, prompt: block.prompt) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    TextField(block.placeholder, text: $text)
                        .font(.system(size: 17, design: .serif))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .focused($focused)
                        .onSubmit { grade() }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(Theme.raised)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(focused ? Theme.moss.opacity(0.6) : Theme.line, lineWidth: 1))
                        .disabled(solved)
                    Button("Seiceáil") { grade() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.bg)
                        .padding(.vertical, 13)
                        .padding(.horizontal, 16)
                        .background(Theme.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .buttonStyle(CarvePress())
                        .disabled(solved)
                }
                .shake(shakeCount)
                if block.fada {
                    HStack(spacing: 6) {
                        ForEach(["á", "é", "í", "ó", "ú"], id: \.self) { fada in
                            Button(fada) {
                                guard !solved else { return }
                                Haptics.tap()
                                text.append(fada)
                            }
                            .font(.system(size: 16, design: .serif))
                            .foregroundStyle(Theme.ink)
                            .padding(.vertical, 7)
                            .padding(.horizontal, 13)
                            .background(Theme.raised)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
                            .buttonStyle(CarvePress())
                        }
                    }
                }
                if let hint = block.hint, verdict == nil {
                    Text(hint)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkFaint)
                        .lineSpacing(3)
                }
                if let verdict {
                    Verdict(ok: verdict.ok, headline: verdict.text)
                }
            }
        }
    }

    private func grade() {
        guard !solved else { return }
        let value = text.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        let lower = value.lowercased()
        var ok = false
        var echo = ""

        switch block.check {
        case .ismise:
            ok = lower.hasPrefix("is mise ") && value.count > 8
            if ok {
                let name = String(value.dropFirst(8)).trimmingCharacters(in: .whitespaces)
                if block.capture == true { state.learnerName = name }
                echo = "\(value) — welcome, \(name)."
            }
        case .isas:
            ok = lower.hasPrefix("is as ") && (lower.hasSuffix(" mé") || lower.hasSuffix(" me")) && value.count > 9
            if ok { echo = "\(value) — noted. You have a place in the story now." }
        case .exact:
            ok = lower == (block.answer ?? "").lowercased() && value == block.answer
            if ok { echo = "\(block.answer ?? "") — carved right." }
        }

        if ok {
            focused = false
            withAnimation(Motion.pop) {
                solved = true
                verdict = (true, "Maith thú! \(echo)")
            }
            onSolved()
        } else {
            Haptics.error()
            shakeCount += 1
            withAnimation(Motion.settle) {
                verdict = (false, block.check == .exact
                    ? "Not quite — mind the fada. Use the accent keys and try again."
                    : "Almost — follow the pattern “\(block.placeholder)” exactly, then your own word.")
            }
        }
    }
}

// MARK: - Match pairs
// Two materials face each other: Irish is stone (serif, raised, a carved groove
// down its leading edge), English is chalk (plain sans, flat on the page).
// A locked pair is joined by a thread drawn across the gutter — the line the
// carver snaps between a word and what it means.

struct MatchView: View {
    let block: MatchBlock
    let onSolved: () -> Void

    @State private var left: [String]
    @State private var right: [String]
    @State private var key: [String: String]
    @State private var selectedLeft: String?
    @State private var locked: Set<String> = []   // locked left + right values
    @State private var threads: [MatchThread] = []
    @State private var flash: String?
    @State private var shakes: [String: Int] = [:]
    @State private var solved = false

    init(block: MatchBlock, onSolved: @escaping () -> Void) {
        self.block = block
        self.onSolved = onSolved
        _left = State(initialValue: block.pairs.map { $0[0] }.shuffled())
        _right = State(initialValue: block.pairs.map { $0[1] }.shuffled())
        _key = State(initialValue: Dictionary(uniqueKeysWithValues: block.pairs.map { ($0[0], $0[1]) }))
    }

    var body: some View {
        ExerciseFrame(context: block.context, prompt: block.prompt) {
            HStack(alignment: .top, spacing: 20) {
                VStack(spacing: 10) {
                    ForEach(left, id: \.self) { item in
                        pairButton(item, isLeft: true)
                    }
                }
                VStack(spacing: 10) {
                    ForEach(right, id: \.self) { item in
                        pairButton(item, isLeft: false)
                    }
                }
            }
            .overlayPreferenceValue(MatchCardAnchorKey.self) { anchors in
                GeometryReader { geo in
                    ForEach(threads) { thread in
                        if let l = anchors["L:\(thread.left)"],
                           let r = anchors["R:\(thread.right)"] {
                            ThreadView(
                                from: CGPoint(x: geo[l].maxX + 1, y: geo[l].midY),
                                to: CGPoint(x: geo[r].minX - 1, y: geo[r].midY))
                        }
                    }
                }
                .allowsHitTesting(false)
            }
            if solved {
                Verdict(ok: true, headline: "Maith thú! All matched.")
            }
        }
    }

    private func pairButton(_ item: String, isLeft: Bool) -> some View {
        Button {
            tap(item, isLeft: isLeft)
        } label: {
            Text(item)
                .font(isLeft ? .system(size: 16.5, design: .serif) : .system(size: 14))
                .foregroundStyle(locked.contains(item) ? Theme.inkSoft : Theme.ink)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.leading, isLeft ? 7 : 0)
                .background(background(item))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .leading) {
                    // The carved groove marks the stone side — Irish only.
                    if isLeft {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(locked.contains(item) ? Theme.moss.opacity(0.6) : Theme.stone)
                            .frame(width: 3)
                            .padding(.vertical, 9)
                            .padding(.leading, 7)
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(border(item), lineWidth: 1))
                // The picked-up stone lifts off the page, waiting for its mate.
                .scaleEffect(selectedLeft == item ? 1.05 : 1)
                .shadow(color: Theme.ink.opacity(shadowStrength(item, isLeft: isLeft)),
                        radius: selectedLeft == item ? 8 : 3,
                        y: selectedLeft == item ? 3 : 2)
                .anchorPreference(key: MatchCardAnchorKey.self, value: .bounds) {
                    ["\(isLeft ? "L" : "R"):\(item)": $0]
                }
        }
        .buttonStyle(CarvePress())
        .shake(shakes[item, default: 0])
        .animation(Motion.pop, value: selectedLeft)
        .animation(Motion.pop, value: locked)
        .disabled(locked.contains(item) || solved)
    }

    private func shadowStrength(_ item: String, isLeft: Bool) -> Double {
        if selectedLeft == item { return 0.18 }
        // Stone tiles carry weight; chalk sits flat.
        return isLeft && !locked.contains(item) ? 0.07 : 0
    }

    private func background(_ item: String) -> Color {
        if locked.contains(item) { return Theme.mossTint }
        if flash == item { return Theme.rustTint }
        // Stone is raised; chalk lies flat on the page.
        return left.contains(item) ? Theme.raised : .clear
    }

    private func border(_ item: String) -> Color {
        if locked.contains(item) { return Theme.moss.opacity(0.55) }
        if flash == item { return Theme.rust }
        if selectedLeft == item { return Theme.ink }
        return Theme.line
    }

    private func tap(_ item: String, isLeft: Bool) {
        if isLeft {
            Haptics.tap()
            selectedLeft = item
            return
        }
        guard let sel = selectedLeft else { return }
        if key[sel] == item {
            Haptics.tick()
            withAnimation(Motion.pop) {
                locked.insert(sel)
                locked.insert(item)
            }
            threads.append(MatchThread(left: sel, right: item))
            selectedLeft = nil
            if locked.count == block.pairs.count * 2 {
                withAnimation(Motion.pop) { solved = true }
                onSolved()
            }
        } else {
            Haptics.error()
            shakes[item, default: 0] += 1
            withAnimation(.easeOut(duration: 0.2)) { flash = item }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if flash == item {
                    withAnimation(.easeOut(duration: 0.3)) { flash = nil }
                }
            }
        }
    }
}

private struct MatchThread: Identifiable {
    let left: String
    let right: String
    var id: String { left }
}

private struct MatchCardAnchorKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>],
                       nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

/// The thread between a matched pair, drawn left → right like a snapped
/// chalk line: it lands soft and stays.
private struct ThreadView: View {
    let from: CGPoint
    let to: CGPoint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0

    var body: some View {
        ThreadLine(from: from, to: to)
            .trim(from: 0, to: progress)
            .stroke(Theme.moss.opacity(0.4),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            .onAppear {
                if reduceMotion {
                    progress = 1
                } else {
                    withAnimation(.easeOut(duration: 0.4)) { progress = 1 }
                }
            }
    }
}

private struct ThreadLine: Shape {
    let from: CGPoint
    let to: CGPoint

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: from)
        let midX = (from.x + to.x) / 2
        p.addCurve(to: to,
                   control1: CGPoint(x: midX, y: from.y),
                   control2: CGPoint(x: midX, y: to.y))
        return p
    }
}
