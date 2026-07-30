import SwiftUI

struct InteractionStudyGalleryView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                EditorialScreenHeader(
                    context: "Internal interaction lab · no story layer",
                    title: "Three small learning loops",
                    detail: "Start touching immediately. Judge the task framing, response, feedback and desire to go again—not a learning architecture.",
                    accent: Theme.moss
                )

                VStack(spacing: 12) {
                    ForEach(InteractionStudyID.allCases) { study in
                        NavigationLink(value: AtlasRoute.interactionStudy(study.rawValue)) {
                            studyRow(study)
                        }
                        .buttonStyle(InteractionStudyPressStyle())
                        .accessibilityIdentifier("interaction-study-card-\(study.rawValue)")
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("The fixed material")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)

                    Text("farraige · bá · áit")
                        .font(.system(.title2, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .accessibilityLabel("farraige, bá, áit")

                    Text(ClewBayInteractionStudyFixture.sentence)
                        .font(.system(.title2, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)

                    Text("Every study is local, disposable and isolated from county progress, carried words and review scheduling.")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(3)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "Fixed material: farraige, bá, áit. \(ClewBayInteractionStudyFixture.sentence)"
                )
                .accessibilityIdentifier("interaction-study-fixed-material")
            }
            .padding(.horizontal, EditorialLayout.pageInset)
            .padding(.vertical, 26)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Interaction studies")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("interaction-studies-gallery")
    }

    private func studyRow(_ study: InteractionStudyID) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: study.symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.moss)
                .frame(width: 48, height: 48)
                .background(Theme.mossTint)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(study.title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text(study.shortSummary)
                    .font(.body)
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.inkFaint)
                .padding(.top, 16)
                .accessibilityHidden(true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .background(Theme.raised)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(study.title). \(study.shortSummary)")
    }
}
