// HSReplay collection UI, verified 2026-09-10: indices 0..3 are permanent
// normal/golden/diamond/signature counts; 4..7 are trial counts.
export function collectionCounts(counts) {
  if (!Array.isArray(counts) || ![2, 4, 8].includes(counts.length) ||
      counts.some(n => !Number.isSafeInteger(n) || n < 0)) {
    throw new Error('Unrecognized HSReplay collection count schema');
  }
  const [normalCount = 0, goldCount = 0, diamondCount = 0, signatureCount = 0] = counts;
  return { normalCount, goldCount, diamondCount, signatureCount,
    totalCount: normalCount + goldCount + diamondCount + signatureCount,
    trialCount: counts.slice(4).reduce((a, b) => a + b, 0) };
}
