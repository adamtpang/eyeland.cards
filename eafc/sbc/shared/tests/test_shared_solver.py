"""Synthetic checks for the shared SBC solver.

Every card name in here is invented. Real club exports, protect lists, and
player profiles stay on disk outside git.
"""

import json
import os
import tempfile
import time
import unittest
import warnings
from collections import Counter
from pathlib import Path

warnings.filterwarnings("ignore", message=r"Constructing LpVariable.*deprecated")

from eafc.sbc.shared.clubs import link_root
from eafc.sbc.shared.cli import main
from eafc.sbc.shared.done import import_solved, write_done
from eafc.sbc.shared.fetch_public import api_url
from eafc.sbc.shared.inventory import (
    build_pool,
    classify_inventory,
    load_inventory,
    select_inventory_path,
)
from eafc.sbc.shared.model import canonical_trim, solve_sbc, solve_squads
from eafc.sbc.shared.specs import formation_slots, load_chemistry, load_specs, prepare_spec

SPECS = Path(__file__).resolve().parents[2] / "specs"
CHEMISTRY = SPECS / "chemistry.json"


def identity(value):
    return value


def card(rid, name, rating, positions, club, league, nation, price, **flags):
    """One invented player, split into an inventory row and a profile."""
    metas = flags.get("metas")
    if metas is None:
        metas = [{"chemistry": 3, "metaRating": flags.get("meta3", 50)}]
    version = flags.get("version", 0)
    item = {
        "resourceId": rid,
        "displayName": name,
        "rating": rating,
        "versionId": version,
        "activeSquad": flags.get("active", False),
        "sbcStorage": flags.get("storage", False),
        "price": flags.get("inv_price", price),
        "untradeable": flags.get("untradeable", True),
        "transferList": flags.get("transfer", False),
        "isObjectivePlayer": flags.get("objective", False),
    }
    profile = {
        "resourceId": rid,
        "assetId": flags.get("asset", rid),
        "name": name,
        "rating": rating,
        "versionId": flags.get("profile_version", version),
        "clubId": club,
        "leagueId": league,
        "countryId": nation,
        "possiblePositions": list(positions),
        "priceInfo": {"displayPrice": price},
        "metaRatings": metas,
    }
    return item, profile


def make_pool(rows, extra_profiles=(), root=identity, **kwargs):
    players = []
    profiles = {}
    for item, profile in rows:
        players.append(item)
        profiles[profile["resourceId"]] = profile
    for profile in extra_profiles:
        profiles[profile["resourceId"]] = profile
    pool, kept, storage = build_pool(players, profiles, root, **kwargs)
    left = Counter({entry["rid"]: entry["own"] for entry in pool if entry["own"]})
    return pool, kept, storage, left


def tiny(**kwargs):
    raw = {
        "id": 1,
        "name": "Synthetic",
        "slots": ["ST"],
        "n": 1,
        "chem": 0,
        "minr": 0,
    }
    raw.update(kwargs)
    return prepare_spec(raw)


def reasons(kept):
    return [why for _name, _rating, why in kept]


class LinkedClubTests(unittest.TestCase):
    def test_union_find_matches_canonical_parent_rule(self):
        root = link_root(
            [
                {"id": 501, "linkedClubIds": [502]},
                {"id": 502, "linkedClubIds": [501]},
                {"id": 503, "linkedClubIds": []},
            ]
        )
        self.assertEqual(root(501), root(502))
        self.assertNotEqual(root(501), root(503))

    def test_same_club_counts_linked_ids_as_one(self):
        root = link_root([{"id": 501, "linkedClubIds": [502]}, {"id": 502, "linkedClubIds": [501]}])
        rows = [
            card(1, "Ada North", 70, ["ST"], 501, 11, 21, 100),
            card(2, "Bea South", 70, ["ST"], 502, 11, 21, 120),
        ]
        pool, _kept, storage, left = make_pool(rows, root=root)
        spec = prepare_spec(
            {"id": 11, "name": "Linked", "slots": ["ST", "ST"], "n": 2, "chem": 0, "minr": 0, "same_club_min": 2},
            root,
        )
        result = solve_sbc(spec, pool, left, storage, seconds=15, exact_model=True)
        self.assertEqual(result["status"], "Optimal")
        self.assertEqual({row["name"] for row in result["players"]}, {"Ada North", "Bea South"})
        self.assertEqual({row["club"] for row in result["players"]}, {root(501)})

    def test_unlinked_clubs_fail_same_club_min(self):
        root = link_root([{"id": 501, "linkedClubIds": []}, {"id": 502, "linkedClubIds": []}])
        rows = [
            card(1, "Ada North", 70, ["ST"], 501, 11, 21, 100),
            card(2, "Bea South", 70, ["ST"], 502, 11, 21, 120),
        ]
        pool, _kept, storage, left = make_pool(rows, root=root)
        spec = prepare_spec(
            {"id": 12, "name": "Split", "slots": ["ST", "ST"], "n": 2, "chem": 0, "minr": 0, "same_club_min": 2},
            root,
        )
        result = solve_sbc(spec, pool, left, storage, seconds=15, exact_model=True)
        self.assertEqual(result["status"], "Infeasible")
        self.assertEqual(result["players"], [])

    def test_clubs_max_uses_the_merged_root(self):
        linked = link_root([{"id": 501, "linkedClubIds": [502]}, {"id": 502, "linkedClubIds": []}])
        rows = [
            card(1, "Ada North", 70, ["ST"], 501, 11, 21, 100),
            card(2, "Bea South", 70, ["ST"], 502, 11, 21, 120),
        ]
        pool, _kept, storage, left = make_pool(rows, root=linked)
        spec = prepare_spec(
            {"id": 13, "name": "One club", "slots": ["ST", "ST"], "n": 2, "chem": 0, "minr": 0, "clubs_max": 1},
            linked,
        )
        merged = solve_sbc(spec, pool, left, storage, seconds=15, exact_model=True)
        self.assertEqual(merged["status"], "Optimal")

        separate = link_root([{"id": 501, "linkedClubIds": []}, {"id": 602, "linkedClubIds": []}])
        rows = [
            card(3, "Cara West", 70, ["ST"], 501, 11, 21, 100),
            card(4, "Dee East", 70, ["ST"], 602, 11, 21, 120),
        ]
        pool, _kept, storage, left = make_pool(rows, root=separate)
        spec = prepare_spec(
            {"id": 14, "name": "Two clubs", "slots": ["ST", "ST"], "n": 2, "chem": 0, "minr": 0, "clubs_max": 1},
            separate,
        )
        split = solve_sbc(spec, pool, left, storage, seconds=15, exact_model=True)
        self.assertEqual(split["status"], "Infeasible")


class ProtectionTests(unittest.TestCase):
    def test_storage_is_exempt_from_chem3_meta(self):
        stored, stored_profile = card(1, "Gia Storage", 80, ["ST"], 10, 20, 30, 400, meta3=90, storage=True)
        club, club_profile = card(2, "Hal Clubmeta", 80, ["ST"], 10, 20, 30, 400, meta3=90)
        _owned, kept, storage, profiles = classify_inventory(
            [stored, club], {1: stored_profile, 2: club_profile}, []
        )
        self.assertIn(1, _owned)
        self.assertNotIn(2, _owned)
        self.assertIn(1, storage)
        self.assertTrue(any(why.startswith("max meta") for why in reasons(kept)))
        pool, kept, storage, left = make_pool([(stored, stored_profile), (club, club_profile)])
        self.assertEqual(pool[0]["rid"], 1)
        result = solve_sbc(tiny(id=21), pool, left, storage, seconds=15, exact_model=True)
        self.assertEqual(result["players"][0]["name"], "Gia Storage")
        self.assertTrue(result["players"][0]["storage"])
        self.assertTrue(result["players"][0]["owned"])

    def test_only_chemistry_3_meta_protects(self):
        low, low_profile = card(
            1,
            "Ivy Chemone",
            80,
            ["ST"],
            10,
            20,
            30,
            400,
            metas=[{"chemistry": 1, "metaRating": 99}, {"chemistry": 3, "metaRating": 70}],
        )
        other, other_profile = card(
            2,
            "Jo Chemtwo",
            80,
            ["ST"],
            10,
            20,
            30,
            400,
            metas=[{"chemistry": 2, "metaRating": 99}],
        )
        high, high_profile = card(3, "Kay Chemthree", 80, ["ST"], 10, 20, 30, 400, meta3=90)
        owned, kept, _storage, _profiles = classify_inventory(
            [low, other, high],
            {1: low_profile, 2: other_profile, 3: high_profile},
            [],
        )
        self.assertEqual(set(owned), {1, 2})
        self.assertEqual(reasons(kept), ["max meta 90.0"])

    def test_keep84_and_active_and_protect_name(self):
        club84, p84 = card(1, "Lia Veteran", 84, ["ST"], 10, 20, 30, 500, meta3=40)
        store84, pstore = card(2, "Mia Vault", 84, ["ST"], 10, 20, 30, 500, meta3=40, storage=True)
        pricey, pprice = card(3, "Nia Pricey", 70, ["ST"], 10, 20, 30, 100, inv_price=2500, meta3=40)
        active, pactive = card(4, "Ora Active", 70, ["ST"], 10, 20, 30, 100, active=True)
        named, pnamed = card(5, "Placeholder Keeper", 70, ["ST"], 10, 20, 30, 100)
        normal, pnormal = card(6, "Pia Normal", 70, ["ST"], 10, 20, 30, 100)
        players = [club84, store84, pricey, active, named, normal]
        profiles = {i: p for i, p in enumerate([p84, pstore, pprice, pactive, pnamed, pnormal], start=1)}
        owned, kept, _storage, _profiles = classify_inventory(
            players, profiles, ["Placeholder"], keep84=True
        )
        why = {name: reason for name, _rating, reason in kept}
        self.assertEqual(why["Lia Veteran"], "club 84+ (kept; Storage copies still used)")
        self.assertNotIn("Mia Vault", why)
        self.assertEqual(why["Nia Pricey"], "high item score, saved for a streamlined SBC")
        self.assertEqual(why["Ora Active"], "active squad")
        self.assertEqual(why["Placeholder Keeper"], "protected")
        self.assertEqual(set(owned), {2, 6})

        plain, _kept, _storage, _profiles = classify_inventory(players, profiles, [])
        self.assertIn(1, plain)
        self.assertIn(3, plain)

    def test_net_keeps_84_including_storage(self):
        store84, profile = card(1, "Quinn Vault", 84, ["GK"], 10, 20, 30, 500, meta3=40, storage=True)
        owned, kept, _storage, _profiles = classify_inventory([store84], {1: profile}, [], net=True)
        self.assertEqual(owned, {})
        self.assertEqual(reasons(kept), ["84+ (net-cost mode keeps good fodder)"])

    def test_transfer_and_objective_flags_do_not_protect(self):
        item, profile = card(1, "Rae Listed", 70, ["ST"], 10, 20, 30, 100, transfer=True, objective=True)
        owned, kept, _storage, _profiles = classify_inventory([item], {1: profile}, [])
        self.assertEqual(list(owned), [1])
        self.assertEqual(kept, [])


class ObjectiveTests(unittest.TestCase):
    def _pool(self):
        owned = card(1, "Ada Fodder", 80, ["ST"], 10, 20, 30, 10000, meta3=40)
        market = card(2, "Bea Bargain", 80, ["ST"], 11, 21, 31, 100, meta3=40)[1]
        return make_pool([owned], extra_profiles=[market])

    def test_default_spends_fewer_coins_than_fodder(self):
        pool, _kept, storage, left = self._pool()
        result = solve_sbc(tiny(id=31), pool, left, storage, seconds=15, exact_model=True)
        self.assertEqual(result["status"], "Optimal")
        self.assertEqual(result["players"][0]["name"], "Ada Fodder")
        self.assertEqual(result["cash"], 0)
        self.assertAlmostEqual(result["objective"], 10000)
        self.assertAlmostEqual(result["best_bound"], result["objective"])
        self.assertAlmostEqual(result["mip_gap"], 0)

    def test_net_buys_when_owned_value_is_expensive(self):
        pool, _kept, storage, left = self._pool()
        result = solve_sbc(tiny(id=32), pool, left, storage, net=True, seconds=15, exact_model=True)
        self.assertEqual(result["status"], "Optimal")
        self.assertEqual(result["players"][0]["name"], "Bea Bargain")
        self.assertEqual(result["cash"], 100)
        self.assertFalse(result["players"][0]["owned"])
        # 100 * cash + 95 * fodder = 100 * 100.
        self.assertAlmostEqual(result["objective"], 10000)
        self.assertAlmostEqual(result["mip_gap"], 0)


class DoneAndReportTests(unittest.TestCase):
    def test_done_list_skips_ids(self):
        row = card(1, "Sue Spare", 70, ["ST", "GK"], 10, 20, 30, 50)
        pool, _kept, storage, left = make_pool([row])
        first = tiny(id=41, name="First", slots=["ST"])
        second = tiny(id=42, name="Second", slots=["GK"])
        squads, skipped = solve_squads(
            [first, second], pool, left, storage, seconds=15, exact_model=True, done={41}
        )
        self.assertEqual(skipped, [41])
        self.assertEqual([squad["id"] for squad in squads], [42])
        self.assertEqual(squads[0]["status"], "Optimal")

    def test_gap_fields_exist_when_infeasible(self):
        row = card(1, "Tess Solo", 70, ["ST"], 10, 20, 30, 50)
        pool, _kept, storage, left = make_pool([row])
        spec = prepare_spec(
            {"id": 43, "name": "Impossible", "slots": ["ST", "ST"], "n": 2, "chem": 0, "minr": 0, "same_club_min": 2}
        )
        result = solve_sbc(spec, pool, left, storage, seconds=15, exact_model=True)
        for key in ("status", "objective", "best_bound", "mip_gap"):
            self.assertIn(key, result)
        self.assertEqual(result["status"], "Infeasible")
        self.assertEqual(result["players"], [])

    def test_import_done_ignores_public_unsolved_rows(self):
        public = [
            {"id": 75, "name": "Sample Set", "solved": False, "solvedCount": 0, "remainingCost": None},
            {"id": 76, "solved": False, "solvedCount": 3, "remainingCost": 1200},
        ]
        merged, marked, total = import_solved(public, set())
        self.assertEqual(total, 2)
        self.assertEqual(marked, set())
        self.assertEqual(merged, set())

        logged = [{"id": 76, "solved": True}, {"id": 75, "solved": False}]
        merged, marked, total = import_solved(logged, {10})
        self.assertEqual(marked, {76})
        self.assertEqual(merged, {10, 76})

    def test_write_done_roundtrip(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "done.json"
            write_done(path, [4, 2])
            self.assertEqual(json.loads(path.read_text(encoding="utf-8")), {"ids": [2, 4]})


class TrimTests(unittest.TestCase):
    def test_canonical_trim_has_no_club_or_nation_bucket(self):
        pool = []
        # Twenty market cards in one league/nation. Only the cheapest 14 survive
        # the league cap (the league-nation cap is the tighter 4, then the
        # league cap adds the next 10).
        for index, price in enumerate(range(1, 21), start=1):
            pool.append(
                {
                    "rid": index,
                    "rating": 70,
                    "price": price,
                    "club": 1000 + index,
                    "league": 7,
                    "nation": 3,
                    "pos": {"ST"},
                }
            )
        owned = {
            "rid": 100,
            "rating": 80,
            "price": 9000,
            "club": 50,
            "league": 7,
            "nation": 9,
            "pos": {"CB"},
        }
        too_low = {
            "rid": 101,
            "rating": 60,
            "price": 1,
            "club": 50,
            "league": 7,
            "nation": 9,
            "pos": {"CB"},
        }
        pool.extend([owned, too_low])
        spec = prepare_spec({"id": 1, "name": "Trim", "slots": ["ST"], "n": 1, "chem": 0, "minr": 65})
        left = Counter({100: 1, 101: 1})
        keep = canonical_trim(pool, spec, left)
        kept_prices = sorted(pool[i]["price"] for i in keep if pool[i]["rid"] < 100)
        self.assertEqual(kept_prices, list(range(1, 15)))
        self.assertIn(20, keep)  # the owned card sits at the end of the pool list
        self.assertNotIn(21, keep)
        self.assertTrue(all(pool[i]["rid"] != 101 for i in keep))


class EightPlayerTests(unittest.TestCase):
    def test_eight_player_proves_optimal_and_reports_gap(self):
        slots = ["GK", "CB", "CB", "CM", "CM", "ST", "ST", "CAM"]
        rows = []
        rid = 1
        for slot, rating in zip(slots, range(76, 84)):
            rows.append(card(rid, f"Owned {slot} {rid}", rating, [slot], 42, 7, 3, 400 + rid, meta3=40))
            rid += 1
        clones = []
        for clone in range(12):
            profile = card(
                100 + clone,
                f"Clone Striker {clone}",
                76,
                ["ST"],
                42,
                7,
                3,
                30 + clone,
                meta3=40,
            )[1]
            clones.append(profile)
        # Extra leagues give the trim something to cut and make the MIP wider
        # than the eight owned cards. None of them are owned, so buying one
        # costs coins and cannot beat the owned squad.
        decoys = []
        decoy_id = 200
        for league in range(5):
            for offset in range(16):
                decoys.append(
                    card(
                        decoy_id,
                        f"Decoy {decoy_id}",
                        75,
                        ["GK", "CB", "CM", "ST", "CAM"],
                        1000 + decoy_id,
                        80 + league,
                        90 + (offset % 4),
                        40 + offset,
                        meta3=40,
                    )[1]
                )
                decoy_id += 1
        pool, _kept, storage, left = make_pool(rows, extra_profiles=clones + decoys)
        spec = prepare_spec(
            {
                "id": 76,
                "name": "Synthetic Eight",
                "slots": slots,
                "n": 8,
                "chem": 6,
                "minr": 65,
                "same_club_min": 3,
                "gold_min": 4,
            }
        )
        started = time.perf_counter()
        fast = solve_sbc(spec, pool, Counter(left), storage, seconds=45)
        elapsed = time.perf_counter() - started
        self.assertLess(elapsed, 45, f"8-player solve took {elapsed:.1f}s")
        self.assertEqual(fast["status"], "Optimal")
        self.assertEqual(fast["cash"], 0)
        self.assertAlmostEqual(fast["mip_gap"], 0)
        self.assertAlmostEqual(fast["best_bound"], fast["objective"])
        self.assertLess(fast["pool"], fast["canonical_pool"])
        self.assertEqual({row["name"] for row in fast["players"]}, {item[0]["displayName"] for item in rows})

        again = solve_sbc(spec, pool, Counter(left), storage, seconds=45, exact_model=True)
        self.assertEqual(again["status"], "Optimal")
        self.assertAlmostEqual(again["objective"], fast["objective"])
        self.assertEqual({row["name"] for row in again["players"]}, {row["name"] for row in fast["players"]})


class InventoryLoaderTests(unittest.TestCase):
    def test_newest_mtime_wins_and_is_printed(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            easy = folder / "easy-inventory.json"
            futbin = folder / "club_futbin.json"
            easy.write_text(
                json.dumps(
                    {
                        "stats": {},
                        "plat": {},
                        "players": [
                            {
                                "resourceId": 5,
                                "displayName": "Ada Striker",
                                "rating": 70,
                                "versionId": 0,
                                "price": 10,
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            futbin.write_text(
                json.dumps(
                    {
                        "imported": "1 Nov 2099",
                        "read": "2099-11-01 12:00",
                        "xi": [{"rating": 70, "pos": "ST", "name": "Ada"}],
                        "players": [
                            {
                                "name": "Ada Striker",
                                "rating": 70,
                                "version": "",
                                "price_pc": 400,
                                "tradeable": True,
                            },
                            {"name": "Bea Loan", "rating": 71, "version": "Loan", "price_pc": 100, "tradeable": False},
                        ],
                    }
                ),
                encoding="utf-8",
            )
            os.utime(easy, (1_000, 1_000))
            os.utime(futbin, (2_000, 2_000))
            self.assertEqual(select_inventory_path([easy, futbin]), futbin)
            profile = {
                "resourceId": 5,
                "name": "Ada Striker",
                "rating": 70,
                "versionId": 0,
                "clubId": 10,
                "leagueId": 20,
                "countryId": 30,
                "possiblePositions": ["ST"],
                "priceInfo": {"displayPrice": 400},
                "metaRatings": [{"chemistry": 3, "metaRating": 40}],
            }
            import io
            from contextlib import redirect_stdout

            buffer = io.StringIO()
            with redirect_stdout(buffer):
                loaded = load_inventory([easy, futbin], {5: profile})
            text = buffer.getvalue()
            self.assertIn("club_futbin.json", text)
            self.assertIn("mtime", text)
            self.assertEqual(loaded["kind"], "futbin")
            by_name = {row["displayName"]: row for row in loaded["players"]}
            self.assertTrue(by_name["Ada Striker"]["activeSquad"])
            self.assertFalse(by_name["Ada Striker"]["sbcStorage"])
            self.assertEqual(by_name["Ada Striker"]["resourceId"], 5)
            self.assertEqual(by_name["Bea Loan"]["versionId"], 2)
            self.assertFalse(by_name["Bea Loan"]["sbcStorage"])

            os.utime(easy, (3_000, 3_000))
            with redirect_stdout(io.StringIO()):
                newer = load_inventory([easy, futbin], {5: profile})
            self.assertEqual(newer["kind"], "easysbc")
            self.assertEqual(newer["players"][0]["resourceId"], 5)


class SpecAndFetchTests(unittest.TestCase):
    def test_committed_specs_match_canonical_shape(self):
        specs = {spec["id"]: spec for spec in load_specs(SPECS)}
        self.assertEqual(set(specs), {118, 119, 120, 121, 114, 75})
        self.assertEqual(len(specs[118]["slots"]), 11)
        self.assertEqual(specs[118]["slots"][0], "GK")
        self.assertEqual(specs[118]["anchor"][0], {483, 452})
        self.assertEqual(specs[118]["nation"], (45, 1))
        self.assertEqual(specs[118]["chem"], 14)
        self.assertEqual(specs[119]["chem"], 18)
        self.assertEqual(specs[120]["chem"], 22)
        self.assertEqual(specs[120]["anchor"][0], {131681, 131682})
        self.assertEqual(specs[121]["chem"], 26)
        self.assertEqual(specs[121]["rating_sum"], 825)
        self.assertEqual(specs[121]["league"], (13, 2))
        self.assertEqual(specs[114]["n"], 9)
        self.assertEqual(len(specs[114]["slots"]), 11)
        self.assertEqual(specs[75]["n"], 7)
        self.assertEqual(specs[75]["slots"], ["GK", "RB", "CB", "CB", "LB", "CM", "CM"])
        order = sorted(specs.values(), key=lambda spec: (-spec["chem"], spec["sequence"]))
        self.assertEqual([spec["id"] for spec in order], [121, 120, 75, 119, 114, 118])
        chemistry = load_chemistry(CHEMISTRY)
        self.assertEqual(chemistry["club"], (2, 4, 7))
        self.assertEqual(chemistry["league"], (3, 5, 8))
        self.assertEqual(chemistry["nation"], (2, 5, 8))

    def test_formation_aliases(self):
        base = {"formations": [{"id": "f442", "uniquePositions": ["GK", "RCB", "LS"]}]}
        self.assertEqual(formation_slots(base, "f442"), ["GK", "CB", "ST"])

    def test_public_endpoints(self):
        self.assertEqual(api_url("base-data"), "https://api-fc27.easysbc.io/base-data")
        self.assertEqual(api_url("sbcs?setId=78"), "https://api-fc27.easysbc.io/sbcs?setId=78")
        self.assertEqual(api_url("players/15"), "https://api-fc27.easysbc.io/players/15")

    def test_price_cap_keeps_owned_cards(self):
        owned = card(1, "Uma Owned", 70, ["ST"], 10, 20, 30, 9000)
        cheap = card(2, "Val Cheap", 70, ["ST"], 10, 20, 30, 500)[1]
        pricey = card(3, "Wes Costly", 70, ["ST"], 10, 20, 30, 2000)[1]
        big = card(4, "Xen Anchor", 70, ["ST"], 131681, 20, 30, 5000)[1]
        over = card(5, "Yas Over", 70, ["ST"], 131681, 20, 30, 7000)[1]
        pool, _kept, _storage, _left = make_pool([owned], extra_profiles=[cheap, pricey, big, over])
        self.assertEqual({entry["rid"] for entry in pool}, {1, 2, 4})


class CliTests(unittest.TestCase):
    def test_solve_prints_inventory_and_writes_gap(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            local = folder / "local"
            profiles = local / "profiles"
            spec_dir = folder / "specs"
            profiles.mkdir(parents=True)
            spec_dir.mkdir()
            (local / "base.json").write_text(
                json.dumps({"managerData": {"clubs": []}, "formations": []}),
                encoding="utf-8",
            )
            (local / "easy-inventory.json").write_text(
                json.dumps(
                    {
                        "stats": {"players": 1},
                        "plat": {},
                        "players": [
                            {
                                "resourceId": 1,
                                "displayName": "Zed Synthetic",
                                "rating": 70,
                                "versionId": 0,
                                "clubId": 10,
                                "countryId": 30,
                                "leagueId": 20,
                                "possiblePositions": ["ST"],
                                "position": "ST",
                                "price": 80,
                                "sbcPrice": 0,
                                "sbcStorage": False,
                                "activeSquad": False,
                                "untradeable": True,
                                "duplicate": False,
                                "transferList": False,
                                "isObjectivePlayer": False,
                                "metaRating": 40,
                                "metaRatingZeroChem": 40,
                                "metalId": 1,
                                "assetId": 1,
                                "eaPlayerId": 1,
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            (profiles / "player-1.json").write_text(
                json.dumps(
                    {
                        "resourceId": 1,
                        "assetId": 1,
                        "name": "Zed Synthetic",
                        "rating": 70,
                        "versionId": 0,
                        "clubId": 10,
                        "leagueId": 20,
                        "countryId": 30,
                        "possiblePositions": ["ST"],
                        "priceInfo": {"displayPrice": 80},
                        "metaRatings": [{"chemistry": 3, "metaRating": 40}],
                    }
                ),
                encoding="utf-8",
            )
            (spec_dir / "1-synthetic.json").write_text(
                json.dumps(
                    {"id": 1, "name": "Synthetic One", "slots": ["ST"], "n": 1, "chem": 0, "minr": 0}
                ),
                encoding="utf-8",
            )
            (spec_dir / "chemistry.json").write_text(
                json.dumps({"club": [2, 4, 7], "league": [3, 5, 8], "nation": [2, 5, 8]}),
                encoding="utf-8",
            )
            config = {
                "inventory_paths": ["../local/easy-inventory.json"],
                "profiles_dir": "../local/profiles",
                "base_path": "../local/base.json",
                "protect_path": "../local/protect.json",
                "consumed_path": "../local/consumed.json",
                "done_path": "../local/done.json",
                "plan_path": "../local/plan.json",
                "specs_dir": "../specs",
                "chemistry_path": "../specs/chemistry.json",
                "platform": "pc",
                "price_provider": "easysbc",
                "price_cap": 1300,
                "anchor_big_clubs": [131681, 131682],
                "anchor_big_cap": 6000,
            }
            shared = folder / "shared"
            shared.mkdir()
            config_path = shared / "config.json"
            config_path.write_text(json.dumps(config), encoding="utf-8")
            import io
            from contextlib import redirect_stdout

            buffer = io.StringIO()
            with redirect_stdout(buffer):
                main(["solve", "--config", str(config_path), "--secs", "15", "--exact-model"])
            text = buffer.getvalue()
            self.assertIn("easy-inventory.json", text)
            self.assertIn("mtime", text)
            self.assertIn("gap", text)
            plan = json.loads((local / "plan.json").read_text(encoding="utf-8"))
            self.assertEqual(plan["squads"][0]["status"], "Optimal")
            self.assertEqual(plan["squads"][0]["mip_gap"], 0)
            self.assertEqual(plan["platform"], "pc")
            self.assertEqual(plan["squads"][0]["players"][0]["name"], "Zed Synthetic")
            self.assertEqual(plan["squads"][0]["players"][0]["price_platform"], "pc")
            self.assertEqual(plan["squads"][0]["players"][0]["price_quality"], "approximate")
            self.assertIn("easy-inventory.json", plan["inventory"]["path"])


if __name__ == "__main__":
    unittest.main()
