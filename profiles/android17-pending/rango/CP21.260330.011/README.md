# Android 17 pending factory evidence · Pixel 10 Pro Fold / rango · CP21.260330.011

State: pending evidence only.

Source:
- Android 17 Beta factory build: `CP21.260330.011`
- Device codename: `rango`
- Local extractor output imported from: `/storage/emulated/0/Download/pixel10_a17_virtual_skin_maps_cp21.260330.011/rango`

Included evidence:
- `virtual-skin-map.json`
- `virtual-skin-map.md`
- stock `thermal_info_config*.json` files from factory `vendor.img`
- `thermal-files/SHA256SUMS`

Guardrails:
- This directory does **not** enable Android 17 support for this device.
- No `customize.sh`, `post-fs-data.sh`, `module.prop`, `update.json`, active profile directory or release ZIP is changed by this evidence import.
- Runtime enablement still requires patched profile review plus post-reboot verification on a real device.

Observed extractor count:
- `virtual_skin_total`: `48`
