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
        private IslandRun _run;
        private const int MinDeckSize = 12;
        private const int MaxCopiesCommon = 2;
        private const int MaxCopiesLegendary = 1;

        private readonly Dictionary<CardDef, int> _counts = new();
        private Text _deckSizeText;
        private Button _startButton;
        private Action<List<CardDef>> _onReady;
        private RectTransform _content;

        public static DeckBuilderUI Build(Transform parent, Action<List<CardDef>> onReady, IslandRun run = null)
        {
            var go = new GameObject("DeckBuilder", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            UIFactory.SetFullStretch(rt);

            var ui = go.AddComponent<DeckBuilderUI>();
            ui._onReady = onReady;
            ui._run = run;
            ui.BuildLayout(rt);
            return ui;
        }

        // Fixed reading width for the deckbuilder column, independent of the actual screen's
        // aspect ratio. Anchoring rows to a fraction of the full canvas (the old approach)
        // meant a wide/ultrawide window stretched every row edge-to-edge, leaving the
        // left-aligned label swimming in blank space on the right — this is the bug Adam
        // found ("too wide with a lot of blank space"). A fixed-width, centered column
        // fixes it regardless of window shape.
        private const float ContentWidth = 760f;
        private const float ContentMargin = 18f;

        private void BuildLayout(RectTransform root)
        {
            UIFactory.CreateBackdrop(root);

            var content = new GameObject("Content", typeof(RectTransform));
            var contentRt = (RectTransform)content.transform;
            contentRt.SetParent(root, false);
            contentRt.anchorMin = new Vector2(0.5f, 0f);
            contentRt.anchorMax = new Vector2(0.5f, 1f);
            contentRt.pivot = new Vector2(0.5f, 0.5f);
            contentRt.sizeDelta = new Vector2(ContentWidth, 0);
            contentRt.anchoredPosition = Vector2.zero;
            _content = contentRt;
            UpdateContentWidth();

            var eyebrow = UIFactory.CreateText(
                contentRt,
                "WAYFINDER'S SPELLBOOK",
                11,
                UIFactory.Primary,
                TextAnchor.MiddleCenter,
                emphasis: true);
            var eyebrowRt = (RectTransform)eyebrow.transform;
            eyebrowRt.anchorMin = new Vector2(0, 1);
            eyebrowRt.anchorMax = new Vector2(1, 1);
            eyebrowRt.pivot = new Vector2(0.5f, 1);
            eyebrowRt.sizeDelta = new Vector2(0, 22);
            eyebrowRt.anchoredPosition = new Vector2(0, -10);

            var title = UIFactory.CreateText(
                contentRt,
                "Build your deck",
                34,
                UIFactory.Foreground,
                TextAnchor.MiddleCenter,
                emphasis: true);
            var titleRt = (RectTransform)title.transform;
            titleRt.anchorMin = new Vector2(0, 1);
            titleRt.anchorMax = new Vector2(1, 1);
            titleRt.pivot = new Vector2(0.5f, 1);
            titleRt.sizeDelta = new Vector2(0, 48);
            titleRt.anchoredPosition = new Vector2(0, -30);

            var subtitle = UIFactory.CreateText(contentRt,
                _run == null ? "Ember, tide, and storm answer your call." : "Choose exactly 12 cards. Remove a card before adding its replacement.",
                14, UIFactory.MutedForeground, TextAnchor.MiddleCenter);
            var subRt = (RectTransform)subtitle.transform;
            subRt.anchorMin = new Vector2(0, 1);
            subRt.anchorMax = new Vector2(1, 1);
            subRt.pivot = new Vector2(0.5f, 1);
            subRt.sizeDelta = new Vector2(0, 24);
            subRt.anchoredPosition = new Vector2(0, -76);

            // Keep the full card pool inside a clipped viewport. The content is taller than
            // the screen, so a layout group directly on CardList would spill over the title
            // and footer instead of producing an actual scrollable list.
            var listArea = new GameObject("CardList", typeof(RectTransform), typeof(Image), typeof(ScrollRect));
            var listRt = (RectTransform)listArea.transform;
            listRt.SetParent(contentRt, false);
            listRt.anchorMin = new Vector2(0f, 0.17f);
            listRt.anchorMax = new Vector2(1f, 0.80f);
            listRt.offsetMin = Vector2.zero;
            listRt.offsetMax = Vector2.zero;
            var listImage = listArea.GetComponent<Image>();
            listImage.color = UIFactory.WithAlpha(UIFactory.Surface, 0.94f);
            UIFactory.StyleRounded(listImage, shadow: true);
            UIFactory.AddOutline(listImage, UIFactory.WithAlpha(UIFactory.Border, 0.72f));

            var viewport = new GameObject("Viewport", typeof(RectTransform), typeof(Image), typeof(Mask));
            var viewportRt = (RectTransform)viewport.transform;
            viewportRt.SetParent(listRt, false);
            UIFactory.SetFullStretch(viewportRt);
            viewportRt.offsetMin = new Vector2(10, 10);
            viewportRt.offsetMax = new Vector2(-24, -10);
            var viewportImage = viewport.GetComponent<Image>();
            viewportImage.color = Color.white;
            viewport.GetComponent<Mask>().showMaskGraphic = false;

            var listContent = new GameObject("Content", typeof(RectTransform));
            var listContentRt = (RectTransform)listContent.transform;
            listContentRt.SetParent(viewportRt, false);
            listContentRt.anchorMin = new Vector2(0f, 1f);
            listContentRt.anchorMax = new Vector2(1f, 1f);
            listContentRt.pivot = new Vector2(0.5f, 1f);
            listContentRt.anchoredPosition = Vector2.zero;
            listContentRt.sizeDelta = Vector2.zero;
            UIFactory.AddVerticalLayout(listContent, spacing: 7, padding: new RectOffset(1, 1, 1, 1));

            var scrollbarGo = new GameObject("Scrollbar", typeof(RectTransform), typeof(Image), typeof(Scrollbar));
            var scrollbarRt = (RectTransform)scrollbarGo.transform;
            scrollbarRt.SetParent(listRt, false);
            scrollbarRt.anchorMin = new Vector2(1f, 0f);
            scrollbarRt.anchorMax = new Vector2(1f, 1f);
            scrollbarRt.pivot = new Vector2(1f, 0.5f);
            scrollbarRt.sizeDelta = new Vector2(8f, -20f);
            scrollbarRt.anchoredPosition = new Vector2(-8f, 0f);
            var scrollbarImage = scrollbarGo.GetComponent<Image>();
            scrollbarImage.color = UIFactory.SurfaceMuted;
            UIFactory.StyleRounded(scrollbarImage);

            var slidingArea = new GameObject("Sliding Area", typeof(RectTransform));
            var slidingAreaRt = (RectTransform)slidingArea.transform;
            slidingAreaRt.SetParent(scrollbarRt, false);
            UIFactory.SetFullStretch(slidingAreaRt);

            var handle = new GameObject("Handle", typeof(RectTransform), typeof(Image));
            var handleRt = (RectTransform)handle.transform;
            handleRt.SetParent(slidingAreaRt, false);
            UIFactory.SetFullStretch(handleRt);
            var handleImage = handle.GetComponent<Image>();
            handleImage.color = UIFactory.Primary;
            UIFactory.StyleRounded(handleImage);

            var scrollbar = scrollbarGo.GetComponent<Scrollbar>();
            scrollbar.handleRect = handleRt;
            scrollbar.targetGraphic = handle.GetComponent<Image>();
            scrollbar.direction = Scrollbar.Direction.BottomToTop;

            var scrollRect = listArea.GetComponent<ScrollRect>();
            scrollRect.viewport = viewportRt;
            scrollRect.content = listContentRt;
            scrollRect.horizontal = false;
            scrollRect.vertical = true;
            scrollRect.movementType = ScrollRect.MovementType.Clamped;
            scrollRect.scrollSensitivity = 32f;
            scrollRect.verticalScrollbar = scrollbar;
            scrollRect.verticalScrollbarVisibility = ScrollRect.ScrollbarVisibility.AutoHide;

            foreach (var card in CardSet.All.Where(c => _run == null || _run.Owned().ContainsKey(c.Id)))
            {
                _counts[card] = _run == null ? 0 : _run.DeckIds.Count(id => id == card.Id);
                BuildCardRow(listContentRt, card);
            }

            // footer: deck size + start button
            var footer = new GameObject("Footer", typeof(RectTransform));
            var footerRt = (RectTransform)footer.transform;
            footerRt.SetParent(contentRt, false);
            footerRt.anchorMin = new Vector2(0f, 0.025f);
            footerRt.anchorMax = new Vector2(1f, 0.145f);
            footerRt.offsetMin = Vector2.zero;
            footerRt.offsetMax = Vector2.zero;
            var footerImage = footer.AddComponent<Image>();
            footerImage.color = UIFactory.WithAlpha(UIFactory.Surface, 0.96f);
            UIFactory.StyleRounded(footerImage, shadow: true);
            UIFactory.AddOutline(footerImage, UIFactory.WithAlpha(UIFactory.Border, 0.72f));
            UIFactory.AddHorizontalLayout(footer, spacing: 12, padding: new RectOffset(12, 12, 10, 10));

            _deckSizeText = UIFactory.CreateText(
                footerRt,
                $"0 / {MinDeckSize} CARDS",
                17,
                UIFactory.Destructive,
                TextAnchor.MiddleCenter,
                emphasis: true);
            var sizeLe = UIFactory.SetPreferredHeight(_deckSizeText.gameObject, 48);
            sizeLe.preferredWidth = 190;

            // Building a deck by hand shouldn't be the only way in -- most people just want
            // to play. Quick Play hands them the same starter deck the AI opponent already
            // uses (CardSet.StarterDeck(), see DuelUI.cs) and skips this screen entirely.
            // The manual builder stays for anyone who wants to actually customize.
            // Violet, not Panel -- Panel is nearly the same dark navy as the screen's own
            // background and the card rows, so the button rendered but was invisible against
            // it. Needs a color that reads as a distinct button the way Arcane does for Start Duel.
            var quickPlay = UIFactory.CreateButton(
                footerRt,
                _run == null ? "Quick Play" : "Cancel",
                UIFactory.Secondary,
                OnQuickPlayClicked,
                17,
                UIFactory.Foreground);
            var quickPlayLayout = UIFactory.SetPreferredHeight(quickPlay.gameObject, 48);
            quickPlayLayout.preferredWidth = 170;

            _startButton = UIFactory.CreateButton(
                footerRt,
                _run == null ? "Start Duel" : "Save deck",
                UIFactory.Primary,
                OnStartClicked,
                18,
                UIFactory.PrimaryForeground);
            var startLayout = UIFactory.SetPreferredHeight(_startButton.gameObject, 48);
            startLayout.preferredWidth = 190;

            RefreshDeckSize();
            if (UnityEngine.EventSystems.EventSystem.current != null) UnityEngine.EventSystems.EventSystem.current.SetSelectedGameObject(quickPlay.gameObject);
        }

        private void BuildCardRow(Transform parent, CardDef card)
        {
            var row = new GameObject($"Row_{card.Id}", typeof(RectTransform), typeof(Image));
            var rowRt = (RectTransform)row.transform;
            rowRt.SetParent(parent, false);
            var rowImage = row.GetComponent<Image>();
            rowImage.color = UIFactory.WithAlpha(UIFactory.ElementSurfaceColor(card.Element), 0.98f);
            UIFactory.StyleRounded(rowImage, shadow: true);
            UIFactory.AddOutline(rowImage, UIFactory.WithAlpha(UIFactory.ElementColor(card.Element), 0.42f));
            UIFactory.SetPreferredHeight(row, 62);
            UIFactory.AddHorizontalLayout(row, spacing: 9, padding: new RectOffset(10, 10, 8, 8));

            var portraitHolder = new GameObject("Portrait", typeof(RectTransform), typeof(Image));
            portraitHolder.transform.SetParent(rowRt, false);
            portraitHolder.GetComponent<Image>().color = UIFactory.Surface;
            portraitHolder.AddComponent<LayoutElement>().preferredWidth = 46;
            CardVisual.Portrait(portraitHolder.transform, card);
            CardVisual.Attach(portraitHolder, card);

            var costBadge = UIFactory.CreatePanel(
                rowRt,
                UIFactory.ElementColor(card.Element),
                rounded: true,
                shadow: false,
                name: "Cost");
            var costLe = UIFactory.SetPreferredHeight(costBadge.gameObject, 38);
            costLe.preferredWidth = 38;
            var costText = UIFactory.CreateText(
                costBadge,
                card.Cost.ToString(),
                17,
                UIFactory.ElementForegroundColor(card.Element),
                TextAnchor.MiddleCenter,
                emphasis: true);
            UIFactory.SetFullStretch((RectTransform)costText.transform);

            var stats = card.Type == CardType.Creature ? $"  {card.Attack}/{card.Health}" : string.Empty;
            var safeName = UIFactory.EscapeRichText(card.Name);
            var safeText = UIFactory.EscapeRichText(card.Text);
            var label = UIFactory.CreateText(rowRt,
                $"<b>{safeName}</b>{stats}\n<size=11><color=#58717A>{safeText}</color></size>",
                15, UIFactory.Foreground, TextAnchor.MiddleLeft);
            label.gameObject.AddComponent<LayoutElement>().flexibleWidth = 1;
            label.verticalOverflow = VerticalWrapMode.Truncate;
            label.lineSpacing = 0.9f;

            var rarityText = UIFactory.CreateText(
                rowRt,
                card.Rarity.ToString().ToUpperInvariant() + (_run == null ? "" : $"\nOWNED {_run.Owned()[card.Id]}"),
                10,
                UIFactory.MutedForeground,
                TextAnchor.MiddleCenter,
                emphasis: true);
            rarityText.gameObject.AddComponent<LayoutElement>().preferredWidth = 78;

            var minus = UIFactory.CreateButton(
                rowRt,
                "-",
                UIFactory.SurfaceMuted,
                () => ChangeCount(card, -1),
                19,
                UIFactory.Foreground,
                shadow: false);
            minus.gameObject.AddComponent<LayoutElement>().preferredWidth = 34;

            var countText = UIFactory.CreateText(
                rowRt,
                _counts[card].ToString(),
                17,
                UIFactory.Foreground,
                TextAnchor.MiddleCenter,
                emphasis: true);
            countText.gameObject.AddComponent<LayoutElement>().preferredWidth = 30;
            countText.name = $"Count_{card.Id}";

            var maxCopies = _run != null ? _run.Owned()[card.Id] : card.Rarity == Rarity.Legendary ? MaxCopiesLegendary : MaxCopiesCommon;
            var plus = UIFactory.CreateButton(
                rowRt,
                "+",
                UIFactory.Primary,
                () => ChangeCount(card, 1),
                19,
                UIFactory.PrimaryForeground,
                shadow: false);
            plus.gameObject.AddComponent<LayoutElement>().preferredWidth = 34;

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
            _deckSizeText.text = $"{total} / {MinDeckSize} CARDS";
            _deckSizeText.color = (_run == null ? total >= MinDeckSize : total == IslandRun.DeckSize) ? UIFactory.Primary : UIFactory.Destructive;
            _startButton.interactable = _run == null ? total >= MinDeckSize : total == IslandRun.DeckSize;
        }

        private void OnRectTransformDimensionsChange() => UpdateContentWidth();

        private void UpdateContentWidth()
        {
            if (_content == null || _content.parent is not RectTransform parent) return;
            var available = Mathf.Max(320f, parent.rect.width - ContentMargin * 2f);
            _content.SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, Mathf.Min(ContentWidth, available));
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

        private void OnQuickPlayClicked()
        {
            _onReady?.Invoke(_run == null ? CardSet.StarterDeck() : _run.Deck());
            Destroy(gameObject);
        }
    }
}
