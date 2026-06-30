# Stable 1.5

Stable release: 1.5-universal.1
Since last public stable: 1.4.12-universal.1

## Highlights

- Verified Test25-Test29 cleanup chain promoted to stable.
- ZRAM 100p install and runtime path retained and verified.
- Use-last install flow now keeps previous settings without repeated menus.
- Thermal overlay and ZRAM setup are cleaner, easier to verify, and less installer-heavy.
- Harish / Codecity001 profile-layout mapping audit added as read-only helper and documentation.

## Verified profile

- Pixel 10 Pro XL / mustang / Android 17 CP2A.260605.012.
- Outdoor Extended, polling mod, pTune Override OFF, ZRAM 100p.
- Post-reboot: ZRAM runtime PASS and thermal tombstone index empty or absent.

## Credits

- Harish / Codecity001, JoshuaDoes, Allen Chang, Jiggs, maicol07, and existing CREDITS.md acknowledgements.

## Not included

- No TensorConservative sysfs/procfs writes.
- No direct profile resolver layout switch.
- No new runtime tuning beyond the verified Test25-Test29 chain.
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

## 1.4.8-universal-test.2

- Improved KernelSU-Next/mountify backend detection in `compat-check.sh`.
- Added `ROOT_IMPL`, `META_BACKEND_PRESENT`, `META_BACKEND_KIND`, and backend-specific vendor overlay warnings.
- Added backend probe capture to `collect-debug.sh`.
- No thermal value changes; stable update JSON unchanged.

## 1.4.8-universal-test.3

- Fixed `compat-check.sh` active vendor SHA comparison false negatives.
- Renamed the internal hash helper to avoid collision with the shell `hash` built-in.
- Added backend probe capture to `collect-debug.sh`.
- No thermal value changes; stable update JSON unchanged.

## 1.4.12-universal-test.2 test2

- Fix mixed metadata from `1.4.12-universal-test.1` where install autosave/state still reported `1.4.11-universal-test.1`.
- Fix helper execution compatibility by chmodding tools during install and documenting `su -c sh ...` entrypoints.
- Keep optional ZRAM 100p disabled by default.
- Stable update channel remains `1.4.11-universal.1`.

## 1.4.12-universal-test.3

- Hotfix optional ZRAM 100p service path: service now applies after boot/mount settle and before exit.
- Switch mmd handling to stop/start restart model with fallbacks.
- Replaces `v1.4.12-universal-test.2` for ZRAM testing; stable channel remains `v1.4.11-universal.1`.

<!-- PIXEL_THERMAL_V1412_TEST5_GUARDED_ZRAM_REINIT_START -->

## 1.4.12-universal-test.5

- Adds guarded manual `tools/reinit-zram-100p.sh` helper for the remaining ZRAM-size test path.
- Helper is disabled by default and requires explicit config + command ACK.
- Refuses live reinit when current swap usage is above a safety threshold.
- Supersedes `v1.4.12-universal-test.4` for ZRAM-size testing; stable channel remains `v1.4.11-universal.1`.
<!-- PIXEL_THERMAL_V1412_TEST5_GUARDED_ZRAM_REINIT_END -->


<!-- PIXEL_THERMAL_V1412_TEST6_VOLUME_ZRAM_MENU_START -->

## 1.4.12-universal-test.6

- Add install/action Volume-key ZRAM 100p menu.
- Write `persist.*` ZRAM props without `resetprop -n`.
- Move optional ZRAM service apply to the early boot service path.
- Keep stable channel on `v1.4.11-universal.1`.

<!-- PIXEL_THERMAL_V1412_TEST6_VOLUME_ZRAM_MENU_END -->

<!-- PIXEL_THERMAL_V1412_TEST6_RUNTIME_PROOF_START -->
- Document `1.4.12-universal-test.6` post-reboot runtime proof: Vol+ ZRAM menu path yields 100p props, fstab present, and `zram0` disksize `16323969024`.
<!-- PIXEL_THERMAL_V1412_TEST6_RUNTIME_PROOF_END -->

<!-- PIXEL_THERMAL_V1412_TEST7_ZRAM_LOG_CLEANUP_START -->
- Add `1.4.12-universal-test.7` prerelease: integrate PR #65 ZRAM install log cleanup/debug-mode gating while preserving the verified test6 ZRAM 100p runtime path and credits.
<!-- PIXEL_THERMAL_V1412_TEST7_ZRAM_LOG_CLEANUP_END -->

<!-- PIXEL_THERMAL_V1412_TEST8_METADATA_GUARD_START -->
- `1.4.12-universal-test.8`: metadata/build-guard hotfix; `customize.sh` now derives installer version metadata from `module.prop`, preventing a repeat of the test7 module.prop/customize mismatch. Runtime ZRAM/log-cleanup code unchanged from test7; stable channel remains `v1.4.11-universal.1`.
<!-- PIXEL_THERMAL_V1412_TEST8_METADATA_GUARD_END -->

<!-- PIXEL_THERMAL_V1412_STABLE_CHANGELOG_START -->
## 1.4.12-universal.1 - 2026-06-25

Stable promotion from verified `v1.4.12-universal-test.8`.

- Promotes optional ZRAM 100p with post-reboot proof on `mustang`.
- Promotes Harish / Codecity001 PR #65 debug-gated install log cleanup.
- Keeps manual `zram-debug.sh` logs available while silent installs avoid success autosave/zram menu/zram apply textlogs.
- Fixes the stable update channel to `1.4.12-universal.1`.
- Preserves JoshuaDoes mmd/service timing and resetprop boot-complete context as vNext nuance, without changing the verified persist-prop path.
<!-- PIXEL_THERMAL_V1412_STABLE_CHANGELOG_END -->

<!-- PIXEL_THERMAL_V1413_TEST1_OUTDOOR_G4_CHANGELOG_START -->
## 1.4.13-universal-test.3 - 2026-06-26

Prerelease test for optional G5 `outdoor-g4-adapted` thermal profile.

- Adds install-time Volume-key menu for optional thermal outdoor profile.
- Keeps safe default/timeout as stock.
- Adds generated `mustang-android17-stable-cp2a-260605012-outdoor-g4-adapted` profile.
- Uses degree-based G4/P9-inspired threshold targets for selected virtual skin/CPU/SOC throttle sensors.
- Blocks battery/USB/charging/speaker/emergency/shutdown/critical paths for first pass.
- Keeps stable `update.json` on `1.4.12-universal.1`.
<!-- PIXEL_THERMAL_V1413_TEST1_OUTDOOR_G4_CHANGELOG_END -->

<!-- PIXEL_THERMAL_V1413_TEST3_PR70_ALLEN_VNEXT_CHANGELOG_START -->
## 1.4.13-universal-test.3 - 2026-06-26

- Accepted PR70 ZRAM resetprop-rs boot_early rework.
- Added Allen CP31/CP21 outdoor-g4-adapted profile fix.
- Preserved debug-gated logs and stable updateJson 1.4.12-universal.1.
- Credits: Harish / Codecity001, JoshuaDoes, Allen Chang.
<!-- PIXEL_THERMAL_V1413_TEST3_PR70_ALLEN_VNEXT_CHANGELOG_END -->
