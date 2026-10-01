import { useState } from 'react';
import { CardFace } from '../duel/CardView';
import '../duel/hs.css';
import { CardSet } from '../engine/engine';
import { DECK_SIZE, IslandRun } from '../engine/island';

export function DeckEditor({ run, onDone }: { run: IslandRun; onDone: (deck: string[] | null) => void }) {
    const owned = run.owned();
    const [deck, setDeck] = useState<string[]>(run.deckIds.slice());
    const count = (id: string) => deck.filter(d => d === id).length;

    const add = (id: string) => {
        if (deck.length >= DECK_SIZE || count(id) >= owned[id]) return;
        setDeck([...deck, id]);
    };
    const remove = (id: string) => {
        const i = deck.indexOf(id);
        if (i >= 0) setDeck([...deck.slice(0, i), ...deck.slice(i + 1)]);
    };

    const ids = Object.keys(owned).sort((a, b) => CardSet.byId(a).cost - CardSet.byId(b).cost || a.localeCompare(b));
    const ready = deck.length === DECK_SIZE;

    return (
        <div className="editor">
            <header className="bar">
                <strong>Edit deck</strong>
                <span className="muted">{deck.length} / {DECK_SIZE} cards. Pick from what you own.</span>
                <button disabled={!ready} onClick={() => onDone(deck)}>Save deck</button>
                <button onClick={() => onDone(null)}>Cancel</button>
            </header>
            <div className="collection">
                {ids.map(id => {
                    const c = CardSet.byId(id), have = owned[id], used = count(id);
                    return (
                        <CardFace key={id} card={c} state={used > 0 ? 'in-deck' : ''}>
                            <span className="owned">{used} of {have} in deck</span>
                            <div className="row">
                                <button onClick={() => remove(id)} disabled={used === 0}>-</button>
                                <button onClick={() => add(id)} disabled={used >= have || deck.length >= DECK_SIZE}>+</button>
                            </div>
                        </CardFace>
                    );
                })}
            </div>
        </div>
    );
}
