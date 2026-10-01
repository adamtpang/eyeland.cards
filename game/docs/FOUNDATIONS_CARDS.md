# Foundations — 100-card prototype set

September 20, 2026. 25 cards per element; 60 minions, 39 spells and 1 weapon; 0–10 mana. Generated Coin is not collectible and is excluded. Costs and stats are initial designs, not balanced ratings. Weapon stats are attack/durability.

Browse in Godot: **Collection**. Select an owned support slot to replace it, or inspect any card and choose **Try in … deck**. Practice borrows a 30-card elemental deck and does not change adventure ownership. Only the original starter/support cards and the Crab reward are currently obtainable in the adventure.

**Art:** the original nine cards have their existing paintings; the 91 added definitions reuse these as explicitly marked prototype illustrations. Unique art is pending.

## Element identities

| Element | Theme | Example package |
|---|---|---|
| Air | Draw, flocks, repeated board buffs | Gather the Flock → Rising Winds → Skyward Chorus |
| Water | Healing and preserving a developed board | Coral Defender → Coral Bloom → Restoring Rain |
| Fire | Pressure, targeted burn and clearing blockers | Flare Fox → Cinder Captain → Scorching Wave |
| Earth | Taunt, armor and empty-crystal ramp into large minions | Deep Roots → Resin Golem → Orun |

Matching-element buffs reward commitment; generic buffs and utility allow mixed-element decks. Class powers are a separate choice. No elemental damage weakness/resistance multiplier is implemented. Starters retain their original shared scaffold ability for save/tutorial compatibility.

Source of authored additions: `game/scripts/build-foundations.py`; runtime source: `game/godot/data/cards.json`. Change the authoring rows before regenerating. The script preserves the nine original stable IDs.

## Air

| Card | Mana | Type | Stats | Rarity | Rules |
|---|---:|---|---|---|---|
| Tailwind | 0 | Spell | — | Common | Give your minions +1/+0. |
| Breeze Finch | 1 | Minion | 2/2 | Common | A small friend with a brave heart. |
| Feather Ward | 1 | Spell | — | Common | Give a friendly minion +1/+2. |
| Wispwing | 1 | Minion | 1/2 | Common | — |
| Cloud Hare | 2 | Minion | 3/2 | Common | — |
| Fresh Breeze | 3 | Spell | — | Rare | Secret: When your opponent casts a spell, counter it. |
| Gale Messenger | 2 | Minion | 1/2 | Rare | Battlecry: Draw 1 card. |
| Gust Bolt | 1 | Spell | — | Common | Deal 3 damage. Overload: (1). |
| Cloudling | 3 | Minion | 3/4 | Legendary | Battlecry: Gain 2 Armor. |
| Gather the Flock | 3 | Spell | — | Common | Summon 2 Breeze Finchs. |
| Rising Winds | 3 | Spell | — | Rare | Give your Air minions +1/+1. |
| Skyfin Ray | 3 | Minion | 2/2 | Common | Charge. |
| Wind Archivist | 3 | Minion | 2/3 | Rare | Spell Damage +1. |
| Cloud Shepherd | 4 | Minion | 2/4 | Rare | Battlecry: Summon 1 Breeze Finch. |
| Storm Kite | 4 | Minion | 4/3 | Common | Battlecry: Deal 1 damage. |
| Windfall | 2 | Spell | — | Rare | Discover an Air minion. |
| Zephyr Dancer | 4 | Minion | 3/4 | Common | Windfury. |
| Flock Captain | 5 | Minion | 3/5 | Rare | Adjacent minions have +2 Attack. |
| Thunderhead | 5 | Spell | — | Common | Deal 3 damage to all enemy minions. |
| Skyward Chorus | 6 | Spell | — | Epic | Give your minions +2/+2. |
| Thunder Roc | 6 | Minion | 6/5 | Epic | Battlecry: Deal 2 damage. |
| Sky Librarian | 7 | Minion | 5/7 | Epic | Battlecry: Draw 2 cards. |
| Eye of the Storm | 8 | Spell | — | Epic | Deal 3 damage to all enemy minions. Draw 2 cards. |
| Nimbus Guardian | 8 | Minion | 7/9 | Epic | Taunt. |
| Aella, Open Sky | 10 | Minion | 7/7 | Legendary | Battlecry: Summon 2 Breeze Finchs. Give your minions +1/+1. |

## Water

| Card | Mana | Type | Stats | Rarity | Rules |
|---|---:|---|---|---|---|
| Sea Glass | 3 | Spell | — | Common | Silence all enemy minions. |
| Dewdrop Newt | 2 | Minion | 1/2 | Common | Poisonous. |
| Mending Tide | 1 | Spell | — | Common | Restore 4 Health to your hero. |
| Clearwater | 2 | Spell | — | Common | Draw 1 card. Restore 2 Health to your hero. |
| Pearl Keeper | 2 | Minion | 1/3 | Common | Battlecry: Restore 2 Health to your hero. |
| Reef Otter | 2 | Minion | 2/3 | Common | Lifesteal. |
| Undertow | 2 | Spell | — | Common | Deal 3 damage. Freeze the target. |
| Brook Guide | 3 | Minion | 2/3 | Rare | Battlecry: Draw 1 card. |
| Coral Defender | 3 | Minion | 2/4 | Common | Taunt. |
| Deep Current | 3 | Spell | — | Rare | Draw 2 cards. |
| Mist Heron | 3 | Minion | 3/3 | Common | Battlecry: Restore 2 Health to your hero. |
| Restoring Rain | 3 | Spell | — | Rare | Restore 4 Health to your minions. Restore 4 Health to your hero. |
| Tideling | 3 | Minion | 3/4 | Legendary | Battlecry: Gain 2 Armor. |
| Coral Bloom | 4 | Spell | — | Rare | Give your Water minions +1/+2. |
| Shellback Tortoise | 4 | Minion | 2/4 | Common | Taunt. Divine Shield. |
| Tidepool Mystic | 4 | Minion | 3/5 | Rare | Battlecry: Restore 2 Health to your minions. |
| Crashing Surf | 5 | Spell | — | Common | Deal 3 damage to all enemy minions. Freeze all enemy minions. |
| Reef Conductor | 5 | Minion | 4/4 | Rare | Your other minions have +1 Health. |
| River Stag | 5 | Minion | 4/6 | Rare | Battlecry: Restore 4 Health to your hero. |
| Glacier Whale | 6 | Minion | 5/7 | Epic | Taunt. |
| Tidal Renewal | 6 | Spell | — | Epic | Restore 8 Health to your hero. Draw 2 cards. |
| Call the Reef | 7 | Spell | — | Epic | Summon 2 Shore Guards. Restore 4 Health to your hero. |
| Pearl Leviathan | 7 | Minion | 6/7 | Epic | Battlecry: Restore 6 Health to your hero. |
| Moonwell Serpent | 8 | Minion | 6/8 | Epic | Battlecry: Draw 2 cards. |
| Nerissa, Deep Song | 10 | Minion | 7/10 | Legendary | Battlecry: Restore 8 Health to your hero. Restore 8 Health to your minions. |

## Fire

| Card | Mana | Type | Stats | Rarity | Rules |
|---|---:|---|---|---|---|
| Kindle | 0 | Spell | — | Common | Gain 1 Armor. |
| Cinder Moth | 1 | Minion | 2/1 | Common | Stealth. |
| Pocket Spark | 1 | Spell | — | Common | Deal 2 damage. |
| Coalback Pup | 2 | Minion | 2/2 | Common | Deathrattle: Summon a Breeze Finch. |
| Flame Lance | 2 | Spell | — | Common | Deal 3 damage. Combo: Deal 5 damage instead. |
| Kiln Keeper | 2 | Minion | 1/3 | Common | Battlecry: Gain 2 Armor. |
| Stoke the Hearth | 2 | Spell | — | Common | Gain 3 Armor. Draw 1 card. |
| Ash Courier | 3 | Minion | 2/3 | Rare | Battlecry: Draw 1 card. |
| Brushfire | 3 | Spell | — | Common | Deal 2 damage to all enemy minions. |
| Ember Chorus | 3 | Spell | — | Rare | Give your Fire minions +2/+0. |
| Emberling | 3 | Minion | 3/4 | Legendary | Battlecry: Gain 2 Armor. |
| Flare Fox | 3 | Minion | 4/2 | Common | Battlecry: Deal 1 damage. |
| Fuel the Fire | 3 | Spell | — | Rare | Draw 2 cards. |
| Hearth Turtle | 3 | Minion | 2/4 | Common | Taunt. |
| Ember Ram | 4 | Minion | 4/3 | Common | Rush. |
| Furnace Beetle | 4 | Minion | 3/5 | Rare | Battlecry: Gain 3 Armor. |
| Cinder Captain | 5 | Minion | 4/4 | Rare | Your other minions have +1 Attack. |
| Lava Salamander | 5 | Minion | 5/4 | Rare | Battlecry: Deal 1 damage to all enemy minions. |
| Scorching Wave | 5 | Spell | — | Rare | Deal 3 damage to all enemy minions. |
| Meteor Fall | 6 | Spell | — | Epic | Deal 8 damage. |
| Pyre Roc | 6 | Minion | 6/5 | Epic | Battlecry: Deal 2 damage. |
| Volcano Drake | 7 | Minion | 6/7 | Epic | Battlecry: Deal 2 damage to all enemy minions. |
| Ashen Colossus | 8 | Minion | 8/8 | Epic | Battlecry: Deal 2 damage to ALL minions. |
| Worldfire | 8 | Spell | — | Epic | Deal 7 damage to ALL characters. |
| Solara, First Flame | 10 | Minion | 8/8 | Legendary | Battlecry: Deal 4 damage to all enemy minions. |

## Earth

| Card | Mana | Type | Stats | Rarity | Rules |
|---|---:|---|---|---|---|
| Pebble Ward | 2 | Spell | — | Common | Secret: When your hero is attacked, gain 8 Armor. |
| Resin Crab | 1 | Minion | 1/2 | Common | A garden visitor, safely held in a card. |
| Resin Salve | 1 | Spell | — | Common | Restore 3 Health to your hero. |
| Deep Roots | 2 | Spell | — | Rare | Choose One: Gain an empty Mana Crystal; or gain 6 Armor. |
| Mossback Cub | 2 | Minion | 2/3 | Common | — |
| Pebble Sentry | 2 | Minion | 1/4 | Common | Taunt. |
| Shore Guard | 2 | Minion | 1/4 | Common | Taunt. |
| Stone Skin | 2 | Spell | — | Common | Gain 5 Armor. |
| Earthen Spear | 3 | Weapon | 3/2 | Common | Equip a 3/2 Earthen Spear. Deathrattle: Gain 2 Armor. |
| Mossling | 3 | Minion | 3/4 | Legendary | Battlecry: Gain 2 Armor. |
| Resin Tender | 3 | Minion | 2/4 | Rare | Battlecry: Gain 3 Armor. |
| Root Digger | 3 | Minion | 2/2 | Rare | Battlecry: Gain 1 empty Mana Crystal. |
| Wild Growthsong | 3 | Spell | — | Rare | Give your Earth minions +1/+2. |
| Crab Colony | 4 | Spell | — | Common | Summon 3 Resin Crabs. |
| Granite Badger | 4 | Minion | 3/6 | Common | Taunt. |
| Grove Keeper | 4 | Minion | 3/4 | Common | Battlecry: Restore 3 Health to your hero. |
| Reclaim | 4 | Spell | — | Rare | Gain 4 Armor. Draw 2 cards. |
| Rootbound Elder | 5 | Minion | 3/6 | Rare | Battlecry: Give your Earth minions +1/+1. |
| Stonehorn Elk | 5 | Minion | 5/6 | Common | — |
| Earthquake | 6 | Spell | — | Epic | Deal 5 damage to ALL minions. |
| Resin Golem | 6 | Minion | 4/8 | Rare | Taunt. Battlecry: Gain 3 Armor. |
| Mountain Mammoth | 7 | Minion | 7/8 | Epic | — |
| Ancient Grove | 8 | Minion | 6/10 | Epic | Taunt. Battlecry: Restore 4 Health to your hero. |
| Mountain's Gift | 8 | Spell | — | Epic | Gain 8 Armor. Summon 2 Shore Guards. |
| Orun, Living Mountain | 10 | Minion | 9/12 | Legendary | Taunt. |
