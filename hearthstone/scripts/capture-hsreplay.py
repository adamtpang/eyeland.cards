"""Run through Helium Harness, not standalone Python.

From C:/Users/adamp/Aether/helium-harness:
Get-Content ../eyeland.cards/hearthstone/scripts/capture-hsreplay.py |
  ./.venv/Scripts/python.exe -m browser_harness.run

Uses requests already observed on the signed-in pages. No stored credentials,
account identifiers in logs, visibility changes, or subscription bypasses.
"""
import json
from pathlib import Path

root = Path('C:/Users/adamp/Aether/eyeland.cards/hearthstone')
cache = root / 'scripts/.cache'
cache.mkdir(parents=True, exist_ok=True)

def capture(page_url, request_path, destination):
    new_tab(page_url)
    wait_for_load()
    expression = '''(async()=>{
      const path=PATH;
      const u=performance.getEntriesByType('resource').map(e=>e.name)
        .find(u=>u.includes(path));
      if(!u)throw Error('Required request missing: sign in and let page load');
      const r=await fetch(u,{credentials:'include'});
      if(!r.ok)throw Error('Source HTTP '+r.status);
      return {body:await r.json(),fetchedAt:new Date().toISOString(),
        lastModified:r.headers.get('last-modified'),
        url:path.includes('collection')?null:u};
    })()'''.replace('PATH', json.dumps(request_path))
    result = cdp('Runtime.evaluate', expression=expression,
                 awaitPromise=True, returnByValue=True)
    if result.get('exceptionDetails'):
        raise RuntimeError('Capture failed; previous snapshot preserved. Check sign-in/page load.')
    data = result['result']['value']
    temporary = cache / (destination + '.tmp')
    temporary.write_text(json.dumps(data), encoding='utf-8')
    temporary.replace(cache / destination)
    print('Captured ' + destination)

capture('https://hsreplay.net/collection/mine/', '/api/v1/collection/?',
        'live-collection-response.json')
capture('https://hsreplay.net/decks/', '/analytics/query/list_decks_by_win_rate_v2/',
        'live-meta-response.json')
