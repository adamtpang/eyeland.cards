using System.Collections;
using System.Linq;
using Eyeland.Game;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;
using UnityEngine.UI;

namespace Eyeland.Tests
{
    /// <summary>
    /// Headless, click-free verification of the deckbuilder -> duel pipeline, run via the
    /// Unity CLI's -runTests (no Editor GUI, no manual clicking). Replaces the computer-use
    /// screenshot attempts from earlier in the project: GameFlow's RuntimeInitializeOnLoadMethod
    /// boots on entering Play mode the same way it would for a human, so these exercise the
    /// exact same code path.
    /// </summary>
    public class DeckBuilderFlowTests
    {
        [UnitySetUp]
        public IEnumerator SetUpFreshDeckBuilder()
        {
            var existing = GameObject.Find("EyelandUI");
            if (existing != null)
            {
                Object.Destroy(existing);
                yield return null;
            }

            var canvas = UIFactory.CreateRootCanvas("EyelandUI");
            DeckBuilderUI.Build(canvas.transform,
                deck => DuelUI.Build(canvas.transform, deck, () => { }));
            yield return null;
        }

        [UnityTearDown]
        public IEnumerator TearDownUI()
        {
            var existing = GameObject.Find("EyelandUI");
            if (existing != null)
                Object.Destroy(existing);
            yield return null;
        }

        [UnityTest]
        public IEnumerator DeckBuilderColumnIsWidthCappedAndResponsive()
        {
            var content = GameObject.Find("EyelandUI/DeckBuilder/Content");
            Assert.IsNotNull(content, "Expected DeckBuilderUI to build a 'Content' column.");

            var width = ((RectTransform)content.transform).rect.width;
            var parentWidth = ((RectTransform)content.transform.parent).rect.width;
            var expectedWidth = Mathf.Min(760f, Mathf.Max(320f, parentWidth - 36f));
            Assert.AreEqual(expectedWidth, width, 1f,
                $"Content should cap at 760 units and shrink with narrow screens ({Screen.width}); " +
                $"expected {expectedWidth}, was {width}.");
            yield break;
        }

        [UnityTest]
        public IEnumerator CardPoolUsesAClippedScrollView()
        {
            var cardList = GameObject.Find("EyelandUI/DeckBuilder/Content/CardList");
            Assert.IsNotNull(cardList, "Expected the deckbuilder's card list to exist.");

            var scrollRect = cardList.GetComponent<ScrollRect>();
            Assert.IsNotNull(scrollRect, "The full card pool must be contained by a ScrollRect.");
            Assert.IsNotNull(scrollRect.viewport, "The ScrollRect needs a clipped viewport.");
            Assert.IsNotNull(scrollRect.viewport.GetComponent<Mask>(), "The viewport must mask overflowing rows.");
            Assert.IsNotNull(scrollRect.content, "The ScrollRect needs a content transform.");
            Assert.Greater(scrollRect.content.rect.height, scrollRect.viewport.rect.height,
                "The card pool should be taller than the viewport so scrolling is meaningful.");
            yield break;
        }

        [UnityTest]
        public IEnumerator FooterActionsHaveVisibleStableWidths()
        {
            var footer = GameObject.Find("EyelandUI/DeckBuilder/Content/Footer");
            Assert.IsNotNull(footer, "Expected the deckbuilder footer to exist.");
            Canvas.ForceUpdateCanvases();

            var actions = footer.GetComponentsInChildren<Button>()
                .ToDictionary(button => button.GetComponentInChildren<Text>().text);
            Assert.Greater(((RectTransform)actions["Quick Play"].transform).rect.width, 120f,
                "Quick Play must not collapse to zero width in the horizontal layout.");
            Assert.Greater(((RectTransform)actions["Start Duel"].transform).rect.width, 120f,
                "Start Duel must not collapse to zero width in the horizontal layout.");
            yield break;
        }

        [UnityTest]
        public IEnumerator CanBuildADeckAndReachAPlayableDuel()
        {
            var cardList = GameObject.Find("EyelandUI/DeckBuilder/Content/CardList");
            Assert.IsNotNull(cardList, "Expected the deckbuilder's card list to exist.");

            var plusButtons = cardList.GetComponentsInChildren<Button>()
                .Where(b => b.GetComponentInChildren<Text>().text == "+")
                .ToList();
            Assert.IsTrue(plusButtons.Count > 0, "Expected '+' buttons in the card list.");

            var clicks = 0;
            foreach (var plus in plusButtons)
            {
                plus.onClick.Invoke();
                clicks++;
                plus.onClick.Invoke();
                clicks++;
                if (clicks >= 12) break;
            }

            var startButton = GameObject.Find("EyelandUI/DeckBuilder/Content/Footer")
                .GetComponentsInChildren<Button>()
                .First(b => b.GetComponentInChildren<Text>().text == "Start Duel");
            Assert.IsTrue(startButton.interactable, "Start Duel should enable once the 12-card minimum is met.");

            startButton.onClick.Invoke();
            yield return null;

            var duel = Object.FindAnyObjectByType<DuelUI>();
            Assert.IsNotNull(duel, "Expected DuelUI to be constructed after clicking Start Duel.");

            var handRow = GameObject.Find("EyelandUI/Duel/Hand/Row");
            Assert.IsNotNull(handRow, "Expected the duel screen's hand row to exist.");

            var handButtons = handRow.GetComponentsInChildren<Button>();
            Assert.IsTrue(handButtons.Length > 0,
                "Expected the opening hand to render at least one playable card button -- this is the " +
                "'can I actually reach and play a duel' check.");
        }
    }
}
