#!/usr/bin/env bash
set -Eeuo pipefail

repo="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
tmp_root="${TMPDIR:-${PREFIX:-$HOME}/tmp}"
mkdir -p "$tmp_root"
tmp="$(mktemp -d "$tmp_root/v2-observability.XXXXXX")"

cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT HUP INT TERM

fail() {
  code="$1"
  shift
  printf '%s\n' "FAIL $*"
  printf '%s\n' "RESULT: V2_DYNAMIC_OBSERVABILITY_VERIFY_FAIL rc=$code"
  ( exit "$code" )
}

for cmd in bash sh git awk sed grep find sort sha256sum wc cmp cp mv mkdir mktemp unzip; do
  command -v "$cmd" >/dev/null 2>&1 || fail 20 "missing_command=$cmd"
done

compat="$repo/tools/bootguard/compat-check.sh"
status="$repo/tools/debug/status-lib.sh"
collector="$repo/tools/bootguard/collect-debug.sh"
patcher="$repo/tools/core/patch-thermal.sh"
helper="$repo/tools/core/supported-build.sh"
supported="$repo/supported_versions.json"

for file in "$compat" "$status" "$collector" "$patcher" "$helper" "$supported"; do
  test -s "$file" || fail 21 "missing_file=$file"
done

for file in "$compat" "$status" "$collector" "$patcher" "$helper"; do
  sh -n "$file" || fail 22 "shell_syntax=$file"
done

python3 -m json.tool "$supported" >/dev/null || fail 23 supported_versions_invalid_json
test "$(git -C "$repo" ls-files 'profiles/*' | wc -l | tr -d ' ')" = 0 ||
  fail 24 static_profiles_reintroduced

grep -q 'DYNAMIC_SOURCE_MANIFEST_VALID' "$compat" || fail 25 source_manifest_gate_missing
grep -q 'DYNAMIC_PATCH_MANIFEST_VALID' "$compat" || fail 26 patch_manifest_gate_missing
grep -q 'DYNAMIC_VALIDATION_REPORT_VALID' "$compat" || fail 27 validation_report_gate_missing
grep -q 'ACTIVE_POLLING_VALID' "$compat" || fail 28 active_polling_gate_missing
grep -q 'DYNAMIC_MATERIALIZATION_VALID' "$status" || fail 29 status_materialization_gate_missing
grep -q 'active_polling_verified' "$status" || fail 30 status_active_value_gate_missing
grep -q 'source-manifest.tsv' "$collector" || fail 31 collector_source_manifest_missing
grep -q 'patch-manifest.tsv' "$collector" || fail 32 collector_patch_manifest_missing
grep -q 'source-cache' "$collector" || fail 33 collector_source_cache_missing
grep -q 'polling_matrix.tsv' "$collector" || fail 34 collector_polling_matrix_missing
if grep -q '\.sha256' "$collector"; then
  fail 35 collector_sidecar_still_present
fi
heredoc_pattern="$(printf '<%s' '<')"
if grep -R -n "$heredoc_pattern" "$compat" "$status" "$collector"; then
  fail 36 heredoc_marker_present
fi

adb="$tmp/adb"
mod="$adb/modules/pixel-10-pro-xl-thermal-fix"
data="$adb/pixel-10-pro-xl-thermal-fix"
vendor="$tmp/vendor"
download="$tmp/download"
source_dir="$data/originals/blazer/CP2A.260705.006/vendor/etc"

mkdir -p \
  "$mod/tools/bootguard" \
  "$mod/tools/debug" \
  "$mod/tools/core" \
  "$mod/system/vendor/etc" \
  "$mod/guard" \
  "$data" \
  "$vendor" \
  "$download" \
  "$source_dir"

cp -fp "$compat" "$mod/tools/bootguard/compat-check.sh"
cp -fp "$collector" "$mod/tools/bootguard/collect-debug.sh"
cp -fp "$status" "$mod/tools/debug/status-lib.sh"
cp -fp "$helper" "$mod/tools/core/supported-build.sh"
cp -fp "$supported" "$mod/supported_versions.json"
chmod 0755 "$mod/tools/bootguard/"*.sh "$mod/tools/debug/"*.sh "$mod/tools/core/"*.sh

make_source() {
  file="$1"
  spacing="$2"
  {
    printf '%s\n' '{'
    printf '%s\n' '  "Sensors": ['
    printf '%s\n' '    {'
    printf '%s\n' '      "Name": "VIRTUAL-SKIN",'
    printf '      "PollingDelay"%s300000,\n' "$spacing"
    printf '%s\n' '      "HotThreshold": ["NAN", 40, 50]'
    printf '%s\n' '    }'
    printf '%s\n' '  ]'
    printf '%s\n' '}'
  } > "$file"
}

make_output() {
  source="$1"
  output="$2"
  sed -E 's/("PollingDelay"[[:space:]]*:[[:space:]]*)300000/\15000/' "$source" > "$output"
}

make_source "$source_dir/thermal_info_config.json" ':'
make_source "$source_dir/thermal_info_config_charge.json" ' : '
make_source "$source_dir/thermal_info_config_throttling.json" '    :    '

printf '%s\n' "file	sha256	bytes	polling_300000" > "$source_dir/source-manifest.tsv"
printf '%s\n' "file	source_sha256	output_sha256	source_polling_300000	replacements	output_polling_300000	output_polling_5000	allowed_diff" > "$mod/guard/patch-manifest.tsv"

first=1
for file in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
  src="$source_dir/$file"
  out="$mod/system/vendor/etc/$file"
  make_output "$src" "$out"
  cp -fp "$out" "$vendor/$file"
  src_sha="$(sha256sum "$src" | awk '{print $1}')"
  out_sha="$(sha256sum "$out" | awk '{print $1}')"
  src_bytes="$(wc -c < "$src" | tr -d ' ')"
  printf '%s\t%s\t%s\t%s\n' "$file" "$src_sha" "$src_bytes" 1 >> "$source_dir/source-manifest.tsv"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$file" "$src_sha" "$out_sha" 1 1 0 1 yes >> "$mod/guard/patch-manifest.tsv"
done

{
  printf '%s\n' '{'
  printf '%s\n' '  "schema": "pixel-thermal-dynamic-validation-v3",'
  printf '%s\n' '  "device": "blazer",'
  printf '%s\n' '  "build_id": "CP2A.260705.006",'
  printf '%s\n' '  "polling_mode": "mod",'
  printf '%s\n' '  "outdoor_profile": "stock",'
  printf '%s\n' '  "files": {'
  printf '%s\n' '    "thermal_info_config.json": {"validation": "passed"},'
  printf '%s\n' '    "thermal_info_config_charge.json": {"validation": "passed"},'
  printf '%s\n' '    "thermal_info_config_throttling.json": {"validation": "passed"}'
  printf '%s\n' '  },'
  printf '%s\n' '  "totals": {'
  printf '%s\n' '    "source_files": 3,'
  printf '%s\n' '    "source_polling_300000": 3,'
  printf '%s\n' '    "replacements": 3,'
  printf '%s\n' '    "output_polling_300000": 0,'
  printf '%s\n' '    "output_polling_5000": 3'
  printf '%s\n' '  },'
  printf '%s\n' '  "validation": "passed"'
  printf '%s\n' '}'
} > "$mod/validation_report.json"
cp -fp "$mod/validation_report.json" "$data/validation_report.json"

{
  printf '%s\n' "THERMAL_POLLING_MODE=mod"
  printf '%s\n' "THERMAL_OUTDOOR_PROFILE=stock"
  printf '%s\n' "THERMAL_DISABLED=0"
  printf '%s\n' "ENABLE_ZRAM_100P=0"
  printf '%s\n' "PTUNE_GUARD_MODE=strict"
  printf '%s\n' "ALLOW_THERMAL_WITH_PTUNE=0"
  printf '%s\n' "RISK_ACK_PTUNE_THERMAL_COLLISION=none"
} > "$data/config.env"

{
  printf '%s\n' "id=pixel-10-pro-xl-thermal-fix"
  printf '%s\n' "name=Fixture"
  printf '%s\n' "version=internal"
  printf '%s\n' "versionCode=1"
  printf '%s\n' "description=fixture"
} > "$mod/module.prop"

{
  printf '%s\n' "device=blazer"
  printf '%s\n' "android=17"
  printf '%s\n' "build_id=CP2A.260705.006"
  printf '%s\n' "build_guard_mode=exact_device_android_build"
  printf '%s\n' "profile=dynamic/blazer/android17"
} > "$mod/install-state.txt"

run_compat() {
  MODDIR="$mod" \
  ID=pixel-10-pro-xl-thermal-fix \
  THERMAL_ADB_ROOT="$adb" \
  THERMAL_DATA_ROOT="$data" \
  THERMAL_VENDOR_DIR="$vendor" \
  THERMAL_DEVICE=blazer \
  THERMAL_ANDROID=17 \
  THERMAL_BUILD_ID="$1" \
  THERMAL_ROOT_IMPL=fixture \
    sh "$mod/tools/bootguard/compat-check.sh"
}

compat_good="$tmp/compat-good.txt"
run_compat CP2A.260705.006 > "$compat_good"
grep -q '^EXACT_BUILD_SUPPORTED=yes$' "$compat_good" || fail 37 exact_build_not_supported
grep -q '^DYNAMIC_SOURCE_MANIFEST_VALID=yes$' "$compat_good" || fail 38 source_manifest_fixture_failed
grep -q '^DYNAMIC_PATCH_MANIFEST_VALID=yes$' "$compat_good" || fail 39 patch_manifest_fixture_failed
grep -q '^DYNAMIC_VALIDATION_REPORT_VALID=yes$' "$compat_good" || fail 40 report_fixture_failed
grep -q '^DYNAMIC_MATERIALIZATION_VALID=yes$' "$compat_good" || fail 41 materialization_fixture_failed
grep -q '^ACTIVE_VENDOR_MATCH=yes$' "$compat_good" || fail 42 active_hash_fixture_failed
grep -q '^ACTIVE_POLLING_VALID=yes$' "$compat_good" || fail 43 active_polling_fixture_failed
grep -q '^ACTIVE_POLLING_5000=3$' "$compat_good" || fail 44 active_5000_fixture_failed
grep -q '^SAFE_TO_REBOOT=yes$' "$compat_good" || fail 45 safe_fixture_failed

MODDIR="$mod" \
ID=pixel-10-pro-xl-thermal-fix \
THERMAL_ADB_ROOT="$adb" \
THERMAL_DATA_ROOT="$data" \
THERMAL_VENDOR_DIR="$vendor" \
THERMAL_DEVICE=blazer \
THERMAL_ANDROID=17 \
THERMAL_BUILD_ID=CP2A.260705.006 \
THERMAL_ROOT_IMPL=fixture \
  sh "$mod/tools/debug/status-lib.sh" collect >/dev/null

grep -q '^POLLING_STATE=active_polling_verified$' "$mod/guard/manager-status.env" ||
  fail 46 status_did_not_require_active_values
grep -q '^POLLING_VALUE=5000$' "$mod/guard/manager-status.env" ||
  fail 47 status_effective_value_not_5000

mkdir -p "$tmp/good-overlay" "$tmp/good-vendor"
cp -fp "$mod/system/vendor/etc/"*.json "$tmp/good-overlay/"
cp -fp "$vendor/"*.json "$tmp/good-vendor/"

for file in "$mod/system/vendor/etc/"*.json "$vendor/"*.json; do
  sed -E 's/("PollingDelay"[[:space:]]*:[[:space:]]*)5000/\1300000/' "$file" > "$file.tmp"
  mv "$file.tmp" "$file"
done

compat_false_green="$tmp/compat-false-green.txt"
run_compat CP2A.260705.006 > "$compat_false_green"
grep -q '^ACTIVE_VENDOR_MATCH=yes$' "$compat_false_green" ||
  fail 48 false_green_fixture_hashes_not_equal
grep -q '^ACTIVE_POLLING_VALID=no$' "$compat_false_green" ||
  fail 49 false_green_active_values_not_rejected
grep -q '^DYNAMIC_MATERIALIZATION_VALID=no$' "$compat_false_green" ||
  fail 50 false_green_manifest_not_rejected
grep -q '^SAFE_TO_REBOOT=no$' "$compat_false_green" ||
  fail 51 false_green_safe_reboot_not_blocked

MODDIR="$mod" \
ID=pixel-10-pro-xl-thermal-fix \
THERMAL_ADB_ROOT="$adb" \
THERMAL_DATA_ROOT="$data" \
THERMAL_VENDOR_DIR="$vendor" \
THERMAL_DEVICE=blazer \
THERMAL_ANDROID=17 \
THERMAL_BUILD_ID=CP2A.260705.006 \
THERMAL_ROOT_IMPL=fixture \
  sh "$mod/tools/debug/status-lib.sh" collect >/dev/null

grep -q '^POLLING_ICON=🔴$' "$mod/guard/manager-status.env" ||
  fail 52 false_green_status_not_red
if grep -q '^POLLING_ICON=🟢$' "$mod/guard/manager-status.env"; then
  fail 53 false_green_status_still_green
fi

rm -f "$mod/system/vendor/etc/"*.json
cp -fp "$tmp/good-overlay/"*.json "$mod/system/vendor/etc/"
rm -f "$vendor/"*.json
cp -fp "$tmp/good-vendor/"*.json "$vendor/"

sed -i 's/^THERMAL_DISABLED=.*/THERMAL_DISABLED=1/' "$data/config.env"
rm -f "$mod/system/vendor/etc/"*.json
compat_unsupported="$tmp/compat-unsupported.txt"
run_compat UNSUPPORTED.TEST > "$compat_unsupported"
grep -q '^EXACT_BUILD_SUPPORTED=no$' "$compat_unsupported" ||
  fail 54 unsupported_fixture_marked_supported
grep -q '^THERMAL_EXPECTED=thermal_disabled_unsupported_build$' "$compat_unsupported" ||
  fail 55 unsupported_fixture_expected_state_wrong
grep -q '^SAFE_TO_REBOOT=yes$' "$compat_unsupported" ||
  fail 56 unsupported_disabled_fixture_not_safe

sed -i 's/^THERMAL_DISABLED=.*/THERMAL_DISABLED=0/' "$data/config.env"
cp -fp "$tmp/good-overlay/"*.json "$mod/system/vendor/etc/"
rm -f "$vendor/"*.json
cp -fp "$tmp/good-vendor/"*.json "$vendor/"

collector_out="$tmp/collector-output.txt"
MODDIR="$mod" \
ID=pixel-10-pro-xl-thermal-fix \
THERMAL_ADB_ROOT="$adb" \
THERMAL_DATA_ROOT="$data" \
THERMAL_VENDOR_DIR="$vendor" \
THERMAL_DOWNLOAD_DIR="$download" \
THERMAL_DEVICE=blazer \
THERMAL_ANDROID=17 \
THERMAL_BUILD_ID=CP2A.260705.006 \
THERMAL_ROOT_IMPL=fixture \
  sh "$mod/tools/bootguard/collect-debug.sh" > "$collector_out"

debug_zip="$(sed -n 's/^Created: //p' "$collector_out" | tail -n 1)"
test -s "$debug_zip" || fail 57 collector_zip_missing
test ! -e "$debug_zip.sha256" || fail 58 collector_sidecar_created
grep -q '^ZIP_SHA256=[0-9a-f]\{64\}$' "$collector_out" ||
  fail 59 collector_sha_not_printed

unzip -l "$debug_zip" > "$tmp/zip-list.txt"
for member in \
  manifests/source-manifest.tsv \
  manifests/patch-manifest.tsv \
  reports/module-validation_report.json \
  source-cache/thermal_info_config.json \
  module-overlay/thermal_info_config.json \
  vendor-active/thermal_info_config.json \
  polling_matrix.tsv \
  compat_check.txt \
  status_collect.txt; do
  grep -q "$member" "$tmp/zip-list.txt" || fail 60 "collector_member_missing=$member"
done

git -C "$repo" diff --check

printf '%s\n' "PASS controlled_files=base+charge+throttling"
printf '%s\n' "PASS exact_build_manifest_gate=yes"
printf '%s\n' "PASS source_cache_manifest_verify=yes"
printf '%s\n' "PASS patch_manifest_report_verify=yes"
printf '%s\n' "PASS active_polling_value_verify=yes"
printf '%s\n' "PASS test6_false_green_regression_blocked=yes"
printf '%s\n' "PASS unsupported_build_thermal_disabled_safe=yes"
printf '%s\n' "PASS status_requires_active_values=yes"
printf '%s\n' "PASS collector_dynamic_cache_and_manifests=yes"
printf '%s\n' "PASS collector_sidecar_absent=yes"
printf '%s\n' "RESULT: V2_DYNAMIC_OBSERVABILITY_VERIFY_DONE rc=0"
