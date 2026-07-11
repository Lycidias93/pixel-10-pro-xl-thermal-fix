# Pixel 10 Thermal Polling Fix 1.4.7-universal-test.1

Prerelease test build for the strict pTune installed-presence guard.

## Change

- A non-removed `id=ptune` module now always means Thermal `skip_mount`, regardless of pTune's `disable` flag.
- `remove=present` pTune is not treated as a conflict.
- This module remains enabled/scriptable; it does not set its own `disable` during pTune presence.
- `service.sh` preserves the pTune presence guard for the next boot if pTune appears after this module was already active.
- Guard files use `disabled_reason=conflict_ptune_installed` and `conflict_guard_mode=strict_presence_skip_mount`.

## Expected state while pTune is installed

```text
Thermal disable=absent
Thermal skip_mount=present
disabled_reason=conflict_ptune_installed
conflict_guard_mode=strict_presence_skip_mount
```

## Stable channel

Stable `update.json` remains on `1.4.4-universal.1`.
