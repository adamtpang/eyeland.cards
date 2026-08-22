using UnityEngine;
using Eyeland.Duel;

namespace Eyeland.Game
{
    /// <summary>
    /// Feeds the card JSON to the portable duel core.
    ///
    /// CardSource resolves the pool from disk or an embedded resource, and Unity has
    /// neither at runtime, so the Unity host hands it the TextAsset instead. Runs before
    /// any scene loads, so nothing has to remember to call it.
    ///
    /// The file comes from game/data/cards.json via game/scripts/sync-unity.mjs. Edit it
    /// there, not in Assets/Resources.
    /// </summary>
    public static class CardDataBootstrap
    {
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        public static void Load()
        {
            if (CardSource.Override != null) return;

            var asset = Resources.Load<TextAsset>("cards");
            if (asset == null)
            {
                Debug.LogError(
                    "cards.json is missing from Assets/Resources. " +
                    "Run: node game/scripts/sync-unity.mjs");
                return;
            }

            CardSource.Override = asset.text;
            Debug.Log($"Eyeland: loaded {CardSet.All.Count} cards.");
        }
    }
}
