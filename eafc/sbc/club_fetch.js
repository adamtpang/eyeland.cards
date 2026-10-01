// Read-only club import, the same request the web app sends when you open Club > Players.
// Pages through every player with a human-like pause; never buys, lists, moves or submits.
new Promise(resolve => {
  const all = {};
  const PAGE = 90;
  const step = offset => {
    const c = new UTSearchCriteriaDTO();
    c.type = SearchType.PLAYER;
    c.count = PAGE;
    c.offset = offset;
    services.Club.search(c).observe(this, (obs, res) => {
      obs.unobserve(this);
      if (!res.success) return resolve(JSON.stringify({ error: res.status, got: Object.keys(all).length }));
      const items = (res.response && res.response.items) || [];
      items.forEach(i => { all[i.id] = i; });
      if (items.length < PAGE || offset > 5000) {
        window.__clubImport = Object.values(all);
        return resolve(JSON.stringify({ ok: true, got: window.__clubImport.length }));
      }
      setTimeout(() => step(offset + PAGE), 1500 + Math.random() * 1000);
    });
  };
  step(0);
})
