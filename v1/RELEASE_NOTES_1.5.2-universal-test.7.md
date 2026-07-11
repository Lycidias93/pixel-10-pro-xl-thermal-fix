# 1.5.2-universal-test.7

Pre-release diagnostic build.

## Canary/ZP diagnostic mode

- Detects Canary/ZP builds from build ID or fingerprint.
- Installs diagnostic-only on Canary/ZP.
- Does not materialize thermal overlay on Canary/ZP.
- Does not materialize ZRAM fstab on Canary/ZP.
- Forces stock polling and stock thermal mode on Canary/ZP.
- Generates /sdcard/Download/pixel_thermal_canary_diagnostic_*.tgz at install time.
- Normal non-Canary builds keep the existing test.6 behavior.

## Why

Some Canary/ZP users report bootloops before Action debug is reachable. This build is meant to collect evidence and isolate whether the trigger is thermal overlay, ZRAM fstab, KernelSU overlay handling, or another early-boot path.
