import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import cardsJson from '../../../data/cards.json';
import parityJson from '../data/parity-cards.json';
import {
    BoardCreature, CardData, CardDef, CardSet, Caster, DuelState, PLAYER_CLASSES, PlayerAction, PlayerClass,
    TargetRule, TargetSide, TurnEngine,
} from '../engine/engine';
import { loadCardData, mergeCardJson } from '../engine/loader';
import { buildClassDeck } from '../engine/constructed';
import { GreedyAI } from '../engine/ai';
import { Rng } from '../engine/rng';
import { CardBacks, CardFace, Floater, HeroPortrait, ManaBar, MinionToken, WeaponToken } from './CardView';
import './duel.css';
import './hs.css';

type Json = Record<string, unknown>;
const defaultCardData = loadCardData(mergeCardJson(cardsJson as Json, parityJson as Json));
CardSet.load(defaultCardData);

const TURN_SECONDS = 75;
const ROPE_AT = 15;
const AI_STEP_MS = 700;
const FIGHT_CLASSES = PLAYER_CLASSES.filter(c => c !== 'neutral');
const EMOTES = ['Greetings.', 'Well played.', 'Thanks.', 'Wow!', 'Oops.', 'Threaten'] as const;
const THREATS: Partial<Record<PlayerClass, string>> = { wizard: 'My magic will tear you apart!', rogue: "I'll cut you!", fighter: "I'll crush you!" };

type Pending =
    | { kind: 'none' }
    | { kind: 'card'; card: CardDef; choice?: number }
    | { kind: 'choose'; card: CardDef }
    | { kind: 'attacker'; attacker: BoardCreature }
    | { kind: 'heroAttacker' }
    | { kind: 'heroPower' };

export interface DuelProps {
    playerDeck?: CardDef[];
    enemyDeck?: CardDef[];
    enemyName?: string;
    enemyHealth?: number;
    playerHealth?: number;
    fixedClass?: PlayerClass;
    cardData?: CardData;
    seed?: number;
    onEnd?: (won: boolean, remainingHealth: number) => void;
}

/** Island fights pass their own decks; a free duel builds 30-card constructed decks for both classes. */
function newDuel(playerClass: PlayerClass, props: DuelProps): DuelState {
    CardSet.load(props.cardData ?? defaultCardData);
    const rng = new Rng(props.seed);
    const foeClass = props.enemyDeck ? 'neutral' : FIGHT_CLASSES[rng.next(FIGHT_CLASSES.length)];
    // Engine log lines are third person ("X draws"), so the player needs a name, not "You".
    const you = new Caster('Player', playerClass);
    if (props.playerHealth !== undefined) you.health = Math.max(1, Math.min(you.maxHealth, props.playerHealth));
    const foe = new Caster(props.enemyName ?? `${foeClass[0].toUpperCase()}${foeClass.slice(1)} AI`, foeClass);
    if (props.enemyHealth) { foe.maxHealth = props.enemyHealth; foe.health = props.enemyHealth; }
    you.deck = rng.shuffled(props.playerDeck ?? buildClassDeck(playerClass, rng));
    foe.deck = rng.shuffled(props.enemyDeck ?? buildClassDeck(foeClass, rng));
    const state = new DuelState(you, foe, rng);
    TurnEngine.setupGame(state);
    return state;
}

/** Hero and creature health (armor included for heroes), keyed the way floaters are keyed. */
function snapshot(s: DuelState): Map<string, number> {
    const m = new Map<string, number>();
    m.set('hero-a', s.a.health + s.a.armor);
    m.set('hero-b', s.b.health + s.b.armor);
    for (const c of [...s.a.board, ...s.b.board]) m.set(String(c.uid), c.health);
    return m;
}

export function DuelScreen(props: DuelProps = {}) {
    const [playerClass, setPlayerClass] = useState<PlayerClass>(props.fixedClass ?? 'rogue');
    useEffect(() => {
        CardSet.load(props.cardData ?? defaultCardData);
        return () => { CardSet.load(defaultCardData); };
    }, [props.cardData]);
    const stateRef = useRef<DuelState>(null as unknown as DuelState);
    if (!stateRef.current) stateRef.current = newDuel(playerClass, props);
    const [, setVersion] = useState(0);
    const rerender = useCallback(() => setVersion(v => v + 1), []);
    const [pending, setPending] = useState<Pending>({ kind: 'none' });
    const [secondsLeft, setSecondsLeft] = useState(TURN_SECONDS);
    const [notice, setNotice] = useState('');
    const [mulliganPicks, setMulliganPicks] = useState<Set<number>>(new Set());
    const [floaters, setFloaters] = useState<Floater[]>([]);
    const [lunge, setLunge] = useState<string | null>(null);
    const [emotes, setEmotes] = useState<{ a?: string; b?: string }>({});
    const [emoteMenu, setEmoteMenu] = useState(false);
    const floaterKey = useRef(1);
    const logRef = useRef<HTMLDivElement>(null);
    const ai = useMemo(() => new GreedyAI('AI'), []);

    const state = stateRef.current;
    const you = state.a, foe = state.b;
    const yourTurn = state.active === you && !state.isOver && !state.mulliganPending;
    const yourPick = state.pendingChoice?.owner === you;
    const power = CardSet.powerFor(you.cls);
    // Development only: lets browser checks stage exact situations. Stripped from production builds.
    if (import.meta.env.DEV) (window as unknown as { __duel: unknown }).__duel = { state, rerender, CardSet };

    const say = useCallback((who: 'a' | 'b', text: string) => {
        setEmotes(e => ({ ...e, [who]: text }));
        setTimeout(() => setEmotes(e => ({ ...e, [who]: undefined })), 2500);
    }, []);

    /** Runs one engine mutation, then turns health changes into floating numbers. */
    const run = useCallback((mutate: () => boolean, attackerId?: string): boolean => {
        const s = stateRef.current;
        const before = snapshot(s);
        const ok = mutate();
        const after = snapshot(s);
        const born: Floater[] = [];
        for (const [id, was] of before) {
            const now = after.get(id) ?? Math.min(was, 0); // a creature that left the board died
            if (now !== was) born.push({ key: floaterKey.current++, id, text: now < was ? `-${was - now}` : `+${now - was}`, kind: now < was ? 'dmg' : 'heal' });
        }
        if (born.length > 0) {
            setFloaters(f => [...f, ...born]);
            setTimeout(() => setFloaters(f => f.filter(x => !born.includes(x))), 1200);
        }
        if (ok && attackerId) { setLunge(attackerId); setTimeout(() => setLunge(null), 380); }
        return ok;
    }, []);

    const refuse = (message: string) => { setNotice(message); rerender(); };
    const act = (ok: boolean, whyNot: string) => {
        setPending({ kind: 'none' });
        setNotice(ok ? '' : whyNot);
        rerender();
    };
    const apply = (action: PlayerAction, whyNot: string, attackerId?: string) =>
        act(run(() => TurnEngine.apply(state, action), attackerId), whyNot);

    const restart = (cls: PlayerClass = playerClass) => {
        stateRef.current = newDuel(cls, props);
        setPending({ kind: 'none' });
        setNotice('');
        setMulliganPicks(new Set());
        setSecondsLeft(TURN_SECONDS);
        rerender();
    };

    const confirmMulligan = () => {
        const s = stateRef.current;
        TurnEngine.mulligan(s, s.a, s.a.hand.filter((_, i) => mulliganPicks.has(i)));
        // The AI throws back anything costing 4 or more.
        TurnEngine.mulligan(s, s.b, s.b.hand.filter(c => c.cost >= 4));
        TurnEngine.startGame(s);
        setMulliganPicks(new Set());
        say('b', 'Greetings.');
        rerender();
    };

    const endTurn = useCallback(() => {
        const s = stateRef.current;
        if (s.active !== s.a || s.isOver || s.mulliganPending) return;
        setPending({ kind: 'none' });
        run(() => { TurnEngine.endTurn(s); return true; });
        rerender();
    }, [rerender, run]);

    // The AI takes one action per tick so its turn is watchable.
    useEffect(() => {
        const s = stateRef.current;
        if (s.isOver || s.mulliganPending) return;
        const aiMoves = s.pendingChoice ? s.pendingChoice.owner === s.b : s.active === s.b;
        if (!aiMoves) return;
        const timer = setTimeout(() => {
            const action = ai.chooseAction(s, s.b, s.a);
            const attackerId = action.kind === 'attack' ? String(action.attacker.uid) : action.kind === 'heroAttack' ? 'hero-b' : undefined;
            const ok = run(() => TurnEngine.apply(s, action), attackerId);
            if (!ok && !s.pendingChoice) run(() => { TurnEngine.endTurn(s); return true; }); // a refused action must never stall the turn
            if (s.isOver && s.winner === s.a) say('b', 'Well played.');
            rerender();
        }, AI_STEP_MS);
        return () => clearTimeout(timer);
    });

    // The rope lives in the front end, not the engine, which must stay deterministic.
    useEffect(() => {
        if (!yourTurn) return;
        setSecondsLeft(TURN_SECONDS);
        const started = Date.now();
        const timer = setInterval(() => {
            const left = TURN_SECONDS - Math.floor((Date.now() - started) / 1000);
            setSecondsLeft(Math.max(0, left));
            if (left <= 0) { clearInterval(timer); endTurn(); }
        }, 250);
        return () => clearInterval(timer);
    }, [yourTurn, state.turnNumber, endTurn]);

    useEffect(() => {
        logRef.current?.scrollTo({ top: logRef.current.scrollHeight });
    });

    // ── interactions ────────────────────────────────────────────────────────
    const cardRule = (card: CardDef, choice?: number): { rule: TargetRule; side: TargetSide } => {
        const option = choice !== undefined ? card.chooseOne?.[choice] : undefined;
        return option ? { rule: option.targeting, side: option.targetSide } : { rule: card.targeting, side: card.targetSide };
    };

    const beginCard = (card: CardDef, choice?: number) => {
        const { rule, side } = cardRule(card, choice);
        if (rule === 'none') return apply({ kind: 'playCard', card, target: null, choice }, `${card.name} cannot be played.`);
        if (rule === 'requiredCreature' && TurnEngine.legalCreatureTargets(state, side).length === 0)
            return refuse(`${card.name} needs ${side === 'friendly' ? 'one of your creatures' : 'an enemy creature'} to target.`);
        setPending({ kind: 'card', card, choice });
        setNotice(side === 'friendly' ? `Choose one of your creatures for ${card.name}.`
            : rule === 'optionalCreature' ? `Choose a target for ${card.name}: an enemy creature, or the enemy hero.`
            : `Choose an enemy creature for ${card.name}.`);
    };

    const clickHandCard = (card: CardDef) => {
        if (!yourTurn || yourPick) return;
        const why = TurnEngine.whyUnplayable(state, card);
        if (why) return refuse(why);
        if (card.chooseOne) { setPending({ kind: 'choose', card }); setNotice(`Choose One: ${card.name}.`); return; }
        beginCard(card);
    };

    const clickYourCreature = (c: BoardCreature) => {
        if (!yourTurn || yourPick) return;
        if (pending.kind === 'card' && cardRule(pending.card, pending.choice).side === 'friendly')
            return apply({ kind: 'playCard', card: pending.card, target: c, choice: pending.choice }, `${pending.card.name} cannot target that.`);
        if (pending.kind === 'heroPower' && power.targetSide === 'friendly')
            return apply({ kind: 'heroPower', target: c }, `${power.name} cannot target that.`);
        if (!c.canAttackNow) return refuse(c.summoningSick ? `${c.source.name} just arrived and cannot attack yet.` : `${c.source.name} cannot attack right now.`);
        setPending({ kind: 'attacker', attacker: c });
        setNotice(`Attack with ${c.source.name}: choose a highlighted target.`);
    };

    const clickYourHero = () => {
        if (!yourTurn || yourPick) return;
        if (pending.kind === 'heroAttacker' || !you.canHeroAttack) { setPending({ kind: 'none' }); setNotice(''); return; }
        setPending({ kind: 'heroAttacker' });
        setNotice(`Attack with your hero (${you.heroAttack} Attack): choose a highlighted target.`);
    };

    const clickEnemy = (target: BoardCreature | null) => {
        if (!yourTurn || yourPick) return;
        if (pending.kind === 'card') {
            const { rule, side } = cardRule(pending.card, pending.choice);
            if (side === 'friendly') return refuse(`${pending.card.name} targets your own creatures.`);
            if (!target && rule !== 'optionalCreature') return refuse(`${pending.card.name} must target a creature.`);
            return apply({ kind: 'playCard', card: pending.card, target, choice: pending.choice }, `${pending.card.name} cannot target that.`);
        }
        if (pending.kind === 'attacker')
            return apply({ kind: 'attack', attacker: pending.attacker, target }, 'That attack is not legal. Taunt or Stealth may be blocking it.', String(pending.attacker.uid));
        if (pending.kind === 'heroAttacker')
            return apply({ kind: 'heroAttack', target }, 'Your hero cannot attack that.', 'hero-a');
        if (pending.kind === 'heroPower') {
            if (power.targetSide === 'friendly') return refuse(`${power.name} targets your own creatures.`);
            if (!target && power.targeting !== 'optionalCreature') return refuse(`${power.name} must target a creature.`);
            return apply({ kind: 'heroPower', target }, `${power.name} cannot target that.`);
        }
    };

    const clickHeroPower = () => {
        if (!yourTurn || yourPick) return;
        if (you.heroPowerUsedThisTurn) return refuse(`${power.name} is once per turn.`);
        if (you.pips < power.cost) return refuse(`${power.name} costs ${power.cost} mana.`);
        if (power.targeting !== 'none') {
            const friendly = power.targetSide === 'friendly';
            if (power.targeting === 'requiredCreature' && TurnEngine.legalCreatureTargets(state, power.targetSide).length === 0)
                return refuse(`${power.name} needs ${friendly ? 'one of your creatures' : 'an enemy creature'} to target.`);
            setPending({ kind: 'heroPower' });
            setNotice(friendly ? `Choose one of your creatures for ${power.name}.`
                : power.targeting === 'optionalCreature' ? `Choose a target for ${power.name}: an enemy creature, or the enemy hero.`
                : `Choose an enemy creature for ${power.name}.`);
            return;
        }
        apply({ kind: 'heroPower', target: null }, `${power.name} cannot be used.`);
    };

    const sendEmote = (text: string) => {
        setEmoteMenu(false);
        say('a', text === 'Threaten' ? (THREATS[you.cls] ?? 'You will regret this!') : text);
        if (text === 'Greetings.' && !state.isOver) setTimeout(() => say('b', 'Greetings.'), 900);
    };

    // Creatures on the aimed-at board, plus the enemy hero when an enemy effect may go face.
    const spellTargets = (rule: TargetRule, side: TargetSide): (BoardCreature | null)[] => [
        ...TurnEngine.legalCreatureTargets(state, side),
        ...(rule === 'optionalCreature' && side === 'enemy' ? [null] : []),
    ];

    const legalTargets = new Set<BoardCreature | null>(
        pending.kind === 'attacker' ? TurnEngine.legalAttackTargets(state, pending.attacker)
            : pending.kind === 'heroAttacker' ? TurnEngine.legalHeroAttackTargets(state)
            : pending.kind === 'card' ? spellTargets(cardRule(pending.card, pending.choice).rule, cardRule(pending.card, pending.choice).side)
            : pending.kind === 'heroPower' ? spellTargets(power.targeting, power.targetSide)
            : [],
    );

    const winner = state.winner;
    const rope = yourTurn && secondsLeft <= ROPE_AT;
    const attacking = pending.kind === 'attacker' || pending.kind === 'heroAttacker';

    return (
        <div className="duel">
            <header className="bar">
                <strong>eyeland.cards</strong>
                <span className="muted">{state.mulliganPending ? 'mulligan' : `turn ${state.turnNumber}`}</span>
                <label>
                    Class{' '}
                    <select disabled={!!props.fixedClass} value={playerClass} onChange={e => { const cls = e.target.value as PlayerClass; setPlayerClass(cls); restart(cls); }}>
                        {FIGHT_CLASSES.map(c => <option key={c} value={c}>{c}</option>)}
                    </select>
                </label>
                {!props.onEnd && <button onClick={() => restart()}>New duel</button>}
                {props.onEnd && !state.isOver && <button onClick={() => { you.health = 0; rerender(); }}>Retreat</button>}
                {props.onEnd && state.isOver && <button className="end" onClick={() => props.onEnd!(winner === you, Math.max(0, you.health))}>Continue</button>}
            </header>

            <div className="table">
                <section className="side foe">
                    <CardBacks count={foe.hand.length} />
                    <div className="hero-row foe-row">
                        <WeaponToken caster={foe} />
                        <HeroPortrait caster={foe} id="hero-b" state={`${legalTargets.has(null) ? 'target' : ''} ${lunge === 'hero-b' ? 'lunge-down' : ''}`}
                                      onClick={() => clickEnemy(null)} floaters={floaters} showSecrets={false} emote={emotes.b}
                                      sub={`${foe.deck.length} in deck`} />
                        <ManaBar caster={foe} />
                    </div>
                    <Board creatures={foe.board} isTarget={c => legalTargets.has(c)} onClick={clickEnemy} floaters={floaters} lunge={lunge} lungeClass="lunge-down" />
                </section>

                <div className={`divider ${rope ? 'rope' : ''}`}>
                    {state.isOver
                        ? <span className="result">{winner === you ? 'Victory' : winner === foe ? 'Defeat' : 'Draw'}</span>
                        : state.mulliganPending ? <span>Choose cards to replace</span>
                        : yourTurn
                            ? <span>Your turn, {secondsLeft}s{rope ? ', the rope is burning' : ''}</span>
                            : <span className="muted">{foe.name} is thinking...</span>}
                    <span className="notice">{notice}</span>
                </div>

                <section className="side you">
                    <Board creatures={you.board} isTarget={c => !attacking && legalTargets.has(c)}
                           selected={pending.kind === 'attacker' ? pending.attacker : undefined}
                           ready={c => yourTurn && c.canAttackNow} onClick={clickYourCreature} floaters={floaters} lunge={lunge} lungeClass="lunge-up" />
                    <div className="hero-row">
                        <WeaponToken caster={you} />
                        <HeroPortrait caster={you} id="hero-a" onClick={clickYourHero} floaters={floaters} showSecrets emote={emotes.a}
                                      state={`${yourTurn && you.canHeroAttack ? 'ready' : ''} ${pending.kind === 'heroAttacker' ? 'selected' : ''} ${lunge === 'hero-a' ? 'lunge-up' : ''}`}
                                      sub={`${you.deck.length} in deck`} />
                        <div className="emote-box">
                            <button className="emote-toggle" onClick={() => setEmoteMenu(m => !m)} title="Emotes">💬</button>
                            {emoteMenu && (
                                <div className="emote-menu">
                                    {EMOTES.map(e => <button key={e} onClick={() => sendEmote(e)}>{e}</button>)}
                                </div>
                            )}
                        </div>
                        <ManaBar caster={you} />
                        <button className={`power ${pending.kind === 'heroPower' ? 'selected' : ''}`} disabled={!yourTurn || you.heroPowerUsedThisTurn || you.pips < power.cost}
                                onClick={clickHeroPower} title={`${power.name}: ${power.text}`}>
                            <span className="cost">{power.cost}</span> {power.name}
                            <small>{power.text}</small>
                        </button>
                        <button className="end" disabled={!yourTurn || yourPick} onClick={endTurn}>End turn</button>
                    </div>
                    <div className="hand">
                        {you.hand.map((card, i) => (
                            <CardFace key={`${card.id}-${i}`} card={card} onClick={() => clickHandCard(card)}
                                      state={`${yourTurn && !TurnEngine.whyUnplayable(state, card) ? 'playable' : ''} ${(pending.kind === 'card' || pending.kind === 'choose') && pending.card === card ? 'selected' : ''}`} />
                        ))}
                    </div>
                </section>

                {state.mulliganPending && (
                    <div className="overlay">
                        <h2>Starting hand</h2>
                        <p className="muted">You go first. Click cards to replace them. The AI goes second and gets The Coin.</p>
                        <div className="picker">
                            {you.hand.map((card, i) => (
                                <CardFace key={i} card={card} state={mulliganPicks.has(i) ? 'replace' : ''}
                                          onClick={() => setMulliganPicks(p => { const n = new Set(p); if (n.has(i)) n.delete(i); else n.add(i); return n; })} />
                            ))}
                        </div>
                        <button className="end" onClick={confirmMulligan}>Confirm{mulliganPicks.size > 0 ? ` (replace ${mulliganPicks.size})` : ''}</button>
                    </div>
                )}

                {yourPick && state.pendingChoice && (
                    <div className="overlay">
                        <h2>Discover a card</h2>
                        <div className="picker">
                            {state.pendingChoice.options.map((card, i) => (
                                <CardFace key={i} card={card} onClick={() => apply({ kind: 'discover', index: i }, 'That pick is not available.')} />
                            ))}
                        </div>
                    </div>
                )}

                {pending.kind === 'choose' && pending.card.chooseOne && (
                    <div className="overlay">
                        <h2>Choose One: {pending.card.name}</h2>
                        <div className="picker">
                            {pending.card.chooseOne.map((option, i) => (
                                <button key={i} className="choice" onClick={() => beginCard(pending.card, i)}>
                                    <strong>{option.name}</strong>
                                    <span>{option.text}</span>
                                </button>
                            ))}
                        </div>
                        <button onClick={() => { setPending({ kind: 'none' }); setNotice(''); }}>Cancel</button>
                    </div>
                )}
            </div>

            <aside className="log" ref={logRef}>
                {state.log.slice(-80).map((line, i) => <div key={i}>{hideFoeCards(line, foe.name)}</div>)}
            </aside>
        </div>
    );
}

/** Hearthstone never shows what the opponent draws or discovers. */
function hideFoeCards(line: string, foeName: string): string {
    if (line.startsWith(`${foeName} draws `) && !line.includes('empty deck')) return `${foeName} draws a card.`;
    if (line.startsWith(`${foeName} discovers `) && !line.includes(' from ')) return `${foeName} discovers a card.`;
    return line;
}

function Board({ creatures, isTarget, onClick, selected, ready, floaters, lunge, lungeClass }: {
    creatures: BoardCreature[];
    isTarget: (c: BoardCreature) => boolean;
    onClick: (c: BoardCreature) => void;
    selected?: BoardCreature;
    ready?: (c: BoardCreature) => boolean;
    floaters: Floater[];
    lunge: string | null;
    lungeClass: string;
}) {
    return (
        <div className="board">
            {creatures.length === 0 && <span className="muted empty">No creatures</span>}
            {creatures.map(c => (
                <MinionToken key={c.uid} c={c} onClick={() => onClick(c)} floaters={floaters}
                             state={`${isTarget(c) ? 'target' : ''} ${selected === c ? 'selected' : ''} ${ready?.(c) ? 'ready' : ''} ${lunge === String(c.uid) ? lungeClass : ''}`} />
            ))}
        </div>
    );
}
