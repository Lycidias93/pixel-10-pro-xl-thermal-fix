#!/system/bin/sh
set -eu

MODDIR="${MODDIR:-${0%/*}/..}"
BASE_PROFILE="${BASE_PROFILE:-}"
CONFIG_FILE="${CONFIG_FILE:-/data/adb/pixel-10-pro-xl-thermal-fix/config.env}"
LOG="${LOG:-/dev/null}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-30}"
DEBOUNCE_SECONDS="${DEBOUNCE_SECONDS:-1.20}"

mkdir -p "$(dirname "$CONFIG_FILE")" 2>/dev/null || true
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true

msg() {
  if command -v ui_print >/dev/null 2>&1; then ui_print "$*"; else echo "$*"; fi
  [ "$LOG" = "/dev/null" ] || echo "$*" >> "$LOG" 2>/dev/null || true
}

cfg_get() {
  _k="$1"
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^${_k}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${_k}=//" | tr -d '\r'
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

read_key_once() {
  # Magisk/getevent compatibility:
  # Accept any Volume Up/Down event, because DOWN-only formatting varies.
  # Sleep before and after reading to avoid counting key release as a second press.
  sleep 0.25 2>/dev/null || true

  if ! command -v getevent >/dev/null 2>&1; then
    echo timeout
    return 0
  fi

  _ev=""
  if command -v timeout >/dev/null 2>&1; then
    _ev="$(timeout "$TIMEOUT_SECONDS" sh -c 'getevent -ql 2>/dev/null | grep -m 1 -E "KEY_VOLUMEUP|KEY_VOLUMEDOWN"' 2>/dev/null || true)"
  else
    _ev="$(getevent -ql 2>/dev/null | grep -m 1 -E "KEY_VOLUMEUP|KEY_VOLUMEDOWN" 2>/dev/null || true)"
  fi

  case "$_ev" in
    *KEY_VOLUMEUP*) sleep "$DEBOUNCE_SECONDS" 2>/dev/null || true; echo up ;;
    *KEY_VOLUMEDOWN*) sleep "$DEBOUNCE_SECONDS" 2>/dev/null || true; echo down ;;
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

option_at() {
  case "$1" in
    0) echo stock ;;
    1) echo outdoor-safe ;;
    2) echo outdoor-plus ;;
    3) echo outdoor-extended ;;
    *) echo stock ;;
  esac
}

index_for() {
  case "$1" in
    outdoor-safe) echo 1 ;;
    outdoor-plus) echo 2 ;;
    outdoor-extended) echo 3 ;;
    *) echo 0 ;;
  esac
}

label_for() {
  case "$1" in
    stock) echo "Stock / Factory" ;;
    outdoor-safe) echo "Outdoor Safe" ;;
    outdoor-plus) echo "Outdoor Plus" ;;
    outdoor-extended) echo "Outdoor Extended" ;;
    *) echo "Stock / Factory" ;;
  esac
}

long_label_for() {
  case "$1" in
    stock) echo "Stock / Factory Thermal" ;;
    outdoor-safe) echo "Outdoor Safe Throttle Fix" ;;
    outdoor-plus) echo "Outdoor Plus Throttle Fix" ;;
    outdoor-extended) echo "Outdoor Extended Throttle Fix" ;;
    *) echo "Stock / Factory Thermal" ;;
  esac
}

show_current() {
  _idx="$1"
  _profile="$(option_at "$_idx")"
  _label="$(label_for "$_profile")"
  _pos=$(( _idx + 1 ))
  msg "Current $_pos/4: $_label"
}

existing="$(cfg_get THERMAL_OUTDOOR_PROFILE)"
idx="$(index_for "$existing")"
choice="$(option_at "$idx")"
steps=0
confirm_reason="timeout"

msg ""
msg "----------------------------------------"
msg "Thermal Throttle Fix"
msg "----------------------------------------"
msg "1 Stock / Factory"
msg "2 Outdoor Safe"
msg "3 Outdoor Plus"
msg "4 Outdoor Extended"
msg ""
msg "Vol+  next"
msg "Vol-  select"
msg "30s   keep shown"
msg "Power not used"
msg "----------------------------------------"
show_current "$idx"

while [ "$steps" -lt 12 ]; do
  key="$(read_key_once)"
  case "$key" in
    up)
      idx=$(( (idx + 1) % 4 ))
      steps=$(( steps + 1 ))
      show_current "$idx"
    ;;
    down)
      choice="$(option_at "$idx")"
      confirm_reason="volume_down"
      break
    ;;
    timeout)
      choice="$(option_at "$idx")"
      confirm_reason="timeout"
      break
    ;;
  esac
done

if [ "$steps" -ge 12 ]; then
  choice="$(option_at "$idx")"
  confirm_reason="max_steps"
fi

if ! variant_exists "$choice"; then
  msg ""
  msg "! Missing profile: $choice"
  msg "! Fallback: Stock / Factory"
  choice="stock"
  confirm_reason="missing_profile_fallback"
fi

choice_label="$(long_label_for "$choice")"

msg ""
msg "Confirmed:"
msg "$choice_label"
msg "----------------------------------------"

case "$choice" in
  outdoor-safe)
    cfg_set THERMAL_OUTDOOR_PROFILE outdoor-safe
    cfg_set THERMAL_OUTDOOR_TARGET outdoor_safe
    cfg_set THERMAL_OUTDOOR_RISK_ACK explicit_user_enable
    cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE test14_compact_cycle
  ;;
  outdoor-plus)
    cfg_set THERMAL_OUTDOOR_PROFILE outdoor-plus
    cfg_set THERMAL_OUTDOOR_TARGET outdoor_plus
    cfg_set THERMAL_OUTDOOR_RISK_ACK explicit_user_enable
    cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE test14_compact_cycle
  ;;
  outdoor-extended)
    cfg_set THERMAL_OUTDOOR_PROFILE outdoor-extended
    cfg_set THERMAL_OUTDOOR_TARGET outdoor_extended
    cfg_set THERMAL_OUTDOOR_RISK_ACK explicit_user_enable_extended
    cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE test14_compact_cycle
  ;;
  *)
    cfg_set THERMAL_OUTDOOR_PROFILE stock
    cfg_set THERMAL_OUTDOOR_TARGET stock
    cfg_set THERMAL_OUTDOOR_RISK_ACK disabled_or_stock_selected
    cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE stock
  ;;
esac

if [ "$LOG" != "/dev/null" ]; then
  {
    echo "choice=$choice"
    echo "choice_label=$choice_label"
    echo "confirm_reason=$confirm_reason"
    echo "steps=$steps"
    echo "timeout_seconds=$TIMEOUT_SECONDS"
    echo "debounce_seconds=$DEBOUNCE_SECONDS"
    echo
    echo "== after =="
    grep -E "^(THERMAL_OUTDOOR_PROFILE|THERMAL_OUTDOOR_RISK_ACK|THERMAL_OUTDOOR_PROFILE_SOURCE|THERMAL_OUTDOOR_TARGET)=" "$CONFIG_FILE" 2>/dev/null || true
    echo "RESULT: PIXEL_THERMAL_OUTDOOR_MENU_DONE choice=$choice confirm_reason=$confirm_reason steps=$steps"
  } >> "$LOG" 2>&1 || true
fi

exit 0
