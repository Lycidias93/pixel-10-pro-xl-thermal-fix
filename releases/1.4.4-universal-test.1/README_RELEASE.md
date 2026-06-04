# Pixel 10 Thermal Polling Fix v1.4.4-universal-test.1

Universal prerelease test ZIP for Android 17 CP21 Pixel 10-series enablement.

Stable update channel remains on `v1.4.3-universal.2`. This prerelease does not promote CP21 to stable.

## PASS / verified scopes

- Pixel 10 Pro XL / mustang / Android 16 / CP1A.260505.005
- Pixel 10 Pro / blazer / Android 16 / CP1A.260505.005 — thanks Harish
- Pixel 10 Pro XL / mustang / Android 17 / CP31.260508.005 / 15421345 — thanks Jiggs

## Enabled in this prerelease but pending runtime PASS

- Pixel 10 / frankel / Android 17 / CP21.260330.011
- Pixel 10 Pro / blazer / Android 17 / CP21.260330.011
- Pixel 10 Pro XL / mustang / Android 17 / CP21.260330.011
- Pixel 10 Pro Fold / rango / Android 17 / CP21.260330.011

A pending entry means the profile is guarded and flashable for testers, but still needs post-reboot debug ZIP verification before it can be treated as PASS.

## After flashing

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```

Upload `/sdcard/Download/pixel_thermal_debug_*.zip`.

## Patch rule

Generated CP21 test profiles only change existing `VIRTUAL-SKIN*` objects with `PollingDelay=300000` to `5000`. No non-virtual-skin sensors are intentionally changed.

## CP21 patch counts

### frankel

| File | Changed 300000→5000 |
|---|---:|
| `thermal_info_config.json` | 3 |
| `thermal_info_config_charge.json` | 2 |
| `thermal_info_config_throttling.json` | 8 |

### blazer

| File | Changed 300000→5000 |
|---|---:|
| `thermal_info_config.json` | 3 |
| `thermal_info_config_charge.json` | 2 |
| `thermal_info_config_throttling.json` | 8 |

### mustang

| File | Changed 300000→5000 |
|---|---:|
| `thermal_info_config.json` | 2 |
| `thermal_info_config_charge.json` | 2 |
| `thermal_info_config_throttling.json` | 8 |

### rango

| File | Changed 300000→5000 |
|---|---:|
| `thermal_info_config.json` | 12 |
| `thermal_info_config_charge.json` | 2 |
| `thermal_info_config_throttling.json` | 8 |

## Credits

- Jiggs — Android 17 Mustang CP31 live testing and debug ZIP verification
- Harish — Android 16 Blazer runtime verification and v1.4.3-universal.2 bootguard hotfix verification
