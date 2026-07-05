import SwiftUI
import UIKit

// MARK: - Illuminated vellum initial
// The scriptorium's closing gift: your name's first letter on vellum,
// corcra vine and gorm interlace, gilded stroke by stroke.
// Hand mode: drag down the letter to lay gold leaf. Reduce Motion
// finishes on arrival.

struct IlluminatedInitialView: View {
    let name: String
    var width: CGFloat = 200
    var carve = false
    var ticks = false
    var handCarve = false
    var onCarved: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start: Date?
    @State private var carveDone = false
    @State private var autoTicked = 0
    @State private var gildProgress: CGFloat = 0
    @State private var handTicked = 0
    @State private var handDone = false

    private let height: CGFloat = 240
    private let gildLeadIn = 0.35
    private let gildDuration = 0.7

    private var initialLetter: String {
        guard let first = name.trimmingCharacters(in: .whitespaces).first else { return "?" }
        return String(first).uppercased()
    }

    private var animating: Bool { carve && !reduceMotion && !carveDone }

    private var displayProgress: CGFloat {
        if handCarve && !reduceMotion { return gildProgress }
        if !carve && !handCarve { return 1 }
        if carveDone || !animating { return 1 }
        return 0
    }

    var body: some View {
        Group {
            if handCarve && !reduceMotion {
                initialStage(progress: gildProgress, showGuide: gildProgress < 1)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Gold travels top → down the letter, like laying leaf.
                                let topY = height * 0.22
                                let botY = height * 0.78
                                let reach = min(max((value.location.y - topY) / (botY - topY), 0), 1)
                                if reach > gildProgress {
                                    gildProgress = reach
                                    handProgressed()
                                }
                            })
            } else {
                TimelineView(.animation(minimumInterval: 1 / 40, paused: !animating)) { timeline in
                    let elapsed = elapsedTime(at: timeline.date)
                    let progress = gildProgress(at: elapsed)
                    initialStage(progress: progress, showGuide: progress < 1)
                        .onChange(of: progress) { _, p in
                            guard animating else { return }
                            let ticksTotal = 8
                            let started = Int(p * CGFloat(ticksTotal))
                            if ticks, started > autoTicked, started < ticksTotal {
                                autoTicked = started
                                Haptics.tick()
                            }
                            if p >= 1, !carveDone {
                                carveDone = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    onCarved?()
                                }
                            }
                        }
                }
            }
        }
        .frame(width: width, height: height)
        .onAppear {
            if start == nil { start = Date() }
            if handCarve, reduceMotion, !handDone {
                gildProgress = 1
                handDone = true
                onCarved?()
            }
        }
        .accessibilityLabel("Illuminated initial: \(initialLetter), from \(name)")
    }

    private func handProgressed() {
        let ticksTotal = 8
        let started = Int(gildProgress * CGFloat(ticksTotal))
        if started > handTicked {
            handTicked = started
            if ticks { Haptics.tick() }
        }
        if gildProgress >= 1, !handDone {
            handDone = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                onCarved?()
            }
        }
    }

    private func elapsedTime(at date: Date) -> Double {
        guard animating, let start else { return .greatestFiniteMagnitude }
        return date.timeIntervalSince(start)
    }

    private func gildProgress(at elapsed: Double) -> CGFloat {
        guard elapsed < .greatestFiniteMagnitude else { return 1 }
        guard elapsed > gildLeadIn else { return 0 }
        return min(max(CGFloat((elapsed - gildLeadIn) / gildDuration), 0), 1)
    }

    private func initialStage(progress: CGFloat, showGuide: Bool) -> some View {
        ZStack {
            vellumCanvas(progress: progress, showGuide: showGuide)
            letterLayer(progress: progress, showGuide: showGuide)
        }
    }

    private func vellumCanvas(progress: CGFloat, showGuide: Bool) -> some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height) / 200
            ctx.translateBy(x: (size.width - 200 * s) / 2, y: (size.height - 240 * s) / 2)
            ctx.scaleBy(x: s, y: s)

            let page = CGRect(x: 20, y: 16, width: 160, height: 208)
            ctx.fill(
                Path(roundedRect: page, cornerRadius: 4),
                with: .linearGradient(
                    Gradient(colors: [
                        Color(light: 0xF5F0E4, dark: 0x3A3830),
                        Color(light: 0xEDE6D6, dark: 0x2E2C26),
                    ]),
                    startPoint: page.origin,
                    endPoint: CGPoint(x: page.maxX, y: page.maxY)))

            ctx.stroke(
                Path(roundedRect: page.insetBy(dx: 6, dy: 6), cornerRadius: 3),
                with: .color(Theme.inkFaint.opacity(0.45)),
                style: StrokeStyle(lineWidth: 1.5))

            // Corcra vine — upper knotwork (lichen purple-red).
            let vineP = min(max((progress - 0.15) / 0.35, 0), 1)
            if vineP > 0 {
                var vine = Path()
                vine.move(to: CGPoint(x: 58, y: 52))
                vine.addQuadCurve(to: CGPoint(x: 100, y: 52), control: CGPoint(x: 79, y: 38))
                vine.addQuadCurve(to: CGPoint(x: 142, y: 52), control: CGPoint(x: 121, y: 66))
                ctx.stroke(vine,
                           with: .color(Theme.rust.opacity(0.35 + 0.55 * vineP)),
                           style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            } else if showGuide {
                var guide = Path()
                guide.move(to: CGPoint(x: 58, y: 52))
                guide.addQuadCurve(to: CGPoint(x: 142, y: 52), control: CGPoint(x: 100, y: 38))
                ctx.stroke(guide,
                           with: .color(Theme.ink.opacity(0.12)),
                           style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [3, 4]))
            }

            // Gorm interlace — lower knotwork (moss blue-green).
            let knotP = min(max((progress - 0.35) / 0.35, 0), 1)
            if knotP > 0 {
                var knot = Path()
                knot.move(to: CGPoint(x: 70, y: 178))
                knot.addQuadCurve(to: CGPoint(x: 100, y: 192), control: CGPoint(x: 85, y: 168))
                knot.addQuadCurve(to: CGPoint(x: 130, y: 178), control: CGPoint(x: 115, y: 198))
                ctx.stroke(knot,
                           with: .color(Theme.moss.opacity(0.35 + 0.55 * knotP)),
                           style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            } else if showGuide, progress < 0.35 {
                var guide = Path()
                guide.move(to: CGPoint(x: 70, y: 178))
                guide.addQuadCurve(to: CGPoint(x: 130, y: 178), control: CGPoint(x: 100, y: 192))
                ctx.stroke(guide,
                           with: .color(Theme.ink.opacity(0.12)),
                           style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [3, 4]))
            }
        }
    }

    private func letterLayer(progress: CGFloat, showGuide: Bool) -> some View {
        ZStack {
            Text(initialLetter)
                .font(.system(size: width * 0.42, weight: .bold, design: .serif))
                .foregroundStyle(Theme.ink.opacity(showGuide && progress < 0.08 ? 0.18 : 0.22))

            Text(initialLetter)
                .font(.system(size: width * 0.42, weight: .bold, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(light: 0xC9A227, dark: 0xD4AF37),
                            Color(light: 0xE8D48B, dark: 0xF0E2A8),
                            Color(light: 0xA8861C, dark: 0xB8942E),
                        ],
                        startPoint: .top,
                        endPoint: .bottom))
                .mask(alignment: .bottom) {
                    Rectangle()
                        .frame(height: max(width * 0.42 * 1.15 * progress, progress > 0 ? 2 : 0))
                }
        }
        .frame(height: height * 0.55)
        .offset(y: 8)
    }
}
