import { useEffect, useRef, useState } from "react";
import { Vector3 } from "three";
import { DuelScreen } from "../duel/DuelScreen";
import { CardFace } from "../duel/CardView";
import { CardSet } from "../engine/engine";
import { buildClassDeck } from "../engine/constructed";
import { Rng } from "../engine/rng";
import { createWorld, ground } from "./scene";
import "./world.css";
import {
    decodeJourney,
    journeyDeck,
    settle,
    equip,
    type Journey,
} from "./progress";
const KEY = "eyeland.three.island.v1";

function load(): { journey: Journey; error: string } {
    try {
        const raw = localStorage.getItem(KEY);
        if (!raw)
            return { journey: { won: false, equipped: false }, error: "" };
        const data = decodeJourney(raw);
        return { journey: data, error: "" };
    } catch {
        return {
            journey: { won: false, equipped: false },
            error: "Save could not be read. It will not be overwritten.",
        };
    }
}
export function WorldIsland({ onLegacy }: { onLegacy: () => void }) {
    const [initial] = useState(load);
    const [journey, setJourney] = useState(initial.journey);
    const [notice, setNotice] = useState(initial.error);
    const [mode, setMode] = useState<"world" | "battle" | "cards">("world");
    const [near, setNear] = useState(false);
    const [error, setError] = useState("");
    const host = useRef<HTMLDivElement>(null);
    const position = useRef(new Vector3(0, ground(0, 8), 8));
    const [fight, setFight] = useState(0);
    function persist(next: Journey) {
        setJourney(next);
        if (initial.error) return;
        try {
            localStorage.setItem(KEY, JSON.stringify(next));
        } catch {
            setNotice(
                "Storage unavailable. Progress is kept for this session.",
            );
        }
    }
    useEffect(() => {
        if (mode !== "world" || !host.current) return;
        try {
            return createWorld(host.current, position.current, setNear, () => {
                setFight((v) => v + 1);
                setMode("battle");
            });
        } catch (e) {
            setError(`The 3D renderer could not start: ${String(e)}`);
        }
    }, [mode]);
    const withoutWolf = journeyDeck(journey);
    if (mode === "battle")
        return (
            <DuelScreen
                key={fight}
                fixedClass="wizard"
                playerDeck={withoutWolf}
                enemyDeck={buildClassDeck("fighter", new Rng(74))}
                enemyName="Cinder Wolf"
                enemyHealth={30}
                playerHealth={30}
                seed={431 + fight}
                onEnd={(won) => {
                    if (won && !journey.won) {
                        persist(settle(journey, true));
                        setNotice(
                            "Cinder Wolf collected · +2 ember shards. Open Cards to add it to your deck.",
                        );
                    } else
                        setNotice(
                            won
                                ? "Victory! First-clear reward already collected."
                                : "Back safely. Your cards are safe—try again when ready.",
                        );
                    setMode("world");
                }}
            />
        );
    return (
        <main className="ey-world">
            <div className="ey-canvas" ref={host} />
            <header className="ey-top">
                <div>
                    <span className="ey-brand">
                        eyeland<span> . cards</span>
                    </span>
                    <small>EMBER REACH · CHAPTER ONE</small>
                </div>
                <nav>
                    <span className="ey-shards">✦ {journey.won ? 2 : 0}</span>
                    <button
                        onClick={() =>
                            setMode(mode === "cards" ? "world" : "cards")
                        }
                    >
                        {mode === "cards" ? "Return" : "Cards"}
                    </button>
                    <button title="Earlier web prototypes" onClick={onLegacy}>
                        More
                    </button>
                </nav>
            </header>
            <section className="ey-quest">
                <small>YOUR EXPEDITION</small>
                <h1>
                    {journey.won ? "A new friend." : "Beyond the familiar."}
                </h1>
                <p>
                    {journey.won
                        ? "Make room for Cinder Wolf in your deck."
                        : "Follow the sandy path into the grove."}
                </p>
                <span>
                    {journey.won
                        ? "✓ Cinder Wolf discovered"
                        : "◇ Find the Cinder Wolf"}
                </span>
            </section>
            {notice && (
                <button
                    className="ey-notice"
                    onClick={() => setNotice("")}
                    title="Dismiss"
                >
                    {notice} ×
                </button>
            )}
            {near && mode === "world" && (
                <button
                    className="ey-encounter"
                    onClick={() => {
                        setFight((v) => v + 1);
                        setMode("battle");
                    }}
                >
                    <small>FIRE · WILD CREATURE</small>
                    <strong>Cinder Wolf</strong>
                    <span>
                        <kbd>E</kbd>{" "}
                        {journey.won
                            ? "Battle again"
                            : "Challenge · earn its card"}
                    </span>
                </button>
            )}
            <footer className="ey-controls">
                <span>
                    <kbd>W A S D</kbd> Move
                </span>
                <span>
                    <kbd>Shift</kbd> Run
                </span>
                <span>
                    <kbd>Space</kbd> Jump
                </span>
                <span>Click to walk · Drag to look · Scroll to zoom</span>
            </footer>
            {error && (
                <section className="ey-modal">
                    <h2>3D unavailable</h2>
                    <p>{error}</p>
                    <button onClick={onLegacy}>
                        Open the earlier web game
                    </button>
                </section>
            )}
            {mode === "cards" && (
                <section className="ey-collection">
                    <div className="ey-collection-head">
                        <div>
                            <small>YOUR JOURNEY</small>
                            <h2>Cards & companions</h2>
                            <p>
                                30-card loan deck · 30 health · 2-mana hero
                                power
                            </p>
                        </div>
                        <button onClick={() => setMode("world")}>
                            Back to island
                        </button>
                    </div>
                    <div className="ey-reward">
                        <CardFace card={CardSet.byId("cinder-wolf")} />
                        <div>
                            <h3>
                                {journey.won
                                    ? "Your first wild card"
                                    : "Waiting in the grove"}
                            </h3>
                            <p>
                                {journey.won
                                    ? "Rush gives your new companion an immediate attack against a minion."
                                    : "Defeat Cinder Wolf to collect its card and two ember shards."}
                            </p>
                            <button
                                disabled={!journey.won || journey.equipped}
                                onClick={() => {
                                    persist(equip(journey));
                                    setNotice(
                                        "Cinder Wolf added to your 30-card deck.",
                                    );
                                }}
                            >
                                {journey.equipped
                                    ? "In your deck"
                                    : journey.won
                                      ? "Equip · replace final loan card"
                                      : "Not collected yet"}
                            </button>
                            <p className="ey-fine">
                                {journey.won
                                    ? "First-clear rewards are saved in this browser."
                                    : "The starter deck is borrowed for this prototype."}
                            </p>
                        </div>
                    </div>
                    <div className="ey-deck">
                        {withoutWolf.map((c, i) => (
                            <div key={i} title={c.text}>
                                <span>{c.cost}</span>
                                {c.name}
                            </div>
                        ))}
                    </div>
                </section>
            )}
        </main>
    );
}
