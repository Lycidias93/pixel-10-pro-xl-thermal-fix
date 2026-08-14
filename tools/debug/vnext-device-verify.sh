#!/system/bin/sh
# Repository-owned, collect-all vNext device verifier.
# Usage: sh tools/debug/vnext-device-verify.sh baseline|post-disable|post-reenable
# The verifier self-enters Magisk/root when invoked from Termux.

ID="pixel-10-pro-xl-thermal-fix"
ROOT_PHASE=0
if [ "${1:-}" = --root ]; then
  ROOT_PHASE=1
  PHASE="${2:-baseline}"
else
  PHASE="${1:-baseline}"
fi
case "$0" in /*) SELF="$0" ;; *) SELF="$(pwd)/$0" ;; esac
MODDIR="${MODDIR:-/data/adb/modules/$ID}"
DATA_ROOT="${THERMAL_DATA_ROOT:-/data/adb/$ID}"
CONFIG_FILE="$DATA_ROOT/config.env"
MODULE_PROP="$MODDIR/module.prop"
HEALTH="$MODDIR/health.log"
BOOTLOG="$MODDIR/guard/bootguard.log"
LMKD_STATE="$DATA_ROOT/lmkd-reload.env"
COLLECTOR="$MODDIR/tools/bootguard/collect-debug.sh"
FAILURES=0
WARNINGS=0
EVIDENCE=complete

say() { printf '%s\n' "$*"; }
fail_check() { FAILURES=$((FAILURES + 1)); say "CHECK_FAIL $*"; }
warn_check() { WARNINGS=$((WARNINGS + 1)); say "CHECK_WARN $*"; }
pass_check() { say "CHECK_PASS $*"; }

kv_file() {
  key="$1"; file="$2"
  [ -r "$file" ] || return 0
  grep -E "^${key}=" "$file" 2>/dev/null | tail -n 1 | sed "s/^${key}=//" | tr -d '\r'
}

cfg_get() { kv_file "$1" "$CONFIG_FILE"; }
prop_get() { /system/bin/getprop "$1" 2>/dev/null | tr -d '\r'; }

stop_now() {
  reason="$1"; code="$2"
  say "evidence_collection=partial"
  say "verdict=stop"
  say "failure_count=$FAILURES"
  say "warning_count=$WARNINGS"
  say "RESULT: PIXEL_THERMAL_VNEXT_DEVICE_VERIFY_STOP phase=$PHASE reason=$reason workflow_exit_code=$code"
  exit "$code"
}

case "$PHASE" in baseline|post-disable|post-reenable) ;; *) stop_now invalid_phase 2 ;; esac

say "task=pixel_thermal_vnext_device_verify"
say "verifier_version=v2"
say "phase=$PHASE"
say "mutation_allowed=evidence_files_only"
say "module_config_mutation=no"
say "network_change=no"

if [ "$ROOT_PHASE" != 1 ] && [ "$(id -u 2>/dev/null || printf 1)" != 0 ]; then
  SU_BIN="$(command -v su 2>/dev/null || true)"
  if [ -z "$SU_BIN" ] || [ ! -x "$SU_BIN" ]; then
    for candidate in /data/data/com.termux/files/usr/bin/su /system/bin/su /system/xbin/su /sbin/su /debug_ramdisk/su; do
      if [ -x "$candidate" ]; then SU_BIN="$candidate"; break; fi
    done
  fi
  [ -n "$SU_BIN" ] && [ -x "$SU_BIN" ] || stop_now su_missing 3
  "$SU_BIN" -c "/system/bin/sh $SELF --root $PHASE"
  root_rc=$?
  exit "$root_rc"
fi
[ "$(id -u 2>/dev/null || printf 1)" = 0 ] || stop_now root_transition_failed 4
say "root_transition=pass"
pass_check root_uid0

battery_level=""
battery_method="none"
if [ -x /system/bin/dumpsys ]; then
  battery_level="$(/system/bin/dumpsys battery 2>/dev/null | sed -n 's/^[[:space:]]*level: //p' | tail -n 1 | awk 'NF == 1 && $1 ~ /^[0-9]+$/ && $1 >= 0 && $1 <= 100 { print $1 }')"
  [ -n "$battery_level" ] && battery_method=root_dumpsys
fi
if [ -z "$battery_level" ] && [ -x /system/bin/cmd ]; then
  battery_level="$(/system/bin/cmd battery get level 2>/dev/null | awk 'NF == 1 && $1 ~ /^[0-9]+$/ && $1 >= 0 && $1 <= 100 { print $1; exit }')"
  [ -n "$battery_level" ] && battery_method=root_cmd
fi
if [ -z "$battery_level" ] && [ -r /sys/class/power_supply/battery/capacity ]; then
  battery_level="$(cat /sys/class/power_supply/battery/capacity 2>/dev/null | awk 'NF == 1 && $1 ~ /^[0-9]+$/ && $1 >= 0 && $1 <= 100 { print $1; exit }')"
  [ -n "$battery_level" ] && battery_method=root_sysfs
fi
[ -n "$battery_level" ] || stop_now battery_unavailable 5
say "battery_method=$battery_method"
say "battery_level=$battery_level"
[ "$battery_level" -ge 15 ] 2>/dev/null || stop_now battery_below_15 6
pass_check battery_gate

say "== identity =="
device="$(prop_get ro.product.device)"
android="$(prop_get ro.build.version.release)"
build_id="$(prop_get ro.build.id)"
boot_completed="$(prop_get sys.boot_completed)"
boot_id="$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || printf unknown)"
say "device=$device"
say "android=$android"
say "build_id=$build_id"
say "boot_completed=$boot_completed"
say "boot_id=$boot_id"
[ "$boot_completed" = 1 ] && pass_check boot_completed || fail_check boot_not_completed

if [ -r "$MODULE_PROP" ]; then
  module_version="$(kv_file version "$MODULE_PROP")"
  module_version_code="$(kv_file versionCode "$MODULE_PROP")"
  say "module_version=${module_version:-unknown}"
  say "module_version_code=${module_version_code:-unknown}"
  case "$module_version" in 2.1.0-alpha.3) pass_check alpha3_version ;; *) fail_check "unexpected_module_version=${module_version:-missing}" ;; esac
else
  EVIDENCE=partial
  fail_check module_prop_missing
fi

for flag in disable skip_mount remove; do
  if [ -e "$MODDIR/$flag" ]; then say "$flag=present"; fail_check "module_flag_${flag}_present"; else say "$flag=absent"; pass_check "module_flag_${flag}_absent"; fi
done

say "== boot/runtime evidence =="
if [ -r "$HEALTH" ]; then
  if grep -Fq 'BOOTGUARD_RUNTIME_VERIFICATION=full_pass' "$HEALTH" 2>/dev/null || grep -Fq 'BOOTGUARD_RUNTIME_VERIFICATION=fast_trusted_unchanged_state' "$HEALTH" 2>/dev/null; then pass_check bootguard_runtime_verified; else fail_check bootguard_runtime_verification_missing; fi
  if grep -Fq 'VNEXT_READINESS state=runtime_verified' "$HEALTH" 2>/dev/null; then pass_check vnext_runtime_verified; else fail_check vnext_runtime_verified_missing; fi
else
  EVIDENCE=partial
  fail_check health_log_missing
fi

say "== configured features =="
polling="$(cfg_get THERMAL_POLLING_MODE)"
thermal="$(cfg_get THERMAL_OUTDOOR_PROFILE)"
zram_enabled="$(cfg_get ENABLE_ZRAM_100P)"
zram_ack="$(cfg_get ZRAM_RISK_ACK)"
lmkd_enabled="$(cfg_get LMKD_SWAP_LOW_RELOAD)"
lmkd_ack="$(cfg_get LMKD_SWAP_LOW_RISK_ACK)"
say "thermal_polling_mode=${polling:-unset}"
say "thermal_outdoor_profile=${thermal:-unset}"
say "zram_enabled=${zram_enabled:-unset}"
say "zram_risk_ack=${zram_ack:-unset}"
say "memory_killer_reload=${lmkd_enabled:-unset}"
say "memory_killer_risk_ack=${lmkd_ack:-unset}"

case "$lmkd_enabled:${lmkd_ack:-none}" in
  0:none|0:) memory_killer_mode=stock ;;
  1:explicit_user_reload) memory_killer_mode=experimental_1_percent ;;
  *) memory_killer_mode=incoherent; fail_check memory_killer_config_incoherent ;;
esac
say "memory_killer_mode=$memory_killer_mode"

say "== ZRAM inventory =="
active_zram_count=0
positive_zram_count=0
active_names=""
active_paths=""
module_fstab="$MODDIR/system/vendor/etc/fstab.zram.100p"
module_fstab_device=""
if [ -r "$module_fstab" ]; then
  module_fstab_device="$(awk 'NF && $1 ~ /zram[0-9]+$/ { print $1; exit }' "$module_fstab" 2>/dev/null)"
  say "module_zram_fstab=present"
  say "module_zram_fstab_device=${module_fstab_device:-unparsed}"
else
  say "module_zram_fstab=absent"
fi

if [ -r /proc/swaps ]; then
  swap_list="$(awk 'NR > 1 && $1 ~ /\/zram[0-9]+$/ { print $1 }' /proc/swaps 2>/dev/null)"
  for swapdev in $swap_list; do
    [ -n "$swapdev" ] || continue
    name="${swapdev##*/}"
    case "$name" in zram[0-9]*) ;; *) continue ;; esac
    active_zram_count=$((active_zram_count + 1))
    [ -n "$active_names" ] && active_names="$active_names,$name" || active_names="$name"
    [ -n "$active_paths" ] && active_paths="$active_paths,$swapdev" || active_paths="$swapdev"
    sysfs="/sys/block/$name"
    disksize="unknown"
    comp="unknown"
    if [ -r "$sysfs/disksize" ]; then disksize="$(cat "$sysfs/disksize" 2>/dev/null | tr -d '\r\n ')"; fi
    if [ -r "$sysfs/comp_algorithm" ]; then comp="$(cat "$sysfs/comp_algorithm" 2>/dev/null | tr -d '\r\n')"; fi
    case "$disksize" in ''|0|*[!0-9]*) ;; *) positive_zram_count=$((positive_zram_count + 1)) ;; esac
    say "zram_device=$name swap_path=$swapdev disksize_bytes=$disksize comp_algorithm=$comp"
  done
else
  EVIDENCE=partial
  fail_check proc_swaps_unreadable
fi
say "zram_active_count=$active_zram_count"
say "zram_positive_disksize_count=$positive_zram_count"
say "zram_active_names=${active_names:-none}"
say "zram_active_paths=${active_paths:-none}"
say "prop_mmd_zram_enabled=$(prop_get mmd.zram.enabled)"
say "prop_mmd_zram_size=$(prop_get mmd.zram.size)"
say "prop_vendor_zram_size=$(prop_get vendor.zram.size)"
say "prop_zram_algorithm=$(prop_get mmd.zram.comp_algorithm)"

if [ "$PHASE" = baseline ] || [ "$PHASE" = post-reenable ]; then
  [ "$zram_enabled" = 1 ] && [ "$zram_ack" = explicit_user_enable ] && pass_check zram_config_enabled || fail_check zram_config_not_enabled
  [ -r "$module_fstab" ] && pass_check zram_module_layout_present || fail_check zram_module_layout_missing
  [ "$active_zram_count" -gt 0 ] 2>/dev/null && pass_check zram_swap_present || fail_check zram_swap_absent
  [ "$positive_zram_count" -gt 0 ] 2>/dev/null && pass_check zram_active_disksize_positive || fail_check zram_active_disksize_not_positive
  if [ -n "$module_fstab_device" ] && [ -n "$active_paths" ]; then
    case ",$active_paths," in *",$module_fstab_device,"*) pass_check zram_layout_target_active ;; *) fail_check "zram_layout_target_not_active target=$module_fstab_device active=$active_paths" ;; esac
  fi
  if [ -r "$HEALTH" ] && grep -Fq 'SERVICE_ZRAM_POST_BOOT result=zram_properties_reapplied_no_mmd_restart' "$HEALTH" 2>/dev/null; then pass_check zram_post_boot_reapply; else fail_check zram_post_boot_reapply_missing; fi
else
  [ "$zram_enabled" = 0 ] && pass_check zram_config_disabled || fail_check zram_config_not_disabled
  [ ! -e "$module_fstab" ] && pass_check zram_module_layout_absent || fail_check zram_module_layout_still_present
  case "${lmkd_enabled:-0}:${lmkd_ack:-none}" in 0:none|0:) pass_check memory_killer_forced_off_with_zram ;; *) fail_check memory_killer_not_forced_off_with_zram ;; esac
  if [ -r "$BOOTLOG" ] && grep -Fq 'SERVICE_ZRAM action=skip' "$BOOTLOG" 2>/dev/null; then pass_check zram_service_skipped; else warn_check zram_service_skip_marker_missing; fi
  if [ -r "$HEALTH" ] && grep -Fq 'SERVICE_ZRAM_POST_BOOT result=zram_properties_reapplied_no_mmd_restart' "$HEALTH" 2>/dev/null; then fail_check zram_post_boot_reapply_present_while_disabled; else pass_check zram_post_boot_reapply_absent; fi
  say "stock_zram_runtime_observation=active_count_$active_zram_count positive_count_$positive_zram_count"
fi

say "== Memory Killer runtime =="
if [ -r "$LMKD_STATE" ]; then
  lmkd_state_boot="$(kv_file boot_id "$LMKD_STATE")"
  lmkd_state_result="$(kv_file reload_result "$LMKD_STATE")"
  lmkd_state_detail="$(kv_file detail "$LMKD_STATE")"
  lmkd_state_enabled="$(kv_file config_enabled "$LMKD_STATE")"
  lmkd_state_ack="$(kv_file risk_ack "$LMKD_STATE")"
  lmkd_state_after="$(kv_file property_after "$LMKD_STATE")"
  lmkd_state_writer="$(kv_file property_writer "$LMKD_STATE")"
  lmkd_state_service="$(kv_file lmkd_service_after "$LMKD_STATE")"
  say "memory_killer_state_boot_id=${lmkd_state_boot:-missing}"
  say "memory_killer_reload_result=${lmkd_state_result:-missing}"
  say "memory_killer_detail=${lmkd_state_detail:-missing}"
  say "memory_killer_property_after=${lmkd_state_after:-unset}"
  say "memory_killer_property_writer=${lmkd_state_writer:-none}"
  say "memory_killer_service_after=${lmkd_state_service:-unknown}"
  if [ "$PHASE" = post-disable ]; then
    case "$lmkd_state_result:$lmkd_state_detail" in disabled:stock_policy_selected) pass_check memory_killer_stock_evidence ;; restore_deferred:*) warn_check memory_killer_restore_deferred ;; *) warn_check "memory_killer_disabled_evidence_unexpected result=${lmkd_state_result:-missing} detail=${lmkd_state_detail:-missing}" ;; esac
  elif [ "$memory_killer_mode" = experimental_1_percent ]; then
    [ "$lmkd_state_boot" = "$boot_id" ] && pass_check memory_killer_same_boot || fail_check memory_killer_evidence_wrong_boot
    [ "$lmkd_state_result" = success ] && pass_check memory_killer_reload_success || fail_check memory_killer_reload_not_success
    [ "$lmkd_state_enabled" = 1 ] && [ "$lmkd_state_ack" = explicit_user_reload ] && pass_check memory_killer_config_evidence || fail_check memory_killer_config_evidence_invalid
    [ "$lmkd_state_after" = 1 ] && [ "$(prop_get ro.lmk.swap_free_low_percentage)" = 1 ] && pass_check memory_killer_property_1 || fail_check memory_killer_property_not_1
    case "$lmkd_state_writer" in magisk_resetprop|resetprop_rs_fallback) pass_check memory_killer_property_writer ;; *) fail_check memory_killer_property_writer_invalid ;; esac
    [ "$lmkd_state_service" = running ] && pass_check memory_killer_service_running || fail_check memory_killer_service_not_running
  elif [ "$memory_killer_mode" = stock ]; then
    [ "$lmkd_state_result" = disabled ] && [ "$lmkd_state_detail" = stock_policy_selected ] && pass_check memory_killer_stock_evidence || warn_check memory_killer_stock_evidence_not_current
  fi
else
  EVIDENCE=partial
  warn_check memory_killer_evidence_missing
fi

say "== Feature Status =="
if [ -s "$MODDIR/tools/debug/status-cached-print.sh" ]; then
  MODDIR="$MODDIR" /system/bin/sh "$MODDIR/tools/debug/status-cached-print.sh" || warn_check feature_status_failed
elif [ -s "$MODDIR/tools/debug/status-lib.sh" ]; then
  MODDIR="$MODDIR" /system/bin/sh "$MODDIR/tools/debug/status-lib.sh" print || warn_check feature_status_failed
else
  EVIDENCE=partial
  warn_check feature_status_helper_missing
fi

say "== Support Snapshot =="
support_path=""
if [ -s "$COLLECTOR" ]; then
  collector_log="/data/local/tmp/pixel_thermal_vnext_device_verify_$$.collector.log"
  thermal_arg="${thermal:-stock}"
  MODDIR="$MODDIR" /system/bin/sh "$COLLECTOR" "device_verify_$PHASE" "$thermal_arg" unknown alpha3_device_test > "$collector_log" 2>&1
  collector_rc=$?
  cat "$collector_log" 2>/dev/null || true
  support_path="$(sed -n 's/^Created: //p' "$collector_log" 2>/dev/null | tail -n 1 | tr -d '\r')"
  if [ "$collector_rc" -eq 0 ] && grep -Fq 'RESULT: PIXEL_THERMAL_PACKAGED_DEBUG_DONE outcome=success workflow_exit_code=0' "$collector_log" 2>/dev/null && [ -s "$support_path" ]; then
    say "support_snapshot=$support_path"
    say "support_snapshot_sha256=$(sha256sum "$support_path" 2>/dev/null | awk '{print $1}')"
    pass_check support_snapshot
  else
    EVIDENCE=partial
    fail_check "support_snapshot_failed rc=$collector_rc"
  fi
  rm -f "$collector_log" 2>/dev/null || true
else
  EVIDENCE=partial
  fail_check support_collector_missing
fi

verdict=pass
[ "$FAILURES" -eq 0 ] || verdict=fail
say "evidence_collection=$EVIDENCE"
say "verdict=$verdict"
say "failure_count=$FAILURES"
say "warning_count=$WARNINGS"
say "module_config_mutation=no"
say "network_change=no"
if [ "$verdict" = pass ]; then
  say "RESULT: PIXEL_THERMAL_VNEXT_DEVICE_VERIFY_PASS phase=$PHASE workflow_exit_code=0"
  exit 0
fi
say "RESULT: PIXEL_THERMAL_VNEXT_DEVICE_VERIFY_FAIL phase=$PHASE failure_count=$FAILURES warning_count=$WARNINGS workflow_exit_code=1"
exit 1
