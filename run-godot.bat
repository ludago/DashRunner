@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\User\Documents\integracion\godot-starter-kit\scripts\run-godot.ps1" -ProjectPath "%~dp0" -GodotPath "C:/Users/User/Desktop/godot/Godot_v4.4.1-stable_win64.exe" %*
pause