import SwiftUI

struct CountyStoryExperienceView: View {
    @EnvironmentObject private var atlas: AtlasPrototypeModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let pack: CountyStoryPack
    let onOpenEvidence: () -> Void
    let onExit: () -> Void

    @State private var showingChapterMenu = false
    @State private var finishedMode: CountyStoryMode?
    @State private var locallyCompletedPageIDs: Set<String> = []

    private var mode: CountyStoryMode? { atlas.mode(for: pack.id) }

    var body: some View {
        Group {
            if let finishedMode {
                completionView(finishedMode)
            } else if let mode, let page = activePage(for: mode) {
                pageExperience(page, mode: mode)
            } else {
                CountyModeOpeningView(pack: pack) { selected in
                    withAnimation(reduceMotion ? nil : Motion.settle) {
                        _ = atlas.begin(pack, mode: selected)
                    }
                }
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if mode != nil, finishedMode == nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingChapterMenu = true
                    } label: {
                        Label("Chapter menu", systemImage: "list.bullet")
                    }
                }
            }
        }
        .sheet(isPresented: $showingChapterMenu) {
            CountyChapterMenuView(pack: pack) { selectedMode in
                _ = atlas.switchMode(in: pack, to: selectedMode)
                finishedMode = nil
                showingChapterMenu = false
            } onSelectPage: { pageID in
                atlas.setActivePage(pageID, in: pack)
                showingChapterMenu = false
            }
            .environmentObject(atlas)
        }
        .onAppear {
            if let mode { _ = atlas.begin(pack, mode: mode) }
        }
    }

    private func activePage(for mode: CountyStoryMode) -> CountyStoryPage? {
        guard let pageID = atlas.resumePageID(for: pack, mode: mode) else { return nil }
        return pack.page(id: pageID)
    }

    private func pageExperience(_ page: CountyStoryPage, mode: CountyStoryMode) -> some View {
        let visible = pack.pages(for: mode)
        let index = visible.firstIndex(where: { $0.id == page.id }) ?? 0
        let isComplete = locallyCompletedPageIDs.contains(page.id)
            || atlas.isPageComplete(page.id, in: pack.id)

        return VStack(spacing: 0) {
            CountyStoryChrome(
                pack: pack,
                mode: mode,
                chapter: pack.chapter(containing: page.id),
                current: index + 1,
                total: visible.count
            )

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Color.clear.frame(height: 0).id("county-page-top")
                        if page.kind == .exercise, page.exercise != nil {
                            CountyExerciseView(page: page, alreadyComplete: isComplete) {
                                locallyCompletedPageIDs.insert(page.id)
                                atlas.markPageComplete(page.id, in: pack)
                            }
                            .padding(.horizontal, EditorialLayout.pageInset)
                            .padding(.top, 24)
                            .frame(maxWidth: EditorialLayout.readingWidth)
                            .frame(maxWidth: .infinity)
                        } else {
                            CountyNarrativePage(
                                page: page,
                                pack: pack,
                                hasEvidence: page.resourceIDs.contains { resourceID in
                                    pack.resources.contains { $0.id == resourceID && ($0.kind == .evidence || $0.kind == .source) }
                                },
                                onOpenEvidence: onOpenEvidence
                            )
                        }
                    }
                    .padding(.bottom, 124)
                    .frame(maxWidth: .infinity)
                    .id(page.id)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: page.id) { _, _ in
                    Task { @MainActor in
                        await Task.yield()
                        proxy.scrollTo("county-page-top", anchor: .top)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            CountyPageControls(
                canGoBack: index > 0,
                canContinue: page.kind == .narrative || isComplete,
                continueTitle: page.advanceLabel ?? (index == visible.count - 1 ? "Complete this chapter path" : "Continue"),
                onBack: {
                    guard index > 0 else { return }
                    move(to: visible[index - 1])
                },
                onContinue: {
                    if page.kind == .narrative { atlas.markPageComplete(page.id, in: pack) }
                    if index == visible.count - 1 {
                        atlas.finish(pack, mode: mode)
                        withAnimation(reduceMotion ? nil : Motion.settle) { finishedMode = mode }
                    } else {
                        move(to: visible[index + 1])
                    }
                }
            )
        }
        .transition(reduceMotion ? .opacity : .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private func move(to page: CountyStoryPage) {
        Haptics.tap()
        withAnimation(reduceMotion ? nil : Motion.settle) {
            atlas.setActivePage(page.id, in: pack)
        }
    }

    private func completionView(_ mode: CountyStoryMode) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                EditorialScreenHeader(
                    context: "\(pack.presentation.countyGa) · \(mode.title) mode",
                    title: completionTitle,
                    detail: completionDetail(for: mode),
                    accent: Theme.moss
                )

                VStack(alignment: .leading, spacing: 10) {
                    Label("Your page progress is saved by stable id.", systemImage: "bookmark")
                    Label("Switching modes keeps shared pages complete.", systemImage: "arrow.triangle.2.circlepath")
                    Label(completionEffectLabel, systemImage: pack.isReleaseCleared ? "checkmark.seal" : "circle.dashed")
                }
                .font(.body)
                .foregroundStyle(Theme.ink)

                Text(completionStatus)
                    .font(.body)
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(4)

                PrimaryButton(title: "Open the other mode", fullWidth: true) {
                    let other: CountyStoryMode = mode == .story ? .learning : .story
                    _ = atlas.switchMode(in: pack, to: other)
                    finishedMode = nil
                }
                Button("Return to the atlas", action: onExit)
                    .buttonStyle(.bordered)
                    .tint(Theme.moss)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .padding(.horizontal, EditorialLayout.pageInset)
            .padding(.vertical, 30)
            .frame(maxWidth: EditorialLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
    }

    private var completionTitle: String {
        if pack.scope == .representativeChapter { return "Rockfleet chapter proof complete" }
        if pack.isReviewDraft { return "\(pack.presentation.countyEn) review path complete" }
        return "\(pack.presentation.countyEn) path complete"
    }

    private func completionDetail(for mode: CountyStoryMode) -> String {
        if pack.scope == .representativeChapter {
            if mode == .story {
                return "You followed the complete chapter account without a language gate."
            }
            return "You followed the shorter causal account and completed all twelve exercise families in their authored positions."
        }
        let pageCount = pack.pages(for: mode).count
        if mode == .story {
            return "You followed the complete \(pageCount)-page account without a language gate."
        }
        let exerciseCount = pack.pages(for: .learning).filter { $0.exercise != nil }.count
        return "You followed the causal account and completed \(exerciseCount) exercises in their authored positions."
    }

    private var completionEffectLabel: String {
        if pack.isReleaseCleared {
            return "The reviewed county can now award its completion effects."
        }
        if pack.isReviewDraft {
            return "This review pass does not award gold, a made object or scheduled words."
        }
        return "This proof does not award county completion or scheduled words."
    }

    private var completionStatus: String {
        if pack.isReviewDraft {
            return "This authored county is bundled for in-app review. Release effects remain locked while these gates are open: \(pack.openReviewGateTitles.joined(separator: ", "))."
        }
        if pack.scope == .representativeChapter {
            return "This is the representative Rockfleet chapter required before the rest of Mayo is authored. County completion remains locked until the complete story and 20-word lifecycle exist."
        }
        if pack.isReleaseCleared {
            return "The complete county pack and its recorded review gates are ready for the normal completion path."
        }
        return "This editorial preview remains available for inspection without awarding county completion."
    }
}

private struct CountyModeOpeningView: View {
    let pack: CountyStoryPack
    let onSelect: (CountyStoryMode) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                EditorialScreenHeader(
                    context: "\(pack.presentation.countyGa) · \(openingStatus)",
                    title: pack.title,
                    detail: pack.presentation.question,
                    accent: Theme.atlasGreen
                )

                Text(pack.presentation.opening)
                    .font(.system(.title3, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(5)

                modeOption(
                    mode: .story,
                    title: pack.scope == .representativeChapter ? "Read the complete chapter" : "Read the complete county story",
                    detail: storyModeDetail,
                    symbol: "book.pages"
                )
                modeOption(
                    mode: .learning,
                    title: pack.scope == .representativeChapter ? "Learn through the shorter chapter" : "Learn through the county story",
                    detail: learningModeDetail,
                    symbol: "text.book.closed"
                )

                Text(openingFootnote)
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(3)
            }
            .padding(.horizontal, EditorialLayout.pageInset)
            .padding(.vertical, 28)
            .frame(maxWidth: EditorialLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Choose a mode")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var openingStatus: String {
        if pack.isReviewDraft { return "in-app review draft" }
        if pack.scope == .representativeChapter { return "representative chapter" }
        if pack.isReleaseCleared { return "reviewed county" }
        return "editorial preview"
    }

    private var storyModeDetail: String {
        let pages = pack.pages(for: .story)
        let minutes = Int(ceil(Double(pages.reduce(0) { $0 + $1.estimatedSeconds }) / 60))
        return "\(pages.count) narrative pages across \(pack.chapters.count) chapters, about \(minutes) minutes. No Irish answer gates progress."
    }

    private var learningModeDetail: String {
        let pages = pack.pages(for: .learning)
        let exercises = pages.compactMap(\.exercise)
        let families = Set(exercises.map(\.family)).count
        let minutes = Int(ceil(Double(pages.reduce(0) { $0 + $1.estimatedSeconds }) / 60))
        return "\(pages.count) pages with \(exercises.count) exercises across \(families) mechanics, about \(minutes) minutes, with explicit recovery."
    }

    private var openingFootnote: String {
        if pack.isReviewDraft {
            return "This complete authoring draft is bundled for review. Page progress is saved, but gold, made objects and word scheduling remain locked while review gates are open."
        }
        if pack.scope == .representativeChapter {
            return "You can change mode from the chapter menu. This proof does not complete Mayo or move words into Words you carry."
        }
        if pack.isReleaseCleared {
            return "You can change mode from the chapter menu. The reviewed county follows the normal completion path."
        }
        return "You can change mode from the chapter menu. This preview remains inspection-only."
    }

    private func modeOption(mode: CountyStoryMode, title: String, detail: String, symbol: String) -> some View {
        Button { onSelect(mode) } label: {
            HStack(alignment: .top, spacing: 15) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(Theme.moss)
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.headline).foregroundStyle(Theme.ink)
                    Text(detail).font(.body).foregroundStyle(Theme.inkSoft).lineSpacing(3)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(Theme.inkFaint)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .background(Theme.raised)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(CarvePress())
        .accessibilityLabel("\(mode.title) mode. \(title). \(detail)")
    }
}

private struct CountyStoryChrome: View {
    let pack: CountyStoryPack
    let mode: CountyStoryMode
    let chapter: CountyStoryChapter?
    let current: Int
    let total: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(mode.title)
                Spacer()
                Text(chapter?.title ?? pack.title).lineLimit(1)
                Text("\(current)/\(total)").monospacedDigit()
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.inkSoft)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.line).frame(height: 3)
                    Capsule().fill(Theme.moss)
                        .frame(width: geometry.size.width * CGFloat(current) / CGFloat(max(total, 1)), height: 3)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, EditorialLayout.pageInset)
        .padding(.vertical, 11)
        .background(Theme.bg)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(mode.title) mode, \(chapter?.title ?? pack.title), page \(current) of \(total)")
    }
}

private struct CountyPageControls: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let canGoBack: Bool
    let canContinue: Bool
    let continueTitle: String
    let onBack: () -> Void
    let onContinue: () -> Void

    private var visibleContinueTitle: String {
        guard dynamicTypeSize.isAccessibilitySize else { return continueTitle }
        return continueTitle.contains("Complete") ? "Complete" : "Continue"
    }

    var body: some View {
        HStack(spacing: 12) {
            if canGoBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                        .frame(width: 44, height: 44)
                        .background(Theme.raised)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(CarvePress())
                .accessibilityLabel("Previous page")
            }
            PrimaryButton(title: visibleContinueTitle, fullWidth: true, action: onContinue)
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.45)
                .accessibilityLabel(continueTitle)
        }
        .padding(.horizontal, EditorialLayout.pageInset)
        .padding(.vertical, 12)
        .background(Theme.bg.opacity(0.98))
    }
}

private struct CountyChapterMenuView: View {
    @EnvironmentObject private var atlas: AtlasPrototypeModel
    @Environment(\.dismiss) private var dismiss
    let pack: CountyStoryPack
    let onSelectMode: (CountyStoryMode) -> Void
    let onSelectPage: (String) -> Void

    private var mode: CountyStoryMode { atlas.mode(for: pack.id) ?? .story }

    var body: some View {
        NavigationStack {
            List {
                Section("Mode") {
                    ForEach(CountyStoryMode.allCases) { candidate in
                        Button { onSelectMode(candidate) } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(candidate.title) mode").foregroundStyle(Theme.ink)
                                    Text(modeDetail(candidate)).font(.caption).foregroundStyle(Theme.inkSoft)
                                }
                                Spacer()
                                if candidate == mode { Image(systemName: "checkmark").foregroundStyle(Theme.moss) }
                            }
                            .frame(minHeight: 44)
                        }
                    }
                }

                ForEach(pack.chapters) { chapter in
                    Section(chapter.title) {
                        ForEach(chapter.pages.filter { $0.visibility.includes(mode) }) { page in
                            Button { onSelectPage(page.id) } label: {
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Image(systemName: atlas.isPageComplete(page.id, in: pack.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(atlas.isPageComplete(page.id, in: pack.id) ? Theme.moss : Theme.inkFaint)
                                    Text(page.title).foregroundStyle(Theme.ink)
                                    Spacer()
                                    if page.kind == .exercise { Image(systemName: "text.book.closed").foregroundStyle(Theme.inkFaint) }
                                }
                                .frame(minHeight: 44)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Chapter menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func modeDetail(_ mode: CountyStoryMode) -> String {
        let completed = atlas.completedRequiredPages(in: pack, mode: mode)
        let total = pack.requiredPageIDs(for: mode).count
        return "\(completed) of \(total) required pages complete"
    }
}
