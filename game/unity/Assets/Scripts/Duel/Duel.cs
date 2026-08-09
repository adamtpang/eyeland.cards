using System;
using System.Collections.Generic;
using System.Linq;

namespace Eyeland.Duel;

/// <summary>A live creature on the board — its own Attack/Health, independent of the CardDef it came from.</summary>
public sealed class BoardCreature
{
    public required CardDef Source { get; init; }
    public int Attack { get; set; }
    public int Health { get; set; }
    public bool Taunt { get; set; }
    public bool CanAttack { get; set; }
    public bool IsAlive => Health > 0;

    public static BoardCreature FromCard(CardDef card) => new()
    {
        Source = card,
        Attack = card.Attack,
        Health = card.Health,
        Taunt = card.Taunt,
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

            target.Health -= attacker.Attack;
            attacker.Health -= target.Attack;
            state.Log.Add($"{attacker.Source.Name} trades with {target.Source.Name} ({attacker.Attack} <-> {target.Attack}).");
        }

        CleanupDead(state);
        return true;
    }

    private static void CleanupDead(DuelState state)
    {
        state.A.Board.RemoveAll(c => !c.IsAlive);
        state.B.Board.RemoveAll(c => !c.IsAlive);
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
