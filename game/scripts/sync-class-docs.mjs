#!/usr/bin/env node
// Regenerates game/data/classes/*.md from game/data/cards.json.
//
// The card data is the single source of truth. These docs are a view of it, so
// they cannot drift: change a card's cost in the JSON and re-run this.
//
// Usage: node game/scripts/sync-class-docs.mjs [--check]
//        --check exits non-zero if any doc is stale, for CI.

import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const REPO = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const DATA = join(REPO, "game", "data", "cards.json");
const OUT = join(REPO, "game", "data", "classes");

const KEYWORDS = {
  taunt: "Taunt", rush: "Rush", charge: "Charge", divineShield: "Divine Shield",
  lifesteal: "Lifesteal", windfury: "Windfury", poisonous: "Poisonous", stealth: "Stealth",
};

const HEAD =
  "| Card | Cost | Type | Stats | Rarity | Keywords | Text |\n|---|---|---|---|---|---|---|";

const title = (s) => s.charAt(0).toUpperCase() + s.slice(1);

function row(c) {
  const kw = [];
  if (c.taunt) kw.push("Taunt");
  for (const k of c.keywords ?? []) if (KEYWORDS[k]) kw.push(KEYWORDS[k]);
  if (c.spellDamage) kw.push(`Spell Damage +${c.spellDamage}`);
  if (c.aura) kw.push("Aura");
  if (c.deathrattle) kw.push("Deathrattle");

  const stats = c.type === "creature" ? `${c.attack ?? 0}/${c.health ?? 0}` : "—";
  return `| **${c.name}** | ${c.cost ?? 0} | ${title(c.type)} | ${stats} | ` +
         `${title(c.rarity ?? "common")} | ${kw.join(", ") || "—"} | ${c.text} |`;
}

const data = JSON.parse(readFileSync(DATA, "utf8"));
const checkOnly = process.argv.includes("--check");
let stale = 0;

function put(name, contents) {
  const path = join(OUT, name);
  const current = existsSync(path) ? readFileSync(path, "utf8") : null;
  if (current === contents) return;
  stale++;
  if (checkOnly) { console.log(`STALE  classes/${name}`); return; }
  mkdirSync(OUT, { recursive: true });
  writeFileSync(path, contents, "utf8");
  console.log(`wrote  classes/${name}`);
}

for (const set of data.sets) {
  const rows = set.cards.map(row).join("\n");

  if (set.id === "neutral") {
    put("neutral.md", `# The Common Collection

**Playable in every deck, by every class.**

These are the shared floor. Their job is to be the baseline every class card is
measured against, and to make a deck legal even when a class set is thin.

${HEAD}
${rows}

## Why neutrals matter

A class card that is not better than a neutral at the same cost, *for that
class's plan*, has not earned its slot. That is the whole test.

Neutrals also carry the keyword vocabulary the classes build on: Rush on
Drift Hand and Cinder Wolf, Taunt on Tide Guard and Reef Warden. A player meets
each keyword on a plain card before meeting it on a clever one.

## Deck rule

A legal deck is **one class plus neutrals**. Neutrals never conflict with a
class choice, which is what lets a thin class set still make a playable deck.
`);
    continue;
  }

  const note = set.note ? `\n> ${set.note}\n` : "";
  put(`${set.class}.md`, `# ${set.name}

**Verb: ${set.verb}.**
${note}
One verb per class, per [\`DESIGN.md\`](../../DESIGN.md) principle 4. A class you
cannot describe in one sentence will not read at the table.

## The ${set.name} set

These cards are **playable only in a ${set.name} deck**.

${HEAD}
${rows}

## What a ${set.name} deck also gets

Every deck may also play the cards in
[**the common collection**](neutral.md). Those are the shared floor this class
is measured against: if a ${set.name} card is not better than a neutral card at
the same cost *for a ${set.name} plan*, it has not earned its slot.

## Deck rule

A legal deck is **one class plus neutrals**. You may not mix two classes. That
is what makes the verb above mean anything: choosing ${set.name} is choosing to
be good at "${set.verb}" and to give up every other class's answer to it.

## Status

Designed, **not yet playtested**. The numbers here are first drafts and should
be expected to move once a real deck meets the AI simulator or a human.
`);
}

if (checkOnly && stale > 0) {
  console.error(`\n${stale} doc(s) out of date. Run: node game/scripts/sync-class-docs.mjs`);
  process.exit(1);
}
console.log(stale === 0 ? "Class docs already up to date." : `\nWrote ${stale} doc(s).`);
