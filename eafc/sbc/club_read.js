(() => {
  const L = k => { try { const v = services.Localization.localize(k); return v === k ? '' : v; } catch (e) { return ''; } };
  const posName = p => { try { return UTPlayerItemViewModel ? '' : ''; } catch (e) { return ''; } };
  let active = [];
  try { const q = Object.values(Object.values(repositories.Squad.squads._collection)[0]._collection).find(q => q.isActive && q.isActive());
        active = q.getPlayers().map(p => p.item && p.item.id); } catch (e) {}
  const vals = (window.__clubImport || Object.values(repositories.Item.club.items._collection)).filter(i => i.type === 'player');
  return JSON.stringify(vals.map(i => {
    const sd = i.getStaticData ? i.getStaticData() : {};
    let pos = [];
    try { pos = (i.possiblePositions || []).map(p => typeof p === 'number' ? p : p); } catch (e) {}
    return {
      itemId: i.id, def: i.definitionId, name: (sd && (sd.name || [sd.firstName, sd.lastName].join(' '))) || '',
      rating: i._rating, pref: i.preferredPosition, pos,
      nationId: i.nationId, leagueId: i.leagueId, teamId: i.teamId,
      nation: L('search.nationName.nation' + i.nationId),
      league: L('global.leagueFull.2027.league' + i.leagueId) || L('global.leagueFull.2026.league' + i.leagueId),
      club: L('global.teamFull.2027.team' + i.teamId) || L('global.teamFull.2026.team' + i.teamId),
      tradable: i.tradable, rare: i._rareflag, loan: i.loans !== -1, squadSlot: active.indexOf(i.id),
    };
  }));
})()
