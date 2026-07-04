import SwiftUI

struct MapView: View {
    @EnvironmentObject var state: AppState
    let onOpenSession: (Int) -> Void
    @State private var showMuseum = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "Caibidil a hAon · Maigh Eo, c. 480 AD")
                    Text("Cúig sheisiún — five sessions")
                        .font(.system(size: 26, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text("A stone-carver on the Mayo coast has work to finish, and you have a language to reclaim.")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(.top, 24)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(state.chapter.sessions.enumerated()), id: \.offset) { index, session in
                        WaypointRow(
                            number: index + 1,
                            session: session,
                            done: state.done[index],
                            action: { onOpenSession(index) })
                    }
                }

                if state.allDone {
                    Button {
                        showMuseum = true
                    } label: {
                        Text("Do Mhúsaem — your artifact →")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.lichen)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 48)
            .frame(maxWidth: 640)
        }
        .sheet(isPresented: $showMuseum) {
            ScrollView {
                ArtifactView(isLast: false, onContinue: {})
                    .padding(22)
            }
            .presentationBackground(Theme.bg)
        }
    }
}

private struct WaypointRow: View {
    let number: Int
    let session: Session
    let done: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Circle()
                    .fill(done ? Theme.moss : Theme.stone)
                    .frame(width: 13, height: 13)
                    .offset(y: 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(number) · \(session.ga)")
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text(session.en)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                if done {
                    Text("carved ✓")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.moss)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Theme.raised)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
