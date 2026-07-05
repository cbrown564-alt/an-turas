import SwiftUI

// MARK: - An Músaem: the collection with a pulse.
// The long-term progress surface, looking backward: every chapter leaves an
// object, every object anchors its phrases. Thirteen niches — twelve of them
// still chalk. Due reviews surface as life in the museum (a rust dot: an
// artifact's people are asking for you), never as a number badge. The shelf
// stays legitimate only because Ar Ais wires it to retrieval — otherwise
// it's a trophy room, and we marked that wreck on the chart.

struct MuseumView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onOpenArAis: () -> Void
    let onOpenChapter: () -> Void

    @State private var showStone = false
    @State private var selected: JourneyChapter?
    @State private var appeared = false

    private var dueCount: Int { state.dueVisits().count }
    private var collected: Int { state.allDone ? 1 : 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                    .padding(.top, 12)

                if dueCount > 0 {
                    pulseRow
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)],
                          spacing: 12) {
                    ForEach(state.journey) { chapter in
                        NicheView(chapter: chapter,
                                  unlocked: chapter.n == 1 && state.allDone,
                                  asking: chapter.n == 1 && dueCount > 0)
                        {
                            Haptics.tap()
                            if chapter.n == 1 && state.allDone {
                                showStone = true
                            } else {
                                selected = chapter
                            }
                        }
                    }
                }
                .opacity(appeared ? 1 : 0)

                Text("Ní pointí iad — possessions, with memory attached. Every artifact keeps its phrases, and its people come asking for you when the wind starts on the grooves.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.inkFaint)
                    .lineSpacing(3)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 48)
            .frame(maxWidth: 640)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !appeared else { return }
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.easeOut(duration: 0.4)) { appeared = true }
            }
        }
        .sheet(isPresented: $showStone) {
            ScrollView {
                ArtifactView()
                    .padding(22)
            }
            .presentationBackground(Theme.bg)
            .presentationCornerRadius(20)
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $selected) { chapter in
            ChapterCard(chapter: chapter,
                        status: chapter.n < state.currentChapterN ? .done
                              : chapter.n == state.currentChapterN ? .current : .ahead) {
                selected = nil
                onOpenChapter()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "An Músaem · do mhúsaem féin", color: Theme.lichen)
            Text("Músaem na hÉireann — yours")
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            Text("\(collected) de 13 bailithe. One artifact per chapter, personalised — your name, your county, your surname.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(4)
        }
    }

    /// Life in the museum: the artifact's people are asking for you.
    private var pulseRow: some View {
        Button {
            Haptics.tap()
            onOpenArAis()
        } label: {
            HStack(spacing: 10) {
                Circle().fill(Theme.rust).frame(width: 8, height: 8)
                Text("Tá \(Turas.people(dueCount)) ag fiafraí fút ag an gcloch — visit them.")
                    .font(.system(size: 13.5, design: .serif))
                    .italic()
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 14)
            .background(Theme.rustTint)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(Theme.rust.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(CarvePress())
    }
}

// MARK: - One niche on the shelf

private struct NicheView: View {
    let chapter: JourneyChapter
    let unlocked: Bool
    let asking: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ArtifactGlyphView(glyph: chapter.glyph,
                                  color: unlocked ? Theme.moss : Theme.stone.opacity(0.8))
                    .frame(width: 40, height: 40)
                    .padding(.top, 6)
                VStack(spacing: 2) {
                    Text(chapter.artifactGa)
                        .font(.system(size: 12.5, weight: .semibold, design: .serif))
                        .foregroundStyle(unlocked ? Theme.ink : Theme.inkSoft)
                        .multilineTextAlignment(.center)
                    Text("Ch.\(chapter.n) · \(chapter.artifactEn)")
                        .font(.system(size: 9.5))
                        .foregroundStyle(Theme.inkFaint)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .top)
            .background(unlocked ? AnyShapeStyle(Theme.raised) : AnyShapeStyle(Theme.sunk.opacity(0.55)))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(unlocked ? Theme.lichen.opacity(0.5) : Theme.line,
                            style: unlocked
                                ? StrokeStyle(lineWidth: 1)
                                : StrokeStyle(lineWidth: 1, dash: [3, 4])))
            .overlay(alignment: .topTrailing) {
                if asking {
                    Circle().fill(Theme.rust).frame(width: 8, height: 8)
                        .padding(8)
                }
            }
        }
        .buttonStyle(CarvePress())
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var text = "\(chapter.artifactGa), chapter \(chapter.n), \(chapter.artifactEn). "
        text += unlocked ? "Collected." : "Not yet collected."
        if asking { text += " Its people are asking for you." }
        return text
    }
}

// MARK: - Artifact glyphs: thirteen objects drawn with the same chisel
// Stroke-only line drawings in a 46×46 design space, one per chapter's
// artifact, echoing the carved-line language of the ogham renderer.

struct ArtifactGlyphView: View {
    let glyph: String
    let color: Color

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height) / 46
            ctx.translateBy(x: (size.width - 46 * s) / 2, y: (size.height - 46 * s) / 2)
            ctx.scaleBy(x: s, y: s)
            let style = StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
            for path in Self.paths(for: glyph) {
                ctx.stroke(path, with: .color(color), style: style)
            }
        }
        .accessibilityHidden(true)
    }

    // swiftlint:disable function_body_length
    static func paths(for glyph: String) -> [Path] {
        var p = Path()
        var extra = Path()
        switch glyph {
        case "stone":
            // The ogham pillar with strokes off both edges.
            p.move(to: CGPoint(x: 18, y: 42))
            p.addLine(to: CGPoint(x: 18, y: 10))
            p.addQuadCurve(to: CGPoint(x: 23, y: 4), control: CGPoint(x: 18, y: 4))
            p.addQuadCurve(to: CGPoint(x: 28, y: 10), control: CGPoint(x: 28, y: 4))
            p.addLine(to: CGPoint(x: 28, y: 42))
            extra.move(to: CGPoint(x: 18, y: 16)); extra.addLine(to: CGPoint(x: 12, y: 16))
            extra.move(to: CGPoint(x: 18, y: 22)); extra.addLine(to: CGPoint(x: 12, y: 22))
            extra.move(to: CGPoint(x: 28, y: 19)); extra.addLine(to: CGPoint(x: 34, y: 19))
            extra.move(to: CGPoint(x: 18, y: 30)); extra.addLine(to: CGPoint(x: 28, y: 34))
            extra.move(to: CGPoint(x: 18, y: 36)); extra.addLine(to: CGPoint(x: 28, y: 40))
        case "initial":
            // A framed initial with knotwork vesicas.
            p.addRoundedRect(in: CGRect(x: 8, y: 6, width: 30, height: 34), cornerSize: CGSize(width: 3, height: 3))
            extra.move(to: CGPoint(x: 16, y: 14))
            extra.addQuadCurve(to: CGPoint(x: 30, y: 14), control: CGPoint(x: 23, y: 8))
            extra.addQuadCurve(to: CGPoint(x: 16, y: 14), control: CGPoint(x: 23, y: 20))
            extra.move(to: CGPoint(x: 23, y: 17)); extra.addLine(to: CGPoint(x: 23, y: 33))
            extra.move(to: CGPoint(x: 16, y: 33))
            extra.addQuadCurve(to: CGPoint(x: 30, y: 33), control: CGPoint(x: 23, y: 39))
        case "armring":
            // Hack-silver: an open ring with bossed terminals.
            p.addArc(center: CGPoint(x: 23, y: 28), radius: 13,
                     startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            extra.addEllipse(in: CGRect(x: 7, y: 27, width: 6, height: 6))
            extra.addEllipse(in: CGRect(x: 33, y: 27, width: 6, height: 6))
        case "surname":
            // The origin card: a heading and a great Ó.
            p.addRoundedRect(in: CGRect(x: 10, y: 7, width: 26, height: 32), cornerSize: CGSize(width: 2, height: 2))
            extra.move(to: CGPoint(x: 15, y: 14)); extra.addLine(to: CGPoint(x: 31, y: 14))
            extra.addEllipse(in: CGRect(x: 17, y: 20, width: 12, height: 12))
            extra.move(to: CGPoint(x: 27, y: 18)); extra.addLine(to: CGPoint(x: 31, y: 15))
        case "poem":
            // A quill over the lines it left.
            p.move(to: CGPoint(x: 14, y: 34))
            p.addLine(to: CGPoint(x: 33, y: 9))
            p.move(to: CGPoint(x: 20, y: 20))
            p.addQuadCurve(to: CGPoint(x: 31, y: 13), control: CGPoint(x: 28, y: 21))
            p.move(to: CGPoint(x: 17, y: 24))
            p.addQuadCurve(to: CGPoint(x: 27, y: 17), control: CGPoint(x: 24, y: 25))
            extra.move(to: CGPoint(x: 12, y: 40)); extra.addLine(to: CGPoint(x: 26, y: 40))
            extra.move(to: CGPoint(x: 30, y: 40)); extra.addLine(to: CGPoint(x: 34, y: 40))
        case "sealed":
            // The departure letter, wax still warm.
            p.addRect(CGRect(x: 9, y: 10, width: 28, height: 22))
            p.move(to: CGPoint(x: 9, y: 10))
            p.addLine(to: CGPoint(x: 23, y: 22))
            p.addLine(to: CGPoint(x: 37, y: 10))
            extra.addEllipse(in: CGRect(x: 19, y: 32, width: 8, height: 8))
        case "hornbook":
            // Paddle, handle, and the lesson.
            p.addRoundedRect(in: CGRect(x: 13, y: 6, width: 20, height: 26), cornerSize: CGSize(width: 3, height: 3))
            p.move(to: CGPoint(x: 21, y: 32)); p.addLine(to: CGPoint(x: 21, y: 40))
            p.move(to: CGPoint(x: 25, y: 32)); p.addLine(to: CGPoint(x: 25, y: 40))
            p.move(to: CGPoint(x: 21, y: 40)); p.addLine(to: CGPoint(x: 25, y: 40))
            extra.move(to: CGPoint(x: 17, y: 13)); extra.addLine(to: CGPoint(x: 29, y: 13))
            extra.move(to: CGPoint(x: 17, y: 19)); extra.addLine(to: CGPoint(x: 29, y: 19))
            extra.move(to: CGPoint(x: 17, y: 25)); extra.addLine(to: CGPoint(x: 25, y: 25))
        case "homeletter":
            // Your letter home: a folded page, half-written.
            p.move(to: CGPoint(x: 11, y: 8))
            p.addLine(to: CGPoint(x: 27, y: 8))
            p.addLine(to: CGPoint(x: 35, y: 16))
            p.addLine(to: CGPoint(x: 35, y: 40))
            p.addLine(to: CGPoint(x: 11, y: 40))
            p.closeSubpath()
            p.move(to: CGPoint(x: 27, y: 8)); p.addLine(to: CGPoint(x: 27, y: 16)); p.addLine(to: CGPoint(x: 35, y: 16))
            extra.move(to: CGPoint(x: 16, y: 22)); extra.addLine(to: CGPoint(x: 30, y: 22))
            extra.move(to: CGPoint(x: 16, y: 28)); extra.addLine(to: CGPoint(x: 30, y: 28))
            extra.move(to: CGPoint(x: 16, y: 34)); extra.addLine(to: CGPoint(x: 24, y: 34))
        case "membership":
            // The Conradh card, name on the line.
            p.addRoundedRect(in: CGRect(x: 8, y: 12, width: 30, height: 22), cornerSize: CGSize(width: 2, height: 2))
            extra.move(to: CGPoint(x: 13, y: 18)); extra.addLine(to: CGPoint(x: 25, y: 18))
            extra.move(to: CGPoint(x: 13, y: 25)); extra.addLine(to: CGPoint(x: 33, y: 25))
            extra.addEllipse(in: CGRect(x: 29, y: 15, width: 5, height: 5))
        case "constitution":
            // The 1937 excerpt, sealed.
            p.addRect(CGRect(x: 11, y: 7, width: 24, height: 34))
            extra.move(to: CGPoint(x: 16, y: 14)); extra.addLine(to: CGPoint(x: 30, y: 14))
            extra.move(to: CGPoint(x: 16, y: 20)); extra.addLine(to: CGPoint(x: 30, y: 20))
            extra.move(to: CGPoint(x: 16, y: 26)); extra.addLine(to: CGPoint(x: 25, y: 26))
            extra.addEllipse(in: CGRect(x: 26, y: 30, width: 7, height: 7))
        case "verse":
            // Sean-nós: three long breaths of melody.
            for (i, y) in [15, 24, 33].enumerated() {
                p.move(to: CGPoint(x: 9, y: CGFloat(y)))
                p.addQuadCurve(to: CGPoint(x: 19, y: CGFloat(y)), control: CGPoint(x: 14, y: CGFloat(y) - 8))
                p.addQuadCurve(to: CGPoint(x: 29, y: CGFloat(y)), control: CGPoint(x: 24, y: CGFloat(y) + 8))
                if i != 1 {
                    p.addQuadCurve(to: CGPoint(x: 37, y: CGFloat(y) - 3), control: CGPoint(x: 34, y: CGFloat(y) - 6))
                }
            }
        case "mural":
            // A gable wall, and the stroke of paint across it.
            p.addRect(CGRect(x: 8, y: 10, width: 30, height: 26))
            p.move(to: CGPoint(x: 8, y: 19)); p.addLine(to: CGPoint(x: 38, y: 19))
            p.move(to: CGPoint(x: 8, y: 28)); p.addLine(to: CGPoint(x: 38, y: 28))
            p.move(to: CGPoint(x: 18, y: 10)); p.addLine(to: CGPoint(x: 18, y: 19))
            p.move(to: CGPoint(x: 28, y: 19)); p.addLine(to: CGPoint(x: 28, y: 28))
            p.move(to: CGPoint(x: 18, y: 28)); p.addLine(to: CGPoint(x: 18, y: 36))
            extra.move(to: CGPoint(x: 12, y: 33))
            extra.addQuadCurve(to: CGPoint(x: 34, y: 14), control: CGPoint(x: 18, y: 18))
        case "fainne":
            // An Fáinne: the ring itself, nothing else needed.
            p.addEllipse(in: CGRect(x: 11, y: 11, width: 24, height: 24))
            extra.addEllipse(in: CGRect(x: 14.5, y: 14.5, width: 17, height: 17))
        default:
            p.addEllipse(in: CGRect(x: 16, y: 16, width: 14, height: 14))
        }
        return [p, extra]
    }
    // swiftlint:enable function_body_length
}
