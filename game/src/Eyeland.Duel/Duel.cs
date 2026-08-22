namespace Eyeland.Duel;

/// <summary>
/// A live creature on the board. Its stats are never a single mutable number: they
/// are recomputed from the layers described in <see cref="Stats"/> (base →
/// enchantments → auras), with damage tracked separately from health.
/// </summary>
public sealed class BoardCreature
{
    public required CardDef Source { get; init; }
    public bool CanAttack { get; set; }

    /// <summary>Damage taken. Never negative. Healing reduces this, it does not raise MaxHealth.</summary>
    public int Damage { get; private set; }

    private readonly List<Enchantment> _enchantments = new();
    private readonly int[] _auraBuffer = new int[Enum.GetValues<Stat>().Length];

    public IReadOnlyList<Enchantment> Enchantments => _enchantments;

    // ── the onion, read outward ───────────────────────────────────────────────
    private int Layered(Stat stat, int baseValue)
    {
        var total = baseValue + _auraBuffer[(int)stat];
        foreach (var e in _enchantments)
            foreach (var m in e.Mods)
                if (m.Stat == stat) total += m.Amount;
        return total;
    }

    public int Attack => Math.Max(0, Layered(Stat.Attack, Source.Attack));
    public int MaxHealth => Math.Max(1, Layered(Stat.MaxHealth, Source.Health));
    public int Health => MaxHealth - Damage;
    public bool Taunt => Layered(Stat.Taunt, Source.Taunt ? 1 : 0) > 0;
    public bool IsAlive => Health > 0;

    // ── mutation ──────────────────────────────────────────────────────────────
    /// <summary>Deals damage. Returns the amount actually dealt.</summary>
    public int TakeDamage(int amount)
    {
        if (amount <= 0) return 0;
        Damage += amount;
        return amount;
    }

    /// <summary>Heals up to MaxHealth. Returns the amount actually restored.</summary>
    public int Restore(int amount)
    {
        if (amount <= 0) return 0;
        var healed = Math.Min(amount, Damage);
        Damage -= healed;
        return healed;
    }

    public void AddEnchantment(Enchantment enchantment) => _enchantments.Add(enchantment);
    public bool RemoveEnchantment(string name) => _enchantments.RemoveAll(e => e.Name == name) > 0;

    internal void ClearAuraBuffer() => Array.Clear(_auraBuffer);
    internal void ApplyAuraMod(StatMod mod) => _auraBuffer[(int)mod.Stat] += mod.Amount;

    public static BoardCreature FromCard(CardDef card) => new()
    {
        Source = card,
        CanAttack = false, // summoning sickness until this caster's next turn start
    };
}

public sealed class Caster
{
    public required string Name { get; init; }
    public int MaxHealth { get; init; } = 30;
    public int Health { get; set; } = 30;
    public int MaxPips { get; set; }
    public int Pips { get; set; }
    public const int PipCap = 10;

    public List<CardDef> Deck { get; init; } = new();
    public List<CardDef> Hand { get; } = new();
    public List<BoardCreature> Board { get; } = new();
    public int FatigueDamage { get; set; }
    public int SpellsCastThisTurn { get; set; }

    public bool IsAlive => Health > 0;

    public void DrawCard(ResolutionLog log)
    {
        if (Deck.Count == 0)
        {
            FatigueDamage++;
            Health -= FatigueDamage;
            log.Add($"{Name} draws from an empty deck and takes {FatigueDamage} fatigue damage.");
            return;
        }

        var card = Deck[0];
        Deck.RemoveAt(0);
        Hand.Add(card);
        log.Add($"{Name} draws {card.Name}.");
    }

    /// <summary>
    /// Deals the opening hand before turn 1 — distinct from the per-turn draw in
    /// StartTurn. Without this, turn 1 is a single random card at 1 pip and almost
    /// always a forced pass; every real card game deals a multi-card starting hand
    /// so the opening turn is a real decision.
    /// </summary>
    public void DealOpeningHand(int count, ResolutionLog log)
    {
        for (var i = 0; i < count; i++)
            DrawCard(log);
    }

    public void StartTurn(ResolutionLog log)
    {
        MaxPips = Math.Min(MaxPips + 1, PipCap);
        Pips = MaxPips;
        SpellsCastThisTurn = 0;
        foreach (var creature in Board)
            creature.CanAttack = true;
        DrawCard(log);
    }
}

public sealed class DuelState
{
    public required Caster A { get; init; }
    public required Caster B { get; init; }
    public Caster Active { get; set; } = null!;
    public Caster Waiting => Active == A ? B : A;
    public int TurnNumber { get; set; } = 1;
    public List<string> Log { get; } = new();

    public bool IsOver => !A.IsAlive || !B.IsAlive;
    public Caster? Winner =>
        (!A.IsAlive, !B.IsAlive) switch
        {
            (true, true) => null, // simultaneous fatigue kill: a draw
            (true, false) => B,
            (false, true) => A,
            _ => null,
        };
}

public abstract record PlayerAction;
public sealed record PlayCard(CardDef Card, BoardCreature? Target) : PlayerAction;
public sealed record AttackAction(BoardCreature Attacker, BoardCreature? Target) : PlayerAction; // Target null = enemy face
public sealed record PassTurn : PlayerAction;

public interface IPlayerController
{
    string Name { get; }
    PlayerAction ChooseAction(DuelState state, Caster me, Caster opponent);
}

/// <summary>
/// Runs the shared rules both the human console harness and AI-vs-AI simulation drive
/// through identically: start-of-turn upkeep, a play phase of repeated actions until pass,
/// end-of-turn cleanup. This is the same loop the Unity scene will call once the MCP bridge
/// is wired up — no UI concerns live in here.
/// </summary>
public static class TurnEngine
{
    public static void RunGame(DuelState state, IPlayerController controllerA, IPlayerController controllerB, int maxTurns = 200)
    {
        var log = new ResolutionLog();
        log.Lines.AddRange(state.Log);

        state.Active = state.A;
        state.A.StartTurn(log);
        state.Log.Clear();
        state.Log.AddRange(log.Lines);

        while (!state.IsOver && state.TurnNumber <= maxTurns)
        {
            var controller = state.Active == state.A ? controllerA : controllerB;
            var action = controller.ChooseAction(state, state.Active, state.Waiting);

            switch (action)
            {
                case PlayCard play:
                    TryPlayCard(state, play.Card, play.Target);
                    break;
                case AttackAction attack:
                    TryAttack(state, attack.Attacker, attack.Target);
                    break;
                case PassTurn:
                    EndTurn(state);
                    break;
            }

            if (state.IsOver) break;
        }
    }

    public static bool TryPlayCard(DuelState state, CardDef card, BoardCreature? target)
    {
        var owner = state.Active;
        var opponent = state.Waiting;

        if (owner.Pips < card.Cost || !owner.Hand.Contains(card))
            return false;
        if (target is not null && (!opponent.Board.Contains(target) || !target.IsAlive))
            return false;
        if (card.Targeting == TargetRule.RequiredCreature && target is null)
            return false;

        owner.Pips -= card.Cost;
        owner.Hand.Remove(card);

        var isFirstSpell = card.Type == CardType.Spell && owner.SpellsCastThisTurn == 0;
        if (card.Type == CardType.Spell)
            owner.SpellsCastThisTurn++;

        BoardCreature? summoned = null;
        if (card.Type == CardType.Creature)
        {
            summoned = BoardCreature.FromCard(card);
            owner.Board.Add(summoned);
        }

        state.Log.Add($"{owner.Name} plays {card.Name}.");

        if (card.OnPlay is { } effect)
        {
            var ctx = new DuelContext
            {
                State = state,
                Owner = owner,
                Opponent = opponent,
                Target = target,
                IsFirstSpellThisTurn = isFirstSpell,
                Log = new ResolutionLog(),
            };
            effect(ctx);
            state.Log.AddRange(ctx.Log.Lines);
        }

        CleanupDead(state);
        return true;
    }

    public static bool TryAttack(DuelState state, BoardCreature attacker, BoardCreature? target)
    {
        var owner = state.Active;
        var opponent = state.Waiting;

        if (!owner.Board.Contains(attacker) || !attacker.CanAttack || !attacker.IsAlive)
            return false;

        var enemyTaunts = opponent.Board.Where(c => c.Taunt && c.IsAlive).ToList();
        if (enemyTaunts.Count > 0 && (target is null || !enemyTaunts.Contains(target)))
            return false; // must attack into taunt if one is up

        attacker.CanAttack = false;

        if (target is null)
        {
            opponent.Health -= attacker.Attack;
            state.Log.Add($"{attacker.Source.Name} attacks {opponent.Name} for {attacker.Attack}.");
        }
        else
        {
            if (!opponent.Board.Contains(target) || !target.IsAlive)
                return false;

            // Both damages are computed before either is applied, so a creature that
            // dies still trades back for its full attack.
            var incoming = target.Attack;
            target.TakeDamage(attacker.Attack);
            attacker.TakeDamage(incoming);
            state.Log.Add($"{attacker.Source.Name} trades with {target.Source.Name} ({attacker.Attack} <-> {target.Attack}).");
        }

        CleanupDead(state);
        return true;
    }

    /// <summary>
    /// The single choke point for board changes. Deaths are resolved first, then every
    /// aura is recomputed from scratch, so a buff whose source just died is gone in the
    /// same step rather than lingering as a stale bonus.
    ///
    /// Removal loops until stable: losing an aura can lower a creature's MaxHealth below
    /// the damage it has already taken, which kills it, which can drop another aura.
    /// </summary>
    private static void CleanupDead(DuelState state)
    {
        for (var pass = 0; pass < 8; pass++)
        {
            var removed = state.A.Board.RemoveAll(c => !c.IsAlive)
                        + state.B.Board.RemoveAll(c => !c.IsAlive);
            AuraSystem.Refresh(state);
            if (removed == 0) break;
        }
    }

    /// <summary>
    /// Public so a UI-driven turn loop (Unity) can call it directly after a human's
    /// "End Turn" click, rather than going through the blocking RunGame loop that
    /// assumes IPlayerController.ChooseAction can synchronously wait for input.
    /// </summary>
    public static void EndTurn(DuelState state)
    {
        state.Log.Add($"-- {state.Active.Name} ends turn {state.TurnNumber} --");
        state.Active = state.Waiting;
        if (state.Active == state.A)
            state.TurnNumber++;

        var log = new ResolutionLog();
        state.Active.StartTurn(log);
        state.Log.AddRange(log.Lines);
    }
}
