#!/system/bin/sh
MC_TIMEOUT_SECONDS="${MC_TIMEOUT_SECONDS:-30}"
MC_DEBOUNCE_SECONDS="${MC_DEBOUNCE_SECONDS:-0.45}"

MC_MIN_WIDTH="${MC_MIN_WIDTH:-28}"
MC_MAX_WIDTH="${MC_MAX_WIDTH:-52}"
MC_DEFAULT_WIDTH="${MC_DEFAULT_WIDTH:-40}"

mc_detect_width() {
  _width="${MC_UI_COLUMNS:-${COLUMNS:-}}"
  case "$_width" in ""|*[!0-9]*) _width="" ;; esac

  if [ -z "$_width" ] && command -v stty >/dev/null 2>&1; then
    _size="$(stty size </dev/tty 2>/dev/null || stty size 2>/dev/null || true)"
    set -- $_size
    [ "$#" -eq 2 ] && _width="$2"
    case "$_width" in ""|*[!0-9]*) _width="" ;; esac
  fi

  [ -n "$_width" ] || _width="$MC_DEFAULT_WIDTH"
  [ "$_width" -ge "$MC_MIN_WIDTH" ] 2>/dev/null || _width="$MC_MIN_WIDTH"
  [ "$_width" -le "$MC_MAX_WIDTH" ] 2>/dev/null || _width="$MC_MAX_WIDTH"
  printf '%s\n' "$_width"
}

MC_UI_WIDTH="$(mc_detect_width)"

mc_msg() {
  _text="$*"
  if [ "$_text" = "----------------------------------------" ]; then
    _text="$(printf '%*s' "$MC_UI_WIDTH" '' | tr ' ' '-')"
  fi
  if command -v ui_print >/dev/null 2>&1; then ui_print "$_text"; else echo "$_text"; fi
}

mc_rule() {
  _rule="$(printf '%*s' "$MC_UI_WIDTH" '' | tr ' ' '-')"
  mc_msg "$_rule"
}

mc_read_key() {
  if ! command -v getevent >/dev/null 2>&1; then echo timeout; return 0; fi
  _ev=""
  if command -v timeout >/dev/null 2>&1; then
    _ev="$(timeout "$MC_TIMEOUT_SECONDS" sh -c 'getevent -ql 2>/dev/null | grep -m 1 -E "KEY_VOLUMEUP|KEY_VOLUMEDOWN"' 2>/dev/null || true)"
  else
    _ev="$(getevent -ql 2>/dev/null | grep -m 1 -E "KEY_VOLUMEUP|KEY_VOLUMEDOWN" 2>/dev/null || true)"
  fi
  case "$_ev" in
    *KEY_VOLUMEUP*) sleep "$MC_DEBOUNCE_SECONDS" 2>/dev/null || true; echo up ;;
    *KEY_VOLUMEDOWN*) sleep "$MC_DEBOUNCE_SECONDS" 2>/dev/null || true; echo down ;;
    *) echo timeout ;;
  esac
}

mc_desc() {
  case "$1" in
    "Action") echo "Open status, settings, debug, advanced." ;;
    "Settings") echo "Change Polling, Thermal, or ZRAM." ;;
    "Polling Mode") echo "Module polling values or stock values." ;;
    "Polling") echo "Choose module or stock polling values." ;;
    "Polling Fix") echo "Module values or stock values." ;;
    "Thermal") echo "Choose Stock, Safe, Plus, or Extended." ;;
    "Thermal Profile") echo "Stock, Safe, Plus, or Extended." ;;
    "ZRAM 100%") echo "Enable or disable 100 percent ZRAM." ;;
    "Debug") echo "Create evidence and bootguard reports." ;;
    "Debug Logging") echo "Minimal or full debug evidence." ;;
    "Bootguard Status") echo "Show bootguard and last-good state." ;;
    "Boot Crash Archive") echo "Create boot crash evidence archive." ;;
    "pTune Override OFF") echo "Keep pTune coexistence blocked." ;;
    "pTune Override ON") echo "Allow explicit pTune coexistence risk." ;;
    "Bootguard") echo "Show bootguard and last-good state." ;;
    "Clear Counters") echo "Reset bootguard counters only." ;;
    "Advanced") echo "pTune and update-channel tools." ;;
    "Update Channel") echo "Stable or test update path only." ;;
    "pTune Override") echo "Allow module beside pTune." ;;
    "pTune Risk") echo "Explicit pTune coexistence risk." ;;
    "Remember Settings") echo "Last choices or fresh start." ;;
    "Safety Level") echo "Allow testing or block conflicts." ;;
    *) echo "" ;;
  esac
}
mc_head() {
  _desc="$(mc_desc "$1")"
  mc_msg ""
  mc_rule
  mc_msg "$1"
  [ -n "$_desc" ] && mc_msg "$_desc"
  mc_rule
}
mc_foot() { mc_msg ""; mc_msg "Vol+  next"; mc_msg "Vol-  select"; mc_msg "30s   keep shown"; mc_msg "Power not used"; mc_rule; }

mc_cycle2() {
  _title="$1"; _label0="$2"; _label1="$3"; _idx="${4:-0}"; _steps=0
  case "$_idx" in 1) ;; *) _idx=0 ;; esac
  mc_head "$_title"; mc_msg "1 $_label0"; mc_msg "2 $_label1"; mc_foot
  while [ "$_steps" -le 8 ]; do
    if [ "$_idx" = "1" ]; then mc_msg "Current 2/2: $_label1"; else mc_msg "Current 1/2: $_label0"; fi
    _key="$(mc_read_key)"
    case "$_key" in
      up) if [ "$_idx" = "1" ]; then _idx=0; else _idx=1; fi; _steps=$(( _steps + 1 )) ;;
      down) MC_INDEX="$_idx"; MC_REASON="volume_down"; MC_STEPS="$_steps"; return 0 ;;
      timeout) MC_INDEX="$_idx"; MC_REASON="timeout"; MC_STEPS="$_steps"; return 0 ;;
    esac
  done
  MC_INDEX="$_idx"; MC_REASON="max_steps"; MC_STEPS="$_steps"; return 0
}

mc_cycle4() {
  _title="$1"; _label0="$2"; _label1="$3"; _label2="$4"; _label3="$5"; _idx="${6:-0}"; _steps=0
  case "$_idx" in 0|1|2|3) ;; *) _idx=0 ;; esac
  mc_head "$_title"; mc_msg "1 $_label0"; mc_msg "2 $_label1"; mc_msg "3 $_label2"; mc_msg "4 $_label3"; mc_foot
  while [ "$_steps" -le 12 ]; do
    _pos=$(( _idx + 1 ))
    case "$_idx" in 0) _label="$_label0" ;; 1) _label="$_label1" ;; 2) _label="$_label2" ;; 3) _label="$_label3" ;; esac
    mc_msg "Current $_pos/4: $_label"
    _key="$(mc_read_key)"
    case "$_key" in
      up) _idx=$(( (_idx + 1) % 4 )); _steps=$(( _steps + 1 )) ;;
      down) MC_INDEX="$_idx"; MC_REASON="volume_down"; MC_STEPS="$_steps"; return 0 ;;
      timeout) MC_INDEX="$_idx"; MC_REASON="timeout"; MC_STEPS="$_steps"; return 0 ;;
    esac
  done
  MC_INDEX="$_idx"; MC_REASON="max_steps"; MC_STEPS="$_steps"; return 0
}
