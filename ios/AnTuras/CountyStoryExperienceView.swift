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
    @State private var exerciseBar = CountyExerciseBarState(title: "Continue", isEnabled: false, isCheck: false)
    @State private var exerciseBarAction: (() -> Void)?

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
            if let mode, atlas.mode(for: pack.id) == nil {
                _ = atlas.begin(pack, mode: mode)
            }
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
        let isExercise = page.kind == .exercise && page.exercise != nil

        return VStack(spacing: 0) {
            CountyStoryChrome(
                pack: pack,
                mode: mode,
                chapter: pack.chapter(containing: page.id),
                current: index + 1,
                total: visible.count,
                compact: isExercise
            )

            ScrollViewReader { proxy in
                GeometryReader { geometry in
                    ScrollView {
                        VStack(alignment: .leading, spacing: isExercise ? 0 : 24) {
                            Color.clear.frame(height: 0).id("county-page-top")
                            if isExercise {
                                exercisePage(page, isComplete: isComplete, topPadding: 8)
                                    // Force a fresh activity engine per page — without this,
                                    // SwiftUI reuses @State from the previous exercise and
                                    // leaves the bank locked as already-complete.
                                    .id(page.id)
                                    // Stage zoning: a short exercise page fills the
                                    // viewport so the shell can center its working area;
                                    // AX-size content outgrows this and scrolls as one
                                    // composition, and keyboard avoidance keeps the
                                    // focused field visible on top of it.
                                    .frame(minHeight: max(geometry.size.height - 108, 0), alignment: .top)
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
                            Color.clear.frame(height: 0).id("county-page-bottom")
                        }
                        .padding(.bottom, 108)
                        .frame(maxWidth: .infinity)
                        .id(page.id)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onAppear { scrollToTaskStart(proxy, page: page) }
                    .onChange(of: page.id) { _, _ in
                        scrollToTaskStart(proxy, page: page)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            CountyPageControls(
                canGoBack: index > 0 && !isExercise,
                canContinue: page.kind == .narrative ? true : (isComplete || exerciseBar.isEnabled),
                continueTitle: page.kind == .exercise
                    ? (index == visible.count - 1 && isComplete ? "Complete this chapter path" : exerciseBar.title)
                    : (page.advanceLabel ?? (index == visible.count - 1 ? "Complete this chapter path" : "Continue")),
                continueEnabled: page.kind == .narrative ? true : (isComplete || exerciseBar.isEnabled),
                onBack: {
                    guard index > 0 else { return }
                    move(to: visible[index - 1])
                },
                onContinue: {
                    if page.kind == .exercise, !isComplete {
                        if exerciseBar.isCheck, let exerciseBarAction {
                            exerciseBarAction()
                            return
                        }
                        if exerciseBarAction != nil, page.exercise?.family == .recordCompare {
                            exerciseBarAction?()
                            return
                        }
                    }
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
        .onChange(of: page.id) { _, _ in
            exerciseBar = CountyExerciseBarState(title: "Continue", isEnabled: false, isCheck: false)
            exerciseBarAction = nil
        }
        .transition(reduceMotion ? .opacity : .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    @ViewBuilder
    private func exercisePage(_ page: CountyStoryPage, isComplete: Bool, topPadding: CGFloat) -> some View {
        CountyExerciseView(
            page: page,
            alreadyComplete: isComplete,
            onComplete: {
                locallyCompletedPageIDs.insert(page.id)
                atlas.markPageComplete(page.id, in: pack)
            },
            onBarUpdate: { bar, action in
                exerciseBar = bar
                exerciseBarAction = action
            },
            struggledPageIDs: atlas.struggledPageIDs(in: pack),
            conversationState: atlas.conversationState(for: page.id),
            onConversationState: { atlas.saveConversationState($0, for: page.id) },
            collectionWords: collectionWords,
            collectionHandoff: collectionHandoff,
            onCollect: {
                atlas.recordFixtureCollection(collectionWords.map(\.ga), in: pack)
            },
            onStruggle: nil,
            onMemoryEvent: { event in
                atlas.recordMemoryEvent(event, in: pack)
            }
        )
        .padding(.horizontal, EditorialLayout.pageInset)
        .padding(.top, topPadding)
        .frame(maxWidth: EditorialLayout.readingWidth)
        .frame(maxWidth: .infinity)
    }

    private func move(to page: CountyStoryPage) {
        Haptics.tap()
        withAnimation(reduceMotion ? nil : Motion.settle) {
            atlas.setActivePage(page.id, in: pack)
        }
    }

    /// Conversations land on the current turn (a restored graph reads bottom-up
    /// like any transcript); every other task starts at its prompt.
    private func scrollToTaskStart(_ proxy: ScrollViewProxy, page: CountyStoryPage) {
        Task { @MainActor in
            await Task.yield()
            if page.exercise?.family == .conversation {
                proxy.scrollTo("county-page-bottom", anchor: .bottom)
            } else {
                proxy.scrollTo("county-page-top", anchor: .top)
            }
        }
    }

    /// C5: the words a completion container hands over — the pack's headwords
    /// that the run's exercises actually worked.
    private var collectionWords: [AtlasWord] {
        let usedLexemes = Set(pack.pages(for: .learning).compactMap(\.exercise).flatMap(\.lexemeIDs))
        guard !usedLexemes.isEmpty else { return [] }
        return pack.targetWords.filter { word in
            usedLexemes.contains("lex." + word.ga.folding(options: .diacriticInsensitive, locale: nil).lowercased())
        }
    }

    private var collectionHandoff: String {
        #if DEBUG
        if isInternalFixture {
            return "For this fixture run they sit in a fixture collection only — no county gold, no made object and no scheduled reviews."
        }
        #endif
        return "These words return to your collection; Words you carry meets them there when scheduling opens."
    }

    private var isFreezeFixture: Bool {
        pack.id == CountyFreezeRunFixture.packID
    }

    private var isInternalFixture: Bool {
        pack.id == CountyFreezeRunFixture.packID
            || pack.id == CountyFarraigeFamilyBFixture.packID
            || pack.id == CountyFarraigeFamilyCFixture.packID
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
        if isFreezeFixture { return "Clew Bay fixture run complete" }
        if pack.id == CountyFarraigeFamilyBFixture.packID {
            return "Farraige family B fixture complete"
        }
        if pack.id == CountyFarraigeFamilyCFixture.packID {
            return "Farraige family C fixture complete"
        }
        if pack.scope == .representativeChapter { return "Rockfleet chapter proof complete" }
        if pack.isReviewDraft { return "\(pack.presentation.countyEn) review path complete" }
        return "\(pack.presentation.countyEn) path complete"
    }

    private func completionDetail(for mode: CountyStoryMode) -> String {
        if isFreezeFixture {
            return "You walked all nine frozen steps — cold opens, in-place repairs, a branching conversation and an exact resume — on the shared county shell."
        }
        if pack.id == CountyFarraigeFamilyBFixture.packID {
            return "You heard farraige in a ship surround and built a different Clew Bay line — D30 pattern B on the shared shell."
        }
        if pack.id == CountyFarraigeFamilyCFixture.packID {
            return "You built one farraige surround, walked the bay, then typed a different question — D30 pattern C on the shared shell."
        }
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
        if isInternalFixture {
            return "The words sit in a fixture collection; this run awards no county gold, made objects or scheduled words."
        }
        if pack.isReleaseCleared {
            return "The reviewed county can now award its completion effects."
        }
        if pack.isReviewDraft {
            return "This review pass does not award gold, a made object or scheduled words."
        }
        return "This proof does not award county completion or scheduled words."
    }

    private var completionStatus: String {
        if isFreezeFixture {
            return "This is the D29 representative-run proof. Production Mayo promotion is untouched, and the fixture collection stays separate from Words you carry and the review scheduler."
        }
        if pack.id == CountyFarraigeFamilyBFixture.packID {
            return "This is the D30 farraige phrase-family B proof. Teaching claims stay blocked until pedagogue and native audio QA; production Mayo is untouched."
        }
        if pack.id == CountyFarraigeFamilyCFixture.packID {
            return "This is the D30 farraige phrase-family C proof (delayed reuse). Teaching claims stay blocked until pedagogue and native audio QA; production Mayo is untouched."
        }
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
    /// Exercise pages keep Duo-density chrome: progress only. Narrative keeps
    /// the mode / chapter labels.
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 0 : 8) {
            if !compact {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(mode.title)
                    Spacer()
                    Text(chapter?.title ?? pack.title).lineLimit(1)
                    Text("\(current)/\(total)").monospacedDigit()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSoft)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.line).frame(height: compact ? 6 : 3)
                    Capsule().fill(Theme.atlasGreen)
                        .frame(
                            width: geometry.size.width * CGFloat(current) / CGFloat(max(total, 1)),
                            height: compact ? 6 : 3
                        )
                }
            }
            .frame(height: compact ? 6 : 3)
        }
        .padding(.horizontal, EditorialLayout.pageInset)
        .padding(.top, compact ? 6 : 11)
        .padding(.bottom, compact ? 8 : 11)
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
    var continueEnabled: Bool? = nil
    let onBack: () -> Void
    let onContinue: () -> Void

    private var visibleContinueTitle: String {
        guard dynamicTypeSize.isAccessibilitySize else { return continueTitle }
        return continueTitle.contains("Complete") ? "Complete" : continueTitle
    }

    private var isPrimaryEnabled: Bool {
        continueEnabled ?? canContinue
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
            PrimaryButton(title: visibleContinueTitle, fullWidth: true, enabled: isPrimaryEnabled, action: onContinue)
                .accessibilityLabel(continueTitle)
                // Bar-label swaps (Check the order → Continue) apply instantly:
                // the settle-transaction cross-dissolve rendered both titles at
                // once — the D2 stale-label ghost.
                .animation(nil, value: visibleContinueTitle)
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
