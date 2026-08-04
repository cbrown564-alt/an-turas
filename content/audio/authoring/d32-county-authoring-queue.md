# D32 county authoring queue

Operational queue for Track A's provisional phrase-family authoring. The atlas and
story slate remain the source inputs; queue membership is not evidence of historical,
Irish-language, pedagogy, rights, audio-QA, or learner-release approval.

**Current priority:** Tracks C–E are closed for payload
`d32.harvest.track-b.2026-08-03` (**2,818** captured lines; **3,880** runtime clips
checksum-verified; reconcile non-blocking). Next: harvest freeze / learner-facing
slice selection — do not open a new provider payload for this tranche. Reports:
[`d32-track-d-post-capture-report.json`](d32-track-d-post-capture-report.json),
[`d32-track-e-reconcile-report.json`](d32-track-e-reconcile-report.json). See
[`STATUS.md`](../../../STATUS.md).

## Bulk Track A avenues (parallel)

These streams are independent where noted. Each must land complete v2 members with
exercise consumers before store registration. Yield is **unique normalized text**, not
member count.

| Id | Avenue | Queue / scope | Tool or path |
| --- | --- | --- | --- |
| A1 | Personal Atlas names and places | All counties; expand past **80** pilot subjects | [`tools/generate_personal_atlas_name_place_families.py`](../../../tools/generate_personal_atlas_name_place_families.py) |
| A2 | Story dialogue and exercise roles | All **32** story bindings | County packs + [`tools/generate_d32_county_families.py`](../../../tools/generate_d32_county_families.py); uses ledger in [`d32-county-harvest-uses.json`](d32-county-harvest-uses.json) |
| A3 | Mutation, fada, minimal-pair contrasts | Risk-sample senses first, then breadth | [`tools/generate_d32_harvest_extension_tranche.py`](../../../tools/generate_d32_harvest_extension_tranche.py) pattern |
| A4 | Pedagogy-bound examples | Cross-county lessons | [`content/pedagogy/irish-explanations-v1.json`](../../pedagogy/irish-explanations-v1.json) + [`tools/validate_pedagogy_corpus.py`](../../../tools/validate_pedagogy_corpus.py) |
| A5 | Evidence-led expansion | **`queue-02-evidence-led-next`** (8 counties) | Manual/source register per county below |
| A6 | Source-packet expansion | **`queue-03-source-packet`** (14 counties) | Confirm packet before family volume |
| A7 | Sensitive expansion | **`queue-04-sensitive-review-first`** (6 counties) | Review route before volume |
| A8 | Story-slate historical names | Story anchors | `STORY_SLATE_SUBJECTS` in personal-atlas generator |

**Preflight before Track B:** merged slice must pass `structured_audio_authoring.py check`
and show **≥500** net-new registrable lines on `prepare-harvest` unless explicitly scoped
smaller.

## Partition

| Queue | Counties | Entry condition |
| --- | --- | --- |
| `slice-01-story-scaffold` | Dublin, Mayo, Meath, Offaly | Existing county story pack and exercise records support exact story/use bindings. The first slice adds new v2 families for Dublin, Meath, and Offaly; Mayo is the existing v2 contract exemplar. |
| `queue-02-evidence-led-next` | Cork, Galway, Kerry, Longford, Louth, Roscommon, Tipperary, Waterford | Named anchor and a plausible place/story language field in the slate; assemble source register and exercise demand before authoring. Source register: [`d32-queue-02-evidence-source-register.json`](d32-queue-02-evidence-source-register.json). Authoring tool: [`tools/generate_d32_evidence_led_tranche.py`](../../../tools/generate_d32_evidence_led_tranche.py). |
| `queue-03-source-packet` | Antrim, Armagh, Carlow, Cavan, Clare, Down, Fermanagh, Kildare, Kilkenny, Laois, Monaghan, Sligo, Westmeath, Wicklow | Build or confirm the story source packet, county/place forms, and consuming exercise shell before writing family members. |
| `queue-04-sensitive-review-first` | Derry, Donegal, Leitrim, Limerick, Tyrone, Wexford | Secure multi-perspective history/community review route, rights, and language source before family expansion; no score-chasing treatment of sensitive material. |

## A7 / `queue-04-sensitive-review-first` — current gate

**Status (2026-08-03):** review route scaffolded; **volume blocked**; yield remains
**TBD**. Do not author net-new unique text for score. Do not invent community or
historian approval. See [`STATUS.md`](../../../STATUS.md) avenue A7 for the Track A
parallelism rule (limited — secure review route before volume).

Canonical checklist and county lanes:

- [`docs/content/sensitive-county-review-route.md`](../../../docs/content/sensitive-county-review-route.md)
- [`queue-04-sensitive-review-register.json`](queue-04-sensitive-review-register.json)

| County | Story id | Volume |
| --- | --- | --- |
| Derry | `d32.derry.city-walls-siege` | Blocked until history, community, rights, and language lanes have named owners and a first packet |
| Donegal | `d32.donegal.flight-of-the-earls` | Blocked (Flight of the Earls / Ulster memory) |
| Leitrim | `d32.leitrim.brian-na-murtha` | Blocked (conquest-narrative risk) |
| Limerick | `d32.limerick.treaty-of-limerick` | Blocked (contested treaty memory) |
| Tyrone | `d32.tyrone.hugh-oneill-dungannon` | Blocked (competing leader descriptions; Donegal sequence) |
| Wexford | `d32.wexford.bagenal-harvey-1798` | Blocked (1798 multi-community civilian experience) |

Existing provisional D32 families for these counties stay draft and release-blocked.
Member learner-release reasons now include sensitive-route markers; that is a gate,
not an approval record.

## Slice handoff

The first representative slice is the three registered family documents in the
canonical store:

- `offaly.cross-of-the-scriptures.cros.cross-noun`
- `dublin.sihtric-penny.ainm.name-noun`
- `meath.trim-de-lacy.baile.town-noun`

Each member is complete as provisional authoring, has an exact repository exercise
consumer, and remains review-pending with capture not requested. Track B may use the
member IDs and canonical Irish text as a manifest input after independently checking
the store; this queue does not authorize provider execution.

Source inputs: `content/audio/atlas-headwords-v1.json`, `docs/COUNTY-STORY-SLATE.md`,
and the four existing `content/{mayo,offaly,dublin,meath}/*.pack.draft.json` records.

## A6 / `queue-03-source-packet` progress (2026-08-03)

Branch: `track-a/a6-source-packet`. Tool:
[`tools/generate_d32_source_packet_expansion.py`](../../../tools/generate_d32_source_packet_expansion.py).
Packet register:
[`d32-queue-03-source-packets.json`](d32-queue-03-source-packets.json).

Entry order followed for all 14 counties: source-packet stub + county/place forms +
existing exercise shell confirmed, then family members authored. Capture was not run.

| County | Packet | Support | Authored members | Notes |
| --- | --- | --- | ---: | --- |
| Antrim | stub confirmed | full_provisional | 40 | `Clochán an Aifir` Logainm-confirmed |
| Armagh | stub confirmed | full_provisional | 40 | manuscript excerpt gate open |
| Carlow | stub confirmed | full_provisional | 40 | Moling Life translation gate open |
| Cavan | stub confirmed | full_provisional | 40 | site Irish forms pending Logainm |
| Clare | stub confirmed | full_provisional | 40 | Kincora/Killaloe forms pending |
| Down | stub confirmed | full_provisional | 40 | Saul form pending |
| Fermanagh | stub confirmed | full_provisional | 40 | Enniskillen form pending |
| Kildare | stub confirmed | full_provisional | 40 | `Cill Dara` Logainm-confirmed |
| Kilkenny | stub confirmed | bounded_sensitive | 40 | descriptive frames only; no trial-as-game |
| Laois | stub confirmed | full_provisional | 40 | Dunamase form pending |
| Monaghan | stub confirmed | rights_bounded | 40 | no Kavanagh quotation; rights blocker recorded |
| Sligo | stub confirmed | full_provisional | 40 | no Yeats quotation in this tranche |
| Westmeath | stub confirmed | full_provisional | 40 | Fore form pending |
| Wicklow | stub confirmed | full_provisional | 40 | Glendalough form pending |

**Yield:** 560 net-new unique normalized texts (within the 300–900 A6 band). Uses ledger
updated; identical duplicate story rows collapsed 602 → 32.
