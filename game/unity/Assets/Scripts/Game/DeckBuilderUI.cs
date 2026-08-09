using System;
using System.Collections.Generic;
using System.Linq;
using Eyeland.Duel;
using UnityEngine;
using UnityEngine.UI;

namespace Eyeland.Game
{
    /// <summary>
    /// v1 Deck's actual contribution: pick your deck before the duel instead of always
    /// playing the fixed symmetric starter. The pool is still the same 10 cards from v0 —
    /// deckbuilding is about composition choice, not needing more cards to prove it.
    /// </summary>
    public sealed class DeckBuilderUI : MonoBehaviour
    {
        private const int MinDeckSize = 12;
        private const int MaxCopiesCommon = 2;
        private const int MaxCopiesLegendary = 1;

        private readonly Dictionary<CardDef, int> _counts = new();
        private Text _deckSizeText;
        private Button _startButton;
        private Action<List<CardDef>> _onReady;

        public static DeckBuilderUI Build(Transform parent, Action<List<CardDef>> onReady)
        {
            var go = new GameObject("DeckBuilder", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            UIFactory.SetFullStretch(rt);

            var ui = go.AddComponent<DeckBuilderUI>();
            ui._onReady = onReady;
            ui.BuildLayout(rt);
            return ui;
        }

        private void BuildLayout(RectTransform root)
        {
            var bg = UIFactory.CreatePanel(root, UIFactory.Abyss);
            UIFactory.SetFullStretch(bg);

            var title = UIFactory.CreateText(root, "Build your deck", 32, UIFactory.Mist, TextAnchor.MiddleLeft);
            var titleRt = (RectTransform)title.transform;
            titleRt.anchorMin = new Vector2(0, 1);
            titleRt.anchorMax = new Vector2(1, 1);
            titleRt.pivot = new Vector2(0.5f, 1);
            titleRt.sizeDelta = new Vector2(0, 60);
            titleRt.anchoredPosition = new Vector2(0, -20);
            title.alignment = TextAnchor.MiddleCenter;

            var subtitle = UIFactory.CreateText(root,
                $"Pick at least {MinDeckSize} cards — up to {MaxCopiesCommon} copies each, {MaxCopiesLegendary} for the Legendary.",
                16, UIFactory.Fog, TextAnchor.MiddleCenter);
            var subRt = (RectTransform)subtitle.transform;
            subRt.anchorMin = new Vector2(0, 1);
            subRt.anchorMax = new Vector2(1, 1);
            subRt.pivot = new Vector2(0.5f, 1);
            subRt.sizeDelta = new Vector2(0, 30);
            subRt.anchoredPosition = new Vector2(0, -68);

            // scrollable card list
            var listArea = new GameObject("CardList", typeof(RectTransform));
            var listRt = (RectTransform)listArea.transform;
            listRt.SetParent(root, false);
            listRt.anchorMin = new Vector2(0.05f, 0.14f);
            listRt.anchorMax = new Vector2(0.95f, 0.86f);
            listRt.offsetMin = Vector2.zero;
            listRt.offsetMax = Vector2.zero;
            UIFactory.AddVerticalLayout(listArea, spacing: 4, padding: new RectOffset(0, 0, 0, 0));

            foreach (var card in CardSet.All)
            {
                _counts[card] = 0;
                BuildCardRow(listRt, card);
            }

            // footer: deck size + start button
            var footer = new GameObject("Footer", typeof(RectTransform));
            var footerRt = (RectTransform)footer.transform;
            footerRt.SetParent(root, false);
            footerRt.anchorMin = new Vector2(0.05f, 0f);
            footerRt.anchorMax = new Vector2(0.95f, 0.12f);
            footerRt.offsetMin = Vector2.zero;
            footerRt.offsetMax = Vector2.zero;
            UIFactory.AddHorizontalLayout(footer, spacing: 16);

            _deckSizeText = UIFactory.CreateText(footerRt, "Deck size: 0", 20, UIFactory.Mist, TextAnchor.MiddleLeft);
            var sizeLe = UIFactory.SetPreferredHeight(_deckSizeText.gameObject, 48);
            sizeLe.preferredWidth = 220;

            _startButton = UIFactory.CreateButton(footerRt, "Start Duel", UIFactory.Arcane, OnStartClicked, 20);
            UIFactory.SetPreferredHeight(_startButton.gameObject, 48);

            RefreshDeckSize();
        }

        private void BuildCardRow(Transform parent, CardDef card)
        {
            var row = new GameObject($"Row_{card.Id}", typeof(RectTransform), typeof(Image));
            var rowRt = (RectTransform)row.transform;
            rowRt.SetParent(parent, false);
            row.GetComponent<Image>().color = UIFactory.Panel;
            UIFactory.SetPreferredHeight(row, 44);
            UIFactory.AddHorizontalLayout(row, spacing: 10, padding: new RectOffset(14, 14, 5, 5));

            var swatch = UIFactory.CreatePanel(rowRt, UIFactory.ElementColor(card.Element));
            var swatchLe = UIFactory.SetPreferredHeight(swatch.gameObject, 30);
            swatchLe.preferredWidth = 8;

            var label = UIFactory.CreateText(rowRt,
                $"{card.Name}  ({card.Cost}){(card.Type == CardType.Creature ? $"  [{card.Attack}/{card.Health}]" : "")}",
                17, UIFactory.Mist, TextAnchor.MiddleLeft);
            label.gameObject.AddComponent<LayoutElement>().flexibleWidth = 1;

            var rarityText = UIFactory.CreateText(rowRt, card.Rarity.ToString(), 13, UIFactory.Fog, TextAnchor.MiddleRight);
            rarityText.gameObject.AddComponent<LayoutElement>().preferredWidth = 90;

            var minus = UIFactory.CreateButton(rowRt, "-", UIFactory.Panel, () => ChangeCount(card, -1), 20);
            minus.gameObject.AddComponent<LayoutElement>().preferredWidth = 36;

            var countText = UIFactory.CreateText(rowRt, "0", 18, UIFactory.Mist, TextAnchor.MiddleCenter);
            countText.gameObject.AddComponent<LayoutElement>().preferredWidth = 30;
            countText.name = $"Count_{card.Id}";

            var maxCopies = card.Rarity == Rarity.Legendary ? MaxCopiesLegendary : MaxCopiesCommon;
            var plus = UIFactory.CreateButton(rowRt, "+", UIFactory.Panel, () => ChangeCount(card, 1), 20);
            plus.gameObject.AddComponent<LayoutElement>().preferredWidth = 36;

            _countLabels[card] = countText;
            _maxCopies[card] = maxCopies;
        }

        private readonly Dictionary<CardDef, Text> _countLabels = new();
        private readonly Dictionary<CardDef, int> _maxCopies = new();

        private void ChangeCount(CardDef card, int delta)
        {
            var next = Mathf.Clamp(_counts[card] + delta, 0, _maxCopies[card]);
            _counts[card] = next;
            _countLabels[card].text = next.ToString();
            RefreshDeckSize();
        }

        private void RefreshDeckSize()
        {
            var total = _counts.Values.Sum();
            _deckSizeText.text = $"Deck size: {total}";
            _deckSizeText.color = total >= MinDeckSize ? UIFactory.Mist : UIFactory.Danger;
            _startButton.interactable = total >= MinDeckSize;
        }

        private void OnStartClicked()
        {
            var deck = new List<CardDef>();
            foreach (var kv in _counts)
                for (var i = 0; i < kv.Value; i++)
                    deck.Add(kv.Key);

            _onReady?.Invoke(deck);
            Destroy(gameObject);
        }
    }
}
