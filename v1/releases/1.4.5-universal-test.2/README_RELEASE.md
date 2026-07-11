# Pixel 10 Thermal Polling Fix 1.4.5-universal-test.2

Prerelease safety test for pTune soft conflict handling.

## What changed versus test.1

- pTune conflict handling no longer creates Magisk `disable`.
- It creates `skip_mount` only, keeping this module scriptable so `post-fs-data.sh` can keep checking every boot.
- Boot guard logs `SOFT_CONFLICT pTune ... action=skip_mount_only` while pTune is active.
- Writes `guard/disabled_reason=conflict_ptune_active`, `guard/conflict_ptune_path`, and `guard/conflict_guard_mode=soft_skip_mount_only`.

## What did not change

- No thermal profile changes.
- No polling value changes.
- No SELinux policy changes.
- No stable updateJson promotion.
- No pTune code or assets bundled.

## Stable channel

Stable remains `1.4.4-universal.1`.

## Test request

With pTune active and after reboot:

```text
disable=absent
skip_mount=present
disabled_reason=conflict_ptune_active
conflict_guard_mode=soft_skip_mount_only
conflict_ptune_path=/data/adb/modules/ptune
```

Without pTune and after one additional boot if `skip_mount` had been present:

```text
disable=absent
skip_mount=absent
active /vendor thermal hashes match module overlay
ThermalHAL running
no fresh ThermalHAL tombstone
no thermal AVC denial
```
