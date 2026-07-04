import SwiftUI

struct CoverView: View {
    @EnvironmentObject var state: AppState
    let onBegin: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    Spacer()
                    OghamStoneView(word: "failte", width: 120)
                    Spacer()
                }
                .padding(.top, 24)

                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "An Turas · Caibidil a hAon")
                    Text(state.chapter.title)
                        .font(.system(size: 34, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text(state.chapter.subtitle)
                        .font(.system(size: 17, design: .serif))
                        .foregroundStyle(Theme.inkSoft)
                }

                Text("Before Ireland wrote on vellum, she wrote on stone — names, carved in strokes along an edge, meant to outlast the people who spoke them. In this chapter you learn Irish the way it first survived: one name at a time. Five short sessions. Every correct answer carves a stroke.")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(4)

                Button(action: onBegin) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tosaigh an turas")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Begin the journey · 5 sessions · ~10 min each")
                            .font(.system(size: 11))
                            .opacity(0.75)
                    }
                    .foregroundStyle(Theme.bg)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Theme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                }

                Text("Prototype for playtesting. Draft content awaiting native-speaker review. Audio is coming (see ABAIR plan) — for now, pronunciation is shown as rough English respelling.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.top, 12)
                    .overlay(Rectangle().fill(Theme.line).frame(height: 1), alignment: .top)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 48)
            .frame(maxWidth: 640)
        }
    }
}
