# Episode 4 text-input freeze — bug report and deep dive

*Opened 13 July 2026 · critical interaction defect in the Gráinne full-story prototype.*

## Summary

On Episode 4, beat 3 (`Ainm. Mise. Tar.`), focusing either identity field and typing
could leave the screen apparently frozen for 10–15 seconds. This is release-blocking:
the first learner-authored Irish line must feel immediate, and iOS text input is a
system interaction with a near-zero tolerance for app-induced latency.

## Reproduction

1. Launch the full Gráinne arc at story step 11.
2. Scroll until `Your name` is hittable.
3. Tap the field and type the first character.
4. Continue into `The place you are from`.

Observed in the reported build: the page was slow to become interactive; taps and
typing appeared to be ignored for roughly 10–15 seconds.

## Severity and impact

- **Severity:** Critical / release blocker.
- **Scope:** Episode 4 identity exercise; the underlying state-ownership pattern was
  also a risk for any text input embedded in a large story hierarchy.
- **User impact:** apparent app hang, lost trust, possible repeated taps or duplicate
  input, and abandonment at the most personally important language moment.
- **Accessibility impact:** magnified at large Dynamic Type because the invalidated
  hierarchy is taller and keyboard-driven scrolling/focus work is more complex.

## Root cause

The two `TextField` bindings were owned by `GrainneStoryView`, the root of the entire
18-beat story surface:

```swift
@State private var learnerNameDraft = ""
@State private var learnerPlaceDraft = ""
```

Every character therefore invalidated the root story view. SwiftUI had to reconsider
story chrome, the scroll hierarchy, transition identity, editorial copy, action
switching, bottom controls and the voyage-chart `Canvas`. The chart was also mounted
on every beat, adding work and state surface where it had no story value.

This is the wrong ownership boundary for high-frequency ephemeral input. A draft
character belongs to the field component. The durable atlas model needs the final,
trimmed identity only after the learner explicitly carries it.

The defect was not caused by audio playback or persistence on each character:

- the fields were bound to local root `@State`, not directly to `AtlasPrototypeModel`;
- `commitLearnerIdentity()` wrote to the atlas only on completion/backgrounding;
- no network request occurs in the exercise;
- speech uses bundled files.

Those facts narrow the primary mechanism to over-broad SwiftUI invalidation and the
focus/scroll/layout work it triggers. Disk image decoding is not on this particular
beat, although image loading elsewhere should still be cached separately.

## Fix

The field component now owns both drafts in local `@State`. Its completion closure
passes two trimmed values upward once:

```swift
@State private var name: String
@State private var place = ""
let onComplete: (String, String) -> Void
```

`GrainneStoryView` writes only the completed name to the atlas and marks the beat
complete. Keystrokes now invalidate the smallest relevant subtree instead of the
whole story screen.

The always-mounted voyage chart was removed at the same time. It now appears only on
four authored route turns: the closing beats of Episodes 1, 4, 5 and 6.

## Regression coverage

`KeyboardPerformanceUITests` contains a dedicated Episode 4 test which:

- launches directly at story step 11;
- makes the name field hittable and focuses it;
- requires the keyboard to appear within 1.25 seconds;
- types the first character and requires acceptance within 1.25 seconds;
- verifies the field value immediately.

`AtlasFlowUITests` retains the largest-accessibility-size identity flow to protect
focus transfer, field reachability and completion enablement.

Measured simulator results are recorded below after the local Xcode run:

| Build | Keyboard ready | First character | Result |
| --- | ---: | ---: | --- |
| Fixed build · iPhone 17 simulator · iOS 26.5 | 2.123 s | 0.339 s | Pass |

The keyboard number includes a cold simulator keyboard-service startup after the tap.
It is tracked with a 2.5-second ceiling. First-character acceptance is the direct
measure of app-side invalidation and is tracked with a 1.25-second ceiling. The fixed
build is roughly 30–45× faster than the reported 10–15 second apparent freeze on that
critical first input.

## Additional safeguards

- Keep draft typing state inside the smallest field/exercise view.
- Do not write `UserDefaults`, model progress, audio manifests or analytics on each
  keystroke.
- Do not attach `.animation` broadly to a view containing focused fields.
- Keep expensive `Canvas`, image decode and document parsing outside the input
  invalidation subtree.
- Add signposts around focus-to-keyboard and first-character latency before profiling
  future reports in Instruments.
- Run keyboard tests on a physical iPhone before release; simulator timings catch
  regressions but do not represent hardware keyboard services exactly.

## Status

Fixed and verified on an iPhone 17 simulator running iOS 26.5. The app compiled, the
dedicated timing test passed, and the largest-Dynamic-Type identity flow remains in
the UI regression suite. A physical-iPhone pass remains a release gate because
simulator keyboard-service startup is not hardware-equivalent.
