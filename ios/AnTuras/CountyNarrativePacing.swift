import SwiftUI

/// Narrative pages share navigation and evidence behavior, but not a template.
/// The pack chooses a composition that matches what the reader is attending to.
struct CountyNarrativePage: View {
    let page: CountyStoryPage
    let pack: CountyStoryPack
    let hasEvidence: Bool
    let onOpenEvidence: () -> Void

    private var presentation: CountyNarrativePresentation {
        page.presentation ?? .editorial
    }

    private var items: [CountyNarrativeDisplayItem] {
        page.displayItems ?? []
    }

    private var visualAssetName: String? {
        guard let resourceID = page.visualResourceID,
              let res = pack.resources.first(where: { $0.id == resourceID && ($0.kind == .image || $0.kind == .video) })
        else { return nil }
        if res.kind == .video {
            let raw = res.value
            return raw.hasPrefix("video.") ? String(raw.dropFirst(6)) : raw
        }
        return res.value
    }

    var body: some View {
        Group {
            switch presentation {
            case .coastalOpening:
                CoastalOpeningPage(
                    page: page,
                    assetName: visualAssetName,
                    hasEvidence: hasEvidence,
                    onOpenEvidence: onOpenEvidence
                )
            case .tidalMeasure:
                TidalMeasurePage(page: page, items: items, hasEvidence: hasEvidence, onOpenEvidence: onOpenEvidence)
            case .movementLine:
                MovementLinePage(page: page, items: items, hasEvidence: hasEvidence, onOpenEvidence: onOpenEvidence)
            case .languageField:
                LanguageFieldPage(page: page, items: items, hasEvidence: hasEvidence, onOpenEvidence: onOpenEvidence)
            case .relationshipField:
                RelationshipFieldPage(page: page, items: items, hasEvidence: hasEvidence, onOpenEvidence: onOpenEvidence)
            case .connectedSystem:
                ConnectedSystemPage(page: page, items: items, hasEvidence: hasEvidence, onOpenEvidence: onOpenEvidence)
            case .archive:
                ArchivePage(
                    page: page,
                    assetName: visualAssetName,
                    hasEvidence: hasEvidence,
                    onOpenEvidence: onOpenEvidence
                )
            case .evidenceBoundary:
                EvidenceBoundaryPage(page: page, items: items, hasEvidence: hasEvidence, onOpenEvidence: onOpenEvidence)
            case .pressureField:
                PressureFieldPage(page: page, items: items, hasEvidence: hasEvidence, onOpenEvidence: onOpenEvidence)
            case .closingQuestion:
                ClosingQuestionPage(page: page, hasEvidence: hasEvidence, onOpenEvidence: onOpenEvidence)
            case .editorial:
                EditorialNarrativePage(page: page, hasEvidence: hasEvidence, onOpenEvidence: onOpenEvidence)
            }
        }
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Place: a wide interpretive field

private struct CoastalOpeningPage: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let page: CountyStoryPage
    let assetName: String?
    let hasEvidence: Bool
    let onOpenEvidence: () -> Void

    private let imageInk = Color(light: 0x172019, dark: 0x172019)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if dynamicTypeSize.isAccessibilitySize {
                image(height: 220)
                imageCaption
                openingText
                    .padding(.horizontal, EditorialLayout.pageInset)
                    .padding(.top, 24)
            } else {
                ZStack(alignment: .topLeading) {
                    image(height: 330)
                    LinearGradient(
                        colors: [Color.white.opacity(0.88), Color.white.opacity(0.38), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    openingText
                        .foregroundStyle(imageInk)
                        .frame(maxWidth: 330, alignment: .leading)
                        .padding(24)
                }
                .frame(height: 330)
                .clipped()
                imageCaption
            }

            VStack(alignment: .leading, spacing: 24) {
                NarrativeProse(page: page)
                if hasEvidence {
                    EvidenceTextLink(title: "Why this place can support the claim", action: onOpenEvidence)
                }
            }
            .padding(.horizontal, EditorialLayout.pageInset)
            .padding(.top, 32)
        }
    }

    private var openingText: some View {
        VStack(alignment: .leading, spacing: 10) {
            EditorialContextLabel(text: page.context, color: dynamicTypeSize.isAccessibilitySize ? Theme.moss : imageInk.opacity(0.78))
            Text(page.title)
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
    }

    @ViewBuilder
    private func image(height: CGFloat) -> some View {
        GeometryReader { geometry in
            if let assetName {
                StoryArtImage(name: assetName)
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: height)
                    .clipped()
            } else {
                Theme.sunk
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(page.visualCaption ?? "Editorial landscape")
    }

    private var imageCaption: some View {
        Text(page.visualCaption ?? "Editorial landscape")
            .font(.caption)
            .foregroundStyle(Theme.inkSoft)
            .padding(.horizontal, EditorialLayout.pageInset)
            .padding(.vertical, 8)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Explanation: tide, route and connected system

private struct TidalMeasurePage: View {
    let page: CountyStoryPage
    let items: [CountyNarrativeDisplayItem]
    let hasEvidence: Bool
    let onOpenEvidence: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 12) {
                EditorialContextLabel(text: page.context, color: Theme.storm)
                Text(page.title)
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.horizontal, EditorialLayout.pageInset)

            TideInstrument(items: items)

            VStack(alignment: .leading, spacing: 24) {
                NarrativeProse(page: page)
                if hasEvidence {
                    EvidenceTextLink(title: "Inspect the place evidence", action: onOpenEvidence)
                }
            }
            .padding(.horizontal, EditorialLayout.pageInset)
        }
        .padding(.top, 32)
    }
}

private struct TideInstrument: View {
    let items: [CountyNarrativeDisplayItem]

    private let levels: [CGFloat] = [0.34, 0.58, 0.82]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    VStack(spacing: 8) {
                        Image(systemName: item.symbol)
                            .font(.title3)
                            .foregroundStyle(Theme.weatheredGold)
                        Rectangle()
                            .fill(Theme.storm.opacity(0.34 + Double(index) * 0.16))
                            .frame(height: 118 * levels[min(index, levels.count - 1)])
                        Text(item.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.salt)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 174, alignment: .bottom)

            Text("The usable threshold moves. Reading it is part of the stronghold.")
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.salt)

            ForEach(items) { item in
                Text("\(item.title): \(item.detail)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.salt.opacity(0.78))
            }
        }
        .padding(.horizontal, EditorialLayout.pageInset)
        .padding(.vertical, 24)
        .background(Theme.atlantic)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(items.map { "\($0.title), \($0.detail)" }.joined(separator: ". "))
    }
}

private struct MovementLinePage: View {
    let page: CountyStoryPage
    let items: [CountyNarrativeDisplayItem]
    let hasEvidence: Bool
    let onOpenEvidence: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            EditorialSectionHeader(context: page.context, title: page.title, accent: Theme.moss)
            NarrativeRoute(items: items)
            NarrativeProse(page: page, detailStyle: .turn)
            if hasEvidence {
                EvidenceTextLink(title: "See the evidence behind the route", action: onOpenEvidence)
            }
        }
        .padding(.horizontal, EditorialLayout.pageInset)
        .padding(.top, 40)
    }
}

private struct NarrativeRoute: View {
    let items: [CountyNarrativeDisplayItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle().fill(index == 0 ? Theme.moss : Theme.sunk)
                            Image(systemName: item.symbol)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(index == 0 ? Theme.bg : Theme.moss)
                        }
                        .frame(width: 44, height: 44)
                        if index < items.count - 1 {
                            Rectangle().fill(Theme.moss.opacity(0.45)).frame(width: 1, height: 52)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.system(.title3, design: .serif, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Text(item.detail)
                            .font(.body)
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ConnectedSystemPage: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let page: CountyStoryPage
    let items: [CountyNarrativeDisplayItem]
    let hasEvidence: Bool
    let onOpenEvidence: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                EditorialContextLabel(text: page.context, color: Theme.weatheredGold)
                Text(page.title)
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.salt)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.horizontal, EditorialLayout.pageInset)
            .padding(.top, 32)

            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 16) { systemItems }
                    .padding(.horizontal, EditorialLayout.pageInset)
                    .padding(.vertical, 28)
            } else {
                HStack(alignment: .top, spacing: 12) { systemItems }
                    .padding(.horizontal, EditorialLayout.pageInset)
                    .padding(.vertical, 32)
            }

            VStack(alignment: .leading, spacing: 24) {
                NarrativeProse(page: page, inverted: true, detailStyle: .limit)
                if hasEvidence {
                    EvidenceTextLink(title: "Inspect how the connection was bounded", inverted: true, action: onOpenEvidence)
                }
            }
            .padding(.horizontal, EditorialLayout.pageInset)
            .padding(.bottom, 32)
        }
        .background(Theme.atlantic)
    }

    @ViewBuilder
    private var systemItems: some View {
        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: item.symbol)
                    .font(.title2)
                    .foregroundStyle(index == 1 ? Theme.weatheredGold : Theme.moss)
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(Theme.salt)
                Text(item.detail)
                    .font(.subheadline)
                    .foregroundStyle(Theme.salt.opacity(0.72))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Language and relationships

private struct LanguageFieldPage: View {
    let page: CountyStoryPage
    let items: [CountyNarrativeDisplayItem]
    let hasEvidence: Bool
    let onOpenEvidence: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            EditorialSectionHeader(context: page.context, title: page.title, accent: Theme.lichen)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    VStack(alignment: index.isMultiple(of: 2) ? .leading : .trailing, spacing: 5) {
                        Text(item.title)
                            .font(.system(.title, design: .serif, weight: .semibold))
                            .foregroundStyle(index == 0 ? Theme.moss : Theme.ink)
                        Text(item.detail)
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .frame(maxWidth: .infinity, alignment: index.isMultiple(of: 2) ? .leading : .trailing)
                    .multilineTextAlignment(index.isMultiple(of: 2) ? .leading : .trailing)
                    .padding(.vertical, 16)
                    if index < items.count - 1 { EditorialRule() }
                }
            }
            .accessibilityElement(children: .contain)

            NarrativeProse(page: page, detailStyle: .limit)
            if hasEvidence {
                EvidenceTextLink(title: "Inspect the relationships named in the record", action: onOpenEvidence)
            }
        }
        .padding(.horizontal, EditorialLayout.pageInset)
        .padding(.top, 40)
    }
}

private struct RelationshipFieldPage: View {
    let page: CountyStoryPage
    let items: [CountyNarrativeDisplayItem]
    let hasEvidence: Bool
    let onOpenEvidence: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            EditorialSectionHeader(context: page.context, title: page.title, accent: Theme.moss)

            VStack(spacing: 20) {
                Text("Authority reaches beyond one person")
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                HStack(alignment: .top, spacing: 8) {
                    ForEach(items) { item in
                        VStack(spacing: 8) {
                            Image(systemName: item.symbol)
                                .font(.title3)
                                .foregroundStyle(Theme.moss)
                                .frame(width: 44, height: 44)
                            Text(item.title).font(.headline).foregroundStyle(Theme.ink)
                            Text(item.detail)
                                .font(.caption)
                                .foregroundStyle(Theme.inkSoft)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.vertical, 24)
            .background(Theme.sunk)
            .accessibilityElement(children: .contain)

            NarrativeProse(page: page, detailStyle: .limit)
            if hasEvidence {
                EvidenceTextLink(title: "Open the family evidence", action: onOpenEvidence)
            }
        }
        .padding(.horizontal, EditorialLayout.pageInset)
        .padding(.top, 40)
    }
}

// MARK: - Record and evidence boundary

private struct ArchivePage: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let page: CountyStoryPage
    let assetName: String?
    let hasEvidence: Bool
    let onOpenEvidence: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 20) {
                        archiveImage(width: nil, height: 250)
                        archiveStatement
                    }
                } else {
                    HStack(alignment: .bottom, spacing: 16) {
                        archiveImage(width: 150, height: 220)
                        archiveStatement
                    }
                }
            }
            .padding(.horizontal, EditorialLayout.pageInset)
            .padding(.top, 24)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.atlantic)

            Text(page.visualCaption ?? "Archival source")
                .font(.caption)
                .foregroundStyle(Theme.inkSoft)
                .padding(.horizontal, EditorialLayout.pageInset)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 28) {
                EditorialSectionHeader(context: page.context, title: page.title, accent: Theme.lichen)
                NarrativeProse(page: page, detailStyle: .limit)
                if hasEvidence {
                    EvidenceTextLink(title: "Open this source and its limits", action: onOpenEvidence)
                }
            }
            .padding(.horizontal, EditorialLayout.pageInset)
            .padding(.top, 24)
        }
    }

    private var archiveStatement: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("1593")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.weatheredGold)
            Text("Questions shape what the record allows us to see.")
                .font(.system(.title3, design: .serif))
                .foregroundStyle(Theme.salt)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func archiveImage(width: CGFloat?, height: CGFloat) -> some View {
        Group {
            if let assetName {
                if width == nil {
                    Image(assetName)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(assetName)
                        .resizable()
                        .scaledToFill()
                }
            } else {
                Theme.sunk
            }
        }
        .frame(width: width, height: height)
        .frame(maxWidth: width == nil ? .infinity : nil)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(page.visualCaption ?? "Archival source")
    }
}

private struct EvidenceBoundaryPage: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let page: CountyStoryPage
    let items: [CountyNarrativeDisplayItem]
    let hasEvidence: Bool
    let onOpenEvidence: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 12) {
                EditorialContextLabel(text: page.context, color: Theme.rust)
                Text(page.title)
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }

            NarrativeProse(page: page)

            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 1) { boundaryItems }
            } else {
                HStack(alignment: .top, spacing: 1) { boundaryItems }
            }

            if hasEvidence {
                EvidenceTextLink(title: "Inspect the line between evidence and inference", action: onOpenEvidence)
            }
        }
        .padding(.horizontal, EditorialLayout.pageInset)
        .padding(.top, 40)
    }

    @ViewBuilder
    private var boundaryItems: some View {
        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: item.symbol)
                    .font(.title2)
                    .foregroundStyle(index == 0 ? Theme.moss : Theme.rust)
                Text(item.title).font(.headline).foregroundStyle(Theme.ink)
                Text(item.detail).font(.body).foregroundStyle(Theme.inkSoft)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(index == 0 ? Theme.mossTint : Theme.sunk)
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Pressure and consequence

private struct PressureFieldPage: View {
    let page: CountyStoryPage
    let items: [CountyNarrativeDisplayItem]
    let hasEvidence: Bool
    let onOpenEvidence: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                EditorialContextLabel(text: page.context, color: Theme.rust)
                Text(page.title)
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.salt)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.horizontal, EditorialLayout.pageInset)
            .padding(.top, 36)
            .padding(.bottom, 28)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(alignment: .top, spacing: 16) {
                        Text("0\(index + 1)")
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(Theme.rust)
                            .frame(width: 28, alignment: .leading)
                        Image(systemName: item.symbol)
                            .font(.headline)
                            .foregroundStyle(Theme.weatheredGold)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title).font(.headline).foregroundStyle(Theme.salt)
                            Text(item.detail).font(.body).foregroundStyle(Theme.salt.opacity(0.72))
                        }
                    }
                    .padding(.vertical, 16)
                    if index < items.count - 1 {
                        Rectangle().fill(Theme.storm).frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, EditorialLayout.pageInset)

            VStack(alignment: .leading, spacing: 24) {
                NarrativeProse(page: page, inverted: true, detailStyle: .turn)
                if hasEvidence {
                    EvidenceTextLink(title: "Inspect the pressure named in the record", inverted: true, action: onOpenEvidence)
                }
            }
            .padding(.horizontal, EditorialLayout.pageInset)
            .padding(.top, 32)
            .padding(.bottom, 36)
        }
        .background(Theme.atlantic)
    }
}

private struct ClosingQuestionPage: View {
    let page: CountyStoryPage
    let hasEvidence: Bool
    let onOpenEvidence: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 48) {
            VStack(alignment: .leading, spacing: 12) {
                EditorialContextLabel(text: page.context, color: Theme.moss)
                Text(page.title)
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }

            Text(page.body)
                .font(.system(.title2, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            if let detail = page.detail {
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "questionmark")
                        .font(.title)
                        .foregroundStyle(Theme.weatheredGold)
                    Text(detail)
                        .font(.system(.title, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.salt)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .background(Theme.atlantic)
            }

            if hasEvidence {
                EvidenceTextLink(title: "Return to the evidence behind the stakes", action: onOpenEvidence)
            }
        }
        .padding(.horizontal, EditorialLayout.pageInset)
        .padding(.top, 48)
    }
}

private struct EditorialNarrativePage: View {
    let page: CountyStoryPage
    let hasEvidence: Bool
    let onOpenEvidence: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            EditorialScreenHeader(context: page.context, title: page.title, detail: nil, accent: Theme.moss)
            NarrativeProse(page: page)
            if hasEvidence {
                EvidenceTextLink(title: "Inspect the supporting record", action: onOpenEvidence)
            }
        }
        .padding(.horizontal, EditorialLayout.pageInset)
        .padding(.top, 40)
    }
}

// MARK: - Shared reading primitives

private enum NarrativeDetailStyle {
    case quiet
    case turn
    case limit
}

private struct NarrativeProse: View {
    let page: CountyStoryPage
    var inverted = false
    var detailStyle: NarrativeDetailStyle = .quiet

    var body: some View {
        VStack(alignment: .leading, spacing: detailStyle == .quiet ? 20 : 24) {
            Text(page.body)
                .font(.system(.title3, design: .serif))
                .foregroundStyle(inverted ? Theme.salt : Theme.ink)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            if let detail = page.detail, !detail.isEmpty {
                detailView(detail)
            }
        }
    }

    @ViewBuilder
    private func detailView(_ detail: String) -> some View {
        switch detailStyle {
        case .quiet:
            Text(detail)
                .font(.body)
                .foregroundStyle(inverted ? Theme.salt.opacity(0.72) : Theme.inkSoft)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        case .turn:
            VStack(alignment: .leading, spacing: 12) {
                Rectangle()
                    .fill(inverted ? Theme.weatheredGold : Theme.moss)
                    .frame(width: 48, height: 2)
                    .accessibilityHidden(true)
                Text(detail)
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(inverted ? Theme.salt : Theme.ink)
                    .lineSpacing(5)
            }
        case .limit:
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle")
                    .font(.headline)
                    .foregroundStyle(inverted ? Theme.weatheredGold : Theme.lichen)
                    .frame(width: 28, height: 28)
                Text(detail)
                    .font(.body)
                    .foregroundStyle(inverted ? Theme.salt.opacity(0.78) : Theme.inkSoft)
                    .lineSpacing(4)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

private struct EvidenceTextLink: View {
    let title: String
    var inverted = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "doc.text.magnifyingglass")
                    .frame(width: 28, height: 28)
                Text(title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(inverted ? Theme.salt : Theme.moss)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the source, claim status and evidence limit without losing this page")
    }
}
