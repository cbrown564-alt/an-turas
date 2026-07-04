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

struct OghamStoneView: View {
    let word: String
    var width: CGFloat = 170

    private let strokeRow: CGFloat = 13
    private let letterGap: CGFloat = 9
    private let wordGap: CGFloat = 20
    private let tick: CGFloat = 26

    private var letters: [Character] { Ogham.letters(for: word).letters }

    private var stemLength: CGFloat {
        letters.reduce(CGFloat(0)) { acc, ch in
            if ch == " " { return acc + wordGap }
            let g = Ogham.alphabet[ch]!
            return acc + CGFloat(g.strokes) * strokeRow + letterGap
        } + 60
    }

    private var height: CGFloat { max(stemLength + 80, 240) }

    var body: some View {
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

            // Stemline.
            var stem = Path()
            stem.move(to: CGPoint(x: cx, y: botY))
            stem.addLine(to: CGPoint(x: cx, y: topY))
            ctx.stroke(stem, with: .color(Theme.ink.opacity(0.55)), lineWidth: 2)

            // Strokes, bottom → top.
            var y = botY - 22
            let ink = GraphicsContext.Shading.color(Theme.ink)
            for ch in letters {
                if ch == " " { y -= wordGap; continue }
                let glyph = Ogham.alphabet[ch]!
                for _ in 0..<glyph.strokes {
                    var p = Path()
                    switch glyph.group {
                    case .right:
                        p.move(to: CGPoint(x: cx, y: y)); p.addLine(to: CGPoint(x: cx + tick, y: y))
                    case .left:
                        p.move(to: CGPoint(x: cx - tick, y: y)); p.addLine(to: CGPoint(x: cx, y: y))
                    case .across:
                        p.move(to: CGPoint(x: cx - tick, y: y + 5)); p.addLine(to: CGPoint(x: cx + tick, y: y - 5))
                    case .vowel:
                        p.move(to: CGPoint(x: cx - 8, y: y)); p.addLine(to: CGPoint(x: cx + 8, y: y))
                    case .peith:
                        p.move(to: CGPoint(x: cx, y: y + 5))
                        p.addQuadCurve(to: CGPoint(x: cx, y: y - 5), control: CGPoint(x: cx + 14, y: y))
                    }
                    ctx.stroke(p, with: ink, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    y -= strokeRow
                }
                y -= letterGap
            }
        }
        .frame(width: width, height: height * (width / 150))
        .accessibilityLabel("Ogham inscription: \(word)")
    }
}

private extension UIColor {
    var swiftUI: Color { Color(uiColor: self) }
}

// MARK: - Carving progress bar (one stroke per solved exercise)

struct CarveBarView: View {
    let total: Int
    let done: Int

    var body: some View {
        Canvas { ctx, size in
            let y = size.height / 2
            var base = Path()
            base.move(to: CGPoint(x: 4, y: y))
            base.addLine(to: CGPoint(x: size.width - 4, y: y))
            ctx.stroke(base, with: .color(Theme.inkFaint.opacity(0.5)), lineWidth: 1.5)

            guard total > 0 else { return }
            let pad: CGFloat = 12
            let span = (size.width - pad * 2) / CGFloat(total)
            for i in 0..<total {
                let x = pad + span * (CGFloat(i) + 0.5)
                let on = i < done
                let color = Theme.moss.opacity(on ? 1 : 0.18)
                var p = Path()
                switch i % 4 {
                case 0: p.move(to: CGPoint(x: x, y: y)); p.addLine(to: CGPoint(x: x, y: y - 9))
                case 1: p.move(to: CGPoint(x: x, y: y)); p.addLine(to: CGPoint(x: x, y: y + 9))
                case 2: p.move(to: CGPoint(x: x - 4, y: y + 8)); p.addLine(to: CGPoint(x: x + 4, y: y - 8))
                default: p.move(to: CGPoint(x: x, y: y - 5)); p.addLine(to: CGPoint(x: x, y: y + 5))
                }
                ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
        }
        .frame(height: 30)
        .accessibilityLabel("\(done) of \(total) strokes carved")
    }
}
