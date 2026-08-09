using System.Collections.Generic;
using Eyeland.Duel;
using UnityEngine;

namespace Eyeland.Game
{
    /// <summary>
    /// Boots the game with no scene wiring required -- RuntimeInitializeOnLoadMethod runs
    /// automatically after any scene loads, so hitting Play in the empty default scene is
    /// enough. Flow: deckbuilder -> duel -> end screen -> back to deckbuilder.
    /// </summary>
    public static class GameFlow
    {
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Boot()
        {
            var canvas = UIFactory.CreateRootCanvas("EyelandUI");
            ShowDeckBuilder(canvas.transform);
        }

        private static void ShowDeckBuilder(Transform root)
        {
            DeckBuilderUI.Build(root, deck => ShowDuel(root, deck));
        }

        private static void ShowDuel(Transform root, List<CardDef> playerDeck)
        {
            DuelUI.Build(root, playerDeck, () => ShowDeckBuilder(root));
        }
    }
}
