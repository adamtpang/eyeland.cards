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
    CardEffect? OnPlay = null)
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
            creature.Health -= amount;
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
            creature.Health -= amount;
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
/// The starter card pool. Ember Bolt, Tidewisp, and Eye of the Storm are the three
/// showcase cards from the eyeland.cards landing page — this is the same game, not a
/// separate prototype. The rest fill out the curve around the same three-element identity:
/// Fire = tempo/burn, Water = control/sustain, Storm = card draw/AoE.
/// </summary>
public static class CardSet
{
    public static readonly CardDef EmberBolt = new(
        "ember-bolt", "Ember Bolt", Cost: 2, CardType.Spell, Element.Fire, Rarity.Common,
        "Deal 3 damage. If it's the first spell you've cast this turn, draw a card.",
        Targeting: TargetRule.OptionalCreature,
        OnPlay: ctx =>
        {
            Effects.Damage(ctx, 3);
            if (ctx.IsFirstSpellThisTurn)
                Effects.Draw(ctx, ctx.Owner);
        });

    public static readonly CardDef Tidewisp = new(
        "tidewisp", "Tidewisp", Cost: 3, CardType.Creature, Element.Water, Rarity.Rare,
        "When Tidewisp appears, restore 2 health to your caster.",
        Attack: 3, Health: 4,
        OnPlay: ctx => Effects.Heal(ctx, ctx.Owner, 2));

    public static readonly CardDef EyeOfTheStorm = new(
        "eye-of-the-storm", "Eye of the Storm", Cost: 5, CardType.Spell, Element.Storm, Rarity.Legendary,
        "Deal 2 damage to all enemies, then draw 2 cards.",
        OnPlay: ctx =>
        {
            Effects.DamageAllEnemyCreatures(ctx, 2);
            Effects.Draw(ctx, ctx.Owner, 2);
        });

    public static readonly CardDef GlowingEmber = new(
        "glowing-ember", "Glowing Ember", Cost: 1, CardType.Creature, Element.Fire, Rarity.Common,
        "Battlecry: Deal 1 damage to the enemy caster.",
        Attack: 1, Health: 2,
        OnPlay: ctx => { ctx.Opponent.Health -= 1; ctx.Log.Add($"{ctx.Opponent.Name} takes 1 damage."); });

    public static readonly CardDef CinderWolf = new(
        "cinder-wolf", "Cinder Wolf", Cost: 3, CardType.Creature, Element.Fire, Rarity.Common,
        "A fast, fragile striker.",
        Attack: 4, Health: 2);

    public static readonly CardDef TideGuard = new(
        "tide-guard", "Tide Guard", Cost: 2, CardType.Creature, Element.Water, Rarity.Common,
        "Taunt.",
        Attack: 1, Health: 4, Taunt: true);

    public static readonly CardDef Riptide = new(
        "riptide", "Riptide", Cost: 4, CardType.Spell, Element.Water, Rarity.Rare,
        "Restore 5 health to your caster and draw a card.",
        OnPlay: ctx =>
        {
            Effects.Heal(ctx, ctx.Owner, 5);
            Effects.Draw(ctx, ctx.Owner);
        });

    public static readonly CardDef SquallCaller = new(
        "squall-caller", "Squall Caller", Cost: 2, CardType.Creature, Element.Storm, Rarity.Common,
        "Battlecry: Draw a card.",
        Attack: 2, Health: 2,
        OnPlay: ctx => Effects.Draw(ctx, ctx.Owner));

    public static readonly CardDef StormcallerElemental = new(
        "stormcaller-elemental", "Stormcaller Elemental", Cost: 4, CardType.Creature, Element.Storm, Rarity.Common,
        "A sturdy elemental body.",
        Attack: 3, Health: 5);

    public static readonly CardDef RollingThunder = new(
        "rolling-thunder", "Rolling Thunder", Cost: 6, CardType.Spell, Element.Storm, Rarity.Rare,
        "Deal 4 damage to a creature.",
        Targeting: TargetRule.RequiredCreature,
        OnPlay: ctx => Effects.Damage(ctx, 4));

    public static readonly IReadOnlyList<CardDef> All = new[]
    {
        EmberBolt, Tidewisp, EyeOfTheStorm, GlowingEmber, CinderWolf,
        TideGuard, Riptide, SquallCaller, StormcallerElemental, RollingThunder,
    };

    /// <summary>
    /// The symmetric v0 starter deck: 2 copies of each common/creature staple, 1 copy of
    /// each rare, 1 copy of the legendary. ~16 cards — enough to prove the duel loop is fun
    /// without building the full 40-card economy v1 (Deck) owns.
    /// </summary>
    public static List<CardDef> StarterDeck()
    {
        var deck = new List<CardDef>();
        void Add(CardDef card, int copies) => deck.AddRange(Enumerable.Repeat(card, copies));

        Add(GlowingEmber, 2);
        Add(TideGuard, 2);
        Add(SquallCaller, 2);
        Add(EmberBolt, 2);
        Add(CinderWolf, 2);
        Add(StormcallerElemental, 2);
        Add(Tidewisp, 1);
        Add(Riptide, 1);
        Add(RollingThunder, 1);
        Add(EyeOfTheStorm, 1);

        return deck;
    }
}
