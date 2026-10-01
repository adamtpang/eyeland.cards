using System;
using System.Linq;
using Eyeland.Duel;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace Eyeland.Game
{
    [Serializable] public sealed class IslandSave
    {
        public int version = 1;
        public int seed;
        public int cleared;
        public string[] deck;
    }

    public static class IslandStorage
    {
        public const string Key = "eyeland.island.v1";
        public static IslandRun Decode(string json)
        {
            var data = JsonUtility.FromJson<IslandSave>(json);
            if (data == null || data.version != 1 || data.deck == null)
                throw new ArgumentException("Save format is not supported.");
            return new IslandRun(data.seed, data.cleared, data.deck);
        }
        public static string Encode(IslandRun run) => JsonUtility.ToJson(new IslandSave
            { seed = run.Seed, cleared = run.Cleared, deck = run.DeckIds.ToArray() });
        public static void Save(IslandRun run, string key = Key)
        {
            PlayerPrefs.SetString(key, Encode(run));
            PlayerPrefs.Save();
        }
    }

    /// <summary>Navigation map for the first expedition; every encounter uses DuelUI.</summary>
    public sealed class IslandUI : MonoBehaviour
    {
        private IslandRun _run;
        private Action<IslandRun> _persist;
        private Transform _parent;
        private string _notice = "";
        private bool _invalidSave;
        private bool _confirmReset;
        public static IslandUI Build(Transform parent, string storageKey = IslandStorage.Key, Action<IslandRun> persist = null)
        {
            var go = new GameObject("Island", typeof(RectTransform));
            go.transform.SetParent(parent, false);
            UIFactory.SetFullStretch((RectTransform)go.transform);
            var ui = go.AddComponent<IslandUI>(); ui._parent = parent;
            ui._persist = persist ?? (run => IslandStorage.Save(run, storageKey));
            try { ui._run = PlayerPrefs.HasKey(storageKey) ? IslandStorage.Decode(PlayerPrefs.GetString(storageKey)) : new IslandRun(Environment.TickCount); }
            catch (Exception) { ui._run = new IslandRun(Environment.TickCount); ui._invalidSave = true; ui._notice = "Your save could not be read. It has been preserved. Confirm a new expedition to replace it."; }
            ui.Render(); return ui;
        }
        private bool Save()
        {
            if (_invalidSave) return false;
            try { _persist(_run); return true; }
            catch (Exception) { _notice = "Saving failed. Keep this window open and choose Retry save."; return false; }
        }
        private void Place(RectTransform rt, float x, float y, float w, float h)
        {
            rt.anchorMin = new Vector2(x, y); rt.anchorMax = new Vector2(x+w, y+h);
            rt.offsetMin = rt.offsetMax = Vector2.zero;
        }
        private void Label(string value, float y, float height, int size = 18)
        {
            var t = UIFactory.CreateText(transform, value, size, UIFactory.Foreground, TextAnchor.MiddleCenter);
            Place((RectTransform)t.transform, .06f, y, .88f, height);
        }
        private Button Button(string label, float x, float y, float w, Action action, int fontSize = 16)
        {
            var b = UIFactory.CreateButton(transform, label, UIFactory.Primary, action, fontSize, UIFactory.PrimaryForeground);
            Place((RectTransform)b.transform, x, y, w, .085f); return b;
        }
        private void Render()
        {
            foreach (Transform child in transform) { child.gameObject.SetActive(false); Destroy(child.gameObject); }
            UIFactory.CreateBackdrop(transform);
            var panel = UIFactory.CreatePanel(transform, UIFactory.WithAlpha(UIFactory.Surface, .94f), true);
            Place(panel, .035f, .03f, .93f, .94f);
            Label("EYELAND · EMBER REACH", .84f, .10f, 30);
            Label($"Expedition {_run.Seed}  ·  {_run.Cleared}/4 cleared  ·  {_run.Resources} ember shards", .77f, .065f);
            Label("Defeat creatures. Earn their cards. Rebuild your deck for the next fight.\nIn battle: click a card to play; click your creature, then its target to attack. Each turn lasts 60 seconds.", .65f, .11f, 15);
            for (var i=0; i<4; i++)
            {
                var index = i; var creature = _run.Creature(i);
                var state = i < _run.Cleared ? "CLEARED" : i == _run.Cleared ? "DUEL" : "LOCKED";
                var copies = i == 3 ? 1 : 2;
                var b = Button($"{state} · {IslandRun.Places[i]}\n<size=11>{creature.Name} · {creature.Rarity} · {copies} card(s) + {2*(i+1)} shards</size>", .09f, .53f-i*.105f, .82f, () => Begin(index), 14);
                b.interactable = !_invalidSave && i == _run.Cleared;
            }
            Label(_notice.Length > 0 ? _notice : _run.Complete ? "The island is yours. Your Warden card is now in your collection." : "Choose the unlocked camp to begin.", .13f, .07f, 15);
            var edit = Button("Edit deck", .09f, .045f, .23f, Edit); edit.interactable = !_invalidSave;
            Button(_confirmReset ? "Confirm new expedition" : "New expedition", .34f, .045f, .32f, () =>
            {
                if (!_confirmReset) { _confirmReset = true; _notice = "This replaces this expedition's saved progress. Click Confirm to continue, or Cancel to keep it."; Render(); return; }
                _run = new IslandRun(Environment.TickCount); _invalidSave = false; _confirmReset = false;
                _notice = "New expedition started."; Save(); Render();
            });
            var retry = Button(_confirmReset ? "Cancel" : "Retry save", .68f, .045f, .23f, () =>
            {
                if (_confirmReset) { _confirmReset = false; _notice = _invalidSave ? "Unreadable save preserved. Start a new expedition when ready." : "Your expedition is unchanged."; }
                else if (Save()) _notice = "Saved on this device.";
                Render();
            });
            retry.interactable = !_invalidSave || _confirmReset;
            Label("LOCAL PROTOTYPE · Progress saves between duels on this device/browser. Leaving a fight restarts it. No cloud save.", .005f, .03f, 10);
            var first = GetComponentsInChildren<Button>().FirstOrDefault(b => b.interactable);
            if (first != null && EventSystem.current != null) EventSystem.current.SetSelectedGameObject(first.gameObject);
        }
        private void Edit()
        {
            _confirmReset = false; gameObject.SetActive(false);
            DeckBuilderUI.Build(_parent, deck => { _run.SetDeck(deck.Select(c => c.Id)); Save(); gameObject.SetActive(true); Render(); }, _run);
        }
        private void Begin(int index)
        {
            if (index != _run.Cleared || _run.Complete || !Save()) { Render(); return; }
            _confirmReset = false; gameObject.SetActive(false);
            DuelUI.Build(_parent, _run.Deck(), () => { gameObject.SetActive(true); Render(); }, _run, won =>
            {
                if (won && _run.RecordVictory(index))
                { _notice = $"Earned {(index==3 ? 1 : 2)} × {_run.Creature(index).Name} and {2*(index+1)} ember shards. Edit your deck to use your reward."; Save(); }
                else _notice = "Your collection is safe. Edit your deck or retry the same creature.";
            });
        }
    }
}
