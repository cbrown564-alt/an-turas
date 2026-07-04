import SwiftUI

// The chapter's closing artifact: the learner's name carved in ogham.
// Also shown standalone from the map as "Do Mhúsaem".

struct ArtifactView: View {
    let isLast: Bool
    let onContinue: () -> Void

    @EnvironmentObject var state: AppState
    @State private var name = ""
    @State private var carvedName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow(text: "Déantán · Artifact", color: Theme.lichen)
                Text("Do chloch féin — your own stone")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text("Dáire owes you a wage for the week. He takes a small slab of the same grey stone and asks what name he should cut. Carve your name the way the first Irish writers would have — read it from the bottom up.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.inkSoft)

                HStack(spacing: 8) {
                    TextField("Your name", text: $name)
                        .font(.system(size: 17, design: .serif))
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .onSubmit { carve() }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Theme.raised)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.line, lineWidth: 1))
                    Button("Snoigh é — carve it") { carve() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.bg)
                        .padding(.vertical, 9)
                        .padding(.horizontal, 14)
                        .background(Theme.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }

                if let carved = carvedName {
                    HStack {
                        Spacer()
                        OghamStoneView(word: carved, width: 160)
                        Spacer()
                    }
                    Text("\(carved.uppercased()) — read upward from the base")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkFaint)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    Text(notesText(for: carved))
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .padding(20)
            .background(Theme.raised)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.line, lineWidth: 1))

            if isLast { ContinueButton(action: onContinue) }
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
        carvedName = trimmed
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
