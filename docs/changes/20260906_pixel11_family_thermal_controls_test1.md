# Pixel 11 family Thermal controls — Test 1

Date: 2026-09-06

Status: exploratory hardware-test candidate; not integrated into `vnext-2.1.0-alpha.5` until exact-head `grizzly` runtime evidence passes.

## Architecture

Install-option and Thermal patch dispatch now resolve a high-level device family:

- `pixel10`: Pixel 10-family plus the existing G4/10a compatibility line; current menu and classic patch behavior remain intact.
- `pixel11`: `cubs`, `grizzly`, `kodiak`, `yogi`; receives a dedicated option set and Tensor G6 patch path.

This prevents Pixel 11-specific Thermal schema changes from widening or destabilizing the established Pixel 9/10 logic and leaves room for a future independent Pixel 12 family.

## Pixel 11 option set

- Recovery Mode: Stock / HotHysteresis / MaxReleaseStep / Combined. Legacy `mod` normalizes to `combined`; hardware acceptance must test the two recovery components separately before Combined.
- Thermal Profile: Stock / Outdoor Safe only under the existing +1 C runtime cap; Test-1 default Stock.
- ZRAM 100% + Emerald Hill modes remain available; Test-1 default disabled to isolate Thermal recovery.
- ZRAM page-cluster is a separate persisted ZRAM sub-choice: Stock or guarded EXPERIMENTAL 0. Install-time selection records desired state only; runtime 0 remains post-Bootguard/reconcile gated.
- Debug Logging and Support Snapshot remain available.
- Classic `PollingDelay 300000 -> 5000`, PassiveDelay tuning, LMKD 1% and pTune override are excluded/pinned safe on Pixel 11.

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

## PassiveDelay decision

The Pixel 11 PassiveDelay experiment is removed. Harish's real-device test found that reducing `PassiveDelay 7000 -> 5000` could severely throttle the prime core and cut single-core performance by roughly 50%. With the recovery changes retained and PassiveDelay left at stock, he reported about 2.3k single-core / 7k multi-core in Geekbench 7.

The uploaded install/support evidence for the problematic run confirms the module had actually materialized recovery `mod` plus `PassiveDelay=5000`: 15 HotHysteresis changes, 32 MaxReleaseStep changes and 7 PassiveDelay changes, while classic PollingDelay stayed 35/35 at 300000 and 0 at 5000. Bootguard and readiness still passed, so the performance regression is not treated as an installation-validation failure.

Evidence supplied 2026-09-06:
- KernelSU install log: SHA-256 `9817c1f4f1803f89fe14020f6f21afdb8b05a0a3a8f53942eaa3deb2d01cceea`, 8634 bytes.
- Packaged debug archive: SHA-256 `3f9efe4c5b07c0f7f83c60c3ee7b396fcd773bcbe7de8c77ce3eb19077b0fcbe`, 362026 bytes.
- Device/build: Pixel 11 Pro / `grizzly`, Android 17 `CD1A.260714.001.A9`.
- Runtime evidence: Bootguard `full_pass`, readiness `runtime_verified`, active vendor match yes, disable/skip_mount/remove flags absent.

Therefore the installer, Action dashboard, WebUI capability surface and thermal patch API no longer expose or apply a Pixel 11 PassiveDelay mode. Existing stale PassiveDelay config keys are removed during the new Pixel 11 selection/control flow.

## Pixel 11 Thermal threshold policy

Pixel 11 re-admits only `Outdoor Safe +1 C`. The patch and verifier bind this to the exact master sensor named `VIRTUAL-SKIN`; `Outdoor Plus` and `Outdoor Extended` remain blocked.

Harish asked for a local threshold check because he suspected the control might be touching a Bluetooth object instead of the intended virtual-skin path. The accepted `grizzly` support package shows the real G6 layout places master `VIRTUAL-SKIN` in `thermal_info_config_common.json`, not in the root include file. A local replay of the current exact targeting rule against that real stock-shaped file changed only:

- `VIRTUAL-SKIN`: `[NAN,39,43,45,46.5,52,65]` -> `[NAN,40,44,46,47.5,53,66]`.

The following remained unchanged: `VIRTUAL-SKIN-HINT`, CPU-LIGHT/MID/ODPM/HIGH, `VIRTUAL-SKIN-SOC`, WLAN/BT/MMW virtual sensors, modem, charge, speaker and protection/OVER-35C objects. The repository regression fixture now mirrors this object placement and fails if any of these non-target controls change.

## Family UI and manager markers

Install options, the legacy Action dashboard and the standalone WebUI use the same device-family contract.

Pixel 11 exposes Recovery, Thermal Stock/+1, ZRAM, page-cluster, logging/support and guarded Emerald Hill options. Classic polling, LMKD and pTune remain outside the Pixel 11 family surface. Pixel 10-family behavior remains on the existing menu/action path.

The standalone WebUI remains pinned to shared core `0.6.1` / template commit `e7aa23ebb36be9b9075c66693d045a19413af8b1`. Family semantics are module-specific and stay in the adapter/runtime status. The capabilities payload intentionally does not add a top-level `device_family` field, because the pinned generic core rejects unknown capability fields. No generic shared-template primitive is required for this module-specific family dispatch.

The manager-card description is already generated dynamically by `tools/debug/status-lib.sh`: Pixel 11 shows Recovery / Thermal / ZRAM markers, while the Pixel 10-family keeps Polling / Thermal / ZRAM / Memory Killer. Regression coverage now binds both marker forms.

## Fail-closed validation

The G6 helper rejects the patch if the target inventory or stock values do not match the expected seven hysteresis arrays and 32 MaxReleaseStep cooling-device/profile bindings distributed across all five target sensors. Multiple `MaxReleaseStep` keys on the same physical JSON line are iterated independently, so validation is bound to the schema objects rather than file pretty-printing. PassiveDelay is not an admitted transformation.

The vNext byte-diff normalizer admits only the family-local recovery fields in `thermal_info_config_common.json`; classic `PollingDelay` and `PassiveDelay` remain untouched. The generated validation state records the Pixel 11 recovery mode only.

## Test build

The module keeps the branch/public package identity at:

- version: `2.1.0-alpha.5`
- versionCode: `1016255`
- test identity: `module.prop` description plus Actions artifact name `pixel-thermal-g6-recovery-test1-<head-sha>`
- release/update publication: unchanged; this is an Actions artifact only.

The vNext CI builds the standard Alpha5-named inner module ZIP inside the distinctly named test-only Actions artifact after all existing vNext regression gates plus `tests/test-pixel11-family-controls.sh`.

## Hardware acceptance gate

Harish / Codecity001 should test the exact Actions artifact on the accepted Pixel 11 Pro / `grizzly` line.

Four-mode acceptance sequence:

1. **Stock** — Thermal Stock, ZRAM disabled/page-cluster Stock; capture the baseline install/reboot, Bootguard/readiness, active overlay and benchmark.
2. **HotHysteresis** — only HotHysteresis recovery active; verify exactly 15 admitted hysteresis slots change and all 32 MaxReleaseStep bindings remain `1`; capture benchmark/recovery observations.
3. **MaxReleaseStep** — only MaxReleaseStep recovery active; verify all seven hysteresis arrays remain stock and exactly 32 admitted bindings change `1 -> 2`; capture benchmark/recovery observations.
4. **Combined** — both recovery changes active; verify exactly 15 + 32 admitted changes and compare against Stock plus both isolated modes.
5. **Thermal threshold round-trip** — from the accepted recovery mode, switch Stock -> Outdoor Safe +1 C -> Stock through Action/WebUI and prove only exact master `VIRTUAL-SKIN` changes.

For all four recovery modes, classic PollingDelay and PassiveDelay must remain Stock. Keep ZRAM disabled for the recovery benchmarks, so page-cluster remains Stock. The standalone WebUI must launch without capability-schema failure, and Action/WebUI/manager surfaces must report the same canonical Recovery mode.

Required evidence before integration: exact candidate identity/hash; exact-head `grizzly` install + reboot; module/Bootguard/readiness validity; active G6 overlay; exact per-mode recovery-field inventory; classic PollingDelay and PassiveDelay unchanged; benchmark/recovery observations for Stock, HotHysteresis, MaxReleaseStep and Combined; standalone WebUI plus family-specific Action/WebUI/manager surfaces verified; Pixel 11 Stock/+1 threshold round-trip proven on exact `VIRTUAL-SKIN`; and no safety/protection regressions.

Harish's real-stock-schema review corrected the original synthetic fixture: on the accepted G6 layout, MaxReleaseStep is nested under BindedCdevInfo/Profile bindings rather than being one top-level sensor property. The five target sensors contain 32 admitted bindings in total (6/6/9/6/5), while VIRTUAL-SKIN-SOC-EXTREME has five separate bindings that remain stock. The corrected unit fixture mirrors that nesting and the fail-closed inventory now requires all 32 target bindings.

The claimed ~2x tier/frequency recovery remains a hypothesis until exact-head device benchmark evidence exists.
