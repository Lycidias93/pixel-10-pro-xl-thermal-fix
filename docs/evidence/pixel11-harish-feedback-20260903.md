# Pixel 11 tester feedback — 2026-09-03

Status: exploratory vNext follow-up. This document records tester-reported behavior and the bounded remediation/test plan; it is not runtime acceptance evidence.

## Reported by Harish / Codecity001

- The Pixel 11 Pro module mount is now working after the root/kernel mount setup was corrected.
- Thermal polling must not be blindly changed across all Pixel 11 Thermal files; exact useful targets remain under review.
- The candidate ZIP was reported as much larger than the early dynamic-patcher prototype and contained duplicate `fstab.zram.100p` content.
- Android's software keyboard could cover the WebUI confirmation field.
- ZRAM `page-cluster=0` returned to stock after reboot.
- The WebUI did not expose the existing Silent/Verbose debug-logging choice.
- Battery temperature appeared to stay near 36 C longer with the module installed than after module removal.

## Changes under test

- Pixel 11 continues to preserve every stock `PollingDelay`; 5-second polling remains blocked pending exact runtime evidence.
- `page-cluster=0` stores an explicit desired state and is reconciled only after Bootguard verification and active ZRAM are confirmed. Stock restore clears the persisted request.
- WebUI typed actions expose Silent and Verbose debug logging using the same `DEBUG_MODE`, `debug_mode`, and `LAST_DEBUG_MODE` settings as the installer menu.
- Shared WebUI Core pin advances to `e7aa23ebb36be9b9075c66693d045a19413af8b1`, which keeps focused inputs visible as the Android visual viewport changes.
- `tools/zram/fstab.zram.100p` is the sole packaged source template. `system/vendor/etc/fstab.zram.100p` is generated only by the install/pre-mount materializer when ZRAM is enabled and is no longer tracked in the source package.

## Heat-isolation rule

The reported battery-temperature difference is valid tester evidence, but it does not isolate a cause. The previous Pixel 11 candidate preserved stock Thermal polling while optional ZRAM/LMKD/debug settings could also be active. Therefore no Thermal, ZRAM, logging, or WebUI component is assigned as root cause without an A/B run.

Exact-head retest order:

1. Thermal polling Stock; Thermal profile Stock.
2. ZRAM disabled; LMKD Stock; Emerald Hill Adaptive; page-cluster Stock.
3. Debug logging Silent.
4. Reboot, reach verified runtime, then measure an idle/battery baseline under the same charging, ambient, screen and radio conditions.
5. Enable one optional feature at a time, reboot when required, and repeat the same observation window.
6. If a temperature delta reproduces, capture a Support Snapshot before changing the next variable.

This isolation sequence is required before treating the reported temperature behavior as a regression in a specific subsystem.
