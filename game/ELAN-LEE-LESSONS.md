# Elan Lee lessons for Eyeland

2026-09-11 · Original synthesis from the YouChop handoff. **Research complete; playtests proposed, not run.**

The most useful next experiment is small: defeat a creature, receive that creature's card and a resource token, change the deck, and try the card in another fight. Does the player discover a useful tactic and want another attempt? This tests Adam's progression promise without waiting for the entire island implementation.

## Evidence and boundaries

Read all 23 available timestamped English-caption transcripts from the September 11 extraction of @ElanLee's public Videos tab, plus its index, manifest and quality report. The extraction reports 69,307 words across 25 listed uploads; two uploads lack English captions. Shorts, streams, interviews on other channels and paid material are outside the corpus. The compilation repeats earlier videos, so it is not independent corroboration.

Captions have not been checked against the audio or visuals. They visibly mistranscribe names and technical terms. Links below point to the start of the relevant caption passage; descriptions of physical demonstrations reflect what the speaker says, not an independent visual inspection. Sales claims, legal anecdotes and universal-sounding marketing claims are his accounts, not verified facts or predictions for Eyeland. No raw transcripts are copied here; the private source location remains in `HANDOFF_FROM_YOUCHOP.md`.

**Source** below means Lee's stated advice or described experience. **Adaptation** means our inference for this digital game. Numerical playtest thresholds are proposed local decision rules, not Lee's recommendations or statistical validation.

## What exists in Eyeland now

Read against `MASTERPLAN.md`, `DESIGN.md`, `game/README.md` and the current source files on September 11:

- `unity/Assets/Scripts/Game/GameFlow.cs` connects deckbuilder → duel → deckbuilder. It does not connect island encounters or rewards.
- `DeckBuilderUI.cs` offers Quick Play and manual deck selection; minimum 12 cards, up to two copies except one Legendary. Its stale ten-card comment is superseded by the data-driven pool described in the game README. Recreating the builder does not receive the previous deck.
- `DuelUI.cs` resolves the AI turn synchronously and refreshes afterward. Its result button says **Build a new deck**. This is code evidence of possible explanation/replay friction, not a usability finding from a new test.
- `src/Eyeland.Duel` implements combat, card effects and logging. The console supports seeded play. `data/cards.json` already includes Rush, Taunt, conditional draw and other interacting tools; content scarcity is not yet demonstrated as the bottleneck.
- `Cards.cs` currently defines Common, Rare and Legendary. Adam's required **Epic** tier is a real implementation gap. No integrated creature-card/resource reward system or turn timer was found in the inspected Unity flow. This does not invalidate separate browser experiments; they do not establish Unity integration.
- Older root status documents lag behind the code. The game README's August 25 simulation reports 56.1% first-player wins in 1,000 same-deck AI games; neither this nor the earlier 71–73% result proves current human balance. No simulations or gameplay tests were rerun for this synthesis.

The vision stays intact: one master game, themed procedural islands, time-bound combat, and **defeat creatures → earn their own cards plus crafting resources → improve the deck → challenge stronger creatures**. Common, Rare, Epic and Legendary remain the four intended tiers. Crafting recipes, quantities and repeat rewards remain undecided; multiplayer stays at v4.

## Principles worth applying

### 1. Earned power should also create room to learn

**Source:** Lee defines a repeatable core activity that players can improve at. His failed board-game prototypes gained meaningful planning through tools and information, especially revealing upcoming movement cards. More drawing and discarding alone had not supplied that planning. [Core loop, 1:02](https://www.youtube.com/watch?v=qq2z27lOO9U&t=62s); [missing mastery and information, 5:06–7:42](https://www.youtube.com/watch?v=FiLc0RQMPx0&t=306s).

**Adaptation:** Evaluate a creature reward by the new decision it enables, alongside its power. Cinder Wolf's existing Rush can change when the player answers an enemy creature; Tide Guard's Taunt can change which board pieces survive. Those are concrete changes to play, not just collection completion. Test what the player plans and does after earning a card. A higher win rate caused only by larger stats would demonstrate power progression, but not mastery.

**Boundary:** Stronger rewards are Adam's requirement. This adds a way to assess their usefulness; it does not replace progression with purely cosmetic or equal-power rewards. Legendaries still need build-around identity under Design Principles 4–5.

### 2. Make surprising success explainable

**Source:** Lee describes surprise as delightful, discovered through experimentation, and not guaranteed every time. His Jenga example is an unexpectedly successful extraction, rather than the inevitable collapse. [Discovery and fragile success, 8:09–9:43](https://www.youtube.com/watch?v=qq2z27lOO9U&t=489s).

**Adaptation:** Aim for a player discovering that two understandable effects combine to save a losing board. Preserve clear rule text and visible resolution. A combo can depend on drawing its pieces, timing and the opposing board while resolving consistently whenever its conditions hold. “Fragile” need not mean adding a random failure chance to a correctly executed move.

**Boundary:** Do not turn this into hidden rules, random prize substitutions, or secretly adjusted odds. The source's dramatic physical board transformation is not evidence that an extra screen animation will create strategic discovery in a digital game.

### 3. Protect the encounter arc while allowing procedural variety

**Source:** Letting players place every board effect undermined the intended difficulty arc; players optimized their own advantage. Lee retained interaction but took responsibility for the underlying board structure. His movement deck also made a changing risk legible. [Escalating tension, 0:32 and 3:10](https://www.youtube.com/watch?v=izaVRwcMJPM&t=32s); [board structure failure, 0:01–1:32](https://www.youtube.com/watch?v=u7WMiwsDhSc&t=1s).

**Adaptation:** Give island generation constraints: an opening camp usable by the starting deck, access to useful earned options before the warden, and a warden that tests the island's learned tactic. Vary encounters and layout inside those constraints. Audit seeds for impossible starts and trivial finishes rather than assuming randomness supplies replayability.

**Boundary:** This is not a proposal to hand-author every island, rig close finishes, or secretly scale away earned strength. His preference for last-place reversals suits his race game; automatic leader punishment could undermine Eyeland's mastery and progression.

### 4. Test teaching without the designer supplying missing rules

**Source:** Lee's instructions worked when he explained them in person but failed when sent out alone. He recommends observing cold reads, recording where help is needed, and testing revisions with new people. He separates starting instructions from a reference guide, and explicitly permits a first strategic tip. [Cold testing, 2:04–5:08](https://www.youtube.com/watch?v=W6C6iajrVjI&t=124s); [strategy and optional reference, 19:25–23:30](https://www.youtube.com/watch?v=W6C6iajrVjI&t=1165s).

**Adaptation:** Quick Play should lead to enough understanding to take a turn: win condition, pips, playing a card, choosing a target, attacking and ending the turn. Put keyword details where the player encounters them. When someone asks why they cannot attack a caster through Taunt, record that exact question rather than assuming a larger glossary solves it. The synchronous AI resolution also deserves observation: can someone explain what just happened?

**Boundary:** Teach basic tactics without revealing every warden counter. Design Principle 6 reserves specific counters for discovery; a generic Taunt example does not spoil those discoveries. A familiar tester can test revisions but cannot become a first-time reader again.

### 5. Leaving and returning are part of the game

**Source:** Reboxing lowers the effort required for the next session. His examples use labels, easy storage and assembly that does not require reconstructing the original retail display. His Bears Versus Babies instructions failed for returning players once the original packets had been mixed. [Reboxing goal, 0:00–2:32](https://www.youtube.com/watch?v=V-RNRQiygI8&t=0s); [returning-player failure, 24:00–26:01](https://www.youtube.com/watch?v=W6C6iajrVjI&t=1440s).

**Adaptation:** For a digital game, the analogues are keeping the chosen deck, understanding what was earned, resuming a run and finding a short rules reminder. The current end screen returns to a freshly constructed deckbuilder; first measure whether that blocks a desired replay. Mock a same-deck retry before adding a save system.

**Boundary:** A manually restored prototype state is not persistent storage. Do not claim saved loot or a resumable island until implemented and tested. Do not force an immediate replay; a player who wants to leave should be able to leave comfortably.

### 6. Keep the theme; loosen unproven implementations

**Source:** Lee usually prefers establishing mechanics before theme, but acknowledges a successful theme-first exception in Survivor. Temporary labels and reused materials let him test before final art existed. His prototype archive preserves versions and lessons. [Mechanics/theme tradeoff, 8:10–10:46](https://www.youtube.com/watch?v=DZQpF__JoMo&t=490s); [fast prototypes and version preservation, 12:11–16:16](https://www.youtube.com/watch?v=kYgdO1p4rCU&t=731s).

**Adaptation:** Eyeland already has an intentional fantasy and a working engine. Preserve both. Use a paper encounter card and a manual reward ledger to test the missing progression connection. Archive the deck, encounter setup, rules version and observed result so the next iteration answers the same question.

**Boundary:** No engine switch, new theme, or restart is implied. The existing paper island experiment's Power abstraction cannot establish whether actual Rush, Taunt or spell sequencing creates a satisfying reward payoff. Use real rules when that is the question.

### 7. Separate interest, understanding and enjoyment

**Source:** Lee describes Happy Salmon's relaunch as largely changing packaging, instructions and handling rather than gameplay. His box-design advice gives different surfaces different jobs: attract attention, convey the experience, and help owners find the game again. [Happy Salmon changes, 2:34–4:37](https://www.youtube.com/watch?v=BhcTDa1v2ek&t=154s); [box roles, 1:04 and 5:07–8:12](https://www.youtube.com/watch?v=7iDqFn0SwHY&t=64s).

**Adaptation:** Distinguish failure to launch the build, failure to understand a turn, and failure to enjoy an understood duel. Eventually demonstrate one actual creature-to-card payoff in the landing-page preview. Until it exists, describe it as planned. The desired message is concrete: defeat a creature and use its card in your next fight.

**Boundary:** Presentation is not proof the loop works. No new marketing or website work is required to run the three tests below.

### 8. Let the player have a story worth telling

**Source:** Lee connects discovery to a feeling of personal ownership. He also explicitly credits The Oatmeal's established audience for the initial crowdfunding surge. Those are different contributions. [Discovery, 4:08–5:42](https://www.youtube.com/watch?v=dc2asKyOLm0&t=248s); [existing audience, 37:37–38:38](https://www.youtube.com/watch?v=dc2asKyOLm0&t=2257s).

**Adaptation:** A useful outcome is a player recounting a specific earned-card decision: which creature they beat, what they changed, and how it helped. Ask for that recollection before explaining what the design was meant to do. It supports meaningful attachment better than asking whether the game “has depth.”

**Boundary:** This is a qualitative learning signal, not a viral-growth forecast. We do not inherit his audience, budgets or physical stunt expertise.

## Three prioritized small playtests

All three are **unrun proposals**. Adam can pilot them, then manually arrange additional testers. No recruiting messages are sent by an agent. Use anonymous participant labels in notes. Counts below are directional gates for another iteration, not population-level evidence. Freeze each variant during a run; record any rescue or rule change and start a new version afterward.

### P1 — Does a creature's card change the next fight?

**Hypothesis:** A player can recognize the reward as the defeated creature and use its ability to form a new plan in the next fight.

**Small setup:** One facilitator-run session, capped at 20 minutes, first with Adam to debug the procedure, then two independent card-game players. Use two short encounters with the existing combat rules. Represent travel and rewards with paper; use the console/Unity combat where setup permits, or manually resolve the exact existing rules. This is a progression mock, not an integrated v2 build.

Before testing, freeze a legal 12-card-or-larger starting deck that excludes Cinder Wolf, and an opening encounter featuring that creature. After victory, award **that Cinder Wolf card plus one paper crafting-resource token**. One card/token is a fixture, not a final economy decision. The second encounter should contain an opportunity for Rush to matter. Let the player choose whether to add the reward or exchange a deck slot while retaining ownership. Do not offer a random replacement reward or forced deletion. Respect existing copy limits.

**Observe:** Can the player identify what they earned without coaching? Do they explain a new plan, choose a slot, and try the card when a legal opportunity appears? Record the board situation, decision and result. End with a neutral replay choice and ask what they would change next time.

**Decision:** Continue toward a thin reward integration if both independent players recognize the creature-to-card relationship and each articulates or demonstrates a new use. If a card is never drawn, or a game bug/teaching failure prevents play, mark the strategic result inconclusive and use a disclosed fixed-hand scenario next. If both understand the rule but see no reason to use the reward, change the encounter/reward pairing first. Stop after 20 minutes or player discomfort; do not add content to rescue the session. A win alone is insufficient evidence.

### P2 — Can a new player take a turn without coaching?

**Hypothesis:** A compact goal-first introduction plus local keyword help gets a newcomer to a deliberate action quickly.

**Small setup:** Three people who have not seen this build, separately, up to ten minutes each. Let them open Quick Play with only the current interface and one short candidate instruction card. Start with the actual win condition, then pips and actions. Offer a basic Taunt example as optional help. Observe silently; supply a rescue only to end a prolonged block and count it as assisted. Use new participants after rewriting the introduction.

**Observe:** Time from playable screen to first intentional legal action; requests for help; confusion about targeting, Rush/Taunt, ending a turn and the AI's last action. At a natural pause, ask how they win and why they chose that move. Do not label aimless clicking as understanding.

**Decision:** Advance this introduction if at least two of three act within two minutes, describe the goal correctly and finish their first turn without verbal rescue. If the same misunderstanding occurs twice, change that wording or affordance before adding tutorial steps. If automated resolution is the obstacle, inspect event presentation rather than blaming the rules. An inexperienced test participant is not proof the combat is bad.

### P3 — Does the end screen preserve the desire to try again?

**Hypothesis:** Keeping the previous deck and making the next action clear reduces avoidable restart effort.

**Small setup:** Two returning testers, after a completed duel, five minutes each. Record the current result → builder experience. Compare it with a paper end-screen mock offering **Retry with this deck / Edit this deck / Done**. Restore the deck manually for the mock; disclose that this is simulated. Reverse order across testers, and note the learning effect. After a brief break, ask them to locate the prior deck and the rules reminder without a verbal recap.

**Observe:** Whether they actually choose another attempt, why they stop, unnecessary setup actions, deck reconstruction mistakes and time to the next playable state. Distinguish lack of interest from lack of time. Do not pressure them to replay.

**Decision:** A candidate rematch change earns implementation only if both can recover the intended deck and next action within 30 seconds in the mock, and observed baseline friction is removed. If they can navigate but do not want another duel, investigate the duel's decisions rather than polishing the end screen. If state is missing, log it as a persistence gap; never infer that the mock proves saving works.

## Conflicts and material deliberately not imported

- **Players as entertainment:** Lee's social-interaction goal fits party games. Solo Eyeland needs its AI, encounters and discovery to provide entertainment now. His preference for groups that already play together is not a reason to exclude solo newcomers from testing. Co-op remains later.
- **Children's games:** Accessible decisions and observable learning transfer; hidden hands, elimination and difficulty preferences from games for four-year-olds are not universal rules for Eyeland. [Children's criteria, 2:03–8:10](https://www.youtube.com/watch?v=9m-d7U-i8g8&t=123s).
- **Publishing and physical logistics:** His crowdfunding-then-publisher preference concerns manufactured tabletop games. Royalty examples, pallets, packaging, magnets and retail shelf economics do not decide a Unity game's commercial model. No crowdfunding, paid service or publishing change follows. [Publishing preference, 5:35–6:35](https://www.youtube.com/watch?v=FhCzsqSTI_U&t=335s).
- **Physical spectacle and ARGs:** Do not reproduce physical transformation mechanisms, staged intimidation, hidden devices, pickpocket stunts or expensive campaigns. Extract discovery and delivery lessons only. “Rule of seven,” sales rankings and anecdotal causal claims are not empirical guarantees.
- **Old paper test:** `research/PAPER-PROTOTYPE-v2-island.md` predates the own-creature-card/resource requirement. Its add-or-remove rewards, third-copy rewards and scalar Power system are historical experimental rules. Its simulations establish properties of that abstraction, not enjoyment or balance of current combat. They must not silently become v2 requirements.
- **Motivation and curiosities:** The graduation speech supports persistence after failure. Office objects demonstrate personal curiosity and archiving. The FBI/Strut anecdote and UFO kite upload add no necessary Eyeland mechanic. A compilation and trailers are repetitions, not additional independent tests.

## Complete reading coverage

Every available transcript was read end to end. This table records its disposition rather than forcing each upload into a new rule.

| Video | Use in this synthesis |
| --- | --- |
| [Resurrecting a Dead Game](https://www.youtube.com/watch?v=BhcTDa1v2ek) | Separate gameplay from handling and communication failures. |
| [Exploding Kittens Co-Creator teaches you how to make games!](https://www.youtube.com/watch?v=6KagILs6xRk) | Compilation; repeats design, instructions and marketing material. |
| [“You are all about to fail”](https://www.youtube.com/watch?v=pOpH1X__u7c) | Persistence context; no imported legal or career claims. |
| [Are You Designing Your Game Backwards?](https://www.youtube.com/watch?v=DZQpF__JoMo) | Mechanics-first preference and theme-first exception. |
| [What Makes a Good Board Game for Children](https://www.youtube.com/watch?v=9m-d7U-i8g8) | Observable learning; audience-specific limits. |
| [Why is no one talking about REBOXING?!](https://www.youtube.com/watch?v=V-RNRQiygI8) | End-of-session and return friction. |
| [I’ve Been Making Board Games for 10 Years](https://www.youtube.com/watch?v=HTwiMJBHqzA) | Series trailer; no independent evidence. |
| [OFFICE TOUR (2025)](https://www.youtube.com/watch?v=xYZGthXyhm8) | Prototype archive at 20:03; curiosities otherwise nonessential. |
| [WILD Marketing Success Stories](https://www.youtube.com/watch?v=dc2asKyOLm0) | Discovery/ownership and existing-audience caveat; no stunts. |
| [Unboxing the Final Version](https://www.youtube.com/watch?v=O13lubknZiY) | Final rules, reference separation, distinct decks and comeback incentives. |
| [Pop-Up Books are Cool](https://www.youtube.com/watch?v=qWR2HQvApEc) | Physical iteration and cost/usability tradeoffs; no popup mechanic proposed. |
| [This Design Isn’t Working](https://www.youtube.com/watch?v=FiLc0RQMPx0) | Planning tools and distinction between novelty and mastery. |
| [Why Board Game Boxes Matter More Than You Think](https://www.youtube.com/watch?v=7iDqFn0SwHY) | Communication by stage; physical distribution specifics excluded. |
| [This Might Fail](https://www.youtube.com/watch?v=u7WMiwsDhSc) | Preserve designed pacing within player agency. |
| [Fixing a Broken Game](https://www.youtube.com/watch?v=izaVRwcMJPM) | Tension plus mastery; distinguish randomness from usable information. |
| [I'm Happy I failed](https://www.youtube.com/watch?v=8kk-rs8c60I) | Modular prototypes and rapid revision. |
| [Board Game Instructions](https://www.youtube.com/watch?v=W6C6iajrVjI) | Cold onboarding, contextual language, reference and returning users. |
| [THE BEST WAY TO PUBLISH A BOARD GAME](https://www.youtube.com/watch?v=FhCzsqSTI_U) | Physical publishing model; not adopted for Eyeland. |
| [PROTOTYPES](https://www.youtube.com/watch?v=kYgdO1p4rCU) | Cheap editable components and preserved versions. |
| [How YOU Can Make a Board Game](https://www.youtube.com/watch?v=qq2z27lOO9U) | Core loop, complications, discovery and replay. |
| [Hi I'm Elan](https://www.youtube.com/watch?v=ifgHfqGgePs) | Channel introduction; no separate design evidence. |
| [Why I got interrogated by the FBI for playing a game](https://www.youtube.com/watch?v=szonRRta4U0) | Personal Strut anecdote; no gameplay change. |
| [UFO Kite Flying – Phase 1](https://www.youtube.com/watch?v=tSObxYVW-bc) | Music/incidental speech; no design lesson inferred. |

Not read because captions were unavailable: [Nara Deer Chases Japanese Business Man](https://www.youtube.com/watch?v=mfbLSF7KG_M) and [Buckyballs – 3 simple faces](https://www.youtube.com/watch?v=bY1c8fZGN8E). No claims about their content beyond the supplied titles.

**Next:** Run P1 as a disclosed manual progression test. Save the frozen setup, observations, unresolved questions and one chosen change. A synthesis is complete; a fun island is still something to demonstrate through play.

## September 12 implementation-status clarification

The implementation inventory above records an earlier September 11 inspection. Later that day, the connected expedition, Epic tier, victory rewards, local saves, timer and creature portraits were implemented. Preserve this note as research history; consult [GDC-LESSONS.md](GDC-LESSONS.md) and [PLAY-EMBER-REACH.md](PLAY-EMBER-REACH.md) for the newer implementation baseline. The original human playtests remain unrun.
