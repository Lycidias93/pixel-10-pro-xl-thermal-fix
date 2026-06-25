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

msg() {
  echo "$*"
  if [ -n "${LOG:-}" ] && [ "$LOG" != "/dev/null" ]; then
    echo "$*" >> "$LOG" 2>/dev/null || true
  fi
}

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
    ev="$(timeout 15 sh -c '/system/bin/getevent -l 2>/dev/null | grep -m 1 -E "KEY_VOLUMEUP|KEY_VOLUMEDOWN"' 2>/dev/null || true)"
  else
    ev="$(/system/bin/getevent -l 2>/dev/null | grep -m 1 -E 'KEY_VOLUMEUP|KEY_VOLUMEDOWN' || true)"
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
    local dbg="${DEBUG_MODE:-}"
    [ -z "$dbg" ] && dbg="$(cfg_get DEBUG_MODE)"
    [ -z "$dbg" ] && dbg="$(cfg_get debug_mode)"
    if [ "$dbg" = "1" ]; then
      MODDIR="$MODDIR" sh "$MODDIR/tools/apply-zram-100p.sh" "$MODE" || true
    else
      MODDIR="$MODDIR" sh "$MODDIR/tools/apply-zram-100p.sh" "$MODE" >/dev/null 2>&1 || true
    fi
  fi
  msg "- Selected: ENABLE ZRAM 100% (Reboot recommended)"
}

disable_zram() {
  if [ -s "$MODDIR/tools/disable-zram-100p.sh" ]; then
    local dbg="${DEBUG_MODE:-}"
    [ -z "$dbg" ] && dbg="$(cfg_get DEBUG_MODE)"
    [ -z "$dbg" ] && dbg="$(cfg_get debug_mode)"
    if [ "$dbg" = "1" ]; then
      sh "$MODDIR/tools/disable-zram-100p.sh" || true
    else
      sh "$MODDIR/tools/disable-zram-100p.sh" >/dev/null 2>&1 || true
    fi
  else
    cfg_set ENABLE_ZRAM_100P 0
    cfg_set ZRAM_RESTART_MMD 0
    cfg_set ZRAM_RISK_ACK disabled_by_user
  fi
  msg "- Selected: SKIP/DISABLE ZRAM 100% (Reboot recommended)"
}

keep_zram() {
  mkdir -p "$CONFIG_DIR" 2>/dev/null || true
  if [ ! -f "$CONFIG_FILE" ]; then
    cfg_set ENABLE_ZRAM_100P 0
    cfg_set ZRAM_RESTART_MMD 0
    cfg_set ZRAM_RISK_ACK disabled_by_default
    msg "- Timeout/No key pressed. Keeping safe default: ZRAM 100% disabled."
    return 0
  fi
  msg "- Keeping existing ZRAM config: ENABLE_ZRAM_100P=$(cfg_get ENABLE_ZRAM_100P)"
}

DL="$(choose_download)"
TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"
TEMP_LOG="$DL/pixel_thermal_zram_menu_${TS}.txt"
LOG="/dev/null"

choose_debug_mode() {
  msg "----------------------------------------"
  msg "  Pixel Thermal Debug Mode"
  msg "  Press [Volume Up] to ENABLE (verbose)"
  msg "  Press [Volume Down] to SKIP (silent)"
  msg "  Timeout (15s) defaults to silent"
  msg "----------------------------------------"

  local dbg_choice="$(read_volume_choice)"

  if [ "$dbg_choice" = "up" ]; then
    msg "selected: enable"
    DEBUG_MODE=1
    cfg_set DEBUG_MODE 1
    cfg_set debug_mode 1
    LOG="$TEMP_LOG"
    mkdir -p "$DL" 2>/dev/null || true
    {
      echo "debug_type=pixel_thermal_zram_menu"
      echo "time=$(date -Is 2>/dev/null || date)"
      echo "mode=$MODE"
      echo "module=$MODDIR"
      echo "config=$CONFIG_FILE"
      echo
      echo "== before =="
      [ -r "$CONFIG_FILE" ] && grep -E '^(ENABLE_ZRAM_100P|ZRAM_RESTART_MMD|ZRAM_RISK_ACK|ZRAM_REINIT_ACK|DEBUG_MODE|debug_mode)=' "$CONFIG_FILE" || true
      echo "dbg_choice=up"
      echo
    } > "$LOG" 2>&1
  else
    msg "selected: disable"
    DEBUG_MODE=0
    cfg_set DEBUG_MODE 0
    cfg_set debug_mode 0
  fi
}

choose_debug_mode

msg "----------------------------------------"
msg "  Optional ZRAM 100% configuration"
msg "  Press [Volume Up] to ENABLE"
msg "  Press [Volume Down] to SKIP/DISABLE"
msg "  Timeout (15s) keeps safe default"
msg "----------------------------------------"

choice="$(read_volume_choice)"

if [ "$LOG" != "/dev/null" ]; then
  {
    echo "choice=$choice"
  } >> "$LOG" 2>&1
fi

case "$choice" in
  up)
    msg "selected: enable"
    enable_zram
    ;;
  down)
    msg "selected: disable"
    disable_zram
    ;;
  *)
    msg "selected: timeout (disable)"
    keep_zram
    ;;
esac

if [ "$LOG" != "/dev/null" ]; then
  {
    echo
    echo "== after =="
    [ -r "$CONFIG_FILE" ] && grep -E '^(ENABLE_ZRAM_100P|ZRAM_RESTART_MMD|ZRAM_RISK_ACK|ZRAM_REINIT_ACK|DEBUG_MODE|debug_mode)=' "$CONFIG_FILE" || true
    echo "RESULT: PIXEL_THERMAL_ZRAM_MENU_DONE choice=$choice"
  } >> "$LOG" 2>&1
fi
