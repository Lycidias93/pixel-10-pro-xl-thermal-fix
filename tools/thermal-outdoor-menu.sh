#!/system/bin/sh
set -eu
MODDIR="${MODDIR:-${0%/*}/..}"
BASE_PROFILE="${BASE_PROFILE:-}"
CONFIG_FILE="${CONFIG_FILE:-/data/adb/pixel-10-pro-xl-thermal-fix/config.env}"
LOG="${LOG:-/dev/null}"
mkdir -p "$(dirname "$CONFIG_FILE")" 2>/dev/null || true
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true
[ -s "$MODDIR/tools/menu-cycle.sh" ] && . "$MODDIR/tools/menu-cycle.sh" || exit 0

msg() { if command -v ui_print >/dev/null 2>&1; then ui_print "$*"; else echo "$*"; fi; [ "$LOG" = "/dev/null" ] || echo "$*" >> "$LOG" 2>/dev/null || true; }
cfg_get() { _k="$1"; [ -r "$CONFIG_FILE" ] || return 0; grep -E "^${_k}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${_k}=//" | tr -d '\r'; }
cfg_set() { _k="$1"; _v="$2"; _tmp="${CONFIG_FILE}.tmp.$$"; touch "$CONFIG_FILE" 2>/dev/null || true; grep -v "^${_k}=" "$CONFIG_FILE" 2>/dev/null > "$_tmp" || true; printf "%s=%s\n" "$_k" "$_v" >> "$_tmp"; mv "$_tmp" "$CONFIG_FILE"; }

variant_exists() { _variant="$1"; case "$_variant" in stock|base) return 0 ;; outdoor-safe|outdoor-plus|outdoor-extended) [ -s "$MODDIR/profiles/${BASE_PROFILE}-${_variant}/system/vendor/etc/thermal_info_config_throttling.json" ] ;; *) return 1 ;; esac; }
option_at() { case "$1" in 0) echo stock ;; 1) echo outdoor-safe ;; 2) echo outdoor-plus ;; 3) echo outdoor-extended ;; *) echo stock ;; esac; }
index_for() { case "$1" in outdoor-safe) echo 1 ;; outdoor-plus) echo 2 ;; outdoor-extended) echo 3 ;; *) echo 0 ;; esac; }
long_label_for() { case "$1" in stock) echo "Stock thermal" ;; outdoor-safe) echo "Outdoor Safe" ;; outdoor-plus) echo "Outdoor Plus" ;; outdoor-extended) echo "Outdoor Extended" ;; *) echo "Stock thermal" ;; esac; }

if [ "$(cfg_get THERMAL_SETTINGS_MODE)" = "last" ]; then
  choice="$(cfg_get THERMAL_OUTDOOR_PROFILE)"
  [ -n "$choice" ] || choice="$(cfg_get LAST_THERMAL_OUTDOOR_PROFILE)"
  case "$choice" in outdoor-safe|outdoor-plus|outdoor-extended) ;; *) choice=stock ;; esac
  max_profile="$(cfg_get THERMAL_MAX_PROFILE)"
  safety="$(cfg_get THERMAL_SAFETY_LEVEL)"
  case "$max_profile:$choice" in outdoor-safe:outdoor-plus|outdoor-safe:outdoor-extended) choice="outdoor-safe" ;; esac
  if ! variant_exists "$choice"; then
    msg ""
    msg "! Missing remembered profile: $choice"
    msg "! Fallback: Stock"
    choice="stock"
    confirm_reason="use_last_missing_profile_fallback"
  else
    confirm_reason="use_last_short_circuit"
  fi
  choice_label="$(long_label_for "$choice")"
  msg ""
  msg "Use last settings:"
  msg "$choice_label"
  msg "----------------------------------------"
  case "$choice" in
    outdoor-safe) cfg_set THERMAL_OUTDOOR_PROFILE outdoor-safe; cfg_set THERMAL_OUTDOOR_TARGET outdoor_safe; cfg_set THERMAL_OUTDOOR_RISK_ACK explicit_user_enable; cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE use_last_short_circuit_test28 ;;
    outdoor-plus) cfg_set THERMAL_OUTDOOR_PROFILE outdoor-plus; cfg_set THERMAL_OUTDOOR_TARGET outdoor_plus; cfg_set THERMAL_OUTDOOR_RISK_ACK explicit_user_enable; cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE use_last_short_circuit_test28 ;;
    outdoor-extended) cfg_set THERMAL_OUTDOOR_PROFILE outdoor-extended; cfg_set THERMAL_OUTDOOR_TARGET outdoor_extended; cfg_set THERMAL_OUTDOOR_RISK_ACK explicit_user_enable_extended; cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE use_last_short_circuit_test28 ;;
    *) cfg_set THERMAL_OUTDOOR_PROFILE stock; cfg_set THERMAL_OUTDOOR_TARGET stock; cfg_set THERMAL_OUTDOOR_RISK_ACK disabled_or_stock_selected; cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE use_last_short_circuit_test28 ;;
  esac
  cfg_set LAST_THERMAL_OUTDOOR_PROFILE "$choice"
  if [ "$LOG" != "/dev/null" ]; then
    { echo "choice=$choice"; echo "choice_label=$choice_label"; echo "confirm_reason=$confirm_reason"; echo "steps=0"; echo "safety=$safety"; echo "max_profile=$max_profile"; echo; echo "== after =="; grep -E "^(THERMAL_OUTDOOR_PROFILE|THERMAL_OUTDOOR_RISK_ACK|THERMAL_OUTDOOR_PROFILE_SOURCE|THERMAL_OUTDOOR_TARGET|THERMAL_SAFETY_LEVEL|THERMAL_MAX_PROFILE)=" "$CONFIG_FILE" 2>/dev/null || true; echo "RESULT: PIXEL_THERMAL_OUTDOOR_MENU_SKIPPED_USE_LAST choice=$choice confirm_reason=$confirm_reason steps=0"; } >> "$LOG" 2>&1 || true
  fi
  exit 0
fi

idx="$(index_for "$(cfg_get THERMAL_OUTDOOR_PROFILE)")"
mc_cycle4 "Thermal Profile" "Stock" "Outdoor Safe" "Outdoor Plus" "Outdoor Ext" "$idx"
choice="$(option_at "$MC_INDEX")"; confirm_reason="$MC_REASON"; steps="$MC_STEPS"
max_profile="$(cfg_get THERMAL_MAX_PROFILE)"; safety="$(cfg_get THERMAL_SAFETY_LEVEL)"
case "$max_profile:$choice" in outdoor-safe:outdoor-plus|outdoor-safe:outdoor-extended) choice="outdoor-safe"; confirm_reason="${confirm_reason}_strict_blocked_to_safe"; msg ""; msg "Strict conflict block:"; msg "Using Outdoor Safe" ;; esac
if ! variant_exists "$choice"; then msg ""; msg "! Missing profile: $choice"; msg "! Fallback: Stock"; choice="stock"; confirm_reason="missing_profile_fallback"; fi
choice_label="$(long_label_for "$choice")"
msg ""; msg "Confirmed:"; msg "$choice_label"; msg "----------------------------------------"

case "$choice" in
  outdoor-safe) cfg_set THERMAL_OUTDOOR_PROFILE outdoor-safe; cfg_set THERMAL_OUTDOOR_TARGET outdoor_safe; cfg_set THERMAL_OUTDOOR_RISK_ACK explicit_user_enable; cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE test17_full_menu ;;
  outdoor-plus) cfg_set THERMAL_OUTDOOR_PROFILE outdoor-plus; cfg_set THERMAL_OUTDOOR_TARGET outdoor_plus; cfg_set THERMAL_OUTDOOR_RISK_ACK explicit_user_enable; cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE test17_full_menu ;;
  outdoor-extended) cfg_set THERMAL_OUTDOOR_PROFILE outdoor-extended; cfg_set THERMAL_OUTDOOR_TARGET outdoor_extended; cfg_set THERMAL_OUTDOOR_RISK_ACK explicit_user_enable_extended; cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE test17_full_menu ;;
  *) cfg_set THERMAL_OUTDOOR_PROFILE stock; cfg_set THERMAL_OUTDOOR_TARGET stock; cfg_set THERMAL_OUTDOOR_RISK_ACK disabled_or_stock_selected; cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE stock ;;
esac
cfg_set LAST_THERMAL_OUTDOOR_PROFILE "$choice"

if [ "$LOG" != "/dev/null" ]; then
  { echo "choice=$choice"; echo "choice_label=$choice_label"; echo "confirm_reason=$confirm_reason"; echo "steps=$steps"; echo "safety=$safety"; echo "max_profile=$max_profile"; echo; echo "== after =="; grep -E "^(THERMAL_OUTDOOR_PROFILE|THERMAL_OUTDOOR_RISK_ACK|THERMAL_OUTDOOR_PROFILE_SOURCE|THERMAL_OUTDOOR_TARGET|THERMAL_SAFETY_LEVEL|THERMAL_MAX_PROFILE)=" "$CONFIG_FILE" 2>/dev/null || true; echo "RESULT: PIXEL_THERMAL_OUTDOOR_MENU_DONE choice=$choice confirm_reason=$confirm_reason steps=$steps"; } >> "$LOG" 2>&1 || true
fi
exit 0
