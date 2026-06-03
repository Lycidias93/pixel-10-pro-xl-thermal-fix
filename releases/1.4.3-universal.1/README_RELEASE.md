# Pixel 10 Thermal Polling Fix v1.4.3-universal.1

Stable universal release.

## Scope

- Android 16 Pixel 10-series universal profile behavior remains unchanged.
- Android 17 is enabled only for Pixel 10 Pro XL / `mustang` on `CP31.260508.005` / `15421345`.
- Android 17 `frankel`, `blazer` and `rango` are scaffold-only pending profiles and remain blocked until device-specific evidence exists.
- Debug collection is manual-only:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```

## Safety

- No bind mounts.
- No runtime text patching.
- No automatic post-reboot debug collection.
- Stable `update.json` points to this release.
- Keep AshLooper / AshReXcue available while testing and do not whitelist this module there.

<!-- RELEASE_143_UNIVERSAL1_TESTER_CREDITS_20260603_START -->
## Tester credit and compatibility evidence

- Android 17 Mustang verification credit: `Jiggs`.
- Verified device/build: Pixel 10 Pro XL / `mustang` / Android 17 / `CP31.260508.005` / incremental `15421345`.
- Evidence: install, reboot, active overlay verification, all expected `VIRTUAL-SKIN` `PollingDelay=5000` targets, running Thermal service, and no fresh ThermalHAL tombstone.

## Online stock debug report for unsupported devices

For unsupported Pixel 10 devices or new firmware, collect stock evidence before flashing:

```sh
pkg install -y python curl
curl -fsSLo pixel_thermal_debug_report.py https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/tools/pixel_thermal_debug_report.py
python3 pixel_thermal_debug_report.py
```

Do not force-install the module outside the guard. Future vNext work may add a pre-abort debug ZIP path for unsupported install attempts.
<!-- RELEASE_143_UNIVERSAL1_TESTER_CREDITS_20260603_END -->

### Toggle/debug report for disabled module state

If Magisk keeps this module disabled, collect a read-only report before removing or reinstalling:

```sh
cd /sdcard/Download
curl -fsSLO https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/tools/pixel_thermal_toggle_debug.sh
su -c 'sh /sdcard/Download/pixel_thermal_toggle_debug.sh'
```

Output:

```text
/sdcard/Download/pixel_thermal_toggle_debug_*.txt
```

This does not change module state; it only collects diagnostic evidence.
