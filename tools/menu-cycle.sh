#!/system/bin/sh
MC_TIMEOUT_SECONDS="${MC_TIMEOUT_SECONDS:-30}"
MC_DEBOUNCE_SECONDS="${MC_DEBOUNCE_SECONDS:-0.45}"

mc_msg() { if command -v ui_print >/dev/null 2>&1; then ui_print "$*"; else echo "$*"; fi; }

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

mc_head() { mc_msg ""; mc_msg "----------------------------------------"; mc_msg "$1"; mc_msg "----------------------------------------"; }
mc_foot() { mc_msg ""; mc_msg "Vol+  next"; mc_msg "Vol-  select"; mc_msg "30s   keep shown"; mc_msg "Power not used"; mc_msg "----------------------------------------"; }

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
