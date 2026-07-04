import SwiftUI
import UIKit

// MARK: - Design tokens: "limestone day" / "night on the shore"
// Ported from prototype/index.html — the frozen design reference.

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { trait in
            let v = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((v >> 16) & 0xFF) / 255,
                green: CGFloat((v >> 8) & 0xFF) / 255,
                blue: CGFloat(v & 0xFF) / 255,
                alpha: 1)
        })
    }
}

enum Theme {
    static let bg       = Color(light: 0xECEDE7, dark: 0x131714)
    static let raised   = Color(light: 0xF7F7F2, dark: 0x1C211C)
    static let sunk     = Color(light: 0xE2E4DB, dark: 0x0E120F)
    static let ink      = Color(light: 0x23281F, dark: 0xD9DCD1)
    static let inkSoft  = Color(light: 0x5A6153, dark: 0x9AA294)
    static let inkFaint = Color(light: 0x8B917F, dark: 0x6B7365)
    static let line     = Color(light: 0xCBCEC1, dark: 0x333B33)
    static let stone    = Color(light: 0xAEB4A6, dark: 0x4A524A)
    static let moss     = Color(light: 0x4C6647, dark: 0x95B28B)
    static let lichen   = Color(light: 0x8F7414, dark: 0xD2A93C)
    static let rust     = Color(light: 0xA34D3B, dark: 0xC97A66)

    static var mossTint: Color { moss.opacity(0.12) }
    static var rustTint: Color { rust.opacity(0.12) }
}

// MARK: - Reusable text styles

struct Eyebrow: View {
    let text: String
    var color: Color = Theme.inkSoft
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .kerning(1.6)
            .foregroundStyle(color)
    }
}

// Renders a markdown paragraph whose [links](turas://g/N) are tappable glosses.
struct GlossText: View {
    let markdown: String
    let glosses: [Gloss]
    @Binding var activeGloss: Gloss?
    var font: Font = .system(size: 19, design: .serif)

    var body: some View {
        Text(attributed)
            .font(font)
            .lineSpacing(5)
            .environment(\.openURL, OpenURLAction { url in
                if url.scheme == "turas",
                   let idx = Int(url.lastPathComponent),
                   glosses.indices.contains(idx) {
                    activeGloss = glosses[idx]
                    return .handled
                }
                return .systemAction
            })
    }

    private var attributed: AttributedString {
        var str = (try? AttributedString(
            markdown: markdown,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(markdown)
        for run in str.runs where run.link != nil {
            str[run.range].foregroundColor = Theme.moss
            str[run.range].underlineStyle = Text.LineStyle(pattern: .dot, color: Theme.moss.opacity(0.6))
            str[run.range].font = font.weight(.semibold)
        }
        return str
    }
}

struct GlossSheet: View {
    let gloss: Gloss
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(gloss.t)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.moss)
                Text("— \(gloss.g)")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.ink)
            }
            if let s = gloss.s {
                Text("rough sound: “\(s)” · real audio coming")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .presentationDetents([.height(130)])
        .presentationBackground(Theme.raised)
    }
}

// MARK: - Wrapping layout for word tiles

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.height }.reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in computeRows(proposal: proposal, subviews: subviews) {
            var x = bounds.minX
            for item in row.items {
                let size = item.sizeThatFits(.unspecified)
                item.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row { var items: [LayoutSubview] = []; var height: CGFloat = 0 }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = [Row()]
        var x: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, !rows[rows.count - 1].items.isEmpty {
                rows.append(Row())
                x = 0
            }
            rows[rows.count - 1].items.append(sub)
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
            x += size.width + spacing
        }
        return rows
    }
}
