@echo off
rem Double-click to copy MacroSets into your Retail and WoW Forever AddOns folders.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1" %*
pause
