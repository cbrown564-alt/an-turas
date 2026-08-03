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
