// eyeland duel engine, ported from game/src/Eyeland.Duel (C#).
//
// The C# engine stays the reference implementation for the console harness and
// balance simulator. This port keeps its rules identical: the stat onion (base,
// enchantments, auras), damage tracked apart from health, Hearthstone keywords,
// hero powers, fatigue, and the 7-creature board cap. The one intentional
// difference is the random source (see rng.ts).
//
// Everything lives in one module on purpose: the C# types reference each other
// in a cycle (effects summon creatures, creatures read the card pool, the turn
// engine reads hero powers), and ES module cycles between classes break at load.

import { Rng } from './rng';

// ── enums ───────────────────────────────────────────────────────────────────

export enum Stat {
    Attack,
    MaxHealth,
    // Keywords are counters where > 0 means "has it", so a printed keyword plus the
    // same keyword from an aura survives the aura's source dying.
    Taunt,
    Rush,
    Charge,
    DivineShield,
    Lifesteal,
    Windfury,
    Poisonous,
    Stealth,
    SpellDamage,
}
const STAT_COUNT = 11;

export type CardType = 'spell' | 'creature' | 'weapon';
// Storm remains a legacy content element; new world content uses four core elements.
export type Element = 'fire' | 'water' | 'earth' | 'air' | 'storm';
export type Rarity = 'common' | 'rare' | 'epic' | 'legendary';
export type TargetRule = 'none' | 'optionalCreature' | 'requiredCreature';
/** Which board a targeted card or hero power aims at. Buffs and heals aim at your own side. */
export type TargetSide = 'enemy' | 'friendly';
/** When a hidden Secret fires. Secrets only trigger on the opponent's turn. */
export type SecretTrigger = 'enemyAttacks' | 'enemyPlaysCreature' | 'enemyCastsSpell';

/** One branch of a Choose One card. */
export interface ChoiceOption {
    name: string;
    text: string;
    targeting: TargetRule;
    targetSide: TargetSide;
    onPlay?: CardEffect;
}

export type AuraScope = 'friendlyOthers' | 'friendlyAll' | 'enemyAll' | 'allCreatures';

export const PLAYER_CLASSES = [
    'neutral',
    'barbarian', 'bard', 'cleric', 'druid', 'fighter', 'monk',
    'paladin', 'ranger', 'rogue', 'sorcerer', 'warlock', 'wizard',
    'tinkerer',
] as const;
export type PlayerClass = typeof PLAYER_CLASSES[number];

// ── data shapes ─────────────────────────────────────────────────────────────

export interface StatMod { stat: Stat; amount: number; }
export interface Enchantment { name: string; mods: StatMod[]; }
export interface AuraDef { scope: AuraScope; mods: StatMod[]; text: string; }

export type CardEffect = (ctx: DuelContext) => void;

/** The printed card. Playing a copy never mutates this. */
export interface CardDef {
    id: string;
    name: string;
    cost: number;
    type: CardType;
    element: Element;
    rarity: Rarity;
    text: string;
    cls: PlayerClass;
    attack: number;
    health: number;
    taunt: boolean;
    targeting: TargetRule;
    targetSide: TargetSide;
    onPlay?: CardEffect;
    aura?: AuraDef;
    keywords?: Stat[];
    spellDamage: number;
    onDeath?: CardEffect;
    /** Weapons: swings before it breaks. */
    durability?: number;
    /** Secrets: hidden on play, fire once when the opponent does this. */
    secret?: { trigger: SecretTrigger; onTrigger?: CardEffect; /** Cancels the spell that triggered it. */ counter?: boolean };
    chooseOne?: ChoiceOption[];
    /** Mana crystals locked on your next turn. */
    overload?: number;
    /** False for tokens like The Coin that never appear in decks or Discover pools. */
    collectible: boolean;
}

export function cardHas(card: CardDef, keyword: Stat): boolean {
    return (keyword === Stat.Taunt && card.taunt) || (card.keywords?.includes(keyword) ?? false);
}

export interface HeroPower {
    name: string;
    cost: number;
    text: string;
    targeting: TargetRule;
    targetSide: TargetSide;
    onUse?: CardEffect;
}

export interface DeckRecipe { order: string[]; counts: Record<string, number>; }

export class CardData {
    constructor(
        readonly cards: CardDef[],
        readonly starterDeck: DeckRecipe,
        readonly heroPowers: Partial<Record<PlayerClass, HeroPower>>,
    ) {}

    powerFor(cls: PlayerClass): HeroPower {
        const power = this.heroPowers[cls] ?? this.heroPowers.neutral;
        if (!power) throw new Error(`No hero power for ${cls} and no neutral fallback.`);
        return power;
    }

    byId(id: string): CardDef {
        const card = this.cards.find(c => c.id === id);
        if (!card) throw new Error(`No card with id '${id}'.`);
        return card;
    }
}

// ── resolution ──────────────────────────────────────────────────────────────

export class ResolutionLog {
    readonly lines: string[] = [];
    add(line: string): void { this.lines.push(line); }
}

export interface DuelContext {
    state: DuelState;
    owner: Caster;
    opponent: Caster;
    target: BoardCreature | null;
    isFirstSpellThisTurn: boolean;
    /** Combo: another card was played earlier this turn. */
    comboActive: boolean;
    log: ResolutionLog;
    /** True only for spell CARDS: Spell Damage never boosts hero powers or battlecries. */
    spellDamageApplies: boolean;
}

// ── the stat onion ──────────────────────────────────────────────────────────

let nextCreatureUid = 1;

export class BoardCreature {
    readonly uid = nextCreatureUid++;
    damage = 0;
    private readonly enchantments: Enchantment[] = [];
    private readonly auraBuffer: number[] = new Array(STAT_COUNT).fill(0);
    private shieldSpent = false;
    private stealthBroken = false;
    /** Silenced: printed keywords, aura, deathrattle and enchantments are gone. */
    silenced = false;
    frozen = false;
    attacksThisTurn = 0;
    summoningSick = true;
    landedOnTurn = -1;

    constructor(readonly source: CardDef) {}

    private layered(stat: Stat, baseValue: number): number {
        let total = baseValue + this.auraBuffer[stat];
        for (const e of this.enchantments)
            for (const m of e.mods)
                if (m.stat === stat) total += m.amount;
        return total;
    }

    get attack(): number { return Math.max(0, this.layered(Stat.Attack, this.source.attack)); }
    get maxHealth(): number { return Math.max(1, this.layered(Stat.MaxHealth, this.source.health)); }
    get health(): number { return this.maxHealth - this.damage; }
    get isAlive(): boolean { return this.health > 0; }

    private keyword(stat: Stat): boolean {
        return this.layered(stat, !this.silenced && cardHas(this.source, stat) ? 1 : 0) > 0;
    }

    /** Hearthstone Silence: strips text and buffs; health never rises and the creature never dies from it. */
    silence(): void {
        const healthBefore = this.health;
        this.silenced = true;
        this.enchantments.length = 0;
        this.frozen = false;
        this.damage = Math.max(0, this.maxHealth - Math.min(healthBefore, this.maxHealth));
    }

    get aura(): AuraDef | undefined { return this.silenced ? undefined : this.source.aura; }
    get deathrattle(): CardEffect | undefined { return this.silenced ? undefined : this.source.onDeath; }

    get taunt(): boolean { return this.keyword(Stat.Taunt); }
    get rush(): boolean { return this.keyword(Stat.Rush); }
    get charge(): boolean { return this.keyword(Stat.Charge); }
    get lifesteal(): boolean { return this.keyword(Stat.Lifesteal); }
    get windfury(): boolean { return this.keyword(Stat.Windfury); }
    get poisonous(): boolean { return this.keyword(Stat.Poisonous); }
    get spellDamage(): number { return Math.max(0, this.layered(Stat.SpellDamage, this.silenced ? 0 : this.source.spellDamage)); }
    get divineShield(): boolean { return !this.shieldSpent && this.keyword(Stat.DivineShield); }
    get stealth(): boolean { return !this.stealthBroken && this.keyword(Stat.Stealth); }
    get attacksAllowed(): number { return this.windfury ? 2 : 1; }

    get canAttackNow(): boolean {
        return this.isAlive && !this.frozen && this.attack > 0
            && this.attacksThisTurn < this.attacksAllowed && !this.summoningSick;
    }

    get enchantmentList(): readonly Enchantment[] { return this.enchantments; }

    /** Returns damage actually dealt: 0 when Divine Shield absorbs it. */
    takeDamage(amount: number): number {
        if (amount <= 0) return 0;
        if (this.divineShield) { this.shieldSpent = true; return 0; }
        this.damage += amount;
        return amount;
    }

    onDealtDamage(): void { this.stealthBroken = true; }

    /** Kills outright, ignoring Divine Shield. */
    destroy(): void { this.damage = this.maxHealth + 999; }

    restore(amount: number): number {
        if (amount <= 0) return 0;
        const healed = Math.min(amount, this.damage);
        this.damage -= healed;
        return healed;
    }

    addEnchantment(e: Enchantment): void { this.enchantments.push(e); }

    removeEnchantment(name: string): boolean {
        const before = this.enchantments.length;
        for (let i = this.enchantments.length - 1; i >= 0; i--)
            if (this.enchantments[i].name === name) this.enchantments.splice(i, 1);
        return this.enchantments.length < before;
    }

    clearAuraBuffer(): void { this.auraBuffer.fill(0); }
    applyAuraMod(mod: StatMod): void { this.auraBuffer[mod.stat] += mod.amount; }

    static fromCard(card: CardDef): BoardCreature {
        const c = new BoardCreature(card);
        c.summoningSick = !(c.charge || c.rush);
        return c;
    }
}

export const AuraSystem = {
    refresh(state: DuelState): void {
        for (const c of [...state.a.board, ...state.b.board])
            if (c.isAlive) c.clearAuraBuffer();

        for (const [owner, opponent] of [[state.a, state.b], [state.b, state.a]] as const) {
            for (const source of owner.board) {
                if (!source.isAlive || !source.aura) continue;
                const aura = source.aura;
                for (const affected of auraTargets(aura.scope, source, owner, opponent))
                    for (const mod of aura.mods)
                        affected.applyAuraMod(mod);
            }
        }
    },
};

function auraTargets(scope: AuraScope, source: BoardCreature, owner: Caster, opponent: Caster): BoardCreature[] {
    switch (scope) {
        case 'friendlyOthers': return owner.board.filter(c => c.isAlive && c !== source);
        case 'friendlyAll': return owner.board.filter(c => c.isAlive);
        case 'enemyAll': return opponent.board.filter(c => c.isAlive);
        case 'allCreatures': return [...owner.board, ...opponent.board].filter(c => c.isAlive);
    }
}

// ── casters and state ───────────────────────────────────────────────────────

export const PIP_CAP = 10;
export const BOARD_CAP = 7;
export const HAND_CAP = 10;
export const SECRET_CAP = 5;

export interface Weapon { card: CardDef; attack: number; durability: number; }

export class Caster {
    maxHealth = 30;
    health = 30;
    maxPips = 0;
    pips = 0;
    deck: CardDef[] = [];
    readonly hand: CardDef[] = [];
    readonly board: BoardCreature[] = [];
    fatigueDamage = 0;
    spellsCastThisTurn = 0;
    cardsPlayedThisTurn = 0;
    heroPowerUsedThisTurn = false;
    armor = 0;
    weapon: Weapon | null = null;
    /** Attack granted to the hero for this turn only, on top of the weapon. */
    tempAttack = 0;
    heroAttacksThisTurn = 0;
    readonly secrets: CardDef[] = [];
    /** Overload owed next turn, and the crystals it locked this turn. */
    overloadNext = 0;
    overloadLocked = 0;

    constructor(readonly name: string, readonly cls: PlayerClass = 'neutral') {}

    get isAlive(): boolean { return this.health > 0; }

    get heroAttack(): number { return (this.weapon?.attack ?? 0) + this.tempAttack; }
    get canHeroAttack(): boolean { return this.isAlive && this.heroAttack > 0 && this.heroAttacksThisTurn < 1; }

    /** Armor soaks damage first. Returns the damage that reached health. */
    takeDamage(amount: number): number {
        if (amount <= 0) return 0;
        const soaked = Math.min(this.armor, amount);
        this.armor -= soaked;
        this.health -= amount - soaked;
        return amount - soaked;
    }

    heal(amount: number): number {
        const healed = Math.max(0, Math.min(amount, this.maxHealth - this.health));
        this.health += healed;
        return healed;
    }

    /** Adds a card to hand; a full hand burns it, as in Hearthstone. */
    receive(card: CardDef, log: ResolutionLog): boolean {
        if (this.hand.length >= HAND_CAP) { log.add(`${this.name}'s hand is full: ${card.name} burns.`); return false; }
        this.hand.push(card);
        return true;
    }

    drawCard(log: ResolutionLog): void {
        if (this.deck.length === 0) {
            this.fatigueDamage++;
            this.takeDamage(this.fatigueDamage);
            log.add(`${this.name} draws from an empty deck and takes ${this.fatigueDamage} fatigue damage.`);
            return;
        }
        const card = this.deck.shift()!;
        if (this.receive(card, log)) log.add(`${this.name} draws ${card.name}.`);
    }

    dealOpeningHand(count: number, log: ResolutionLog): void {
        for (let i = 0; i < count; i++) this.drawCard(log);
    }

    startTurn(log: ResolutionLog): void {
        this.maxPips = Math.min(this.maxPips + 1, PIP_CAP);
        this.overloadLocked = Math.min(this.overloadNext, this.maxPips);
        this.overloadNext = 0;
        this.pips = this.maxPips - this.overloadLocked;
        this.spellsCastThisTurn = 0;
        this.cardsPlayedThisTurn = 0;
        this.heroPowerUsedThisTurn = false;
        this.heroAttacksThisTurn = 0;
        this.tempAttack = 0;
        for (const creature of this.board) {
            creature.summoningSick = false;
            creature.attacksThisTurn = 0;
            // Freeze spends the whole allowance, so Windfury loses both swings.
            if (creature.frozen) {
                creature.frozen = false;
                creature.attacksThisTurn = creature.attacksAllowed;
            }
        }
        this.drawCard(log);
    }
}

export class DuelState {
    active: Caster;
    turnNumber = 1;
    readonly log: string[] = [];
    /** A Discover waiting for its owner to pick. Every other action is refused until then. */
    pendingChoice: { owner: Caster; options: CardDef[] } | null = null;
    /** Hands are dealt but mulligans are not done: turn 1 has not started. */
    mulliganPending = false;

    constructor(readonly a: Caster, readonly b: Caster, readonly random: Rng = new Rng()) {
        this.active = a;
    }

    get waiting(): Caster { return this.active === this.a ? this.b : this.a; }
    get isOver(): boolean { return !this.a.isAlive || !this.b.isAlive; }

    /** Null while running or on a simultaneous double kill. */
    get winner(): Caster | null {
        const aDead = !this.a.isAlive, bDead = !this.b.isAlive;
        if (aDead && !bDead) return this.b;
        if (bDead && !aDead) return this.a;
        return null;
    }
}

export type PlayerAction =
    | { kind: 'playCard'; card: CardDef; target: BoardCreature | null; choice?: number }
    | { kind: 'attack'; attacker: BoardCreature; target: BoardCreature | null } // null target = enemy face
    | { kind: 'heroAttack'; target: BoardCreature | null }
    | { kind: 'heroPower'; target: BoardCreature | null }
    | { kind: 'discover'; index: number }
    | { kind: 'pass' };

export interface PlayerController {
    name: string;
    chooseAction(state: DuelState, me: Caster, opponent: Caster): PlayerAction;
}

// ── effects ─────────────────────────────────────────────────────────────────

export const Effects = {
    spellPower(ctx: DuelContext): number {
        return ctx.spellDamageApplies
            ? ctx.owner.board.filter(c => c.isAlive).reduce((sum, c) => sum + c.spellDamage, 0)
            : 0;
    },

    damage(ctx: DuelContext, amount: number): void {
        amount += Effects.spellPower(ctx);
        if (ctx.target) {
            ctx.target.takeDamage(amount);
            ctx.log.add(`${ctx.target.source.name} takes ${amount} damage (${Math.max(ctx.target.health, 0)} health left).`);
        } else {
            Effects.damageCaster(ctx, ctx.opponent, amount);
        }
    },

    damageCaster(ctx: DuelContext, who: Caster, amount: number): void {
        const armorBefore = who.armor;
        who.takeDamage(amount);
        const soaked = armorBefore - who.armor;
        ctx.log.add(`${who.name} takes ${amount} damage${soaked > 0 ? ` (${soaked} absorbed by armor)` : ''} (${Math.max(who.health, 0)} health left).`);
    },

    damageAllEnemyCreatures(ctx: DuelContext, amount: number): void {
        amount += Effects.spellPower(ctx);
        for (const creature of ctx.opponent.board.slice()) {
            creature.takeDamage(amount);
            ctx.log.add(`${creature.source.name} takes ${amount} damage (${Math.max(creature.health, 0)} health left).`);
        }
    },

    heal(ctx: DuelContext, who: Caster, amount: number): void {
        who.heal(amount);
        ctx.log.add(`${who.name} restores ${amount} health (${who.health} health now).`);
    },

    draw(ctx: DuelContext, who: Caster, count = 1): void {
        for (let i = 0; i < count; i++) who.drawCard(ctx.log);
    },

    buff(ctx: DuelContext, target: BoardCreature, name: string, attack: number, health: number): void {
        const mods: StatMod[] = [];
        if (attack !== 0) mods.push({ stat: Stat.Attack, amount: attack });
        if (health !== 0) mods.push({ stat: Stat.MaxHealth, amount: health });
        if (mods.length === 0) return;
        target.addEnchantment({ name, mods });
        const parts = [attack !== 0 ? `+${attack} Attack` : '', health !== 0 ? `+${health} Health` : ''].filter(Boolean);
        ctx.log.add(`${target.source.name} gains ${parts.join(' and ')}.`);
    },

    buffAllFriendly(ctx: DuelContext, name: string, attack: number, health: number): void {
        for (const c of ctx.owner.board.filter(x => x.isAlive))
            Effects.buff(ctx, c, name, attack, health);
    },

    grantTaunt(ctx: DuelContext, target: BoardCreature): void {
        target.addEnchantment({ name: 'Taunt', mods: [{ stat: Stat.Taunt, amount: 1 }] });
        ctx.log.add(`${target.source.name} gains Taunt.`);
    },

    healCreature(ctx: DuelContext, target: BoardCreature, amount: number): void {
        const healed = target.restore(amount);
        ctx.log.add(healed > 0 ? `${target.source.name} restores ${healed} health.` : `${target.source.name} is already undamaged.`);
    },

    damageOwnCaster(ctx: DuelContext, amount: number): void {
        ctx.owner.takeDamage(amount);
        ctx.log.add(`${ctx.owner.name} pays ${amount} health.`);
    },

    damageRandomEnemyCreature(ctx: DuelContext, amount: number): void {
        const living = ctx.opponent.board.filter(c => c.isAlive);
        if (living.length === 0) {
            ctx.opponent.takeDamage(amount);
            ctx.log.add(`Nothing to strike, so ${ctx.opponent.name} takes ${amount}.`);
            return;
        }
        const pick = living[ctx.state.random.next(living.length)];
        pick.takeDamage(amount);
        ctx.log.add(`${pick.source.name} is struck for ${amount}.`);
    },

    gainArmor(ctx: DuelContext, amount: number): void {
        ctx.owner.armor += amount;
        ctx.log.add(`${ctx.owner.name} gains ${amount} Armor.`);
    },

    /** Temporary mana, like The Coin: it can exceed the crystal cap for this turn. */
    gainMana(ctx: DuelContext, amount: number): void {
        ctx.owner.pips += amount;
        ctx.log.add(`${ctx.owner.name} gains ${amount} mana this turn.`);
    },

    heroAttack(ctx: DuelContext, amount: number): void {
        ctx.owner.tempAttack += amount;
        ctx.log.add(`${ctx.owner.name} gains +${amount} Attack this turn.`);
    },

    silence(ctx: DuelContext, target: BoardCreature): void {
        target.silence();
        ctx.log.add(`${target.source.name} is silenced.`);
    },

    /** Offers 3 different collectible cards from the owner's class and neutral, filtered by type. */
    discover(ctx: DuelContext, type: CardType | 'any'): void {
        const pool = CardSet.all.filter(c => c.collectible
            && (c.cls === ctx.owner.cls || c.cls === 'neutral')
            && (type === 'any' || c.type === type));
        const options: CardDef[] = [];
        const remaining = pool.slice();
        while (options.length < 3 && remaining.length > 0)
            options.push(remaining.splice(ctx.state.random.next(remaining.length), 1)[0]);
        if (options.length === 0) { ctx.log.add('There is nothing to Discover.'); return; }
        ctx.state.pendingChoice = { owner: ctx.owner, options };
        ctx.log.add(`${ctx.owner.name} discovers from ${options.length} cards.`);
    },

    destroyCreature(ctx: DuelContext, target: BoardCreature): void {
        target.destroy();
        ctx.log.add(`${target.source.name} is destroyed.`);
    },

    freeze(ctx: DuelContext, target: BoardCreature): void {
        target.frozen = true;
        ctx.log.add(`${target.source.name} is frozen.`);
    },

    summon(ctx: DuelContext, cardId: string, count: number): void {
        const card = CardSet.byId(cardId);
        for (let i = 0; i < count; i++) {
            if (ctx.owner.board.length >= BOARD_CAP) { ctx.log.add('The board is full.'); return; }
            ctx.owner.board.push(BoardCreature.fromCard(card));
            ctx.log.add(`${card.name} is summoned.`);
        }
    },
};

// ── the card pool ───────────────────────────────────────────────────────────

let loaded: CardData | null = null;

export const CardSet = {
    load(data: CardData): void { loaded = data; },

    get data(): CardData {
        if (!loaded) throw new Error('Card pool not loaded. Call CardSet.load(loadCardData(json)) first.');
        return loaded;
    },

    byId(id: string): CardDef { return CardSet.data.byId(id); },
    get all(): CardDef[] { return CardSet.data.cards; },
    powerFor(cls: PlayerClass): HeroPower { return CardSet.data.powerFor(cls); },

    starterDeck(): CardDef[] {
        const recipe = CardSet.data.starterDeck;
        const deck: CardDef[] = [];
        for (const id of recipe.order) {
            const card = CardSet.data.byId(id);
            const copies = recipe.counts[id] ?? 1;
            for (let i = 0; i < copies; i++) deck.push(card);
        }
        return deck;
    },
};

// ── turn engine ─────────────────────────────────────────────────────────────

function makeContext(state: DuelState, owner: Caster, opponent: Caster, target: BoardCreature | null,
                     isFirstSpell: boolean, spellDamageApplies: boolean, comboActive = false): DuelContext {
    return { state, owner, opponent, target, isFirstSpellThisTurn: isFirstSpell, comboActive, spellDamageApplies, log: new ResolutionLog() };
}

/** Uncollectible 0-mana spell the second player gets: +1 mana this turn. */
export const THE_COIN_ID = 'the-coin';

export const TurnEngine = {
    /** Deals opening hands (3 for the first player, 4 for the second) and opens the mulligan. */
    setupGame(state: DuelState): void {
        const log = new ResolutionLog();
        state.a.dealOpeningHand(3, log);
        state.b.dealOpeningHand(4, log);
        state.log.push(...log.lines);
        state.mulliganPending = true;
    },

    /** Returns the chosen opening cards to the deck and draws replacements. */
    mulligan(state: DuelState, who: Caster, replace: CardDef[]): boolean {
        if (!state.mulliganPending) return false;
        const out: CardDef[] = [];
        for (const card of replace) {
            const i = who.hand.indexOf(card);
            if (i >= 0) out.push(who.hand.splice(i, 1)[0]);
        }
        const log = new ResolutionLog();
        for (let i = 0; i < out.length; i++) who.drawCard(log);
        who.deck = state.random.shuffled([...who.deck, ...out]);
        state.log.push(`${who.name} replaces ${out.length} card${out.length === 1 ? '' : 's'}.`);
        return true;
    },

    /** Ends the mulligan: the second player gets The Coin and the first player's turn 1 begins. */
    startGame(state: DuelState): void {
        state.mulliganPending = false;
        const log = new ResolutionLog();
        const coin = CardSet.data.cards.find(c => c.id === THE_COIN_ID);
        if (coin && state.b.receive(coin, log)) log.add(`${state.b.name} gets The Coin.`);
        state.active = state.a;
        state.a.startTurn(log);
        state.log.push(...log.lines);
    },

    runGame(state: DuelState, controllerA: PlayerController, controllerB: PlayerController, maxTurns = 200): void {
        if (state.mulliganPending) TurnEngine.startGame(state);
        else {
            const log = new ResolutionLog();
            state.active = state.a;
            state.a.startTurn(log);
            state.log.push(...log.lines);
        }

        // Guard against a controller that never passes: a legal action always changes
        // state, so thousands of actions in one game means a controller bug.
        let safety = 0;
        while (!state.isOver && state.turnNumber <= maxTurns && safety++ < 100_000) {
            const who = state.pendingChoice?.owner ?? state.active;
            const controller = who === state.a ? controllerA : controllerB;
            const opponent = who === state.a ? state.b : state.a;
            if (!TurnEngine.apply(state, controller.chooseAction(state, who, opponent)) && !state.pendingChoice)
                TurnEngine.endTurn(state); // a refused action must never stall the game
        }
    },

    /** Applies one action. Returns false when the engine refused it. */
    apply(state: DuelState, action: PlayerAction): boolean {
        if (state.mulliganPending || state.isOver) return false;
        if (state.pendingChoice && action.kind !== 'discover') return false;
        switch (action.kind) {
            case 'playCard': return TurnEngine.tryPlayCard(state, action.card, action.target, action.choice);
            case 'attack': return TurnEngine.tryAttack(state, action.attacker, action.target);
            case 'heroAttack': return TurnEngine.tryHeroAttack(state, action.target);
            case 'heroPower': return TurnEngine.tryUseHeroPower(state, action.target);
            case 'discover': return TurnEngine.chooseDiscover(state, action.index);
            case 'pass': TurnEngine.endTurn(state); return true;
        }
    },

    /** Why this card cannot be played right now, or null when it can (ignoring its target). */
    whyUnplayable(state: DuelState, card: CardDef): string | null {
        const owner = state.active;
        if (owner.pips < card.cost) return `${card.name} costs ${card.cost}; you have ${owner.pips} mana.`;
        if (card.type === 'creature' && owner.board.length >= BOARD_CAP) return 'Your board is full (7 creatures).';
        if (card.secret) {
            if (owner.secrets.some(x => x.id === card.id)) return `${card.name} is already active.`;
            if (owner.secrets.length >= SECRET_CAP) return 'You already have 5 Secrets.';
        }
        return null;
    },

    tryPlayCard(state: DuelState, card: CardDef, target: BoardCreature | null, choice?: number): boolean {
        const owner = state.active, opponent = state.waiting;
        if (!owner.hand.includes(card) || TurnEngine.whyUnplayable(state, card)) return false;

        // Choose One: the picked branch supplies the targeting and the effect.
        let targeting = card.targeting, targetSide = card.targetSide, onPlay = card.onPlay;
        if (card.chooseOne) {
            const option = choice === undefined ? undefined : card.chooseOne[choice];
            if (!option) return false;
            ({ targeting, targetSide, onPlay } = option);
        }
        if (targeting === 'none') target = null;
        if (target && !TurnEngine.legalCreatureTargets(state, targetSide).includes(target)) return false;
        if (targeting === 'requiredCreature' && !target) return false;

        owner.pips -= card.cost;
        owner.hand.splice(owner.hand.indexOf(card), 1);
        const combo = owner.cardsPlayedThisTurn > 0;
        owner.cardsPlayedThisTurn++;
        if (card.overload) owner.overloadNext += card.overload;

        const isSpell = card.type === 'spell';
        const isFirstSpell = isSpell && owner.spellsCastThisTurn === 0;
        if (isSpell) owner.spellsCastThisTurn++;

        if (card.secret) {
            owner.secrets.push(card);
            state.log.push(`${owner.name} casts a Secret.`);
            return true;
        }

        const branch = card.chooseOne && choice !== undefined ? ` (${card.chooseOne[choice].name})` : '';
        state.log.push(`${owner.name} plays ${card.name}${branch}.`);

        // Counter-Secrets cancel a spell before it does anything, but the mana is spent.
        if (isSpell && TurnEngine.fireSecrets(state, 'enemyCastsSpell', null)) {
            cleanupDead(state);
            return true;
        }

        let summoned: BoardCreature | null = null;
        if (card.type === 'creature') {
            summoned = BoardCreature.fromCard(card);
            summoned.landedOnTurn = state.turnNumber;
            owner.board.push(summoned);
        }
        if (card.type === 'weapon') {
            if (owner.weapon) state.log.push(`${owner.name}'s ${owner.weapon.card.name} is replaced.`);
            owner.weapon = { card, attack: card.attack, durability: Math.max(1, card.durability ?? 1) };
        }

        if (onPlay) {
            const ctx = makeContext(state, owner, opponent, target, isFirstSpell, isSpell, combo);
            onPlay(ctx);
            state.log.push(...ctx.log.lines);
        }

        if (summoned) TurnEngine.fireSecrets(state, 'enemyPlaysCreature', summoned);
        cleanupDead(state);
        return true;
    },

    /**
     * Fires the waiting player's Secrets that match this trigger, each at most once.
     * Returns true when one of them countered the action.
     */
    fireSecrets(state: DuelState, trigger: SecretTrigger, target: BoardCreature | null): boolean {
        const defender = state.waiting, attacker = state.active;
        let countered = false;
        for (const secret of defender.secrets.filter(x => x.secret?.trigger === trigger)) {
            defender.secrets.splice(defender.secrets.indexOf(secret), 1);
            state.log.push(`Secret revealed: ${secret.name}!`);
            if (secret.secret?.onTrigger) {
                const ctx = makeContext(state, defender, attacker, target, false, true);
                secret.secret.onTrigger(ctx);
                state.log.push(...ctx.log.lines);
            }
            if (secret.secret?.counter) { countered = true; state.log.push('The spell is countered.'); }
        }
        return countered;
    },

    /**
     * Creatures a spell, battlecry or hero power may aim at. Enemy effects cannot
     * pick a Stealthed creature; friendly effects may pick any of your own.
     */
    legalCreatureTargets(state: DuelState, side: TargetSide): BoardCreature[] {
        const board = side === 'friendly' ? state.active.board : state.waiting.board;
        return board.filter(c => c.isAlive && (side === 'friendly' || !c.stealth));
    },

    /** Every legal target for this attacker right now. Null means the enemy caster. */
    legalAttackTargets(state: DuelState, attacker: BoardCreature): (BoardCreature | null)[] {
        const targets: (BoardCreature | null)[] = [];
        if (!state.active.board.includes(attacker) || !attacker.canAttackNow) return targets;

        const visible = state.waiting.board.filter(c => c.isAlive && !c.stealth);
        const taunts = visible.filter(c => c.taunt);
        if (taunts.length > 0) return taunts;

        targets.push(...visible);
        const justLanded = attacker.rush && !attacker.charge && state.turnNumber === attacker.landedOnTurn;
        if (!justLanded) targets.push(null);
        return targets;
    },

    /** Legal targets for your hero's attack. Null means the enemy caster. */
    legalHeroAttackTargets(state: DuelState): (BoardCreature | null)[] {
        if (!state.active.canHeroAttack) return [];
        const visible = state.waiting.board.filter(c => c.isAlive && !c.stealth);
        const taunts = visible.filter(c => c.taunt);
        return taunts.length > 0 ? taunts : [...visible, null];
    },

    tryHeroAttack(state: DuelState, target: BoardCreature | null): boolean {
        const owner = state.active, opponent = state.waiting;
        if (!TurnEngine.legalHeroAttackTargets(state).includes(target)) return false;

        owner.heroAttacksThisTurn++;
        TurnEngine.fireSecrets(state, 'enemyAttacks', null);
        if (!owner.isAlive || (target && !target.isAlive)) { cleanupDead(state); return true; }

        const attack = owner.heroAttack;
        if (!target) {
            opponent.takeDamage(attack);
            state.log.push(`${owner.name} attacks ${opponent.name} for ${attack}.`);
        } else {
            const incoming = target.attack;
            target.takeDamage(attack);
            owner.takeDamage(incoming);
            state.log.push(`${owner.name} attacks ${target.source.name} (${attack} <-> ${incoming}).`);
        }

        if (owner.weapon) {
            owner.weapon.durability--;
            if (owner.weapon.durability <= 0) {
                state.log.push(`${owner.name}'s ${owner.weapon.card.name} breaks.`);
                owner.weapon = null;
            }
        }
        cleanupDead(state);
        return true;
    },

    chooseDiscover(state: DuelState, index: number): boolean {
        const pending = state.pendingChoice;
        if (!pending || !pending.options[index]) return false;
        state.pendingChoice = null;
        const log = new ResolutionLog();
        const card = pending.options[index];
        if (pending.owner.receive(card, log)) log.add(`${pending.owner.name} discovers ${card.name}.`);
        state.log.push(...log.lines);
        return true;
    },

    tryUseHeroPower(state: DuelState, target: BoardCreature | null): boolean {
        const owner = state.active, opponent = state.waiting;
        const power = CardSet.powerFor(owner.cls);

        if (owner.heroPowerUsedThisTurn || owner.pips < power.cost) return false;
        if (power.targeting === 'requiredCreature' && !target) return false;
        if (power.targeting === 'none') target = null;
        if (target && !TurnEngine.legalCreatureTargets(state, power.targetSide).includes(target)) return false;

        owner.pips -= power.cost;
        owner.heroPowerUsedThisTurn = true;
        state.log.push(`${owner.name} uses ${power.name}.`);

        if (power.onUse) {
            const ctx = makeContext(state, owner, opponent, target, false, false);
            power.onUse(ctx);
            state.log.push(...ctx.log.lines);
        }

        cleanupDead(state);
        return true;
    },

    tryAttack(state: DuelState, attacker: BoardCreature, target: BoardCreature | null): boolean {
        const owner = state.active, opponent = state.waiting;
        if (!TurnEngine.legalAttackTargets(state, attacker).includes(target)) return false;

        attacker.attacksThisTurn++;
        attacker.onDealtDamage();

        // Attack Secrets resolve first; a trap that kills the attacker stops the swing.
        TurnEngine.fireSecrets(state, 'enemyAttacks', attacker);
        if (!attacker.isAlive || (target && !target.isAlive)) { cleanupDead(state); return true; }

        let dealt: number;
        if (!target) {
            dealt = attacker.attack;
            opponent.takeDamage(dealt);
            state.log.push(`${attacker.source.name} attacks ${opponent.name} for ${dealt}.`);
        } else {
            const incoming = target.attack;
            dealt = target.takeDamage(attacker.attack);
            const taken = attacker.takeDamage(incoming);
            state.log.push(`${attacker.source.name} trades with ${target.source.name} (${attacker.attack} <-> ${incoming}).`);

            if (dealt > 0 && attacker.poisonous) { target.destroy(); state.log.push(`${target.source.name} succumbs to poison.`); }
            if (taken > 0 && target.poisonous) { attacker.destroy(); state.log.push(`${attacker.source.name} succumbs to poison.`); }

            if (taken > 0) {
                target.onDealtDamage();
                if (target.lifesteal) {
                    opponent.heal(taken);
                    state.log.push(`${opponent.name} drains ${taken}.`);
                }
            }
        }

        if (dealt > 0 && attacker.lifesteal) {
            owner.heal(dealt);
            state.log.push(`${owner.name} drains ${dealt}.`);
        }

        cleanupDead(state);
        return true;
    },

    endTurn(state: DuelState): void {
        if (state.mulliganPending || state.isOver) return;
        // A Discover left open when the turn ends takes its first option.
        if (state.pendingChoice) TurnEngine.chooseDiscover(state, 0);
        state.log.push(`-- ${state.active.name} ends turn ${state.turnNumber} --`);
        state.active = state.waiting;
        if (state.active === state.a) state.turnNumber++;
        const log = new ResolutionLog();
        state.active.startTurn(log);
        state.log.push(...log.lines);
    },
};

function cleanupDead(state: DuelState): void {
    for (let pass = 0; pass < 8; pass++) {
        let removed = 0;
        for (const [owner, opponent] of [[state.a, state.b], [state.b, state.a]] as const) {
            const dead = owner.board.filter(c => !c.isAlive);
            if (dead.length === 0) continue;

            for (let i = owner.board.length - 1; i >= 0; i--)
                if (!owner.board[i].isAlive) owner.board.splice(i, 1);
            removed += dead.length;

            // Deathrattles fire after the body leaves, so a summon cannot collide with the corpse.
            for (const corpse of dead) {
                const deathrattle = corpse.deathrattle;
                if (!deathrattle) continue;
                state.log.push(`${corpse.source.name}'s deathrattle triggers.`);
                const ctx = makeContext(state, owner, opponent, null, false, false);
                deathrattle(ctx);
                state.log.push(...ctx.log.lines);
            }
        }
        AuraSystem.refresh(state);
        if (removed === 0) break;
    }
}
