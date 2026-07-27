# Android 17 Canary Thermal patch root cause and Fix 5 reference

## Verified reference

The functional reference supplied after Allen Chang's final clean-flash testing is:

- file: `pixel-10-pro-xl-thermal-fix5.zip`
- SHA-256: `252547739652cdc6c111cb7285b40d4dc215108f50c62c0d86b3598ccf663d66`
- device/build: `mustang / Android 17 / ZP11.260618.005`
- observed result: Stock, Outdoor Safe, Outdoor Plus, and Outdoor Extended install and boot.

The ZIP is evidence, not a source branch to merge wholesale. Dev.6 ports its Thermal target semantics onto the newer transactional and fail-closed V2 implementation.

## Root cause

Older dynamic patching modified only `VIRTUAL-SKIN` and `VIRTUAL-SKIN-HINT`. Android 17 Canary added and tightened a larger hierarchy of downstream virtual sensors. Selective deltas broke the relative threshold ordering between the master skin sensors and dependent CPU, SoC, charging, speaker, and cellular emergency sensors.

Several independent intermediate defects obscured the root cause:

1. A prefix regex matched names before their closing quote and unintentionally included new sensors.
2. A later exact-pair hotfix excluded required downstream sensors.
3. Android AWK rejected the dynamic `%.*f` formatter used by dev.4.
4. Fixed expectations such as `2 zones / 14 values` or `11 / 77` did not match build-local sensor inventories.
5. An intermediate support flag marked an otherwise supported local-validation build as unsupported.
6. The old Action path committed settings before validated materialization and could leave a boot-looping profile active.

## Dev.6 target contract

The verified Fix 5 core intentionally treats the local `VIRTUAL-SKIN*` prefix as one coordinated downstream family. Unlike the earlier accidental broad match, this is now the explicit contract and is paired with an explicit ambient-trigger exclusion.

Included when present in the local stock files:

- every sensor name beginning with `VIRTUAL-SKIN`
- `cellular-emergency`

Explicitly excluded:

- `VIRTUAL-SKIN-OVER-35C-TRIGGER`

The target inventory is derived independently from each build's three stock Thermal files. No fixed sensor, array, or value count is used. Every numeric target threshold receives the same selected delta, including the final source-defined value. `NAN`/`NaN` sentinels and the stock integer/one-decimal representation are retained.

## Preserved dev.5 safeguards

- Android-AWK portable fixed-precision formatting
- atomic stock cache and overlay promotion
- independent delta validation
- canonical persistent validation state
- transactional Action, OTA auto-switch, and pTune materialization
- fail-closed rollback on any mismatch
- runtime-evidence admission by exact device/Android/build tuple

## Runtime evidence

### Mustang Stable dev.6 proof

Fresh installed-runtime verification completed on 2026-07-27 for:

- module: `2.0.0-alpha.3-dev.6 / 1016217`
- package SHA-256: `b6c7d14edc49ddded30094b984b66c0dac40d436360461bb55e5fd630148a0b9`
- device/build: `mustang / Android 17 / CP2A.260705.006 / 15641320`
- selected state: Polling Mod, Outdoor Extended, ZRAM 100p, pTune installed-disabled
- validated inventory: 3 files, 12 target zones, 12 threshold arrays, 84 values, delta `+3 C`
- active state: all three `/vendor/etc` files hash-equal to the generated module overlays
- Bootguard: pending absent, fail count 0, threshold 2, last-good present
- ZRAM: active near total RAM size with `lz77eh`
- Thermal service: responsive with no recent fatal Thermal pattern
- verifier summary: `checks_failed=0`, `warnings=0`
- exact result: `RESULT: CG_INSTALLED_RUNTIME_VERIFY_DONE outcome=success workflow_exit_code=0`

### Mustang Canary Fix 5 proof

- `mustang / Android 17 / ZP11.260618.005`
- Fix 5 clean-flash confirmation for Stock, Outdoor Safe, Outdoor Plus, and Outdoor Extended

Dev.6 is now postboot-proven on the Stable Mustang tuple. A fresh dev.6 install and postboot verification on the Canary tuple is still required before release or channel promotion.
