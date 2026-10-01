# eyeland.cards: Design Principles

Distilled from real origin-story research on the greatest games of all time,
Adam's personal favorites and the wider canon, not inspirational quotes.
Each one is a rule to actually check a future decision against, with the
game and the specific fact it came from, so the reasoning survives even if
the memory of the research session doesn't.

## 1. One clear idea, executed with conviction, shipped small

Stardew Valley: Eric Barone alone, 4.5 years, every line of code and every
pixel himself. Slay the Spire: two people quit their jobs off a single phone
call and a design doc. Minecraft: shipped *paid and unfinished* at $13,
built live in front of the people who'd already bought in. None of the
greats started at full scope.

**Rule:** never expand scope before the current build-ladder rung
(`v0 Duel → v1 Deck → v2 Island → v3 World → v4 Online`) is proven fun.

## 2. Complexity emerges from simple rules interacting, not from piling on

Tetris: one mechanic, absolute elegance, born out of hardware constraint:
a Soviet lab computer, not a big budget.

**Rule:** keep individual card text short (same instinct as Ben Brode's
"play now, think later"). Let surprising moments come from combining simple
cards, never from one card doing five things at once.

## 3. Never lie to the player about fairness

Dark Souls, Miyazaki: *"We believe in challenging games, but not in unfair
or dishonest ones."* Death is communication, never a random punishment.

**Rule:** when a real imbalance is found, e.g. v0's ~71% first-player-advantage
finding, log it honestly (see `game/README.md`) rather than quietly patch
or hide it. A game that cheats the player quietly breaks trust permanently,
even if no single match feels unfair.

## 4. Reward synergy and mastery, not raw power

Slay the Spire: metrics-driven design, thousands of card concepts cut down
to the ones with real combo potential, extensive playtesting before ship.

**Rule:** each element needs a clear verb that combos with itself and with
the others, not just bigger numbers at higher cost. Already true of the
starter three: Fire = tempo/burn, Water = control/sustain, Storm =
draw/AoE. Keep every future card legible against one of these verbs.

## 5. Legendaries are build-arounds, not stat sticks

Hearthstone (Ben Brode's design philosophy) and, independently, the
JelloApocalypse Pokémon-pitch research arrived at the identical rule.
Already validated in the codebase: Eye of the Storm does AoE + draw, not
"the biggest number." Keep this for every future legendary.

## 6. Bosses get identity from mechanics, not a palette-swapped element

From the Jello Pokémon research: name bosses by *what they do*: "the Combo
warden," "the Control warden," "the Aggro warden," the way gym leaders
should be themed by mechanic, not by "the Fire gym." This maps onto a card
game even better than it maps onto Pokémon, since deck archetypes already
give bosses a built-in identity.

**Rule (added from the fuller Jello transcript):** a mechanic-themed boss
needs a real hard counter, but it should be *discoverable*, not printed on
the boss's own tooltip. Jello's Sound Gym example: a Pokémon with the
Soundproof ability trivializes the fight, but you only learn that from an
NPC sitting outside the gym, in a different cave. The counter exists;
fairness (Principle 3) demands it, but finding it is the player's work,
not a freebie. Translate this to eyeland as: every warden's hard counter
lives in a card, companion, or hint discoverable through play, never in the
warden's own flavor text.

## 6a. The boss scales with the player's own progress, not a fixed level

Jello's fix for badge-skipping trivializing gyms: Gym Leaders field a
stronger team based on the challenger's badge count, not a fixed level,
so a gym you beat early stays a real fight if you return late, and one you
skip doesn't go stale waiting for you. Direct rule for eyeland: a warden's
deck strength should scale off the player's own real progress (cards
unlocked, islands cleared), not a number baked in at design time. Prevents
both "trivialized by over-leveling" and "permanently too hard because I
found it early," the same failure mode in both directions.

## 6b. The world remembers what you did, or didn't do

Jello's bank-heist example: reach the bank before 3 badges and you stop the
robbery; skip that town entirely and NPCs elsewhere tell you a *different*
character stopped it instead, on a version-exclusive riverboat fight. The
world reacts to the player's actual choices and timing, not just narrates a
fixed sequence: his explicit contrast case is Skyrim, where ending the
civil war changes literally nothing in the world afterward. **Rule:** at
least some eyeland encounters should resolve differently depending on real
player choices (which island first, which warden skipped, which companion
carried), and something elsewhere in the game should visibly reference the
outcome. A world that doesn't notice what you did isn't a world, it's a
theme park queue.

## 7. Companions need to be personally meaningful, not stat blocks

Pokémon's real origin: Satoshi Tajiri wanted kids to feel what he felt
catching real insects as urbanization erased that chance. It nearly
bankrupted Game Freak, six years, five employees quit unpaid, because he
refused to ship the feeling wrong.

**Rule:** writing and flavor budget goes to companion personality and card
flavor text, not lore-dump cutscenes. Same instinct as "charm over plot"
from the Jello research.

## 8. Every "failure" period in the middle is normal, not a signal to stop

Pokémon nearly folded Game Freak before it shipped. Tetris's own creator
didn't earn a dollar from his own game for a decade: the Soviet state
owned the idea, and it took an actual international licensing war before
Pajitnov saw royalties. Worth remembering specifically when the middle of a
build stretch feels like nothing is working, that feeling is the normal
shape of the thing, in every one of these stories, not a signal something
is wrong.

## 9. Generate the challenge, don't hand-author every instance of it

Minecraft's own origin: Notch's stated philosophy was *"there's a certain
elegance in telling the computer how to make a world to show to the player
rather than to tell the computer what world to show."* Dwarf Fortress is his
cited direct influence: emergent, procedurally generated worlds where
players write their own stories, not designers.

**Rule:** eyeland's v0 console harness already proves this is possible:
`--seed <n>` gives a deterministic shuffle, the same rules generating a
different-but-fair game every time instead of a hand-authored one. Extend
that instinct rather than abandon it: a "seed of the day" variant of any
GAMES-1000 entry (same rules, same generator, different seed) is free
replayability that doesn't cost new content. When v2 Island resumes, island
layouts should follow the same logic: rules that generate a world, not a
hand-placed one.

## 10. A quest log's job is suggesting a next move, not replacing freedom

FTB's HQM quest book, read firsthand tonight (not theory): a DETECT-type
task, a chained page structure, an optional "pick one" reward. Its real job
in a game as open as a modded Minecraft tech tree is turning "you can do
anything" into "here's a good next thing to try", without removing the
freedom to ignore it and go do something else entirely. The same lesson
surfaced independently tonight in themain.quest: an empty quest board left
the *entire* Match/Climb/Unlocks system invisible, because the quest log
wasn't just a suggestion, it was a gate.

**Rule:** any future progression layer in eyeland (companion unlocks, card
discovery, island objectives) needs a discoverable quest layer that
suggests a next step, same as HQM guides an FTB player through an
overwhelming tech tree, but the underlying system must stay real and
usable even for a player who ignores the log entirely. A quest log that's
load-bearing infrastructure, not a suggestion, is the themain.quest mistake
repeating itself.

## 11. Strength comes from beating things, not from a menu

Adam's own synthesis (2026-08-15), naming three real, specific games rather
than a vibe: Breath of the Wild and Pokémon both tie player power directly
to combat, not shopping. BotW's actual design philosophy (Nintendo's own
"multiplication" principle) is simple systems combining, e.g. bombs + metal
+ magnet, weather + lightning, and clearing a monster camp is how you
actually get better weapons and materials, not a store. Pokémon's core loop
is identical in shape: battle wild Pokémon and Gym Leaders, get stronger,
no other path.

**Rule:** eyeland's own card/companion power should come from beating mobs
and wardens, the same loop as v0's Match itself, not from a currency shop.
The build-a-deck layer (already real, v1's `DeckBuilderUI`) is the
*expression* of that earned strength, not a separate progression track.

**Open question, deliberately not resolved here:** Adam named both Terraria
and WoW for "choose classes," but they're two different real models, not
one. WoW commits you to a class at creation. Terraria has no class-select
screen at all: your "class" (melee/ranged/magic/summoner) is emergent from
whatever gear you're actually wearing, freely reassignable anytime. Which
model eyeland follows (a real class commitment vs. gear-defined flexible
role) is a real fork this file won't silently pick for the game, same
discipline as MASTERPLAN.md leaving pricing open rather than guessing.

**Co-op, cited concretely:** Wizard101's actual party-questing (friends
join your instance, fight the same dungeon together) is the named model for
eyeland's own multiplayer layer, not a generic "add multiplayer" note. This
is explicitly `v4 Online`'s job on the existing build ladder (Principle 1),
not something to pull forward before v0-v3 are proven.

## 11a. Creature victories award their cards and crafting resources

Adam's explicit direction, 2026-09-09: progression is Pokémon-like. Defeat
creatures to earn their cards as prizes; defeating stronger creatures gives
you stronger options for your deck and lets you take on stronger encounters.
The reward is the defeated creature's own card, not an unrelated random card.

- Creatures and their corresponding cards have four rarity tiers: **Common,
  Rare, Epic, Legendary**.
- Creatures also drop **crafting resources**, alongside the card reward.
- The progression loop is **defeat creatures → earn their cards and resources
  → improve your deck → challenge stronger creatures**.

This is confirmed design direction, not an implemented loot or crafting system.
Drop quantities, repeat rewards, resource types, recipes, crafting outputs,
and the precise relationship between rarity and encounter strength remain
undecided. Preserve synergy and counterplay (Principles 4–5) when balancing
stronger rewards.

### Research follow-up: test the reward's tactical payoff (2026-09-11)

[`ELAN-LEE-LESSONS.md`](ELAN-LEE-LESSONS.md) contains the source-linked synthesis
of all 23 available Elan Lee transcripts. Its proposed first test uses two
encounters and a manually awarded creature card plus resource token to ask
whether earned power creates a new decision in the next fight. Two further
tests cover unassisted first-turn understanding and returning to the same deck.
These are unrun experiments, not new committed mechanics or playtest results.
Keep rewards tied to the defeated creature and retain all four rarity tiers.
The older `research/PAPER-PROTOTYPE-v2-island.md` uses add-or-remove rewards
and scalar Power; those historical abstractions do not override Principle 11a
or establish the tactical payoff of actual combat.

## 12. Visual system: storybook archipelago

The 2026-08-26 beautification pass follows one concrete reference: the
Poptropica island-map image on Adam's Milanote Islands board. The useful
parts are the bright storybook sky, floating-island world map, playful color,
and instantly legible adventure tone. The implementation uses original art
and does not copy Poptropica characters, logos, or interface assets.

The runtime remains Unity uGUI. There is no React, Tailwind, or web framework
inside this build, so the design system is expressed as semantic C# tokens in
`Assets/Scripts/Game/UIFactory.cs` and a small responsive patch applied to
Unity's generated WebGL shell by `Assets/Scripts/Editor/GamesBuildScript.cs`.

### Semantic tokens

| Token | Hex | OKLCH | Runtime role |
| --- | --- | --- | --- |
| Background | `#edf7f4` | `oklch(0.9678 0.0113 176.32)` | Browser shell and quiet game ground |
| Foreground | `#102a43` | `oklch(0.2785 0.0564 249.75)` | Primary ink |
| Surface | `#fffdf6` | `oklch(0.9937 0.0095 93.57)` | Parchment panels |
| Surface elevated | `#ffffff` | `oklch(1.0000 0 0)` | Highest-contrast surfaces |
| Surface muted | `#ddeeea` | `oklch(0.9354 0.0188 180.26)` | Secondary controls |
| Muted foreground | `#58717a` | `oklch(0.5321 0.0325 221.87)` | Rules text and labels |
| Primary | `#197b78` | `oklch(0.5297 0.0847 191.72)` | Main action and plus buttons |
| Primary foreground | `#fffdf6` | `oklch(0.9937 0.0095 93.57)` | Text on primary |
| Secondary | `#f5d88f` | `oklch(0.8903 0.0971 88.68)` | Quick Play action |
| Accent | `#ffb765` | `oklch(0.8312 0.1292 67.94)` | End Turn action |
| Destructive | `#d4544d` | `oklch(0.6124 0.1632 26.15)` | Invalid deck count and danger |
| Border | `#91bab7` | `oklch(0.7584 0.0440 190.71)` | Surface outlines |
| Ring | `#35e3d0` | `oklch(0.8276 0.1371 183.72)` | Focus and active highlight |
| Fire | `#e86f42` | `oklch(0.6778 0.1617 40.27)` | Fire cost and card identity |
| Water | `#259caf` | `oklch(0.6387 0.1024 211.14)` | Water cost and card identity |
| Storm | `#7957d5` | `oklch(0.5576 0.1851 291.69)` | Storm cost and card identity |

Panels and controls use a maximum 8 px visual radius. Unity renders that
radius from `Assets/Resources/UI/rounded-rect.png`, a 64 by 64 imported
nine-slice source that remains available in WebGL builds.

### Assets and type

- `Assets/Resources/Art/eyeland-archipelago.png` is original generated art.
  Final prompt: "Wide 16:9 painterly storybook fantasy game background with a
  bright turquoise sky and cloud sea, whimsical floating islands framing the
  edges, and a central dueling island; clean low-detail center for readable
  card-game UI; cheerful adventure palette; no text, logo, characters, cards,
  interface, border, or gradient overlay." It was created with the built-in
  image generation tool and then imported by Unity as a sprite.
- `Assets/Resources/Fonts/Poppins-Regular.ttf` and
  `Poppins-SemiBold.ttf` are the runtime type family. They came from the
  official Google Fonts repository and retain `OFL-Poppins.txt` alongside
  the font files.
- The art is decorative context. Every command, state, value, and card rule
  remains readable without interpreting the image.

### Verification

- Foreground on Surface measures `14.39:1`; Muted foreground on Surface is
  `5.08:1`; Primary foreground on Primary is `4.98:1`.
- Element badge text is chosen per hue: Foreground on Fire is `4.73:1`,
  Foreground on Water is `4.50:1`, and white on Storm is `4.99:1`.
- Unity 6000.5.7f1 compiled the final runtime and all 4 PlayMode tests passed.
- The final WebGL player built successfully at 51,057,483 bytes with 0 errors.
  Unity reported 30 non-blocking build warnings.
- Playwright verified the deck builder and Quick Play duel at 1280 by 800,
  a narrow 430 by 900 desktop embed, and an iPhone 13 profile at 390 by 664.
  The browser reported 0 page errors in all final captures.

## GDC research follow-up

See [GDC-LESSONS.md](GDC-LESSONS.md) for the September 12 synthesis, actual reading coverage and three prioritized, unrun playtests. It preserves these design principles and identifies where historical examples do not transfer directly to persistent collections or future cooperative play.
