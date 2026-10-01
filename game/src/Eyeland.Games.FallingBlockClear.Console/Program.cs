using Eyeland.Games.FallingBlockClear;

int? seed = null;
var seedArgIndex = Array.IndexOf(args, "--seed");
if (seedArgIndex >= 0 && seedArgIndex + 1 < args.Length && int.TryParse(args[seedArgIndex + 1], out var s))
    seed = s;

var state = new GameState(seed);

Console.WriteLine("Falling Block Clear -- GAMES-1000 entry 002");
Console.WriteLine("a=left  d=right  w=rotate  s=soft drop  x=hard drop  q=quit");
Console.WriteLine($"Clear {GameState.LinesToWin} lines to win. No wall-kicks, no hold, no next-piece preview -- one mechanic, on purpose.\n");

while (!state.IsOver)
{
    Console.WriteLine(state.Render());
    Console.Write("> ");
    var input = Console.ReadLine();
    if (input is null || input.Trim().ToLowerInvariant() == "q") break;

    var result = input.Trim().ToLowerInvariant() switch
    {
        "a" => state.MoveLeft(),
        "d" => state.MoveRight(),
        "w" => state.Rotate(),
        "s" => state.SoftDrop(),
        "x" => state.HardDrop(),
        _ => ActionResult.Blocked,
    };

    foreach (var line in state.Log.Skip(Math.Max(0, state.Log.Count - 1)))
        Console.WriteLine($"  {line}");
}

Console.WriteLine(state.Render());
Console.WriteLine(state.Won ? "YOU WON." : "GAME OVER.");
Console.WriteLine($"Lines cleared: {state.LinesCleared}/{GameState.LinesToWin}");
