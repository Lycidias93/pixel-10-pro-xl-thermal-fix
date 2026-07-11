# Pixel 10 Thermal Polling Fix 1.4.3-universal-test.1

Public universal prerelease.

Scope:
- Android 16 Pixel 10 profiles from the existing universal test line.
- Android 17 Mustang / Pixel 10 Pro XL only for CP31.260508.005 / incremental 15421345.
- Android 17 Mustang profile is based on tester-supplied stock evidence and has passed post-reboot verification twice.

Collector:
- No automatic post-reboot collector.
- Manual command after reboot:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```

Expected output:

```text
/sdcard/Download/pixel_thermal_debug_*.zip
```

Stable update channel remains unchanged.
