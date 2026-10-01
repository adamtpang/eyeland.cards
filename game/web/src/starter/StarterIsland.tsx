import { useEffect, useState } from 'react';
import { DuelScreen } from '../duel/DuelScreen';
import { CardFace } from '../duel/CardView';
import { CLASSES, ELEMENTS, ENCOUNTER, LANDMARKS, SPAWN, STARTER_DATA, TERRAIN,
    finishEncounter, initialJourney, move, nearby, starterDeck, StarterClass, StarterElement } from './content';
import './starter.css';

export function StarterIsland({ onExpedition }: { onExpedition: () => void }) {
    const [position, setPosition] = useState(SPAWN);
    const [journey, setJourney] = useState(initialJourney);
    const [element, setElement] = useState<StarterElement>('fire');
    const [cls, setClass] = useState<StarterClass>('warrior');
    const [started, setStarted] = useState(false);
    const [battle, setBattle] = useState(false);
    const [deckVisible, setDeckVisible] = useState(false);
    const [notice, setNotice] = useState('Home is small. The world beyond the water is not.');
    const deck = starterDeck(element);
    const selectedClass = CLASSES.find(c => c.id === cls)!;

    useEffect(() => {
        if (battle || !started) return;
        const onKey = (event: KeyboardEvent) => {
            if ((event.target as HTMLElement).closest('input, select, textarea, button')) return;
            const directions: Record<string, [number, number]> = {
                ArrowUp: [0, -1], w: [0, -1], ArrowDown: [0, 1], s: [0, 1],
                ArrowLeft: [-1, 0], a: [-1, 0], ArrowRight: [1, 0], d: [1, 0],
            };
            const delta = directions[event.key];
            if (delta) { event.preventDefault(); setPosition(p => move(p, ...delta)); }
        };
        window.addEventListener('keydown', onKey);
        return () => window.removeEventListener('keydown', onKey);
    }, [battle, started]);

    function interact(id: string) {
        if (!nearby(position).some(l => l.id === id)) return;
        if (id === 'encounter') { setBattle(true); return; }
        if (id === 'camp') {
            setJourney(j => ({ ...j, health: 30 }));
            setNotice('You rest by the fire. Health restored to 30. Home is still here.');
        } else if (id === 'home') {
            setNotice(journey.won ? 'Your family: “You kept the garden safe. Come sit with us before you go.”'
                : 'Your family: “Take your companion to the resin garden. A crab has been eating the seedlings. We need that harvest.”');
        } else if (id === 'friend') {
            setNotice('Your friend: “They say the four elemental monarchs rule whole domains. One day we’ll see them together.”');
        } else if (id === 'crop') {
            setNotice('Luminous resin feeds this village and binds its cards. To you it is ordinary. Faraway captains may think otherwise.');
        } else if (id === 'dock') {
            setNotice(journey.won ? 'A black sail crosses the horizon. Protecting a garden is only the beginning. The next chapter is not built yet.'
                : 'A ship waits beyond the reef. First, help your family in the garden.');
        }
    }

    if (battle) return <DuelScreen playerDeck={deck} enemyDeck={ENCOUNTER.deck.map(id => STARTER_DATA.byId(id))}
        cardData={STARTER_DATA} fixedClass={selectedClass.engineClass} playerHealth={journey.health}
        enemyName={ENCOUNTER.name} enemyHealth={ENCOUNTER.health} seed={20260920}
        onEnd={(won, health) => {
            const first = won && !journey.won;
            setJourney(j => finishEncounter(j, won, health));
            setBattle(false);
            if (!won) setPosition({ x: 6, y: 5 });
            setNotice(first ? 'Garden safe! Resin Crab joined your collection, with 2 luminous resin. Your five-card deck stays unchanged. Visit home or the lookout.'
                : won ? 'You won the practice rematch. The garden reward is already collected.'
                : 'You returned safely to the campfire with 1 HP. Rest before trying again. No cards were lost.');
        }} />;

    return <main className="home-island">
        <header className="home-header"><div><small>eyeland.cards · playable story sketch</small><h1>Before the horizon</h1></div>
            <button onClick={onExpedition}>Ember Reach & practice</button></header>
        {!started ? <section className="home-intro">
            <p className="eyebrow">CHAPTER ZERO / HOME ISLAND</p>
            <h2>A small home.<br />A companion for a bigger world.</h2>
            <p>Your family grows luminous resin on a quiet island. Today, a crab is the biggest problem in the garden. Beyond the reef, unfamiliar sails are gathering.</p>
            <div className="home-choices"><label>Class<select value={cls} onChange={e => setClass(e.target.value as StarterClass)}>
                {CLASSES.map(c => <option key={c.id} value={c.id}>{c.name} — {c.description}</option>)}</select></label>
                <label>Element<select value={element} onChange={e => setElement(e.target.value as StarterElement)}>
                    {ELEMENTS.map(e => <option key={e.id} value={e.id}>{e.name} — {e.verb}</option>)}</select></label></div>
            <p>Your first deck: <strong>{deck.map(c => c.name).join(', ')}</strong>.</p>
            <button className="home-primary" onClick={() => { setStarted(true); setNotice('Visit your family, then head east to the crab clearing.'); }}>Begin at home</button>
            <p className="home-footnote">Five cards · one encounter · solo. Starter names and abilities are placeholders; evolution comes later. This story sketch lasts for this session.</p>
        </section> : <>
            <div className="home-status"><span>{selectedClass.name} · {element}</span><strong>♥ {journey.health}/30</strong>
                <span>{journey.resources} luminous resin</span><span>{journey.won ? 'Garden protected' : 'Help the resin garden'}</span></div>
            <div className="home-layout"><section>
                <div className="home-map" tabIndex={0} aria-label="Home Island map. Move with arrow keys or W A S D. Water blocks movement.">
                    {TERRAIN.flatMap((row, y) => [...row].map((tile, x) => {
                        const landmark = LANDMARKS.find(l => l.x === x && l.y === y);
                        const player = position.x === x && position.y === y;
                        return <div key={`${x}-${y}`} className={`home-tile ${tile === '#' ? 'sea' : 'land'} ${landmark ? 'landmark' : ''} ${player ? 'player' : ''}`}
                            title={player ? 'You' : landmark?.name}>
                            <span>{player ? '◆' : landmark?.icon ?? (tile === '#' ? '≈' : '')}</span>
                        </div>;
                    }))}
                </div>
                <p className="home-footnote">Click the map, then use WASD / arrow keys. Or use the movement buttons. ◆ is you.</p>
                <div className="home-controls">{[['↑', 0, -1, 'Move north'], ['←', -1, 0, 'Move west'], ['↓', 0, 1, 'Move south'], ['→', 1, 0, 'Move east']].map(([icon, dx, dy, label]) =>
                    <button key={String(label)} aria-label={String(label)} onClick={() => setPosition(p => move(p, Number(dx), Number(dy)))}>{icon}</button>)}</div>
                <div className="home-legend">{LANDMARKS.map(l => <span key={l.id}>{l.icon} {l.name}</span>)}</div>
            </section><aside className="home-panel">
                <p className="eyebrow">CLOSE TO YOU</p>
                <div className="home-actions">{nearby(position).map(l => <button key={l.id} onClick={() => interact(l.id)}>
                    {l.id === 'encounter' ? journey.won ? 'Practice: Resin Crab' : 'Encounter: Resin Crab' : l.id === 'camp' ? 'Rest at campfire' : `Visit ${l.name}`}</button>)}</div>
                {nearby(position).length === 0 && <p>Walk toward a landmark to interact.</p>}
                <p className="home-notice" role="status">{notice}</p>
                <button onClick={() => setDeckVisible(v => !v)}>{deckVisible ? 'Hide' : 'View'} five-card deck</button>
                <p className="home-footnote">Collection reward: {journey.collection.length ? 'Resin Crab ×1. Deck editing for this story sketch is a next step.' : 'Help the garden to earn your first creature card.'}</p>
            </aside></div>
            {deckVisible && <section className="home-deck" aria-label="Five-card starter deck">{deck.map(c => <CardFace key={c.id} card={c} />)}</section>}
        </>}
    </main>;
}
