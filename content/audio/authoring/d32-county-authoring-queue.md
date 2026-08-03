# D32 county authoring queue

Operational queue for Track A's provisional phrase-family authoring. The atlas and
story slate remain the source inputs; queue membership is not evidence of historical,
Irish-language, pedagogy, rights, audio-QA, or learner-release approval.

## Partition

| Queue | Counties | Entry condition |
| --- | --- | --- |
| `slice-01-story-scaffold` | Dublin, Mayo, Meath, Offaly | Existing county story pack and exercise records support exact story/use bindings. The first slice adds new v2 families for Dublin, Meath, and Offaly; Mayo is the existing v2 contract exemplar. |
| `queue-02-evidence-led-next` | Cork, Galway, Kerry, Longford, Louth, Roscommon, Tipperary, Waterford | Named anchor and a plausible place/story language field in the slate; assemble source register and exercise demand before authoring. |
| `queue-03-source-packet` | Antrim, Armagh, Carlow, Cavan, Clare, Down, Fermanagh, Kildare, Kilkenny, Laois, Monaghan, Sligo, Westmeath, Wicklow | Build or confirm the story source packet, county/place forms, and consuming exercise shell before writing family members. |
| `queue-04-sensitive-review-first` | Derry, Donegal, Leitrim, Limerick, Tyrone, Wexford | Secure multi-perspective history/community review route, rights, and language source before family expansion; no score-chasing treatment of sensitive material. |

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
