namespace Eyeland.Duel;

/// <summary>
/// Finds the card JSON, in a way that works in every host this library runs in.
///
/// Resolution order:
///   1. <see cref="Override"/>, if a host has set it. Unity does this from a TextAsset,
///      which is also how a future card editor would preview unsaved edits.
///   2. <c>game/data/cards.json</c> on disk, searched upward from the running binary.
///      This is the path that makes editing the JSON take effect with no recompile.
///   3. The copy embedded in this assembly at build time, for shipped builds where the
///      repo layout is gone.
///
/// If all three miss it throws rather than falling back to a silently empty pool, per
/// DESIGN.md principle 3.
/// </summary>
public static class CardSource
{
    private const string FileName = "cards.json";
    private const string ResourceName = "Eyeland.Duel.cards.json";

    /// <summary>Set by a host that supplies the JSON itself (Unity, tests, a card editor).</summary>
    public static string? Override { get; set; }

    public static string Json =>
        Override
        ?? FromDisk()
        ?? FromEmbedded()
        ?? throw new FileNotFoundException(
            $"Could not find {FileName}. Set CardSource.Override, or keep game/data/{FileName} " +
            "reachable from the running binary.");

    /// <summary>The resolved path, when the disk copy is the one in use. Null otherwise.</summary>
    public static string? ResolvedPath { get; private set; }

    private static string? FromDisk()
    {
        var dir = AppContext.BaseDirectory;
        for (var depth = 0; depth < 10 && dir is not null; depth++)
        {
            var candidate = Path.Combine(dir, "game", "data", FileName);
            if (File.Exists(candidate))
            {
                ResolvedPath = candidate;
                return File.ReadAllText(candidate);
            }
            dir = Directory.GetParent(dir)?.FullName;
        }
        return null;
    }

    private static string? FromEmbedded()
    {
        var asm = typeof(CardSource).Assembly;
        using var stream = asm.GetManifestResourceStream(ResourceName);
        if (stream is null) return null;
        using var reader = new StreamReader(stream);
        return reader.ReadToEnd();
    }
}
