#!/system/bin/sh
# Pixel 10 Thermal & Memory Control - install debug/autosave helper.
# Sourced by customize.sh. Expects MODPATH, MODULE_ID, MODULE_VERSION,
# MODULE_VERSION_CODE, device/build variables, root_impl, mount_backend_hint,
# root_backend_guard_mode, config_get, ui_print, and abort from the installer.

# BEGIN PIXEL_THERMAL_INSTALL_DEBUG_AUTOSAVE_V1411
thermal_sanitize_name() {
  echo "${1:-unknown}" | tr -c 'A-Za-z0-9._-' '_'
}
thermal_choose_download_dir() {
  for d in /sdcard/Download /storage/emulated/0/Download; do
    if [ -d "$d" ] && [ -w "$d" ]; then echo "$d"; return 0; fi
  done
  echo /storage/emulated/0/Download
}
THERMAL_INSTALL_DEBUG_TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"
THERMAL_INSTALL_DEBUG_DIR="$(thermal_choose_download_dir)"
THERMAL_INSTALL_DEBUG_BASE="pixel_thermal_install_$(thermal_sanitize_name "$MODULE_VERSION")_$(thermal_sanitize_name "$device")_$(thermal_sanitize_name "$build_id")_$(thermal_sanitize_name "$incremental")_$THERMAL_INSTALL_DEBUG_TS"
THERMAL_INSTALL_DEBUG_LOG="$THERMAL_INSTALL_DEBUG_DIR/${THERMAL_INSTALL_DEBUG_BASE}.txt"
THERMAL_INSTALL_DEBUG_COLLECT_STDOUT="$THERMAL_INSTALL_DEBUG_DIR/${THERMAL_INSTALL_DEBUG_BASE}_collect_debug_stdout.txt"

thermal_save_install_debug() {
  result="${1:-unknown}"
  reason="${2:-none}"
  if [ "$result" = "success" ]; then
    local dbg_mode="$(config_get DEBUG_MODE)"
    [ -z "$dbg_mode" ] && dbg_mode="$(config_get debug_mode)"
    if [ "$dbg_mode" != "1" ]; then
      return 0
    fi
  fi
  mkdir -p "$THERMAL_INSTALL_DEBUG_DIR" 2>/dev/null || true
  {
    echo "debug_type=pixel_thermal_install_autosave"
    echo "result=$result"
    echo "reason=$reason"
    echo "time=$(date -Is 2>/dev/null || date 2>/dev/null || true)"
    echo "module_id=$MODULE_ID"
    echo "module_version=$MODULE_VERSION"
    echo "module_version_code=$MODULE_VERSION_CODE"
    echo "modpath=$MODPATH"
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
    echo "android_guard=${android_guard:-unset}"
    echo "fingerprint_android_guard=${fingerprint_android_guard:-unset}"
    echo "incremental_guard=${incremental_guard:-unset}"
    echo "profile_source_build=${profile_source_build:-unset}"
    echo "profile_source_incremental=${profile_source_incremental:-unset}"
    echo "profile_dir=${profile_dir:-unset}"
    echo "active_dir=${active_dir:-unset}"
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
    echo "== profile dir =="
    [ -n "${profile_dir:-}" ] && ls -la "$profile_dir" 2>/dev/null || true
    echo
    echo "== active overlay dir =="
    [ -n "${active_dir:-}" ] && ls -la "$active_dir" 2>/dev/null || true
    echo
    echo "== install-state =="
    cat "$MODPATH/install-state.txt" 2>/dev/null || true
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
  ui_print "Install debug autosave: $THERMAL_INSTALL_DEBUG_LOG"
}

thermal_collect_debug_on_fail() {
  [ -s "$MODPATH/tools/collect-debug.sh" ] || return 0
  MODDIR="$MODPATH" sh "$MODPATH/tools/collect-debug.sh" > "$THERMAL_INSTALL_DEBUG_COLLECT_STDOUT" 2>&1 || true
  ui_print "Install-fail collect-debug stdout: $THERMAL_INSTALL_DEBUG_COLLECT_STDOUT"
}

thermal_abort() {
  reason="$*"
  thermal_save_install_debug "fail" "$reason"
  thermal_collect_debug_on_fail
  abort "$reason"
}
# END PIXEL_THERMAL_INSTALL_DEBUG_AUTOSAVE_V1411
