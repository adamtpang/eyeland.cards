#!/usr/bin/env node

import { existsSync } from "node:fs";
import { readFile, readdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const SCRIPT_PATH = fileURLToPath(import.meta.url);
const HEARTHSTONE_DIR = path.dirname(path.dirname(SCRIPT_PATH));
const DEFAULT_COLLECTION_PATH = path.join(HEARTHSTONE_DIR, "collection-full.json");
const DEFAULT_CARDS_PATH = path.join(HEARTHSTONE_DIR, "scripts", ".cache", "cards.json");
const LISTS_DIR = path.join(HEARTHSTONE_DIR, "lists");
const LOG_PATH = path.join(HEARTHSTONE_DIR, "log.md");

const FORMAT_NAMES = new Map([
  [1, "Wild"],
  [2, "Standard"],
  [3, "Classic"],
  [4, "Twist"],
]);

const CRAFT_DUST = {
  FREE: 0,
  COMMON: 40,
  RARE: 100,
  EPIC: 400,
  LEGENDARY: 1600,
};

class ByteReader {
  constructor(buffer) {
    this.buffer = buffer;
    this.offset = 0;
  }

  readVarint() {
    let result = 0;
    let shift = 0;
    while (this.offset < this.buffer.length) {
      const byte = this.buffer[this.offset++];
      result += (byte & 0x7f) * 2 ** shift;
      if ((byte & 0x80) === 0) return result;
      shift += 7;
      if (shift > 49) throw new Error("Deck code contains an invalid varint.");
    }
    throw new Error("Deck code ended unexpectedly.");
  }
}

function normalizeName(value) {
  return String(value ?? "").trim().toLowerCase();
}

export function decodeDeckstring(deckCode) {
  let bytes;
  try {
    bytes = Buffer.from(deckCode.trim(), "base64");
  } catch {
    throw new Error("Deck code is not valid base64.");
  }
  if (bytes.length < 5) throw new Error("Deck code is too short.");

  const reader = new ByteReader(bytes);
  const reserved = reader.readVarint();
  if (reserved !== 0) throw new Error("Deck code has an unsupported header.");

  const version = reader.readVarint();
  const format = reader.readVarint();
  const heroCount = reader.readVarint();
  const heroes = Array.from({ length: heroCount }, () => reader.readVarint());
  const cards = [];

  for (const count of [1, 2]) {
    const groupSize = reader.readVarint();
    for (let i = 0; i < groupSize; i++) {
      cards.push({ dbfId: reader.readVarint(), count });
    }
  }

  const variableGroupSize = reader.readVarint();
  for (let i = 0; i < variableGroupSize; i++) {
    cards.push({ dbfId: reader.readVarint(), count: reader.readVarint() });
  }

  return {
    version,
    format,
    heroes,
    cards,
    trailingBytes: bytes.length - reader.offset,
  };
}

export function buildCollectionIndex(collectionCards) {
  const byDbfId = new Map();
  const byName = new Map();
  for (const card of collectionCards) {
    byDbfId.set(card.dbfId, card.totalCount ?? 0);
    const key = normalizeName(card.name);
    byName.set(key, (byName.get(key) ?? 0) + (card.totalCount ?? 0));
  }
  return { byDbfId, byName };
}

export function ownedCountForCard(card, collectionIndex) {
  const byName = collectionIndex.byName.get(normalizeName(card?.name));
  if (byName !== undefined) return byName;
  return collectionIndex.byDbfId.get(card?.dbfId) ?? 0;
}

export function craftDustFor(rarity, count) {
  return (CRAFT_DUST[rarity] ?? 0) * count;
}

function cardClasses(card) {
  return new Set([card.cardClass, ...(card.classes ?? [])].filter(Boolean));
}

function isClassCompatible(card, deckClasses) {
  const classes = cardClasses(card);
  return classes.has("NEUTRAL") || [...classes].some((value) => deckClasses.has(value));
}

function replacementScore(target, candidate) {
  let score = 0;
  const costGap = Math.abs((target.cost ?? 0) - (candidate.cost ?? 0));
  if (costGap === 0) score += 6;
  else if (costGap === 1) score += 3;
  if (target.type && candidate.type === target.type) score += 5;
  if (target.rarity && candidate.rarity === target.rarity) score += 1;
  if (target.cardClass && candidate.cardClass === target.cardClass) score += 1;
  return score;
}

function findReplacementCandidates({ target, cards, collectionIndex, representedSets, deckClasses, deckNames }) {
  const candidatesByName = new Map();
  for (const card of cards) {
    const key = normalizeName(card.name);
    if (!card.collectible || deckNames.has(key) || !representedSets.has(card.set)) continue;
    if (!isClassCompatible(card, deckClasses)) continue;
    const owned = ownedCountForCard(card, collectionIndex);
    if (owned < 1) continue;

    const candidate = { ...card, owned, score: replacementScore(target, card) };
    const existing = candidatesByName.get(key);
    if (!existing || candidate.score > existing.score) candidatesByName.set(key, candidate);
  }

  return [...candidatesByName.values()]
    .sort((a, b) => b.score - a.score || Math.abs(a.cost - target.cost) - Math.abs(b.cost - target.cost) || a.name.localeCompare(b.name))
    .slice(0, 3)
    .map(({ name, cost, type, set, owned }) => ({ name, cost, type, set, owned }));
}

export function analyzeDeck({ decoded, cards, collection }) {
  const cardsByDbfId = new Map(cards.filter((card) => Number.isInteger(card.dbfId)).map((card) => [card.dbfId, card]));
  const collectionIndex = buildCollectionIndex(collection.cards ?? collection);
  const heroCards = decoded.heroes.map((id) => cardsByDbfId.get(id)).filter(Boolean);
  const deckClasses = new Set(heroCards.flatMap((card) => [...cardClasses(card)]).filter((value) => value !== "NEUTRAL"));
  const entries = decoded.cards.map((entry) => ({
    ...entry,
    card: cardsByDbfId.get(entry.dbfId) ?? null,
  }));
  const deckNames = new Set(entries.map((entry) => normalizeName(entry.card?.name)).filter(Boolean));
  const representedSets = new Set(entries.map((entry) => entry.card?.set).filter(Boolean));
  representedSets.add("CORE");

  const curve = {};
  const types = {};
  const missing = [];
  const special = [];
  const unknown = [];
  let collectibleSlots = 0;
  let missingCopies = 0;
  let craftDust = 0;

  for (const entry of entries) {
    const card = entry.card;
    if (!card) {
      unknown.push({ dbfId: entry.dbfId, count: entry.count });
      continue;
    }

    const curveKey = card.cost >= 10 ? "10+" : String(card.cost ?? "?");
    curve[curveKey] = (curve[curveKey] ?? 0) + entry.count;
    types[card.type ?? "UNKNOWN"] = (types[card.type ?? "UNKNOWN"] ?? 0) + entry.count;

    if (!card.collectible) {
      special.push({ dbfId: card.dbfId, name: card.name, count: entry.count, set: card.set });
      continue;
    }

    collectibleSlots += entry.count;
    const owned = ownedCountForCard(card, collectionIndex);
    const shortfall = Math.max(0, entry.count - owned);
    if (shortfall > 0) {
      const dust = craftDustFor(card.rarity, shortfall);
      missingCopies += shortfall;
      craftDust += dust;
      missing.push({
        dbfId: card.dbfId,
        name: card.name,
        required: entry.count,
        owned,
        missing: shortfall,
        cost: card.cost,
        type: card.type,
        rarity: card.rarity,
        set: card.set,
        dust,
      });
    }
  }

  for (const item of missing) {
    item.replacements = findReplacementCandidates({
      target: cardsByDbfId.get(item.dbfId),
      cards,
      collectionIndex,
      representedSets,
      deckClasses,
      deckNames,
    });
  }

  const totalDeckCards = decoded.cards.reduce((sum, entry) => sum + entry.count, 0);
  return {
    format: FORMAT_NAMES.get(decoded.format) ?? `Unknown (${decoded.format})`,
    version: decoded.version,
    heroes: heroCards.map((card) => ({ dbfId: card.dbfId, name: card.name, cardClass: card.cardClass })),
    classes: [...deckClasses].sort(),
    totalDeckCards,
    collectibleSlots,
    ownedCollectibleCopies: collectibleSlots - missingCopies,
    missingCopies,
    craftDust,
    curve,
    types,
    representedSets: [...representedSets].sort(),
    missing,
    special,
    unknown,
    trailingBytes: decoded.trailingBytes,
  };
}

function extractDeckCode(markdown) {
  const matches = markdown.match(/[A-Za-z0-9+/]{40,}={0,2}/g) ?? [];
  if (matches.length === 0) throw new Error("No Hearthstone deck code found in the deck file.");
  return matches.at(-1);
}

async function latestDeckPath() {
  const files = (await readdir(LISTS_DIR))
    .filter((name) => name.endsWith(".md"))
    .sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
  if (files.length === 0) throw new Error(`No deck lists found in ${LISTS_DIR}.`);
  return path.join(LISTS_DIR, files.at(-1));
}

function parseArgs(argv) {
  const options = { json: false, prompt: false, help: false };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--json") options.json = true;
    else if (arg === "--prompt") options.prompt = true;
    else if (arg === "--help" || arg === "-h") options.help = true;
    else if (["--deck-code", "--deck", "--collection", "--cards"].includes(arg)) {
      if (!argv[i + 1]) throw new Error(`${arg} needs a value.`);
      options[arg.slice(2).replace("-", "_")] = argv[++i];
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }
  return options;
}

function formatCurve(curve) {
  const order = Object.keys(curve).sort((a, b) => (a === "10+" ? 99 : Number(a)) - (b === "10+" ? 99 : Number(b)));
  return order.map((cost) => `${cost}:${curve[cost]}`).join("  ");
}

function formatReport(report, source, collection) {
  const lines = [
    "Hearthstone collection deck report",
    `Deck: ${source}`,
    `Format/class: ${report.format} / ${report.classes.join(", ") || "unknown"}`,
    `Deck size: ${report.totalDeckCards} (${report.collectibleSlots} collectible, ${report.special.reduce((sum, card) => sum + card.count, 0)} special)`,
    `Collection fit: ${report.ownedCollectibleCopies}/${report.collectibleSlots} collectible copies owned`,
    `Missing: ${report.missingCopies} copies / ${report.craftDust.toLocaleString("en-US")} dust`,
    `Curve: ${formatCurve(report.curve)}`,
    `Collection source updated: ${collection.sourceLastModified ?? "unknown (do not treat processing time as freshness)"}`,
    `Collection processed: ${collection.generatedAt ?? "unknown"}`,
  ];

  if (report.missing.length > 0) {
    lines.push("", "Missing cards:");
    for (const item of report.missing) {
      lines.push(`- ${item.name}: own ${item.owned}/${item.required}, need ${item.missing}, ${item.dust.toLocaleString("en-US")} dust`);
      if (item.replacements.length > 0) {
        lines.push(`  Owned shortlist: ${item.replacements.map((card) => `${card.name} (${card.cost}, ${card.type})`).join("; ")}`);
      }
    }
  } else {
    lines.push("", "You own every collectible card in this deck.");
  }

  if (report.special.length > 0) {
    lines.push("", `Special deck entries (no collection check): ${report.special.map((card) => `${card.count}x ${card.name}`).join(", ")}`);
  }
  if (report.unknown.length > 0) {
    lines.push("", `Warning: ${report.unknown.length} deck entries were not found in the local card cache.`);
  }
  lines.push("", "Replacement shortlists are owned-card heuristics from the deck's represented sets plus Core, not live meta recommendations.");
  return lines.join("\n");
}

function formatPrompt({ reportText, source, deckNotes, ladderLog }) {
  return [
    "# Hearthstone deckbuilding packet",
    "",
    "Use the grounded collection report below to improve this deck. Preserve the deck's core gameplan, make every change as card out / card in / why / curve delta, and finish with a valid deck code. Do not invent card text. Verify current Standard rotation, balance changes, and meta data before making competitive claims.",
    "",
    "## Collection report",
    "",
    reportText,
    "",
    `## Current list notes (${source})`,
    "",
    deckNotes.trim(),
    "",
    "## Ladder log",
    "",
    ladderLog.trim() || "No ladder games logged yet.",
  ].join("\n");
}

function printHelp() {
  console.log(`Usage: node hearthstone/scripts/deckbuilder.mjs [options]

Options:
  --deck-code CODE   Analyze a pasted Hearthstone deck code
  --deck FILE        Analyze a deck code found in a Markdown file
  --collection FILE  Override collection-full.json
  --cards FILE       Override the cached HearthstoneJSON cards file
  --json             Emit machine-readable JSON
  --prompt           Emit a grounded AI deckbuilding prompt packet
  -h, --help         Show this help

With no options, the newest Markdown file in hearthstone/lists is analyzed.`);
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    printHelp();
    return;
  }

  const collectionPath = path.resolve(options.collection ?? DEFAULT_COLLECTION_PATH);
  const cardsPath = path.resolve(options.cards ?? DEFAULT_CARDS_PATH);
  for (const requiredPath of [collectionPath, cardsPath]) {
    if (!existsSync(requiredPath)) {
      throw new Error(`Missing ${requiredPath}. Run node hearthstone/scripts/refresh-collection.mjs first.`);
    }
  }

  let deckCode = options.deck_code;
  let deckPath = options.deck ? path.resolve(options.deck) : null;
  let deckNotes = "Deck code supplied directly; no list notes available.";
  if (!deckCode) {
    deckPath ??= await latestDeckPath();
    deckNotes = await readFile(deckPath, "utf8");
    deckCode = extractDeckCode(deckNotes);
  }

  const [cards, collection] = await Promise.all([
    readFile(cardsPath, "utf8").then(JSON.parse),
    readFile(collectionPath, "utf8").then(JSON.parse),
  ]);
  const decoded = decodeDeckstring(deckCode);
  const report = analyzeDeck({ decoded, cards, collection });
  const source = deckPath ? path.relative(HEARTHSTONE_DIR, deckPath) : "pasted deck code";

  if (options.json) {
    console.log(JSON.stringify({ source, deckCode, collectionGeneratedAt: collection.generatedAt, ...report }, null, 2));
    return;
  }

  const reportText = formatReport(report, source, collection);
  if (options.prompt) {
    const ladderLog = existsSync(LOG_PATH) ? await readFile(LOG_PATH, "utf8") : "";
    console.log(formatPrompt({ reportText, source, deckNotes, ladderLog }));
  } else {
    console.log(reportText);
  }
}

if (path.resolve(process.argv[1] ?? "") === SCRIPT_PATH) {
  main().catch((error) => {
    console.error(`deckbuilder: ${error.message}`);
    process.exit(1);
  });
}
