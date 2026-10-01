import test from 'node:test';
import assert from 'node:assert/strict';
import { rankOwnedDecks, sourceAgeHours } from './self-test.mjs';
const deck = overrides => ({ deck_id: 'example', deck_list: '[[1,2]]', deck_sideboard: '[]',
  total_games: 800, win_rate: 55, ...overrides });
const rank = (counts, d) => rankOwnedDecks({ 1: counts }, { series: { data: { TEST: [d] } } })[0];
test('trial-only copies never produce a zero-craft recommendation', () => {
  assert.equal(rank([0,0,0,0,2,0,0,0], deck()).eligibleForTrial, false);
  assert.equal(rank([0,0,1,1,0,0,0,0], deck()).eligibleForTrial, true);
});
test('unknown sideboard ownership and small samples exclude candidates', () => {
  assert.equal(rank([2,0], deck({ deck_sideboard: '[[2,1]]' })).eligibleForTrial, false);
  assert.equal(rank([2,0], deck({ total_games: 20 })).eligibleForTrial, false);
  assert.equal(rank([1,0], deck({ deck_list: '[[1,1],[1,1]]' })).missingCopies, 1);
});
test('missing, invalid, or future source timestamps cannot pass freshness', () => {
  const now = Date.parse('2026-09-10T00:00:00Z');
  assert.equal(sourceAgeHours('2026-09-09T00:00:00Z', now), 24);
  for (const v of [null, undefined, 'bad', '2026-09-11T00:00:00Z'])
    assert.equal(sourceAgeHours(v, now), Infinity);
});
