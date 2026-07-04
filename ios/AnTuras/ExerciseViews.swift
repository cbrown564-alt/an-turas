import SwiftUI

// MARK: - Shared exercise chrome

private struct ExerciseCard<Content: View>: View {
    let prompt: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(prompt)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.ink)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.sunk)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
            }
        }
        .transition(.offset(y: 8).combined(with: .opacity))
    }
}

// MARK: - Choice

struct ChoiceView: View {
    let block: ChoiceBlock
    let isLast: Bool
    let onContinue: () -> Void
    let onSolved: () -> Void

    @State private var solved = false
    @State private var wrongPicks: Set<String> = []
    @State private var shakes: [String: Int] = [:]
    @State private var verdict: (ok: Bool, why: String)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ExerciseCard(prompt: block.prompt) {
                VStack(spacing: 8) {
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
            if solved && isLast { ContinueButton(action: onContinue) }
        }
    }

    private func optionRow(_ opt: ChoiceOption) -> some View {
        Button {
            pick(opt)
        } label: {
            Text(opt.txt)
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(background(for: opt))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6)
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
    let isLast: Bool
    let onContinue: () -> Void
    let onSolved: () -> Void

    @Namespace private var tileNS
    @State private var bank: [TileItem]
    @State private var chosen: [TileItem] = []
    @State private var solved = false
    @State private var shakeCount = 0
    @State private var verdict: (ok: Bool, text: String)?

    init(block: AssembleBlock, isLast: Bool, onContinue: @escaping () -> Void, onSolved: @escaping () -> Void) {
        self.block = block
        self.isLast = isLast
        self.onContinue = onContinue
        self.onSolved = onSolved
        _bank = State(initialValue:
            block.tiles.enumerated().map { TileItem(id: $0.offset, word: $0.element) }.shuffled())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ExerciseCard(prompt: block.prompt) {
                VStack(alignment: .leading, spacing: 10) {
                    FlowLayout(spacing: 8) {
                        ForEach(chosen) { item in
                            tile(item, inBank: false)
                        }
                    }
                    .frame(minHeight: 44)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(Rectangle().fill(Theme.line).frame(height: 2), alignment: .bottom)
                    .shake(shakeCount)

                    FlowLayout(spacing: 8) {
                        ForEach(bank) { item in
                            tile(item, inBank: true)
                        }
                    }
                    .frame(minHeight: 44)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button("Seiceáil — check") { check() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.bg)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                        .background(Theme.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .buttonStyle(CarvePress())
                        .disabled(solved)

                    if let verdict {
                        Verdict(ok: verdict.ok, headline: verdict.text)
                    }
                }
            }
            if solved && isLast { ContinueButton(action: onContinue) }
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
                .padding(.vertical, 9)
                .padding(.horizontal, 14)
                .background(Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
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
    let isLast: Bool
    let onContinue: () -> Void
    let onSolved: () -> Void

    @EnvironmentObject var state: AppState
    @State private var text = ""
    @State private var solved = false
    @State private var shakeCount = 0
    @State private var verdict: (ok: Bool, text: String)?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ExerciseCard(prompt: block.prompt) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        TextField(block.placeholder, text: $text)
                            .font(.system(size: 17, design: .serif))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .focused($focused)
                            .onSubmit { grade() }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(Theme.raised)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6)
                                .stroke(focused ? Theme.moss.opacity(0.6) : Theme.line, lineWidth: 1))
                            .disabled(solved)
                        Button("Seiceáil") { grade() }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.bg)
                            .padding(.vertical, 11)
                            .padding(.horizontal, 14)
                            .background(Theme.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
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
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Theme.raised)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.line, lineWidth: 1))
                                .buttonStyle(CarvePress())
                            }
                        }
                    }
                    if let hint = block.hint, verdict == nil {
                        Text(hint)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.inkFaint)
                    }
                    if let verdict {
                        Verdict(ok: verdict.ok, headline: verdict.text)
                    }
                }
            }
            if solved && isLast { ContinueButton(action: onContinue) }
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

struct MatchView: View {
    let block: MatchBlock
    let isLast: Bool
    let onContinue: () -> Void
    let onSolved: () -> Void

    @State private var left: [String]
    @State private var right: [String]
    @State private var key: [String: String]
    @State private var selectedLeft: String?
    @State private var locked: Set<String> = []   // locked left + right values
    @State private var flash: String?
    @State private var shakes: [String: Int] = [:]
    @State private var solved = false

    init(block: MatchBlock, isLast: Bool, onContinue: @escaping () -> Void, onSolved: @escaping () -> Void) {
        self.block = block
        self.isLast = isLast
        self.onContinue = onContinue
        self.onSolved = onSolved
        _left = State(initialValue: block.pairs.map { $0[0] }.shuffled())
        _right = State(initialValue: block.pairs.map { $0[1] }.shuffled())
        _key = State(initialValue: Dictionary(uniqueKeysWithValues: block.pairs.map { ($0[0], $0[1]) }))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ExerciseCard(prompt: block.prompt) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(spacing: 8) {
                        ForEach(left, id: \.self) { item in
                            pairButton(item, isLeft: true)
                        }
                    }
                    VStack(spacing: 8) {
                        ForEach(right, id: \.self) { item in
                            pairButton(item, isLeft: false)
                        }
                    }
                }
                if solved {
                    Verdict(ok: true, headline: "Maith thú! All matched.")
                }
            }
            if solved && isLast { ContinueButton(action: onContinue) }
        }
    }

    private func pairButton(_ item: String, isLeft: Bool) -> some View {
        Button {
            tap(item, isLeft: isLeft)
        } label: {
            Text(item)
                .font(isLeft ? .system(size: 16, design: .serif) : .system(size: 14))
                .foregroundStyle(locked.contains(item) ? Theme.inkSoft : Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 11)
                .padding(.horizontal, 11)
                .background(background(item))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(border(item), lineWidth: 1))
                // The picked-up tile lifts off the stone, waiting for its mate.
                .scaleEffect(selectedLeft == item ? 1.05 : 1)
                .shadow(color: Theme.ink.opacity(selectedLeft == item ? 0.18 : 0),
                        radius: 8, y: 3)
        }
        .buttonStyle(CarvePress())
        .shake(shakes[item, default: 0])
        .animation(Motion.pop, value: selectedLeft)
        .animation(Motion.pop, value: locked)
        .disabled(locked.contains(item) || solved)
    }

    private func background(_ item: String) -> Color {
        if locked.contains(item) { return Theme.mossTint }
        if flash == item { return Theme.rustTint }
        if selectedLeft == item { return Theme.raised }
        return Theme.raised
    }

    private func border(_ item: String) -> Color {
        if locked.contains(item) { return Theme.moss }
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
