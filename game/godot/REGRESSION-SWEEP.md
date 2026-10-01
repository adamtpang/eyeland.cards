# Core regression sweep

2026-09-20. Headless Godot runs; this does not establish rendered UX or full parity.

| Test | Initial result |
|---|---|
| check | 328 assertions but invalid legacy fixture emitted script errors; corrected fixture rerun clean 328/328 |
| openings | Initial match driver failed; updated for choices, rerun clean 348/348 |
| constructed | CONSTRUCTED: 25 / 25 passed |
| auras | AURAS: 15 passed; 0 failed |
| silence | SILENCE: 8 passed; 0 failed |
| deathrattle | DEATHRATTLE: 8 / 8 passed |
| death_choice | DEATH CHOICE: 5 / 5 passed |
| discover | DISCOVER: 7 / 7 passed |
| choose_one | CHOOSE ONE: 4 / 4 passed |
| counterspell | COUNTERSPELL: 6 / 6 passed |
| secret_choice | SECRET CHOICE: 12 / 12 passed |
| secret_interrupt | SECRET INTERRUPTION: 8 / 8 passed |
| weapons | WEAPONS: 13 / 13 passed |
| hero_freeze | HERO FREEZE: 7 / 7 passed |
| freeze | FREEZE: 12 passed; 0 failed |
| combo | COMBO: 8 / 8 passed |
| overload | OVERLOAD: 9 / 9 passed |
| draws | DRAWS: 7 passed; 0 failed |
| lifesteal | LIFESTEAL: 8 passed; 0 failed |
| poisonous | POISONOUS: 4 / 4 passed |
| windfury | WINDFURY: 5 / 5 passed |
| stealth | STEALTH: 6 / 6 passed |
| spell_damage | SPELL DAMAGE: 6 / 6 passed |
| shield | DIVINE SHIELD: 7 / 7 passed |
| ai | AI DECISIONS: 16 / 16 passed |
| placement_ai | PLACEMENT AI: 4 / 4 passed |
| collection | FOUNDATIONS COLLECTION: 466/466 passed |

## Integration rerun after feedback pacing

2026-09-20: rendered `journey.gd` 14/14 and `openings.gd` 348/348; headless `constructed.gd` 25/25 and `match_invariants.gd` 160 games / 34,634 side states. All exited successfully with no reported script errors. Journey uses isolated saves, a seeded winning fixture and a disclosed earned-card draw swap. Both full-match drivers exercise UI callbacks, not entirely physical mouse input. Within-action visual sequencing remains incomplete.

## September 21 presentation integration sweep

31 engine suites passed with no reported script errors. Of 13 rendered suites, eight passed initially; five used fixed or immediate presentation timing assumptions and failed after animation sequencing changed. Updated aura/Silence, draw journey, opponent feedback, spell feedback and weapon UI checks to wait for actual feedback/result completion with a five-second bound. All five reruns passed; no engine changes were made in this sweep.

Raw results: `../evidence/parity-engine-sweep-2026-09-21.json`, `../evidence/parity-rendered-sweep-2026-09-21.json`, and `../evidence/parity-rendered-rerun-2026-09-21.json`. Initial failures remain recorded. This is 44 passing suites after corrections, not a full parity claim. Fresh first/second-player complete journeys and the remaining presentation requirements still need final verification.

September 21 follow-up: rendered full journey 14/14 and openings/second-player match 348/348 passed. Constructed/expanded diagnostics 26/26 passed. Refreshed screenshot inspection found damage-number occlusion; raising number overlays above creature feedback passed 11 spell-feedback checks. Full journeys preceded this isolated overlay/diagnostics change.

## Final presentation-fix integration (September 21)
After weapon snapshots, Secret markers and Discover gating: rendered journey 14/14 and openings/complete second-player match 348/348 passed, followed by constructed 26/26 and audio 13/13. No reported script errors. Tests use isolated saves and the previously disclosed journey fixtures. Refreshed battle frame inspected at 1280x800. Runtime cue preview exported for listening review; feedback pending. This does not claim an unaided human match or subjective audio approval.
