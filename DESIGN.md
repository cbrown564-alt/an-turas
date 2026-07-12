---
name: An Turas
description: A living historical atlas for learning Irish through the real stories of Ireland.
colors:
  limestone: "#ECEDE7"
  limestone-raised: "#F7F7F2"
  limestone-sunk: "#E2E4DB"
  shore-night: "#131714"
  shore-raised: "#1C211C"
  shore-sunk: "#0E120F"
  ink: "#23281F"
  ink-dark-mode: "#D9DCD1"
  ink-soft: "#5A6153"
  ink-soft-dark-mode: "#9AA294"
  ink-faint: "#8B917F"
  boundary: "#CBCEC1"
  stone: "#AEB4A6"
  moss: "#4C6647"
  moss-dark-mode: "#95B28B"
  lichen: "#8F7414"
  rust: "#A34D3B"
  atlas-green: "#16803A"
  atlas-gold: "#B8860B"
  atlas-white: "#FFFDF6"
typography:
  display:
    fontFamily: "New York, Georgia, serif"
    fontSize: "34pt"
    fontWeight: 600
    lineHeight: 1.12
    letterSpacing: "normal"
  headline:
    fontFamily: "New York, Georgia, serif"
    fontSize: "26pt"
    fontWeight: 600
    lineHeight: 1.18
    letterSpacing: "normal"
  title:
    fontFamily: "New York, Georgia, serif"
    fontSize: "20pt"
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "normal"
  body:
    fontFamily: "SF Pro, -apple-system, sans-serif"
    fontSize: "17pt"
    fontWeight: 400
    lineHeight: 1.35
    letterSpacing: "normal"
  label:
    fontFamily: "SF Pro, -apple-system, sans-serif"
    fontSize: "12pt"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "1.6pt"
rounded:
  control: "4pt"
  compact: "7pt"
  container: "10pt"
  sheet: "20pt"
spacing:
  xxs: "4pt"
  xs: "8pt"
  sm: "12pt"
  md: "16pt"
  lg: "22pt"
  xl: "28pt"
  xxl: "48pt"
components:
  button-primary:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.limestone}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    padding: "13pt 22pt"
    height: "44pt"
  evidence-container:
    backgroundColor: "{colors.limestone-raised}"
    textColor: "{colors.ink}"
    rounded: "{rounded.container}"
    padding: "16pt"
  selected-chip:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.limestone}"
    typography: "{typography.label}"
    rounded: "{rounded.compact}"
    padding: "9pt 13pt"
---

# Design System: An Turas

## Overview

**Creative North Star: “The Living Field Journal”**

An Turas should feel like opening a field journal beside an artifact: intimate, tactile, and precise, with the whole island just beyond the page. “Limestone day” and “night on the shore” provide quiet, mineral surfaces; moss, lichen, rust, and the atlas flag colors act as evidence marks rather than decoration. Storytelling can be cinematic, but the controls remain unmistakably native iOS.

The interface alternates registers—map, person, place, evidence, source, language, practice, and collection—so depth comes from changing the learner's mode of attention rather than adding card stacks or exposition. Calm negative space and a narrow reading measure let words and objects carry the screen. Dark Mode is a true shore-at-night counterpart, never a neon reskin.

This system rejects generic language-app gamification, “plastic shamrock” Irishness, solemn digital-museum distance, fictional-history role-play, and interface novelty that breaks trusted iOS behavior.

**Key Characteristics:**

- Mineral, adaptive surfaces with high-contrast botanical accents.
- Serif-led editorial moments inside a system-native interaction shell.
- Evidence, uncertainty, and provenance made visible without production jargon.
- Tactile feedback that is brief, physical, and optional under Reduce Motion.
- Spacious reading views balanced by compact atlas and practice controls.

## Colors

The palette is drawn from limestone, vegetation, oxidized metal, and the shoreline at night; it is restrained everywhere except where atlas progress must read instantly.

### Primary

- **Moss:** The principal interactive tint for links, pronunciation, current language focus, selected evidence, and positive learning state. Its rarity makes it meaningful.
- **Limestone / Shore Night:** The adaptive canvas. Use limestone in light appearance and the deep green-black shore surface in dark appearance.

### Secondary

- **Lichen:** Marks language lenses, archival notes, and moments that need an ochre distinction without implying completion.
- **Rust:** Reserved for correction, friction, destructive actions, or historically material emphasis. It is not a general decorative accent.

### Tertiary

- **Atlas Green, Atlas Gold, and Atlas White:** A deliberately higher-contrast progress vocabulary: green is the county in play, gold is a story carried, and white is waiting. Always pair these colors with shape, label, or state text.

### Neutral

- **Ink:** Primary text and the filled primary-action surface.
- **Ink Soft:** Supporting prose and explanatory labels that must remain comfortably readable.
- **Ink Faint:** Metadata only; never use it for essential instructions or long body copy.
- **Raised, Sunk, Boundary, and Stone:** Establish surface hierarchy, separators, disabled state, and cartographic structure without relying on shadows.

### Named Rules

**The Evidence-Mark Rule.** Evidence state is a quiet, inspectable primitive—not a badge system. In the main reading flow, place one small, familiar SF Symbol beside a material claim; give it a 44 pt hit target, a complete accessibility label, and a tap path to the claim's status, sources, competing readings, and review history. Do not print “recorded,” “supported interpretation,” or similar taxonomy repeatedly beside ordinary prose. Persistent text labels are reserved for disputed, traditional, reconstructed, unknown, or otherwise consequential boundaries. Accent color may reinforce the mark but never carries its meaning alone.

**Evidence-mark symbols (provisional; lock after usability and expert review):** `doc.text` for a recorded source, `info.circle` for an interpretation, `questionmark.circle` for a possibility or unknown, `quote.bubble` for tradition, and `arrow.triangle.branch` for competing or disputed readings. These are implementation candidates, not yet immutable brand assets; test recognition, VoiceOver language, and cross-cultural meaning before freezing them.

**The Flag-without-a-Flag Rule.** Atlas green, gold, and white communicate progress, not nationalism; never spread the trio across unrelated controls or ornamental backgrounds.

**The Adaptive Pair Rule.** Every custom color must ship as a tested light/dark pair and remain distinguishable with Increased Contrast and without color alone.

## Typography

**Display Font:** New York through SwiftUI's system serif design, with Georgia as documentation fallback  
**Body Font:** SF Pro through SwiftUI system text styles  
**Label/Mono Font:** SF Pro for labels; SF Mono only for dates, inscriptions, coordinates, and source-like strings

**Character:** Editorial serif type gives stories, Irish phrases, names, and artifacts a human cadence. San Francisco carries navigation, instructions, controls, metadata, and dense learning UI so the app stays legible and native.

### Hierarchy

- **Display** (semibold, 34 pt reference, 1.12): County openings, major people, and singular story turns. Implement with a scalable semantic style, not a fixed-size assumption.
- **Headline** (semibold, 26 pt reference, 1.18): Screen and dossier headings.
- **Title** (semibold, 20 pt reference, 1.25): Evidence objects, story registers, and important Irish phrases.
- **Body** (regular, 17 pt reference, 1.35): Exposition and instructions, normally limited to roughly 65–70 characters per line.
- **Label** (semibold, 12 pt reference, 1.6 pt tracking): Sparse contextual markers such as place, date, or register. Sentence case is the default; uppercase is reserved for short archival or cartographic labels.

### Named Rules

**The Two-Voice Rule.** Serif speaks for story, names, quoted language, and evidence; sans serif speaks for the interface. Never use display serif for buttons, tabs, settings, or dense metadata.

**The Living Type Rule.** The point sizes above describe the current hierarchy, not fixed geometry. Production components must migrate to Dynamic Type styles and survive accessibility sizes without clipping.

**The Sparse Label Rule.** Do not place a tracked uppercase eyebrow above every heading. Use a contextual label only when it conveys real place, time, evidence, or language-register information.

## Elevation

An Turas is flat by default. Depth comes from tonal layering—limestone, raised, and sunk surfaces—plus separators, scale, and controlled overlap. Shadows are structural exceptions for map labels or transient elements that must separate from complex cartography; sheets use native system presentation and material behavior.

### Shadow Vocabulary

- **Map Label Lift** (`0 2pt 4pt rgba(35, 40, 31, 0.08)`): The only routine custom shadow, used to keep a small label legible over map detail. Never combine it with a heavy border or apply it to ordinary cards.

### Named Rules

**The Flat-Field Rule.** Surfaces sit in the same physical world until hierarchy or interaction requires separation. If every container casts a shadow, the journal metaphor has collapsed into a card dashboard.

## Components

Components should feel carved, placed, or revealed—never glossy. Standard iOS navigation and controls remain standard; custom styling belongs to the content and evidence layer.

### Buttons

- **Shape:** Compact, nearly square corners (4 pt) with a minimum 44 pt touch target.
- **Primary:** Ink fill, limestone text, semibold SF Pro, and 13 × 22 pt internal padding. One dominant primary action per screen.
- **Pressed / Focus:** A brief scale to 0.965 and opacity to 0.82 may provide tactile give, paired with light haptics. VoiceOver and keyboard focus retain clear native feedback. Reduce Motion removes scale.
- **Secondary / Ghost:** Use native plain or bordered button treatments with moss tint. Do not invent decorative button families.

### Chips

- **Style:** Compact 7 pt corners, short labels, and 9 × 13 pt padding. Unselected chips use a raised neutral surface; selected chips invert to ink and limestone.
- **State:** Use for bounded view filters or evidence categories, never as a substitute for navigation. Each state needs text and selection semantics.

### Cards / Containers

- **Corner Style:** Quietly curved (8–12 pt), never pill-shaped.
- **Background:** Raised for discrete evidence or exercises; sunk for inset explanation and reflection.
- **Shadow Strategy:** None at rest. Use a one-point boundary only when adjacent tonal layers do not separate clearly.
- **Internal Padding:** 16 pt default, 20–22 pt for dossier-scale containers.
- **Structure:** Prefer editorial sections, lists, maps, and full-bleed evidence over grids of identical cards.

### Inputs / Fields

- **Style:** Use native SwiftUI fields, text editors, toggles, pickers, and segmented controls with moss tint and semantic backgrounds.
- **Focus:** Preserve system focus behavior and add no ornamental glow.
- **Error / Disabled:** Error uses rust plus an icon and plain-language explanation. Disabled state reduces emphasis but must remain readable.

### Navigation

- Use `NavigationStack` for hierarchy, native back behavior, sheets for self-contained tasks, and a tab bar only if the product stabilizes around two to five true top-level destinations.
- Preserve edge-swipe back, safe areas, large-title conventions where appropriate, and native sheet dismissal. Full-screen covers are reserved for genuinely immersive story encounters.

### Atlas and Evidence

- The island map is a progress instrument and editorial table of contents, not a decorative hero. Every mark must encode county, route, time, status, or selection.
- Evidence views lead with the surviving object or source, then expose provenance, interpretation, and language earned from it. The full evidence taxonomy belongs in the opened detail, not repeated through the story surface. Reconstruction and consequential dispute still require visibly different entry and exit treatment.

### Motion and Haptics

- `settle` is the standard state transition; `rise` is reserved for story beats; `pop` is limited to small marks such as carving strokes and locks.
- Motion communicates arrival, state, spatial continuity, or physical response. It must never delay the learner's task.
- Reduce Motion replaces staggered movement, springs, shakes, and map travel with immediate changes or short crossfades. Haptics reinforce consequential touch but never become required feedback.

## Do's and Don'ts

### Do:

- **Do** make the real person, place, object, document, or surviving trace the visual center of each encounter.
- **Do** use limestone/shore tonal layering before adding borders or shadows.
- **Do** preserve native iOS navigation, controls, safe areas, 44 pt touch targets, VoiceOver order, Dynamic Type, Dark Mode, Increased Contrast, and Reduce Motion.
- **Do** distinguish documented fact, inference, uncertainty, and reconstruction with restrained symbols, accessible semantics, and complete on-demand detail. Use persistent text when misunderstanding would materially change the account.
- **Do** let Irish appear early, audibly, and in context; pronunciation controls and glosses must be easy to find without interrupting reading.
- **Do** separate “What survives,” “What you made,” and “Words you carry” in the collection.

### Don't:

- **Don't** use generic language-app gamification: streak anxiety, XP, leagues, confetti, cartoon reward economies, or overdue-card debt.
- **Don't** use “plastic shamrock” Irishness: novelty Celtic decoration, tourist-green saturation, romantic nationalism, or history reduced to costume and folklore.
- **Don't** make the experience resemble a textbook, flashcard inventory, spreadsheet-like curriculum, trophy room, or solemn digital museum.
- **Don't** cast the learner as a fictional guide, witness, or assistant in undocumented history.
- **Don't** break trusted iOS navigation, controls, accessibility, or reading behavior for interface novelty.
- **Don't** use decorative card grids, side-stripe accents, gradient text, glassmorphism, oversized corner radii, or border-plus-wide-shadow ghost cards.
- **Don't** communicate county progress, certainty, correctness, or error by color alone.
- **Don't** turn evidence status into repeated pills, uppercase labels, or prose that restates the claim. One claim gets one primary reading and one quiet path to its evidence.
- **Don't** hard-code type in production components where Dynamic Type can express the intended hierarchy.
