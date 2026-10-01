"""Read-only FUTBIN fetcher over the Helium CDP bridge (cdp.py). Results cached in %TEMP%/eafc-sbc-cache.

It only reads public FUTBIN pages. It never touches EA, the web app or the market.
"""
import hashlib
import json
import os
import time
from urllib.parse import urlencode

import cdp

CACHE = os.path.join(os.environ.get("TEMP", "/tmp"), "eafc-sbc-cache")
MAX_AGE = 3 * 3600  # prices move, so refetch after 3 hours

ROWS_JS = r"""
JSON.stringify(Array.from(document.querySelectorAll('tr')).map(r => {
  const a = r.querySelector('td a[href*="/27/player/"]');
  if (!a) return null;
  const t = alt => { const i = r.querySelector('img[alt="' + alt + '"]'); return i ? (i.title || '') : ''; };
  const txt = s => { const e = r.querySelector(s); return e ? e.innerText.trim() : ''; };
  return {
    id: a.getAttribute('href').split('/')[3],
    href: a.getAttribute('href'),
    name: a.innerText.trim().split('\n')[0],
    rating: parseInt(txt('.table-rating')) || 0,
    pos: txt('.table-pos').replace(/\+\+/g, '').split(/[\s,]+/).filter(Boolean),
    nation: t('Nation'), league: t('League'), club: t('Club'),
    price: (t => { const m = t.replace(/,/g, '').match(/([0-9.]+)\s*([KM]?)/i);
      return m ? Math.round(parseFloat(m[1]) * ({k: 1e3, m: 1e6}[m[2].toLowerCase()] || 1)) : 0; })(txt('td.platform-pc-only .price')),
  };
}).filter(Boolean))
"""

_sid = None
_blocked = False
_last_fetch = 0.0
_tid = None


def front():
    """Bring the FUTBIN tab forward: background tabs do not render SPA content."""
    if _tid:
        cdp.call("Target.activateTarget", {"targetId": _tid})
OFFLINE = os.environ.get("FUTBIN_OFFLINE") == "1"  # prefer cached prices, fetch only what is missing


def _mark_blocked():
    global _blocked
    if not _blocked:
        print("FUTBIN returned 403 (rate limited): using cached prices, which may be hours old")
    _blocked = True


def session():
    global _sid
    if _sid is None:
        global _tid
        tid = _tid = cdp.call("Target.createTarget", {"url": "about:blank"})["targetId"]
        _sid = cdp.attach(tid)
        cdp.call("Target.activateTarget", {"targetId": tid})
    return _sid


def players(**filters):
    """Cheapest-first PC player list. filters: rating=(lo,hi), nation, league, club, page."""
    q = {"pc_price": "200+", "sort": "pc_price", "order": "asc"}
    if "rating" in filters:
        lo, hi = filters.pop("rating")
        q["player_rating"] = f"{lo}-{hi}"
    q.update({k: v for k, v in filters.items() if v is not None})  # pc_price may be overridden
    url = "https://www.futbin.com/27/players?" + urlencode(q)
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, hashlib.md5(url.encode()).hexdigest() + ".json")
    cached = []
    if os.path.exists(path):
        cached = json.load(open(path, encoding="utf-8"))
        for r in cached:
            r["name"] = r["href"].rstrip("/").split("/")[-1].replace("-", " ").title()
        fresh = time.time() - os.path.getmtime(path) < MAX_AGE
        if cached and (fresh or OFFLINE or _blocked):
            return cached
    if _blocked:
        return cached
    global _sid, _last_fetch
    wait = 3 - (time.time() - _last_fetch)  # be gentle: FUTBIN 403s bulk fetching
    if wait > 0:
        time.sleep(wait)
    _last_fetch = time.time()
    try:
        sid = session()
        cdp.call("Page.navigate", {"url": url}, sid)
    except RuntimeError:
        _sid = None  # tab session dropped: open a fresh tab and retry once
        time.sleep(2)
        sid = session()
        cdp.call("Page.navigate", {"url": url}, sid)
    rows = []
    for _ in range(40):
        time.sleep(0.75)
        try:
            rows = json.loads(cdp.evaluate(sid, ROWS_JS) or "[]")
        except Exception:  # noqa: BLE001
            rows = []
        if rows and all(r["price"] for r in rows[:3]):
            break
    for r in rows:
        r["name"] = r["href"].rstrip("/").split("/")[-1].replace("-", " ").title()
    if not rows:
        if "Error - 403" in (cdp.evaluate(sid, "document.body.innerText.slice(0,200)") or ""):
            _mark_blocked()
        return cached  # never cache an empty page; fall back to the older copy
    json.dump(rows, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=0)
    return rows
