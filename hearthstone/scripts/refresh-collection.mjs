#!/usr/bin/env node
// Regenerates collection.md's checkboxes from a real HSReplay collection
// export, instead of hand-editing them.
//
// Usage:
//   1. Log into hsreplay.net in a browser where HDT has already uploaded
//      your collection (Options -> Replays -> Claim Account in HDT, then
//      open My Collection in-game once).
//   2. Fetch https://hsreplay.net/api/v1/collection/?region=<R>&account_lo=<ID>&type=CONSTRUCTED
//      (R/ID are printed in that URL once you load hsreplay.net signed in)
//      and save the raw JSON response to hearthstone/collection-raw.json.
//   3. node hearthstone/scripts/refresh-collection.mjs
//
// Outputs:
//   hearthstone/collection-full.json  — every owned card, general purpose,
//                                        reusable across any future archetype
//   hearthstone/collection.md         — checkboxes rewritten in place,
//                                        every other line left untouched

import { readFile, writeFile, mkdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";

const HEARTHSTONE_DIR = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const RAW_PATH = path.join(HEARTHSTONE_DIR, "collection-raw.json");
const FULL_PATH = path.join(HEARTHSTONE_DIR, "collection-full.json");
const MD_PATH = path.join(HEARTHSTONE_DIR, "collection.md");
const CACHE_DIR = path.join(HEARTHSTONE_DIR, "scripts", ".cache");
const CARDS_CACHE_PATH = path.join(CACHE_DIR, "cards.json");
const CARDS_URL = "https://api.hearthstonejson.com/v1/latest/enUS/cards.json";

async function loadCardDefs({ forceRefresh }) {
  if (!forceRefresh && existsSync(CARDS_CACHE_PATH)) {
    const cached = JSON.parse(await readFile(CARDS_CACHE_PATH, "utf8"));
    return cached;
  }
  await mkdir(CACHE_DIR, { recursive: true });
  try {
    const res = await fetch(CARDS_URL);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const cards = await res.json();
    await writeFile(CARDS_CACHE_PATH, JSON.stringify(cards), "utf8");
    return cards;
  } catch (err) {
    // Node's fetch (undici) has a flaky IPv6 timeout to this host on some
    // machines even though curl reaches it fine. Fall back to curl.
    console.warn(`node fetch failed (${err.message}), falling back to curl...`);
    execFileSync("curl", ["-s", "--max-time", "30", "-o", CARDS_CACHE_PATH, CARDS_URL]);
    const cards = JSON.parse(await readFile(CARDS_CACHE_PATH, "utf8"));
    return cards;
  }
}

function buildDbfIndex(cardDefs) {
  const byDbfId = new Map();
  for (const card of cardDefs) {
    if (typeof card.dbfId === "number") byDbfId.set(card.dbfId, card);
  }
  return byDbfId;
}

function buildNameIndex(cardDefs) {
  // Collectible cards only; first match wins (cards.json can have dupes
  // across sets when a card is reprinted, e.g. into Core).
  const byName = new Map();
  for (const card of cardDefs) {
    if (!card.collectible) continue;
    const key = card.name.trim().toLowerCase();
    if (!byName.has(key)) byName.set(key, card);
  }
  return byName;
}

async function main() {
  const forceRefresh = process.argv.includes("--refresh-cards");

  if (!existsSync(RAW_PATH)) {
    console.error(`Missing ${RAW_PATH}`);
    console.error(
      "Fetch the JSON from hsreplay.net/api/v1/collection/?region=...&account_lo=...&type=CONSTRUCTED " +
        "(while signed in, with HDT having uploaded your collection at least once) and save it there first."
    );
    process.exit(1);
  }

  const raw = JSON.parse(await readFile(RAW_PATH, "utf8"));
  const collection = raw.collection ?? raw; // tolerate either shape
  const cardDefs = await loadCardDefs({ forceRefresh });
  const byDbfId = buildDbfIndex(cardDefs);
  const byName = buildNameIndex(cardDefs);

  // --- collection-full.json: every owned card, general purpose ---
  const owned = [];
  for (const [dbfIdStr, counts] of Object.entries(collection)) {
    const dbfId = Number(dbfIdStr);
    const card = byDbfId.get(dbfId);
    if (!card) continue; // unknown dbfId (e.g. non-collectible internal entry)
    const normalCount = counts[0] ?? 0;
    const goldCount = counts[1] ?? 0;
    if (normalCount === 0 && goldCount === 0) continue;
    owned.push({
      dbfId,
      name: card.name,
      set: card.set,
      rarity: card.rarity ?? null,
      cost: card.cost ?? null,
      cardClass: card.cardClass ?? null,
      normalCount,
      goldCount,
      totalCount: normalCount + goldCount,
    });
  }
  owned.sort((a, b) => a.name.localeCompare(b.name));

  await writeFile(
    FULL_PATH,
    JSON.stringify(
      {
        generatedAt: new Date().toISOString(),
        sourceLastModified: raw._sourceLastModified ?? null,
        cardCount: owned.length,
        cards: owned,
      },
      null,
      2
    ) + "\n",
    "utf8"
  );
  console.log(`Wrote ${FULL_PATH} (${owned.length} distinct owned cards)`);

  // --- collection.md: rewrite checkboxes in place ---
  if (!existsSync(MD_PATH)) {
    console.log(`No ${MD_PATH} to update, skipping.`);
    return;
  }
  const md = await readFile(MD_PATH, "utf8");
  const lineRe = /^(- )(✅|\[ \])( \d+× )(?:\(own \d+\/\d+\) )?(\*\*.+?\*\*: )(.+)$/;

  let changed = 0;
  const lines = md.split("\n").map((line) => {
    const m = line.match(lineRe);
    if (!m) return line;
    const [, dash, , countPart, namePart, rest] = m;
    const needed = Number(countPart.trim().replace("×", ""));
    const cardName = namePart.slice(2, namePart.indexOf("**", 2)).trim();

    // Core-set cards are auto-granted; the file's own header says they need
    // no checkbox tracking. Leave them checked, don't touch.
    if (/·\s*Core\s*·/.test(rest)) {
      if (dash + "✅" + countPart + namePart + rest !== line) changed++;
      return `${dash}✅${countPart}${namePart}${rest}`;
    }

    const match = byName.get(cardName.toLowerCase());
    const haveCount = match ? owned.find((c) => c.dbfId === match.dbfId)?.totalCount ?? 0 : 0;

    let marker;
    let ownedNote = "";
    if (haveCount >= needed) {
      marker = "✅";
    } else if (haveCount > 0) {
      marker = "[ ]";
      ownedNote = `(own ${haveCount}/${needed}) `;
    } else {
      marker = "[ ]";
    }

    const newLine = `${dash}${marker}${countPart}${ownedNote}${namePart}${rest}`;
    if (newLine !== line) changed++;
    return newLine;
  });

  await writeFile(MD_PATH, lines.join("\n"), "utf8");
  console.log(`Updated ${MD_PATH} (${changed} line${changed === 1 ? "" : "s"} changed)`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
