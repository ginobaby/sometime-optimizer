# Review of the supplied optimiser

Reviewed 2026-09-07. Line numbers refer to the locally archived original, SHA256 `97247B1899CA0B818A2EAEC6EAA4EB5F3C70156CB519AAD74A93354BD8F970BE`.

The old program performs most changes sequentially before offering its extras menu. Adding warnings to a handful of prompts would leave those automatic changes active. The executable was replaced with a small explicit allowlist; all old commands are removed from the execution path.

| Original area | Finding and decision |
| --- | --- |
| 8–77: elevation, tool ZIP, Defender | Automatically elevates, downloads a mutable GitHub ZIP without hash/signature checks, recommends disabling real-time/tamper protection and launches dControl. Removed. |
| 143–157: restore point | Suppresses errors and prints success without verifying a restore point. Replaced with checked per-setting backups for the new limited scope. |
| 199–376: desktop/privacy/gaming | Forces location, notifications, accessibility, input, capture, fullscreen behavior, HAGS, hibernation and UAC choices. Keep only small optional user preferences. Move hardware/capture decisions to Windows Settings with warnings. |
| 385–666: service baseline | Hundreds of hard-coded service defaults, including obsolete names and per-user suffixes from another PC. Removed; service defaults depend on edition, features and device. |
| 674–800: telemetry and tuning | Disables diagnostics/compatibility tasks, changes scheduler/svchost configuration, denies SYSTEM access to diagnostics, imports external O&O configuration, prints fake success. Removed. |
| 850–1144: services/tasks | Disables update/Store, networking, printing, Bluetooth, time sync, licensing, recovery, TPM and maintenance components. Can break updates, sign-in, peripherals, network detection and recovery. Removed. |
| 1200–1436: debloat | Disables Hello, backup/encryption helpers, virtualization and browser updaters; removes tasks and Gaming Services; runs external scripts as TrustedInstaller. Can break WSL/VMs, Game Pass, authentication and device features. Removed. |
| 1440–1610: Windows file deletion | Takes ownership/deletes Edge/WebView, Update Orchestrator, SmartScreen, widgets and lock screen components. Unrecoverable by registry undo; removed. |
| 1656–1785: app priorities/Copilot | Hard-coded game paths, low priorities for core Windows/security processes, blanket Copilot removal/provisioning changes. Removed; app choices go through Settings. |
| 1963–2193: GPU | Hard-coded video GUIDs and adapter indices; interrupt/power/thermal/preemption changes and external NVIDIA profile imports. Hardware-specific; can cause instability, heat, display or recording problems. Removed. |
| 2222–2536: timers/priority | BCD timer flags, scheduler values, runtime installer and persistent timer tools. No general 25H2 benefit established; removed. |
| 2542–2804: devices/network/power | Driver-specific NIC values, disabling devices/Wi-Fi, imported power plans and fixes. Can disconnect network/peripherals or change sleep/battery behavior. Removed. |
| 2834–2929: cleanup | Forces theme, kills/restarts Explorer, deletes temporary/app/update/diagnostic files and offers defrag. Removed automatic cleanup; Windows Storage Settings lets the user review deletions. |
| 2998–3355: extras | WMIC adapter resets, broad network resets, unverified installers, referral browser download and DNS changes chosen from arbitrary active adapters. Removed. |
| 3359–3378: exit | Disables TrustedInstaller then immediately reboots. Can prevent servicing and lose unsaved work. Removed. |

## 25H2 evidence

- [Microsoft release information](https://learn.microsoft.com/en-us/windows/release-health/windows11-release-information): 25H2 uses build 26200. Future/client-preview and server builds are rejected for writes.
- [25H2 changes](https://learn.microsoft.com/en-us/windows/whats-new/whats-new-windows-11-version-25h2): WMIC and PowerShell 2.0 removal. The replacement uses PowerShell 5.1 and `Get-CimInstance`.
- [BCDEdit documentation](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set): boot changes can make a system inoperable; platform clock/tick options include debugging-only settings. No boot edits remain.
- [Windows performance guidance](https://support.microsoft.com/en-us/windows/experience/performance-optimization/tips-to-improve-pc-performance-in-windows): focus on updates, startup load, storage, effects and power tradeoffs, rather than blanket service removal.
- [Settings URI reference](https://learn.microsoft.com/en-us/windows/apps/develop/launch/launch-settings): built-in destinations used by the maintenance menu; availability can depend on hardware.

## If the old script already ran

The new tool deliberately does not guess old values or claim to repair old damage. Preserve personal files and any restore point/system image from before the old run. Use Windows recovery/System Restore if available. If components were deleted, a Windows repair reinstall or recovery from a known-good backup may be needed. Check Windows Security and Windows Update afterward. Do not run the old script again or reuse its external profiles as a repair.

## GitHub dependencies

The original references QuakedK/Oneclick tools and GPU profiles, QuakedK/Downloads dControl, Orbmu2k/nvidiaProfileInspector and LordOfMice/hidusbf, among other vendor installers. No external tools were downloaded or executed. The linked NVIDIA profile was read as text to investigate the reported display bug; see [NVIDIA display recovery](NVIDIA-DISPLAY.md). The ZIP contents were not supplied or inspected, so no claims are made about their safety or licenses. The preference tweaks need only repository files. A subsequent user-requested optional MAS launcher is a separate, explicitly warned remote-code path; see the README. Its payload is not covered by this audit or undo.

