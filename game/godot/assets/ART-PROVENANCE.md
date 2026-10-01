# Original Eyeland artwork

Generated September 20, 2026 using the built-in image-generation tool. Copied into this project without editing the generated bitmap. The original procedural portraits remain in `portrait.gd` as reference. Generated artwork is a prototype asset, not a claim of human authorship.

## creatures.png

Nine-panel portrait atlas; `skin.gd` selects equal thirds using AtlasTexture regions. Ordering: Emberling, Tideling, Mossling; Cloudling, Shore Guard, Breeze Finch; Pocket Spark, Mending Tide, Resin Crab.

Exact prompt:

> Create a single production game asset: a square 1536x1536 portrait atlas, exactly 3 columns by 3 rows of equal 512-square panels, edge-to-edge no gutters, no frames, no text, no lettering, no UI. Each panel is an independent centered collectible fantasy card illustration with subject fully contained in its panel and generous room around it, cohesive premium hand-painted storybook fantasy art, charming expressive creatures, rich brushwork, dramatic soft lighting, teal shadows and warm golden highlights, high detail not flat vector. TOP ROW left: Emberling, a tiny fox dragon with warm amber fur and flame ears in a glowing forest. Top middle: Tideling, a friendly small turquoise aquatic dragon with fins in a moonlit tide pool. Top right: Mossling, a round mossy forest guardian with leafy antlers and amber eyes among ferns. MIDDLE ROW left: Cloudling, a small ivory feathered flying dragon on pastel clouds. Middle middle: Shore Guard, a sturdy little tortoise creature with a weathered stone shield shell beside the coast. Middle right: Breeze Finch, a brave small blue-and-cream bird spreading its wings in sea wind. BOTTOM ROW left: Pocket Spark, a magical bright golden flame swirling from a hand, spell art. Bottom middle: Mending Tide, an aqua healing spiral with soft luminous droplets and lotus blossom, spell art. Bottom right: Resin Crab, an adorable amber crab with a glowing golden resin crystal shell among beach grass. Each panel full bleed individual scenic background. Absolutely no borders or words. This is original artwork for eyeland.cards.

## island.png

Painted scenery under the native interactive map pins/player. The logical grid remains authoritative for navigation.

Exact prompt:

> Production game background asset for eyeland.cards. Landscape 1536x1024. A beautiful hand-painted cozy fantasy island chart, high overhead almost orthographic aerial view, entire single small island visible surrounded by deep petrol teal ocean and delicate pale surf. Original storybook fantasy illustration, painterly detailed miniature diorama, warm late afternoon light, golden beaches, lush sage forests and mossy rocks, winding sandy footpaths. Composition coordinates essential: island occupies middle 80 percent horizontally and middle 75 percent vertically, ocean margin all around. A cozy terracotta-roof cottage at 27 percent image width, 44 percent image height; small friendly village clearing at 42 percent width 31 percent height; luminous amber resin flower garden at 57 percent width 44 percent height; sandy crab clearing with amber rocks at 73 percent width 44 percent height; tiny warm campfire clearing at 50 percent width 68 percent height; wooden jetty on lower right coast at 73 percent width 68 percent height. Connect these with readable sandy paths, open grass where a small player marker can travel. A few remote sailboats far out to sea, no people closeup. Trees clustered away from paths. Rich artisanal game art, atmospheric depth, delicate brushwork, lovely coast. NO text, NO letters, NO labels, NO UI, NO map pins, NO frame, NO cards. This will be the actual map background with interface markers drawn over it.

## Foundations catalog reuse (2026-09-20)

The 91 new card definitions map to the existing original nine-cell atlas through explicit `art` IDs and `artStatus: shared prototype illustration`. No additional creature paintings were generated in this pass. Reuse is temporary; card names do not mean these are unique depictions. Unique per-card illustrations remain on the roadmap.

## September 21 dedicated card art

The shared Foundations illustration mapping above is superseded by `cards/manifest.json`: four original five-by-five atlases provide 100 distinct portraits. See `cards/ART-DIRECTION.md` for prompts, subjects, UI decisions and verification. `battle-board.png` is an additional original generated tabletop background. Existing starter and island artwork is preserved.
