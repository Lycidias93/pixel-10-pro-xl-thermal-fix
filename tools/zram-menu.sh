#!/system/bin/sh
MODDIR="${MODDIR:-${0%/*}/..}"
CONFIG_DIR="/data/adb/pixel-10-pro-xl-thermal-fix"
CONFIG_FILE="$CONFIG_DIR/config.env"
MODE="${1:-action}"
DOWNLOAD="/sdcard/Download"
ALT_DOWNLOAD="/storage/emulated/0/Download"

choose_download() {
  for d in "$DOWNLOAD" "$ALT_DOWNLOAD"; do
    [ -d "$d" ] && [ -w "$d" ] && { echo "$d"; return 0; }
  done
  echo "$ALT_DOWNLOAD"
}

msg() { echo "$*"; }

cfg_set() {
  k="$1"; v="$2"
  mkdir -p "$CONFIG_DIR" 2>/dev/null || true
  touch "$CONFIG_FILE" 2>/dev/null || true
  if grep -q "^${k}=" "$CONFIG_FILE" 2>/dev/null; then
    sed -i "s|^${k}=.*|${k}=${v}|" "$CONFIG_FILE" 2>/dev/null || true
  else
    echo "${k}=${v}" >> "$CONFIG_FILE"
  fi
  chmod 0600 "$CONFIG_FILE" 2>/dev/null || true
}

cfg_get() {
  k="$1"
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^${k}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${k}=//" | tr -d '\r'
}

read_volume_choice() {
  # Returns: up/down/timeout/unknown. Timeout keeps the current safe config.
  if ! command -v getevent >/dev/null 2>&1; then
    echo unknown
    return 0
  fi
  if command -v timeout >/dev/null 2>&1; then
    ev="$(timeout 15 sh -c 'while true; do getevent -qlc 1 2>/dev/null | grep -m1 -E "KEY_VOLUMEUP|KEY_VOLUMEDOWN" && exit 0; done' 2>/dev/null || true)"
  else
    ev="$(getevent -qlc 1 2>/dev/null | grep -m1 -E 'KEY_VOLUMEUP|KEY_VOLUMEDOWN' || true)"
  fi
  case "$ev" in
    *KEY_VOLUMEUP*) echo up ;;
    *KEY_VOLUMEDOWN*) echo down ;;
    "") echo timeout ;;
    *) echo unknown ;;
  esac
}

enable_zram() {
  cfg_set ENABLE_ZRAM_100P 1
  cfg_set ZRAM_RESTART_MMD 1
  cfg_set ZRAM_RISK_ACK explicit_user_enable
  if [ -s "$MODDIR/tools/apply-zram-100p.sh" ]; then
    MODDIR="$MODDIR" sh "$MODDIR/tools/apply-zram-100p.sh" "$MODE" || true
  fi
  msg "ZRAM 100p enabled in config. Reboot recommended."
}

disable_zram() {
  if [ -s "$MODDIR/tools/disable-zram-100p.sh" ]; then
    sh "$MODDIR/tools/disable-zram-100p.sh" || true
  else
    cfg_set ENABLE_ZRAM_100P 0
    cfg_set ZRAM_RESTART_MMD 0
    cfg_set ZRAM_RISK_ACK disabled_by_user
  fi
  msg "ZRAM 100p disabled in config. Reboot recommended."
}

keep_zram() {
  mkdir -p "$CONFIG_DIR" 2>/dev/null || true
  if [ ! -f "$CONFIG_FILE" ]; then
    cfg_set ENABLE_ZRAM_100P 0
    cfg_set ZRAM_RESTART_MMD 0
    cfg_set ZRAM_RISK_ACK disabled_by_default
    msg "No prior config found; keeping safe default ZRAM 100p disabled."
    return 0
  fi
  msg "Keeping existing ZRAM config: ENABLE_ZRAM_100P=$(cfg_get ENABLE_ZRAM_100P) ZRAM_RISK_ACK=$(cfg_get ZRAM_RISK_ACK)"
}

DL="$(choose_download)"
TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"
LOG="$DL/pixel_thermal_zram_menu_${TS}.txt"
{
  echo "debug_type=pixel_thermal_zram_menu"
  echo "time=$(date -Is 2>/dev/null || date)"
  echo "mode=$MODE"
  echo "module=$MODDIR"
  echo "config=$CONFIG_FILE"
  echo
  echo "== before =="
  [ -r "$CONFIG_FILE" ] && grep -E '^(ENABLE_ZRAM_100P|ZRAM_RESTART_MMD|ZRAM_RISK_ACK|ZRAM_REINIT_ACK)=' "$CONFIG_FILE" || true
  echo

  msg "ZRAM 100p option"
  msg "Vol+ = enable ZRAM 100p"
  msg "Vol- = disable ZRAM 100p"
  msg "Timeout = keep existing / safe default"
  choice="$(read_volume_choice)"
  echo "choice=$choice"
  case "$choice" in
    up) enable_zram ;;
    down) disable_zram ;;
    *) keep_zram ;;
  esac

  echo
  echo "== after =="
  [ -r "$CONFIG_FILE" ] && grep -E '^(ENABLE_ZRAM_100P|ZRAM_RESTART_MMD|ZRAM_RISK_ACK|ZRAM_REINIT_ACK)=' "$CONFIG_FILE" || true
  echo "RESULT: PIXEL_THERMAL_ZRAM_MENU_DONE choice=$choice"
} > "$LOG" 2>&1
cat "$LOG"
