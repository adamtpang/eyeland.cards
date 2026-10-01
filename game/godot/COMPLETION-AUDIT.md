# Constructed battle completion audit

2026-09-21. Agreed classic-style constructed battle goal complete. This audit preserves the requested classic-style constructed scope and distinguishes rule tests from complete presentation evidence.

## Evidence inspected

- `PARITY.md`, `REGRESSION-SWEEP.md`, and the September 21 engine/rendered JSON results in `../evidence/`.
- `battle.gd` turn, damage, aura, weapon, death-batch and Secret continuation paths.
- `duel_board.gd` hero/weapon/Secret/hand rendering and Discover modal construction.
- `main.gd` ordered effect schedule, action handlers and result transition.
- `creature_feedback.gd` state snapshots, live and temporary portraits, row layout playback.
- Focused tests for death batches and interrupted Secret attacks were read, not merely counted.

## Requirement assessment

| Requirement | Evidence | Assessment |
|---|---|---|
| 30 HP, 2-mana powers, 10 mana, saved 30-card deck | constructed checks; reward/save/reload journey | Implemented and tested; preserve saves |
| First player, opening hands, mulligan, Coin, turn flow | openings 348 checks including second-player full match | Implemented and tested; current final journey rerun recorded separately |
| AI targeting, trades and placement | ai, placement_ai, 160-game invariants | Tactical behavior tested; competitive strength is not established or required for this prototype |
| Deathrattle and event batches | deathrattle, death_batch, death_choice, weapon_deathrattle | Named interactions tested, including paused choices and queued trigger preservation |
| Shield, Rush, Charge, Stealth, Freeze, Windfury, Poisonous, Lifesteal, Spell Damage | named engine suites; focused rendered status/attack tests | Implemented; evidence spans rules and selected UI interactions |
| Auras and friendly targeting | auras, aura_timing_ui, friendly_targets, placement_ai | Implemented and tested |
| Weapons and hero attacks | weapons, weapon_keywords, weapon_ui, hero_freeze | Implemented and verified, including scheduled equip/break/replacement (weapon_timing_ui 10/10; weapon_replacement_ui 9/9) |
| Secrets | secrets, counterspell, secret_interrupt, secret_choice and rendered reveal tests | Implemented and verified; secret_marker_ui 8/8, reveal_ui 10/10, secret_choice_ui 8/8 |
| Discover and Choose One | discover, choose_one, choice_ui, discover_ui, offturn_choice/timeout | Implemented and verified, including presentation gate, off-turn clock and interrupted attack continuation |
| Combo, Silence and Overload | named engine and rendered suites | Implemented and tested |
| Simultaneous hero death/draw | draws and rendered draw_journey | Implemented and tested; no duplicate reward settlement |
| Dragging, targeting, history and hand usability | friendly_targets, weapon_ui, full_hand_ui, history_ui | Implemented with focused rendered evidence |
| Ordered combat, stats and layout feedback | effect/status/layout/movement tests | Implemented with focused timing/layout tests; identified weapon, marker and modal defects closed; complete journeys pass after fixes |
| Sound | audio tests and rendered timing checks | Cue generation/mute/timing tested; Adam approved the runtime sound preview on September 21 |
| Complete rendered matches | journey and openings full-match drivers | Automated callbacks plus selected mouse input; not an unaided human playtest |

## Completion decision

Adam responded “yeah i like them!” to the six-cue runtime preview on September 21. This closes the remaining listening review. All named requirements above have implementation and verification evidence; no required work remains in the agreed battle scope. Prior blocked/pending entries below are historical and superseded by this decision.

This approval covers the sounds, not an unaided full-game playtest or competitive balance. The complete match evidence remains automated UI journeys with disclosed fixtures. No production code changed during closure, so the recorded post-fix regression results still apply.

The four implementation/integration audit items are closed by the specific evidence below: weapon snapshots, Secret markers, Discover gating, and post-fix full rendered journeys. No further unspecified cross-mechanic sweep is required merely because older checkpoint prose calls for one. Any new concrete failure must still be fixed.

## Historical audit follow-ups

No missing classes, expansions, matchmaking, RPG systems, unique art for every card, competitive balancing or subjective fun are being added as completion gates for this battle goal. Existing artwork limitations and human-playtest status remain disclosed product limitations.

Current-build rerun during this audit: rendered `journey.gd` passed 14/14 with no reported script errors. This covers the reward/deck/reload loop after moving-effect fixes; second-player rerun is deferred until the remaining presentation changes land.

Weapon timing follow-up: scheduled equip/durability/destruction is implemented; both-side native Spear timing 10/10, rendered drag/click weapon 13/13 and engine weapons 13/13 pass. Replacement-specific visual ordering remains to be verified before closing item 1.

Weapon item 1 verified: `weapon_replacement_ui.gd` passes 9/9 for both-side old-weapon retention, removal before replacement, fresh durability, once-only Armor Deathrattle presentation and cancellation on leaving. Weapon Deathrattle engine checks pass 6/6. Together with prior equip/swing/break tests this closes the identified weapon presentation gap; the overall goal remains active for items 2–5.

Secret marker item 2 verified: engine events now carry before/remaining Secret lists and Secret plays publish state snapshots. Markers retain the displayed list until reveal playback, preserve hidden opponent tooltips through redraw, and return on replay. Rendered `secret_marker_ui.gd` passes 8/8 using a real opponent Secret/attack/replay with a synthetic preceding reveal to exercise queue timing. `secret_reveal_ui.gd` passes 10/10. Engine secrets 8/8, interruption 8/8, Secret choice 12/12 and Counterspell 6/6 pass. This closes marker timing only; the choice presentation gate and final integration/audio review remain open.

Choice gate item 3 implemented and verified: player Discover offers and input now wait for the ordered presentation queue and live effects to finish. Off-turn choice countdown starts only when offers are available. Own-turn expiry defers automatic selection until presentation is ready. Rendered secret_choice_ui passes 8/8, including hidden modal/countdown during reveal, refusal of early callback, physical mouse selection and interrupted attack resumption. Offturn_choice 4/4, offturn_timeout 5/5, discover_ui 5/5 and choice_ui 6/6 pass. Older fixtures now wait for the actual presentation boundary instead of assuming immediate choice after death/summon. Items 4 (final integration) and 5 (audio review) remain open.

Post-choice-gate integration: rendered journey.gd passed 14/14 on the current build, covering the isolated reward/deck/reload loop. Fresh battle.png was visually inspected: hero/power portraits, dimmed unaffordable hand cards and damage text over a departing portrait are visible without clipping at 1280x800. This is a selected frame, not whole-match visual observation. Audio.gd passes 13/13; export_audio_review.gd generated ../evidence/battle-cues-review.wav from the runtime generator at its -12 dB volume (play, attack, Secret, victory, defeat, draw). Listening feedback has been requested from Adam; no listening verdict is inferred from the export or tests.

Second-player final integration also passed 348/348 on the current build; constructed 26/26 passed. Item 4's full-match reruns are complete. Selected battle-frame inspection is recorded above; human playtesting remains distinct. Listening review is pending Adam's response to the runtime audio preview. A final reconciliation of the checklist against this evidence is still required before closing the goal.

Goal status: blocked pending audible-review feedback after the same outstanding review persisted across three goal turns. The implementation and recorded test results remain unchanged. This status does not assert missing playback functionality or completed subjective review. Resume after feedback on the exported runtime cues.

Resumed audit: added direct coverage for own-turn expiry while a queued Secret reveal precedes Discover. offturn_timeout.gd now passes 9/9: hidden offers remain unselectable after expiry, early callback is refused, and after reveal the first offer is selected and the turn passes without stalling. This adds missing direct evidence to the gate claim; no production behavior changed. Listening feedback remains unreceived.
