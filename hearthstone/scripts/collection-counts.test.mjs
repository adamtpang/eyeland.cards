import test from 'node:test';
import assert from 'node:assert/strict';
import { collectionCounts } from './collection-counts.mjs';

test('includes permanent diamond/signature copies and excludes trial copies', () => {
  assert.deepEqual(collectionCounts([1, 2, 1, 1, 4, 3, 2, 1]), {
    normalCount: 1, goldCount: 2, diamondCount: 1, signatureCount: 1,
    totalCount: 5, trialCount: 10,
  });
  assert.equal(collectionCounts([0, 0, 0, 0, 2, 0, 0, 0]).totalCount, 0);
});
test('supports old exports but rejects unknown/invalid schemas', () => {
  assert.equal(collectionCounts([1, 2]).totalCount, 3);
  for (const v of [[1], [1, 2, 3], [1, -1], [1, '2'], [1, 0.5], null]) {
    assert.throws(() => collectionCounts(v));
  }
});
