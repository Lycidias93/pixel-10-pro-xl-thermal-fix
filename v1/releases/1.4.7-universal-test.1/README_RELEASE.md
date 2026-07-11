# Pixel 10 Thermal Polling Fix 1.4.7-universal-test.1

Prerelease test build for the strict pTune installed-presence guard.

## Why this exists

A pTune-enabled boot path produced repeated `android.hardware.thermal-service.pixel` tombstones with:

```text
Abort message: 'ThermalHAL could not be initialized properly.'
```

This module's pTune soft guard correctly prevented its own ThermalHAL overlay from mounting, but disabled pTune could still allow the module to rearm before pTune was later re-enabled. Since Magisk consumes `skip_mount` before module scripts can react for the same boot, the safe behavior is stricter.

## Change

- A non-removed `id=ptune` module now always means Thermal `skip_mount`, regardless of pTune's `disable` flag.
- `remove=present` pTune is not treated as a conflict.
- This module remains enabled/scriptable; it does not set its own `disable` during pTune presence.
- Guard files now use:

```text
disabled_reason=conflict_ptune_installed
conflict_guard_mode=strict_presence_skip_mount
conflict_ptune_path=/data/adb/modules/ptune
```

## Expected states

### pTune installed

```text
pTune disable=present or absent
Thermal disable=absent
Thermal skip_mount=present
disabled_reason=conflict_ptune_installed
conflict_guard_mode=strict_presence_skip_mount
```

### Thermal solo

Thermal solo now requires pTune to be removed or pending removal, not just disabled.

```text
/data/adb/modules/ptune absent
# or
/data/adb/modules/ptune/remove present
```

Then reinstall or boot the Thermal module and verify the usual debug ZIP.

## Stable channel

Stable `update.json` remains on `1.4.4-universal.1`.
