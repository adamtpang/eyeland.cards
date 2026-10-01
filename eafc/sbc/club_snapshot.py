"""Read-only club import: page through Club > Players with the web app's own search, save club.json.
Reads page memory over the Helium CDP bridge; never clicks or sends anything to EA."""
import json
import os

import cdp

POS = {0: "GK", 1: "SW", 2: "RWB", 3: "RB", 4: "CB", 5: "CB", 6: "CB", 7: "LB", 8: "LWB", 9: "CDM",
       10: "CDM", 11: "CDM", 12: "RM", 13: "CM", 14: "CM", 15: "CM", 16: "LM", 17: "CAM", 18: "CAM",
       19: "CAM", 20: "CF", 21: "CF", 22: "CF", 23: "RW", 24: "ST", 25: "ST", 26: "ST", 27: "LW"}
HERE = os.path.dirname(__file__)
OUT = os.path.join(HERE, "club.json")


def main():
    import webapp
    sid = webapp.session()
    print("club search:", cdp.evaluate(sid, open(os.path.join(HERE, "club_fetch.js"), encoding="utf-8").read()))
    rows = json.loads(cdp.evaluate(sid, open(os.path.join(HERE, "club_read.js"), encoding="utf-8").read()))
    club = {}
    for r in rows:
        r["pos"] = sorted({POS.get(p, str(p)) for p in r["pos"]} | {POS.get(r["pref"], "")} - {""})
        r["club"] = f"team{r['teamId']}" if r["club"].startswith("*") or not r["club"] else r["club"]
        r["role"] = ("loan" if r["loan"] else "starter" if 0 <= r["squadSlot"] < 11
                     else "bench" if r["squadSlot"] >= 11 else "spare")
        club[str(r["itemId"])] = r
    json.dump(sorted(club.values(), key=lambda p: -p["rating"]), open(OUT, "w", encoding="utf-8"),
              ensure_ascii=False, indent=1)
    from collections import Counter
    print(f"loaded now: {len(rows)}, saved total: {len(club)}", dict(Counter(p["role"] for p in club.values())))


if __name__ == "__main__":
    main()
