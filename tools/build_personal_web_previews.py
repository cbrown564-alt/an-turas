#!/usr/bin/env python3
"""Generate crawlable, source-visible pages from the gated public payload."""

from __future__ import annotations

import argparse
import html
import json
from pathlib import Path
from urllib.parse import quote


STYLE = """
:root{color-scheme:light dark;--bg:#ecede7;--raised:#f7f7f2;--ink:#23281f;--soft:#5a6153;--moss:#4c6647;--line:#cbcec1}
@media(prefers-color-scheme:dark){:root{--bg:#131714;--raised:#1c211c;--ink:#d9dcd1;--soft:#aeb5a8;--moss:#95b28b;--line:#3d453d}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:17px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}
main{width:min(100% - 40px,680px);margin:auto;padding:56px 0 72px}h1,h2{font-family:"New York",Georgia,serif;text-wrap:balance}h1{font-size:clamp(2rem,8vw,3.8rem);line-height:1.08;letter-spacing:-.025em;margin:.2rem 0 1rem}h2{font-size:1.35rem;margin:2.2rem 0 .6rem}p{max-width:68ch;text-wrap:pretty}.context,a{color:var(--moss)}.soft{color:var(--soft)}.claim{padding:18px 0;border-top:1px solid var(--line)}.evidence{padding:14px;background:var(--raised);border-radius:10px}a{min-height:44px;display:inline-flex;align-items:center;font-weight:650}@media(prefers-reduced-motion:reduce){*{scroll-behavior:auto!important;transition:none!important}}
""".strip()


def render(subject: dict, attribution: str) -> str:
    subject_id = subject["id"]
    canonical = f"https://anturas.ie/personal-atlas/subjects/{quote(subject_id)}/"
    app_link = f"anturas://personal/{quote(subject_id)}"
    evidence_by_id = {item["id"]: item for item in subject["evidence"]}
    claims = []
    for claim in subject["assertions"]:
        evidence = []
        for evidence_id in claim["evidenceIds"]:
            item = evidence_by_id[evidence_id]
            link = ""
            if item.get("stableURL"):
                link = f' <a href="{html.escape(item["stableURL"], quote=True)}" rel="noreferrer">Open source</a>'
            evidence.append(
                f"<li>{html.escape(item['citation'])}{link}</li>"
            )
        claims.append(
            f"""<section class="claim"><h2>{html.escape(claim['statement'])}</h2>
            <p class="soft">{html.escape(claim['certainty'])} · {html.escape(claim['scope'])}</p>
            <div class="evidence"><ul>{''.join(evidence)}</ul>
            <p class="soft">Reviewed {html.escape(claim['reviewedAt'])} by {html.escape(claim['reviewer'])}. Rights: {html.escape(claim['rightsState'])}.</p></div></section>"""
        )
    title = html.escape(subject["canonicalDisplay"])
    description = html.escape(subject["editorial"]["shortAnswer"], quote=True)
    return f"""<!doctype html><html lang="en"><head><meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="index,follow">
    <meta name="description" content="{description}"><link rel="canonical" href="{canonical}">
    <title>{title} — An Turas personal atlas</title><style>{STYLE}</style></head><body><main>
    <p class="context">{'A name you carry' if subject['kind']=='name' else 'A place you know'}</p>
    <h1>{title}</h1><p class="soft">{html.escape(subject['subtitle'])}</p>
    <p>{html.escape(subject['editorial']['shortAnswer'])}</p>
    <p><a href="{app_link}">Open this sourced page in An Turas</a></p>
    {''.join(claims)}
    <h2>Limits</h2><p>This page explains documented forms and reviewed interpretations. It does not infer a family tree, ancestry, ownership, or a personal migration route.</p>
    <p class="soft">Content version {html.escape(subject['editorial']['contentVersion'])} · {html.escape(attribution)}</p>
    </main></body></html>"""


def build(source: dict, output: Path) -> list[str]:
    urls = []
    for subject in source.get("subjects", []):
        destination = output / "subjects" / subject["id"] / "index.html"
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(
            render(subject, source["attribution"]), encoding="utf-8"
        )
        urls.append(
            f"https://anturas.ie/personal-atlas/subjects/{quote(subject['id'])}/"
        )
    sitemap = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">" + "".join(
        f"<url><loc>{html.escape(url)}</loc></url>" for url in urls
    ) + "</urlset>\n"
    output.mkdir(parents=True, exist_ok=True)
    (output / "sitemap.xml").write_text(sitemap, encoding="utf-8")
    return urls


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    source = json.loads(args.source.read_text(encoding="utf-8"))
    urls = build(source, args.output)
    print(f"Generated {len(urls)} crawlable personal-atlas previews")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
