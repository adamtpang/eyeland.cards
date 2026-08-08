namespace Eyeland.Duel;

/// <summary>
/// A dumb-but-legal opponent for v0: play the most expensive affordable card each step
/// (aiming damage at the strongest enemy creature when a target is useful), then attack
/// with everything that can attack, respecting taunt. Enough to prove the duel loop is
/// fun to play against — balance-quality AI is a later problem.
/// </summary>
public sealed class GreedyAI : IPlayerController
{
    public string Name { get; }

    public GreedyAI(string name) => Name = name;

    public PlayerAction ChooseAction(DuelState state, Caster me, Caster opponent)
    {
        var playable = me.Hand.Where(c => c.Cost <= me.Pips).OrderByDescending(c => c.Cost).ToList();
        if (playable.Count > 0)
        {
            var card = playable[0];
            BoardCreature? target = card.Targeting switch
            {
                TargetRule.None => null,
                _ => opponent.Board.Where(c => c.IsAlive).OrderByDescending(c => c.Attack).FirstOrDefault(),
            };
            if (card.Targeting == TargetRule.RequiredCreature && target is null)
            {
                // No legal creature to hit — this card is unplayable right now, skip it.
                playable.RemoveAt(0);
            }
            else
            {
                return new PlayCard(card, target);
            }
        }

        var attacker = me.Board.FirstOrDefault(c => c.CanAttack && c.IsAlive);
        if (attacker is not null)
        {
            var enemyTaunt = opponent.Board.FirstOrDefault(c => c.Taunt && c.IsAlive);
            return new AttackAction(attacker, enemyTaunt);
        }

        return new PassTurn();
    }
}
