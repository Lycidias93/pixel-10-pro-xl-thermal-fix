# Pixel 10 factory manifest and download workflow

This workflow is for recurring Android 17 Pixel 10 factory-image intake.

## Rule

Do not store full factory ZIPs in Git. They are large, repeatable downloads and must stay outside the repository.

The repository keeps only:

- manifest/crawler tools
- explicit downloader tools
- vendor extract/matrix/decision tools
- small reviewed metadata/docs

## Supported G5 devices

- frankel: Pixel 10
- blazer: Pixel 10 Pro
- mustang: Pixel 10 Pro XL
- rango: Pixel 10 Pro Fold

## Standard flow

1. Generate a reviewed factory manifest.
2. Dry-run the download plan.
3. Download factory ZIPs only with explicit `--allow-download`.
4. Extract selected vendor files.
5. Build matrix and decision report.
6. Delete full factory folders/ZIPs after verification.
7. Keep the small extract/matrix/decision artifacts.

## Manifest generation

Example:

```bash
python3 tools/pixel10-a17-vendor/pixel10_factory_manifest.py \
  --source https://developer.android.com/about/versions/17/qpr1/download \
  --build CP31.260618.005 \
  --kind factory \
  --out /ssd1/jdownloader-downloads/pixel10-a17-vendor/manifests/cp31_260618005_factory.tsv
```

## Download dry-run

```bash
python3 tools/pixel10-a17-vendor/pixel10_factory_download.py \
  --manifest /ssd1/jdownloader-downloads/pixel10-a17-vendor/manifests/cp31_260618005_factory.tsv \
  --out-dir /ssd1/jdownloader-downloads/pixel10-a17-vendor/downloads \
  --dry-run
```

## Explicit download

```bash
python3 tools/pixel10-a17-vendor/pixel10_factory_download.py \
  --manifest /ssd1/jdownloader-downloads/pixel10-a17-vendor/manifests/cp31_260618005_factory.tsv \
  --out-dir /ssd1/jdownloader-downloads/pixel10-a17-vendor/downloads \
  --allow-download
```

## Extraction and matrix

Use the existing tools in this directory:

- `pixel10_a17_vendor_extract.py`
- `pixel10_a17_vendor_matrix.py`
- `pixel10_a17_matrix_decision_report.py`

## Safety

- `pixel10_factory_manifest.py` does not download ZIPs.
- `pixel10_factory_download.py` refuses to download without `--allow-download`.
- Full factory material must remain outside Git.
- Large downloads should be reviewed by manifest and dry-run first.
