# Game science study guide

Written 2026-10-01 for Eyeland. Research, frameworks and lessons from great games, each
tied to a decision in this game.

**How far to trust each line.** A research agent gathered these on 2026-10-01.
`[read]` means the page was opened and read. `[search]` means the source was found and its
details matched in search results, but the page was not opened. `[memory]` means it is
from memory and not checked. Open the link before quoting anything in public.

## 1. Why people play

### The 8 kinds of fun (MDA)

This is most likely "the 8 things people play games for". Hunicke, LeBlanc and Zubek,
"MDA: A Formal Approach to Game Design and Game Research", 2004 `[search]`.
https://users.cs.northwestern.edu/~hunicke/MDA.pdf

| Kind of fun | Meaning `[memory]` | Where Eyeland can deliver it |
|---|---|---|
| Sensation | Sense pleasure | Attack feel, the cel island, music |
| Fantasy | Make-believe | Being a card-wielding adventurer with a companion |
| Narrative | Drama | The garden, Mira, black sails on the horizon |
| Challenge | Obstacle course | Battles that need a better deck or better play |
| Fellowship | Social framework | Co-op questing (planned, not built) |
| Discovery | Uncharted territory | New islands, new creatures |
| Expression | Self-discovery | Deck building, class and companion choice |
| Submission | Pastime | A quick battle, tending a collection |

Adam's favourite games map onto this cleanly: Minecraft and Terraria are Discovery and
Expression; Hearthstone and Wizard101 are Challenge and Expression; Pokemon is Discovery
and collection; EA FC and Overwatch are Challenge and Fellowship. The overlap, and so the
core of Eyeland, is **Discovery, Expression and Challenge**.

### Other models

- **Self-Determination Theory in games.** Ryan, Rigby and Przybylski (2006), "The
  Motivational Pull of Video Games" `[search]`. Three needs each independently predict
  enjoyment and future play: **autonomy** (meaningful choice), **competence** (I am
  getting better) and **relatedness** (I matter to others).
  https://doi.org/10.1007/s11031-006-9051-8
- **Quantic Foundry motivation model** `[search]`. Twelve motivations in six pairs:
  Action (Destruction, Excitement), Social (Competition, Community), Mastery (Challenge,
  Strategy), Achievement (Completion, Power), Immersion (Fantasy, Story), Creativity
  (Design, Discovery). https://quanticfoundry.com/2016/12/15/primary-motivations/
- **Bartle's player types** (1996) `[search]`: Achievers, Explorers, Socializers, Killers.
  https://mud.co.uk/richard/hcds.htm
- **Lazzaro's 4 Keys** (2004) `[search]`: Hard Fun, Easy Fun, Altered States, The People
  Factor.
- **Octalysis** (Yu-kai Chou) `[read]`. Eight "core drives": Epic Meaning, Accomplishment,
  Creativity and Feedback, Ownership, Social Influence, Scarcity, Unpredictability, Loss
  Avoidance. It is a gamification model, not games research, and the last three are the
  ones manipulative designs lean on.
  https://yukaichou.com/gamification-examples/octalysis-gamification-framework/

## 2. Flow

- **Flow**: Csikszentmihalyi (1990) `[memory]`. The triggers Adam named are the core ones:
  clear goals, immediate feedback, and challenge matched to skill.
- **GameFlow**: Sweetser and Wyeth (2005) `[search]`. Eight elements: concentration,
  challenge, skills, control, clear goals, feedback, immersion, social interaction.
  https://dl.acm.org/doi/10.1145/1077246.1077253
- **Jenova Chen, "Flow in Games"** (2006) `[search]`. Let players set their own difficulty
  through choices inside the game rather than a menu.
  https://www.jenovachen.com/flowingames/Flow_in_games_final.pdf

How the onboarding built on 2026-10-01 uses them:

| Trigger | In the game |
|---|---|
| Clear goals | A goal plate on the island and a golden marker over the place to go |
| Immediate feedback | "Goal complete" pulse and chime; a coach line that changes after every action |
| Challenge and skill | Three lessons that add one idea each, then the real Crab fight |

## 3. Findings that should change decisions

- **Tutorials help most in complex, unfamiliar games.** Andersen et al., CHI 2012, 45,000+
  players `[search]`. Tutorials raised play time by up to 29% in the complex game and did
  almost nothing in simple, familiar ones. Help shown in context beat help shown up front,
  and restricting the player's freedom showed no benefit. *For Eyeland: a card battler is
  complex, so teach it, but in context, and never lock the player in.*
  https://grail.cs.washington.edu/projects/game-abtesting/chi2012/chi2012.pdf
- **Juice: medium beats extreme.** Kao (2020), n=3,018 `[search]`: medium and high visual
  feedback beat both none and extreme on enjoyment, play time and performance. Juul and
  Begy (2016) `[search]`: players rated a juicy version higher but played worse in it.
  *For Eyeland: the Heavy and Slash attack feels are probably right; do not stack more
  effects on top without a playtest.*
- **Easier kept players longer.** Lomas et al., CHI 2013 `[search]`: players played longer
  when the game was easier, against the usual inverted-U assumption.
  *For Eyeland: early fights should be winnable by a first-time player.*
  https://dl.acm.org/doi/10.1145/2470654.2470668
- **Failure is wanted, if you can escape it by improving.** Juul, "The Art of Failure"
  (2013) `[search]`. *For Eyeland: a loss should point at a fix (a card to earn, a deck
  change), not just send the player back to camp.*
- **Loot boxes track problem gambling.** Zendle and Cairns (2018), n=7,422 `[search]`.
  *For Eyeland: cards come from beating creatures, not from paid random packs.*

## 4. Onboarding rules

George Fan, "How I Got My Mom to Play Through Plants vs. Zombies", GDC 2012 `[read, via
notes]`. https://www.gdcvault.com/play/1015541/How-I-Got-My-Mom

1. Blend the tutorial into the game.
2. Have the player do, not read.
3. Spread out the teaching of mechanics.
4. Get the player to perform the action once.
5. Use fewer words.
6. Use unobtrusive messaging.
7. Use adaptive messaging (only when needed).
8. Do not create noise.
9. Teach through visuals.
10. Leverage what people already know.

Eric Dodds, "Hearthstone: 10 Bits of Design Wisdom", GDC 2014 `[read, via summary]`:
iterate fast, share the vision, simplify, keep it deep, immediate fun, embrace the medium,
do not change too much, support player stories, emotional design matters, little
victories. https://www.gdcvault.com/play/1020775/Hearthstone-10-Bits-of-Design

Where Eyeland's onboarding still breaks these rules: the coach uses sentences where an
arrow or a glowing card would do (rules 5 and 9), and nothing yet stops showing hints to
a player who clearly already knows (rule 7).

## 5. One lesson from each great game

| Game or studio | Lesson | Trust |
|---|---|---|
| Minecraft | Simple blocks that combine into play the designers never planned | `[search]` |
| Wizard101 | Card depth presented like an animated show: cool and powerful, also silly and fun | `[search]` |
| Hearthstone | Remove complexity, never depth; make the first minutes fun | `[read]` |
| EA FC Ultimate Team | Collection plus squad building is a strong loop; its paid packs are what the loot box research warns about | `[search]`, weak source |
| Overwatch | Every hero readable at a glance and by sound | `[search]` |
| Terraria | Build the game you want to play; keep giving back to players | `[search]`, weak source |
| Pokemon | Collecting came from insect collecting plus the link cable: collection is social | `[search]` |
| Breath of the Wild | A few rules that multiply with each other, so players invent solutions | `[search]` |
| Nintendo | Introduce a mechanic safely, develop it, twist it, conclude | `[search]` |
| Blizzard | Gameplay first; easy to learn, almost impossible to master | `[search]` |
| Supercell | Small teams that kill their own games and celebrate the lesson | `[search]` |
| Valve | Playtests settle design arguments | `[search]` |

Sources for this table are in the research notes; the weakest are Mojang, Terraria and
EA FC, where no developer talk or postmortem was found.

## 6. What Eyeland takes from each of Adam's games

A proposal to argue with, not a decision:

- **Pokemon:** the loop. Beat a creature, get its card, go further.
- **Hearthstone:** the battle. Mana, creatures, spells, readable in seconds.
- **Wizard101:** the feeling. Battles staged in the world, with spectacle.
- **Breath of the Wild:** the island. See something far away, walk to it.
- **Minecraft and Terraria:** resources and crafting, so exploring feeds the deck.
- **EA FC:** squad building. The pleasure of fitting a deck together under constraints.
- **Overwatch:** readable classes with one signature power each.

Only the first three exist in any form today.
