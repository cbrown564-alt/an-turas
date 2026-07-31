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
    static let atlantic = Color(light: 0x111C22, dark: 0x0B1419)
    static let storm    = Color(light: 0x33464C, dark: 0x81969B)
    static let weatheredGold = Color(light: 0x9A7618, dark: 0xD7B64D)
    static let salt     = Color(light: 0xF2F3EC, dark: 0xF2F3EC)

    static var mossTint: Color { moss.opacity(0.12) }
    /// Deeper moss fill for a confirmed-correct tile; `mossTint` marks selection.
    static var mossTintDeep: Color { moss.opacity(0.2) }
    static var rustTint: Color { rust.opacity(0.12) }
}

/// Shared exercise surface grammar — distinct forms per role so hierarchy is
/// visible without reading labels (Phase A craft vs Duo).
enum ExerciseSurface {
    static let tileRadius: CGFloat = 14
    static let chipRadius: CGFloat = 8
    static let trayRadius: CGFloat = 12
    static let capsuleRadius: CGFloat = 999
    static let choiceMinHeight: CGFloat = 64
    /// Matching-board tiles: taller than a choice row so half-width tiles
    /// still breathe when a meaning wraps.
    static let matchTileMinHeight: CGFloat = 72
    static let chipMinHeight: CGFloat = 48
    static let listenTrayMinHeight: CGFloat = 88
    static let slowCapsuleMinHeight: CGFloat = 44
    static let slowCapsuleMinWidth: CGFloat = 56
    static let zoneGap: CGFloat = 20
    static let choiceGap: CGFloat = 10
    /// Gap inside tile grids (matching stacks, builder bank and answer).
    static let tileGridSpacing: CGFloat = 12
    /// Option-tile interior padding.
    static let optionPadH: CGFloat = 16
    static let optionPadV: CGFloat = 14
    /// Border weights: resting hairline, mid emphasis, committed state.
    static let borderHairline: CGFloat = 1
    static let borderEmphasis: CGFloat = 1.5
    static let borderState: CGFloat = 2
    static let tactileLip: CGFloat = 3
}

/// Bottom lip on raised tiles — limestone tactile cue, not cartoon 3D.
struct TactileLip: ViewModifier {
    var radius: CGFloat = ExerciseSurface.tileRadius
    var active: Bool = true
    /// Tightened bottom corners for transcript-aligned tiles; nil mirrors `radius`.
    var bottomLeadingRadius: CGFloat? = nil
    var bottomTrailingRadius: CGFloat? = nil

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if active {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: bottomLeadingRadius ?? radius,
                    bottomTrailingRadius: bottomTrailingRadius ?? radius,
                    topTrailingRadius: 0
                )
                .fill(Theme.sunk.opacity(0.9))
                .frame(height: ExerciseSurface.tactileLip)
                .offset(y: ExerciseSurface.tactileLip)
                .allowsHitTesting(false)
            }
        }
    }
}

extension View {
    func tactileLip(
        radius: CGFloat = ExerciseSurface.tileRadius,
        active: Bool = true,
        bottomLeadingRadius: CGFloat? = nil,
        bottomTrailingRadius: CGFloat? = nil
    ) -> some View {
        modifier(TactileLip(
            radius: radius,
            active: active,
            bottomLeadingRadius: bottomLeadingRadius,
            bottomTrailingRadius: bottomTrailingRadius
        ))
    }
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
    var enabled = true
    var accessibilityIdentifier: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                // Disabled stays plainly readable on the sunk fill (D9 bar):
                // half-strength ink, not a pale gray whisper.
                .foregroundStyle(enabled ? Theme.bg : Theme.ink.opacity(0.55))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 13)
                .padding(.horizontal, 22)
                .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 44)
                .background(enabled ? Theme.ink : Theme.sunk)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay {
                    if !enabled {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Theme.line, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(CarvePress())
        .disabled(!enabled)
        .accessibilityIdentifier(accessibilityIdentifier ?? title)
    }
}

/// A low-emphasis hint affordance — not a bordered control.
struct QuietHintButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.moss)
                .frame(minHeight: 44, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
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

// MARK: - Editorial composition

/// Shared page rhythm for image-led and text-led surfaces. Individual story
/// heroes may break out to full width; readable prose returns to this column.
enum EditorialLayout {
    static let pageInset: CGFloat = 20
    static let readingWidth: CGFloat = 680
    static let groupGap: CGFloat = 10
    static let sectionGap: CGFloat = 30
}

/// Context is written as supplied. Uppercase remains available for genuinely
/// archival or cartographic labels without turning every heading into a badge.
struct EditorialContextLabel: View {
    let text: String
    var color: Color = Theme.inkSoft

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .kerning(0.9)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// The image-free equivalent of an editorial hero: one contextual line, one
/// typographic anchor, and a short orientation. Uses semantic type throughout.
struct EditorialScreenHeader: View {
    let context: String
    let title: String
    var detail: String?
    var accent: Color = Theme.inkSoft

    var body: some View {
        VStack(alignment: .leading, spacing: EditorialLayout.groupGap) {
            if !context.isEmpty {
                EditorialContextLabel(text: context, color: accent)
            }
            Text(title)
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(.body)
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A lighter section transition for narrative sequence. It avoids introducing
/// a card simply to separate a label, title, and supporting sentence.
struct EditorialSectionHeader: View {
    let context: String?
    let title: String
    var detail: String?
    var accent: Color = Theme.inkSoft

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let context, !context.isEmpty {
                EditorialContextLabel(text: context, color: accent)
            }
            Text(title)
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(.body)
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EditorialRule: View {
    var color: Color = Theme.line

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: 0.7)
            .accessibilityHidden(true)
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
