# Ultimate Team club playbook

Written 2026-10-02. The repeatable way to run the club with limited time: measure, then act on
the one thing that pays most. Club data stays in gitignored files, never in this public repo.

## The weekly loop (about 15 minutes of my time, then you play)

1. **Import the club on FUTBIN** (My Club, Import my club; allowed once an hour).
2. **Club report:** `python eafc/sbc/club_report.py` reads it through Helium and writes the
   gitignored `eafc/sbc/club-report.md`: best XI changes, depth per position, weakest starters.
3. **SBC triage:** list the live SBCs, keep only the limited-time ones, score each by ROI.
4. **Solve the keepers** from FUTBIN's PC-cheapest community squads (see the fast path below).
5. **Objectives:** the ones that pay coins, packs or a card you would start, in order of reward
   per minute.
6. **Play:** Squad Battles and anything else you enjoy.

## How decisions are made

**ROI = value out / value in.**

- In: coins for bought cards, plus each club card at its FUTBIN item score (an untradeable spare
  is still worth what it could do in another SBC).
- Out: tradeable packs at expected coin value; untradeable fodder at item score; a card you will
  start at 0.7 x the price of a similar tradeable card.
- **1.0 or more:** do. **0.7 to 1.0:** only for a card you want or a completion. **Under 0.7:**
  skip. Community vote (EasySBC, FUTBIN likes) is the tiebreaker.
- Only limited-time SBCs. Never-expiring upgrades and re-rolls are lotteries; skip them.
- A wanted card (Olise POTM) is judged as a want, not an investment: compare it with its
  tradeable version, whose real cost is only the resale loss (5% tax plus price drop).

**Which player to buy:** whichever replaces the starter with the lowest FUTBIN rating in the
thinnest position, at the best FUTBIN rating per coin. Real output (goals, assists) beats rating
when they disagree.

**When to buy and sell:** prices fall when a promo drops (Friday 6pm UK, 1am Saturday in
Singapore) and fodder rises before big SBCs. Buy into crashes, sell tradeables into spikes.

## Fast path for SBCs on PC

- FUTBIN is set to PC prices in Helium. Console and PC are separate markets.
- `futbin.com/27/squad-building-challenges/Challenges/<id>/<slug>`: requirements, formation and
  every community squad with its console and PC price. Sort by the PC price.
- `python eafc/sbc/read_squad.py <squad url>`: the squad's players, nations, leagues, clubs and
  prices. The squad page shows each requirement as have/need.
- Check the live price as you buy: golds move hourly.

## Limits

- Neither FUTBIN nor EasySBC knows which SBCs you have completed. Only the game does.
- FUTBIN rating is for a player's best role; using it for another slot is an approximation.
- Everything here reads pages only. Nothing buys, lists, moves or submits.
