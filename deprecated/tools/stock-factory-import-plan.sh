#!/usr/bin/env sh
set -eu

cat <<'EOF'
== stock factory import plan ==
target_build=CP31.260618.005
devices=frankel blazer mustang rango

required_paths:
- originals/frankel/CP31.260618.005/
- originals/blazer/CP31.260618.005/
- originals/mustang/CP31.260618.005/
- originals/rango/CP31.260618.005/

required_files_per_device:
- thermal_info_config.json
- thermal_info_config_charge.json
- thermal_info_config_throttling.json

required_metadata:
- source build
- source incremental when available
- source kind
- source path
- relative repo path
- sha256
- bytes
- profile consumers
- classification
- notes

classification_values:
- stock-exact
- compatibility-derived
- unknown

next_action:
prepare stock files and a manifest, then run:
tools/stock-import-manifest-verify.sh <manifest.tsv>

RESULT: STOCK_FACTORY_IMPORT_PLAN_DONE
EOF
