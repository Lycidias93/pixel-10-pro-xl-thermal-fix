#!/system/bin/sh
# Pixel 10 Thermal & Memory Control - install debug/autosave helper.
# Sourced by customize.sh.

thermal_sanitize_name() {
  echo "${1:-unknown}" | tr -c 'A-Za-z0-9._-' '_'
}

thermal_choose_download_dir() {
  for d in /sdcard/Download /storage/emulated/0/Download; do
    if [ -d "$d" ] && [ -w "$d" ]; then
      echo "$d"
      return 0
    fi
  done
  echo /storage/emulated/0/Download
}

thermal_battery_field() {
  _pattern="$1"
  printf '%s\n' "$THERMAL_BATTERY_DUMP" \
    | awk -F: -v pattern="$_pattern" '$1 ~ pattern {gsub(/[[:space:]]/,"",$2); print $2; exit}'
}

thermal_packaged_debug_collector() {
  for _collector in \
    "$MODPATH/tools/bootguard/collect-debug-v3.sh" \
    "$MODPATH/tools/bootguard/collect-debug.sh"; do
    [ -s "$_collector" ] || continue
    printf '%s\n' "$_collector"
    return 0
  done
  return 1
}

THERMAL_INSTALL_STARTED_EPOCH="$(date +%s 2>/dev/null || echo 0)"
THERMAL_INSTALL_DEBUG_TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"
THERMAL_INSTALL_DEBUG_DIR="$(thermal_choose_download_dir)"
THERMAL_INSTALL_DEBUG_BASE="pixel_thermal_install_$(thermal_sanitize_name "$MODULE_VERSION")_$(thermal_sanitize_name "$device")_$(thermal_sanitize_name "$build_id")_$(thermal_sanitize_name "$incremental")_$THERMAL_INSTALL_DEBUG_TS"
THERMAL_INSTALL_DEBUG_LOG="$THERMAL_INSTALL_DEBUG_DIR/${THERMAL_INSTALL_DEBUG_BASE}.txt"
THERMAL_INSTALL_DEBUG_COLLECT_STDOUT="$THERMAL_INSTALL_DEBUG_DIR/${THERMAL_INSTALL_DEBUG_BASE}_collect_debug_stdout.txt"

thermal_save_install_debug() {
  result="${1:-unknown}"
  reason="${2:-none}"
  if [ "$result" = "success" ]; then
    dbg_mode="$(config_get DEBUG_MODE)"
    [ -z "$dbg_mode" ] && dbg_mode="$(config_get debug_mode)"
    if [ "$dbg_mode" != "1" ]; then
      return 0
    fi
  fi

  THERMAL_BATTERY_DUMP="$(dumpsys battery 2>/dev/null || true)"
  battery_level="$(thermal_battery_field '^[[:space:]]*level$')"
  battery_status="$(thermal_battery_field '^[[:space:]]*status$')"
  powered_usb="$(thermal_battery_field 'USB powered')"
  powered_ac="$(thermal_battery_field 'AC powered')"
  powered_wireless="$(thermal_battery_field 'Wireless powered')"

  install_finished_epoch="$(date +%s 2>/dev/null || echo 0)"
  install_elapsed_seconds=unknown
  case "$THERMAL_INSTALL_STARTED_EPOCH:$install_finished_epoch" in
    *[!0-9:]*|:*|*:) ;;
    *) install_elapsed_seconds=$((install_finished_epoch - THERMAL_INSTALL_STARTED_EPOCH)) ;;
  esac

  package_path="${ZIPFILE:-${ZIP_PATH:-unset}}"
  package_sha256=unavailable
  package_bytes=unavailable
  if [ -n "$package_path" ] && [ "$package_path" != unset ] && [ -s "$package_path" ]; then
    package_sha256="$(sha256sum "$package_path" 2>/dev/null | awk '{print $1}' || true)"
    package_bytes="$(wc -c < "$package_path" 2>/dev/null | tr -d ' ' || true)"
    [ -n "$package_sha256" ] || package_sha256=unavailable
    [ -n "$package_bytes" ] || package_bytes=unavailable
  fi

  mkdir -p "$THERMAL_INSTALL_DEBUG_DIR" 2>/dev/null || true
  {
    echo "debug_type=pixel_thermal_install_autosave"
    echo "result=$result"
    echo "reason=$reason"
    echo "time=$(date -Is 2>/dev/null || date 2>/dev/null || true)"
    echo "install_elapsed_seconds=$install_elapsed_seconds"
    echo "module_id=$MODULE_ID"
    echo "module_version=$MODULE_VERSION"
    echo "module_version_code=$MODULE_VERSION_CODE"
    echo "modpath=$MODPATH"
    echo
    echo "== package =="
    echo "package_path=$package_path"
    echo "package_sha256=$package_sha256"
    echo "package_bytes=$package_bytes"
    echo
    echo "== battery / power =="
    echo "battery_level=${battery_level:-unknown}"
    echo "battery_status=${battery_status:-unknown}"
    echo "powered_usb=${powered_usb:-unknown}"
    echo "powered_ac=${powered_ac:-unknown}"
    echo "powered_wireless=${powered_wireless:-unknown}"
    echo
    echo "== device =="
    echo "model=$model"
    echo "device=$device"
    echo "android=$android"
    echo "android_sdk=$android_sdk"
    echo "build_id=$build_id"
    echo "incremental=$incremental"
    echo "fingerprint=$fingerprint"
    echo
    echo "== root / backend =="
    echo "root_impl=${root_impl:-unknown}"
    echo "mount_backend_hint=${mount_backend_hint:-unknown}"
    echo "root_backend_guard_mode=${root_backend_guard_mode:-unknown}"
    echo
    echo "== selected profile =="
    echo "profile=${profile:-unset}"
    echo "profile_state=${profile_state:-unset}"
    echo "build_state=${build_state:-unset}"
    echo "build_evidence=${build_evidence:-unset}"
    echo "build_guard_mode=${build_guard_mode:-unset}"
    echo "android_guard=${android_guard:-unset}"
    echo "fingerprint_android_guard=${fingerprint_android_guard:-unset}"
    echo "incremental_guard=${incremental_guard:-unset}"
    echo "profile_source_build=${profile_source_build:-unset}"
    echo "profile_source_incremental=${profile_source_incremental:-unset}"
    echo "profile_dir=${profile_dir:-unset}"
    echo "active_dir=${active_dir:-unset}"
    echo "thermal_polling_mode=$(config_get THERMAL_POLLING_MODE)"
    echo "thermal_outdoor_profile=$(config_get THERMAL_OUTDOOR_PROFILE)"
    echo "last_thermal_outdoor_profile=$(config_get LAST_THERMAL_OUTDOOR_PROFILE)"
    echo "thermal_settings_mode=$(config_get THERMAL_SETTINGS_MODE)"
    echo "dynamic_unverified_build=$(config_get DYNAMIC_UNVERIFIED_BUILD)"
    echo
    echo "== pTune guard =="
    echo "PTUNE_GUARD_MODE=${PTUNE_GUARD_MODE:-unset}"
    echo "PTUNE_INSTALLED_PATH=${PTUNE_INSTALLED_PATH:-unset}"
    echo "PTUNE_ACTIVE_PATH=${PTUNE_ACTIVE_PATH:-unset}"
    echo "PTUNE_CONFLICT_PATH=${PTUNE_CONFLICT_PATH:-unset}"
    echo "PTUNE_CONFLICT_MODE=${PTUNE_CONFLICT_MODE:-unset}"
    echo "PTUNE_OVERRIDE_ALLOWED=${PTUNE_OVERRIDE_ALLOWED:-unset}"
    echo "PTUNE_KNOWN_BAD=${PTUNE_KNOWN_BAD:-unset}"
    echo
    echo "== relevant files =="
    ls -la "$MODPATH" 2>/dev/null || true
    echo
    echo "== guard dir =="
    ls -la "$MODPATH/guard" 2>/dev/null || true
    echo
    echo "== validation dir =="
    ls -la "/data/adb/$MODULE_ID/validation" 2>/dev/null || true
    echo
    echo "== profile dir =="
    [ -n "${profile_dir:-}" ] && ls -la "$profile_dir" 2>/dev/null || true
    echo
    echo "== active overlay dir =="
    [ -n "${active_dir:-}" ] && ls -la "$active_dir" 2>/dev/null || true
    echo
    echo "== install-state =="
    cat "$MODPATH/install-state.txt" 2>/dev/null || true
    echo
    echo "== validation summaries =="
    cat "$MODPATH/guard/outdoor-delta-validation.env" 2>/dev/null || true
    cat "$MODPATH/validation_report.json" 2>/dev/null || true
    echo
    echo "== su / magisk =="
    su -v 2>/dev/null || true
    su -V 2>/dev/null || true
    magisk -v 2>/dev/null || true
    magisk -V 2>/dev/null || true
    echo
    echo "== recent thermal logcat =="
    logcat -d -t 300 2>/dev/null | grep -i -E "thermal|ThermalHAL|android.hardware.thermal|pixel-10-pro-xl-thermal-fix|Magisk|KernelSU|SukiSU|APatch" || true
  } > "$THERMAL_INSTALL_DEBUG_LOG" 2>&1 || true

  ui_print "Install debug autosave:"
  ui_print "Saved"
  ui_print "In Download folder"
}

thermal_collect_debug_on_fail() {
  collector="$(thermal_packaged_debug_collector 2>/dev/null || true)"
  [ -n "$collector" ] || return 0
  selected_profile="$(config_get THERMAL_OUTDOOR_PROFILE)"
  [ -n "$selected_profile" ] || selected_profile=unknown
  previous_profile="$(config_get LAST_THERMAL_OUTDOOR_PROFILE)"
  [ -n "$previous_profile" ] || previous_profile=unknown
  MODDIR="$MODPATH" sh "$collector" install-failure "$selected_profile" "$previous_profile" unknown > "$THERMAL_INSTALL_DEBUG_COLLECT_STDOUT" 2>&1 || true
  ui_print "Install-fail debug stdout:"
  ui_print "$(basename "$THERMAL_INSTALL_DEBUG_COLLECT_STDOUT")"
  ui_print "In Download folder"
}

thermal_abort() {
  reason="$*"
  thermal_save_install_debug "fail" "$reason"
  thermal_collect_debug_on_fail
  abort "$reason"
}
