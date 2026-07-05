#!/usr/bin/env python3
"""Generate content/chapter3/draft.json — Chapter 3 generator output."""
import json
from pathlib import Path

chapter = {
    "title": "Na Lochlannaigh",
    "subtitle": "The Vikings — Dubhlinn, 795–900 AD",
    "sessions": [
        {
            "ga": "An Deatach ar an bhfánaí",
            "en": "Smoke on the horizon — the past tense arrives",
            "hook": "Tomorrow you'll walk east to the black pool. The past tense will carry you — and so will the strangers who came from the sea.",
            "pages": [
                {
                    "type": "scene",
                    "place": "Coast north of the Shannon · c. 795 AD",
                    "image": "ch3-coast",
                    "beats": [
                        {
                            "n": "You have stepped forward again — east from the scriptorium's quiet, down to a coast where the wind carries salt and wood-smoke from a settlement of timber and thatch."
                        },
                        {
                            "n": "A woman named Ailbhe stands on the headland, hand shading her eyes. Her dog Bran whines once, low in his throat."
                        },
                        {
                            "s": "Chonaic mé deatach ar an bhfánaí.",
                            "who": "Ailbhe — the trader",
                            "g": "I saw smoke on the horizon — *chonaic* is past tense: I saw",
                            "ph": "KHON-ik may JAT-akh er un VAH-nee",
                        },
                    ],
                },
                {
                    "type": "scene",
                    "beats": [
                        {
                            "n": "At first it looked like a cloud. Then the cloud had edges — dark prows, square sails, the line of the sea broken by something that did not belong to this shore."
                        },
                        {
                            "s": "Tháinig na longa ó thuaidh.",
                            "who": "Ailbhe",
                            "g": "The ships came from the north — *tháinig* = came (past)",
                            "ph": "HAW-nig na LONG-uh oh HOO-ee",
                        },
                        {
                            "n": "What happened next is history, not a story with heroes. They took what they could carry. They burned what they could not. Ailbhe does not dress it up."
                        },
                        {
                            "s": "Rinne siad damáiste.",
                            "who": "Ailbhe",
                            "g": "They did damage — *rinne* = made/did (past)",
                            "ph": "RIN-yeh seed DAM-awsh-teh",
                        },
                    ],
                },
                {
                    "type": "note",
                    "title": "An Nóta Gramadaí — the séimhiú in the past",
                    "paras": [
                        "You know lenition from names and places. In the **past tense**, it becomes a system: the verb often marks *finished time* by changing the first consonant.",
                        "**Chonaic** — saw — begins with *ch*, not *c*. **Tháinig** — came — begins with *th*, not *t*. **Rinne** — did — is its own shape, but still past.",
                        "School lists these as irregular exceptions. Irish treats them as one family: **the action is over**. From here on, listen for that first-letter shift when someone tells you what already happened.",
                    ],
                    "pairs": [
                        "Chonaic mé … — I saw …",
                        "Tháinig siad … — They came …",
                        "Rinne mé … — I did / I made …",
                    ],
                },
                {
                    "type": "choice",
                    "context": "Bran barks at the empty sea. Ailbhe is testing whether you followed.",
                    "prompt": "Which sentence means “I saw smoke on the horizon”?",
                    "opts": [
                        {
                            "txt": "Chonaic mé deatach ar an bhfánaí",
                            "ok": True,
                            "why": "Chonaic = I saw. Deatach ar an bhfánaí — smoke on the horizon.",
                        },
                        {
                            "txt": "Feicim deatach ar an bhfánaí",
                            "ok": False,
                            "why": "Feicim is present — I see now. Ailbhe spoke of what already happened: chonaic.",
                        },
                        {
                            "txt": "Tá deatach ar an bhfánaí",
                            "ok": False,
                            "why": "Tá tells you the smoke is there now — not that you saw it arrive.",
                        },
                    ],
                },
                {
                    "type": "match",
                    "prompt": "Match the past-tense verb to its meaning.",
                    "pairs": [
                        ["chonaic", "saw"],
                        ["tháinig", "came"],
                        ["rinne", "did / made"],
                        ["chuaigh", "went"],
                    ],
                },
                {
                    "type": "echo",
                    "context": "Ailbhe speaks slowly — past tense on the tongue, not the present you learned in the scriptorium.",
                    "s": "Tháinig na longa ó thuaidh.",
                    "who": "Ailbhe — then you",
                    "g": "The ships came from the north",
                    "ph": "HAW-nig na LONG-uh oh HOO-ee",
                },
                {
                    "type": "choice",
                    "context": "A boy from the settlement asks what the strangers did.",
                    "prompt": "Which line answers in the past?",
                    "opts": [
                        {
                            "txt": "Rinne siad damáiste",
                            "ok": True,
                            "why": "Rinne = they did. Damáiste = damage. Past tense, plain fact.",
                        },
                        {
                            "txt": "Tá siad ag déanamh damáiste",
                            "ok": False,
                            "why": "That is present progressive — they are doing damage now. The raid is over.",
                        },
                        {
                            "txt": "Is damáiste iad",
                            "ok": False,
                            "why": "Identity with *is* — not the right tool for an action completed.",
                        },
                    ],
                },
                {
                    "type": "turn",
                    "beats": [
                        {
                            "n": "Ailbhe turns from the sea. Her voice is steady — she wants your witness, not a story."
                        },
                        {
                            "s": "Cad a chonaic tú?",
                            "who": "Ailbhe",
                            "g": "What did you see? — *cad a* + past verb",
                            "ph": "kawd ah KHON-ik too",
                        },
                    ],
                    "cue": "Answer in the past — what you saw on the horizon.",
                    "replies": [
                        {
                            "s": "Chonaic mé deatach ar an bhfánaí.",
                            "g": "I saw smoke on the horizon",
                            "ph": "KHON-ik may JAT-akh er un VAH-nee",
                            "reaction": [
                                {
                                    "s": "Tá a fhios agam.",
                                    "who": "Ailbhe",
                                    "g": "I know — literally ‘there is knowledge at me’",
                                    "ph": "taw iss AH-gum",
                                },
                                {
                                    "n": "She nods once. The past tense holds what the present cannot.",
                                },
                            ],
                        }
                    ],
                },
                {
                    "type": "listen",
                    "context": "Wind off the water. Ailbhe murmurs the line again — listen.",
                    "prompt": "Which past-tense verb did she use?",
                    "say": "Chonaic mé deatach ar an bhfánaí",
                    "opts": [
                        {
                            "txt": "Chonaic — I saw",
                            "ok": True,
                            "why": "Chonaic mé — I saw. The hard ch at the start marks past seeing.",
                        },
                        {
                            "txt": "Chuaigh — I went",
                            "ok": False,
                            "why": "Chuaigh is went — you'll walk with that verb tomorrow.",
                        },
                        {
                            "txt": "Cheannaigh — I bought",
                            "ok": False,
                            "why": "Cheannaigh is bought — market tense, not horizon tense.",
                        },
                    ],
                },
                {
                    "type": "note",
                    "title": "A generation later",
                    "paras": [
                        "The raids did not stop. Neither did the sea. But over a generation something else happened too: **trade**.",
                        "Norse and Irish did not only meet with swords. They met with wool and silver, with fish and slaves and timber — and with words that stuck.",
                        "Tomorrow you'll walk to **Dubhlinn**, the black pool where a muddy town is rising. You'll need the past tense to say how you got there.",
                    ],
                },
                {
                    "type": "scene",
                    "beats": [
                        {
                            "n": "The smoke clears. The settlement rebuilds. Ailbhe folds her cloak and points east along the coast."
                        },
                        {
                            "s": "Chuaigh mé an bealach seo cheana.",
                            "who": "Ailbhe",
                            "g": "I went this way before — *chuaigh* = went",
                            "ph": "KHWEE may un BAL-akh shuh HYAN-uh",
                        },
                        {
                            "n": "“Tomorrow,” she says, “you'll need *chuaigh* in your mouth — and names for left and right.”",
                        },
                    ],
                },
            ],
        },
        {
            "ga": "An Poll Dubh",
            "en": "The black pool — movement and directions",
            "hook": "Tomorrow the market opens at the quay. Sigur trades in Irish and Norse at once — and you'll need every loanword before you can count the price.",
            "pages": [
                {
                    "type": "recarve",
                    "intro": "East along the coast road. Ailbhe walks ahead; Bran trots at her heel. Yesterday's smoke is ash — but the verbs stay past.",
                    "items": [
                        {
                            "answer": "Chonaic mé deatach ar an bhfánaí",
                            "en": "I saw smoke on the horizon",
                            "from": "Seisiún 1",
                        },
                        {
                            "answer": "Tháinig na longa ó thuaidh",
                            "en": "The ships came from the north",
                            "from": "Seisiún 1",
                        },
                        {
                            "answer": "Rinne siad damáiste",
                            "en": "They did damage",
                            "from": "Seisiún 1",
                        },
                    ],
                },
                {
                    "type": "scene",
                    "place": "Dubhlinn · c. 900 AD",
                    "image": "ch3-dubhlinn",
                    "beats": [
                        {
                            "n": "A generation later — or two — the headland gives way to mud flats, timber walls, smoke from forges and kitchens, the smell of fish and tallow. Longships lie beached beside currachs. Norse and Irish share the same muddy street."
                        },
                        {
                            "s": "Chuaigh mé go dtí an linn dubh.",
                            "who": "Ailbhe",
                            "g": "I went to the black pool — *chuaigh … go dtí* = went to",
                            "ph": "KHWEE may guh djee un lin duv",
                        },
                    ],
                },
                {
                    "type": "lens",
                    "en": "Dublin",
                    "ga": "Dubhlinn",
                    "parts": [
                        {"ga": "dubh", "en": "black"},
                        {"ga": "linn", "en": "pool — a tidal pool at the river mouth"},
                    ],
                    "meaning": "the black pool",
                    "note": "The Vikings did not rename an Irish city — they settled at a feature Irish speakers already described. **Baile Átha Cliath** is the older Irish name for the crossing; **Dubhlinn** is what the Norse heard and kept. Today both names survive in different registers.",
                },
                {
                    "type": "note",
                    "title": "Ag dul — going places",
                    "paras": [
                        "Movement in the past uses **chuaigh** — went — plus a direction.",
                        "**Go dtí** marks a destination: *Chuaigh mé go dtí an margadh* — I went to the market.",
                        "Directions wear séimhiú after certain prepositions: **ar dheis** (on the right), **ar chlé** (on the left), **díreach ar aghaidh** (straight ahead).",
                    ],
                    "pairs": [
                        "Chuaigh mé go dtí an margadh. — I went to the market.",
                        "Téigh ar dheis. — Turn right. (command)",
                        "Téigh ar chlé. — Turn left.",
                        "Téigh díreach ar aghaidh. — Go straight ahead.",
                    ],
                },
                {
                    "type": "choice",
                    "context": "A Norse sailor blocks the lane with a barrel. Ailbhe points left.",
                    "prompt": "She says “Téigh ar chlé.” Which way do you go?",
                    "opts": [
                        {
                            "txt": "Left",
                            "ok": True,
                            "why": "Ar chlé = on the left. Téigh ar chlé — go left.",
                        },
                        {
                            "txt": "Right",
                            "ok": False,
                            "why": "Right is ar dheis — different séimhiú, different side.",
                        },
                        {
                            "txt": "Back to the shore",
                            "ok": False,
                            "why": "She gave a left/right command, not a return.",
                        },
                    ],
                },
                {
                    "type": "match",
                    "prompt": "Match the direction phrase to its meaning.",
                    "pairs": [
                        ["ar dheis", "on the right"],
                        ["ar chlé", "on the left"],
                        ["díreach ar aghaidh", "straight ahead"],
                        ["trasna an bhóthair", "across the road"],
                        ["isteach sa mhargadh", "into the market"],
                    ],
                },
                {
                    "type": "turn",
                    "beats": [
                        {
                            "n": "Sigur — a Norse merchant in a blue cloak — blocks the lane without quite blocking it. Trade manners."
                        },
                        {
                            "s": "Cá bhfuil tú ag teacht?",
                            "who": "Sigur",
                            "g": "Where are you coming from? — Connacht form; Munster often *Cá bhfuil tú ag teacht?* similarly",
                            "ph": "kaw vwil too eg TCHAKHT",
                        },
                    ],
                    "cue": "Tell him where you went — the black pool.",
                    "replies": [
                        {
                            "s": "Chuaigh mé go dtí an linn dubh.",
                            "g": "I went to the black pool",
                            "ph": "KHWEE may guh djee un lin duv",
                            "reaction": [
                                {
                                    "s": "Maith.",
                                    "who": "Sigur",
                                    "g": "Good — short approval",
                                    "ph": "my",
                                },
                                {
                                    "n": "He steps aside. Chuaigh — went — opens the town.",
                                },
                            ],
                        }
                    ],
                },
                {
                    "type": "note",
                    "title": "Ag comhaireamh sa tsráid — counting in the street",
                    "paras": [
                        "Eleven through fifteen add **déag** after the unit — and the unit lenites where required.",
                        "You'll hear them at stalls before you hear grammar labels.",
                    ],
                    "pairs": [
                        "aon déag — eleven",
                        "dó dhéag — twelve",
                        "trí déag — thirteen",
                        "ceithre déag — fourteen",
                        "cúig déag — fifteen",
                    ],
                },
                {
                    "type": "listen",
                    "context": "Sigur counts hides on the quay — listen for the number.",
                    "prompt": "Which number did he say?",
                    "say": "trí déag",
                    "opts": [
                        {
                            "txt": "trí déag — thirteen",
                            "ok": True,
                            "why": "Trí déag — three + déag = thirteen.",
                        },
                        {
                            "txt": "trí — three",
                            "ok": False,
                            "why": "He added déag — this was thirteen, not three.",
                        },
                        {
                            "txt": "ceithre déag — fourteen",
                            "ok": False,
                            "why": "Ceithre déag starts harder. He said trí déag.",
                        },
                    ],
                },
                {
                    "type": "choice",
                    "prompt": "Which phrase means “I went to the market”?",
                    "opts": [
                        {
                            "txt": "Chuaigh mé go dtí an margadh",
                            "ok": True,
                            "why": "Chuaigh = went. Go dtí an margadh = to the market.",
                        },
                        {
                            "txt": "Tá mé ag dul go dtí an margadh",
                            "ok": False,
                            "why": "That is present — I am going. Sigur asked where you came from in the past.",
                        },
                        {
                            "txt": "Is margadh mé",
                            "ok": False,
                            "why": "You are not identifying as a market.",
                        },
                    ],
                },
                {
                    "type": "choice",
                    "prompt": "Sigur counts hides: cúig déag. What number is that?",
                    "opts": [
                        {
                            "txt": "fifteen",
                            "ok": True,
                            "why": "Cúig déag = five + ten = fifteen.",
                        },
                        {
                            "txt": "five",
                            "ok": False,
                            "why": "Five alone is cúig. He added déag.",
                        },
                        {
                            "txt": "fifty",
                            "ok": False,
                            "why": "Fifty is caoga — a different word entirely.",
                        },
                    ],
                },
                {
                    "type": "typein",
                    "context": "Ailbhe chalks the direction on a slate — missing fadas: “Teigh ar chle.”",
                    "prompt": "Correct it — mind *Téigh* and *chlé*.",
                    "placeholder": "Téigh ar chlé",
                    "check": "exact",
                    "answer": "Téigh ar chlé",
                    "fada": True,
                    "hint": "Téigh and chlé both need fadas.",
                },
                {
                    "type": "echo",
                    "context": "Sigur waves you toward the stalls.",
                    "s": "Téigh díreach ar aghaidh.",
                    "who": "Sigur — then you",
                    "g": "Go straight ahead",
                    "ph": "tchay JEE-rakh er eye",
                },
                {
                    "type": "scene",
                    "beats": [
                        {
                            "n": "The market noise rises — Norse, Irish, the clink of silver on wood. Sigur grins without warmth."
                        },
                        {
                            "n": "“Tomorrow,” Ailbhe says, “you buy with words the Norse left behind — and Irish kept.”",
                        },
                    ],
                },
            ],
        },
        {
            "ga": "An Margadh",
            "en": "The market — trade words and Norse loans",
            "hook": "Tomorrow Sigur cuts silver by weight. You'll need every number to sixteen before he names your price.",
            "pages": [
                {
                    "type": "recarve",
                    "intro": "The market opens at dawn. On your way in you pass yesterday's directions — still chalked on a post.",
                    "items": [
                        {
                            "answer": "Chuaigh mé go dtí an linn dubh",
                            "en": "I went to the black pool",
                            "from": "Seisiún 2",
                        },
                        {
                            "answer": "Téigh ar dheis",
                            "en": "turn right — command form",
                            "from": "Seisiún 2",
                        },
                        {
                            "answer": "trí déag",
                            "en": "thirteen — the hides he counted",
                            "from": "Seisiún 2",
                        },
                    ],
                },
                {
                    "type": "scene",
                    "place": "An margadh — the market quay",
                    "image": "ch3-market",
                    "beats": [
                        {
                            "n": "Stalls of fish, wool, amber, bronze pins. Sigur spreads a cloth and sets out shoes that curl at the toe — the Norse shape that will become Ireland's everyday **bróg**."
                        },
                        {
                            "s": "Is margadh mór é seo.",
                            "who": "Sigur",
                            "g": "This is a big market — *margadh* is itself a Norse loan Irish kept",
                            "ph": "iss MAR-ug mor ay shuh",
                        },
                        {
                            "s": "Cheannaigh mé bróga anseo inné.",
                            "who": "Ailbhe",
                            "g": "I bought shoes here yesterday — *cheannaigh* = bought (past)",
                            "ph": "KHYAN-ee may BROG-uh un-YOH in-YAY",
                        },
                    ],
                },
                {
                    "type": "note",
                    "title": "Focail Lochlannacha — words the Vikings left",
                    "paras": [
                        "Irish did not disappear under Norse. It **borrowed** — and then grammar took over.",
                        "**Margadh** (market), **pingin** (penny), **bróg** (shoe), **bord** (table), **gard** (enclosure/garden) — Norse words wearing Irish endings and Irish verbs.",
                        "You don't say “to buy bróg” in English either. You say **cheannaigh mé bróga** — bought I shoes — past tense, Irish order.",
                    ],
                    "pairs": [
                        "margadh — market (loan)",
                        "pingin — penny (loan)",
                        "bróg — shoe (loan)",
                        "cheannaigh mé bróga — I bought shoes",
                        "dhíol mé iasc — I sold fish",
                    ],
                },
                {
                    "type": "match",
                    "prompt": "Match the word to its origin and meaning.",
                    "pairs": [
                        ["margadh", "market — Norse loan, Irish grammar"],
                        ["pingin", "penny — Norse loan"],
                        ["bróg", "shoe — gave English “brogue”"],
                        ["bord", "table — Norse loan"],
                        ["gard", "garden/enclosure — Norse loan"],
                    ],
                },
                {
                    "type": "choice",
                    "context": "Sigur holds up a silver coin.",
                    "prompt": "Which word names the coin — a Norse loan Irish kept?",
                    "opts": [
                        {
                            "txt": "pingin",
                            "ok": True,
                            "why": "Pingin — penny — from Old Norse. Still in Irish and English.",
                        },
                        {
                            "txt": "pinge",
                            "ok": False,
                            "why": "Close, but Irish keeps pingin — watch the ending.",
                        },
                        {
                            "txt": "praghas",
                            "ok": False,
                            "why": "Praghas is price — native word, not the coin.",
                        },
                    ],
                },
                {
                    "type": "assemble",
                    "context": "Ailbhe rebuilds the line Sigur spoke.",
                    "prompt": "Build: “I bought shoes.”",
                    "tiles": ["bróga", "mé", "Cheannaigh"],
                    "answer": "Cheannaigh mé bróga",
                },
                {
                    "type": "listen",
                    "context": "Haggling behind you — listen for the trade verb.",
                    "prompt": "Which verb did the seller use?",
                    "say": "Dhíol mé an t-iasc",
                    "opts": [
                        {
                            "txt": "Dhíol mé — I sold",
                            "ok": True,
                            "why": "Dhíol = sold. An t-iasc — the fish.",
                        },
                        {
                            "txt": "Cheannaigh mé — I bought",
                            "ok": False,
                            "why": "Cheannaigh is bought — the seller did the opposite.",
                        },
                        {
                            "txt": "Rinne mé — I made",
                            "ok": False,
                            "why": "Rinne is made/did — not a sale.",
                        },
                    ],
                },
                {
                    "type": "choice",
                    "prompt": "Which sentence means “I sold fish”?",
                    "opts": [
                        {
                            "txt": "Dhíol mé iasc",
                            "ok": True,
                            "why": "Dhíol = sold. Iasc = fish.",
                        },
                        {
                            "txt": "Cheannaigh mé iasc",
                            "ok": False,
                            "why": "Cheannaigh = bought — the other direction.",
                        },
                        {
                            "txt": "Tá iasc agam",
                            "ok": False,
                            "why": "That is possession — I have fish — not a completed sale.",
                        },
                    ],
                },
                {
                    "type": "choice",
                    "context": "Sigur taps the table — a Norse **bord** — and the yard gate — **gard** — visible through the lane.",
                    "prompt": "Which pair names the Norse loans correctly?",
                    "opts": [
                        {
                            "txt": "bord — table; gard — garden/enclosure",
                            "ok": True,
                            "why": "Both are Norse loans Irish kept — bord for table, gard for enclosure.",
                        },
                        {
                            "txt": "bord — shoe; gard — market",
                            "ok": False,
                            "why": "Shoe is bróg; market is margadh.",
                        },
                        {
                            "txt": "bord — penny; gard — fish",
                            "ok": False,
                            "why": "Penny is pingin; fish is iasc.",
                        },
                    ],
                },
                {
                    "type": "turn",
                    "beats": [
                        {
                            "n": "Sigur points at Ailbhe's boots — good leather, Norse cut. He wants the story again."
                        },
                        {
                            "s": "Inné — cá bhfuair tú na bróga?",
                            "who": "Sigur",
                            "g": "Yesterday — where did you get the shoes?",
                            "ph": "in-YAY · kaw vwil too na BROG-uh",
                        },
                    ],
                    "cue": "Tell him where you bought them — past tense.",
                    "replies": [
                        {
                            "s": "Cheannaigh mé bróga anseo inné.",
                            "g": "I bought shoes here yesterday",
                            "ph": "KHYAN-ee may BROG-uh un-YOH in-YAY",
                            "reaction": [
                                {
                                    "s": "Maith an margadh.",
                                    "who": "Sigur",
                                    "g": "Good market — fair deal",
                                    "ph": "my un MAR-ug",
                                },
                                {
                                    "n": "Cheannaigh — bought — closes the bargain.",
                                },
                            ],
                        }
                    ],
                },
                {
                    "type": "typein",
                    "context": "A price slate reads “Praghas: aon deag pingin” — someone dropped a fada on “aon”.",
                    "prompt": "Correct: “Praghas: aon deag pingin.”",
                    "placeholder": "Praghas: aon déag pingin",
                    "check": "exact",
                    "answer": "Praghas: aon déag pingin",
                    "fada": True,
                    "hint": "Aon déag — eleven — needs a fada on déag.",
                },
                {
                    "type": "scene",
                    "beats": [
                        {
                            "n": "Sigur locks a strongbox and taps the side where silver waits in coils — not coin but **hack-silver**, rings cut by weight."
                        },
                        {
                            "n": "“Tomorrow,” he says, “we weigh your word against the scales — and count past fifteen.”",
                        },
                    ],
                },
            ],
        },
        {
            "ga": "Airgead agus Trádáil",
            "en": "Silver and trade — money and higher numbers",
            "hook": "Tomorrow the arm-ring is cut to weight and marked with your name. Sigur says Dubhlinn is only one of the port towns — wait until you hear Wexford.",
            "pages": [
                {
                    "type": "recarve",
                    "intro": "The scales open at first light. Sigur's fingers are ink-stained from tally marks.",
                    "items": [
                        {
                            "answer": "Cheannaigh mé bróga",
                            "en": "I bought shoes",
                            "from": "Seisiún 3",
                        },
                        {
                            "answer": "pingin",
                            "en": "penny — Norse loan",
                            "from": "Seisiún 3",
                        },
                        {
                            "answer": "margadh",
                            "en": "market",
                            "from": "Seisiún 3",
                        },
                    ],
                },
                {
                    "type": "scene",
                    "place": "An scála — the weighing table",
                    "image": "ch3-silver",
                    "beats": [
                        {
                            "n": "Silver does not arrive as coins alone. Arm-rings — **fáinní airgid** — are cut with shears when a deal needs exact weight. The shavings still spend."
                        },
                        {
                            "s": "Rinne mé margadh le Sigur.",
                            "who": "Ailbhe",
                            "g": "I made a deal with Sigur — *rinne* returns: did/made",
                            "ph": "RIN-yeh may MAR-ug leh SIG-ur",
                        },
                        {
                            "s": "Chonaic mé an t-airgead ar an scála.",
                            "who": "Ailbhe",
                            "g": "I saw the silver on the scales",
                            "ph": "KHON-ik may un TAR-gud er un SKAW-luh",
                        },
                    ],
                },
                {
                    "type": "note",
                    "title": "Uimhreacha 16–20 — and the money words",
                    "paras": [
                        "Sixteen to nineteen follow the same **déag** pattern: **sé déag**, **seacht déag**, **ocht déag**, **naoi déag**. Twenty is **fiche**.",
                        "**Airgead** means silver/money. **Scilling** is another loan — a shilling's weight in trade talk.",
                    ],
                    "pairs": [
                        "sé déag — sixteen",
                        "seacht déag — seventeen",
                        "ocht déag — eighteen",
                        "naoi déag — nineteen",
                        "fiche — twenty",
                        "airgead — silver / money",
                    ],
                },
                {
                    "type": "match",
                    "prompt": "Match the number or money word to its meaning.",
                    "pairs": [
                        ["sé déag", "sixteen"],
                        ["seacht déag", "seventeen"],
                        ["ocht déag", "eighteen"],
                        ["naoi déag", "nineteen"],
                        ["fiche", "twenty"],
                        ["airgead", "silver / money"],
                        ["scilling", "shilling — trade loan"],
                    ],
                },
                {
                    "type": "choice",
                    "context": "Sigur drops eighteen pingin on the cloth.",
                    "prompt": "Which phrase counts them correctly?",
                    "opts": [
                        {
                            "txt": "Ocht déag pingin",
                            "ok": True,
                            "why": "Ocht déag = eighteen. Pingin — pennies.",
                        },
                        {
                            "txt": "Ocht pingin déag",
                            "ok": False,
                            "why": "The number comes before pingin; déag attaches to the unit, not the coin.",
                        },
                        {
                            "txt": "Ocht déag scilling",
                            "ok": False,
                            "why": "He counted pingin, not scilling.",
                        },
                    ],
                },
                {
                    "type": "listen",
                    "context": "The scales settle — listen.",
                    "prompt": "How many pingin did Sigur say?",
                    "say": "fiche pingin",
                    "opts": [
                        {
                            "txt": "fiche pingin — twenty pennies",
                            "ok": True,
                            "why": "Fiche = twenty. Pingin = pennies.",
                        },
                        {
                            "txt": "dó pingin — two pennies",
                            "ok": False,
                            "why": "Dó is two. He said fiche — twenty.",
                        },
                        {
                            "txt": "cúig déag pingin — fifteen pennies",
                            "ok": False,
                            "why": "Cúig déag is fifteen. Fiche is a new word for twenty.",
                        },
                    ],
                },
                {
                    "type": "assemble",
                    "context": "Ailbhe narrates the deal for the record.",
                    "prompt": "Build: “I made a deal with Sigur.”",
                    "tiles": ["Sigur", "le", "mé", "margadh", "Rinne"],
                    "answer": "Rinne mé margadh le Sigur",
                },
                {
                    "type": "listen",
                    "context": "Sigur counts aloud — higher numbers now.",
                    "prompt": "Which number did he say?",
                    "say": "ceithre déag pingin",
                    "opts": [
                        {
                            "txt": "ceithre déag pingin — fourteen pennies",
                            "ok": True,
                            "why": "Ceithre déag = fourteen. Pingin = pennies.",
                        },
                        {
                            "txt": "cúig déag pingin — fifteen pennies",
                            "ok": False,
                            "why": "Cúig déag is fifteen. He said ceithre déag.",
                        },
                        {
                            "txt": "ceithre pingin — four pennies",
                            "ok": False,
                            "why": "He added déag — this was fourteen.",
                        },
                    ],
                },
                {
                    "type": "turn",
                    "beats": [
                        {
                            "n": "Sigur pushes the scales toward you. He already knows the answer — he wants the verb."
                        },
                        {
                            "s": "Chonaic tú an t-airgead?",
                            "who": "Sigur",
                            "g": "Did you see the silver? — past question with *chonaic*",
                            "ph": "KHON-ik too un TAR-gud",
                        },
                    ],
                    "cue": "Tell him what you saw — on the scales.",
                    "replies": [
                        {
                            "s": "Chonaic mé an t-airgead ar an scála.",
                            "g": "I saw the silver on the scales",
                            "ph": "KHON-ik may un TAR-gud er un SKAW-luh",
                            "reaction": [
                                {
                                    "s": "Maith.",
                                    "who": "Sigur",
                                    "g": "Good",
                                    "ph": "my",
                                },
                                {
                                    "n": "The scales remember. So does the past tense.",
                                },
                            ],
                        }
                    ],
                },
                {
                    "type": "choice",
                    "prompt": "Which sentence means “They came from the north”?",
                    "opts": [
                        {
                            "txt": "Tháinig siad ó thuaidh",
                            "ok": True,
                            "why": "Tháinig = came. Ó thuaidh = from the north.",
                        },
                        {
                            "txt": "Tagann siad ó thuaidh",
                            "ok": False,
                            "why": "Tagann is present habitual — they come. You need past.",
                        },
                        {
                            "txt": "Tá siad ó thuaidh",
                            "ok": False,
                            "why": "That says they are from the north — not that they came.",
                        },
                    ],
                },
                {
                    "type": "note",
                    "title": "Portaí — towns the sea built",
                    "paras": [
                        "Dubhlinn is not alone. **Port Láirge** (Waterford), **Loch Garman** (Wexford), **Luimneach** (Limerick) — Viking ports that became Irish cities.",
                        "Each name is a chapter in mixing: Norse settlement, Irish speech, English later — layers, not a single conquest.",
                    ],
                    "pairs": [
                        "Dubhlinn — the black pool → Dublin",
                        "Port Láirge — Irish name for Waterford, beside the Norse fjord-name",
                        "Loch Garman — Irish name for Wexford's inlet",
                    ],
                },
                {
                    "type": "typein",
                    "context": "Sigur writes the tally wrong: “Rinne me margadh le Sigur.”",
                    "prompt": "Correct it — mind *mé*.",
                    "placeholder": "Rinne mé margadh le Sigur",
                    "check": "exact",
                    "answer": "Rinne mé margadh le Sigur",
                    "fada": True,
                    "hint": "Rinne mé — I made — needs fada on mé.",
                },
                {
                    "type": "scene",
                    "beats": [
                        {
                            "n": "The deal closes. Sigur selects a thin arm-ring from the coil — hack-silver, ready to be cut to your weight."
                        },
                        {
                            "n": "“Tomorrow,” Ailbhe says, “it becomes yours — and we ask what the port towns left in the English you speak without thinking.”",
                        },
                    ],
                },
            ],
        },
        {
            "ga": "An Fáinne Airgid",
            "en": "Hack-silver — what the ports left behind",
            "hook": "A castle rises over a ford in the next valley. Chapter 4 waits — and the Normans speak Irish better than their grandfathers wanted.",
            "pages": [
                {
                    "type": "recarve",
                    "intro": "Last morning at the quay. Bran snaps at gulls. Sigur waits with shears and scales.",
                    "items": [
                        {
                            "answer": "Cheannaigh mé bróga anseo inné",
                            "en": "I bought shoes here yesterday",
                            "from": "Seisiún 3",
                        },
                        {
                            "answer": "Chuaigh mé go dtí an margadh",
                            "en": "I went to the market",
                            "from": "Seisiún 2",
                        },
                        {
                            "answer": "Chonaic mé an t-airgead",
                            "en": "I saw the silver",
                            "from": "Seisiún 4",
                        },
                        {
                            "answer": "Tá mé ag obair",
                            "en": "I am working — from the scriptorium, still true",
                            "from": "Caibidil 2",
                        },
                    ],
                },
                {
                    "type": "scene",
                    "place": "An margadh — closing trade",
                    "image": "ch3-silver",
                    "beats": [
                        {
                            "n": "Sigur cuts the ring — not a gift, a measure. Silver by weight, trust by handshake. He marks the cut with a tiny notch: your deal, your name, your weight in **airgead**."
                        },
                        {
                            "s": "Ghearr sé an fáinne dom.",
                            "who": "Ailbhe",
                            "g": "He cut the ring for me — *ghearr* = cut (past)",
                            "ph": "YAR shay un FAW-nyeh dum",
                        },
                        {
                            "s": "Is le {name} an fáinne seo.",
                            "who": "Sigur",
                            "g": "This ring belongs to {name} — identity with *is* again, for possession of the artifact",
                            "ph": "iss leh … un FAW-nyeh shuh",
                        },
                    ],
                },
                {
                    "type": "lens",
                    "en": "Dublin",
                    "ga": "Baile Átha Cliath",
                    "parts": [
                        {"ga": "baile", "en": "town / homestead"},
                        {"ga": "áth cliath", "en": "hurdled ford — the older Irish name for the crossing"},
                        {"ga": "Dubhlinn", "en": "the black pool — the Norse name for the same settlement"},
                    ],
                    "meaning": "two names, one town — Irish ford and Norse pool",
                    "note": "Look at any port you know: **–ford** in English often marks a Norse inlet; **Port–** in Irish names a harbour. Luimneach (Limerick), Port Láirge (Waterford), Loch Garman (Wexford) — palimpsests, not a single conquest.",
                },
                {
                    "type": "assemble",
                    "context": "Ailbhe prompts one last past-tense chain.",
                    "prompt": "Build: “The ships came from the north.”",
                    "tiles": ["ó thuaidh", "siad", "Tháinig", "na longa"],
                    "answer": "Tháinig na longa ó thuaidh",
                },
                {
                    "type": "typein",
                    "context": "Sigur chalks your tally: “Chonaic me an t-airgead.”",
                    "prompt": "Correct — mind *chonaic mé*.",
                    "placeholder": "Chonaic mé an t-airgead",
                    "check": "exact",
                    "answer": "Chonaic mé an t-airgead",
                    "fada": True,
                    "hint": "Chonaic mé — two words need fadas.",
                },
                {
                    "type": "scene",
                    "beats": [
                        {
                            "n": "The market thins. Norse and Irish part without ceremony — same mud, same river, same words tomorrow."
                        },
                        {
                            "s": "Ar scáth a chéile a mhaireann na daoine.",
                            "who": "Ailbhe",
                            "g": "People live in each other's shelter — the proverb of mixed towns",
                            "ph": "er SKAW ah KHAY-luh ah VWEER-un na DEE-neh",
                        },
                    ],
                },
                {
                    "type": "seanfhocal",
                    "ga": "Ar scáth a chéile a mhaireann na daoine.",
                    "en": "We live in each other's shelter.",
                    "note": "Not a Viking proverb — an Irish one for a Viking-Irish age. Dubhlinn survives because people traded, not only fought. Collected to your museum beside the scriptorium's unity.",
                },
                {
                    "type": "listen",
                    "context": "Ailbhe murmurs the proverb again as the quay empties.",
                    "prompt": "Which phrase did she say?",
                    "say": "Ar scáth a chéile a mhaireann na daoine",
                    "opts": [
                        {
                            "txt": "Ar scáth a chéile a mhaireann na daoine — we live in each other's shelter",
                            "ok": True,
                            "why": "The proverb Ailbhe spoke — shelter in each other.",
                        },
                        {
                            "txt": "Ní neart go cur le chéile",
                            "ok": False,
                            "why": "That was the scriptorium's unity proverb — different chapter, same idea of togetherness.",
                        },
                        {
                            "txt": "Cheannaigh mé bróga",
                            "ok": False,
                            "why": "You did buy shoes — but she spoke the proverb.",
                        },
                    ],
                },
                {
                    "type": "scene",
                    "place": "Baile Átha Cliath · an lá inniu",
                    "image": "ch3-today",
                    "beats": [
                        {
                            "n": "Walk Dublin's quays today and you walk Norse **longphort** logic in Irish paving. **Margadh** became market. **Pingin** became penny. **Bróg** became brogue — the shoe, then the accent, then the joke about how Irish English sounds."
                        },
                        {
                            "n": "Waterford, Wexford, Limerick — **port** towns whose names still carry inlet and fjord memory in English, while Irish kept its own names beside them: Port Láirge, Loch Garman, Luimneach."
                        },
                        {
                            "n": "You did not learn a foreign chapter. You learned words your English already borrowed — and Irish never stopped speaking.",
                        },
                    ],
                },
                {
                    "type": "artifact",
                },
                {
                    "type": "fin",
                    "paras": [
                        "**Caibidil a Ceathair — Na Normannaigh** is next: a castle over the ford at Áth Troim, a steward's daughter who speaks better Irish than her grandfather, and the grammar of what you have — *tá … agam*.",
                        "You're testing a prototype — after finishing, please tell us: what pulled you back, and what didn't? That answer shapes everything we build next.",
                    ],
                },
            ],
        },
    ],
    "visits": [
        {
            "id": "v-chonaic",
            "session": 0,
            "who": "Ailbhe",
            "where": "ar an bhfánaí",
            "frame": "Smoke is gone but she still wants your witness — what did you see on the horizon?",
            "en": "I saw smoke on the horizon",
            "answer": "Chonaic mé deatach ar an bhfánaí",
            "check": "exact",
        },
        {
            "id": "v-thainig",
            "session": 0,
            "who": "Ailbhe",
            "where": "ag an cladach",
            "frame": "The boy asks where the ships came from. Answer in the past.",
            "en": "The ships came from the north",
            "answer": "Tháinig na longa ó thuaidh",
            "check": "exact",
        },
        {
            "id": "v-chuaigh",
            "session": 1,
            "who": "Sigur",
            "where": "ag bealach an linne",
            "frame": "He asks how you reached the black pool — not where you're going, where you went.",
            "en": "I went to the black pool",
            "answer": "Chuaigh mé go dtí an linn dubh",
            "check": "exact",
        },
        {
            "id": "v-deis",
            "session": 1,
            "who": "Ailbhe",
            "where": "sa tsráid",
            "frame": "A barrel blocks the lane. She points — Téigh ar dheis, she says. Give the command back.",
            "en": "turn right",
            "answer": "Téigh ar dheis",
            "check": "exact",
        },
        {
            "id": "v-margadh",
            "session": 2,
            "who": "Sigur",
            "where": "ar an ché",
            "frame": "The market roars at dawn. Name it — the Norse loan Irish kept.",
            "en": "market",
            "answer": "margadh",
            "check": "exact",
        },
        {
            "id": "v-brog",
            "session": 2,
            "who": "Sigur",
            "where": "ag an stól",
            "frame": "He holds up the curled Norse shoe — the word that became brogue in English.",
            "en": "shoe — Norse loan",
            "answer": "bróg",
            "check": "exact",
        },
        {
            "id": "v-cheannaigh",
            "session": 3,
            "who": "Ailbhe",
            "where": "ag an scála",
            "frame": "The scales remember yesterday's boots. How did you buy them?",
            "en": "I bought shoes",
            "answer": "Cheannaigh mé bróga",
            "check": "exact",
        },
    ],
}

out = Path(__file__).resolve().parent / "draft.json"
out.write_text(json.dumps(chapter, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"Wrote {out} ({out.stat().st_size} bytes)")
