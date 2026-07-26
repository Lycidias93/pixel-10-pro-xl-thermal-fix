# Android 17 Canary Thermal patch root cause

## Affected tuple

- Device: `mustang`
- Android: `17`
- Build: `ZP11.260618.005`
- Initial behavior: Stock booted while all non-stock profiles failed after boot animation.
- Refined evidence: a clean install with Outdoor Safe boots; Outdoor Plus remains on an infinite loading bar. Changing profiles through the old Action path can create a boot loop.

## Confirmed implementation defects

1. Prefix matching treated every sensor beginning with `VIRTUAL-SKIN` as an Outdoor target. New Canary sensors such as `VIRTUAL-SKIN-OVER-35C-TRIGGER` were unintentionally modified.
2. The seventh `HotThreshold` entry (zero-based index 6) is the fixed hardware emergency shutdown ceiling. It must remain byte-equivalent to the stock value, normally `55.0` C.
3. AWK arithmetic discarded decimal scale. The first dev.4 formatter then used `%.*f`, which Android's AWK rejected during flashing with `formats are not supported`.
4. The old Action settings path invoked the raw patcher, wrote requested settings before independent validation, and ignored materialization failure. This made profile changes non-transactional.

## Current safety contract

- Only exact `Name` values `VIRTUAL-SKIN` and `VIRTUAL-SKIN-HINT` are Outdoor targets.
- Prefix variants and all other virtual sensors remain byte-equivalent to stock except independently permitted `PollingDelay` changes.
- The exact target pair must occur once each across the controlled Thermal files.
- Target arrays must have exactly seven entries.
- Entry 7 (zero-based index 6) is never changed and must not exceed `55.0` C in the stock source.
- Numeric formatting uses fixed portable AWK formats selected by source scale; dynamic `%.*f` is forbidden.
- Non-stock profiles are admitted only up to the maximum postboot-proven delta for the exact device/Android/build tuple.
- `mustang/17/ZP11.260618.005` is currently capped at Outdoor Safe (`+1 C`). Plus and Extended fail closed.
- Action profile and Polling changes use `patch-thermal-validated.sh`; configuration is committed only after successful materialization and independent validation.

## Isolation test

Repo-generated manual overlays contain Allen's exact stock Thermal files with only the two target arrays modified. They omit Action, dynamic patching, Polling changes, ZRAM, and services. A manual Plus overlay is the decisive isolation test:

- Plus fails: the build's Thermal semantics or accepted range is responsible.
- Plus boots: the full module's orchestration/materialization path is responsible.

## Source evidence

- `therm.rar`: `b2542ae9e98faacc453734dee25cea88c61dc95411ece7ca466841028d4fee06`
- `thermal_info_config.json`: `9976306c6421447426f17464a12a3d058eee6e4c936e6a1db7dceb9280c0286d`
- `thermal_info_config_charge.json`: `2d5d10a5ab2eae1443ea6200569c316cbf0109c407a16672386c0e0095bf8532`
- `thermal_info_config_throttling.json`: `3f2989b45a484a3f669b97019790fe533aa7e4b954e8d7a29146cbf6542423de`
- dev.2 install autosave: `ffa87f0a04fd232e76d149133b5651b3b9cd8f8a4d059ab7f9b8b96acbba1fc0`

The archive and install autosave were supplied directly by Allen Chang following Harish's collection instructions.
