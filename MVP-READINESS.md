# Eyeland local MVP readiness — 2026-09-11

Scope fixed before implementation: Unity solo desktop prototype; a seeded island of three creature camps and a warden, real timed card duels, creature-card/resource rewards, owned-card deck edits and saved local progress. No accounts, purchases, multiplayer, crafting recipes or production deployment. Browser storage is device/origin specific. Fun and a 20-minute duration require human playtests and are not certified by automated checks.

Baseline: 0/100 evidenced this revision (existing engine is present; journey untested). Working tree includes pre-existing changes. Target: local WebGL build of game/unity. Auth category redistributed to core (+10) and persistence (+5), as no identity or network service exists.

| ID | Criterion | Weight | Status | Required evidence |
|---|---|---:|---|---|
| C1 | Four seeded, differentiated encounters launch real engine duels | 10 | pass | runtime journey + seed test |
| C2 | Win grants the defeated creature and resources exactly once | 10 | pass | win/re-entry tests + runtime reward |
| C3 | Earned cards can change the next actual duel deck | 10 | pass | edit/start journey |
| C4 | Timed turns, loss retry and island completion work | 10 | pass | timer/loss/completion evidence |
| U1 | First screen explains objective, controls and save scope | 5 | pass | rendered inspection |
| U2 | Navigation supports island, deck, duel and results | 5 | pass | ordinary controls journey |
| U3 | Rewards and locked camps are understandable | 5 | pass | rendered inspection |
| P1 | Reload retains seed, victories, inventory, resources and deck | 10 | pass | save roundtrip + runtime reload |
| P2 | Invalid save recovers visibly without silent overwrite | 5 | pass | corrupt save test |
| P3 | Duplicate rewards and illegal decks are rejected | 5 | pass | game/island-checks.txt; deterministic progression checks |
| P4 | New expedition requires deliberate confirmation | 5 | pass | UI test |
| A1 | Desktop 1280x720 and 1920x1080 controls remain readable | 5 | pass | rendered inspection |
| A2 | Keyboard navigation and focus on primary actions | 5 | pass | keyboard journey |
| O1 | Reproducible local build and launch instructions | 5 | pass | fresh build/launch |
| O2 | Save failures visible, retry supported, no fatal runtime errors | 5 | pass | failure injection + logs |

Production: not deployed. Human enjoyment/onboarding playtests remain separate required product validation before broader release.

## Iteration 1

Source implementation complete; **5/100 evidenced**, all UI/build-dependent criteria still untested. `dotnet run --project game/tests/IslandChecks/IslandChecks.csproj` passes ownership/reward/illegal-deck checks and 400 terminating actual-engine simulations. Editor 6000.5.7f1 executable was missing; restoring the same version and WebGL module via Unity CLI. No graphical readiness claim yet.

## Iteration 2

All **10/10 Unity PlayMode tests pass** (`game/island-test-results.xml`, `game/island-tests.log`). These include a complete four-encounter journey using actual UI handlers and actual engine combat, editing earned cards into each following duel, plus saved expedition reconstruction. Recovery tests use dedicated `eyeland.tests.*` PlayerPrefs keys and delete those fixtures afterward. They do not overwrite the real expedition key. Pointer/browser evidence is still pending, so these tests alone do not establish WebGL readiness.

The journey caught an existing missing `UseHeroPower` branch in the Unity AI turn loop; that branch and the player's neutral power control are now implemented and retested. Editor and WebGL support are restored in the user-owned runtime documented in game/LOCAL-UNITY-RUNTIME.md. First WebGL compilation is running.

## Final verification: 100/100 for the declared local desktop prototype scope

Baseline 0; intermediate 5; final 100. This is technical acceptance using complementary evidence, not human enjoyment, a complete native four-fight playthrough, production readiness or bug-free software.

Build ember-reach-v1, UTC 2026-09-11T06:56:51Z, wasm SHA256 4DFF621EF4CB11647C0A7F8C942A4917C7751896CA1572A75E8CBCEA4D4D6E6E. Served and manifest verified at http://127.0.0.1:8765/. Source sync passes. Final Unity XML reports 10 passed, 0 failed at 07:04:54Z. The working tree includes unrelated pre-existing changes; this is a build fingerprint, not a clean commit claim.

Evidence directory: game/evidence/ember-reach-2026-09-11/.

- C1/C4: game/island-test-results.xml and IslandFlowTests.cs cover all four real-engine duels through actual Unity UI handlers, rewards, deck changes, completion, timer expiry with a pending target and loss. Native browser play separately observed automatic expiry, retreat, retry, first victory and next encounter. The full four-fight journey was automated in Unity, not completed through browser pointer input.
- C2/C3/U2: Native Helium mouse input won Ashwood (first-victory.png), earned two Wolves and two shards, removed two Riptides and added two Wolves (deck-earned.png), saved, reloaded, and started Moonpool. earned-in-duel.png shows the earned Wolf drawn in that actual next duel. No injected gameplay state or JavaScript button activation was used for this journey. Unity tests supplement duplicate-grant and next-deck assertions.
- U1/U3/A1: island-final-1280.png, island-final-1920.png, deck-final.png, reloaded.png and next-duel.png show controls, instructions, local-save scope, rarity/reward labels, locked encounters and readable desktop layouts. Camp label clipping was fixed and the WebGL build refreshed.
- P1: reloaded.png retains seed -299258, 1/4 cleared and two shards; deck-reloaded.png retains two Wolves, zero Riptides and 12 cards. Actual next-duel draw verifies use. Reconstruction after each of four clears also passes Unity tests.
- P2/P3/P4: Dedicated eyeland.tests.* fixtures test corruption preservation, confirmed recovery, illegal decks and duplicate rewards. Native reset-confirm.png shows the second confirmation; Cancel preserved progress. Real user saves were not overwritten by fixtures.
- A2: Native Enter activates deck Cancel, result Return and the selected unlocked encounter; keyboard-return.png, keyboard-island.png and keyboard-start.png. Primary actions have selected-state feedback. This does not certify screen-reader support or full keyboard-only combat.
- O1/O2: Fresh WebGL build, HTTP launch, fingerprint above and build/play scripts. Injected save failure and retry pass Unity tests. browser-events.json has no Runtime.exceptionThrown. Nonfatal Unity warnings concern unsupported FSR postprocessing under software-rendered Helium and deprecated manual filesystem synchronization; gameplay and save/reload pass. A cancelled request during reload is recorded. This is not a warning-free console claim.

The isolated Helium QA profile was used for the final journey. Early rapid automated clicks were unreliable; held native input and rendered-state checks resolved test harness timing. Failed automated attempts and synthetic win rates are not human balance feedback.

Remaining product validation: Adam's first unaided playtest, time to first win, reward comprehension, whether deck changes create a new tactic, and desire to replay. Resources accumulate; crafting recipes, walkable overworld, multiplayer, cloud saves and public deployment remain outside this prototype scope.

### Creature visual pass verification (2026-09-11)

Final WebGL build: 2026-09-11T07:53:20Z; wasm SHA256 ECD6CCE78291B1BCE8A5A2789DF3F94F76FF02C087849371CCD39BA0BE50FF5B. This supersedes the earlier build fingerprint. Build succeeded; the ten existing Unity PlayMode tests passed with CardVisual integration before the final log-line/status-label layout adjustment. Final browser verification used native Helium input: persisted deck loaded, portrait hover inspection, summon Glowing Ember, end turn, select attacker and target face. Opponent health fell from 19 to 18 on summon and to 17 after the attack. Inspected 1280x720 and 1920x1080. Evidence: game/evidence/card-art-2026-09-11/{wolf-inspect,final-board,final-target,final-attack,final-1920}.png. Final events contain no Runtime.exceptionThrown or console error. The combat log now displays the two most recent lines to fit its smaller region. Full rules remain available through hover/focus inspection; spells retain an element-colored SPELL visual. The prior full progression tests remain complementary evidence; this presentation pass did not repeat an entire native four-fight expedition. Server remains at http://127.0.0.1:8765/. Refresh an already-open game to load the new build; completed progress is preserved, unfinished fights restart.
