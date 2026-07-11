# Stock-file and factory-extract pipeline

Status: vNext planning and guard layer
Scope: CP31.260618.005 stock-source intake

## Goal

Stock-source files may be imported only when they are traceable, hashable and explicitly classified.

This pipeline is intentionally conservative. It does not import binary/vendor files by itself and it does not claim runtime support for untested devices.

## Target stock basis

The target CP31.260618.005 basis is:

```text
originals/frankel/CP31.260618.005/
originals/blazer/CP31.260618.005/
originals/mustang/CP31.260618.005/
originals/rango/CP31.260618.005/
```

## Minimum metadata

Every imported stock file needs one manifest row with:

```text
device
build
incremental
source_kind
source_path
relative_path
sha256
bytes
profile_consumers
classification
notes
```

Accepted `classification` values:

```text
stock-exact
compatibility-derived
unknown
```

Preferred state is `stock-exact`.

`unknown` is allowed during staging but must not be promoted into runtime claims.

## Required thermal files

A complete stock basis should normally contain:

```text
thermal_info_config.json
thermal_info_config_charge.json
thermal_info_config_throttling.json
```

## Workflow

1. Export or extract stock files outside the module overlay.
2. Run `tools/stock-export-guard.sh` on-device before exporting live stock.
3. Fill a manifest using `templates/stock-import-manifest.example.tsv`.
4. Verify the manifest with `tools/stock-import-manifest-verify.sh`.
5. Add files and manifest in a dedicated PR.
6. Run profile matrix and UI guards.
7. Update docs only after hashes and classification are present.

## Safety rules

- Do not import files from an active Magisk overlay as stock.
- Do not import while `/data/adb/modules_update/pixel-10-pro-xl-thermal-fix` exists.
- Do not import while pTune is active.
- Do not treat compatibility-derived files as stock-exact.
- Do not claim frankel/blazer/rango runtime support without device runtime logs.
- Do not bump stable `update.json` as part of stock intake.
- Do not include secrets, private dump paths, auth material or personal device paths in manifests.

## Current status

This PR adds the guard and manifest layer only.

No stock files are imported yet.

## SSD2 canonical storage

Marker: FACTORY_IMAGE_SSD2_CANONICAL_20260710

Factory image, vendor extract and thermal stock-intake work now uses only:

/ssd2/pixel-thermal-factory

The former /ssd1/jdownloader-downloads/pixel10-a17-vendor tree is superseded and was migrated under /ssd2/pixel-thermal-factory/migrated/20260710_112828/.
