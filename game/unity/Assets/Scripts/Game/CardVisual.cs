using System.Collections.Generic;
using Eyeland.Duel;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace Eyeland.Game
{
    // Art is presentation only: rules, ownership and live stats remain engine data.
    public sealed class CardVisual : MonoBehaviour, IPointerEnterHandler, IPointerExitHandler, ISelectHandler, IDeselectHandler
    {
        private static readonly Dictionary<string, Texture2D> Art = new();
        private CardDef _card;
        private GameObject _preview;

        public static void Attach(GameObject target, CardDef card)
        {
            target.AddComponent<CardVisual>()._card = card;
        }

        private static void Place(RectTransform rt, float x, float y, float w, float h)
        {
            rt.anchorMin = new Vector2(x, y); rt.anchorMax = new Vector2(x+w, y+h);
            rt.offsetMin = rt.offsetMax = Vector2.zero;
        }

        private static Text Label(Transform parent, string value, float x, float y, float w, float h, int size, Color? color = null)
        {
            var text = UIFactory.CreateText(parent, value, size, color ?? UIFactory.Foreground, TextAnchor.MiddleCenter);
            Place((RectTransform)text.transform, x,y,w,h);
            text.raycastTarget = false;
            text.resizeTextForBestFit = true; text.resizeTextMinSize = size - 2; text.resizeTextMaxSize = size;
            return text;
        }

        public static RectTransform Portrait(Transform parent, CardDef card)
        {
            var go = new GameObject("Portrait_"+card.Id, typeof(RectTransform), typeof(RawImage));
            go.transform.SetParent(parent, false);
            if (!Art.TryGetValue(card.Id, out var texture))
            {
                texture = Resources.Load<Texture2D>("Art/Creatures/"+card.Id);
                Art[card.Id] = texture;
            }
            var image = go.GetComponent<RawImage>();
            image.texture = texture; image.raycastTarget = false;
            image.color = texture != null ? Color.white : UIFactory.ElementColor(card.Element);
            if (texture == null) Label(go.transform, card.Type == CardType.Spell ? "SPELL" : "CREATURE", .05f,.25f,.9f,.5f,16,Color.white);
            // Preserve the square artwork within any region, rather than stretch the creature.
            var fit = go.AddComponent<AspectRatioFitter>(); fit.aspectRatio = 1; fit.aspectMode = AspectRatioFitter.AspectMode.FitInParent;
            return (RectTransform)go.transform;
        }

        public static void Draw(Transform parent, CardDef card, bool full = false, int? attack = null, int? health = null, string state = "")
        {
            var rarity = card.Rarity == Rarity.Legendary ? UIFactory.Accent : card.Rarity == Rarity.Epic ? UIFactory.Storm : card.Rarity == Rarity.Rare ? UIFactory.Water : UIFactory.Border;
            var image = parent.GetComponent<Image>();
            if (image != null) UIFactory.AddOutline(image, rarity, 2);
            var region = new GameObject("ArtWindow", typeof(RectTransform)); region.transform.SetParent(parent,false);
            Place((RectTransform)region.transform,.035f,full ? .42f : .28f,.93f,full ? .54f : .68f);
            Portrait(region.transform,card);
            Label(parent, UIFactory.EscapeRichText(card.Name), .04f,full ? .32f : .12f,.92f,full ? .10f : .16f, full ? 18 : 10);
            var cost = UIFactory.CreatePanel(parent, UIFactory.Primary, true);
            Place(cost,.02f,.79f,.22f,.19f);
            Label(cost,card.Cost.ToString(),0,0,1,1,full ? 24 : 16,Color.white);
            if (full)
            {
                Label(parent,card.Rarity.ToString().ToUpperInvariant()+" · "+card.Element,.05f,.265f,.9f,.055f,10,UIFactory.Primary);
                Label(parent,UIFactory.EscapeRichText(card.Text),.07f,.09f,.86f,.17f,14);
            }
            if (card.Type == CardType.Creature)
            {
                Label(parent,(attack ?? card.Attack)+" ATK",.03f,.01f,.4f,.095f,full ? 17 : 11);
                Label(parent,(health ?? card.Health)+" HP",.57f,.01f,.4f,.095f,full ? 17 : 11);
            }
            if (!string.IsNullOrEmpty(state)) Label(parent,state,.25f,.85f,.73f,.14f,9,UIFactory.Primary);
        }

        public void OnPointerEnter(PointerEventData e) => Show();
        public void OnPointerExit(PointerEventData e) => Hide();
        public void OnSelect(BaseEventData e) => Show();
        public void OnDeselect(BaseEventData e) => Hide();
        private void Show()
        {
            if (_preview != null || _card == null) return;
            var canvas = GetComponentInParent<Canvas>(); if (canvas == null) return;
            var panel = UIFactory.CreatePanel(canvas.transform,UIFactory.Surface,true,true,"Card inspection");
            _preview = panel.gameObject;
            panel.anchorMin = panel.anchorMax = new Vector2(.5f,.5f);
            panel.sizeDelta = new Vector2(230,340);
            var local = canvas.transform.InverseTransformPoint(transform.position);
            panel.anchoredPosition = new Vector2(local.x > 0 ? -330 : 330, 35);
            Draw(panel,_card,true);
            foreach (var graphic in panel.GetComponentsInChildren<Graphic>()) graphic.raycastTarget = false;
        }
        private void Hide() { if (_preview != null) { _preview.SetActive(false); Destroy(_preview); _preview=null; } }
        private void OnDisable() => Hide();
    }
}
