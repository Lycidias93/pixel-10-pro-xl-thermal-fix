# Pixel 10 Thermal Polling Fix 1.4.4-universal-test.2

Prerelease/test ZIP. Stable update channel remains `1.4.3-universal.3`.

## What changed

- Includes the SELinux overlay-read hotfix from `1.4.3-universal.3`.
- Keeps Android 16 universal path for mustang, frankel, blazer and rango.
- Keeps Android 17 Mustang CP31 / 15421345 verified path.
- Enables Android 17 CP21.260330.011 test profiles for frankel, blazer, mustang and rango.
- Improves manual debug ZIP evidence: SELinux contexts, AVC denials, sepolicy copy, time context, and old-vs-fresh ThermalHAL tombstone marker.

## Already verified / PASS evidence exists

- Pixel 10 Pro XL / mustang / Android 16 / CP1A.260505.005
- Pixel 10 Pro / blazer / Android 16 / CP1A.260505.005
- Pixel 10 Pro XL / mustang / Android 17 / CP31.260508.005 / 15421345

## Enabled but still needs post-reboot debug ZIP

- Pixel 10 / frankel / Android 16
- Pixel 10 Pro Fold / rango / Android 16
- Pixel 10 / frankel / Android 17 / CP21.260330.011
- Pixel 10 Pro / blazer / Android 17 / CP21.260330.011
- Pixel 10 Pro XL / mustang / Android 17 / CP21.260330.011
- Pixel 10 Pro Fold / rango / Android 17 / CP21.260330.011

## Required verification after flashing

Run after install + reboot:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```

Upload `/sdcard/Download/pixel_thermal_debug_*.zip`.

PASS requires: disable/skip_mount/remove absent, correct selected profile, active vendor thermal hashes match module overlay, ThermalHAL running, no fresh ThermalHAL tombstone or fresh AVC denial.

## Credits

- Jiggs — Android 17 Mustang CP31 verification.
- Harish — Android 16 Blazer runtime and bootguard hotfix verification.
- maicol07 — Android 16 Mustang SELinux overlay-read crash-loop logcat and `1.4.3-universal.3` hotfix verification.
