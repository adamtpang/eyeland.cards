# Sokpop: creative process and lessons for Eyeland

Researched September 20, 2026. This is a sourced synthesis of public first-person interviews and Sokpop's announcement, not a transcript. No game code or scope commitments changed in this research pass.

## What their process actually looks like

**Practice finishing small games.** Tijmen describes a game-jam background: they made many small projects but often left them unfinished outside jams. Turning those projects into releases became a viable creative/business direction. In 2021, subscribers also wanted a slower cadence and bigger games. [Tijmen interview, Game Pilgrim, January 2021](https://gamepilgrim.com/2021/01/20/developer-interview-sokpop-collective/)

**There is no single mandatory creative recipe.** Rubna describes starting from a character, while Aran is drawn to technology and mechanics. They prioritize enjoying creation, and became more willing to finish quickly or abandon projects when motivation disappeared. Rubna contrasts a roughly 700-hour project that disappointed commercially with a subsequent three-week game that people liked. That is an anecdote, not a guarantee about effort or sales. [Aran/Rubna interview, Game Developer, March 2023](https://www.gamedeveloper.com/design/indie-troupe-sokpop-collective-on-releasing-100-games-in-five-years)

**The collective's output was not one person's output.** They describe primarily individual projects under a shared subscription. Patreon supported experiments, while individual games could also sell separately. They report no formal commercial-validation process; personal interest matters and demand can surprise them. [Sokpop interview, Pantaloon](https://www.pantaloon.io/news/sokpop-interview)

**Let ideas develop before choosing one.** Rubna describes keeping several ideas in mind and choosing the one with the clearest vision; others draw from films, games or mechanical experiments. [Direct interviews, PC Gamer, 2020](https://www.pcgamer.com/somehow-the-sokpop-collective-has-released-two-games-a-month-for-two-years/)

**They revised the deadline model.** Sokpop announced on November 23, 2022 that the monthly-game requirement would end in December. The new goal was another hundred games with project-appropriate deadlines, more collaboration and aftercare. Treat the FAQ's monthly-release wording as historical. [Sokpop's own announcement](https://www.patreon.com/sokpop/posts/100-sokpop-games-75013736)

Their later interview identifies missing control explanations, camera issues, localization and controller support as costs of rushing. Repeated releases created learning opportunities; they did not make every release polished. [Game Developer interview](https://www.gamedeveloper.com/design/indie-troupe-sokpop-collective-on-releasing-100-games-in-five-years)

## Proposed Eyeland adaptation — our process, not a claimed Sokpop formula

Keep the larger Eyeland vision. Develop it through small playable adventures with clear endings and one interesting question each.

1. **Pick a feeling and one hook.** Example: winning the Crab should make the player feel stronger because its card enables a useful decision in the next fight.
2. **State the smallest playable experiment.** Two encounters, one earned card, one deck change. Use the current island and battle engine rather than rebuilding infrastructure.
3. **Make it playable before expanding content.** It needs a beginning, understandable controls, a challenge, a reward and a next use for that reward.
4. **Play it together.** Observe where Adam hesitates, which choices feel obvious, and whether he voluntarily wants another fight. Automated tests cannot answer these questions.
5. **Keep, reshape or shelve the experiment.** An uninteresting card interaction can change without abandoning Eyeland. Record the observation and decision.
6. **Polish what the player repeatedly touches.** Movement, camera, jumping, card readability, targeting, feedback and saves deserve attention in every small build.
7. **Mark a playable version complete.** Maintain a working build and a short change note before starting the next experiment. No public-release schedule is promised here.

### Candidate experiments

| Experiment | Question | Small boundary |
|---|---|---|
| Crab earns its place | Does the captured card change how the next fight is played? | One additional encounter and a distinct use for the existing reward |
| A tempting overlook | Is walking, running and jumping enjoyable without a battle reward? | One optional route and a clear destination; no new movement system |
| Two cards work together | Can Adam recognize and enjoy a small compounding card package? | Two synergistic cards and one opponent; use already-supported effects first |

These are proposals, not implemented features or proven outcomes. Preserve the full Hearthstone-parity checklist, but test fun between parity milestones instead of making completion of every mechanic a prerequisite for playtesting. Third-person exploration, the starter companion, four rarities, resources/crafting and eventual co-op remain the game's direction.

## Source limits

The official [2019 GDC session](https://www.gdcvault.com/play/1025669/One-Year-of-Sokpop-Games) was located through Sokpop's FAQ. Only its listing/abstract was reviewed here; do not claim the talk was watched or its transcript read. Cadence changed over time, and a collective release interval should not be treated as the development time of every individual game. The proposed Eyeland workflow is an adaptation, not a documented studio-wide Sokpop checklist.
