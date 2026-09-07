Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Tweaks {
    @(
        [pscustomobject]@{ Id='extensions'; Title='Show file extensions'; Warning='Changing a suffix while renaming can stop a file opening.'; Path='Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='HideFileExt'; Kind='DWord'; Value=0 }
        [pscustomobject]@{ Id='transparency'; Title='Disable transparency'; Warning='Changes Start and other surfaces; no guaranteed FPS improvement.'; Path='Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'; Name='EnableTransparency'; Kind='DWord'; Value=0 }
        [pscustomobject]@{ Id='taskbar-animation'; Title='Reduce taskbar animations'; Warning='Changes taskbar transitions. Windows updates may ignore this preference; this is not a global animation switch.'; Path='Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='TaskbarAnimations'; Kind='DWord'; Value=0 }
        [pscustomobject]@{ Id='menu-delay'; Title='Shorten classic menu delay to 200 ms'; Warning='Hover menus may open accidentally. Modern menus may ignore this.'; Path='Control Panel\Desktop'; Name='MenuShowDelay'; Kind='String'; Value='200' }
        [pscustomobject]@{ Id='mouse'; Title='Disable pointer acceleration'; Warning='Changes desktop mouse feel and games using Windows pointer input. Raw-input games may be unaffected.'; Path='Control Panel\Mouse'; Name='MouseSpeed'; Kind='String'; Value='0' }
        [pscustomobject]@{ Id='dark-apps'; Title='Use dark app theme'; Warning='Changes supported app appearance; some apps use their own theme. Cosmetic only.'; Path='Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'; Name='AppsUseLightTheme'; Kind='DWord'; Value=0 }
    )
}
function Test-SupportedOS($Info) {
    return ($Info.ProductType -eq 1 -and $Info.BuildNumber -eq '26200')
}
function Get-IdentityTag {
    return ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value + '@' + $env:COMPUTERNAME)
}
function Read-Setting($Tweak) {
    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($Tweak.Path)
    try {
        $exists = $null -ne $key -and $key.GetValueNames() -contains $Tweak.Name
        $kind = $null; $value = $null
        if ($exists) {
            $kind = $key.GetValueKind($Tweak.Name).ToString()
            if ($kind -notin @('String','DWord')) { throw "Unexpected registry type for $($Tweak.Id): $kind. No changes made." }
            $value = $key.GetValue($Tweak.Name)
        }
        return [pscustomobject]@{ Id=$Tweak.Id; Exists=$exists; Kind=$kind; Value=$value }
    } finally { if ($null -ne $key) { $key.Dispose() } }
}
function Write-Setting($Tweak, $Setting) {
    if ($Setting.Exists) {
        $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($Tweak.Path)
        try {
            $value = $Setting.Value
            if ($Setting.Kind -eq 'DWord') { $value = [int]$value }
            $kind = [Microsoft.Win32.RegistryValueKind]([Enum]::Parse([Microsoft.Win32.RegistryValueKind], $Setting.Kind))
            $key.SetValue($Tweak.Name, $value, $kind)
        } finally { $key.Dispose() }
    } else {
        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($Tweak.Path, $true)
        try { if ($null -ne $key) { $key.DeleteValue($Tweak.Name, $false) } }
        finally { if ($null -ne $key) { $key.Dispose() } }
    }
    $actual = Read-Setting $Tweak
    if ($actual.Exists -ne $Setting.Exists -or ($Setting.Exists -and
        ($actual.Kind -ne $Setting.Kind -or $actual.Value -cne $Setting.Value))) { throw "Verification failed: $($Tweak.Id)" }
}
function Save-Journal($Journal, [string]$Path) {
    # Persist originals before any registry writes. Never execute backup content.
    $temporary = $Path + '.tmp'
    $Journal | Export-Clixml -LiteralPath $temporary -Depth 6
    Move-Item -LiteralPath $temporary -Destination $Path -Force
}
function Read-Journal([string]$Path) {
    $journal = Import-Clixml -LiteralPath $Path
    if ($journal.Schema -ne 1 -or $journal.Identity -ne (Get-IdentityTag)) { throw 'Backup belongs to another user/computer or has an unsupported format.' }
    if ($journal.Status -notin @('Pending','Applied','Restored')) { throw 'Invalid backup status.' }
    $seen = @{}
    foreach ($entry in $journal.Entries) {
        if ($entry.Id -notin @((Get-Tweaks).Id) -or $seen.ContainsKey($entry.Id)) { throw 'Invalid or duplicate backup setting.' }
        $seen[$entry.Id] = $true
        if ($entry.Exists -isnot [bool]) { throw 'Invalid backup existence flag.' }
        if ($entry.Exists) {
            if ($entry.Kind -eq 'DWord' -and $entry.Value -is [int]) { continue }
            if ($entry.Kind -eq 'String' -and $entry.Value -is [string]) { continue }
            throw 'Invalid backup value type.'
        }
    }
    if (@($journal.Entries).Count -eq 0) { throw 'Empty backup.' }
    return $journal
}
function Restore-Journal($Journal, [string]$Path) {
    $errors = @()
    $entries = @($Journal.Entries)
    [array]::Reverse($entries)
    foreach ($entry in $entries) {
        try {
            $tweak = Get-Tweaks | Where-Object Id -eq $entry.Id
            Write-Setting $tweak $entry
        } catch { $errors += $_.Exception.Message }
    }
    if ($errors.Count) { throw ('Undo incomplete; keep the backup and retry. ' + ($errors -join '; ')) }
    $Journal.Status = 'Restored'
    Save-Journal $Journal $Path
}
function Invoke-Tweaks([string[]]$Ids, [string]$StateDirectory, [switch]$Preview) {
    if (-not $Ids.Count) { throw 'Choose at least one tweak.' }
    $catalog = @(Get-Tweaks)
    foreach ($id in $Ids) { if ($id -notin $catalog.Id) { throw "Unknown tweak: $id" } }
    $selected = @($catalog | Where-Object Id -in $Ids)
    if ($Preview) { return $selected }
    [void][IO.Directory]::CreateDirectory($StateDirectory)
    $path = Join-Path $StateDirectory 'active.clixml'
    if (Test-Path -LiteralPath $path) {
        $previous = Read-Journal $path
        if ($previous.Status -ne 'Restored') { throw 'An active backup exists. Undo it before applying another selection.' }
        Copy-Item -LiteralPath $path -Destination (Join-Path $StateDirectory (([guid]::NewGuid().ToString()) + '.clixml'))
    }
    $entries = @($selected | ForEach-Object { Read-Setting $_ })
    $journal = [pscustomobject]@{ Schema=1; Identity=(Get-IdentityTag); Created=(Get-Date).ToString('o'); Status='Pending'; Entries=$entries }
    Save-Journal $journal $path
    try {
        foreach ($tweak in $selected) {
            Write-Setting $tweak ([pscustomobject]@{ Exists=$true; Kind=$tweak.Kind; Value=$tweak.Value })
        }
        $journal.Status = 'Applied'
        Save-Journal $journal $path
    } catch {
        $failure = $_.Exception.Message
        try { Restore-Journal $journal $path }
        catch { throw "$failure`n$($_.Exception.Message)" }
        throw "$failure`nOriginal values restored."
    }
    return "Applied and verified $($selected.Count) settings. Backup: $path"
}
function Undo-Tweaks([string]$StateDirectory) {
    $path = Join-Path $StateDirectory 'active.clixml'
    if (-not (Test-Path -LiteralPath $path)) { throw 'No backup from this version exists.' }
    $journal = Read-Journal $path
    if ($journal.Status -eq 'Restored') { return 'This backup has already been restored.' }
    Restore-Journal $journal $path
    return 'Original setting values restored and verified.'
}
