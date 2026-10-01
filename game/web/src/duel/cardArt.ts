// Card art. Cards with a painted portrait (public/art/<id>.jpg) use it; the rest get
// a generated illustration: an element-colored painted backdrop with an emoji subject.
// Replacing a placeholder is just adding public/art/<id>.jpg and listing the id below.

import type { CardDef, PlayerClass } from '../engine/engine';

const PAINTED = new Set([
    'cinder-wolf', 'ember-reach-warden', 'galehart', 'glowing-ember',
    'squall-caller', 'stormcaller-elemental', 'tide-guard', 'tidewisp',
]);

const SUBJECT: Record<string, string> = {
    'home-emberling': '🐉', 'home-tideling': '🐟', 'home-mossling': '🐢', 'home-cloudling': '🕊️',
    'home-shore-guard': '🛡️', 'home-breeze-finch': '🐦', 'home-spark': '🔥',
    'home-mending-tide': '🌊', 'home-resin-crab': '🦀',
    'ember-bolt': '☄️', 'riptide': '🌊', 'rolling-thunder': '⛈️', 'storm-totem': '🗿',
    'eye-of-the-storm': '🌀', 'drift-hand': '🦀', 'reef-warden': '🐢', 'salvage': '🩹',
    'bar-scarred-brute': '👹', 'bar-reckless-swing': '🪓', 'bar-warcry': '📯', 'bar-the-unbroken': '🦍',
    'brd-street-singer': '🎤', 'brd-refrain': '🎶', 'brd-chorus-of-two': '🎻', 'brd-the-last-verse': '📜',
    'clr-acolyte': '🕯️', 'clr-mend': '💞', 'clr-sanctuary': '⛪', 'clr-the-long-vigil': '🕊️',
    'drd-sapling': '🌱', 'drd-seedbearer': '🌰', 'drd-overgrow': '🌿', 'drd-thicket': '🌳', 'drd-heart-of-the-grove': '💚',
    'ftr-recruit': '🪖', 'ftr-vanguard': '🐎', 'ftr-shield-line': '🛡️', 'ftr-second-wind': '💨', 'ftr-the-standard-bearer': '🚩',
    'mnk-initiate': '🥋', 'mnk-flurry': '👊', 'mnk-open-palm': '🖐️', 'mnk-the-hundred-steps': '🐉',
    'pal-squire': '🤺', 'pal-lay-on-hands': '🙏', 'pal-smite': '🔨', 'pal-the-last-oath': '👑',
    'rng-wolf': '🐺', 'rng-viper': '🐍', 'rng-mark': '🎯', 'rng-call-companion': '🦮', 'rng-the-long-shot': '🏹',
    'rog-cutpurse': '🥷', 'rog-backstab': '🗡️', 'rog-opening-move': '♟️', 'rog-the-quiet-blade': '🔪',
    'sor-spark': '✨', 'sor-wild-surge': '💥', 'sor-unstable-familiar': '🦎', 'sor-the-tide-of-chance': '🎲',
    'wlk-pact-imp': '😈', 'wlk-dark-bargain': '📕', 'wlk-siphon': '🩸', 'wlk-the-debt-collector': '💀',
    'wiz-apprentice': '🧙', 'wiz-arcane-jolt': '⚡', 'wiz-frost-ward': '❄️', 'wiz-study': '📚', 'wiz-the-open-book': '📖',
    'the-coin': '🪙', 'ftr-iron-blade': '⚔️', 'bar-rusted-cleaver': '🪓', 'rog-twin-daggers': '🗡️', 'rng-hunting-bow': '🏹',
    'wiz-mirror-ward': '🪞', 'rng-bramble-snare': '🪤', 'rog-ambush': '🎭', 'pal-guarding-light': '🌟',
    'wiz-rummage': '🔍', 'curio-seeker': '🧭', 'drd-groves-gift': '🎁', 'drd-fern-keeper': '🌿',
    'rog-shadow-strike': '🌑', 'rog-dusk-adept': '🦇', 'clr-hush': '🤫', 'mute-sentinel': '🗿',
    'sor-storm-surge': '🌩️', 'sor-thunder-idol': '🗽', 'ftr-shield-up': '🛡️', 'bar-savage-blow': '💢',
    'tnk-scrap-servitor': '🤖', 'tnk-bolt-on': '🔩', 'tnk-assembly-line': '🏭', 'tnk-the-workshop': '⚙️',
};

export const CLASS_ICON: Record<PlayerClass, string> = {
    neutral: '🧑', barbarian: '🪓', bard: '🪕', cleric: '✝️', druid: '🍃', fighter: '⚔️', monk: '☯️',
    paladin: '🛡️', ranger: '🏹', rogue: '🗡️', sorcerer: '🔮', warlock: '🜏', wizard: '🧙', tinkerer: '🔧',
};

export interface Art { image?: string; emoji: string; }

export function artFor(card: CardDef): Art {
    if (PAINTED.has(card.id)) return { image: `art/${card.id}.jpg`, emoji: '' };
    return { emoji: SUBJECT[card.id] ?? (card.type === 'spell' ? '✨' : CLASS_ICON[card.cls]) };
}
