param([switch]$Editor)
$ErrorActionPreference = 'Stop'
$projectPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../godot'))
# Packaged desktop apps (Claude, Codex) get a private copy of AppData\Local, so an install
# made from inside one is invisible to a normal shell. The home folder is checked first.
$runtimeName = 'EyelandTools/Godot/Godot_v4.7.2-stable_win64.exe'
$runtimePath = Join-Path $env:USERPROFILE $runtimeName
if (-not (Test-Path -LiteralPath $runtimePath)) { $runtimePath = Join-Path $env:LOCALAPPDATA $runtimeName }
if (-not (Test-Path -LiteralPath $runtimePath)) {
    throw "Godot 4.7.2 was not found at $runtimePath. Install Godot and import game/godot/project.godot."
}
$launchArguments = @('--path', ('"' + $projectPath + '"'))
if ($Editor) { $launchArguments += '--editor' } else { $launchArguments += @('--', '--collection') }
# This is the interactive game/editor explicitly launched by the player.
Start-Process -FilePath $runtimePath -ArgumentList $launchArguments
