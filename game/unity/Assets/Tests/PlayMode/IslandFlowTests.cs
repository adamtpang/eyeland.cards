using System;
using System.Collections;
using System.Linq;
using System.Reflection;
using Eyeland.Duel;
using Eyeland.Game;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;
using UnityEngine.UI;

namespace Eyeland.Tests
{
    public class IslandFlowTests
    {
        [Test] public void RewardsAreOwnedOnceAndDeckSurvivesRoundtrip()
        {
            var run = new IslandRun(20260911);
            Assert.False(run.RecordVictory(1));
            Assert.True(run.RecordVictory(0));
            Assert.False(run.RecordVictory(0));
            Assert.AreEqual(2, run.Resources);
            Assert.AreEqual(2, run.Owned()["cinder-wolf"]);
            var deck = run.DeckIds.ToArray(); deck[0] = "cinder-wolf"; deck[1] = "cinder-wolf";
            run.SetDeck(deck);
            var restored = IslandStorage.Decode(IslandStorage.Encode(run));
            CollectionAssert.AreEqual(deck, restored.DeckIds);
            Assert.AreEqual(run.Seed, restored.Seed);
            Assert.AreEqual(run.Resources, restored.Resources);
            Assert.AreEqual(run.Cleared, restored.Cleared);
            for (var i = 1; i < 4; i++) Assert.True(restored.RecordVictory(i));
            Assert.True(restored.Complete);
            Assert.AreEqual(20, restored.Resources);
            Assert.AreEqual(1, restored.Owned()["ember-reach-warden"]);
            Assert.False(restored.RecordVictory(3));
            Assert.AreEqual(Rarity.Epic, restored.Creature(2).Rarity);
            Assert.NotNull(restored.Creature(2).Aura);
        }
        [Test] public void InvalidInventoryAndSaveAreRejected()
        {
            Assert.Throws<ArgumentException>(() => IslandStorage.Decode("{}"));
            Assert.Throws<ArgumentException>(() => new IslandRun(1, 5));
            var run = new IslandRun(1);
            Assert.Throws<ArgumentException>(() => run.SetDeck(Enumerable.Repeat("ember-reach-warden",12)));
            Assert.Throws<ArgumentException>(() => run.SetDeck(Enumerable.Repeat("ember-bolt",12)));
            Assert.Throws<ArgumentException>(() => run.SetDeck(new string[0]));
        }
        [Test] public void SeededEncountersAreReproducibleAndPlayable()
        {
            var run = new IslandRun(18);
            for (var i=0;i<4;i++)
            {
                CollectionAssert.AreEqual(run.EnemyDeck(i), new IslandRun(18).EnemyDeck(i));
                Assert.AreEqual(12, run.EnemyDeck(i).Count);
                Assert.True(run.EnemyDeck(i).Any(c => c.Id == IslandRun.Creatures[i]));
            }
        }
        [UnityTest] public IEnumerator CorruptSaveRequiresConfirmationAndSaveFailureCanRetry()
        {
            const string key = "eyeland.tests.island.fixture";
            var canvas = UIFactory.CreateRootCanvas("IslandRecoveryTestCanvas");
            PlayerPrefs.SetString(key, "corrupt fixture");
            var ui = IslandUI.Build(canvas.transform, key);
            yield return null;
            Button Find(string label) => ui.GetComponentsInChildren<Button>().First(b => b.GetComponentInChildren<Text>().text == label);
            Assert.False(Find("Edit deck").interactable);
            Find("New expedition").onClick.Invoke(); yield return null;
            Assert.AreEqual("corrupt fixture", PlayerPrefs.GetString(key));
            Find("Confirm new expedition").onClick.Invoke(); yield return null;
            Assert.AreEqual(0, IslandStorage.Decode(PlayerPrefs.GetString(key)).Cleared);
            UnityEngine.Object.Destroy(ui.gameObject); yield return null;
            bool fail = true;
            ui = IslandUI.Build(canvas.transform, key, run => { if (fail) throw new Exception("fixture write failure"); IslandStorage.Save(run,key); });
            Find("Retry save").onClick.Invoke(); yield return null;
            Assert.True(ui.GetComponentsInChildren<Text>().Any(t => t.text.Contains("Saving failed")));
            fail = false;
            Find("Retry save").onClick.Invoke(); yield return null;
            Assert.True(ui.GetComponentsInChildren<Text>().Any(t => t.text.Contains("Saved on this device")));
            PlayerPrefs.DeleteKey(key); PlayerPrefs.Save();
            UnityEngine.Object.Destroy(canvas.gameObject); yield return null;
        }
        [UnityTest] public IEnumerator FourEncounterUiJourneyPersistsRewardsAndEditedDeck()
        {
            const string key = "eyeland.tests.journey.fixture";
            IslandStorage.Save(new IslandRun(0), key);
            var canvas = UIFactory.CreateRootCanvas("IslandJourneyTestCanvas");
            var island = IslandUI.Build(canvas.transform, key);
            yield return null;
            var flags = BindingFlags.NonPublic | BindingFlags.Instance;
            string[] cuts = { "riptide", "stormcaller-elemental", "squall-caller" };
            for (int camp = 0; camp < 4; camp++)
            {
                island.GetComponentsInChildren<Button>().First(b => b.GetComponentInChildren<Text>().text.StartsWith("DUEL ·")).onClick.Invoke();
                yield return null;
                var ui = canvas.GetComponentInChildren<DuelUI>();
                Assert.NotNull(ui);
                var state = (DuelState)typeof(DuelUI).GetField("_state", flags).GetValue(ui);
                if (camp > 0) Assert.AreEqual(2,state.A.Deck.Concat(state.A.Hand).Count(c=>c.Id==IslandRun.Creatures[camp-1]), "Earned cards must reach the actual next duel deck");
                void Invoke(string method, params object[] args) => typeof(DuelUI).GetMethod(method, flags).Invoke(ui,args);
                var ai = new GreedyAI("test player");
                int guard = 0;
                while (!state.IsOver && guard++ < 200)
                {
                    var action = ai.ChooseAction(state,state.A,state.B);
                    switch(action)
                    {
                        case PlayCard play:
                            Invoke("OnHandCardClicked",play.Card);
                            if (play.Card.Targeting != TargetRule.None)
                            {
                                if (play.Target == null) Invoke("OnTargetFaceClicked");
                                else Invoke("OnCreatureClicked",play.Target,true);
                            }
                            break;
                        case AttackAction attack:
                            Invoke("OnCreatureClicked",attack.Attacker,false);
                            if (attack.Target == null) Invoke("OnTargetFaceClicked");
                            else Invoke("OnCreatureClicked",attack.Target,true);
                            break;
                        case UseHeroPower: Invoke("OnHeroPowerClicked"); break;
                        case PassTurn: Invoke("OnEndTurnClicked"); break;
                        default: Assert.Fail("Unexpected neutral action"); break;
                    }
                    yield return null;
                }
                Assert.AreSame(state.A,state.Winner,$"Fixture should win camp {camp}");
                Assert.AreEqual(camp+1,IslandStorage.Decode(PlayerPrefs.GetString(key)).Cleared);
                ui.GetComponentsInChildren<Button>().Single(b => b.GetComponentInChildren<Text>().text=="Return to island").onClick.Invoke();
                yield return null;
                if (camp == 3) break;
                island.GetComponentsInChildren<Button>().Single(b => b.GetComponentInChildren<Text>().text=="Edit deck").onClick.Invoke();
                yield return null;
                var builder = canvas.GetComponentInChildren<DeckBuilderUI>();
                Button RowAction(string id,string text) => builder.GetComponentsInChildren<RectTransform>().First(t => t.name=="Row_"+id).GetComponentsInChildren<Button>().First(b=>b.GetComponentInChildren<Text>().text==text);
                for(var copy=0;copy<2;copy++) { RowAction(cuts[camp],"-").onClick.Invoke(); RowAction(IslandRun.Creatures[camp],"+").onClick.Invoke(); }
                var save = builder.GetComponentsInChildren<Button>().Single(b => b.GetComponentInChildren<Text>().text=="Save deck");
                Assert.True(save.interactable); save.onClick.Invoke();
                yield return null;
                Assert.AreEqual(2,IslandStorage.Decode(PlayerPrefs.GetString(key)).DeckIds.Count(id=>id==IslandRun.Creatures[camp]));
            }
            UnityEngine.Object.Destroy(island.gameObject); yield return null;
            island = IslandUI.Build(canvas.transform,key); yield return null;
            Assert.True(island.GetComponentsInChildren<Text>().Any(t=>t.text.Contains("4/4 cleared") && t.text.Contains("20 ember shards")));
            PlayerPrefs.DeleteKey(key); PlayerPrefs.Save();
            UnityEngine.Object.Destroy(canvas.gameObject); yield return null;
        }
        [UnityTest] public IEnumerator TimerEndsPendingTurnAndReportsLossOnce()
        {
            var canvas = UIFactory.CreateRootCanvas("IslandTestCanvas");
            int results = 0;
            var run = new IslandRun(12);
            var ui = DuelUI.Build(canvas.transform, run.Deck(), () => {}, run, won => results++);
            yield return null;
            var flags = BindingFlags.NonPublic | BindingFlags.Instance;
            var state = (DuelState)typeof(DuelUI).GetField("_state",flags).GetValue(ui);
            Assert.AreEqual("Cinder Wolf", state.B.Name);
            Assert.AreEqual(4, state.A.Hand.Count);
            typeof(DuelUI).GetField("_pendingCard",flags).SetValue(ui,run.Deck().First(c=>c.Targeting==TargetRule.OptionalCreature));
            typeof(DuelUI).GetField("_deadline",flags).SetValue(ui, -1f);
            yield return null;
            Assert.Greater(state.TurnNumber, 1);
            Assert.IsNull(typeof(DuelUI).GetField("_pendingCard",flags).GetValue(ui));
            state.A.Health = 0;
            typeof(DuelUI).GetMethod("Refresh",flags).Invoke(ui,null);
            typeof(DuelUI).GetMethod("Refresh",flags).Invoke(ui,null);
            Assert.AreEqual(1,results);
            Assert.AreEqual(0,run.Cleared);
            UnityEngine.Object.Destroy(canvas.gameObject);
            yield return null;
        }
    }
}
