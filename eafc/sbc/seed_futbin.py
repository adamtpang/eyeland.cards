"""Seed a solve from FUTBIN's cheapest community squad for an SBC, so our result can only
match or beat it. Reads FUTBIN only (the SBC page, the squad page, and a player page for
any card not already cached). Writes result.json in the fixed formation, then improves
it with our own single and pair swaps.

  python seed_futbin.py sbcs/5-leagues-6-nations.json <futbin challenge url> [--club club.json] [--exclude "A,B"]
"""
import json
import os
import re
import sys
import time

import cdp
import futbin
import optimize as o
from solve import check, chemistry, cost, improve, player_chem, rating

HERE = os.path.dirname(os.path.abspath(__file__))
POSITIONS = {"GK", "RB", "LB", "CB", "RWB", "LWB", "CDM", "CM", "CAM", "RM", "LM", "RW", "LW", "ST", "CF"}


def page_text(sid, url, want):
    futbin.front()
    cdp.call("Page.navigate", {"url": url}, sid)
    for _ in range(20):
        time.sleep(1.5)
        t = cdp.evaluate(sid, "document.body.innerText") or ""
        if want in t:
            return t
    return ""


def cheapest_squad_url(sid, challenge_url):
    page_text(sid, challenge_url, "Community Squad")
    return cdp.evaluate(sid, r"""(()=>{const a=[...document.querySelectorAll('a[href*="/squad/"]')]
      .find(a=>/Cheapest/.test(a.closest('tr')?a.closest('tr').innerText:a.innerText));
      return a?a.getAttribute('href'):null})()""")


def squad_cards(sid, squad_url):
    page_text(sid, "https://www.futbin.com" + squad_url, "PAC")
    rows = json.loads(cdp.evaluate(sid, r"""JSON.stringify([...document.querySelectorAll('.playercard-field')].map(c=>{
      const a=c.querySelector('a[href*="/27/player/"]');return {href:a&&a.getAttribute('href'),
      txt:(c.innerText||'').replace(/\s+/g,' ')}}).filter(r=>r.href))"""))
    out = []
    for r in rows:
        toks = r["txt"].split()
        price = int(toks[0].replace(",", "")) if toks and toks[0].replace(",", "").isdigit() else 0
        # "<price> <score> <rating> <POS> <POS> ..." ; the rating is the first 2-digit token after price/score
        rating_i = next(i for i in range(2, len(toks)) if toks[i].isdigit() and 40 <= int(toks[i]) <= 99)
        pos = []
        for t in toks[rating_i + 1:]:
            if t in POSITIONS:
                pos.append(t)
            else:
                break
        out.append({"href": r["href"], "id": r["href"].split("/")[3], "price": price,
                    "rating": int(toks[rating_i]), "pos": pos})
    return out


def details(sid, card):
    page_text(sid, "https://www.futbin.com" + card["href"], "current price")
    info = json.loads(cdp.evaluate(sid, r"""JSON.stringify(Object.fromEntries(['Nation','League','Club']
      .map(k=>{const i=document.querySelector('img[alt='+k+']');return [k,i?i.title:'']})))"""))
    card.update(nation=info["Nation"], league=info["League"], club=info["Club"],
                name=card["href"].rstrip("/").split("/")[-1].replace("-", " ").title())
    time.sleep(3)
    return card


def main():
    spec_path, url = sys.argv[1], sys.argv[2]
    club_path = sys.argv[sys.argv.index("--club") + 1] if "--club" in sys.argv else None
    excl = [e.strip().lower() for e in (sys.argv[sys.argv.index("--exclude") + 1]
            if "--exclude" in sys.argv else "").split(",") if e.strip()]
    spec = json.load(open(spec_path, encoding="utf-8"))
    slots, req = spec["formation"].split(), spec["requirements"]
    sid = futbin.session()
    squad_url = cheapest_squad_url(sid, url)
    if not squad_url:
        raise SystemExit("no community squad found on the SBC page")
    cards = squad_cards(sid, squad_url)
    print(f"FUTBIN cheapest squad {squad_url}: {len(cards)} cards, {sum(c['price'] for c in cards):,} coins")
    pool = o.build_pool(spec, 1, set())
    by_id = {p["id"]: p for p in pool}
    seed = []
    for c in cards:
        known = by_id.get(c["id"])
        seed.append(dict(known, price=c["price"], pos=c["pos"] or known["pos"]) if known else details(sid, c))
    for p in seed:
        by_id[p["id"]] = p
    pool = list(by_id.values())
    # fit the 11 seed cards into the fixed formation's slots
    m = o.build_model(slots, req, seed)
    placed, st = o.solve_at(m, slots, req, None, 60)
    if not placed or not check(placed, slots, req):
        raise SystemExit("could not fit FUTBIN's squad to our formation/rules; check the spec")
    print(f"seed fits: {cost(placed):,} coins, rating {rating(placed)}, chem {chemistry(placed, slots)}")
    if club_path:
        for p in json.load(open(club_path, encoding="utf-8")):
            if p["role"] == "spare" and p["rating"] < 75 and not any(e in p["name"].lower() for e in excl):
                pool.append({"id": f"club{p['itemId']}", "href": "", "name": p["name"] + " (CLUB)",
                             "rating": p["rating"], "pos": p["pos"], "nation": p["nation"],
                             "league": o.EA_LEAGUE.get(p["leagueId"], p["league"]),
                             "club": p["club"], "price": 0, "mine": True})
    pool = [p for p in pool if not any(e in p["name"].lower() for e in excl)]
    better = improve(placed, slots, req, [p for p in pool if p["price"] or p.get("mine")])
    print(f"after our swaps: {cost(better):,} coins, rating {rating(better)}, chem {chemistry(better, slots)}")
    pc = player_chem(better, slots)
    rows = [{"slot": s, "chem": pc[i], "card": p,
             "swaps": [] if p.get("mine") else o.ready_swaps(better, slots, req, pool, i)}
            for i, (s, p) in enumerate(zip(slots, better))]
    json.dump({"sbc": spec["name"], "formation": spec["formation"], "coins": o.coins_of(better),
               "rating": rating(better), "chemistry": chemistry(better, slots),
               "verdict": f"FUTBIN cheapest community squad improved by our swaps (seed {cost(placed):,})",
               "slots": rows}, open(os.path.join(HERE, "result.json"), "w", encoding="utf-8"),
              ensure_ascii=False, indent=1)
    for r in rows:
        c = r["card"]
        print(f"{r['slot']:4} {c['name'][:26]:26} {c['rating']} {c['nation'][:12]:12} {c['league'][:18]:18} "
              f"chem {r['chem']} {'CLUB' if c.get('mine') else c['price']}")


if __name__ == "__main__":
    main()
