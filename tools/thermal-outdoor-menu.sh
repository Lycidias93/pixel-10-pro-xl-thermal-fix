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
    _key="$(timeout 10 getevent -qlc 1 2>/dev/null | grep -E "KEY_VOLUMEUP|KEY_VOLUMEDOWN" | head -1 || true)"
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
    stock) echo "Stock / default" ;;
    outdoor-safe) echo "Outdoor Safe" ;;
    outdoor-plus) echo "Outdoor Plus" ;;
    outdoor-extended) echo "Outdoor Extended" ;;
    *) echo "Stock / default" ;;
  esac
}

idx=0
choice="stock"
confirmed=0
steps=0

msg "----------------------------------------"
msg "Outdoor profile selection"
msg "Volume Up: next option"
msg "Volume Down: confirm shown option"
msg "Timeout: Stock / default"
msg "No Power button is used"
msg "----------------------------------------"

while [ "$steps" -lt 8 ]; do
  current="$(option_at "$idx")"
  current_label="$(label_for "$current")"

  msg "Current: $current_label"
  msg "Volume Up = next | Volume Down = confirm"

  key="$(read_key)"
  case "$key" in
    up)
      idx=$(( (idx + 1) % 4 ))
      steps=$(( steps + 1 ))
    ;;
    down)
      choice="$current"
      confirmed=1
      break
    ;;
    *)
      choice="stock"
      confirmed=0
      break
    ;;
  esac
done

if [ "$steps" -ge 8 ] && [ "$confirmed" -ne 1 ]; then
  choice="stock"
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
    cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE test11_full_matrix_volume_cycle
    msg "confirmed: Outdoor Safe"
  ;;
  outdoor-plus)
    cfg_set THERMAL_OUTDOOR_PROFILE outdoor-plus
    cfg_set THERMAL_OUTDOOR_TARGET outdoor_plus
    cfg_set THERMAL_OUTDOOR_RISK_ACK explicit_user_enable
    cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE test11_full_matrix_volume_cycle
    msg "confirmed: Outdoor Plus"
  ;;
  outdoor-extended)
    cfg_set THERMAL_OUTDOOR_PROFILE outdoor-extended
    cfg_set THERMAL_OUTDOOR_TARGET outdoor_extended
    cfg_set THERMAL_OUTDOOR_RISK_ACK explicit_user_enable_extended
    cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE test11_full_matrix_volume_cycle
    msg "confirmed: Outdoor Extended"
  ;;
  *)
    cfg_set THERMAL_OUTDOOR_PROFILE stock
    cfg_set THERMAL_OUTDOOR_TARGET stock
    cfg_set THERMAL_OUTDOOR_RISK_ACK disabled_by_user_or_timeout
    cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE stock
    msg "confirmed: Stock / default"
  ;;
esac

if [ "$LOG" != "/dev/null" ]; then
  {
    echo "choice=$choice"
    echo "confirmed=$confirmed"
    echo "steps=$steps"
    echo
    echo "== after =="
    grep -E "^(THERMAL_OUTDOOR_PROFILE|THERMAL_OUTDOOR_RISK_ACK|THERMAL_OUTDOOR_PROFILE_SOURCE|THERMAL_OUTDOOR_TARGET)=" "$CONFIG_FILE" 2>/dev/null || true
    echo "RESULT: PIXEL_THERMAL_OUTDOOR_MENU_DONE choice=$choice confirmed=$confirmed steps=$steps"
  } >> "$LOG" 2>&1 || true
fi

exit 0
