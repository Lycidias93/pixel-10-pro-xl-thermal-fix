# v1.3-mustang.14

Stable minor Pixel 10 Pro XL / mustang release.

## Runtime scope

No runtime thermal scope change versus `v1.3-mustang.13`.

- `thermal_info_config_throttling.json`: all eight verified `VIRTUAL-SKIN*` PollingDelay targets set to `5000ms`
- `thermal_info_config.json`: `VIRTUAL-SKIN-SPEAKER` set to `5000ms`
- `thermal_info_config_charge.json`: `VIRTUAL-SKIN-CHARGE-WIRED` and `VIRTUAL-SKIN-CHARGE-PERSIST` set to `5000ms`

## New in this release

- Bundles `tools/pixel_thermal_debug_report.py`.
- Adds a public README verify command.
- Adds compatibility-report instructions for new Mustang firmwares and other Pixel 10-series devices.
- Adds explicit AshLooper credit and GitHub link.

## Links

- Project: https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix
- Releases: https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases
- Issues / compatibility reports: https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/issues
- AshLooper external bootloop protection: https://github.com/RipperHybrid/AshLooper

## Credits

- Original thermal polling idea and upstream inspiration: original module author / upstream project.
- Mustang fork, controlled bisect, runtime verification and packaging: Lycidias93.
- External bootloop protection during testing: AshLooper by RipperHybrid.

## Verified baseline

- `v1.3-mustang.13` post-reboot and soak verification passed.
- ThermalHAL fresh tombstone check passed.
- AshLooper loops remained `0`.
