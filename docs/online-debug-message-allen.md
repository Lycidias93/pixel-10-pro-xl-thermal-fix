# Online debug handoff

The original Allen-specific black-screen handoff is historical. The coordinated Fix-5 Thermal family logic was integrated into `2.0.0-alpha.3-dev.6`, and the current public prerelease has a broader collector for install, Action-switch, status, and boot failures.

Use `tools/debug/collect-thermal-prerelease-online.sh` and the instructions in `docs/prerelease-online-debug.md`.

Suggested public handoff:

> If the current Alpha 3 Dev 6 prerelease fails to install, shows red status, bootloops, hangs at the loading bar, or fails after changing profiles in Action, please stop further profile changes and recover to a working boot. Do not wipe the module data. Run the current online collector, review the generated README, and send the archive together with the approximate failure time and the profile transition you selected.

The older `collect-outdoor-boot-failure-online.sh` is retained only for reconstructing the original pre-Fix-5 Canary incident.
