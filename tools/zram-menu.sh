#!/system/bin/sh
set -eu

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
  k="$1"
  v="$2"
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

read_key_once() {
  if ! command -v getevent >/dev/null 2>&1; then
    echo timeout
    return 0
  fi

  ev=""
  if command -v timeout >/dev/null 2>&1; then
    ev="$(timeout 12 getevent -ql 2>/dev/null | awk '/KEY_VOLUMEUP|KEY_VOLUMEDOWN/ && ($0 ~ / DOWN$/ || $0 ~ / 00000001$/) { print; exit }' 2>/dev/null || true)"
  else
    ev="$(getevent -ql 2>/dev/null | awk '/KEY_VOLUMEUP|KEY_VOLUMEDOWN/ && ($0 ~ / DOWN$/ || $0 ~ / 00000001$/) { print; exit }' 2>/dev/null || true)"
  fi

  case "$ev" in
    *KEY_VOLUMEUP*) sleep 0.45 2>/dev/null || true; echo up ;;
    *KEY_VOLUMEDOWN*) sleep 0.45 2>/dev/null || true; echo down ;;
    *) echo timeout ;;
  esac
}

enable_zram() {
  cfg_set ENABLE_ZRAM_100P 1
  cfg_set ZRAM_RESTART_MMD 1
  cfg_set ZRAM_RISK_ACK explicit_user_enable
  if [ "$MODE" != "install" ] && [ -s "$MODDIR/tools/apply-zram-100p.sh" ]; then
    dbg="${DEBUG_MODE:-}"
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
  if [ "$MODE" != "install" ] && [ -s "$MODDIR/tools/disable-zram-100p.sh" ]; then
    dbg="${DEBUG_MODE:-}"
    [ -z "$dbg" ] && dbg="$(cfg_get DEBUG_MODE)"
    [ -z "$dbg" ] && dbg="$(cfg_get debug_mode)"
    if [ "$dbg" = "1" ]; then
      sh "$MODDIR/tools/disable-zram-100p.sh" || true
    else
      sh "$MODDIR/tools/disable-zram-100p.sh" >/dev/null 2>&1 || true
    fi
  fi
  cfg_set ENABLE_ZRAM_100P 0
  cfg_set ZRAM_RESTART_MMD 0
  cfg_set ZRAM_RISK_ACK disabled_by_user
  msg "- Selected: DISABLE ZRAM 100% (Reboot recommended)"
}

DL="$(choose_download)"
TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"
TEMP_LOG="$DL/pixel_thermal_zram_menu_${TS}.txt"
LOG="/dev/null"

show_two_choice() {
  title="$1"
  idx="$2"
  label0="$3"
  label1="$4"

  msg ""
  msg "----------------------------------------"
  msg "$title"
  msg "----------------------------------------"
  msg "[1/2] $label0"
  msg "[2/2] $label1"
  msg ""
  msg "Volume Up   = next option"
  msg "Volume Down = confirm selected option"
  msg "Timeout     = confirm selected option"
  msg "Power       = not used"
  msg "----------------------------------------"
  msg ""

  if [ "$idx" = "1" ]; then
    msg "Now selected: [2/2] $label1"
  else
    msg "Now selected: [1/2] $label0"
  fi
  msg "Volume Up = next | Volume Down = confirm"
}

cycle_two() {
  idx="$1"
  title="$2"
  label0="$3"
  label1="$4"
  steps=0

  while [ "$steps" -lt 8 ]; do
    show_two_choice "$title" "$idx" "$label0" "$label1"
    key="$(read_key_once)"
    case "$key" in
      up)
        if [ "$idx" = "1" ]; then idx=0; else idx=1; fi
        steps=$(( steps + 1 ))
      ;;
      down)
        CYCLE_IDX="$idx"
        CYCLE_REASON="volume_down"
        CYCLE_STEPS="$steps"
        return 0
      ;;
      timeout)
        CYCLE_IDX="$idx"
        CYCLE_REASON="timeout"
        CYCLE_STEPS="$steps"
        return 0
      ;;
    esac
  done

  CYCLE_IDX="$idx"
  CYCLE_REASON="max_steps"
  CYCLE_STEPS="$steps"
  return 0
}

choose_debug_mode() {
  dbg="$(cfg_get DEBUG_MODE)"
  [ -z "$dbg" ] && dbg="$(cfg_get debug_mode)"
  case "$dbg" in 1) dbg_idx=1 ;; *) dbg_idx=0 ;; esac

  cycle_two "$dbg_idx" "Pixel Thermal Debug Logging" "Silent install" "Verbose debug logs"
  dbg_idx="$CYCLE_IDX"
  dbg_reason="$CYCLE_REASON"
  dbg_steps="$CYCLE_STEPS"

  msg ""
  msg "Confirmed Debug Logging:"
  if [ "$dbg_idx" = "1" ]; then
    msg "Verbose debug logs"
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
      echo "debug_choice=verbose"
      echo "debug_confirm_reason=$dbg_reason"
      echo "debug_steps=$dbg_steps"
      echo
      echo "== before =="
      [ -r "$CONFIG_FILE" ] && grep -E '^(ENABLE_ZRAM_100P|ZRAM_RESTART_MMD|ZRAM_RISK_ACK|ZRAM_REINIT_ACK|DEBUG_MODE|debug_mode)=' "$CONFIG_FILE" || true
      echo
    } > "$LOG" 2>&1
  else
    msg "Silent install"
    DEBUG_MODE=0
    cfg_set DEBUG_MODE 0
    cfg_set debug_mode 0
  fi
  msg "----------------------------------------"
}

choose_zram_mode() {
  zram="$(cfg_get ENABLE_ZRAM_100P)"
  case "$zram" in 1) zram_idx=1 ;; *) zram_idx=0 ;; esac

  cycle_two "$zram_idx" "Optional ZRAM 100% Profile" "ZRAM 100% disabled" "ZRAM 100% enabled"
  zram_idx="$CYCLE_IDX"
  zram_reason="$CYCLE_REASON"
  zram_steps="$CYCLE_STEPS"

  if [ "$LOG" != "/dev/null" ]; then
    {
      echo "zram_choice_index=$zram_idx"
      echo "zram_confirm_reason=$zram_reason"
      echo "zram_steps=$zram_steps"
      echo
    } >> "$LOG" 2>&1
  fi

  msg ""
  msg "Confirmed ZRAM 100% Profile:"
  if [ "$zram_idx" = "1" ]; then
    msg "ZRAM 100% enabled"
    enable_zram
    zram_choice="enable"
  else
    msg "ZRAM 100% disabled"
    disable_zram
    zram_choice="disable"
  fi
  msg "----------------------------------------"
}

choose_debug_mode
choose_zram_mode

if [ "$LOG" != "/dev/null" ]; then
  {
    echo
    echo "== after =="
    [ -r "$CONFIG_FILE" ] && grep -E '^(ENABLE_ZRAM_100P|ZRAM_RESTART_MMD|ZRAM_RISK_ACK|ZRAM_REINIT_ACK|DEBUG_MODE|debug_mode)=' "$CONFIG_FILE" || true
    echo "RESULT: PIXEL_THERMAL_ZRAM_MENU_DONE choice=$zram_choice confirm_reason=$zram_reason steps=$zram_steps"
  } >> "$LOG" 2>&1
fi

exit 0
