# Pixel 10 Thermal Polling Fix 1.4.7-universal-test.2

Prerelease for controlled pTune compatibility testing.

## What changed

- Adds `/data/adb/pixel-10-pro-xl-thermal-fix/config.env` support.
- Keeps the safe default from `1.4.7-universal-test.1`: pTune installed means this module stays enabled but `skip_mount` is kept.
- Adds a dangerous opt-in master switch for controlled tests where this module may mount even while pTune is installed/active.
- Adds immediate health markers in `health.log` so early crashes still leave evidence.
- Adds `tools/compat-check.sh`.
- Adds `tools/collect-ptune-evidence.sh`.
- Stable `update.json` remains unchanged on `1.4.4-universal.1`.

## Safe default

```text
pTune installed + no override -> Thermal module enabled, skip_mount=present
```

## Dangerous override

Create `/data/adb/pixel-10-pro-xl-thermal-fix/config.env` with both lines:

```sh
ALLOW_THERMAL_WITH_PTUNE=1
RISK_ACK_PTUNE_THERMAL_COLLISION=I_UNDERSTAND_BOOTLOOP_RISK
```

Optional guard mode:

```sh
PTUNE_GUARD_MODE=strict
```

Supported values:

```text
strict       pTune installed = skip_mount (default)
active_only  only enabled/staged pTune = skip_mount
off          guard disabled, only honored with the risk ack above
```

This override is expected to be risky. pTune `versionCode=200` already reproduced ThermalHAL bootloops on one `mustang / CP1A.260505.005` setup.

## Status commands

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/compat-check.sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-ptune-evidence.sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```
