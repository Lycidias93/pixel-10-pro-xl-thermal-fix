# Android 17 pending profile scaffolds

These directories are documentation/evidence placeholders only.

They are not selected by `customize.sh`, are not active runtime profiles, and are not used for installation.
Android 17 remains enabled only for `mustang` on CP31.260508.005 / 15421345 until each missing device has stock thermal evidence and post-reboot verification.

| Codename | Device | State |
|---|---|---|
| `frankel` | Pixel 10 | scaffold only / blocked by guard |
| `blazer` | Pixel 10 Pro | scaffold only / blocked by guard |
| `rango` | Pixel 10 Pro Fold | scaffold only / blocked by guard |

Required before enabling a profile:

1. Exact Android 17 build fingerprint, build id and incremental.
2. Stock `/vendor/etc/thermal_info_config*.json` files from that device/build.
3. A profile diff limited to proven `VIRTUAL-SKIN*` `PollingDelay` changes.
4. Post-reboot debug ZIP showing active overlay hash match and ThermalHAL stability.
