#!/usr/bin/env node
// Fetches clean plaintext from terraria.wiki.gg's MediaWiki API (TextExtracts
// extension: action=query&prop=extracts&explaintext=1) and caches it locally,
// so wiki content is available in context without a live fetch every time.
//
// Usage:
//   node cache-wiki-page.mjs "Eye of Cthulhu" "Skeletron" "Wall of Flesh"
//   node cache-wiki-page.mjs --seed          (refetch the standard seed list)
//   node cache-wiki-page.mjs --seed --refresh (ignore cache, refetch all)

import { readFile, writeFile, mkdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";

const TERRARIA_DIR = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const CACHE_DIR = path.join(TERRARIA_DIR, "wiki-cache");
const API = "https://terraria.wiki.gg/api.php";

// The pages questbook.md's progression actually depends on. Not the whole
// wiki (thousands of pages) — just what's real reference material for this
// speedrun. Add more titles here (or pass them on the CLI) as new pages
// come up.
const SEED_PAGES = [
  "Guide:Game progression",
  "Bosses",
  "Hardmode",
  "Eye of Cthulhu",
  "Eater of Worlds",
  "Brain of Cthulhu",
  "Queen Bee",
  "Skeletron",
  "Wall of Flesh",
  "The Destroyer",
  "The Twins",
  "Skeletron Prime",
  "Plantera",
  "Golem",
  "Lunatic Cultist",
  "Lunar Events",
  "Moon Lord",
  "Suspicious Looking Eye",
  "Red Potion",
  "Drunk",
  "For the Worthy",
];

function slugify(title) {
  return title.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}

function fetchViaCurl(url) {
  const out = execFileSync("curl", ["-s", "--max-time", "20", url], { maxBuffer: 20 * 1024 * 1024 });
  return out.toString("utf8");
}

async function fetchExtract(title) {
  const url = `${API}?action=query&titles=${encodeURIComponent(title)}&prop=extracts&explaintext=1&format=json`;
  let body;
  try {
    const res = await fetch(url);
    body = await res.text();
  } catch {
    // same flaky-fetch fallback as the hearthstone script
    body = fetchViaCurl(url);
  }
  const data = JSON.parse(body);
  const pages = data?.query?.pages ?? {};
  const page = Object.values(pages)[0];
  if (!page || page.missing !== undefined) return null;
  return { title: page.title, extract: page.extract ?? "" };
}

async function cachePage(title, { refresh }) {
  const slug = slugify(title);
  const cachePath = path.join(CACHE_DIR, `${slug}.md`);
  if (!refresh && existsSync(cachePath)) {
    console.log(`cached: ${title}`);
    return;
  }
  const result = await fetchExtract(title);
  if (!result) {
    console.warn(`NOT FOUND: ${title}`);
    return;
  }
  const md = `# ${result.title}\n\nSource: https://terraria.wiki.gg/wiki/${encodeURIComponent(
    result.title.replace(/ /g, "_")
  )}\nFetched: ${new Date().toISOString()}\n\n---\n\n${result.extract}\n`;
  await writeFile(cachePath, md, "utf8");
  console.log(`fetched: ${title} -> ${slug}.md (${result.extract.length} chars)`);
}

async function main() {
  await mkdir(CACHE_DIR, { recursive: true });
  const args = process.argv.slice(2);
  const refresh = args.includes("--refresh");
  const useSeed = args.includes("--seed") || args.length === 0 || (args.length === 1 && refresh);
  const titles = useSeed ? SEED_PAGES : args.filter((a) => !a.startsWith("--"));

  for (const title of titles) {
    await cachePage(title, { refresh });
    await new Promise((r) => setTimeout(r, 400));
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
