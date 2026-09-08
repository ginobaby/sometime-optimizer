@echo off
setlocal
title SOMETIME - Undo
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0Sometime.ps1" -Action Restore
set "result=%errorlevel%"
pause
exit /b %result%
