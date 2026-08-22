# JelloApocalypse: "Let's Make a Pokémon Game!" — the full pitch

Source: [youtube.com/watch?v=tGhpDOx0CMk](https://www.youtube.com/watch?v=tGhpDOx0CMk) (2019)
Raw transcript: [`jello-pokemon-pitch-transcript.txt`](jello-pokemon-pitch-transcript.txt) (38.5k chars, pulled via yt-dlp 2026-08-22)

`game/DESIGN.md` cites this pitch in principles 6, 6a, 6b, and 7, but the
source itself was never saved. This is the full thing, structured. Read it
when designing eyeland's wardens, island structure, or progression, since
DESIGN.md only distilled about four ideas out of roughly thirty.

**His own constraints, worth keeping in mind:** a real budget and real
time constraints (no "add 1000 new Pokémon"), it has to stay a genuine
all-ages Pokémon game (no edgy fan-game darkness), and he's deliberately
only talking about **mechanical and structural design**, not creature
designs.

---

## The framing move: design from a thesis

Before any mechanic, he asks what the game is *for*. His example: Breath of
the Wild is built around **exploration and growth** — you explore, clear
shrines, get stronger, and that new strength opens new places, so the loop
feeds itself.

He then names Pokémon's three theses:

1. **"Gotta catch 'em all"** — already done well, he changes nothing.
2. **"Make the player feel like they're on a journey"** — the bulk of the pitch.
3. **"Encourage players to love and befriend their Pokémon"** — saved for the end.

This is the same instinct as eyeland's own build ladder: name what the game
is trying to make the player *feel*, then check every mechanic against it.

---

## Structure: three versions, not two

The single biggest change he proposes. Instead of Black/White, there are
**three versions** — one per starter type — each starting you in a
completely different corner of the region with a different professor.

- Three professors are friendly rivals running a research competition. Each
  entrusts one starter + one Pokédex to one trainer. Most research wins.
- The other two trainers become your **"buds"** (friendly rivals), so you
  only get two per version.
- **Each starting area must be genuinely cool**, so nobody avoids a version
  because its opening is lame. His examples: a fire-themed factory town
  with steel/poison types, a haunted or fairy-tale forest with ghost/fairy/
  dragon types, a desert oasis or a cloud-height waterfall full of bird
  Pokémon.
- Each start sits in its own far corner with **one route in and out**, so
  you get a short linear prologue to teach new players the ropes, while
  veterans still see something new.

---

## The open world: four counties, half the map open immediately

After the **first badge**, the world opens up. The region splits into four
"counties": one per starting area, plus a central county holding the
Pokémon League.

**How he keeps it balanced without walling it off:**

- **Difficulty bands per county.** Your home county is roughly level 5-30.
  The two you didn't start in are ~20-60. The central county starts at
  level 45 minimum. The bands rotate by version so you always begin in the
  easy one.
- **You can walk into the endgame county early and lose.** He wants that
  on purpose: seeing powerful trainers you can't beat yet "gives the player
  something to work towards."
- **An on-screen indicator of the local average Pokémon level**, so you
  instantly know when you're out of your depth.
- **The run mechanic gets a much higher success rate when you're
  underleveled**, so wandering somewhere too hard is survivable.
- **A high-level trainer blocks the route exit**, so you can't just sprint
  through the whole game while fleeing every encounter.
- **Fast travel very early** (a Fly-like item, a transit pass, a borrowed
  professor's bird), so players aren't scared to explore far.

---

## Research quests: optional, and they visibly change your town

Every town has an optional research quest for your professor — a small
dungeon or scavenger hunt. They're never mandatory, but:

> the more research quests that you completed, the more the professor
> enhances your starting town using the information you give them

Your home town grows, the local economy improves, and everyone likes you.
He calls this "a nice concrete way to mark the player's progress" and a
natural excuse to hand out rewards.

## The map as a JRPG Metroidvania

Most of the world is open, but specific dungeons and secret areas stay
locked until you get a particular item or Pokémon — night-vision goggles
from the fire-starter's factory letting you cross a pitch-black forest near
the grass start, or an Ampharos/Illumise to light the way.

- **Good TMs and stat items live in thematic dungeons.** Want Earthquake?
  It's in the earthquake cave.
- **Some dungeons end in a Pokémon boss** (totem-style, or a Snorlax) with
  a real reward. He explicitly prefers Pokémon bosses over trainer bosses.

---

## Gyms: the richest section

### Gym leaders scale to your badge count

Taken from the manga and Pokémon Origins: gym leaders keep **multiple teams
at different strengths** and field one based on how many badges the
challenger holds. One badge might be two level-10 Pokémon; six badges could
be five Pokémon in the high 30s or low 40s.

The point is that a gym you skipped early doesn't become trivial later, and
**you can't grind past a gym** — it levels with you.

**Important limit he draws:** only gym leaders scale. He names Pokémon
Crystal Clear, which scales *every* trainer to badge count, and says he
really doesn't like that.

### Gyms are themed by mechanic, not by type

His flat verdict on type gyms: "Pokémon has done this to death, I think
there is nothing more that can be done with it."

Instead:

| Gym | The mechanic |
|---|---|
| **Sound Gym** | Pop idol named Melody; Whismur, Jigglypuff, Chatot, Chingling, Chimecho, all using Uproar, Sonic Boom, Sing |
| **Weather Gym** | A weather lady in a TV station running Sunny Day/Solar Beam, Rain Dance/Thunder combos |
| **Friendship Gym** | Every Pokémon evolves via friendship (Blissey, Umbreon); leader is an intimidating-looking biker who's actually a sweetheart, running a max-friendship Crobat with Return; the gym is a biker bar full of bros |
| **Baby Pokémon Gym** | exactly what it says |
| **Status Effect Gym** | his own note: "this is the worst one, everybody hates it" |
| **Gender Gym** | trainers split male-only/female-only Pokémon; the leader is a double battle against a lovey-dovey couple with matching pairs (Miltank/Tauros, Illumise/Volbeat); bring a genderless Pokémon to cheese it |

### The hard counter is real but discoverable

The Sound Gym's counter is the **Soundproof** ability, which blocks all
sound-based moves. But you don't learn that from the gym. You learn it from
a guy on a bench outside, and the Pokémon that has it is in a specific cave
far away.

> there's still a hard-counter strategy, but they kinda gotta work for it
> if they wanna cheat their way through

This is DESIGN.md principle 6's source.

### Ten gyms, but you only need eight

His stated ideal (he admits it's more work and less likely to ship):

- **Skip the two you hate.** If a gym is miserable for you, just don't do it.
- It creates real player-to-player conversation: "which gym did you skip?"
- **If you show up to a late gym already holding eight badges**, the leader
  goes "oh, you got all eight, huh? I'm gonna fight you for real" and
  becomes a bonkers-hard superboss.
- Fighting every gym leader at full strength becomes the **postgame
  challenge** after the Elite Four.

### Gyms can be skipped via side quest

A gym leader who's also a firefighter: help him rescue a Pokémon from a
burning-building dungeon and he hands you the badge outright, with an open
invitation to fight him anyway for a TM. Another escape hatch for a gym
that's blocking a player, and more optional content.

---

## Story events, and a world that notices

**Event flags appear and disappear.** Leaving the fire town, you'll meet
the water bud one way or the other — but *where* is up to you. Some flags
are permanently missable: an event with the grass bud vanishes once you
pass level 35 or five badges. Over a playthrough you should hit your buds
3 times minimum, 6-8 if you catch every opportunity.

### Team Bad Guy: keep the motivation small

His diagnosis of why Pokémon villains fail: the writers think they need
"BIG JRPG VILLAINS WHO WANT TO BLOW UP THE WORLD." They don't.

> As a player, I want to collect Pokémon and be friends with them. Team Bad
> Guy wants to steal Pokémon from me, and treat them badly for financial
> gain. That's it! They're jerks!

That's why Team Rocket works and Team Flare doesn't — Team Flare can't even
say why they're Team Flare. His flavor pick: **mafia-themed**, violin cases
that open into a Kricketune, cement shoes courtesy of a Conkeldurr.

### The bank heist: the anti-Skyrim example

The clearest statement of the whole "world reacts" idea, and DESIGN.md
principle 6b's source:

- Playing fire version, there's a bank in an early town and rumors of a
  heist. Get there under three badges and you stop it.
- **Never go?** They succeed — and now every Team Bad Guy goon has potions
  bought with the stolen money. The game is genuinely harder.
- **Playing grass version?** You start too far away to make it. NPCs tell
  you the fire bud stopped it. Instead, *you* get a version-exclusive
  riverboat casino fight. In the other versions, NPCs mention the grass bud
  handled the riverboat.

His contrast case, stated bluntly: Skyrim, where you can end the civil war
and nothing changes — same camps, same enemies, guards just say "the Civil
War sure is over!" His word for that is "soulless."

### "Jerk": the rival who becomes the final boss

One Team Bad Guy member is your personal rival (a Blue, a Silver, "the one
you wanna punch in the face"). He starts as a flunky and climbs the ranks
every time you meet him — and he's the **final boss**. He calls it "kinda
dumb and cheesy" and likes it anyway.

### Charm over plot: hire writers

He doesn't want a sweeping storyline in a game this open. He wants **charm**,
and says the radical ask is literally "hire a writer, maybe two or three,"
plus a good localization team.

His model is **Trails in the Sky** — ugly, mediocre gameplay, but every NPC
is likable enough that you want to help all of them; he says its first
chapter is carried almost entirely by dialogue and characters. His read on
Pokémon's own writing is that only some Mystery Dungeon games got it right,
and probably by accident.

---

## Thesis three: love and befriend your Pokémon

**The problem with Pokémon Amie / Refresh:** the affection system is
"completely busted." Feed a Pokémon cupcakes for 25 minutes and it gets
dodge, crit, and experience bonuses that turn a benchwarmer into an
unstoppable killing machine. He says he *stopped petting his Pokémon*
because it would ruin the game's challenge — a mechanic actively punishing
you for engaging with it.

**His fix:** rebalance it down, or move the bonuses onto a **friendship
bracelet** item. Two or three exist, each hidden in a genuinely difficult
dungeon. Then an overpowered favorite is a *reward you earned*, not an
arbitrary consequence of petting.

---

## Mechanical nitpicks

- **No forced tutorials.** Just ask "do you already know how to catch a
  Pokémon?" and skip it. ~70% of players already know.
- **Cut legendaries.** They're not special anymore, their story role is
  always tacked-on. Starters become the box mascots instead ("they'll sell
  more plushies"). Keep at most one, in a cave, story-irrelevant, optional
  — and make it **gimmicky and weird rather than strong**.
- **Difficulty options at the start.** Normal and a Challenge/Master mode,
  with higher trainer levels and bigger teams. His shot at Black and White:
  Hard Mode was Black-exclusive, Easy was White-exclusive, and both had to
  be *unlocked by beating the game* — "who plays a game on Normal Mode and
  is then like, oh, I'm glad I unlocked Easy Mode so I can play the whole
  game I just beat again but easier?"
- **Delete IVs entirely.** They make some Pokémon objectively better than
  others and push grinding, which is against the spirit of the series.
- **Add a Battle Simulator** instead of a Battle Frontier: build any team
  from scratch with any moves, abilities, and items, in a virtual space, on
  a console in the Pokémon Center, available before your first badge. Real
  competitive play with zero grinding.
- **Let people rename traded Pokémon.** The restriction prevents nothing.
- **Drop the traded-Pokémon EXP boost.** It existed to sell link cables;
  Wonder Trade made it meaningless.
- **Zoom the camera out.** The 3D overworld shows too little at once.

---

## What eyeland.cards has already taken, and what it hasn't

**Already in `game/DESIGN.md`:**
- Principle 6 — bosses themed by mechanic, with a discoverable hard counter
- Principle 6a — bosses scale to the player's real progress, not fixed level
- Principle 6b — the world remembers what you did (the bank heist)
- Principle 7 — companions as personality, not stat blocks

**Real ideas not yet absorbed anywhere**, each a live candidate for v2
Island and beyond:

- **Design from a stated thesis**, then check every mechanic against it.
  Directly applicable to writing v2 Island's vertical-slice sentence.
- **Difficulty bands by region + an on-screen local level indicator +
  a generous escape hatch when underleveled.** A concrete, proven-in-theory
  answer to how an open island archipelago stays fair without invisible walls.
- **Optional quests that visibly upgrade your home base.** A progress marker
  that isn't a number going up.
- **Metroidvania gating via items/companions**, with thematic rewards in
  thematic dungeons.
- **Skippable content with a "you got all eight? then I'm going all out"
  reward for completionists.**
- **Missable, appearing-and-disappearing event flags** as a reason to
  replay.
- **Small, legible villain motivation** instead of a world-ending plot.
- **Charm as a budget line.** He'd rather hire writers than add systems.
- **Powerful items as earned rewards, not grind side-effects** (the
  friendship bracelet fix). Maps directly onto DESIGN.md principle 11,
  strength from beating things, not from a menu.
- **A sandbox mode available from minute one** (his Battle Simulator) so
  players can explore deckbuilding without grinding for cards first —
  arguably eyeland's own Quick Play button, already shipped, taken further.
