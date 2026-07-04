import SwiftUI
import UIKit

// MARK: - Ogham transliteration + rendering
// Strokes hang off a central stemline; standing stones read bottom → top.

enum OghamGroup { case right, left, across, vowel, peith }

struct OghamGlyph {
    let group: OghamGroup
    let strokes: Int
}

enum Ogham {
    static let alphabet: [Character: OghamGlyph] = [
        "b": .init(group: .right, strokes: 1), "l": .init(group: .right, strokes: 2),
        "f": .init(group: .right, strokes: 3), "s": .init(group: .right, strokes: 4),
        "n": .init(group: .right, strokes: 5),
        "h": .init(group: .left, strokes: 1), "d": .init(group: .left, strokes: 2),
        "t": .init(group: .left, strokes: 3), "c": .init(group: .left, strokes: 4),
        "q": .init(group: .left, strokes: 5),
        "m": .init(group: .across, strokes: 1), "g": .init(group: .across, strokes: 2),
        "ŋ": .init(group: .across, strokes: 3), "z": .init(group: .across, strokes: 4),
        "r": .init(group: .across, strokes: 5),
        "a": .init(group: .vowel, strokes: 1), "o": .init(group: .vowel, strokes: 2),
        "u": .init(group: .vowel, strokes: 3), "e": .init(group: .vowel, strokes: 4),
        "i": .init(group: .vowel, strokes: 5),
        "p": .init(group: .peith, strokes: 1),
    ]

    private static let substitutions: [Character: String] = [
        "k": "c", "v": "f", "w": "f", "y": "i", "j": "i", "x": "cs",
        "á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u",
    ]

    /// Letters (or " " word gaps) ready to draw, plus carver's notes about substitutions.
    static func letters(for raw: String) -> (letters: [Character], notes: [String]) {
        var out: [Character] = []
        var notes: [String] = []
        var s = Substring(raw.lowercased())
        while let ch = s.first {
            if ch == " " { out.append(" "); s = s.dropFirst(); continue }
            if s.hasPrefix("ng") { out.append("ŋ"); s = s.dropFirst(2); continue }
            if let sub = substitutions[ch], sub.first!.isLetter, !"aeiou".contains(sub) {
                let note = "\(ch) → \(sub)"
                if !notes.contains(note) { notes.append(note) }
            }
            if ch == "p" {
                let note = "p → peith, a medieval addition"
                if !notes.contains(note) { notes.append(note) }
            }
            let mapped = substitutions[ch] ?? String(ch)
            for m in mapped where alphabet[m] != nil { out.append(m) }
            s = s.dropFirst()
        }
        return (out, notes)
    }
}

// MARK: - Standing stone with a carved inscription
// With `carve: true` the strokes appear one at a time, bottom → top, the way the
// carver would cut them; `ticks: true` adds a faint haptic per stroke.

struct OghamStoneView: View {
    let word: String
    var width: CGFloat = 170
    var carve = false
    var ticks = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start: Date?
    @State private var carveDone = false

    private let strokeRow: CGFloat = 13
    private let letterGap: CGFloat = 9
    private let wordGap: CGFloat = 20
    private let tick: CGFloat = 26

    // Carve timing: stem first, then strokes at a careful, human pace.
    private let stemLeadIn = 0.35
    private let firstStrokeAt = 0.5
    private let strokeInterval = 0.085
    private let strokeDuration = 0.14

    private var letters: [Character] { Ogham.letters(for: word).letters }

    private var totalStrokes: Int {
        letters.reduce(0) { $0 + (Ogham.alphabet[$1]?.strokes ?? 0) }
    }

    private var animating: Bool { carve && !reduceMotion && !carveDone }

    private var stemLength: CGFloat {
        letters.reduce(CGFloat(0)) { acc, ch in
            if ch == " " { return acc + wordGap }
            let g = Ogham.alphabet[ch]!
            return acc + CGFloat(g.strokes) * strokeRow + letterGap
        } + 60
    }

    private var height: CGFloat { max(stemLength + 80, 240) }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 40, paused: !animating)) { timeline in
            let elapsed = elapsedTime(at: timeline.date)
            let started = strokesStarted(at: elapsed)
            stoneCanvas(elapsed: elapsed)
                .onChange(of: started) { _, n in
                    guard animating else { return }
                    if ticks, n > 0 { Haptics.tick() }
                    if n >= totalStrokes {
                        DispatchQueue.main.asyncAfter(deadline: .now() + strokeDuration + 0.1) {
                            carveDone = true
                        }
                    }
                }
        }
        .onAppear { if start == nil { start = Date() } }
        .frame(width: width, height: height * (width / 150))
        .accessibilityLabel("Ogham inscription: \(word)")
    }

    private func elapsedTime(at date: Date) -> Double {
        guard animating, let start else { return .greatestFiniteMagnitude }
        return date.timeIntervalSince(start)
    }

    private func strokesStarted(at elapsed: Double) -> Int {
        guard elapsed < .greatestFiniteMagnitude else { return totalStrokes }
        guard elapsed > firstStrokeAt else { return 0 }
        return min(totalStrokes, Int((elapsed - firstStrokeAt) / strokeInterval) + 1)
    }

    /// 0…1 progress of stroke `index`, given elapsed carve time.
    private func strokeProgress(_ index: Int, elapsed: Double) -> Double {
        guard elapsed < .greatestFiniteMagnitude else { return 1 }
        let begins = firstStrokeAt + Double(index) * strokeInterval
        return min(max((elapsed - begins) / strokeDuration, 0), 1)
    }

    private func stoneCanvas(elapsed: Double) -> some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let topY: CGFloat = 42
            let botY = size.height - 30

            // The stone: an irregular standing slab.
            var stone = Path()
            stone.move(to: CGPoint(x: cx - 34, y: size.height - 8))
            stone.addCurve(to: CGPoint(x: cx - 26, y: topY - 12),
                           control1: CGPoint(x: cx - 40, y: size.height * 0.6),
                           control2: CGPoint(x: cx - 36, y: size.height * 0.3))
            stone.addQuadCurve(to: CGPoint(x: cx + 12, y: topY - 18),
                               control: CGPoint(x: cx - 8, y: topY - 30))
            stone.addCurve(to: CGPoint(x: cx + 32, y: size.height - 8),
                           control1: CGPoint(x: cx + 30, y: topY - 4),
                           control2: CGPoint(x: cx + 36, y: size.height * 0.45))
            stone.closeSubpath()
            ctx.fill(stone, with: .linearGradient(
                Gradient(colors: [UIColor(Theme.stone).swiftUI, UIColor(Theme.sunk).swiftUI]),
                startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
            ctx.stroke(stone, with: .color(Theme.inkFaint.opacity(0.6)), lineWidth: 1)

            // Lichen.
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 22, y: size.height * 0.28, width: 14, height: 14)),
                     with: .color(Theme.lichen.opacity(0.28)))
            ctx.fill(Path(ellipseIn: CGRect(x: cx + 9, y: size.height * 0.62, width: 10, height: 10)),
                     with: .color(Theme.lichen.opacity(0.2)))

            // Stemline, drawn bottom → top ahead of the strokes.
            let stemP = elapsed < .greatestFiniteMagnitude
                ? min(max(elapsed / stemLeadIn, 0), 1) : 1
            if stemP > 0 {
                var stem = Path()
                stem.move(to: CGPoint(x: cx, y: botY))
                stem.addLine(to: CGPoint(x: cx, y: botY - (botY - topY) * stemP))
                ctx.stroke(stem, with: .color(Theme.ink.opacity(0.55)), lineWidth: 2)
            }

            // Strokes, bottom → top, each cut outward from the stem.
            var y = botY - 22
            var strokeIndex = 0
            for ch in letters {
                if ch == " " { y -= wordGap; continue }
                let glyph = Ogham.alphabet[ch]!
                for _ in 0..<glyph.strokes {
                    let p = strokeProgress(strokeIndex, elapsed: elapsed)
                    strokeIndex += 1
                    defer { y -= strokeRow }
                    guard p > 0 else { continue }
                    let f = CGFloat(p)
                    var path = Path()
                    switch glyph.group {
                    case .right:
                        path.move(to: CGPoint(x: cx, y: y))
                        path.addLine(to: CGPoint(x: cx + tick * f, y: y))
                    case .left:
                        path.move(to: CGPoint(x: cx, y: y))
                        path.addLine(to: CGPoint(x: cx - tick * f, y: y))
                    case .across:
                        path.move(to: CGPoint(x: cx - tick, y: y + 5))
                        path.addLine(to: CGPoint(x: cx - tick + tick * 2 * f, y: y + 5 - 10 * f))
                    case .vowel:
                        path.move(to: CGPoint(x: cx - 8 * f, y: y))
                        path.addLine(to: CGPoint(x: cx + 8 * f, y: y))
                    case .peith:
                        path.move(to: CGPoint(x: cx, y: y + 5))
                        path.addQuadCurve(to: CGPoint(x: cx, y: y - 5), control: CGPoint(x: cx + 14, y: y))
                    }
                    ctx.stroke(path, with: .color(Theme.ink.opacity(0.4 + 0.6 * p)),
                               style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }
                y -= letterGap
            }
        }
    }
}

private extension UIColor {
    var swiftUI: Color { Color(uiColor: self) }
}

// MARK: - Carving progress bar (one stroke per solved exercise)
// Individual marks so each new stroke pops in with a spring.

struct CarveBarView: View {
    let total: Int
    let done: Int

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Theme.inkFaint.opacity(0.5))
                .frame(height: 1.5)
            HStack(spacing: 0) {
                ForEach(0..<max(total, 1), id: \.self) { index in
                    TickMark(variant: index % 4)
                        .stroke(Theme.moss.opacity(index < done ? 1 : 0.18),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 12, height: 22)
                        .scaleEffect(index < done ? 1 : 0.8)
                        .animation(Motion.pop, value: done)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 26)
        .accessibilityLabel("\(done) of \(total) strokes carved")
    }
}

/// One ogham-flavoured tick; variants echo the four stroke families.
struct TickMark: Shape {
    let variant: Int

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        let cy = rect.midY
        switch variant {
        case 0: p.move(to: CGPoint(x: cx, y: cy)); p.addLine(to: CGPoint(x: cx, y: cy - 9))
        case 1: p.move(to: CGPoint(x: cx, y: cy)); p.addLine(to: CGPoint(x: cx, y: cy + 9))
        case 2: p.move(to: CGPoint(x: cx - 4, y: cy + 8)); p.addLine(to: CGPoint(x: cx + 4, y: cy - 8))
        default: p.move(to: CGPoint(x: cx, y: cy - 5)); p.addLine(to: CGPoint(x: cx, y: cy + 5))
        }
        return p
    }
}
