# Credits

## Pixel Thermal 1.4.12 ZRAM + log-cleanup release line

- **Harish / Codecity001**: Pixel 10 Pro (`blazer`) install/runtime testing, ZRAM debug logs, reboot verification, issue reports, install-time Volume-key ZRAM selection, Magisk Action UX recommendation, and PR #65 log cleanup/debug-gating for clean silent installs, and outdoor-g4-adapted thermal profile UX/testing direction.
- **JoshuaDoes**: ZRAM 100p technical input and context around the `mmd` restart path (`stop mmd && start mmd`), early service timing after Magisk mounts the vendor overlay, and the `resetprop` / `sys.boot_completed` timing nuance for possible future in-memory property handling.

These credits apply to the optional ZRAM 100p release line from the `v1.4.12-universal-test.*` builds through stable `1.4.12-universal.1`.

Notes:

- ZRAM remains optional and gated by explicit user choice.
- Stable update channel now points to `1.4.12-universal.1`.
- The existing module author attribution remains in `module.prop`.
