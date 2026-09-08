# Isolated checks: no optimiser stages or security changes are run on this PC.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Sometime.ps1') -Library
function Assert($Condition,[string]$Message){if(-not $Condition){throw "FAIL: $Message"};Write-Host "PASS: $Message"}
function Assert-Throws([scriptblock]$Body,[string]$Pattern){
    $caught=$false
    try{& $Body | Out-Null}catch{if($_.Exception.Message -notlike "*$Pattern*"){throw};$caught=$true}
    Assert $caught "Reports $Pattern"
}
$tokens=$null;$parseErrors=$null
foreach($file in @('Sometime.ps1','Activation.ps1','Test-Core.ps1')){
    [void][Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $file),[ref]$tokens,[ref]$parseErrors)
    Assert (-not $parseErrors.Count) "$file parses"
}
Assert (Test-25H2 ([pscustomobject]@{ProductType=1;BuildNumber='26200'})) '25H2 client accepted'
Assert (-not (Test-25H2 ([pscustomobject]@{ProductType=3;BuildNumber='26200'}))) 'Server rejected'
Assert (-not (Test-25H2 ([pscustomobject]@{ProductType=1;BuildNumber='26100'}))) 'Other Windows builds rejected'
$batch=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'main 1.bat') -Raw
Assert ($batch -notmatch '(?im)^\s*(set /p|choice\s)') 'Batch automatically runs without a numbered selection menu'
Assert ($batch -match 'Windows Update and Defender' -and $batch -match '-Action Backup') 'Security stages retained after mandatory backup'
Assert ($batch -notmatch '(?im)^\s*>>') 'Log redirections stay on their command lines'
$registryLines=@($batch -split '\r?\n' | Where-Object {$_ -match '^reg(?:\.exe)? add '})
Assert ($registryLines.Count -gt 40) 'Original batch preference set retained, beyond the six-tweak edition'
Assert (@($registryLines | Where-Object {$_ -notmatch '\|\| call :Failed'}).Count -eq 0) 'Every native registry command checks its exit code'
$labels=@([regex]::Matches($batch,'(?im)^:([A-Za-z][A-Za-z0-9]*)') | ForEach-Object {$_.Groups[1].Value})
foreach($target in @([regex]::Matches($batch,'(?i)(?:goto|call)\s+:([A-Za-z][A-Za-z0-9]*)') | ForEach-Object {$_.Groups[1].Value} | Select-Object -Unique)){
    Assert ($target -in $labels) "Batch target $target exists"
}
$runtime=(Get-Content (Join-Path $PSScriptRoot 'Sometime.ps1') -Raw)+$batch
Assert ($runtime -notmatch '(?i)nvidiaProfileInspector|importProfile|QuakedOptimizedNV|PowerMizer|nvlddmkm|bcdedit\s|wmic\s|NSudo|takeown\s|icacls\s|shutdown\s+/r') 'NVIDIA/boot overrides, legacy WMIC, ownership bypass and forced restart absent'
$apps=@(Get-Content (Join-Path $PSScriptRoot 'Apps.txt'))
Assert ($apps.Count -gt 30 -and ($apps -join ' ') -notmatch '(?i)WindowsStore|StorePurchase|HEIF|VP9|WebMedia|Webp|Realtek|HPAudio|QuickAssist|WindowsTerminal|ScreenSketch') 'Broad app list retained while Store, codecs, device controls and recovery tools are excluded'
Assert ('wuauserv' -in @(Get-UpdateServices) -and 'BITS' -in @(Get-UpdateServices)) 'Windows Update disable targets retained'
Assert ((@(Get-BackgroundServices) -join ' ') -notmatch 'WlanSvc|Spooler|bthserv|BDESVC|WbioSrvc|TrustedInstaller') 'Essential device, encryption and servicing services excluded'

# Mock Defender for three outcomes; never invoke the installed Defender cmdlets.
$script:tamper=$true;$script:realtime=$true;$script:setCalls=0;$script:ignoreChange=$false
function Get-MpComputerStatus{[pscustomobject]@{IsTamperProtected=$script:tamper;RealTimeProtectionEnabled=$script:realtime}}
function Set-MpPreference{param([bool]$DisableRealtimeMonitoring);$script:setCalls++;if(-not $script:ignoreChange){$script:realtime=-not $DisableRealtimeMonitoring}}
Assert-Throws {Disable-DefenderRealtime} 'tamper protection'
Assert ($script:setCalls -eq 0) 'Tamper protection is not bypassed'
$script:tamper=$false
Disable-DefenderRealtime
Assert (-not $script:realtime -and $script:setCalls -eq 1) 'Defender disable result is verified (mocked)'
$script:realtime=$true;$script:ignoreChange=$true
Assert-Throws {Disable-DefenderRealtime} 'remains enabled'

$script:mockService=[pscustomobject]@{Status='Running';StartType='Automatic'}
function Get-Service{param($Name,$ErrorAction);if($Name -ne 'Missing'){return $script:mockService}}
function Set-Service{param($Name,$StartupType);$script:mockService.StartType=$StartupType}
function Stop-Service{param($Name,[switch]$Force);$script:mockService.Status='Stopped'}
Disable-ListedServices @('Mock','Missing')
Assert ($script:mockService.StartType -eq 'Disabled' -and $script:mockService.Status -eq 'Stopped') 'Service startup and running state both verified (mocked)'
function Set-Service{param($Name,$StartupType);throw 'Access denied'}
Assert-Throws {Disable-ListedServices @('Mock')} 'could not be disabled'

. (Join-Path $PSScriptRoot 'Activation.ps1')
$script:launches=0;$script:answer=''
function Read-Host{param($Prompt);$script:answer}
function Start-MasProcess{$script:launches++;[pscustomobject]@{ExitCode=0}}
Show-ActivationOption
Assert ($script:launches -eq 0) 'Cancelling activation runs nothing'
$script:answer='LAUNCH MAS';Show-ActivationOption
Assert ($script:launches -eq 1) 'Activation is a separately confirmed launcher (mocked)'
Write-Host 'All checks passed. No real registry, service, Defender, app, installer or cleanup operations ran.'
