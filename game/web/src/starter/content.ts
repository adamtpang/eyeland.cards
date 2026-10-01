import baseCards from '../../../data/cards.json';
import parityCards from '../data/parity-cards.json';
import starterCards from './starter-cards.json';
import { CardData, PlayerClass } from '../engine/engine';
import { loadCardData, mergeCardJson } from '../engine/loader';

export const ELEMENTS = [
    { id: 'fire', name: 'Fire', starter: 'home-emberling', verb: 'Pressure and momentum' },
    { id: 'water', name: 'Water', starter: 'home-tideling', verb: 'Flow and sustain' },
    { id: 'earth', name: 'Earth', starter: 'home-mossling', verb: 'Protection and endurance' },
    { id: 'air', name: 'Air', starter: 'home-cloudling', verb: 'Tempo and movement' },
] as const;
export type StarterElement = typeof ELEMENTS[number]['id'];
export const CLASSES = [
    { id: 'warrior', name: 'Warrior', engineClass: 'fighter', description: 'Shield and strike' },
    { id: 'ranger', name: 'Ranger', engineClass: 'ranger', description: 'Precision and companions' },
    { id: 'wizard', name: 'Wizard', engineClass: 'wizard', description: 'Spells and preparation' },
] as const satisfies readonly { id: string; name: string; engineClass: PlayerClass; description: string }[];
export type StarterClass = typeof CLASSES[number]['id'];
export const STARTER_DATA: CardData = loadCardData(mergeCardJson(mergeCardJson(baseCards, parityCards), starterCards));
export function starterDeck(element: StarterElement) {
    const starter = ELEMENTS.find(e => e.id === element)!;
    return [starter.starter, 'home-shore-guard', 'home-breeze-finch', 'home-spark', 'home-mending-tide'].map(id => STARTER_DATA.byId(id));
}
export const ENCOUNTER = {
    id: 'crop-crab', name: 'Resin Crab', health: 12,
    deck: ['home-resin-crab', 'home-resin-crab', 'home-breeze-finch', 'home-spark', 'home-shore-guard'],
    rewardCard: 'home-resin-crab', rewardResource: 2,
} as const;

// Authored placeholder terrain: # is sea. Positions use the same grid as movement.
export const TERRAIN = [
    '#############',
    '###.......###',
    '##.........##',
    '#...........#',
    '#...........#',
    '##.........##',
    '###.......###',
    '#############',
];
export const LANDMARKS = [
    { id: 'home', name: 'Family home', icon: '⌂', x: 3, y: 3 },
    { id: 'friend', name: 'Old friend', icon: '☺', x: 5, y: 2 },
    { id: 'crop', name: 'Resin garden', icon: '♣', x: 7, y: 3 },
    { id: 'encounter', name: 'Crab clearing', icon: '⚔', x: 9, y: 3 },
    { id: 'camp', name: 'Campfire', icon: '♨', x: 6, y: 5 },
    { id: 'dock', name: 'Lookout dock', icon: '⚑', x: 9, y: 5 },
] as const;
export type Point = { x: number; y: number };
export const SPAWN: Point = { x: 3, y: 4 };
export function move(position: Point, dx: number, dy: number): Point {
    const x = position.x + dx, y = position.y + dy;
    return Math.abs(dx) + Math.abs(dy) === 1 && TERRAIN[y]?.[x] === '.' ? { x, y } : position;
}
export function nearby(position: Point) {
    return LANDMARKS.filter(l => Math.abs(l.x - position.x) + Math.abs(l.y - position.y) <= 1);
}
export interface Journey {
    health: number;
    won: boolean;
    resources: number;
    collection: string[];
}
export function initialJourney(): Journey { return { health: 30, won: false, resources: 0, collection: [] }; }
export function finishEncounter(journey: Journey, won: boolean, health: number): Journey {
    const firstWin = won && !journey.won;
    return {
        health: won ? Math.max(1, Math.min(30, health)) : 1,
        won: journey.won || won,
        resources: journey.resources + (firstWin ? ENCOUNTER.rewardResource : 0),
        collection: firstWin ? [...journey.collection, ENCOUNTER.rewardCard] : journey.collection,
    };
}
