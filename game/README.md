# eyeland.cards: v0 Duel, v1 Deck

The first two rungs of the build ladder: `v0 Duel → v1 Deck → v2 Island → v3 World → v4 Online`.
Plain C#/.NET, zero Unity dependency: the point of v0 is to prove the card-combat
loop is fun before spending any editor/engine time on it. `Eyeland.Duel` is written
as a portable class library on purpose: these same files drop into a Unity project's
`Assets/Scripts/` unmodified once the Unity MCP bridge is set up.

The three cards are the same three from the eyeland.cards landing page: Ember Bolt,
Tidewisp, Eye of the Storm. This is the same game, not a separate prototype.

Read [`DESIGN.md`](DESIGN.md) before designing any new card, boss, or system:
concrete rules distilled from real research into why the greatest games actually
work, not inspirational quotes.

## Run it

```bash
cd game/src/Eyeland.Duel.Console
dotnet run
```

Commands during a duel:
- `p <handIndex> [targetBoardIndex]`: play a card, optionally aimed at an enemy creature
- `a <yourBoardIndex> [enemyBoardIndex]`: attack face, or a specific enemy creature
- `end`: pass the turn
- `help` / `quit`

Pass `--seed <n>` for a deterministic shuffle: useful for replaying a run from turn 1
with a longer command sequence each time (how the playtest below was driven over piped
stdin, with no way to react mid-process without one).

## Balance-test it

```bash
dotnet run -- --simulate 500
```

Runs N headless AI-vs-AI games with the symmetric starter deck and reports win rate,
draw rate, and average game length. This is the same tool to reach for once decks
stop being symmetric; Ben Brode-style, iterate from ladder data, not theorycraft
(see `../hearthstone/CLAUDE.md`, same philosophy already run there).

**Known v0 findings:**

- **Fixed:** no starting hand. `StartTurn` always drew exactly one card, with no
  separate deal before turn 1, found by actually playing a full 10-turn game
  (`--seed 42`), not by code review. Turn 1 was a single random card at 1 pip,
  usually unaffordable, so the opening move was almost always a forced pass.
  `Caster.DealOpeningHand` now deals 3 cards to each side before turn 1, separate
  from the per-turn draw.
- **Largely resolved 2026-08-23, by accident.** Going first used to win **71-73%**
  of symmetric AI-vs-AI games, and the note here said it needed a real decision
  (an extra card on the draw, a coin). Adding the Hearthstone keyword set moved it
  to **51.2 / 53.2 / 53.5%** across three runs of 2,000, without any catch-up
  mechanic being added.
  The cause is **Rush**. Cinder Wolf and Drift Hand can now answer a board the
  turn they land, so the player on the draw is no longer a full tempo step behind.
  That is exactly the job Rush does in Hearthstone, and it turned out to be the
  missing piece rather than a coin.
  Average game length rose from 9.3 to 12.0 turns at the same time, consistent
  with boards trading more instead of one side snowballing.
  Not called "fixed": ~53% is close to fair but not proven fair, and this is one
  AI against itself on one symmetric deck. Re-measure when class decks exist.
- Taunt behaves correctly under real play: it absorbs attacks (even multiple weaker
  ones) until it dies, then stops forcing: confirmed live when a 1/4 Tide Guard ate
  two attacks in one enemy turn before the rest went face.
- Hand indices shift after every play (list, not stable IDs): fine for a scripted
  or careful player, mildly error-prone for a fast one. Worth stable per-card handles
  before this becomes a real UI, not urgent for v0.

## Structure

```
game/src/
  Eyeland.Duel/            the engine: cards, decks, casters, turn rules (no UI)
    Cards.cs                card/effect model + the starter card pool
    Duel.cs                 Caster, BoardCreature, DuelState, TurnEngine (the rules)
    GreedyAI.cs              dumb-but-legal opponent
  Eyeland.Duel.Console/     playable terminal harness + the AI-vs-AI simulator
    Program.cs

game/data/
  cards.json               THE CARD POOL, as data. Add or change cards here, no recompile.

game/scripts/
  sync-unity.mjs           copies the duel core + cards.json into Unity (--check for CI)

game/unity/Assets/Scripts/
  Duel/                    generated copy of game/src/Eyeland.Duel, plus a small
                            polyfill and explicit `using`s Unity's compiler needs that
                            the console project's .csproj settings hide (see below);
                            edit game/src/ first, then re-copy, never edit the Unity
                            copy directly and let it drift
  Game/                    v1 Deck: click-driven UI on top of the same engine
    UIFactory.cs             runtime-constructed uGUI helpers (no hand-edited .unity
                              scene files, no Inspector wiring to keep in sync)
    DeckBuilderUI.cs         pick your deck (10-card pool, 2 copies each, 1 for the
                              Legendary, 12-card minimum) before the duel starts
    DuelUI.cs                the actual duel screen: human turns are click-driven,
                              AI turns run in a tight synchronous loop since GreedyAI
                              never blocks (see TurnEngine's doc comment for why the
                              console version's blocking RunGame loop doesn't fit here)
    GameFlow.cs              boots with zero scene wiring via RuntimeInitializeOnLoadMethod
```

## v1 Deck in Unity: what's actually verified vs. what needs your own eyes

**Verified, via real clicks in Play mode, not just "it compiles":**
- Clean compile (0 errors) after fixing real issues along the way (see below)
- `RuntimeInitializeOnLoadMethod` correctly boots the whole UI with zero scene setup
- The deckbuilder renders all 10 real cards with correct cost/stats/rarity
- `+`/`-` clicks correctly increment/decrement, correctly cap (2 copies, 1 for the
  Legendary), and the running deck-size counter is correct and turns from red to
  white exactly at the 12-card minimum

**Not fully click-verified, a real gap, not glossed over:** I could not get Unity's
Game-view preview to show the full canvas at a size where I could reliably click
"Start Duel" and walk the actual duel screen end-to-end. This is a Game-view preview
*zoom* control (separate from the actual `CanvasScaler`, which is set to
`ScaleWithScreenSize` and sizes correctly to a real screen/build regardless) that I
could not get to respond reliably through computer-use clicks/drags. **If you hit the
same thing:** the Scale slider next to the Game tab, or the Free Aspect dropdown's
resolution presets, or just un-maximizing/resizing the Unity window, should get the
whole canvas back into view; any one of those should take you a few seconds with a
mouse in a way it didn't for me. `DuelUI` reuses the exact same `TurnEngine.TryPlayCard`
/ `TryAttack` / `EndTurn` calls already proven correct via v0's real 10-turn console
playthrough, so the underlying logic is on solid ground: what's unverified is
specifically the click-wiring glue in `DuelUI`, not the rules engine.

## Real compile bugs found and fixed while porting v0 into Unity

Unity's compiler and runtime differ from the console project's `.csproj` in several
ways that only show up when you actually try to compile; logging these since they'll
recur the moment more code gets ported:

- **`required` members need `-langversion:11`**: Unity defaults to C# 9 for
  `Assembly-CSharp` regardless of the compiler's real capability. Fixed via
  `Assets/csc.rsp` (`-langversion:11`), the standard override mechanism.
- **`required`/`init` need BCL support types Unity's runtime doesn't ship**:
  `RequiredMemberAttribute`, `CompilerFeatureRequiredAttribute`, `IsExternalInit`.
  Fixed via a small polyfill (`Duel/RequiredMemberPolyfill.cs`) rather than editing
  the engine files, preserving their "drops in unmodified" design intent.
- **No `ImplicitUsings`**: Unity doesn't respect that `.csproj` setting the console
  project relies on. The Unity copies of the engine files need explicit
  `using System;` / `using System.Collections.Generic;` / `using System.Linq;` that
  the console originals don't.
- **`UnityEngine.UI` (legacy `Text`/`Button`/`Image`) isn't bundled by
  `com.unity.modules.ui` alone in Unity 6**: needed `com.unity.ugui` added to
  `Packages/manifest.json` explicitly.
- **Bare `Object` is ambiguous** the moment both `using System;` and `using UnityEngine;`
  are in scope (`System.Object` vs `UnityEngine.Object`, both spelled `Object`):
  needs `UnityEngine.Object.Destroy(...)` etc. spelled out fully.

## Not yet built (later rungs, not v1's job)

- The archipelago overworld, wild encounters (`v2 Island`)
- Real card art: the current UI uses colored panels + text, functional not pretty
- The "going first" imbalance noted above: still open, now matters more since real
  deckbuilding makes the signal harder to isolate the longer it's left
