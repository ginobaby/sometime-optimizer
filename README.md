# SOMETIME - Windows 11 25H2

This edition returns to the supplied **main 1.bat**: the original SOMETIME banner, sequential screens, appearance/privacy/input tweaks and broader cleanup flow. It does not use the earlier six-preference menu.

## Run

1. Choose **Code > Download ZIP** on GitHub and extract all files together.
2. Double-click **main 1.bat** and accept the administrator prompt for your own Windows account.
3. Read the warning screen. After 10 seconds the run starts automatically; Ctrl+C cancels before it starts. There is no numbered menu or per-tweak selection.

Keep `Sometime.ps1`, `Activation.ps1` and `Apps.txt` next to the batch file. `Sometime.ps1` provides checked helper stages; the main batch contains the original preference commands. Downloaded scripts may require Properties > Unblock on the ZIP before extraction after review. The launcher uses a process-scoped RemoteSigned policy and does not override organisation policy.

## Included

- 68 native registry commands based on the original: activity history, location, notifications, Sticky Keys shortcut behavior, Num Lock, classic context menu, file extensions/hidden files, widgets/taskbar, animation/performance appearance, Game DVR, Game Mode, transparency, mouse acceleration, hibernation, privacy/suggestions and dark theme.
- **Windows Update service disabling and Defender real-time protection disabling retained at the owner's request.** This reduces malware protection and security updates. Protected services or tamper protection may block these changes, and Windows may later restore them. The tool reports partial failure rather than claiming permanent disablement.
- Selected background services: diagnostic telemetry, offline maps, retail demo, remote registry and fax. Dependent features stop working.
- 44 app-name patterns from the original removal list, applied to the current user. Read/edit **Apps.txt** before running if you use those apps. Store, codecs, core sign-in and driver-control packages are excluded. App removal can lose app data/features and reinstallation may need Store access/licensing.
- Microsoft Visual C++ x64 runtime installation if absent, using Microsoft's endpoint and a valid Microsoft Authenticode signature before execution.
- Built-in High performance power plan only if already available and AC power is detected. Hibernation/Fast Startup are disabled by the original preferences. Higher power usage, heat and fan noise are possible.
- Temp files older than seven days and DNS cache cleanup. Reparse points are skipped; system folders, update stores, logs and Prefetch are not deleted.

No FPS gain is guaranteed. Windows edition, policy and cumulative updates can affect whether individual preferences work. This is targeted at Windows 11 25H2 client build 26200; other builds are blocked.

## Display and destructive changes removed

The NVIDIA profile import is removed along with hard-coded GPU registry/interrupt changes. The run does not force resolution, refresh rate, scaling, HAGS or driver profiles. Read [NVIDIA-DISPLAY.md](NVIDIA-DISPLAY.md) if an earlier import already affected your display.

System-component deletion, ownership/security-descriptor bypasses, blanket essential-service disabling, core-process priority changes, boot timer tweaks, obsolete WMIC resets and forced restart are removed. Existing damage from the original script is not automatically repaired.

## Screens, errors and recovery

Screens clear between sections. Cyan/magenta identify stages, yellow highlights risks or partial failure, green marks checked success, and red marks errors. This clears the visible console only, not shell history or logs. Registry command output and helper transcripts are saved locally; the final screen shows the log and backup paths and flags failed steps.

Before tweaks, the program saves registry exports, a manifest of absent keys, selected service states, Defender's previous preference and the active power-plan ID under `%LOCALAPPDATA%\SometimeOptimizer\OriginalFlow\<run-id>`. These local files are never uploaded. It enables System Protection and creates a restore point, or explicitly reports reuse of a point from the previous 24 hours. If backup/restore-point preparation fails, it stops before the tweak sequence.

**Undo Sometime.bat opens Windows System Restore. It is not an exact automatic undo of this broader edition.** Restore points may predate other changes and do not back up personal/app data. Registry exports are reference snapshots: importing them can overwrite later changes and does not automatically remove newly created values. Deleted temp files, removed apps and third-party activation are not covered by those snapshots. Keep a separate backup of important data.

No automatic restart occurs. Save work and restart at a convenient time. Check Windows Security and Windows Update afterward, especially if a disable step was blocked.

## Optional activation

**Activate Sometime.bat** opens a separate warned launcher and requires **LAUNCH MAS** before executing the requested `irm https://get.activated.win/ | iex` command. It opens the MAS menu, not unattended activation. It does not run as part of optimisation.

The third-party script downloads additional code and requests administrator access; its content can change. Its full payload was not audited or executed during development. Activation/licensing and other changes are outside the backup scope. Use only with appropriate licence rights and check activation in Windows Settings afterward.

## Validation

Read-only preview:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\Sometime.ps1 -Preview
```

Isolated tests:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\Test-Core.ps1
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\Test-Batch.ps1
```

The tests parse scripts and use mocked service, Defender, restore-point, app removal, runtime installer and activation commands. The batch harness replaces system commands and checks success, validation failure, backup failure, security failure and registry failure paths, including exit codes and warning files. They never apply actual tweaks. Live 25H2 apply/recovery and hardware testing remain outstanding; passing these tests is not a stability or performance guarantee. `Core.ps1` is a retired file from the earlier edition and is not used.

The original user-supplied file credits SOMETIME, Oneclick/QuakedK, CTT and Privacy is Freedom. A local archive is excluded from publication. No external profile/tool ZIP is redistributed. See [AUDIT.md](AUDIT.md) for the original review and scope changes.

