# Pixel 10 Thermal Polling Fix 1.4.7-universal-test.3

Prerelease test for pTune override materialization.

## What changed

- Safe default unchanged: pTune installed keeps Thermal skip-mounted unless explicit override is configured.
- Added `tools/enable-ptune-override.sh` so the override always materializes the selected profile before clearing `skip_mount`.
- Added `tools/disable-ptune-override.sh` to return to the safe strict guard.
- `compat-check.sh` now reports `MODULE_OVERLAY_READY` and `ACTIVE_VENDOR_MATCH`.
- `post-fs-data.sh` protects the next boot if override config exists but overlay files are missing.
- Stable updateJson remains on `1.4.4-universal.1`.

## High risk warning

pTune `versionCode=200` has user evidence of ThermalHAL bootloops on `mustang` / `CP1A.260505.005`. Only use the override for controlled tests.
