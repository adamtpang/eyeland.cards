"""Formulation, matching, rating-floor, and parallel checks.

Card names here are invented. Nothing in this file is a real club export.
"""

import io
import subprocess
import sys
import unittest
from collections import Counter
from contextlib import redirect_stdout
from itertools import combinations
from pathlib import Path

from eafc.sbc.shared.benchmark import synthetic_case
from eafc.sbc.shared.clubs import link_root
from eafc.sbc.shared.inventory import fold_name, futbin_to_inventory, match_futbin_players
from eafc.sbc.shared.model import solve_sbc, solve_squads
from eafc.sbc.shared.rating import squad_rating
from eafc.sbc.shared.specs import DEFAULT_CHEMISTRY, load_spec_file, prepare_spec
from eafc.sbc.shared.tests.test_shared_solver import card, make_pool

FIXTURE = Path(__file__).resolve().parent / "fixtures" / "900-rating-floor.json"


def _owned_market(pairs):
    """pairs: (name, rating, pos, club, league, nation, price, owned)."""
    rows = []
    extras = []
    for index, (name, rating, pos, club, league, nation, price, owned) in enumerate(pairs, start=1):
        item, profile = card(index, name, rating, pos, club, league, nation, price, meta3=40)
        if owned:
            rows.append((item, profile))
        else:
            extras.append(profile)
    return make_pool(rows, extra_profiles=extras)


def _brute(spec, pool, left):
    indexes = [i for i, card_row in enumerate(pool) if card_row["rating"] >= spec["minr"]]
    best = None
    for combo in combinations(indexes, spec["n"]):
        if len({pool[i]["asset"] for i in combo}) != len(combo):
            continue
        from eafc.sbc.shared.model import _assign_slots, _meets, _squad_chem

        assignment, _oop = _assign_slots(list(combo), spec, pool)
        in_position = [pool[i] for i in combo if i in set(assignment.values())]
        chem, _parts = _squad_chem(in_position, DEFAULT_CHEMISTRY)
        cards = [pool[i] for i in combo]
        if not _meets(spec, cards, in_position, chem):
            continue
        cash = sum(pool[i]["price"] for i in combo if left[pool[i]["rid"]] <= 0)
        fodder = sum(pool[i]["price"] for i in combo if left[pool[i]["rid"]] > 0)
        key = (cash, fodder, 1000 * cash + fodder)
        if best is None or key < best:
            best = key
    return best


class FormulationTests(unittest.TestCase):
    def _cases(self):
        chem = {
            "id": 2,
            "name": "Same club chem",
            "slots": ["ST", "ST"],
            "n": 2,
            "chem": 2,
            "minr": 0,
        }
        spread = {
            "id": 3,
            "name": "Club cap",
            "slots": ["ST", "ST"],
            "n": 2,
            "chem": 0,
            "minr": 0,
            "clubs_max": 1,
        }
        total = {
            "id": 4,
            "name": "Rating sum",
            "slots": ["CM", "CM"],
            "n": 2,
            "chem": 0,
            "minr": 0,
            "rating_sum": 160,
        }
        single = {"id": 1, "name": "One", "slots": ["GK"], "n": 1, "chem": 0, "minr": 0}
        return [
            (
                single,
                [
                    ("Ada Keeper", 70, ["GK"], 1, 1, 1, 40, True),
                    ("Bea Keeper", 70, ["GK"], 2, 1, 2, 30, False),
                ],
            ),
            (
                chem,
                [
                    ("Cara North", 75, ["ST"], 5, 2, 3, 50, True),
                    ("Dee North", 76, ["ST"], 5, 2, 4, 55, False),
                    ("Eve Other", 80, ["ST"], 6, 2, 3, 20, False),
                    ("Fay Other", 80, ["ST"], 7, 3, 4, 20, False),
                ],
            ),
            (
                spread,
                [
                    ("Gia One", 74, ["ST"], 8, 1, 1, 25, False),
                    ("Hal One", 74, ["ST"], 8, 1, 2, 30, False),
                    ("Ivy Two", 74, ["ST"], 9, 1, 1, 10, False),
                    ("Jo Two", 74, ["ST"], 10, 2, 2, 12, False),
                ],
            ),
            (
                total,
                [
                    ("Kay Low", 70, ["CM"], 1, 1, 1, 15, True),
                    ("Lia Low", 70, ["CM"], 1, 1, 1, 15, True),
                    ("Mia High", 82, ["CM"], 2, 2, 2, 40, False),
                    ("Nia High", 82, ["CM"], 3, 2, 3, 45, False),
                ],
            ),
        ]

    def test_weighted_formulations_match_on_several_cases(self):
        for raw_spec, pairs in self._cases():
            spec = prepare_spec(raw_spec)
            pool, _kept, storage, left = _owned_market(pairs)
            with self.subTest(spec=spec["name"]):
                brute = _brute(spec, pool, left)
                self.assertIsNotNone(brute, spec["name"])
                old = solve_sbc(
                    spec, pool, Counter(left), storage, seconds=20, formulation="legacy", objective_mode="weighted"
                )
                new = solve_sbc(
                    spec, pool, Counter(left), storage, seconds=20, formulation="strong", objective_mode="weighted"
                )
                self.assertEqual(old["status"], "Optimal", spec["name"])
                self.assertEqual(new["status"], "Optimal", spec["name"])
                self.assertEqual(old["cash"], new["cash"], spec["name"])
                self.assertEqual(old["fodder"], new["fodder"], spec["name"])
                self.assertAlmostEqual(old["objective"], new["objective"], places=4)
                self.assertEqual((old["cash"], old["fodder"], int(round(old["objective"]))), brute)
                lex = solve_sbc(spec, pool, Counter(left), storage, seconds=20, formulation="strong")
                self.assertEqual(lex["status"], "Optimal")
                self.assertEqual(lex["mip_gap"], 0)
                # Every price in these cases is below 1000, so the old weight
                # encodes the same coin-then-fodder order.
                self.assertEqual((lex["cash"], lex["fodder"]), (old["cash"], old["fodder"]))

    def test_lex_keeps_expensive_fodder_when_the_old_weight_would_buy(self):
        spec = prepare_spec({"id": 8, "name": "Scale", "slots": ["ST"], "n": 1, "chem": 0, "minr": 0})
        pool, _kept, storage, left = _owned_market(
            [
                ("Ora Fodder", 80, ["ST"], 1, 1, 1, 5000, True),
                ("Pia Bargain", 80, ["ST"], 2, 1, 2, 4, False),
            ]
        )
        weighted = solve_sbc(spec, pool, Counter(left), storage, seconds=15, formulation="legacy")
        lex = solve_sbc(spec, pool, Counter(left), storage, seconds=15, formulation="strong")
        self.assertEqual(weighted["status"], "Optimal")
        self.assertEqual(lex["status"], "Optimal")
        self.assertEqual(weighted["cash"], 4)
        self.assertEqual(lex["cash"], 0)
        self.assertEqual(lex["players"][0]["name"], "Ora Fodder")


class RatingTests(unittest.TestCase):
    def test_squad_rating_integer_formula(self):
        self.assertEqual(squad_rating([75] * 11), 75)
        self.assertEqual(squad_rating([80, 80, 80]), 80)
        self.assertEqual(squad_rating([90, 70, 70]), 90)
        self.assertEqual(squad_rating([78, 78, 78]), 78)

    def test_team_rating_accepts_an_uneven_squad(self):
        spec = prepare_spec(
            {
                "id": 81,
                "name": "Uneven",
                "slots": ["ST", "ST", "ST"],
                "n": 3,
                "chem": 0,
                "minr": 0,
                "team_rating_min": 80,
            }
        )
        pool, _kept, storage, left = _owned_market(
            [
                ("Que Ninety", 90, ["ST"], 1, 1, 1, 10, False),
                ("Rae Seventy", 70, ["ST"], 2, 1, 2, 10, False),
                ("Sue Seventy", 70, ["ST"], 3, 1, 3, 10, False),
                ("Tess Eighty", 80, ["ST"], 4, 2, 4, 100, False),
                ("Uma Eighty", 80, ["ST"], 5, 2, 5, 100, False),
                ("Val Eighty", 80, ["ST"], 6, 2, 6, 100, False),
            ]
        )
        result = solve_sbc(spec, pool, left, storage, seconds=20)
        self.assertEqual(result["status"], "Optimal")
        self.assertEqual(result["cash"], 30)
        self.assertEqual(sorted(row["rating"] for row in result["players"]), [70, 70, 90])
        self.assertGreaterEqual(squad_rating(row["rating"] for row in result["players"]), 80)

    def test_rating_floor_fixture(self):
        spec = load_spec_file(FIXTURE)
        self.assertEqual(spec["rating_floors"], [{"min": 80, "count": 5}])
        self.assertEqual(spec["team_rating_min"], 78)
        self.assertEqual(spec["item_score_floors"], [{"min": 10, "count": 8}])
        rows = []
        extras = []
        for index in range(8):
            rating = 81 if index < 5 else 76
            item, profile = card(
                index + 1,
                f"Floor {index}",
                rating,
                ["ST", "CM"],
                3,
                3,
                3,
                20 + index,
                meta3=40,
            )
            profile["itemScore"] = 15
            if index < 4:
                rows.append((item, profile))
            else:
                extras.append(profile)
        # A cheap 75 cannot fill a floor seat.
        cheap = card(50, "Floor Skip", 75, ["ST", "CM"], 4, 4, 4, 5, meta3=40)[1]
        cheap["itemScore"] = 15
        extras.append(cheap)
        pool, _kept, storage, left = make_pool(rows, extra_profiles=extras)
        result = solve_sbc(spec, pool, left, storage, seconds=20)
        self.assertEqual(result["status"], "Optimal")
        self.assertGreaterEqual(sum(1 for row in result["players"] if row["rating"] >= 80), 5)
        self.assertGreaterEqual(squad_rating(row["rating"] for row in result["players"]), 78)


class ClubCountTests(unittest.TestCase):
    def test_clubs_max_can_count_raw_ids(self):
        root = link_root([{"id": 501, "linkedClubIds": [502]}, {"id": 502, "linkedClubIds": []}])
        rows = [
            card(1, "Ada North", 70, ["ST"], 501, 11, 21, 100),
            card(2, "Bea South", 70, ["ST"], 502, 11, 21, 120),
        ]
        pool, _kept, storage, left = make_pool(rows, root=root)
        linked = prepare_spec(
            {
                "id": 13,
                "name": "Linked count",
                "slots": ["ST", "ST"],
                "n": 2,
                "chem": 0,
                "minr": 0,
                "clubs_max": 1,
                "count_linked_clubs": True,
            },
            root,
        )
        separate = prepare_spec(
            {
                "id": 14,
                "name": "Raw count",
                "slots": ["ST", "ST"],
                "n": 2,
                "chem": 0,
                "minr": 0,
                "clubs_max": 1,
                "count_linked_clubs": False,
            },
            root,
        )
        merged = solve_sbc(linked, pool, Counter(left), storage, seconds=15)
        split = solve_sbc(separate, pool, Counter(left), storage, seconds=15)
        self.assertEqual(merged["status"], "Optimal")
        self.assertEqual(split["status"], "Infeasible")
        self.assertFalse(separate["count_linked_clubs"])


class MatchTests(unittest.TestCase):
    def _profiles(self):
        return {
            5: {
                "resourceId": 5,
                "name": "Ada Striker",
                "rating": 70,
                "versionId": 0,
                "clubId": 10,
                "countryId": 30,
            },
            6: {
                "resourceId": 6,
                "name": "José Northwind",
                "rating": 81,
                "versionId": 0,
                "clubId": 11,
                "countryId": 45,
            },
            7: {
                "resourceId": 7,
                "name": "Rafa Northwind",
                "rating": 84,
                "versionId": 0,
                "clubId": 12,
                "countryId": 46,
            },
            8: {
                "resourceId": 8,
                "name": "Rafa Southwind",
                "rating": 84,
                "versionId": 0,
                "clubId": 13,
                "countryId": 46,
            },
            9: {
                "resourceId": 9,
                "name": "Id Only Card",
                "rating": 77,
                "versionId": 1,
                "clubId": 14,
                "countryId": 47,
            },
        }

    def test_fold_and_id_and_short_name(self):
        self.assertEqual(fold_name("José Northwind"), "jose northwind")
        rows = [
            {"resourceId": 9, "name": "Wrong Label", "rating": 10, "version": "", "price_pc": 1},
            {"name": "JOSE NORTHWIND", "rating": 81, "version": "", "price_pc": 2},
            {"name": "Rafa", "rating": 84, "club_id": 12, "nation_id": 46, "version": "", "price_pc": 3},
            {"name": "Rafa", "rating": 84, "version": "", "price_pc": 4},
            {"name": "Nobody Synthetic", "rating": 60, "version": "", "price_pc": 5},
        ]
        items, issues = match_futbin_players(rows, self._profiles(), [])
        by_name = {row["displayName"]: row for row in items}
        self.assertEqual(by_name["Wrong Label"]["resourceId"], 9)
        self.assertEqual(by_name["JOSE NORTHWIND"]["resourceId"], 6)
        rafa_rows = [row for row in items if row["displayName"] == "Rafa"]
        self.assertEqual(rafa_rows[0]["resourceId"], 7)
        self.assertLess(rafa_rows[1]["resourceId"], 0)
        reasons = {issue["name"]: issue["reason"] for issue in issues}
        self.assertEqual(reasons["Nobody Synthetic"], "unmatched")
        self.assertEqual(reasons["Rafa"], "ambiguous")
        buffer = io.StringIO()
        with redirect_stdout(buffer):
            futbin_to_inventory({"players": rows, "xi": []}, self._profiles())
        text = buffer.getvalue()
        self.assertIn("unmatched", text)
        self.assertIn("Nobody Synthetic", text)
        self.assertIn("ambiguous", text)


class ParallelAndPlanTests(unittest.TestCase):
    def test_parallel_matches_sequential_objectives(self):
        shared = card(1, "Ada Shared", 80, ["ST", "GK"], 1, 1, 1, 40, meta3=40)
        other = card(2, "Bea Other", 78, ["GK"], 2, 1, 2, 90, meta3=40)
        pool, _kept, storage, left = make_pool([shared, other])
        first = prepare_spec({"id": 1, "name": "High", "slots": ["ST"], "n": 1, "chem": 0, "minr": 0, "sequence": 0})
        second = prepare_spec({"id": 2, "name": "Low", "slots": ["GK"], "n": 1, "chem": 0, "minr": 0, "sequence": 1})
        serial, _skipped = solve_squads([first, second], pool, Counter(left), storage, seconds=15, jobs=1)
        parallel, _skipped = solve_squads([second, first], pool, Counter(left), storage, seconds=15, jobs=2)
        self.assertEqual([squad["status"] for squad in serial], ["Optimal", "Optimal"])
        self.assertEqual([squad["status"] for squad in parallel], ["Optimal", "Optimal"])
        self.assertEqual(
            [(squad["id"], squad["cash"], squad["fodder"]) for squad in serial],
            [(squad["id"], squad["cash"], squad["fodder"]) for squad in parallel],
        )
        self.assertTrue(any(squad.get("search") == "parallel" for squad in parallel))

    def test_plan_warm_start_uses_resource_ids(self):
        pool, _kept, storage, left = make_pool([card(1, "Ada Start", 70, ["ST"], 1, 1, 1, 25, meta3=40)])
        spec = prepare_spec({"id": 3, "name": "Plan", "slots": ["ST"], "n": 1, "chem": 0, "minr": 0})
        first = solve_sbc(spec, pool, Counter(left), storage, seconds=15)
        self.assertEqual(first["status"], "Optimal")
        again = solve_sbc(spec, pool, Counter(left), storage, seconds=15, plan_squads=[first])
        self.assertEqual(again["status"], "Optimal")
        self.assertEqual(again["warm_start_source"], "plan")
        self.assertEqual(again["cash"], first["cash"])
        bogus = solve_sbc(
            spec,
            pool,
            Counter(left),
            storage,
            seconds=15,
            plan_squads=[{"id": 3, "players": [{"rid": 999, "name": "Missing"}]}],
        )
        self.assertEqual(bogus["status"], "Optimal")
        self.assertNotEqual(bogus["warm_start_source"], "plan")


class BenchmarkShapeTests(unittest.TestCase):
    def test_synthetic_benchmark_case_is_fake_and_large(self):
        spec, pool, left, _storage = synthetic_case(1000)
        self.assertEqual(spec["n"], 8)
        self.assertEqual(len(pool), 1000)
        self.assertGreaterEqual(sum(left.values()), 800)
        self.assertTrue(all(card["name"].startswith("Synthetic ") for card in pool))
        self.assertEqual(len({card["name"] for card in pool}), 1000)


class CpsatTests(unittest.TestCase):
    def test_cpsat_matches_highs_when_installed(self):
        probe = subprocess.run(
            [sys.executable, "-c", "import ortools.sat.python.cp_model"],
            capture_output=True,
            check=False,
        )
        if probe.returncode != 0:
            self.skipTest("ortools is not installed")
        spec = prepare_spec(
            {"id": 15, "name": "Cross", "slots": ["ST", "ST"], "n": 2, "chem": 2, "minr": 0}
        )
        pool, _kept, storage, left = _owned_market(
            [
                ("Ada Cross", 75, ["ST"], 5, 2, 3, 40, True),
                ("Bea Cross", 76, ["ST"], 5, 2, 4, 50, False),
                ("Cara Other", 80, ["ST"], 6, 3, 5, 15, False),
            ]
        )
        highs = solve_sbc(spec, pool, Counter(left), storage, seconds=20, engine="highs")
        cpsat = solve_sbc(spec, pool, Counter(left), storage, seconds=20, engine="cpsat", threads=2)
        self.assertEqual(highs["status"], "Optimal")
        self.assertEqual(cpsat["status"], "Optimal")
        self.assertEqual(cpsat["engine"], "cpsat")
        self.assertEqual((cpsat["cash"], cpsat["fodder"]), (highs["cash"], highs["fodder"]))
        self.assertEqual(cpsat["mip_gap"], 0)


if __name__ == "__main__":
    unittest.main()
