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
        // Original dark brand tokens retained for the Falling Block prototype.
        public static readonly Color Abyss = new(0.024f, 0.039f, 0.102f);
        public static readonly Color Panel = new(0.078f, 0.118f, 0.165f);
        public static readonly Color Mist = new(0.918f, 0.933f, 0.984f);
        public static readonly Color Fog = new(0.702f, 0.733f, 0.867f);
        public static readonly Color Arcane = new(0.208f, 0.890f, 0.816f);
        public static readonly Color Ember = new(1f, 0.718f, 0.396f);
        public static readonly Color Violet = new(0.608f, 0.482f, 1f);
        public static readonly Color Danger = new(0.925f, 0.38f, 0.36f);

        // Eyeland Duel semantic tokens. These preserve the existing ink, teal, ember,
        // and violet identity while moving the playable UI into the bright storybook world.
        public static readonly Color Background = Hex(0xEDF7F4);
        public static readonly Color Foreground = Hex(0x102A43);
        public static readonly Color Surface = Hex(0xFFFDF6);
        public static readonly Color SurfaceElevated = Hex(0xFFFFFF);
        public static readonly Color SurfaceMuted = Hex(0xDDEEEA);
        public static readonly Color MutedForeground = Hex(0x58717A);
        public static readonly Color Primary = Hex(0x197B78);
        public static readonly Color PrimaryForeground = Hex(0xFFFDF6);
        public static readonly Color Secondary = Hex(0xF5D88F);
        public static readonly Color Accent = Hex(0xFFB765);
        public static readonly Color Destructive = Hex(0xD4544D);
        public static readonly Color Border = Hex(0x91BAB7);
        public static readonly Color Ring = Hex(0x35E3D0);
        public static readonly Color Fire = Hex(0xE86F42);
        public static readonly Color Water = Hex(0x259CAF);
        public static readonly Color Storm = Hex(0x7957D5);

        private static Font _defaultFont;
        private static Font _semiboldFont;
        private static Sprite _roundedSprite;
        private static Sprite _backdropSprite;

        public static Font DefaultFont => _defaultFont ??=
            Resources.Load<Font>("Fonts/Poppins-Regular") ??
            Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");

        public static Font SemiboldFont => _semiboldFont ??=
            Resources.Load<Font>("Fonts/Poppins-SemiBold") ?? DefaultFont;

        private static Color Hex(uint value) => new(
            ((value >> 16) & 0xff) / 255f,
            ((value >> 8) & 0xff) / 255f,
            (value & 0xff) / 255f);

        public static Color WithAlpha(Color color, float alpha) =>
            new(color.r, color.g, color.b, alpha);

        public static string EscapeRichText(string value) => (value ?? string.Empty)
            .Replace("&", "&amp;")
            .Replace("<", "&lt;")
            .Replace(">", "&gt;");

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

        public static RectTransform CreateBackdrop(Transform parent)
        {
            var go = new GameObject("ArchipelagoBackdrop", typeof(RectTransform), typeof(Image));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            SetFullStretch(rt);

            var image = go.GetComponent<Image>();
            image.raycastTarget = false;
            if (_backdropSprite == null)
            {
                var texture = Resources.Load<Texture2D>("Art/eyeland-archipelago");
                if (texture != null)
                {
                    _backdropSprite = Sprite.Create(
                        texture,
                        new Rect(0, 0, texture.width, texture.height),
                        new Vector2(0.5f, 0.5f),
                        100f);
                    _backdropSprite.name = "Eyeland Archipelago Backdrop";
                }
            }

            if (_backdropSprite != null)
                image.sprite = _backdropSprite;
            else
                image.color = Background;

            var veil = CreatePanel(parent, WithAlpha(Background, 0.16f), name: "BackdropVeil");
            SetFullStretch(veil);
            veil.GetComponent<Image>().raycastTarget = false;
            return rt;
        }

        public static RectTransform CreatePanel(
            Transform parent,
            Color color,
            bool rounded = false,
            bool shadow = false,
            string name = "Panel")
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            var image = go.GetComponent<Image>();
            image.color = color;
            if (rounded) StyleRounded(image, shadow);
            return rt;
        }

        public static Text CreateText(
            Transform parent,
            string text,
            int fontSize,
            Color color,
            TextAnchor anchor = TextAnchor.MiddleLeft,
            bool emphasis = false)
        {
            var go = new GameObject("Text", typeof(RectTransform), typeof(Text));
            go.transform.SetParent(parent, false);
            var t = go.GetComponent<Text>();
            t.font = emphasis ? SemiboldFont : DefaultFont;
            t.text = text;
            t.fontSize = fontSize;
            t.color = color;
            t.alignment = anchor;
            t.raycastTarget = false;
            t.supportRichText = true;
            t.horizontalOverflow = HorizontalWrapMode.Wrap;
            t.verticalOverflow = VerticalWrapMode.Overflow;
            return t;
        }

        public static Button CreateButton(
            Transform parent,
            string label,
            Color bg,
            Action onClick,
            int fontSize = 16,
            Color? foreground = null,
            bool shadow = true)
        {
            var go = new GameObject("Button", typeof(RectTransform), typeof(Image), typeof(Button));
            go.transform.SetParent(parent, false);
            var img = go.GetComponent<Image>();
            img.color = bg;
            StyleRounded(img, shadow);
            var btn = go.GetComponent<Button>();
            btn.targetGraphic = img;
            var colors = btn.colors;
            colors.normalColor = Color.white;
            colors.selectedColor = new Color(0.65f, 1f, 0.8f, 1f);
            colors.highlightedColor = new Color(1f, 1f, 1f, 0.86f);
            colors.pressedColor = new Color(0.84f, 0.84f, 0.84f, 1f);
            colors.disabledColor = new Color(1f, 1f, 1f, 0.42f);
            colors.fadeDuration = 0.08f;
            btn.colors = colors;
            btn.onClick.AddListener(() => onClick?.Invoke());

            var text = CreateText(
                go.transform,
                label,
                fontSize,
                foreground ?? Foreground,
                TextAnchor.MiddleCenter,
                emphasis: true);
            var textRt = (RectTransform)text.transform;
            textRt.anchorMin = Vector2.zero;
            textRt.anchorMax = Vector2.one;
            textRt.offsetMin = new Vector2(6, 4);
            textRt.offsetMax = new Vector2(-6, -4);
            text.verticalOverflow = VerticalWrapMode.Truncate;

            return btn;
        }

        public static void StyleRounded(Image image, bool shadow = false)
        {
            var sprite = RoundedSprite;
            if (sprite != null)
            {
                image.sprite = sprite;
                image.type = Image.Type.Sliced;
            }
            else
            {
                image.sprite = null;
                image.type = Image.Type.Simple;
            }
            if (shadow)
            {
                var effect = image.gameObject.GetComponent<Shadow>() ?? image.gameObject.AddComponent<Shadow>();
                effect.effectColor = new Color(0.04f, 0.13f, 0.18f, 0.18f);
                effect.effectDistance = new Vector2(0f, -2f);
                effect.useGraphicAlpha = true;
            }
        }

        public static void AddOutline(Image image, Color color, float distance = 1f)
        {
            var outline = image.gameObject.GetComponent<Outline>() ?? image.gameObject.AddComponent<Outline>();
            outline.effectColor = color;
            outline.effectDistance = new Vector2(distance, -distance);
            outline.useGraphicAlpha = true;
        }

        private static Sprite RoundedSprite
        {
            get
            {
                if (_roundedSprite != null) return _roundedSprite;
                var texture = Resources.Load<Texture2D>("UI/rounded-rect");
                if (texture == null) return null;

                _roundedSprite = Sprite.Create(
                    texture,
                    new Rect(0, 0, texture.width, texture.height),
                    new Vector2(0.5f, 0.5f),
                    100f,
                    0,
                    SpriteMeshType.FullRect,
                    new Vector4(12f, 12f, 12f, 12f));
                _roundedSprite.name = "Eyeland Rounded UI";
                return _roundedSprite;
            }
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
            v.childAlignment = TextAnchor.UpperCenter;
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
            h.childAlignment = TextAnchor.MiddleCenter;
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
            Eyeland.Duel.Element.Fire => Fire,
            Eyeland.Duel.Element.Water => Water,
            Eyeland.Duel.Element.Storm => Storm,
            _ => MutedForeground,
        };

        public static Color ElementSurfaceColor(Eyeland.Duel.Element element) => element switch
        {
            Eyeland.Duel.Element.Fire => Hex(0xFFF0E8),
            Eyeland.Duel.Element.Water => Hex(0xE5F7F8),
            Eyeland.Duel.Element.Storm => Hex(0xF0ECFF),
            _ => Surface,
        };

        public static Color ElementForegroundColor(Eyeland.Duel.Element element) => element switch
        {
            Eyeland.Duel.Element.Storm => PrimaryForeground,
            _ => Foreground,
        };
    }
}
