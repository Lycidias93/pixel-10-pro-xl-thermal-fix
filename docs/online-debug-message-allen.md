# Allen Chang online debug handoff

Use after the online collector has been merged to `v2`.

> Thanks, that is enough to narrow it down: `mustang`, July Canary `ZP11.260618.005`; Stock Thermal boots, while every non-stock profile reaches the end of the boot animation and then goes black.
>
> You do not need to type anything while the screen is black. After reproducing it, recover to a successful Stock boot without deleting `/data/adb/pixel-10-pro-xl-thermal-fix`, then run the current online collector once from Termux.
>
> Tell me two things before running it:
>
> 1. Which profile failed: `outdoor-safe`, `outdoor-plus`, or `outdoor-extended`?
> 2. Was the module installed cleanly or as an upgrade?
>
> The generated ZIP already contains the three requested stock Thermal files, preferably from the Magisk mirror, plus the exact original cache, module overlays, active Vendor files, hash comparisons, previous-boot logcat when available, pstore/ramoops, boot reason, display/Thermal state, Magisk state, and crash markers.
>
> Please send the ZIP and the approximate time the screen turned black. Until we understand it, stay on Stock Thermal; Polling and ZRAM can remain separate.
