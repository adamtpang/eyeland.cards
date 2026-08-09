using System;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace Eyeland.Game
{
    /// <summary>
    /// Everything built here is runtime-constructed uGUI, on purpose: no hand-authored
    /// .unity scene files or Inspector wiring to keep in sync by hand. One bootstrap
    /// script builds the whole UI in code, same spirit as the console harness before it.
    /// </summary>
    public static class UIFactory
    {
        public static readonly Color Abyss = new(0.024f, 0.039f, 0.102f);
        public static readonly Color Panel = new(0.078f, 0.118f, 0.165f);
        public static readonly Color Mist = new(0.918f, 0.933f, 0.984f);
        public static readonly Color Fog = new(0.702f, 0.733f, 0.867f);
        public static readonly Color Arcane = new(0.208f, 0.890f, 0.816f);
        public static readonly Color Ember = new(1f, 0.718f, 0.396f);
        public static readonly Color Violet = new(0.608f, 0.482f, 1f);
        public static readonly Color Danger = new(0.925f, 0.38f, 0.36f);

        public static Font DefaultFont => Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");

        public static Canvas CreateRootCanvas(string name)
        {
            var canvasGo = new GameObject(name, typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            var canvas = canvasGo.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            var scaler = canvasGo.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(960, 600);
            scaler.matchWidthOrHeight = 0.5f;

            if (UnityEngine.Object.FindFirstObjectByType<EventSystem>() == null)
            {
                var es = new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));
                UnityEngine.Object.DontDestroyOnLoad(es);
            }

            return canvas;
        }

        public static RectTransform CreatePanel(Transform parent, Color color)
        {
            var go = new GameObject("Panel", typeof(RectTransform), typeof(Image));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            go.GetComponent<Image>().color = color;
            return rt;
        }

        public static Text CreateText(Transform parent, string text, int fontSize, Color color, TextAnchor anchor = TextAnchor.MiddleLeft)
        {
            var go = new GameObject("Text", typeof(RectTransform), typeof(Text));
            go.transform.SetParent(parent, false);
            var t = go.GetComponent<Text>();
            t.font = DefaultFont;
            t.text = text;
            t.fontSize = fontSize;
            t.color = color;
            t.alignment = anchor;
            t.horizontalOverflow = HorizontalWrapMode.Wrap;
            t.verticalOverflow = VerticalWrapMode.Overflow;
            return t;
        }

        public static Button CreateButton(Transform parent, string label, Color bg, Action onClick, int fontSize = 16)
        {
            var go = new GameObject("Button", typeof(RectTransform), typeof(Image), typeof(Button));
            go.transform.SetParent(parent, false);
            var img = go.GetComponent<Image>();
            img.color = bg;
            var btn = go.GetComponent<Button>();
            btn.targetGraphic = img;
            var colors = btn.colors;
            colors.highlightedColor = Color.Lerp(bg, Color.white, 0.15f);
            colors.pressedColor = Color.Lerp(bg, Color.black, 0.2f);
            colors.disabledColor = new Color(bg.r, bg.g, bg.b, 0.35f);
            btn.colors = colors;
            btn.onClick.AddListener(() => onClick?.Invoke());

            var text = CreateText(go.transform, label, fontSize, Abyss, TextAnchor.MiddleCenter);
            var textRt = (RectTransform)text.transform;
            textRt.anchorMin = Vector2.zero;
            textRt.anchorMax = Vector2.one;
            textRt.offsetMin = new Vector2(6, 4);
            textRt.offsetMax = new Vector2(-6, -4);

            return btn;
        }

        public static VerticalLayoutGroup AddVerticalLayout(GameObject go, int spacing = 8, RectOffset padding = null)
        {
            var v = go.AddComponent<VerticalLayoutGroup>();
            v.spacing = spacing;
            v.padding = padding ?? new RectOffset(12, 12, 12, 12);
            v.childForceExpandWidth = true;
            v.childForceExpandHeight = false;
            v.childControlHeight = true;
            v.childControlWidth = true;
            go.AddComponent<ContentSizeFitter>().verticalFit = ContentSizeFitter.FitMode.PreferredSize;
            return v;
        }

        public static HorizontalLayoutGroup AddHorizontalLayout(GameObject go, int spacing = 8, RectOffset padding = null)
        {
            var h = go.AddComponent<HorizontalLayoutGroup>();
            h.spacing = spacing;
            h.padding = padding ?? new RectOffset(0, 0, 0, 0);
            h.childForceExpandWidth = false;
            h.childForceExpandHeight = true;
            h.childControlHeight = true;
            h.childControlWidth = true;
            return h;
        }

        public static void SetFullStretch(RectTransform rt)
        {
            rt.anchorMin = Vector2.zero;
            rt.anchorMax = Vector2.one;
            rt.offsetMin = Vector2.zero;
            rt.offsetMax = Vector2.zero;
        }

        public static LayoutElement SetPreferredHeight(GameObject go, float height)
        {
            var le = go.GetComponent<LayoutElement>() ?? go.AddComponent<LayoutElement>();
            le.preferredHeight = height;
            return le;
        }

        public static Color ElementColor(Eyeland.Duel.Element element) => element switch
        {
            Eyeland.Duel.Element.Fire => Ember,
            Eyeland.Duel.Element.Water => new Color(0.31f, 0.84f, 0.90f),
            Eyeland.Duel.Element.Storm => Violet,
            _ => Fog,
        };
    }
}
