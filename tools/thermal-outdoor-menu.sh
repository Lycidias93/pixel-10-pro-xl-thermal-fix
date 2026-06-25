#!/system/bin/sh
MODDIR="${MODDIR:-${0%/*}/..}"
CONFIG_DIR="/data/adb/pixel-10-pro-xl-thermal-fix"
CONFIG_FILE="$CONFIG_DIR/config.env"
MODE="${1:-action}"
DOWNLOAD="/sdcard/Download"
ALT_DOWNLOAD="/storage/emulated/0/Download"
choose_download(){ for d in "$DOWNLOAD" "$ALT_DOWNLOAD"; do [ -d "$d" ] && [ -w "$d" ] && { echo "$d"; return 0; }; done; echo "$ALT_DOWNLOAD"; }
cfg_set(){ k="$1"; v="$2"; mkdir -p "$CONFIG_DIR" 2>/dev/null || true; touch "$CONFIG_FILE" 2>/dev/null || true; if grep -q "^${k}=" "$CONFIG_FILE" 2>/dev/null; then sed -i "s|^${k}=.*|${k}=${v}|" "$CONFIG_FILE" 2>/dev/null || true; else echo "${k}=${v}" >> "$CONFIG_FILE"; fi; chmod 0600 "$CONFIG_FILE" 2>/dev/null || true; }
cfg_get(){ k="$1"; [ -r "$CONFIG_FILE" ] || return 0; grep -E "^${k}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${k}=//" | tr -d '\r'; }
read_volume_choice(){ if ! command -v getevent >/dev/null 2>&1; then echo unknown; return 0; fi; if command -v timeout >/dev/null 2>&1; then ev="$(timeout 15 sh -c '/system/bin/getevent -l 2>/dev/null | grep -m 1 -E "KEY_VOLUMEUP|KEY_VOLUMEDOWN"' 2>/dev/null || true)"; else ev="$(/system/bin/getevent -l 2>/dev/null | grep -m 1 -E 'KEY_VOLUMEUP|KEY_VOLUMEDOWN' || true)"; fi; case "$ev" in *KEY_VOLUMEUP*) echo up;; *KEY_VOLUMEDOWN*) echo down;; "") echo timeout;; *) echo unknown;; esac; }
msg(){ echo "$*"; if [ -n "${LOG:-}" ] && [ "$LOG" != "/dev/null" ]; then echo "$*" >> "$LOG" 2>/dev/null || true; fi; }
DL="$(choose_download)"; TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"; LOG="/dev/null"
dbg="$(cfg_get DEBUG_MODE)"; [ -z "$dbg" ] && dbg="$(cfg_get debug_mode)"
if [ "$dbg" = "1" ]; then
  LOG="$DL/pixel_thermal_outdoor_menu_${TS}.txt"
  { echo "debug_type=pixel_thermal_outdoor_menu"; echo "time=$(date -Is 2>/dev/null || date)"; echo "mode=$MODE"; echo "module=$MODDIR"; echo "config=$CONFIG_FILE"; echo "base_profile=${BASE_PROFILE:-unset}"; echo; echo "== before =="; [ -r "$CONFIG_FILE" ] && grep -E '^(THERMAL_OUTDOOR_PROFILE|THERMAL_OUTDOOR_RISK_ACK|THERMAL_OUTDOOR_TARGET|THERMAL_OUTDOOR_PROFILE_SOURCE|DEBUG_MODE|debug_mode)=' "$CONFIG_FILE" || true; echo; } > "$LOG" 2>&1
fi
msg "----------------------------------------"
msg "  Optional Thermal Outdoor Profile"
msg "  Press [Volume Up] to ENABLE outdoor-g4-adapted"
msg "  Press [Volume Down] to keep STOCK thermal profile"
msg "  Timeout (15s) keeps STOCK"
msg "----------------------------------------"
choice="$(read_volume_choice)"
case "$choice" in
  up) cfg_set THERMAL_OUTDOOR_PROFILE outdoor-g4-adapted; cfg_set THERMAL_OUTDOOR_RISK_ACK explicit_user_enable; cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE g5_phase0b_g4_adapted_test1; cfg_set THERMAL_OUTDOOR_TARGET g4_adapted; msg "selected: enable outdoor-g4-adapted";;
  down) cfg_set THERMAL_OUTDOOR_PROFILE stock; cfg_set THERMAL_OUTDOOR_RISK_ACK disabled_by_user; cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE stock; cfg_set THERMAL_OUTDOOR_TARGET stock; msg "selected: stock";;
  *) if [ "$(cfg_get THERMAL_OUTDOOR_PROFILE)" = "outdoor-g4-adapted" ]; then msg "selected: timeout; keeping existing outdoor-g4-adapted"; else cfg_set THERMAL_OUTDOOR_PROFILE stock; cfg_set THERMAL_OUTDOOR_RISK_ACK disabled_by_default; cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE stock_timeout; cfg_set THERMAL_OUTDOOR_TARGET stock; msg "selected: timeout; keeping stock"; fi;;
esac
if [ "$LOG" != "/dev/null" ]; then { echo "choice=$choice"; echo; echo "== after =="; [ -r "$CONFIG_FILE" ] && grep -E '^(THERMAL_OUTDOOR_PROFILE|THERMAL_OUTDOOR_RISK_ACK|THERMAL_OUTDOOR_PROFILE_SOURCE|THERMAL_OUTDOOR_TARGET|DEBUG_MODE|debug_mode)=' "$CONFIG_FILE" || true; echo "RESULT: PIXEL_THERMAL_OUTDOOR_MENU_DONE choice=$choice"; } >> "$LOG" 2>&1; fi
exit 0
