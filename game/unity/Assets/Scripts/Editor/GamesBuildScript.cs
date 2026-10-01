using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace Eyeland.Games.Editor
{
    /// <summary>
    /// CLI-only build pipeline for GAMES-1000 entries -- no Editor GUI clicking,
    /// matching the standing CLI-first rule for this project. Each entry is its
    /// own standalone build (own scripting define, own scene, own output folder),
    /// never bundled with the MMORPG's own boot path.
    ///
    /// Invoke via: unity.exe -batchmode -nographics -quit -projectPath <path>
    ///   -executeMethod Eyeland.Games.Editor.GamesBuildScript.BuildFallingBlockClearWebGL
    /// </summary>
    public static class GamesBuildScript
    {
        private const string FallingBlockClearScenePath = "Assets/Scenes/Games/002-FallingBlockClear.unity";
        private const string FallingBlockClearDefine = "EYELAND_GAME_002_FALLINGBLOCK";
        private const string FallingBlockClearOutputDir = "Builds/WebGL/002-FallingBlockClear";

        // GameFlow.Boot() is unguarded (no scripting define) -- it's the MMORPG's
        // own default boot path, so this scene just needs to exist and be built,
        // no define wiring like the games-queue entries need.
        private const string EyelandDuelScenePath = "Assets/Scenes/Games/001-EyelandDuel.unity";
        private const string EyelandDuelOutputDir = "Builds/WebGL/001-EyelandDuel";

        public static void BuildFallingBlockClearWebGL()
        {
            EnsureSceneExists(FallingBlockClearScenePath);
            SetScriptingDefine(FallingBlockClearDefine);
            BuildWebGL(FallingBlockClearScenePath, FallingBlockClearOutputDir);
        }

        public static void BuildEyelandDuelWebGL()
        {
            var target = NamedBuildTarget.WebGL;
            var current = PlayerSettings.GetScriptingDefineSymbols(target);
            var cleaned = string.Join(";", current.Split(';').Where(d => d != FallingBlockClearDefine && !string.IsNullOrWhiteSpace(d)));
            if (cleaned != current) PlayerSettings.SetScriptingDefineSymbols(target, cleaned);
            EnsureSceneExists(EyelandDuelScenePath);
            BuildWebGL(EyelandDuelScenePath, EyelandDuelOutputDir);
        }

        public static void RefreshEyelandDuelWebGLShell()
        {
            var outputPath = Path.Combine(Directory.GetCurrentDirectory(), EyelandDuelOutputDir);
            ApplyResponsiveWebGLShell(outputPath);
        }

        private static void BuildWebGL(string scenePath, string outputDir)
        {
            SetActiveScenes(scenePath);

            // Disabled, not Brotli/gzip: a plain static file server (used for local
            // preview) doesn't send the Content-Encoding header the compressed
            // format needs, so the browser tries to parse raw compressed bytes as
            // JS and fails. itch.io's own upload pipeline handles compressed
            // Unity builds correctly, so this is a local-preview-only tradeoff,
            // not a real itch.io deployment problem -- re-enable before a real
            // upload if the larger uncompressed size matters.
            PlayerSettings.WebGL.compressionFormat = WebGLCompressionFormat.Disabled;

            var projectRoot = Path.GetFullPath(Path.Combine(Application.dataPath, ".."));
            var outputPath = Path.GetFullPath(Path.Combine(projectRoot, outputDir));
            var buildRoot = Path.Combine(projectRoot, "Builds") + Path.DirectorySeparatorChar;
            if (!outputPath.StartsWith(buildRoot, System.StringComparison.OrdinalIgnoreCase))
                throw new System.InvalidOperationException("Refusing to clean a build outside this project's Builds folder.");
            // Clean, not incremental: a prior compressed build can leave stale .gz
            // files that an incremental build doesn't always overwrite, which is
            // exactly what happened switching from compressed to uncompressed.
            if (Directory.Exists(outputPath))
                Directory.Delete(outputPath, recursive: true);
            Directory.CreateDirectory(outputPath);

            var report = BuildPipeline.BuildPlayer(new BuildPlayerOptions
            {
                scenes = new[] { scenePath },
                locationPathName = outputPath,
                target = BuildTarget.WebGL,
                options = BuildOptions.None,
            });

            var summary = report.summary;
            Debug.Log($"[GamesBuildScript] WebGL build result ({outputDir}): {summary.result}, " +
                      $"total time: {summary.totalTime}, total size: {summary.totalSize} bytes, " +
                      $"errors: {summary.totalErrors}, warnings: {summary.totalWarnings}");

            if (summary.result != UnityEditor.Build.Reporting.BuildResult.Succeeded)
            {
                Debug.LogError($"[GamesBuildScript] Build did not succeed for {outputDir} -- see errors above.");
                EditorApplication.Exit(1);
            }

            ApplyResponsiveWebGLShell(outputPath);
        }

        private static void ApplyResponsiveWebGLShell(string outputPath)
        {
            var indexPath = Path.Combine(outputPath, "index.html");
            var stylePath = Path.Combine(outputPath, "TemplateData", "style.css");
            if (!File.Exists(indexPath) || !File.Exists(stylePath))
                throw new FileNotFoundException($"WebGL shell is missing from {outputPath}");

            var index = File.ReadAllText(indexPath)
                .Replace("<title>Unity Web Player | unity</title>", "<title>Eyeland</title>");

            var buildPath = Path.Combine(outputPath, "Build");
            var wasmPath = Directory.GetFiles(buildPath, "*.wasm").SingleOrDefault();
            if (wasmPath == null)
                throw new FileNotFoundException($"WebGL wasm payload is missing from {buildPath}");

            var buildName = Path.GetFileNameWithoutExtension(wasmPath);
            var cacheKey = File.GetLastWriteTimeUtc(wasmPath).Ticks.ToString("x");
            foreach (var suffix in new[] { ".loader.js", ".data", ".framework.js", ".wasm" })
            {
                index = index.Replace(
                    $"/{buildName}{suffix}\"",
                    $"/{buildName}{suffix}?v={cacheKey}\"");
            }

            const string fixedCanvasCrLf = "canvas.style.width = \"960px\";\r\n        canvas.style.height = \"600px\";";
            const string fixedCanvasLf = "canvas.style.width = \"960px\";\n        canvas.style.height = \"600px\";";
            const string responsiveCanvas =
                "function sizeDesktopCanvas() {\n" +
                "          var width = Math.min(960, window.innerWidth, window.innerHeight * 1.6);\n" +
                "          canvas.style.width = width + \"px\";\n" +
                "          canvas.style.height = (width / 1.6) + \"px\";\n" +
                "        }\n" +
                "        sizeDesktopCanvas();\n" +
                "        window.addEventListener(\"resize\", sizeDesktopCanvas);";

            if (index.Contains(fixedCanvasCrLf))
                index = index.Replace(fixedCanvasCrLf, responsiveCanvas);
            else if (index.Contains(fixedCanvasLf))
                index = index.Replace(fixedCanvasLf, responsiveCanvas);
            else if (!index.Contains("function sizeDesktopCanvas()"))
                throw new InvalidDataException("Unity's desktop canvas markup changed; update the responsive shell patch.");

            File.WriteAllText(indexPath, index);

            const string marker = "/* eyeland-responsive-shell */";
            var style = File.ReadAllText(stylePath);
            if (!style.Contains(marker))
            {
                style += "\n\n/* eyeland-responsive-shell */\n" +
                         "html, body { width: 100%; height: 100%; overflow: hidden; background: #edf7f4 }\n" +
                         "#unity-footer { display: none }\n";
                File.WriteAllText(stylePath, style);
            }

            Debug.Log($"[GamesBuildScript] Applied responsive WebGL shell to {outputPath} " +
                      $"with cache key {cacheKey}");
        }

        private static void EnsureSceneExists(string scenePath)
        {
            if (File.Exists(scenePath)) return;

            Directory.CreateDirectory(Path.GetDirectoryName(scenePath)!);
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            EditorSceneManager.SaveScene(scene, scenePath);
            Debug.Log($"[GamesBuildScript] Created new empty scene at {scenePath}");
        }

        private static void SetActiveScenes(string scenePath)
        {
            var entry = new EditorBuildSettingsScene(scenePath, true);
            var existing = EditorBuildSettings.scenes.Where(s => s.path != scenePath).ToArray();
            EditorBuildSettings.scenes = existing.Append(entry).ToArray();
        }

        private static void SetScriptingDefine(string define)
        {
            var target = NamedBuildTarget.WebGL;
            var current = PlayerSettings.GetScriptingDefineSymbols(target);
            var defines = current.Split(';').Where(d => !string.IsNullOrWhiteSpace(d)).ToList();
            if (!defines.Contains(define))
            {
                defines.Add(define);
                PlayerSettings.SetScriptingDefineSymbols(target, string.Join(";", defines));
                Debug.Log($"[GamesBuildScript] Added scripting define {define} for WebGL");
            }
        }
    }
}
