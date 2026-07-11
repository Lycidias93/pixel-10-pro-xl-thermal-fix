# v1.3-mustang.13

Stable Pixel 10 Pro XL / mustang thermal polling release.

## Runtime scope

No runtime thermal scope change versus v1.3-mustang.12.

- thermal_info_config_throttling.json: all eight verified VIRTUAL-SKIN* PollingDelay targets set to 5000ms
- thermal_info_config.json: VIRTUAL-SKIN-SPEAKER set to 5000ms
- thermal_info_config_charge.json: VIRTUAL-SKIN-CHARGE-WIRED and VIRTUAL-SKIN-CHARGE-PERSIST set to 5000ms

## Fixes

- Corrects stale installer wording that still said thermal_info_config_throttling.json only.
- Keeps absent/null PollingDelay entries untouched.

## Verified baseline

- v1.3-mustang.12 post-reboot runtime verify passed.
- ThermalHAL fresh tombstone check passed.
- AshLooper loops remained 0.
