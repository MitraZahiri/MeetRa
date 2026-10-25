"""Builds docs/MeetRa-Saga-Bible.pdf from stories.py and worldmap.py.

Usage:  python docs/saga/build.py
Needs Microsoft Edge or Google Chrome (used headless to print the HTML to PDF).
"""

import html
import os
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from stories import AGES, CAST, PLACES, STORIES  # noqa: E402
from worldmap import build_map  # noqa: E402

HERE = Path(__file__).parent
OUT_HTML = HERE / "saga.html"
OUT_PDF = HERE.parent / "MeetRa-Saga-Bible.pdf"

e = html.escape

EPISODES = [
    ("Episode 1", "The Seven Trials", "15", "The game in development now"),
    ("Episode 2", "Origins of Ra", "9–14", "Prequel: Saena, Zev, the birth of Ra, Ember"),
    ("Episode 3", "Father and Son", "16–18", "The Copper Coast, the Seven Hunters, Sorin"),
    ("Episode 4", "The Prince of Fire", "19–22", "Aven, the garden city, Corin's return, Prince Fen"),
    ("Episode 5", "The Long War", "23–28", "Sieges, the Whirlwind Ogre, the Stone Pit, the Twelve Duels, the Dusk Khan's end"),
    ("Episode 6", "The Bronze Prince", "29–33", "Prince Aspen, the Tamarisk Arrow, the death of Ra"),
    ("Prologue pack", "The Age of First Kings", "1–8", "Short mythic levels; can ship free as a demo"),
    ("Anthology", "The Age of Crowns", "34–44", "Episodic chapters with new heroes and mini-games"),
]

MECHANICS = [
    ("Animal ally calls", 1), ("Hearths (checkpoints)", 2), ("Binding enemies · Script Stones", 3), ("Aura resource", 4),
    ("Stealth and hiding", 5), ("Ox-Head Mace · rallying allies", 6), ("World map", 7), ("War Horn shockwave", 8),
    ("Saena's Feather", 9), ("Rope climbing", 10), ("Hub village", 11), ("Disguise", 12), ("Horse riding · fast travel", 13),
    ("Grab and throw", 14), ("Ember Burst · Lasso · Truthlight", 15), ("Swimming · tides", 16), ("Hero swap", 17),
    ("Fire resistance", 19), ("Seasons in open regions", 21), ("Bow aiming (drag to aim)", 22), ("Branching by choice", 24),
    ("Two-character puzzles", 25), ("Arena mode", 26), ("New Game+", 31), ("Rafting", 34), ("Formation commands", 35),
    ("Darkness navigation by sound", 36), ("Polo (local multiplayer)", 38), ("Rhythm mini-game", 39), ("Reputation", 40),
    ("Board-game mini-games", 41), ("Troop orders", 42),
]


def card(s):
    return f"""
<article class="card">
  <header>
    <div class="num">{s['n']}</div>
    <div class="titles">
      <h3>{e(s['chapter'])}</h3>
      <p class="source">Shahnameh source: <b>{e(s['source'])}</b></p>
    </div>
  </header>
  <div class="chips">
    <span class="chip"><i>Region</i>{e(s['where'])}</span>
    <span class="chip"><i>Play</i>{e(s['play'])}</span>
    <span class="chip"><i>Map pin</i>{s['n']}</span>
  </div>
  <div class="story"><h4>The story</h4><p>{e(s['summary'])}</p></div>
  <h4>The MeetRa chapter</h4>
  <p>{e(s['scenario'])}</p>
  <div class="two">
    <div><h4>Boss / set piece</h4><p>{e(s['boss'])}</p></div>
    <div><h4>Earns</h4><p>{e(s['reward'])}</p></div>
  </div>
</article>"""


def build_html():
    ages_html = ""
    for age in AGES:
        cards = "".join(card(s) for s in STORIES if s["age"] == age["id"])
        nums = [s["n"] for s in STORIES if s["age"] == age["id"]]
        first, last = nums[0], nums[-1]
        ages_html += f"""
<section class="age">
  <div class="age-head">
    <div class="ornament">✦ ✦ ✦</div>
    <h2>{e(age['title'])}</h2>
    <p class="range">Chapters {first}–{last}</p>
    <p class="age-intro">{e(age['intro'])}</p>
  </div>
  {cards}
</section>"""

    toc_rows = "".join(
        f"<tr><td class='n'>{s['n']}</td><td><b>{e(s['chapter'])}</b></td><td>{e(s['source'])}</td><td>{e(s['where'])}</td></tr>"
        for s in STORIES
    )
    cast_rows = "".join(f"<tr><td>{e(a)}</td><td><b>{e(b)}</b></td></tr>" for a, b in CAST)
    place_rows = "".join(f"<tr><td>{e(a)}</td><td><b>{e(b)}</b></td></tr>" for a, b in PLACES)
    ep_rows = "".join(f"<tr><td><b>{e(a)}</b></td><td>{e(b)}</td><td class='n'>{c}</td><td>{e(d)}</td></tr>" for a, b, c, d in EPISODES)
    mech_rows = "".join(f"<tr><td>{e(m)}</td><td class='n'>{n}</td></tr>" for m, n in MECHANICS)

    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<title>MeetRa Saga Bible</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@500;700&family=EB+Garamond:ital,wght@0,400;0,600;1,400&display=swap" rel="stylesheet">
<style>
  @page {{ size: A4; margin: 16mm 15mm 18mm; @bottom-center {{ content: counter(page); }} }}
  @page map {{ size: A4 landscape; margin: 8mm; }}
  @page cover {{ margin: 0; }}
  :root {{ --lapis:#1b2a6b; --gold:#b8892e; --gold2:#d4a845; --red:#a8322a; --ink:#2b1f14; --parch:#f6ecd2; --turq:#2bb3a8; }}
  * {{ box-sizing: border-box; }}
  html {{ -webkit-print-color-adjust: exact; print-color-adjust: exact; }}
  body {{ margin:0; font-family:'EB Garamond', Georgia, serif; font-size:10.6pt; line-height:1.38; color:var(--ink); }}
  h1, h2, h3, h4, .region, .city, .pin, .trial, .carto {{ font-family:'Cinzel', Georgia, serif; }}
  h2 {{ color:var(--lapis); font-size:22pt; margin:0 0 4pt; letter-spacing:.04em; }}
  h3 {{ margin:0; font-size:13.5pt; color:var(--lapis); letter-spacing:.02em; }}
  h4 {{ margin:7pt 0 2pt; font-size:8.6pt; letter-spacing:.12em; text-transform:uppercase; color:var(--gold); }}
  p {{ margin:0 0 4pt; }}
  table {{ width:100%; border-collapse:collapse; font-size:9.4pt; }}
  th {{ text-align:left; font-family:'Cinzel', serif; font-size:8.5pt; letter-spacing:.08em; color:#fff; background:var(--lapis); padding:4pt 6pt; }}
  td {{ padding:3pt 6pt; border-bottom:1px solid #e5d6b3; vertical-align:top; }}
  tr:nth-child(even) td {{ background:#fbf6ea; }}
  td.n {{ text-align:center; font-weight:600; color:var(--red); width:34pt; }}

  /* Cover */
  .cover {{ page: cover; height:297mm; width:210mm; position:relative; background:var(--lapis); color:var(--parch); overflow:hidden; break-after:page; }}
  .cover .frame {{ position:absolute; inset:12mm; border:3px solid var(--gold2); outline:1px solid var(--turq); outline-offset:-9px; }}
  .cover .sun {{ position:absolute; left:50%; top:62mm; transform:translateX(-50%); width:70mm; height:70mm; border-radius:50%;
     background:radial-gradient(circle, #f7d774 0 52%, transparent 53%), repeating-conic-gradient(#d4a845 0 6deg, transparent 6deg 22.5deg);
     -webkit-mask: radial-gradient(circle, #000 0 70%, transparent 71%); mask: radial-gradient(circle, #000 0 70%, transparent 71%); }}
  .cover .title {{ position:absolute; top:146mm; width:100%; text-align:center; }}
  .cover h1 {{ font-size:56pt; margin:0; color:#f7d774; letter-spacing:.06em; }}
  .cover .sub1 {{ font-family:'Cinzel', serif; font-size:17pt; letter-spacing:.2em; margin-top:2mm; }}
  .cover .sub2 {{ font-style:italic; font-size:14pt; margin-top:10mm; color:#e9dcbc; }}
  .cover .foot {{ position:absolute; bottom:24mm; width:100%; text-align:center; font-size:11pt; color:#c9bd9c; letter-spacing:.08em; }}

  .page {{ break-after:page; }}
  .lead {{ font-size:12pt; }}
  .rule {{ border:1px solid #e1cf9f; background:#fbf6ea; border-left:5px solid var(--gold); padding:8pt 10pt; margin:8pt 0; }}
  .cols {{ display:grid; grid-template-columns:1fr 1fr; gap:14pt; }}

  /* Map */
  .mappage {{ page: map; break-before:page; break-after:page; height:190mm; display:flex; flex-direction:column; }}
  .mappage h2 {{ font-size:15pt; margin:0 0 2mm; text-align:center; }}
  .worldmap {{ width:100%; height:182mm; display:block; }}
  .worldmap .region {{ text-anchor:middle; fill:#3b2a1a; letter-spacing:.18em; font-weight:700; paint-order:stroke; stroke:#f3e6c6; stroke-width:5px; stroke-linejoin:round; }}
  .worldmap .sub {{ paint-order:stroke; stroke:#f3e6c6; stroke-width:4px; }}
  .worldmap {{ overflow:hidden; }}
  .index td {{ padding:1.1pt 5pt; font-size:8.4pt; line-height:1.25; }}
  .worldmap .sub {{ text-anchor:middle; font-family:'EB Garamond', serif; font-style:italic; font-size:14px; fill:#5a4630; }}
  .worldmap .city {{ text-anchor:middle; font-size:15px; font-weight:700; fill:#1b2a6b; paint-order:stroke; stroke:#f6ecd2; stroke-width:4px; }}
  .worldmap .pin {{ text-anchor:middle; font-size:12px; font-weight:700; fill:#1b2a6b; }}
  .worldmap .trial {{ text-anchor:middle; font-size:10px; font-weight:700; fill:#fbf3df; }}
  .worldmap .carto {{ text-anchor:middle; font-weight:700; fill:#1b2a6b; letter-spacing:.12em; }}
  .worldmap .legend {{ font-family:'EB Garamond', serif; font-size:16px; fill:#3b2a1a; }}

  /* Ages and cards */
  .age-head {{ break-before:page; text-align:center; padding:6mm 0 4mm; margin-bottom:5mm; border-bottom:2px solid var(--gold2); }}
  .ornament {{ color:var(--gold); letter-spacing:.6em; font-size:12pt; }}
  .range {{ font-family:'Cinzel', serif; color:var(--red); letter-spacing:.15em; font-size:9pt; margin:0; }}
  .age-intro {{ font-style:italic; font-size:11.5pt; max-width:150mm; margin:3mm auto 0; }}
  .card {{ break-inside:avoid; border:1px solid #dcc79a; border-radius:5pt; padding:9pt 11pt 7pt; margin:0 0 9pt; background:#fffdf7; }}
  .card header {{ display:flex; gap:9pt; align-items:center; border-bottom:1px solid #eadcb9; padding-bottom:5pt; }}
  .num {{ flex:none; width:30pt; height:30pt; border-radius:50%; background:var(--lapis); color:#f7d774; font-family:'Cinzel', serif;
          font-weight:700; font-size:13pt; display:flex; align-items:center; justify-content:center; border:2px solid var(--gold2); }}
  .source {{ margin:1pt 0 0; font-size:9.6pt; color:#6a5538; font-style:italic; }}
  .chips {{ display:flex; flex-wrap:wrap; gap:4pt; margin:6pt 0 2pt; }}
  .chip {{ font-size:8.6pt; background:#f1e6cb; border-radius:9pt; padding:1pt 7pt; }}
  .chip i {{ font-style:normal; color:var(--gold); font-family:'Cinzel', serif; font-size:7.4pt; letter-spacing:.08em; margin-right:4pt; text-transform:uppercase; }}
  .story {{ background:#f5eedd; border-left:3px solid var(--turq); padding:3pt 8pt 2pt; margin:6pt 0 0; font-size:9.8pt; }}
  .story h4 {{ color:#1f8a82; margin-top:3pt; }}
  .two {{ display:grid; grid-template-columns:1fr 1fr; gap:12pt; }}
  .appendix h2 {{ break-before:page; }}
</style></head>
<body>

<section class="cover">
  <div class="frame"></div>
  <div class="sun"></div>
  <div class="title">
    <h1>MeetRa</h1>
    <div class="sub1">THE SAGA BIBLE</div>
    <div class="sub2">Game scenarios for every story of the Book of Kings,<br>and the map of the Realm of the Dawnfire</div>
  </div>
  <div class="foot">Design document · v1.0 · 2026</div>
</section>

<section class="page">
  <h2>How to Read This Book</h2>
  <p class="lead">The <i>Shahnameh</i> (the Book of Kings), finished by Ferdowsi around 1010, tells the story of the world from the first
  king to the last. It holds dozens of stories that already work like video game chapters: a hero, a journey, a monster, a reward.</p>
  <p>This document turns <b>each major story</b> into a playable <b>MeetRa chapter</b>. There are {len(STORIES)} chapters in three books:</p>
  <table>
    <tr><th>Book</th><th>Chapters</th><th>Role in MeetRa</th></tr>
    <tr><td><b>I · The Age of First Kings</b></td><td class="n">1–8</td><td>Mythic prologue: fire, iron, the Serpent King</td></tr>
    <tr><td><b>II · The Age of Heroes</b></td><td class="n">9–33</td><td>The main campaign around Ra, Ember and Saena. Includes the Seven Trials.</td></tr>
    <tr><td><b>III · The Age of Crowns</b></td><td class="n">34–44</td><td>Episodic chapters with new heroes after Ra</td></tr>
  </table>
  <div class="rule"><b>The breeze rule.</b> MeetRa is inspired by the Shahnameh; it does not retell it. Inside the game every person and place
  has an <b>original name</b> (Ra, Saena, the Dusk Khan, Crownhold...). The original Shahnameh names appear only in the grey
  "Source" lines of this book, so the team can see where each idea comes from. Full lists are in the appendix.</div>
  <h4>Every chapter card shows</h4>
  <table>
    <tr><td><b>The story</b></td><td>A short summary of the Shahnameh story the chapter is based on</td></tr>
    <tr><td><b>The MeetRa chapter</b></td><td>What the player does: setting, level beats, twist</td></tr>
    <tr><td><b>Boss / set piece</b></td><td>The climax of the chapter</td></tr>
    <tr><td><b>Earns</b></td><td>The new mechanic, item or mode it adds to the game</td></tr>
    <tr><td><b>Map pin</b></td><td>Where it happens on the world map (next page)</td></tr>
  </table>
  <h4>Release plan</h4>
  <table><tr><th>Release</th><th>Title</th><th>Chapters</th><th>Contents</th></tr>{ep_rows}</table>
</section>

<section class="mappage">
  <h2>The Realm of the Dawnfire</h2>
  {build_map()}
</section>

<section class="page">
  <h2>Chapter Index</h2>
  <table class="index"><tr><th>#</th><th>MeetRa chapter</th><th>Shahnameh source</th><th>Region</th></tr>{toc_rows}</table>
</section>

{ages_html}

<section class="appendix">
  <h2>Appendix A · Cast</h2>
  <p>Shahnameh name (for reference only) and the original MeetRa name used in the game.</p>
  <table><tr><th>Shahnameh</th><th>MeetRa</th></tr>{cast_rows}</table>
  <h2>Appendix B · Places and Mechanics</h2>
  <div class="cols">
    <div><h4>Places</h4><table><tr><th>Shahnameh</th><th>MeetRa map</th></tr>{place_rows}</table></div>
    <div><h4>Where each mechanic is introduced</h4><table><tr><th>Mechanic</th><th>Ch.</th></tr>{mech_rows}</table></div>
  </div>
</section>

</body></html>"""


def find_browser():
    for p in [
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    ]:
        if os.path.exists(p):
            return p
    return shutil.which("msedge") or shutil.which("chrome") or shutil.which("google-chrome")


def main():
    OUT_HTML.write_text(build_html(), encoding="utf-8")
    browser = find_browser()
    if not browser:
        sys.exit("Edge or Chrome is needed to print the PDF. The HTML is at " + str(OUT_HTML))
    profile = HERE / ".browser-profile"
    subprocess.run(
        [browser, "--headless", "--disable-gpu", f"--user-data-dir={profile}", "--no-pdf-header-footer",
         "--virtual-time-budget=15000", f"--print-to-pdf={OUT_PDF}", OUT_HTML.resolve().as_uri()],
        check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=180,
    )
    shutil.rmtree(profile, ignore_errors=True)
    print("Wrote", OUT_PDF)


if __name__ == "__main__":
    main()
