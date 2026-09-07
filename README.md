# SOMETIME Optimizer — Windows 11 25H2

An opt-in replacement for the supplied SOMETIME/Oneclick batch optimiser. The preference tweaks work offline; the separately confirmed activation launcher requires internet access. It targets Windows 11 **25H2 client build 26200** and uses Windows PowerShell 5.1 and CIM instead of WMIC. This is a conservative preferences tool, not a promise of extra FPS.

## Run

Download the whole repository as a ZIP and extract it. Double-click **main 1.bat** normally, **without** administrator privileges. Keep `Sometime.ps1`, `Core.ps1` and `Activation.ps1` alongside it. Choose options, read their warnings, then type `APPLY`. Nothing applies automatically.

The launcher uses `RemoteSigned` only for its PowerShell process; it does not change the machine execution policy. Downloaded scripts may be blocked until you review them and use Properties → Unblock on the downloaded ZIP before extracting. Organisation policy may still prohibit scripts; this tool does not override it.

Read-only preview, also available on other Windows builds:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\Sometime.ps1 -Preview
```

## Features

- Individually select visible file extensions, transparency, taskbar animations, classic menu delay, pointer acceleration and dark app theme.
- Every option displays its tradeoff before confirmation. Some registry preferences may be ignored or reset by Windows updates.
- Built-in Settings shortcuts for startup apps, Game Mode, graphics, captures, storage, power, updates and installed apps. Changes made there are manual and outside this tool's undo.
- Existing registry values and types are saved **before** writes; each write is read back. A failed apply attempts rollback and reports incomplete recovery.
- One active selection at a time prevents overwriting your original backup. Undo before choosing a different set.
- The preference tweaks do not download tools, change services/security/drivers, remove apps/files, restart Windows or elevate. The optional third-party activation tool has a separate scope described below.

## Optional activation launcher

Menu **6** displays a warning and requires the exact text **LAUNCH MAS** before running the requested `irm https://get.activated.win/ | iex` command in a separate PowerShell process. It opens the third-party MAS menu; this command alone is **not unattended activation**. No activation method is preselected and it never launches at optimiser startup or during preview/apply/undo. Menu **7** opens Windows' own Activation settings.

The remote launcher downloads additional code and requests administrator access. Its current content can change; the full tool has not been audited or run during development. Its activation/licensing and other system changes are **outside this optimiser's backup/undo**. Review the tool and use it only with appropriate licence rights. A successful launcher exit does not establish successful activation: check Windows Activation settings. This optional integration is the only runtime remote-code execution path.

## Undo and limits

Choose menu option 2 and type `UNDO`. Originals are stored in `%LOCALAPPDATA%\SometimeOptimizer\25H2\active.clixml`, bound to this computer and Windows user. Keep that folder. Undo restores exact saved values, including removing values that originally did not exist; harmless empty registry keys can remain. It replaces subsequent manual edits to those same values. Save work and sign out/in to refresh preferences.

If interrupted, reopen and use Undo before another apply. If undo reports an error, preserve the backup and retry after resolving the error. Backups are local settings snapshots, **not system restore points or full system backups**.

**This version cannot undo the old script.** That script deletes Windows files, tasks and app components without recoverable backups. If it has already run, see [the audit and recovery notes](AUDIT.md).

## Validation

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\Test-Core.ps1
```

Tests replace registry access with an in-memory implementation and create only ignored `.test-output` files. They cover backup/undo, interrupted and failed operations, version checks and malformed backups. They do not establish driver compatibility or performance gains. Actual Windows 11 25H2 apply/undo and Settings behavior still need checking in a disposable VM before distributing a release.

## Origin

The supplied file identifies itself as SOMETIME and credits Oneclick/QuakedK, CTT and Privacy is Freedom sections. The original is retained locally as `archive/original-main.bat.txt`, excluded from Git and uploads. No external tools or profiles are redistributed. No upstream license was supplied; the archive has not been relicensed.

Repository: https://github.com/ginobaby/sometime-optimizer

For the reported NVIDIA Hz/scaling reset, see [NVIDIA display recovery](NVIDIA-DISPLAY.md), also available in menu option 5. The old profile import has been removed; existing driver settings require separate recovery.


