namespace Eyeland.Duel;

public enum Element { Fire, Water, Storm }

public enum CardType { Spell, Creature }

public enum Rarity { Common, Rare, Legendary }

/// <summary>
/// The result of resolving a card: what happened, for the log and the console UI.
/// Effects append here instead of printing directly, so the engine stays UI-agnostic
/// (the same CardDef will later run unmodified inside the Unity duel scene).
/// </summary>
public sealed class ResolutionLog
{
    public List<string> Lines { get; } = new();
    public void Add(string line) => Lines.Add(line);
}

/// <summary>
/// Everything needed to resolve a card is passed through one context object,
/// rather than threading Owner/Opponent/Target through every effect signature.
/// </summary>
public sealed class DuelContext
{
    public required DuelState State { get; init; }
    public required Caster Owner { get; init; }
    public required Caster Opponent { get; init; }
    public BoardCreature? Target { get; init; }
    public bool IsFirstSpellThisTurn { get; init; }
    public required ResolutionLog Log { get; init; }
}

public delegate void CardEffect(DuelContext ctx);

/// <summary>
/// Whether a card's effect can/must be aimed at a specific enemy creature.
/// OptionalCreature covers cards like "deal 3 damage" (Effects.Damage falls back to face
/// when Target is null); RequiredCreature covers cards restricted to "...to a creature".
/// </summary>
public enum TargetRule { None, OptionalCreature, RequiredCreature }

/// <summary>
/// An immutable card definition — the "printed card." Playing a copy never mutates
/// this; creatures get their own BoardCreature instance with independent Attack/Health.
/// </summary>
public sealed record CardDef(
    string Id,
    string Name,
    int Cost,
    CardType Type,
    Element Element,
    Rarity Rarity,
    string Text,
    int Attack = 0,
    int Health = 0,
    bool Taunt = false,
    TargetRule Targeting = TargetRule.None,
    CardEffect? OnPlay = null,
    AuraDef? Aura = null)
{
    public override string ToString() =>
        Type == CardType.Creature
            ? $"{Name} ({Cost}) [{Attack}/{Health}]"
            : $"{Name} ({Cost})";
}

public static class Effects
{
    /// <summary>Damages the chosen target, or the opponent's face if no target was chosen.</summary>
    public static void Damage(DuelContext ctx, int amount)
    {
        if (ctx.Target is { } creature)
        {
            creature.TakeDamage(amount);
            ctx.Log.Add($"{creature.Source.Name} takes {amount} damage ({Math.Max(creature.Health, 0)} health left).");
        }
        else
        {
            ctx.Opponent.Health -= amount;
            ctx.Log.Add($"{ctx.Opponent.Name} takes {amount} damage ({Math.Max(ctx.Opponent.Health, 0)} health left).");
        }
    }

    public static void DamageAllEnemyCreatures(DuelContext ctx, int amount)
    {
        foreach (var creature in ctx.Opponent.Board)
        {
            creature.TakeDamage(amount);
            ctx.Log.Add($"{creature.Source.Name} takes {amount} damage ({Math.Max(creature.Health, 0)} health left).");
        }
    }

    public static void Heal(DuelContext ctx, Caster who, int amount)
    {
        who.Health = Math.Min(who.Health + amount, who.MaxHealth);
        ctx.Log.Add($"{who.Name} restores {amount} health ({who.Health} health now).");
    }

    public static void Draw(DuelContext ctx, Caster who, int count = 1)
    {
        for (var i = 0; i < count; i++)
            who.DrawCard(ctx.Log);
    }
}

/// <summary>
/// The card pool, loaded from <c>game/data/cards.json</c> at first use.
///
/// The named properties below are conveniences for code that wants a specific card
/// (tests, the console harness, the Unity scenes). They resolve by id out of the
/// loaded data, so adding a card to the JSON needs no change here at all — only a
/// card that code refers to by name needs a property.
///
/// Ember Bolt, Tidewisp, and Eye of the Storm are the three showcase cards from the
/// eyeland.cards landing page: this is the same game, not a separate prototype. The
/// rest fill out the curve around the same three-element identity: Fire = tempo/burn,
/// Water = control/sustain, Storm = card draw/AoE.
/// </summary>
public static class CardSet
{
    private static CardData? _data;

    /// <summary>The parsed card file. Loaded once, on first access.</summary>
    public static CardData Data => _data ??= CardLoader.FromJson(CardSource.Json);

    /// <summary>
    /// Replaces the loaded pool. For tests and for any future card editor that wants to
    /// preview edited data without restarting. Pass null to fall back to the shipped file.
    /// </summary>
    public static void Load(string? json)
    {
        _data = json is null ? null : CardLoader.FromJson(json);
    }

    public static CardDef ById(string id) => Data.ById(id);

    public static CardDef EmberBolt => ById("ember-bolt");
    public static CardDef Tidewisp => ById("tidewisp");
    public static CardDef EyeOfTheStorm => ById("eye-of-the-storm");
    public static CardDef GlowingEmber => ById("glowing-ember");
    public static CardDef CinderWolf => ById("cinder-wolf");
    public static CardDef TideGuard => ById("tide-guard");
    public static CardDef Riptide => ById("riptide");
    public static CardDef SquallCaller => ById("squall-caller");
    public static CardDef StormcallerElemental => ById("stormcaller-elemental");
    public static CardDef RollingThunder => ById("rolling-thunder");
    public static CardDef StormTotem => ById("storm-totem");

    public static IReadOnlyList<CardDef> All => Data.Cards;

    /// <summary>
    /// The symmetric v0 starter deck, built from the recipe in the card file: 2 copies of
    /// each common staple, 1 of each rare, 1 legendary. 16 cards — enough to prove the duel
    /// loop is fun without building the full 40-card economy v1 (Deck) owns.
    /// </summary>
    public static List<CardDef> StarterDeck()
    {
        var recipe = Data.StarterDeck;
        var deck = new List<CardDef>();
        foreach (var id in recipe.Order)
        {
            var card = Data.ById(id);
            var copies = recipe.Counts.TryGetValue(id, out var n) ? n : 1;
            for (var i = 0; i < copies; i++) deck.Add(card);
        }
        return deck;
    }
}
