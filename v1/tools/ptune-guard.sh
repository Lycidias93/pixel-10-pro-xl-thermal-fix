#!/system/bin/sh
# Pixel 10 Thermal & Memory Control - pTune guard helper.
# Extracted from customize.sh for Test22.
# Sourced by customize.sh and executed at source time.

PTUNE_GUARD_MODE="$(config_get PTUNE_GUARD_MODE)"
[ -n "$PTUNE_GUARD_MODE" ] || PTUNE_GUARD_MODE="strict"
case "$PTUNE_GUARD_MODE" in strict|active_only|off) ;; *) ui_print "! Invalid PTUNE_GUARD_MODE=$PTUNE_GUARD_MODE, using strict"; PTUNE_GUARD_MODE="strict" ;; esac
ALLOW_THERMAL_WITH_PTUNE="$(config_get ALLOW_THERMAL_WITH_PTUNE)"
RISK_ACK_PTUNE_THERMAL_COLLISION="$(config_get RISK_ACK_PTUNE_THERMAL_COLLISION)"
PTUNE_OVERRIDE_ALLOWED=0
PTUNE_OVERRIDE_NAME="none"
PTUNE_RISK_ACK_STATE="not_present"
if [ "$ALLOW_THERMAL_WITH_PTUNE" = "1" ] && [ "$RISK_ACK_PTUNE_THERMAL_COLLISION" = "I_UNDERSTAND_BOOTLOOP_RISK" ]; then
  PTUNE_OVERRIDE_ALLOWED=1
  PTUNE_OVERRIDE_NAME="allow_thermal_with_ptune"
  PTUNE_RISK_ACK_STATE="explicit_user_override"
fi
if [ "$PTUNE_GUARD_MODE" = "off" ] && [ "$PTUNE_OVERRIDE_ALLOWED" != "1" ]; then
  ui_print "! pTune off ignored"
ui_print "! Using strict guard"
  PTUNE_GUARD_MODE="strict"
fi
ptune_installed_path() {
  for d in /data/adb/modules/ptune /data/adb/modules_update/ptune; do
    [ -f "$d/module.prop" ] || continue
    grep -q '^id=ptune$' "$d/module.prop" 2>/dev/null || continue
    [ -e "$d/remove" ] && continue
    echo "$d"
    return 0
  done
  return 1
}
ptune_active_path() {
  for d in /data/adb/modules/ptune /data/adb/modules_update/ptune; do
    [ -f "$d/module.prop" ] || continue
    grep -q '^id=ptune$' "$d/module.prop" 2>/dev/null || continue
    [ -e "$d/remove" ] && continue
    [ -e "$d/disable" ] && continue
    echo "$d"
    return 0
  done
  return 1
}
ptune_known_bad_state() {
  d="$1"
  vc="$(grep -E '^versionCode=' "$d/module.prop" 2>/dev/null | sed 's/^versionCode=//')"
  [ "$vc" = "200" ] && echo "yes_versionCode_200_thermalhal_bootloop_on_mustang_cp1a_260505_005" || echo "no"
}
PTUNE_INSTALLED_PATH="$(ptune_installed_path 2>/dev/null || true)"
PTUNE_ACTIVE_PATH="$(ptune_active_path 2>/dev/null || true)"
PTUNE_KNOWN_BAD="no"
[ -n "$PTUNE_INSTALLED_PATH" ] && PTUNE_KNOWN_BAD="$(ptune_known_bad_state "$PTUNE_INSTALLED_PATH")"
PTUNE_CONFLICT_PATH=""
PTUNE_CONFLICT_REASON="conflict_ptune_active_or_staged"
PTUNE_CONFLICT_MODE="strict_active_skip_mount"
case "$PTUNE_GUARD_MODE" in
  strict) PTUNE_CONFLICT_PATH="$PTUNE_ACTIVE_PATH"; PTUNE_CONFLICT_REASON="conflict_ptune_active_or_staged"; PTUNE_CONFLICT_MODE="strict_active_skip_mount" ;;
  active_only) PTUNE_CONFLICT_PATH="$PTUNE_ACTIVE_PATH"; PTUNE_CONFLICT_REASON="conflict_ptune_active"; PTUNE_CONFLICT_MODE="active_only_skip_mount" ;;
  off) PTUNE_CONFLICT_PATH=""; PTUNE_CONFLICT_REASON="guard_off"; PTUNE_CONFLICT_MODE="guard_off" ;;
esac
if [ -n "$PTUNE_CONFLICT_PATH" ] && [ "$PTUNE_OVERRIDE_ALLOWED" != "1" ]; then
  ui_print "! pTune conflict"
ui_print "! $PTUNE_CONFLICT_PATH"
  ui_print "! pTune guard mode"
ui_print "! $PTUNE_GUARD_MODE -> $PTUNE_CONFLICT_MODE"
  [ "$PTUNE_KNOWN_BAD" = "no" ] || ui_print "! Known bad pTune state: $PTUNE_KNOWN_BAD"
  ui_print "! Module remains scriptable"
ui_print "! skip_mount active"
  mkdir -p "$MODPATH/guard"
  rm -f "$MODPATH/disable" "$MODPATH/remove"
  touch "$MODPATH/skip_mount"
  echo "$PTUNE_CONFLICT_REASON" > "$MODPATH/guard/disabled_reason"
  echo "$PTUNE_CONFLICT_PATH" > "$MODPATH/guard/conflict_ptune_path"
  echo "$PTUNE_CONFLICT_MODE" > "$MODPATH/guard/conflict_guard_mode"
  rm -f "$MODPATH/guard/guard_override" "$MODPATH/guard/guard_override_source" "$MODPATH/guard/risk_ack" 2>/dev/null || true
  ACTIVE_MODPATH="/data/adb/modules/$MODULE_ID"
  if [ -d "$ACTIVE_MODPATH" ]; then
    mkdir -p "$ACTIVE_MODPATH/guard"
    rm -f "$ACTIVE_MODPATH/disable" "$ACTIVE_MODPATH/remove"
    touch "$ACTIVE_MODPATH/skip_mount"
    echo "$PTUNE_CONFLICT_REASON" > "$ACTIVE_MODPATH/guard/disabled_reason"
    echo "$PTUNE_CONFLICT_PATH" > "$ACTIVE_MODPATH/guard/conflict_ptune_path"
    echo "$PTUNE_CONFLICT_MODE" > "$ACTIVE_MODPATH/guard/conflict_guard_mode"
    rm -f "$ACTIVE_MODPATH/guard/guard_override" "$ACTIVE_MODPATH/guard/guard_override_source" "$ACTIVE_MODPATH/guard/risk_ack" 2>/dev/null || true
  fi
  [ -s "$MODPATH/tools/collect-debug.sh" ] && chmod 0755 "$MODPATH/tools/collect-debug.sh" || true
  [ -s "$MODPATH/tools/pixel_thermal_toggle_debug.sh" ] && chmod 0755 "$MODPATH/tools/pixel_thermal_toggle_debug.sh" || true
[ -s "$MODPATH/tools/auto-profile-switch.sh" ] && chmod 0755 "$MODPATH/tools/auto-profile-switch.sh" || true
[ -s "$MODPATH/tools/compat-check.sh" ] && chmod 0755 "$MODPATH/tools/compat-check.sh" || true
[ -s "$MODPATH/tools/collect-ptune-evidence.sh" ] && chmod 0755 "$MODPATH/tools/collect-ptune-evidence.sh" || true
[ -s "$MODPATH/tools/enable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/enable-ptune-override.sh" || true
[ -s "$MODPATH/tools/disable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/disable-ptune-override.sh" || true
  [ -s "$MODPATH/tools/compat-check.sh" ] && chmod 0755 "$MODPATH/tools/compat-check.sh" || true
  [ -s "$MODPATH/tools/collect-ptune-evidence.sh" ] && chmod 0755 "$MODPATH/tools/collect-ptune-evidence.sh" || true
  [ -s "$MODPATH/tools/enable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/enable-ptune-override.sh" || true
  [ -s "$MODPATH/tools/disable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/disable-ptune-override.sh" || true
  [ -s "$MODPATH/tools/compat-check.sh" ] && chmod 0755 "$MODPATH/tools/compat-check.sh" || true
  [ -s "$MODPATH/tools/collect-ptune-evidence.sh" ] && chmod 0755 "$MODPATH/tools/collect-ptune-evidence.sh" || true
  [ -s "$MODPATH/tools/enable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/enable-ptune-override.sh" || true
  [ -s "$MODPATH/tools/disable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/disable-ptune-override.sh" || true
  {
    printf '%s\n' "module_id=$MODULE_ID"
    printf '%s\n' "module_version=$MODULE_VERSION"
    printf '%s\n' "module_version_code=$MODULE_VERSION_CODE"
    printf '%s\n' "device=$device"
    printf '%s\n' "profile=skip_mount_by_ptune_guard"
    printf '%s\n' "profile_state=${PTUNE_CONFLICT_REASON}"
    printf '%s\n' "build_state=not_materialized_due_ptune_guard"
    printf '%s\n' "android=$android"
    printf '%s\n' "android_sdk=$android_sdk"
    printf '%s\n' "build_id=$build_id"
    printf '%s\n' "incremental=$incremental"
    printf '%s\n' "android_guard=not_evaluated_due_ptune_guard"
    printf '%s\n' "fingerprint_android_guard=not_evaluated_due_ptune_guard"
    printf '%s\n' "incremental_guard=not_applicable"
    printf '%s\n' "profile_materialized=no"
    printf '%s\n' "active_overlay_dir=none"
    printf '%s\n' "expected_thermal_files=0"
    printf '%s\n' "config_file=$CONFIG_FILE"
    printf '%s\n' "config_ptune_guard_mode=$PTUNE_GUARD_MODE"
    printf '%s\n' "config_allow_thermal_with_ptune=${ALLOW_THERMAL_WITH_PTUNE:-0}"
    printf '%s\n' "config_override_allowed=$PTUNE_OVERRIDE_ALLOWED"
    printf '%s\n' "risk_ack=$PTUNE_RISK_ACK_STATE"
    printf '%s\n' "conflict_guard=ptune_present"
    printf '%s\n' "conflict_guard_mode=$PTUNE_CONFLICT_MODE"
    printf '%s\n' "conflict_ptune_path=$PTUNE_CONFLICT_PATH"
    printf '%s\n' "known_bad_ptune=$PTUNE_KNOWN_BAD"
    printf '%s\n' "bind_mount_model=no"
    printf '%s\n' "live_runtime_text_patch_model=no"
    printf '%s\n' "selinux_overlay_read_policy=installed_but_overlay_skipped_due_ptune_guard"
    printf '%s\n' "update_json_channel=stable_update_json_1.5.1-universal.1_public_stable"
    printf '%s\n' "debug_collector=manual_or_auto_on_install_fail_v1411"
    printf '%s\n' "compat_check_command=su -c /data/adb/modules/$MODULE_ID/tools/compat-check.sh"
    printf '%s\n' "ptune_evidence_command=su -c /data/adb/modules/$MODULE_ID/tools/collect-ptune-evidence.sh"
  } > "$MODPATH/install-state.txt"
  thermal_save_install_debug "skip_mount" "$PTUNE_CONFLICT_REASON"
  ui_print "Installed with skip_mount"
ui_print "$PTUNE_CONFLICT_REASON"
  exit 0
fi
