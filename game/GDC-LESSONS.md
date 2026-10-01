# GDC lessons for Eyeland

2026-09-12. Original synthesis from a focused local reading. **Research completed; all three playtests below are proposals, not run.** No gameplay code, deployment or broad redesign in this pass.

The strongest next experiment is an unaided **first victory → earned Wolf → chosen deck change → useful action in the next fight**. The connected prototype now exists. Its technical acceptance and illustrated cards make this test possible; they do not answer whether the reward creates understanding, attachment or a new tactic.

## Reading coverage and source limits

The private local archive contains 1,783 available transcripts, reported as 13,066,052 words, from 1,916 public Videos-tab uploads. There are 133 gaps and 68 possible early endings. Availability totals are archive metadata, not my reading coverage. I did not read the combined corpus or all GDC talks. Full transcripts remain in `knowledge-private/gdc/`, excluded by both Git and Vercel; exclusions were checked again for this pass.

I searched the index for card games, prototyping, playtesting, onboarding, progression and creature collection. I read three available transcripts end to end, recovering sections truncated in initial tool output, and one focused onboarding excerpt. I also read the handoff, index introduction, provenance headers and the selected entries in the quality report. All four selected entries have `possibleEarlyEnd: false`; that is not a guarantee of completeness.

| Talk | Actual reading | Why selected |
|---|---|---|
| [Hearthstone: 10 Bits Of Design Wisdom](https://www.youtube.com/watch?v=pyjDMPTgxxk) — Eric Dodds | Entire available transcript, 0:04–49:59 final segment | Paper/Flash prototypes, readable cards, onboarding, feedback and player stories |
| [Slay the Spire: Metrics Driven Design and Balance](https://www.youtube.com/watch?v=7rqfbvnO_H0) — Anthony Giovannetti | Entire available transcript including Q&A, 0:05–35:15 final segment | Card roles, persistent versus temporary power, biased metrics and enemy information |
| [Hitchhiker's Guide to Rapid Prototypes!](https://www.youtube.com/watch?v=sYWkiv1hTPM) — speaker introduced as Mark Barrett in the transcript | Entire available transcript, 0:02–25:38 final segment | Testable interactions and scope |
| [The Gamer's Brain, Part 2: UX of Onboarding and Player Engagement](https://www.youtube.com/watch?v=Paf6B1jleCo) | Intro at 0:05; focused continuous excerpt 11:13–20:42; keyword search hits earlier in the talk. Remainder not read. | Divided attention, learning and visible controls |

These four texts are community Whisper transcriptions, with provenance pointing to dklassic/GDC-transcript commit `aa864490ba81ae02da84fe769042ea938e3a73a1`. Audio, slides and footage were not independently checked. Spelling and terms are visibly imperfect. Timestamp links locate the source segments, not independently verified quotations. Descriptions of demonstrations below are the speaker's account, not claims that I watched the footage. Historical design choices in these talks are not claims about current Hearthstone or Slay the Spire features. No direct crafting-economy or cooperative-networking talk was deeply studied; those adaptations have correspondingly weaker support.

**Source** means the speaker's stated experience. **Eyeland inference** means our application, not the speaker's recommendation for this game. Numeric test thresholds below are provisional local decisions, not statistical validation or published research findings.

## Current implementation, checked against source

Read `EYELAND-IDENTITY.md`, `DESIGN.md`, `MASTERPLAN.md`, `ELAN-LEE-LESSONS.md`, current project context and relevant runtime source on September 12:

- `src/Eyeland.Duel/IslandRun.cs` defines four ordered encounters, a seed, exactly 12 owned cards per deck, defeated-creature rewards, and Common/Rare/Epic/Legendary progression. Seed variation changes supporting cards; it is not a walkable procedural island.
- Rewards and resources are derived from cleared encounters. `Resources = Cleared * (Cleared + 1)` gives 2, 6, 12 and 20 cumulative shards. This is an earned-total calculation, **not a spendable crafting ledger**. A real crafting implementation needs expenditure/ownership state and save validation; changing a displayed number would not implement crafting.
- `IslandUI.cs` saves seed, clears and deck through `IslandStorage`/PlayerPrefs and reconstructs collection. It handles invalid saves and explicit reset. `CardVisual.cs` supplies illustrations and inspection; `DuelUI.cs` has a 60-second turn and processes the AI turn before refreshing the display. The visible log retains only the two most recent entries. This is a plausible explanation bottleneck, not a newly observed human failure.
- Current foes share much of their supporting deck and increase health by encounter. Different creature rewards exist; whether each encounter meaningfully teaches a different tactic remains untested.
- Existing September 11 evidence records ten Unity tests, synthetic combat simulations and a native browser reward/deck/reload journey. I did not rerun those tests or conduct a new play session for this research. Neither the 100/100 local technical score nor automated win rates certify human fun or onboarding.
- Separate capture decisions, crafting recipes, character XP/equipment and cooperative questing remain planned. Adam's guaranteed defeated-creature card rewards and four rarities remain requirements.

The earlier Elan Lee note's implementation inventory was accurate to its earlier inspection and is now historical: its missing Epic, rewards, save and timer observations must not be treated as today's gaps. Its proposed tests have not become human results merely because the features were subsequently built.

## Lessons and adaptations

### 1. Define the behavior being tested before expanding the feature set

**Source:** Dodds describes paper experiments that exposed undesirable fortress/hero play, then a Flash prototype that established core mechanics before the production implementation. This is Eric Dodds speaking about work that included Ben Brode, not a Ben Brode presentation. [Paper failures, 3:51–4:53](https://www.youtube.com/watch?v=pyjDMPTgxxk&t=231s); [Flash prototype, 4:53–5:58](https://www.youtube.com/watch?v=pyjDMPTgxxk&t=293s). The rapid-prototyping talk distinguishes building a minimum product from eliciting a needed interaction. [5:57–7:00](https://www.youtube.com/watch?v=sYWkiv1hTPM&t=357s).

**Eyeland inference:** The next milestone should be a player deciding why to replace two cards with the Wolf and then benefiting from that decision. More islands or a recipe database would not answer that question. Use the existing Unity build; no engine switch or prototype restart follows from these accounts.

**With Elan Lee:** This reinforces mastery and fast experiments, but updates the method: the real reward loop is now available, so a paper substitute is unnecessary for testing that loop. Paper remains useful for a new crafting choice. The rapid-prototyping speaker's game-jam advice does not override Adam's commitment to one master game.

### 2. Keep individual actions readable while preserving combinations

**Source:** Dodds describes simplifying turn structure and interactions, but retaining summoning sickness after removing it harmed depth. He presents hero powers and combinations of simple cards as ways to retain tactical choice. [15:35–16:10](https://www.youtube.com/watch?v=pyjDMPTgxxk&t=935s); [19:30–22:41](https://www.youtube.com/watch?v=pyjDMPTgxxk&t=1170s).

**Eyeland inference:** A novice should distinguish cost, attack, health, resting and Rush before being asked to optimize a deck. Preserve the possibility that Rush creates a useful immediate trade; do not remove resting merely to make all cards immediately clickable. Test whether the illustrated card's inspection is discovered and whether its rule predicts actual behavior.

**With Elan Lee:** Simple tools can create mastery through interactions. The source supports checking comprehension; it does not prove that copying familiar card presentation alone establishes Eyeland's identity. The identity still comes from adventure, collection and eventually shared quests.

### 3. Persistent ownership changes which powerful combinations are safe

**Source:** Giovannetti defines balance in terms of each card having a role rather than equal strength. He explains why a rare, difficult-to-assemble combination can be acceptable in a solo roguelike where the player cannot reliably start every run with it. [3:15–5:49](https://www.youtube.com/watch?v=7rqfbvnO_H0&t=195s).

**Eyeland inference:** Once a player owns a Legendary and its partners, rarity no longer makes that combination rare in their future decks. Evaluate repeatable access, setup costs and competing uses of deck slots. Preserve stronger rewards while making them introduce decisions; do not assume a rarity label alone prevents one solved deck from dominating every island. Future party play also needs to test whether one player's combo removes everyone else's meaningful turn.

**With Elan Lee:** This fits earned power plus mastery. It qualifies any blanket appeal to dramatic, rare reversals: Eyeland retains cards between fights and intends cooperative play. No player nerf, equal-power-only progression or randomized capture failure is proposed here.

### 4. A winning-deck statistic can measure survival rather than card strength

**Source:** Giovannetti's Madness example appeared disproportionately in winning decks because it was usually obtained late. Two unusually prolific testers also dominated early aggregate results. He argues for combining metrics with other feedback. [10:25–12:28](https://www.youtube.com/watch?v=7rqfbvnO_H0&t=625s).

**Eyeland inference:** A Warden card will naturally correlate with completed islands because completion awards it. Likewise, Wolf owners have already won once. Compare decision opportunities, experience and encounter stage; do not infer causal card power from ownership plus wins. Record one line per tester as well as per attempt so Adam's many runs do not masquerade as many independent players. Synthetic AI runs test termination and expose possible extremes; they do not represent novices reading unfamiliar cards.

**With Elan Lee:** Observe behavior and hear the player's own explanation. Start with local notes, build fingerprint, seed, deck before/after, encounter and coaching count. A remote analytics service is not required for three to five formative sessions.

### 5. Available information must also be noticed and understood

**Source:** The onboarding excerpt describes players overlooking conspicuous messages while occupied by combat, and distinguishes affordances for action, understanding and perception. [14:27–19:10](https://www.youtube.com/watch?v=Paf6B1jleCo&t=867s); [19:41–20:42](https://www.youtube.com/watch?v=Paf6B1jleCo&t=1181s). Dodds describes short contextual teaching sufficient to enter the game, leaving further learning for play. [22:41–24:50](https://www.youtube.com/watch?v=pyjDMPTgxxk&t=1361s).

**Eyeland inference:** A reward line or hover tooltip being present is not evidence that it teaches. Watch whether the player notices the Wolf, finds it in the collection and understands the exact-12 requirement. A 60-second timer competes with first-time reading; record whether it expires during confusion before deciding on a teaching intervention. Do not remove the game's time-bound combat requirement by default.

**With Elan Lee:** Cold reads are the right test. There is a genuine tension between minimal instruction and insufficient information: teach legal action, not the entire strategy. Do not use the talk's simplified memory-capacity numbers as a universal rule that Eyeland must show exactly three UI elements. Those scientific claims were not independently reviewed here.

### 6. Explain what happened before revealing everything that will happen

**Source:** In Q&A, Giovannetti describes unpredictable enemy moves compounding card randomness and several iterations of enemy intent presentation. [28:06–28:37](https://www.youtube.com/watch?v=7rqfbvnO_H0&t=1686s); [33:15](https://www.youtube.com/watch?v=7rqfbvnO_H0&t=1995s). Dodds discusses directing feedback toward emotionally important moments, including a newly summoned card. [45:14–46:21](https://www.youtube.com/watch?v=pyjDMPTgxxk&t=2714s).

**Eyeland inference:** First test whether a player can reconstruct the AI turn after its synchronous resolution and two-line log. If not, a compact visible action history or paced resolution may solve the problem before adding prediction mechanics. An exact next-move indicator is a substantially different design experiment and could leak hidden-hand information; it should not be inferred automatically from Slay the Spire's success.

**With Elan Lee:** Explainable surprise supports learning. `DESIGN.md` preserves discoverable boss counters: showing past attacks or legal targets does not disclose the counter. Revealing a perfect future answer would change that relationship.

### 7. Put new rewards in service of a player story, with a sustainable production cadence

**Source:** Dodds connects player stories to unexpected combinations and notes how quests and progression screens accumulated around the original simple result screen. [17:11–18:21](https://www.youtube.com/watch?v=pyjDMPTgxxk&t=1031s); [33:59–38:17](https://www.youtube.com/watch?v=pyjDMPTgxxk&t=2039s). Giovannetti praises frequent updates but acknowledges their burden and says he would consider a slower cadence in a future project. [34:15–34:45](https://www.youtube.com/watch?v=7rqfbvnO_H0&t=2055s).

**Eyeland inference:** The desired story is specific: a creature I found supplied a card or ingredient that helped my next encounter. Test one recipe and its reason to adventure before adding several currencies, XP screens and quest notifications. Keep useful changes frequent enough to learn, but do not promise weekly public content or reproduce crunch. Progression and multiplayer remain the destination, not a reason to omit validation of the next step.

**With Elan Lee:** Both sources value stories generated through play. Hearthstone's historical decision to minimize narrative is not a reason to cut Eyeland's RPG quests or responsive world. The crafting proposal below is our inference; these readings do not establish a recipe economy or suitable prices.

## Three prioritized playtests

All are **unrun**. Adam can do a pilot, but as the creator and an experienced card player he is not a fresh onboarding sample. Adam handles invitations personally. Use consented local observation, anonymous tester labels and a separate profile/fixture; preserve real collection saves. A pilot of three to five people is for finding problems, not estimating population retention. Record the unchanged build fingerprint and seed before each condition. No production changes are authorized by this research alone.

### 1. First reward becomes a tactic — highest priority, current build

**Hypothesis:** A new player understands that winning adds the defeated creature to their collection and can choose a useful deck change without designer coaching.

**Setup:** Start a fresh Ember Reach profile. Say only: “Play the expedition. Stop whenever you want.” Let the player win Ashwood, inspect rewards, edit if they choose and enter Moonpool. Do not instruct them to add the Wolf; that would manufacture the outcome. If they cannot reach a reward, record the blocker and optionally use a clearly labeled post-victory fixture for a separate reward-comprehension task, never counted as unaided completion.

**Observe:** Time to first legal play and first win; help requests; timer expiries while reading; reward recall; spontaneous deck edit; cards cut and reason; whether the Wolf was drawn in a usable situation; whether Rush changed a choice; desire to continue. Ask afterward what changed and why. Not drawing the Wolf is “no opportunity,” not proof the mechanic failed; a separate disclosed seeded tactical fixture can isolate comprehension.

**Decision:** Continue to test 2 if at least three of five fresh testers can explain the reward and make an intentional legal deck choice unaided, with at least two observed useful Wolf decisions when opportunities occurred. These are local screening thresholds. Stop and revise the earliest shared obstacle if two testers need the same help. If they deliberately keep their deck for a sound reason, treat that as comprehension, not a failure to obey. If they understand everything but find the reward irrelevant, revise encounter/card payoff rather than add more tutorial text.

### 2. Can the player explain the opponent's turn? — feedback before new combat rules

**Hypothesis:** Important AI actions are being lost in synchronous resolution and the two-entry log; readable action history would improve causal understanding.

**Setup:** In a separate seeded combat fixture, arrange a short opponent turn containing a summon, an attack and a visible board change. Compare the current presentation with a local paper/replay version showing the same actions in order, one at a time. Counterbalance condition order across testers; do not show the same solution twice to the same person and call it a fair comparison. This replay is a mock presentation experiment, not a shipped replay system or animation test.

**Observe:** Before explaining, ask what changed, what caused it, and what response is legal now. Record missed causes, mistaken targeting assumptions, and whether the person can choose a response. Record clarity separately from “looks exciting.”

**Decision:** Prototype a real history/pacing change only if at least two testers miss a consequential cause in the baseline and the staged presentation helps comparable tasks. Stop if the issue is actually unreadable rules, missing hover discovery or target legality. If both presentations are understood, do not add a replay feature merely because the reference game has one. Preserve unknown future moves and discoverable boss counters.

### 3. One recipe creates a reason to adventure — gated by tests 1–2

**Hypothesis:** A visible recipe for a tactically useful card makes players choose an ingredient source for a reason, rather than merely collect a currency number.

**Setup:** Use a disposable paper quest/recipe sheet and manual resource ledger alongside a recorded save fixture. Offer one clearly priced recipe, one short ingredient objective and the option to keep resources. State the mock status explicitly. The authored four-camp route currently cannot establish free route choice; offer two paper destination options for the planning task and label that outcome as mock choice only. Do not call it implemented exploration or resource spending.

**Observe:** Can the player explain what the recipe enables, what ingredient is missing, why they chose a destination and whether the resulting card deserves a deck slot? Is the trip anticipated as a useful goal or described as repetitive toll-paying? Keep time and tactical benefit separate from rarity excitement.

**Decision:** Build the smallest real spending ledger/recipe/quest slice only if at least three of five participants understand the goal and at least two describe a concrete deck use. Stop or change the recipe if two report an understood but uninteresting chore, or everyone regards it as a compulsory upgrade. Do not tune a multi-currency economy from these five observations. Before implementation, specify spend persistence, duplicate crafting, ownership limits and reload behavior; `Resources` is currently derived and cannot simply be decremented.

## Durable decision

Keep the world and collection vision. Use the current illustrated prototype to test the earned-card interaction first. The three deep readings reinforce this choice, but they are developer experience reports, not controlled proof of what will make Eyeland fun. The next research expansion should target crafting economies and cooperative questing only when those are the next concrete design questions; neither was validated by this pass.
