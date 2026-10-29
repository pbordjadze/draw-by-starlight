#!/usr/bin/env python3
"""Fetches each drawable constellation's story from Wikipedia, word for word, with its source.

    tools/wikipedia_stories.py > Sources/StarlightCore/Resources/stories.json

The app shows no text of its own about a constellation: what it says comes from the lead section
of the constellation's English Wikipedia article, quoted as it stands, under Wikipedia's license
(Creative Commons Attribution-ShareAlike 4.0), with a link to the article and to the exact
revision quoted. This writes `stories.json`: the license and the date, then one entry per
constellation of `FIRST_SET` (IAU abbreviation → article title) with the article's title, URL,
revision id and date, and the lead section as plain text.

It asks MediaWiki's action API for every article in one request, with a descriptive User-Agent, and
waits as long as a 429 answer's Retry-After says (Wikimedia's API etiquette; a shared address gets
about one request a minute); the REST summary endpoint rate-limits harder.
"""
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from datetime import date

FIRST_SET = {
    "Cas": "Cassiopeia (constellation)",
    "UMa": "Ursa Major",
    "Cyg": "Cygnus (constellation)",
    "Lyr": "Lyra",
    "Ori": "Orion (constellation)",
    "Leo": "Leo (constellation)",
    "Sco": "Scorpius",
    "Gem": "Gemini (constellation)",
    "Tau": "Taurus (constellation)",
    "Peg": "Pegasus (constellation)",
    "And": "Andromeda (constellation)",
    "Per": "Perseus (constellation)",
    "Boo": "Boötes",
    "Aql": "Aquila (constellation)",
    "Aur": "Auriga (constellation)",
    "CMa": "Canis Major",
}
API = "https://en.wikipedia.org/w/api.php"
USER_AGENT = "DrawByStarlight-stories/1.0 (https://github.com/pbordjadze/draw-by-starlight)"


def tidy(paragraph):
    """Plain-text extracts drop a pronunciation template's audio and IPA and leave its brackets
    behind ("Cassiopeia () is", "pronounced:  LY-rə"): the empty brackets and doubled spaces go,
    and nothing else changes."""
    text = re.sub(r"\(\s*\)", "", paragraph)
    text = re.sub(r"\s+([,;.])", r"\1", text)
    return re.sub(r" {2,}", " ", text).strip()


def fetch(titles):
    """The articles' pages, by the title asked for (redirects followed). At most 20 at once: the
    extracts module's limit for lead sections."""
    assert len(titles) <= 20
    query = urllib.parse.urlencode({
        "action": "query", "format": "json", "formatversion": "2", "redirects": "1",
        "prop": "extracts|info|revisions", "exintro": "1", "explaintext": "1", "exlimit": "20",
        "inprop": "url", "rvprop": "ids|timestamp", "titles": "|".join(titles),
    })
    request = urllib.request.Request(f"{API}?{query}", headers={"User-Agent": USER_AGENT})
    for attempt in range(6):
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                result = json.load(response)["query"]
            break
        except urllib.error.HTTPError as error:
            if error.code != 429 or attempt == 5:
                raise
            wait = int(error.headers.get("Retry-After", "60"))
            print(f"rate limited; waiting {wait} s", file=sys.stderr)
            time.sleep(wait + 1)
    asked = {r["to"]: r["from"] for r in result.get("redirects", [])}
    asked.update({r["to"]: r["from"] for r in result.get("normalized", [])})
    pages = {}
    for page in result["pages"]:
        if "missing" in page or not page.get("extract", "").strip():
            sys.exit(f"{page.get('title')}: no article text")
        revision = page["revisions"][0]
        pages[asked.get(page["title"], page["title"])] = {
            "title": page["title"],
            "url": page["canonicalurl"],
            "revision": revision["revid"],
            "revised": revision["timestamp"],
            "paragraphs": [tidy(p) for p in page["extract"].split("\n") if p.strip()],
        }
    return pages


def main():
    pages = fetch(list(FIRST_SET.values()))
    stories = {}
    for abbreviation, title in FIRST_SET.items():
        stories[abbreviation] = pages[title]
        print(f"{abbreviation}: {pages[title]['title']} r{pages[title]['revision']}, "
              f"{len(pages[title]['paragraphs'])} paragraphs", file=sys.stderr)
    json.dump({
        "source": "Wikipedia, The Free Encyclopedia",
        "license": "Creative Commons Attribution-ShareAlike 4.0 International",
        "licenseURL": "https://creativecommons.org/licenses/by-sa/4.0/",
        "retrieved": date.today().isoformat(),
        "stories": stories,
    }, sys.stdout, ensure_ascii=False, indent=1)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
