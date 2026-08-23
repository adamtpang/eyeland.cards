namespace Eyeland.Duel;

// ─────────────────────────────────────────────────────────────────────────────
// The stat onion.
//
// A creature's live stats are never stored as one mutable number. They are
// recomputed from layers, outermost last:
//
//   Layer 0  BASE          the printed CardDef values. Never changes.
//   Layer 1  ENCHANTMENTS  permanent modifiers attached to this creature.
//                          Survive until explicitly removed. Stored.
//   Layer 2  AURAS         continuous modifiers from OTHER entities, valid only
//                          while their source is alive and in scope. Never
//                          stored: recomputed into a buffer on every board change.
//
// Damage is tracked separately from health, which is the part the old flat model
// got wrong. `Health` is derived (MaxHealth - Damage), so a +2 max-health buff
// on a damaged creature raises its ceiling without silently healing it, and
// losing that buff doesn't kill a creature that was never actually hurt.
//
// The layer approach is the same idea as SabberStone's "onion system"
// (github.com/HearthSim/SabberStone, AGPLv3). This is an independent
// implementation of the pattern for eyeland's own model: no SabberStone code
// is used or derived from here, only the architectural idea, which is not
// itself copyrightable.
// ─────────────────────────────────────────────────────────────────────────────

/// <summary>
/// A stat that layers can modify. Add cases here, not new buff fields.
///
/// Keywords are stats too, held as counters rather than booleans, which is what lets
/// them be granted and revoked by layers without losing track. A creature with printed
/// Taunt that also gets Taunt from an aura sits at 2; when the aura source dies it drops
/// to 1 and the creature correctly keeps its printed Taunt. A boolean would have lost that.
/// </summary>
public enum Stat
{
    Attack,
    MaxHealth,

    // ── keywords, counters where > 0 means "has it" ──
    Taunt,        // enemies must attack this first
    Rush,         // may attack enemy creatures the turn it lands
    Charge,       // may attack anything the turn it lands
    DivineShield, // absorbs the first damage it would take
    Lifesteal,    // damage it deals heals your caster
    Windfury,     // may attack twice each turn
    Poisonous,    // any creature it damages is destroyed
    Stealth,      // cannot be targeted until it attacks or deals damage
    SpellDamage,  // this creature adds N to your spell damage
}

/// <summary>One modifier: "+2 Attack", "+1 MaxHealth", "grant Taunt".</summary>
public readonly record struct StatMod(Stat Stat, int Amount)
{
    public override string ToString() =>
        Stat == Stat.Taunt ? "Taunt" : $"{(Amount >= 0 ? "+" : "")}{Amount} {Stat}";
}

/// <summary>
/// Layer 1. A permanent modifier attached to one creature: the result of a
/// battlecry buff, a spell, a deathrattle. Persists until removed explicitly.
/// </summary>
public sealed record Enchantment(string Name, IReadOnlyList<StatMod> Mods)
{
    public static Enchantment Of(string name, params StatMod[] mods) => new(name, mods);
}

/// <summary>Which creatures an aura reaches.</summary>
public enum AuraScope
{
    /// <summary>Every other friendly creature. The common "your other minions have +1/+1".</summary>
    FriendlyOthers,
    /// <summary>Every friendly creature, including the aura's own source.</summary>
    FriendlyAll,
    /// <summary>Every enemy creature.</summary>
    EnemyAll,
    /// <summary>Every creature on the board, both sides.</summary>
    AllCreatures,
}

/// <summary>
/// Layer 2, declared on a CardDef. A creature carrying one of these projects its
/// mods onto everything in scope for exactly as long as it is alive on the board.
/// </summary>
public sealed record AuraDef(AuraScope Scope, IReadOnlyList<StatMod> Mods, string Text)
{
    public static AuraDef Of(AuraScope scope, string text, params StatMod[] mods) =>
        new(scope, mods, text);
}

/// <summary>
/// Recomputes every aura on the board from scratch.
///
/// Deliberately a full recompute rather than incremental add/remove: incremental
/// aura bookkeeping is the classic source of "minion keeps a buff after the
/// buffer died" bugs, and a board caps at 7 per side, so the cost is trivial.
/// </summary>
public static class AuraSystem
{
    public static void Refresh(DuelState state)
    {
        foreach (var creature in AllLiving(state))
            creature.ClearAuraBuffer();

        foreach (var (owner, opponent) in new[] { (state.A, state.B), (state.B, state.A) })
        {
            foreach (var source in owner.Board.Where(c => c.IsAlive))
            {
                if (source.Source.Aura is not { } aura) continue;

                foreach (var affected in Targets(aura.Scope, source, owner, opponent))
                    foreach (var mod in aura.Mods)
                        affected.ApplyAuraMod(mod);
            }
        }
    }

    private static IEnumerable<BoardCreature> AllLiving(DuelState state) =>
        state.A.Board.Concat(state.B.Board).Where(c => c.IsAlive);

    private static IEnumerable<BoardCreature> Targets(
        AuraScope scope, BoardCreature source, Caster owner, Caster opponent) => scope switch
    {
        AuraScope.FriendlyOthers => owner.Board.Where(c => c.IsAlive && !ReferenceEquals(c, source)),
        AuraScope.FriendlyAll    => owner.Board.Where(c => c.IsAlive),
        AuraScope.EnemyAll       => opponent.Board.Where(c => c.IsAlive),
        AuraScope.AllCreatures   => owner.Board.Concat(opponent.Board).Where(c => c.IsAlive),
        _ => Enumerable.Empty<BoardCreature>(),
    };
}
