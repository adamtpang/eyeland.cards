# eyeland.cards — Design Principles

Distilled from real origin-story research on the greatest games of all time —
Adam's personal favorites and the wider canon — not inspirational quotes.
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

Tetris: one mechanic, absolute elegance, born out of hardware constraint —
a Soviet lab computer, not a big budget.

**Rule:** keep individual card text short (same instinct as Ben Brode's
"play now, think later"). Let surprising moments come from combining simple
cards, never from one card doing five things at once.

## 3. Never lie to the player about fairness

Dark Souls, Miyazaki: *"We believe in challenging games, but not in unfair
or dishonest ones."* Death is communication, never a random punishment.

**Rule:** when a real imbalance is found — e.g. v0's ~71% first-player-advantage
finding — log it honestly (see `game/README.md`) rather than quietly patch
or hide it. A game that cheats the player quietly breaks trust permanently,
even if no single match feels unfair.

## 4. Reward synergy and mastery, not raw power

Slay the Spire: metrics-driven design, thousands of card concepts cut down
to the ones with real combo potential, extensive playtesting before ship.

**Rule:** each element needs a clear verb that combos with itself and with
the others, not just bigger numbers at higher cost. Already true of the
starter three — Fire = tempo/burn, Water = control/sustain, Storm =
draw/AoE — keep every future card legible against one of these verbs.

## 5. Legendaries are build-arounds, not stat sticks

Hearthstone (Ben Brode's design philosophy) and, independently, the
JelloApocalypse Pokémon-pitch research arrived at the identical rule.
Already validated in the codebase: Eye of the Storm does AoE + draw, not
"the biggest number." Keep this for every future legendary.

## 6. Bosses get identity from mechanics, not a palette-swapped element

From the Jello Pokémon research: name bosses by *what they do* — "the Combo
warden," "the Control warden," "the Aggro warden" — the way gym leaders
should be themed by mechanic, not by "the Fire gym." This maps onto a card
game even better than it maps onto Pokémon, since deck archetypes already
give bosses a built-in identity.

## 7. Companions need to be personally meaningful, not stat blocks

Pokémon's real origin: Satoshi Tajiri wanted kids to feel what he felt
catching real insects as urbanization erased that chance. It nearly
bankrupted Game Freak — six years, five employees quit unpaid — because he
refused to ship the feeling wrong.

**Rule:** writing and flavor budget goes to companion personality and card
flavor text, not lore-dump cutscenes. Same instinct as "charm over plot"
from the Jello research.

## 8. Every "failure" period in the middle is normal, not a signal to stop

Pokémon nearly folded Game Freak before it shipped. Tetris's own creator
didn't earn a dollar from his own game for a decade — the Soviet state
owned the idea, and it took an actual international licensing war before
Pajitnov saw royalties. Worth remembering specifically when the middle of a
build stretch feels like nothing is working — that feeling is the normal
shape of the thing, in every one of these stories, not a signal something
is wrong.
