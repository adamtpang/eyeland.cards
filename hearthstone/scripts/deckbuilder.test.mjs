import assert from "node:assert/strict";
import test from "node:test";

import {
  buildCollectionIndex,
  craftDustFor,
  decodeDeckstring,
  ownedCountForCard,
} from "./deckbuilder.mjs";

const RAFAAMLOCK_CODE = "AAECAf0GDqn1BsODB4KYB4ilB4mlB4qlB5GlB5OlB5SlB5WlB5alB5elB5qlB63ZBw3noATTngbZggeEmQfenQfhnQeqrQeNvgfXvgfa1we32QeN3AeO3AcAAA==";

test("decodes the current 40-card Rafaamlock deck", () => {
  const deck = decodeDeckstring(RAFAAMLOCK_CODE);
  assert.equal(deck.version, 1);
  assert.equal(deck.format, 2);
  assert.deepEqual(deck.heroes, [893]);
  assert.equal(deck.cards.reduce((sum, card) => sum + card.count, 0), 40);
  assert.equal(deck.cards.filter((card) => card.count === 1).length, 14);
  assert.equal(deck.cards.filter((card) => card.count === 2).length, 13);
});

test("aggregates owned copies across card reprints", () => {
  const collection = buildCollectionIndex([
    { dbfId: 1, name: "Timethief Rafaam", totalCount: 1 },
    { dbfId: 2, name: "Timethief Rafaam", totalCount: 1 },
  ]);
  assert.equal(ownedCountForCard({ dbfId: 99, name: "Timethief Rafaam" }, collection), 2);
});

test("calculates normal crafting dust", () => {
  assert.equal(craftDustFor("COMMON", 2), 80);
  assert.equal(craftDustFor("EPIC", 2), 800);
  assert.equal(craftDustFor("LEGENDARY", 1), 1600);
});
