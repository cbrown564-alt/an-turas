import SwiftUI

// An Chonair — the path. The chapter map is itself an ogham stem: a carved line
// running down the page, each session hanging off it with its number cut in
// strokes. Done sessions are carved in moss; the next one waits raised.

struct MapView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let zoomNS: Namespace.ID
    let onOpenSession: (Int) -> Void

    @State private var showMuseum = false
    @State private var appeared = false

    private var nextIndex: Int? { state.done.firstIndex(of: false) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                    .padding(.top, 12)

                VStack(spacing: 0) {
                    ForEach(Array(state.chapter.sessions.enumerated()), id: \.offset) { index, session in
                        WaypointRow(
                            number: index + 1,
                            session: session,
                            done: state.done[index],
                            isNext: index == nextIndex,
                            isFirst: index == 0,
                            isLast: index == state.chapter.sessions.count - 1 && !state.allDone)
                        {
                            Haptics.tap()
                            onOpenSession(index)
                        }
                        .zoomSource(id: index, ns: zoomNS)
                        .cascade(index, appeared: appeared, reduceMotion: reduceMotion)
                    }

                    if state.allDone {
                        museumRow
                            .cascade(state.chapter.sessions.count, appeared: appeared, reduceMotion: reduceMotion)
                    }
                }
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
                withAnimation { appeared = true }
            }
        }
        .sheet(isPresented: $showMuseum) {
            ScrollView {
                ArtifactView()
                    .padding(22)
            }
            .presentationBackground(Theme.bg)
            .presentationCornerRadius(20)
            .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Caibidil a hAon · Maigh Eo, c. 480 AD")
            Text("Cúig sheisiún — five sessions")
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            Text("A stone-carver on the Mayo coast has work to finish, and you have a language to reclaim.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSoft)
            // Returning learners land here, not on the cover — the map owns
            // the welcome back.
            if state.done.contains(true), !state.allDone {
                Text("Tá tú ar ais — you're back. Dáire kept your place.")
                    .font(.system(size: 14.5, design: .serif))
                    .italic()
                    .foregroundStyle(Theme.moss)
                    .padding(.top, 2)
            }
        }
    }

    private var museumRow: some View {
        HStack(alignment: .top, spacing: 0) {
            // Foot of the stem: the path ends at your museum.
            VStack(spacing: 0) {
                Rectangle().fill(Theme.moss).frame(width: 2, height: 26)
                Circle().fill(Theme.lichen).frame(width: 9, height: 9)
            }
            .frame(width: 44)

            Button {
                Haptics.tap()
                showMuseum = true
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Eyebrow(text: "Déantán · unlocked", color: Theme.lichen)
                    Text("Do Mhúsaem — your artifact")
                        .font(.system(size: 19, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text("The stone Dáire cut for you, with your name in strokes.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.lichen.opacity(0.5), lineWidth: 1))
                .padding(.top, 14)
            }
            .buttonStyle(CarvePress())
        }
    }
}

// MARK: - One waypoint on the stem

private struct WaypointRow: View {
    let number: Int
    let session: Session
    let done: Bool
    let isNext: Bool
    let isFirst: Bool
    let isLast: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 0) {
                OghamWaypointNumeral(
                    count: number,
                    color: done ? Theme.moss : (isNext ? Theme.ink : Theme.stone),
                    stemTop: !isFirst,
                    stemBottom: !isLast)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.ga)
                        .font(.system(size: 19, weight: .semibold, design: .serif))
                        .foregroundStyle(done || isNext ? Theme.ink : Theme.inkSoft)
                    Text(session.en)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSoft)
                    if done {
                        Text("Snoite — carved ✓")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.moss)
                            .padding(.top, 1)
                    } else if isNext {
                        Text("Lean ort — continue here →")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.lichen)
                            .padding(.top, 1)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, isNext ? 16 : 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isNext ? Theme.raised : .clear)
                        .shadow(color: Theme.ink.opacity(isNext ? 0.08 : 0), radius: 10, y: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isNext ? Theme.line : .clear, lineWidth: 1))
                .padding(.vertical, isNext ? 8 : 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(CarvePress())
        .accessibilityLabel("Seisiún \(number), \(session.ga). \(done ? "Carved." : isNext ? "Continue here." : "Not yet carved.")")
    }
}

// The session number cut in ogham: N strokes hanging right off the stem,
// the same family as B–L–F–S–N on a real pillar edge.
private struct OghamWaypointNumeral: View {
    let count: Int
    let color: Color
    let stemTop: Bool
    let stemBottom: Bool

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(stemTop ? Theme.line : .clear)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                Rectangle()
                    .fill(stemBottom ? Theme.line : .clear)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            VStack(spacing: 5) {
                ForEach(0..<count, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(color)
                        .frame(width: 16, height: 3)
                }
            }
            .offset(x: 8)
        }
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
                .offset(y: appeared ? 0 : 18)
                .animation(Motion.rise.delay(0.1 + Double(order) * 0.07), value: appeared)
        }
    }
}
