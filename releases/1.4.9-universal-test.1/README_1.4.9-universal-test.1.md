# Pixel 10 Thermal Polling Fix 1.4.9-universal-test.1

Guarded Android 17 stable CP2A factory profile import.

- Build: `CP2A.260605.012` / `15430684`
- Devices: `mustang`, `blazer`, `frankel`, `rango`
- State: factory evidence imported, pending live runtime verification
- Stable updateJson unchanged: `1.4.4-universal.1`

Post-reboot verification:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/compat-check.sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```
