// Hearthstone-style card, board minion, hero, weapon and mana bar. Shared by the duel and the deck editor.

import type { ReactNode } from 'react';
import type { BoardCreature, CardDef, Caster } from '../engine/engine';
import { artFor, CLASS_ICON } from './cardArt';

const KEYWORD_WORDS = /\b(Battlecry|Deathrattle|Taunt|Rush|Charge|Divine Shield|Lifesteal|Windfury|Poisonous|Stealth|Freeze|Secret|Discover|Choose One|Combo|Silence|Overload|Armor|Spell Damage \+\d)\b/g;

function RulesText({ text }: { text: string }) {
    const parts = text.split(KEYWORD_WORDS);
    return <>{parts.map((p, i) => (i % 2 === 1 ? <b key={i}>{p}</b> : p))}</>;
}

/** A damage or heal number that floats up over a token for about a second. */
export interface Floater { key: number; id: string; text: string; kind: 'dmg' | 'heal'; }

function Floaters({ id, floaters }: { id: string; floaters: Floater[] }) {
    return <>{floaters.filter(f => f.id === id).map(f => <span key={f.key} className={`floater ${f.kind}`}>{f.text}</span>)}</>;
}

export function CardArt({ card, className = '' }: { card: CardDef; className?: string }) {
    const art = artFor(card);
    return (
        <div className={`art el-${card.element} ${className}`}>
            {art.image ? <img src={art.image} alt="" draggable={false} /> : <span className="glyph">{art.emoji}</span>}
        </div>
    );
}

/** A full card as it looks in hand, in the collection, in a picker, or as a hover preview. */
export function CardFace({ card, state = '', onClick, children }: {
    card: CardDef;
    state?: string;
    onClick?: () => void;
    children?: ReactNode;
}) {
    const minion = card.type === 'creature', weapon = card.type === 'weapon';
    const kind = minion ? 'Creature' : weapon ? 'Weapon' : card.secret ? 'Secret' : 'Spell';
    const body = (
        <>
            <span className="gem mana">{card.cost}</span>
            <CardArt card={card} className={minion ? 'oval' : weapon ? 'round' : 'window'} />
            <span className={`rarity r-${card.rarity}`} />
            <span className="banner">{card.name}</span>
            <span className="rules"><span><RulesText text={card.text} /></span></span>
            <span className="tribe">{card.cls === 'neutral' ? kind : `${CLASS_ICON[card.cls]} ${card.cls} ${kind.toLowerCase()}`}</span>
            {(minion || weapon) && <span className="gem attack">{card.attack}</span>}
            {minion && <span className="gem health">{card.health}</span>}
            {weapon && <span className="gem durability">{card.durability ?? 1}</span>}
            {children}
        </>
    );
    const cls = `hs-card ${minion ? 'is-minion' : weapon ? 'is-weapon' : 'is-spell'} el-${card.element} ${state}`;
    return onClick
        ? <button className={cls} onClick={onClick}>{body}</button>
        : <div className={cls}>{body}</div>;
}

export function MinionToken({ c, state, onClick, floaters }: { c: BoardCreature; state: string; onClick: () => void; floaters: Floater[] }) {
    const flags = [
        c.taunt && 'taunt', c.divineShield && 'shield', c.frozen && 'frozen', c.stealth && 'stealth',
        c.poisonous && 'poison', c.windfury && 'windfury', c.lifesteal && 'lifesteal', c.silenced && 'silenced',
    ].filter(Boolean).join(' ');
    const attackUp = c.attack > c.source.attack, healthUp = c.maxHealth > c.source.health;
    return (
        <button className={`hs-minion ${flags} ${state}`} onClick={onClick} aria-label={`${c.source.name} ${c.attack}/${c.health}`}>
            <CardArt card={c.source} className="token" />
            {c.poisonous && <span className="badge">☠️</span>}
            {c.lifesteal && <span className="badge left">🩸</span>}
            {c.windfury && <span className="badge top">🌪️</span>}
            {c.silenced && <span className="badge top">🤐</span>}
            <span className={`gem attack ${attackUp ? 'up' : ''}`}>{c.attack}</span>
            <span className={`gem health ${c.damage > 0 ? 'hurt' : healthUp ? 'up' : ''}`}>{c.health}</span>
            <Floaters id={String(c.uid)} floaters={floaters} />
            <div className="preview"><CardFace card={c.source} /></div>
        </button>
    );
}

export function HeroPortrait({ caster, id, state, onClick, sub, floaters, showSecrets, emote }: {
    caster: Caster;
    id: string;
    state: string;
    onClick: () => void;
    sub: string;
    floaters: Floater[];
    /** Your own Secrets show their names; the opponent's show only a "?". */
    showSecrets: boolean;
    emote?: string;
}) {
    return (
        <div className={`hs-hero-wrap ${state}`}>
            <button className="hs-hero" onClick={onClick}>
                <span className="portrait">{CLASS_ICON[caster.cls]}</span>
                {caster.heroAttack > 0 && <span className="gem attack">{caster.heroAttack}</span>}
                {caster.armor > 0 && <span className="gem armor">{caster.armor}</span>}
                <span className="gem health">{caster.health}</span>
                <span className="secrets">
                    {caster.secrets.map((s, i) => (
                        <span key={i} className="secret" title={showSecrets ? `${s.name}: ${s.text}` : 'Secret'}>?</span>
                    ))}
                </span>
                <Floaters id={id} floaters={floaters} />
                <span className="hero-label">{caster.name}<small>{sub}</small></span>
            </button>
            {emote && <span className="emote-bubble">{emote}</span>}
        </div>
    );
}

export function WeaponToken({ caster }: { caster: Caster }) {
    if (!caster.weapon) return <div className="weapon-slot empty" />;
    const w = caster.weapon;
    return (
        <div className="weapon-slot" title={`${w.card.name}: ${w.card.text}`}>
            <CardArt card={w.card} className="token" />
            <span className="gem attack">{w.attack}</span>
            <span className="gem durability">{w.durability}</span>
        </div>
    );
}

export function ManaBar({ caster }: { caster: Caster }) {
    return (
        <div className="mana-bar" aria-label={`${caster.pips} of ${caster.maxPips} mana`}>
            <b>{caster.pips}/{caster.maxPips}</b>
            {Array.from({ length: 10 }, (_, i) => {
                const locked = i >= caster.maxPips - caster.overloadLocked && i < caster.maxPips;
                const cls = locked ? 'overload' : i < caster.pips ? 'full' : i < caster.maxPips ? 'spent' : 'locked';
                return <span key={i} className={`crystal ${cls}`} />;
            })}
            {caster.overloadNext > 0 && <em className="owed">Overload {caster.overloadNext}</em>}
        </div>
    );
}

export function CardBacks({ count }: { count: number }) {
    return (
        <div className="card-backs" aria-label={`${count} cards in hand`}>
            {Array.from({ length: count }, (_, i) => <span key={i} className="card-back" />)}
        </div>
    );
}
