"""Exact cheapest valid SBC squad: an integer program (PuLP + HiGHS) over every candidate
fetched from FUTBIN, across several formations. Exact for the fetched pool; the pool is
built wide (cheapest pages per rating, plus fodder from each nation/league that the cheap
high-rated cards come from). Read-only: prints a shopping list, you buy and submit.

  python optimize.py sbcs/england-v-spain.json [--exclude "Oyarzabal"] [--owned owned.json] [--pages 3]
"""
import argparse
import json
import os
import time
from collections import defaultdict

import pulp

import futbin
from solve import chemistry, check, cost, player_chem, rating

FORMATIONS = {
    "4-3-3": "GK RB CB CB LB CM CM CM RW ST LW",
    "4-4-2": "GK RB CB CB LB RM CM CM LM ST ST",
    "4-1-2-1-2": "GK RB CB CB LB CDM CM CM CAM ST ST",
    "4-2-3-1": "GK RB CB CB LB CDM CDM CAM CAM CAM ST",
    "3-5-2": "GK CB CB CB CDM CDM RM LM CAM ST ST",
    "5-2-1-2": "GK RWB CB CB CB LWB CM CM CAM ST ST",
    "3-4-3": "GK CB CB CB RM CM CM LM RW ST LW",
}
CLUB, NATION, LEAGUE = (2, 5, 8), (2, 5, 8), (3, 5, 8)
# EA web app league names that FUTBIN spells differently, keyed by EA league id
EA_LEAGUE = {31: "Serie A TIM", 2216: "Barclays WSL", 16: "Ligue 1 McDonald's", 39: "MLS", 2222: "NWSL"}


def build_pool(spec, pages, owned):
    by_id = {}

    def add(**f):
        for p in futbin.players(**f):
            if p["price"] or p["id"] in owned:
                by_id[p["id"]] = p

    lo = max(45, spec["requirements"].get("min_rating", 45) - 12)
    for r in range(lo, 87):
        for pg in range(1, pages + 1):
            add(rating=(r, r), page=pg)
    for f in spec.get("pools", []):
        add(**dict(f))
    # fodder that shares nation or league with the cheap high-rated cards
    floor = spec["requirements"].get("min_rating", 0) + 5
    hi = sorted((p for p in by_id.values() if p["rating"] >= floor), key=lambda p: p["price"])
    nat_ids, lg_ids = spec.get("nation_ids", {}), spec.get("league_ids", {})
    seen = set()
    for p in hi[:80]:
        for kind, ids in (("nation", nat_ids), ("league", lg_ids)):
            key = (kind, p[kind])
            if p[kind] in ids and key not in seen:
                seen.add(key)
                for pg in (1, 2):
                    add(**{kind: ids[p[kind]]}, page=pg)
    for p in by_id.values():
        if p["id"] in owned:
            p["price"] = 0
    return list(by_id.values())


def _group(ids, key):
    d = defaultdict(list)
    for i in ids:
        d[key(i)].append(i)
    return d


def prune(slots, pool, copies=6, exact=False):
    """Drop dominated cards. Two cards with the same nation, league and usable positions
    (and the same club, when that club has another candidate to pair with) are
    interchangeable for every requirement, and a higher rating never lowers the squad
    rating. So a card is dropped when `copies` cards of its profile are at least as
    highly rated and no more expensive. With exact=False the club is ignored when grouping,
    which cuts thousands of cards to a few hundred but can miss a squad whose chemistry
    needs two cards from the same club (the result is then near-exact, not proven)."""
    usable = {p["id"]: tuple(sorted(set(p["pos"]) & set(slots))) for p in pool}
    live = [p for p in pool if usable[p["id"]]]
    club_n = defaultdict(int)
    for p in live:
        club_n[p["club"]] += 1
    groups = defaultdict(list)
    for p in live:
        club = p["club"] if exact and club_n[p["club"]] > 1 else None
        groups[(p["nation"], p["league"], club, usable[p["id"]])].append(p)
    keep = []
    for ps in groups.values():
        ps.sort(key=lambda p: (p["price"], -p["rating"]))
        kept = []
        for p in ps:
            if sum(k["rating"] >= p["rating"] for k in kept) < copies:
                kept.append(p)
        keep += kept
    return keep


def build_model(slots, req, pool):
    prob = pulp.LpProblem("sbc", pulp.LpMinimize)
    S = range(len(slots))
    P = {p["id"]: p for p in pool}
    x = {(p["id"], s): pulp.LpVariable(f"x_{p['id']}_{s}", cat="Binary")
         for p in pool for s in S if slots[s] in p["pos"]}
    by_player = defaultdict(list)
    for (q, s), v in x.items():
        by_player[q].append(v)
    used = list(by_player)
    y = {q: pulp.lpSum(vs) for q, vs in by_player.items()}
    prob += pulp.lpSum(P[q]["price"] * v for (q, s), v in x.items())
    for s in S:
        prob += pulp.lpSum(v for (q, t), v in x.items() if t == s) == 1
    for q in used:
        prob += y[q] <= 1
    for ids in _group(used, lambda i: P[i]["name"]).values():
        if len(ids) > 1:  # two versions of one real player cannot both play
            prob += pulp.lpSum(y[i] for i in ids) <= 1

    z, groups, n = {}, {}, 0
    for key, th in (("club", CLUB), ("nation", NATION), ("league", LEAGUE)):
        groups[key] = _group(used, lambda i, k=key: P[i][k])
        for g, ids in groups[key].items():
            cnt = pulp.lpSum(y[i] for i in ids)
            for k, t in enumerate(th):
                if len(ids) >= t:
                    n += 1
                    v = pulp.LpVariable(f"z{n}", cat="Binary")
                    prob += cnt >= t * v
                    z[key, g, k] = v
            if key == "club" and "max_same_club" in req:
                prob += cnt <= req["max_same_club"]
            if key == "league" and "max_same_league" in req:
                prob += cnt <= req["max_same_league"]
            if key == "nation" and "max_same_nation" in req:
                prob += cnt <= req["max_same_nation"]
    chem = []
    for q in used:
        c = pulp.LpVariable(f"c_{q}", 0, 3)
        prob += c <= 3 * y[q]
        prob += c <= pulp.lpSum(z[k, P[q][k], j] for k in ("club", "nation", "league")
                                for j in range(3) if (k, P[q][k], j) in z)
        chem.append(c)
    prob += pulp.lpSum(chem) >= req.get("min_chemistry", 0)

    for key, lim in (("league", "max_leagues"), ("league", "exact_leagues"), ("nation", "exact_nations")):
        if lim not in req:
            continue
        U = []
        for g, ids in groups[key].items():
            n += 1
            u = pulp.LpVariable(f"U{n}", cat="Binary")  # 1 exactly when this group is used
            for i in ids:
                prob += y[i] <= u
            prob += u <= pulp.lpSum(y[i] for i in ids)
            U.append(u)
        if lim.startswith("exact"):
            prob += pulp.lpSum(U) == req[lim]
        else:
            prob += pulp.lpSum(U) <= req[lim]
    if "min_same_nation" in req:
        need = req["min_same_nation"]
        Ns = []
        for g, ids in groups["nation"].items():
            if len(ids) >= need:
                n += 1
                v = pulp.LpVariable(f"N{n}", cat="Binary")
                prob += pulp.lpSum(y[i] for i in ids) >= need * v
                Ns.append(v)
        prob += pulp.lpSum(Ns) >= 1
    if "min_from_nations" in req:
        m = req["min_from_nations"]
        prob += pulp.lpSum(y[i] for i in used if P[i]["nation"] in m["nations"]) >= m["count"]
    tot = pulp.lpSum(P[i]["rating"] * y[i] for i in used)
    return prob, x, P, used, y, tot


def solve_at(model, slots, req, T, secs):
    """With the rating sum fixed at T the average is a constant, so the EA rating
    formula becomes linear and exact."""
    prob, x, P, used, y, tot = model
    k = len(slots)
    for name in ("sumT", "rate"):
        prob.constraints.pop(name, None)
    if T is None:  # no squad rating requirement: one plain solve
        prob.solve(pulp.HiGHS(msg=False, timeLimit=secs))
        if prob.sol_status not in (1, 2):
            return None, prob.sol_status
        squad = [None] * k
        for (q, s), v in x.items():
            if v.value() is not None and v.value() > 0.5:
                squad[s] = P[q]
        return squad, prob.sol_status
    prob += (tot == T), "sumT"
    adj = pulp.lpSum((P[i]["rating"] + max(0.0, P[i]["rating"] - T / k)) * y[i] for i in used)
    prob += (adj >= k * req.get("min_rating", 0) - 0.5), "rate"  # EA rounds the total
    prob.solve(pulp.HiGHS(msg=False, timeLimit=secs))
    if prob.sol_status not in (1, 2):
        return None, prob.sol_status
    squad = [None] * k
    for (q, s), v in x.items():
        if v.value() is not None and v.value() > 0.5:
            squad[s] = P[q]
    return squad, prob.sol_status


def rating_bounds(pool, req, k):
    """Cheapest possible cost for each rating sum T, ignoring chemistry and nations.
    Exact small knapsack; used to prove the full solve is optimal."""
    cheap = defaultdict(list)
    for p in pool:
        cheap[p["rating"]].append(p["price"])
    items = [(r, c) for r, cs in cheap.items() for c in sorted(cs)[:k]]
    target = k * req.get("min_rating", 0) - 0.5
    out = {}
    lo_r, hi_r = min(cheap), max(cheap)
    for T in range(k * lo_r, k * hi_r + 1):
        prob = pulp.LpProblem("lb", pulp.LpMinimize)
        v = [pulp.LpVariable(f"v{j}", cat="Binary") for j in range(len(items))]
        prob += pulp.lpSum(c * vj for (r, c), vj in zip(items, v))
        prob += pulp.lpSum(v) == k
        prob += pulp.lpSum(r * vj for (r, c), vj in zip(items, v)) == T
        prob += pulp.lpSum((r + max(0.0, r - T / k)) * vj for (r, c), vj in zip(items, v)) >= target
        prob.solve(pulp.HiGHS(msg=False, timeLimit=30))
        if prob.sol_status == 1:
            out[T] = round(pulp.value(prob.objective))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sbc")
    ap.add_argument("--exclude", default="")
    ap.add_argument("--owned")
    ap.add_argument("--pages", type=int, default=3)
    ap.add_argument("--formations", default="4-2-3-1,4-3-3,4-1-2-1-2,4-4-2,3-5-2,3-4-3")
    ap.add_argument("--secs", type=int, default=30, help="time limit per solve")
    ap.add_argument("--budget", type=int, default=180, help="total seconds before returning the best found")
    ap.add_argument("--club", help="club.json from club_snapshot.py; spares cost 0")
    ap.add_argument("--exact", action="store_true", help="slow: keep club pairs when pruning (provable)")
    ap.add_argument("--first", action="store_true", help="stop at the first rating sum that yields a squad")
    ap.add_argument("--keep-premium", type=int, default=500,
                    help="extra coins a good club card is worth keeping (0 = spend club freely)")
    ap.add_argument("--free-below", type=int, default=75, help="club cards under this rating are free fodder")
    ap.add_argument("--use-bench", action="store_true", help="also allow bench players")
    a = ap.parse_args()
    spec = json.load(open(a.sbc, encoding="utf-8"))
    req = spec["requirements"]
    owned = set(json.load(open(a.owned))) if a.owned else set()
    excl = [e.strip().lower() for e in a.exclude.split(",") if e.strip()]
    pool = [p for p in build_pool(spec, a.pages, owned)
            if p["id"] not in excl and not any(e in p["name"].lower() for e in excl)]
    if a.club:
        usable = {"spare"} | ({"bench"} if a.use_bench else set())
        mine = [p for p in json.load(open(a.club, encoding="utf-8")) if p["role"] in usable
                and not any(e in p["name"].lower() for e in excl)]
        for p in mine:
            pool.append({"id": f"club{p['itemId']}", "href": "", "name": f"{p['name']} (CLUB)",
                         "rating": p["rating"], "pos": p["pos"], "nation": p["nation"],
                         "league": EA_LEAGUE.get(p["leagueId"], p["league"]),
                         "club": p["club"], "price": 0, "mine": True})
        # keep value: using a good club card "costs" what it would take to replace it,
        # plus a premium, so the solver buys cheap cards before burning good fodder
        floor = {}
        for q in pool:
            if not q.get("mine") and q["price"]:
                floor[q["rating"]] = min(floor.get(q["rating"], 10**9), q["price"])
        for q in pool:
            if q.get("mine"):
                repl = min((v for r, v in floor.items() if r >= q["rating"]), default=1000)
                q["price"] = 0 if q["rating"] < a.free_below else repl + a.keep_premium
        print(f"using {len(mine)} of your club cards for free ({', '.join(sorted(usable))})")
    if req.get("min_player_rating"):
        pool = [p for p in pool if p["rating"] >= req["min_player_rating"]]
    print(f"{spec['name']}: {len(pool)} candidate cards")
    k = 11
    lb = rating_bounds(pool, req, k) if "min_rating" in req else {None: 0}
    order = sorted(lb, key=lambda T: lb[T])
    print(f"cheapest conceivable (ignoring chemistry and nations): {lb[order[0]]:,}")
    t0 = time.time()
    best, proven, timed_out = seed(spec, pool, req), True, False
    if best:
        print(f"  starting from last saved squad: {best[0]}, {coins_of(best[1]):,} coins (still valid)")
    if spec.get("formation"):  # SBCs have a fixed formation: never pick our own
        forms = [("fixed", spec["formation"].split())]
    else:
        forms = [(f, FORMATIONS[f].split()) for f in a.formations.split(",")]
    for T in order:
        if best and cost(best[1]) <= lb[T]:
            break
        if time.time() - t0 > a.budget:
            timed_out = True
            break
        for f, slots in forms:
            if time.time() - t0 > a.budget:
                break
            m = build_model(slots, req, prune(slots, pool, exact=a.exact))
            squad, st = solve_at(m, slots, req, T, a.secs)
            del m
            if st == 2:
                proven = False
            if squad and check(squad, slots, req) and (best is None or cost(squad) < cost(best[1])):
                best = (f, squad, slots)
                print(f"  found {f}: {coins_of(squad):,} coins ({int(time.time() - t0)}s)", flush=True)
    if not best:
        raise SystemExit("no valid squad found; try a bigger --budget")
    f, squad, slots = best
    if cost(squad) <= lb[order[0]]:
        verdict = "proven cheapest (matches the lowest conceivable price)"
    elif timed_out or not proven:
        verdict = f"best found in {a.budget}s, not proven cheapest (floor {lb[order[0]]:,})"
    else:
        verdict = "proven cheapest in the fetched pool"
    print(f"\nBest: {f}, {coins_of(squad):,} coins to buy, rating {rating(squad)}, "
          f"chem {chemistry(squad, slots)}. {verdict}\n")
    pc = player_chem(squad, slots)
    rows = []
    for i, (s, p) in enumerate(zip(slots, squad)):
        tag = "CLUB" if p.get("mine") else f"buy {p['price']:,}"
        print(f"{s:4} {p['name'][:26]:26} {p['rating']}  {p['nation'][:12]:12} "
              f"{p['league'][:20]:20} {p['club'][:18]:18} chem {pc[i]}  {tag}")
        swaps = [] if p.get("mine") else ready_swaps(squad, slots, req, pool, i)
        for q in swaps:
            print(f"       swap: {q['name'][:26]:26} {q['rating']} {q['nation'][:12]:12} {q['league'][:18]:18} {q['price']:,}")
        rows.append({"slot": s, "chem": pc[i], "card": p, "swaps": swaps})
    json.dump({"sbc": spec["name"], "formation": f, "coins": coins_of(squad), "rating": rating(squad),
               "chemistry": chemistry(squad, slots), "verdict": verdict, "slots": rows},
              open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "result.json"), "w",
                   encoding="utf-8"), ensure_ascii=False, indent=1)


def seed(spec, pool, req):
    """Reuse the last saved squad for this SBC if every card is still in the pool and it
    still passes, so a short run can only improve on it."""
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "result.json")
    if not os.path.exists(path):
        return None
    last = json.load(open(path, encoding="utf-8"))
    if last.get("sbc") != spec["name"]:
        return None
    by_id = {p["id"]: p for p in pool}
    squad = [by_id.get(r["card"]["id"]) for r in last["slots"]]
    slots = [r["slot"] for r in last["slots"]]
    if None in squad or not check(squad, slots, req):
        return None
    if spec.get("formation") and slots != spec["formation"].split():
        return None
    return (last["formation"], squad, slots)


def coins_of(squad):
    return sum(0 if p.get("mine") else p["price"] for p in squad)


def ready_swaps(squad, slots, req, pool, i, n=3):
    """Cheapest cards that can replace slot i alone and keep every requirement."""
    taken = {p["id"] for p in squad}
    out = []
    for c in sorted(pool, key=lambda p: p["price"]):
        if c["id"] in taken or c.get("mine") or slots[i] not in c["pos"]:
            continue
        trial = squad[:i] + [c] + squad[i + 1:]
        if check(trial, slots, req):
            out.append(c)
            if len(out) == n:
                break
    return out


if __name__ == "__main__":
    main()
