param([int]$Port = 8765)
$taskBuild = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../unity/Builds/WebGL/001-EyelandDuel'))
if (-not (Test-Path (Join-Path $taskBuild 'build-info.json'))) {
    throw 'Build the Ember Reach WebGL prototype first. See game/PLAY-EMBER-REACH.md.'
}
Write-Host "Play Eyeland at http://127.0.0.1:$Port (keep this terminal open)."
python -m http.server $Port --bind 127.0.0.1 --directory $taskBuild
