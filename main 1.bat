@echo off
setlocal
title SOMETIME Optimizer - Windows 11 25H2
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0Sometime.ps1"
set "result=%errorlevel%"
echo.
if not "%result%"=="0" echo Optimizer stopped. Read the message above; no automatic retry will run.
pause
exit /b %result%

