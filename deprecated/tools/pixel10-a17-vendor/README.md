# Pixel 10 A17 vendor workflow tools

These tools preserve the vendor extraction, matrix, and decision-report workflow used for Pixel 10 Android 17 factory images.

## Scope

- Devices: frankel, blazer, mustang, rango
- Android basis: Android 17 stable and QPR beta factory images
- Current QPR1 Beta 6 basis: CP31.260618.005

## Included tools

- pixel10_a17_vendor_extract.py: extracts selected vendor files from unpacked factory image folders
- pixel10_a17_vendor_matrix.py: builds TSV matrices from extracted vendor files
- pixel10_a17_matrix_decision_report.py: creates the focused decision report

## Recommended workflow

1. Download factory images outside the repo.
2. Extract selected vendor files with pixel10_a17_vendor_extract.py.
3. Build matrix files with pixel10_a17_vendor_matrix.py.
4. Build the decision report with pixel10_a17_matrix_decision_report.py.
5. Keep small extract/matrix/decision artifacts and delete full factory folders after verification.

## Verified pi4 layout used for CP31.260618.005

- /ssd1/jdownloader-downloads/pixel10-a17-vendor/current/cp31_260618005/vendor_extract
- /ssd1/jdownloader-downloads/pixel10-a17-vendor/current/cp31_260618005/vendor_matrix
- /ssd1/jdownloader-downloads/pixel10-a17-vendor/current/cp31_260618005/vendor_decision

## Downloader/crawler policy

Do not add a default auto-downloader that pulls large factory ZIPs without explicit user action.

A future stable/beta crawler should first generate a reviewed manifest of official factory image URLs, then require an explicit download step.
