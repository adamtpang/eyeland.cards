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

        private CardDef _pendingCard;
        private BoardCreature _pendingAttacker;

        public static DuelUI Build(Transform parent, List<CardDef> playerDeck, Action onRematch)
        {
            var go = new GameObject("Duel", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            UIFactory.SetFullStretch(rt);

            var ui = go.AddComponent<DuelUI>();
            ui._onRematch = onRematch;
            ui._root = rt;
            ui.StartDuel(playerDeck);
            return ui;
        }

        private static List<T> Shuffled<T>(List<T> list)
        {
            var rng = new System.Random();
            return list.OrderBy(_ => rng.Next()).ToList();
        }

        private void StartDuel(List<CardDef> playerDeck)
        {
            var player = new Caster { Name = "You", Deck = Shuffled(playerDeck) };
            var opponent = new Caster { Name = "The Warden", Deck = Shuffled(CardSet.StarterDeck()) };
            _state = new DuelState { A = player, B = opponent };
            _ai = new GreedyAI(opponent.Name);

            BuildLayout();

            var log = new ResolutionLog();
            _state.Active = _state.A;
            _state.A.StartTurn(log);
            _state.Log.AddRange(log.Lines);

            Refresh();
        }

        private void BuildLayout()
        {
            var bg = UIFactory.CreatePanel(_root, UIFactory.Abyss);
            UIFactory.SetFullStretch(bg);

            // Opponent strip (top)
            var oppStrip = NewRegion("OpponentStrip", 0f, 0.86f, 1f, 1f);
            _opponentInfo = UIFactory.CreateText(oppStrip, "", 18, UIFactory.Mist, TextAnchor.MiddleLeft);
            var oppInfoRt = (RectTransform)_opponentInfo.transform;
            oppInfoRt.anchorMin = new Vector2(0, 0.5f);
            oppInfoRt.anchorMax = new Vector2(0.4f, 1f);
            oppInfoRt.offsetMin = new Vector2(16, 0);
            oppInfoRt.offsetMax = Vector2.zero;

            _opponentBoardRow = NewRow(oppStrip, 0f, 0f, 1f, 0.5f);

            // Log (middle)
            var logRegion = NewRegion("Log", 0f, 0.44f, 1f, 0.86f);
            var logPanel = UIFactory.CreatePanel(logRegion, UIFactory.Panel);
            UIFactory.SetFullStretch(logPanel);
            _logText = UIFactory.CreateText(logPanel, "", 14, UIFactory.Fog, TextAnchor.LowerLeft);
            var logRt = (RectTransform)_logText.transform;
            logRt.anchorMin = Vector2.zero;
            logRt.anchorMax = Vector2.one;
            logRt.offsetMin = new Vector2(14, 8);
            logRt.offsetMax = new Vector2(-14, -8);

            // Target prompt (shown only while choosing a target)
            _targetPrompt = NewRegion("TargetPrompt", 0f, 0.40f, 1f, 0.44f);
            var promptPanel = UIFactory.CreatePanel(_targetPrompt, new Color(UIFactory.Arcane.r, UIFactory.Arcane.g, UIFactory.Arcane.b, 0.18f));
            UIFactory.SetFullStretch(promptPanel);
            UIFactory.AddHorizontalLayout(promptPanel.gameObject, spacing: 12, padding: new RectOffset(14, 14, 4, 4));
            _targetPromptText = UIFactory.CreateText(promptPanel, "", 14, UIFactory.Arcane, TextAnchor.MiddleLeft);
            _targetPromptText.gameObject.AddComponent<LayoutElement>().flexibleWidth = 1;
            _faceTargetButton = UIFactory.CreateButton(promptPanel, "Target face", UIFactory.Arcane, OnTargetFaceClicked, 14);
            _faceTargetButton.gameObject.AddComponent<LayoutElement>().preferredWidth = 130;
            var cancelBtn = UIFactory.CreateButton(promptPanel, "Cancel", UIFactory.Danger, CancelPending, 14);
            cancelBtn.gameObject.AddComponent<LayoutElement>().preferredWidth = 100;
            _targetPrompt.gameObject.SetActive(false);

            // Player strip (bottom)
            var playerStrip = NewRegion("PlayerStrip", 0f, 0.14f, 1f, 0.40f);
            _playerInfo = UIFactory.CreateText(playerStrip, "", 18, UIFactory.Mist, TextAnchor.MiddleLeft);
            var pInfoRt = (RectTransform)_playerInfo.transform;
            pInfoRt.anchorMin = new Vector2(0, 0.62f);
            pInfoRt.anchorMax = new Vector2(0.4f, 1f);
            pInfoRt.offsetMin = new Vector2(16, 0);
            pInfoRt.offsetMax = Vector2.zero;

            var endTurnHolder = NewRegion("EndTurnHolder", 0.75f, 0.62f, 1f, 1f, playerStrip);
            _endTurnButton = UIFactory.CreateButton(endTurnHolder, "End Turn", UIFactory.Ember, OnEndTurnClicked, 18);
            var etRt = (RectTransform)_endTurnButton.transform;
            etRt.anchorMin = new Vector2(0.1f, 0.15f);
            etRt.anchorMax = new Vector2(0.9f, 0.85f);
            etRt.offsetMin = Vector2.zero;
            etRt.offsetMax = Vector2.zero;

            _playerBoardRow = NewRow(playerStrip, 0f, 0.30f, 1f, 0.60f);

            // Hand (bottom strip)
            var handRegion = NewRegion("Hand", 0f, 0f, 1f, 0.14f);
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
            UIFactory.AddHorizontalLayout(go, spacing: 8, padding: new RectOffset(16, 16, 4, 4));
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

            _opponentInfo.text = $"{opp.Name}\nHealth {opp.Health}   Pips {opp.Pips}/{opp.MaxPips}";
            _playerInfo.text = $"{me.Name}\nHealth {me.Health}   Pips {me.Pips}/{me.MaxPips}";

            RenderBoard(_opponentBoardRow, opp.Board, isEnemyBoard: true);
            RenderBoard(_playerBoardRow, me.Board, isEnemyBoard: false);
            RenderHand(me);

            var recent = _state.Log.Skip(Mathf.Max(0, _state.Log.Count - 10));
            _logText.text = string.Join("\n", recent);

            _endTurnButton.interactable = _pendingCard == null && _pendingAttacker == null;
        }

        private void RenderBoard(RectTransform row, List<BoardCreature> board, bool isEnemyBoard)
        {
            ClearChildren(row);
            if (board.Count == 0)
            {
                UIFactory.CreateText(row, "(empty board)", 13, UIFactory.Fog, TextAnchor.MiddleCenter);
                return;
            }

            foreach (var creature in board)
            {
                var label = $"{creature.Source.Name}\n{creature.Attack}/{creature.Health}" +
                            (creature.Taunt ? "  [Taunt]" : "") +
                            (!isEnemyBoard && !creature.CanAttack ? "  (tapped)" : "");
                var color = UIFactory.ElementColor(creature.Source.Element);
                var btn = UIFactory.CreateButton(row, label, color, () => OnCreatureClicked(creature, isEnemyBoard), 12);
                btn.gameObject.AddComponent<LayoutElement>().preferredWidth = 130;

                if (isEnemyBoard)
                {
                    // Only clickable when we're actively choosing a target for a card or attack.
                    btn.interactable = _pendingCard != null || _pendingAttacker != null;
                }
                else
                {
                    btn.interactable = creature.CanAttack && creature.IsAlive && _pendingCard == null;
                }
            }
        }

        private void RenderHand(Caster me)
        {
            ClearChildren(_handRow);
            foreach (var card in me.Hand)
            {
                var affordable = card.Cost <= me.Pips;
                var color = UIFactory.ElementColor(card.Element);
                var label = $"{card.Name} ({card.Cost})";
                var btn = UIFactory.CreateButton(_handRow, label, color, () => OnHandCardClicked(card), 13);
                btn.gameObject.AddComponent<LayoutElement>().preferredWidth = 150;
                btn.interactable = affordable && _pendingAttacker == null;
            }
        }

        private static void ClearChildren(Transform parent)
        {
            for (var i = parent.childCount - 1; i >= 0; i--)
                UnityEngine.Object.Destroy(parent.GetChild(i).gameObject);
        }

        // ---------------------------------------------------------------
        // Interaction
        // ---------------------------------------------------------------

        private void OnHandCardClicked(CardDef card)
        {
            _pendingAttacker = null;

            if (card.Targeting == TargetRule.None)
            {
                TurnEngine.TryPlayCard(_state, card, null);
                Refresh();
                return;
            }

            _pendingCard = card;
            _targetPrompt.gameObject.SetActive(true);
            _targetPromptText.text = $"Choose a target for {card.Name}...";
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

            if (!isEnemyBoard && creature.CanAttack && creature.IsAlive && _pendingCard == null)
            {
                _pendingAttacker = creature;
                _targetPrompt.gameObject.SetActive(true);
                _targetPromptText.text = $"Attack with {creature.Source.Name} -- choose a target or hit face.";
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
            ClearChildren(_root);
            var bg = UIFactory.CreatePanel(_root, UIFactory.Abyss);
            UIFactory.SetFullStretch(bg);

            var won = _state.Winner == _state.A;
            var draw = _state.Winner == null;
            var headline = draw ? "Draw -- both casters collapsed from fatigue."
                : won ? "You win! The Warden falls." : "You lose. The Warden stands over you.";
            var color = draw ? UIFactory.Fog : won ? UIFactory.Arcane : UIFactory.Danger;

            var text = UIFactory.CreateText(_root, headline, 30, color, TextAnchor.MiddleCenter);
            var textRt = (RectTransform)text.transform;
            textRt.anchorMin = new Vector2(0.1f, 0.55f);
            textRt.anchorMax = new Vector2(0.9f, 0.7f);
            textRt.offsetMin = Vector2.zero;
            textRt.offsetMax = Vector2.zero;

            var again = UIFactory.CreateButton(_root, "Build a new deck", UIFactory.Arcane, () =>
            {
                _onRematch?.Invoke();
                Destroy(gameObject);
            }, 18);
            var againRt = (RectTransform)again.transform;
            againRt.anchorMin = new Vector2(0.38f, 0.4f);
            againRt.anchorMax = new Vector2(0.62f, 0.48f);
            againRt.offsetMin = Vector2.zero;
            againRt.offsetMax = Vector2.zero;
        }
    }
}
