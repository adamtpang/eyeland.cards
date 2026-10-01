"""Helium driver over cdp_bridge.py (one held CDP connection).

  python hb.py targets                      list page targets
  python hb.py new <url>                    open tab, attach, print sessionId
  python hb.py attach <targetId>            attach to existing tab
  python hb.py nav <sid> <url>              navigate + wait for load
  python hb.py text <sid> [maxChars]        body innerText
  python hb.py eval <sid> <js>              evaluate JS (returnByValue)
  python hb.py type <sid> <selector> <text> focus element, insert text as real input
  python hb.py click <sid> <selector>       scroll into view, real mouse click at center
  python hb.py shot <sid> <file.png>        screenshot to file
  python hb.py url <sid>                    current URL + title
"""
import base64
import json
import socket
import sys
import time

PORT = 9333


def call(method, params=None, session=None, timeout=90):
    payload = {"method": method, "params": params or {}, "timeout": timeout}
    if session:
        payload["sessionId"] = session
    with socket.create_connection(("127.0.0.1", PORT), timeout=timeout + 10) as s:
        s.sendall((json.dumps(payload) + "\n").encode())
        buf = b""
        while not buf.endswith(b"\n"):
            chunk = s.recv(1 << 16)
            if not chunk:
                break
            buf += chunk
    res = json.loads(buf.decode() or "{}")
    if "error" in res:
        raise RuntimeError(f"{method}: {res['error']}")
    return res.get("result", {})


def evaluate(sid, expr, await_promise=True):
    r = call("Runtime.evaluate", {"expression": expr, "returnByValue": True,
                                  "awaitPromise": await_promise}, sid)
    if "exceptionDetails" in r:
        raise RuntimeError("JS exception: " + json.dumps(r["exceptionDetails"])[:800])
    return r.get("result", {}).get("value")


def attach(target_id):
    r = call("Target.attachToTarget", {"targetId": target_id, "flatten": True})
    sid = r["sessionId"]
    call("Page.enable", {}, sid)
    call("Runtime.enable", {}, sid)
    return sid


def wait_load(sid, timeout=25):
    t0 = time.time()
    while time.time() - t0 < timeout:
        try:
            if evaluate(sid, "document.readyState") == "complete":
                return True
        except Exception:  # noqa: BLE001
            pass
        time.sleep(0.5)
    return False


def center(sid, selector):
    evaluate(sid, f"(()=>{{const e=document.querySelector({json.dumps(selector)});"
                  f"if(!e)throw new Error('no element');e.scrollIntoView({{block:'center'}});return 1}})()")
    time.sleep(0.3)
    box = evaluate(sid, f"(()=>{{const r=document.querySelector({json.dumps(selector)})"
                        f".getBoundingClientRect();return [r.x+r.width/2, r.y+r.height/2, r.width, r.height]}})()")
    return box


def click(sid, selector):
    x, y, w, h = center(sid, selector)
    if w == 0 or h == 0:
        raise RuntimeError("element has zero size (hidden?)")
    for t in ("mouseMoved", "mousePressed", "mouseReleased"):
        call("Input.dispatchMouseEvent", {"type": t, "x": x, "y": y, "button": "left",
                                          "clickCount": 1}, sid)
    return (x, y)


def type_into(sid, selector, text):
    center(sid, selector)
    evaluate(sid, f"document.querySelector({json.dumps(selector)}).focus()")
    call("Input.insertText", {"text": text}, sid)
    return evaluate(sid, f"document.querySelector({json.dumps(selector)}).value")


def main():
    a = sys.argv[1:]
    cmd = a[0]
    if cmd == "targets":
        ts = call("Target.getTargets")["targetInfos"]
        for t in ts:
            if t["type"] == "page":
                print(t["targetId"], "|", t["url"][:90], "|", t["title"][:60])
    elif cmd == "new":
        tid = call("Target.createTarget", {"url": a[1]})["targetId"]
        sid = attach(tid)
        wait_load(sid)
        print("targetId", tid)
        print("sessionId", sid)
    elif cmd == "attach":
        print("sessionId", attach(a[1]))
    elif cmd == "nav":
        call("Page.navigate", {"url": a[2]}, a[1])
        print("loaded" if wait_load(a[1]) else "load timeout")
    elif cmd == "text":
        n = int(a[2]) if len(a) > 2 else 3000
        print(evaluate(a[1], f"document.body.innerText.slice(0,{n})"))
    elif cmd == "eval":
        v = evaluate(a[1], a[2])
        print(json.dumps(v, indent=1, ensure_ascii=False)[:8000] if not isinstance(v, str) else v[:8000])
    elif cmd == "type":
        print("value now:", type_into(a[1], a[2], a[3])[:300])
    elif cmd == "typefile":
        with open(a[3], encoding="utf-8") as f:
            text = f.read().rstrip("\n")
        print("value now:", type_into(a[1], a[2], text)[:1200])
    elif cmd == "click":
        print("clicked at", click(a[1], a[2]))
    elif cmd == "shot":
        data = call("Page.captureScreenshot", {"format": "png"}, a[1])["data"]
        with open(a[2], "wb") as f:
            f.write(base64.b64decode(data))
        print("saved", a[2])
    elif cmd == "url":
        print(evaluate(a[1], "location.href + ' | ' + document.title"))
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
