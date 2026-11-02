"""Buy-price quotes for one platform.

The platform is ``ps``, ``xbox``, or ``pc`` and comes from config. A missing
platform is an error. Quotes carry source, platform, and ``fetched_at``.
A quote older than the staleness window (default 15 minutes), or one with no
timestamp, is stale. A market card with no current amount is not buyable and
is not priced at zero.

Live lowest-BIN fetches are not performed.

* FUTBIN terms section 13 prohibit scraping or data mining without written
  permission (https://www.futbin.com/tos). ``robots.txt`` disallows
  query-string URLs. A direct request from this environment received HTTP 403
  with a Cloudflare challenge.
* fut.gg is covered by the Stormstrike terms (https://stormstrike.gg/terms),
  which prohibit automated access or scraping unless expressly permitted.
  ``robots.txt`` disallows ``/api/*``. No express permission for price fetches
  was found.

Both site providers read a local JSON file the owner fills, for example from
their own browser. A manual override file wins over that file and over the
EasySBC catalogue.
"""

import json
from dataclasses import asdict, dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path

PLATFORMS = ("ps", "xbox", "pc")
USER_AGENT = "eyeland-sbc-solver/1.0 (+https://github.com/adamtpang/eyeland.cards)"

FUTBIN_LIVE_REASON = (
    "FUTBIN terms section 13 prohibit scraping or data mining without written "
    "permission (https://www.futbin.com/tos). robots.txt disallows query-string "
    "URLs. A direct request from this environment got HTTP 403 with a Cloudflare "
    "challenge. Put lowest BIN rows in the local bin-prices file instead."
)
FUTGG_LIVE_REASON = (
    "Stormstrike terms for fut.gg prohibit automated access or scraping unless "
    "expressly permitted (https://stormstrike.gg/terms). robots.txt disallows "
    "/api/*. No express permission for price fetches was found. Put lowest BIN "
    "rows in the local bin-prices file instead."
)


class LivePricesUnavailable(Exception):
    """Raised when a site must not be fetched. No request is made."""


@dataclass
class Quote:
    amount: int | None
    source: str
    platform: str
    fetched_at: str | None
    quality: str

    def as_dict(self):
        return asdict(self)


def require_platform(value):
    """Return ps, xbox, or pc. Refuse anything else, including a blank."""
    text = str(value or "").strip().lower()
    if text not in PLATFORMS:
        raise SystemExit(
            "platform is required in config.json and must be one of ps, xbox, pc. Refusing to guess."
        )
    return text


def parse_time(value):
    if not value:
        return None
    text = str(value).strip()
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        parsed = datetime.fromisoformat(text)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def is_stale(fetched_at, now, minutes):
    """A missing timestamp is stale. ``minutes`` is the maximum age."""
    moment = parse_time(fetched_at)
    if moment is None:
        return True
    current = now if now.tzinfo else now.replace(tzinfo=timezone.utc)
    return current - moment > timedelta(minutes=float(minutes))


def price_moved(old, new, *, pct=5, coins=100):
    """True when the change is beyond either the percent or the coin tolerance."""
    if old is None or new is None:
        return True
    old_i, new_i = int(old), int(new)
    if old_i <= 0:
        return new_i != old_i
    delta = abs(new_i - old_i)
    return delta > int(coins) or (delta / old_i) > (float(pct) / 100.0)


def _read_price_file(path, platform):
    """Rows whose platform matches. Wrong-platform files are ignored."""
    file = Path(path) if path else None
    if file is None or not file.is_file():
        return {}, None
    raw = json.loads(file.read_text(encoding="utf-8-sig"))
    file_platform = str(raw.get("platform") or "").strip().lower()
    if file_platform != platform:
        return {}, f"{file.name} is for {file_platform or 'an unset platform'}, not {platform}; ignored"
    rows = raw.get("prices") or raw.get("quotes") or []
    found = {}
    if isinstance(rows, dict):
        items = [{"resource_id": key, **(value if isinstance(value, dict) else {"amount": value})} for key, value in rows.items()]
    else:
        items = list(rows)
    for row in items:
        try:
            resource_id = int(row.get("resource_id") or row.get("resourceId") or row.get("rid"))
        except (TypeError, ValueError):
            continue
        amount = row.get("amount", row.get("price"))
        try:
            amount = int(amount) if amount is not None else None
        except (TypeError, ValueError):
            amount = None
        if amount is not None and amount <= 0:
            amount = None
        found[resource_id] = Quote(
            amount=amount,
            source=row.get("source") or "file",
            platform=platform,
            fetched_at=row.get("fetched_at"),
            quality=row.get("quality") or "file",
        )
    return found, None


def write_cache(path, platform, quotes, *, source):
    """Persist the quotes just used. The file is local and gitignored."""
    if not path:
        return
    file = Path(path)
    file.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "platform": platform,
        "source": source,
        "prices": [
            {"resource_id": rid, **quote.as_dict()}
            for rid, quote in sorted(quotes.items())
        ],
    }
    file.write_text(json.dumps(payload, indent=1), encoding="utf-8")


class EasySbcCatalogue:
    """Approximate catalogue prices already on EasySBC profiles.

    These are not lowest BIN and are not platform-specific. The configured
    platform is stamped on the quote so the plan shows which market the run
    is for. ``quality`` stays ``approximate``.
    """

    name = "easysbc"
    live = False
    live_reason = "EasySBC displayPrice is an approximate catalogue price, not a live lowest BIN."

    def __init__(self, profiles):
        self.profiles = profiles

    def quotes(self, resource_ids, platform, now=None):
        del now
        found = {}
        for resource_id in resource_ids:
            profile = self.profiles.get(int(resource_id)) or self.profiles.get(resource_id)
            if not profile:
                found[int(resource_id)] = Quote(None, self.name, platform, None, "approximate")
                continue
            info = profile.get("priceInfo") or {}
            raw = info.get("displayPrice", profile.get("price"))
            try:
                amount = int(raw) if raw else None
            except (TypeError, ValueError):
                amount = None
            if amount is not None and amount <= 0:
                amount = None
            found[int(resource_id)] = Quote(
                amount,
                self.name,
                platform,
                profile.get("_price_file_mtime"),
                "approximate",
            )
        return found


class FileBinProvider:
    """Lowest BIN rows from a local file. Does not contact the site."""

    live = False

    def __init__(self, name, path, reason, *, quality="file"):
        self.name = name
        self.path = path
        self.live_reason = reason
        self.quality = quality

    def quotes(self, resource_ids, platform, now=None):
        del now
        rows, warning = _read_price_file(self.path, platform)
        self.warning = warning
        found = {}
        for resource_id in resource_ids:
            quote = rows.get(int(resource_id))
            if quote is None:
                found[int(resource_id)] = Quote(None, self.name, platform, None, self.quality)
            else:
                found[int(resource_id)] = Quote(
                    quote.amount, self.name, platform, quote.fetched_at, self.quality
                )
        return found


class ManualOverrides:
    name = "manual"
    live = False
    live_reason = "Spot prices typed into the local override file."

    def __init__(self, path):
        self.path = path

    def quotes(self, resource_ids, platform, now=None):
        del now
        rows, warning = _read_price_file(self.path, platform)
        self.warning = warning
        found = {}
        for resource_id in resource_ids:
            quote = rows.get(int(resource_id))
            if quote is None or quote.amount is None:
                continue
            found[int(resource_id)] = Quote(
                quote.amount, "manual", platform, quote.fetched_at, "manual"
            )
        return found


def build_provider(name, profiles, *, bin_path=None, overrides_path=None):
    """The catalogue, or a file-backed FUTBIN / fut.gg provider, plus overrides."""
    chosen = (name or "easysbc").strip().lower()
    if chosen == "easysbc":
        base = EasySbcCatalogue(profiles)
    elif chosen == "futbin":
        base = FileBinProvider("futbin", bin_path, FUTBIN_LIVE_REASON)
    elif chosen == "futgg":
        base = FileBinProvider("futgg", bin_path, FUTGG_LIVE_REASON)
    else:
        raise SystemExit(f"unknown price_provider {name!r}. Use easysbc, futbin, or futgg.")
    return LayeredProvider(base, ManualOverrides(overrides_path) if overrides_path else None)


class LayeredProvider:
    def __init__(self, base, overrides):
        self.base = base
        self.overrides = overrides
        self.name = base.name
        self.live = False
        self.live_reason = base.live_reason

    def quotes(self, resource_ids, platform, now=None):
        found = self.base.quotes(resource_ids, platform, now=now)
        self.warning = getattr(self.base, "warning", None)
        if self.overrides is None:
            return found
        over = self.overrides.quotes(resource_ids, platform, now=now)
        if getattr(self.overrides, "warning", None):
            self.warning = self.overrides.warning
        found.update(over)
        return found


def apply_quotes(profiles, owned_ids, quotes, platform, now, staleness_minutes):
    """Stamp quotes onto profiles. Market cards with no amount are priced at 0.

    Returning them at 0 makes ``build_pool`` drop them as buys. Owned cards
    stay. Stale quotes are kept and flagged.
    """
    unquoted = []
    stale = []
    for resource_id, profile in list(profiles.items()):
        quote = quotes.get(int(resource_id))
        owned = int(resource_id) in owned_ids
        amount = None if quote is None else quote.amount
        fetched_at = None if quote is None else quote.fetched_at
        source = quote.source if quote else "missing"
        quality = quote.quality if quote else "missing"
        stale_flag = amount is None or is_stale(fetched_at, now, staleness_minutes)
        profile["price_source"] = source
        profile["price_platform"] = platform
        profile["price_fetched_at"] = fetched_at
        profile["price_quality"] = quality
        profile["price_stale"] = stale_flag
        if amount is None:
            if not owned:
                info = profile.setdefault("priceInfo", {})
                info["displayPrice"] = 0
                unquoted.append(
                    {
                        "rid": int(resource_id),
                        "name": profile.get("name") or profile.get("displayName") or str(resource_id),
                        "rating": profile.get("rating"),
                        "reason": "no current quote",
                    }
                )
            else:
                stale.append(
                    {
                        "rid": int(resource_id),
                        "name": profile.get("name") or str(resource_id),
                        "reason": "owned card has no current quote; fodder keeps the catalogue price",
                    }
                )
            continue
        info = profile.setdefault("priceInfo", {})
        info["displayPrice"] = int(amount)
        if stale_flag:
            stale.append(
                {
                    "rid": int(resource_id),
                    "name": profile.get("name") or str(resource_id),
                    "amount": int(amount),
                    "fetched_at": fetched_at,
                    "reason": "stale",
                }
            )
    return unquoted, stale


def buy_rows(squads):
    rows = []
    for squad in squads or []:
        for player in squad.get("players") or []:
            if player.get("owned"):
                continue
            if not player.get("cash"):
                continue
            rows.append(player)
    return rows


def recheck_buys(
    solve_once,
    pool,
    left,
    provider,
    platform,
    *,
    rounds=3,
    pct=5,
    coins=100,
    now=None,
    staleness_minutes=15,
):
    """Solve, then re-quote every buy. Re-solve when a price moves or disappears.

    At most ``rounds`` solves. A move on the last solve is reported and not
    solved again.
    """
    now = now or datetime.now(timezone.utc)
    notes = []
    squads, skipped = [], []
    for attempt in range(1, int(rounds) + 1):
        squads, skipped = solve_once(pool, left)
        buys = buy_rows(squads)
        quotes = provider.quotes([row["rid"] for row in buys], platform, now=now) if buys else {}
        moves = []
        excluded = []
        by_rid = {card["rid"]: card for card in pool}
        for row in buys:
            card = by_rid.get(row["rid"])
            quote = quotes.get(int(row["rid"]))
            current = None if quote is None else quote.amount
            if current is None:
                excluded.append(
                    {
                        "rid": row["rid"],
                        "name": row.get("name"),
                        "old": None if card is None else card.get("price"),
                        "reason": "no current quote",
                    }
                )
                continue
            old = row.get("cash")
            if price_moved(old, current, pct=pct, coins=coins):
                moves.append(
                    {
                        "rid": row["rid"],
                        "name": row.get("name"),
                        "old": old,
                        "new": int(current),
                        "source": quote.source,
                        "fetched_at": quote.fetched_at,
                    }
                )
            if card is not None:
                card["price"] = int(current)
                card["price_source"] = quote.source
                card["price_platform"] = platform
                card["price_fetched_at"] = quote.fetched_at
                card["price_quality"] = quote.quality
                card["price_stale"] = is_stale(quote.fetched_at, now, staleness_minutes)
        if excluded:
            gone = {item["rid"] for item in excluded}
            pool[:] = [card for card in pool if card["rid"] not in gone]
        notes.append({"round": attempt, "moves": moves, "excluded": excluded})
        if not moves and not excluded:
            break
        if attempt == int(rounds):
            notes[-1]["unresolved"] = True
            break
    return squads, skipped, notes
