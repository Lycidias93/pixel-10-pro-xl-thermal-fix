#!/usr/bin/env bash
set -Eeuo pipefail

repo="${1:-$(cd "$(dirname "$0")/.." && pwd)}"

fail() {
  code="$1"
  shift
  printf '%s\n' "FAIL $*"
  printf '%s\n' "RESULT: V2_DYNAMIC_SAFETY_VERIFY_FAIL rc=$code"
  ( exit "$code" )
}

for cmd in bash sh python3 sha256sum find sort awk sed grep cmp cp mktemp; do
  command -v "$cmd" >/dev/null 2>&1 || fail 20 "missing_command=$cmd"
done

patcher="$repo/tools/core/patch-thermal.sh"
helper="$repo/tools/core/supported-build.sh"
action="$repo/action.sh"
customize="$repo/customize.sh"
autoswitch="$repo/tools/core/auto-profile-switch.sh"
install_overlay="$repo/tools/core/install-thermal-overlay.sh"
finalize="$repo/tools/install-finalize.sh"
supported="$repo/supported_versions.json"

for file in "$patcher" "$helper" "$action" "$customize" "$autoswitch" "$install_overlay" "$finalize" "$supported"; do
  test -s "$file" || fail 21 "missing_file=$file"
done
for file in "$patcher" "$helper" "$action" "$customize" "$autoswitch" "$install_overlay" "$finalize"; do
  sh -n "$file" || fail 22 "shell_syntax=$file"
done
python3 -m json.tool "$supported" >/dev/null || fail 23 supported_versions_json_invalid

test "$(git -C "$repo" ls-files 'profiles/*' | wc -l | tr -d ' ')" = 0 ||
  fail 24 static_profiles_reintroduced

grep -q 'thermal_info_config.json' "$patcher" || fail 25 base_missing
grep -q 'thermal_info_config_charge.json' "$patcher" || fail 26 charge_missing
grep -q '"PollingDelay"\[\[:space:\]\]\*:\[\[:space:\]\]\*300000' "$patcher" ||
  fail 27 whitespace_tolerant_replacement_missing
grep -q 'patched_source_5000_rejected' "$patcher" || fail 28 patched_source_rejection_missing
grep -q 'target_atomic_promotion_failed' "$patcher" || fail 29 atomic_promotion_missing
grep -q 'thermal_json_tolerant_validate "$output_file"' "$patcher" || fail 30 output_json_validation_missing
grep -q 'source-manifest.tsv' "$patcher" || fail 31 source_manifest_missing
grep -q 'unallowed_byte_change' "$patcher" || fail 32 allowed_diff_gate_missing
grep -q 'thermal_supported_refresh_for_current' "$action" || fail 33 immutable_refresh_missing
grep -q 'SUPPORTED_REFRESH_COMMIT' "$helper" || fail 34 refresh_provenance_missing
grep -q 'THERMAL_INSTALL_ENABLED=0' "$customize" || fail 35 unsupported_install_guard_missing
! grep -q 'Installation will proceed' "$customize" || fail 36 unsafe_install_warning_still_present
! grep -q 'CANARY_DIAGNOSTIC_NO_OVERLAY' "$customize" || fail 37 diagnostic_canary_block_still_present
grep -q 'thermal_only_disabled' "$autoswitch" || fail 38 zram_preserving_unsupported_guard_missing

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mod="$tmp/module"
data="$tmp/data"
source="$tmp/source"
mkdir -p "$mod/tools/core" "$mod/system/vendor/etc" "$mod/guard" "$data" "$source"
cp -fp "$patcher" "$helper" "$mod/tools/core/"
chmod 0755 "$mod/tools/core/"*.sh
printf '%s\n' keep-zram > "$mod/system/vendor/etc/fstab.zram.100p"

make_json() {
  file="$1"
  delay="$2"
  name="$3"
  spacing="$4"
  {
    printf '%s\n' '{'
    printf '%s\n' '  "Sensors": ['
    printf '%s\n' '    {'
    printf '      "Name": "%s",\n' "$name"
    printf '      "PollingDelay"%s%s,\n' "$spacing" "$delay"
    printf '%s\n' '      "HotThreshold": ["NAN", 40, 50]'
    printf '%s\n' '    }'
    printf '%s\n' '  ]'
    printf '%s\n' '}'
  } > "$file"
}

make_json "$source/thermal_info_config.json" 300000 VIRTUAL-SKIN ' : '
make_json "$source/thermal_info_config_aa_throttling.json" 300000 OTHER '    :    '
make_json "$source/thermal_info_config_bg_tasks_throttling.json" 300000 OTHER ':'
make_json "$source/thermal_info_config_charge.json" 300000 OTHER ' :'
make_json "$source/thermal_info_config_earlywarnings.json" 300000 OTHER ': '
make_json "$source/thermal_info_config_lpm.json" 300000 OTHER '  :  '
make_json "$source/thermal_info_config_stats.json" 300000 OTHER ' :   '
make_json "$source/thermal_info_config_throttling.json" 300000 VIRTUAL-SKIN-HINT '   : '

THERMAL_DATA_ROOT="$data" \
THERMAL_SOURCE_DIR="$source" \
THERMAL_DEVICE=blazer \
THERMAL_BUILD_ID=CP2A.260705.006 \
  sh "$mod/tools/core/patch-thermal.sh" mod stock "$mod" > "$tmp/run1.txt"

grep -q '^PATCH_THERMAL=pass$' "$tmp/run1.txt" || fail 39 first_materialization_failed
test "$(find "$mod/system/vendor/etc" -maxdepth 1 -type f -name 'thermal_info_config*.json' | wc -l | tr -d ' ')" = 3 ||
  fail 40 output_inventory_not_3
grep -R '"PollingDelay"[[:space:]]*:[[:space:]]*300000' "$mod/system/vendor/etc"/thermal_info_config*.json >/dev/null 2>&1 &&
  fail 41 source_300000_remains
test "$(grep -R -o '"PollingDelay"[[:space:]]*:[[:space:]]*5000' "$mod/system/vendor/etc"/thermal_info_config*.json | wc -l | tr -d ' ')" = 3 ||
  fail 42 output_5000_count_not_3
test -s "$mod/system/vendor/etc/fstab.zram.100p" || fail 43 nonthermal_file_not_preserved
python3 -m json.tool "$mod/validation_report.json" >/dev/null || fail 44 report_invalid_json
test -s "$mod/guard/patch-manifest.tsv" || fail 45 patch_manifest_missing
test -s "$data/originals/blazer/CP2A.260705.006/vendor/etc/source-manifest.tsv" ||
  fail 46 build_keyed_cache_missing

first_hashes="$tmp/first-hashes.txt"
find "$mod/system/vendor/etc" -maxdepth 1 -type f -name 'thermal_info_config*.json' -print0 |
  sort -z | xargs -0 sha256sum > "$first_hashes"

THERMAL_DATA_ROOT="$data" \
THERMAL_SOURCE_DIR="$mod/system/vendor/etc" \
THERMAL_DEVICE=blazer \
THERMAL_BUILD_ID=CP2A.260705.006 \
  sh "$mod/tools/core/patch-thermal.sh" mod stock "$mod" > "$tmp/run2.txt"

second_hashes="$tmp/second-hashes.txt"
find "$mod/system/vendor/etc" -maxdepth 1 -type f -name 'thermal_info_config*.json' -print0 |
  sort -z | xargs -0 sha256sum > "$second_hashes"
cmp -s "$first_hashes" "$second_hashes" || fail 47 repeated_run_not_idempotent

rm -rf "$data/originals/blazer/CP2A.260705.006"
before_reject="$tmp/before-reject.txt"
find "$mod/system/vendor/etc" -maxdepth 1 -type f -name 'thermal_info_config*.json' -print0 |
  sort -z | xargs -0 sha256sum > "$before_reject"
set +e
THERMAL_DATA_ROOT="$data" \
THERMAL_SOURCE_DIR="$mod/system/vendor/etc" \
THERMAL_DEVICE=blazer \
THERMAL_BUILD_ID=CP2A.260705.006 \
  sh "$mod/tools/core/patch-thermal.sh" mod stock "$mod" > "$tmp/reject.txt" 2>&1
reject_rc="$?"
set -e
test "$reject_rc" -ne 0 || fail 48 patched_source_was_accepted
grep -q 'patched_source_5000_rejected' "$tmp/reject.txt" || fail 49 rejection_reason_missing

after_reject="$tmp/after-reject.txt"
find "$mod/system/vendor/etc" -maxdepth 1 -type f -name 'thermal_info_config*.json' -print0 |
  sort -z | xargs -0 sha256sum > "$after_reject"
cmp -s "$before_reject" "$after_reject" || fail 50 failed_run_changed_target

. "$helper"
thermal_supported_check "$supported" blazer 17 CP2A.260705.006 ||
  fail 51 supported_check_rejected_known_build
thermal_supported_check "$supported" blazer 17 UNSUPPORTED.TEST &&
  fail 52 supported_check_accepted_unknown_build

git -C "$repo" diff --check
printf '%s\n' "PASS static_profiles_absent=yes"
printf '%s\n' "PASS controlled_files=base+charge+throttling"
printf '%s\n' "PASS polling_whitespace_tolerant=yes"
printf '%s\n' "PASS patched_source_fail_closed=yes"
printf '%s\n' "PASS source_cache_build_keyed=yes"
printf '%s\n' "PASS source_inventory_manifest=yes"
printf '%s\n' "PASS allowed_diff_gate=yes"
printf '%s\n' "PASS tolerant_json_validation=yes"
printf '%s\n' "PASS atomic_target_promotion=yes"
printf '%s\n' "PASS repeated_action_idempotent=yes"
printf '%s\n' "PASS unsupported_build_thermal_only_disabled=yes"
printf '%s\n' "PASS canary_diagnostic_forcing_removed=yes"
printf '%s\n' "PASS immutable_supported_refresh_design=yes"
printf '%s\n' "RESULT: V2_DYNAMIC_SAFETY_VERIFY_DONE rc=0"
