#!/system/bin/sh
set -eu

MODDIR="${MODDIR:-${0%/*}/..}"
BASE_PROFILE="${BASE_PROFILE:-}"
CONFIG_FILE="${CONFIG_FILE:-/data/adb/pixel-10-pro-xl-thermal-fix/config.env}"
LOG="${LOG:-/dev/null}"

mkdir -p "$(dirname "$CONFIG_FILE")" 2>/dev/null || true
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true

msg() {
  if command -v ui_print >/dev/null 2>&1; then ui_print "$*"; else echo "$*"; fi
  [ "$LOG" = "/dev/null" ] || echo "$*" >> "$LOG" 2>/dev/null || true
}

cfg_set() {
  _k="$1"
  _v="$2"
  _tmp="${CONFIG_FILE}.tmp.$$"
  touch "$CONFIG_FILE" 2>/dev/null || true
  grep -v "^${_k}=" "$CONFIG_FILE" 2>/dev/null > "$_tmp" || true
  printf "%s=%s\n" "$_k" "$_v" >> "$_tmp"
  mv "$_tmp" "$CONFIG_FILE"
}

read_key() {
  _key=""
  if command -v getevent >/dev/null 2>&1; then
    _key="$(timeout 10 getevent -qlc 1 2>/dev/null | grep -E "KEY_VOLUMEUP|KEY_VOLUMEDOWN|KEY_POWER" | head -1 || true)"
  fi
  case "$_key" in
    *KEY_VOLUMEUP*) echo up ;;
    *KEY_VOLUMEDOWN*) echo down ;;
    *KEY_POWER*) echo power ;;
    *) echo timeout ;;
  esac
}

variant_exists() {
  _variant="$1"
  case "$_variant" in
    stock|base) return 0 ;;
    outdoor-safe|outdoor-plus|outdoor-extended)
      [ -s "$MODDIR/profiles/${BASE_PROFILE}-${_variant}/system/vendor/etc/thermal_info_config_throttling.json" ]
    ;;
    *) return 1 ;;
  esac
}

choice="stock"

msg "----------------------------------------"
msg "Outdoor profile"
msg "Volume Up: outdoor-safe"
msg "Volume Down: stock/default"
msg "Power/Timeout: plus/extended menu"
msg "----------------------------------------"

case "$(read_key)" in
  up) choice="outdoor-safe" ;;
  down|timeout) choice="stock" ;;
  power) choice="stock_then_more" ;;
esac

if [ "$choice" = "stock_then_more" ]; then
  msg "----------------------------------------"
  msg "Stronger outdoor profile"
  msg "Volume Up: outdoor-plus"
  msg "Power: outdoor-extended"
  msg "Volume Down/Timeout: stock/default"
  msg "----------------------------------------"
  case "$(read_key)" in
    up) choice="outdoor-plus" ;;
    power) choice="outdoor-extended" ;;
    *) choice="stock" ;;
  esac
fi

if ! variant_exists "$choice"; then
  msg "! selected outdoor variant missing: $choice"
  choice="stock"
fi

case "$choice" in
  outdoor-safe)
    cfg_set THERMAL_OUTDOOR_PROFILE outdoor-safe
    cfg_set THERMAL_OUTDOOR_TARGET outdoor_safe
    cfg_set THERMAL_OUTDOOR_RISK_ACK explicit_user_enable
    cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE test9_full_matrix
    msg "selected: outdoor-safe"
  ;;
  outdoor-plus)
    cfg_set THERMAL_OUTDOOR_PROFILE outdoor-plus
    cfg_set THERMAL_OUTDOOR_TARGET outdoor_plus
    cfg_set THERMAL_OUTDOOR_RISK_ACK explicit_user_enable
    cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE test9_full_matrix
    msg "selected: outdoor-plus"
  ;;
  outdoor-extended)
    cfg_set THERMAL_OUTDOOR_PROFILE outdoor-extended
    cfg_set THERMAL_OUTDOOR_TARGET outdoor_extended
    cfg_set THERMAL_OUTDOOR_RISK_ACK explicit_user_enable_extended
    cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE test9_full_matrix
    msg "selected: outdoor-extended"
  ;;
  *)
    cfg_set THERMAL_OUTDOOR_PROFILE stock
    cfg_set THERMAL_OUTDOOR_TARGET stock
    cfg_set THERMAL_OUTDOOR_RISK_ACK disabled_by_user_or_timeout
    cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE stock
    msg "selected: stock/default"
  ;;
esac

if [ "$LOG" != "/dev/null" ]; then
  {
    echo "choice=$choice"
    echo
    echo "== after =="
    grep -E "^(THERMAL_OUTDOOR_PROFILE|THERMAL_OUTDOOR_RISK_ACK|THERMAL_OUTDOOR_PROFILE_SOURCE|THERMAL_OUTDOOR_TARGET)=" "$CONFIG_FILE" 2>/dev/null || true
    echo "RESULT: PIXEL_THERMAL_OUTDOOR_MENU_DONE choice=$choice"
  } >> "$LOG" 2>&1 || true
fi

exit 0
