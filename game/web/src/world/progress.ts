import { CardSet } from "../engine/engine";
import { buildClassDeck, validateConstructed } from "../engine/constructed";
import { Rng } from "../engine/rng";
export type Journey = { won: boolean; equipped: boolean };
export function decodeJourney(raw: string): Journey {
    const d = JSON.parse(raw);
    if (
        !d ||
        typeof d.won !== "boolean" ||
        typeof d.equipped !== "boolean" ||
        (d.equipped && !d.won)
    )
        throw Error("Invalid island save");
    return { won: d.won, equipped: d.equipped };
}
export function settle(j: Journey, won: boolean): Journey {
    return { ...j, won: j.won || won };
}
export function equip(j: Journey): Journey {
    return { ...j, equipped: j.won };
}
export function journeyDeck(j: Journey) {
    const deck = buildClassDeck("wizard", new Rng(431)).filter(
        (c) => c.id !== "cinder-wolf",
    );
    for (const c of CardSet.all) {
        if (
            c.id === "cinder-wolf" ||
            !c.collectible ||
            (c.cls !== "neutral" && c.cls !== "wizard")
        )
            continue;
        while (
            deck.length < 30 &&
            deck.filter((x) => x.id === c.id).length <
                (c.rarity === "legendary" ? 1 : 2)
        )
            deck.push(c);
    }
    if (j.won && j.equipped) deck[29] = CardSet.byId("cinder-wolf");
    const error = validateConstructed(deck, "wizard");
    if (error) throw Error(error);
    return deck;
}
