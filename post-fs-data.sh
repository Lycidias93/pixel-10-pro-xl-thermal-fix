#!/system/bin/sh
MODDIR=${0%/*}
MODULE_ID="pixel-10-pro-xl-thermal-fix"
CONFIG_DIR="/data/adb/$MODULE_ID"
CONFIG_FILE="$CONFIG_DIR/config.env"
GUARDDIR="$MODDIR/guard"
LOG="$GUARDDIR/bootguard.log"
mkdir -p "$GUARDDIR"
log_line() { echo "$(date -Is 2>/dev/null || date) $*" >> "$LOG"; }

config_get() {
  key="$1"
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^${key}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${key}=//" | tr -d '\r'
}

load_config() {
  PTUNE_GUARD_MODE="$(config_get PTUNE_GUARD_MODE)"
  [ -n "$PTUNE_GUARD_MODE" ] || PTUNE_GUARD_MODE="strict"
  case "$PTUNE_GUARD_MODE" in strict|active_only|off) ;; *) PTUNE_GUARD_MODE="strict" ;; esac
  ALLOW_THERMAL_WITH_PTUNE="$(config_get ALLOW_THERMAL_WITH_PTUNE)"
  RISK_ACK_PTUNE_THERMAL_COLLISION="$(config_get RISK_ACK_PTUNE_THERMAL_COLLISION)"
  PTUNE_OVERRIDE_ALLOWED=0
  if [ "$ALLOW_THERMAL_WITH_PTUNE" = "1" ] && [ "$RISK_ACK_PTUNE_THERMAL_COLLISION" = "I_UNDERSTAND_BOOTLOOP_RISK" ]; then
    PTUNE_OVERRIDE_ALLOWED=1
  fi
  if [ "$PTUNE_GUARD_MODE" = "off" ] && [ "$PTUNE_OVERRIDE_ALLOWED" != "1" ]; then
    log_line "CONFIG_WARNING PTUNE_GUARD_MODE=off ignored_without_risk_ack fallback=strict"
    PTUNE_GUARD_MODE="strict"
  fi
}

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

write_override_guard() {
  path="$1"
  echo "allow_thermal_with_ptune" > "$GUARDDIR/guard_override"
  echo "$CONFIG_FILE" > "$GUARDDIR/guard_override_source"
  echo "explicit_user_override" > "$GUARDDIR/risk_ack"
  echo "$path" > "$GUARDDIR/conflict_ptune_path"
  echo "override_allow_mount_with_ptune" > "$GUARDDIR/conflict_guard_mode"
  rm -f "$MODDIR/disable" "$MODDIR/skip_mount" "$MODDIR/remove" 2>/dev/null || true
}

soft_conflict_ptune() {
  path="$1"
  mode="$2"
  reason="$3"
  log_line "SOFT_CONFLICT pTune path=$path action=$mode reason=$reason"
  echo "$reason" > "$GUARDDIR/disabled_reason"
  echo "$path" > "$GUARDDIR/conflict_ptune_path"
  echo "$mode" > "$GUARDDIR/conflict_guard_mode"
  rm -f "$MODDIR/disable" "$MODDIR/remove" 2>/dev/null || true
  touch "$MODDIR/skip_mount"
  sync
}

disable_wrong_target() {
  reason="$1"
  log_line "DISABLE wrong_target reason=$reason"
  echo "$reason" > "$GUARDDIR/disabled_reason"
  touch "$MODDIR/disable" "$MODDIR/skip_mount"
  sync
}

passive_arm() {
  scope="$1"
  rm -f "$MODDIR/disable" "$MODDIR/remove" 2>/dev/null || true
  if [ "$PTUNE_OVERRIDE_ALLOWED" = "1" ] && [ -n "$PTUNE_INSTALLED" ]; then
    write_override_guard "$PTUNE_INSTALLED"
    log_line "OVERRIDE pTune path=$PTUNE_INSTALLED action=allow_mount_with_ptune scope=$scope risk_ack=explicit_user_override"
  else
    rm -f "$MODDIR/skip_mount" 2>/dev/null || true
    rm -f "$GUARDDIR/disabled_reason" "$GUARDDIR/conflict_guard_mode" "$GUARDDIR/conflict_ptune_path" "$GUARDDIR/guard_override" "$GUARDDIR/guard_override_source" "$GUARDDIR/risk_ack" 2>/dev/null || true
    log_line "PASSIVE_ARM device=$device android=$android build=$build_id incremental=$incremental scope=$scope universal_guard=true selinux_policy=thermal_hal_system_file_read_only stale_flags_cleared=true"
  fi
}

load_config
PTUNE_INSTALLED="$(ptune_installed_path 2>/dev/null || true)"
PTUNE_ACTIVE="$(ptune_active_path 2>/dev/null || true)"
PTUNE_CONFLICT=""
PTUNE_CONFLICT_MODE="strict_presence_skip_mount"
PTUNE_CONFLICT_REASON="conflict_ptune_installed"
case "$PTUNE_GUARD_MODE" in
  strict) PTUNE_CONFLICT="$PTUNE_INSTALLED"; PTUNE_CONFLICT_MODE="strict_presence_skip_mount"; PTUNE_CONFLICT_REASON="conflict_ptune_installed" ;;
  active_only) PTUNE_CONFLICT="$PTUNE_ACTIVE"; PTUNE_CONFLICT_MODE="active_only_skip_mount"; PTUNE_CONFLICT_REASON="conflict_ptune_active" ;;
  off) PTUNE_CONFLICT="" ;;
esac
if [ -n "$PTUNE_CONFLICT" ] && [ "$PTUNE_OVERRIDE_ALLOWED" != "1" ]; then
  soft_conflict_ptune "$PTUNE_CONFLICT" "$PTUNE_CONFLICT_MODE" "$PTUNE_CONFLICT_REASON"
  exit 0
fi

device="$(getprop ro.product.device 2>/dev/null)"
android="$(getprop ro.build.version.release 2>/dev/null)"
build_id="$(getprop ro.build.id 2>/dev/null)"
fingerprint="$(getprop ro.build.fingerprint 2>/dev/null)"
incremental="$(getprop ro.build.version.incremental 2>/dev/null)"

case "$android" in
  16|16.*)
    case "$fingerprint" in *":16/"*) ;; *) disable_wrong_target "android16_fingerprint_mismatch"; exit 0 ;; esac
    case "$device" in mustang|frankel|blazer|rango) passive_arm "android16_pixel10_universal"; exit 0 ;; *) disable_wrong_target "unsupported_android16_device_$device"; exit 0 ;; esac ;;
  17|17.*)
    case "$device" in
      mustang)
        case "$fingerprint" in
          google/mustang_beta/mustang:CinnamonBun/CP31.260508.005/15421345:user/release-keys) case "$incremental" in 15421345) passive_arm "android17_mustang_cp31_15421345"; exit 0 ;; *) disable_wrong_target "unsupported_android17_cp31_incremental_$incremental"; exit 0 ;; esac ;;
          google/mustang_beta/mustang:CinnamonBun/CP31.260522.006/15591510:user/release-keys) case "$incremental" in 15591510) passive_arm "android17_mustang_cp31_15591510_qpr1_beta4_guarded_test"; exit 0 ;; *) disable_wrong_target "unsupported_android17_cp31_qpr1_beta4_incremental_$incremental"; exit 0 ;; esac ;;
          *":CinnamonBun/CP21.260330.011/"*|*":17/CP21.260330.011/"*) passive_arm "android17_mustang_cp21_guarded_pending"; exit 0 ;;
          *) disable_wrong_target "unsupported_android17_mustang_fingerprint"; exit 0 ;;
        esac ;;
      frankel|blazer|rango)
        case "$build_id" in CP21.260330.011) ;; *) disable_wrong_target "unsupported_android17_cp21_build_$build_id"; exit 0 ;; esac
        case "$fingerprint" in *":CinnamonBun/CP21.260330.011/"*|*":17/CP21.260330.011/"*) passive_arm "android17_${device}_cp21_guarded_pending"; exit 0 ;; *) disable_wrong_target "unsupported_android17_cp21_fingerprint"; exit 0 ;; esac ;;
      *) disable_wrong_target "unsupported_android17_device_$device"; exit 0 ;;
    esac ;;
  *) disable_wrong_target "unsupported_android_$android"; exit 0 ;;
esac
