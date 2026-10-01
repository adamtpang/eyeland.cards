# Play the starter island

From `C:/Users/adamp/Aether/eyeland.cards/game/web`:

```powershell
npm run dev -- --host 127.0.0.1
```

Open **http://127.0.0.1:8080/** locally. A development server was left running on that address during this handoff. This is not a public deployment.

1. Choose a class and element, then **Begin at home**.
2. Use the movement buttons, or click the map and use arrows/WASD. Water blocks movement. Interactions appear when within one tile of a landmark.
3. Visit family, then head east toward the crossed swords. Choose **Encounter: Resin Crab**.
4. Confirm or replace your opening cards. Click affordable cards to play; choose targets when asked. Minions usually rest before attacking. Click a ready minion then an enemy to attack. **End turn** lets the AI act.
5. After a win or retreat choose **Continue**. Rest at the campfire to recover health; visit the lookout for the chapter hook.

The starter deck contains exactly five cards. The four elemental starters are placeholder variants with the same battle ability. Normal fatigue applies when the small deck runs out. Evolving companions, mastery/fizzle and advanced world systems are documented designs, not implemented features.

The story sketch keeps progress only while it remains open. Reloading or choosing **Ember Reach & practice** ends that session. The existing expedition's browser save and its 12-card editor are separate and preserved. No purchase or reset of existing data is needed to try this slice.

Checks: `npm test`, `npm run typecheck`, `npm run build`. See [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) for exact verification and limits.
