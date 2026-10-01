$ErrorActionPreference = 'Stop'
$projectPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../godot'))
$buildPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../builds/windows'))
$runtimePath = Join-Path $env:LOCALAPPDATA 'EyelandTools/Godot/Godot_v4.7.2-stable_win64_console.exe'
New-Item -ItemType Directory -Force -Path $buildPath | Out-Null
& $runtimePath --headless --path $projectPath --export-release 'Windows Desktop' (Join-Path $buildPath 'Eyeland.exe')
if ($LASTEXITCODE -ne 0) { throw "Godot export failed ($LASTEXITCODE)." }
@'
EYELAND - Windows prototype

Double-click Eyeland.exe. No Godot installation is required.
New players create a character; returning players enter their island.
Open Collection to edit a deck and play a practice battle.

Progress is stored in %APPDATA%\eyeland-godot-mvp, outside this folder.
Replacing the executable preserves your existing progress.
F8 in battle saves a local bug report. Sound can be muted in battle.

This is an unsigned local prototype. Windows may show a publisher warning.
'@ | Set-Content -LiteralPath (Join-Path $buildPath 'README.txt') -Encoding utf8
$archivePath = Join-Path (Split-Path $buildPath) 'Eyeland-Windows.zip'
foreach ($notice in @('LICENSE.txt','COPYRIGHT.txt')) {
    $destination = if ($notice -eq 'LICENSE.txt') { 'GODOT-LICENSE.txt' } else { 'GODOT-THIRD-PARTY.txt' }
    Invoke-WebRequest "https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/$notice" -OutFile (Join-Path $buildPath $destination)
}
Copy-Item -Path (Join-Path $projectPath 'assets/fonts/OFL-*.txt') -Destination $buildPath
$packageFiles = @('Eyeland.exe','README.txt','GODOT-LICENSE.txt','GODOT-THIRD-PARTY.txt','OFL-Poppins.txt','OFL-CormorantGaramond.txt') | ForEach-Object { Join-Path $buildPath $_ }
Compress-Archive -LiteralPath $packageFiles -DestinationPath $archivePath -Force
Get-Item -LiteralPath (Join-Path $buildPath 'Eyeland.exe'),$archivePath | Select-Object FullName,Length
