// Cards as data: game/data/cards.json names effects from the registry below.
// Adding a card needs no code; only a new KIND of effect does. Loading fails
// loudly with the offending card id instead of producing a card that silently
// does nothing (DESIGN.md principle 3).

import {
    AuraDef, AuraScope, CardData, CardDef, CardEffect, CardType, ChoiceOption, DeckRecipe, DuelContext, SecretTrigger,
    Effects, Element, HeroPower, PLAYER_CLASSES, PlayerClass, Rarity, Stat, StatMod, TargetRule, TargetSide,
} from './engine';

interface EffectStep {
    effect: string;
    amount: number;
    attack: number;
    health: number;
    card: string | null;
    condition: string | null;
    /** Discover: which card type to offer ('spell', 'creature', 'weapon' or 'any'). */
    pool: string;
}

// Lowercase keys: effect names are matched case-insensitively, as in the C# loader.
const EFFECTS: Record<string, (ctx: DuelContext, s: EffectStep) => void> = {
    damage: (ctx, s) => Effects.damage(ctx, s.amount),
    damageenemycaster: (ctx, s) => {
        Effects.damageCaster(ctx, ctx.opponent, s.amount);
    },
    damageallenemycreatures: (ctx, s) => Effects.damageAllEnemyCreatures(ctx, s.amount),
    healcaster: (ctx, s) => Effects.heal(ctx, ctx.owner, s.amount),
    draw: (ctx, s) => Effects.draw(ctx, ctx.owner, s.amount),
    bufftarget: (ctx, s) => { if (ctx.target) Effects.buff(ctx, ctx.target, s.card ?? 'Buff', s.attack, s.health); },
    buffself: (ctx, s) => {
        const living = ctx.owner.board.filter(c => c.isAlive);
        const last = living[living.length - 1];
        if (last) Effects.buff(ctx, last, s.card ?? 'Buff', s.attack, s.health);
    },
    buffallfriendly: (ctx, s) => Effects.buffAllFriendly(ctx, s.card ?? 'Inspired', s.attack, s.health),
    granttaunt: (ctx) => { if (ctx.target) Effects.grantTaunt(ctx, ctx.target); },
    healtarget: (ctx, s) => { if (ctx.target) Effects.healCreature(ctx, ctx.target, s.amount); },
    damageowncaster: (ctx, s) => Effects.damageOwnCaster(ctx, s.amount),
    damagerandomenemycreature: (ctx, s) => Effects.damageRandomEnemyCreature(ctx, s.amount),
    destroytarget: (ctx) => { if (ctx.target) Effects.destroyCreature(ctx, ctx.target); },
    freezetarget: (ctx) => { if (ctx.target) Effects.freeze(ctx, ctx.target); },
    summon: (ctx, s) => { if (s.card) Effects.summon(ctx, s.card, Math.max(1, s.amount)); },
    gainarmor: (ctx, s) => Effects.gainArmor(ctx, s.amount),
    gainmana: (ctx, s) => Effects.gainMana(ctx, s.amount),
    heroattack: (ctx, s) => Effects.heroAttack(ctx, s.amount),
    silencetarget: (ctx) => { if (ctx.target) Effects.silence(ctx, ctx.target); },
    discover: (ctx, s) => Effects.discover(ctx, (s.pool || 'any') as CardType | 'any'),
};

// Target effects that help the chosen creature aim at your own board; the rest aim at the enemy's.
const FRIENDLY_TARGET_EFFECTS = new Set(['bufftarget', 'granttaunt', 'healtarget']);
const ENEMY_TARGET_EFFECTS = new Set(['damage', 'destroytarget', 'freezetarget', 'silencetarget']);

/** Explicit targetSide wins; otherwise infer it from the effects, refusing a mix of both. */
function readTargetSide(raw: unknown, steps: EffectStep[], owner: string): TargetSide {
    const friendly = steps.some(s => FRIENDLY_TARGET_EFFECTS.has(s.effect));
    const enemy = steps.some(s => ENEMY_TARGET_EFFECTS.has(s.effect));
    if (raw !== undefined && raw !== null && raw !== '') return oneOf<TargetSide>(raw, ['enemy', 'friendly'], owner, 'targetSide', 'enemy');
    if (friendly && enemy)
        throw new Error(`Card '${owner}' mixes friendly and enemy target effects; set "targetSide" explicitly.`);
    return friendly ? 'friendly' : 'enemy';
}

const CONDITIONS: Record<string, (ctx: DuelContext) => boolean> = {
    firstspellthisturn: ctx => ctx.isFirstSpellThisTurn,
    combo: ctx => ctx.comboActive,
};

const STAT_NAMES: Record<string, Stat> = {
    attack: Stat.Attack, maxhealth: Stat.MaxHealth, taunt: Stat.Taunt, rush: Stat.Rush,
    charge: Stat.Charge, divineshield: Stat.DivineShield, lifesteal: Stat.Lifesteal,
    windfury: Stat.Windfury, poisonous: Stat.Poisonous, stealth: Stat.Stealth, spelldamage: Stat.SpellDamage,
};

type Json = Record<string, unknown>;

function oneOf<T extends string>(raw: unknown, valid: readonly T[], cardId: string, field: string, fallback: T): T {
    if (raw === undefined || raw === null || raw === '') return fallback;
    const lower = String(raw).toLowerCase();
    const match = valid.find(v => v.toLowerCase() === lower);
    if (!match) throw new Error(`Card '${cardId}' has an invalid ${field} '${raw}'. Valid: ${valid.join(', ')}.`);
    return match;
}

const num = (v: unknown, fallback = 0): number => (typeof v === 'number' ? v : fallback);
const str = (v: unknown, fallback = ''): string => (typeof v === 'string' ? v : fallback);
const arr = (v: unknown): Json[] => (Array.isArray(v) ? (v as Json[]) : []);

function readStep(n: Json): EffectStep {
    const effect = str(n.effect);
    if (!EFFECTS[effect.toLowerCase()])
        throw new Error(`Unknown effect '${effect}'. Known: ${Object.keys(EFFECTS).join(', ')}.`);
    const condition = typeof n.condition === 'string' ? n.condition : null;
    if (condition !== null && !CONDITIONS[condition.toLowerCase()])
        throw new Error(`Unknown condition '${condition}'. Known: ${Object.keys(CONDITIONS).join(', ')}.`);
    return {
        effect: effect.toLowerCase(),
        amount: num(n.amount),
        attack: num(n.attack),
        health: num(n.health),
        card: typeof n.card === 'string' ? n.card : null,
        condition: condition?.toLowerCase() ?? null,
        pool: typeof n.pool === 'string' ? n.pool.toLowerCase() : 'any',
    };
}

function compile(steps: EffectStep[]): CardEffect | undefined {
    if (steps.length === 0) return undefined;
    return ctx => {
        for (const step of steps) {
            if (step.condition && !CONDITIONS[step.condition](ctx)) continue;
            EFFECTS[step.effect](ctx, step);
        }
    };
}

function readKeywords(node: unknown, cardId: string): Stat[] | undefined {
    const raw = arr(node).map(v => String(v)).filter(v => v.length > 0);
    if (raw.length === 0) return undefined;
    return raw.map(k => {
        const stat = STAT_NAMES[k.toLowerCase()];
        if (stat === undefined) throw new Error(`Card '${cardId}' has an invalid keyword '${k}'.`);
        if (stat === Stat.Attack || stat === Stat.MaxHealth)
            throw new Error(`Card '${cardId}' lists '${k}' as a keyword; it is a stat.`);
        return stat;
    });
}

function readAura(n: Json, cardId: string): AuraDef {
    const scope = oneOf<AuraScope>(n.scope, ['friendlyOthers', 'friendlyAll', 'enemyAll', 'allCreatures'], cardId, 'aura.scope', 'friendlyOthers');
    const mods: StatMod[] = arr(n.mods).map(m => {
        const stat = STAT_NAMES[str(m.stat).toLowerCase()];
        if (stat === undefined) throw new Error(`Card '${cardId}' has an invalid aura stat '${m.stat}'.`);
        return { stat, amount: num(m.amount) };
    });
    if (mods.length === 0) throw new Error(`Card '${cardId}' declares an aura with no mods.`);
    return { scope, mods, text: str(n.text) };
}

function readSecret(n: Json, cardId: string): { trigger: SecretTrigger; onTrigger?: CardEffect; counter?: boolean } {
    return {
        trigger: oneOf<SecretTrigger>(n.trigger, ['enemyAttacks', 'enemyPlaysCreature', 'enemyCastsSpell'], cardId, 'secret.trigger', 'enemyAttacks'),
        onTrigger: compile(arr(n.onTrigger).map(readStep)),
        counter: n.counter === true,
    };
}

function readChoice(n: Json, owner: string): ChoiceOption {
    const steps = arr(n.onPlay).map(readStep);
    return {
        name: str(n.name, owner),
        text: str(n.text),
        targeting: oneOf<TargetRule>(n.targeting, ['none', 'optionalCreature', 'requiredCreature'], owner, 'targeting', 'none'),
        targetSide: readTargetSide(n.targetSide, steps, owner),
        onPlay: compile(steps),
    };
}

/** Appends another card file's sets to the base file, so web-only cards stay out of cards.json. */
export function mergeCardJson(base: Json, extra: Json): Json {
    return { ...base, sets: [...arr(base.sets), ...arr(extra.sets)] };
}

function readCard(n: Json): CardDef {
    const id = str(n.id);
    if (!id) throw new Error("A card is missing its 'id'.");
    try {
        const onPlaySteps = arr(n.onPlay).map(readStep);
        return {
            id,
            name: str(n.name, id),
            cost: num(n.cost),
            type: oneOf<CardType>(n.type, ['spell', 'creature', 'weapon'], id, 'type', 'creature'),
            element: oneOf<Element>(n.element, ['fire', 'water', 'earth', 'air', 'storm'], id, 'element', 'fire'),
            rarity: oneOf<Rarity>(n.rarity, ['common', 'rare', 'epic', 'legendary'], id, 'rarity', 'common'),
            text: str(n.text),
            cls: oneOf<PlayerClass>(n.class, PLAYER_CLASSES, id, 'class', 'neutral'),
            attack: num(n.attack),
            health: num(n.health),
            taunt: n.taunt === true,
            keywords: readKeywords(n.keywords, id),
            spellDamage: num(n.spellDamage),
            onDeath: compile(arr(n.deathrattle).map(readStep)),
            targeting: oneOf<TargetRule>(n.targeting, ['none', 'optionalCreature', 'requiredCreature'], id, 'targeting', 'none'),
            targetSide: readTargetSide(n.targetSide, onPlaySteps, id),
            onPlay: compile(onPlaySteps),
            aura: n.aura ? readAura(n.aura as Json, id) : undefined,
            durability: typeof n.durability === 'number' ? n.durability : undefined,
            secret: n.secret ? readSecret(n.secret as Json, id) : undefined,
            chooseOne: Array.isArray(n.chooseOne) ? arr(n.chooseOne).map((o, i) => readChoice(o, `${id}#${i}`)) : undefined,
            overload: typeof n.overload === 'number' ? n.overload : undefined,
            collectible: n.collectible !== false,
        };
    } catch (e) {
        const message = e instanceof Error ? e.message : String(e);
        throw new Error(message.startsWith(`Card '${id}'`) ? message : `Card '${id}' failed to load: ${message}`);
    }
}

/** Parses the contents of game/data/cards.json. Throws on any malformed card. */
export function loadCardData(root: Json): CardData {
    const cards: CardDef[] = [];
    for (const node of arr(root.cards)) cards.push(readCard(node));
    for (const set of arr(root.sets))
        for (const node of arr(set.cards)) cards.push(readCard(node));

    const seen = new Set<string>(), duplicates = new Set<string>();
    for (const c of cards) (seen.has(c.id) ? duplicates : seen).add(c.id);
    if (duplicates.size > 0) throw new Error(`Duplicate card ids: ${[...duplicates].join(', ')}.`);

    const deckNode = (root.starterDeck ?? {}) as Json;
    const order = arr(deckNode.order).map(v => String(v));
    const countsNode = (deckNode.counts ?? {}) as Json;
    const starterDeck: DeckRecipe = { order, counts: Object.fromEntries(order.map(id => [id, num(countsNode[id], 1)])) };

    const heroPowers: Partial<Record<PlayerClass, HeroPower>> = {};
    const hpNode = (root.heroPowers ?? {}) as Json;
    for (const cls of PLAYER_CLASSES) {
        const n = hpNode[cls] as Json | undefined;
        if (!n) continue;
        const steps = arr(n.onPlay).map(readStep);
        heroPowers[cls] = {
            name: str(n.name, cls),
            cost: num(n.cost, 2),
            text: str(n.text),
            targeting: oneOf<TargetRule>(n.targeting, ['none', 'optionalCreature', 'requiredCreature'], `heroPower:${cls}`, 'targeting', 'none'),
            targetSide: readTargetSide(n.targetSide, steps, `heroPower:${cls}`),
            onUse: compile(steps),
        };
    }

    return new CardData(cards, starterDeck, heroPowers);
}
