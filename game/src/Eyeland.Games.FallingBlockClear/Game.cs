namespace Eyeland.Games.FallingBlockClear;

public enum ActionResult { Ok, Blocked, Locked, GameOver, Won }

/// <summary>
/// Board + turn logic. Deliberately turn-based, not real-time: every player
/// action (move, rotate, drop) also advances gravity by one row, matching
/// DESIGN.md Principle 9 (--seed-style determinism: the same input sequence
/// always produces the same game, real-time framerate never enters into it).
/// This is what makes a console harness -- and therefore a real playtest
/// with no Unity GUI at all -- possible for entry 002, the same pattern that
/// proved out v0 Duel.
/// </summary>
public sealed class GameState
{
    public const int Width = 8;
    public const int Height = 14;
    public const int LinesToWin = 10;

    private readonly int[,] _board = new int[Height, Width]; // 0 = empty, else PieceKind+1
    public Piece Current { get; private set; }
    public int LinesCleared { get; private set; }
    public bool IsOver { get; private set; }
    public bool Won { get; private set; }
    public readonly List<string> Log = new();

    private readonly Random _rng;

    public GameState(int? seed = null)
    {
        _rng = seed is { } s ? new Random(s) : new Random();
        Current = Piece.Spawn(NextKind(), Width);
    }

    private PieceKind NextKind() => (PieceKind)_rng.Next(3);

    private bool Collides(int originRow, int originCol, IReadOnlyList<Cell> cells)
    {
        foreach (var c in cells)
        {
            var r = originRow + c.Row;
            var col = originCol + c.Col;
            if (col < 0 || col >= Width || r >= Height) return true;
            if (r >= 0 && _board[r, col] != 0) return true;
        }
        return false;
    }

    public ActionResult MoveLeft() => ApplyThenGravity(() =>
    {
        if (!Collides(Current.OriginRow, Current.OriginCol - 1, Current.Cells))
            Current.MoveTo(Current.OriginRow, Current.OriginCol - 1);
    });

    public ActionResult MoveRight() => ApplyThenGravity(() =>
    {
        if (!Collides(Current.OriginRow, Current.OriginCol + 1, Current.Cells))
            Current.MoveTo(Current.OriginRow, Current.OriginCol + 1);
    });

    public ActionResult Rotate() => ApplyThenGravity(() =>
    {
        var rotated = Current.Rotated();
        if (!Collides(Current.OriginRow, Current.OriginCol, rotated))
            Current.ApplyRotation(rotated);
    });

    /// <summary>Drop with no extra horizontal move, still counts as one turn's gravity step.</summary>
    public ActionResult SoftDrop() => ApplyThenGravity(() => { });

    public ActionResult HardDrop()
    {
        if (IsOver) return Won ? ActionResult.Won : ActionResult.GameOver;
        while (!Collides(Current.OriginRow + 1, Current.OriginCol, Current.Cells))
            Current.MoveTo(Current.OriginRow + 1, Current.OriginCol);
        return LockAndSpawn();
    }

    private ActionResult ApplyThenGravity(Action doMove)
    {
        if (IsOver) return Won ? ActionResult.Won : ActionResult.GameOver;
        doMove();
        if (!Collides(Current.OriginRow + 1, Current.OriginCol, Current.Cells))
        {
            Current.MoveTo(Current.OriginRow + 1, Current.OriginCol);
            return ActionResult.Ok;
        }
        return LockAndSpawn();
    }

    private ActionResult LockAndSpawn()
    {
        foreach (var c in Current.BoardCells())
        {
            if (c.Row < 0) continue; // locked partially above the visible board: ignore those cells
            _board[c.Row, c.Col] = (int)Current.Kind + 1;
        }

        var cleared = ClearFullLines();
        if (cleared > 0)
        {
            LinesCleared += cleared;
            Log.Add($"Cleared {cleared} line(s). Total: {LinesCleared}/{LinesToWin}.");
        }

        if (LinesCleared >= LinesToWin)
        {
            IsOver = true;
            Won = true;
            Log.Add("WON: reached the line target.");
            return ActionResult.Won;
        }

        var next = Piece.Spawn(NextKind(), Width);
        if (Collides(next.OriginRow, next.OriginCol, next.Cells))
        {
            IsOver = true;
            Won = false;
            Log.Add("GAME OVER: stack topped out.");
            return ActionResult.GameOver;
        }

        Current = next;
        return ActionResult.Locked;
    }

    private int ClearFullLines()
    {
        var fullRows = new List<int>();
        for (var r = 0; r < Height; r++)
        {
            var full = true;
            for (var c = 0; c < Width; c++)
                if (_board[r, c] == 0) { full = false; break; }
            if (full) fullRows.Add(r);
        }
        foreach (var r in fullRows)
        {
            for (var rr = r; rr > 0; rr--)
                for (var c = 0; c < Width; c++)
                    _board[rr, c] = _board[rr - 1, c];
            for (var c = 0; c < Width; c++)
                _board[0, c] = 0;
        }
        return fullRows.Count;
    }

    private static readonly char[] KindGlyph = { '.', 'I', 'O', 'L' }; // index 0 unused (0 = empty cell)

    public string Render()
    {
        var overlay = new HashSet<(int, int)>(Current.BoardCells().Where(c => c.Row >= 0).Select(c => (c.Row, c.Col)));
        var sb = new System.Text.StringBuilder();
        sb.Append('+').Append('-', Width).Append("+\n");
        for (var r = 0; r < Height; r++)
        {
            sb.Append('|');
            for (var c = 0; c < Width; c++)
            {
                if (overlay.Contains((r, c))) sb.Append('#');
                else sb.Append(KindGlyph[_board[r, c]]);
            }
            sb.Append("|\n");
        }
        sb.Append('+').Append('-', Width).Append("+\n");
        return sb.ToString();
    }
}
