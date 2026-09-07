# NVIDIA resolution, refresh-rate and scaling recovery

The old optimiser imports a global NVIDIA Profile Inspector profile and writes hard-coded GPU registry settings. The new version does neither. It never changes resolutions, refresh rates, scaling, G-SYNC/VRR, EDID, custom timings or NVIDIA driver profiles.

## What was found

The [linked upstream profile](https://raw.githubusercontent.com/QuakedK/Oneclick/refs/heads/main/Downloads/QuakedOptimizedNVProflie.nip), inspected on 2026-09-07, sets preferred refresh rate and multiple global G-SYNC/VRR flags, plus a machine-specific Preferred OpenGL GPU identifier. The old batch imports it into the driver at lines 2059–2085. These are inappropriate as universal optimisations. The profile is mutable, so the copy previously imported on your PC may differ.

The exact cause of the reported Hz/scaling reset has **not** been reproduced. The profile is a plausible contributor; driver state, application overrides, available display modes and custom timings can also matter. Removing the import prevents this optimiser reapplying it but does not revert existing driver state.

## Recover a PC where the old version already ran

Save work and close games first. Note your monitor's native resolution, supported refresh rate and current custom settings before resetting anything. Resets can remove your chosen game profiles; display changes may briefly blank the screen. Do not import the old profile again.

1. Open NVIDIA Control Panel → Manage 3D settings. Restore the global defaults and Apply; also restore the affected game's program settings if you customised/imported them. This resets 3D preferences, not necessarily custom display modes or every hidden Profile Inspector value. If you exported a known-good driver profile before using the old tool, retain it for recovery.
2. Under Display → Change resolution, select the correct monitor, a known-supported resolution and its supported refresh rate, then Apply. Resolution and Hz are a pair: switching resolutions can expose a different list of supported rates. Avoid forcing an unsupported rate or creating new custom timings to mask the issue.
3. Under Display → Adjust desktop size and position, select **Full-screen** if you want stretching, or **Aspect ratio** if you want proportions preserved with borders. These are scaling controls, separate from creating a custom resolution. If supported, try **Perform scaling on: GPU**, and enable **Override the scaling mode set by games and programs** if you want this choice to take precedence. Apply. Availability depends on your display connection and hardware.
4. Close/reopen the panel, change between two supported resolutions, and check the saved scaling choice and refresh rate on each. Then test the affected game and check again after a restart. Keep only configurations that remain stable. This is the manual acceptance test for the reported bug.
5. If the settings still reset, stop applying more tweaks. Record GPU model, driver version, monitor, cable/port, exact resolution/Hz pairs, and whether the reset happens immediately, after launching a game or after reboot. An official driver reinstall/reset may be needed if the old global/hidden settings persist; it should be a deliberate troubleshooting step, with awareness that custom profiles can be lost.

On a laptop whose internal display is driven by integrated graphics, NVIDIA may not expose these display controls. Use the display-owning GPU's controls/Windows Advanced display instead.

## Sources

- [NVIDIA scaling controls](https://www.nvidia.com/content/Control-Panel-Help/vLatest/en-us/mergedProjects/nvdsp/Adjust_Desktop_Size_and_Position_-_Windows_Vista_and_Later.htm)
- [NVIDIA Manage 3D Settings](https://www.nvidia.com/content/Control-Panel-Help/vLatest/en-us/mergedProjects/3D%20Settings/Manage_3D_Settings_%28reference%29.htm)
- [NVIDIA change resolution](https://nvidia.custhelp.com/app/answers/detail/a_id/97/~/how-do-i-change-my-display-resolution)
