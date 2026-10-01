// A dumb-but-legal opponent, ported from GreedyAI.cs and extended for the parity rules:
// play the most expensive playable card (aiming at the strongest target when one helps),
// use the hero power with leftover mana, attack with every creature, then with the hero,
// asking the engine what is legal rather than re-deriving Taunt, Rush and Stealth.

import { BoardCreature, CardDef, CardSet, Caster, DuelState, PlayerAction, PlayerController, TargetRule, TargetSide, TurnEngine } from './engine';

function pickTarget(state: DuelState, targeting: TargetRule, side: TargetSide): BoardCreature | null | undefined {
    if (targeting === 'none') return null;
    const best = TurnEngine.legalCreatureTargets(state, side).sort((x, y) => y.attack - x.attack)[0] ?? null;
    if (targeting === 'requiredCreature' && !best) return undefined; // cannot be played now
    return best;
}

function planCard(state: DuelState, card: CardDef): PlayerAction | null {
    if (card.chooseOne) {
        for (let i = 0; i < card.chooseOne.length; i++) {
            const option = card.chooseOne[i];
            const target = pickTarget(state, option.targeting, option.targetSide);
            if (target !== undefined) return { kind: 'playCard', card, target, choice: i };
        }
        return null;
    }
    const target = pickTarget(state, card.targeting, card.targetSide);
    return target === undefined ? null : { kind: 'playCard', card, target };
}

export class GreedyAI implements PlayerController {
    constructor(readonly name: string) {}

    chooseAction(state: DuelState, me: Caster, _opponent: Caster): PlayerAction {
        // Discover: take the most expensive offer.
        if (state.pendingChoice?.owner === me) {
            const options = state.pendingChoice.options;
            let best = 0;
            options.forEach((c, i) => { if (c.cost > options[best].cost) best = i; });
            return { kind: 'discover', index: best };
        }

        const playable = me.hand.filter(c => !TurnEngine.whyUnplayable(state, c)).sort((x, y) => y.cost - x.cost);
        for (const card of playable) {
            const plan = planCard(state, card);
            if (plan) return plan;
        }

        const power = CardSet.powerFor(me.cls);
        if (!me.heroPowerUsedThisTurn && me.pips >= power.cost) {
            const target = pickTarget(state, power.targeting, power.targetSide);
            if (target !== undefined) return { kind: 'heroPower', target };
        }

        for (const candidate of me.board.filter(c => c.canAttackNow)) {
            const targets = TurnEngine.legalAttackTargets(state, candidate);
            if (targets.length === 0) continue;
            const kill = targets.find((t): t is BoardCreature =>
                t !== null && t.health <= candidate.attack && t.attack < candidate.health);
            const best = kill ?? (targets.includes(null) ? null : targets[0]);
            return { kind: 'attack', attacker: candidate, target: best };
        }

        const heroTargets = TurnEngine.legalHeroAttackTargets(state);
        if (heroTargets.length > 0) {
            const kill = heroTargets.find((t): t is BoardCreature =>
                t !== null && t.health <= me.heroAttack && t.attack < me.health + me.armor - 5);
            return { kind: 'heroAttack', target: kill ?? (heroTargets.includes(null) ? null : heroTargets[0]) };
        }

        return { kind: 'pass' };
    }
}
