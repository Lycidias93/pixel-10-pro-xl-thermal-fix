# Pixel 10 Thermal Polling Fix v1.4.3-universal.3

Stable hotfix release.

## Why this exists

A Pixel 10 Pro XL / Mustang Android 16 user reported an infinite loading / boot hang with repeated ThermalHAL crashes after installing `v1.4.3-universal.2`.

Logcat showed:

- `/vendor/bin/hw/android.hardware.thermal-service.pixel` aborting repeatedly
- `ThermalHAL could not be initialized properly`
- SELinux read denial while ThermalHAL tried to read the Magisk-mounted thermal config overlay

This was not a malformed JSON profile. It was a SELinux compatibility issue with the current Magisk overlay source label on that setup.

## Fixed

- Add `sepolicy.rule`
- Allow `hal_thermal_default` read-only access to Magisk-mounted `system_file` thermal overlay files
- Keep the permission narrow: read/open/getattr/map only, no write, no execute
- Keep the stable profile guard unchanged:
  - Android 16: `mustang`, `frankel`, `blazer`, `rango`
  - Android 17: `mustang` CP31 / `15421345` only

## Not changed

- No thermal profile values changed versus `v1.4.3-universal.2`
- No Android 17 non-Mustang stable enablement
- No runtime text patching
- No service-time bind mount
- No background polling daemon

## Verify after install

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```

Upload:

```text
/sdcard/Download/pixel_thermal_debug_*.zip
```

PASS requires:

```text
disable=absent
skip_mount=absent
remove=absent
thermal service running
no fresh ThermalHAL tombstone
active /vendor thermal hashes match module overlay hashes
```

## SHA-256

```text
9951b4cbfb0d7ad57578ad0ac26b110db1ab663d4b89215a7c9fdd3ddd2a8a42
```
