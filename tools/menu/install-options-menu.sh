#!/system/bin/sh
set -eu
MODULE_ID="${MODULE_ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-${0%/*}/..}"
CONFIG_DIR="/data/adb/$MODULE_ID"
CONFIG_FILE="$CONFIG_DIR/config.env"
mkdir -p "$CONFIG_DIR" 2>/dev/null || true
touch "$CONFIG_FILE" 2>/dev/null || true
chmod 0600 "$CONFIG_FILE" 2>/dev/null || true
[ -s "$MODDIR/tools/menu/menu-cycle.sh" ] && . "$MODDIR/tools/menu/menu-cycle.sh" || exit 0

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
has_remembered() {
  for k in LAST_THERMAL_OUTDOOR_PROFILE LAST_THERMAL_POLLING_MODE LAST_PTUNE_OVERRIDE LAST_DEBUG_MODE LAST_ZRAM_100P THERMAL_OUTDOOR_PROFILE THERMAL_POLLING_MODE DEBUG_MODE ENABLE_ZRAM_100P; do
    [ -n "$(cfg_get "$k")" ] && return 0
  done
  return 1
}

target_for_profile() {
  case "$1" in
    outdoor-safe) echo outdoor_safe ;;
    outdoor-plus) echo outdoor_plus ;;
    outdoor-extended) echo outdoor_extended ;;
    *) echo stock ;;
  esac
}

risk_for_profile() {
  case "$1" in
    outdoor-safe|outdoor-plus) echo explicit_user_enable ;;
    outdoor-extended) echo explicit_user_enable_extended ;;
    *) echo disabled_or_stock_selected ;;
  esac
}

apply_last_settings_and_exit() {
  cfg_set THERMAL_SETTINGS_MODE last

  ptune_path="$(ptune_present 2>/dev/null || true)"
  if [ -n "$ptune_path" ]; then
    cfg_set PTUNE_CONFLICT present
    cfg_set PTUNE_CONFLICT_PATH "$ptune_path"
  else
    cfg_set PTUNE_CONFLICT none
    cfg_set PTUNE_CONFLICT_PATH none
  fi

  last_profile="$(cfg_get LAST_THERMAL_OUTDOOR_PROFILE)"
  [ -n "$last_profile" ] || last_profile="$(cfg_get THERMAL_OUTDOOR_PROFILE)"
  case "$last_profile" in outdoor-safe|outdoor-plus|outdoor-extended) profile_choice="$last_profile" ;; *) profile_choice=stock ;; esac
  cfg_set THERMAL_OUTDOOR_PROFILE "$profile_choice"
  cfg_set THERMAL_OUTDOOR_TARGET "$(target_for_profile "$profile_choice")"
  cfg_set THERMAL_OUTDOOR_RISK_ACK "$(risk_for_profile "$profile_choice")"
  cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE use_last_short_circuit_test28
  cfg_set LAST_THERMAL_OUTDOOR_PROFILE "$profile_choice"

  last_polling="$(cfg_get LAST_THERMAL_POLLING_MODE)"
  [ -n "$last_polling" ] || last_polling="$(cfg_get THERMAL_POLLING_MODE)"
  case "$last_polling" in stock) polling=stock ;; *) polling=mod ;; esac
  cfg_set THERMAL_POLLING_MODE "$polling"
  cfg_set LAST_THERMAL_POLLING_MODE "$polling"

  last_ptune="$(cfg_get LAST_PTUNE_OVERRIDE)"
  [ -n "$last_ptune" ] || last_ptune="$(cfg_get ALLOW_THERMAL_WITH_PTUNE)"
  case "$last_ptune" in
    1)
      cfg_set PTUNE_OVERRIDE_MENU on
      cfg_set ALLOW_THERMAL_WITH_PTUNE 1
      cfg_set RISK_ACK_PTUNE_THERMAL_COLLISION I_UNDERSTAND_BOOTLOOP_RISK
      cfg_set LAST_PTUNE_OVERRIDE 1
    ;;
    *)
      cfg_set PTUNE_OVERRIDE_MENU off
      cfg_set ALLOW_THERMAL_WITH_PTUNE 0
      cfg_set RISK_ACK_PTUNE_THERMAL_COLLISION none
      cfg_set LAST_PTUNE_OVERRIDE 0
    ;;
  esac

  last_debug="$(cfg_get LAST_DEBUG_MODE)"
  [ -n "$last_debug" ] || last_debug="$(cfg_get DEBUG_MODE)"
  case "$last_debug" in silent|0)
    cfg_set DEBUG_MODE 0
    cfg_set debug_mode 0
    cfg_set LAST_DEBUG_MODE silent
  ;;
    *)
    cfg_set DEBUG_MODE 1
    cfg_set debug_mode 1
    cfg_set LAST_DEBUG_MODE verbose
  ;;
  esac

  last_zram="$(cfg_get LAST_ZRAM_100P)"
  [ -n "$last_zram" ] || last_zram="$(cfg_get ENABLE_ZRAM_100P)"
  case "$last_zram" in disabled|0)
    cfg_set ENABLE_ZRAM_100P 0
    cfg_set ZRAM_RESTART_MMD 0
    cfg_set ZRAM_RISK_ACK disabled_by_user
    cfg_set LAST_ZRAM_100P disabled
  ;;
    *)
    cfg_set ENABLE_ZRAM_100P 1
    cfg_set ZRAM_RESTART_MMD 1
    cfg_set ZRAM_RISK_ACK explicit_user_enable
    cfg_set LAST_ZRAM_100P enabled
  ;;
  esac

  mc_msg ""
  mc_msg "Use last settings"
  mc_msg "Outdoor: $(cfg_get THERMAL_OUTDOOR_PROFILE)"
  mc_msg "Polling: $(cfg_get THERMAL_POLLING_MODE)"
  mc_msg "pTune: $(cfg_get PTUNE_OVERRIDE_MENU)"
  mc_msg "ZRAM: $(cfg_get LAST_ZRAM_100P)"
  mc_msg "No further install menus"
  mc_msg "----------------------------------------"
  exit 0
}

remember_idx=1; has_remembered && remember_idx=0
mc_cycle2 "Remember Settings" "Use last" "Fresh defaults" "$remember_idx"
if [ "$MC_INDEX" = "0" ]; then
  if has_remembered; then
    cfg_set THERMAL_SETTINGS_MODE last
    cfg_set USE_LAST_FALLBACK none
    mc_msg "Settings: last"
    apply_last_settings_and_exit
  fi
  cfg_set USE_LAST_FALLBACK no_saved_fresh_defaults_test28
  mc_msg ""
  mc_msg "No saved settings found"
  mc_msg "Using fresh defaults"
  MC_INDEX=1
fi
if [ "$MC_INDEX" != "0" ]; then
  cfg_set THERMAL_SETTINGS_MODE fresh
  cfg_set DEBUG_MODE 1; cfg_set debug_mode 1; cfg_set LAST_DEBUG_MODE verbose
  cfg_set THERMAL_OUTDOOR_PROFILE stock
  cfg_set THERMAL_POLLING_MODE mod
  cfg_set ALLOW_THERMAL_WITH_PTUNE 0
  cfg_set RISK_ACK_PTUNE_THERMAL_COLLISION none
  cfg_set ENABLE_ZRAM_100P 0
  cfg_set ZRAM_RESTART_MMD 0
  cfg_set ZRAM_RISK_ACK disabled_by_user
  cfg_set LAST_ZRAM_100P disabled
  mc_msg "Settings: fresh"
fi
  ptune_path="$(ptune_present 2>/dev/null || true)"
  if [ -n "$ptune_path" ]; then
    cfg_set PTUNE_CONFLICT present
    cfg_set PTUNE_CONFLICT_PATH "$ptune_path"
  else
    cfg_set PTUNE_CONFLICT none
    cfg_set PTUNE_CONFLICT_PATH none
  fi

  mc_msg ""
  mc_msg "Conflict scan"
  mc_msg "Checks pTune status"
  [ -n "$ptune_path" ] && mc_msg "pTune: present" || mc_msg "pTune: none"

  case "$(cfg_get THERMAL_POLLING_MODE)" in stock) polling_idx=1 ;; *) polling_idx=0 ;; esac
  mc_cycle2 "Polling Fix" "Mod values" "Stock values" "$polling_idx"
  [ "$MC_INDEX" = "1" ] && polling=stock || polling=mod
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

  mc_msg ""
  mc_msg "Install choices"
  mc_msg "Final selected install state."
  mc_msg "Polling: $polling"
  mc_msg "pTune: $(cfg_get PTUNE_OVERRIDE_MENU)"
  mc_msg "----------------------------------------"
  exit 0
