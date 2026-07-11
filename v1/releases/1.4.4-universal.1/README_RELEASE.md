# Pixel 10 Thermal Polling Fix 1.4.4-universal.1

Stable channel promotion for the verified `1.4.4-universal-test.2` path.

## Stable update channel

`update.json` now points to `1.4.4-universal.1` / versionCode `1014403`.

## Included

- SELinux overlay-read hotfix from `1.4.3-universal.3`
- improved debug ZIP evidence collection from `1.4.4-universal-test.2`
- Android 16 Pixel 10 universal profile path
- Android 17 Mustang CP31 verified profile
- Android 17 CP21 profiles remain guarded and require post-reboot debug ZIPs before PASS status

## Already verified / PASS

- Pixel 10 Pro XL / mustang / Android 16 / CP1A.260505.005
- Pixel 10 Pro / blazer / Android 16 / CP1A.260505.005
- Pixel 10 Pro XL / mustang / Android 17 / CP31.260508.005 / 15421345

## Still pending verification

- Pixel 10 / frankel / Android 16
- Pixel 10 Pro Fold / rango / Android 16
- Pixel 10 / frankel / Android 17 / CP21.260330.011
- Pixel 10 Pro / blazer / Android 17 / CP21.260330.011
- Pixel 10 Pro XL / mustang / Android 17 / CP21.260330.011
- Pixel 10 Pro Fold / rango / Android 17 / CP21.260330.011

## After flashing

Reboot, then run:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```

Upload:

```text
/sdcard/Download/pixel_thermal_debug_*.zip
```

## Credits

- Jiggs — Android 17 Mustang CP31 verification
- Harish — Android 16 Blazer runtime and bootguard hotfix verification
- maicol07 — Android 16 Mustang SELinux overlay-read crash-loop logcat and hotfix verification
