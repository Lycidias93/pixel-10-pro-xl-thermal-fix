<!-- PIXEL_THERMAL_V1413_TEST4_PIXEL9_CREDITS_START -->
## Credits for Pixel 9 thermal mod inspiration

- **nokia5700black**: Pixel 9 Pro XL ThermalThrottling-mod inspiration from the user-provided XDA pre-March Pixel 9 Pro XL package/thread.
- **JohnTheFarm3r**: Pixel 9 Pro XL thermal throttling modifier inspiration from the user-provided XDA Pixel 9 Pro XL packages/threads.
- **Rana260492**: Pixel 9 Pro XL Android 15/16 post-March thermal throttling modifier inspiration from the user-provided XDA package/thread.
- Pixel 10 `outdoor-g4-adapted-plus` intentionally does **not** copy the Pixel 9 5-minute polling delay, USB, charge, battery, speaker, shutdown, or emergency changes. It only uses conservative threshold inspiration.

Reference threads provided by user:
- https://xdaforums.com/t/mod-thermal-throttling-modifier-pixel-9-pro-xl.4690006/
- https://xdaforums.com/t/mod-throttling-mod-for-march-15-16-android-9-pro-xl.4735878/
<!-- PIXEL_THERMAL_V1413_TEST4_PIXEL9_CREDITS_END -->

# Credits

## Pixel Thermal 1.4.12 ZRAM + log-cleanup release line

- **Harish / Codecity001**: Pixel 10 Pro (`blazer`) install/runtime testing, ZRAM debug logs, reboot verification, issue reports, install-time Volume-key ZRAM selection, Magisk Action UX recommendation, and PR #65 log cleanup/debug-gating for clean silent installs, and outdoor-g4-adapted thermal profile UX/testing direction.
- **JoshuaDoes**: ZRAM 100p technical input and context around the `mmd` restart path (`stop mmd && start mmd`), early service timing after Magisk mounts the vendor overlay, and the `resetprop` / `sys.boot_completed` timing nuance for possible future in-memory property handling.

These credits apply to the optional ZRAM 100p release line from the `v1.4.12-universal-test.*` builds through stable `1.4.12-universal.1`.

Notes:

- ZRAM remains optional and gated by explicit user choice.
- Stable update channel now points to `1.4.12-universal.1`.
- The existing module author attribution remains in `module.prop`.
- **Harish / Codecity001**: PR70 ZRAM resetprop-rs boot_early rework, script cleanup, debug-gating feedback, and Pixel test iteration.
- **JoshuaDoes**: resetprop -n, boot timing, mmd restart, and root-detection-safe in-memory property guidance.
- **Allen Chang**: QPR1/CP31 boot verification and missing outdoor profile report for mustang-android17-cp31.
