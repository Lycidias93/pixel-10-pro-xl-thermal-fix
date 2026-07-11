# Factory image storage root

Status: active.
Marker: FACTORY_IMAGE_SSD2_CANONICAL_20260710

Canonical root:

/ssd2/pixel-thermal-factory

All Pixel Thermal factory image, vendor extract and thermal stock-intake work now lives under that root.

Superseded source:

/ssd1/jdownloader-downloads/pixel10-a17-vendor

The superseded source was migrated into:

/ssd2/pixel-thermal-factory/migrated/20260710_112828/ssd1/jdownloader-downloads/pixel10-a17-vendor

Migration evidence:

- candidate_count=162
- moved=162
- failed=0
- RESULT: PI4_FACTORY_IMAGE_MIGRATION_DONE status=ok
- RESULT: PI4_FACTORY_IMAGE_DEEP_VERIFY_DONE status=ok
- deep_inventory_count=165
- leftover_count=0

Evidence files on pi4:

- /ssd2/pixel-thermal-factory/manifests/factory_image_migration_20260710_112828.tsv
- /ssd2/pixel-thermal-factory/reports/factory_image_migration_20260710_112828.txt
- /ssd2/pixel-thermal-factory/reports/factory_image_deep_inventory_20260710_115108.txt
- /ssd2/pixel-thermal-factory/reports/factory_image_leftovers_outside_ssd2_20260710_115108.txt

Rules:

- Do not use /ssd1 as factory-image working root.
- Use /ssd2/pixel-thermal-factory for downloads, extracts, manifests, reports and incoming ZIPs.
- Do not import thermal stock files from active Magisk overlays.
- Stock files still need manifest rows with hash, size, source and classification before repo import.
- Runtime claims still require install plus reboot evidence.
