<!-- V1411_STABLE_START -->
## 1.4.11-universal.1

Stable promotion of v1.4.11 install debug autosave.

- Promoted after Pixel 10 Pro XL `mustang` post-reboot verification.
- Keeps Android 16 / Android 17 major guard and known-device guard.
- Keeps pTune conflict guard active.
- Preserves v1.4.10-universal.3 profile path fix.
- Adds install autosave evidence under `/sdcard/Download/pixel_thermal_install_*.txt`.
- Debug ZIP collector remains available at `/sdcard/Download/pixel_thermal_debug_*.zip`.
- Stable update channel points to `v1.4.11-universal.1`.
<!-- V1411_STABLE_END -->

<!-- README_V1410_STABLE_ANDROID_MAJOR_GUARD_HOTFIX_20260624_START -->
## 1.4.10-universal.1 stable

Current stable: `1.4.10-universal.1` / `versionCode=1015002`.

This stable hotfix keeps Android-major and Pixel 10 codename guards, while treating build ID, fingerprint and incremental as diagnostic fields instead of hard blockers. It is intended to reduce false blocking for QPR / unsupported-build reports while preserving safer device and Android-major boundaries.

Stable channel: `1.4.10-universal.1`.
<!-- README_V1410_STABLE_ANDROID_MAJOR_GUARD_HOTFIX_20260624_END -->

<!-- V1410_MAJOR_GUARD_TEST_START -->
## v1.4.10-universal-test.1 experimental test

Experimental test release for QPR / unsupported-build feedback.

- Android build/fingerprint/incremental checks are relaxed to Android-major + Pixel 10 codename in the test channel.
- Unsupported devices and unsupported Android major versions remain blocked.
- pTune conflict guard remains active.
- Root/backend detection is log-only diagnostics, not a hard block.
- Stable remains `v1.4.9-universal.2`.
<!-- V1410_MAJOR_GUARD_TEST_END -->

<!-- README_V149_STABLE_METADATA_HOTFIX_START -->
## Stable metadata hotfix: `1.4.9-universal.2`

`1.4.9-universal.2` corrects installer-internal metadata and installer text after the `1.4.9` stable promotion. Runtime thermal profiles and guarded auto-switch behavior stay unchanged from the validated stable line.
<!-- README_V149_STABLE_METADATA_HOTFIX_END -->

<!-- README_V149_UNIVERSAL1_STABLE_FINAL_20260621_START -->
## Stable release: 1.4.9-universal.2

Status: **stable final** for guarded auto-profile-switch.

- Release tag: `v1.4.9-universal.2`.
- VersionCode: `1014904`.
- Runtime proof: `mustang` / Android 17 Stable `CP2A.260605.012` / incremental `15430684`.
- Stable-gate dry-run: A16-to-A17 rematerialization PASS, current-profile-valid PASS, unknown-build block PASS.
- Stable update channel now points to `1.4.9-universal.2`.
- `frankel` and `rango` Android 17 stable profiles remain pending live verification.
<!-- README_V149_UNIVERSAL1_STABLE_FINAL_20260621_END -->

<!-- README_V149_TEST2_HOTFIX_RELEASE_20260621_START -->
## Hotfix prerelease: 1.4.9-universal-test.2

Status: **published hotfix prerelease** for guarded auto-profile-switch.

- Release tag: `v1.4.9-universal-test.2`.
- VersionCode: `1014902`.
- Release ZIP SHA256: `4418dfb2412597cd90f7bceaf6008929674e242563de5f49de6145938f2b1810`.
- Runtime proof: `mustang` / Android 17 Stable `CP2A.260605.012` / incremental `15430684`.
- Auto-switch result: `AUTO_SWITCH_PASS reason=current_profile_valid`.
- Compat result: `PROFILE_STALE_AFTER_OTA=no`, `REINSTALL_REQUIRED=no`, `MODULE_OVERLAY_READY=yes`, `ACTIVE_VENDOR_MATCH=yes`, `VENDOR_OVERLAY_BACKEND_WARN=no`, `SAFE_TO_REBOOT=yes`.
- Stable `update.json` now points to `1.4.9-universal.2`.

Boundary: current-profile-valid is proven; a captured stale-profile remediation event is still a separate future test.
<!-- README_V149_TEST2_HOTFIX_RELEASE_20260621_END -->

<!-- README_V149_TEST2_RUNTIME_PROOF_20260621_START -->
## Runtime proof: 1.4.9-universal-test.2 auto-profile-switch

Status: **runtime verified on mustang / Android 17 Stable CP2A**.

Evidence:
- Release candidate: `v1.4.9-universal-test.2` / `versionCode=1014902`.
- Source main after auto-switch PR: `459c201`.
- Local release ZIP SHA256: `4418dfb2412597cd90f7bceaf6008929674e242563de5f49de6145938f2b1810`.
- Debug proof ZIP: `pixel_thermal_debug_20260621_124205.zip`.
- Debug proof SHA256: `de5713b1a42e79f83b0ac439ce20a78bfbd55c2b68fff23f4f16156505c4b898`.
- Device/build: `mustang`, Android `17`, build `CP2A.260605.012`, incremental `15430684`.
- Selected profile: `mustang-android17-stable-cp2a-260605012`.
- Auto-switch runtime state: `AUTO_SWITCH_PASS reason=current_profile_valid`.
- Compat: `PROFILE_STALE_AFTER_OTA=no`, `REINSTALL_REQUIRED=no`, `MODULE_OVERLAY_READY=yes`, `ACTIVE_VENDOR_MATCH=yes`, `VENDOR_OVERLAY_BACKEND_WARN=no`, `SAFE_TO_REBOOT=yes`.
- Mount proof: active `/vendor/etc/thermal_info_config*.json` hashes match the module overlay.
- ThermalHAL proof: `logcat_thermal_tail.txt` contains live `pixel-thermal` sensor/model output; `thermal_tombstone_index.txt` is empty.
- pTune boundary: pTune is installed but disabled at runtime; override config remains explicit and documented.

Interpretation:
- The auto-switch hook is active and confirms the currently materialized profile as valid.
- This is a current-profile-valid proof, not a captured stale-profile drift remediation event.
- Unknown/incompatible builds still fail safe with `skip_mount`, `PROFILE_STALE_AFTER_OTA=yes` and `REINSTALL_REQUIRED=yes`.

Stable `update.json` now points to `1.4.9-universal.2`.
<!-- README_V149_TEST2_RUNTIME_PROOF_20260621_END -->

<!-- README_AUTO_PROFILE_SWITCH_149_UNIVERSAL_TEST2_START -->
## Guarded auto-profile-switch after compatible Android OTA/build change

Prerelease `1.4.9-universal-test.2` adds a boot-time guarded auto-profile-switch path. If the device, Android version, build ID, fingerprint and incremental match a bundled compatible profile, the module can rematerialize the active ThermalHAL profile after an OTA/build-family change without a manual reinstall.

Safety boundary:

- Unknown or incompatible builds are not auto-switched; the module writes `PROFILE_STALE_AFTER_OTA=yes`, `REINSTALL_REQUIRED=yes` and sets `skip_mount`.
- Active/staged pTune still blocks unless the explicit `ALLOW_THERMAL_WITH_PTUNE=1` plus `RISK_ACK_PTUNE_THERMAL_COLLISION=I_UNDERSTAND_BOOTLOOP_RISK` override is configured.
- Stable `update.json` remains on `v1.4.4-universal.1` until the auto-switch path has live post-reboot verification.

Verify after OTA/reboot:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/compat-check.sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```
<!-- README_AUTO_PROFILE_SWITCH_149_UNIVERSAL_TEST2_END -->

# Pixel 10 Thermal Polling Fix

Magisk thermal polling overlay for Pixel 10-series devices.

- **Stable channel:** `v1.4.9-universal.2` · **VersionCode:** `1014904`
- **Latest prerelease/test:** none newer than current stable
- **Android:** Android 16 Pixel 10-series + guarded Android 17 profiles
- **Root:** Magisk primary; KernelSU-Next / mountify community-tested
- **Module ID:** `pixel-10-pro-xl-thermal-fix`

## Download

- Current stable release: <https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v1.4.9-universal.2>
- Previous stable release: <https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v1.4.4-universal.1>
- All releases: <https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases>
- Issues / compatibility requests: <https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/issues>

Stable update channel:

```text
https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/update.json
```

The stable update channel now points to `1.4.9-universal.2`.

## Current status

- **Stable release:** `v1.4.9-universal.2`
- **Latest prerelease:** none newer than current stable
- **Install type:** Magisk ZIP
- **Android 16 verified:** Pixel 10 Pro XL / `mustang`
- **Android 16 verified:** Pixel 10 Pro / `blazer`
- **Android 17 CP31 verified:** Pixel 10 Pro XL / `mustang` / `CP31.260508.005` / `15421345`
- **Android 17 stable verified:** Pixel 10 Pro / `blazer` / `CP2A.260605.012` / `15430684`
- **Android 17 stable verified:** Pixel 10 Pro XL / `mustang` / `CP2A.260605.012` / `15430684` / Auto-Switch PASS
- **Android 17 stable included, pending live verify:** `frankel`, `rango`
- **pTune compatibility:** pTune latest alpha + Thermal Fix override verified on Magisk / `mustang`
- **KernelSU-Next / mountify:** community-tested with `ACTIVE_VENDOR_MATCH=yes`

## Changelog since `v1.4.8-universal-test.3`

### `v1.4.9-universal-test.1`

- Added guarded Android 17 stable support for `CP2A.260605.012 / 15430684`.
- Imported Android 17 stable factory thermal profiles for:
  - Pixel 10 Pro XL / `mustang`
  - Pixel 10 Pro / `blazer`
  - Pixel 10 / `frankel`
  - Pixel 10 Pro Fold / `rango`
- Added exact build/fingerprint guards for Android 17 stable profiles.
- Marked Pixel 10 Pro / `blazer` Android 17 stable as live-verified:
  - `ACTIVE_VENDOR_MATCH=yes`
  - `thermalhal_running=yes`
  - `fresh_thermal_tombstone=no`
- `mustang`, `frankel` and `rango` Android 17 stable profiles are included but still need post-reboot live verification.
- Stable update channel now points to `1.4.9-universal.2`.

## What it does

This module provides guarded thermal polling profiles for supported Pixel 10-series devices.

The installer selects the matching profile for the device codename, Android version and guarded build/fingerprint, then materializes it into the Magisk overlay path.

Design boundaries:

- no runtime text patching
- no service-time bind mount model
- no background polling daemon
- no unsupported profile activation
- no blind Android 17 support using Android 16 files

The intended change is targeted thermal polling behavior for selected Pixel thermal config entries. The stock thermal policy remains in charge. This is not an overclock, benchmark unlock, cooling bypass or FPS tweak.

## Compatibility matrix

```text
Device / Android / Build                                      Status       Notes
Pixel 10 Pro XL / mustang / Android 16                         PASS         verified
Pixel 10 Pro / blazer / Android 16                             PASS         tested by Harish
Pixel 10 Pro XL / mustang / Android 17 CP31 / 15421345         PASS         tested by Jiggs
Pixel 10 Pro / blazer / Android 17 stable CP2A / 15430684      PASS         tested by Harish
Pixel 10 Pro XL / mustang / Android 17 stable CP2A / 15430684  PASS         local Auto-Switch/runtime proof
Pixel 10 / frankel / Android 17 stable CP2A / 15430684         pending      profile included, needs live verify
Pixel 10 Pro Fold / rango / Android 17 stable CP2A / 15430684  pending      profile included, needs live verify
Pixel 10 / frankel / Android 16                                beta         needs tester feedback
Pixel 10 Pro Fold / rango / Android 16                         beta         needs tester feedback
Other builds / unknown devices                                 blocked      compatibility report required first
```

A PASS on one Pixel 10 device does not automatically verify the other codenames.

## Safe flow

### Requirements

- Supported Pixel 10-series device/build
- Magisk recommended as primary install path
- Working rollback path
- Recommended during testing: AshLooper / AshReXcue installed, but do not whitelist this module there

### Install / update

1. Download the ZIP from the release page.
2. Install/update using Magisk.
3. Reboot.
4. Run verify before reporting success or bugs.

### Verify after install/update

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/compat-check.sh
```

Expected good result:

```text
MODULE_OVERLAY_READY=yes
ACTIVE_VENDOR_MATCH=yes
VENDOR_OVERLAY_BACKEND_WARN=no
SAFE_TO_REBOOT=yes
```

Manual debug collector after reboot:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```

Output:

```text
/sdcard/Download/pixel_thermal_debug_*.zip
```

## pTune / KernelSU-Next / mountify compatibility

### pTune

pTune latest alpha was tested with this module on Pixel 10 Pro XL / `mustang`.

Verified state on Magisk with explicit Thermal Fix pTune override:

```text
PTUNE_ENABLED=yes
ALLOW_THERMAL_WITH_PTUNE=1
RISK_ACK_VALID=yes
MODULE_OVERLAY_READY=yes
ACTIVE_VENDOR_MATCH=yes
VENDOR_OVERLAY_BACKEND_WARN=no
SAFE_TO_REBOOT=yes
thermalhal_running=yes
fresh_thermal_tombstone=no
```

Important:

- pTune compatibility is still considered advanced/experimental.
- By default, the module avoids mounting beside active pTune unless the explicit risk-ack override is configured.
- Future pTune versions may add their own Mustang thermal overlays. If pTune intentionally takes priority later, compatibility may change by design.

### KernelSU-Next / mountify

A tester confirmed KernelSU-Next + MetaModule/mountify with:

```text
ACTIVE_VENDOR_MATCH=yes
```

`v1.4.8-universal-test.3` and newer include improved compat diagnostics for mountify/backend detection and active vendor match checks.

## Debug / support

Please include this when reporting issues:

```text
Device:
Codename:
Android version:
ROM / build:
Build incremental:
Build fingerprint:
Root solution + version:
Module version:
Install/update path:
Expected result:
Actual result:
Compat-check output:
Debug ZIP:
```

Installed-module debug after reboot:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```

Upload:

```text
/sdcard/Download/pixel_thermal_debug_*.zip
```

Magisk toggle / module-state issues:

```sh
cd /sdcard/Download
curl -fsSLO https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/tools/pixel_thermal_toggle_debug.sh
su -c 'sh /sdcard/Download/pixel_thermal_toggle_debug.sh'
```

Upload:

```text
/sdcard/Download/pixel_thermal_toggle_debug_*.txt
```

This helper only collects module/Magisk/module-state information. It does not delete, enable, disable or patch anything.

For unsupported devices or newer firmware before flashing, use the stock thermal debug helper/report path and upload the generated archive. Do not force-install unsupported profiles.

Public-safe quick debug command:

```sh
su -c 'MOD=/data/adb/modules/pixel-10-pro-xl-thermal-fix; echo "== module.prop =="; cat "$MOD/module.prop"; echo "== install-state =="; cat "$MOD/install-state.txt"; echo "== compat =="; sh "$MOD/tools/compat-check.sh"; echo "== overlay files =="; ls -l "$MOD/system/vendor/etc"; echo "== recent tombstones =="; ls -lt /data/tombstones | head -20'
```

Please check generated output before posting it publicly.

Do not post raw MAC addresses, private IPs, hostnames, SSH keys, tokens or personal paths.

## Rollback / uninstall

Normal rollback:

1. Disable or remove the module in Magisk.
2. Reboot.
3. Verify that the changed behavior is gone.

Copy commands, if needed:

```sh
su -c 'touch /data/adb/modules/pixel-10-pro-xl-thermal-fix/disable'
su -c 'touch /data/adb/modules/pixel-10-pro-xl-thermal-fix/skip_mount'
su -c 'reboot'
```

Manual removal, only if normal Magisk removal is not available:

```sh
su -c 'rm -rf /data/adb/modules/pixel-10-pro-xl-thermal-fix'
su -c 'reboot'
```

Only use manual cleanup when normal Magisk removal is not available. Reboot after removal.

## Recent changelog

### `v1.4.9-universal-test.1`

Added:

- Android 17 stable `CP2A.260605.012 / 15430684` guarded profile import.
- Factory thermal profiles for `mustang`, `blazer`, `frankel` and `rango`.
- Exact build/fingerprint guards for Android 17 stable profiles.

Verified:

- `blazer` Android 17 stable live verification PASS.

Pending:

- `mustang`, `frankel` and `rango` Android 17 stable need post-reboot live verification.

Notes:

- Stable updateJson now points to `1.4.9-universal.2`.

### `v1.4.8-universal-test.3`

Fixed:

- `ACTIVE_VENDOR_MATCH` false-negative in compat-check.
- SHA comparison helper no longer conflicts with shell behavior.

Verified:

- pTune latest alpha + Thermal Fix override on Magisk / `mustang`.
- KernelSU-Next + MetaModule/mountify community validation.

### `v1.4.8-universal-test.2`

Added:

- Improved KernelSU-Next / mountify backend diagnostics.
- Separated backend detection from actual active vendor match result.

### `v1.4.8-universal-test.1`

Changed:

- User `disable`, `remove` and `skip_mount` markers are authoritative.
- Disabled pTune is treated as inactive.
- Added stock-export guard, quarantine helper and backend diagnostics.
- Service health is read-only and does not mutate markers.

### `v1.4.4-universal.1`

Stable release:

- Current stable update channel target.
- Pixel 10-series Android 16 profile path.
- Guarded Android 17 Mustang support.
- Carries forward SELinux overlay-read hotfix and debug evidence collection improvements.

Older `v1.4.3` builds are superseded by newer stable/test releases.

## Related / other modules

None bundled.

External bootloop safety tools are not included in this module.

Recommended while testing:

- AshLooper / AshReXcue by RipperHybrid

Important:

- Do not whitelist this thermal module in AshLooper / AshReXcue while testing. It should remain able to disable the module if a bad boot happens.

## Credits / disclaimer

Credits:

- marx161 — original thermal polling fix idea and upstream inspiration
- Lycidias93 — Pixel 10-series fork, controlled profile handling, runtime verification tooling and release packaging
- Jiggs — Android 17 Mustang / CP31 live testing and debug ZIP verification
- Harish — Pixel 10 Pro / Blazer Android 16 and Android 17 stable live testing
- pogo-airsupport — KernelSU-Next / MetaModule / mountify validation
- RipperHybrid / AshLooper / AshReXcue — external bootloop safety recommendation during testing; not bundled
- teoweed / teozazaa — external Tensor thermal tweak analysis inspiration only; no code, values, bind-mount model or live patching model reused
- Android / Magisk / XDA communities

Disclaimer:

Root modules can change system behavior. Use at your own risk, keep a working rollback path, and do not flash modules you do not understand.
## 1.4.10-universal.2 stable profile packaging hotfix

- Fixes the 1.4.10-universal.1 release ZIP packaging issue where selected profile directories were missing from the install archive.
- Keeps the Android-major guard stable behavior from 1.4.10: Android 16/17 plus Pixel 10 codename guard.
- Build ID, fingerprint and incremental remain log/warn only, not hard blockers.
- pTune conflict guard remains active.
- Stable update channel points to 1.4.10-universal.2.

## 1.4.10-universal.3 stable profile path hotfix

- Fixes v1.4.10-universal.2 install abort after selecting the correct Android-major profile.
- Installer now accepts both nested `profiles/<profile>/system/vendor/etc` and top-level `<profile>` profile layouts.
- Build ID, fingerprint and incremental remain log/warn only, not hard blockers.
- Android 16/17 and Pixel 10 codename guards remain active.
- Stable update channel points to 1.4.10-universal.3.


## 1.4.12-universal-test.2 install-debug autosave test

- Adds automatic install-debug autosave to `/sdcard/Download` or `/storage/emulated/0/Download`.
- On installer failure, a `pixel_thermal_install_*.txt` snapshot is written automatically.
- On installer failure, the bundled debug collector is attempted with `MODDIR=$MODPATH`; collector stdout is also saved in Download.
- The exact Magisk app UI log is still outside module control, but the autosave captures the relevant installer state, selected profile, device/build, root/mount backend, pTune guard state and recent thermal logcat.
- Stable update channel remains `v1.4.10-universal.3`; this is a manual prerelease test.


### Optional ZRAM 100p test path (1.4.12-universal-test.2)

This test release adds an optional, disabled-by-default ZRAM 100p path inspired by pTune's Tensor ZRAM setup. It is not part of the thermal overlay default path.

Enable manually:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/enable-zram-100p.sh
```

Disable config:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/disable-zram-100p.sh
```

Debug:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/zram-debug.sh
```

The test overlays `/vendor/etc/fstab.zram.100p` with `zramsize=100%,zram_backingdev_size=2G` and applies the ZRAM props used by the experimental PowerPulse/pTune path. Reboot is recommended after enable/disable.

<!-- V1412_TEST2_EXEC_METADATA_FIX_START -->
### 1.4.12-universal-test.2 test2 shell-entrypoint fix

`1.4.12-universal-test.2` replaces the bad `1.4.12-universal-test.1` prerelease.

- Fixes mixed installer/autosave metadata that still reported `1.4.11-universal-test.1`.
- Keeps optional ZRAM 100p disabled by default.
- Ensures helper scripts are chmodded during install.
- Documents the compatible invocation form for Magisk/KernelSU/HybridMount environments:

```sh
su -c sh /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/enable-zram-100p.sh
su -c sh /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/disable-zram-100p.sh
su -c sh /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/zram-debug.sh
```

Stable update channel remains `1.4.11-universal.1` until this prerelease is verified.
<!-- V1412_TEST2_EXEC_METADATA_FIX_END -->
