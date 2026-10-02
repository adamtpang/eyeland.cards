"""Read a FUTBIN SBC squad page (read-only) through the Helium bridge: players, nation, league, club, rating, price."""
import json
import sys
import time

import cdp

TAB = "7B8A3EC6E40492EBF1FF3F6754B48923"
JS = r'''JSON.stringify(Array.from(document.querySelectorAll('img[alt="Nation"]')).map(n=>{
  let c=n; for(let k=0;k<8&&c;k++){ if(c.querySelectorAll('img[alt="Nation"]').length==1 && c.querySelector('img[alt="Club"]') && /\d/.test(c.innerText)) {const p=c.parentElement; if(!p||p.querySelectorAll('img[alt="Nation"]').length>1) break;} c=c.parentElement;}
  const t=a=>{const i=c.querySelector('img[alt="'+a+'"]');return i?(i.title||i.getAttribute('data-original-title')||''):''};
  const nm=Array.from(c.querySelectorAll('img')).map(i=>i.alt).find(a=>a&&!['Nation','League','Club','Coin','Item Score','Small Coin'].includes(a))||'';
  return {name:nm,nation:t('Nation'),league:t('League'),club:t('Club'),text:c.innerText.replace(/\s+/g,' ').trim()};
}))'''


def read(url):
    sid = cdp.attach(TAB)
    cdp.call("Target.activateTarget", {"targetId": TAB})
    cdp.call("Page.navigate", {"url": url}, session=sid)
    time.sleep(9)
    return json.loads(cdp.call("Runtime.evaluate", {"expression": JS, "returnByValue": True}, session=sid)["result"]["value"])


if __name__ == "__main__":
    for p in read(sys.argv[1]):
        print(json.dumps(p, ensure_ascii=False))
