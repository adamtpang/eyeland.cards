param([string]$UnityPath = (Join-Path $env:LOCALAPPDATA 'EyelandTools/Unity/6000.5.7f1/Editor/Unity.exe'))
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $UnityPath)) { $UnityPath = 'C:/Program Files/Unity/Hub/Editor/6000.5.7f1/Editor/Unity.exe' }
if (-not (Test-Path $UnityPath)) { throw 'Unity 6000.5.7f1 with WebGL support is required. Pass -UnityPath if installed elsewhere.' }
$taskGame = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$taskProject = Join-Path $taskGame 'unity'
$taskLog = Join-Path $taskGame 'island-build.log'
node (Join-Path $PSScriptRoot 'sync-unity.mjs')
if ($LASTEXITCODE -ne 0) { throw 'Unity source sync failed.' }
$taskArgs = '-batchmode -nographics -quit -projectPath "{0}" -buildTarget WebGL -executeMethod Eyeland.Games.Editor.GamesBuildScript.BuildEyelandDuelWebGL -logFile "{1}"' -f $taskProject,$taskLog
$taskProcess = Start-Process -FilePath $UnityPath -ArgumentList $taskArgs -WindowStyle Hidden -PassThru
$taskProcess.WaitForExit()
if ($taskProcess.ExitCode -ne 0) { throw "Unity build failed ($($taskProcess.ExitCode)); read $taskLog" }
$taskBuild = Join-Path $taskProject 'Builds/WebGL/001-EyelandDuel'
$taskWasm = @(Get-ChildItem (Join-Path $taskBuild 'Build') -Filter '*.wasm')
if ($taskWasm.Count -ne 1) { throw 'Expected one WebGL payload.' }
@{ prototype = 'ember-reach-v1'; builtUtc = [DateTime]::UtcNow.ToString('o'); wasmSha256 = (Get-FileHash $taskWasm[0].FullName -Algorithm SHA256).Hash } | ConvertTo-Json | Set-Content (Join-Path $taskBuild 'build-info.json')
Write-Host "Built Ember Reach. Run game/scripts/play-ember-reach.ps1 to play."
