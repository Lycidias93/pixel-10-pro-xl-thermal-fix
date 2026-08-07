#!/system/bin/sh
# Layout-aware vNext compatibility verifier for experimental Pixel 9 / Pixel 10a support.
set -u

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
ADB_ROOT="${THERMAL_ADB_ROOT:-/data/adb}"
M="${MODDIR:-$ADB_ROOT/modules/$ID}"
DATA_ROOT="${THERMAL_DATA_ROOT:-$ADB_ROOT/$ID}"
CFG="$DATA_ROOT/config.env"
VENDOR_DIR="${THERMAL_VENDOR_DIR:-/vendor/etc}"
OVERLAY_DIR="$M/system/vendor/etc"
GUARD_DIR="$M/guard"
SUPPORTED_JSON="$M/supported_versions.json"
SUPPORTED_HELPER="$M/tools/core/supported-build.sh"
LAYOUT_HELPER="$M/tools/core/thermal-layout.sh"
LAYOUT_ENV="$GUARD_DIR/thermal-layout.env"

DEVICE="${THERMAL_DEVICE:-$(getprop ro.product.device 2>/dev/null || true)}"
ANDROID="${THERMAL_ANDROID:-$(getprop ro.build.version.release 2>/dev/null || true)}"
BUILD_ID="${THERMAL_BUILD_ID:-$(getprop ro.build.id 2>/dev/null || true)}"
[ -n "$DEVICE" ] || DEVICE=unknown
[ -n "$ANDROID" ] || ANDROID=unknown
[ -n "$BUILD_ID" ] || BUILD_ID=unknown
BUILD_SLUG="$(printf '%s' "$BUILD_ID" | tr -c 'A-Za-z0-9._-' '_')"
CACHE_DIR="$DATA_ROOT/originals/$DEVICE/$BUILD_SLUG/vendor/etc"
SOURCE_MANIFEST="$CACHE_DIR/source-manifest.tsv"
PATCH_MANIFEST="$GUARD_DIR/patch-manifest.tsv"
REPORT_MODULE="$M/validation_report.json"
REPORT_DATA="$DATA_ROOT/validation_report.json"

kv_get() {
  _k="$1"; _f="$2"
  [ -r "$_f" ] || return 0
  sed -n "s/^${_k}=//p" "$_f" | tail -n 1 | tr -d '\r'
}

cfg_get() { kv_get "$1" "$CFG"; }
flag() { [ -e "$1" ] && printf '%s\n' present || printf '%s\n' absent; }
sha_file() { [ -s "$1" ] && sha256sum "$1" 2>/dev/null | awk '{print $1}' || true; }
bytes_file() { [ -s "$1" ] && wc -c < "$1" 2>/dev/null | tr -d ' ' || true; }
count_polling_value() {
  _f="$1"; _v="$2"
  [ -r "$_f" ] || { printf '%s\n' 0; return 0; }
  awk -v value="$_v" '{ line=$0; p="\"PollingDelay\"[[:space:]]*:[[:space:]]*" value "([^0-9]|$)"; while (match(line,p)) { n++; line=substr(line,RSTART+RLENGTH) } } END { print n+0 }' "$_f"
}

platform_supported=no
build_evidence=unsupported_platform
if [ -r "$SUPPORTED_HELPER" ] && [ -r "$SUPPORTED_JSON" ]; then
  . "$SUPPORTED_HELPER"
  if thermal_supported_check "$SUPPORTED_JSON" "$DEVICE" "$ANDROID" "$BUILD_ID"; then
    platform_supported=yes
    build_evidence="$(thermal_build_evidence_state "$SUPPORTED_JSON" "$DEVICE" "$ANDROID" "$BUILD_ID")"
  fi
fi

layout_valid=no
layout_family=unsupported
layout_files=""
layout_count=0
if [ -r "$LAYOUT_HELPER" ]; then
  . "$LAYOUT_HELPER"
  if thermal_layout_load_env "$LAYOUT_ENV"; then
    layout_valid=yes
    layout_family="$THERMAL_LAYOUT_FAMILY"
    layout_files="$THERMAL_LAYOUT_FILES"
    layout_count="$THERMAL_LAYOUT_COUNT"
  fi
fi

source_manifest_valid=yes
source_cache_valid=yes
source_rows=0
source_polling_total=0
if [ "$layout_valid" != yes ] || [ ! -s "$SOURCE_MANIFEST" ]; then
  source_manifest_valid=no
  source_cache_valid=no
else
  _tab="$(printf '\t')"
  while IFS="$_tab" read -r file expected_sha expected_bytes expected_polling extra; do
    [ "$file" = file ] && continue
    [ -n "$file" ] || continue
    source_rows=$((source_rows + 1))
    case " $layout_files " in *" $file "*) ;; *) source_manifest_valid=no; source_cache_valid=no; continue ;; esac
    [ -z "$extra" ] || source_manifest_valid=no
    src="$CACHE_DIR/$file"
    [ -s "$src" ] || { source_cache_valid=no; continue; }
    [ "$(sha_file "$src")" = "$expected_sha" ] || source_cache_valid=no
    [ "$(bytes_file "$src")" = "$expected_bytes" ] || source_cache_valid=no
    [ "$(count_polling_value "$src" 300000)" = "$expected_polling" ] || source_cache_valid=no
    [ "$(count_polling_value "$src" 5000)" = 0 ] || source_cache_valid=no
    case "$expected_polling" in ''|*[!0-9]*) source_manifest_valid=no; source_cache_valid=no ;; *) source_polling_total=$((source_polling_total + expected_polling)) ;; esac
  done < "$SOURCE_MANIFEST"
  [ "$source_rows" -eq "$layout_count" ] 2>/dev/null || source_manifest_valid=no
fi
[ "$source_manifest_valid" = yes ] || source_cache_valid=no

polling_mode="$(cfg_get THERMAL_POLLING_MODE)"; [ -n "$polling_mode" ] || polling_mode=mod
outdoor_profile="$(cfg_get THERMAL_OUTDOOR_PROFILE)"; [ -n "$outdoor_profile" ] || outdoor_profile=stock

patch_manifest_valid=yes
patch_rows=0
patch_source_polling_total=0
patch_replacement_total=0
overlay_polling_300000=0
overlay_polling_5000=0
if [ "$layout_valid" != yes ] || [ ! -s "$PATCH_MANIFEST" ]; then
  patch_manifest_valid=no
else
  _tab="$(printf '\t')"
  while IFS="$_tab" read -r file source_sha output_sha source_polling replacements output300000 output5000 allowed extra; do
    [ "$file" = file ] && continue
    [ -n "$file" ] || continue
    patch_rows=$((patch_rows + 1))
    case " $layout_files " in *" $file "*) ;; *) patch_manifest_valid=no; continue ;; esac
    [ -z "$extra" ] || patch_manifest_valid=no
    [ "$allowed" = yes ] || patch_manifest_valid=no
    out="$OVERLAY_DIR/$file"
    [ -s "$out" ] || { patch_manifest_valid=no; continue; }
    [ "$(sha_file "$out")" = "$output_sha" ] || patch_manifest_valid=no
    [ "$(count_polling_value "$out" 300000)" = "$output300000" ] || patch_manifest_valid=no
    [ "$(count_polling_value "$out" 5000)" = "$output5000" ] || patch_manifest_valid=no
    case "$source_polling:$replacements:$output300000:$output5000" in *[!0-9:]*|:*|*:) patch_manifest_valid=no; continue ;; esac
    if [ "$polling_mode" = mod ]; then
      [ "$replacements" = "$source_polling" ] || patch_manifest_valid=no
      [ "$output300000" = 0 ] || patch_manifest_valid=no
      [ "$output5000" = "$source_polling" ] || patch_manifest_valid=no
    else
      [ "$replacements" = 0 ] || patch_manifest_valid=no
      [ "$output300000" = "$source_polling" ] || patch_manifest_valid=no
      [ "$output5000" = 0 ] || patch_manifest_valid=no
    fi
    patch_source_polling_total=$((patch_source_polling_total + source_polling))
    patch_replacement_total=$((patch_replacement_total + replacements))
    overlay_polling_300000=$((overlay_polling_300000 + output300000))
    overlay_polling_5000=$((overlay_polling_5000 + output5000))
  done < "$PATCH_MANIFEST"
  [ "$patch_rows" -eq "$layout_count" ] 2>/dev/null || patch_manifest_valid=no
  [ "$patch_source_polling_total" = "$source_polling_total" ] || patch_manifest_valid=no
fi

validation_report_valid=yes
[ -s "$REPORT_MODULE" ] || validation_report_valid=no
[ -s "$REPORT_DATA" ] || validation_report_valid=no
if [ "$validation_report_valid" = yes ]; then
  [ "$(sha_file "$REPORT_MODULE")" = "$(sha_file "$REPORT_DATA")" ] || validation_report_valid=no
  grep -q '"validation"[[:space:]]*:[[:space:]]*"passed"' "$REPORT_MODULE" 2>/dev/null || validation_report_valid=no
  grep -q "\"device\"[[:space:]]*:[[:space:]]*\"$DEVICE\"" "$REPORT_MODULE" 2>/dev/null || validation_report_valid=no
  grep -q "\"build_id\"[[:space:]]*:[[:space:]]*\"$BUILD_ID\"" "$REPORT_MODULE" 2>/dev/null || validation_report_valid=no
fi

module_overlay_ready=yes
overlay_inventory_count=0
if [ "$layout_valid" != yes ]; then
  module_overlay_ready=no
else
  for file in $layout_files; do
    [ -s "$OVERLAY_DIR/$file" ] || module_overlay_ready=no
    overlay_inventory_count=$((overlay_inventory_count + 1))
  done
  [ "$overlay_inventory_count" -eq "$layout_count" ] 2>/dev/null || module_overlay_ready=no
fi

materialization_valid=no
if [ "$platform_supported" = yes ] && [ "$layout_valid" = yes ] && [ "$source_manifest_valid" = yes ] && [ "$source_cache_valid" = yes ] && [ "$patch_manifest_valid" = yes ] && [ "$validation_report_valid" = yes ] && [ "$module_overlay_ready" = yes ]; then
  materialization_valid=yes
fi

active_match=yes
active_checked=0
active_polling_300000=0
active_polling_5000=0
if [ "$layout_valid" != yes ]; then
  active_match=no
else
  for file in $layout_files; do
    mf="$OVERLAY_DIR/$file"; vf="$VENDOR_DIR/$file"
    if [ ! -s "$mf" ] || [ ! -s "$vf" ]; then active_match=no; continue; fi
    active_checked=$((active_checked + 1))
    [ "$(sha_file "$mf")" = "$(sha_file "$vf")" ] || active_match=no
    active_polling_300000=$((active_polling_300000 + $(count_polling_value "$vf" 300000)))
    active_polling_5000=$((active_polling_5000 + $(count_polling_value "$vf" 5000)))
  done
  [ "$active_checked" -eq "$layout_count" ] 2>/dev/null || active_match=no
fi

active_polling_valid=pending
if [ "$active_match" = yes ]; then
  active_polling_valid=yes
  if [ "$polling_mode" = mod ]; then
    [ "$active_polling_300000" = 0 ] || active_polling_valid=no
    [ "$active_polling_5000" = "$source_polling_total" ] || active_polling_valid=no
  else
    [ "$active_polling_300000" = "$source_polling_total" ] || active_polling_valid=no
    [ "$active_polling_5000" = 0 ] || active_polling_valid=no
  fi
fi

pany=""; pact=""; pstate=absent
for d in "$ADB_ROOT/modules_update/ptune" "$ADB_ROOT/modules/ptune"; do
  [ -f "$d/module.prop" ] || continue
  grep -q '^id=ptune$' "$d/module.prop" 2>/dev/null || continue
  [ -e "$d/remove" ] && continue
  [ -z "$pany" ] && pany="$d"
  case "$d" in */modules_update/ptune) pstate=staged_update; pact="$d" ;; *) if [ -e "$d/disable" ]; then [ "$pstate" = absent ] && pstate=installed_disabled; else pstate=installed_enabled; [ -z "$pact" ] && pact="$d"; fi ;; esac
done
pt_inst=no; [ -n "$pany" ] && pt_inst=yes
pt_en=no; [ -n "$pact" ] && pt_en=yes
mode="$(cfg_get PTUNE_GUARD_MODE)"; [ -n "$mode" ] || mode=strict
allow="$(cfg_get ALLOW_THERMAL_WITH_PTUNE)"; ack="$(cfg_get RISK_ACK_PTUNE_THERMAL_COLLISION)"
override=no; [ "$allow" = 1 ] && [ "$ack" = I_UNDERSTAND_BOOTLOOP_RISK ] && override=yes

td="$(flag "$M/disable")"; ts="$(flag "$M/skip_mount")"; tr="$(flag "$M/remove")"
thermal_cfg_disabled="$(cfg_get THERMAL_DISABLED)"; [ -n "$thermal_cfg_disabled" ] || thermal_cfg_disabled=0

transition_pending="$(kv_get transition_pending "$GUARD_DIR/platform-transition.env")"; [ -n "$transition_pending" ] || transition_pending=no
transition_phase="$(kv_get phase "$GUARD_DIR/platform-transition.env")"; [ -n "$transition_phase" ] || transition_phase=absent
transition_reason="$(kv_get reason "$GUARD_DIR/platform-transition.env")"; [ -n "$transition_reason" ] || transition_reason=none
selected_profile="$(cat "$GUARD_DIR/selected_profile" 2>/dev/null || true)"; [ -n "$selected_profile" ] || selected_profile=dynamic

auto_state="$(cat "$GUARD_DIR/auto_profile_switch_state" 2>/dev/null || true)"; [ -n "$auto_state" ] || auto_state=experimental_manual_reinstall
reinstall_required="$(kv_get REINSTALL_REQUIRED "$GUARD_DIR/reinstall_required")"; [ -n "$reinstall_required" ] || reinstall_required=no
profile_stale_after_ota="$(kv_get PROFILE_STALE_AFTER_OTA "$GUARD_DIR/profile_stale_after_ota")"; [ -n "$profile_stale_after_ota" ] || profile_stale_after_ota=no

exp=thermal_active_allowed
safe=yes
reason=dynamic_materialization_valid
if [ "$tr" = present ]; then exp=module_remove_authoritative; reason=remove_present
elif [ "$td" = present ]; then exp=module_disable_authoritative; reason=disable_present
elif [ "$ts" = present ]; then exp=module_skip_mount_authoritative; reason=skip_mount_present
elif [ "$pt_en" = yes ] && [ "$override" != yes ]; then exp=thermal_skip_mount_required; safe=no; reason=ptune_active_or_staged
elif [ "$platform_supported" != yes ]; then exp=thermal_disabled_unsupported_platform; if [ "$thermal_cfg_disabled" = 1 ] && [ "$overlay_inventory_count" = 0 ]; then safe=yes; reason=unsupported_platform_thermal_disabled; else safe=no; reason=unsupported_platform_overlay_not_disabled; fi
elif [ "$thermal_cfg_disabled" = 1 ]; then exp=thermal_disabled_by_platform_guard; if [ "$overlay_inventory_count" = 0 ]; then safe=yes; reason=supported_platform_thermal_disabled_overlay_absent; else safe=no; reason=supported_platform_disabled_but_overlay_present; fi
elif [ "$materialization_valid" != yes ]; then safe=no; reason=dynamic_materialization_invalid
elif [ "$active_match" = yes ] && [ "$active_polling_valid" != yes ]; then safe=no; reason=active_polling_values_invalid
elif [ "$active_match" = yes ]; then safe=yes; reason=active_dynamic_overlay_verified
else safe=yes; reason=dynamic_overlay_valid_reboot_pending
fi

root_impl=unknown
_suv="$(su -v 2>/dev/null || true) $(su -V 2>/dev/null || true)"
case "$_suv" in *KernelSU*Next*|*KSU-Next*) root_impl=kernelsu_next ;; *KernelSU*|*ksu*) root_impl=kernelsu ;; *Magisk*|*magisk*) root_impl=magisk ;; *APatch*|*apatch*) root_impl=apatch ;; esac

{
  printf '%s\n' "DEVICE=$DEVICE"
  printf '%s\n' "ANDROID=$ANDROID"
  printf '%s\n' "BUILD_ID=$BUILD_ID"
  printf '%s\n' "PLATFORM_SUPPORTED=$platform_supported"
  printf '%s\n' "BUILD_EVIDENCE=$build_evidence"
  printf '%s\n' "DYNAMIC_LAYOUT_VALID=$layout_valid"
  printf '%s\n' "DYNAMIC_LAYOUT_FAMILY=$layout_family"
  printf '%s\n' "DYNAMIC_CONTROLLED_FILES=$layout_count"
  printf '%s\n' "DYNAMIC_SOURCE_CACHE=$CACHE_DIR"
  printf '%s\n' "DYNAMIC_SOURCE_MANIFEST=$SOURCE_MANIFEST"
  printf '%s\n' "DYNAMIC_SOURCE_MANIFEST_VALID=$source_manifest_valid"
  printf '%s\n' "DYNAMIC_SOURCE_CACHE_VALID=$source_cache_valid"
  printf '%s\n' "DYNAMIC_SOURCE_ROWS=$source_rows"
  printf '%s\n' "DYNAMIC_SOURCE_POLLING_300000=$source_polling_total"
  printf '%s\n' "DYNAMIC_PATCH_MANIFEST=$PATCH_MANIFEST"
  printf '%s\n' "DYNAMIC_PATCH_MANIFEST_VALID=$patch_manifest_valid"
  printf '%s\n' "DYNAMIC_PATCH_ROWS=$patch_rows"
  printf '%s\n' "DYNAMIC_REPLACEMENTS=$patch_replacement_total"
  printf '%s\n' "DYNAMIC_OVERLAY_POLLING_300000=$overlay_polling_300000"
  printf '%s\n' "DYNAMIC_OVERLAY_POLLING_5000=$overlay_polling_5000"
  printf '%s\n' "DYNAMIC_VALIDATION_REPORT=$REPORT_MODULE"
  printf '%s\n' "DYNAMIC_VALIDATION_REPORT_VALID=$validation_report_valid"
  printf '%s\n' "DYNAMIC_MATERIALIZATION_VALID=$materialization_valid"
  printf '%s\n' "POLLING_MODE=$polling_mode"
  printf '%s\n' "OUTDOOR_PROFILE=$outdoor_profile"
  printf '%s\n' "ACTIVE_POLLING_VALID=$active_polling_valid"
  printf '%s\n' "ACTIVE_POLLING_300000=$active_polling_300000"
  printf '%s\n' "ACTIVE_POLLING_5000=$active_polling_5000"
  printf '%s\n' "PTUNE_INSTALLED=$pt_inst"
  printf '%s\n' "PTUNE_ENABLED=$pt_en"
  printf '%s\n' "PTUNE_STATE=$pstate"
  printf '%s\n' "PTUNE_PATH=${pany:-none}"
  printf '%s\n' "CONFIG_FILE=$CFG"
  printf '%s\n' "PTUNE_GUARD_MODE=$mode"
  printf '%s\n' "ALLOW_THERMAL_WITH_PTUNE=${allow:-0}"
  printf '%s\n' "RISK_ACK_VALID=$override"
  printf '%s\n' "THERMAL_CONFIG_DISABLED=$thermal_cfg_disabled"
  printf '%s\n' "THERMAL_DISABLE=$td"
  printf '%s\n' "THERMAL_SKIP_MOUNT=$ts"
  printf '%s\n' "THERMAL_REMOVE=$tr"
  printf '%s\n' "THERMAL_EXPECTED=$exp"
  printf '%s\n' "AUTO_PROFILE_SWITCH_STATE=$auto_state"
  printf '%s\n' "AUTO_SELECTED_PROFILE=$selected_profile"
  printf '%s\n' "BUILD_GUARD_MODE=dynamic_local_validation_vnext"
  printf '%s\n' "PLATFORM_TRANSITION_PENDING=$transition_pending"
  printf '%s\n' "PLATFORM_TRANSITION_PHASE=$transition_phase"
  printf '%s\n' "PLATFORM_TRANSITION_REASON=$transition_reason"
  printf '%s\n' "PROFILE_STALE_AFTER_OTA=$profile_stale_after_ota"
  printf '%s\n' "REINSTALL_REQUIRED=$reinstall_required"
  printf '%s\n' "MODULE_OVERLAY_READY=$module_overlay_ready"
  printf '%s\n' "THERMAL_CHECKED_FILES=$patch_rows"
  printf '%s\n' "ACTIVE_VENDOR_MATCH=$active_match"
  printf '%s\n' "ACTIVE_VENDOR_CHECKED_FILES=$active_checked"
  printf '%s\n' "ROOT_IMPL=$root_impl"
  printf '%s\n' 'META_BACKEND_PRESENT=unknown_experimental'
  printf '%s\n' 'META_BACKEND_KIND=not_probed_by_vnext_compat'
  printf '%s\n' 'META_BACKEND_VERSION=unknown'
  printf '%s\n' 'META_BACKEND_PROBE_MODE=conservative'
  printf '%s\n' 'VENDOR_OVERLAY_BACKEND_WARN=no'
  printf '%s\n' "SAFE_TO_REBOOT=$safe"
  printf '%s\n' "REASON=$reason"
}
