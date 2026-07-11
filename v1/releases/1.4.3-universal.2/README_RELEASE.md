# Pixel 10 Thermal Polling Fix v1.4.3-universal.2

Stable hotfix release.

## What changed

- Fixes the boot-time `post-fs-data.sh` guard so Android 16 universal profiles (`frankel`, `blazer`, `rango`) are not disabled after install.
- Keeps Android 17 guarded to Pixel 10 Pro XL / `mustang` / `CP31.260508.005` / incremental `15421345`.
- Keeps all thermal profile files unchanged from `1.4.3-universal.1`.
- Keeps debug collection manual-only.

## Why

`1.4.3-universal.1` selected/materialized Android 16 beta profiles correctly at install time, but the older boot guard still allowed only Android 16 `mustang` and created `disable`/`skip_mount` for other codenames. This prevented Magisk from mounting the selected overlay on `blazer` even though install-state was correct.

## After install

Reboot, then collect debug evidence with:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```

Expected output:

```text
/sdcard/Download/pixel_thermal_debug_*.zip
```

## Scope

- Android 16 Pixel 10 Pro XL / `mustang`: verified
- Android 16 Pixel 10 / `frankel`: beta/pending tester verification
- Android 16 Pixel 10 Pro / `blazer`: beta/pending runtime verification after this hotfix
- Android 16 Pixel 10 Pro Fold / `rango`: beta/pending tester verification
- Android 17 Pixel 10 Pro XL / `mustang` CP31 / `15421345`: verified
- Other Android 17 devices/builds: blocked until evidence/profile exists
