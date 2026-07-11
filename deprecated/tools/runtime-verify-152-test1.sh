#!/usr/bin/env sh
set -eu

id="pixel-10-pro-xl-thermal-fix"
moddir="${1:-/data/adb/modules/$id}"

say() {
  printf '%s\n' "$*"
}

say "== runtime verify: 1.5.2-universal-test.1 =="
say "target=$moddir"

[ -d "$moddir" ] || { say "FAIL module_missing"; exit 1; }
[ ! -e "$moddir/remove" ] || { say "FAIL module_remove_pending"; exit 2; }
[ ! -e "$moddir/disable" ] || { say "FAIL module_disabled"; exit 3; }
[ ! -e "$moddir/skip_mount" ] || { say "FAIL module_skip_mount"; exit 4; }
say "PASS module_active_no_disable_remove_skip_mount"

grep -n '^version=1.5.2-universal-test.1$' "$moddir/module.prop"
grep -n '^versionCode=1016201$' "$moddir/module.prop"
say "PASS module_version_test1"

grep -n '"version": "1.5.1-universal.1"' "$moddir/update.json"
grep -n '"versionCode": 1016108' "$moddir/update.json"
say "PASS stable_update_json_unchanged_runtime"

cd "$moddir"

sh tools/cp31-260618005-selection-verify.sh .
sh tools/cp31-260618005-alias-verify.sh .
sh tools/verify-evidence-scope.sh runtime "$moddir"

matrix_log="${TMPDIR:-/data/local/tmp}/pixel_thermal_matrix_152_test1_$$.log"
sh tools/profile-matrix-verify.sh > "$matrix_log"
cat "$matrix_log"
grep -q 'PROFILE_MATRIX_VERIFY_PASS count=83' "$matrix_log"
rm -f "$matrix_log"
sh tools/ui-text-guard.sh 44

sh tools/status-lib.sh update >/dev/null 2>&1 || true
status_log="${TMPDIR:-/data/local/tmp}/pixel_thermal_status_152_test1_$$.log"
sh tools/status-lib.sh print > "$status_log" 2>/dev/null || true
cat "$status_log"

grep -q 'Polling: .*active' "$status_log"
grep -q 'Thermal: .*active' "$status_log"
grep -q 'ZRAM:.*active' "$status_log"
grep -q 'Vendor: match' "$status_log"
grep -q 'Reboot: safe' "$status_log"
rm -f "$status_log"
say "PASS manager_status_active_vendor_match_reboot_safe"

selected="$(cat "$moddir/guard/selected_profile" 2>/dev/null || sed -n 's/^profile=//p' "$moddir/install-state.txt" 2>/dev/null | tail -n 1 || true)"
say "selected_profile=$selected"

build_id="$(getprop ro.build.id 2>/dev/null || true)"
device="$(getprop ro.product.device 2>/dev/null || true)"
say "device=$device"
say "build_id=$build_id"

case "$device:$build_id:$selected" in
  mustang:CP2A.260605.012:mustang-android17-cp2a-cp2a260605012-outdoor-extended)
    say "PASS selected_mustang_cp2a_outdoor_extended_expected"
  ;;
  *:CP31.*:*-android17-cp31-cp31260618005*)
    say "PASS selected_current_cp31_alias"
  ;;
  *)
    say "WARN selected_profile_not_in_primary_runtime_evidence device=$device build=$build_id selected=$selected"
  ;;
esac

for f in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
  [ -s "$moddir/system/vendor/etc/$f" ] || { say "FAIL active_overlay_file_missing $f"; exit 5; }
  say "PASS active_overlay_file_present $f"
done

zram_swaps="$(grep -E 'zram0|/dev/block/zram' /proc/swaps 2>/dev/null || true)"
zram_size="$(cat /sys/block/zram0/disksize 2>/dev/null || echo 0)"
say "zram_swaps=$zram_swaps"
say "zram_disksize=$zram_size"
[ -n "$zram_swaps" ] || { say "FAIL zram_swap_missing"; exit 6; }
[ "$zram_size" != "0" ] || { say "FAIL zram_disksize_zero"; exit 7; }
say "PASS zram_runtime_active_nonzero"

grep -n 'Update Ch' "$moddir/tools/action-dashboard.sh"
grep -n 'Mode: status only' "$moddir/tools/action-dashboard.sh"
say "PASS advanced_update_channel_status_only_present"

say "RESULT: PIXEL_THERMAL_152_TEST1_RUNTIME_VERIFY_DONE"
