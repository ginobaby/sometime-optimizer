# Tests use an in-memory registry replacement. No Windows settings are changed.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Core.ps1')
$script:values = @{}
$script:writes = 0
$script:failId = ''
function Get-IdentityTag { 'test-user@test-machine' }
function Read-Setting($Tweak) {
    if ($script:values.ContainsKey($Tweak.Id)) { return $script:values[$Tweak.Id] }
    [pscustomobject]@{ Id=$Tweak.Id; Exists=$false; Kind=$null; Value=$null }
}
function Write-Setting($Tweak, $Setting) {
    $script:writes++
    if ($script:failId -eq $Tweak.Id) { $script:failId=''; throw 'Injected write failure' }
    $script:values[$Tweak.Id] = [pscustomobject]@{ Id=$Tweak.Id; Exists=$Setting.Exists; Kind=$Setting.Kind; Value=$Setting.Value }
}
function Assert($Condition, $Message) { if (-not $Condition) { throw "FAIL: $Message" }; Write-Host "PASS: $Message" }
function Assert-Throws([scriptblock]$Action, [string]$Pattern) {
    $caught=$false
    try { & $Action | Out-Null } catch { if ($_.Exception.Message -notlike "*$Pattern*") { throw }; $caught=$true }
    Assert $caught "Rejects: $Pattern"
}
$testRoot = Join-Path $PSScriptRoot ('.test-output\' + [guid]::NewGuid().ToString())
$state = Join-Path $testRoot 'normal'
$preview = @(Invoke-Tweaks -Ids @('extensions','mouse') -StateDirectory $state -Preview)
Assert ($preview.Count -eq 2 -and $script:writes -eq 0 -and -not (Test-Path $state)) 'Preview makes no registry or filesystem changes'
Assert-Throws { Invoke-Tweaks -Ids @('invalid') -StateDirectory $state } 'Unknown tweak'
Assert (Test-SupportedOS ([pscustomobject]@{ ProductType=1; BuildNumber='26200' })) '25H2 client accepted'
Assert (-not (Test-SupportedOS ([pscustomobject]@{ ProductType=3; BuildNumber='26200' }))) 'Server rejected'
Assert (-not (Test-SupportedOS ([pscustomobject]@{ ProductType=1; BuildNumber='26100' }))) 'Other builds rejected'
$script:values['extensions'] = [pscustomobject]@{ Id='extensions'; Exists=$true; Kind='DWord'; Value=1 }
Invoke-Tweaks -Ids @('extensions','extensions','mouse') -StateDirectory $state | Out-Null
Assert ($script:writes -eq 2) 'Duplicate choices apply once'
Assert ($script:values['extensions'].Value -eq 0) 'Selected setting applied'
Assert-Throws { Invoke-Tweaks -Ids @('extensions') -StateDirectory $state } 'active backup'
Undo-Tweaks $state | Out-Null
Assert ($script:values['extensions'].Value -eq 1) 'Original DWORD restored'
Assert (-not $script:values['mouse'].Exists) 'Originally absent value removed on undo'
$before = $script:writes
Undo-Tweaks $state | Out-Null
Assert ($before -eq $script:writes) 'Repeated undo makes no writes'
Invoke-Tweaks -Ids @('mouse') -StateDirectory $state | Out-Null
Undo-Tweaks $state | Out-Null
Assert (@(Get-ChildItem $state -Filter '*.clixml').Count -eq 2) 'Prior restored backup retained'
$script:failId='mouse'
$failureState = Join-Path $testRoot 'failure'
Assert-Throws { Invoke-Tweaks -Ids @('extensions','mouse') -StateDirectory $failureState } 'Original values restored'
Assert ($script:values['extensions'].Value -eq 1) 'Partial failure automatically rolled back'
$journal = Read-Journal (Join-Path $failureState 'active.clixml')
$journal.Status='Pending'
Save-Journal $journal (Join-Path $failureState 'active.clixml')
Undo-Tweaks $failureState | Out-Null
Assert ((Read-Journal (Join-Path $failureState 'active.clixml')).Status -eq 'Restored') 'Interrupted transaction can be undone'
$journal.Identity='different-user'
Save-Journal $journal (Join-Path $failureState 'active.clixml')
Assert-Throws { Undo-Tweaks $failureState } 'another user/computer'
$journal.Identity=Get-IdentityTag
$journal.Entries[0].Id='unknown-path'
Save-Journal $journal (Join-Path $failureState 'active.clixml')
Assert-Throws { Undo-Tweaks $failureState } 'Invalid or duplicate'
$blocked = Join-Path $testRoot 'blocked'
[void][IO.Directory]::CreateDirectory($blocked)
[void][IO.Directory]::CreateDirectory((Join-Path $blocked 'active.clixml.tmp'))
$before=$script:writes
Assert-Throws { Invoke-Tweaks -Ids @('mouse') -StateDirectory $blocked } 'Access'
Assert ($before -eq $script:writes) 'Backup failure prevents writes'
$executable = (Get-Content (Join-Path $PSScriptRoot 'Optimizer.ps1') -Raw) + (Get-Content (Join-Path $PSScriptRoot 'Core.ps1') -Raw) + (Get-Content (Join-Path $PSScriptRoot 'main 1.bat') -Raw)
Assert ($executable -notmatch '(?i)importProfile|nvidiaProfileInspector|PowerMizer|nvlddmkm|ChangeDisplaySettings|SetDisplayConfig|PreferredRefreshRate|curl\s|Invoke-WebRequest|Invoke-RestMethod|bcdedit|wmic\s|NSudo|Remove-AppxPackage') 'No NVIDIA imports/display writes, downloads, boot edits or legacy debloat in executable files'
Write-Host 'All isolated tests passed. No real registry writes or optimiser actions were executed.'

