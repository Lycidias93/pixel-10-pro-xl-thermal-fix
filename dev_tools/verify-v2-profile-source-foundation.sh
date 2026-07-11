#!/usr/bin/env bash
set -Eeuo pipefail

repo="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
map="$repo/profiles/profile-map.tsv"
inventory="$repo/profiles/manifests/thermal-stock-inventory.tsv"
resolver="$repo/tools/core/profile-resolver.sh"
source_verify="$repo/tools/core/profile-source-verify.sh"
patcher="$repo/tools/core/patch-thermal.sh"
action_dashboard="$repo/tools/action-dashboard.sh"
auto_switch="$repo/tools/core/auto-profile-switch.sh"

fail() {
  code="$1"
  shift
  printf '%s\n' "FAIL $*"
  printf '%s\n' "RESULT: V2_PROFILE_SOURCE_FOUNDATION_VERIFY_FAIL rc=$code"
  ( exit "$code" )
}

for cmd in bash sh python3 sha256sum find sort awk sed grep cmp mktemp cp; do
  command -v "$cmd" >/dev/null 2>&1 || fail 20 "missing_command=$cmd"
done

for file in "$map" "$inventory" "$resolver" "$source_verify" "$patcher" "$action_dashboard" "$auto_switch"; do
  test -s "$file" || fail 21 "missing_file=$file"
done

map_rows="$(awk 'NR>1{n++} END{print n+0}' "$map")"
json_count="$(find "$repo/profiles" -type f -path '*/system/vendor/etc/thermal_info_config*.json' | wc -l | tr -d ' ')"
inventory_rows="$(awk 'NR>1{n++} END{print n+0}' "$inventory")"
[[ "$map_rows" == 8 ]] || fail 22 "map_rows=$map_rows expected=8"
[[ "$json_count" == 78 ]] || fail 23 "json_count=$json_count expected=78"
[[ "$inventory_rows" == 78 ]] || fail 24 "inventory_rows=$inventory_rows expected=78"

python3 -m json.tool "$repo/profiles/profile-index.json" >/dev/null
python3 -m json.tool "$repo/profiles/manifests/source-bundles.json" >/dev/null
python3 -m json.tool "$repo/profiles/manifests/blazer-cp2a260705006-polling-gate.json" >/dev/null
python3 -m json.tool "$repo/supported_versions.json" >/dev/null
grep -q 'cfg_get THERMAL_DISABLED' "$action_dashboard" || fail 38 action_disabled_guard_missing
grep -q 'cfg_set THERMAL_DISABLED 0' "$auto_switch" || fail 39 ota_disabled_state_clear_missing

for file in \
  "$repo/customize.sh" \
  "$repo/tools/action-dashboard.sh" \
  "$repo/tools/install-finalize.sh" \
  "$repo/tools/core/profile-resolver.sh" \
  "$repo/tools/core/profile-source-verify.sh" \
  "$repo/tools/core/patch-thermal.sh" \
  "$repo/tools/core/install-thermal-overlay.sh" \
  "$repo/tools/core/auto-profile-switch.sh"; do
  sh -n "$file" || fail 25 "shell_syntax=$file"
done

before_profiles="$(mktemp)"
after_profiles="$(mktemp)"
find "$repo/profiles" -type f -print0 | sort -z | xargs -0 sha256sum > "$before_profiles"

while IFS=$'\t' read -r device android build_id channel family slug rel count polling polling_files bundle; do
  [[ "$device" == device ]] && continue
  sh "$source_verify" "$repo" "$device" "$android" "$build_id" >/dev/null || fail 26 "source_verify=$device/$build_id"
done < "$map"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp" "$before_profiles" "$after_profiles"' EXIT
mod="$tmp/module"
data="$tmp/data"
mkdir -p "$mod/tools" "$mod/system/vendor/etc" "$data"
cp -a "$repo/profiles" "$mod/profiles"
cp -a "$repo/tools/core" "$mod/tools/core"
printf '%s\n' 'test-fstab-preserve' > "$mod/system/vendor/etc/fstab.zram.100p"

lookup_profile() {
  local want_device="$1"
  local want_build="$2"
  awk -F '\t' -v d="$want_device" -v b="$want_build" 'NR>1 && $1==d && $3==b {print $7 "\t" $9; found++} END{if(found!=1) exit 1}' "$map"
}

run_patch_case() {
  local device="$1"
  local build_id="$2"
  local polling_mode="$3"
  local outdoor_mode="$4"
  local verify_stock_identity="$5"
  local row rel expected_poll source_etc source_file name replacements remaining output5000 hot_values
  row="$(lookup_profile "$device" "$build_id")" || fail 27 "profile_lookup=$device/$build_id"
  IFS=$'\t' read -r rel expected_poll <<< "$row"

  rm -rf "$mod/system/vendor/etc" "$data"
  mkdir -p "$mod/system/vendor/etc" "$data"
  printf '%s\n' 'test-fstab-preserve' > "$mod/system/vendor/etc/fstab.zram.100p"
  THERMAL_DATA_ROOT="$data" sh "$mod/tools/core/patch-thermal.sh" "$polling_mode" "$outdoor_mode" "$mod" "$device" 17 "$build_id" >/dev/null || fail 28 "patch=$device/$build_id/$polling_mode/$outdoor_mode"
  [[ "$(cat "$mod/system/vendor/etc/fstab.zram.100p")" == test-fstab-preserve ]] || fail 29 "fstab_not_preserved=$device/$build_id"
  python3 -m json.tool "$mod/validation_report.json" >/dev/null || fail 40 "module_validation_report_invalid=$device/$build_id"
  python3 -m json.tool "$data/validation_report.json" >/dev/null || fail 41 "data_validation_report_invalid=$device/$build_id"
  cmp -s "$mod/validation_report.json" "$data/validation_report.json" || fail 42 "validation_report_copy_mismatch=$device/$build_id"
  grep -q '"validation": "passed"' "$mod/validation_report.json" || fail 43 "validation_report_pass_missing=$device/$build_id"

  if [[ "$verify_stock_identity" == yes ]]; then
    source_etc="$mod/$rel/system/vendor/etc"
    for source_file in "$source_etc"/thermal_info_config*.json; do
      name="${source_file##*/}"
      cmp -s "$source_file" "$mod/system/vendor/etc/$name" || fail 30 "stock_not_identical=$device/$build_id/$name"
    done
  fi

  replacements="$(awk -F '\t' 'NR>1{s+=$5} END{print s+0}' "$mod/guard/patch-manifest.tsv")"
  remaining="$(awk -F '\t' 'NR>1{s+=$6} END{print s+0}' "$mod/guard/patch-manifest.tsv")"
  output5000="$(awk -F '\t' 'NR>1{s+=$7} END{print s+0}' "$mod/guard/patch-manifest.tsv")"
  hot_values="$(awk -F '\t' 'NR>1{s+=$8} END{print s+0}' "$mod/guard/patch-manifest.tsv")"

  if [[ "$polling_mode" == mod ]]; then
    [[ "$replacements" == "$expected_poll" ]] || fail 31 "replacement_total=$device/$build_id/$replacements expected=$expected_poll"
    [[ "$remaining" == 0 ]] || fail 32 "remaining_300000=$device/$build_id/$remaining"
    [[ "$output5000" == "$expected_poll" ]] || fail 33 "output_5000=$device/$build_id/$output5000 expected=$expected_poll"
  else
    [[ "$replacements" == 0 ]] || fail 34 "stock_replacements=$device/$build_id/$replacements"
    [[ "$output5000" == 0 ]] || fail 35 "stock_output_5000=$device/$build_id/$output5000"
  fi
  if [[ "$outdoor_mode" != stock ]]; then
    [[ "$hot_values" -gt 0 ]] || fail 36 "outdoor_hotthreshold_changes_missing=$device/$build_id"
  fi
}

run_patch_case frankel ZP11.260618.005 stock stock yes
run_patch_case blazer CP2A.260705.006 mod stock no
run_patch_case rango CP2A.260705.006 mod stock no
run_patch_case mustang CP2A.260705.006 mod outdoor-safe no

find "$repo/profiles" -type f -print0 | sort -z | xargs -0 sha256sum > "$after_profiles"
cmp -s "$before_profiles" "$after_profiles" || fail 37 profiles_modified_by_verify

git -C "$repo" diff --check
printf '%s\n' "PASS profile_map_rows=$map_rows"
printf '%s\n' "PASS thermal_json_count=$json_count"
printf '%s\n' "PASS inventory_rows=$inventory_rows"
printf '%s\n' "PASS exact_profiles_verified=8"
printf '%s\n' "PASS stock_materialization_byte_identical=frankel/ZP11.260618.005"
printf '%s\n' "PASS polling_materialization_verified=blazer+rango+mustang/CP2A.260705.006"
printf '%s\n' "PASS outdoor_safe_materialization_verified=mustang/CP2A.260705.006"
printf '%s\n' "PASS validation_report_compatibility=yes"
printf '%s\n' "PASS upstream_f21_action_guards_preserved=yes"
printf '%s\n' "PASS ota_disabled_state_clear=yes"
printf '%s\n' "RESULT: V2_PROFILE_SOURCE_FOUNDATION_VERIFY_DONE rc=0"
