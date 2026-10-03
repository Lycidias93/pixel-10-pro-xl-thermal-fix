#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

make_module() {
  local dst="$1"
  mkdir -p "$dst/tools/core" "$dst/guard" "$dst/system/vendor/etc"
  for path in \
    tools/core/supported-build.sh \
    tools/core/outdoor-runtime-policy.sh \
    tools/core/thermal-layout.sh \
    tools/core/patch-thermal-vnext-core.sh \
    tools/core/patch-thermal.sh \
    tools/core/verify-outdoor-delta.sh \
    tools/core/validation-state.sh \
    tools/core/patch-thermal-validated-vnext.sh \
    tools/core/patch-thermal-validated.sh; do
    cp "$repo_root/$path" "$dst/$path"
  done
  cp "$repo_root/supported_versions.json" "$dst/supported_versions.json"
}

write_classic_fixture() {
  local src="$1"
  mkdir -p "$src"
  cat > "$src/thermal_info_config.json" <<'JSON'
{
  "Sensors": [
    {"Name": "VIRTUAL-SKIN", "HotThreshold": ["NAN", 39, 43, 45, 46.5, 52, 55], "PollingDelay": 300000}
  ]
}
JSON
  cat > "$src/thermal_info_config_charge.json" <<'JSON'
{
  "Sensors": [
    {"Name": "DISPLAY-SKIN", "HotThreshold": ["NAN", 40, 45, 50, 55, "NAN", "NAN"], "PollingDelay": 300000}
  ]
}
JSON
  cat > "$src/thermal_info_config_throttling.json" <<'JSON'
{
  "Sensors": [
    {"Name": "VIRTUAL-SKIN-HINT", "HotThreshold": ["NAN", 37, 43, 45, 46.5, 52, 55], "PollingDelay": 300000}
  ]
}
JSON
}

run_case() {
  local name="$1" polling="$2" profile="$3"
  local root="$tmp/$name" mod="$tmp/$name/mod" src="$tmp/$name/source" data="$tmp/$name/data"
  make_module "$mod"
  write_classic_fixture "$src"
  mkdir -p "$data"
  THERMAL_DEVICE=mustang THERMAL_ANDROID=17 THERMAL_BUILD_ID=SPARSE_PARITY_TEST \
    THERMAL_SOURCE_DIR="$src" THERMAL_DATA_ROOT="$data" \
    sh "$mod/tools/core/patch-thermal-validated.sh" "$polling" "$profile" "$mod" stock | tee "$root.log"
}

run_case stock stock stock
grep -Fxq 'PATCH_THERMAL=pass' "$tmp/stock.log"
grep -Fxq 'PATCH_THERMAL_DELTA_VALIDATION=pass' "$tmp/stock.log"
grep -Fxq 'PATCH_THERMAL_MATERIALIZATION=stock-no-overlay' "$tmp/stock.log"
grep -Fxq 'PATCH_THERMAL_OVERLAY_COUNT=0' "$tmp/stock.log"
grep -Fxq 'PATCH_THERMAL_OVERLAY_FILES=none' "$tmp/stock.log"
[[ ! -e "$tmp/stock/mod/system/vendor/etc" ]]
cat > "$tmp/stock/data/config.env" <<'CFG'
THERMAL_POLLING_MODE=stock
THERMAL_OUTDOOR_PROFILE=stock
THERMAL_DISABLED=0
CFG
THERMAL_DEVICE=mustang THERMAL_ANDROID=17 THERMAL_BUILD_ID=SPARSE_PARITY_TEST \
  THERMAL_VENDOR_DIR="$tmp/stock/source" THERMAL_DATA_ROOT="$tmp/stock/data" MODDIR="$tmp/stock/mod" \
  sh "$repo_root/tools/bootguard/compat-check-vnext.sh" > "$tmp/stock/compat.log"
grep -Fxq 'DYNAMIC_PATCH_MANIFEST_VALID=yes' "$tmp/stock/compat.log"
grep -Fxq 'DYNAMIC_PATCH_ROWS=3' "$tmp/stock/compat.log"
grep -Fxq 'DYNAMIC_MATERIALIZATION_VALID=yes' "$tmp/stock/compat.log"
grep -Fxq 'SAFE_TO_REBOOT=yes' "$tmp/stock/compat.log"
bash -c '. "$1"; thermal_materialization_overlay_valid "$2" stock stock stock' _ "$tmp/stock/mod/tools/core/thermal-layout.sh" "$tmp/stock/mod"
mkdir -p "$tmp/stock/mod/system/vendor/etc"
printf '%s\n' '{}' > "$tmp/stock/mod/system/vendor/etc/thermal_info_config_charge.json"
! bash -c '. "$1"; thermal_materialization_overlay_valid "$2" stock stock stock' _ "$tmp/stock/mod/tools/core/thermal-layout.sh" "$tmp/stock/mod"
rm -f "$tmp/stock/mod/system/vendor/etc/thermal_info_config_charge.json"

run_case outdoor stock outdoor-safe
grep -Fxq 'PATCH_THERMAL=pass' "$tmp/outdoor.log"
grep -Fxq 'PATCH_THERMAL_DELTA_VALIDATION=pass' "$tmp/outdoor.log"
grep -Fxq 'PATCH_THERMAL_MATERIALIZATION=sparse-overlay' "$tmp/outdoor.log"
grep -Fxq 'PATCH_THERMAL_OVERLAY_COUNT=2' "$tmp/outdoor.log"
grep -Fxq 'PATCH_THERMAL_OVERLAY_FILES=thermal_info_config.json,thermal_info_config_throttling.json' "$tmp/outdoor.log"
[[ -s "$tmp/outdoor/mod/system/vendor/etc/thermal_info_config.json" ]]
[[ -s "$tmp/outdoor/mod/system/vendor/etc/thermal_info_config_throttling.json" ]]
[[ ! -e "$tmp/outdoor/mod/system/vendor/etc/thermal_info_config_charge.json" ]]
grep -Fq '"HotThreshold": ["NAN", 40, 44, 46, 47.5, 53, 56]' "$tmp/outdoor/mod/system/vendor/etc/thermal_info_config.json"
grep -Fq '"HotThreshold": ["NAN", 38, 44, 46, 47.5, 53, 56]' "$tmp/outdoor/mod/system/vendor/etc/thermal_info_config_throttling.json"
bash -c '. "$1"; thermal_materialization_overlay_valid "$2" stock outdoor-safe stock' _ "$tmp/outdoor/mod/tools/core/thermal-layout.sh" "$tmp/outdoor/mod"
! bash -c '. "$1"; thermal_materialization_overlay_valid "$2" stock stock stock' _ "$tmp/outdoor/mod/tools/core/thermal-layout.sh" "$tmp/outdoor/mod"
cp "$tmp/outdoor/mod/system/vendor/etc/thermal_info_config.json" "$tmp/outdoor/good.json"
printf '%s\n' '{"truncated":true}' > "$tmp/outdoor/mod/system/vendor/etc/thermal_info_config.json"
! bash -c '. "$1"; thermal_materialization_overlay_valid "$2" stock outdoor-safe stock' _ "$tmp/outdoor/mod/tools/core/thermal-layout.sh" "$tmp/outdoor/mod"
mv "$tmp/outdoor/good.json" "$tmp/outdoor/mod/system/vendor/etc/thermal_info_config.json"
mv "$tmp/outdoor/mod/system/vendor/etc/thermal_info_config.json" "$tmp/outdoor/missing.json"
! bash -c '. "$1"; thermal_materialization_overlay_valid "$2" stock outdoor-safe stock' _ "$tmp/outdoor/mod/tools/core/thermal-layout.sh" "$tmp/outdoor/mod"
mv "$tmp/outdoor/missing.json" "$tmp/outdoor/mod/system/vendor/etc/thermal_info_config.json"

run_case polling mod stock
grep -Fxq 'PATCH_THERMAL=pass' "$tmp/polling.log"
grep -Fxq 'PATCH_THERMAL_DELTA_VALIDATION=pass' "$tmp/polling.log"
grep -Fxq 'PATCH_THERMAL_MATERIALIZATION=sparse-overlay' "$tmp/polling.log"
grep -Fxq 'PATCH_THERMAL_OVERLAY_COUNT=3' "$tmp/polling.log"
grep -R -Fq '"PollingDelay": 5000' "$tmp/polling/mod/system/vendor/etc"
bash -c '. "$1"; thermal_materialization_overlay_valid "$2" mod stock stock' _ "$tmp/polling/mod/tools/core/thermal-layout.sh" "$tmp/polling/mod"

grep -Fq 'THERMAL_LAYOUT_HELPER="$MODDIR/tools/core/thermal-layout.sh"' "$repo_root/tools/core/auto-profile-switch.sh"
grep -Fq '. "$THERMAL_LAYOUT_HELPER"' "$repo_root/tools/core/auto-profile-switch.sh"
grep -Fq 'thermal_materialization_overlay_valid "$MODDIR" "$POLLING" "$OUTDOOR" "$RECOVERY" || NEED=1' "$repo_root/tools/core/auto-profile-switch.sh"
grep -Fq 'AUTO_SWITCH_BLOCK reason=thermal_layout_helper_missing action=thermal_only_disabled' "$repo_root/tools/core/auto-profile-switch.sh"
grep -Fq 'rm -f "$MODDIR/system/vendor/etc"/thermal_info_config*.json' "$repo_root/tools/core/auto-profile-switch.sh"
grep -Fq 'thermal_materialization_overlay_valid "$MODDIR" "$ready_polling" "$ready_outdoor" "$ready_recovery" && ready=yes' "$repo_root/post-fs-data.sh"
grep -Fq 'thermal_materialization_overlay_valid "$target" "$THERMAL_POLLING_MODE" "$THERMAL_OUTDOOR_PROFILE" "$PIXEL11_HYSTERESIS_MODE"' "$repo_root/tools/ptune/enable-ptune-override.sh"
grep -Fq 'thermal_materialization_manifest_row_load' "$repo_root/tools/core/thermal-layout.sh"

printf '%s\n' 'PASS pixel10_stock_stock_zero_overlay'
printf '%s\n' 'PASS pixel10_outdoor_sparse_changed_files_only'
printf '%s\n' 'PASS pixel10_polling_sparse_all_changed_files'
printf '%s\n' 'PASS sparse_boot_consumers_honor_materialization_contract'
printf '%s\n' 'RESULT: VNEXT_SPARSE_OVERLAY_PARITY_PASS'
