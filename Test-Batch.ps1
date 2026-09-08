# Exercise CMD control flow with system commands replaced by a harmless mock.
$ErrorActionPreference='Stop'
$root=Join-Path $PSScriptRoot ('.test-output\batch-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root -Force | Out-Null
$mock=Join-Path $root 'mock.cmd'
@'
@echo off
if "%~1"=="Backup" mkdir "%SOMETIME_BACKUP%" >nul 2>&1
echo %~1>>"%~dp0calls.txt"
if "%~1"=="%MOCK_FAIL%" exit /b 1
exit /b 0
'@ | Set-Content -LiteralPath $mock -Encoding ascii
$source=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'main 1.bat')
$result=foreach($line in $source){
    if($line -match '^\s*"%SOMETIME_PS%".*-Action (\S+)') {'call "'+$mock+'" '+$Matches[1];continue}
    if($line -match '^\s*"%SOMETIME_PS%".*-Command ') {'rem Mock elevation';continue}
    if($line -match '^set "SOMETIME_BACKUP=') {'set "SOMETIME_BACKUP='+$root+'\%MOCK_CASE%"';continue}
    if($line -match '^reg(?:\.exe)? add ') {'call "'+$mock+'" Registry >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Registry preference"';continue}
    if($line -match '^powercfg') {'call "'+$mock+'" Hibernate >>"%SOMETIME_LOG%" 2>&1 || call :Failed "Hibernation"';continue}
    if($line -match '^fltmc') {'ver >nul';continue}
    if($line -match '^\s*(timeout|pause|chcp|cls|color|title)\b') {'rem Display or wait omitted';continue}
    if($line -and $line -notmatch '^\s*(@?echo|set|if |exit |\)|:|call :|rem )'){throw "Unrecognised batch instruction: $line"}
    $line
}
$path=Join-Path $root 'flow.cmd'
$result | Set-Content -LiteralPath $path -Encoding ascii
$oldFail=$env:MOCK_FAIL;$oldCase=$env:MOCK_CASE
try {
    foreach($case in @('Success','Validate','Backup','Security','Registry')){
        $env:MOCK_CASE=$case;$env:MOCK_FAIL=$case
        & $env:ComSpec /d /c "`"$path`"" > (Join-Path $root "$case-output.txt") 2>&1
        $code=$LASTEXITCODE
        $expected=1;if($case -eq 'Success'){$expected=0}
        if($code -ne $expected){throw "$case returned $code; expected $expected"}
        $calls=@(Get-Content (Join-Path $root 'calls.txt'))
        if($case -in @('Validate','Backup') -and 'Security' -in $calls){throw 'A fatal stage did not stop execution'}
        if($case -in @('Success','Security','Registry') -and 'Cleanup' -notin $calls){throw 'Flow did not reach cleanup'}
        if($case -in @('Security','Registry') -and -not (Test-Path (Join-Path $root "$case\warnings.flag"))){throw 'Missing failure warning'}
        Write-Host "PASS: mocked batch $case path, exit $code"
        Clear-Content -LiteralPath (Join-Path $root 'calls.txt')
    }
} finally {$env:MOCK_FAIL=$oldFail;$env:MOCK_CASE=$oldCase}
Write-Host 'Batch control-flow checks passed; no optimiser system commands executed.'
