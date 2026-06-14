# Pixel 10 Thermal Polling Fix 1.4.6-universal-test.2

Prerelease test build.

## Scope

- Keeps `v1.4.6-universal-test.1` guarded QPR1 Beta 4 support for Pixel 10 Pro XL / mustang:
  - `CP31.260522.006`
  - incremental `15591510`
  - exact fingerprint guard
- Keeps the `v1.4.5-universal-test.2` pTune soft-conflict model.
- Adds stale-disable cleanup for pTune conflict installs.

## What changed versus 1.4.6-universal-test.1

- If pTune is active or staged, install cleanup now removes stale `disable` flags from both current install staging and active `/data/adb/modules/pixel-10-pro-xl-thermal-fix`.
- `skip_mount` is preserved in the pTune conflict path.
- If pTune is absent, stale `disable`, `skip_mount`, `remove`, and pTune conflict guard files are cleared so the no-pTune path can be verified cleanly.
- Stable `update.json` remains on `1.4.4-universal.1`.

## Verification required

### pTune active

```text
thermal_disable=absent
thermal_skip_mount=present
disabled_reason=conflict_ptune_active
conflict_guard_mode=soft_skip_mount_only
conflict_ptune_path=/data/adb/modules/ptune
bootguard_tail contains SOFT_CONFLICT pTune ... action=skip_mount_only
```

### pTune absent

```text
thermal_disable=absent
thermal_skip_mount=absent
profile_materialized=yes
active_overlay_dir=system/vendor/etc
expected_thermal_files=3
ThermalHAL running
no thermal AVC denials
no fresh ThermalHAL tombstones
```

The build is not stable until both paths are verified.
