# Pixel 10 Thermal Polling Fix 1.4.6-universal-test.1

Prerelease guarded Android 17 QPR1 Beta 4 test build for Pixel 10 Pro XL / `mustang`.

## Target

```text
build_id=CP31.260522.006
incremental=15591510
fingerprint=google/mustang_beta/mustang:CinnamonBun/CP31.260522.006/15591510:user/release-keys
```

## What changed

- Adds exact fingerprint guard for `CP31.260522.006 / 15591510`.
- Reuses the existing `mustang-android17-cp31` patched thermal profile.
- The stock thermal files supplied by tester match the known CP31 stock structure for the three module-touched files.

## What did not change

- No thermal profile value changes.
- No polling value changes.
- No SELinux policy changes.
- No stable updateJson promotion.
- pTune soft conflict guard from 1.4.5-universal-test.2 remains in place.

## Required proof after install

After install + reboot, run:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```

Upload the ZIP and `.sha256` from `/sdcard/Download`.
