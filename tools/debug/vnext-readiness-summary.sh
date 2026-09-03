#!/system/bin/sh
# Compact read-only vNext support/readiness summary.
set -u

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
ADB_ROOT="${THERMAL_ADB_ROOT:-/data/adb}"
M="${MODDIR:-$ADB_ROOT/modules/$ID}"
GUARD="$M/guard"
COMPAT="$M/tools/bootguard/compat-check-vnext.sh"

DEVICE="${THERMAL_DEVICE:-$(getprop ro.product.device 2>/dev/null || true)}"
ANDROID="${THERMAL_ANDROID:-$(getprop ro.build.version.release 2>/dev/null || true)}"
BUILD_ID="${THERMAL_BUILD_ID:-$(getprop ro.build.id 2>/dev/null || true)}"
[ -n "$DEVICE" ] || DEVICE=unknown
[ -n "$ANDROID" ] || ANDROID=unknown
[ -n "$BUILD_ID" ] || BUILD_ID=unknown

kv() {
  _key="$1"; _file="$2"
  [ -r "$_file" ] || return 0
  sed -n "s/^${_key}=//p" "$_file" 2>/dev/null | tail -n 1 | tr -d '\r'
}

experimental=no
g6_graph=no
case "$DEVICE:$ANDROID" in
  tokay:17|caiman:17|komodo:17|comet:17|tegu:17|stallion:17|cubs:17|grizzly:17|kodiak:17|yogi:17) experimental=yes ;;
esac
case "$DEVICE:$ANDROID" in cubs:17|grizzly:17|kodiak:17|yogi:17) g6_graph=yes ;; esac

ptune_policy=available_guarded
[ "$experimental" = yes ] && ptune_policy=blocked_experimental_platform
polling_policy=stock_or_mod
[ "$g6_graph" = yes ] && polling_policy=stock_only_pending_runtime_evidence

module_version="$(kv version "$M/module.prop")"
module_version_code="$(kv versionCode "$M/module.prop")"
[ -n "$module_version" ] || module_version=missing
[ -n "$module_version_code" ] || module_version_code=missing

TMP="/data/local/tmp/pixel_thermal_readiness.$$"
rm -f "$TMP" 2>/dev/null || true
compat_rc=127
if [ -s "$COMPAT" ]; then
  MODDIR="$M" THERMAL_ADB_ROOT="$ADB_ROOT" THERMAL_DEVICE="$DEVICE" THERMAL_ANDROID="$ANDROID" THERMAL_BUILD_ID="$BUILD_ID" sh "$COMPAT" > "$TMP" 2>&1
  compat_rc=$?
else
  printf '%s\n' 'REASON=compat_helper_missing' > "$TMP"
fi

platform_supported="$(kv PLATFORM_SUPPORTED "$TMP")"
build_evidence="$(kv BUILD_EVIDENCE "$TMP")"
layout_valid="$(kv DYNAMIC_LAYOUT_VALID "$TMP")"
layout_family="$(kv DYNAMIC_LAYOUT_FAMILY "$TMP")"
controlled_files="$(kv DYNAMIC_CONTROLLED_FILES "$TMP")"
source_polling_total="$(kv DYNAMIC_SOURCE_POLLING_TOTAL "$TMP")"
materialization_valid="$(kv DYNAMIC_MATERIALIZATION_VALID "$TMP")"
active_match="$(kv DYNAMIC_ACTIVE_MATCH "$TMP")"
active_polling_valid="$(kv DYNAMIC_ACTIVE_POLLING_VALID "$TMP")"
safe_to_reboot="$(kv SAFE_TO_REBOOT "$TMP")"
reason="$(kv REASON "$TMP")"

[ -n "$platform_supported" ] || platform_supported=unknown
[ -n "$build_evidence" ] || build_evidence=unknown
[ -n "$layout_valid" ] || layout_valid=unknown
[ -n "$layout_family" ] || layout_family=unknown
[ -n "$controlled_files" ] || controlled_files=unknown
[ -n "$source_polling_total" ] || source_polling_total=unknown
[ -n "$materialization_valid" ] || materialization_valid=unknown
[ -n "$active_match" ] || active_match=unknown
[ -n "$active_polling_valid" ] || active_polling_valid=unknown
[ -n "$safe_to_reboot" ] || safe_to_reboot=unknown
[ -n "$reason" ] || reason=compat_output_incomplete

readiness_state=needs_attention
runtime_evidence=pending
next_action=inspect_support_snapshot
if [ "$safe_to_reboot" = yes ] && [ "$reason" = active_dynamic_overlay_verified ]; then
  readiness_state=runtime_verified
  runtime_evidence=postboot_active_overlay_verified
  next_action=report_runtime_verified_result
elif [ "$safe_to_reboot" = yes ] && [ "$reason" = dynamic_overlay_valid_reboot_pending ]; then
  readiness_state=install_ready_reboot_pending
  runtime_evidence=materialized_local_validation_only
  next_action=reboot_then_collect_runtime_status
elif [ "$safe_to_reboot" = yes ]; then
  readiness_state=safe_nonactive_state
  runtime_evidence=nonactive_safe_state
  next_action=review_reason_before_enabling_thermal
fi

printf '%s\n' 'schema=pixel-thermal-vnext-readiness-v1'
printf '%s\n' "device=$DEVICE"
printf '%s\n' "android=$ANDROID"
printf '%s\n' "build_id=$BUILD_ID"
printf '%s\n' "module_version=$module_version"
printf '%s\n' "module_version_code=$module_version_code"
printf '%s\n' "experimental_platform=$experimental"
printf '%s\n' "g6_include_graph_platform=$g6_graph"
printf '%s\n' "polling_policy=$polling_policy"
printf '%s\n' "ptune_override_policy=$ptune_policy"
printf '%s\n' "platform_supported=$platform_supported"
printf '%s\n' "build_evidence=$build_evidence"
printf '%s\n' "layout_valid=$layout_valid"
printf '%s\n' "layout_family=$layout_family"
printf '%s\n' "controlled_files=$controlled_files"
printf '%s\n' "source_polling_total=$source_polling_total"
printf '%s\n' "materialization_valid=$materialization_valid"
printf '%s\n' "active_match=$active_match"
printf '%s\n' "active_polling_valid=$active_polling_valid"
printf '%s\n' "safe_to_reboot=$safe_to_reboot"
printf '%s\n' "compat_reason=$reason"
printf '%s\n' "compat_exit_code=$compat_rc"
printf '%s\n' "readiness_state=$readiness_state"
printf '%s\n' "runtime_evidence=$runtime_evidence"
printf '%s\n' "next_action=$next_action"

rm -f "$TMP" 2>/dev/null || true
exit 0
