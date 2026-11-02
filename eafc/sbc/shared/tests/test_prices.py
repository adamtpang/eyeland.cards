"""Price quotes, staleness, and recheck. No network."""

import json
import tempfile
import unittest
import urllib.request
from collections import Counter
from datetime import datetime, timedelta, timezone
from pathlib import Path
from unittest.mock import patch

from eafc.sbc.shared.cli import main
from eafc.sbc.shared.inventory import build_pool
from eafc.sbc.shared.model import solve_sbc
from eafc.sbc.shared.prices import (
    EasySbcCatalogue,
    FileBinProvider,
    FUTBIN_LIVE_REASON,
    Quote,
    apply_quotes,
    build_provider,
    is_stale,
    price_moved,
    recheck_buys,
    require_platform,
)
from eafc.sbc.shared.specs import prepare_spec
from eafc.sbc.shared.tests.test_shared_solver import card, make_pool

NOW = datetime(2026, 11, 2, 1, 0, tzinfo=timezone.utc)


def quote(amount, minutes_ago, source="file"):
    fetched = None if minutes_ago is None else (NOW - timedelta(minutes=minutes_ago)).isoformat()
    return Quote(amount, source, "pc", fetched, "file" if source != "easysbc" else "approximate")


class Scripted:
    def __init__(self, batches):
        self.batches = batches
        self.calls = []

    def quotes(self, resource_ids, platform, now=None):
        del now
        self.calls.append((tuple(resource_ids), platform))
        batch = self.batches[min(len(self.calls) - 1, len(self.batches) - 1)]
        return {int(item): batch[int(item)] for item in resource_ids if int(item) in batch}


class PlatformTests(unittest.TestCase):
    def test_platform_is_required(self):
        self.assertEqual(require_platform("PC"), "pc")
        self.assertEqual(require_platform("xbox"), "xbox")
        for blank in ("", None, "switch", "  "):
            with self.assertRaises(SystemExit) as caught:
                require_platform(blank)
            self.assertIn("Refusing to guess", str(caught.exception))

    def test_solve_refuses_when_config_has_no_platform(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "config.json"
            path.write_text(json.dumps({"platform": "", "inventory_paths": []}), encoding="utf-8")
            with self.assertRaises(SystemExit) as caught:
                main(["solve", "--config", str(path)])
            self.assertIn("platform", str(caught.exception).lower())


class StaleAndMissingTests(unittest.TestCase):
    def test_staleness_uses_the_timestamp(self):
        self.assertFalse(is_stale((NOW - timedelta(minutes=14)).isoformat(), NOW, 15))
        self.assertTrue(is_stale((NOW - timedelta(minutes=16)).isoformat(), NOW, 15))
        self.assertTrue(is_stale(None, NOW, 15))
        self.assertFalse(price_moved(1000, 1050, pct=5, coins=100))
        self.assertTrue(price_moved(1000, 1100, pct=5, coins=100))
        self.assertTrue(price_moved(200, 230, pct=5, coins=100))
        self.assertFalse(price_moved(200, 209, pct=5, coins=100))

    def test_missing_quote_is_excluded_from_buys_and_not_free(self):
        owned_item, owned_profile = card(1, "Ada Owned", 70, ["ST"], 1, 1, 1, 40, meta3=40)
        market = card(2, "Bea Market", 70, ["ST"], 2, 1, 2, 80, meta3=40)[1]
        profiles = {1: owned_profile, 2: market}
        quotes = {
            1: quote(None, 1),
            2: quote(None, 1),
        }
        unquoted, _stale = apply_quotes(profiles, {1}, quotes, "pc", NOW, 15)
        self.assertEqual([row["rid"] for row in unquoted], [2])
        self.assertEqual(market["priceInfo"]["displayPrice"], 0)
        self.assertNotEqual(owned_profile["priceInfo"]["displayPrice"], 0)
        pool, _kept, _storage = build_pool([owned_item], profiles, lambda value: value)
        self.assertEqual({entry["rid"] for entry in pool}, {1})
        self.assertTrue(owned_profile["price_stale"])

    def test_stale_quote_stays_buyable_and_is_flagged(self):
        market = card(3, "Cara Stale", 70, ["ST"], 3, 1, 3, 10, meta3=40)[1]
        profiles = {3: market}
        apply_quotes(profiles, set(), {3: quote(250, 40)}, "xbox", NOW, 15)
        self.assertEqual(market["priceInfo"]["displayPrice"], 250)
        self.assertTrue(market["price_stale"])
        self.assertEqual(market["price_platform"], "xbox")
        self.assertEqual(market["price_source"], "file")


class RecheckTests(unittest.TestCase):
    def _pool(self):
        ada = card(1, "Ada Bid", 70, ["ST"], 1, 1, 1, 100, meta3=40)[1]
        bea = card(2, "Bea Bid", 70, ["ST"], 2, 1, 2, 500, meta3=40)[1]
        pool, _kept, storage, left = make_pool([], extra_profiles=[ada, bea])
        return pool, storage, left

    def test_recheck_resolves_again_when_the_buy_price_moves(self):
        pool, storage, left = self._pool()
        spec = prepare_spec({"id": 7, "name": "Buy", "slots": ["ST"], "n": 1, "chem": 0, "minr": 0})
        calls = []

        def solve_once(current, left0):
            calls.append(sorted((card["rid"], card["price"]) for card in current))
            result = solve_sbc(
                spec, current, Counter(left0), storage, seconds=15, formulation="legacy", exact_model=True
            )
            return [result], []

        provider = Scripted(
            [
                {1: quote(900, 1, "futbin")},
                {2: quote(500, 1, "futbin")},
            ]
        )
        squads, _skipped, notes = recheck_buys(
            solve_once, pool, left, provider, "pc", rounds=3, now=NOW, staleness_minutes=15
        )
        self.assertEqual(len(calls), 2)
        self.assertEqual(notes[0]["moves"][0]["old"], 100)
        self.assertEqual(notes[0]["moves"][0]["new"], 900)
        self.assertFalse(notes[-1].get("unresolved"))
        self.assertEqual(squads[0]["players"][0]["name"], "Bea Bid")
        self.assertEqual(provider.calls[0][1], "pc")

    def test_missing_recheck_quote_drops_the_buy(self):
        pool, storage, left = self._pool()
        spec = prepare_spec({"id": 8, "name": "Drop", "slots": ["ST"], "n": 1, "chem": 0, "minr": 0})

        def solve_once(current, left0):
            result = solve_sbc(
                spec, current, Counter(left0), storage, seconds=15, formulation="legacy", exact_model=True
            )
            return [result], []

        provider = Scripted([{1: quote(None, 1)}, {2: quote(500, 1)}])
        # Make Ada the cheaper card so the first buy is Ada, then the recheck has no quote.
        for card_row in pool:
            if card_row["rid"] == 1:
                card_row["price"] = 50
        squads, _skipped, notes = recheck_buys(
            solve_once, pool, left, provider, "ps", rounds=3, now=NOW, staleness_minutes=15
        )
        self.assertEqual(notes[0]["excluded"][0]["rid"], 1)
        self.assertEqual(squads[0]["players"][0]["name"], "Bea Bid")
        self.assertEqual(provider.calls[0][1], "ps")


class FileProviderTests(unittest.TestCase):
    def test_bin_file_respects_platform_and_does_not_fetch(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "bin-prices.json"
            path.write_text(
                json.dumps(
                    {
                        "platform": "pc",
                        "prices": [
                            {"resource_id": 900001, "amount": 1400, "fetched_at": NOW.isoformat()}
                        ],
                    }
                ),
                encoding="utf-8",
            )
            wrong = Path(tmp) / "xbox.json"
            wrong.write_text(
                json.dumps({"platform": "xbox", "prices": [{"resource_id": 900001, "amount": 50}]}),
                encoding="utf-8",
            )
            provider = FileBinProvider("futbin", path, FUTBIN_LIVE_REASON)

            def explode(*_args, **_kwargs):
                raise AssertionError("network")

            with patch.object(urllib.request, "urlopen", explode):
                found = provider.quotes([900001, 900002], "pc", now=NOW)
            self.assertEqual(found[900001].amount, 1400)
            self.assertEqual(found[900001].source, "futbin")
            self.assertIsNone(found[900002].amount)
            self.assertIn("section 13", provider.live_reason)
            self.assertFalse(provider.live)
            skipped = FileBinProvider("futbin", wrong, FUTBIN_LIVE_REASON)
            skipped.quotes([900001], "pc", now=NOW)
            self.assertIn("ignored", skipped.warning)

    def test_manual_override_replaces_catalogue(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "price-overrides.json"
            path.write_text(
                json.dumps(
                    {
                        "platform": "pc",
                        "prices": [
                            {"resource_id": 1, "amount": 1550, "fetched_at": NOW.isoformat()}
                        ],
                    }
                ),
                encoding="utf-8",
            )
            profile = card(1, "Ada Override", 70, ["ST"], 1, 1, 1, 80, meta3=40)[1]
            provider = build_provider("easysbc", {1: profile}, overrides_path=path)
            found = provider.quotes([1], "pc", now=NOW)
            self.assertEqual(found[1].amount, 1550)
            self.assertEqual(found[1].source, "manual")
            self.assertEqual(found[1].quality, "manual")


if __name__ == "__main__":
    unittest.main()
