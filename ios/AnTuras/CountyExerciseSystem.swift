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
    /// or an explicit Check fails.
    let onStruggle: (() -> Void)?

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
        onComplete: @escaping () -> Void,
        onBarUpdate: @escaping (CountyExerciseBarState, (() -> Void)?) -> Void,
        struggledPageIDs: [String] = [],
        conversationState: CountyConversationState? = nil,
        onConversationState: ((CountyConversationState) -> Void)? = nil,
        collectionWords: [AtlasWord] = [],
        collectionHandoff: String = "",
        onCollect: (() -> Void)? = nil,
        onStruggle: (() -> Void)? = nil
    ) {
        self.page = page
        self.alreadyComplete = alreadyComplete
        self.onComplete = onComplete
        self.onBarUpdate = onBarUpdate
        self.struggledPageIDs = struggledPageIDs
        self.conversationState = conversationState
        self.onConversationState = onConversationState
        self.collectionWords = collectionWords
        self.collectionHandoff = collectionHandoff
        self.onCollect = onCollect
        self.onStruggle = onStruggle
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

    /// Memory events reach their current consumers: struggle feeds the run's
    /// ordered record (C3/D27). Success, hint and recovery are emitted
    /// exactly once by the engine; their persistence lands with the
    /// learner-memory handoff (rebuild plan step 11).
    private func apply(_ transition: CountyActivityTransition) {
        for event in transition.memoryEvents where event.kind == .struggle {
            onStruggle?()
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

            // Build / type: one soft English target under the imperative when
            // authored — replaces repeating it inside the prompt stack.
            if showsEnglishTarget, let translation = exercise.translation, !translation.isEmpty {
                Text(translation)
                    .font(.body)
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            responseSurface

            feedbackPanel
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
                optionFont: .system(.body, design: .serif)
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

    @ViewBuilder
    private var feedbackPanel: some View {
        switch presentationPhase {
        case .unanswered:
            EmptyView()
        case .hint:
            compactSupportLine(
                icon: "lightbulb",
                accessibilityPrefix: "Hint",
                text: panelMessage ?? exercise.hint,
                color: Theme.lichen
            )
        case .incorrect:
            VStack(alignment: .leading, spacing: 2) {
                compactSupportLine(
                    icon: "arrow.uturn.left",
                    accessibilityPrefix: "Not quite",
                    text: panelMessage ?? exercise.recovery,
                    color: Theme.rust
                )
                QuietHintButton(title: "Show a steadier step") {
                    withAnimation(feedbackAnimation) {
                        engine.beginRecovery()
                        panelMessage = exercise.recovery
                    }
                }
                .accessibilityIdentifier("exercise-recovery-button")
            }
        case .recovery:
            compactSupportLine(
                icon: "arrow.uturn.left.circle",
                accessibilityPrefix: "A steadier step",
                text: panelMessage ?? exercise.recovery,
                color: Theme.lichen
            )
        case .complete:
            // Concise verdict only — no titled card. Continue owns the next step.
            compactSupportLine(
                icon: "checkmark",
                accessibilityPrefix: "Complete",
                text: panelMessage ?? exercise.feedback,
                color: Theme.moss,
                lineLimit: 2
            )
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
                .frame(width: 20, height: 20)
                .padding(.top, 2)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(2)
                .lineLimit(lineLimit)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(accessibilityPrefix). \(text)")
        .accessibilityFocused($a11yFocus, equals: .feedback)
    }

    private func grade(_ option: CountyExerciseOption) {
        if option.isCorrect {
            formEngineResponse()
            apply(engine.check(outcome: .correct, diagnosticShown: false))
            markCorrect(option.rationale)
        } else {
            noteSelectionWrong("\(option.rationale) \(exercise.recovery)", escalates: true)
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
        let transition = withAnimation(feedbackAnimation) {
            formEngineResponse()
            let checked = engine.check(outcome: .incorrect, diagnosticShown: true, escalatesDiagnostic: true)
            panelMessage = message
            return checked
        }
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
                panelMessage = message
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
        let transition = withAnimation(feedbackAnimation) {
            formEngineResponse()
            let completed = engine.complete()
            panelMessage = message ?? exercise.feedback
            return completed
        }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let audioText = exercise.audioText, SpeechService.shared.canSpeak(audioText) {
                CountyAudioPromptControl(
                    text: audioText,
                    presentation: .listenObject(
                        hearLabel: "Hear the Irish",
                        replayLabel: "Replay the Irish"
                    ),
                    disabled: locked
                )
            } else if exercise.audioText != nil {
                MissingAudioNotice()
            }

            CountyChoiceSurface(
                exercise: exercise,
                locked: locked,
                onPick: onPick,
                optionFont: .system(.body, design: .serif)
            )
        }
    }
}

/// Shared listen object: playing / played / idle, replay, and optional Slow.
/// Moss ghost chrome only — never steals the ink primary (D2).
private struct CountyAudioPromptControl: View {
    enum Presentation {
        /// Waveform board without revealing the Irish (recognition tasks).
        case listenObject(hearLabel: String, replayLabel: String)
        /// Visible Irish target with Play as a secondary control (speak).
        case spokenTarget
        /// Compact model control above a builder bank.
        case modelControl(playLabel: String, replayLabel: String)
    }

    let text: String
    let presentation: Presentation
    var includeSlow: Bool = true
    var disabled: Bool = false
    var onWillPlay: (() -> Void)? = nil
    var onPlayed: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var speech = SpeechService.shared
    @State private var hasPlayed = false

    private static let slowRate: Float = 0.7

    private var isPlaying: Bool { speech.isSpeaking(text) }

    private var primaryLabel: String {
        switch presentation {
        case .listenObject(let hear, let replay):
            return hasPlayed ? replay : hear
        case .spokenTarget:
            return hasPlayed ? "Replay the model" : "Play the model"
        case .modelControl(let play, let replay):
            return hasPlayed ? replay : play
        }
    }

    var body: some View {
        switch presentation {
        case .listenObject:
            listenBoard
        case .spokenTarget:
            spokenTargetBoard
        case .modelControl:
            modelRow
        }
    }

    private var listenBoard: some View {
        HStack(alignment: .center, spacing: 10) {
            Button {
                play(rate: 1)
            } label: {
                HStack(alignment: .center, spacing: 14) {
                    AudioWaveMark(playing: isPlaying)
                        .frame(width: 36, height: 28)
                    Text(primaryLabel)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                .background(Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isPlaying ? Theme.moss : Theme.line, lineWidth: isPlaying ? 2 : 1)
                }
            }
            .buttonStyle(CarvePress())
            .disabled(disabled)
            .accessibilityLabel(primaryLabel)
            .accessibilityValue(isPlaying ? "playing" : (hasPlayed ? "played" : "ready"))
            .opacity(disabled ? 0.55 : 1)

            if includeSlow {
                Button {
                    play(rate: Self.slowRate)
                } label: {
                    Text("SLOW")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.moss)
                        .frame(minWidth: 52, minHeight: 72)
                        .background(Theme.raised)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.line, lineWidth: 1)
                        }
                }
                .buttonStyle(CarvePress())
                .disabled(disabled)
                .accessibilityLabel("Play slowly")
                .accessibilityHint("Plays the same recording at a slower rate")
            }
        }
    }

    private var spokenTargetBoard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(text)
                .font(.system(.title, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.line, lineWidth: 1)
                }
                .accessibilityLabel("Model line: \(text)")

            HStack(spacing: 10) {
                Button {
                    play(rate: 1)
                } label: {
                    Label(primaryLabel, systemImage: isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
                .tint(Theme.moss)
                .disabled(disabled)
                .accessibilityLabel(primaryLabel)
                .accessibilityValue(isPlaying ? "playing" : (hasPlayed ? "played" : "ready"))

                if includeSlow {
                    Button("SLOW") { play(rate: Self.slowRate) }
                        .font(.caption.weight(.bold))
                        .buttonStyle(.bordered)
                        .tint(Theme.moss)
                        .frame(minHeight: 48)
                        .disabled(disabled)
                        .accessibilityLabel("Play the model slowly")
                }
            }
        }
    }

    private var modelRow: some View {
        HStack(alignment: .center, spacing: 10) {
            Button {
                play(rate: 1)
            } label: {
                HStack(spacing: 12) {
                    AudioWaveMark(playing: isPlaying)
                    Text(primaryLabel)
                        .font(.headline)
                    Spacer(minLength: 8)
                }
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .background(Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isPlaying ? Theme.moss : Theme.line, lineWidth: isPlaying ? 2 : 1)
                }
            }
            .buttonStyle(CarvePress())
            .disabled(disabled)
            .accessibilityLabel(primaryLabel)
            .accessibilityValue(isPlaying ? "playing" : (hasPlayed ? "played" : "ready"))

            if includeSlow {
                Button {
                    play(rate: Self.slowRate)
                } label: {
                    Text("SLOW")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.moss)
                        .frame(minWidth: 52, minHeight: 56)
                        .background(Theme.raised)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Theme.line, lineWidth: 1)
                        }
                }
                .buttonStyle(CarvePress())
                .disabled(disabled)
                .accessibilityLabel("Play slowly")
            }
        }
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
private struct AudioWaveMark: View {
    let playing: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let heights: [CGFloat] = [11, 18, 13, 22, 15]

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: reduceMotion || !playing ? 60 : 0.12,
                paused: reduceMotion || !playing
            )
        ) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<heights.count, id: \.self) { index in
                    let pulse = playing && !reduceMotion
                        ? (0.55 + 0.45 * abs(sin(t * 4.2 + Double(index))))
                        : 1
                    Capsule()
                        .fill(Theme.moss.opacity(playing ? 0.95 : 0.38))
                        .frame(width: 4, height: heights[index] * pulse)
                }
            }
            .frame(width: 32, height: 24)
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
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
    }
}

private struct CountyChoiceSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onPick: (CountyExerciseOption) -> Void
    var optionFont: Font = .body

    @State private var wrongOptionIDs: Set<String> = []
    @State private var chosenCorrectID: String?

    var body: some View {
        VStack(spacing: 12) {
            if let template = exercise.sentenceTemplate {
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
    }

    @ViewBuilder
    private func choiceRow(_ option: CountyExerciseOption) -> some View {
        let isWrong = wrongOptionIDs.contains(option.id)
        let isCorrect = chosenCorrectID == option.id
        let settledAway = chosenCorrectID != nil && !isCorrect && !isWrong
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
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(leadingMark(for: option))
                        .frame(width: 4, height: 22)
                        .opacity(isCorrect || isWrong ? 1 : 0)
                        .accessibilityHidden(true)
                    Text(option.text)
                        .font(optionFont)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
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
                    }
                }
                .foregroundStyle(Theme.ink)
                .padding(.vertical, 16)
                .padding(.horizontal, 15)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .background(rowBackground(for: option))
                .clipShape(RoundedRectangle(cornerRadius: isCorrect ? 14 : 10))
                .overlay {
                    RoundedRectangle(cornerRadius: isCorrect ? 14 : 10)
                        .stroke(rowBorder(for: option), lineWidth: rowBorderWidth(for: option))
                }
            }
            .buttonStyle(CarvePress())
            .disabled(locked)
            .opacity(settledAway ? 0.42 : 1)
            .accessibilityLabel(option.text)
            .accessibilityValue(isWrong ? "Not correct" : (isCorrect ? "Correct" : ""))
            .accessibilityAddTraits(choiceTraits(for: option))

            if isWrong {
                Text(option.rationale)
                    .font(.subheadline)
                    .foregroundStyle(Theme.rust)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 15)
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
        if chosenCorrectID == option.id { return Theme.mossTint }
        if wrongOptionIDs.contains(option.id) { return Theme.rustTint }
        return Theme.raised
    }

    private func rowBorder(for option: CountyExerciseOption) -> Color {
        if chosenCorrectID == option.id { return Theme.moss }
        if wrongOptionIDs.contains(option.id) { return Theme.rust }
        return Theme.line
    }

    private func rowBorderWidth(for option: CountyExerciseOption) -> CGFloat {
        if chosenCorrectID == option.id { return 2.5 }
        if wrongOptionIDs.contains(option.id) { return 2 }
        return 1
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
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text("Your reply")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSoft)

            CountyChoiceSurface(
                exercise: exercise,
                locked: locked,
                onPick: onPick,
                optionFont: .system(.body, design: .serif)
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
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.line, lineWidth: 1)
        }
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
        .padding(.horizontal, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.mossTint)
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
                            .font(.system(.body, design: .serif, weight: .semibold))
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
                .padding(.vertical, 13)
                .padding(.horizontal, 15)
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .background(misfit ? Theme.rustTint : Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(misfit ? Theme.rust : Theme.line, lineWidth: misfit ? 2 : 1)
                }
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
                    .padding(.horizontal, 15)
            }
        }
    }
}

/// F6 read or listen and respond: the reading sits in a sunk card with the
/// Irish line in the story serif; when a listen variant is authored, replay is
/// always available and the visible text and meaning route remain on screen —
/// missing audio never traps the answer.
private struct CountyReadRespondSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onPick: (CountyExerciseOption) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let audioText = exercise.audioText {
                if SpeechService.shared.canSpeak(audioText) {
                    CountyAudioPromptControl(
                        text: audioText,
                        presentation: .listenObject(
                            hearLabel: "Hear the line",
                            replayLabel: "Replay the line"
                        ),
                        disabled: locked
                    )
                } else {
                    MissingAudioNotice()
                }
            }

            if let note = exercise.modelText, !note.isEmpty {
                Text(note)
                    .font(.body)
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                    .background(Theme.sunk)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            CountyChoiceSurface(
                exercise: exercise,
                locked: locked,
                onPick: onPick,
                optionFont: .body
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
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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
                .clipShape(RoundedRectangle(cornerRadius: 10))
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
    let onPick: (CountyExerciseOption) -> Void
    let onCheck: (String) -> Void
    let onCheckReadyChange: (Bool, @escaping () -> Void) -> Void

    @ObservedObject private var speech = SpeechService.shared
    @State private var heard = false

    private var embedded: CountyExercise { candidate.exercise }
    private var originalLine: String { embedded.modelText ?? embedded.answer }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(struggled
                     ? "\(candidate.label) slipped — meet it again from the original sound."
                     : "Nothing slipped. One quiet return keeps \(candidate.label) warm.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(originalLine)
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    if let audioText = embedded.audioText, speech.canSpeak(audioText) {
                        Button {
                            Haptics.tap()
                            speech.speak(audioText)
                            heard = true
                        } label: {
                            Label(heard ? "Replay" : "Hear", systemImage: speech.isSpeaking(audioText) ? "speaker.wave.2.fill" : "speaker.wave.2")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.moss)
                                .frame(minHeight: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Hear the original sound: \(audioText)")
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.raised)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.line, lineWidth: 1)
            }

            switch embedded.family {
            case .freeTyping:
                CountyTypingSurface(
                    exercise: embedded,
                    locked: locked,
                    recoveryPresented: recoveryPresented,
                    onCheck: onCheck,
                    onCheckReadyChange: onCheckReadyChange
                )
            case .listenChoose:
                CountyListenChoiceSurface(
                    exercise: embedded,
                    locked: locked,
                    onPick: onPick
                )
            default:
                CountyChoiceSurface(
                    exercise: embedded,
                    locked: locked,
                    onPick: onPick,
                    optionFont: .system(.body, design: .serif)
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
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if let question = discoveryQuestion {
                Text(question)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            CountyChoiceSurface(exercise: exercise, locked: locked, onPick: onPick, optionFont: .body)
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
/// remaining tiles never slide under the learner's thumb (or under a resolved
/// accessibility frame mid-animation). Tiles return to their own slot when
/// removed from the answer.
private struct CountyBuilderSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let startsWithAudio: Bool
    let onCheck: (String) -> Void
    let onCheckReadyChange: (Bool, @escaping () -> Void) -> Void

    @ObservedObject private var speech = SpeechService.shared
    @State private var placed: Set<Int> = []
    @State private var chosen: [Int] = []
    @State private var heard = false

    private var tokenFont: Font {
        exercise.operatesOnSentence ? .system(.body, design: .serif) : .body
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if startsWithAudio, let audioText = exercise.audioText {
                if speech.canSpeak(audioText) {
                    CountyAudioPromptControl(
                        text: audioText,
                        presentation: .modelControl(
                            playLabel: "Play the model",
                            replayLabel: "Replay the model"
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

            FlowLayout(spacing: 10) {
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
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .padding(12)
            .background(Theme.sunk)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.line, lineWidth: 1)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Your answer: \(chosen.map { exercise.tokens[$0] }.joined(separator: " "))")

            FlowLayout(spacing: 10) {
                ForEach(Array(exercise.tokens.enumerated()), id: \.offset) { slot, token in
                    if placed.contains(slot) {
                        Text(token)
                            .font(tokenFont)
                            .opacity(0)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 50)
                            .background(Theme.sunk)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .accessibilityHidden(true)
                    } else {
                        tile(token, inAnswer: false) {
                            placed.insert(slot)
                            chosen.append(slot)
                            publishCheckState()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        }
        .onAppear { publishCheckState() }
        .onChange(of: locked) { _, _ in publishCheckState() }
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
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14)
                .frame(minHeight: 50)
                .background(Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: inAnswer ? 10 : 8))
                .overlay {
                    RoundedRectangle(cornerRadius: inAnswer ? 10 : 8)
                        .stroke(inAnswer ? Theme.moss : Theme.line, lineWidth: inAnswer ? 2 : 1)
                }
        }
        .buttonStyle(CarvePress())
        .disabled(locked)
    }
}

/// Thumb-native matching: Irish word chips sit in one compact row pair above
/// full-width meaning rows that stay in reach of the bottom bar. A wrong pair
/// never locks the board or escalates to mastery chrome — the attempted meaning
/// keeps a plain-language note until the next tap repairs it.
private struct CountyMatchingSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onWrong: (String) -> Void
    let onRepair: () -> Void
    let onComplete: (String?) -> Void

    @ObservedObject private var speech = SpeechService.shared
    @State private var selectedLeft: CountyExercisePair?
    @State private var matched: Set<String> = []
    @State private var missedRightID: String?

    private var wordColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 9), GridItem(.flexible(), spacing: 9)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(columns: wordColumns, spacing: 10) {
                ForEach(exercise.pairs) { pair in
                    wordChip(pair)
                }
            }

            VStack(spacing: 10) {
                ForEach(Array(exercise.pairs.reversed())) { pair in
                    meaningRow(pair)
                }
            }
        }
    }

    private func pickWord(_ pair: CountyExercisePair) {
        Haptics.tap()
        selectedLeft = pair
        missedRightID = nil
        if speech.canSpeak(pair.left) { speech.speak(pair.left) }
    }

    private func pickMeaning(_ pair: CountyExercisePair) {
        guard let selectedLeft else { return }
        if selectedLeft.id == pair.id {
            Haptics.tap()
            matched.insert(pair.id)
            self.selectedLeft = nil
            missedRightID = nil
            onRepair()
            if matched.count == exercise.pairs.count {
                onComplete(exercise.feedback)
            }
        } else {
            missedRightID = pair.id
            onWrong(mismatchNote(attempted: pair, selected: selectedLeft))
        }
    }

    private func mismatchNote(attempted: CountyExercisePair, selected: CountyExercisePair) -> String {
        "\u{201C}\(attempted.right)\u{201D} does not belong with \u{201C}\(selected.left)\u{201D}. Choose another meaning."
    }

    private func wordChip(_ pair: CountyExercisePair) -> some View {
        let complete = matched.contains(pair.id)
        let selected = selectedLeft?.id == pair.id
        return Button {
            pickWord(pair)
        } label: {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(selected ? Theme.moss : Color.clear)
                    .frame(width: 4, height: 20)
                    .accessibilityHidden(true)
                Text(pair.left)
                    .font(.system(.body, design: .serif, weight: selected ? .semibold : .regular))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                if complete {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.moss)
                        .accessibilityHidden(true)
                } else if selected {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(Theme.moss)
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(selected ? Theme.mossTint : Theme.raised)
            .clipShape(RoundedRectangle(cornerRadius: selected ? 12 : 10))
            .overlay {
                RoundedRectangle(cornerRadius: selected ? 12 : 10)
                    .stroke(
                        selected ? Theme.moss : Theme.line,
                        lineWidth: selected ? 2.5 : 1
                    )
            }
        }
        .buttonStyle(CarvePress())
        .disabled(locked || complete)
        .opacity(complete ? 0.4 : 1)
        .accessibilityLabel(pair.left)
        .accessibilityValue(complete ? "matched" : (selected ? "selected" : ""))
        .accessibilityAddTraits(selected || complete ? .isSelected : [])
    }

    private func meaningRow(_ pair: CountyExercisePair) -> some View {
        let complete = matched.contains(pair.id)
        let missed = missedRightID == pair.id
        let awaitingPair = selectedLeft != nil && !complete && !missed
        return VStack(alignment: .leading, spacing: 6) {
            Button {
                pickMeaning(pair)
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(missed ? Theme.rust : (complete ? Theme.moss : Color.clear))
                        .frame(width: 4, height: 22)
                        .opacity(missed || complete ? 1 : 0)
                        .accessibilityHidden(true)
                    if complete {
                        Text(pair.left)
                            .font(.system(.body, design: .serif, weight: .semibold))
                            .fixedSize(horizontal: false, vertical: true)
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .accessibilityHidden(true)
                    }
                    Text(pair.right)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                }
                .foregroundStyle(Theme.ink)
                .padding(.vertical, 16)
                .padding(.horizontal, 15)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .background(missed ? Theme.rustTint : (complete ? Theme.mossTint : Theme.raised))
                .clipShape(RoundedRectangle(cornerRadius: complete || missed ? 12 : 10))
                .overlay {
                    RoundedRectangle(cornerRadius: complete || missed ? 12 : 10)
                        .stroke(
                            missed ? Theme.rust : (complete ? Theme.moss : (awaitingPair ? Theme.inkSoft : Theme.line)),
                            lineWidth: missed || complete ? 2.5 : (awaitingPair ? 1.5 : 1)
                        )
                }
            }
            .buttonStyle(CarvePress())
            .disabled(locked || complete)
            .opacity(complete ? 0.4 : 1)
            .accessibilityLabel(pair.right)
            .accessibilityValue(complete ? "matched with \(pair.left)" : (missed ? "not a match" : ""))
            .accessibilityHint(selectedLeft == nil && !complete ? "Choose an Irish word first." : "")
            .accessibilityAddTraits(complete ? .isSelected : [])

            if missed, let selectedLeft {
                Text(mismatchNote(attempted: pair, selected: selectedLeft))
                    .font(.subheadline)
                    .foregroundStyle(Theme.rust)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 15)
            }
        }
    }
}

private struct CountyTypingSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    /// The shell's recovery phase: the keyboard must yield so the restructured
    /// panel and the answer field share a coherent, fully reachable scroll
    /// composition (D3/D9). The next touch on the field restores the keyboard.
    var recoveryPresented: Bool = false
    let onCheck: (String) -> Void
    let onCheckReadyChange: (Bool, @escaping () -> Void) -> Void

    @State private var text = ""
    @FocusState private var focused: Bool

    init(
        exercise: CountyExercise,
        locked: Bool,
        recoveryPresented: Bool = false,
        onCheck: @escaping (String) -> Void,
        onCheckReadyChange: @escaping (Bool, @escaping () -> Void) -> Void
    ) {
        self.exercise = exercise
        self.locked = locked
        self.recoveryPresented = recoveryPresented
        self.onCheck = onCheck
        self.onCheckReadyChange = onCheckReadyChange
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
                .background(Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focused ? Theme.moss : Theme.line, lineWidth: focused ? 2 : 1)
                }
                .disabled(locked)
                .accessibilityLabel("Your Irish answer")
                .accessibilityIdentifier("irish-answer-field")
                .onChange(of: text) { _, _ in publishCheckState() }
            FadaKeyRow(text: $text, disabled: locked)
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
                    .disabled(locked)
                    .accessibilityLabel("Insert \(fada) from keyboard toolbar")
                }
                Button("Check") {
                    focused = false
                    onCheck(text)
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || locked)
                .accessibilityLabel("Check answer from keyboard")
            }
        }
    }

    private func publishCheckState() {
        let ready = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !locked
        onCheckReadyChange(ready, { onCheck(text) })
    }
}

/// Record and compare keeps one ink primary per state, owned by the shared
/// bottom slot: Record (or Stop) until a recording exists, then "I compared
/// both" once playback has happened. Play model, Play back and Record again
/// stay moss ghosts; the no-recording escape is a quiet text button unless the
/// microphone is unavailable, where it becomes the primary.
private struct CountySpeakingSurface: View {
    let exercise: CountyExercise
    let locked: Bool
    let onComplete: (String?) -> Void
    let onPrimaryChange: (_ title: String, _ isEnabled: Bool, _ action: (() -> Void)?) -> Void

    @StateObject private var recorder = EchoRecorder()
    @ObservedObject private var speech = SpeechService.shared
    @State private var compared = false

    private var forcedDenied: Bool {
        ProcessInfo.processInfo.arguments.contains("--microphone-denied")
    }

    private var micUnavailable: Bool { recorder.denied || forcedDenied }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let model = exercise.audioText, speech.canSpeak(model) {
                CountyAudioPromptControl(
                    text: model,
                    presentation: .spokenTarget,
                    disabled: locked,
                    onWillPlay: {
                        recorder.stopPlayback()
                    }
                )
            } else {
                MissingAudioNotice()
            }

            if micUnavailable {
                Label("Microphone access is off. You can keep listening and continue without recording.", systemImage: "mic.slash")
                    .font(.body)
                    .foregroundStyle(Theme.inkSoft)
                    .padding(16)
                    .background(Theme.sunk)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .accessibilityElement(children: .combine)
            } else {
                recordingStatus
            }

            if compared, !locked {
                Text("No pronunciation score — compare by ear.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
            }

            if !micUnavailable, !locked, recorder.state != .recording {
                QuietHintButton(title: "Continue without recording") { finish() }
                    .accessibilityIdentifier("speaking-continue-without-recording")
            }
        }
        .onAppear { publishPrimary() }
        .onChange(of: recorder.state) { _, _ in publishPrimary() }
        .onChange(of: recorder.denied) { _, _ in publishPrimary() }
        .onChange(of: compared) { _, _ in publishPrimary() }
        .onChange(of: locked) { _, _ in publishPrimary() }
        .onDisappear { recorder.discard() }
    }

    @ViewBuilder
    private var recordingStatus: some View {
        switch recorder.state {
        case .idle:
            EmptyView()
        case .recording:
            Label("Recording — stop when you have said the line.", systemImage: "record.circle")
                .font(.body)
                .foregroundStyle(Theme.rust)
                .accessibilityElement(children: .combine)
        case .recorded:
            HStack(spacing: 10) {
                Button {
                    speech.stop()
                    recorder.playBack()
                    compared = true
                } label: {
                    Label("Play your voice", systemImage: recorder.playing ? "waveform" : "play.fill")
                        .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)
                Button("Record again") {
                    compared = false
                    recorder.toggle()
                }
                .buttonStyle(.bordered)
                .frame(minHeight: 44)
            }
            .tint(Theme.moss)
            .disabled(locked)
        }
    }

    private func publishPrimary() {
        guard !locked else {
            onPrimaryChange("Continue", true, nil)
            return
        }
        if micUnavailable {
            onPrimaryChange("Continue without recording", true, finish)
            return
        }
        switch recorder.state {
        case .idle:
            onPrimaryChange("Record your voice", true, startRecording)
        case .recording:
            onPrimaryChange("Stop recording", true, stopRecording)
        case .recorded:
            onPrimaryChange("I compared both", compared, compared ? finish : nil)
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

struct CountyExerciseGalleryView: View {
    private let states: [(CountyExercisePhase, String, String)] = [
        (.unanswered, "Unanswered", "One clear task and a visible response area."),
        (.incorrect, "Not quite", "Diagnostic feedback names the mismatch while the response stays editable."),
        (.hint, "Hint", "A hint supports another attempt without revealing a score."),
        (.complete, "Complete", "Completion is quiet and does not add points or celebration."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                EditorialScreenHeader(
                    context: "Internal exercise gallery",
                    title: "One feedback model across the activity layers",
                    detail: "Use this screen to inspect copy length, state language, missing resources and accessibility recomposition."
                )

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(CountyExerciseFamily.allCases, id: \.self) { family in
                        Label(family.title, systemImage: "circle")
                            .font(.body)
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                }

                EditorialSectionHeader(context: nil, title: "Feedback states", detail: nil)
                ForEach(states, id: \.0) { state in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: state.0 == .incorrect ? "arrow.uturn.left" : "checkmark.circle")
                            .foregroundStyle(state.0 == .incorrect ? Theme.rust : Theme.moss)
                            .frame(width: 28, height: 28)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(state.1).font(.headline)
                            Text(state.2).font(.body).foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .padding(16)
                    .background(Theme.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                EditorialSectionHeader(context: nil, title: "Failure and edge states", detail: nil)
                MissingAudioNotice()
                Label("Denied microphone: listening remains available and progress is never trapped.", systemImage: "mic.slash")
                    .font(.body)
                    .foregroundStyle(Theme.inkSoft)
                    .padding(16)
                    .background(Theme.sunk)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text("Long-copy and accessibility-size check: a diagnostic explanation can wrap across several lines without covering the response or pushing the only primary action beneath the home indicator.")
                    .font(.body)
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(4)
                    .padding(16)
                    .background(Theme.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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
}
