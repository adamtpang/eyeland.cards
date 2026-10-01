import assert from 'node:assert/strict';
import { CardSet, Caster, DuelState, TurnEngine } from '../engine/engine';
import { GreedyAI } from '../engine/ai';
import { Rng } from '../engine/rng';
import { CLASSES, ELEMENTS, ENCOUNTER, LANDMARKS, SPAWN, STARTER_DATA, TERRAIN,
    finishEncounter, initialJourney, move, nearby, starterDeck } from './content';

CardSet.load(STARTER_DATA);
for (const e of ELEMENTS) {
    const deck = starterDeck(e.id);
    assert.equal(deck.length, 5);
    assert.equal(new Set(deck.map(c => c.id)).size, 5);
    assert.equal(deck.filter(c => c.rarity === 'legendary').length, 1);
    assert.equal(deck[0].element, e.id);
}
assert.equal(STARTER_DATA.byId('home-shore-guard').element, 'earth');
assert.equal(STARTER_DATA.byId('home-breeze-finch').element, 'air');
assert.ok(STARTER_DATA.cards.some(c => c.element === 'storm'), 'legacy Storm preserved');

// Every story interaction must be physically reachable, with no walking on water.
const visited = new Set<string>();
const queue = [SPAWN];
while (queue.length) {
    const p = queue.shift()!, key = `${p.x},${p.y}`;
    if (visited.has(key)) continue;
    visited.add(key);
    assert.equal(TERRAIN[p.y][p.x], '.');
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const next = move(p, dx, dy);
        if (!visited.has(`${next.x},${next.y}`)) queue.push(next);
    }
}
assert.ok(LANDMARKS.every(l => visited.has(`${l.x},${l.y}`)));
assert.ok(nearby(SPAWN).some(l => l.id === 'home'));
assert.deepEqual(move({ x: 3, y: 1 }, 0, -1), { x: 3, y: 1 });
assert.deepEqual(move(SPAWN, 2, 0), SPAWN);

const fresh = initialJourney();
const loss = finishEncounter(fresh, false, 0);
assert.equal(loss.health, 1);
assert.equal(loss.resources, 0);
assert.deepEqual(loss.collection, []);
const win = finishEncounter(fresh, true, 17);
assert.equal(win.health, 17);
assert.equal(win.resources, 2);
assert.deepEqual(win.collection, [ENCOUNTER.rewardCard]);
const repeat = finishEncounter(win, true, 12);
assert.equal(repeat.resources, 2);
assert.deepEqual(repeat.collection, win.collection);
assert.equal(finishEncounter(win, false, 0).won, true);
assert.equal(fresh.resources, 0, 'outcome reducer must not mutate prior state');

// All class/element starts play real games. This checks reachability of victory,
// not human balance or fun. Same starter stats intentionally isolate class powers.
for (const cls of CLASSES) for (const element of ELEMENTS) {
    let wins = 0;
    for (let seed = 0; seed < 25; seed++) {
        const rng = new Rng(seed);
        const a = new Caster('Player', cls.engineClass), b = new Caster(ENCOUNTER.name, 'neutral');
        a.deck = rng.shuffled(starterDeck(element.id));
        b.deck = rng.shuffled(ENCOUNTER.deck.map(id => STARTER_DATA.byId(id)));
        b.maxHealth = b.health = ENCOUNTER.health;
        const s = new DuelState(a, b, rng);
        TurnEngine.setupGame(s);
        TurnEngine.runGame(s, new GreedyAI('Player'), new GreedyAI('Crab'));
        assert.ok(s.isOver, `${cls.id}/${element.id} seed ${seed} must terminate`);
        if (s.winner === a) wins++;
    }
    assert.ok(wins > 0, `${cls.id}/${element.id} must be winnable`);
    console.log(`${cls.id}/${element.id}: ${wins}/25 AI wins`);
}
console.log('Starter checks passed: 300 terminating games, four five-card decks, reachable map, single rewards, safe defeat.');
