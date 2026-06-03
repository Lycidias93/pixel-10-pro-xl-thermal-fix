# Pixel 10 Thermal Polling Fix v1.4.3-universal.1

Stable universal release.

## Scope

- Android 16 Pixel 10-series universal profile behavior remains unchanged.
- Android 17 is enabled only for Pixel 10 Pro XL / `mustang` on `CP31.260508.005` / `15421345`.
- Android 17 `frankel`, `blazer` and `rango` are scaffold-only pending profiles and remain blocked until device-specific evidence exists.
- Debug collection is manual-only:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```

## Safety

- No bind mounts.
- No runtime text patching.
- No automatic post-reboot debug collection.
- Stable `update.json` points to this release.
- Keep AshLooper / AshReXcue available while testing and do not whitelist this module there.
