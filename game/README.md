# eyeland.cards — v0 Duel

The first rung of the build ladder: `v0 Duel → v1 Deck → v2 Island → v3 World → v4 Online`.
Plain C#/.NET, zero Unity dependency — the point of v0 is to prove the card-combat
loop is fun before spending any editor/engine time on it. `Eyeland.Duel` is written
as a portable class library on purpose: these same files drop into a Unity project's
`Assets/Scripts/` unmodified once the Unity MCP bridge is set up.

The three cards are the same three from the eyeland.cards landing page — Ember Bolt,
Tidewisp, Eye of the Storm — this is the same game, not a separate prototype.

## Run it

```bash
cd game/src/Eyeland.Duel.Console
dotnet run
```

Commands during a duel:
- `p <handIndex> [targetBoardIndex]` — play a card, optionally aimed at an enemy creature
- `a <yourBoardIndex> [enemyBoardIndex]` — attack face, or a specific enemy creature
- `end` — pass the turn
- `help` / `quit`

## Balance-test it

```bash
dotnet run -- --simulate 500
```

Runs N headless AI-vs-AI games with the symmetric starter deck and reports win rate,
draw rate, and average game length. This is the same tool to reach for once decks
stop being symmetric — Ben Brode-style, iterate from ladder data, not theorycraft
(see `../hearthstone/CLAUDE.md`, same philosophy already run there).

**Known v0 finding:** going first currently wins ~71% of symmetric AI-vs-AI games.
Real card games compensate the player on the draw (an extra card, a "coin"); v0 has
no such mechanic yet. Flagging honestly rather than fixing blind — needs a real
decision (extra starting card? excess pips?) before v1's asymmetric decks make the
signal harder to isolate.

## Structure

```
game/src/
  Eyeland.Duel/            the engine — cards, decks, casters, turn rules (no UI)
    Cards.cs                card/effect model + the starter card pool
    Duel.cs                 Caster, BoardCreature, DuelState, TurnEngine (the rules)
    GreedyAI.cs              dumb-but-legal opponent
  Eyeland.Duel.Console/     playable terminal harness + the AI-vs-AI simulator
    Program.cs
```

## Not yet built (later rungs, not v0's job)

- Real 40-card decks / deckbuilding (`v1 Deck`)
- The archipelago overworld, wild encounters (`v2 Island`)
- Unity scene, sprites, animation — this engine is UI-agnostic on purpose so the
  Unity layer is a thin renderer over it, not a rewrite
- The "going first" imbalance noted above
