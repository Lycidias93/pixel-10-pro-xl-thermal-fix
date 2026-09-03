# Pixel 11 tester feedback — 2026-09-03

Status: exploratory vNext follow-up. This document records tester-reported behavior, bounded remediation and the exact feedback-candidate package audit; it is not runtime acceptance evidence.

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

## Package-size audit

Exploratory PR #193 head `a82cebaf23dd0d3ec7bf48ec0cb0157cd9f1441b` passed vNext CI run `33711256537` and produced an 83-entry candidate:

- candidate SHA-256: `ce0b6639960d0a08bd61ef47f4c94c542881377d4b86d8623df92c7276bd9427`
- candidate bytes: `2711747`
- previous PR #192 candidate bytes: `2709422`
- feedback-candidate delta: `+2325` bytes
- `bin/webui-server-arm64`: 5,964,097 bytes uncompressed / 2,314,358 bytes compressed, about 85.7% of compressed file payload
- `tools/resetprop-rs`: 457,240 bytes uncompressed / 229,515 bytes compressed, about 8.5% of compressed file payload
- those two required runtime binaries together account for about 94.2% of compressed file payload
- the removed duplicate `system/vendor/etc/fstab.zram.100p` was only 74 bytes uncompressed / 67 bytes compressed

Therefore the duplicate was real package hygiene debt but was not the source of the multi-megabyte size. The current size is dominated by the native standalone WebUI server, with the cross-root-manager `resetprop-rs` fallback a distant second. Returning to an early ~256 KB patcher-only size would require an architectural feature trade-off or replacement of those runtime components, not simple duplicate cleanup. No such regression in WebUI/root-manager support is made in this feedback fix.

## Heat-isolation rule

The reported battery-temperature difference is valid tester evidence, but it does not isolate a cause. The previous Pixel 11 candidate preserved stock Thermal polling while optional ZRAM/LMKD/debug settings could also be active. Therefore no Thermal, ZRAM, logging, WebUI or mount component is assigned as root cause without an A/B run.

Exact-head retest order:

1. Thermal polling Stock; Thermal profile Stock.
2. ZRAM disabled; LMKD Stock; Emerald Hill Adaptive; page-cluster Stock.
3. Debug logging Silent.
4. Reboot, reach verified runtime, then measure an idle/battery baseline under the same charging, ambient, screen and radio conditions.
5. Enable one optional feature at a time, reboot when required, and repeat the same observation window.
6. If a temperature delta reproduces, capture a Support Snapshot before changing the next variable.

This isolation sequence is required before treating the reported temperature behavior as a regression in a specific subsystem.
