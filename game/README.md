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
    DeckBuilderUI.cs         pick your deck (70-card pool, 2 copies each, 1 for the
                              Legendary, 12-card minimum) before the duel starts
    DuelUI.cs                the actual duel screen: human turns are click-driven,
                              AI turns run in a tight synchronous loop since GreedyAI
                              never blocks (see TurnEngine's doc comment for why the
                              console version's blocking RunGame loop doesn't fit here)
    GameFlow.cs              boots with zero scene wiring via RuntimeInitializeOnLoadMethod
```

## v1 Deck in Unity: verified 2026-08-25

Verified from an isolated copy of the real Unity project with Unity 6000.5.7f1:

- Clean Unity compile with zero C# errors.
- Four PlayMode tests pass. They cover the fixed-width deckbuilder, the clipped
  70-card scroll view, visible footer action widths, and the full deckbuilder to
  playable duel flow.
- The `.NET` engine builds cleanly, `sync-unity.mjs --check` passes, and the
  final 1,000-game same-deck simulation completed at 56.1% / 43.9%, with no
  draws and an 11.8-turn average. That is verification evidence, not a claim
  that first-player balance is solved.
- The Eyeland Duel WebGL build succeeds with zero errors at roughly 49.9 MB.
- A Playwright smoke test loads the real WebGL canvas in Edge, reports all 70
  cards loaded, and catches browser-visible layout regressions. The verification
  pass fixed an overflowing card list and zero-width Quick Play / Start Duel
  buttons found this way.

Run the same PlayMode suite from a shell:

```powershell
& 'C:\Program Files\Unity\Hub\Editor\6000.5.7f1\Editor\Unity.exe' `
  -batchmode -nographics -runTests -testPlatform PlayMode `
  -projectPath game\unity -testResults game\unity\playmode-results.xml
```

Build the itch.io-ready WebGL folder through the checked-in editor method:

```powershell
& 'C:\Program Files\Unity\Hub\Editor\6000.5.7f1\Editor\Unity.exe' `
  -batchmode -nographics -quit -projectPath game\unity -buildTarget WebGL `
  -executeMethod Eyeland.Games.Editor.GamesBuildScript.BuildEyelandDuelWebGL
```

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
- **Unity's runtime lacks newer convenience overloads** used by the .NET build:
  generic `Enum.GetValues<T>()` and one-argument `Array.Clear(...)` were replaced
  with their compatible overloads in the portable duel core.
- **UI code must follow engine API renames**: the browser checkpoint caught stale
  `BoardCreature.CanAttack` references after the engine moved to `CanAttackNow`.

## Not yet built (later rungs, not v1's job)

- The archipelago overworld, wild encounters (`v2 Island`)
- Real card art: the current UI uses colored panels + text, functional not pretty
- The "going first" imbalance noted above: still open, now matters more since real
  deckbuilding makes the signal harder to isolate the longer it's left

## 2026-09-11: Ember Reach local playable prototype

The default Unity boot now opens a connected solo expedition: three camps and a Warden, timed real-engine duels, defeated-creature card rewards, ember shards, owned 12-card deck editing and browser-local saves. Common/Rare/Epic/Legendary are represented. The route is an encounter menu with seeded supporting cards and shuffles; a walkable 3D island, crafting recipes and multiplayer are still not implemented.

Play instructions: game/PLAY-EMBER-REACH.md. Local URL: http://127.0.0.1:8765/ while the server runs; restart with game/scripts/play-ember-reach.ps1. Build with game/scripts/build-ember-reach.ps1. Unity 6000.5.7f1 plus WebGL was restored under Adam's AppData/Local/EyelandTools; see game/LOCAL-UNITY-RUNTIME.md. Production was not deployed.

MVP-READINESS.md records 100/100 for the fixed local technical scope: final 10/10 Unity tests, a four-encounter UI-handler journey, 400 terminating engine simulations, and native Helium first victory -> reward -> deck edit -> reload -> earned card in next duel. The full four-fight journey was not played through native browser input. Human enjoyment and session length remain unvalidated. MVP-NEXT-PROMPT.md starts with Adam's unaided playtest; preserve prior research and unrelated working-tree changes.

## 2026-09-20: Brainstorm Island Cards desktop takeover

Read `game/docs/README.md` for the complete recovered design-context set (14 requested systems/scope documents with explicit direction versus hypotheses), and `game/docs/IMPLEMENTATION_STATUS.md` for verified implementation state. The existing React/TypeScript web client is retained; no Godot/Unity restart. Default entry now offers an authored Home Island story sketch with movement, three starter classes, four elements, five-card decks, Legendary placeholders and one real-engine encounter/reward/rest loop. `game/docs/PLAY_STARTER_ISLAND.md` explains local play. New story progress is session-only; existing Ember Reach saves and practice remain separate. Baseline 81 engine checks plus 300 starter simulations, typecheck and build pass. No publishing/deployment/commit was performed. Co-op, market, crafting, fizzle/evolution and full story remain design work.
