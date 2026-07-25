# 2.0.0-alpha.2

Public V2 Alpha 2 prerelease for the guarded Android 17 Pixel 10 thermal and memory path.

This release keeps the stable channel on `1.5.1-universal.1`. It promotes only the opt-in prerelease channel after the matching tag and the exact verified ZIP asset exist.

## Changes since 1.5.2-universal-v2-alpha.1

### Thermal materialization and Outdoor validation

- Routes both installation and Action rematerialization through the validated thermal wrapper.
- Keeps the dynamic build-keyed stock source and limits the overlay to the three critical files:
  - `thermal_info_config.json`;
  - `thermal_info_config_charge.json`;
  - `thermal_info_config_throttling.json`.
- Verifies exact Outdoor threshold deltas:
  - Stock: `+0`;
  - Outdoor Safe: `+1`;
  - Outdoor Plus: `+2`;
  - Outdoor Extended: `+3`.
- Preserves quoted `"NAN"` threshold sentinels exactly while applying deltas only to numeric values.
- Accepts legitimate stock files with zero target arrays instead of requiring every file to contain an Outdoor target.
- Counts only target zones that actually expose a `HotThreshold` array, matching the real dynamic patch scope.
- Fails closed and rolls back generated overlays when target arrays are malformed, missing, reordered, renamed, or changed by an unexpected delta.

### Bootguard and recovery behavior

- Restores the normal Bootguard minimum threshold to `2`.
- Keeps threshold `1` only for explicit `CANARY_DIAGNOSTIC_MODE=1` recovery diagnostics.
- Exposes the effective minimum and threshold in Bootguard status and logs.
- Prevents a normal V2 install from self-disabling after a single unresolved pending boot.

### pTune state handling

- Distinguishes pTune states accurately:
  - absent;
  - installed and disabled;
  - active and blocked;
  - active with explicit risk override.
- Writes pTune override markers only when pTune is actually active and the explicit override is effective.
- Keeps the fresh and verified release path on pTune installed-disabled or absent.

### Support and prerelease policy

- Restricts V2 activation to Android 17.
- Fails closed for unknown devices, Android versions, and build IDs.
- Keeps the supported Pixel 10 codenames `mustang`, `blazer`, `frankel`, and `rango` behind the exact build matrix.
- Correctly classifies `alpha`, `beta`, `rc`, `candidate`, and `test` versions as prereleases.
- Keeps stable `update.json` unchanged.

### Fresh-install defaults

- Polling Mod is enabled by default.
- ZRAM 100p is enabled by default with explicit risk acknowledgement recorded by the installer.
- Stock Outdoor remains the initial thermal profile.
- pTune thermal override remains off by default.

## Exact package and Mustang runtime proof

Verified package:

- File: `pixel-10-thermal-memory-control-2.0.0-alpha.2.zip`
- SHA-256: `3f66c76d65f0de29f0815c663b5dc34c37f0c1b5084e91d4df8e6d5bc939a4c8`
- Size: `2017962` bytes
- ZIP entries: `1514`
- Version: `2.0.0-alpha.2`
- VersionCode: `1016211`
- Tested source head: `392e7f634f3d2b4fcd676b8ec08337f85f5c4399`
- V2 merge commit: `ff2ea8bb3f908d9df89a4c947d2852834b75d9fa`

The package was built twice from the exact source and both archives were binary-identical. ZIP integrity, required paths, metadata, exclusion of Git metadata, and exclusion of module disable markers all passed.

Post-reboot verification passed on:

- Device: Pixel 10 Pro XL (`mustang`)
- Android: `17`
- Build: `CP2A.260705.006`
- Incremental: `15641320`
- Thermal profile: Stock
- Polling: Mod
- ZRAM: 100p
- pTune: installed-disabled
- KPatch: no active module

Runtime evidence:

- the staged module was consumed and the active module reports the exact version and versionCode;
- `disable`, `skip_mount`, and `remove` are absent;
- all three active `/vendor/etc` thermal files exactly match the module overlay hashes;
- Outdoor validation reports 3 files, 2 target zones, 2 arrays, 14 values, and exact delta `0`;
- Bootguard pending is absent, fail count is `0`, threshold is `2`, and last-good is present;
- all nine ZRAM properties match the requested values;
- ZRAM disksize is `16331833344` bytes for `15949056` KiB RAM;
- `lz77eh` is active and `/dev/block/zram0` is active swap;
- no ZRAM failure marker is present;
- final runtime marker: `RESULT: CG_INSTALLED_RUNTIME_VERIFY_DONE outcome=success workflow_exit_code=0`.

## Evidence boundary and remaining Alpha work

- Mustang has exact package install, reboot, Thermal, Bootguard, and ZRAM runtime PASS.
- Blazer has community Android 17 runtime PASS; exact build metadata and a normalized debug bundle remain evidence-hardening follow-up.
- Frankel and rango still need exact-build runtime evidence before stable support claims.
- Canary/ZP remains recovery-gated and must not be treated as a normal supported runtime path.
- Stock, Safe, Plus, and Extended pass the corrected real-layout delta matrix. Exercising Safe, Plus, and Extended through the installed Alpha 2 Action path remains a Beta 1 gate, not an Alpha 2 publication blocker.
- Active pTune coexistence remains advanced and experimental. The exact release proof covers pTune installed-disabled.
- This module does not disable Android thermal safety, overclock the device, or activate unknown builds.

## Update-channel boundary

- Stable `update.json` remains on `1.5.1-universal.1`.
- `update-prerelease.json` may point to this release only after the matching prerelease tag and exact ZIP asset are publicly available and hash-verified.
- Do not replace the verified asset under the same tag. Any package-content change requires a new versionCode, a new artifact hash, and a fresh exact-package verification cycle.
