import { useState } from 'react';
import { CardSet } from '../engine/engine';
import { CREATURES, IslandRun, PLACES } from '../engine/island';
import { load, save } from './storage';
import { DeckEditor } from './DeckEditor';
import { DuelScreen } from '../duel/DuelScreen';

type Mode = { kind: 'island' } | { kind: 'deck' } | { kind: 'duel'; index: number } | { kind: 'practice' };

export function IslandScreen() {
    const [loaded] = useState(() => load());
    const [run, setRun] = useState<IslandRun>(loaded.run);
    const [invalid, setInvalid] = useState(loaded.invalid);
    const [mode, setMode] = useState<Mode>({ kind: 'island' });
    const [notice, setNotice] = useState(loaded.invalid
        ? 'Your save could not be read. It has been preserved. Confirm a new expedition to replace it.' : '');
    const [confirmReset, setConfirmReset] = useState(false);

    const persist = (r: IslandRun) => {
        if (invalid) return false;
        const ok = save(r);
        if (!ok) setNotice('Saving failed on this device. Progress is kept for this session only; use Retry save.');
        return ok;
    };

    const startNew = () => {
        const fresh = new IslandRun(Date.now() & 0x7fffffff);
        setRun(fresh); setInvalid(false); setConfirmReset(false);
        setNotice('New expedition started.');
        save(fresh);
    };

    if (mode.kind === 'deck') {
        return <DeckEditor run={run} onDone={deck => {
            if (deck) { run.setDeck(deck); persist(run); setNotice('Deck saved.'); }
            setMode({ kind: 'island' });
        }} />;
    }

    // Practice: a free constructed duel (30-card class decks, random opponent class), no rewards.
    if (mode.kind === 'practice') {
        return <DuelScreen key="practice" seed={Date.now() & 0x7fffffff} onEnd={() => setMode({ kind: 'island' })} />;
    }

    if (mode.kind === 'duel') {
        const i = mode.index;
        return <DuelScreen
            key={`${run.seed}-${i}`}
            playerDeck={run.deck()}
            enemyDeck={run.enemyDeck(i)}
            enemyName={run.creature(i).name}
            enemyHealth={run.enemyHealth(i)}
            seed={run.seed + i * 7919}
            onEnd={won => {
                if (won && run.recordVictory(i)) {
                    persist(run);
                    setNotice(`Earned ${i === 3 ? 1 : 2} x ${run.creature(i).name} and ${2 * (i + 1)} ember shards. Edit your deck to use your reward.`);
                } else if (!won) {
                    setNotice(`${run.creature(i).name} held ${PLACES[i]}. Try again, or edit your deck first.`);
                }
                setMode({ kind: 'island' });
            }} />;
    }

    return (
        <div className="island">
            <header className="bar">
                <strong>Ember Reach</strong>
                <span className="muted">Expedition {run.seed}, {run.cleared}/4 cleared, {run.resources} ember shards</span>
            </header>
            <p className="notice">{notice}</p>
            <div className="camps">
                {CREATURES.map((id, i) => {
                    const c = CardSet.byId(id);
                    const state = i < run.cleared ? 'Cleared' : i === run.cleared ? 'Next' : 'Locked';
                    return (
                        <button key={id} className={`camp ${state.toLowerCase()}`} disabled={invalid || i !== run.cleared || run.complete}
                                onClick={() => setMode({ kind: 'duel', index: i })}>
                            <span className="state">{state}</span>
                            <span className="place">{PLACES[i]}</span>
                            <span className="muted">{c.name}, {c.rarity}, {run.enemyHealth(i)} HP</span>
                            <span className="muted">Reward: {i === 3 ? 1 : 2} card{i === 3 ? '' : 's'} + {2 * (i + 1)} shards</span>
                        </button>
                    );
                })}
            </div>
            {run.complete && <p className="result">Ember Reach is cleared. Start a new expedition for a fresh island.</p>}
            <div className="row">
                <button disabled={invalid} onClick={() => setMode({ kind: 'deck' })}>Edit deck</button>
                <button onClick={() => setMode({ kind: 'practice' })}>Practice duel</button>
                <button onClick={() => {
                    if (!confirmReset) { setConfirmReset(true); setNotice('This replaces this expedition\'s saved progress. Click Confirm to continue, or Cancel to keep it.'); return; }
                    startNew();
                }}>{confirmReset ? 'Confirm new expedition' : 'New expedition'}</button>
                <button disabled={!invalid && !confirmReset && false} onClick={() => {
                    if (confirmReset) { setConfirmReset(false); setNotice(invalid ? 'Unreadable save preserved. Start a new expedition when ready.' : 'Your expedition is unchanged.'); }
                    else if (persist(run)) setNotice('Saved on this device.');
                }}>{confirmReset ? 'Cancel' : 'Retry save'}</button>
            </div>
            <p className="muted small">Saves live in this browser only. Your deck: {run.deckIds.map(id => CardSet.byId(id).name).join(', ')}.</p>
        </div>
    );
}
