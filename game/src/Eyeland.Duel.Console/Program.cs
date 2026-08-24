using Eyeland.Duel;

int? seed = null;
var seedArgIndex = Array.IndexOf(args, "--seed");
if (seedArgIndex >= 0 && seedArgIndex + 1 < args.Length && int.TryParse(args[seedArgIndex + 1], out var s))
    seed = s;

if (args.Length > 0 && args[0] == "--simulate")
{
    var rounds = args.Length > 1 && int.TryParse(args[1], out var n) ? n : 100;
    Simulate(rounds);
    return;
}

PlayInteractive(seed);
return;

// ---------------------------------------------------------------------
// AI-vs-AI headless simulation: proves the engine is deterministic and
// terminates, and doubles as a balance-testing tool once decks diverge
// past the symmetric v0 starter deck.
// ---------------------------------------------------------------------
static void Simulate(int rounds)
{
    int aWins = 0, bWins = 0, draws = 0;
    var turnCounts = new List<int>();

    for (var i = 0; i < rounds; i++)
    {
        var state = NewGame();
        TurnEngine.RunGame(state, new GreedyAI("Player A"), new GreedyAI("Player B"));
        turnCounts.Add(state.TurnNumber);

        if (state.Winner == state.A) aWins++;
        else if (state.Winner == state.B) bWins++;
        else draws++;
    }

    Console.WriteLine($"Simulated {rounds} AI-vs-AI games (symmetric starter deck, both sides go first equally often is NOT modeled — A always opens):");
    Console.WriteLine($"  A (on the play) wins: {aWins} ({100.0 * aWins / rounds:F1}%)");
    Console.WriteLine($"  B (on the draw) wins: {bWins} ({100.0 * bWins / rounds:F1}%)");
    Console.WriteLine($"  Draws (double fatigue-out): {draws}");
    Console.WriteLine($"  Average game length: {turnCounts.Average():F1} turns (min {turnCounts.Min()}, max {turnCounts.Max()})");
}

static DuelState NewGame(int? seed = null)
{
    // Same seed -> same two shuffled decks, so a run can be replayed from turn 1 with a
    // longer command sequence each time — a stand-in for a live REPL when driving this
    // over piped stdin (no way to react mid-process without one).
    const int OpeningHandSize = 3;

    var rng = seed is { } s ? new Random(s) : new Random();
    var a = new Caster { Name = "Player A", Deck = Shuffled(CardSet.StarterDeck(), rng) };
    var b = new Caster { Name = "Player B", Deck = Shuffled(CardSet.StarterDeck(), rng) };

    var openingLog = new ResolutionLog();
    a.DealOpeningHand(OpeningHandSize, openingLog);
    b.DealOpeningHand(OpeningHandSize, openingLog);

    var state = new DuelState { A = a, B = b };
    state.Log.AddRange(openingLog.Lines);
    return state;
}

// Fisher-Yates, not OrderBy(_ => rng.Next()) -- the sort-by-random-key shuffle it
// replaced isn't proven uniform (ties in the random keys resolve via the sort's own
// tie-breaking, which biases the result). Cherry-picked from CardHouse's
// CardGroup.Shuffle (github.com/pipeworks-studios/CardHouse), reimplemented here
// rather than pulled in wholesale since that project's shuffle lives on a MonoBehaviour
// CardGroup while this one is a plain method on a portable, engine-agnostic List<T>.
static List<CardDef> Shuffled(List<CardDef> deck, Random rng)
{
    var result = new List<CardDef>(deck);
    for (var i = result.Count - 1; i > 0; i--)
    {
        var j = rng.Next(i + 1);
        (result[i], result[j]) = (result[j], result[i]);
    }
    return result;
}

// ---------------------------------------------------------------------
// Interactive human-vs-GreedyAI console duel.
// ---------------------------------------------------------------------
static void PlayInteractive(int? seed = null)
{
    var state = NewGame(seed);
    var human = new ConsoleController();
    var ai = new GreedyAI("the Warden");

    Console.WriteLine("=== eyeland.cards — v0 Duel ===");
    Console.WriteLine("Commands: p <handIndex> [targetBoardIndex] | a <yourBoardIndex> [enemyBoardIndex] | end | help | quit\n");

    TurnEngine.RunGame(state, human, ai);

    Console.WriteLine();
    Console.WriteLine(state.Winner is null
        ? "Both casters collapse from fatigue at once. It's a draw."
        : state.Winner == state.A
            ? "You win! The Warden falls."
            : "You lose. The Warden stands over you.");
}

sealed class ConsoleController : IPlayerController
{
    public string Name => "You";

    /// <summary>
    /// Hearthstone's own turn budget. Lives in the console, NOT the engine: the engine
    /// has to stay deterministic so --simulate can run thousands of games, and wall-clock
    /// time in the rules would break that. Any front end enforces its own rope.
    /// </summary>
    public const int TurnSeconds = 75;
    private const int RopeAt = 15;

    private int _lastTurnSeen = -1;
    private DateTime _turnStarted = DateTime.MinValue;
    private bool _ropeShown;

    /// <summary>Starts this turn's clock. Called once per turn, not once per command.</summary>
    private void StartClock() { _turnStarted = DateTime.UtcNow; _ropeShown = false; }
    private int SecondsLeft => Math.Max(0, TurnSeconds - (int)(DateTime.UtcNow - _turnStarted).TotalSeconds);

    /// <summary>
    /// Reads a line, but gives up when the turn budget runs out. Polls for keys rather
    /// than blocking on ReadLine so the clock can actually expire mid-input.
    /// Returns null when time is up.
    /// </summary>
    private string? ReadWithRope()
    {
        var buffer = new System.Text.StringBuilder();
        Console.Write($"[{SecondsLeft,2}s] > ");

        while (true)
        {
            if (SecondsLeft <= 0) return null;

            if (!_ropeShown && SecondsLeft <= RopeAt)
            {
                _ropeShown = true;
                Console.WriteLine();
                Console.WriteLine($"  the rope is burning ({SecondsLeft}s)");
                Console.Write($"[{SecondsLeft,2}s] > {buffer}");
            }

            if (!Console.KeyAvailable) { Thread.Sleep(50); continue; }

            var key = Console.ReadKey(intercept: true);
            if (key.Key == ConsoleKey.Enter) { Console.WriteLine(); return buffer.ToString().Trim().ToLowerInvariant(); }
            if (key.Key == ConsoleKey.Backspace)
            {
                if (buffer.Length > 0) { buffer.Length--; Console.Write(" "); }
                continue;
            }
            if (!char.IsControl(key.KeyChar)) { buffer.Append(key.KeyChar); Console.Write(key.KeyChar); }
        }
    }

    public PlayerAction ChooseAction(DuelState state, Caster me, Caster opponent)
    {
        FlushLog(state);
        if (_lastTurnSeen != state.TurnNumber) { _lastTurnSeen = state.TurnNumber; StartClock(); }
        PrintState(state, me, opponent);

        while (true)
        {
            var input = ReadWithRope();
            if (input is null)
            {
                Console.WriteLine();
                Console.WriteLine("  ...the rope burns out. Your turn ends.");
                return new PassTurn();
            }
            if (input.Length == 0) continue;

            var parts = input.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            switch (parts[0])
            {
                case "quit":
                    Environment.Exit(0);
                    break;

                case "help":
                    Console.WriteLine("p <handIndex> [targetBoardIndex] — play a card, optionally aimed at an enemy creature");
                    Console.WriteLine("a <yourBoardIndex> [enemyBoardIndex] — attack face, or a specific enemy creature");
                    Console.WriteLine("hp [enemyBoardIndex] — use your hero power (2 mana, once per turn)");
                    Console.WriteLine("end — pass the turn");
                    continue;

                case "hp":
                {
                    var power = CardSet.PowerFor(me.Class);
                    if (me.HeroPowerUsedThisTurn) { Console.WriteLine("Already used this turn."); continue; }
                    if (me.Pips < power.Cost) { Console.WriteLine($"{power.Name} costs {power.Cost}; you have {me.Pips}."); continue; }

                    BoardCreature? hpTarget = null;
                    if (parts.Length == 2)
                    {
                        if (!int.TryParse(parts[1], out var ti) || ti < 0 || ti >= opponent.Board.Count)
                        { Console.WriteLine("No enemy creature at that index."); continue; }
                        hpTarget = opponent.Board[ti];
                    }
                    if (power.Targeting == TargetRule.RequiredCreature && hpTarget is null)
                    { Console.WriteLine($"{power.Name} needs a target: hp <enemyBoardIndex>"); continue; }

                    return new UseHeroPower(hpTarget);
                }

                case "end":
                    return new PassTurn();

                case "p" when parts.Length is 2 or 3:
                {
                    if (!int.TryParse(parts[1], out var hi) || hi < 0 || hi >= me.Hand.Count)
                    {
                        Console.WriteLine("No card at that hand index.");
                        continue;
                    }
                    BoardCreature? target = null;
                    if (parts.Length == 3)
                    {
                        if (!int.TryParse(parts[2], out var ti) || ti < 0 || ti >= opponent.Board.Count)
                        {
                            Console.WriteLine("No enemy creature at that board index.");
                            continue;
                        }
                        target = opponent.Board[ti];
                    }
                    return new PlayCard(me.Hand[hi], target);
                }

                case "a" when parts.Length is 2 or 3:
                {
                    if (!int.TryParse(parts[1], out var bi) || bi < 0 || bi >= me.Board.Count)
                    {
                        Console.WriteLine("No creature of yours at that board index.");
                        continue;
                    }
                    BoardCreature? target = null;
                    if (parts.Length == 3)
                    {
                        if (!int.TryParse(parts[2], out var ti) || ti < 0 || ti >= opponent.Board.Count)
                        {
                            Console.WriteLine("No enemy creature at that board index.");
                            continue;
                        }
                        target = opponent.Board[ti];
                    }
                    return new AttackAction(me.Board[bi], target);
                }

                default:
                    Console.WriteLine("Didn't understand that — type 'help' for commands.");
                    continue;
            }
        }
    }

    private int _loggedUpTo;

    private void FlushLog(DuelState state)
    {
        for (; _loggedUpTo < state.Log.Count; _loggedUpTo++)
            Console.WriteLine($"  {state.Log[_loggedUpTo]}");
    }

    private static void PrintState(DuelState state, Caster me, Caster opponent)
    {
        Console.WriteLine();
        Console.WriteLine($"=== Turn {state.TurnNumber} ===");
        Console.WriteLine($"{opponent.Name,-12} Health {opponent.Health,3}  Pips {opponent.Pips}/{opponent.MaxPips}");
        PrintBoard(opponent.Board);
        Console.WriteLine($"{me.Name,-12} Health {me.Health,3}  Pips {me.Pips}/{me.MaxPips}");
        PrintBoard(me.Board);

        Console.WriteLine("Your hand:");
        for (var i = 0; i < me.Hand.Count; i++)
        {
            var c = me.Hand[i];
            var affordable = c.Cost <= me.Pips ? " " : "*";
            Console.WriteLine($"  [{i}]{affordable}{c} — {c.Text}");
        }
        Console.WriteLine();
    }

    private static void PrintBoard(List<BoardCreature> board)
    {
        if (board.Count == 0)
        {
            Console.WriteLine("  Board: (empty)");
            return;
        }
        var entries = board.Select((c, i) =>
            $"[{i}] {c.Source.Name} {c.Attack}/{c.Health}{(c.Taunt ? " (Taunt)" : "")}{(c.CanAttackNow ? "" : " (tapped)")}");
        Console.WriteLine("  Board: " + string.Join("  ", entries));
    }
}
