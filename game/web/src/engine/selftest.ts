// Engine self-test: run with `npm test`. Mirrors the C# verification suites
// (keywords, hero powers, data loading) plus an AI-vs-AI simulation that must
// terminate and should land near the C# engine's first-player win rate.

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import {
    BoardCreature, CardDef, CardSet, Caster, DuelState, ResolutionLog, Stat, TurnEngine,
} from './engine';
import { loadCardData, mergeCardJson } from './loader';
import { buildClassDeck, validateConstructed } from './constructed';
import { GreedyAI } from './ai';
import { IslandRun } from './island';
import { Rng } from './rng';

const here = dirname(fileURLToPath(import.meta.url));
const json = JSON.parse(readFileSync(resolve(here, '../../../data/cards.json'), 'utf8'));
const parityJson = JSON.parse(readFileSync(resolve(here, '../data/parity-cards.json'), 'utf8'));

let passed = 0, failed = 0;
function check(name: string, ok: boolean, detail = ''): void {
    if (ok) { passed++; console.log(`  PASS  ${name}`); }
    else { failed++; console.log(`  FAIL  ${name}${detail ? `  (${detail})` : ''}`); }
}

// A creature-only test card, so each keyword is tested in isolation.
function creature(id: string, attack: number, health: number, extra: Partial<CardDef> = {}): CardDef {
    return {
        id, name: id, cost: 0, type: 'creature', element: 'fire', rarity: 'common', text: '',
        cls: 'neutral', attack, health, taunt: false, targeting: 'none', targetSide: 'enemy', spellDamage: 0, collectible: true, ...extra,
    };
}

function duel(clsA: Caster['cls'] = 'neutral', clsB: Caster['cls'] = 'neutral'): DuelState {
    const s = new DuelState(new Caster('A', clsA), new Caster('B', clsB), new Rng(7));
    s.a.pips = s.a.maxPips = 10;
    s.b.pips = s.b.maxPips = 10;
    return s;
}

function place(owner: Caster, card: CardDef, ready = true, turn = -1): BoardCreature {
    const c = BoardCreature.fromCard(card);
    if (ready) c.summoningSick = false;
    c.landedOnTurn = turn;
    owner.board.push(c);
    return c;
}

console.log('Data');
check('shared cards.json alone still loads 72 cards', loadCardData(json).cards.length === 72);
const data = loadCardData(mergeCardJson(json, parityJson));
CardSet.load(data);
check('parity cards load on top', data.cards.length === 72 + parityJson.sets[0].cards.length, `${data.cards.length}`);
check('starter deck has 16 cards', CardSet.starterDeck().length === 16);
check('every class has a hero power', (['barbarian', 'bard', 'cleric', 'druid', 'fighter', 'monk', 'paladin', 'ranger', 'rogue', 'sorcerer', 'warlock', 'wizard', 'tinkerer'] as const).every(c => data.heroPowers[c]));
check('every hero power costs 2', Object.values(data.heroPowers).every(p => p!.cost === 2));
let threw = false;
try { loadCardData({ sets: [{ cards: [{ id: 'x', onPlay: [{ effect: 'nope' }] }] }] }); } catch { threw = true; }
check('unknown effect fails loudly', threw);
threw = false;
try { loadCardData({ sets: [{ cards: [{ id: 'd' }, { id: 'd' }] }] }); } catch { threw = true; }
check('duplicate ids fail loudly', threw);

console.log('Keywords');
{
    const s = duel();
    const guard = place(s.b, creature('guard', 1, 5, { taunt: true }));
    const attacker = place(s.a, creature('att', 2, 2));
    check('taunt blocks face', !TurnEngine.tryAttack(s, attacker, null));
    check('taunt forces its own target', TurnEngine.tryAttack(s, attacker, guard));
}
{
    const s = duel();
    const r = BoardCreature.fromCard(creature('rush', 3, 3, { keywords: [Stat.Rush] }));
    r.landedOnTurn = s.turnNumber;
    s.a.board.push(r);
    const foe = place(s.b, creature('foe', 1, 1));
    check('rush can act the turn it lands', r.canAttackNow);
    check('rush cannot hit face on arrival', !TurnEngine.tryAttack(s, r, null));
    check('rush can hit a creature on arrival', TurnEngine.tryAttack(s, r, foe));
}
{
    const s = duel();
    const c = BoardCreature.fromCard(creature('charge', 3, 3, { keywords: [Stat.Charge] }));
    c.landedOnTurn = s.turnNumber;
    s.a.board.push(c);
    check('charge hits face on arrival', TurnEngine.tryAttack(s, c, null) && s.b.health === 27);
}
{
    const s = duel();
    const shield = place(s.b, creature('shield', 1, 2, { keywords: [Stat.DivineShield] }));
    const a1 = place(s.a, creature('a1', 5, 5));
    TurnEngine.tryAttack(s, a1, shield);
    check('divine shield absorbs the first hit', shield.isAlive && shield.damage === 0 && !shield.divineShield);
}
{
    const s = duel();
    const big = place(s.b, creature('big', 1, 20));
    const viper = place(s.a, creature('viper', 1, 3, { keywords: [Stat.Poisonous] }));
    TurnEngine.tryAttack(s, viper, big);
    check('poisonous destroys what it damages', !s.b.board.includes(big));
}
{
    const s = duel();
    s.a.health = 20;
    const imp = place(s.a, creature('imp', 3, 3, { keywords: [Stat.Lifesteal] }));
    TurnEngine.tryAttack(s, imp, null);
    check('lifesteal heals its caster', s.a.health === 23);
}
{
    const s = duel();
    const wf = place(s.a, creature('wf', 2, 5, { keywords: [Stat.Windfury] }));
    const first = TurnEngine.tryAttack(s, wf, null);
    const second = TurnEngine.tryAttack(s, wf, null);
    const third = TurnEngine.tryAttack(s, wf, null);
    check('windfury attacks exactly twice', first && second && !third);
}
{
    const s = duel();
    const hidden = place(s.b, creature('hidden', 2, 2, { keywords: [Stat.Stealth] }));
    const att = place(s.a, creature('att', 2, 2));
    check('stealth cannot be targeted', !TurnEngine.tryAttack(s, att, hidden));
}
{
    const s = duel();
    const target = place(s.b, creature('t', 3, 3));
    target.frozen = true;
    s.active = s.b;
    s.b.startTurn(new ResolutionLog());
    check('freeze costs the next turn of attacks', !target.canAttackNow && !target.frozen);
}

console.log('Spell damage, auras, deathrattles');
{
    const s = duel('wizard');
    place(s.a, CardSet.byId('wiz-apprentice'));
    const foe = place(s.b, creature('foe', 1, 10));
    TurnEngine.tryUseHeroPower(s, foe);
    check('spell damage does NOT boost hero powers', foe.damage === 1, `damage ${foe.damage}`);
    const bolt = CardSet.byId('ember-bolt');
    s.a.hand.push(bolt);
    TurnEngine.tryPlayCard(s, bolt, foe);
    check('spell damage boosts spell cards', foe.damage === 1 + 4, `damage ${foe.damage}`);
}
{
    const s = duel();
    const totem = place(s.a, CardSet.byId('storm-totem'));
    const buddy = place(s.a, creature('buddy', 2, 2));
    TurnEngine.tryPlayCard(s, pushHand(s.a, creature('filler', 0, 1)), null);
    check('aura adds +1 attack to others', buddy.attack === 3 && totem.attack === 0, `buddy ${buddy.attack}`);
    totem.destroy();
    const killer = pushHand(s.a, creature('filler2', 0, 1));
    TurnEngine.tryPlayCard(s, killer, null);
    check('aura vanishes when its source dies', buddy.attack === 2, `buddy ${buddy.attack}`);
}
{
    const s = duel();
    const seed = place(s.b, CardSet.byId('drd-seedbearer'));
    const att = place(s.a, creature('att', 20, 20));
    TurnEngine.tryAttack(s, att, seed);
    check('deathrattle summons after death', s.b.board.some(c => c.source.id === 'drd-sapling'));
}

console.log('Hero powers');
{
    const s = duel('ranger');
    const first = TurnEngine.tryUseHeroPower(s, null);
    const second = TurnEngine.tryUseHeroPower(s, null);
    check('hero power is once per turn', first && !second);
    check('hero power spends 2 mana', s.a.pips === 8);
    const t = duel('ranger');
    t.a.pips = 1;
    check('hero power needs mana', !TurnEngine.tryUseHeroPower(t, null));
}

console.log('Targeting');
{
    check('buff card aims at your side', data.cards.find(c => c.id === 'brd-refrain')?.targetSide === 'friendly');
    check('heal card aims at your side', data.cards.find(c => c.id === 'salvage')?.targetSide === 'friendly');
    check('damage card aims at the enemy', data.cards.find(c => c.id === 'rolling-thunder')?.targetSide === 'enemy');
    check('bard hero power aims at your side', data.heroPowers.bard?.targetSide === 'friendly');
    let mixed = false;
    try { loadCardData({ sets: [{ cards: [{ id: 'm', targeting: 'requiredCreature', onPlay: [{ effect: 'damage', amount: 1 }, { effect: 'buffTarget', attack: 1 }] }] }] }); } catch { mixed = true; }
    check('mixed target effects fail loudly', mixed);

    const s = duel();
    const ally = place(s.a, creature('ally', 2, 2));
    const foe = place(s.b, creature('foe', 3, 3));
    const refrain = pushHand(s.a, data.cards.find(c => c.id === 'brd-refrain')!);
    check('friendly buff refuses an enemy target', !TurnEngine.tryPlayCard(s, refrain, foe));
    const before = ally.attack;
    check('friendly buff lands on your creature', TurnEngine.tryPlayCard(s, refrain, ally) && ally.attack > before && foe.attack === 3);

    const hidden = place(s.b, creature('sneak', 1, 1, { keywords: [Stat.Stealth] }));
    const thunder = pushHand(s.a, data.cards.find(c => c.id === 'rolling-thunder')!);
    check('enemy spell cannot aim at Stealth', !TurnEngine.tryPlayCard(s, thunder, hidden));
    check('enemy spell refuses your own creature', !TurnEngine.tryPlayCard(s, thunder, ally));
    check('enemy spell hits an enemy creature', TurnEngine.tryPlayCard(s, thunder, foe));

    const b = duel('bard');
    const mine = place(b.a, creature('mine', 1, 1));
    place(b.b, creature('theirs', 1, 1));
    check('bard hero power buffs your creature', TurnEngine.tryUseHeroPower(b, mine) && mine.attack === 2);
}

console.log('Simulation');
{
    const games = 1000;
    let aWins = 0, draws = 0, turns = 0, unfinished = 0;
    for (let i = 0; i < games; i++) {
        const rng = new Rng(1000 + i);
        const a = new Caster('Player A'), b = new Caster('Player B');
        a.deck = rng.shuffled(CardSet.starterDeck());
        b.deck = rng.shuffled(CardSet.starterDeck());
        const log = new ResolutionLog();
        a.dealOpeningHand(3, log);
        b.dealOpeningHand(3, log);
        const s = new DuelState(a, b, rng);
        TurnEngine.runGame(s, new GreedyAI('Player A'), new GreedyAI('Player B'));
        if (!s.isOver) unfinished++;
        if (s.winner === a) aWins++;
        else if (!s.winner) draws++;
        turns += s.turnNumber;
    }
    const rate = (100 * aWins) / games;
    console.log(`  ${games} games: first player wins ${rate.toFixed(1)}%, draws ${draws}, avg ${(turns / games).toFixed(1)} turns`);
    check('every simulated game finishes', unfinished === 0, `${unfinished} unfinished`);
    check('first-player rate near the C# engine (51.5%)', rate > 44 && rate < 59, `${rate.toFixed(1)}%`);
}

// Parity tests end turns, so both sides get a stocked deck to keep fatigue out of the numbers.
function pduel(cls: Caster['cls'] = 'neutral'): DuelState {
    const s = duel(cls);
    s.a.deck = Array.from({ length: 20 }, () => CardSet.byId('riptide'));
    s.b.deck = Array.from({ length: 20 }, () => CardSet.byId('riptide'));
    return s;
}

console.log('Parity: core rules');
const card = (id: string) => CardSet.byId(id);
{
    const s = pduel();
    for (let i = 0; i < 10; i++) s.a.hand.push(card('ember-bolt'));
    s.a.deck = [card('riptide')];
    const log = new ResolutionLog();
    s.a.drawCard(log);
    check('hand limit 10: an 11th card burns', s.a.hand.length === 10 && s.a.deck.length === 0 && log.lines[0].includes('burns'));
}
{
    const s = pduel();
    for (let i = 0; i < 7; i++) place(s.a, creature(`c${i}`, 1, 1));
    const extra = pushHand(s.a, card('glowing-ember'));
    check('board limit 7 blocks playing a creature', !TurnEngine.tryPlayCard(s, extra, null) && s.a.hand.includes(extra));
}
{
    const rng = new Rng(5);
    const a = new Caster('A'), b = new Caster('B');
    a.deck = rng.shuffled(CardSet.starterDeck()); b.deck = rng.shuffled(CardSet.starterDeck());
    const s = new DuelState(a, b, rng);
    TurnEngine.setupGame(s);
    check('opening hands: 3 for first, 4 for second', a.hand.length === 3 && b.hand.length === 4 && s.mulliganPending);
    check('no actions before the mulligan ends', !TurnEngine.apply(s, { kind: 'pass' }));
    const kept = a.hand[2], deckBefore = a.deck.length;
    TurnEngine.mulligan(s, a, [a.hand[0], a.hand[1]]);
    check('mulligan replaces the chosen cards', a.hand.length === 3 && a.hand.includes(kept) && a.deck.length === deckBefore);
    TurnEngine.startGame(s);
    check('second player gets The Coin', b.hand.some(c => c.id === 'the-coin') && b.hand.length === 5);
    check('turn 1 starts after the mulligan', !s.mulliganPending && a.maxPips === 1 && a.hand.length === 4);
    TurnEngine.endTurn(s);
    const coin = b.hand.find(c => c.id === 'the-coin')!;
    check('The Coin gives 1 temporary mana', TurnEngine.tryPlayCard(s, coin, null) && b.pips === 2 && b.maxPips === 1);
}
{
    const s = pduel();
    s.a.armor = 3;
    s.a.takeDamage(5);
    check('armor absorbs damage first', s.a.armor === 0 && s.a.health === 28);
}
{
    const rng = new Rng(9);
    const deck = buildClassDeck('rogue', rng);
    check('class deck is a legal 30', validateConstructed(deck, 'rogue') === null, validateConstructed(deck, 'rogue') ?? '');
    check('constructed rejects a third copy', validateConstructed([...deck.slice(0, 27), card('ember-bolt'), card('ember-bolt'), card('ember-bolt')], 'rogue') !== null);
    check('constructed rejects another class', validateConstructed([...deck.slice(0, 29), card('wiz-study')], 'rogue') !== null);
    check('constructed rejects tokens', validateConstructed([...deck.slice(0, 29), card('the-coin')], 'rogue') !== null);
}

console.log('Parity: card types and keywords');
{
    const s = pduel('fighter');
    const blade = pushHand(s.a, card('ftr-iron-blade'));
    const foe = place(s.b, creature('foe', 2, 5));
    check('weapon equips', TurnEngine.tryPlayCard(s, blade, null) && s.a.weapon?.attack === 3 && s.a.weapon.durability === 2);
    check('hero attacks a creature and takes damage back', TurnEngine.tryHeroAttack(s, foe) && foe.health === 2 && s.a.health === 28);
    check('hero attacks once per turn', !TurnEngine.tryHeroAttack(s, null));
    TurnEngine.endTurn(s); TurnEngine.endTurn(s);
    check('weapon breaks at 0 durability', TurnEngine.tryHeroAttack(s, null) && s.a.weapon === null && s.b.health === 27);
    const guard = place(s.b, creature('guard', 1, 1, { taunt: true }));
    const blow = pushHand(s.a, card('bar-savage-blow'));
    TurnEngine.endTurn(s); TurnEngine.endTurn(s);
    check('temporary hero attack', TurnEngine.tryPlayCard(s, blow, null) && s.a.heroAttack === 3);
    check('hero attack respects Taunt', !TurnEngine.tryHeroAttack(s, null) && TurnEngine.tryHeroAttack(s, guard));
}
{
    const s = pduel();
    const ambush = card('rog-ambush');
    s.b.secrets.push(ambush);
    const played = pushHand(s.a, card('stormcaller-elemental'));
    TurnEngine.tryPlayCard(s, played, null);
    check('Secret fires on the matching enemy action', s.b.secrets.length === 0 && s.a.board.every(c => c.source.id !== 'stormcaller-elemental' || c.damage === 4));
    s.b.secrets.push(card('wiz-mirror-ward'));
    const bolt = pushHand(s.a, card('ember-bolt'));
    const hpBefore = s.b.health;
    check('counter Secret cancels a spell', TurnEngine.tryPlayCard(s, bolt, null) && s.b.health === hpBefore && s.b.secrets.length === 0);
    const snare = pushHand(s.a, card('rng-bramble-snare'));
    check('playing a Secret hides it', TurnEngine.tryPlayCard(s, snare, null) && s.a.secrets.length === 1);
    const snare2 = pushHand(s.a, card('rng-bramble-snare'));
    check('no duplicate Secrets', !TurnEngine.tryPlayCard(s, snare2, null));
    check('your own Secret does not fire on your turn', s.a.secrets.length === 1);
    TurnEngine.endTurn(s);
    const attacker = place(s.b, creature('att', 2, 3));
    TurnEngine.tryAttack(s, attacker, null);
    check('attack Secret hits the attacker first', !attacker.isAlive && s.a.health === 30 && s.a.secrets.length === 0);
}
{
    const s = pduel('wizard');
    const rummage = pushHand(s.a, card('wiz-rummage'));
    TurnEngine.tryPlayCard(s, rummage, null);
    const offer = s.pendingChoice;
    check('Discover offers 3 different spells', !!offer && offer.options.length === 3 && new Set(offer.options.map(c => c.id)).size === 3 && offer.options.every(c => c.type === 'spell' && c.collectible));
    check('other actions wait for the Discover pick', !TurnEngine.apply(s, { kind: 'pass' }));
    const pick = offer!.options[1];
    check('Discover adds the picked card', TurnEngine.apply(s, { kind: 'discover', index: 1 }) && s.a.hand.includes(pick) && !s.pendingChoice);
}
{
    const s = pduel('druid');
    const ally = place(s.a, creature('ally', 1, 1));
    const foe = place(s.b, creature('foe', 3, 3));
    const gift = pushHand(s.a, card('drd-groves-gift'));
    check('Choose One needs a choice', !TurnEngine.tryPlayCard(s, gift, ally));
    check('Choose One branch 1 buffs a friend', TurnEngine.tryPlayCard(s, gift, ally, 0) && ally.attack === 3);
    const gift2 = pushHand(s.a, card('drd-groves-gift'));
    check('Choose One branch 2 damages an enemy', TurnEngine.tryPlayCard(s, gift2, foe, 1) && !foe.isAlive);
}
{
    const s = pduel('rogue');
    const foe = place(s.b, creature('foe', 1, 8));
    const strike = pushHand(s.a, card('rog-shadow-strike'));
    TurnEngine.tryPlayCard(s, strike, foe);
    check('no Combo on the first card', foe.damage === 2);
    const strike2 = pushHand(s.a, card('rog-shadow-strike'));
    TurnEngine.tryPlayCard(s, strike2, foe);
    check('Combo after another card this turn', foe.damage === 6);
}
{
    const s = pduel();
    const foe = place(s.b, creature('buffed', 2, 2, { taunt: true, keywords: [Stat.DivineShield] }));
    foe.addEnchantment({ name: 'big', mods: [{ stat: Stat.Attack, amount: 3 }, { stat: Stat.MaxHealth, amount: 3 }] });
    foe.takeDamage(1); // pops the shield
    foe.takeDamage(4);
    const hush = pushHand(s.a, card('clr-hush'));
    check('Silence removes buffs and keywords without killing', TurnEngine.tryPlayCard(s, hush, foe) && foe.attack === 2 && foe.isAlive && foe.health === 1 && !foe.taunt);
}
{
    const s = pduel('sorcerer');
    s.a.maxPips = 5;
    const surge = pushHand(s.a, card('sor-storm-surge'));
    TurnEngine.tryPlayCard(s, surge, null);
    TurnEngine.endTurn(s); TurnEngine.endTurn(s);
    check('Overload locks crystals next turn', s.a.maxPips === 6 && s.a.pips === 5 && s.a.overloadLocked === 1);
    TurnEngine.endTurn(s); TurnEngine.endTurn(s);
    check('Overload clears after one turn', s.a.pips === 7 && s.a.overloadLocked === 0);
}

console.log('Parity: simulation with every rule');
{
    const classes = ['fighter', 'rogue', 'wizard', 'druid', 'sorcerer', 'ranger', 'paladin', 'cleric', 'barbarian'] as const;
    const games = 400;
    let aWins = 0, unfinished = 0;
    for (let i = 0; i < games; i++) {
        const rng = new Rng(5000 + i);
        const a = new Caster('Player A', classes[i % classes.length]), b = new Caster('Player B', classes[(i * 7 + 3) % classes.length]);
        a.deck = rng.shuffled(buildClassDeck(a.cls, rng));
        b.deck = rng.shuffled(buildClassDeck(b.cls, rng));
        const s = new DuelState(a, b, rng);
        TurnEngine.setupGame(s);
        TurnEngine.runGame(s, new GreedyAI('Player A'), new GreedyAI('Player B'));
        if (!s.isOver) unfinished++;
        if (s.winner === a) aWins++;
    }
    console.log(`  ${games} constructed games: first player wins ${(100 * aWins / games).toFixed(1)}%`);
    check('every constructed game finishes', unfinished === 0, `${unfinished} unfinished`);
}

console.log('Island');
{
    const run = new IslandRun(42);
    check('island starts with a 12-card deck', run.deck().length === 12);
    check('enemy deck is 12 cards', run.enemyDeck(0).length === 12);
    check('victory is recorded once, in order', run.recordVictory(0) && !run.recordVictory(0) && !run.recordVictory(2));
    check('cleared creature joins the collection', run.owned()['cinder-wolf'] === 2);
}

console.log(`\n${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);

function pushHand(owner: Caster, card: CardDef): CardDef {
    owner.hand.push(card);
    return card;
}
