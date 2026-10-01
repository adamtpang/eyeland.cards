"""Our own EasySBC: take a working SBC squad and swap out inflated cards for the
cheapest players that still meet every requirement. Read-only: it only reads
FUTBIN prices and prints a shopping list. You buy and submit by hand.

  python solve.py sbcs/england-v-spain.json [--exclude "Gavi,574"] [--owned owned.json]

--exclude  names or FUTBIN ids you refuse to buy (e.g. cards pumped by the community squad)
--owned    JSON list of FUTBIN ids already in your club; they cost 0
"""
import argparse
import json
from collections import Counter

import futbin

CLUB, NATION, LEAGUE = (2, 5, 8), (2, 5, 8), (3, 5, 8)


def steps(n, t):
    return sum(n >= x for x in t)


def fits(p, slot):
    return slot in p["pos"]


def player_chem(squad, slots):
    """Per-player chemistry. Verified against EA's own numbers on a real squad (2026-09-27):
    thresholds below, only in-position players count, and an in-position Icon has 3 chem
    and adds 1 to every league's count."""
    on = [p for p, s in zip(squad, slots) if fits(p, s)]
    icons = sum(p["league"] == "Icons" for p in on)
    cl, na, le = (Counter(p[k] for p in on) for k in ("club", "nation", "league"))
    out = []
    for p, s in zip(squad, slots):
        if not fits(p, s):
            out.append(0)
        elif p["league"] == "Icons":
            out.append(3)
        else:
            out.append(min(3, steps(cl[p["club"]], CLUB) + steps(na[p["nation"]], NATION)
                           + steps(le[p["league"]] + icons, LEAGUE)))
    return out


def chemistry(squad, slots):
    return sum(player_chem(squad, slots))


def rating(squad):
    r = [p["rating"] for p in squad]
    avg = sum(r) / len(r)
    total = sum(r) + sum(max(0, x - avg) for x in r)
    # EA rounds the total to the nearest whole number, then divides and floors:
    # e.g. 890.56 -> 891 -> 81.0 = 81, and 825.09 -> 825 -> 75.0 = 75
    return int(round(total + 1e-9) // len(r))


def check(squad, slots, req):
    ids = [p["id"] for p in squad]
    if len(set(ids)) != len(ids):
        return False
    if "min_from_nations" in req:
        m = req["min_from_nations"]
        if sum(p["nation"] in m["nations"] for p in squad) < m["count"]:
            return False
    if "min_same_nation" in req and max(Counter(p["nation"] for p in squad).values()) < req["min_same_nation"]:
        return False
    if "max_same_club" in req and max(Counter(p["club"] for p in squad).values()) > req["max_same_club"]:
        return False
    if "max_leagues" in req and len({p["league"] for p in squad}) > req["max_leagues"]:
        return False
    if "exact_leagues" in req and len({p["league"] for p in squad}) != req["exact_leagues"]:
        return False
    if "exact_nations" in req and len({p["nation"] for p in squad}) != req["exact_nations"]:
        return False
    if "max_same_league" in req and max(Counter(p["league"] for p in squad).values()) > req["max_same_league"]:
        return False
    if "max_same_nation" in req and max(Counter(p["nation"] for p in squad).values()) > req["max_same_nation"]:
        return False
    if req.get("min_player_rating") and min(p["rating"] for p in squad) < req["min_player_rating"]:
        return False
    if rating(squad) < req.get("min_rating", 0):
        return False
    return chemistry(squad, slots) >= req.get("min_chemistry", 0)


def cost(squad):
    return sum(p["price"] for p in squad)


def improve(squad, slots, req, pool):
    """Single swaps, then pair swaps, always taking the biggest saving that stays valid."""
    while True:
        best, best_cost = None, cost(squad)
        for i, slot in enumerate(slots):
            for c in pool:
                if c["price"] >= squad[i]["price"] or not fits(c, slot):
                    continue
                trial = squad[:i] + [c] + squad[i + 1:]
                if cost(trial) < best_cost and check(trial, slots, req):
                    best, best_cost = trial, cost(trial)
        if best is None:
            # pair swaps: needed when one swap alone breaks rating or chemistry
            cheap = {s: [c for c in pool if fits(c, s)][:25] for s in set(slots)}
            for i in range(len(slots)):
                for j in range(i + 1, len(slots)):
                    for a in cheap[slots[i]]:
                        if a["price"] >= squad[i]["price"] + squad[j]["price"]:
                            break
                        for b in cheap[slots[j]]:
                            trial = list(squad)
                            trial[i], trial[j] = a, b
                            if cost(trial) < best_cost and check(trial, slots, req):
                                best, best_cost = trial, cost(trial)
        if best is None:
            return squad
        squad = best


def repair(squad, holes, slots, req, pool):
    """An excluded card left a hole: refill it (and if needed one other slot) with the cheapest valid pair."""
    best, best_cost = None, float("inf")
    for i in holes:
        for a in (c for c in pool if fits(c, slots[i])):
            trial = squad[:i] + [a] + squad[i + 1:]
            if check(trial, slots, req) and cost(trial) < best_cost:
                best, best_cost = trial, cost(trial)
    if best:
        return best
    for i in holes:
        for a in [c for c in pool if fits(c, slots[i])][:60]:
            for j in range(len(slots)):
                if j == i:
                    continue
                for b in [c for c in pool if fits(c, slots[j])][:60]:
                    trial = list(squad)
                    trial[i], trial[j] = a, b
                    if cost(trial) < best_cost and check(trial, slots, req):
                        best, best_cost = trial, cost(trial)
    return best or squad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sbc")
    ap.add_argument("--exclude", default="")
    ap.add_argument("--owned", default=None)
    a = ap.parse_args()
    spec = json.load(open(a.sbc, encoding="utf-8"))
    slots, req = spec["slots"], spec["requirements"]
    owned = set(json.load(open(a.owned))) if a.owned else set()
    excl = {x.strip().lower() for x in a.exclude.split(",") if x.strip()}

    by_id = {}
    for f in spec["pools"]:
        f = dict(f)
        for p in futbin.players(**f):
            if p["price"] or p["id"] in owned:
                by_id[p["id"]] = p
    for p in by_id.values():
        if p["id"] in owned:
            p["price"] = 0
    missing = [i for i in spec["base_squad"] if i not in by_id]
    if missing:
        print(f"note: base ids not in fetched pools, filled with cheapest fit: {missing}")
    base = [by_id.get(i) or next(c for c in sorted(by_id.values(), key=lambda p: p["price"]) if fits(c, s))
            for i, s in zip(spec["base_squad"], slots)]
    pool = sorted((p for p in by_id.values()
                   if p["id"] not in excl and p["name"].lower() not in excl
                   and not any(e in p["name"].lower() for e in excl)),
                  key=lambda p: p["price"])
    print(f"{spec['name']}: base squad {cost(base):,} coins, rating {rating(base)}, chem {chemistry(base, slots)}, "
          f"valid={check(base, slots, req)}")
    start = [p if p in pool else next(c for c in pool if fits(c, s)) for p, s in zip(base, slots)]
    if not check(start, slots, req):
        start = repair(start, [i for i, p in enumerate(base) if p not in pool], slots, req, pool)
    best = improve(start, slots, req, pool)
    if not check(best, slots, req):
        raise SystemExit("no valid squad found with those exclusions; loosen --exclude")
    print(f"Solved: {cost(best):,} coins, rating {rating(best)}, chem {chemistry(best, slots)}\n")
    for s, p in zip(slots, best):
        tag = "OWNED" if p["id"] in owned else f"{p['price']:,}"
        swap = "" if p in base else "  <- swap"
        print(f"{s:4} {p['name'][:26]:26} {p['rating']}  {p['nation'][:12]:12} {p['league'][:20]:20} {tag}{swap}")


if __name__ == "__main__":
    main()
