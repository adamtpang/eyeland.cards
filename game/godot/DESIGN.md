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
| Overworld (3D island, sky, water, characters) | Not started. Still the September prototype |
| Sound and music per look | Not started. Only the attack-hit cues exist |
| In-game clock | Not built. The computer's clock picks the look (06:00 to 18:00 is day) |

Checked by `tests/looks.gd` (16 automated checks plus screenshots in
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

- Normal play picks day or night from the computer's clock until the island has its own.
- **F5** cycles day, night and classic on any screen.
- Tests always start in day, with the original attack feel, so results do not depend on the
  time they run.

## Next: the overworld

The island is still the September prototype: a framed 3D view, flat sky, block character.
The plan is a full-screen view with the HUD on top, a gradient sky with sun and moon, a
water shader, toon shading with ink outlines by day and fog with glowing landmarks at
night, and the CC0 KayKit Adventurers characters Adam approved on 2026-10-01 in place of the
block figure.

## Fonts

All Open Font License, from Google Fonts' GitHub, in `assets/fonts/` with their licence
files: Baloo 2, Nunito, Cinzel, Spectral (added 2026-10-01); Cormorant Garamond and Poppins
(classic look).
