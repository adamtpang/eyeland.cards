# Eyeland design system

Decided by Adam on 2026-10-01 from the three-direction style board
(https://claude.ai/artifact/7xkMjZQc1DLXjMemSC1nzw): **Sunlit Cel by day, Inked Relic at
night.** The earlier painted look is kept as "classic" for comparison; its document is
[DESIGN-2026-09-20-coastal-storybook.md](DESIGN-2026-09-20-coastal-storybook.md).

One layout, three looks. Every colour, font, outline and shadow comes from the tokens in
`skin.gd` (`UIStyle.P`). Draw code must not hard-code a colour.

## Status

| Area | Day and night looks |
|---|---|
| Battle board, cards, tokens, gems, hero portraits | Applied (2026-10-01) |
| Menus: collection, deck, buttons, panels, tooltips | Applied through the shared theme |
| Card art restyle (cel by day, engraved at night) | Applied with `card_style.gdshader` |
| Overworld (3D island, sky, water, characters) | First pass applied (2026-10-01), see "The overworld" below |
| Sound and music per look | Synthesized ambience and placeholder tunes on the island; battle has hit cues only |
| In-game clock | Built (2026-10-01): 12-minute days on the island, shown in the HUD, saved |

Checked by `tests/looks.gd` (46 automated checks plus screenshots in
`game/evidence/looks-2026-10-01/`). No human has judged the look in motion yet.

## The two looks

| | Day: Sunlit Cel | Night: Inked Relic |
|---|---|---|
| Mood | Bright Saturday-morning adventure | An old sea chart read at night |
| Shapes | Chunky, rounded (radius 14 to 18) | Sharp, engraved (radius 3 to 6) |
| Outline | 3 px ink navy on everything | 1 px bone line, double ring on tokens |
| Shadow | Hard drop shadow, no blur | None; a faint ember glow on cards |
| Display font | Baloo 2, weight 800 | Cinzel, weight 600 |
| Body font | Nunito, weight 700 | Spectral Regular |
| Card art | Flat value bands, boosted colour, ink edges | Bone-on-indigo cross-hatching |
| Gems | Round, outlined, offset shadow | Diamonds with a bone edge |
| Attack feel | B Heavy | C Slash |

## Colour tokens

| Role | Day | Night |
|---|---|---|
| Background | `#7fd3ee` sky | `#0d0b14` |
| Ink / outline | `#1d2a4d` | `#110f1a` |
| Panel | `#ffffff` | `#1e1b2e` |
| Text | `#1d2a4d` | `#d9cfb8` bone |
| Muted text | `#4f5f85` | `#8f88a3` |
| Primary action | `#ffd23f` sun | `#e2643a` ember |
| Playable / positive | `#12b886` | `#8e7ff5` spirit |
| Board | `#f6dfa0` sand | `#1a1728` indigo |
| Card face | `#ffffff` | `#1e1b2e` |
| Name banner | `#ff6b57` coral, white text | `#110f1a`, ember text |
| Mana | `#2f8fff` | `#8e7ff5` |
| Attack | `#ffab00` | `#d9cfb8` |
| Health | `#ff4d6d` | `#e2643a` |

Element accents (fire, water, earth, air) and rarity gems keep one set of colours in every look.

## Rules

- **One accent per look.** Day spends yellow on the single primary action; night spends ember.
  Everything else stays in ink, white and the board colour.
- **State is shown by the outline**, not by a new fill: hover and focus use the primary
  accent, playable uses the positive colour, idle uses ink (day) or bone (night).
- **Numbers sit in gems; names sit on plates.** Health and attack never float over artwork
  without a plate or gem behind them.
- **Art is restyled, not replaced.** `card_style.gdshader` restyles only draws tagged with
  `UIStyle.ART`, so frames and text are untouched. New art should be made for the look it
  will mostly be seen in, then checked in the other.
- **Motion matches the look.** Day: squash, bounce, hard hits (attack feel B). Night: sharp,
  fast, glowing (attack feel C). F1 to F4 still switch the attack feel by hand.
- **Layout does not change between looks.** Positions and sizes are shared, so every layout
  test covers all three.

## Switching

- **The island has its own clock.** A full day takes 12 real minutes on the island and the
  clock pauses in battles and menus. 06:00 to 18:00 is day. Sunrise and sunset blend over
  12 seconds. The time is shown in the island HUD and kept in the save.
- **F5** skips to the next sunset or sunrise on any screen. **F6** toggles the classic look.
- Tests always start in day, with the original attack feel, so results do not depend on the
  time they run.

## The overworld

First pass, 2026-10-01 (`world_3d.gd`, `sky.gdshader`, `water.gdshader`):

- **Full-window 3D view** with the HUD floating on top as plates: place and health top
  left, the nearby action bottom centre. Empty HUD space passes the mouse to the world.
- **Toon shading everywhere** (`DIFFUSE_TOON`, no highlights) with one shared ink outline
  pass: navy by day, bone at night. Clouds, flowers and paths skip the outline.
- **Sky:** flat two-colour gradient with a hard sun disc by day; indigo with a moon and
  twinkling stars at night.
- **Water:** flat cel colour, foam rings that breathe along the shore, drifting glints.
- **Light:** day is a warm sun with pale blue shadows. Night is dim moonlight, fog, bloom,
  and warm point lights at the cottage, campfire, garden crystals and dock lantern.
- **Characters:** animated KayKit Adventurers (CC0, Kay Lousberg, in `assets/characters/`
  with the licence). Warrior is the Knight, ranger the hooded Rogue, wizard the Mage; Mira
  uses the Mage or Rogue. Idle, walk, run and jump animations. The old block figure remains
  as a fallback if a model is missing.
- **Scenery:** round and pine trees, bushes, rocks, flowers, a fenced cottage, tent, dock
  posts and drifting clouds.

Second pass, 2026-10-01 (`terrain.gdshader`, `grass.gdshader`, `world_audio.gd`):

- **Creatures:** the companion has a face, feet and one feature for its element (flame
  tuft, fins, leaf sprout or wings) and hops while it follows. The Resin Crab has a spotted
  shell, eye stalks, snapping claws and six moving legs. Both are still built from simple
  shapes in code, not sculpted models.
- **Ground:** hard-edged brush dabs and sun patches on the grass, speckle on the sand, and
  about 2,000 swaying grass blades drawn as one MultiMesh, kept off the paths.
- **Sound:** synthesized in code, no recordings. Sea wash, birdsong by day, crickets at
  night, footsteps, jump, landing and an interact chime. The Sound button on the island
  silences island and battle sound together.
- **Day to night blends** on the same island over 1.8 seconds: the sun sweeps round, the
  sky passes through a short orange sunset, and lights, fog, stars and crickets fade.
  Re-rendering the HUD no longer rebuilds the world.

Third pass, 2026-10-01:

- **Music:** two short loops written as note lists and synthesized in code
  (`world_audio.gd`): a bright C major tune by day (100 bpm, bass, plucked arpeggio, bell
  melody) and a slow A minor one at night (66 bpm, pads and a sparse bell line). They
  crossfade with the look and obey the Sound button. Copies for listening are in
  `game/evidence/looks-2026-10-01/tune-day.wav` and `tune-night.wav`. They are placeholders:
  nobody has listened to them yet, and a composed track would be better.
- **In-game clock**, described under "Switching".

- **Companion models:** four animated monsters from Quaternius's CC0 "Ultimate Monsters"
  bundle (in `assets/creatures/` with the licence): Dragon for fire, Fish for water,
  Mushnub for earth, Birb for air. They idle and walk or fly behind the hero, with their
  own thinner outline pass because their rigs are authored at a different scale. The
  code-built friend remains as a fallback. Their colours do not all match their element
  yet (the earth Mushnub is blue).

Still open: the Resin Crab is still built from shapes in code (the pack has no crab), no
NPC other than Mira, and no human has judged how any of this looks in motion or how it
sounds.

## Fonts

All Open Font License, from Google Fonts' GitHub, in `assets/fonts/` with their licence
files: Baloo 2, Nunito, Cinzel, Spectral (added 2026-10-01); Cormorant Garamond and Poppins
(classic look).
