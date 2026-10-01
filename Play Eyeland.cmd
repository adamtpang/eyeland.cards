@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0game\scripts\play-godot.ps1"
if errorlevel 1 pause
