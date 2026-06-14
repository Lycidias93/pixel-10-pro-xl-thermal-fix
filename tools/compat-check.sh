#!/system/bin/sh
MODULE_ID="pixel-10-pro-xl-thermal-fix"
MODDIR="/data/adb/modules/$MODULE_ID"
CONFIG_FILE="/data/adb/$MODULE_ID/config.env"
config_get() {
  key="$1"
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^${key}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${key}=//" | tr -d '\r'
}
flag_state() { [ -e "$1" ] && echo present || echo absent; }
ptune_path_any=""
ptune_path_enabled=""
for d in /data/adb/modules/ptune /data/adb/modules_update/ptune; do
  [ -f "$d/module.prop" ] || continue
  grep -q '^id=ptune$' "$d/module.prop" 2>/dev/null || continue
  [ -e "$d/remove" ] && continue
  [ -z "$ptune_path_any" ] && ptune_path_any="$d"
  if [ ! -e "$d/disable" ]; then [ -z "$ptune_path_enabled" ] && ptune_path_enabled="$d"; fi
done
mode="$(config_get PTUNE_GUARD_MODE)"; [ -n "$mode" ] || mode=strict
case "$mode" in strict|active_only|off) ;; *) mode=strict ;; esac
allow="$(config_get ALLOW_THERMAL_WITH_PTUNE)"
risk="$(config_get RISK_ACK_PTUNE_THERMAL_COLLISION)"
override=no
[ "$allow" = "1" ] && [ "$risk" = "I_UNDERSTAND_BOOTLOOP_RISK" ] && override=yes
known_bad=no
if [ -n "$ptune_path_any" ]; then
  vc="$(grep -E '^versionCode=' "$ptune_path_any/module.prop" 2>/dev/null | sed 's/^versionCode=//')"
  [ "$vc" = "200" ] && known_bad=yes_versionCode_200_thermalhal_bootloop_on_mustang_cp1a_260505_005
fi
th_disable="$(flag_state "$MODDIR/disable")"
th_skip="$(flag_state "$MODDIR/skip_mount")"
th_remove="$(flag_state "$MODDIR/remove")"
pt_installed=no; [ -n "$ptune_path_any" ] && pt_installed=yes
pt_enabled=no; [ -n "$ptune_path_enabled" ] && pt_enabled=yes
expected="thermal_active_allowed"
safe="yes"
reason="no_ptune_conflict"
case "$mode" in
  strict)
    if [ "$pt_installed" = yes ] && [ "$override" != yes ]; then expected="thermal_skip_mount_required"; reason="ptune_installed"; fi ;;
  active_only)
    if [ "$pt_enabled" = yes ] && [ "$override" != yes ]; then expected="thermal_skip_mount_required"; reason="ptune_enabled"; fi ;;
  off)
    if [ "$override" != yes ]; then expected="thermal_skip_mount_required"; reason="guard_off_without_risk_ack_fallback_strict"; [ "$pt_installed" = no ] && expected="thermal_active_allowed"; fi ;;
esac
if [ "$expected" = "thermal_skip_mount_required" ]; then
  if [ "$th_disable" = absent ] && [ "$th_skip" = present ]; then safe=yes; else safe=no; fi
fi
cat <<EOF
PTUNE_INSTALLED=$pt_installed
PTUNE_ENABLED=$pt_enabled
PTUNE_PATH=${ptune_path_any:-none}
PTUNE_KNOWN_BAD=$known_bad
CONFIG_FILE=$CONFIG_FILE
PTUNE_GUARD_MODE=$mode
ALLOW_THERMAL_WITH_PTUNE=${allow:-0}
RISK_ACK_VALID=$override
THERMAL_DISABLE=$th_disable
THERMAL_SKIP_MOUNT=$th_skip
THERMAL_REMOVE=$th_remove
THERMAL_EXPECTED=$expected
SAFE_TO_REBOOT=$safe
REASON=$reason
EOF
