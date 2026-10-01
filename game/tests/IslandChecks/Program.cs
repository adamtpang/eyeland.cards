using Eyeland.Duel;
void Check(bool ok, string message) { if (!ok) throw new Exception(message); }
var run = new IslandRun(42);
Check(!run.RecordVictory(2), "locked reward");
for (var i=0;i<4;i++) { Check(run.RecordVictory(i), "victory"); Check(!run.RecordVictory(i), "duplicate"); }
Check(run.Complete && run.Resources==20 && run.Owned()["ember-reach-warden"]==1,"completion");
try { run.SetDeck(Enumerable.Repeat("ember-bolt",12)); throw new Exception("illegal deck accepted"); } catch(ArgumentException) { }
Check(run.Creature(2).Aura != null, "epic aura");
Console.WriteLine("PASS: reward, ownership, deck integrity, four rarities, completion");
var winningSeeds = Enumerable.Range(0,100).ToHashSet();
for(var camp=0;camp<4;camp++)
{
    int wins=0; int max=0;
    for(var seed=0;seed<100;seed++)
    {
        var island = new IslandRun(seed,camp);
        var ids=island.DeckIds.Select(id => camp>0 && id=="riptide" ? "cinder-wolf" : camp>1 && id=="stormcaller-elemental" ? "tidewisp" : camp>2 && id=="squall-caller" ? "galehart" : id).ToArray();
        island.SetDeck(ids);
        var rng=new Random(unchecked(seed + camp * 7919));
        List<CardDef> Shuffle(List<CardDef> cards) { for(var j=cards.Count-1;j>0;j--) {var k=rng.Next(j+1); (cards[j],cards[k])=(cards[k],cards[j]);} return cards; }
        var a=new Caster{Name="Player",Deck=Shuffle(island.Deck())};
        var b=new Caster{Name="Creature",Health=island.EnemyHealth(camp),MaxHealth=island.EnemyHealth(camp),Deck=Shuffle(island.EnemyDeck(camp))};
        var log=new ResolutionLog();a.DealOpeningHand(3,log);b.DealOpeningHand(3,log);
        var state=new DuelState{A=a,B=b,Random=rng};
        TurnEngine.RunGame(state,new GreedyAI("Player"),new GreedyAI("Creature"));
        Check(state.IsOver,"unfinished duel");
        if(state.Winner==a)wins++; else winningSeeds.Remove(seed); max=Math.Max(max,state.TurnNumber);
    }
    Console.WriteLine($"Camp {camp+1}: {wins}/100 player AI wins; longest {max} turns. Synthetic balance signal, not human fun evidence.");
}

Console.WriteLine("Four-win fixture seeds: " + string.Join(",",winningSeeds.Take(8)));
