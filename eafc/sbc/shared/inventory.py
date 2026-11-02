"""Club inventory, meta protection, and the buyable player pool.

Owned cards come from an EasySBC export (``easy-inventory.json``). A FUTBIN
``club_futbin.json`` (keys ``imported``, ``read``, ``xi``, ``players``) is
only a fallback, joined onto EasySBC player profiles. The loader uses whichever
configured file was modified most recently and prints that path and timestamp.

Protection matches the canonical Marquee solver, in the same order:

* special / loan versions (``versionId`` not 0 or 1)
* a name substring from the local protect file (saved squads have no export field)
* ``activeSquad``
* a card with no player profile
* rating 84+ when ``--net`` is on, storage included
* club rating 84+ when ``--keep84`` is on; SBC Storage copies stay usable
* inventory ``price`` above 2000 when ``--keep84`` is on
* chem-3 meta >= 85, unless the card is in SBC Storage

Chem-3 meta is the max ``metaRating`` whose ``chemistry`` is 3. Other
chemistry rows do not count. ``transferList`` and ``isObjectivePlayer`` are
not protection rules in the canonical solver, so they are not rules here.
"""

import json
import unicodedata
from datetime import datetime
from pathlib import Path

# Canonical market caps: ordinary cards above 1300 are not worth searching,
# except the two big anchor clubs used by Milano v Lombardia.
DEFAULT_PRICE_CAP = 1300
DEFAULT_ANCHOR_BIG = (131681, 131682)
DEFAULT_ANCHOR_BIG_CAP = 6000

_FUTBIN_BASIC_VERSIONS = {"", "normal", "gold", "rare", "common"}


def read_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8-sig"))


def chem3_meta(profile):
    ratings = profile.get("metaRatings") or []
    values = [row["metaRating"] for row in ratings if row["chemistry"] == 3]
    return max(values or [0])


def with_meta(profile):
    if "maxMeta" in profile:
        return profile
    return {**profile, "maxMeta": chem3_meta(profile)}


def load_profiles(directory):
    """Load ``player-*.json`` profiles and attach chem-3 ``maxMeta``."""
    profiles = {}
    folder = Path(directory)
    if not folder.is_dir():
        return profiles
    for path in sorted(folder.glob("player-*.json")):
        profile = with_meta(read_json(path))
        profiles[profile["resourceId"]] = profile
    return profiles


def inventory_kind(document):
    if not isinstance(document, dict) or not isinstance(document.get("players"), list):
        return None
    if "xi" in document and ("imported" in document or "read" in document):
        return "futbin"
    players = document["players"]
    if "stats" in document or "plat" in document:
        return "easysbc"
    if players and isinstance(players[0], dict) and "resourceId" in players[0]:
        return "easysbc"
    return None


def select_inventory_path(paths):
    """Pick the newest existing file. Equal mtimes keep the earlier path."""
    existing = [Path(path) for path in paths if Path(path).is_file()]
    if not existing:
        listed = ", ".join(str(path) for path in paths) or "(none configured)"
        raise FileNotFoundError(f"no inventory file found among: {listed}")
    return max(existing, key=lambda path: path.stat().st_mtime)


def _stamp(path):
    modified = path.stat().st_mtime
    iso = datetime.fromtimestamp(modified).isoformat(timespec="seconds")
    return modified, iso


def _xi_active(name, xi_rows):
    folded = (name or "").casefold()
    if not folded:
        return False
    for row in xi_rows or []:
        slot = (row.get("name") or "").casefold()
        if slot and (slot in folded or folded in slot):
            return True
    return False


def _futbin_version_id(version):
    text = version or ""
    if "loan" in text.casefold() or text.casefold() not in _FUTBIN_BASIC_VERSIONS:
        return 2
    return 0


def fold_name(name):
    """Case-fold, strip accents, and collapse punctuation to spaces."""
    text = unicodedata.normalize("NFKD", name or "")
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    cleaned = []
    for ch in text.casefold():
        cleaned.append(ch if ch.isalnum() else " ")
    return " ".join("".join(cleaned).split())


def _row_resource_ids(row):
    found = []
    for key in ("resourceId", "resource_id", "playerResourceId", "player_resource_id"):
        value = row.get(key)
        if value in (None, ""):
            continue
        try:
            found.append(int(value))
        except (TypeError, ValueError):
            continue
    return found


def _short_name_match(row_folded, profile_folded):
    """A single-token name may match the other side's first token.

    'Rafa' against 'Rafa Northwind' is the shape this covers. Tokens shorter
    than 3 characters are ignored so a one-letter export cannot attach itself
    to every card.
    """
    row_tokens = row_folded.split()
    profile_tokens = profile_folded.split()
    if len(row_tokens) == 1 and len(profile_tokens) > 1 and len(row_tokens[0]) >= 3:
        return row_tokens[0] == profile_tokens[0]
    if len(profile_tokens) == 1 and len(row_tokens) > 1 and len(profile_tokens[0]) >= 3:
        return profile_tokens[0] == row_tokens[0]
    return False


def _tie_score(row, profile):
    score = 0
    club = row.get("club_id", row.get("clubId"))
    nation = row.get("nation_id", row.get("countryId", row.get("nationId")))
    try:
        if club is not None and int(club) == int(profile.get("clubId")):
            score += 2
    except (TypeError, ValueError):
        pass
    try:
        if nation is not None and int(nation) == int(profile.get("countryId")):
            score += 1
    except (TypeError, ValueError):
        pass
    return score


def _prefer_normal(profiles):
    normals = [profile for profile in profiles if profile.get("versionId") in (0, 1)]
    return normals or list(profiles)


def match_futbin_players(rows, profiles, xi_rows=()):
    """Join FUTBIN club rows onto EasySBC profiles.

    Order: resource id, then accent-folded exact name plus rating, then a
    single-token short name plus rating. Rating is required for name matches.
    Club id and nation id break ties when the row carries them. Ambiguous
    name matches are not guessed. Every unmatched row is returned with a
    synthetic id and an issue record; nothing is dropped.
    """
    by_id = {}
    by_exact = {}
    by_rating = {}
    for profile in profiles.values():
        resource_id = profile.get("resourceId")
        if resource_id is None:
            continue
        by_id[int(resource_id)] = profile
        folded = fold_name(profile.get("name") or profile.get("displayName") or "")
        rating = profile.get("rating")
        by_exact.setdefault((folded, rating), []).append(profile)
        by_rating.setdefault(rating, []).append(profile)

    items = []
    issues = []
    synthetic = -1
    for row in rows or []:
        name = row.get("name") or row.get("displayName") or ""
        rating = row.get("rating") or 0
        profile = None
        reason = None
        for resource_id in _row_resource_ids(row):
            profile = by_id.get(resource_id)
            if profile is not None:
                break
        if profile is None and row.get("id") not in (None, ""):
            try:
                profile = by_id.get(int(row.get("id")))
            except (TypeError, ValueError):
                profile = None
        if profile is None:
            folded = fold_name(name)
            exact = _prefer_normal(by_exact.get((folded, rating), []))
            if len(exact) == 1:
                profile = exact[0]
            elif len(exact) > 1:
                ranked = sorted(exact, key=lambda item: _tie_score(row, item), reverse=True)
                if _tie_score(row, ranked[0]) > _tie_score(row, ranked[1]):
                    profile = ranked[0]
                else:
                    reason = "ambiguous"
            else:
                short = [
                    item
                    for item in by_rating.get(rating, [])
                    if _short_name_match(folded, fold_name(item.get("name") or ""))
                ]
                short = _prefer_normal(short)
                if len(short) == 1:
                    profile = short[0]
                elif len(short) > 1:
                    ranked = sorted(short, key=lambda item: _tie_score(row, item), reverse=True)
                    if _tie_score(row, ranked[0]) > 0 and _tie_score(row, ranked[0]) > _tie_score(row, ranked[1]):
                        profile = ranked[0]
                    else:
                        reason = "ambiguous"
                else:
                    reason = "unmatched"
        version_id = _futbin_version_id(row.get("version"))
        if profile is not None and version_id in (0, 1):
            version_id = profile.get("versionId", 0)
        if profile is None:
            if reason is None:
                reason = "unmatched"
            issues.append({"name": name, "rating": rating, "reason": reason})
            resource_id = synthetic
            synthetic -= 1
        else:
            resource_id = profile["resourceId"]
        items.append(
            {
                "resourceId": resource_id,
                "displayName": name,
                "rating": rating,
                "versionId": version_id,
                "activeSquad": _xi_active(name, xi_rows),
                "sbcStorage": False,
                "price": int(row.get("price_pc") or 0),
                "untradeable": not row.get("tradeable", True),
            }
        )
    return items, issues


def futbin_to_inventory(document, profiles):
    """Map a FUTBIN club export onto EasySBC profile ids.

    SBC Storage is not in this export, so every mapped card has
    ``sbcStorage`` false. Starting XI names become ``activeSquad``. A FUTBIN
    row that matches no profile is kept with a synthetic id and later
    protected as "no profile" so it cannot be spent by accident. Unmatched
    and ambiguous rows are printed; they are not dropped.
    """
    items, issues = match_futbin_players(document.get("players") or [], profiles or {}, document.get("xi") or [])
    for issue in issues:
        print(
            f"futbin {issue['reason']}: {issue['name']!r} rating {issue['rating']}",
            flush=True,
        )
    if issues:
        print(f"futbin name match: {len(issues)} unmatched or ambiguous row(s)", flush=True)
    return items


def load_inventory(paths, profiles=None):
    """Load the newest inventory and print the file and timestamp used."""
    path = select_inventory_path(paths)
    modified, iso = _stamp(path)
    document = read_json(path)
    kind = inventory_kind(document)
    if kind is None:
        raise ValueError(f"{path} is neither an EasySBC export nor a FUTBIN club file")
    if kind == "easysbc":
        players = [row for row in document["players"] if "resourceId" in row]
        note = "EasySBC export"
    else:
        players = futbin_to_inventory(document, profiles or {})
        note = "FUTBIN club fallback (no SBC Storage field; XI mapped to activeSquad)"
    print(f"inventory {path} [{note}] mtime {iso}", flush=True)
    return {
        "path": path,
        "kind": kind,
        "mtime": modified,
        "mtime_iso": iso,
        "players": players,
    }


def load_name_list(path):
    """Protect / consumed files: a JSON list, or ``{"names": [...]}``."""
    if not path or not Path(path).is_file():
        return []
    raw = read_json(path)
    if isinstance(raw, list):
        return [str(item) for item in raw]
    return [str(item) for item in raw.get("names", [])]


def _profile_price(profile):
    info = profile.get("priceInfo") or {}
    return int(info.get("displayPrice") or profile.get("price") or 0)


def classify_inventory(players, profiles, protect_names, *, net=False, keep84=False):
    """Split an export into usable owned counts, kept rows, and storage ids."""
    owned = {}
    kept = []
    storage = {row["resourceId"] for row in players if row.get("sbcStorage")}
    normalized = {rid: with_meta(profile) for rid, profile in profiles.items()}
    for row in players:
        if "resourceId" not in row:
            continue
        profile = normalized.get(row["resourceId"])
        name = row.get("displayName") or row.get("name") or ""
        why = None
        version = row.get("versionId")
        if version not in (0, 1):
            why = "special"
        elif any(token in name for token in protect_names):
            why = "protected"
        elif row.get("activeSquad"):
            why = "active squad"
        elif not profile:
            why = "no profile"
        elif net and row.get("rating", 0) >= 84:
            why = "84+ (net-cost mode keeps good fodder)"
        elif keep84 and row.get("rating", 0) >= 84 and not row.get("sbcStorage"):
            why = "club 84+ (kept; Storage copies still used)"
        elif keep84 and (row.get("price") or 0) > 2000:
            why = "high item score, saved for a streamlined SBC"
        elif not row.get("sbcStorage") and profile["maxMeta"] >= 85:
            why = f"max meta {profile['maxMeta']:.1f}"
        if why:
            kept.append((name, row.get("rating"), why))
        else:
            owned[row["resourceId"]] = owned.get(row["resourceId"], 0) + 1
    return owned, kept, storage, normalized


def build_pool(
    players,
    profiles,
    root,
    protect_names=(),
    *,
    net=False,
    keep84=False,
    price_cap=DEFAULT_PRICE_CAP,
    anchor_big=DEFAULT_ANCHOR_BIG,
    anchor_big_cap=DEFAULT_ANCHOR_BIG_CAP,
):
    """Owned counts plus the market profiles the canonical price cap allows.

    Profiles are walked in resourceId order so a fresh run does not depend on
    directory order. That can change which equal-cost card a solver tie picks
    versus the original script's glob order; the objective is unchanged.
    """
    owned, kept, storage, normalized = classify_inventory(
        players, profiles, protect_names, net=net, keep84=keep84
    )
    big = {root(club) for club in anchor_big}
    pool = []
    for rid in sorted(normalized):
        profile = normalized[rid]
        if profile.get("versionId") not in (0, 1):
            continue
        price = _profile_price(profile)
        copies = owned.get(rid, 0)
        cap = anchor_big_cap if root(profile["clubId"]) in big else price_cap
        if not copies and (not price or price > cap):
            continue
        positions = profile.get("possiblePositions") or []
        pool.append(
            {
                "rid": rid,
                "asset": profile.get("assetId", rid),
                "name": profile.get("name") or profile.get("displayName") or str(rid),
                "rating": int(profile.get("rating") or 0),
                "price": price,
                "own": copies,
                "club": root(profile["clubId"]),
                "club_raw": int(profile["clubId"]),
                "version": int(profile.get("versionId") or 0),
                "league": profile.get("leagueId"),
                "nation": profile.get("countryId"),
                "pos": set(positions),
                "meta": profile["maxMeta"],
                "score": profile.get("itemScore", 0),
            }
        )
    return pool, kept, storage


def apply_consumed(pool, left, names):
    """Decrement one owned copy per consumed name, first exact pool-name match."""
    for name in names:
        rid = next((card["rid"] for card in pool if card["name"] == name and left[card["rid"]] > 0), None)
        if rid is None:
            print(f"consumed name not in owned pool: {name}", flush=True)
        else:
            left[rid] -= 1
