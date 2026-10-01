import { readFile, writeFile, copyFile, rename } from 'node:fs/promises';
import { collectionCounts } from './collection-counts.mjs';
const root = new URL('../', import.meta.url);
const response = JSON.parse(await readFile(new URL('./.cache/live-collection-response.json', import.meta.url), 'utf8'));
if (!response.body?.collection || !Number.isFinite(Date.parse(response.body.lastModified)))
  throw Error('Missing collection or source update timestamp');
const entries = Object.entries(response.body.collection);
if (!entries.length) throw Error('Empty collection; previous import preserved');
for (const [id, counts] of entries) {
  if (!/^\d+$/.test(id)) throw Error('Invalid collection ID');
  collectionCounts(counts);
}
const target = new URL('collection-raw.json', root);
try { await copyFile(target, new URL('./.cache/collection-raw-previous.json', import.meta.url)); }
catch (e) { if (e.code !== 'ENOENT') throw e; }
const temp = new URL('./.cache/collection-raw-next.json', import.meta.url);
await writeFile(temp, JSON.stringify({ ...response.body, _fetchedAt: response.fetchedAt }, null, 2) + '\n');
await rename(temp, target);
console.log(`Validated ${entries.length} collection records; source updated ${response.body.lastModified}`);
