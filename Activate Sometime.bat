@echo off
setlocal
title SOMETIME - Activation
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0Sometime.ps1" -Action Activation
set "result=%errorlevel%"
pause
exit /b %result%
