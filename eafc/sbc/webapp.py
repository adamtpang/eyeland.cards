"""Attach to the open FUT Web App tab in Helium (read-only) and remember the session."""
import os

import cdp

HERE = os.path.dirname(__file__)


def session():
    path = os.path.join(HERE, ".sid")
    if os.path.exists(path):
        sid = open(path).read().strip()
        try:
            cdp.evaluate(sid, "1")
            return sid
        except Exception:  # noqa: BLE001
            pass
    tabs = [t for t in cdp.call("Target.getTargets")["targetInfos"]
            if t["type"] == "page" and "ultimate-team/web-app" in t["url"]]
    if not tabs:
        raise SystemExit("open the FUT Web App in Helium first")
    sid = cdp.attach(tabs[0]["targetId"])
    open(path, "w").write(sid)
    return sid
