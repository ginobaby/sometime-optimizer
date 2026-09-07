#requires -Version 5.1
[CmdletBinding()]
param([switch]$Preview, [string[]]$Tweaks)
. (Join-Path $PSScriptRoot 'Core.ps1')
$mutex = $null; $locked = $false
try {
    if ($Preview) {
        if (-not $Tweaks) { $Tweaks = @((Get-Tweaks).Id) }
        Invoke-Tweaks -Ids $Tweaks -StateDirectory '' -Preview | Format-List Id,Title,Warning,Path,Name,Kind,Value
        exit 0
    }
    if ($Tweaks) { throw 'Use the interactive menu to apply tweaks, or add -Preview to inspect them.' }
    $os = Get-CimInstance Win32_OperatingSystem
    Write-Host 'SOMETIME Optimizer - Windows 11 25H2 edition' -ForegroundColor Cyan
    Write-Host "Detected: $($os.Caption), build $($os.BuildNumber)"
    if (-not (Test-SupportedOS $os)) { throw 'Changes are restricted to Windows 11 25H2 (client build 26200). Use -Preview on other versions.' }
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Open normally, without Run as administrator. Tweaks apply only to the signed-in user.' }
    $mutex = New-Object Threading.Mutex($false, ('Local\SometimeOptimizer-' + [Security.Principal.WindowsIdentity]::GetCurrent().User.Value))
    try { $locked = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $locked = $true }
    if (-not $locked) { throw 'Another optimiser window is open. Close it first.' }
    $state = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'SometimeOptimizer\25H2'
    Write-Host 'No changes happen until you choose settings and type APPLY. No FPS gain is guaranteed.'
    Write-Host 'Undo covers this version only; it cannot repair damage from the old batch file.' -ForegroundColor Yellow
    while ($true) {
        Write-Host "`n1 Choose and preview tweaks`n2 Undo this version's changes`n3 Windows settings and maintenance`n4 View backup location`n5 NVIDIA display recovery guide`n0 Exit"
        switch (Read-Host 'Choose') {
            '1' {
                try {
                    $catalog = @(Get-Tweaks)
                    for ($i=0; $i -lt $catalog.Count; $i++) { Write-Host "$($i+1) $($catalog[$i].Title)" }
                    $inputText = Read-Host 'Enter numbers separated by commas, or Enter to cancel'
                    if ([string]::IsNullOrWhiteSpace($inputText)) { continue }
                    $ids = @()
                    foreach ($part in ($inputText -split ',')) {
                        $number = 0
                        if (-not [int]::TryParse($part.Trim(), [ref]$number) -or $number -lt 1 -or $number -gt $catalog.Count) { throw 'Invalid selection. Nothing changed.' }
                        $ids += $catalog[$number-1].Id
                    }
                    Invoke-Tweaks -Ids $ids -StateDirectory $state -Preview | Format-List Title,Warning,Path,Name,Value
                    Write-Host 'Existing values are backed up before writes. All options are optional.'
                    if ((Read-Host 'Type APPLY to apply this selection') -ceq 'APPLY') {
                        Write-Host (Invoke-Tweaks -Ids $ids -StateDirectory $state)
                        Write-Host 'Save work, then sign out and back in when convenient to refresh settings.'
                    }
                } catch { Write-Host $_.Exception.Message -ForegroundColor Red }
            }
            '2' {
                try {
                    Write-Host 'Undo replaces later manual changes to these same settings with pre-apply values.' -ForegroundColor Yellow
                    if ((Read-Host 'Type UNDO to continue') -ceq 'UNDO') {
                        Write-Host (Undo-Tweaks $state)
                        Write-Host 'Save work, then sign out and back in to refresh settings.'
                    }
                } catch { Write-Host $_.Exception.Message -ForegroundColor Red }
            }
            '3' {
                Write-Host "1 Startup apps: disabling sync/security/device tools may stop their features.`n2 Game Mode: compare frame times in your games.`n3 Graphics: GPU preference/HAGS depends on hardware; test one change at a time.`n4 Captures: disabling background recording loses replay clips.`n5 Storage: review files; deleted files are not covered by Undo.`n6 Power: higher performance can increase heat, fan noise and battery drain.`n7 Windows Update`n8 Installed apps: uninstalling apps can remove their data and features.`nEnter to cancel"
                $pages = @{ '1'='startupapps'; '2'='gaming-gamemode'; '3'='display-advancedgraphics'; '4'='gaming-gamedvr'; '5'='storagesense'; '6'='powersleep'; '7'='windowsupdate'; '8'='appsfeatures' }
                $choice = Read-Host 'Open page'
                if ($pages.ContainsKey($choice)) {
                    try { Start-Process ('ms-settings:' + $pages[$choice]) }
                    catch { Write-Host "Could not open Settings: $($_.Exception.Message)" -ForegroundColor Red }
                }
            }
            '4' { Write-Host $state }
            '5' { Get-Content -LiteralPath (Join-Path $PSScriptRoot 'NVIDIA-DISPLAY.md') | Out-Host }
            '0' { exit 0 }
            default { Write-Host 'Choose one of the listed options.' }
        }
    }
} catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
finally { if ($locked) { $mutex.ReleaseMutex() }; if ($null -ne $mutex) { $mutex.Dispose() } }

