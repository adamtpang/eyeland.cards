// Seeded random source (mulberry32). The C# engine uses System.Random, whose
// sequence cannot be reproduced in JavaScript, so a given seed shuffles
// differently here than in the console harness. Reproducibility within the web
// client is what matters: the same seed always replays the same duel.
export class Rng {
    private state: number;

    constructor(seed: number = Math.floor(Math.random() * 0x7fffffff)) {
        this.state = seed >>> 0;
    }

    /** Float in [0, 1). */
    nextFloat(): number {
        this.state = (this.state + 0x6d2b79f5) >>> 0;
        let t = this.state;
        t = Math.imul(t ^ (t >>> 15), t | 1);
        t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    }

    /** Integer in [0, maxExclusive). */
    next(maxExclusive: number): number {
        return Math.floor(this.nextFloat() * maxExclusive);
    }

    /** Unbiased Fisher-Yates shuffle, returning a new array. */
    shuffled<T>(items: readonly T[]): T[] {
        const out = items.slice();
        for (let i = out.length - 1; i > 0; i--) {
            const j = this.next(i + 1);
            [out[i], out[j]] = [out[j], out[i]];
        }
        return out;
    }
}
