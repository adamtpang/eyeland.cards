import { readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { collectionCounts } from './collection-counts.mjs';

const cache = new URL('./.cache/', import.meta.url);
const load = name => readFile(new URL(name, cache), 'utf8').then(JSON.parse);

export function rankOwnedDecks(collection, meta, { minGames = 500 } = {}) {
  if (!collection || !meta?.series?.data) throw Error('Missing collection/meta schema');
  const owned = new Map(Object.entries(collection).map(([id, counts]) =>
    [Number(id), collectionCounts(counts).totalCount]));
  const rows = [];
  for (const [playerClass, decks] of Object.entries(meta.series.data)) {
    if (!Array.isArray(decks)) throw Error('Invalid meta class rows');
    for (const deck of decks) {
      const cards = JSON.parse(deck.deck_list);
      const sideboard = JSON.parse(deck.deck_sideboard || '[]');
      if (!Array.isArray(cards) || cards.some(c => !Array.isArray(c) || c.length !== 2 ||
          !c.every(n => Number.isSafeInteger(n) && n > 0))) throw Error('Invalid deck card counts');
      if (!Array.isArray(sideboard)) throw Error('Invalid sideboard schema');
      if (!Number.isFinite(deck.win_rate) || deck.win_rate < 0 || deck.win_rate > 100 ||
          !Number.isSafeInteger(deck.total_games) || deck.total_games < 0) throw Error('Invalid statistics');
      const needed = new Map();
      for (const [id, count] of cards) needed.set(id, (needed.get(id) || 0) + count);
      const missingCopies = [...needed].reduce((s, [id, count]) =>
        s + Math.max(0, count - (owned.get(id) || 0)), 0);
      rows.push({ playerClass, deckId: deck.deck_id, games: deck.total_games,
        winRate: deck.win_rate, missingCopies, sideboardNeedsReview: sideboard.length > 0,
        eligibleForTrial: missingCopies === 0 && sideboard.length === 0 &&
          deck.total_games >= minGames && deck.win_rate > 50 });
    }
  }
  return rows.sort((a, b) => Number(b.eligibleForTrial) - Number(a.eligibleForTrial) ||
    a.missingCopies - b.missingCopies || b.winRate - a.winRate || b.games - a.games);
}

export function sourceAgeHours(value, now = Date.now()) {
  const date = Date.parse(value);
  return Number.isFinite(date) && date <= now ? (now - date) / 3600000 : Infinity;
}

async function main() {
  const [collection, meta] = await Promise.all([
    load('live-collection-response.json'), load('live-meta-response.json'),
  ]);
  const sourceUpdated = collection.body.lastModified || collection.lastModified;
  const collectionAge = sourceAgeHours(sourceUpdated);
  const metaAge = sourceAgeHours(meta.body.as_of);
  const u = new URL(meta.url);
  const scope = Object.fromEntries(u.searchParams);
  const rows = rankOwnedDecks(collection.body.collection, meta.body);
  const ready = collectionAge <= 48 && metaAge <= 48 &&
    scope.GameType === 'RANKED_STANDARD' && scope.TimeRange === 'CURRENT_PATCH';
  const report = { testedAt: new Date().toISOString(), sourceUpdated,
    collectionAgeHours: Number.isFinite(collectionAge) ? collectionAge : null,
    metaAsOf: meta.body.as_of, metaAgeHours: Number.isFinite(metaAge) ? metaAge : null,
    scope, freshStandardData: ready, totalDecks: rows.length,
    zeroCraftDecks: rows.filter(r => r.missingCopies === 0 && !r.sideboardNeedsReview).length,
    trialCandidates: ready ? rows.filter(r => r.eligibleForTrial) : [],
    rows, legality: 'Source-listed Standard; independent Oracle/in-game validation pending',
    ownership: 'Exact card IDs, permanent copies only; reprint equivalents may be undercounted',
    viciousSyndicate: { url: 'https://www.vicioussyndicate.com/vs-data-reaper-report-356/',
      published: '2026-09-03', role: 'Qualitative background before patch 36.4.2; not blended into live win rates' },
  };
  await writeFile(new URL('self-test.json', cache), JSON.stringify(report, null, 2) + '\n');
  const lines = ['# Your Hearthstone product test', '',
    `Collection last updated: ${sourceUpdated}.`,
    `Meta: ${scope.GameType}, ${scope.LeagueRankRange}, ${scope.Region}, ${scope.TimeRange}.`,
    `Meta data timestamp: ${meta.body.as_of}.`, '',
    `${rows.length} decks checked; ${report.zeroCraftDecks} match your permanent collection exactly.`,
    `Fresh Standard data gate: ${ready ? 'PASS' : 'BLOCKED — refresh sources and confirm filters'}.`, '',
    '## Zero-craft trial candidates', '',
    '| Class | Source deck | Win rate | Games |', '| --- | --- | ---: | ---: |',
    ...report.trialCandidates.map(r => `| ${r.playerClass} | [Open deck](https://hsreplay.net/decks/${r.deckId}/) | ${r.winRate}% | ${r.games} |`), '',
    'Trial filter: at least 500 observed games and over 50% observed win rate. This is a screening rule, not proof of strength or a predicted personal win rate.', '',
    report.ownership + '.', report.legality + '.', '',
    '[vS report #356](https://www.vicioussyndicate.com/vs-data-reaper-report-356/) is pre-patch background; its statistics are not combined with current-patch HSReplay statistics.', '',
    '## Test with your account', '',
    '1. Open a candidate and confirm HSReplay shows Your Cost: 0 Dust.',
    '2. Copy the source deck code and import it in Hearthstone. Confirm Standard accepts it with no missing cards.',
    '3. Play five games. Record opponent, result, and one confusing or weak point per game.',
    '4. Report whether the recommendation saved time and whether you would use it again. Five games test usability, not competitive win rate.', '',
    'No cards were crafted. This is a local, manually initiated data test, not a hosted autonomous agent.',
  ];
  await writeFile(new URL('self-test.md', cache), lines.join('\n') + '\n');
  console.log(JSON.stringify({ totalDecks: rows.length, zeroCraftDecks: report.zeroCraftDecks,
    freshStandardData: ready, trialCandidates: report.trialCandidates }, null, 2));
}
if (path.resolve(process.argv[1] || '') === fileURLToPath(import.meta.url)) {
  main().catch(e => { console.error('Self-test failed:', e.message); process.exitCode = 1; });
}
