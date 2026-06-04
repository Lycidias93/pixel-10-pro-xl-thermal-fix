## 1.4.4-universal-test.2 - prerelease test

- Add prerelease `1.4.4-universal-test.2`.
- Carry forward `1.4.3-universal.3` SELinux overlay-read hotfix.
- Keep stable `update.json` on `1.4.3-universal.3`.
- Enable guarded Android 17 CP21 test profiles for frankel, blazer, mustang and rango.
- Improve manual debug ZIP evidence: SELinux contexts, AVC denial summary, sepolicy copy, time context, and old-vs-fresh ThermalHAL tombstone marker.
- Credits: Jiggs, Harish, maicol07.

## 1.4.3-universal.3 - stable SELinux overlay-read hotfix

- Fixed ThermalHAL crash loop on setups where Magisk-mounted `/vendor/etc/thermal_info_config*.json` appears as `system_file`.
- Added read-only `sepolicy.rule` for `hal_thermal_default` to read/open/getattr/map Magisk overlay config files.
- No thermal profile values changed versus `v1.4.3-universal.2`.
- Stable updateJson now points to `1.4.3-universal.3`.

## 1.4.3-universal.2 - Universal boot guard hotfix


## 1.4.4-universal-test.1

Prerelease universal Android 17 CP21 test build.

### Added

- Guarded Android 17 CP21 runtime test profiles for Frankel, Blazer, Mustang and Rango.
- Runtime profiles generated from imported CP21 factory evidence.
- Install-state `verification_state` markers for PASS versus pending scopes.
- Documentation that stable `update.json` remains on v1.4.3-universal.2.

### Changed

- Android 17 CP21 guarded test install path is enabled in the universal prerelease ZIP.
- Android 17 Mustang CP31 verified path remains unchanged.
- Android 16 universal path remains unchanged.

### Verification state

PASS:

- Mustang Android 16 CP1A.260505.005
- Blazer Android 16 CP1A.260505.005
- Mustang Android 17 CP31.260508.005 / 15421345

Pending runtime verification:

- Frankel Android 16
- Rango Android 16
- Frankel Android 17 CP21.260330.011
- Blazer Android 17 CP21.260330.011
- Mustang Android 17 CP21.260330.011
- Rango Android 17 CP21.260330.011


- Fixed `post-fs-data.sh` boot guard so Android 16 `frankel`, `blazer`, and `rango` universal profiles are not disabled after install.
- Keeps thermal profile files unchanged from `1.4.3-universal.1`.
- Keeps Android 17 support restricted to `mustang` / `CP31.260508.005` / `15421345`.
- Updated stable `update.json` to `1.4.3-universal.2` / versionCode `1014305`.

## Unreleased

- Added named Android 17 Mustang tester credit for `Jiggs` in README/release documentation.
- Documented the online stock debug report path for unsupported Pixel 10 devices and newer firmware before installing the module.
- Documented vNext guard plan: unsupported installs may generate a pre-abort stock debug ZIP, but must still abort without enabling profiles or materializing overlays.

## 1.4.3-universal.1 - Stable universal release

- Promoted the Android 16 universal + Android 17 Mustang CP31 profile line to stable.
- Updated `update.json` to `1.4.3-universal.1` / versionCode `1014304`.
- Kept Android 17 strictly guarded to `mustang` / `CP31.260508.005` / `15421345`.
- Added scaffold-only Android 17 pending profile docs for `frankel`, `blazer` and `rango`; these are not enabled.
- Kept debug collection manual-only via `tools/collect-debug.sh`.

## Toggle debug helper - 2026-06-03

- Added public read-only `tools/pixel_thermal_toggle_debug.sh` for cases where Magisk keeps the module disabled.
- The helper records module flags, Magisk staging directories, AshLooper/AshReXcue status, thermal mountinfo and Magisk logs.
- No runtime thermal profile, release ZIP, module.prop or updateJson change.

## v1.4.2-universal-test.1

- Documented Mustang post-reboot PASS for `v1.4.2-universal-test.1`; stable `update.json` remains unchanged and additional devices remain beta/pending. - 2026-06-02

- Pre-release build for Android 16-only Pixel 10-series profile expansion.
- Adds `frankel`, `blazer`, and `rango` install-time beta/pending profile support.
- Keeps `mustang` as verified/stable.
- Blocks Android 17 pending separate factory evidence/profile files.
- Keeps `update.json` stable channel unchanged.

## Unreleased

- Strengthened install-time Android guard: Android 16 profiles now abort on non-Android-16 devices and document that Android 17 requires separate factory evidence/profile files.

- Added factory-based minimal polling source profiles for Pixel 10 Android 16 `CP1A.260505.005`: `frankel`, `blazer`, and `rango` now use factory thermal JSON plus only allowed VIRTUAL-SKIN polling-delay changes to `5000`. No release ZIP, module.prop bump, or update.json change in this step.

<!-- DEBUG_REPORT_PERMISSION_DENIED_FIX_20260602_START -->
## Debug report PermissionError fix - 2026-06-02

- Fixed the public thermal debug report tool so restricted `/data/adb/modules/...` access does not abort report generation.
- Narrowed the privacy sanitizer account pattern to avoid false positives on the report's own `accounts_collected=false` metadata and README wording.
- Runtime thermal profiles, release ZIPs, updateJson and stable channel are unchanged.

<!-- DEBUG_REPORT_PERMISSION_DENIED_FIX_20260602_END -->

<!-- DEBUG_REPORT_PERMISSION_FIX_20260602_START -->
## Debug report tool - permission handling

- Online `tools/pixel_thermal_debug_report.py` now tolerates `PermissionError` on `/data/adb/modules/...`.
- Module-state collection records `module_path_readable=false` and `module_path_error=permission_denied` instead of aborting.
- Thermal file, AshLooper and sanitizer reads now use guarded filesystem helpers.
- No runtime thermal profile, ZIP asset, release channel or `updateJson` change.

<!-- DEBUG_REPORT_PERMISSION_FIX_20260602_END -->

## v1.3-mustang.15

- Stable Mustang tooling/support release.
- Runtime thermal scope unchanged from `v1.3-mustang.14`.
- Debug report ZIP now defaults to `/storage/emulated/0/Download`.
- Added `--out-dir` support for custom debug report locations.
- Added debug report schema manifest, file hashes and stronger sanitizer metadata.
- README now explains daily-use expectations, public verify command, support matrix and compatibility report workflow.
- Added AshLooper GitHub credit and checksum release asset.

## v1.3-mustang.14

- Stable minor release with no runtime thermal scope change versus `v1.3-mustang.13`.
- Bundles `tools/pixel_thermal_debug_report.py` for sanitized compatibility reports from new Mustang firmwares or other Pixel 10-series devices.
- Adds a public README verify command without project-internal `cgprep`/`cgrun` tooling.
- Adds explicit AshLooper credit and GitHub link as the external bootloop protection used during testing.
- Keeps older `v1.3-mustang.*` releases as historical prerelease/bisect/test releases.

## Release archive note

- `v1.3-mustang.13` is the current stable Mustang release.
- Earlier `v1.3-mustang.*` releases are historical bisect/test builds and are kept for audit, rollback context and troubleshooting.
- Do not prefer older bisect builds for normal installation unless explicitly debugging a regression.


## Documentation cleanup - README intro and changelog placement

- Reworked README to start with a short explanation of why this Mustang fork exists.
- Added credits section.
- Removed per-version changelog-style sections from README.
- Kept release history in CHANGELOG.md.


## v1.3-mustang.13

- Stable cleanup release for Pixel 10 Pro XL / mustang.
- No runtime thermal scope change versus v1.3-mustang.12.
- Keeps all verified 300000ms -> 5000ms PollingDelay targets across throttling, base and charge configs.
- Fixes stale installer text that still said thermal_info_config_throttling.json only.
- Keeps VIRTUAL-SKIN entries with absent/null PollingDelay untouched.


## v1.3-mustang.12

- Adds both remaining true 300000ms charge thermal config candidates to the stable v1.3-mustang.11 baseline: thermal_info_config_charge.json VIRTUAL-SKIN-CHARGE-WIRED and VIRTUAL-SKIN-CHARGE-PERSIST PollingDelay 300000ms -> 5000ms.
- Keeps all eight throttling-only VIRTUAL-SKIN targets from v1.3-mustang.10.
- Keeps thermal_info_config.json VIRTUAL-SKIN-SPEAKER from v1.3-mustang.11.
- Does not alter VIRTUAL-SKIN entries with absent/null PollingDelay.
- Requires post-reboot runtime verification for fresh ThermalHAL tombstones.

## v1.3-mustang.11

- Adds the first base thermal config candidate to the stable v1.3-mustang.10 throttling baseline: thermal_info_config.json VIRTUAL-SKIN-SPEAKER PollingDelay 300000ms -> 5000ms.
- Keeps all eight throttling-only VIRTUAL-SKIN targets from v1.3-mustang.10.
- Does not add thermal_info_config_charge.json.
- Does not alter VIRTUAL-SKIN entries with absent/null PollingDelay.
- Requires post-reboot runtime verification for fresh ThermalHAL tombstones.

## v1.3-mustang.10

- Adds the final remaining throttling-only VIRTUAL-SKIN sensor to the stable v1.3-mustang.9 baseline: VIRTUAL-SKIN-SOC-EXTREME PollingDelay 300000ms -> 5000ms.
- Active targets: VIRTUAL-SKIN, VIRTUAL-SKIN-HINT, VIRTUAL-SKIN-CPU-LIGHT-ODPM, VIRTUAL-SKIN-CPU-ODPM, VIRTUAL-SKIN-CPU-MID, VIRTUAL-SKIN-CPU-HIGH, VIRTUAL-SKIN-SOC, VIRTUAL-SKIN-SOC-EXTREME.
- Keeps overlay scope limited to system/vendor/etc/thermal_info_config_throttling.json.
- Does not restore thermal_info_config.json or thermal_info_config_charge.json.
- Requires post-reboot runtime verification for fresh ThermalHAL tombstones.

## v1.3-mustang.9

- Adds one additional SOC-adjacent VIRTUAL-SKIN throttling sensor to the stable v1.3-mustang.8 baseline: VIRTUAL-SKIN-SOC PollingDelay 300000ms -> 5000ms.
- Active targets: VIRTUAL-SKIN, VIRTUAL-SKIN-HINT, VIRTUAL-SKIN-CPU-LIGHT-ODPM, VIRTUAL-SKIN-CPU-ODPM, VIRTUAL-SKIN-CPU-MID, VIRTUAL-SKIN-CPU-HIGH, VIRTUAL-SKIN-SOC.
- Keeps overlay scope limited to system/vendor/etc/thermal_info_config_throttling.json.
- Does not restore thermal_info_config.json or thermal_info_config_charge.json.
- Requires post-reboot runtime verification for fresh ThermalHAL tombstones.

## v1.3-mustang.8

- Adds one additional VIRTUAL-SKIN throttling sensor to the stable v1.3-mustang.7 baseline: VIRTUAL-SKIN-HINT PollingDelay 300000ms -> 5000ms.
- Active targets: VIRTUAL-SKIN, VIRTUAL-SKIN-HINT, VIRTUAL-SKIN-CPU-LIGHT-ODPM, VIRTUAL-SKIN-CPU-ODPM, VIRTUAL-SKIN-CPU-MID, VIRTUAL-SKIN-CPU-HIGH.
- Keeps overlay scope limited to system/vendor/etc/thermal_info_config_throttling.json.
- Does not restore thermal_info_config.json or thermal_info_config_charge.json.
- Requires post-reboot runtime verification for fresh ThermalHAL tombstones.

## v1.3-mustang.7

- Adds one additional generic VIRTUAL-SKIN throttling sensor to the stable v1.3-mustang.6 baseline: VIRTUAL-SKIN PollingDelay 300000ms -> 5000ms.
- Active targets: VIRTUAL-SKIN, VIRTUAL-SKIN-CPU-LIGHT-ODPM, VIRTUAL-SKIN-CPU-ODPM, VIRTUAL-SKIN-CPU-MID, VIRTUAL-SKIN-CPU-HIGH.
- Keeps overlay scope limited to system/vendor/etc/thermal_info_config_throttling.json.
- Does not restore thermal_info_config.json or thermal_info_config_charge.json.
- Requires post-reboot runtime verification for fresh ThermalHAL tombstones.

## v1.3-mustang.6

- Adds one additional CPU-adjacent VIRTUAL-SKIN throttling sensor to the stable v1.3-mustang.5 baseline: VIRTUAL-SKIN-CPU-HIGH PollingDelay 300000ms -> 5000ms.
- Active targets: VIRTUAL-SKIN-CPU-LIGHT-ODPM, VIRTUAL-SKIN-CPU-ODPM, VIRTUAL-SKIN-CPU-MID, VIRTUAL-SKIN-CPU-HIGH.
- Keeps overlay scope limited to system/vendor/etc/thermal_info_config_throttling.json.
- Does not restore thermal_info_config.json or thermal_info_config_charge.json.
- Requires post-reboot runtime verification for fresh ThermalHAL tombstones.

## v1.3-mustang.5

- Adds one additional CPU-adjacent VIRTUAL-SKIN throttling sensor to the stable v1.3-mustang.4 baseline: VIRTUAL-SKIN-CPU-MID PollingDelay 300000ms -> 5000ms.
- Active targets: VIRTUAL-SKIN-CPU-LIGHT-ODPM, VIRTUAL-SKIN-CPU-ODPM, VIRTUAL-SKIN-CPU-MID.
- Keeps overlay scope limited to system/vendor/etc/thermal_info_config_throttling.json.
- Does not restore thermal_info_config.json or thermal_info_config_charge.json.
- Requires post-reboot runtime verification for fresh ThermalHAL tombstones.

## v1.3-mustang.4

- Adds one additional VIRTUAL-SKIN throttling sensor to the stable v1.3-mustang.3 baseline: VIRTUAL-SKIN-CPU-ODPM PollingDelay 300000ms -> 5000ms.
- Keeps overlay scope limited to system/vendor/etc/thermal_info_config_throttling.json.
- Does not restore thermal_info_config.json or thermal_info_config_charge.json.
- Requires post-reboot runtime verification for fresh ThermalHAL tombstones.
# Changelog

## v1.3-mustang.3

- Rebuilt as a minimal live-stock-derived bisect release after ThermalHAL tombstones were observed with the broader overlay.
- Uses the live stock `thermal_info_config_throttling.json` from Pixel 10 Pro XL build `CP1A.260505.005/15081906` as base.
- Removes broad overlays for:
  - `thermal_info_config.json`
  - `thermal_info_config_charge.json`
- Changes only:
  - `VIRTUAL-SKIN-CPU-LIGHT-ODPM` `PollingDelay: 300000 -> 5000`
- Replaces self-disable loop counter with passive guard logging while AshLooper remains the primary bootloop protector.
- Keeps wrong-target boot-time disable for non-`mustang`/wrong fingerprint cases.

## v1.3-mustang.2

- Added guard grace counter.
- Still failed runtime validation on this device with ThermalHAL tombstones.

## v1.3-mustang.1

- Initial Pixel 10 Pro XL / `mustang` port.
- Narrowed to `VIRTUAL-SKIN*` semantic changes.

<!-- UNIVERSAL_FIRST_V141_RC1_START -->
## 1.4.1-universal.1
Added:
- Universal-first release identity and installer flow.
- Install-time profile materialization for `mustang` and `blazer`.
- `install-state.txt` with selected profile/build/runtime model.
- Read-only post-boot `health.log` for support/verification.
- Release-scope and verify docs under `docs/`.

Changed:
- Public release naming moves from Pixel 10 Pro XL-only wording to Pixel 10-series universal wording.
- `module.prop` name/description updated while keeping stable module ID.

Not changed:
- No polling values changed by this release.
- No stable `update.json` rollout in this release build step.
- No service bind mount model.
- No live runtime text patching.
- No generic Tensor compatibility claim.

Credits:
- Keeps `marx161`, `Lycidias93`, AshLooper/RipperHybrid and future Blazer tester credits.
- Adds `teoweed` / `teozazaa` as external Tensor thermal tweak analysis inspiration only; no code or values reused.
<!-- UNIVERSAL_FIRST_V141_RC1_END -->

<!-- UNIVERSAL_FIRST_RC_SCOPE_1.4.1-universal.1_START -->
## 1.4.1-universal.1 - Universal-first release

- Converted the release to a universal-first package identity while keeping the existing module ID stable.
- Added install-time profile materialization for supported Pixel 10 profiles.
- Added read-only post-boot health evidence.
- No polling values are changed by this release.
- No bind-mount model is used.
- No live text patching is used.
- Credits: `teoweed / teozazaa` is credited for external Tensor thermal tweak analysis inspiration only; no code, values, service model or text patching model was reused.
<!-- UNIVERSAL_FIRST_RC_SCOPE_1.4.1-universal.1_END -->


## v1.4.1-universal.1 final-candidate polish

- Health log wording finalized for v1.4.1-universal.1: mount status is marked best-effort and interactive post-reboot verify remains authoritative.
- No polling-value changes.
- No update.json change in the candidate build step.
- Added explicit external inspiration boundary for teoweed / teozazaa: no code reuse, no value reuse, no bind-mount model reuse, no live text patching model reuse.
- Universal final status markers: No polling-value changes; Mustang verified; Blazer beta; read-only health; no code reuse; no value reuse.

## External inspiration boundary

- External Tensor thermal tweak by teoweed / teozazaa was used for analysis inspiration only.
- no code reuse
- no value reuse
- no service.sh bind-mount model reuse
- no live text patching model reuse

## Universal final status

- Mustang verified
- Blazer beta/pending
- No polling values changed by this release
- updateJson remains on the stable main channel until release publish.

<!-- UNIVERSAL_FINAL_STATUS_20260602_START -->
## Universal-first final status

- Mustang verified.
- Blazer beta/pending.
- No polling values changed by this release.
- External teoweed / teozazaa analysis credit is inspiration only: no code reuse, no value reuse, no service.sh bind-mount model reuse, and no live text patching.
- Runtime model: install-time profile materialization only; no bind mount and no runtime text patching.
<!-- UNIVERSAL_FINAL_STATUS_20260602_END -->

<!-- CHANGELOG_1_4_3_universal_test_1_START -->
## 1.4.3-universal-test.1 - Android 17 Mustang public universal prerelease

- Added Android 17 Mustang CP31.260508.005 / 15421345 profile to the universal test line.
- Kept Android 16 universal profile behavior unchanged.
- Added manual-only debug collector at `tools/collect-debug.sh`.
- Did not change stable `update.json`.
<!-- CHANGELOG_1_4_3_universal_test_1_END -->

## Android 17 CP21 pending factory evidence - 2026-06-04

- Imported factory-derived Android 17 CP21 thermal evidence for `frankel`, `blazer`, `mustang` and `rango`.
- Added stock thermal files plus virtual-skin maps under `profiles/android17-pending/`.
- No active profile, release ZIP, `module.prop`, `update.json`, `customize.sh` or `post-fs-data.sh` change.
- Android 17 non-Mustang support remains blocked pending real-device post-reboot verification.
