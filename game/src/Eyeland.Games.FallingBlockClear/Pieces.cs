namespace Eyeland.Games.FallingBlockClear;

/// <summary>
/// GAMES-1000 entry 002. One mechanic only, per DESIGN.md Principle 2 (Tetris:
/// one mechanic, absolute elegance, born out of hardware constraint, not a big
/// budget) -- three piece shapes, no wall-kicks, no hold queue, no next-piece
/// preview. Scope is the point, not a limitation to fix later.
/// </summary>
public enum PieceKind { I, O, L }

public readonly record struct Cell(int Row, int Col);

public sealed class Piece
{
    public PieceKind Kind { get; }
    public int BoxSize { get; }
    public IReadOnlyList<Cell> Cells { get; private set; }
    public int OriginRow { get; private set; }
    public int OriginCol { get; private set; }

    private Piece(PieceKind kind, int boxSize, IReadOnlyList<Cell> cells, int originRow, int originCol)
    {
        Kind = kind;
        BoxSize = boxSize;
        Cells = cells;
        OriginRow = originRow;
        OriginCol = originCol;
    }

    public static Piece Spawn(PieceKind kind, int boardWidth)
    {
        var (boxSize, cells) = kind switch
        {
            PieceKind.I => (4, new[] { new Cell(1, 0), new Cell(1, 1), new Cell(1, 2), new Cell(1, 3) }),
            PieceKind.O => (2, new[] { new Cell(0, 0), new Cell(0, 1), new Cell(1, 0), new Cell(1, 1) }),
            PieceKind.L => (3, new[] { new Cell(0, 2), new Cell(1, 0), new Cell(1, 1), new Cell(1, 2) }),
            _ => throw new ArgumentOutOfRangeException(nameof(kind)),
        };
        var originCol = (boardWidth - boxSize) / 2;
        return new Piece(kind, boxSize, cells, originRow: 0, originCol: originCol);
    }

    public Piece Clone() => new(Kind, BoxSize, Cells.ToArray(), OriginRow, OriginCol);

    public void MoveTo(int originRow, int originCol)
    {
        OriginRow = originRow;
        OriginCol = originCol;
    }

    /// <summary>
    /// Rotate 90 degrees clockwise within the piece's own bounding box:
    /// (row, col) -> (col, size-1-row). No wall-kicks -- if the rotated shape
    /// collides, the caller just discards it and the piece stays as-is. A
    /// real, documented simplification, not an oversight.
    /// </summary>
    public IReadOnlyList<Cell> Rotated()
    {
        var n = BoxSize;
        return Cells.Select(c => new Cell(c.Col, n - 1 - c.Row)).ToArray();
    }

    public void ApplyRotation(IReadOnlyList<Cell> rotated) => Cells = rotated;

    public IEnumerable<Cell> BoardCells(int? originRowOverride = null, int? originColOverride = null, IReadOnlyList<Cell>? cellsOverride = null)
    {
        var or = originRowOverride ?? OriginRow;
        var oc = originColOverride ?? OriginCol;
        foreach (var c in cellsOverride ?? Cells)
            yield return new Cell(or + c.Row, oc + c.Col);
    }
}
