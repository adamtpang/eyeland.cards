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

static List<CardDef> Shuffled(List<CardDef> deck, Random rng) =>
    deck.OrderBy(_ => rng.Next()).ToList();

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

    public PlayerAction ChooseAction(DuelState state, Caster me, Caster opponent)
    {
        FlushLog(state);
        PrintState(state, me, opponent);

        while (true)
        {
            Console.Write("> ");
            var input = Console.ReadLine()?.Trim().ToLowerInvariant();
            if (string.IsNullOrEmpty(input)) continue;

            var parts = input.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            switch (parts[0])
            {
                case "quit":
                    Environment.Exit(0);
                    break;

                case "help":
                    Console.WriteLine("p <handIndex> [targetBoardIndex] — play a card, optionally aimed at an enemy creature");
                    Console.WriteLine("a <yourBoardIndex> [enemyBoardIndex] — attack face, or a specific enemy creature");
                    Console.WriteLine("end — pass the turn");
                    continue;

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
            $"[{i}] {c.Source.Name} {c.Attack}/{c.Health}{(c.Taunt ? " (Taunt)" : "")}{(c.CanAttack ? "" : " (tapped)")}");
        Console.WriteLine("  Board: " + string.Join("  ", entries));
    }
}
