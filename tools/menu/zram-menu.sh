#!/system/bin/sh
set -eu
MODDIR="${MODDIR:-${0%/*}/..}"
CONFIG_DIR="/data/adb/pixel-10-pro-xl-thermal-fix"
CONFIG_FILE="$CONFIG_DIR/config.env"
MODE="${1:-action}"
DOWNLOAD="/sdcard/Download"
ALT_DOWNLOAD="/storage/emulated/0/Download"
[ -s "$MODDIR/tools/menu/menu-cycle.sh" ] && . "$MODDIR/tools/menu/menu-cycle.sh" || exit 0

choose_download() { for d in "$DOWNLOAD" "$ALT_DOWNLOAD"; do [ -d "$d" ] && [ -w "$d" ] && { echo "$d"; return 0; }; done; echo "$ALT_DOWNLOAD"; }
msg() { echo "$*"; if [ -n "${LOG:-}" ] && [ "$LOG" != "/dev/null" ]; then echo "$*" >> "$LOG" 2>/dev/null || true; fi; }
cfg_set() { k="$1"; v="$2"; mkdir -p "$CONFIG_DIR" 2>/dev/null || true; touch "$CONFIG_FILE" 2>/dev/null || true; if grep -q "^${k}=" "$CONFIG_FILE" 2>/dev/null; then sed -i "s|^${k}=.*|${k}=${v}|" "$CONFIG_FILE" 2>/dev/null || true; else echo "${k}=${v}" >> "$CONFIG_FILE"; fi; chmod 0600 "$CONFIG_FILE" 2>/dev/null || true; }
cfg_get() { k="$1"; [ -r "$CONFIG_FILE" ] || return 0; grep -E "^${k}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${k}=//" | tr -d '\r'; }

enable_zram() { cfg_set ENABLE_ZRAM_100P 1; cfg_set ZRAM_RESTART_MMD 1; cfg_set ZRAM_RISK_ACK explicit_user_enable; cfg_set LAST_ZRAM_100P enabled; msg "- Selected: ZRAM enabled"; }
disable_zram() { cfg_set ENABLE_ZRAM_100P 0; cfg_set ZRAM_RESTART_MMD 0; cfg_set ZRAM_RISK_ACK disabled_by_user; cfg_set LAST_ZRAM_100P disabled; msg "- Selected: ZRAM disabled"; }

apply_last_zram_and_exit() {
  last_dbg="$(cfg_get LAST_DEBUG_MODE)"
  [ -n "$last_dbg" ] || last_dbg="$(cfg_get DEBUG_MODE)"
  case "$last_dbg" in silent|0)
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
    zram_choice="disable"
  ;;
    *)
    cfg_set ENABLE_ZRAM_100P 1
    cfg_set ZRAM_RESTART_MMD 1
    cfg_set ZRAM_RISK_ACK explicit_user_enable
    cfg_set LAST_ZRAM_100P enabled
    zram_choice="enable"
  ;;
  esac

  msg ""
  msg "Use last settings:"
  msg "ZRAM: $(cfg_get LAST_ZRAM_100P)"
  msg "No ZRAM menu"
  msg "----------------------------------------"
  echo "RESULT: ZRAM_MENU_SKIPPED_USE_LAST"
  echo "choice=$zram_choice"
  echo "reason=use_last"
  echo "steps=0"
  exit 0
}

DL="$(choose_download)"; TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"; TEMP_LOG="$DL/pixel_thermal_zram_menu_${TS}.txt"; LOG="/dev/null"

choose_debug_mode() {
  # Test builds default to Verbose. Fresh installs and missing/stale debug state
  # must show Verbose as the initial selector, while explicit "last silent"
  # remains reusable when the remembered settings path is chosen.
  settings_mode="$(cfg_get THERMAL_SETTINGS_MODE)"
  last_dbg="$(cfg_get LAST_DEBUG_MODE)"
  dbg="$(cfg_get DEBUG_MODE)"; [ -z "$dbg" ] && dbg="$(cfg_get debug_mode)"

  if [ "$settings_mode" = "fresh" ]; then
    dbg="1"
  elif [ "$last_dbg" = "silent" ]; then
    dbg="0"
  elif [ "$last_dbg" = "verbose" ]; then
    dbg="1"
  elif [ -z "$dbg" ]; then
    dbg="1"
  fi

  case "$dbg" in 1) dbg_idx=1 ;; *) dbg_idx=0 ;; esac
  mc_cycle2 "Debug Logging" "Silent" "Verbose" "$dbg_idx"
  dbg_idx="$MC_INDEX"; dbg_reason="$MC_REASON"; dbg_steps="$MC_STEPS"
  msg ""; msg "Confirmed:"
  if [ "$dbg_idx" = "1" ]; then
    msg "Verbose"; DEBUG_MODE=1; cfg_set DEBUG_MODE 1; cfg_set debug_mode 1; cfg_set LAST_DEBUG_MODE verbose; LOG="$TEMP_LOG"; mkdir -p "$DL" 2>/dev/null || true
    { echo "debug_type=pixel_thermal_zram_menu"; echo "time=$(date -Is 2>/dev/null || date)"; echo "mode=$MODE"; echo "module=$MODDIR"; echo "config=$CONFIG_FILE"; echo "debug_choice=verbose"; echo "debug_confirm_reason=$dbg_reason"; echo "debug_steps=$dbg_steps"; echo "timeout_seconds=$MC_TIMEOUT_SECONDS"; echo "debounce_seconds=$MC_DEBOUNCE_SECONDS"; echo; echo "== before =="; [ -r "$CONFIG_FILE" ] && grep -E '^(THERMAL_|PTUNE_|ALLOW_THERMAL|RISK_ACK|ENABLE_ZRAM_100P|ZRAM_RESTART_MMD|ZRAM_RISK_ACK|DEBUG_MODE|debug_mode|LAST_)=' "$CONFIG_FILE" || true; echo; } > "$LOG" 2>&1
  else
    msg "Silent"; DEBUG_MODE=0; cfg_set DEBUG_MODE 0; cfg_set debug_mode 0; cfg_set LAST_DEBUG_MODE silent
  fi
  msg "----------------------------------------"
}

choose_zram_mode() {
  zram="$(cfg_get ENABLE_ZRAM_100P)"; case "$zram" in 1) zram_idx=1 ;; *) zram_idx=0 ;; esac
  mc_cycle2 "ZRAM 100%" "Disabled" "Enabled" "$zram_idx"
  zram_idx="$MC_INDEX"; zram_reason="$MC_REASON"; zram_steps="$MC_STEPS"
  [ "$LOG" != "/dev/null" ] && { echo "zram_choice_index=$zram_idx"; echo "zram_confirm_reason=$zram_reason"; echo "zram_steps=$zram_steps"; echo; } >> "$LOG" 2>&1
  msg ""; msg "Confirmed:"
  if [ "$zram_idx" = "1" ]; then msg "ZRAM enabled"; enable_zram; zram_choice="enable"; else msg "ZRAM disabled"; disable_zram; zram_choice="disable"; fi
  msg "----------------------------------------"
}

if [ "$(cfg_get THERMAL_SETTINGS_MODE)" = "last" ]; then
  apply_last_zram_and_exit
fi
choose_debug_mode
choose_zram_mode
if [ "$LOG" != "/dev/null" ]; then
  { echo; echo "== after =="; [ -r "$CONFIG_FILE" ] && grep -E '^(THERMAL_|PTUNE_|ALLOW_THERMAL|RISK_ACK|ENABLE_ZRAM_100P|ZRAM_RESTART_MMD|ZRAM_RISK_ACK|DEBUG_MODE|debug_mode|LAST_)=' "$CONFIG_FILE" || true; echo "RESULT: PIXEL_THERMAL_ZRAM_MENU_DONE choice=$zram_choice confirm_reason=$zram_reason steps=$zram_steps"; } >> "$LOG" 2>&1
fi
exit 0
