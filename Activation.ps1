# Optional third-party launcher. Dot-sourcing this file performs no downloads.
function Start-MasProcess {
    $command = @'
$ErrorActionPreference = 'Stop'
try {
    irm https://get.activated.win/ | iex
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
'@
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    $exe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    # Separate process isolates the downloaded script from the optimiser's state.
    return Start-Process -FilePath $exe -ArgumentList @('-NoLogo','-NoProfile','-EncodedCommand',$encoded) -Wait -PassThru
}

function Show-ActivationOption {
    Write-Host 'THIRD-PARTY ACTIVATION TOOL - outside optimiser backup/undo' -ForegroundColor Yellow
    Write-Host 'This downloads and executes the current script at https://get.activated.win/.'
    Write-Host 'It downloads additional code and asks for administrator access. Remote content can change.'
    Write-Host 'Activation/licensing or other system changes cannot be undone by this optimiser.'
    Write-Host 'The full downloaded tool has not been audited here. Use only with appropriate licence rights.'
    Write-Host 'The supplied command opens the MAS menu; it does not select an unattended activation method.'
    if ((Read-Host 'Type LAUNCH MAS to open it, or Enter to cancel') -cne 'LAUNCH MAS') {
        Write-Host 'Cancelled. Nothing downloaded or executed.'
        return
    }
    try {
        $process = Start-MasProcess
        if ($process.ExitCode -ne 0) { throw "Launcher exited with code $($process.ExitCode)." }
        Write-Host 'Activation tool closed. Activation success is not verified; check Windows Settings > System > Activation.'
    } catch { Write-Host "Activation launcher failed: $($_.Exception.Message)" -ForegroundColor Red }
}

