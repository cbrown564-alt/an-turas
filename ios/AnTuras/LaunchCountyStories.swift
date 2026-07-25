import SwiftUI

// MARK: - Pack-backed atlas presentation

enum LaunchStoryClearance: String, Equatable {
    case cleared = "Reviewed story"
    case reviewDraft = "Review draft"
    case editorialPreview = "Editorial preview"
}

enum LaunchObjectKind: String, Equatable {
    case cross, penny, castle
}

struct LaunchSourceFact: Identifiable {
    let id: String
    let certainty: EvidenceCertainty
    let text: String
}

struct LaunchEpisode: Identifiable {
    let id: String
    let title: String
    let place: String
}

/// A read-only presentation adapter for atlas surfaces that predate the version-two
/// page renderer. All story, language, evidence and review copy remains owned by the
/// county pack.
struct LaunchCountyStory: Identifiable {
    let pack: CountyStoryPack

    var id: String { pack.id }
    var countyGa: String { pack.presentation.countyGa }
    var countyEn: String { pack.presentation.countyEn }
    var province: String { pack.presentation.province }
    var title: String { pack.title }
    var era: String { pack.presentation.era }
    var anchor: String { pack.presentation.anchor }
    var question: String { pack.presentation.question }
    var opening: String { pack.presentation.opening }
    var sourceTitle: String { pack.presentation.sourceTitle }
    var sourceDetail: String { pack.presentation.sourceDetail }
    var evidenceLimit: String { pack.presentation.evidenceLimit }
    var tegLevel: String { pack.presentation.tegLevel }
    var tegCanDo: String { pack.presentation.tegCanDo }
    var artifactTitle: String { pack.presentation.artifactTitle }
    var artifactPrompt: String { pack.presentation.artifactPrompt }
    var words: [AtlasWord] { pack.targetWords }

    var objectKind: LaunchObjectKind {
        switch pack.id {
        case let id where id.hasPrefix("offaly."): return .cross
        case let id where id.hasPrefix("dublin."): return .penny
        default: return .castle
        }
    }

    var clearance: LaunchStoryClearance {
        if pack.isReleaseCleared { return .cleared }
        if pack.isReviewDraft { return .reviewDraft }
        return .editorialPreview
    }

    var reviewGate: String {
        let open = pack.openReviewGateTitles
        if open.isEmpty { return "The recorded history, language, audio and rights reviews are complete." }
        return "Open review gates: \(open.joined(separator: ", "))."
    }

    var episodes: [LaunchEpisode] {
        pack.chapters.map { .init(id: $0.id, title: $0.title, place: $0.place) }
    }

    var sourceFacts: [LaunchSourceFact] {
        let evidence = pack.resources.filter { $0.kind == .evidence || $0.kind == .source }
        if evidence.isEmpty {
            return [
                .init(
                    id: "\(pack.id).source",
                    certainty: .unknown,
                    text: "\(sourceTitle). \(sourceDetail)"
                ),
            ]
        }
        return evidence.map { resource in
            .init(
                id: resource.id,
                certainty: resource.kind == .evidence ? .material : .documented,
                text: "\(resource.value). \(resource.status.replacingOccurrences(of: "-", with: " "))."
            )
        }
    }
}

enum LaunchCountyCatalog {
    static let stories: [LaunchCountyStory] = CountyStoryPackCatalog.packs
        .filter { $0.id != "mayo.grainne-1593" }
        .map(LaunchCountyStory.init(pack:))

    static func story(id: String) -> LaunchCountyStory? {
        stories.first { $0.id == id }
    }

    static func story(county: String) -> LaunchCountyStory? {
        stories.first { $0.countyEn == county }
    }
}

struct AtlasReviewCandidate: Identifiable {
    let storyID: String
    let county: String
    let word: AtlasWord

    var id: String { "\(storyID)|\(word.ga)" }
}

// MARK: - Shared county dossier

struct LaunchCountyDossierView: View {
    @EnvironmentObject private var atlas: AtlasPrototypeModel
    let story: LaunchCountyStory
    let onBegin: () -> Void
    let onEvidence: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EditorialLayout.sectionGap) {
                EditorialScreenHeader(
                    context: "\(story.countyGa) · \(story.countyEn) · \(story.era)",
                    title: story.title,
                    detail: story.anchor,
                    accent: atlas.isCountyComplete(story.id) ? Theme.atlasGold : Theme.atlasGreen
                )

                objectOpening

                EditorialSectionHeader(
                    context: "The question",
                    title: story.question,
                    detail: story.opening
                )

                launchState

                VStack(alignment: .leading, spacing: 12) {
                    Text("\(story.episodes.count) chapter preview · twenty provisional words")
                        .font(.system(.title2, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    ForEach(Array(story.episodes.enumerated()), id: \.element.id) { index, episode in
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.monospacedDigit().weight(.bold))
                                .foregroundStyle(Theme.inkFaint)
                                .frame(width: 20, alignment: .leading)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(episode.title).font(.headline).foregroundStyle(Theme.ink)
                                Text(episode.place).font(.caption).foregroundStyle(Theme.inkSoft)
                            }
                        }
                        .padding(.vertical, 6)
                        if index < story.episodes.count - 1 { EditorialRule() }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    EditorialContextLabel(text: "External progress", color: Theme.moss)
                    Text(story.tegLevel)
                        .font(.system(.title2, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(story.tegCanDo).font(.body).foregroundStyle(Theme.inkSoft)
                }

                PrimaryButton(
                    title: atlas.mode(for: story.id) == nil ? "Choose a mode" : "Continue in \(story.countyEn)",
                    fullWidth: true,
                    action: onBegin
                )
            }
            .padding(EditorialLayout.pageInset)
            .padding(.bottom, 34)
            .frame(maxWidth: EditorialLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(story.countyEn)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var objectOpening: some View {
        Button(action: onEvidence) {
            HStack(spacing: 20) {
                LaunchObjectMark(kind: story.objectKind)
                    .frame(width: 116, height: 116)
                VStack(alignment: .leading, spacing: 7) {
                    Text(story.sourceTitle)
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(story.sourceDetail)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                    Label("Open the evidence record", systemImage: "doc.text.magnifyingglass")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.moss)
                        .frame(minHeight: 44)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(CarvePress())
        .accessibilityLabel("Open the evidence record")
        .accessibilityHint("Opens provenance, certainty and release status")
    }

    private var launchState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                story.clearance.rawValue,
                systemImage: story.clearance == .cleared ? "checkmark.seal" : "person.2.badge.gearshape"
            )
            .font(.headline)
            .foregroundStyle(story.clearance == .cleared ? Theme.moss : Theme.rust)
            Text(story.reviewGate)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(3)
        }
        .padding(16)
        .background(story.clearance == .cleared ? Theme.mossTint : Theme.rustTint)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Evidence record

struct LaunchEvidenceView: View {
    @EnvironmentObject private var atlas: AtlasPrototypeModel
    let story: LaunchCountyStory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EditorialLayout.sectionGap) {
                EditorialScreenHeader(
                    context: "Evidence record · \(story.countyEn)",
                    title: story.sourceTitle,
                    detail: story.sourceDetail,
                    accent: Theme.lichen
                )

                LaunchObjectMark(kind: story.objectKind)
                    .frame(height: 190)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Interpretive diagram identifying the evidence type; not the historical object")

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(story.sourceFacts) { fact in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: fact.certainty.icon)
                                .foregroundStyle(fact.certainty.color)
                                .frame(width: 24, height: 44, alignment: .top)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(fact.text).font(.body).foregroundStyle(Theme.ink)
                                Text(fact.certainty.rawValue.capitalized)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    EditorialContextLabel(text: "What this does not prove", color: Theme.rust)
                    Text(story.evidenceLimit)
                        .font(.body)
                        .foregroundStyle(Theme.ink)
                        .lineSpacing(4)
                }
                .padding(16)
                .background(Theme.rustTint)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 8) {
                    Label(
                        story.clearance.rawValue,
                        systemImage: story.clearance == .cleared ? "checkmark.seal" : "person.2.badge.gearshape"
                    )
                    .font(.headline)
                    .foregroundStyle(story.clearance == .cleared ? Theme.moss : Theme.rust)
                    Text(story.reviewGate).font(.subheadline).foregroundStyle(Theme.inkSoft)
                }

                Button {
                    atlas.markEvidenceInspected(story.id)
                    Haptics.tap()
                } label: {
                    Label(
                        atlas.hasInspectedEvidence(story.id) ? "Evidence record inspected" : "Mark this record inspected",
                        systemImage: atlas.hasInspectedEvidence(story.id) ? "checkmark" : "eye"
                    )
                    .font(.headline)
                    .foregroundStyle(Theme.moss)
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(CarvePress())
            }
            .padding(EditorialLayout.pageInset)
            .padding(.bottom, 34)
            .frame(maxWidth: EditorialLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Evidence")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { atlas.markEvidenceInspected(story.id) }
    }
}

// MARK: - Rights-safe object diagrams

struct LaunchObjectMark: View {
    let kind: LaunchObjectKind
    var compact = false

    var body: some View {
        Canvas { context, size in
            let bounds = CGRect(origin: .zero, size: size).insetBy(dx: compact ? 12 : 10, dy: compact ? 8 : 10)
            let side = min(bounds.width, bounds.height)
            let rect = CGRect(x: bounds.midX - side / 2, y: bounds.midY - side / 2, width: side, height: side)
            switch kind {
            case .cross:
                var cross = Path()
                let width = rect.width * 0.17
                cross.addRoundedRect(
                    in: CGRect(x: rect.midX - width / 2, y: rect.minY, width: width, height: rect.height),
                    cornerSize: .init(width: 3, height: 3)
                )
                cross.addRoundedRect(
                    in: CGRect(
                        x: rect.minX + rect.width * 0.18,
                        y: rect.minY + rect.height * 0.28,
                        width: rect.width * 0.64,
                        height: width
                    ),
                    cornerSize: .init(width: 3, height: 3)
                )
                context.fill(cross, with: .color(Theme.stone.opacity(0.82)))
                context.stroke(cross, with: .color(Theme.ink.opacity(0.34)), lineWidth: 1)
            case .penny:
                let coin = Path(ellipseIn: rect.insetBy(dx: rect.width * 0.08, dy: rect.height * 0.08))
                context.fill(coin, with: .color(Theme.weatheredGold.opacity(0.28)))
                context.stroke(coin, with: .color(Theme.weatheredGold), lineWidth: 2)
                let inner = Path(ellipseIn: rect.insetBy(dx: rect.width * 0.20, dy: rect.height * 0.20))
                context.stroke(inner, with: .color(Theme.inkSoft), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                var cross = Path()
                cross.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.31))
                cross.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.31))
                cross.move(to: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.midY))
                cross.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.34, y: rect.midY))
                context.stroke(cross, with: .color(Theme.inkSoft), lineWidth: 2)
            case .castle:
                var castle = Path()
                let base = CGRect(
                    x: rect.minX + rect.width * 0.18,
                    y: rect.minY + rect.height * 0.40,
                    width: rect.width * 0.64,
                    height: rect.height * 0.48
                )
                castle.addRect(base)
                let towerWidth = rect.width * 0.18
                castle.addRect(
                    CGRect(
                        x: base.minX - towerWidth * 0.35,
                        y: rect.minY + rect.height * 0.24,
                        width: towerWidth,
                        height: rect.height * 0.64
                    )
                )
                castle.addRect(
                    CGRect(
                        x: base.maxX - towerWidth * 0.65,
                        y: rect.minY + rect.height * 0.24,
                        width: towerWidth,
                        height: rect.height * 0.64
                    )
                )
                context.fill(castle, with: .color(Theme.stone.opacity(0.62)))
                context.stroke(castle, with: .color(Theme.inkSoft), lineWidth: 1.2)
                var ford = Path()
                ford.move(to: CGPoint(x: rect.minX, y: rect.maxY - 8))
                ford.addCurve(
                    to: CGPoint(x: rect.maxX, y: rect.maxY - 3),
                    control1: CGPoint(x: rect.width * 0.34, y: rect.maxY - 22),
                    control2: CGPoint(x: rect.width * 0.66, y: rect.maxY + 8)
                )
                context.stroke(
                    ford,
                    with: .color(Theme.moss),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
            }
        }
    }
}

private extension EvidenceCertainty {
    var icon: String {
        switch self {
        case .documented: return "doc.text"
        case .material: return "cube"
        case .later: return "clock"
        case .tradition: return "quote.bubble"
        case .disputed: return "arrow.triangle.branch"
        case .reconstruction: return "scope"
        case .unknown: return "questionmark.circle"
        }
    }
}
