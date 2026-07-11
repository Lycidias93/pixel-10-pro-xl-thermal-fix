# Bootguard v2 guard pack

Status: vNext guard layer.

Scope:

- protect only `pixel-10-pro-xl-thermal-fix`
- never disable other modules
- preserve debug evidence
- allow manual recovery
- keep WebUI for a later post-stable cycle

## Behavior

`post-fs-data.sh` calls `tools/bootguard-lib.sh preflight`.

The preflight step checks for an uncleared previous `pending_boot`, increments `guard/fail_count`, sets a new `pending_boot`, writes `guard/last_attempt.env`, and self-disables only this module after the threshold is reached.

`service.sh` calls `tools/bootguard-lib.sh success` after `sys.boot_completed=1` and the normal health/status update.

The success step writes `guard/last_good.env`, clears `pending_boot`, resets `fail_count`, and writes `guard/last_success_at`.

## Threshold

Default threshold is `2`.

Optional config:

```text
BOOTGUARD_FAIL_THRESHOLD=2
```

Allowed effective range: 2 to 5.

## Action menu

The Action menu exposes debug ZIP export, boot-crash archive export, bootguard status, and bootguard counter clear.

Counter clear does not remove the module `disable` marker.

## Differential

`tools/last-good-diff.sh` compares current state to `guard/last_good.env`.

Tracked items: build, incremental, module version/code, config hash, profile, overlay hash, pTune state, thermal settings, ZRAM settings.

## Safety

Bootguard v2 does not attempt to repair other modules and does not delete user data.

WebUI is intentionally out of scope for this guard pack and remains planned for after stable.
