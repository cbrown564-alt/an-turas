import SwiftUI

enum CountyExercisePhase: String, CaseIterable {
    case unanswered
    case incorrect
    case hint
    case recovery
    case complete
}

/// Bottom-bar state published by an exercise page to the county story shell.
struct CountyExerciseBarState: Equatable {
    var title: String
    var isEnabled: Bool
    var isCheck: Bool
}

/// One calm task shell for every county-pack mechanic. Correctness, retry,
/// hints and completion live here rather than being reinvented by each task.
struct CountyExerciseView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    /// VoiceOver focus targets owned by the shell: the task prompt (start of
    /// the documented reading order) and the feedback/support panel.
    private enum ShellFocus: Hashable {
        case prompt
        case feedback
    }

    let page: CountyStoryPage
    let alreadyComplete: Bool
    /// The first learning task may carry a short authored arrival cue. Later
    /// tasks keep the compact activity shell.
    let showsStoryContext: Bool
    let onComplete: () -> Void
    let onBarUpdate: (CountyExerciseBarState, (() -> Void)?) -> Void
    /// C3: the run's ordered struggle record, used to target contextual review.
    let struggledPageIDs: [String]
    /// C1: persisted turn-graph position for exact resume after interruption.
    let conversationState: CountyConversationState?
    let onConversationState: ((CountyConversationState) -> Void)?
    /// C5: words the completion container hands to the collection.
    let collectionWords: [AtlasWord]
    let collectionHandoff: String
    let onCollect: (() -> Void)?
    /// D27 struggle memory event: fires when a repair window closes uncorrected
    /// or an explicit Check fails. Prefer `onMemoryEvent` for the full quartet.
    let onStruggle: (() -> Void)?
    /// Exactly-once success/struggle/hint/recovery handoff (rebuild plan step 11).
    let onMemoryEvent: ((CountyMemoryEvent) -> Void)?

    /// The pure lifecycle engine owns correctness, support, retry, completion
    /// and exactly-once memory credit (rebuild plan step 3). The view keeps
    /// only presentation copy and family-local response state.
    @State private var engine: CountyActivityStateEngine
    @State private var panelMessage: String?
    @State private var checkReady = false
    @State private var checkAction: (() -> Void)?
    /// Shell-owned announcement/focus queue: one pending task at a time, so a
    /// batched state change (haptics + panel swap + engine transition) yields
    /// one concise VoiceOver announcement and one focus move.
    @State private var announcementTask: Task<Void, Never>?
    @AccessibilityFocusState private var a11yFocus: ShellFocus?

    init(
        page: CountyStoryPage,
        alreadyComplete: Bool,
        showsStoryContext: Bool = false,
        onComplete: @escaping () -> Void,
        onBarUpdate: @escaping (CountyExerciseBarState, (() -> Void)?) -> Void,
        struggledPageIDs: [String] = [],
        conversationState: CountyConversationState? = nil,
        onConversationState: ((CountyConversationState) -> Void)? = nil,
        collectionWords: [AtlasWord] = [],
        collectionHandoff: String = "",
        onCollect: (() -> Void)? = nil,
        onStruggle: (() -> Void)? = nil,
        onMemoryEvent: ((CountyMemoryEvent) -> Void)? = nil
    ) {
        self.page = page
        self.alreadyComplete = alreadyComplete
        self.showsStoryContext = showsStoryContext
        self.onComplete = onComplete
        self.onBarUpdate = onBarUpdate
        self.struggledPageIDs = struggledPageIDs
        self.conversationState = conversationState
        self.onConversationState = onConversationState
        self.collectionWords = collectionWords
        self.collectionHandoff = collectionHandoff
        self.onCollect = onCollect
        self.onStruggle = onStruggle
        self.onMemoryEvent = onMemoryEvent
        let exercise = page.exercise!
        let reviewCandidate = CountyContextualReviewTargeting.candidate(
            from: exercise.reviewCandidates ?? [],
            struggledPageIDs: struggledPageIDs
        )
        _engine = State(initialValue: CountyActivityStateEngine(
            exerciseID: page.id,
            targetIDs: exercise.lexemeIDs,
            grading: Self.activityGrading(for: exercise, candidate: reviewCandidate),
            completionEvidence: exercise.resolvedContract(reviewCandidate: reviewCandidate).completionEvidence,
            restoringCompletion: alreadyComplete
        ))
        _panelMessage = State(initialValue: alreadyComplete ? "This exercise is complete. You can still revisit the task." : nil)
    }

    private var exercise: CountyExercise { page.exercise! }
    private var locksResponse: Bool { engine.isComplete }

    /// C3: the deterministic target for this run's contextual review.
    private var resolvedReviewCandidate: CountyReviewCandidate? {
        CountyContextualReviewTargeting.candidate(
            from: exercise.reviewCandidates ?? [],
            struggledPageIDs: struggledPageIDs
        )
    }

    /// D27 grading: multi-part responses keep an explicit Check; everything
    /// else grades on the selection touch behind the repair window.
    private static func activityGrading(
        for exercise: CountyExercise,
        candidate: CountyReviewCandidate?
    ) -> CountyActivityGrading {
        switch exercise.family {
        case .sentenceConstruction, .freeTyping:
            return .explicitCheck
        case .contextualReview:
            return candidate?.exercise.family == .freeTyping ? .explicitCheck : .selectionTouch
        default:
            return .selectionTouch
        }
    }

    /// The typed response kind this page's family supplies to the engine.
    private var familyResponseKind: CountyActivityResponse.Kind {
        switch exercise.family {
        case .sentenceConstruction: return .arrangement
        case .freeTyping: return .typedText
        case .matching: return .pairing
        case .conversation: return .dialogueTurn
        case .recordCompare: return .spokenComparison
        case .completion: return .containerAction
        case .contextualReview:
            return resolvedReviewCandidate?.exercise.family == .freeTyping ? .typedText : .selection
        case .listenChoose, .fillGap, .readRespond, .grammarDiscovery:
            return .selection
        }
    }

    /// The feedback panel keeps the freeze's four-state vocabulary; the
    /// engine's richer lifecycle maps onto it. An unrepaired diagnostic stays
    /// on the affected target, so the panel only rises for a hint, an
    /// escalated diagnostic, or completion.
    private var presentationPhase: CountyExercisePhase {
        if engine.isComplete { return .complete }
        if engine.phase == .recovery { return .recovery }
        if engine.phase == .hint { return .hint }
        if engine.diagnosticEscalated { return .incorrect }
        return .unanswered
    }

    // MARK: Shell-owned announcements and VoiceOver focus

    /// Every state-change announcement and focus move funnels through the
    /// shell (rebuild plan step 4); response components never post their own.
    private func handlePresentationChange(from old: CountyExercisePhase, to new: CountyExercisePhase) {
        switch new {
        case .hint:
            announceAndFocus(panelMessage ?? exercise.hint)
        case .incorrect:
            announceAndFocus(panelMessage ?? exercise.recovery)
        case .recovery:
            announceAndFocus(panelMessage ?? exercise.recovery)
        case .complete where old != .complete:
            announceAndFocus(panelMessage ?? exercise.feedback)
        case .unanswered where old != .unanswered:
            // A hint taken early, an in-place repair, or a retry reopening the
            // response: return focus to the start of the task's reading order.
            restorePromptFocus()
        default:
            break
        }
    }

    /// A concise announcement with no focus move (the on-target diagnostic of
    /// matching and conversation, whose note stays beside the response).
    private func announce(_ message: String) {
        announcementTask?.cancel()
        announcementTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            AccessibilityNotification.Announcement(message).post()
        }
    }

    /// Move VoiceOver focus onto the freshly risen panel, then announce its
    /// message once the layout has settled.
    private func announceAndFocus(_ message: String) {
        announcementTask?.cancel()
        announcementTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            a11yFocus = .feedback
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            AccessibilityNotification.Announcement(message).post()
        }
    }

    private func restorePromptFocus() {
        announcementTask?.cancel()
        announcementTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            a11yFocus = .prompt
        }
    }

    /// Drives one formed response through the engine, reopening the response
    /// through retry when a diagnostic or recovery has closed it.
    @discardableResult
    private func formEngineResponse() -> CountyActivityTransition {
        if engine.requiresRetry {
            engine.retry()
        }
        return engine.updateResponse(CountyActivityResponse(familyResponseKind))
    }

    /// Memory events reach their consumers: struggle feeds the run's ordered
    /// C3 record; all four kinds persist through the learner-memory handoff
    /// (rebuild plan step 11) for debt-free review seeding.
    private func apply(_ transition: CountyActivityTransition) {
        for event in transition.memoryEvents {
            onMemoryEvent?(event)
            if event.kind == .struggle {
                onStruggle?()
            }
        }
    }

    /// Cold open is one imperative line (page title). Prompt and objective stay
    /// available to VoiceOver and to the hint path — they do not consume the
    /// first viewport.
    private var supportCopy: String {
        [exercise.prompt, exercise.objective]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(page.title)
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($a11yFocus, equals: .prompt)
                    .accessibilityHint(supportCopy)

                if presentationPhase == .unanswered, !exercise.hint.isEmpty {
                    Button {
                        withAnimation(feedbackAnimation) {
                            engine.requestHint()
                            panelMessage = exercise.hint
                        }
                    } label: {
                        Image(systemName: "lightbulb")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.moss)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Show a hint")
                }
            }

            if showsStoryContext,
               (!page.context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !page.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                VStack(alignment: .leading, spacing: 5) {
                    if !page.context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(page.context)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.inkSoft)
                            .textCase(.uppercase)
                            .kerning(0.7)
                    }
                    if !page.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(page.body)
                            .font(.body)
                            .foregroundStyle(Theme.inkSoft)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    [page.context, page.body]
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                        .joined(separator: ". ")
                )
            }

            // Build / type: one soft English target under the imperative when
            // authored — replaces repeating it inside the prompt stack.
            if showsEnglishTarget, let translation = exercise.translation, !translation.isEmpty {
                Text(translation)
                    .font(.body)
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Stage zoning: prompt pinned top; the working area and its
            // adjacent feedback share the flexible middle, so a surface's
            // bank (builder tiles, choice list, meanings) lands in the lower
            // half instead of directly under the prompt. The story page
            // supplies a viewport min-height; AX-size content outgrows it and
            // scrolls as one composition, and with the keyboard up the scroll
            // view still brings the focused field into view.
            // Matching and builder keep fixed surface heights — pin under the
            // prompt so banks stay above the bar inset.
            if exercise.family == .matching || exercise.family == .sentenceConstruction {
                responseSurface
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, ExerciseSurface.zoneGap)

                feedbackPanel
            } else {
                Spacer(minLength: ExerciseSurface.zoneGap)

                responseSurface

                feedbackPanel

                Spacer(minLength: ExerciseSurface.zoneGap)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task { syncBarState() }
        .onAppear { syncBarState() }
        .onChange(of: engine.phase) { _, _ in syncBarState() }
        .onChange(of: checkReady) { _, _ in syncBarState() }
        .onChange(of: presentationPhase) { old, new in
            handlePresentationChange(from: old, to: new)
        }
        // Rebuild plan step 4: the shell owns interruption. Back navigation,
        // page advance, the chapter menu and atlas exit all dismantle this
        // view; backgrounding reaches it through the scene phase. An open D27
        // repair window closes as unrepaired struggle; a completed engine
        // loses nothing. The emitted events route through `apply` like any
        // other engine signal.
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                apply(engine.interrupt())
            }
        }
        .onDisappear {
            apply(engine.interrupt())
            announcementTask?.cancel()
        }
    }

    /// English target line for construction / typing when the title is the
    /// short imperative and the prompt would otherwise restate the sentence.
    private var showsEnglishTarget: Bool {
        switch exercise.family {
        case .sentenceConstruction, .freeTyping:
            return exercise.translation != nil
        default:
            return false
        }
    }

    @ViewBuilder
    private var responseSurface: some View {
        switch exercise.family {
        case .listenChoose:
            CountyListenChoiceSurface(exercise: exercise, locked: locksResponse, onPick: grade)
        case .sentenceConstruction:
            CountyBuilderSurface(
                exercise: exercise,
                locked: locksResponse,
                startsWithAudio: exercise.audioText != nil,
                onCheck: gradeText,
                onCheckReadyChange: { ready, handler in
                    checkReady = ready
                    checkAction = ready ? handler : nil
                    syncBarState()
                }
            )
        case .matching:
            CountyMatchingSurface(
                exercise: exercise,
                locked: locksResponse,
                onWrong: { noteSelectionWrong($0, escalates: false) },
                onRepair: noteSelectionRepair,
                onComplete: markCorrect
            )
        case .freeTyping:
            CountyTypingSurface(
                exercise: exercise,
                locked: locksResponse,
                recoveryPresented: engine.phase == .recovery,
                incorrectPresented: presentationPhase == .incorrect,
                onCheck: gradeText,
                onCheckReadyChange: { ready, handler in
                    checkReady = ready
                    checkAction = ready ? handler : nil
                    syncBarState()
                }
            )
        case .conversation:
            if let graph = exercise.conversation {
                CountyConversationGraphSurface(
                    graph: graph,
                    locked: locksResponse,
                    restored: conversationState,
                    onStateChange: { onConversationState?($0) },
                    onMisfit: { noteSelectionWrong($0, escalates: false) },
                    onRepair: noteSelectionRepair,
                    onComplete: { markCorrect($0) },
                    feedbackMessage: exercise.feedback
                )
            } else {
                CountyConversationSurface(exercise: exercise, locked: locksResponse, onPick: grade)
            }
        case .grammarDiscovery:
            CountyGrammarDiscoverySurface(exercise: exercise, locked: locksResponse, onPick: grade)
        case .fillGap:
            CountyChoiceSurface(
                exercise: exercise,
                locked: locksResponse,
                onPick: grade,
                usesWorkingIrish: true
            )
        case .readRespond:
            CountyReadRespondSurface(exercise: exercise, locked: locksResponse, onPick: grade)
        case .completion:
            CountyCompletionSurface(
                capabilities: exercise.capabilities ?? [],
                collectionWords: collectionWords,
                handoffNote: collectionHandoff,
                locked: locksResponse,
                onCollect: { onCollect?() },
                onComplete: { markCorrect($0) },
                feedbackMessage: exercise.feedback
            )
        case .contextualReview:
            if let candidate = resolvedReviewCandidate {
                CountyContextualReviewSurface(
                    candidate: candidate,
                    struggled: struggledPageIDs.contains(candidate.pageID),
                    locked: locksResponse,
                    recoveryPresented: engine.phase == .recovery,
                    incorrectPresented: presentationPhase == .incorrect,
                    onPick: { option in
                        if option.isCorrect {
                            formEngineResponse()
                            apply(engine.check(outcome: .correct, diagnosticShown: false))
                            markCorrect(candidate.exercise.feedback)
                        } else {
                            noteSelectionWrong(option.rationale, escalates: false)
                        }
                    },
                    onCheck: { value in
                        if normalized(value) == normalized(candidate.exercise.answer) {
                            formEngineResponse()
                            apply(engine.check(outcome: .correct, diagnosticShown: false))
                            markCorrect(candidate.exercise.feedback)
                        } else {
                            markWrong(candidate.exercise.recovery)
                        }
                    },
                    onCheckReadyChange: { ready, handler in
                        checkReady = ready
                        checkAction = ready ? handler : nil
                        syncBarState()
                    }
                )
            }
        case .recordCompare:
            CountySpeakingSurface(
                exercise: exercise,
                locked: locksResponse,
                onComplete: markCorrect,
                onPrimaryChange: { title, enabled, action in
                    onBarUpdate(
                        CountyExerciseBarState(title: title, isEnabled: enabled, isCheck: false),
                        action
                    )
                }
            )
        }
    }

    /// One stable panel identity across the lifecycle. State changes update
    /// icon, copy and color in place — instantly, not by cross-dissolve — so
    /// the incoming verdict can never overlap the panel it replaces (the D5
    /// ghost: the complete line rendered on top of the outgoing incorrect
    /// panel for the length of the settle animation). The recovery affordance
    /// exists only in the incorrect state; complete is exactly one line.
    @ViewBuilder
    private var feedbackPanel: some View {
        switch presentationPhase {
        case .unanswered:
            EmptyView()
        case .complete where exercise.family == .completion:
            // The completion surface already states the handoff under its
            // words list; a second support line below would repeat it.
            EmptyView()
        case .hint, .incorrect, .recovery, .complete:
            VStack(alignment: .leading, spacing: 2) {
                compactSupportLine(
                    icon: panelIcon,
                    accessibilityPrefix: panelPrefix,
                    text: panelText,
                    color: panelColor,
                    lineLimit: presentationPhase == .complete ? 2 : nil
                )
                if presentationPhase == .incorrect {
                    QuietHintButton(title: "Hint") {
                        withAnimation(feedbackAnimation) {
                            engine.beginRecovery()
                            panelMessage = exercise.recovery
                        }
                    }
                    .accessibilityIdentifier("exercise-recovery-button")
                    .transition(.identity)
                }
            }
            .animation(feedbackAnimation, value: presentationPhase)
        }
    }

    private var panelIcon: String {
        switch presentationPhase {
        case .hint: return "lightbulb"
        case .incorrect: return "arrow.uturn.left"
        case .recovery: return "arrow.uturn.left.circle"
        default: return "checkmark"
        }
    }

    private var panelPrefix: String {
        switch presentationPhase {
        case .hint: return "Hint"
        case .incorrect: return "Not quite"
        case .recovery: return "Hint"
        default: return "Complete"
        }
    }

    private var panelColor: Color {
        switch presentationPhase {
        case .hint, .recovery: return Theme.lichen
        case .incorrect: return Theme.rust
        default: return Theme.moss
        }
    }

    private var panelText: String {
        switch presentationPhase {
        case .hint: return panelMessage ?? exercise.hint
        case .incorrect: return panelMessage ?? ""
        case .recovery: return panelMessage ?? exercise.recovery
        // Concise verdict only — no titled card. Continue owns the next step.
        default: return panelMessage ?? exercise.feedback
        }
    }

    private func compactSupportLine(
        icon: String,
        accessibilityPrefix: String,
        text: String,
        color: Color,
        lineLimit: Int? = nil
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .contentTransition(.identity)
                .frame(width: 20, height: 20)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(accessibilityPrefix)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
                    .contentTransition(.identity)
                if !text.isEmpty {
                    Text(text)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(2)
                        .lineLimit(lineLimit)
                        .contentTransition(.identity)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text.isEmpty ? accessibilityPrefix : "\(accessibilityPrefix). \(text)")
        .accessibilityFocused($a11yFocus, equals: .feedback)
    }

    private func grade(_ option: CountyExerciseOption) {
        if option.isCorrect {
            formEngineResponse()
            apply(engine.check(outcome: .correct, diagnosticShown: false))
            markCorrect(option.rationale)
        } else {
            noteSelectionWrong(option.rationale, escalates: true)
        }
    }

    private func gradeText(_ value: String) {
        if normalized(value) == normalized(exercise.answer) {
            formEngineResponse()
            apply(engine.check(outcome: .correct, diagnosticShown: false))
            markCorrect(exercise.feedback)
        } else {
            markWrong(exercise.recovery)
        }
    }

    private func markWrong(_ message: String) {
        Haptics.error()
        formEngineResponse()
        let transition = engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: true)
        panelMessage = message
        apply(transition)
    }

    /// A wrong touch on a selection-graded family stays local: the diagnostic
    /// attaches to the affected target and the attempt remains open. Only a
    /// second wrong touch — the D27 repair window closing — records struggle,
    /// and only choice families raise the recovery panel for it. Matching keeps
    /// its brief on-target unlock instead of mastery-failure chrome.
    private func noteSelectionWrong(_ message: String, escalates: Bool) {
        Haptics.error()
        announce(message)
        formEngineResponse()
        let transition = withAnimation(feedbackAnimation) {
            let checked = engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: escalates)
            if engine.diagnosticEscalated {
                panelMessage = nil
            }
            return checked
        }
        apply(transition)
    }

    private func noteSelectionRepair() {
        formEngineResponse()
        engine.registerRepair()
    }

    private func markCorrect(_ message: String? = nil) {
        // The freeze's quiet vocabulary: a soft chisel per item; the single
        // flourish is reserved for the run's completion container (C5).
        if exercise.family == .completion {
            Haptics.flourish()
        } else {
            Haptics.chisel()
        }
        // Commit feedback copy before the phase animation so the complete
        // panel never stacks on the outgoing incorrect line (D5 ghost).
        panelMessage = message ?? exercise.feedback
        formEngineResponse()
        let transition = engine.complete()
        apply(transition)
        if transition.accepted {
            onComplete()
        }
        syncBarState()
    }

    private func syncBarState() {
        // One ink primary (D2): selection families publish disabled Continue until
        // graded; multi-part families publish Check until accepted; speak owns the
        // slot via onPrimaryChange. Never put a second ink fill in the response
        // surface.
        if engine.isComplete {
            onBarUpdate(CountyExerciseBarState(title: "Continue", isEnabled: true, isCheck: false), nil)
            return
        }

        switch exercise.family {
        case .recordCompare:
            // The speaking surface publishes its own primary per recording state
            // (Record, Stop, I compared both, or the mic-denied escape).
            break
        case .sentenceConstruction, .freeTyping:
            let title = exercise.family == .sentenceConstruction ? "Check the order" : "Check the sentence"
            onBarUpdate(
                CountyExerciseBarState(title: title, isEnabled: checkReady, isCheck: true),
                checkReady ? checkAction : nil
            )
        case .contextualReview:
            // A typed re-entry owns the Check slot; a choice re-entry completes
            // on selection like its parent family.
            if resolvedReviewCandidate?.exercise.family == .freeTyping {
                onBarUpdate(
                    CountyExerciseBarState(title: "Check the line", isEnabled: checkReady, isCheck: true),
                    checkReady ? checkAction : nil
                )
            } else {
                onBarUpdate(CountyExerciseBarState(title: "Continue", isEnabled: false, isCheck: false), nil)
            }
        default:
            // listenChoose, matching, fillGap, conversation, readRespond,
            // grammarDiscovery, completion: Continue only after the surface
            // completes (matching auto-settles pairs; selection checks on tap).
            onBarUpdate(CountyExerciseBarState(title: "Continue", isEnabled: false, isCheck: false), nil)
        }
    }

    private var feedbackAnimation: Animation? {
        reduceMotion ? nil : Motion.settle
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: " | ", with: " | ")
            .lowercased()
    }
}

private struct CountyListenChoiceSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onPick: (CountyExerciseOption) -> Void
    /// When false, the parent owns the audio instrument (review remap).
    var includeAudio: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// True after the learner plays the clip or touches a choice — either
    /// lifts the demoted choice stack (F1: audio leads, meanings follow).
    @State private var hasEngaged = false

    private var offersAudio: Bool {
        guard includeAudio, let audioText = exercise.audioText else { return false }
        return SpeechService.shared.canSpeak(audioText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if includeAudio {
                if let audioText = exercise.audioText, SpeechService.shared.canSpeak(audioText) {
                    CountyAudioPromptControl(
                        text: audioText,
                        presentation: .listenObject(
                            hearLabel: "Listen",
                            replayLabel: "Listen again"
                        ),
                        disabled: locked,
                        onPlayed: { hasEngaged = true }
                    )
                } else if exercise.audioText != nil {
                    MissingAudioNotice()
                }
            }

            if offersAudio {
                Spacer(minLength: ExerciseSurface.zoneGap)
            }

            CountyChoiceSurface(
                exercise: exercise,
                locked: locked,
                onPick: { option in
                    hasEngaged = true
                    onPick(option)
                },
                demoted: offersAudio && !hasEngaged && !locked
            )
            .animation(reduceMotion ? nil : Motion.settle, value: hasEngaged)
            .accessibilityHint(
                offersAudio && !hasEngaged
                    ? "You can listen first or choose an answer."
                    : ""
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

/// Shared listen instrument: ripple stone for recognition, sunk tray for builders.
private struct CountyAudioPromptControl: View {
    enum Presentation {
        /// Ripple disc without revealing the Irish (recognition tasks).
        case listenObject(hearLabel: String, replayLabel: String)
        /// Compact sunk model tray above a builder bank.
        case modelControl(playLabel: String, replayLabel: String)
    }

    let text: String
    let presentation: Presentation
    var includeSlow: Bool = true
    /// Inline ripple under an Irish hero (read/respond); default is stage hero.
    var compact: Bool = false
    var disabled: Bool = false
    var onWillPlay: (() -> Void)? = nil
    var onPlayed: (() -> Void)? = nil

    @ObservedObject private var speech = SpeechService.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasPlayed = false

    private static let slowRate: Float = 0.7

    private var isPlaying: Bool { speech.isSpeaking(text) }

    private var accessibilityLabel: String {
        switch presentation {
        case .listenObject(let hear, let replay):
            return hasPlayed ? replay : hear
        case .modelControl(let play, let replay):
            return hasPlayed ? replay : play
        }
    }

    private var modelTrayLabel: String { accessibilityLabel }

    private var actionWord: String { hasPlayed ? "Éist arís" : "Éist" }

    var body: some View {
        switch presentation {
        case .listenObject:
            rippleInstrument
        case .modelControl:
            modelInstrumentTray
        }
    }

    // MARK: Ripple stone (listen and choose, listen-only read/respond)

    @ViewBuilder
    private var rippleInstrument: some View {
        if compact {
            compactRippleRow
        } else {
            heroRippleColumn
        }
    }

    private var heroRippleColumn: some View {
        VStack(spacing: 14) {
            rippleDisc(diameter: 132, waveWidth: 52)
            HStack(spacing: 16) {
                Text(actionWord)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                if includeSlow {
                    slowTextButton
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .opacity(disabled ? 0.55 : 1)
    }

    private var compactRippleRow: some View {
        HStack(spacing: 12) {
            rippleDisc(diameter: 56, waveWidth: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(actionWord)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.moss)
                if includeSlow {
                    slowTextButton
                }
            }
            Spacer(minLength: 0)
        }
        .opacity(disabled ? 0.55 : 1)
    }

    private func rippleDisc(diameter: CGFloat, waveWidth: CGFloat) -> some View {
        Button {
            play(rate: 1)
        } label: {
            ZStack {
                rippleRings(diameter: diameter)
                OrganicWaveMark(playing: isPlaying)
                    .frame(width: waveWidth, height: waveWidth * 0.54)
            }
            .frame(width: diameter, height: diameter)
            .background(Theme.raised)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(
                        isPlaying ? Theme.moss : Theme.line,
                        lineWidth: isPlaying ? ExerciseSurface.borderState : ExerciseSurface.borderHairline
                    )
            }
            .tactileLip(radius: diameter / 2, active: !disabled)
        }
        .buttonStyle(CarvePress())
        .disabled(disabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isPlaying ? "playing" : (hasPlayed ? "played" : "ready"))
    }

    private var slowTextButton: some View {
        Button {
            play(rate: Self.slowRate)
        } label: {
            Text("Slow")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSoft)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityLabel("Play slowly")
        .accessibilityHint("Plays the same recording at a slower rate")
    }

    private func rippleRings(diameter: CGFloat) -> some View {
        TimelineView(
            .animation(
                minimumInterval: reduceMotion || !isPlaying ? 60 : 0.16,
                paused: reduceMotion || !isPlaying
            )
        ) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let scale = diameter / 132
            ZStack {
                ForEach(0..<3, id: \.self) { ring in
                    let base = (44 + CGFloat(ring) * 22) * scale
                    let breathe = isPlaying && !reduceMotion
                        ? 1 + 0.06 * CGFloat(sin(t * 2.4 + Double(ring)))
                        : 1
                    Circle()
                        .stroke(Theme.line.opacity(0.85 - Double(ring) * 0.2), lineWidth: 1)
                        .frame(width: base * breathe, height: base * breathe)
                        .opacity(isPlaying ? 0.9 - Double(ring) * 0.22 : 0.55 - Double(ring) * 0.12)
                }
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: Sunk tray (audio-prompted builders)

    /// Full-width sunk tray with Slow demoted to a caption accessory at the
    /// trailing edge — never a peer capsule beside the play control.
    private var modelInstrumentTray: some View {
        HStack(alignment: .center, spacing: 0) {
            Button {
                play(rate: 1)
            } label: {
                HStack(alignment: .center, spacing: 14) {
                    AudioWaveMark(playing: isPlaying)
                        .frame(width: 36, height: 28)
                    Text(modelTrayLabel)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 8)
                }
                .padding(.leading, 16)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity, minHeight: ExerciseSurface.listenTrayMinHeight, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(CarvePress())
            .disabled(disabled)
            .accessibilityLabel(modelTrayLabel)
            .accessibilityValue(isPlaying ? "playing" : (hasPlayed ? "played" : "ready"))

            if includeSlow {
                slowAccessory(accessibilityLabel: "Play slowly")
                    .padding(.trailing, 8)
            }
        }
        .background(Theme.sunk)
        .clipShape(RoundedRectangle(cornerRadius: ExerciseSurface.trayRadius))
        .overlay {
            RoundedRectangle(cornerRadius: ExerciseSurface.trayRadius)
                .stroke(isPlaying ? Theme.moss : Color.clear, lineWidth: isPlaying ? ExerciseSurface.borderState : 0)
        }
        .opacity(disabled ? 0.55 : 1)
    }

    /// The demoted rate accessory: caption voice tucked next to the play
    /// control, not a peer capsule. Label, hint and action are unchanged.
    private func slowAccessory(accessibilityLabel: String) -> some View {
        Button {
            play(rate: Self.slowRate)
        } label: {
            Text("Slow")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSoft)
                .padding(.horizontal, 8)
                .frame(
                    minWidth: ExerciseSurface.slowCapsuleMinWidth,
                    minHeight: ExerciseSurface.slowCapsuleMinHeight
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(CarvePress())
        .disabled(disabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Plays the same recording at a slower rate")
    }

    private func play(rate: Float) {
        guard !disabled else { return }
        Haptics.tap()
        onWillPlay?()
        speech.speak(text, rate: rate)
        hasPlayed = true
        onPlayed?()
    }
}

/// Five-bar mark that reads as an audio object; pulses only while playing.
/// `playing` is the control's live `SpeechService.isSpeaking(text)`, so the
/// bars animate exactly while their own line sounds and rest when idle;
/// Reduce Motion keeps them static. `compact` fits instrument pills.
private struct AudioWaveMark: View {
    let playing: Bool
    var compact: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var heights: [CGFloat] { compact ? [7, 12, 9, 14, 10] : [11, 18, 13, 22, 15] }
    private var barWidth: CGFloat { compact ? 3 : 4 }
    private var barSpacing: CGFloat { compact ? 2 : 3 }

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: reduceMotion || !playing ? 60 : 0.12,
                paused: reduceMotion || !playing
            )
        ) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(0..<heights.count, id: \.self) { index in
                    let pulse = playing && !reduceMotion
                        ? (0.55 + 0.45 * abs(sin(t * 4.2 + Double(index))))
                        : 1
                    Capsule()
                        .fill(Theme.moss.opacity(playing ? 0.95 : 0.38))
                        .frame(width: barWidth, height: heights[index] * pulse)
                }
            }
            .frame(width: compact ? 22 : 32, height: compact ? 16 : 24)
        }
        .accessibilityHidden(true)
    }
}

/// Organic wave stroke for the ripple listen instrument — distinct from EQ bars.
private struct OrganicWaveMark: View {
    let playing: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: reduceMotion || !playing ? 60 : 0.1,
                paused: reduceMotion || !playing
            )
        ) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { graphicsContext, size in
                var path = Path()
                let midY = size.height * 0.5
                let amplitude = playing && !reduceMotion ? size.height * 0.22 : size.height * 0.14
                let wavelength = size.width / 2.2
                path.move(to: CGPoint(x: 0, y: midY))
                let steps = 24
                for step in 0...steps {
                    let x = size.width * CGFloat(step) / CGFloat(steps)
                    let phase = (x / wavelength) * .pi * 2 + (playing ? t * 5 : 0)
                    let y = midY + sin(phase) * amplitude
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                graphicsContext.stroke(
                    path,
                    with: .color(Theme.moss.opacity(playing ? 0.95 : 0.42)),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .accessibilityHidden(true)
    }
}

private struct MissingAudioNotice: View {
    var body: some View {
        Label {
            Text("The model recording is missing. You can still read the task, but listening is unavailable on this device.")
        } icon: {
            Image(systemName: "speaker.slash")
        }
        .font(.body)
        .foregroundStyle(Theme.rust)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.rustTint)
        .clipShape(RoundedRectangle(cornerRadius: ExerciseSurface.tileRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct CountyChoiceSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onPick: (CountyExerciseOption) -> Void
    /// Two-Voice: true when the options themselves are working Irish (serif);
    /// English meanings and interface choices stay in SF.
    var usesWorkingIrish: Bool = false

    /// When false, the parent surface owns the Irish prompt (read/respond).
    var showsSentenceTemplate: Bool = true
    /// F1 listen-choose: meanings stay tappable but visually follow the audio
    /// instrument until the learner listens or answers.
    var demoted: Bool = false

    @State private var wrongOptionIDs: Set<String> = []
    @State private var chosenCorrectID: String?

    private var optionFont: Font {
        usesWorkingIrish ? .system(.title3, design: .serif) : .title3
    }

    var body: some View {
        VStack(spacing: ExerciseSurface.choiceGap) {
            if showsSentenceTemplate, let template = exercise.sentenceTemplate {
                Text(template)
                    .font(.system(.title, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                    .padding(.bottom, 2)
                    .accessibilityAddTraits(.isHeader)
            }
            ForEach(exercise.options) { option in
                choiceRow(option)
            }
        }
        .opacity(demoted ? 0.84 : 1)
    }

    @ViewBuilder
    private func choiceRow(_ option: CountyExerciseOption) -> some View {
        let isWrong = wrongOptionIDs.contains(option.id)
        let isCorrect = chosenCorrectID == option.id
        let settledAway = chosenCorrectID != nil && !isCorrect && !isWrong
        let shortLabel = option.text.split(whereSeparator: \.isWhitespace).count <= 3
        VStack(alignment: .leading, spacing: 6) {
            Button {
                guard !locked else { return }
                if option.isCorrect {
                    chosenCorrectID = option.id
                    wrongOptionIDs.removeAll()
                } else {
                    wrongOptionIDs.insert(option.id)
                }
                onPick(option)
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(leadingMark(for: option))
                        .frame(width: 4, height: 22)
                        .opacity(isCorrect || isWrong ? 1 : 0)
                        .accessibilityHidden(true)
                    Text(option.text)
                        .font(optionFont)
                        .multilineTextAlignment(shortLabel ? .center : .leading)
                        .frame(maxWidth: .infinity, alignment: shortLabel ? .center : .leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(Theme.moss)
                            .accessibilityHidden(true)
                    } else if isWrong {
                        Image(systemName: "xmark.circle")
                            .font(.body)
                            .foregroundStyle(Theme.rust)
                            .accessibilityHidden(true)
                    } else {
                        Color.clear.frame(width: 22, height: 22)
                    }
                }
                .foregroundStyle(Theme.ink)
                .padding(.vertical, ExerciseSurface.optionPadV)
                .padding(.horizontal, ExerciseSurface.optionPadH)
                .frame(maxWidth: .infinity, minHeight: ExerciseSurface.choiceMinHeight, alignment: .center)
                .background(rowBackground(for: option))
                .clipShape(RoundedRectangle(cornerRadius: ExerciseSurface.tileRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: ExerciseSurface.tileRadius)
                        .stroke(rowBorder(for: option), lineWidth: rowBorderWidth(for: option))
                }
                .tactileLip(radius: ExerciseSurface.tileRadius, active: !isCorrect && !isWrong)
            }
            .buttonStyle(CarvePress())
            .disabled(locked)
            .opacity(settledAway ? 0.42 : 1)
            .accessibilityLabel(option.text)
            .accessibilityValue(isWrong ? "Not correct" : (isCorrect ? "Correct" : ""))
            .accessibilityAddTraits(choiceTraits(for: option))

            if isWrong, !locked {
                Text(option.rationale)
                    .font(.subheadline)
                    .foregroundStyle(Theme.rust)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, ExerciseSurface.optionPadH)
                    .transition(.identity)
            }
        }
    }

    private func choiceTraits(for option: CountyExerciseOption) -> AccessibilityTraits {
        chosenCorrectID == option.id ? .isSelected : []
    }

    private func leadingMark(for option: CountyExerciseOption) -> Color {
        if chosenCorrectID == option.id { return Theme.moss }
        if wrongOptionIDs.contains(option.id) { return Theme.rust }
        return .clear
    }

    private func rowBackground(for option: CountyExerciseOption) -> Color {
        if chosenCorrectID == option.id { return Theme.mossTintDeep }
        if wrongOptionIDs.contains(option.id) { return Theme.rustTint }
        return Theme.raised
    }

    private func rowBorder(for option: CountyExerciseOption) -> Color {
        if chosenCorrectID == option.id { return Theme.moss }
        if wrongOptionIDs.contains(option.id) { return Theme.rust }
        return Theme.line
    }

    private func rowBorderWidth(for option: CountyExerciseOption) -> CGFloat {
        if chosenCorrectID == option.id { return ExerciseSurface.borderState }
        if wrongOptionIDs.contains(option.id) { return ExerciseSurface.borderState }
        return ExerciseSurface.borderHairline
    }
}

private struct CountyConversationSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onPick: (CountyExerciseOption) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("They ask")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkSoft)
                Text(conversationPrompt)
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.sunk)
            .clipShape(RoundedRectangle(cornerRadius: ExerciseSurface.tileRadius))

            Text("Your reply")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSoft)

            CountyChoiceSurface(
                exercise: exercise,
                locked: locked,
                onPick: onPick,
                usesWorkingIrish: true
            )
        }
    }

    private var conversationPrompt: String {
        let prompt = exercise.prompt
        if let range = prompt.range(of: ". Choose", options: [.caseInsensitive]) {
            return String(prompt[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let question = prompt.split(separator: "?").first, prompt.contains("?") {
            return "\(question)?"
        }
        return prompt
    }
}

/// C1 conversation: a finite authored turn graph rendered as one living
/// transcript. Partner lines keep their sunk cards; fitting learner replies
/// join the transcript as moss rows. A mismatched reply carries its diagnostic
/// on that turn and the graph never advances until a fitting reply lands, so
/// any acceptable branch can be tried without clearing prior turns. The state
/// persists after every turn, and an interrupted conversation resumes at the
/// exact node with its transcript intact.
private struct CountyConversationGraphSurface: View {
    let graph: CountyConversationGraph
    let locked: Bool
    let restored: CountyConversationState?
    let onStateChange: (CountyConversationState) -> Void
    let onMisfit: (String) -> Void
    let onRepair: () -> Void
    let onComplete: (String?) -> Void
    let feedbackMessage: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var speech = SpeechService.shared
    @State private var state: CountyConversationState
    @State private var misfitReplyID: String?

    init(
        graph: CountyConversationGraph,
        locked: Bool,
        restored: CountyConversationState?,
        onStateChange: @escaping (CountyConversationState) -> Void,
        onMisfit: @escaping (String) -> Void,
        onRepair: @escaping () -> Void,
        onComplete: @escaping (String?) -> Void,
        feedbackMessage: String
    ) {
        self.graph = graph
        self.locked = locked
        self.restored = restored
        self.onStateChange = onStateChange
        self.onMisfit = onMisfit
        self.onRepair = onRepair
        self.onComplete = onComplete
        self.feedbackMessage = feedbackMessage
        let valid = restored.flatMap { graph.node(id: $0.currentNodeID) != nil ? $0 : nil }
        _state = State(initialValue: valid ?? CountyConversationEngine.initialState(for: graph))
        _misfitReplyID = State(initialValue: nil)
    }

    private var isConversationComplete: Bool {
        guard let last = state.turns.last,
              let node = graph.node(id: last.nodeID),
              let reply = node.replies.first(where: { $0.id == last.replyID }) else { return false }
        return reply.next == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !state.turns.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(state.turns.enumerated()), id: \.offset) { _, turn in
                        if let node = graph.node(id: turn.nodeID),
                           let reply = node.replies.first(where: { $0.id == turn.replyID }) {
                            partnerCard(node.partner, gloss: node.partnerGloss, settled: true)
                            learnerRow(reply.text, gloss: reply.gloss)
                        }
                    }
                }
                .accessibilityElement(children: .contain)
            }

            if !isConversationComplete, let node = CountyConversationEngine.currentNode(in: state, graph: graph) {
                partnerCard(node.partner, gloss: node.partnerGloss, audioText: node.audioText, settled: false)

                VStack(spacing: 10) {
                    ForEach(node.replies) { reply in
                        replyRow(reply)
                    }
                }
            }
        }
    }

    private func pick(_ reply: CountyConversationReply) {
        switch CountyConversationEngine.choose(replyID: reply.id, in: state, graph: graph) {
        case .misfit(let message):
            misfitReplyID = reply.id
            onMisfit(message)
        case .advanced(let next):
            settle(into: next, reply: reply)
        case .completed(let next):
            settle(into: next, reply: reply)
            onComplete(feedbackMessage)
        }
    }

    private func settle(into next: CountyConversationState, reply: CountyConversationReply) {
        if let audioText = reply.audioText, speech.canSpeak(audioText) {
            speech.speak(audioText)
        } else {
            Haptics.tap()
        }
        misfitReplyID = nil
        withAnimation(reduceMotion ? nil : Motion.settle) {
            state = next
        }
        onRepair()
        onStateChange(next)
    }

    private func partnerCard(
        _ line: String,
        gloss: String?,
        audioText: String? = nil,
        settled: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(line)
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(settled ? Theme.inkSoft : Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let audioText, speech.canSpeak(audioText) {
                    Button {
                        speech.speak(audioText)
                    } label: {
                        Image(systemName: speech.isSpeaking(audioText) ? "speaker.wave.2.fill" : "speaker.wave.2")
                            .font(.subheadline)
                            .foregroundStyle(Theme.moss)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Hear the line: \(line)")
                }
            }
            if let gloss, !gloss.isEmpty {
                Text(gloss)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.raised)
        // Transcript alignment: partner turns hug the leading edge with a
        // tightened bottom-leading corner — the speaker's side of the page.
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: ExerciseSurface.tileRadius,
            bottomLeadingRadius: 4,
            bottomTrailingRadius: ExerciseSurface.tileRadius,
            topTrailingRadius: ExerciseSurface.tileRadius
        ))
        .overlay {
            UnevenRoundedRectangle(
                topLeadingRadius: ExerciseSurface.tileRadius,
                bottomLeadingRadius: 4,
                bottomTrailingRadius: ExerciseSurface.tileRadius,
                topTrailingRadius: ExerciseSurface.tileRadius
            )
            .stroke(Theme.line, lineWidth: ExerciseSurface.borderHairline)
        }
        .opacity(settled ? 0.75 : 1.0)
        .padding(.trailing, 40)
        .accessibilityElement(children: .contain)
    }

    private func learnerRow(_ text: String, gloss: String?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.moss)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(text)
                    .font(.system(.body, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.moss)
                    .fixedSize(horizontal: false, vertical: true)
                if let gloss, !gloss.isEmpty {
                    Text(gloss)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, ExerciseSurface.optionPadH)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.mossTint)
        // Learner turns hug the trailing edge, corner tightened to match.
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: ExerciseSurface.tileRadius,
            bottomLeadingRadius: ExerciseSurface.tileRadius,
            bottomTrailingRadius: 4,
            topTrailingRadius: ExerciseSurface.tileRadius
        ))
        .opacity(0.75)
        .padding(.leading, 40)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("You said: \(text)")
    }

    private func replyRow(_ reply: CountyConversationReply) -> some View {
        let misfit = misfitReplyID == reply.id
        return VStack(alignment: .leading, spacing: 6) {
            Button {
                guard !locked else { return }
                pick(reply)
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(reply.text)
                            .font(.system(.title3, design: .serif, weight: .semibold))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        if let gloss = reply.gloss, !gloss.isEmpty {
                            Text(gloss)
                                .font(.subheadline)
                                .foregroundStyle(Theme.inkSoft)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer(minLength: 8)
                }
                .foregroundStyle(Theme.ink)
                .padding(.vertical, ExerciseSurface.optionPadV)
                .padding(.horizontal, ExerciseSurface.optionPadH)
                .frame(maxWidth: .infinity, minHeight: ExerciseSurface.choiceMinHeight, alignment: .leading)
                .background(misfit ? Theme.rustTint : Theme.raised)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: ExerciseSurface.tileRadius,
                    bottomLeadingRadius: ExerciseSurface.tileRadius,
                    bottomTrailingRadius: 4,
                    topTrailingRadius: ExerciseSurface.tileRadius
                ))
                .overlay {
                    UnevenRoundedRectangle(
                        topLeadingRadius: ExerciseSurface.tileRadius,
                        bottomLeadingRadius: ExerciseSurface.tileRadius,
                        bottomTrailingRadius: 4,
                        topTrailingRadius: ExerciseSurface.tileRadius
                    )
                    .stroke(
                        misfit ? Theme.rust : Theme.line,
                        lineWidth: misfit ? ExerciseSurface.borderState : ExerciseSurface.borderHairline
                    )
                }
                .tactileLip(radius: ExerciseSurface.tileRadius, active: !misfit, bottomTrailingRadius: 4)
            }
            .buttonStyle(CarvePress())
            .disabled(locked)
            .accessibilityLabel(reply.gloss.map { "\(reply.text) — \($0)" } ?? reply.text)
            .accessibilityValue(misfit ? "Does not fit this turn" : "")

            if misfit, let diagnostic = reply.diagnostic {
                Text(diagnostic)
                    .font(.subheadline)
                    .foregroundStyle(Theme.rust)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, ExerciseSurface.optionPadH)
            }
        }
        .padding(.leading, 40)
    }
}

/// F6 read or listen and respond: the Irish line is the hero; a compact listen
/// control sits beneath it when audio is available. Context notes belong on
/// story pages, not inside the exercise surface.
private struct CountyReadRespondSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onPick: (CountyExerciseOption) -> Void

    @ObservedObject private var speech = SpeechService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: ExerciseSurface.zoneGap) {
            if let line = exercise.sentenceTemplate {
                VStack(alignment: .leading, spacing: 10) {
                    Text(line)
                        .font(.system(.title, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)

                    if let audioText = exercise.audioText, speech.canSpeak(audioText) {
                        CountyAudioPromptControl(
                            text: audioText,
                            presentation: .listenObject(
                                hearLabel: "Listen",
                                replayLabel: "Listen again"
                            ),
                            compact: true,
                            disabled: locked
                        )
                    } else if exercise.audioText != nil {
                        MissingAudioNotice()
                    }
                }
            } else if let audioText = exercise.audioText {
                if speech.canSpeak(audioText) {
                    CountyAudioPromptControl(
                        text: audioText,
                        presentation: .listenObject(
                            hearLabel: "Listen",
                            replayLabel: "Listen again"
                        ),
                        disabled: locked
                    )
                } else {
                    MissingAudioNotice()
                }
            } else if let note = exercise.modelText, !note.isEmpty {
                Text(note)
                    .font(.body)
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                    .background(Theme.sunk)
                    .clipShape(RoundedRectangle(cornerRadius: ExerciseSurface.tileRadius))
            }

            CountyChoiceSurface(
                exercise: exercise,
                locked: locked,
                onPick: onPick,
                showsSentenceTemplate: false
            )
        }
    }
}

/// C5 completion: states what the run has made possible and hands its words to
/// the collection — capabilities, not points theatre. No response is required;
/// the page completes as it appears so the bottom slot carries one live
/// Continue.
private struct CountyCompletionSurface: View {
    let capabilities: [CountyCompletionCapability]
    let collectionWords: [AtlasWord]
    let handoffNote: String
    let locked: Bool
    let onCollect: () -> Void
    let onComplete: (String?) -> Void
    let feedbackMessage: String

    @State private var gathered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(capabilities) { capability in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: capability.symbol)
                            .font(.headline)
                            .foregroundStyle(Theme.moss)
                            .frame(width: 28, height: 28)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(capability.title)
                                .font(.headline)
                                .foregroundStyle(Theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.moss)
                            .accessibilityHidden(true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.raised)
                    .clipShape(RoundedRectangle(cornerRadius: ExerciseSurface.tileRadius))
                    .accessibilityElement(children: .combine)
                }
            }

            if !collectionWords.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Words you carry from this run")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.inkSoft)
                    ForEach(collectionWords) { word in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(word.ga)
                                .font(.system(.body, design: .serif, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                            Text("· \(word.en)")
                                .font(.body)
                                .foregroundStyle(Theme.inkSoft)
                            Spacer(minLength: 8)
                        }
                        .frame(minHeight: 32)
                        .accessibilityElement(children: .combine)
                    }
                    Text(handoffNote)
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.sunk)
                .clipShape(RoundedRectangle(cornerRadius: ExerciseSurface.tileRadius))
            }
        }
        .onAppear {
            guard !gathered else { return }
            gathered = true
            onCollect()
            if !locked {
                onComplete(feedbackMessage)
            }
        }
    }
}

/// C3 contextual mistake review: the run's own struggle record chooses one
/// authored target, and the learner re-enters it from the original sound or
/// sentence — context first, then the original response method. It is never a
/// bare delayed retype.
private struct CountyContextualReviewSurface: View {
    let candidate: CountyReviewCandidate
    let struggled: Bool
    let locked: Bool
    var recoveryPresented: Bool = false
    var incorrectPresented: Bool = false
    let onPick: (CountyExerciseOption) -> Void
    let onCheck: (String) -> Void
    let onCheckReadyChange: (Bool, @escaping () -> Void) -> Void

    @ObservedObject private var speech = SpeechService.shared

    private var embedded: CountyExercise { candidate.exercise }

    var body: some View {
        VStack(alignment: .leading, spacing: ExerciseSurface.zoneGap) {
            switch embedded.family {
            case .freeTyping:
                CountyTypingSurface(
                    exercise: embedded,
                    locked: locked,
                    recoveryPresented: recoveryPresented,
                    incorrectPresented: incorrectPresented,
                    onCheck: onCheck,
                    onCheckReadyChange: onCheckReadyChange
                )
            case .listenChoose:
                // One InstrumentControl only — choices without a second Hear.
                if let audioText = embedded.audioText, speech.canSpeak(audioText) {
                    CountyAudioPromptControl(
                        text: audioText,
                        presentation: .listenObject(
                            hearLabel: "Listen",
                            replayLabel: "Listen again"
                        ),
                        disabled: locked
                    )
                } else if embedded.audioText != nil {
                    MissingAudioNotice()
                }
                CountyListenChoiceSurface(
                    exercise: embedded,
                    locked: locked,
                    onPick: onPick,
                    includeAudio: false
                )
            default:
                CountyChoiceSurface(
                    exercise: embedded,
                    locked: locked,
                    onPick: onPick,
                    usesWorkingIrish: embedded.family == .fillGap
                )
            }
        }
    }
}

private struct CountyGrammarDiscoverySurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onPick: (CountyExerciseOption) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !workedExamples.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(workedExamples, id: \.self) { line in
                        Text(line)
                            .font(.system(.title3, design: .serif, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.sunk)
                .clipShape(RoundedRectangle(cornerRadius: ExerciseSurface.tileRadius))
            }

            if let question = discoveryQuestion {
                Text(question)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            CountyChoiceSurface(exercise: exercise, locked: locked, onPick: onPick)
        }
    }

    private var workedExamples: [String] {
        if let model = exercise.modelText, !model.isEmpty {
            return model.components(separatedBy: "\n").filter { !$0.isEmpty }
        }
        let prompt = exercise.prompt
        if let range = prompt.range(of: " What ", options: [.caseInsensitive]) {
            return String(prompt[..<range.lowerBound])
                .components(separatedBy: ". ")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        return []
    }

    private var discoveryQuestion: String? {
        let prompt = exercise.prompt
        if let range = prompt.range(of: " What ", options: [.caseInsensitive]) {
            return String(prompt[range.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
}

/// Tile builder with a stable bank: picked tiles leave a sunk placeholder so
/// Sentence construction: ruled answer tray above, word bank below. Placed
/// tiles leave the bank entirely — no ghost placeholders. Audio-first steps
/// lead with ripple listen; the bank stays visually secondary until heard.
private struct CountyBuilderSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let startsWithAudio: Bool
    let onCheck: (String) -> Void
    let onCheckReadyChange: (Bool, @escaping () -> Void) -> Void

    @ObservedObject private var speech = SpeechService.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var placed: Set<Int> = []
    @State private var chosen: [Int] = []
    @State private var heard = false

    /// Two-Voice: bank tokens are working Irish except `ordering`, whose
    /// clause tiles are authored English (evidence-sequence steps) in every
    /// pack — interface text, so SF.
    private var usesWorkingIrish: Bool {
        exercise.authoredUse != "ordering"
    }

    private var tokenFont: Font {
        usesWorkingIrish ? .system(.title3, design: .serif) : .title3
    }

    private var bankDemoted: Bool {
        startsWithAudio && !heard && chosen.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if startsWithAudio, let audioText = exercise.audioText {
                if speech.canSpeak(audioText) {
                    CountyAudioPromptControl(
                        text: audioText,
                        presentation: .listenObject(
                            hearLabel: "Listen",
                            replayLabel: "Listen again"
                        ),
                        disabled: locked,
                        onPlayed: {
                            heard = true
                            publishCheckState()
                        }
                    )
                } else {
                    MissingAudioNotice()
                }
            }

            answerTray
                .padding(.top, startsWithAudio ? ExerciseSurface.choiceGap : 0)

            tokenBank
                .padding(.top, ExerciseSurface.zoneGap)
                .opacity(bankDemoted ? 0.84 : 1)
                .animation(reduceMotion ? nil : Motion.settle, value: bankDemoted)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { publishCheckState() }
        .onChange(of: locked) { _, _ in publishCheckState() }
    }

    private var answerTray: some View {
        FlowLayout(spacing: ExerciseSurface.tileGridSpacing) {
            ForEach(Array(chosen.enumerated()), id: \.offset) { position, slot in
                tile(exercise.tokens[slot], inAnswer: true) {
                    placed.remove(slot)
                    chosen.remove(at: position)
                    publishCheckState()
                }
                .accessibilityLabel(exercise.tokens[slot])
                .accessibilityHint("In your answer. Double-tap to return it to the bank.")
            }
        }
        .frame(maxWidth: .infinity, minHeight: ExerciseSurface.builderTrayMinHeight, alignment: .leading)
        .padding(12)
        .background(alignment: .topLeading) {
            ZStack(alignment: .topLeading) {
                Theme.sunk
                VStack(spacing: ExerciseSurface.chipMinHeight + ExerciseSurface.tileGridSpacing - ExerciseSurface.borderHairline) {
                    ForEach(0..<4, id: \.self) { _ in
                        Rectangle()
                            .fill(Theme.line)
                            .frame(height: ExerciseSurface.borderHairline)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12 + ExerciseSurface.chipMinHeight + ExerciseSurface.tileGridSpacing / 2 - ExerciseSurface.borderHairline / 2)
                .accessibilityHidden(true)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: ExerciseSurface.trayRadius))
        .overlay {
            RoundedRectangle(cornerRadius: ExerciseSurface.trayRadius)
                .stroke(Theme.line, lineWidth: ExerciseSurface.borderHairline)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            chosen.isEmpty
                ? "Your answer. Tap words from the bank below."
                : "Your answer: \(chosen.map { exercise.tokens[$0] }.joined(separator: " "))"
        )
    }

    private var tokenBank: some View {
        FlowLayout(spacing: ExerciseSurface.tileGridSpacing) {
            ForEach(Array(exercise.tokens.enumerated()), id: \.offset) { slot, token in
                if !placed.contains(slot) {
                    tile(token, inAnswer: false) {
                        placed.insert(slot)
                        chosen.append(slot)
                        publishCheckState()
                    }
                    .accessibilityIdentifier("builder-bank-\(token)")
                    .accessibilityLabel(token)
                    .accessibilityHint("Add to your answer.")
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: ExerciseSurface.chipMinHeight, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private func publishCheckState() {
        let ready = chosen.count == exercise.tokens.count && !locked && (!startsWithAudio || heard)
        onCheckReadyChange(ready, performCheck)
    }

    private func performCheck() {
        let separator = exercise.authoredUse == "ordering" ? " | " : " "
        onCheck(chosen.map { exercise.tokens[$0] }.joined(separator: separator))
    }

    private func tile(_ token: String, inAnswer: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(token)
                .font(tokenFont)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, ExerciseSurface.optionPadH)
                .frame(minHeight: ExerciseSurface.chipMinHeight)
                .background(Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: ExerciseSurface.chipRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: ExerciseSurface.chipRadius)
                        .stroke(
                            inAnswer ? Theme.moss : Theme.line,
                            lineWidth: inAnswer ? ExerciseSurface.borderState : ExerciseSurface.borderHairline
                        )
                }
                .tactileLip(radius: ExerciseSurface.chipRadius, active: !inAnswer)
        }
        .buttonStyle(CarvePress())
        .disabled(locked)
    }
}

/// Two-column matching: Irish stone in one column, shuffled chalk meanings in
/// the other. Columns are independent — the learner joins any word to any
/// meaning. A moss thread snaps across the gutter when a pair locks.
private struct CountyMatchingSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onWrong: (String) -> Void
    let onRepair: () -> Void
    let onComplete: (String?) -> Void

    @ObservedObject private var speech = SpeechService.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedLeft: CountyExercisePair?
    @State private var matched: Set<String> = []
    @State private var missedRightID: String?
    @State private var meaningOrder: [String]
    @State private var celebratingPairID: String?

    init(
        exercise: CountyExercise,
        locked: Bool,
        onWrong: @escaping (String) -> Void,
        onRepair: @escaping () -> Void,
        onComplete: @escaping (String?) -> Void
    ) {
        self.exercise = exercise
        self.locked = locked
        self.onWrong = onWrong
        self.onRepair = onRepair
        self.onComplete = onComplete
        _meaningOrder = State(initialValue: exercise.pairs.map(\.id).shuffled())
    }

    private var boardHeight: CGFloat {
        ExerciseSurface.matchBoardHeight(pairCount: exercise.pairs.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ExerciseSurface.choiceGap) {
            matchColumnHeaders

            HStack(alignment: .top, spacing: ExerciseSurface.tileGridSpacing) {
                VStack(spacing: ExerciseSurface.tileGridSpacing) {
                    ForEach(exercise.pairs) { pair in
                        irishSlot(for: pair)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: boardHeight, alignment: .top)

                VStack(spacing: ExerciseSurface.tileGridSpacing) {
                    ForEach(meaningOrder, id: \.self) { pairID in
                        if let pair = exercise.pairs.first(where: { $0.id == pairID }) {
                            meaningSlot(for: pair)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: boardHeight, alignment: .top)
            }
            .frame(height: boardHeight, alignment: .top)
            .overlayPreferenceValue(MatchTileAnchorKey.self) { anchors in
                GeometryReader { geometry in
                    if let celebratingPairID,
                       let leftAnchor = anchors[MatchTileAnchorKey.id(pairID: celebratingPairID, irish: true)],
                       let rightAnchor = anchors[MatchTileAnchorKey.id(pairID: celebratingPairID, irish: false)] {
                        MatchPairThread(
                            from: CGPoint(x: geometry[leftAnchor].maxX, y: geometry[leftAnchor].midY),
                            to: CGPoint(x: geometry[rightAnchor].minX, y: geometry[rightAnchor].midY)
                        )
                    }
                }
                .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Slots stay on the board after a match so remaining tiles never grow.
    private func shouldShowTile(_ pair: CountyExercisePair) -> Bool {
        !matched.contains(pair.id) || celebratingPairID == pair.id
    }

    /// Fixed-height row anchor — content overlays the slot so flex layout
    /// cannot redistribute height when earlier pairs are matched.
    private func matchSlotContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Color.clear
            .frame(height: ExerciseSurface.matchSlotHeight)
            .overlay(alignment: .top) {
                content()
            }
            .frame(height: ExerciseSurface.matchSlotHeight, alignment: .top)
    }

    @ViewBuilder
    private func irishSlot(for pair: CountyExercisePair) -> some View {
        let visible = shouldShowTile(pair)
        matchSlotContainer {
            matchTile(
                pairID: pair.id,
                side: .irish,
                text: pair.left,
                selected: selectedLeft?.id == pair.id,
                missed: false,
                awaiting: false,
                celebrating: celebratingPairID == pair.id
            ) {
                pickWord(pair)
            }
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(visible)
            .accessibilityHidden(!visible)
            .accessibilityLabel(pair.left)
            .accessibilityValue(selectedLeft?.id == pair.id ? "selected" : "")
            .accessibilityAddTraits(selectedLeft?.id == pair.id ? .isSelected : [])
        }
        .animation(nil, value: matched)
    }

    @ViewBuilder
    private func meaningSlot(for pair: CountyExercisePair) -> some View {
        let visible = shouldShowTile(pair)
        let missed = missedRightID == pair.id
        matchSlotContainer {
            VStack(alignment: .leading, spacing: 6) {
                matchTile(
                    pairID: pair.id,
                    side: .english,
                    text: pair.right,
                    selected: false,
                    missed: missed,
                    awaiting: selectedLeft != nil && !missed && celebratingPairID == nil,
                    celebrating: celebratingPairID == pair.id
                ) {
                    pickMeaning(pair)
                }
                .opacity(visible ? 1 : 0)
                .allowsHitTesting(visible)
                .accessibilityHidden(!visible)
                .accessibilityLabel(pair.right)
                .accessibilityValue(missed ? "not a match" : "")
                .accessibilityHint(selectedLeft == nil ? "Choose an Irish word first." : "")

                Group {
                    if visible, missed, let selectedLeft {
                        Text(mismatchNote(attempted: pair, selected: selectedLeft))
                            .font(.subheadline)
                            .foregroundStyle(Theme.rust)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, ExerciseSurface.optionPadH)
                    } else {
                        Color.clear
                    }
                }
                .frame(height: ExerciseSurface.matchNoteBandHeight, alignment: .top)
            }
        }
        .animation(nil, value: matched)
    }

    private var matchColumnHeaders: some View {
        HStack(spacing: ExerciseSurface.tileGridSpacing) {
            Text("Irish")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Meaning")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Theme.inkFaint)
        .textCase(.uppercase)
        .kerning(0.5)
        .padding(.horizontal, ExerciseSurface.optionPadH)
        .accessibilityHidden(true)
    }

    private func pickWord(_ pair: CountyExercisePair) {
        guard celebratingPairID == nil else { return }
        Haptics.tap()
        if selectedLeft?.id == pair.id {
            selectedLeft = nil
        } else {
            selectedLeft = pair
            missedRightID = nil
            if speech.canSpeak(pair.left) { speech.speak(pair.left) }
        }
    }

    private func pickMeaning(_ pair: CountyExercisePair) {
        guard let leftSelection = selectedLeft, celebratingPairID == nil else { return }
        if leftSelection.id == pair.id {
            Haptics.chisel()
            // Clear the mismatch note on the repairing tap (D27 next-touch
            // repair) — do not wait for the celebration settle.
            missedRightID = nil
            celebratingPairID = pair.id
            onRepair()
            let settleDelay = reduceMotion ? 0 : 0.38
            DispatchQueue.main.asyncAfter(deadline: .now() + settleDelay) {
                matched.insert(pair.id)
                self.selectedLeft = nil
                celebratingPairID = nil
                if matched.count == exercise.pairs.count {
                    onComplete(exercise.feedback)
                }
            }
        } else {
            missedRightID = pair.id
            onWrong(mismatchNote(attempted: pair, selected: leftSelection))
        }
    }

    private func mismatchNote(attempted: CountyExercisePair, selected: CountyExercisePair) -> String {
        "Not a match."
    }

    private enum MatchTileSide {
        case irish
        case english
    }

    @ViewBuilder
    private func matchTile(
        pairID: String,
        side: MatchTileSide,
        text: String,
        selected: Bool,
        missed: Bool,
        awaiting: Bool,
        celebrating: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let isIrish = side == .irish
        Button(action: action) {
            Text(text)
                .font(isIrish ? .system(.title3, design: .serif, weight: selected || celebrating ? .semibold : .regular) : .title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(tileForeground(selected: selected, missed: missed, celebrating: celebrating))
                .padding(.horizontal, ExerciseSurface.optionPadH)
                .padding(.leading, isIrish ? 6 : 0)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: ExerciseSurface.matchTileMinHeight)
                .background(tileBackground(side: side, selected: selected, missed: missed, celebrating: celebrating))
                .clipShape(RoundedRectangle(cornerRadius: ExerciseSurface.tileRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: ExerciseSurface.tileRadius)
                        .stroke(
                            tileBorder(selected: selected, missed: missed, awaiting: awaiting, celebrating: celebrating),
                            lineWidth: borderWidth(selected: selected, missed: missed, awaiting: awaiting, celebrating: celebrating)
                        )
                }
                .overlay(alignment: .leading) {
                    if isIrish {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(grooveColor(selected: selected, celebrating: celebrating))
                            .frame(width: 3)
                            .padding(.vertical, 10)
                            .padding(.leading, 8)
                    }
                }
                .tactileLip(radius: ExerciseSurface.tileRadius, active: isIrish && !selected && !missed && !celebrating)
                .contentShape(RoundedRectangle(cornerRadius: ExerciseSurface.tileRadius))
        }
        .buttonStyle(CarvePress())
        .frame(maxWidth: .infinity)
        .frame(height: ExerciseSurface.matchTileMinHeight)
        .fixedSize(horizontal: false, vertical: true)
        .disabled(locked || (celebratingPairID != nil && celebratingPairID != pairID))
        .anchorPreference(
            key: MatchTileAnchorKey.self,
            value: .bounds,
            transform: { [MatchTileAnchorKey.id(pairID: pairID, irish: isIrish): $0] }
        )
    }

    private func tileForeground(selected: Bool, missed: Bool, celebrating: Bool) -> Color {
        if celebrating { return Theme.moss }
        if missed { return Theme.ink }
        if selected { return Theme.moss }
        return Theme.ink
    }

    private func tileBackground(side: MatchTileSide, selected: Bool, missed: Bool, celebrating: Bool) -> Color {
        if celebrating { return Theme.mossTintDeep }
        if missed { return Theme.rustTint }
        if selected { return Theme.mossTint }
        return side == .irish ? Theme.raised : Color.clear
    }

    private func grooveColor(selected: Bool, celebrating: Bool) -> Color {
        if celebrating { return Theme.moss }
        if selected { return Theme.moss.opacity(0.75) }
        return Theme.stone
    }

    private func tileBorder(selected: Bool, missed: Bool, awaiting: Bool, celebrating: Bool) -> Color {
        if celebrating { return Theme.moss }
        if missed { return Theme.rust }
        if selected { return Theme.moss }
        if awaiting { return Theme.inkSoft }
        return Theme.line
    }

    private func borderWidth(selected: Bool, missed: Bool, awaiting: Bool, celebrating: Bool) -> CGFloat {
        if celebrating || missed || selected { return ExerciseSurface.borderState }
        if awaiting { return ExerciseSurface.borderEmphasis }
        return ExerciseSurface.borderHairline
    }
}

private struct MatchTileAnchorKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]

    static func id(pairID: String, irish: Bool) -> String {
        "\(irish ? "L" : "R"):\(pairID)"
    }

    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

/// Moss thread snapped between a locked pair — the line between word and meaning.
private struct MatchPairThread: View {
    let from: CGPoint
    let to: CGPoint

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0

    var body: some View {
        MatchThreadCurve(from: from, to: to)
            .trim(from: 0, to: progress)
            .stroke(
                Theme.moss.opacity(0.55),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .onAppear {
                if reduceMotion {
                    progress = 1
                } else {
                    withAnimation(Motion.pop) { progress = 1 }
                }
            }
    }
}

private struct MatchThreadCurve: Shape {
    let from: CGPoint
    let to: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        let midX = (from.x + to.x) / 2
        path.addCurve(
            to: to,
            control1: CGPoint(x: midX, y: from.y),
            control2: CGPoint(x: midX, y: to.y)
        )
        return path
    }
}

private struct CountyTypingSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    /// The shell's recovery phase: the keyboard must yield so the restructured
    /// panel and the answer field share a coherent, fully reachable scroll
    /// composition (D3/D9). The next touch on the field restores the keyboard.
    var recoveryPresented: Bool = false
    /// The shell's incorrect verdict: the field wears rust, never moss, while
    /// a wrong answer stands uncorrected.
    var incorrectPresented: Bool = false
    let onCheck: (String) -> Void
    let onCheckReadyChange: (Bool, @escaping () -> Void) -> Void

    @State private var text = ""
    @FocusState private var focused: Bool

    init(
        exercise: CountyExercise,
        locked: Bool,
        recoveryPresented: Bool = false,
        incorrectPresented: Bool = false,
        onCheck: @escaping (String) -> Void,
        onCheckReadyChange: @escaping (Bool, @escaping () -> Void) -> Void
    ) {
        self.exercise = exercise
        self.locked = locked
        self.recoveryPresented = recoveryPresented
        self.incorrectPresented = incorrectPresented
        self.onCheck = onCheck
        self.onCheckReadyChange = onCheckReadyChange
    }

    /// Verdict-first field border: rust while an incorrect verdict stands,
    /// moss for completion or the live focus ring — never moss on a wrong
    /// answer.
    private var fieldBorder: Color {
        if incorrectPresented { return Theme.rust }
        if locked || focused { return Theme.moss }
        return .clear
    }

    private var fieldBorderWidth: CGFloat {
        incorrectPresented || locked || focused ? ExerciseSurface.borderState : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Type in Irish", text: $text, axis: .vertical)
                .font(.system(.title3, design: .serif))
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .focused($focused)
                .padding(16)
                .frame(minHeight: 80)
                .background(incorrectPresented ? Theme.rustTint : Theme.sunk)
                .clipShape(RoundedRectangle(cornerRadius: ExerciseSurface.trayRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: ExerciseSurface.trayRadius)
                        .stroke(fieldBorder, lineWidth: fieldBorderWidth)
                }
                .disabled(locked)
                .accessibilityLabel("Your Irish answer")
                .accessibilityIdentifier("irish-answer-field")
                .onChange(of: text) { _, _ in publishCheckState() }
            // One fada source at a time: the in-screen row stands in while the
            // keyboard is dismissed; once focused, the keyboard-accessory row
            // (with its Check affordance) takes over.
            if !focused {
                FadaKeyRow(text: $text, disabled: locked)
            }
        }
        .onAppear { publishCheckState() }
        .onChange(of: locked) { _, _ in publishCheckState() }
        // Entering recovery swaps and shortens the feedback panel; with the
        // keyboard still up, the first-responder field can be left outside the
        // keyboard-constrained viewport with an invalid accessibility frame,
        // unreachable to VoiceOver and scroll-to-visible. Resigning focus lets
        // the composition recompose; tapping the field re-raises the keyboard
        // for the in-place repair.
        .onChange(of: recoveryPresented) { _, presented in
            if presented { focused = false }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                ForEach(["á", "é", "í", "ó", "ú"], id: \.self) { fada in
                    Button(fada) {
                        Haptics.tap()
                        text.append(fada)
                    }
                    .tint(Theme.moss)
                    .disabled(locked)
                    .accessibilityLabel("Insert \(fada) from keyboard toolbar")
                }
                Button("Check") {
                    focused = false
                    onCheck(text)
                }
                .tint(Theme.moss)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || locked)
                .accessibilityLabel("Check answer from keyboard")
            }
        }
    }

    private func publishCheckState() {
        let ready = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !locked
        onCheckReadyChange(ready, {
            // Any explicit Check drops the keyboard so the verdict panel,
            // which sits directly under the field, is never covered by the
            // keyboard or left floating oddly above it.
            focused = false
            onCheck(text)
        })
    }
}

/// Speak stage: Irish hero, a single listen control, then the mic as the only
/// record entry point. Skip is a quiet opt-out; the bottom bar carries Continue.
private struct CountySpeakingSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onComplete: (String?) -> Void
    let onPrimaryChange: (_ title: String, _ isEnabled: Bool, _ action: (() -> Void)?) -> Void

    @StateObject private var recorder = EchoRecorder()
    @ObservedObject private var speech = SpeechService.shared
    @State private var hasPlayedModel = false

    private var forcedDenied: Bool {
        ProcessInfo.processInfo.arguments.contains("--microphone-denied")
    }

    private var micUnavailable: Bool { recorder.denied || forcedDenied }

    private var modelLine: String? { exercise.audioText ?? exercise.modelText }

    var body: some View {
        VStack(alignment: .leading, spacing: ExerciseSurface.zoneGap) {
            if let model = modelLine {
                VStack(spacing: 12) {
                    Text(model)
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 72, alignment: .center)
                        .accessibilityLabel("Line to say: \(model)")
                        .accessibilityAddTraits(.isHeader)

                    if speech.canSpeak(model) {
                        Button {
                            guard !locked else { return }
                            recorder.stopPlayback()
                            Haptics.tap()
                            speech.speak(model)
                            hasPlayedModel = true
                        } label: {
                            HStack(spacing: 8) {
                                AudioWaveMark(playing: speech.isSpeaking(model), compact: true)
                                Text(hasPlayedModel ? "Listen again" : "Listen")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(Theme.moss)
                            .frame(minHeight: 44)
                        }
                        .buttonStyle(.plain)
                        .disabled(locked)
                        .accessibilityLabel(hasPlayedModel ? "Listen again" : "Listen")
                    } else {
                        MissingAudioNotice()
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                MissingAudioNotice()
            }

            if micUnavailable {
                Label("Microphone access is off.", systemImage: "mic.slash")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityElement(children: .combine)
            } else {
                VStack(spacing: 12) {
                    recordTarget
                    recordingStatus
                    if !locked, recorder.state != .recording {
                        Button("Skip") { finish() }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.inkSoft)
                            .frame(minHeight: 44)
                            .accessibilityIdentifier("speaking-continue-without-recording")
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { publishPrimary() }
        .onChange(of: recorder.state) { _, _ in publishPrimary() }
        .onChange(of: recorder.denied) { _, _ in publishPrimary() }
        .onChange(of: locked) { _, _ in publishPrimary() }
        .onDisappear { recorder.discard() }
    }

    private var recordTarget: some View {
        Button {
            switch recorder.state {
            case .idle: startRecording()
            case .recording: stopRecording()
            case .recorded: break
            }
        } label: {
            Image(systemName: recorder.state == .recording ? "stop.fill" : "mic.fill")
                .font(.title)
                .foregroundStyle(recorder.state == .recording ? Theme.bg : Theme.moss)
                .frame(width: 96, height: 96)
                .background(recorder.state == .recording ? Theme.moss : Theme.sunk)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .tactileLip(radius: 28, active: recorder.state == .idle)
        }
        .buttonStyle(CarvePress())
        .disabled(locked || recorder.state == .recorded)
        .opacity(recorder.state == .recorded ? 0.55 : 1.0)
        .accessibilityLabel(recorder.state == .recording ? "Stop recording" : "Record")
    }

    @ViewBuilder
    private var recordingStatus: some View {
        switch recorder.state {
        case .idle:
            EmptyView()
        case .recording:
            Text("Recording…")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.rust)
                .frame(maxWidth: .infinity, alignment: .center)
        case .recorded:
            HStack(spacing: 8) {
                Button {
                    speech.stop()
                    recorder.playBack()
                } label: {
                    Label("Yours", systemImage: recorder.playing ? "waveform" : "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.moss)
                        .padding(.horizontal, 14)
                        .frame(minHeight: ExerciseSurface.slowCapsuleMinHeight)
                        .background(Theme.sunk)
                        .clipShape(Capsule())
                }
                .buttonStyle(CarvePress())
                .accessibilityLabel("Play your voice")

                Button {
                    recorder.toggle()
                } label: {
                    Text("Again")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.moss)
                        .padding(.horizontal, 14)
                        .frame(minHeight: ExerciseSurface.slowCapsuleMinHeight)
                        .background(Theme.sunk)
                        .clipShape(Capsule())
                }
                .buttonStyle(CarvePress())
                .accessibilityLabel("Record again")
            }
            .frame(maxWidth: .infinity)
            .disabled(locked)
        }
    }

    private func publishPrimary() {
        guard !locked else {
            onPrimaryChange("Continue", true, nil)
            return
        }
        if micUnavailable {
            onPrimaryChange("Continue", true, finish)
            return
        }
        switch recorder.state {
        case .idle:
            onPrimaryChange("Continue", false, nil)
        case .recording:
            onPrimaryChange("Stop", true, stopRecording)
        case .recorded:
            onPrimaryChange("Continue", true, finish)
        }
    }

    private func startRecording() {
        speech.stop()
        recorder.toggle()
    }

    private func stopRecording() {
        recorder.stop()
    }

    private func finish() {
        recorder.stopPlayback()
        onComplete(exercise.feedback)
    }
}

// MARK: - Internal exercise gallery

/// Manifest entry for the foundation-gate mechanics gallery. Deep-links into
/// the Clew Bay freeze fixture for operable C1/C3/C5 and failure inspection.
struct CountyGalleryManifestEntry: Identifiable, Equatable {
    enum Kind: String {
        case container
        case family
        case failure
    }

    let id: String
    let kind: Kind
    let title: String
    let detail: String
    /// Freeze page to open, when the entry is operable on the shared shell.
    let freezePageID: String?
}

enum CountyExerciseGalleryManifest {
    static let entries: [CountyGalleryManifestEntry] = [
        CountyGalleryManifestEntry(
            id: "c1",
            kind: .container,
            title: "C1 Conversation",
            detail: "Turn graph, misfit diagnostic, branch that changes a later partner line, exact-node resume.",
            freezePageID: "mayo.clew-bay.conversation-origin"
        ),
        CountyGalleryManifestEntry(
            id: "c3",
            kind: .container,
            title: "C3 Contextual review",
            detail: "Re-enters the earliest struggled target from its original sound or sentence.",
            freezePageID: "mayo.clew-bay.review-struggle"
        ),
        CountyGalleryManifestEntry(
            id: "c5",
            kind: .container,
            title: "C5 Completion",
            detail: "Capability summary and fixture collection handoff — no gold, no scheduler.",
            freezePageID: "mayo.clew-bay.completion"
        ),
        CountyGalleryManifestEntry(
            id: "f1",
            kind: .family,
            title: "Listen and choose",
            detail: "Cold open → wrong repair window → complete.",
            freezePageID: "mayo.clew-bay.listen-farraige"
        ),
        CountyGalleryManifestEntry(
            id: "f2",
            kind: .family,
            title: "Sentence construction",
            detail: "Tile build with Check / Continue primacy.",
            freezePageID: "mayo.clew-bay.build-origin"
        ),
        CountyGalleryManifestEntry(
            id: "f3",
            kind: .family,
            title: "Free typed production",
            detail: "Fada toolbar and in-place recovery.",
            freezePageID: "mayo.clew-bay.type-origin"
        ),
        CountyGalleryManifestEntry(
            id: "f5",
            kind: .family,
            title: "Matching",
            detail: "Thumb-native board; brief wrong-pair unlock.",
            freezePageID: "mayo.clew-bay.match-coast"
        ),
        CountyGalleryManifestEntry(
            id: "f6",
            kind: .family,
            title: "Read or listen and respond",
            detail: "Comprehension with listen-or-read route.",
            freezePageID: "mayo.clew-bay.comprehend-coast"
        ),
        CountyGalleryManifestEntry(
            id: "f7",
            kind: .family,
            title: "Record and compare",
            detail: "Record owns ink; quiet escape unless mic denied.",
            freezePageID: "mayo.clew-bay.speak-origin"
        ),
        CountyGalleryManifestEntry(
            id: "missing-audio",
            kind: .failure,
            title: "Missing audio",
            detail: "Authored fallback keeps the task completable without sound.",
            freezePageID: nil
        ),
        CountyGalleryManifestEntry(
            id: "mic-denied",
            kind: .failure,
            title: "Denied microphone",
            detail: "Listening remains available; progress is never trapped. Launch freeze with --microphone-denied.",
            freezePageID: "mayo.clew-bay.speak-origin"
        ),
        CountyGalleryManifestEntry(
            id: "long-copy",
            kind: .failure,
            title: "Long-copy accessibility",
            detail: "Diagnostic wrap must leave the response and primary action reachable at largest Dynamic Type.",
            freezePageID: nil
        ),
    ]
}

struct CountyExerciseGalleryView: View {
    let onOpenFreezePage: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                EditorialScreenHeader(
                    context: "Internal exercise gallery",
                    title: "Foundation gate matrix",
                    detail: "Operate C1, C3, and C5 on the shared shell, then walk families and failure states. Each operable row opens the Clew Bay freeze fixture at that page."
                )

                section(title: "Containers", entries: CountyExerciseGalleryManifest.entries.filter { $0.kind == .container })
                section(title: "Response families", entries: CountyExerciseGalleryManifest.entries.filter { $0.kind == .family })
                section(title: "Failure and edge states", entries: CountyExerciseGalleryManifest.entries.filter { $0.kind == .failure })

                MissingAudioNotice()
                    .accessibilityLabel("Missing audio failure state")

                Text("Long-copy and accessibility-size check: a diagnostic explanation can wrap across several lines without covering the response or pushing the only primary action beneath the home indicator.")
                    .font(.body)
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(4)
                    .padding(16)
                    .background(Theme.raised)
                    .clipShape(RoundedRectangle(cornerRadius: ExerciseSurface.tileRadius))
                    .accessibilityLabel("Long copy accessibility size state")
            }
            .padding(.horizontal, EditorialLayout.pageInset)
            .padding(.vertical, 24)
            .frame(maxWidth: EditorialLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Exercise gallery")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func section(title: String, entries: [CountyGalleryManifestEntry]) -> some View {
        EditorialSectionHeader(context: nil, title: title, detail: nil)
        VStack(alignment: .leading, spacing: 10) {
            ForEach(entries) { entry in
                if let pageID = entry.freezePageID {
                    Button {
                        onOpenFreezePage(pageID)
                    } label: {
                        entryRow(entry, actionable: true)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open \(entry.title)")
                } else {
                    entryRow(entry, actionable: false)
                }
            }
        }
    }

    private func entryRow(_ entry: CountyGalleryManifestEntry, actionable: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: actionable ? "play.circle" : "info.circle")
                .foregroundStyle(Theme.moss)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title).font(.headline).foregroundStyle(Theme.ink)
                Text(entry.detail).font(.body).foregroundStyle(Theme.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(Theme.raised)
        .clipShape(RoundedRectangle(cornerRadius: ExerciseSurface.tileRadius))
        .contentShape(Rectangle())
    }
}
