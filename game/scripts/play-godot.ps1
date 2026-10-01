param([switch]$Editor)
$ErrorActionPreference = 'Stop'
$projectPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../godot'))
$runtimePath = Join-Path $env:LOCALAPPDATA 'EyelandTools/Godot/Godot_v4.7.2-stable_win64.exe'
if (-not (Test-Path -LiteralPath $runtimePath)) {
    throw "Godot 4.7.2 was not found at $runtimePath. Install Godot and import game/godot/project.godot."
}
$launchArguments = @('--path', ('"' + $projectPath + '"'))
if ($Editor) { $launchArguments += '--editor' } else { $launchArguments += @('--', '--collection') }
# This is the interactive game/editor explicitly launched by the player.
Start-Process -FilePath $runtimePath -ArgumentList $launchArguments
