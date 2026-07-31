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

## Pixel Thermal V2 Alpha 3 development line

- **Allen Chang**: July Canary screenshot, installation/failure evidence and stock Thermal files showing the unsupported-build guard disabling Thermal while ZRAM stayed active and later exposing the Canary Outdoor-profile boot failure. This evidence drove the correction that treats exact build IDs as evidence rather than the Dynamic V2 activation gate and supported the exact-target Thermal safety work.
- **Harish / Codecity001**:
  - real-world Pixel 10 Pro / Blazer logging, installation, reboot and runtime testing, including the post-release Blazer / Android 17 stable community PASS;
  - commit `b9ff85db` limiting Dynamic V2 patching to the three critical base, charge and throttling configurations;
  - post-Alpha-2 package/performance review covering slow extraction, slow Action startup, repository-only flashable-ZIP content and leaner validator organization without weakening independent checks;
  - Action-dashboard optimization design: cached status, shallow backend probing, one combined supported-build probe, removal of obsolete/duplicate paths and suppression of unnecessary status re-renders after submenu return;
  - analysis of Allen's Canary stock Thermal files that identified prefix-target overreach, the fixed emergency-threshold entry and loss of decimal formatting;
  - PR #70 ZRAM application rework with `resetprop-rs`, `boot_early` service timing, script cleanup, debug-gating feedback and Pixel test iteration;
  - later integration, testing and menu/Action UX work around the pTune/Joshua-derived ZRAM and Emerald Hill path in `v2-perf` and Dev.12;
  - profile-layout refactor concept and mockup reference used by the manager/menu work.
  - Dev.20 LMKD live-reload validation: moving the 1-percent property into the ZRAM apply path, reloading LMKD after the write for boot and Action use, and consolidating the feature into fewer runtime scripts.
- **JoshuaDoes / pTune**: original source and inspiration for the Emerald Hill devfreq control adopted by this module, including adaptive operation and the optional maximum-frequency minimum lock. JoshuaDoes also provided ZRAM 100-percent technical input covering the `mmd` restart path (`stop mmd && start mmd`), early timing after Magisk mounts the vendor overlay, in-memory `resetprop -n`, `sys.boot_completed` timing and root-detection-safe property handling. These pTune/Joshua concepts formed the ZRAM and Emerald Hill foundation later safety-adapted through Dev.17.
- **Lycidias93**: Mustang CP2A.260705.006 installation, reboot, active-vendor, PollingDelay, Magisk, Bootguard, ZRAM, Emerald Hill and install-state runtime verification, plus the fail-closed integration, regression coverage and release binding.

The final Alpha 3 implementation safety-adapts contributed concepts and evidence with independent local validation, Bootguard ordering, kernel-OPP bounds, baseline restore, adaptive fallback, physical Emerald Hill alias deduplication, stock LMK policy, install-state preservation and deterministic package verification.

<!-- PIXEL_THERMAL_V2_ALPHA1_CREDITS_20260715_START -->
## Pixel Thermal V2 alpha line

- **Harish / Codecity001**: real-world Pixel 10 Pro logging, commit b9ff85db limiting V2 dynamic patching to the three critical base, charge and throttling configurations, and post-release Blazer / Android 17 stable community runtime PASS confirmation.
- **Lycidias93**: Mustang CP2A.260705.006 dirty-install, reboot, active-vendor, PollingDelay, Magisk and Bootguard runtime verification.
<!-- PIXEL_THERMAL_V2_ALPHA1_CREDITS_20260715_END -->


## Pixel Thermal 1.5.1 dynamic manager status release line

- **Allen Chang**: Ampel/Action menu idea, Beta 1/QPR1 testing, runtime verification, screenshots, debug logs, and Pixel 10 build-family feedback.

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
- Harish / Codecity001: profile layout refactor concept and mockup reference for Test29.
