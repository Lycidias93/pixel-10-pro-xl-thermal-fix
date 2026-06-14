#!/system/bin/sh
MODDIR=${0%/*}
MODULE_ID="pixel-10-pro-xl-thermal-fix"
CONFIG_DIR="/data/adb/$MODULE_ID"
CONFIG_FILE="$CONFIG_DIR/config.env"
LOG="$MODDIR/health.log"
GUARDDIR="$MODDIR/guard"
GUARDLOG="$GUARDDIR/bootguard.log"
mkdir -p "$GUARDDIR"

log_guard() { echo "$(date -Is 2>/dev/null || date) $*" >> "$GUARDLOG"; }
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
    log_guard "CONFIG_WARNING PTUNE_GUARD_MODE=off ignored_without_risk_ack fallback=strict phase=service"
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
ptune_known_bad() {
  d="$1"
  vc="$(grep -E '^versionCode=' "$d/module.prop" 2>/dev/null | sed 's/^versionCode=//')"
  [ "$vc" = "200" ] && echo "yes_versionCode_200_thermalhal_bootloop_on_mustang_cp1a_260505_005" || echo "no"
}
apply_ptune_guard() {
  phase="$1"
  load_config
  installed="$(ptune_installed_path 2>/dev/null || true)"
  active="$(ptune_active_path 2>/dev/null || true)"
  conflict=""
  mode="strict_presence_skip_mount"
  reason="conflict_ptune_installed"
  case "$PTUNE_GUARD_MODE" in
    strict) conflict="$installed"; mode="strict_presence_skip_mount"; reason="conflict_ptune_installed" ;;
    active_only) conflict="$active"; mode="active_only_skip_mount"; reason="conflict_ptune_active" ;;
    off) conflict="" ;;
  esac
  if [ -n "$installed" ] && [ "$PTUNE_OVERRIDE_ALLOWED" = "1" ]; then
    rm -f "$MODDIR/disable" "$MODDIR/skip_mount" "$MODDIR/remove" 2>/dev/null || true
    echo "allow_thermal_with_ptune" > "$GUARDDIR/guard_override"
    echo "$CONFIG_FILE" > "$GUARDDIR/guard_override_source"
    echo "explicit_user_override" > "$GUARDDIR/risk_ack"
    echo "$installed" > "$GUARDDIR/conflict_ptune_path"
    echo "override_allow_mount_with_ptune" > "$GUARDDIR/conflict_guard_mode"
    log_guard "OVERRIDE pTune path=$installed action=allow_mount_with_ptune phase=$phase risk_ack=explicit_user_override known_bad=$(ptune_known_bad "$installed")"
    sync
    return 0
  fi
  [ -n "$conflict" ] || return 0
  rm -f "$MODDIR/disable" "$MODDIR/remove" 2>/dev/null || true
  touch "$MODDIR/skip_mount"
  echo "$reason" > "$GUARDDIR/disabled_reason"
  echo "$conflict" > "$GUARDDIR/conflict_ptune_path"
  echo "$mode" > "$GUARDDIR/conflict_guard_mode"
  rm -f "$GUARDDIR/guard_override" "$GUARDDIR/guard_override_source" "$GUARDDIR/risk_ack" 2>/dev/null || true
  log_guard "SOFT_CONFLICT pTune path=$conflict action=$mode reason=$reason phase=$phase known_bad=$(ptune_known_bad "$conflict")"
  sync
}

# Immediate evidence so early reboot/crash still leaves a marker.
load_config
{
  echo "health_start=yes"
  echo "timestamp_start=$(date +%s 2>/dev/null || echo unknown)"
  echo "timestamp_start_iso=$(date -Is 2>/dev/null || date)"
  echo "module_dir=$MODDIR"
  echo "boot_completed=$(getprop sys.boot_completed 2>/dev/null || echo unknown)"
  echo "health_log_model=immediate_plus_ptune_config_guard"
  echo "config_file=$CONFIG_FILE"
  echo "ptune_guard_mode=$PTUNE_GUARD_MODE"
  echo "allow_thermal_with_ptune=${ALLOW_THERMAL_WITH_PTUNE:-0}"
  echo "override_allowed=$PTUNE_OVERRIDE_ALLOWED"
  echo "flags_start_disable=$([ -e "$MODDIR/disable" ] && echo present || echo absent)"
  echo "flags_start_skip_mount=$([ -e "$MODDIR/skip_mount" ] && echo present || echo absent)"
} > "$LOG" 2>&1

apply_ptune_guard "service_start"
(
  i=0
  while [ "$i" -lt 240 ]; do
    apply_ptune_guard "service_watch"
    sleep 30
    i=$((i + 1))
  done
) >/dev/null 2>&1 &

boot_wait=0
while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ] && [ "$boot_wait" -lt 120 ]; do
  sleep 2
  boot_wait=$((boot_wait + 2))
done

sleep 60
load_config
{
  echo "health_start=yes"
  echo "timestamp=$(date +%s 2>/dev/null || echo unknown)"
  echo "timestamp_iso=$(date -Is 2>/dev/null || date)"
  echo "module_dir=$MODDIR"
  echo "boot_completed=$(getprop sys.boot_completed 2>/dev/null || echo unknown)"
  echo "health_log_model=immediate_plus_ptune_config_guard"
  echo "mount_check=best_effort_interactive_verify_is_authoritative"
  echo "config_file=$CONFIG_FILE"
  echo "ptune_guard_mode=$PTUNE_GUARD_MODE"
  echo "allow_thermal_with_ptune=${ALLOW_THERMAL_WITH_PTUNE:-0}"
  echo "override_allowed=$PTUNE_OVERRIDE_ALLOWED"
  echo
  echo "== module =="
  cat "$MODDIR/module.prop" 2>/dev/null || echo "module_prop=missing"
  echo
  echo "== config =="
  if [ -r "$CONFIG_FILE" ]; then cat "$CONFIG_FILE"; else echo "config=missing_default_strict"; fi
  echo
  echo "== install-state =="
  cat "$MODDIR/install-state.txt" 2>/dev/null || echo "install_state=missing"
  echo
  echo "== flags =="
  [ ! -e "$MODDIR/disable" ] && echo "disable=absent" || echo "disable=present"
  [ ! -e "$MODDIR/skip_mount" ] && echo "skip_mount=absent" || echo "skip_mount=present"
  [ ! -e "$MODDIR/remove" ] && echo "remove=absent" || echo "remove=present"
  echo
  echo "== pTune =="
  for d in /data/adb/modules/ptune /data/adb/modules_update/ptune; do
    echo "-- $d"
    if [ -f "$d/module.prop" ]; then
      grep -E "^(id=|name=|version=|versionCode=)" "$d/module.prop" || true
      [ -e "$d/disable" ] && echo disable=present || echo disable=absent
      [ -e "$d/remove" ] && echo remove=present || echo remove=absent
      [ -e "$d/skip_mount" ] && echo skip_mount=present || echo skip_mount=absent
      echo "known_bad=$(ptune_known_bad "$d")"
    else
      echo present=no
    fi
  done
  echo
  echo "== overlay-files =="
  for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
    if [ -s "$MODDIR/system/vendor/etc/$f" ]; then
      echo "module_file=present:$f"
      command -v sha256sum >/dev/null 2>&1 && sha256sum "$MODDIR/system/vendor/etc/$f" | sed "s#  .*/#  #"
    else
      echo "module_file=missing:$f"
    fi
  done
  echo
  echo "== active-vendor-files =="
  for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
    if [ -s "/vendor/etc/$f" ]; then
      echo "vendor_file=present:$f"
      command -v sha256sum >/dev/null 2>&1 && sha256sum "/vendor/etc/$f" | sed "s#  .*/#  #"
    else
      echo "vendor_file=missing:$f"
    fi
  done
  echo
  echo "== mounts-best-effort =="
  grep -E "thermal_info_config(_charge|_throttling)?\.json|/data/adb/modules/ptune|pixel-10-pro-xl-thermal-fix" /proc/self/mountinfo 2>/dev/null || true
  echo
  echo "== tombstone quick check =="
  find /data/tombstones /data/system/dropbox -maxdepth 1 -type f 2>/dev/null | xargs -r grep -l "thermal\|Thermal" 2>/dev/null | tail -10
  echo
  echo "health_log_complete=yes"
} > "$LOG" 2>&1

exit 0
