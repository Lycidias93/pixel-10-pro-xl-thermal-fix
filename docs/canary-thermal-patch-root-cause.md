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

- `mustang / 17 / CP2A.260705.006`: Outdoor Extended postboot PASS
- `mustang / 17 / ZP11.260618.005`: Fix 5 clean-flash Stock, Safe, Plus, and Extended boot confirmation

A new dev.6 package still requires fresh install and postboot verification before release or promotion.
