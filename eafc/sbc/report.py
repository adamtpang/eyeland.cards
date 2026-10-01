"""Turn result.json into a shopping page: live PC price and card image for each card to buy,
plus its ready-made swaps. Reads FUTBIN only, one player page every few seconds.

  python report.py            -> writes sbc-report.html next to this file
"""
import base64
import html
import json
import os
import re
import time

import cdp
import futbin

HERE = os.path.dirname(os.path.abspath(__file__))
INFO_JS = r"""JSON.stringify({price:(document.body.innerText.match(/current price on FUT is ([^.]+)\./)||[])[1]||''})"""
CARD_JS = r"""(()=>{const c=[...document.querySelectorAll('[class*="playercard"]')].map(e=>[e,e.getBoundingClientRect()])
 .filter(([e,r])=>r.width>150&&r.height>200&&r.width<500).sort((a,b)=>b[1].width*b[1].height-a[1].width*a[1].height);
 if(!c.length)return null;c[0][0].scrollIntoView({block:'center'});const r=c[0][0].getBoundingClientRect();
 return JSON.stringify([r.x,r.y,r.width,r.height])})()"""


def live(card):
    """Live PC price and a PNG of the card, from the player's FUTBIN page."""
    sid = futbin.session()
    cdp.call("Page.navigate", {"url": "https://www.futbin.com" + card["href"]}, sid)
    price, box = None, None
    for _ in range(20):
        time.sleep(1)
        try:
            txt = json.loads(cdp.evaluate(sid, INFO_JS))["price"]
            box = cdp.evaluate(sid, CARD_JS)
        except Exception:  # noqa: BLE001
            continue
        m = re.search(r"([\d,]+) on PC", txt)
        if m and box:
            price = int(m.group(1).replace(",", ""))
            break
    png = None
    if box:
        time.sleep(1.5)
        x, y, w, h = json.loads(cdp.evaluate(sid, CARD_JS))
        png = cdp.call("Page.captureScreenshot", {"format": "png", "clip": {
            "x": x, "y": y, "width": w, "height": h, "scale": 1}}, sid)["data"]
    return price, png


def main():
    res = json.load(open(os.path.join(HERE, "result.json"), encoding="utf-8"))
    total, tiles, club = 0, "", []
    for r in res["slots"]:
        c = r["card"]
        if c.get("mine"):
            club.append(f"{html.escape(c['name'].replace(' (CLUB)', ''))} ({r['slot']})")
            continue
        price, png = live(c)
        time.sleep(3)
        shown = price if price else c["price"]
        total += shown
        jump = price and price > c["price"] + 100
        was = f" (was {c['price']:,})" if jump else ""
        print(f"{r['slot']:4} {c['name']} live {price} (cached {c['price']})")
        img = f'<img src="data:image/png;base64,{png}" alt="{html.escape(c["name"])}">' if png else ""
        swaps = "".join(
            f'<li><a href="https://www.futbin.com{html.escape(q["href"])}">{html.escape(q["name"])}</a> '
            f'{q["rating"]} · {html.escape(q["nation"])} · {html.escape(q["league"])} · ~{q["price"]:,}</li>'
            for q in r["swaps"])
        tiles += (f'<div class="c"><div class="slot">{r["slot"]} · chem {r["chem"]}</div>{img}'
                  f'<div class="n">{html.escape(c["name"])}</div>'
                  f'<div class="m">{c["rating"]} · {html.escape(c["nation"])} · {html.escape(c["league"])}'
                  f'<br>{html.escape(c["club"])}</div>'
                  f'<div class="p{" jump" if jump else ""}">{shown:,} coins on PC'
                  f'{was}</div>'
                  f'<a href="https://www.futbin.com{html.escape(c["href"])}">FUTBIN page</a>'
                  f'<div class="sw">If too pricey, swap in:<ul>{swaps or "<li>no single swap, rerun</li>"}</ul></div></div>')
    page = f"""<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>SBC Shopping List</title>
<style>:root{{--bg:#f6f5f2;--fg:#1c1c1c;--card:#fff;--mut:#666;--warn:#b3261e}}
@media (prefers-color-scheme:dark){{:root{{--bg:#151515;--fg:#eee;--card:#222;--mut:#aaa;--warn:#ff8a80}}}}
body{{background:var(--bg);color:var(--fg);font:15px system-ui;margin:0;padding:16px}}h1{{font-size:20px}}
.g{{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:14px}}
.c{{background:var(--card);border-radius:10px;padding:10px;text-align:center}}.c img{{width:100%;max-width:190px}}
.slot{{font-weight:700;font-size:17px}}.n{{font-weight:600}}.m{{color:var(--mut);font-size:13px}}
.p{{font-weight:700;margin:6px 0}}.jump{{color:var(--warn)}}a{{color:inherit;font-size:13px}}
.sw{{text-align:left;font-size:12px;color:var(--mut);margin-top:6px}}.sw ul{{padding-left:16px;margin:4px 0}}</style></head><body>
<h1>{html.escape(res["sbc"])}: {total:,} coins on PC now</h1>
<p>{res["formation"]}, rating {res["rating"]}, chemistry {res["chemistry"]}. {html.escape(res["verdict"])}.<br>
From your club: {", ".join(club) or "none"}. Every swap listed keeps all requirements on its own.</p>
<div class="g">{tiles}</div></body></html>"""
    out = os.path.join(HERE, "sbc-report.html")
    open(out, "w", encoding="utf-8").write(page)
    print(f"total {total:,} -> {out}")


if __name__ == "__main__":
    main()
