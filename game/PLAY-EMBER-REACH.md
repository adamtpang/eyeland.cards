# Play the Ember Reach prototype

This is the first connected **Unity solo expedition**, intended for Adam's own playtest. It keeps the existing card-duel engine and replaces the default deckbuilder boot with an island encounter map. It is a navigation prototype, not a walkable 3D island or an MMO.

## The test

Can earning a creature's card make you try a new tactic in the next fight?

1. Start at Ashwood camp with the supplied 12-card deck.
2. Spend pips to play cards. Click your creature and then an enemy creature or the enemy face to attack. Creatures normally wait one turn; Rush can attack creatures immediately. Taunt protects other targets.
3. Win to earn two Cinder Wolf cards and two ember shards.
4. Open **Edit deck**. Remove two cards and add the Wolves; save exactly 12 cards.
5. Beat Moonpool and Stormgrass, then the Warden. Use your new cards between fights.

Steady Hand spends 2 pips to heal your caster for 2, once per turn. A turn lasts 60 seconds. Time running out ends your turn even during target selection. Defeat costs no cards or shards. Returning to the same encounter uses the same seed. Closing during a duel abandons that fight; completed encounters and deck changes save separately.

## Prototype tuning

- One authored four-encounter route; the expedition seed varies supporting cards and shuffles.
- Common Cinder Wolf → Rare Tidewisp → Epic Galehart → Legendary Ember Reach Warden.
- Camp wins award two copies; Warden awards one. A cleared encounter cannot be farmed.
- Rewards: 2, 4, 6 and 8 ember shards (20 total). Resources accumulate; crafting recipes are not implemented.
- Collection-only, exactly 12-card deck. At most two copies, one legendary.
- Player starts at 30 HP each fight. Opponents: 14, 19, 24 and 29 HP.
- Browser/device local save, no account or cloud sync. Clearing site data removes progress.
- New expedition replaces this save only after a second confirmation click.

## Build / checks

From the repository root:

```powershell
dotnet run --project game/tests/IslandChecks/IslandChecks.csproj
./game/scripts/build-ember-reach.ps1
./game/scripts/play-ember-reach.ps1
```

The play script serves http://127.0.0.1:8765. Alternatively open `game/unity` with Unity 6000.5.7f1 and press Play. The build script uses the project's existing `Eyeland.Games.Editor.GamesBuildScript.BuildEyelandDuelWebGL` method. See MVP-READINESS.md for current build and interaction evidence; do not assume an old build contains this expedition.

## Adam's first playtest notes

Before changing balance, record: time to first victory; whether you noticed the reward; which two cards you cut; whether Rush changed a decision; where the next fight became confusing; whether you wanted one more fight. The intended 20-minute session length and enjoyment are unverified until someone plays it.

## Creature card visuals (2026-09-11)

The eight creatures used by Ember Reach now have original generated portraits. Hand and battlefield cards show portraits, names, costs and current battlefield attack/health; hovering or focusing a card opens its full printed rules. Deck rows have portrait previews. Spell cards currently retain their element-colored SPELL treatment. Art does not change card mechanics. Prompts and provenance: CREATURE-ART-PROMPTS.json. Broader game direction: EYELAND-IDENTITY.md.
