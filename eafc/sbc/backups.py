"""For a solved squad: which slots are free fodder, which are critical, and the cheapest
single-card backup for each if the named buy is overpriced. Read-only, prices from FUTBIN.

  python backups.py sbcs/england-v-spain.json id1,id2,...   (ids in slot order)
"""
import json
import sys

import futbin
from solve import check, chemistry, cost, fits, rating


def main():
    spec = json.load(open(sys.argv[1], encoding="utf-8"))
    slots, req = spec["slots"], spec["requirements"]
    by_id = {}
    for f in spec["pools"]:
        for p in futbin.players(**dict(f)):
            if p["price"]:
                by_id[p["id"]] = p
    squad = [by_id[i] for i in sys.argv[2].split(",")]
    pool = sorted(by_id.values(), key=lambda p: p["price"])
    print(f"squad {cost(squad):,}, rating {rating(squad)}, chem {chemistry(squad, slots)}\n")
    for i, (s, p) in enumerate(zip(slots, squad)):
        ok = [c for c in pool if c["id"] not in {q["id"] for q in squad} and fits(c, s)
              and check(squad[:i] + [c] + squad[i + 1:], slots, req)]
        # what does a valid replacement need to share with the pick?
        same_nat = all(c["nation"] == p["nation"] for c in ok)
        same_lg = all(c["league"] == p["league"] for c in ok)
        min_r = min((c["rating"] for c in ok), default=0)
        need = []
        if min_r >= 80:
            need.append(f"{min_r}+ rating")
        if same_nat:
            need.append(p["nation"])
        if same_lg:
            need.append(p["league"])
        b = ok[0] if ok else None
        bk = f"{b['name'][:24]} {b['rating']} {b['nation'][:10]} {b['price']:,}" if b else "none, rerun solve.py"
        print(f"{s:4}|{p['name'][:22]:22}|{', '.join(need) or 'any'}|{len(ok)}|{bk}")


if __name__ == "__main__":
    main()
