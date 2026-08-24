namespace Eyeland.Duel;

/// <summary>
/// A live creature on the board. Its stats are never a single mutable number: they
/// are recomputed from the layers described in <see cref="Stats"/> (base →
/// enchantments → auras), with damage tracked separately from health.
/// </summary>
public sealed class BoardCreature
{
    public required CardDef Source { get; init; }

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
    public bool IsAlive => Health > 0;

    // ── keywords, resolved through the same layers ────────────────────────────
    private bool Keyword(Stat stat) => Layered(stat, Source.Has(stat) ? 1 : 0) > 0;

    public bool Taunt => Keyword(Stat.Taunt);
    public bool Rush => Keyword(Stat.Rush);
    public bool Charge => Keyword(Stat.Charge);
    public bool Lifesteal => Keyword(Stat.Lifesteal);
    public bool Windfury => Keyword(Stat.Windfury);
    public bool Poisonous => Keyword(Stat.Poisonous);
    public int SpellDamage => Math.Max(0, Layered(Stat.SpellDamage, Source.SpellDamage));

    /// <summary>Divine Shield is consumed when it absorbs, so it needs its own spent flag.</summary>
    public bool DivineShield => !_shieldSpent && Keyword(Stat.DivineShield);
    private bool _shieldSpent;

    /// <summary>Stealth drops permanently the moment this creature attacks or deals damage.</summary>
    public bool Stealth => !_stealthBroken && Keyword(Stat.Stealth);
    private bool _stealthBroken;

    /// <summary>Frozen creatures skip their next chance to attack.</summary>
    public bool Frozen { get; set; }

    /// <summary>Attacks already made this turn, against the Windfury allowance.</summary>
    public int AttacksThisTurn { get; set; }
    public int AttacksAllowed => Windfury ? 2 : 1;

    /// <summary>Whether this creature may attack right now, and if not, why not.</summary>
    public bool CanAttackNow => IsAlive && !Frozen && Attack > 0
                                && AttacksThisTurn < AttacksAllowed && !SummoningSick;

    /// <summary>True until this creature's controller starts a turn with it on the board.</summary>
    public bool SummoningSick { get; set; } = true;

    /// <summary>
    /// The turn this creature hit the board. Rush needs it: Rush and Charge both clear
    /// summoning sickness, and the only thing separating them is that Rush may not hit
    /// the enemy caster on its arrival turn specifically.
    /// </summary>
    public int LandedOnTurn { get; set; } = -1;

    // ── mutation ──────────────────────────────────────────────────────────────
    /// <summary>
    /// Deals damage. Returns the amount actually dealt, which is 0 if Divine Shield
    /// absorbed it. Poisonous is applied by the caller, not here, since it depends on
    /// the source rather than the victim.
    /// </summary>
    public int TakeDamage(int amount)
    {
        if (amount <= 0) return 0;
        if (DivineShield) { _shieldSpent = true; return 0; }
        Damage += amount;
        return amount;
    }

    /// <summary>Called when this creature deals damage: breaks Stealth.</summary>
    public void OnDealtDamage() => _stealthBroken = true;

    /// <summary>Kills outright, ignoring Divine Shield. For Poisonous and destroy effects.</summary>
    public void Destroy() => Damage = MaxHealth + 999;

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

    public static BoardCreature FromCard(CardDef card)
    {
        var c = new BoardCreature { Source = card };
        // Charge and Rush both mean "act the turn you land". They differ in what they may
        // hit, which TryAttack enforces, not here.
        c.SummoningSick = !(c.Charge || c.Rush);
        return c;
    }
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

    /// <summary>The deck's class. Decides which hero power this caster gets.</summary>
    public PlayerClass Class { get; init; } = PlayerClass.Neutral;

    /// <summary>Hero powers are once per turn, which is the whole reason they are balanced at 2 mana.</summary>
    public bool HeroPowerUsedThisTurn { get; set; }

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
        HeroPowerUsedThisTurn = false;
        foreach (var creature in Board)
        {
            creature.SummoningSick = false;
            creature.AttacksThisTurn = 0;

            // Freeze costs the creature this turn's attacks, then thaws. Spending the
            // allowance rather than setting a flag means Windfury loses both swings,
            // which is the behaviour Freeze is supposed to have.
            if (creature.Frozen)
            {
                creature.Frozen = false;
                creature.AttacksThisTurn = creature.AttacksAllowed;
            }
        }
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

    /// <summary>
    /// The single source of randomness for card effects, so a duel is reproducible from
    /// a seed. Same reason the console harness already takes --seed: a bug you cannot
    /// replay is a bug you cannot fix.
    /// </summary>
    public Random Random { get; init; } = new();

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
public sealed record UseHeroPower(BoardCreature? Target) : PlayerAction;
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
                case UseHeroPower power:
                    TryUseHeroPower(state, power.Target);
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
            summoned.LandedOnTurn = state.TurnNumber;
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
                SpellDamageApplies = card.Type == CardType.Spell,
                Log = new ResolutionLog(),
            };
            effect(ctx);
            state.Log.AddRange(ctx.Log.Lines);
        }

        CleanupDead(state);
        return true;
    }

    /// <summary>
    /// Every target this creature may legally attack right now. Null in the returned list
    /// means the enemy caster.
    ///
    /// Exists so the AI and the UI ask the engine what is legal instead of each
    /// re-deriving Taunt, Rush, and Stealth and drifting out of sync. GreedyAI proposing
    /// an attack TryAttack then refuses is an infinite loop, which is exactly what
    /// happened when Rush was added.
    /// </summary>
    public static List<BoardCreature?> LegalAttackTargets(DuelState state, BoardCreature attacker)
    {
        var targets = new List<BoardCreature?>();
        if (!state.Active.Board.Contains(attacker) || !attacker.CanAttackNow) return targets;

        var opponent = state.Waiting;
        var visible = opponent.Board.Where(c => c.IsAlive && !c.Stealth).ToList();
        var taunts = visible.Where(c => c.Taunt).ToList();

        if (taunts.Count > 0)
        {
            targets.AddRange(taunts);
            return targets;
        }

        targets.AddRange(visible);

        // Rush may not hit the enemy caster on the turn it lands; Charge may.
        var justLanded = attacker.Rush && !attacker.Charge && state.TurnNumber == attacker.LandedOnTurn;
        if (!justLanded) targets.Add(null);

        return targets;
    }

    /// <summary>
    /// Resolves one attack, applying every combat keyword.
    ///
    /// Order matters and follows Hearthstone's own: Taunt and Stealth restrict what may
    /// be chosen; both damages are computed before either lands so a dying creature still
    /// trades back; Divine Shield absorbs inside TakeDamage; Poisonous and Lifesteal read
    /// the damage actually dealt, so a shielded hit neither poisons nor heals.
    /// </summary>
    /// <summary>
    /// Uses the active caster's hero power. Once per turn, costs its own mana, and
    /// resolves through the same effect pipeline as a card, so nothing about targeting
    /// or Spell Damage needs a special case.
    /// </summary>
    public static bool TryUseHeroPower(DuelState state, BoardCreature? target)
    {
        var owner = state.Active;
        var opponent = state.Waiting;
        var power = CardSet.PowerFor(owner.Class);

        if (owner.HeroPowerUsedThisTurn || owner.Pips < power.Cost) return false;
        if (power.Targeting == TargetRule.RequiredCreature && target is null) return false;
        if (target is not null && (!opponent.Board.Contains(target) || !target.IsAlive || target.Stealth))
            return false;

        owner.Pips -= power.Cost;
        owner.HeroPowerUsedThisTurn = true;
        state.Log.Add($"{owner.Name} uses {power.Name}.");

        if (power.OnUse is { } effect)
        {
            var ctx = new DuelContext
            {
                State = state, Owner = owner, Opponent = opponent,
                Target = target, IsFirstSpellThisTurn = false, Log = new ResolutionLog(),
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

        if (!owner.Board.Contains(attacker) || !attacker.CanAttackNow)
            return false;

        // Rush may hit creatures but not the enemy caster on the turn it lands. Charge may
        // hit anything. SummoningSick is already false for both by this point, so the
        // distinction has to be drawn here.
        var justLanded = attacker.AttacksThisTurn == 0 && attacker.Rush && !attacker.Charge
                         && state.TurnNumber == attacker.LandedOnTurn;
        if (target is null && justLanded)
            return false;

        // Stealth hides a creature from being chosen as a target.
        var enemyTaunts = opponent.Board.Where(c => c.Taunt && c.IsAlive && !c.Stealth).ToList();
        if (enemyTaunts.Count > 0 && (target is null || !enemyTaunts.Contains(target)))
            return false;
        if (target is not null && target.Stealth)
            return false;

        attacker.AttacksThisTurn++;
        attacker.OnDealtDamage(); // attacking always breaks Stealth

        int dealt;
        if (target is null)
        {
            dealt = attacker.Attack;
            opponent.Health -= dealt;
            state.Log.Add($"{attacker.Source.Name} attacks {opponent.Name} for {dealt}.");
        }
        else
        {
            if (!opponent.Board.Contains(target) || !target.IsAlive)
                return false;

            var incoming = target.Attack;
            dealt = target.TakeDamage(attacker.Attack);
            var taken = attacker.TakeDamage(incoming);

            state.Log.Add($"{attacker.Source.Name} trades with {target.Source.Name} ({attacker.Attack} <-> {incoming}).");

            if (dealt > 0 && attacker.Poisonous) { target.Destroy(); state.Log.Add($"{target.Source.Name} succumbs to poison."); }
            if (taken > 0 && target.Poisonous) { attacker.Destroy(); state.Log.Add($"{attacker.Source.Name} succumbs to poison."); }

            if (taken > 0)
            {
                target.OnDealtDamage();
                if (target.Lifesteal)
                {
                    opponent.Health = Math.Min(opponent.MaxHealth, opponent.Health + taken);
                    state.Log.Add($"{opponent.Name} drains {taken}.");
                }
            }
        }

        if (dealt > 0 && attacker.Lifesteal)
        {
            owner.Health = Math.Min(owner.MaxHealth, owner.Health + dealt);
            state.Log.Add($"{owner.Name} drains {dealt}.");
        }

        CleanupDead(state);
        return true;
    }

    private static void CleanupDead(DuelState state)
    {
        for (var pass = 0; pass < 8; pass++)
        {
            var removed = 0;
            foreach (var (owner, opponent) in new[] { (state.A, state.B), (state.B, state.A) })
            {
                var dead = owner.Board.Where(c => !c.IsAlive).ToList();
                if (dead.Count == 0) continue;

                owner.Board.RemoveAll(c => !c.IsAlive);
                removed += dead.Count;

                // Deathrattles fire after the body leaves the board, so a rattle that
                // summons cannot collide with the corpse for a board slot.
                foreach (var corpse in dead.Where(c => c.Source.OnDeath is not null))
                {
                    state.Log.Add($"{corpse.Source.Name}'s deathrattle triggers.");
                    var ctx = new DuelContext
                    {
                        State = state, Owner = owner, Opponent = opponent,
                        Target = null, IsFirstSpellThisTurn = false, Log = new ResolutionLog(),
                    };
                    corpse.Source.OnDeath!(ctx);
                    state.Log.AddRange(ctx.Log.Lines);
                }
            }
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
