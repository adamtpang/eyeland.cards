import { useState } from "react";
import { IslandScreen } from "./island/IslandScreen";
import { WorldIsland } from "./world/WorldIsland";
function App() {
    const [legacy, setLegacy] = useState(false);
    return legacy ? (
        <>
            <button onClick={() => setLegacy(false)}>
                Return to 3D island
            </button>
            <IslandScreen />
        </>
    ) : (
        <WorldIsland onLegacy={() => setLegacy(true)} />
    );
}
export default App;
