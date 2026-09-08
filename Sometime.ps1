#requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Run','Validate','Backup','Security','Background','Apps','Runtime','Power','Cleanup','Restore','Activation')]
    [string]$Action='Run',
    [switch]$Preview,
    [switch]$Library
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Get-UpdateServices { @('wuauserv','BITS','UsoSvc','DoSvc','WaaSMedicSvc') }
function Get-BackgroundServices { @('DiagTrack','dmwappushservice','MapsBroker','RetailDemo','RemoteRegistry','Fax') }
function Test-25H2($Info) { $Info.ProductType -eq 1 -and $Info.BuildNumber -eq '26200' }
function Show-Result([string]$Message,[string]$Color='Cyan') { Write-Host $Message -ForegroundColor $Color }

function Disable-ListedServices([string[]]$Names) {
    $failed=$false
    foreach($name in $Names) {
        try {
            $service=Get-Service -Name $name -ErrorAction SilentlyContinue
            if(-not $service) { Show-Result "[SKIP] $name is not installed." 'DarkGray'; continue }
            Set-Service -Name $name -StartupType Disabled
            if($service.Status -ne 'Stopped') { Stop-Service -Name $name -Force }
            $actual=Get-Service -Name $name
            if($actual.StartType -ne 'Disabled' -or $actual.Status -ne 'Stopped') { throw 'State verification failed.' }
            Show-Result "[OK] $name stopped and disabled." 'Green'
        } catch { $failed=$true; Show-Result "[WARNING] $name : $($_.Exception.Message)" 'Yellow' }
    }
    if($failed) { throw 'Some services could not be disabled. No protected-service permissions were bypassed.' }
}
function Disable-DefenderRealtime {
    Show-Result 'WARNING: attempting to turn off Defender real-time malware protection.' 'Yellow'
    $before=Get-MpComputerStatus
    if($before.PSObject.Properties.Name -contains 'IsTamperProtected' -and $before.IsTamperProtected) {
        throw 'Defender tamper protection is enabled; the disable step was skipped. No bypass is used.'
    }
    Set-MpPreference -DisableRealtimeMonitoring $true
    if((Get-MpComputerStatus).RealTimeProtectionEnabled) { throw 'Defender real-time protection remains enabled. Windows or policy blocked the change.' }
    Show-Result '[OK] Defender real-time protection is currently off. Windows may re-enable it later.' 'Green'
}
function Save-OriginalBackups([string]$Directory) {
    New-Item -ItemType Directory -Path $Directory -ErrorAction Stop | Out-Null
    $keys=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach($line in [IO.File]::ReadAllLines((Join-Path $PSScriptRoot 'main 1.bat'))) {
        if($line -match '^reg(?:\.exe)?\s+add\s+(?:"([^"]+)"|(\S+))') {
            $key=$Matches[1]; if(-not $key){$key=$Matches[2]}
            if($key -notmatch '^(HKCU|HKLM|HKU|HKEY_CURRENT_USER|HKEY_LOCAL_MACHINE|HKEY_USERS)\\' -or $key.Contains('%')) { throw 'Unrecognised registry backup target.' }
            [void]$keys.Add($key)
        }
    }
    $index=0; $manifest=@()
    foreach($key in $keys) {
        $index++; $file=('registry-{0:D3}.reg' -f $index)
        & "$env:SystemRoot\System32\reg.exe" query $key *> $null
        $exists=$LASTEXITCODE -eq 0
        if($exists) {
            & "$env:SystemRoot\System32\reg.exe" export $key (Join-Path $Directory $file) /y *> $null
            if($LASTEXITCODE -ne 0) { throw "Could not back up $key. No tweaks started." }
        }
        $manifest += [pscustomobject]@{ Key=$key; Existed=$exists; File=$file }
    }
    $manifest | Export-Clixml -LiteralPath (Join-Path $Directory 'registry-manifest.clixml')
    Get-CimInstance Win32_Service | Where-Object Name -in (@(Get-UpdateServices)+@(Get-BackgroundServices)) |
        Select-Object Name,StartMode,State | Export-Clixml -LiteralPath (Join-Path $Directory 'services.clixml')
    if(Get-Command Get-MpPreference -ErrorAction SilentlyContinue) {
        Get-MpPreference | Select-Object DisableRealtimeMonitoring | Export-Clixml -LiteralPath (Join-Path $Directory 'defender.clixml')
    }
    & "$env:SystemRoot\System32\powercfg.exe" /getactivescheme | Set-Content -LiteralPath (Join-Path $Directory 'power-plan.txt')
    if($LASTEXITCODE -ne 0){ throw 'Could not capture the active power plan.' }
    Show-Result "Registry and service snapshots saved to $Directory" 'Green'
    Enable-ComputerRestore -Drive ($env:SystemDrive+'\')
    $recent=@(Get-ComputerRestorePoint | Where-Object {
        [Management.ManagementDateTimeConverter]::ToDateTime($_.CreationTime) -gt (Get-Date).AddHours(-24)
    } | Sort-Object SequenceNumber -Descending)
    if($recent.Count) {
        Show-Result "Using existing restore point $($recent[0].SequenceNumber) from the last 24 hours. It may predate other recent changes." 'Yellow'
    } else {
        Checkpoint-Computer -Description 'SOMETIME before original-flow tweaks' -RestorePointType MODIFY_SETTINGS
        $created=@(Get-ComputerRestorePoint | Where-Object Description -eq 'SOMETIME before original-flow tweaks')
        if(-not $created.Count){ throw 'Restore point could not be verified. No tweaks started.' }
        Show-Result 'Restore point created and verified.' 'Green'
    }
    'Backups verified; stage log follows.' | Set-Content -LiteralPath (Join-Path $Directory 'run.log')
}
function Remove-ListedApps {
    Show-Result 'WARNING: removing listed apps for the current user can remove app data/features. Reinstallation may require Store access and a licence. Registry backups do not restore apps.' 'Yellow'
    $patterns=@(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Apps.txt') | Where-Object { $_ -and -not $_.StartsWith('#') })
    $seen=@{}; $failures=0
    foreach($pattern in $patterns) {
        foreach($app in @(Get-AppxPackage -Name "*$pattern*")) {
            if($seen.ContainsKey($app.PackageFullName)){continue}
            $seen[$app.PackageFullName]=$true
            if($app.IsFramework -or $app.NonRemovable) { Show-Result "[SKIP] Protected/framework package: $($app.Name)" 'DarkGray'; continue }
            try {
                Remove-AppxPackage -Package $app.PackageFullName
                if(Get-AppxPackage -Name $app.Name){throw 'Package is still registered.'}
                Show-Result "[OK] Removed $($app.Name) for this user." 'Green'
            } catch { $failures++; Show-Result "[WARNING] $($app.Name): $($_.Exception.Message)" 'Yellow' }
        }
    }
    if(-not $seen.Count){Show-Result 'No matching removable apps installed.' 'DarkGray'}
    if($failures){throw "$failures app removals failed; see log."}
}
function Install-MicrosoftRuntime([string]$Directory) {
    if($env:PROCESSOR_ARCHITECTURE -ne 'AMD64'){Show-Result 'Automatic x64 runtime installation skipped on this architecture.' 'Yellow';return}
    $runtime=Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64' -ErrorAction SilentlyContinue
    if($runtime -and $runtime.Installed -eq 1){Show-Result 'Visual C++ x64 runtime already installed.' 'Green';return}
    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
    $file=Join-Path $Directory 'vc_redist.x64.exe'
    Invoke-WebRequest 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -UseBasicParsing -OutFile $file
    $signature=Get-AuthenticodeSignature -LiteralPath $file
    if($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation(?:,|$)'){throw 'Runtime publisher/signature verification failed; installer not run.'}
    $process=Start-Process -FilePath $file -ArgumentList '/install /quiet /norestart' -Wait -PassThru
    if($process.ExitCode -notin @(0,3010)){throw "Microsoft runtime installer failed: $($process.ExitCode)"}
    if($process.ExitCode -eq 3010){Show-Result 'Runtime installed; restart later to finish.' 'Yellow'}else{Show-Result 'Runtime installed.' 'Green'}
}
function Set-PerformancePower {
    Show-Result 'WARNING: High performance can increase heat, power consumption and fan noise. Hibernation was disabled by the batch preferences.' 'Yellow'
    Add-Type -AssemblyName System.Windows.Forms
    if([Windows.Forms.SystemInformation]::PowerStatus.PowerLineStatus -ne 'Online'){Show-Result 'Keeping current power plan while on battery or unknown AC status.' 'Yellow';return}
    $schemes=& "$env:SystemRoot\System32\powercfg.exe" /list
    if(($schemes -join '') -notmatch '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'){Show-Result 'Built-in High performance is unavailable; keeping the current plan.' 'Yellow';return}
    & "$env:SystemRoot\System32\powercfg.exe" /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    if($LASTEXITCODE -ne 0){throw 'Power plan change failed.'}
    Show-Result 'Built-in High performance plan selected.' 'Green'
}
function Clear-OldTemporaryFiles {
    Show-Result 'WARNING: deletes files older than 7 days inside your temp folder. Deleted files are not covered by registry backups. Reparse points are skipped.' 'Yellow'
    $root=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
    $local=[Environment]::GetFolderPath('LocalApplicationData').TrimEnd('\')+'\'
    if(-not $root.StartsWith($local,[StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $root -PathType Container)){throw 'Unexpected temporary directory; cleanup skipped.'}
    $current=$root
    while($current -and $current.StartsWith($local.TrimEnd('\'),[StringComparison]::OrdinalIgnoreCase)){
        if((Get-Item -LiteralPath $current -Force).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Temp path contains a reparse point; cleanup skipped.'}
        $current=[IO.Path]::GetDirectoryName($current)
    }
    $pending=New-Object 'System.Collections.Generic.Stack[string]';$pending.Push($root)
    $cutoff=(Get-Date).AddDays(-7);$removed=0;$skipped=0
    while($pending.Count){
        foreach($item in @(Get-ChildItem -LiteralPath $pending.Pop() -Force -ErrorAction SilentlyContinue)){
            if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){$skipped++;continue}
            if($item.PSIsContainer){$pending.Push($item.FullName);continue}
            if($item.LastWriteTime -lt $cutoff){
                try {Remove-Item -LiteralPath $item.FullName -Force; $removed++}catch{$skipped++}
            }
        }
    }
    Show-Result "Removed $removed old temporary files; $skipped files/links skipped." 'Green'
    & "$env:SystemRoot\System32\ipconfig.exe" /flushdns
    if($LASTEXITCODE -ne 0){throw 'DNS cache flush failed.'}
}

if($Library){return}
$transcribing=$false
try {
    if($Preview){
        Show-Result 'Automatic original-style flow: Backup -> Defender/Windows Update -> appearance/input/Game DVR -> privacy -> background services -> app removal -> Microsoft runtime -> power -> temp/DNS cleanup.'
        Show-Result 'WARNINGS: reduced security, lost updates/recording/location/notifications, changed input/appearance, app removal, no hibernation, possible heat/battery impact. No NVIDIA import or forced reboot.' 'Yellow'
        Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Apps.txt')
        exit 0
    }
    if($Action -eq 'Run'){& (Join-Path $PSScriptRoot 'main 1.bat');exit $LASTEXITCODE}
    if($Action -eq 'Activation'){. (Join-Path $PSScriptRoot 'Activation.ps1');Show-ActivationOption;exit 0}
    if($Action -eq 'Restore'){
        Show-Result 'System Restore can revert system settings, but is not a backup of personal/app data. Registry exports are reference snapshots, not an exact one-click undo.' 'Yellow'
        Start-Process -FilePath "$env:SystemRoot\System32\rstrui.exe"
        exit 0
    }
    if(-not (Test-25H2 (Get-CimInstance Win32_OperatingSystem))){throw 'This build targets Windows 11 25H2 client build 26200. Other builds are blocked.'}
    if($Action -eq 'Validate'){exit 0}
    $principal=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Start main 1.bat and accept its administrator prompt.'}
    $directory=$env:SOMETIME_BACKUP
    $base=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'SometimeOptimizer\OriginalFlow'
    if(-not $directory -or -not [IO.Path]::GetFullPath($directory).StartsWith($base+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Missing or invalid run backup directory.'}
    if($Action -eq 'Backup'){Save-OriginalBackups $directory;exit 0}
    if(-not (Test-Path -LiteralPath (Join-Path $directory 'registry-manifest.clixml'))){throw 'Run the backup stage first.'}
    Start-Transcript -LiteralPath (Join-Path $directory 'run.log') -Append | Out-Null;$transcribing=$true
    switch($Action){
        'Security' {
            Show-Result 'WARNING: Windows Update/security patches and Defender malware protection are being disabled. Store downloads can be affected. Windows may later restore settings.' 'Yellow'
            $failures=@()
            try{Disable-ListedServices @(Get-UpdateServices)}catch{$failures+=$_.Exception.Message}
            try{Disable-DefenderRealtime}catch{$failures+=$_.Exception.Message}
            if($failures.Count){throw ($failures -join "`n")}
        }
        'Background' {Show-Result 'Disables diagnostic telemetry, offline map updates, retail demo, remote registry and fax services. Features relying on these services will stop.' 'Yellow';Disable-ListedServices @(Get-BackgroundServices)}
        'Apps' {Remove-ListedApps}
        'Runtime' {Install-MicrosoftRuntime $directory}
        'Power' {Set-PerformancePower}
        'Cleanup' {Clear-OldTemporaryFiles}
    }
} catch {Show-Result $_.Exception.Message 'Red';exit 1}
finally {if($transcribing){Stop-Transcript | Out-Null}}
