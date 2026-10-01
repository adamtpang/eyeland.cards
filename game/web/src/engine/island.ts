// Ember Reach expedition, ported from IslandRun.cs: three camps and a warden.
// Rewards are derived from how many encounters are cleared, so replaying a
// result or reloading a save cannot duplicate inventory.

import { CardDef, CardSet } from './engine';
import { Rng } from './rng';

export const DECK_SIZE = 12;
export const CREATURES = ['cinder-wolf', 'tidewisp', 'galehart', 'ember-reach-warden'] as const;
export const PLACES = ['Ashwood camp', 'Moonpool camp', 'Stormgrass camp', "Warden's summit"] as const;
const STARTER = ['ember-bolt', 'glowing-ember', 'tide-guard', 'squall-caller', 'stormcaller-elemental', 'riptide'];

export class IslandRun {
    deckIds: string[];

    constructor(readonly seed: number, public cleared = 0, deck?: string[]) {
        if (cleared < 0 || cleared > 4) throw new Error('Invalid cleared encounter count.');
        this.deckIds = STARTER.flatMap(id => [id, id]);
        if (deck) this.setDeck(deck);
    }

    get resources(): number { return this.cleared * (this.cleared + 1); }
    get complete(): boolean { return this.cleared === 4; }

    owned(): Record<string, number> {
        const owned: Record<string, number> = Object.fromEntries(STARTER.map(id => [id, 2]));
        for (let i = 0; i < this.cleared; i++) owned[CREATURES[i]] = i === 3 ? 1 : 2;
        return owned;
    }

    setDeck(ids: string[]): void {
        const owned = this.owned();
        const counts: Record<string, number> = {};
        for (const id of ids) counts[id] = (counts[id] ?? 0) + 1;
        if (ids.length !== DECK_SIZE || Object.entries(counts).some(([id, n]) => !(id in owned) || n > owned[id]))
            throw new Error('Choose exactly 12 cards from your collection.');
        this.deckIds = ids.slice();
    }

    deck(): CardDef[] {
        return this.deckIds.slice().sort().map(id => CardSet.byId(id));
    }

    creature(index: number): CardDef { return CardSet.byId(CREATURES[index]); }
    enemyHealth(index: number): number { return 14 + index * 5; }

    enemyDeck(index: number): CardDef[] {
        if (index < 0 || index > 3) throw new Error('Encounter index out of range.');
        // The seed varies the supporting card while preserving the authored difficulty arc.
        const support = new Rng(this.seed + index * 7919).next(2) === 0 ? 'tide-guard' : 'squall-caller';
        const ids = ['glowing-ember', support, CREATURES[index], 'ember-bolt', 'stormcaller-elemental', 'riptide'];
        return ids.flatMap(id => [id, id]).map(id => CardSet.byId(id));
    }

    recordVictory(index: number): boolean {
        if (this.complete || index !== this.cleared) return false;
        this.cleared++;
        return true;
    }
}
