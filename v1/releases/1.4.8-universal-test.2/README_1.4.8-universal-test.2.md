# Pixel 10 Thermal Polling Fix 1.4.8-universal-test.2

Diagnostic follow-up for KernelSU-Next/mountify backend reporting.

## Changes

- Adds `ROOT_IMPL`, `META_BACKEND_PRESENT`, `META_BACKEND_KIND`, and `META_BACKEND_VERSION`.
- Keeps `ACTIVE_VENDOR_MATCH` as the hard runtime result.
- Reports a distinct warning when a backend is present but `/vendor/etc/thermal_info_config*.json` still does not match the module overlay.
- Adds backend probe output to `collect-debug.sh`.

Stable update JSON remains on `1.4.4-universal.1`.
