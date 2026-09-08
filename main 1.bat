@echo off
setlocal DisableDelayedExpansion
title SOMETIME - Windows 11 25H2
set "SOMETIME_ENTRY=%~f0"
set "SOMETIME_PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
"%SOMETIME_PS%" -NoLogo -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0Sometime.ps1" -Action Validate
if errorlevel 1 goto :Fatal
fltmc >nul 2>&1
if errorlevel 1 (
    "%SOMETIME_PS%" -NoLogo -NoProfile -Command "Start-Process -FilePath $env:SOMETIME_ENTRY -Verb RunAs"
    exit /b
)
set "SOMETIME_BACKUP=%LOCALAPPDATA%\SometimeOptimizer\OriginalFlow\%RANDOM%-%RANDOM%"
set "SOMETIME_LOG=%SOMETIME_BACKUP%\run.log"
:OSS
chcp 65001 >nul 2>&1
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.                               ██████  ▒█████   ███▄ ▄███▓▓█████▄▄▄█████▓ ██▓ ███▄ ▄███▓▓█████ 
echo.                             ▒██    ▒ ▒██▒  ██▒▓██▒▀█▀ ██▒▓█   ▀▓  ██▒ ▓▒▓██▒▓██▒▀█▀ ██▒▓█   ▀ 
echo.                             ░ ▓██▄   ▒██░  ██▒▓██    ▓██░▒███  ▒ ▓██░ ▒░▒██▒▓██    ▓██░▒███   
echo.                               ▒   ██▒▒██   ██░▒██    ▒██ ▒▓█  ▄░ ▓██▓ ░ ░██░▒██    ▒██ ▒▓█  ▄ 
echo.                             ▒██████▒▒░ ████▓▒░▒██▒   ░██▒░▒████▒ ▒██▒ ░ ░██░▒██▒   ░██▒░▒████▒
echo.                             ▒ ▒▓▒ ▒ ░░ ▒░▒░▒░ ░ ▒░   ░  ░░░ ▒░ ░ ▒ ░░   ░▓  ░ ▒░   ░  ░░░ ▒░ ░
echo.                             ░ ░▒  ░ ░  ░ ▒ ▒░ ░  ░      ░ ░ ░  ░   ░     ▒ ░░  ░      ░ ░ ░  ░
echo.                             ░  ░  ░  ░ ░ ░ ▒  ░      ░      ░    ░       ▒ ░░      ░      ░   
echo.                                   ░      ░ ░         ░      ░  ░         ░         ░      ░  ░
echo.                                                                                          
echo. 
echo.                                  ╔════════════════════════════════════════════════════╗      
echo.                                  ║              Windows 11 25H2 - SOMETIME               ║
echo.                                  ╚════════════════════════════════════════════════════╝
echo.
echo.
echo.
echo.
echo. 
echo. ╔═════════╗                                                                        
echo. ║ Loading ║                                              
echo. ╚═════════╝
timeout 2 > nul              

cls
color 0E
echo ============================================================
echo                    SOMETIME - READ FIRST
echo ============================================================
echo This automatic run disables Windows Update and attempts to
echo disable Defender real-time protection, as requested.
echo WARNING: this reduces malware protection and security updates.
echo It changes appearance, input, privacy, recording and power,
echo disables selected background services, removes listed apps,
echo installs the Microsoft VC++ runtime if needed, and cleans old temp files.
echo Location, notifications, Sticky Keys shortcuts and game recording change.
echo Mouse feel changes; hibernation and Fast Startup become unavailable.
echo Apps and deleted files are not covered by registry backups.
echo No NVIDIA profile, driver override, or forced reboot is included.
echo Starting in 10 seconds. Press Ctrl+C now to cancel.
timeout /t 10 /nobreak >nul
cls
color 0B
echo Creating restore point and saving original settings...
"%SOMETIME_PS%" -NoLogo -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0Sometime.ps1" -Action Backup
if errorlevel 1 goto :Fatal
call :Stage Security "Windows Update and Defender" 0E
cls
chcp 437 >nul
color 0D
echo (CTT) Disabling Activity History...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
echo Stage commands finished; any errors are recorded in the log.
timeout /t 2 /nobreak >nul
cls
color 0B
echo (CTT) Disabling Location...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Deny" /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" /v "SensorPermissionState" /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" /v "Status" /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKLM\SYSTEM\Maps" /v "AutoUpdateEnabled" /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
echo Stage commands finished; any errors are recorded in the log.
timeout /t 2 /nobreak >nul
cls
color 0D
echo (CTT) Disabling Notifications...
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableNotificationCenter /t REG_DWORD /d 1 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
echo Stage commands finished; any errors are recorded in the log.
timeout /t 2 /nobreak >nul
cls
color 0B
timeout /t 2 /nobreak >nul
cls
color 0D
echo (CTT) Disabling StickyKeys...
reg add "HKEY_CURRENT_USER\Control Panel\Accessibility\StickyKeys" /v Flags /t REG_SZ /d 506 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
echo Stage commands finished; any errors are recorded in the log.
timeout /t 2 /nobreak >nul
cls
color 0B
echo (CTT) Enabling Numlock On Start Up...
reg add "HKU\.DEFAULT\Control Panel\Keyboard" /v InitialKeyboardIndicators /t REG_SZ /d 2 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
echo Stage commands finished; any errors are recorded in the log.
timeout /t 2 /nobreak >nul
cls
color 0D
echo (CTT) Enabling Win 10 Right Click Menu...
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
echo Stage commands finished; any errors are recorded in the log.
echo Stage commands finished; any errors are recorded in the log.
timeout /t 2 /nobreak >nul
cls
color 0B
echo (CTT) Show File Extensions...
reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
echo Stage commands finished; any errors are recorded in the log.
timeout /t 2 /nobreak >nul
cls
color 0D
echo Show Hidden Files and Folders...
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
echo Stage commands finished; any errors are recorded in the log.
timeout /t 2 /nobreak >nul
cls
color 0B
echo (CTT) Disabling Taskbar Widgets...
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
echo Stage commands finished; any errors are recorded in the log.
timeout /t 2 /nobreak >nul
cls
color 0D
echo (CTT) Setting Display For Performance...
reg add "HKCU\Control Panel\Desktop" /v "DragFullWindows" /t REG_SZ /d "0" /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "200" /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\Control Panel\Keyboard" /v KeyboardDelay /t REG_SZ /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewAlphaSelect" /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewShadow" /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 3 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\Software\Microsoft\Windows\DWM" /v "EnableAeroPeek" /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
echo Stage commands finished; any errors are recorded in the log.
timeout /t 2 /nobreak >nul
cls
color 0B
echo (CTT) Disabling GameDVR...
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
echo Stage commands finished; any errors are recorded in the log.
timeout /t 2 /nobreak >nul
cls
color 0D
echo Enabling Game Mode...
reg add "HKEY_CURRENT_USER\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 1 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKEY_CURRENT_USER\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 1 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
echo Game Mode preference applied.
timeout /t 2 /nobreak >nul
cls
color 0B
timeout /t 2 /nobreak >nul
cls
color 0D
echo Disabling Transparency Effects...
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize /v EnableTransparency /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
echo Stage commands finished; any errors are recorded in the log.
timeout /t 2 /nobreak >nul
cls
color 0B
echo (CTT) Disabling Mouse Acceleration...
reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
echo Stage commands finished; any errors are recorded in the log.
timeout /t 2 /nobreak >nul
cls
color 0D
echo (CTT) Disabling Hibernation...
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Power" /v HibernateEnabled /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" /v ShowHibernateOption /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
powercfg.exe /hibernate off >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Hibernation"
echo Stage commands finished; any errors are recorded in the log.
cls
color 0D
echo Applying original privacy and Explorer preferences...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 1 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 1 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v ContentDeliveryAllowed /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v OemPreInstalledAppsEnabled /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v PreInstalledAppsEnabled /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v PreInstalledAppsEverEnabled /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338387Enabled /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338388Enabled /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353698Enabled /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DoNotShowFeedbackNotifications /t REG_DWORD /d 1 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableTailoredExperiencesWithDiagnosticData /t REG_DWORD /d 1 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v DisabledByGroupPolicy /t REG_DWORD /d 1 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" /v EnthusiastMode /t REG_DWORD /d 1 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" /v PeopleBand /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /t REG_DWORD /d 1 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v SearchOrderConfig /t REG_DWORD /d 1 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\Control Panel\Mouse" /v MouseHoverTime /t REG_SZ /d 400 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" /v "ScoobeSystemSettingEnabled" /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v ColorPrevalence /t REG_DWORD /d 1 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"
echo Required diagnostic data may remain depending on Windows edition and policy.
timeout /t 2 /nobreak >nul
echo.
echo.
echo.                                                                          
timeout /t 2 /nobreak >nul
cls
color 0B
chcp 65001 >nul 2>&1
echo. 
echo.
echo.
echo.
echo.
echo.                                 ██╗    ██╗██╗███╗   ██╗██████╗  ██████╗ ██╗    ██╗███████╗ 
echo.                                 ██║    ██║██║████╗  ██║██╔══██╗██╔═══██╗██║    ██║██╔════╝ 
echo.                                 ██║ █╗ ██║██║██╔██╗ ██║██║  ██║██║   ██║██║ █╗ ██║███████╗ 
echo.                                 ██║███╗██║██║██║╚██╗██║██║  ██║██║   ██║██║███╗██║╚════██║ 
echo.                                 ╚███╔███╔╝██║██║ ╚████║██████╔╝╚██████╔╝╚███╔███╔╝███████║ 
echo.                                  ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚══════╝ 
echo.                                                           
echo.                                  ██████╗██╗     ███████╗ █████╗ ███╗   ██╗██╗   ██╗██████╗ 
echo.                                 ██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║██║   ██║██╔══██╗
echo.                                 ██║     ██║     █████╗  ███████║██╔██╗ ██║██║   ██║██████╔╝
echo.                                 ██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║██║   ██║██╔═══╝ 
echo.                                 ╚██████╗███████╗███████╗██║  ██║██║ ╚████║╚██████╔╝██║     
echo.                                  ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝   
echo. 
echo.                                  ╔════════════════════════════════════════════════════╗
echo.                                  ║        Running SOMETIME's Windows Cleanup...       ║       
echo.                                  ╚════════════════════════════════════════════════════╝
echo.
echo. 
echo.
echo.                                                                          
timeout /t 2 /nobreak >nul
cls
call :Stage Background "Background services" 0D
call :Stage Apps "Microsoft apps and bloatware" 0E
cls
color 0B
echo NVIDIA profile import and hard-coded GPU settings: REMOVED.
echo Windows display resolution, refresh rate and scaling are preserved.
echo HAGS, boot timers, device interrupts and core process priorities are not forced.
timeout /t 3 /nobreak >nul
call :Stage Runtime "Microsoft Visual C++ runtime" 0B
call :Stage Power "Power settings" 0E
call :Stage Cleanup "Temporary files and DNS cache" 0B
cls
color 0A
echo ============================================================
echo                     SOMETIME FINISHED
echo ============================================================
echo Review the log for warnings or commands Windows blocked:
echo "%SOMETIME_LOG%"
echo Backups: "%SOMETIME_BACKUP%"
if exist "%SOMETIME_BACKUP%\warnings.flag" color 0E
if exist "%SOMETIME_BACKUP%\warnings.flag" echo SOME STEPS FAILED OR WERE BLOCKED. CHECK THE LOG.
echo Defender may re-enable itself. Updates may be restored by Windows.
echo Save your work, then restart when convenient. No reboot is forced.
echo Restore options: Undo Sometime.bat
echo Optional activation: Activate Sometime.bat
echo NVIDIA recovery: NVIDIA-DISPLAY.md
pause
if exist "%SOMETIME_BACKUP%\warnings.flag" exit /b 1
exit /b 0

:Stage
cls
color %~3
echo ============================================================
echo %~2
echo ============================================================
"%SOMETIME_PS%" -NoLogo -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0Sometime.ps1" -Action %~1
if errorlevel 1 call :Failed "%~2"
timeout /t 3 /nobreak >nul
exit /b

:Failed
color 0C
echo [WARNING] %~1 failed or was partly blocked. Review the log.
echo [WARNING] %~1 failed or was partly blocked.>>"%SOMETIME_LOG%"
echo warning>>"%SOMETIME_BACKUP%\warnings.flag"
timeout /t 3 /nobreak >nul
exit /b

:Fatal
color 0C
echo Sometime stopped. Read the error above before retrying.
pause
exit /b 1
