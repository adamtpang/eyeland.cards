// Hearthstone constructed deck rules for free duels: exactly 30 cards, at most two
// copies of a card, one of a legendary, and only your class plus neutral cards.
// Island expeditions keep their own 12-card rule (island.ts) on purpose.

import { CardDef, CardSet, PlayerClass } from './engine';
import { Rng } from './rng';

export const CONSTRUCTED_SIZE = 30;

/** Null when the deck is legal, otherwise the first rule it breaks. */
export function validateConstructed(deck: CardDef[], cls: PlayerClass): string | null {
    if (deck.length !== CONSTRUCTED_SIZE) return `A deck needs exactly ${CONSTRUCTED_SIZE} cards (this one has ${deck.length}).`;
    const counts = new Map<string, number>();
    for (const card of deck) {
        if (!card.collectible) return `${card.name} cannot go in a deck.`;
        if (card.cls !== 'neutral' && card.cls !== cls) return `${card.name} is a ${card.cls} card.`;
        const n = (counts.get(card.id) ?? 0) + 1;
        counts.set(card.id, n);
        if (n > (card.rarity === 'legendary' ? 1 : 2))
            return card.rarity === 'legendary' ? `Only one copy of legendary ${card.name}.` : `At most two copies of ${card.name}.`;
    }
    return null;
}

/** A legal 30-card deck: every class card first, then neutrals, two copies each, one per legendary. */
export function buildClassDeck(cls: PlayerClass, rng: Rng): CardDef[] {
    const pool = CardSet.all.filter(c => c.collectible && (c.cls === cls || c.cls === 'neutral'));
    const classCards = rng.shuffled(pool.filter(c => c.cls === cls));
    const neutrals = rng.shuffled(pool.filter(c => c.cls === 'neutral'));
    const deck: CardDef[] = [];
    for (const card of [...classCards, ...neutrals]) {
        const copies = card.rarity === 'legendary' ? 1 : 2;
        for (let i = 0; i < copies && deck.length < CONSTRUCTED_SIZE; i++) deck.push(card);
        if (deck.length >= CONSTRUCTED_SIZE) break;
    }
    return deck;
}
