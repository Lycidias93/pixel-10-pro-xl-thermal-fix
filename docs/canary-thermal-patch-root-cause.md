# Android 17 Canary Thermal patch root cause

## Affected tuple

- Device: `mustang`
- Android: `17`
- Build: `ZP11.260618.005`
- Observed behavior: Stock Thermal boots; Outdoor Safe, Plus, and Extended reach the end of boot animation and then the display turns black before normal Android startup UI appears.

## Confirmed causes

1. Prefix matching treated every sensor beginning with `VIRTUAL-SKIN` as an Outdoor target. New Canary sensors such as `VIRTUAL-SKIN-OVER-35C-TRIGGER` were unintentionally modified.
2. The seventh `HotThreshold` entry (zero-based index 6) is the fixed hardware emergency shutdown ceiling. It must remain byte-equivalent to the stock value, normally `55.0` C. Raising it desynchronizes the Thermal HAL from fixed kernel/hardware protection.
3. AWK arithmetic discarded decimal scale, for example converting `37.0` into `38`. The patcher must preserve the source number's decimal precision.

## Hotfix contract

- Only exact `Name` values `VIRTUAL-SKIN` and `VIRTUAL-SKIN-HINT` are Outdoor targets.
- Prefix variants and all other virtual sensors remain Thermal-byte-equivalent to stock except independently permitted `PollingDelay` changes.
- The exact target pair must occur once each across the controlled Thermal files.
- Target arrays must have exactly seven entries.
- Entry 7 (zero-based index 6) is never changed and must not exceed `55.0` C in the stock source.
- Numeric formatting preserves source decimal precision.
- The independent delta verifier enforces the same rules and rejects duplicate or missing exact target zones.
- Canary fixtures include additional `VIRTUAL-SKIN-*` sensors and a `55.0` emergency value.

## Safety boundary

Until a fixed build passes install and postboot testing on `ZP11.260618.005`, Stock Thermal is the only approved Thermal profile for that tuple. Polling and ZRAM are independent.

## Source evidence

The root cause was derived by Harish from Allen Chang's stock Thermal files and failure evidence for `mustang/ZP11.260618.005`. Exact uploaded source hashes are added when the archive is available to the repository workflow.
