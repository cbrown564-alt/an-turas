import SwiftUI

// MARK: - Ar Ais: spaced repetition as visiting.
// The scheduler underneath is boring, solved technology. The innovation is
// entirely the clothing: due items arrive as people and places asking for
// you, batched by scene — never "37 cards due". Answering re-cuts the
// groove with the same recarve mechanic the sessions taught.

struct ArAisView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The queue is frozen on arrival so cards don't vanish mid-visit as
    /// the scheduler moves them into the future.
    @State private var queue: [Visit] = []
    @State private var agoLines: [String: String] = [:]
    @State private var answered: Set<String> = []
    @State private var expanded: String?
    @State private var appeared = false

    private var remaining: Int { queue.count - answered.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                    .padding(.top, 12)

                if queue.isEmpty {
                    emptyState
                } else {
                    ForEach(queue) { visit in
                        VisitCardView(
                            visit: visit,
                            ago: agoLines[visit.id] ?? "inniu",
                            learnerName: state.learnerName,
                            isExpanded: expanded == visit.id,
                            isAnswered: answered.contains(visit.id),
                            onTap: { tap(visit) },
                            onAnswered: { struggled in finish(visit, struggled: struggled) })
                        .cascade(queue.firstIndex(where: { $0.id == visit.id }) ?? 0,
                                 appeared: appeared, reduceMotion: reduceMotion)
                    }

                    if remaining == 0 {
                        allDoneBlock
                            .transition(.offset(y: 10).combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 48)
            .frame(maxWidth: 640)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if queue.isEmpty {
                let due = state.dueVisits()
                queue = due
                for visit in due {
                    if let p = state.visitProgress[visit.id] {
                        agoLines[visit.id] = Turas.ago(p.due)
                    }
                }
                expanded = due.first?.id
            }
            guard !appeared else { return }
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.easeOut(duration: 0.4)) { appeared = true }
            }
        }
    }

    private func tap(_ visit: Visit) {
        guard !answered.contains(visit.id) else { return }
        Haptics.tap()
        withAnimation(Motion.settle) {
            expanded = expanded == visit.id ? nil : visit.id
        }
    }

    private func finish(_ visit: Visit, struggled: Bool) {
        state.completeVisit(visit, struggled: struggled)
        withAnimation(Motion.settle) {
            _ = answered.insert(visit.id)
            expanded = queue.first { !answered.contains($0.id) }?.id
        }
        if remaining == 0 {
            Haptics.flourish()
        }
    }

    // MARK: Pieces

    private var header: some View {
        EditorialScreenHeader(
            context: "Ar Ais · athchuairt",
            title: headline,
            detail: subline,
            accent: Theme.rust
        )
    }

    private var headline: String {
        if queue.isEmpty { return "Níl éinne ag fanacht" }
        if remaining == 0 { return "Tá tú ar ais" }
        let people = Set(queue.filter { !answered.contains($0.id) }.map(\.who))
        if people.count == 1, let who = people.first {
            return "Tá \(who) ag fiafraí fút"
        }
        return "Tá \(Turas.people(people.count)) ag fiafraí fút"
    }

    private var subline: String {
        if queue.isEmpty { return "No one is waiting at the stone today." }
        if remaining == 0 { return "Nobody was forgotten. The grooves are sharp again." }
        return "The stone remembers — the question is whether you do. Visit them; it only takes a moment."
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let next = state.nextReturn() {
                Text("Fillfidh \(next.visit.who) \(Turas.until(next.due)) — \(next.visit.who) will have a question for you \(untilEn(next.due)).")
                    .font(.system(size: 15, design: .serif))
                    .italic()
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(4)
            } else {
                Text("Finish a session on the path and its people will start asking for you — tomorrow, and the day after, for as long as you let the wind work on the grooves.")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.sunk.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var allDoneBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Verdict(ok: true,
                    headline: "Tá tú ar ais — you're back.",
                    detail: "Every groove you re-cut sits deeper than it did. That's how remembering works here.")
            if let next = state.nextReturn() {
                Text("Fillfidh \(next.visit.who) \(Turas.until(next.due)).")
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.top, 2)
            }
        }
        .padding(.top, 6)
    }

    private func untilEn(_ due: Date) -> String {
        let days = Int(ceil(due.timeIntervalSince(Date()) / 86400))
        switch days {
        case ..<1: return "later today"
        case 1: return "tomorrow"
        default: return "in \(days) days"
        }
    }
}

// MARK: - One visit: a letter that opens into the recarve interaction

private struct VisitCardView: View {
    let visit: Visit
    let ago: String
    let learnerName: String
    let isExpanded: Bool
    let isAnswered: Bool
    let onTap: () -> Void
    let onAnswered: (_ struggled: Bool) -> Void

    @State private var text = ""
    @State private var shakeCount = 0
    @State private var misses = 0
    @State private var verdict: String?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("\(visit.who) · \(visit.where) · \(ago)")
                            .font(.system(size: 11, weight: .semibold))
                            .kerning(0.6)
                            .foregroundStyle(isAnswered ? Theme.moss : Theme.rust)
                            .textCase(.uppercase)
                        Spacer(minLength: 0)
                        if isAnswered {
                            Text("ATHSNOITE ✓")
                                .font(.system(size: 10, weight: .bold))
                                .kerning(1)
                                .foregroundStyle(Theme.moss)
                        }
                    }
                    Text(visit.frame)
                        .font(.system(size: 15, design: .serif))
                        .foregroundStyle(isAnswered ? Theme.inkSoft : Theme.ink)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isAnswered)

            if isAnswered {
                answeredRow
            } else if isExpanded {
                workbench
                    .transition(.offset(y: 8).combined(with: .opacity))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.raised)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(isAnswered ? Theme.moss.opacity(0.4)
                    : isExpanded ? Theme.rust.opacity(0.4) : Theme.line, lineWidth: 1))
    }

    /// The phrase restored, standing on the page the way recarve leaves it.
    private var answeredRow: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(answeredDisplay)
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            Text("— \(visit.en)")
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(.leading, 14)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Theme.moss.opacity(0.6))
                .frame(width: 3)
                .padding(.vertical, 2)
        }
    }

    private var answeredDisplay: String {
        text.isEmpty ? visit.displayPhrase : text
    }

    // MARK: The recarve bench

    private var workbench: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(RecarveView.weathered(visit.displayPhrase))
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .kerning(1.5)
                    .foregroundStyle(Theme.stone)
                Text("— \(visit.en)")
                    .font(.system(size: 13))
                    .italic()
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(.leading, 14)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Theme.stone.opacity(0.55))
                    .frame(width: 3)
                    .padding(.vertical, 2)
            }
            .accessibilityLabel("Weathered phrase meaning: \(visit.en)")

            HStack(spacing: 8) {
                TextField("Cut it fresh…", text: $text)
                    .font(.system(size: 17, design: .serif))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($focused)
                    .onSubmit { grade() }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Theme.bg)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(focused ? Theme.moss.opacity(0.6) : Theme.line, lineWidth: 1))
                Button("Snoigh") { grade() }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.bg)
                    .padding(.vertical, 13)
                    .padding(.horizontal, 16)
                    .background(Theme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .buttonStyle(CarvePress())
            }
            .shake(shakeCount)

            FadaKeyRow(text: $text, disabled: false)

            if let verdict {
                Text(verdict)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.rust)
                    .lineSpacing(3)
                    .transition(.offset(y: 6).combined(with: .opacity))
            }
        }
    }

    private func grade() {
        let value = text.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        guard !value.isEmpty else { return }
        let lower = value.lowercased()

        let ok: Bool
        switch visit.check {
        case .ismise:
            ok = lower.hasPrefix("is mise ") && value.count > 8
        case .isas:
            ok = lower.hasPrefix("is as ") && (lower.hasSuffix(" mé") || lower.hasSuffix(" me")) && value.count > 9
        case .exact:
            ok = lower == visit.answer.lowercased()
        }

        if ok {
            Haptics.chisel()
            focused = false
            text = value
            onAnswered(misses > 0)
        } else {
            Haptics.error()
            shakeCount += 1
            misses += 1
            withAnimation(Motion.settle) {
                verdict = hint(for: value)
            }
        }
    }

    private func hint(for value: String) -> String {
        switch visit.check {
        case .exact:
            return stripFadas(value) == stripFadas(visit.answer)
                ? "The letters are right — the fadas eroded first. Put them back with the keys below."
                : "Not quite — read what's left of the strokes, and the meaning underneath."
        case .ismise:
            return "Follow the groove: “Is mise …”, then your own name."
        case .isas:
            return "Follow the groove: “Is as … mé” — your county in the gap."
        }
    }

    private func stripFadas(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: "á", with: "a")
            .replacingOccurrences(of: "é", with: "e")
            .replacingOccurrences(of: "í", with: "i")
            .replacingOccurrences(of: "ó", with: "o")
            .replacingOccurrences(of: "ú", with: "u")
    }
}

private extension View {
    @ViewBuilder
    func cascade(_ order: Int, appeared: Bool, reduceMotion: Bool) -> some View {
        if reduceMotion {
            opacity(appeared ? 1 : 0)
        } else {
            self
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(Motion.rise.delay(0.1 + Double(order) * 0.08), value: appeared)
        }
    }
}
