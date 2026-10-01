// Browser-local save for the Ember Reach expedition. Same shape as the Unity
// IslandSave (seed, cleared, deck) so a run is just three numbers and a list.
import { IslandRun } from '../engine/island';

export const SAVE_KEY = 'eyeland.island.v1';

interface IslandSave { seed: number; cleared: number; deck: string[]; }

export function encode(run: IslandRun): string {
    const save: IslandSave = { seed: run.seed, cleared: run.cleared, deck: run.deckIds.slice() };
    return JSON.stringify(save);
}

/** Throws on a malformed or illegal save; callers decide what to do with the old text. */
export function decode(json: string): IslandRun {
    const data = JSON.parse(json) as Partial<IslandSave>;
    if (typeof data.seed !== 'number' || typeof data.cleared !== 'number' || !Array.isArray(data.deck))
        throw new Error('Save format is not supported.');
    return new IslandRun(data.seed, data.cleared, data.deck.map(String));
}

export function save(run: IslandRun): boolean {
    try { localStorage.setItem(SAVE_KEY, encode(run)); return true; }
    catch { return false; }
}

export type Loaded = { run: IslandRun; invalid: false } | { run: IslandRun; invalid: true };

export function load(): Loaded {
    let raw: string | null = null;
    try { raw = localStorage.getItem(SAVE_KEY); } catch { raw = null; }
    if (raw === null) {
        // Persist the fresh expedition at once, so a reload before the first win
        // keeps the same seed instead of rolling a new island.
        const run = new IslandRun(Date.now() & 0x7fffffff);
        save(run);
        return { run, invalid: false };
    }
    try { return { run: decode(raw), invalid: false }; }
    catch { return { run: new IslandRun(Date.now() & 0x7fffffff), invalid: true }; }
}
