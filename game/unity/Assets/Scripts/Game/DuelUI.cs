using System;
using System.Collections.Generic;
using System.Linq;
using Eyeland.Duel;
using UnityEngine;
using UnityEngine.UI;

namespace Eyeland.Game
{
    /// <summary>
    /// Turns clicks into the exact same TurnEngine calls the console harness made from
    /// typed commands. Human turns are click-driven (event-based); AI turns run in a tight
    /// synchronous loop since GreedyAI.ChooseAction never blocks -- see Duel.cs's TurnEngine
    /// doc comment for why RunGame's blocking loop can't be reused directly here.
    /// </summary>
    public sealed class DuelUI : MonoBehaviour
    {
        private DuelState _state;
        private GreedyAI _ai;
        private Action _onRematch;
        private IslandRun _run;
        private Action<bool> _onResult;
        private float _deadline;
        private bool _finished;
        private Text _timer;
        private int _encounter;
        private System.Random _shuffleRandom;
        private void Update()
        {
            if (_finished || _state == null || _state.IsOver) return;
            if (_timer != null) _timer.text = $"YOUR TURN · {Mathf.CeilToInt(Mathf.Max(0, _deadline - Time.unscaledTime))}s";
            if (Time.unscaledTime >= _deadline) { ClearPending(); OnEndTurnClicked(); }
        }

        private RectTransform _root;
        private Text _opponentInfo;
        private Text _playerInfo;
        private Text _logText;
        private RectTransform _opponentBoardRow;
        private RectTransform _playerBoardRow;
        private RectTransform _handRow;
        private RectTransform _targetPrompt;
        private Text _targetPromptText;
        private Button _faceTargetButton;
        private Button _endTurnButton;
        private Button _heroPowerButton;

        private CardDef _pendingCard;
        private BoardCreature _pendingAttacker;

        public static DuelUI Build(Transform parent, List<CardDef> playerDeck, Action onRematch, IslandRun run = null, Action<bool> onResult = null)
        {
            var go = new GameObject("Duel", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            UIFactory.SetFullStretch(rt);

            var ui = go.AddComponent<DuelUI>();
            ui._onRematch = onRematch;
            ui._run = run; ui._onResult = onResult; ui._encounter = run?.Cleared ?? 0;
            ui._shuffleRandom = new System.Random(run == null ? Environment.TickCount : unchecked(run.Seed + ui._encounter * 7919));
            ui._root = rt;
            ui.StartDuel(playerDeck);
            return ui;
        }

        // Fisher-Yates -- see game/src/Eyeland.Duel.Console/Program.cs's Shuffled() for why
        // this replaced OrderBy(_ => rng.Next()), same fix applied on both sides.
        private List<T> Shuffled<T>(List<T> list)
        {
            var rng = _shuffleRandom;
            var result = new List<T>(list);
            for (var i = result.Count - 1; i > 0; i--)
            {
                var j = rng.Next(i + 1);
                (result[i], result[j]) = (result[j], result[i]);
            }
            return result;
        }

        private void StartDuel(List<CardDef> playerDeck)
        {
            var player = new Caster { Name = "Wayfinder", Deck = Shuffled(playerDeck) };
            var opponent = new Caster { Name = _run == null ? "The Warden" : _run.Creature(_encounter).Name, Deck = Shuffled(_run == null ? CardSet.StarterDeck() : _run.EnemyDeck(_encounter)), Health = _run?.EnemyHealth(_encounter) ?? 30, MaxHealth = _run?.EnemyHealth(_encounter) ?? 30 };
            _state = new DuelState { A = player, B = opponent, Random = _shuffleRandom };
            _ai = new GreedyAI(opponent.Name);

            BuildLayout();

            var log = new ResolutionLog();
            _state.Active = _state.A;
            _state.A.DealOpeningHand(3, log);
            _state.B.DealOpeningHand(3, log);
            _state.A.StartTurn(log);
            _deadline = Time.unscaledTime + 60;
            _state.Log.AddRange(log.Lines);

            Refresh();
            if (UnityEngine.EventSystems.EventSystem.current != null) UnityEngine.EventSystems.EventSystem.current.SetSelectedGameObject(_endTurnButton.gameObject);
        }

        private void OnHeroPowerClicked()
        {
            if (_finished || _state.Active != _state.A || _pendingCard != null || _pendingAttacker != null) return;
            TurnEngine.TryUseHeroPower(_state, null);
            Refresh();
        }

        private void BuildLayout()
        {
            UIFactory.CreateBackdrop(_root);
            _timer = UIFactory.CreateText(_root, "YOUR TURN · 60s", 14, UIFactory.Foreground, TextAnchor.MiddleCenter);
            var timerRt = (RectTransform)_timer.transform;
            timerRt.anchorMin = new Vector2(.3f, .71f); timerRt.anchorMax = new Vector2(.7f, .77f);
            timerRt.offsetMin = timerRt.offsetMax = Vector2.zero;
            if (_run != null)
            {
                var retreat = UIFactory.CreateButton(_root, "Retreat", UIFactory.SurfaceMuted, () => { _state.A.Health = 0; Refresh(); }, 14);
                var retreatRt = (RectTransform)retreat.transform;
                retreatRt.anchorMin = new Vector2(.03f, .72f); retreatRt.anchorMax = new Vector2(.18f, .78f);
                retreatRt.offsetMin = retreatRt.offsetMax = Vector2.zero;
            }

            var power = CardSet.PowerFor(PlayerClass.Neutral);
            _heroPowerButton = UIFactory.CreateButton(_root, $"{power.Name} ({power.Cost})\nHeal 2", UIFactory.SurfaceMuted, OnHeroPowerClicked, 12);
            var powerRt = (RectTransform)_heroPowerButton.transform;
            powerRt.anchorMin = new Vector2(.03f, .60f); powerRt.anchorMax = new Vector2(.18f, .69f);
            powerRt.offsetMin = powerRt.offsetMax = Vector2.zero;

            // Opponent HUD and board float over the archipelago instead of filling a dark strip.
            var oppHud = NewRegion("OpponentHUD", 0.02f, 0.82f, 0.27f, 0.97f);
            var oppHudImage = oppHud.gameObject.AddComponent<Image>();
            oppHudImage.color = UIFactory.WithAlpha(UIFactory.Surface, 0.94f);
            UIFactory.StyleRounded(oppHudImage, shadow: true);
            UIFactory.AddOutline(oppHudImage, UIFactory.WithAlpha(UIFactory.Border, 0.72f));
            _opponentInfo = UIFactory.CreateText(
                oppHud,
                "",
                16,
                UIFactory.Foreground,
                TextAnchor.MiddleLeft);
            var oppInfoRt = (RectTransform)_opponentInfo.transform;
            UIFactory.SetFullStretch(oppInfoRt);
            oppInfoRt.offsetMin = new Vector2(14, 8);
            oppInfoRt.offsetMax = new Vector2(-14, -8);

            var opponentBoard = NewRegion("OpponentBoard", 0.29f, 0.79f, 0.98f, 0.97f);
            _opponentBoardRow = NewRow(opponentBoard, 0f, 0f, 1f, 1f);

            // A compact event ribbon leaves the central island visible as the arena.
            var logRegion = NewRegion("Log", 0.21f, 0.57f, 0.79f, 0.69f);
            var logPanel = UIFactory.CreatePanel(
                logRegion,
                UIFactory.WithAlpha(UIFactory.Surface, 0.90f),
                rounded: true,
                shadow: true,
                name: "EventRibbon");
            UIFactory.SetFullStretch(logPanel);
            UIFactory.AddOutline(logPanel.GetComponent<Image>(), UIFactory.WithAlpha(UIFactory.Border, 0.72f));
            _logText = UIFactory.CreateText(
                logPanel,
                "",
                12,
                UIFactory.MutedForeground,
                TextAnchor.MiddleLeft);
            var logRt = (RectTransform)_logText.transform;
            logRt.anchorMin = Vector2.zero;
            logRt.anchorMax = Vector2.one;
            logRt.offsetMin = new Vector2(16, 10);
            logRt.offsetMax = new Vector2(-16, -10);
            _logText.verticalOverflow = VerticalWrapMode.Truncate;

            // Target prompt (shown only while choosing a target)
            _targetPrompt = NewRegion("TargetPrompt", 0.18f, 0.49f, 0.82f, 0.57f);
            var promptPanel = UIFactory.CreatePanel(
                _targetPrompt,
                UIFactory.WithAlpha(UIFactory.SurfaceElevated, 0.97f),
                rounded: true,
                shadow: true,
                name: "TargetPromptPanel");
            UIFactory.SetFullStretch(promptPanel);
            UIFactory.AddOutline(promptPanel.GetComponent<Image>(), UIFactory.Ring, 2f);
            UIFactory.AddHorizontalLayout(promptPanel.gameObject, spacing: 10, padding: new RectOffset(12, 12, 7, 7));
            _targetPromptText = UIFactory.CreateText(
                promptPanel,
                "",
                13,
                UIFactory.Primary,
                TextAnchor.MiddleLeft,
                emphasis: true);
            _targetPromptText.gameObject.AddComponent<LayoutElement>().flexibleWidth = 1;
            _faceTargetButton = UIFactory.CreateButton(
                promptPanel,
                "Target face",
                UIFactory.Primary,
                OnTargetFaceClicked,
                13,
                UIFactory.PrimaryForeground);
            _faceTargetButton.gameObject.AddComponent<LayoutElement>().preferredWidth = 120;
            var cancelBtn = UIFactory.CreateButton(
                promptPanel,
                "Cancel",
                UIFactory.SurfaceMuted,
                CancelPending,
                13,
                UIFactory.Foreground,
                shadow: false);
            cancelBtn.gameObject.AddComponent<LayoutElement>().preferredWidth = 88;
            _targetPrompt.gameObject.SetActive(false);

            // Player HUD, board, and action sit above the hand as three clear zones.
            var playerHud = NewRegion("PlayerHUD", 0.02f, 0.30f, 0.27f, 0.46f);
            var playerHudImage = playerHud.gameObject.AddComponent<Image>();
            playerHudImage.color = UIFactory.WithAlpha(UIFactory.Surface, 0.95f);
            UIFactory.StyleRounded(playerHudImage, shadow: true);
            UIFactory.AddOutline(playerHudImage, UIFactory.WithAlpha(UIFactory.Border, 0.72f));
            _playerInfo = UIFactory.CreateText(
                playerHud,
                "",
                16,
                UIFactory.Foreground,
                TextAnchor.MiddleLeft);
            var pInfoRt = (RectTransform)_playerInfo.transform;
            UIFactory.SetFullStretch(pInfoRt);
            pInfoRt.offsetMin = new Vector2(14, 8);
            pInfoRt.offsetMax = new Vector2(-14, -8);

            var endTurnHolder = NewRegion("EndTurnHolder", 0.80f, 0.32f, 0.98f, 0.45f);
            _endTurnButton = UIFactory.CreateButton(
                endTurnHolder,
                "End Turn",
                UIFactory.Accent,
                OnEndTurnClicked,
                17,
                UIFactory.Foreground);
            var etRt = (RectTransform)_endTurnButton.transform;
            etRt.anchorMin = Vector2.zero;
            etRt.anchorMax = Vector2.one;
            etRt.offsetMin = Vector2.zero;
            etRt.offsetMax = Vector2.zero;

            var playerBoard = NewRegion("PlayerBoard", 0.29f, 0.29f, 0.78f, 0.49f);
            _playerBoardRow = NewRow(playerBoard, 0f, 0f, 1f, 1f);

            // Hand (bottom strip)
            var handRegion = NewRegion("Hand", 0.02f, 0.01f, 0.98f, 0.28f);
            var handImage = handRegion.gameObject.AddComponent<Image>();
            handImage.color = UIFactory.WithAlpha(UIFactory.Surface, 0.92f);
            UIFactory.StyleRounded(handImage, shadow: true);
            UIFactory.AddOutline(handImage, UIFactory.WithAlpha(UIFactory.Border, 0.68f));
            _handRow = NewRow(handRegion, 0f, 0f, 1f, 1f);
        }

        private RectTransform NewRegion(string name, float xMin, float yMin, float xMax, float yMax, Transform parent = null)
        {
            var go = new GameObject(name, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent != null ? parent : _root, false);
            rt.anchorMin = new Vector2(xMin, yMin);
            rt.anchorMax = new Vector2(xMax, yMax);
            rt.offsetMin = Vector2.zero;
            rt.offsetMax = Vector2.zero;
            return rt;
        }

        private RectTransform NewRow(Transform parent, float xMin, float yMin, float xMax, float yMax)
        {
            var go = new GameObject("Row", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = new Vector2(xMin, yMin);
            rt.anchorMax = new Vector2(xMax, yMax);
            rt.offsetMin = Vector2.zero;
            rt.offsetMax = Vector2.zero;
            UIFactory.AddHorizontalLayout(go, spacing: 8, padding: new RectOffset(10, 10, 8, 8));
            return rt;
        }

        // ---------------------------------------------------------------
        // Rendering
        // ---------------------------------------------------------------

        private void Refresh()
        {
            if (_state.IsOver)
            {
                ShowEndScreen();
                return;
            }

            var me = _state.A;
            var opp = _state.B;

            _opponentInfo.text = $"<size=10>{opp.Name.ToUpperInvariant()}</size>\n<b>{opp.Health} HP</b>   {opp.Pips}/{opp.MaxPips} PIPS";
            _playerInfo.text = $"<size=10>WAYFINDER</size>\n<b>{me.Health} HP</b>   {me.Pips}/{me.MaxPips} PIPS";

            RenderBoard(_opponentBoardRow, opp.Board, isEnemyBoard: true);
            RenderBoard(_playerBoardRow, me.Board, isEnemyBoard: false);
            RenderHand(me);

            var recent = _state.Log.Skip(Mathf.Max(0, _state.Log.Count - 2));
            _logText.text = string.Join("\n", recent);

            _endTurnButton.interactable = _pendingCard == null && _pendingAttacker == null;
            _heroPowerButton.interactable = _endTurnButton.interactable && !me.HeroPowerUsedThisTurn && me.Pips >= CardSet.PowerFor(me.Class).Cost;
            var events = UnityEngine.EventSystems.EventSystem.current;
            if (events != null && (events.currentSelectedGameObject == null || !events.currentSelectedGameObject.activeInHierarchy))
            {
                var next = _endTurnButton.interactable ? _endTurnButton : _faceTargetButton.gameObject.activeInHierarchy ? _faceTargetButton : _opponentBoardRow.GetComponentsInChildren<Button>().FirstOrDefault(b => b.interactable);
                if (next != null) events.SetSelectedGameObject(next.gameObject);
            }
        }

        private void RenderBoard(RectTransform row, List<BoardCreature> board, bool isEnemyBoard)
        {
            ClearChildren(row);
            if (board.Count == 0)
            {
                UIFactory.CreateText(row, "OPEN BOARD", 10, UIFactory.MutedForeground, TextAnchor.MiddleCenter, emphasis: true);
                return;
            }

            foreach (var creature in board)
            {
                var name = UIFactory.EscapeRichText(creature.Source.Name);
                var state = creature.Taunt ? "  TAUNT" : !isEnemyBoard && !creature.CanAttackNow ? "  RESTING" : string.Empty;
                var label = $"<b>{name}</b>\n<size=10>{creature.Attack} ATK   {creature.Health} HP{state}</size>";
                var btn = UIFactory.CreateButton(
                    row,
                    label,
                    UIFactory.ElementSurfaceColor(creature.Source.Element),
                    () => OnCreatureClicked(creature, isEnemyBoard),
                    12,
                    UIFactory.Foreground);
                btn.GetComponentInChildren<Text>().gameObject.SetActive(false);
                CardVisual.Draw(btn.transform, creature.Source, attack: creature.Attack, health: creature.Health, state: state.Trim());
                CardVisual.Attach(btn.gameObject, creature.Source);
                var layout = btn.gameObject.AddComponent<LayoutElement>();
                layout.preferredWidth = Mathf.Min(112, (row.rect.width - 20 - (board.Count-1)*8) / board.Count);
                layout.flexibleWidth = 0;
                UIFactory.AddOutline(
                    btn.GetComponent<Image>(),
                    UIFactory.WithAlpha(UIFactory.ElementColor(creature.Source.Element), 0.68f));

                if (isEnemyBoard)
                {
                    // Only clickable when we're actively choosing a target for a card or attack.
                    btn.interactable = _pendingCard != null || _pendingAttacker != null;
                }
                else
                {
                    btn.interactable = creature.CanAttackNow && creature.IsAlive && _pendingCard == null;
                }
            }
        }

        private void RenderHand(Caster me)
        {
            ClearChildren(_handRow);
            var availableWidth = Mathf.Max(320f, _handRow.rect.width - 20f);
            var preferredWidth = Mathf.Clamp(
                (availableWidth - Mathf.Max(0, me.Hand.Count - 1) * 8f) / Mathf.Max(1, me.Hand.Count),
                82f,
                158f);
            foreach (var card in me.Hand)
            {
                var affordable = card.Cost <= me.Pips;
                var name = UIFactory.EscapeRichText(card.Name);
                var rules = UIFactory.EscapeRichText(card.Text);
                var stats = card.Type == CardType.Creature ? $"   {card.Attack}/{card.Health}" : string.Empty;
                var label = $"<size=16><b>{card.Cost}</b></size>  <b>{name}</b>{stats}\n<size=10><color=#58717A>{rules}</color></size>";
                var btn = UIFactory.CreateButton(
                    _handRow,
                    label,
                    UIFactory.ElementSurfaceColor(card.Element),
                    () => OnHandCardClicked(card),
                    preferredWidth < 110f ? 10 : 12,
                    UIFactory.Foreground);
                var layout = btn.gameObject.AddComponent<LayoutElement>();
                layout.preferredWidth = preferredWidth;
                layout.flexibleWidth = 0;
                UIFactory.AddOutline(
                    btn.GetComponent<Image>(),
                    UIFactory.WithAlpha(UIFactory.ElementColor(card.Element), 0.74f));
                btn.GetComponentInChildren<Text>().gameObject.SetActive(false);
                CardVisual.Draw(btn.transform, card);
                CardVisual.Attach(btn.gameObject, card);
                btn.interactable = affordable && _pendingAttacker == null;
            }
        }

        private static void ClearChildren(Transform parent)
        {
            for (var i = parent.childCount - 1; i >= 0; i--)
                { parent.GetChild(i).gameObject.SetActive(false); UnityEngine.Object.Destroy(parent.GetChild(i).gameObject); }
        }

        // ---------------------------------------------------------------
        // Interaction
        // ---------------------------------------------------------------

        private void OnHandCardClicked(CardDef card)
        {
            ClearPending();

            if (card.Targeting == TargetRule.None)
            {
                TurnEngine.TryPlayCard(_state, card, null);
                Refresh();
                return;
            }

            _pendingCard = card;
            _targetPrompt.gameObject.SetActive(true);
            _targetPromptText.text = $"Choose a target for {UIFactory.EscapeRichText(card.Name)}";
            _faceTargetButton.gameObject.SetActive(card.Targeting == TargetRule.OptionalCreature);
            Refresh();
        }

        private void OnCreatureClicked(BoardCreature creature, bool isEnemyBoard)
        {
            if (_pendingCard != null && isEnemyBoard)
            {
                TurnEngine.TryPlayCard(_state, _pendingCard, creature);
                ClearPending();
                Refresh();
                return;
            }

            if (_pendingAttacker != null && isEnemyBoard)
            {
                TurnEngine.TryAttack(_state, _pendingAttacker, creature);
                ClearPending();
                Refresh();
                return;
            }

            if (!isEnemyBoard && creature.CanAttackNow && creature.IsAlive && _pendingCard == null)
            {
                _pendingAttacker = creature;
                _targetPrompt.gameObject.SetActive(true);
                _targetPromptText.text = $"{UIFactory.EscapeRichText(creature.Source.Name)}: choose a target or hit face";
                _faceTargetButton.gameObject.SetActive(true);
                Refresh();
            }
        }

        private void OnTargetFaceClicked()
        {
            if (_pendingCard != null)
                TurnEngine.TryPlayCard(_state, _pendingCard, null);
            else if (_pendingAttacker != null)
                TurnEngine.TryAttack(_state, _pendingAttacker, null);

            ClearPending();
            Refresh();
        }

        private void CancelPending()
        {
            ClearPending();
            Refresh();
        }

        private void ClearPending()
        {
            _pendingCard = null;
            _pendingAttacker = null;
            _targetPrompt.gameObject.SetActive(false);
        }

        private void OnEndTurnClicked()
        {
            if (_finished || _state.IsOver) return;
            _deadline = Time.unscaledTime + 60;
            if (_pendingCard != null || _pendingAttacker != null) return;

            TurnEngine.EndTurn(_state); // hands the turn to the AI (state.Active becomes B)

            var guard = 0;
            while (!_state.IsOver && _state.Active == _state.B && guard++ < 200)
            {
                var action = _ai.ChooseAction(_state, _state.B, _state.A);
                switch (action)
                {
                    case PlayCard play:
                        TurnEngine.TryPlayCard(_state, play.Card, play.Target);
                        break;
                    case AttackAction attack:
                        TurnEngine.TryAttack(_state, attack.Attacker, attack.Target);
                        break;
                    case UseHeroPower power:
                        TurnEngine.TryUseHeroPower(_state, power.Target);
                        break;
                    case PassTurn:
                        if (!_state.IsOver)
                            TurnEngine.EndTurn(_state); // hands the turn back to the player; while's own
                                                         // condition check exits the loop next iteration
                        break;
                }
            }

            Refresh();
        }

        private void ShowEndScreen()
        {
            if (_finished) return;
            _finished = true;
            _onResult?.Invoke(_state.Winner == _state.A);
            ClearChildren(_root);
            UIFactory.CreateBackdrop(_root);

            var won = _state.Winner == _state.A;
            var draw = _state.Winner == null;
            var headline = draw ? "Draw: both casters collapsed from fatigue."
                : won ?  $"You win! {_state.B.Name} falls." : "Defeated. Your cards are safe. Try again.";
            if (won && _run != null) headline += $"\nEarned {(_encounter == 3 ? 1 : 2)} × {_run.Creature(_encounter).Name} + {2 * (_encounter + 1)} ember shards.";
            var color = draw ? UIFactory.MutedForeground : won ? UIFactory.Primary : UIFactory.Destructive;

            var resultPanel = UIFactory.CreatePanel(
                _root,
                UIFactory.WithAlpha(UIFactory.Surface, 0.96f),
                rounded: true,
                shadow: true,
                name: "ResultPanel");
            resultPanel.anchorMin = new Vector2(0.20f, 0.30f);
            resultPanel.anchorMax = new Vector2(0.80f, 0.70f);
            resultPanel.offsetMin = Vector2.zero;
            resultPanel.offsetMax = Vector2.zero;
            UIFactory.AddOutline(resultPanel.GetComponent<Image>(), UIFactory.WithAlpha(UIFactory.Border, 0.78f));

            var eyebrow = UIFactory.CreateText(
                resultPanel,
                "DUEL COMPLETE",
                11,
                UIFactory.MutedForeground,
                TextAnchor.MiddleCenter,
                emphasis: true);
            var eyebrowRt = (RectTransform)eyebrow.transform;
            eyebrowRt.anchorMin = new Vector2(0.08f, 0.68f);
            eyebrowRt.anchorMax = new Vector2(0.92f, 0.88f);
            eyebrowRt.offsetMin = Vector2.zero;
            eyebrowRt.offsetMax = Vector2.zero;

            var text = UIFactory.CreateText(resultPanel, headline, 20, color, TextAnchor.MiddleCenter, emphasis: true);
            var textRt = (RectTransform)text.transform;
            textRt.anchorMin = new Vector2(0.08f, 0.38f);
            textRt.anchorMax = new Vector2(0.92f, 0.70f);
            textRt.offsetMin = Vector2.zero;
            textRt.offsetMax = Vector2.zero;

            var again = UIFactory.CreateButton(resultPanel, _run == null ? "Build a new deck" : "Return to island", UIFactory.Primary, () =>
            {
                _onRematch?.Invoke();
                Destroy(gameObject);
            }, 17, UIFactory.PrimaryForeground);
            var againRt = (RectTransform)again.transform;
            againRt.anchorMin = new Vector2(0.30f, 0.12f);
            againRt.anchorMax = new Vector2(0.70f, 0.32f);
            againRt.offsetMin = Vector2.zero;
            againRt.offsetMax = Vector2.zero;
            if (UnityEngine.EventSystems.EventSystem.current != null) UnityEngine.EventSystems.EventSystem.current.SetSelectedGameObject(again.gameObject);
        }
    }
}
