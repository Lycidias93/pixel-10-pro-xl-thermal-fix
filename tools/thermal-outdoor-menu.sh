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
    _key="$(timeout 12 getevent -qlc 1 2>/dev/null | grep -E "KEY_VOLUMEUP|KEY_VOLUMEDOWN" | head -1 || true)"
  fi
  case "$_key" in
    *KEY_VOLUMEUP*) echo up ;;
    *KEY_VOLUMEDOWN*) echo down ;;
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

label_for() {
  case "$1" in
    stock) echo "Stock / Factory Thermal" ;;
    outdoor-safe) echo "Outdoor Safe Throttle Fix" ;;
    outdoor-plus) echo "Outdoor Plus Throttle Fix" ;;
    outdoor-extended) echo "Outdoor Extended Throttle Fix" ;;
    *) echo "Stock / Factory Thermal" ;;
  esac
}

index_label() {
  case "$1" in
    0) echo "1/4" ;;
    1) echo "2/4" ;;
    2) echo "3/4" ;;
    3) echo "4/4" ;;
    *) echo "1/4" ;;
  esac
}


show_current_clean() {
  _idx="$1"
  _profile="$(option_at "$_idx")"
  _label="$(label_for "$_profile")"
  _num="$(index_label "$_idx")"
  msg "Selected [$_num]: $_label"
}

idx=0
choice="stock"
steps=0
confirm_reason="timeout"

msg ""
msg "----------------------------------------"
msg "Thermal Throttle Fix Profile"
msg "----------------------------------------"
msg "All options are cycle-selectable:"
msg "[1/4] Stock / Factory Thermal"
msg "[2/4] Outdoor Safe Throttle Fix"
msg "[3/4] Outdoor Plus Throttle Fix"
msg "[4/4] Outdoor Extended Throttle Fix"
msg ""
msg "Volume Up   = next profile"
msg "Volume Down = confirm shown profile"
msg "Timeout     = confirm shown profile"
msg "Power       = not used"
msg "----------------------------------------"
show_current_clean "$idx"

while [ "$steps" -lt 16 ]; do
  key="$(read_key)"
  case "$key" in
    up)
      idx=$(( (idx + 1) % 4 ))
      steps=$(( steps + 1 ))
      show_current_clean "$idx"
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

if [ "$steps" -ge 16 ]; then
  choice="$(option_at "$idx")"
  confirm_reason="max_steps"
fi

if ! variant_exists "$choice"; then
  msg ""
  msg "! Selected profile files are missing: $choice"
  msg "! Falling back to Stock / Factory Thermal"
  choice="stock"
  confirm_reason="missing_profile_fallback"
fi

choice_label="$(label_for "$choice")"

msg ""
msg "Confirmed Thermal Throttle Fix Profile:"
msg "$choice_label"
msg "----------------------------------------"

case "$choice" in
  outdoor-safe)
    cfg_set THERMAL_OUTDOOR_PROFILE outdoor-safe
    cfg_set THERMAL_OUTDOOR_TARGET outdoor_safe
    cfg_set THERMAL_OUTDOOR_RISK_ACK explicit_user_enable
    cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE test12_clean_cycle
  ;;
  outdoor-plus)
    cfg_set THERMAL_OUTDOOR_PROFILE outdoor-plus
    cfg_set THERMAL_OUTDOOR_TARGET outdoor_plus
    cfg_set THERMAL_OUTDOOR_RISK_ACK explicit_user_enable
    cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE test12_clean_cycle
  ;;
  outdoor-extended)
    cfg_set THERMAL_OUTDOOR_PROFILE outdoor-extended
    cfg_set THERMAL_OUTDOOR_TARGET outdoor_extended
    cfg_set THERMAL_OUTDOOR_RISK_ACK explicit_user_enable_extended
    cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE test12_clean_cycle
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
    echo
    echo "== after =="
    grep -E "^(THERMAL_OUTDOOR_PROFILE|THERMAL_OUTDOOR_RISK_ACK|THERMAL_OUTDOOR_PROFILE_SOURCE|THERMAL_OUTDOOR_TARGET)=" "$CONFIG_FILE" 2>/dev/null || true
    echo "RESULT: PIXEL_THERMAL_OUTDOOR_MENU_DONE choice=$choice confirm_reason=$confirm_reason steps=$steps"
  } >> "$LOG" 2>&1 || true
fi

exit 0
