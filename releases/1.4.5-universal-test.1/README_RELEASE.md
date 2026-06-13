# Pixel 10 Thermal Polling Fix 1.4.5-universal-test.1

Prerelease safety test for pTune conflict handling.

## What changed

- Adds detection for active/staged pTune module (`id=ptune`).
- If pTune is active or staged, this module self-disables by creating `disable` and `skip_mount`.
- Writes `guard/disabled_reason=conflict_ptune_active` and records the pTune path.
- Adds pTune/conflict evidence to the manual debug ZIP.

## What did not change

- No thermal profile changes.
- No polling value changes.
- No SELinux policy changes.
- No stable updateJson promotion.
- No pTune code or assets bundled.

## Stable channel

Stable remains `1.4.4-universal.1`.

## Test request

After flashing and rebooting, run:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```

Upload:

```text
/sdcard/Download/pixel_thermal_debug_*.zip
```

PASS without pTune:

```text
disable=absent
skip_mount=absent
active /vendor thermal hashes match module overlay
ThermalHAL running
no fresh ThermalHAL tombstone
no thermal AVC denial
```

PASS with pTune active:

```text
disable=present
skip_mount=present
disabled_reason=conflict_ptune_active
no claim that this module owns the active thermal overlay
```
