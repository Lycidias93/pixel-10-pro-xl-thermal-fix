
## 1.4.8-universal-test.1 guard_first vNext

- User disable/remove/skip_mount markers are authoritative.
- Disabled pTune is inactive.
- Added stock-export guard, quarantine helper, and vendor overlay backend diagnostics.
- Service health is read-only and does not mutate markers.
- Stable updateJson unchanged.

## Latest prerelease: 1.4.7-universal-test.2

`1.4.7-universal-test.2` adds the pTune config guard test layer on top of `1.4.7-universal-test.1`.

Safe default remains: if pTune is installed, this module stays enabled but keeps `skip_mount` so it does not mount ThermalHAL overlays beside pTune.

New test-only override config:

```sh
/data/adb/pixel-10-pro-xl-thermal-fix/config.env
ALLOW_THERMAL_WITH_PTUNE=1
RISK_ACK_PTUNE_THERMAL_COLLISION=I_UNDERSTAND_BOOTLOOP_RISK
```

New tools:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/compat-check.sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-ptune-evidence.sh
```

Stable update channel remains `1.4.4-universal.1`.

<!-- STOCK_DEBUG_ONLINE_QPR1_CP31_20260613_START -->
### Prerelease 1.4.7-universal-test.1

This prerelease changes pTune handling to a strict installed-presence guard:

- if a non-removed `id=ptune` module exists in `/data/adb/modules/ptune` or `/data/adb/modules_update/ptune`, this module keeps `skip_mount` present;
- disabled pTune still counts as a conflict because `skip_mount` must exist before the next Magisk mount pass;
- `remove=present` pTune is ignored so a pending uninstall does not keep this module parked;
- the module remains scriptable and writes `disabled_reason=conflict_ptune_installed` plus `conflict_guard_mode=strict_presence_skip_mount`;
- stable `update.json` remains on `1.4.4-universal.1`.

This means Thermal solo testing now requires pTune to be removed, not merely disabled. The stricter behavior avoids accidental same-boot ThermalHAL overlay competition when pTune is re-enabled later.

### Prerelease 1.4.6-universal-test.2

This prerelease keeps the QPR1 Beta 4 `CP31.260522.006 / 15591510` exact guard from `1.4.6-universal-test.1` and adds a pTune soft-guard cleanup fix:

- when pTune is active/staged, stale `disable` flags are removed from both the install staging module and the active runtime module;
- `skip_mount` remains present so this module does not mount ThermalHAL overlays while pTune is active;
- when pTune is absent, stale `disable`/`skip_mount`/`remove` and pTune conflict guard files are cleared so the normal overlay path can be tested cleanly after reboot;
- stable `update.json` remains on `1.4.4-universal.1`.

Required verification paths:

- pTune active: `thermal_disable=absent`, `thermal_skip_mount=present`, `SOFT_CONFLICT pTune ... action=skip_mount_only` after reboot.
- pTune absent: `thermal_disable=absent`, `thermal_skip_mount=absent`, profile materialized, post-reboot debug ZIP confirms active ThermalHAL overlay or reports the remaining mount boundary clearly.

## Online stock thermal debug report

For unsupported or newer firmware, collect stock ThermalHAL evidence **before** installing the module. This is required for Android 17 QPR/QPR1 beta builds such as `CP31.260522.006`.

### Preferred path: ADB push from a computer

Use this when the phone's stock shell has no `curl`/`wget`, or when its `su` does not support `su -c`.

1. Download this file on the computer/browser and save it as `pixel10-stock-thermal-debug-online.sh`:

```text
https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/tools/pixel10-stock-thermal-debug-online.sh
```

2. Push and run it:

```sh
adb push pixel10-stock-thermal-debug-online.sh /data/local/tmp/
adb shell
su
cd /data/local/tmp
chmod 0755 pixel10-stock-thermal-debug-online.sh
sh ./pixel10-stock-thermal-debug-online.sh
exit
exit
```

3. Pull the generated archive and checksum:

```sh
adb pull /sdcard/Download/pixel10_stock_thermal_debug_*.zip .
adb pull /sdcard/Download/pixel10_stock_thermal_debug_*.zip.sha256 .
```

If the helper reports `.tar.gz` instead of `.zip`, pull the `.tar.gz` and `.tar.gz.sha256` files instead.

### Optional path: download directly on the phone

Use only if the shell has `curl` or `wget` and root supports this syntax:

```sh
su 0 sh -c 'cd /data/local/tmp && rm -f pixel10-stock-thermal-debug-online.sh && (curl -fsSLo pixel10-stock-thermal-debug-online.sh https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/tools/pixel10-stock-thermal-debug-online.sh || wget -O pixel10-stock-thermal-debug-online.sh https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/tools/pixel10-stock-thermal-debug-online.sh) && chmod 0755 pixel10-stock-thermal-debug-online.sh && sh ./pixel10-stock-thermal-debug-online.sh'
```

If `su 0 sh -c` fails, open a root shell with `su` first and run the commands manually.

The helper is read-only. It does not install or modify this module. It copies stock `/vendor/etc/thermal_info_config*.json`, build props, SHA256s and a robust `VIRTUAL-SKIN` / `PollingDelay` summary into an archive under `/sdcard/Download`.

Upload both generated files: the archive and its matching `.sha256` file.
<!-- STOCK_DEBUG_ONLINE_QPR1_CP31_20260613_END -->

# Pixel 10 Thermal Polling Fix

<!-- RELEASE_143_UNIVERSAL_2_BOOTGUARD_HOTFIX_START -->
## Stable hotfix 1.4.3-universal.2

`1.4.3-universal.2` fixes the boot-time guard from `1.4.3-universal.1`: Android 16 universal profiles for `frankel`, `blazer`, and `rango` are no longer disabled after install by `post-fs-data.sh`.

Thermal profile files are unchanged. Android 17 remains enabled only for Pixel 10 Pro XL / `mustang` on `CP31.260508.005` / `15421345`.

After updating, reboot and run:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```
<!-- RELEASE_143_UNIVERSAL_2_BOOTGUARD_HOTFIX_END -->

<!-- README_CURRENT_STABLE_143_UNIVERSAL1_20260603_START -->
## Current stable release: `v1.4.3-universal.1`

`1.4.3-universal.1` is the current stable universal release.

- Android 16 Pixel 10-series profile behavior remains unchanged.
- Android 17 support is enabled only for Pixel 10 Pro XL / `mustang` on `CP31.260508.005` / incremental `15421345`.
- Android 17 Mustang verification credit: `Jiggs` provided the live install, reboot and manual debug ZIP evidence that promoted the A17 Mustang profile to stable.
- Android 17 `frankel`, `blazer` and `rango` are prepared as scaffold-only pending profiles and remain blocked until device-specific evidence exists.
- Debug collection is manual-only for installed modules and does not run automatically after reboot.

Manual collector after flash + reboot:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```

For devices or firmware that are not yet supported by the install guard, do **not** force-install the module. Use the online stock debug report from `main` first.
<!-- README_CURRENT_STABLE_143_UNIVERSAL1_20260603_END -->

Project: <https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix>
Releases: <https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases>
Issues / compatibility requests: <https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/issues>

Magisk thermal polling module for Pixel 10-series testing.

The **stable verified path** is still Pixel 10 Pro XL (`mustang`) on Android 16. The current universal release is a **manual prerelease test ZIP** that keeps the same module ID and stable update channel while adding a beta Pixel 10 Pro (`blazer`) profile.

## Current release channels

| Channel | Release | Device scope | Verification state | Install path |
|---|---:|---|---|---|
| Stable | `v1.4.4-universal.1` | Pixel 10-series Android 16 profiles; Android 17 only for Pixel 10 Pro XL / `mustang` / `CP31.260508.005` / `15421345` | Mustang Android 16 verified; Mustang Android 17 verified by `Jiggs`; other Android 17 devices blocked | Normal stable release / `main/update.json` |
| Pending evidence | none | Android 17 `frankel`, `blazer`, `rango`; newer firmware fingerprints | Scaffold-only documentation, no enabled profile | Submit stock debug report first |

Older universal test releases are superseded by `v1.4.3-universal.1` for normal installation.

## Permanent module identity

The module ID is intentionally kept stable:

```text
id=pixel-10-pro-xl-thermal-fix
```

The update channel is intentionally kept stable:

```text
updateJson=https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/update.json
```

This means:

- existing Mustang installs can update without a module-ID migration;
- the stable update channel only points to promoted stable releases;
- universal prereleases remain manual-only until promoted;
- future public naming/description may change, but the module ID and safe update channel should stay fixed.

## Why this fork exists

The original thermal polling idea is useful, but the first direct Pixel 10 Pro XL port was too broad for `mustang` and caused the native Pixel ThermalHAL to abort during boot.

This fork avoids blind patching. It changes only proven `PollingDelay=300000` `VIRTUAL-SKIN*` candidates that survived install, reboot and post-boot ThermalHAL checks on the verified Mustang firmware.

In daily use, the intended difference is more responsive thermal skin-sensor polling. Selected `VIRTUAL-SKIN*` sensors are checked every `5000ms` instead of every `300000ms`, so Android can notice relevant skin/thermal changes sooner during charging, navigation, camera use, gaming, hotspot use or other sustained loads. This is not an overclock, benchmark unlock, cooling bypass or guaranteed FPS tweak. The stock thermal policy remains in charge.

<!-- README_CREDITS_UNIVERSAL_20260601_START -->
<!-- EXTERNAL_INSPIRATION_BOUNDARY_20260602_START -->
## External inspiration boundary

- teoweed / teozazaa: external Tensor thermal tweak reviewed for release-hardening and support-scope ideas only.
- no code reuse from the external ZIP or thread.
- no value reuse from the external ZIP or thread.
- no service.sh bind-mount model reuse.
- no live text patching model reuse.
<!-- EXTERNAL_INSPIRATION_BOUNDARY_20260602_END -->

## Credits

- Original thermal polling fix idea and upstream inspiration: `marx161`. The module metadata intentionally keeps the upstream credit as `based on marx161`.
- Pixel 10-series fork, Mustang controlled bisect, profile materialization fix, runtime verification and public release packaging: [Lycidias93](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix).
- Android 17 Mustang live verification: `Jiggs` provided the Pixel 10 Pro XL / `mustang` / `CP31.260508.005` / `15421345` install, reboot and debug ZIP evidence used to promote the A17 Mustang profile.
- External bootloop safety during testing: [AshLooper](https://github.com/RipperHybrid/AshLooper) by RipperHybrid. AshLooper is not bundled and not required by the ZIP itself, but it is strongly recommended while testing ports, universal prereleases or new firmware.
- Future Pixel 10 Android 17 `frankel`, `blazer` and `rango` testers should be credited only after real device-specific stock evidence and post-reboot verification are available.

AshLooper should stay outside the module and this module should not be added to the AshLooper whitelist, so AshLooper can still protect against a bad boot.
<!-- README_CREDITS_UNIVERSAL_20260601_END -->

## Supported profiles

### Stable verified

```text
Device: Pixel 10 Pro XL
Codename: mustang
Android: 16
Verified build: CP1A.260505.005 / 15081906
Release: v1.4.3-universal.1
State: stable / live verified
```

```text
Device: Pixel 10 Pro XL
Codename: mustang
Android: 17
Verified build: CP31.260508.005 / 15421345
Release: v1.4.3-universal.1
State: stable / live verified by Jiggs
```

### Android 16 beta / pending live verification

```text
Pixel 10         / frankel / Android 16 / CP1A.260505.005 / beta-pending
Pixel 10 Pro     / blazer  / Android 16 / CP1A.260505.005 / beta-pending
Pixel 10 Pro Fold/ rango   / Android 16 / CP1A.260505.005 / beta-pending
```

### Android 17 prepared but blocked

```text
frankel / blazer / rango Android 17 profiles are scaffold-only pending entries.
They are not enabled by the installer until device-specific stock thermal evidence exists.
```

### Unsupported

Unknown devices, unsupported Android versions or unsupported Android 17 fingerprints abort during install. Do not force-install this module on unrelated devices or new firmware.

## How the universal ZIP works

The universal ZIP is **multi-profile**, not a shared thermal overlay.

At install time, the selector checks Android version, device codename, build identity and fingerprint. It materializes only the matching profile into the active Magisk overlay path:

```text
Android 16 mustang -> profiles/mustang -> system/vendor/etc
Android 16 frankel -> profiles/frankel -> system/vendor/etc, beta-pending
Android 16 blazer  -> profiles/blazer  -> system/vendor/etc, beta-pending
Android 16 rango   -> profiles/rango   -> system/vendor/etc, beta-pending
Android 17 mustang CP31.260508.005 / 15421345 -> profiles/mustang-android17-cp31 -> system/vendor/etc
Other Android 17 devices/builds -> abort
```

A healthy install must contain both:

```text
profiles/<device>/system/vendor/etc/...
system/vendor/etc/...
```

The first directory keeps the source profile. The second directory is the active Magisk overlay path that Android ThermalHAL reads after reboot.

## What changes in daily use

This module does not overclock the device, disable thermal protection or bypass the stock cooling policy. Android ThermalHAL remains in control.

What it changes is the update rate for selected skin-related thermal input sensors. On the verified Mustang firmware, selected `VIRTUAL-SKIN*` sensors that normally use `PollingDelay=300000ms` are polled at `5000ms` instead.

This is meant to make the thermal model react sooner during workloads where skin temperature matters, for example:

- charging while using the phone;
- Android Auto / navigation;
- camera or video recording;
- gaming or emulation;
- hotspot or sustained mobile data;
- long screen-on sessions under load.

Expected effect: more responsive thermal awareness and smoother thermal decision timing. It is not a guaranteed FPS, benchmark or battery-life tweak, and it does not make the phone ignore safety limits.

## Verified Mustang runtime scope

`v1.4.3-universal.1` and `v1.4.3-universal.1` use the same verified Mustang runtime scope.

### `thermal_info_config_throttling.json`

```text
VIRTUAL-SKIN
VIRTUAL-SKIN-HINT
VIRTUAL-SKIN-CPU-LIGHT-ODPM
VIRTUAL-SKIN-CPU-MID
VIRTUAL-SKIN-CPU-ODPM
VIRTUAL-SKIN-CPU-HIGH
VIRTUAL-SKIN-SOC
VIRTUAL-SKIN-SOC-EXTREME
```

### `thermal_info_config.json`

```text
VIRTUAL-SKIN-SPEAKER
```

### `thermal_info_config_charge.json`

```text
VIRTUAL-SKIN-CHARGE-WIRED
VIRTUAL-SKIN-CHARGE-PERSIST
```

All listed Mustang targets are set to:

```text
PollingDelay: 300000 -> 5000
```

## What is intentionally not changed

The module does not set missing/null `PollingDelay` entries to `5000`.

Examples intentionally left untouched:

```text
VIRTUAL-SKIN-PREDICTION-MODEL
VIRTUAL-SKIN-SPEAKER-SUB-0
VIRTUAL-SKIN-SPEAKER-SUB-1
VIRTUAL-SKIN-SUB-0..7
VIRTUAL-SKIN-LEGACY
VIRTUAL-SKIN-MODEL
VIRTUAL-SKIN-CHARGE
```

These entries are likely derived/model/formula sensors or helper sensors. Changing them without a real existing `PollingDelay` value would be a different and much riskier modification.

## Safety model

- The installer is device scoped.
- Mustang stable scope was built through controlled bisecting.
- Mustang `v1.4.3-universal.1` has passed install, pre-reboot staging and post-reboot verification.
- Blazer remains beta until a real Pixel 10 Pro tester reports install, reboot, mounts and ThermalHAL state.
- AshLooper is recommended as an external bootloop protection layer during testing.
- This module should not be added to the AshLooper whitelist.
- `disable` and `skip_mount` must remain absent for normal operation.

Expected healthy Mustang state for `v1.4.3-universal.1`:

```text
id=pixel-10-pro-xl-thermal-fix
version=1.4.3-universal.1
versionCode=1014304
disable=absent
skip_mount=absent
AshLooper loops=0
fresh_thermalhal_tombstone=absent
```

## Install

### Stable install

Download the latest stable ZIP from GitHub Releases and install it in Magisk:

```text
v1.4.3-universal.1
pixel-10-thermal-polling-fix-v1.4.3-universal.1.zip
```

Release page:

```text
https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v1.4.3-universal.1
```

### Manual debug collector after installing this module

After flashing and rebooting, collect runtime evidence with:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```

Output:

```text
/sdcard/Download/pixel_thermal_debug_*.zip
```

### Online stock debug report before installing this module

For unsupported Pixel 10 devices, new Android 17 firmware, or any device outside the install guard, collect a stock compatibility report before flashing. This does not install or patch anything.

```sh
pkg install -y python curl
curl -fsSLo pixel_thermal_debug_report.py https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/tools/pixel_thermal_debug_report.py
python3 pixel_thermal_debug_report.py
```

Default output:

```text
/storage/emulated/0/Download/pixel_thermal_debug_<device>_<incremental>_<timestamp>.zip
```

Do not use the installed-module collector path on devices where the module is not installed. Use the online stock debug report instead.

### vNext install-abort debug plan

A future vNext may generate a stock debug ZIP automatically before aborting an unsupported install. The guard must still abort and must not materialize overlays for unsupported Android/device/firmware combinations.

## Pre-reboot staging check

After installing a universal test ZIP and before rebooting, check that the selected profile was materialized into active `system/vendor/etc` overlays:

```sh
su -c 'id=pixel-10-pro-xl-thermal-fix; base=/data/adb/modules_update/$id; cat "$base/module.prop"; for f in system/vendor/etc/thermal_info_config_throttling.json system/vendor/etc/thermal_info_config.json system/vendor/etc/thermal_info_config_charge.json profiles/mustang/system/vendor/etc/thermal_info_config_throttling.json profiles/blazer/system/vendor/etc/thermal_info_config_throttling.json; do test -s "$base/$f" && echo "present:$f" || echo "MISSING:$f"; done'
```

Expected for a healthy universal staging:

```text
present:system/vendor/etc/thermal_info_config_throttling.json
present:system/vendor/etc/thermal_info_config.json
present:system/vendor/etc/thermal_info_config_charge.json
```

If active `system/vendor/etc` files are missing, do not reboot into that staging.

## Post-reboot verify

After rebooting, check:

```text
version=1.4.3-universal.1
versionCode=1014304
disable=absent
skip_mount=absent
```

The three overlay mounts should be present:

```text
/vendor/etc/thermal_info_config_throttling.json
/vendor/etc/thermal_info_config.json
/vendor/etc/thermal_info_config_charge.json
```

Public Termux verify command:

```sh
su -c 'mod=/data/adb/modules/pixel-10-pro-xl-thermal-fix; echo "== module =="; grep -E "^(id|version|versionCode|description|updateJson)=" "$mod/module.prop"; test ! -e "$mod/disable" && echo "disable=absent" || echo "FAIL disable=present"; test ! -e "$mod/skip_mount" && echo "skip_mount=absent" || echo "FAIL skip_mount=present"; echo "== mounts =="; for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do grep -F "pixel-10-pro-xl-thermal-fix/system/vendor/etc/$f" /proc/self/mountinfo >/dev/null && echo "mount=present:$f" || echo "FAIL_mount=absent:$f"; done; echo "== AshLooper =="; grep -E "^loops=|^disable=|^threshold=|^boot=|^whitelist=" /data/adb/modules/AshLooper/settings.prop 2>/dev/null || echo "AshLooper status not readable"'
```

The selected `VIRTUAL-SKIN*` targets should show `PollingDelay=5000`, null/missing `PollingDelay` entries should remain untouched, and there should be no fresh ThermalHAL tombstone.

## Compatibility report for new firmware or other Pixel 10 devices

<!-- DEBUG_REPORT_PERMISSION_DENIED_FIX_20260602_START -->
### Debug report PermissionError note

If the public debug report script fails with `PermissionError` while checking `/data/adb/modules/...`, download the current script from `main` again. The tool is expected to record restricted module-state access as `permission_denied` and still create the sanitized report. If you specifically need module-state details, run the script via root from Termux.
<!-- DEBUG_REPORT_PERMISSION_DENIED_FIX_20260602_END -->


Use this before requesting support for newer firmware or another Pixel 10-series device.

The command does not patch anything. It creates a sanitized ZIP with selected device identity, build fingerprint, thermal config hashes and the `VIRTUAL-SKIN*` `PollingDelay` map.

Run it from Termux:

```sh
pkg install -y python
curl -fsSLO https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/tools/pixel_thermal_debug_report.py
python3 pixel_thermal_debug_report.py
```

Default output:

```text
/storage/emulated/0/Download/pixel_thermal_debug_<device>_<incremental>_<timestamp>.zip
```

Custom output directory:

```sh
python3 pixel_thermal_debug_report.py --out-dir "$HOME/pixel-thermal-debug"
```

Upload the generated ZIP to the GitHub issue or XDA post.

Do not request support with only a marketing device name. Device codename, fingerprint and thermal files can change between firmwares.

If this module is installed and active, disable/remove it and reboot before creating an adaptation report. Otherwise `/vendor` may show Magisk overlays instead of stock thermal files.

<!-- DEBUG_REPORT_PERMISSION_FIX_20260602_START -->
[B]Permission note:[/B] On some Android/userdebug/root setups, a normal Termux shell may not be allowed to stat `/data/adb/modules/...`. The debug report tool now records that as `permission_denied` instead of crashing. If you want module-state details too, run the report through root:

```sh
su -c '/data/data/com.termux/files/usr/bin/python3 /data/data/com.termux/files/home/pixel_thermal_debug_report.py'
```
<!-- DEBUG_REPORT_PERMISSION_FIX_20260602_END -->

## Support matrix

```text
Stable verified:
- Pixel 10 Pro XL / mustang / Android 16 / CP1A.260505.005 / 15081906
- Pixel 10 Pro XL / mustang / Android 17 / CP31.260508.005 / 15421345 / verified by Jiggs

Beta / pending live verification:
- Pixel 10 / frankel / Android 16 / CP1A.260505.005
- Pixel 10 Pro / blazer / Android 16 / CP1A.260505.005
- Pixel 10 Pro Fold / rango / Android 16 / CP1A.260505.005

Prepared but blocked:
- Android 17 frankel / blazer / rango scaffold-only pending profiles

Needs stock compatibility report first:
- newer mustang firmware
- Android 17 frankel / blazer / rango
- any other Pixel 10-series codename/fingerprint
```

## Rollback

From a booted system:

```sh
su -c 'touch /data/adb/modules/pixel-10-pro-xl-thermal-fix/disable'
su -c 'touch /data/adb/modules/pixel-10-pro-xl-thermal-fix/skip_mount'
su -c 'reboot'
```

Or remove the module from Magisk and reboot.

If the device cannot boot normally, use your external bootloop protection layer or Magisk recovery workflow to disable/remove the module.

## Release policy

- `v1.4.3-universal.1` is the current stable release.
- Stable `main/update.json` points to `v1.4.3-universal.1`.
- Android 17 is enabled only for Pixel 10 Pro XL / `mustang` / `CP31.260508.005` / `15421345`.
- Android 17 `frankel`, `blazer` and `rango` remain scaffold-only pending until stock evidence and live verification exist.
- Unsupported installs should abort. A future vNext may create a pre-abort stock debug ZIP, but must not enable a profile or materialize overlays.
- Historical builds are kept for audit and rollback context, but should not be preferred for normal installation.
- Full release history belongs in `CHANGELOG.md`, not in this README.

<!-- UNIVERSAL_FIRST_V141_RC1_START -->
## Universal-first release
- Version: `1.4.1-universal.1` / `1014101`
- Release model: universal-first manual release.
- Stable module ID remains `pixel-10-pro-xl-thermal-fix` for migration safety.
- Mustang remains the verified profile.
- Blazer remains beta/pending live verification.
- No thermal polling values are changed by this support/verification release.
- No `service.sh` bind mount model and no live runtime text patching are used.
- Adds install-time `install-state.txt` and read-only post-boot `health.log`.

Credits:
- `marx161` remains credited for the original thermal polling idea.
- `teoweed` / `teozazaa` is credited as external Tensor thermal tweak analysis inspiration only. No code, bind-mount model, live runtime text patching, or polling values are reused.
<!-- UNIVERSAL_FIRST_V141_RC1_END -->

<!-- UNIVERSAL_FIRST_RC_SCOPE_1.4.1-universal.1_START -->
## Universal-first release scope

This release changes the release model and support/verification evidence only.

- No polling values are changed by this release.
- No bind-mount model is used.
- No live text patching is used.
- The active Magisk overlay is materialized at install time from the selected device profile.
- `mustang` remains the verified profile.
- `blazer` remains beta/pending until a real install, reboot, mount and ThermalHAL report is available.
- Credits include `marx161`, `teoweed / teozazaa`, RipperHybrid/AshLooper and Lycidias93, with `teoweed / teozazaa` credited for external analysis inspiration only.
<!-- UNIVERSAL_FIRST_RC_SCOPE_1.4.1-universal.1_END -->

<!-- UNIVERSAL_FINAL_STATUS_20260602_START -->
## Universal-first final status

- Mustang verified.
- Blazer beta/pending.
- No polling values changed by this release.
- External teoweed / teozazaa analysis credit is inspiration only: no code reuse, no value reuse, no service.sh bind-mount model reuse, and no live text patching.
- Runtime model: install-time profile materialization only; no bind mount and no runtime text patching.
<!-- UNIVERSAL_FINAL_STATUS_20260602_END -->

<!-- PIXEL10_ANDROID16_MINIMAL_POLLING_20260602_START -->
## Pixel 10 Android 16 minimal polling profiles

Factory-based minimal polling profiles are staged for additional Pixel 10 devices on build `CP1A.260505.005`:

| Device | Codename | Profile state |
|---|---|---|
| Pixel 10 | `frankel` | beta/pending |
| Pixel 10 Pro | `blazer` | beta/pending |
| Pixel 10 Pro Fold | `rango` | beta/pending |
| Pixel 10 Pro XL | `mustang` | stable/live verified |

The additional profiles are generated from factory thermal JSON evidence and change only allowed `VIRTUAL-SKIN` polling-delay fields to `5000`.

Guardrails:
- No CPU cdev, PIDInfo, threshold, frequency, power-rail, or non-polling fields are ported from existing tuned profiles.
- `blazer` no longer acts as a source template for other devices.
- Factory evidence is not a live-device verification.
- New devices remain beta/pending until owner install and post-reboot verification are green.
<!-- PIXEL10_ANDROID16_MINIMAL_POLLING_20260602_END -->

<!-- PIXEL10_ANDROID16_INSTALL_GUARD_20260602_START -->
## Android version/profile guard

This module profile set is Android 16 only.

Install-time guard behavior:
- aborts when `ro.build.version.release` is not Android 16,
- aborts when the build fingerprint does not identify Android 16,
- records `profile_source_android=16` and `profile_source_build=CP1A.260505.005` in `install-state.txt`,
- treats `frankel`, `blazer`, and `rango` as beta/pending live verification,
- keeps `mustang` as the only stable/live-verified profile.

Android 17 must use a separate factory evidence dump and separate profile set. Do not reuse Android 16 thermal files for Android 17.
<!-- PIXEL10_ANDROID16_INSTALL_GUARD_20260602_END -->

<!-- RELEASE_v1.4.2-universal-test.1_SUMMARY_START -->
## v1.4.2-universal-test.1 pre-release

`v1.4.2-universal-test.1` is an Android 16-only universal test release.

- `mustang`: verified/stable profile path.
- `frankel`, `blazer`, `rango`: beta/pending live verification.
- Android 17 is blocked and requires separate factory evidence/profile files.
- `update.json` remains on stable `v1.4.1-universal.1`.
<!-- RELEASE_v1.4.2-universal-test.1_SUMMARY_END -->

<!-- RELEASE_v1.4.2-universal-test.1_MUSTANG_PASS_START -->
## v1.4.2-universal-test.1 Mustang post-reboot PASS

`v1.4.2-universal-test.1` has passed post-reboot verification on Mustang / Pixel 10 Pro XL.

- Release type: pre-release.
- ZIP SHA-256: `69d2e5d9feb541996424f63a75d3d90dee1951290bd1330ba50b720331f982ae`.
- Stable update channel unchanged: `v1.4.1-universal.1`.
- `frankel`, `blazer`, and `rango` remain beta/pending live verification.
- Android 17 remains blocked pending separate factory evidence/profile files.
<!-- RELEASE_v1.4.2-universal-test.1_MUSTANG_PASS_END -->

<!-- README_RELEASE_143_UNIVERSAL_STABLE_20260603_START -->
## Stable release 1.4.3-universal.1

`1.4.3-universal.1` promotes the tested universal line to the stable update channel.

- Android 16 Pixel 10-series profile behavior remains unchanged.
- Android 17 is enabled only for Pixel 10 Pro XL / `mustang` on `CP31.260508.005` / `15421345`.
- Android 17 `frankel`, `blazer` and `rango` are prepared as scaffold-only pending profiles and remain blocked until device-specific evidence exists.
- Debug collection remains manual-only:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```

The module should still not be added to the AshLooper / AshReXcue whitelist while testing.
<!-- README_RELEASE_143_UNIVERSAL_STABLE_20260603_END -->

<!-- TOGGLE_DEBUG_SCRIPT_20260603_START -->
## Toggle/debug report for disabled module state

If Magisk keeps showing this module as disabled, collect a read-only toggle/debug report before removing or reinstalling:

```sh
cd /sdcard/Download
curl -fsSLO https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/tools/pixel_thermal_toggle_debug.sh
su -c 'sh /sdcard/Download/pixel_thermal_toggle_debug.sh'
```

Output:

```text
/sdcard/Download/pixel_thermal_toggle_debug_*.txt
```

This script does not enable, disable, remove, mount or patch anything. It records module flags, Magisk module directories, AshLooper/AshReXcue status, thermal mountinfo and recent Magisk logs so a stuck `disable`/`skip_mount` state can be diagnosed.
<!-- TOGGLE_DEBUG_SCRIPT_20260603_END -->

<!-- A17_CP21_PENDING_EVIDENCE_20260604_START -->
### Android 17 CP21 pending factory evidence

Factory-derived Android 17 CP21 thermal evidence has been imported for `frankel`, `blazer`, `mustang` and `rango` under `profiles/android17-pending/`.

This is not a support enablement. Android 17 non-Mustang devices remain blocked until patched profile review and post-reboot live verification are complete.
<!-- A17_CP21_PENDING_EVIDENCE_20260604_END -->

## 1.4.3-universal.3 prerelease note

`1.4.3-universal.3` is a universal prerelease test ZIP. It enables guarded Android 17 CP21 profiles for Pixel 10 series devices from imported factory evidence, while the stable `update.json` channel remains on `1.4.3-universal.3`.

PASS / verified scopes:

- Pixel 10 Pro XL / `mustang` / Android 16 / `CP1A.260505.005`
- Pixel 10 Pro / `blazer` / Android 16 / `CP1A.260505.005`
- Pixel 10 Pro XL / `mustang` / Android 17 / `CP31.260508.005` / `15421345`

Enabled but not runtime PASS yet:

- Pixel 10 / `frankel` / Android 17 / `CP21.260330.011`
- Pixel 10 Pro / `blazer` / Android 17 / `CP21.260330.011`
- Pixel 10 Pro XL / `mustang` / Android 17 / `CP21.260330.011`
- Pixel 10 Pro Fold / `rango` / Android 17 / `CP21.260330.011`

After flashing this prerelease, reboot and run:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```

Upload `/sdcard/Download/pixel_thermal_debug_*.zip` for PASS evaluation.


## 1.4.7-universal-test.3 - override materializer test

Prerelease `1.4.7-universal-test.3` keeps the safe default from `v1.4.7-test.2`: when pTune is installed, this module remains scriptable but uses `skip_mount` unless the user explicitly enables the high risk override.

New in this test:
- `tools/enable-ptune-override.sh` writes the risk_ack config, materializes the selected thermal profile into `system/vendor/etc`, clears `skip_mount`, and verifies the staged/active module path.
- `tools/disable-ptune-override.sh` returns to the strict safe default and restores `skip_mount` when pTune is installed.
- `tools/compat-check.sh` now reports `MODULE_OVERLAY_READY` and `ACTIVE_VENDOR_MATCH`, so an override without materialized overlay files is no longer considered healthy.
- `post-fs-data.sh` keeps the next boot protected if override config is set but overlay files are missing.

High risk override command:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/enable-ptune-override.sh
```

Return to safe default:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/disable-ptune-override.sh
```

The stable update channel is unchanged and remains on `1.4.4-universal.1`.
