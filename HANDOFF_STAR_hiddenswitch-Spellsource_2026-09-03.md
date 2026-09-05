# Handoff: learn from hiddenswitch/Spellsource

Written 2026-09-03 by the Aether root session, using the github-star-match skill. This
repo was on Adam's GitHub stars; it was reviewed against eyeland.cards, this file was
written, and the star was removed. Popularity is not evidence of fit; the verdict
below is about a concrete local seam or the lack of one.

- **Verdict:** `defer`. No usable license (NOASSERTION), so no code can be copied; the design (server-authoritative rules engine, card definitions as data, replays) is still worth studying by reading, not lifting.
- **Local owner repository:** `eyeland.cards`
- **Local evidence paths:**
  - eyeland.cards/CLAUDE.md
  - eyeland.cards/DESIGN.md
  - the C# combat engine (real, playtested per this session's tier list)
- **Upstream:** https://github.com/hiddenswitch/Spellsource
- **Reviewed commit:** `437ea74` on `develop` (2026-07-30)
- **Upstream layout at that commit:** .github,.yarn,bin,buildSrc,docs,gradle,spellsource-cards-git,spellsource-cards-private,spe
- **License conclusion:** NOASSERTION. A license is granted, or the design is re-derived from public docs with zero copied code.
- **Smallest experiment, or deferred trigger:** Trigger: eyeland.cards needs a networked multiplayer rules server. Then open an issue upstream asking for a license, or treat docs/ as read-only design reference.
- **Validation before adoption:** run the local project's own tests after any change, keep the reviewed commit pinned above, and preserve upstream license notices if any file is copied.

Boundary, per the skill: this analysis authorizes no installation or code change.
Implement only when Adam asks in that project's own session. Do not add the upstream
repo as `kin` in repos.yaml; it is a reference, not a Repo Rep.
