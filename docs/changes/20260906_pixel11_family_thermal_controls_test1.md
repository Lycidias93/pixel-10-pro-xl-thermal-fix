# Pixel 11 family Thermal controls — Test 1

Date: 2026-09-06

Status: exploratory hardware-test candidate; not integrated into `vnext-2.1.0-alpha.5` until exact-head `grizzly` runtime evidence passes.

## Architecture

Install-option and Thermal patch dispatch now resolve a high-level device family:

- `pixel10`: Pixel 10-family plus the existing G4/10a compatibility line; current menu and classic patch behavior remain intact.
- `pixel11`: `cubs`, `grizzly`, `kodiak`, `yogi`; receives a dedicated option set and Tensor G6 patch path.

This prevents Pixel 11-specific Thermal schema changes from widening or destabilizing the established Pixel 9/10 logic and leaves room for a future independent Pixel 12 family.

## Pixel 11 option set

- HotHysteresis & MaxReleaseStep: `mod|stock`; Test-1 default `mod`.
- Passive Polling: `mod|stock`; Test-1 default `stock` (`PassiveDelay=7000`).
- Thermal Profile: Stock / Outdoor Safe only under the existing +1 C runtime cap; Test-1 default Stock.
- ZRAM 100% + Emerald Hill modes remain available; Test-1 default disabled to isolate Thermal recovery.
- Debug Logging and Support Snapshot remain available.
- Classic `PollingDelay 300000 -> 5000`, LMKD 1% and pTune override are excluded/pinned safe on Pixel 11.

Remembered settings are family-local so Pixel 10 choices do not silently become Pixel 11 choices.

## Test-1 G6 recovery patch

Only `thermal_info_config_common.json` is eligible for the new recovery controls.

Target sensors:

- `VIRTUAL-SKIN`
- `VIRTUAL-SKIN-HINT`
- `VIRTUAL-SKIN-CPU-LIGHT-ODPM`
- `VIRTUAL-SKIN-CPU-MID`
- `VIRTUAL-SKIN-CPU-ODPM`
- `VIRTUAL-SKIN-CPU-HIGH`
- `VIRTUAL-SKIN-SOC`

HotHysteresis is slot-bound and fail-closed against the stock arrays supplied for G6 testing. The transformation changes exactly 15 admitted numeric slots while leaving EMERG/SHUTDOWN values untouched.

MaxReleaseStep changes exactly 32 cooling-device and profile bindings from `1 -> 2` across five target sensors: the four CPU targets plus `VIRTUAL-SKIN-SOC`.

`VIRTUAL-SKIN` and `VIRTUAL-SKIN-HINT` do not gain a MaxReleaseStep. `VIRTUAL-SKIN-SOC-EXTREME` remains stock at `1`.

## Phase-2 PassiveDelay path

The same family patcher contains a separate, independently selectable `PassiveDelay 7000 -> 5000` mode for the same seven target sensors. It changes exactly seven values and leaves modem/RF, shutdown, cellular-emergency, charging and `VIRTUAL-SKIN-SOC-EXTREME` stock.

This path is intentionally not the Test-1 default and is not eligible for target-branch integration until Test-1 recovery evidence is reviewed.

## Fail-closed validation

The G6 helper rejects the patch if the target inventory or stock values do not match the expected seven hysteresis arrays, 32 MaxReleaseStep cooling-device/profile bindings distributed across all five target sensors, and seven PassiveDelay targets.

The vNext byte-diff normalizer admits only the family-local controlled fields in `thermal_info_config_common.json`; classic `PollingDelay` remains stock. The generated validation state records the Pixel 11 recovery/passive modes.

## Test build

The module keeps the branch/public package identity at:

- version: `2.1.0-alpha.5`
- versionCode: `1016255`
- test identity: `module.prop` description plus Actions artifact name `pixel-thermal-g6-recovery-test1-<head-sha>`
- release/update publication: unchanged; this is an Actions artifact only.

The vNext CI builds the standard Alpha5-named inner module ZIP inside the distinctly named test-only Actions artifact after all existing vNext regression gates plus `tests/test-pixel11-family-controls.sh`.

## Hardware acceptance gate

Harish / Codecity001 should test the exact Actions artifact on the accepted Pixel 11 Pro / `grizzly` line.

Test 1 selections:

- HotHysteresis & MaxReleaseStep: Mod
- Passive Polling: Stock 7s
- Thermal Profile: Stock
- ZRAM: Disabled
- classic PollingDelay: pinned Stock

Required evidence before integration or phase 2: exact candidate identity/hash, install + reboot, module/Bootguard/readiness validity, active G6 overlay, classic PollingDelay unchanged, selected recovery fields exact, benchmark/recovery observations and no safety/protection regressions.

Harish's real-stock-schema review corrected the original synthetic fixture: on the accepted G6 layout, MaxReleaseStep is nested under BindedCdevInfo/Profile bindings rather than being one top-level sensor property. The five target sensors contain 32 admitted bindings in total (6/6/9/6/5), while VIRTUAL-SKIN-SOC-EXTREME has five separate bindings that remain stock. The corrected unit fixture mirrors that nesting and the fail-closed inventory now requires all 32 target bindings.

The claimed ~2x tier/frequency recovery remains a hypothesis until exact-head device benchmark evidence exists.
