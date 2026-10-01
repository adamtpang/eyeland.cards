# Three.js island prototype — September 24, 2026

Run `npm install` then `npm run dev -- --host 127.0.0.1` from game/web. Open http://127.0.0.1:8080/.

Default entry is now a Three.js/WebGL2 island. WASD/arrows move relative to the orbit camera, Shift runs, Space jumps, drag orbits, wheel zooms, and clicking terrain walks toward it (direct steering, not pathfinding). Approach the Cinder Wolf and press E or Challenge. The existing web duel handles the fight. A first victory grants one Wolf and two shards; Cards lets you replace the final loan-deck card with it. The new save key is eyeland.three.island.v1; existing web and Godot saves are separate and untouched. Malformed new saves are preserved, with writes blocked.

Implemented: procedural island, water animation, trees, cottage, dock, distant floating islands, visible animated avatar, companion, ground/tree/house collision, camera follow/orbit, one real encounter, 30-card legal loan decks, earned-card equip, first-clear reward and browser persistence. More opens earlier web expedition tools.

Scope: a stylized functional comparison prototype. No Tidewater code/assets were copied. No photorealistic ocean, WebGPU effects, swimming, crafting, multiplayer or complete Godot battle migration. This uses the older TypeScript card catalog/art and battle UI; the native 100-card art and newer interaction fixes are not all ported. Direct click movement may stop at obstacles. Desktop keyboard/mouse is the current target. Position resets on reload; rewards/equipped card persist.

Verification: TypeScript check and production build passed. Existing engine suite 81/81, 1,400 terminating simulations, plus 300 starter simulations passed. Added world regression checks cover legal 30-card decks before/after equip, earned-only equip, duplicate victory, defeat preservation, save roundtrip and malformed saves. Browser rendered the island and initial UI. See continuation entries for further UI checks. No 60 FPS measurement or human enjoyment claim.

Browser interaction check: clicked terrain to walk from spawn into Wolf proximity; camera followed and Challenge appeared. Clicked Challenge and verified mulligan, 30 health and 30-card opening counts. Retreat reached Defeat/Continue. The browser tab disappeared before the Continue click; the return transition and a full victory have not been verified through native browser input. Reward/equip persistence is covered by the pure logic regression, not an asserted full UI journey.
