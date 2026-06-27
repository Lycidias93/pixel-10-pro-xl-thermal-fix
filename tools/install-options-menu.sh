#!/system/bin/sh
set -eu
MODULE_ID="${MODULE_ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-${0%/*}/..}"
CONFIG_DIR="/data/adb/$MODULE_ID"
CONFIG_FILE="$CONFIG_DIR/config.env"
mkdir -p "$CONFIG_DIR" 2>/dev/null || true
touch "$CONFIG_FILE" 2>/dev/null || true
chmod 0600 "$CONFIG_FILE" 2>/dev/null || true
[ -s "$MODDIR/tools/menu-cycle.sh" ] && . "$MODDIR/tools/menu-cycle.sh" || exit 0

cfg_get() { k="$1"; [ -r "$CONFIG_FILE" ] || return 0; grep -E "^${k}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${k}=//" | tr -d '\r'; }
cfg_set() { k="$1"; v="$2"; tmp="${CONFIG_FILE}.tmp.$$"; touch "$CONFIG_FILE" 2>/dev/null || true; grep -v "^${k}=" "$CONFIG_FILE" 2>/dev/null > "$tmp" || true; printf "%s=%s\n" "$k" "$v" >> "$tmp"; mv "$tmp" "$CONFIG_FILE"; chmod 0600 "$CONFIG_FILE" 2>/dev/null || true; }

ptune_present() {
  for d in /data/adb/modules/ptune /data/adb/modules_update/ptune; do
    [ -f "$d/module.prop" ] || continue
    grep -q '^id=ptune$' "$d/module.prop" 2>/dev/null || continue
    [ -e "$d/remove" ] && continue
    echo "$d"; return 0
  done
  return 1
}
foreign_thermal_overlay() {
  for root in /data/adb/modules /data/adb/modules_update; do
    [ -d "$root" ] || continue
    for d in "$root"/*; do
      [ -d "$d" ] || continue
      b="$(basename "$d")"
      [ "$b" = "$MODULE_ID" ] && continue
      [ "$b" = "ptune" ] && continue
      [ -e "$d/remove" ] && continue
      [ -e "$d/disable" ] && continue
      if find "$d/system/vendor/etc" -maxdepth 1 -type f -name 'thermal_info_config*.json' 2>/dev/null | grep -q .; then echo "$d"; return 0; fi
    done
  done
  return 1
}
has_remembered() {
  for k in LAST_THERMAL_OUTDOOR_PROFILE LAST_THERMAL_POLLING_MODE LAST_PTUNE_OVERRIDE LAST_THERMAL_SAFETY_LEVEL LAST_DEBUG_MODE LAST_ZRAM_100P THERMAL_OUTDOOR_PROFILE THERMAL_POLLING_MODE DEBUG_MODE ENABLE_ZRAM_100P; do
    [ -n "$(cfg_get "$k")" ] && return 0
  done
  return 1
}

remember_idx=1; has_remembered && remember_idx=0
mc_cycle2 "Remember Settings" "Use last" "Fresh defaults" "$remember_idx"
if [ "$MC_INDEX" = "0" ]; then
  cfg_set THERMAL_SETTINGS_MODE last; mc_msg "Settings: last"
else
  cfg_set THERMAL_SETTINGS_MODE fresh
  cfg_set DEBUG_MODE 1; cfg_set debug_mode 1; cfg_set LAST_DEBUG_MODE verbose
  cfg_set THERMAL_OUTDOOR_PROFILE stock
  cfg_set THERMAL_POLLING_MODE mod
  cfg_set THERMAL_SAFETY_LEVEL normal
  cfg_set ALLOW_THERMAL_WITH_PTUNE 1
  cfg_set RISK_ACK_PTUNE_THERMAL_COLLISION I_UNDERSTAND_BOOTLOOP_RISK
  cfg_set DEBUG_MODE 0; cfg_set debug_mode 0
  cfg_set ENABLE_ZRAM_100P 1; cfg_set ZRAM_RESTART_MMD 1
  mc_msg "Settings: fresh"
fi

case "$(cfg_get THERMAL_SAFETY_LEVEL)" in strict) safety_idx=1 ;; *) safety_idx=0 ;; esac
mc_cycle2 "Safety Level" "Normal" "Strict" "$safety_idx"
if [ "$MC_INDEX" = "1" ]; then safety=strict; else safety=normal; fi
cfg_set THERMAL_SAFETY_LEVEL "$safety"; cfg_set LAST_THERMAL_SAFETY_LEVEL "$safety"

foreign_path="$(foreign_thermal_overlay 2>/dev/null || true)"
ptune_path="$(ptune_present 2>/dev/null || true)"
if [ -n "$foreign_path" ]; then
  cfg_set THERMAL_CONFLICT foreign_overlay; cfg_set THERMAL_CONFLICT_PATH "$foreign_path"; cfg_set THERMAL_POLLING_CONFLICT foreign_polling_drift
else
  cfg_set THERMAL_CONFLICT none; cfg_set THERMAL_CONFLICT_PATH none; cfg_set THERMAL_POLLING_CONFLICT none
fi
if [ -n "$ptune_path" ]; then cfg_set PTUNE_CONFLICT present; cfg_set PTUNE_CONFLICT_PATH "$ptune_path"; else cfg_set PTUNE_CONFLICT none; cfg_set PTUNE_CONFLICT_PATH none; fi

mc_msg ""; mc_msg "Conflict scan"
[ -n "$foreign_path" ] && mc_msg "Thermal: foreign overlay" || mc_msg "Thermal: PASS"
[ -n "$foreign_path" ] && mc_msg "Polling: foreign drift" || mc_msg "Polling: PASS"
[ -n "$ptune_path" ] && mc_msg "pTune: present" || mc_msg "pTune: none"
if [ "$safety" = "strict" ] && [ -n "$foreign_path" ]; then cfg_set THERMAL_MAX_PROFILE outdoor-safe; mc_msg "Strict: max Safe"; else cfg_set THERMAL_MAX_PROFILE outdoor-extended; fi

case "$(cfg_get THERMAL_POLLING_MODE)" in stock) polling_idx=1 ;; *) polling_idx=0 ;; esac
mc_cycle2 "Polling Fix" "Mod values" "Stock values" "$polling_idx"
[ "$MC_INDEX" = "1" ] && polling=stock || polling=mod
if [ "$safety" = "strict" ] && [ -n "$foreign_path" ] && [ "$polling" = "mod" ]; then polling=stock; mc_msg "Strict: Stock polling"; fi
cfg_set THERMAL_POLLING_MODE "$polling"; cfg_set LAST_THERMAL_POLLING_MODE "$polling"

allow="$(cfg_get ALLOW_THERMAL_WITH_PTUNE)"; risk="$(cfg_get RISK_ACK_PTUNE_THERMAL_COLLISION)"
case "$allow:$risk" in 1:I_UNDERSTAND_BOOTLOOP_RISK) ptune_idx=0 ;; *) ptune_idx=1 ;; esac
mc_cycle2 "pTune Override" "Override ON" "Override OFF" "$ptune_idx"
if [ "$MC_INDEX" = "0" ]; then
  cfg_set PTUNE_OVERRIDE_MENU on
  cfg_set ALLOW_THERMAL_WITH_PTUNE 1
  cfg_set RISK_ACK_PTUNE_THERMAL_COLLISION I_UNDERSTAND_BOOTLOOP_RISK
  cfg_set LAST_PTUNE_OVERRIDE 1
else
  cfg_set PTUNE_OVERRIDE_MENU off
  cfg_set ALLOW_THERMAL_WITH_PTUNE 0
  cfg_set RISK_ACK_PTUNE_THERMAL_COLLISION none
  cfg_set LAST_PTUNE_OVERRIDE 0
fi

mc_msg ""; mc_msg "Install choices"
mc_msg "Safety: $safety"
mc_msg "Polling: $polling"
mc_msg "pTune: $(cfg_get PTUNE_OVERRIDE_MENU)"
mc_msg "----------------------------------------"
exit 0
