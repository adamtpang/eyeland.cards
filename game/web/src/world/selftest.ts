import assert from "node:assert/strict";
import cards from "../../../data/cards.json";
import parity from "../data/parity-cards.json";
import { CardSet } from "../engine/engine";
import { loadCardData, mergeCardJson } from "../engine/loader";
import { validateConstructed } from "../engine/constructed";
import { decodeJourney, journeyDeck, settle, equip } from "./progress";
CardSet.load(loadCardData(mergeCardJson(cards, parity)));
const fresh = { won: false, equipped: false };
assert.deepEqual(settle(fresh, false), fresh);
assert.equal(equip(fresh).equipped, false);
const win = settle(fresh, true);
assert.deepEqual(settle(win, true), win);
assert.deepEqual(settle(win, false), win);
const equipped = equip(win);
assert.deepEqual(decodeJourney(JSON.stringify(equipped)), equipped);
for (const bad of ["null", "{}", '{"won":false,"equipped":true}', "broken"])
    assert.throws(() => decodeJourney(bad));
for (const j of [fresh, win, equipped]) {
    const d = journeyDeck(j);
    assert.equal(validateConstructed(d, "wizard"), null);
    assert.equal(
        d.filter((c) => c.id === "cinder-wolf").length,
        j.equipped ? 1 : 0,
    );
}
console.log(
    "World checks passed: legal 30-card decks, earned-only equip, single reward, loss preservation, save roundtrip and corrupt-save rejection.",
);
