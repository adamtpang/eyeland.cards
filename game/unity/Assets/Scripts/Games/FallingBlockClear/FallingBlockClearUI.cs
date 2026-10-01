using System.Collections.Generic;
using Eyeland.Game;
using UnityEngine;
using UnityEngine.UI;

namespace Eyeland.Games.FallingBlockClear
{
    /// <summary>
    /// GAMES-1000 entry 002, real Unity UI over the same GameState/Piece engine
    /// already proven correct via a real console playtest (see GAMES-1000.md).
    /// Same runtime-constructed-uGUI pattern as the MMORPG's UIFactory-based
    /// screens: no hand-authored .unity scene content, no Inspector wiring.
    ///
    /// Boot is gated by EYELAND_GAME_002_FALLINGBLOCK so it never collides with
    /// GameFlow.cs's own RuntimeInitializeOnLoadMethod boot in the same project
    /// -- each GAMES-1000 entry gets its own scripting define and its own
    /// standalone build, not a shared scene with the MMORPG.
    /// </summary>
    public sealed class FallingBlockClearUI : MonoBehaviour
    {
        private const float CellSize = 32f;
        private GameState _state;
        private RectTransform _boardRoot;
        private readonly Dictionary<(int, int), Image> _cells = new();
        private Text _statusText;
        private Text _logText;

#if EYELAND_GAME_002_FALLINGBLOCK
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Boot()
        {
            // The scripting define alone isn't scoped enough: it's set per build-target-group
            // in ProjectSettings, so it stays active in the Editor for every scene as long as
            // WebGL is the active platform, not just for this entry's own scene -- that's what
            // let this UI boot on top of GameFlow's deckbuilder and eat its clicks. Gate on the
            // actual active scene too so this entry only ever boots in its own scene.
            if (UnityEngine.SceneManagement.SceneManager.GetActiveScene().name != "002-FallingBlockClear")
                return;

            var canvas = UIFactory.CreateRootCanvas("FallingBlockClearUI");
            var go = new GameObject("FallingBlockClear", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(canvas.transform, false);
            UIFactory.SetFullStretch(rt);
            go.AddComponent<FallingBlockClearUI>().Init(rt);
        }
#endif

        private void Init(RectTransform root)
        {
            _state = new GameState();

            var bg = UIFactory.CreatePanel(root, UIFactory.Abyss);
            UIFactory.SetFullStretch(bg);

            var title = UIFactory.CreateText(root, "FALLING BLOCK CLEAR", 22, UIFactory.Mist, TextAnchor.MiddleCenter);
            var titleRt = (RectTransform)title.transform;
            titleRt.anchorMin = new Vector2(0, 1);
            titleRt.anchorMax = new Vector2(1, 1);
            titleRt.pivot = new Vector2(0.5f, 1);
            titleRt.sizeDelta = new Vector2(0, 40);
            titleRt.anchoredPosition = new Vector2(0, -12);

            _statusText = UIFactory.CreateText(root, "", 14, UIFactory.Fog, TextAnchor.MiddleCenter);
            var statusRt = (RectTransform)_statusText.transform;
            statusRt.anchorMin = new Vector2(0, 1);
            statusRt.anchorMax = new Vector2(1, 1);
            statusRt.pivot = new Vector2(0.5f, 1);
            statusRt.sizeDelta = new Vector2(0, 24);
            statusRt.anchoredPosition = new Vector2(0, -46);

            var boardGo = new GameObject("Board", typeof(RectTransform));
            _boardRoot = (RectTransform)boardGo.transform;
            _boardRoot.SetParent(root, false);
            _boardRoot.anchorMin = new Vector2(0.5f, 0.5f);
            _boardRoot.anchorMax = new Vector2(0.5f, 0.5f);
            _boardRoot.pivot = new Vector2(0.5f, 0.5f);
            _boardRoot.sizeDelta = new Vector2(GameState.Width * CellSize, GameState.Height * CellSize);
            _boardRoot.anchoredPosition = new Vector2(0, -10);

            var boardBg = UIFactory.CreatePanel(_boardRoot, UIFactory.Panel);
            UIFactory.SetFullStretch(boardBg);

            for (var r = 0; r < GameState.Height; r++)
                for (var c = 0; c < GameState.Width; c++)
                    _cells[(r, c)] = CreateCell(r, c);

            _logText = UIFactory.CreateText(root, "", 13, UIFactory.Fog, TextAnchor.LowerCenter);
            var logRt = (RectTransform)_logText.transform;
            logRt.anchorMin = new Vector2(0, 0);
            logRt.anchorMax = new Vector2(1, 0);
            logRt.pivot = new Vector2(0.5f, 0);
            logRt.sizeDelta = new Vector2(0, 60);
            logRt.anchoredPosition = new Vector2(0, 10);

            Redraw();
        }

        private Image CreateCell(int row, int col)
        {
            var go = new GameObject($"Cell_{row}_{col}", typeof(RectTransform), typeof(Image));
            var rt = (RectTransform)go.transform;
            rt.SetParent(_boardRoot, false);
            rt.anchorMin = new Vector2(0, 1);
            rt.anchorMax = new Vector2(0, 1);
            rt.pivot = new Vector2(0, 1);
            rt.sizeDelta = new Vector2(CellSize - 1, CellSize - 1);
            rt.anchoredPosition = new Vector2(col * CellSize, -row * CellSize);
            var img = go.GetComponent<Image>();
            img.color = UIFactory.Panel;
            return img;
        }

        private static Color ColorFor(int cellValue) => cellValue switch
        {
            1 => UIFactory.Arcane,  // I
            2 => UIFactory.Ember,   // O
            3 => UIFactory.Violet,  // L
            _ => UIFactory.Panel,   // empty
        };

        private void Update()
        {
            if (_state.IsOver) return;

            ActionResult? result = null;
            if (Input.GetKeyDown(KeyCode.A) || Input.GetKeyDown(KeyCode.LeftArrow)) result = _state.MoveLeft();
            else if (Input.GetKeyDown(KeyCode.D) || Input.GetKeyDown(KeyCode.RightArrow)) result = _state.MoveRight();
            else if (Input.GetKeyDown(KeyCode.W) || Input.GetKeyDown(KeyCode.UpArrow)) result = _state.Rotate();
            else if (Input.GetKeyDown(KeyCode.S) || Input.GetKeyDown(KeyCode.DownArrow)) result = _state.SoftDrop();
            else if (Input.GetKeyDown(KeyCode.Space) || Input.GetKeyDown(KeyCode.X)) result = _state.HardDrop();

            if (result.HasValue) Redraw();
        }

        private void Redraw()
        {
            for (var r = 0; r < GameState.Height; r++)
                for (var c = 0; c < GameState.Width; c++)
                    _cells[(r, c)].color = ColorFor(_state.CellAt(r, c));

            var pieceColor = ColorFor((int)_state.CurrentKind + 1);
            foreach (var cell in _state.CurrentPieceBoardCells())
                if (cell.Row >= 0 && _cells.TryGetValue((cell.Row, cell.Col), out var img))
                    img.color = pieceColor;

            _statusText.text = _state.IsOver
                ? (_state.Won ? "YOU WON" : "GAME OVER") + $" -- lines {_state.LinesCleared}/{GameState.LinesToWin}  (A/D move, W rotate, S drop, Space hard-drop)"
                : $"Lines {_state.LinesCleared}/{GameState.LinesToWin}   (A/D move, W rotate, S drop, Space hard-drop)";

            if (_state.Log.Count > 0)
                _logText.text = _state.Log[_state.Log.Count - 1];
        }
    }
}
