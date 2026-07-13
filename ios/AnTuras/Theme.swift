import SwiftUI
import UIKit

// MARK: - Design tokens: "limestone day" / "night on the shore"
// Ported from prototype/index.html — the frozen design reference.

extension Color {
    init(
        light: UInt32,
        dark: UInt32,
        highContrastLight: UInt32? = nil,
        highContrastDark: UInt32? = nil
    ) {
        self.init(uiColor: UIColor { trait in
            let highContrast = trait.accessibilityContrast == .high
            let v: UInt32
            if trait.userInterfaceStyle == .dark {
                v = highContrast ? (highContrastDark ?? dark) : dark
            } else {
                v = highContrast ? (highContrastLight ?? light) : light
            }
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
    // Secondary text remains above WCAG AA on both core surfaces. High Contrast
    // gets a distinct pair instead of relying on opacity changes.
    static let inkFaint = Color(
        light: 0x5F6657,
        dark: 0x9AA294,
        highContrastLight: 0x3E4539,
        highContrastDark: 0xC0C6B9
    )
    static let line     = Color(light: 0xCBCEC1, dark: 0x333B33)
    static let stone    = Color(light: 0x62695A, dark: 0x8F988A)
    static let moss     = Color(light: 0x4C6647, dark: 0x95B28B)
    static let lichen   = Color(light: 0x796100, dark: 0xD2A93C)
    // Atlas progress deliberately uses the flag colours at higher contrast:
    // green is the county in play, white is waiting, gold is a story carried.
    static let atlasGreen = Color(light: 0x0F6C2F, dark: 0x6CC98B)
    static let atlasGold  = Color(light: 0x7B5B00, dark: 0xF0C654)
    static let atlasWhite = Color(light: 0xFFFDF6, dark: 0xE9ECE2)
    static let mapInk = Color(
        light: 0x263229,
        dark: 0xE9ECE2,
        highContrastLight: 0x101711,
        highContrastDark: 0xFFFFFF
    )
    static let rust     = Color(light: 0xA34D3B, dark: 0xC97A66)

    static var mossTint: Color { moss.opacity(0.12) }
    static var rustTint: Color { rust.opacity(0.12) }
}

// MARK: - Motion tokens: everything settles like dust after a chisel strike.

enum Motion {
    /// Default settle for content arriving or changing state.
    static let settle = Animation.spring(response: 0.42, dampingFraction: 0.86)
    /// Snappy overshoot for small marks popping in (carve-bar strokes, locks).
    static let pop = Animation.spring(response: 0.32, dampingFraction: 0.55)
    /// Slower rise for story beats entering.
    static let rise = Animation.spring(response: 0.52, dampingFraction: 0.88)
}

/// Press physics for every tappable surface: a slight give, like touching stone.
struct CarvePress: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.965 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(
                reduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.7),
                value: configuration.isPressed
            )
    }
}

/// Horizontal shake for a mis-strike. Drive by incrementing an Int trigger.
struct ShakeEffect: GeometryEffect {
    var travel: CGFloat = 6
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: travel * sin(animatableData * .pi * 2 * 3), y: 0))
    }
}

extension View {
    func shake(_ trigger: Int) -> some View {
        modifier(AccessibleShakeModifier(trigger: trigger))
    }
}

private struct AccessibleShakeModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let trigger: Int

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(
                travel: reduceMotion ? 0 : 6,
                animatableData: CGFloat(trigger)
            ))
            .animation(reduceMotion ? nil : .linear(duration: 0.38), value: trigger)
    }
}

// MARK: - Shared buttons

struct PrimaryButton: View {
    let title: String
    var fullWidth = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.bg)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 13)
                .padding(.horizontal, 22)
                .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 44)
                .background(Theme.ink)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(CarvePress())
    }
}

// MARK: - Reusable text styles

struct Eyebrow: View {
    let text: String
    var color: Color = Theme.inkSoft
    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .kerning(1.6)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// Renders a markdown paragraph whose [links](turas://g/N) are tappable glosses.
struct GlossText: View {
    let markdown: String
    let glosses: [Gloss]
    @Binding var activeGloss: Gloss?
    var font: Font = .system(.body, design: .serif)
    var lineSpacing: CGFloat = 5

    var body: some View {
        Text(attributed)
            .font(font)
            .lineSpacing(lineSpacing)
            .environment(\.openURL, OpenURLAction { url in
                if url.scheme == "turas",
                   let idx = Int(url.lastPathComponent),
                   glosses.indices.contains(idx) {
                    Haptics.tap()
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
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .foregroundStyle(Theme.moss)
                Text("— \(gloss.g)")
                    .font(.body)
                    .foregroundStyle(Theme.ink)
            }
            if SpeechService.shared.canSpeak(gloss.t) {
                SoundRow(text: gloss.t,
                         hint: gloss.s.map { "rough sound: “\($0)”" },
                         label: gloss.s.map { "éist · “\($0)”" } ?? "éist — hear it")
                    .padding(.top, 2)
            } else if let s = gloss.s {
                Text("rough sound: “\(s)” · real audio coming")
                    .font(.caption)
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .presentationDetents([.height(140)])
        .presentationBackground(Theme.raised)
        .presentationCornerRadius(20)
        .presentationDragIndicator(.visible)
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
