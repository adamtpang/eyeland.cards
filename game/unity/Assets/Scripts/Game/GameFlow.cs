using UnityEngine;

namespace Eyeland.Game
{
    /// <summary>Boots the solo expedition without scene wiring.</summary>
    public static class GameFlow
    {
#if !EYELAND_GAME_002_FALLINGBLOCK
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Boot()
        {
            var canvas = UIFactory.CreateRootCanvas("EyelandUI");
            IslandUI.Build(canvas.transform);
        }
#endif
    }
}
