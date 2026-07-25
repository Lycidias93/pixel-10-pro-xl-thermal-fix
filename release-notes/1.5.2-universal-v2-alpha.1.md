# 1.5.2-universal-v2-alpha.1

Public alpha pre-release for community validation of the dynamic V2 architecture.

## What changed

- Thermal overlays are generated from the device's exact build-keyed stock source cache.
- Only three critical files are patched: thermal_info_config.json, thermal_info_config_charge.json and thermal_info_config_throttling.json.
- Polling Mod changes only matching PollingDelay 300000 values to 5000 in the controlled files.
- Source manifests, patch manifests, validation reports and active vendor hashes/values are verified fail-closed.
- Bootguard v2 records pending, last-good and failure state.
- Debug output includes dynamic source, patch, active-value and backend evidence.

## Verified before release

- Pixel 10 Pro XL (mustang)
- Android 17 / CP2A.260705.006
- Dirty install while the prior module was active
- Stock Thermal
- Polling Mod
- 22 active PollingDelay values at 5000 and zero controlled values at 300000
- Three active vendor files matched the generated overlay
- pTune disabled
- Module ZRAM disabled
- Bootguard pending absent, fail count zero and last-good present
- Runtime acceptance: active_dynamic_overlay_verified

## Alpha validation targets

1. Mustang reinstall from this public release asset.
2. Blazer stable base reboot and runtime verification.
3. Canary/ZP only on an exact supported build with a working recovery path.
4. frankel and rango community evidence.
5. ZRAM 100p separately, only after the base thermal path is green.

A PASS on Mustang does not mark another codename or build runtime-supported.

## Update channels

- Stable update.json remains on 1.5.1-universal.1.
- The alpha ZIP defaults to the stable path, matching the previous safety convention.
- Testers can explicitly select Action > Advanced > Update Channel > Use Test to follow v2/update-prerelease.json.

## Safety and rollback

- This is a public alpha, not a stable release.
- Keep a working Magisk/recovery rollback path.
- Unknown device/build combinations remain blocked by the exact-build guard.
- Disable or remove the module and reboot to return to stock.
- Do not enable pTune coexistence or ZRAM 100p during the first base validation run.

## Credits

- Harish / Codecity001 for real-world logging and the three-critical-file V2 patch scope.
- marx161 and the existing project contributors for the module foundation and testing.
