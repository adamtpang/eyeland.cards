"""Read Adam's club from FUTBIN My Club (read-only, through the Helium bridge) and report on it.

  python club_report.py            refresh from FUTBIN, save club_futbin.json, write club-report.md
  python club_report.py --offline  report from the saved club_futbin.json

Needs Adam's FUTBIN club import (EA-licensed, re-import hourly) and the bridge on port 9333.
It only reads pages. It never touches EA, the web app or the market.
"""
import json
import os
import re
import sys
import time
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
CLUB = os.path.join(HERE, "club_futbin.json")
REPORT = os.path.join(HERE, "club-report.md")
TAB_FILE = os.path.join(HERE, "futbin_tab.txt")
# Gitignored notes FUTBIN cannot know, e.g. {"loans": ["Hazard"]}. Loan players are never suggested.
NOTES = os.path.join(HERE, "club_notes.json")
POSITIONS = ["GK", "RB", "CB", "LB", "CDM", "CM", "CAM", "RM", "LM", "RW", "LW", "ST"]
GOOD = 80.0  # FUTBIN rating a player needs to count as real depth

ROWS_JS = r"""JSON.stringify(Array.from(document.querySelectorAll('tbody tr')).map(r => {
  const spot = r.querySelector('[hx-get*="playerspotlight"]');
  const t = a => { const i = r.querySelector('img[alt="' + a + '"]'); return i ? i.title : ''; };
  const cells = Array.from(r.querySelectorAll('td')).map(td => td.innerText.replace(/\s+/g, ' ').trim());
  return {spot: spot ? spot.getAttribute('hx-get') : '', nation: t('Nation'), league: t('League'), club: t('Club'),
          version: (r.querySelector('.table-player-revision') || {}).innerText || '', cells};
}))"""

SPOT_JS = r"""(async (urls) => {
  const out = {};
  const one = async u => {
    const d = new DOMParser().parseFromString(await (await fetch(u)).text(), 'text/html');
    const main = d.querySelector('.playercard-27-position');
    const alts = Array.from(new Set(Array.from(d.querySelectorAll('.playercard-27-alt-pos-sub')).map(e => e.textContent.trim())));
    const stats = {};
    for (const k of ['Pac', 'Sho', 'Pas', 'Dri', 'Def', 'Phy', 'Div', 'Han', 'Kic', 'Ref', 'Spd', 'Pos']) {
      const m = d.body.innerText.match(new RegExp('(\\d+)' + k));
      if (m) stats[k.toLowerCase()] = +m[1];
    }
    out[u] = {main: main ? main.textContent.trim() : '', alts, stats};
  };
  for (let i = 0; i < urls.length; i += 6) await Promise.all(urls.slice(i, i + 6).map(one));
  return JSON.stringify(out);
})(%s)"""


def num(text):
    m = re.match(r"([\d.,]+)\s*([KM]?)", (text or "").replace(",", ""))
    return int(float(m.group(1)) * {"": 1, "K": 1e3, "M": 1e6}[m.group(2)]) if m else 0


def tab():
    import cdp
    tid = open(TAB_FILE).read().strip() if os.path.exists(TAB_FILE) else ""
    try:
        return cdp, tid, cdp.attach(tid)
    except Exception:  # noqa: BLE001  the tab was closed: open a background one
        tid = cdp.call("Target.createTarget", {"url": "about:blank", "background": True})["targetId"]
        open(TAB_FILE, "w").write(tid)
        return cdp, tid, cdp.attach(tid)


def evaluate(cdp, sid, js, wait=False):
    r = cdp.call("Runtime.evaluate", {"expression": js, "returnByValue": True, "awaitPromise": wait}, session=sid)
    return r["result"].get("value")


def refresh():
    cdp, tid, sid = tab()
    cdp.call("Page.navigate", {"url": "https://www.futbin.com/27/my-club"}, session=sid)
    time.sleep(7)
    overview = evaluate(cdp, sid, "document.body.innerText") or ""
    if "Import:" not in overview:
        raise SystemExit("FUTBIN My Club is not available: log in to FUTBIN in Helium and import your club.")
    imported = re.search(r"Import:\s*([\d.]+)\s*([\d:]+\s*[AP]M)", overview)
    lineup = overview[overview.find("Tactic"):overview.find("WHOLE CLUB")]
    xi = re.findall(r"\n(\d{2})\n([A-Z]{2,3})\n(?:\+\+\n)?([^\n]+)\n\2", lineup)
    cdp.call("Page.navigate", {"url": "https://www.futbin.com/27/my-club/club-players"}, session=sid)
    time.sleep(7)
    rows = json.loads(evaluate(cdp, sid, ROWS_JS) or "[]")
    spots = json.loads(evaluate(cdp, sid, SPOT_JS % json.dumps([r["spot"] for r in rows if r["spot"]]), wait=True) or "{}")
    players = []
    for r in rows:
        c = r["cells"]
        fr = re.match(r"([\d.]+)\s+(\S+)\s*-?\s*(.*)", c[7] or "")
        s = spots.get(r["spot"], {})
        players.append({
            "name": re.sub(r"\s+" + re.escape(r["version"]) + "$", "", c[1]).strip() if r["version"] else c[1],
            "version": r["version"], "rating": int(c[0]), "item_score": num(c[3]),
            "pos": s.get("main") or c[4].replace("+", ""), "alts": s.get("alts", []),
            "futbin": float(fr.group(1)) if fr else None, "best_pos": fr.group(2) if fr else "", "role": fr.group(3) if fr else "",
            "skills": int(c[9] or 0), "weak_foot": int(c[10] or 0),
            "games": int(c[11] or 0), "goals": int(c[12] or 0), "assists": int(c[13] or 0),
            "price_pc": num(c[6]), "tradeable": c[15] != "Untradeable",
            "nation": r["nation"], "league": r["league"], "club": r["club"], "stats": s.get("stats", {}),
        })
    data = {"imported": " ".join(imported.groups()) if imported else "", "read": time.strftime("%Y-%m-%d %H:%M"),
            "xi": [{"rating": int(a), "pos": b, "name": n.strip()} for a, b, n in xi], "players": players}
    json.dump(data, open(CLUB, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    return data


def can_play(p, pos):
    return pos == p["pos"] or pos in p["alts"]


def report(data):
    notes = json.load(open(NOTES, encoding="utf-8")) if os.path.exists(NOTES) else {}
    loans = [n.lower() for n in notes.get("loans", [])]
    for p in data["players"]:
        p["loan"] = any(n in p["name"].lower() for n in loans)
    players = [p for p in data["players"] if not p["loan"]]
    by_name = {p["name"]: p for p in players}
    xi = []
    for slot in data["xi"]:
        match = next((p for p in data["players"] if slot["name"] in p["name"] or p["name"].endswith(slot["name"])), None)
        xi.append((slot["pos"], match))
    xi_names = {p["name"] for _, p in xi if p}
    lines = [f"# Club report", "", f"FUTBIN import {data['imported']}, read {data['read']}. "
             f"{len(players)} players (loans left out: {', '.join(notes.get('loans', [])) or 'none'}), "
             f"{sum(p['tradeable'] for p in players)} tradeable.", ""]

    lines += ["## Starting XI", "", "| Slot | Player | FUTBIN | Best upgrade in club |", "|---|---|---|---|"]
    gaps = []
    for pos, p in xi:
        if not p:
            continue
        better = sorted((q for q in players if q["name"] not in xi_names and can_play(q, pos) and (q["futbin"] or 0) > (p["futbin"] or 0)),
                        key=lambda q: -(q["futbin"] or 0))
        up = f"{better[0]['name']} {better[0]['futbin']}" if better else "none"
        if better:
            gaps.append((better[0]["futbin"] - (p["futbin"] or 0), pos, p, better[0]))
        lines.append(f"| {pos} | {p['name']} {p['rating']} | {p['futbin']} | {up} |")
    lines += ["", "## Free upgrades (bench player better than the starter in that slot)", ""]
    for gain, pos, p, q in sorted(gaps, key=lambda g: -g[0]):
        lines.append(f"- **{pos}:** {q['name']} ({q['futbin']}) over {p['name']} ({p['futbin']}), +{gain:.1f}")
    if not gaps:
        lines.append("- None: every starter is the best you own for that slot.")

    lines += ["", f"## Depth by position (players rated {GOOD:.0f}+ by FUTBIN who can play it)", "",
              "| Position | Depth | Best options |", "|---|---|---|"]
    thin = []
    for pos in POSITIONS:
        able = sorted((p for p in players if can_play(p, pos) and (p["futbin"] or 0) >= GOOD), key=lambda p: -(p["futbin"] or 0))
        if pos == "GK":
            able = [p for p in players if p["pos"] == "GK"]
        lines.append(f"| {pos} | {len(able)} | {', '.join(f'{p['name']} {p['futbin']}' for p in able[:4]) or '-'} |")
        if len(able) <= 1:
            thin.append(pos)
    lines += ["", f"**Thinnest:** {', '.join(thin) or 'none'}.", ""]

    weakest = sorted((p for _, p in xi if p and p["futbin"]), key=lambda p: p["futbin"])[:3]
    lines += ["## Weakest starters (the next card to buy should replace one of these)", ""]
    lines += [f"- {p['name']} ({p['pos']}, FUTBIN {p['futbin']}, {p['games']} games, {p['goals']} goals)" for p in weakest]
    open(REPORT, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    report(json.load(open(CLUB, encoding="utf-8")) if "--offline" in sys.argv else refresh())
