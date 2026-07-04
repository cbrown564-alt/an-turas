import SwiftUI

// The chapter's closing artifact: the learner's name carved in ogham.
// Also shown standalone from the map as "Do Mhúsaem".

struct ArtifactView: View {
    @EnvironmentObject var state: AppState
    @State private var name = ""
    @State private var carvedName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Déantán · Artifact", color: Theme.lichen)
                Text("Do chloch féin — your own stone")
                    .font(.system(size: 23, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.bottom, 2)
            Text("Dáire owes you a wage for the week. He takes a small slab of the same grey stone and asks what name he should cut. Carve your name the way the first Irish writers would have — read it from the bottom up.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(4)

            HStack(spacing: 8) {
                TextField("Your name", text: $name)
                    .font(.system(size: 17, design: .serif))
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit { carve() }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Theme.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line, lineWidth: 1))
                Button("Snoigh é — carve it") { carve() }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.bg)
                    .padding(.vertical, 13)
                    .padding(.horizontal, 16)
                    .background(Theme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .buttonStyle(CarvePress())
            }
            .padding(.top, 4)

            if let carved = carvedName {
                HStack {
                    Spacer()
                    // The payoff of the chapter: your own name cut stroke by
                    // stroke, each one a tick of the chisel under your thumb.
                    OghamStoneView(word: carved, width: 160, carve: true, ticks: true)
                        .id(carved)
                    Spacer()
                }
                .transition(.offset(y: 14).combined(with: .opacity))
                Text("\(carved.uppercased()) — read upward from the base")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkFaint)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                Text(notesText(for: carved))
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(3)
            }
        }
        .onAppear {
            if name.isEmpty, !state.learnerName.isEmpty {
                name = state.learnerName
                carvedName = state.learnerName
            }
        }
    }

    private func carve() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Haptics.chisel()
        withAnimation(Motion.settle) { carvedName = trimmed }
    }

    private func notesText(for carved: String) -> String {
        let notes = Ogham.letters(for: carved).notes
        if notes.isEmpty {
            return "Every letter of your name existed in the ogham alphabet — no substitutions needed."
        }
        return "Carver's notes: " + notes.joined(separator: " · ")
            + ". Ogham was cut for Primitive Irish — letters it never had borrow later signs."
    }
}
