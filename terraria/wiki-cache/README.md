# Terraria wiki cache

Local, clean-text cache of terraria.wiki.gg pages, fetched via the real
MediaWiki TextExtracts API (no HTML scraping, no invented content). Built
so wiki facts (boss mechanics, item effects, world-seed behavior) are
available in context without a live fetch every time.

Not a full wiki mirror — the wiki has thousands of pages, most irrelevant
to this speedrun. This cache is scoped to what `../questbook.md`'s
progression route and past sessions actually reference: the boss list,
each boss's own page, the world-progression guide, hardmode, and a couple
of specific items that came up in play (Suspicious Looking Eye, Red Potion,
the Drunk/For the Worthy world seeds this server uses).

## Refreshing

```bash
node ../scripts/cache-wiki-page.mjs --seed              # re-fetch anything missing
node ../scripts/cache-wiki-page.mjs --seed --refresh     # force re-fetch everything (wiki content can go stale after game updates)
node ../scripts/cache-wiki-page.mjs "Some Other Page"     # cache one more page ad hoc
```

Each cached `.md` file has its source URL and fetch timestamp at the top —
check that before trusting it against a patch that shipped after the fetch
date.
