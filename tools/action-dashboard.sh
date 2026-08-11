#!/system/bin/sh
ID="${ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-/data/adb/modules/$ID}"
CONFIG_DIR="${THERMAL_CONFIG_DIR:-/data/adb/$ID}"
CONFIG_FILE="$CONFIG_DIR/config.env"
ZRAM_LAYOUT="$MODDIR/tools/zram/materialize-zram-choice.sh"
EH_CONTROL="$MODDIR/tools/zram/emerald-hill-control.sh"
EH_EVENT_LOG="$CONFIG_DIR/zram-eh/events.log"
LMKD_RELOAD_EVIDENCE="$CONFIG_DIR/lmkd-reload.env"
PTUNE_ROOTS="${PTUNE_MODULE_ROOTS:-/data/adb/modules/ptune /data/adb/modules_update/ptune}"
ACTION_DASHBOARD_PERF="$MODDIR/guard/action-dashboard-performance.env"
STATUS_DIRTY=1
STATUS_SHOWN=0
STATUS_REFRESH_COUNT=0
STATUS_CACHED_PRINT_COUNT=0
ACTION_MENU_RENDER_COUNT=0

MENU_CYCLE_AVAILABLE=0
[ -s "$MODDIR/tools/menu/menu-cycle.sh" ] && . "$MODDIR/tools/menu/menu-cycle.sh" && MENU_CYCLE_AVAILABLE=1
POLICY_HELPER="$MODDIR/tools/core/outdoor-runtime-policy.sh"
POLICY_AVAILABLE=0
[ -s "$POLICY_HELPER" ] && . "$POLICY_HELPER" && POLICY_AVAILABLE=1

POLICY_DEVICE="${THERMAL_DEVICE:-$(getprop ro.product.device 2>/dev/null || true)}"
POLICY_ANDROID="${THERMAL_ANDROID:-$(getprop ro.build.version.release 2>/dev/null || true)}"
POLICY_BUILD="${THERMAL_BUILD_ID:-$(getprop ro.build.id 2>/dev/null || true)}"
[ -n "$POLICY_DEVICE" ] || POLICY_DEVICE=unknown
[ -n "$POLICY_ANDROID" ] || POLICY_ANDROID=unknown
[ -n "$POLICY_BUILD" ] || POLICY_BUILD=unknown

msg() {
  if command -v ui_print >/dev/null 2>&1; then ui_print "$*"; else echo "$*"; fi
}

if [ "$MENU_CYCLE_AVAILABLE" != "1" ] || [ "$POLICY_AVAILABLE" != "1" ]; then
  msg "! Action menu unavailable"
  if [ -s "$MODDIR/tools/debug/status-cached-print.sh" ]; then
    MODDIR="$MODDIR" sh "$MODDIR/tools/debug/status-cached-print.sh" || true
  elif [ -s "$MODDIR/tools/debug/status-lib.sh" ]; then
    sh "$MODDIR/tools/debug/status-lib.sh" print || true
  fi
  exit 0
fi

cfg_get() {
  k="$1"
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^${k}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${k}=//" | tr -d '\r'
}

cfg_set() {
  k="$1"
  v="$2"
  mkdir -p "$CONFIG_DIR" 2>/dev/null || true
  touch "$CONFIG_FILE" 2>/dev/null || true
  tmp="$CONFIG_FILE.tmp.$$"
  grep -v "^${k}=" "$CONFIG_FILE" 2>/dev/null > "$tmp" || true
  printf '%s=%s\n' "$k" "$v" >> "$tmp"
  mv "$tmp" "$CONFIG_FILE"
  chmod 0600 "$CONFIG_FILE" 2>/dev/null || true
}

strip_outdoor_suffix() {
  p="$1"
  case "$p" in
    */outdoor-extended) echo "${p%/outdoor-extended}/base" ;;
    */outdoor-plus) echo "${p%/outdoor-plus}/base" ;;
    */outdoor-safe) echo "${p%/outdoor-safe}/base" ;;
    *-outdoor-extended) echo "${p%-outdoor-extended}" ;;
    *-outdoor-plus) echo "${p%-outdoor-plus}" ;;
    *-outdoor-safe) echo "${p%-outdoor-safe}" ;;
    *) echo "$p" ;;
  esac
}

current_base_profile() {
  echo "dynamic"
}

variant_exists() {
  case "$2" in stock|outdoor-safe|outdoor-plus|outdoor-extended) ;; *) return 1 ;; esac
  thermal_outdoor_profile_admitted "$2" "$POLICY_DEVICE" "$POLICY_ANDROID" "$POLICY_BUILD"
}

policy_max_delta() {
  thermal_outdoor_max_delta "$POLICY_DEVICE" "$POLICY_ANDROID" "$POLICY_BUILD" 2>/dev/null || printf '%s\n' 0
}

policy_label() {
  _profile="$1"
  _label="$2"
  if variant_exists dynamic "$_profile"; then
    printf '%s\n' "$_label"
  else
    printf '%s\n' "$_label blocked"
  fi
}

selected_variant_profile() {
  cfg_get THERMAL_OUTDOOR_PROFILE
}

mark_status_dirty() {
  STATUS_DIRTY=1
}

refresh_status() {
  if [ -s "$MODDIR/tools/debug/status-lib.sh" ]; then
    sh "$MODDIR/tools/debug/status-lib.sh" update >/dev/null 2>&1 || true
    STATUS_REFRESH_COUNT=$((STATUS_REFRESH_COUNT + 1))
  fi
  STATUS_DIRTY=0
}

ensure_status() {
  [ "$STATUS_DIRTY" = 0 ] || refresh_status
}

show_status() {
  msg ""
  msg "----------------------------------------"
  msg "Pixel 10 Thermal & Memory Control"
  msg "----------------------------------------"
  if [ -s "$MODDIR/tools/debug/status-cached-print.sh" ]; then
    MODDIR="$MODDIR" sh "$MODDIR/tools/debug/status-cached-print.sh"
    STATUS_CACHED_PRINT_COUNT=$((STATUS_CACHED_PRINT_COUNT + 1))
  elif [ -s "$MODDIR/tools/debug/status-lib.sh" ]; then
    sh "$MODDIR/tools/debug/status-lib.sh" print
  else
    msg "! status helper missing"
  fi
  msg "----------------------------------------"
}

ui_menu3() {
  _title="$1"; _label0="$2"; _label1="$3"; _label2="$4"; _idx="${5:-0}"; _steps=0
  case "$_idx" in 0|1|2) ;; *) _idx=0 ;; esac
  mc_head "$_title"; mc_msg "1 $_label0"; mc_msg "2 $_label1"; mc_msg "3 $_label2"; mc_foot
  while [ "$_steps" -le 12 ]; do
    _pos=$(( _idx + 1 ))
    case "$_idx" in 0) _label="$_label0" ;; 1) _label="$_label1" ;; *) _label="$_label2" ;; esac
    mc_msg "Current $_pos/3: $_label"
    _key="$(mc_read_key)"
    case "$_key" in
      up) _idx=$(( (_idx + 1) % 3 )); _steps=$(( _steps + 1 )) ;;
      down) UI_INDEX="$_idx"; UI_REASON="volume_down"; UI_STEPS="$_steps"; return 0 ;;
      timeout) UI_INDEX="$_idx"; UI_REASON="timeout"; UI_STEPS="$_steps"; return 0 ;;
    esac
  done
  UI_INDEX="$_idx"; UI_REASON="max_steps"; UI_STEPS="$_steps"; return 0
}

ui_menu4() {
  _title="$1"; _label0="$2"; _label1="$3"; _label2="$4"; _label3="$5"; _idx="${6:-0}"; _steps=0
  case "$_idx" in 0|1|2|3) ;; *) _idx=0 ;; esac
  mc_head "$_title"; mc_msg "1 $_label0"; mc_msg "2 $_label1"; mc_msg "3 $_label2"; mc_msg "4 $_label3"; mc_foot
  while [ "$_steps" -le 14 ]; do
    _pos=$(( _idx + 1 ))
    case "$_idx" in 0) _label="$_label0" ;; 1) _label="$_label1" ;; 2) _label="$_label2" ;; *) _label="$_label3" ;; esac
    mc_msg "Current $_pos/4: $_label"
    _key="$(mc_read_key)"
    case "$_key" in
      up) _idx=$(( (_idx + 1) % 4 )); _steps=$(( _steps + 1 )) ;;
      down) UI_INDEX="$_idx"; UI_REASON="volume_down"; UI_STEPS="$_steps"; return 0 ;;
      timeout) UI_INDEX="$_idx"; UI_REASON="timeout"; UI_STEPS="$_steps"; return 0 ;;
    esac
  done
  UI_INDEX="$_idx"; UI_REASON="max_steps"; UI_STEPS="$_steps"; return 0
}

ui_menu5() {
  _title="$1"; _label0="$2"; _label1="$3"; _label2="$4"; _label3="$5"; _label4="$6"; _idx="${7:-0}"; _steps=0
  case "$_idx" in 0|1|2|3|4) ;; *) _idx=0 ;; esac
  mc_head "$_title"; mc_msg "1 $_label0"; mc_msg "2 $_label1"; mc_msg "3 $_label2"; mc_msg "4 $_label3"; mc_msg "5 $_label4"; mc_foot
  while [ "$_steps" -le 16 ]; do
    _pos=$(( _idx + 1 ))
    case "$_idx" in 0) _label="$_label0" ;; 1) _label="$_label1" ;; 2) _label="$_label2" ;; 3) _label="$_label3" ;; *) _label="$_label4" ;; esac
    mc_msg "Current $_pos/5: $_label"
    _key="$(mc_read_key)"
    case "$_key" in
      up) _idx=$(( (_idx + 1) % 5 )); _steps=$(( _steps + 1 )) ;;
      down) UI_INDEX="$_idx"; UI_REASON="volume_down"; UI_STEPS="$_steps"; return 0 ;;
      timeout) UI_INDEX="$_idx"; UI_REASON="timeout"; UI_STEPS="$_steps"; return 0 ;;
    esac
  done
  UI_INDEX="$_idx"; UI_REASON="max_steps"; UI_STEPS="$_steps"; return 0
}

ui_menu6() {
  _title="$1"; _label0="$2"; _label1="$3"; _label2="$4"; _label3="$5"; _label4="$6"; _label5="$7"; _idx="${8:-0}"; _steps=0
  case "$_idx" in 0|1|2|3|4|5) ;; *) _idx=0 ;; esac
  mc_head "$_title"; mc_msg "1 $_label0"; mc_msg "2 $_label1"; mc_msg "3 $_label2"; mc_msg "4 $_label3"; mc_msg "5 $_label4"; mc_msg "6 $_label5"; mc_foot
  while [ "$_steps" -le 18 ]; do
    _pos=$(( _idx + 1 ))
    case "$_idx" in 0) _label="$_label0" ;; 1) _label="$_label1" ;; 2) _label="$_label2" ;; 3) _label="$_label3" ;; 4) _label="$_label4" ;; *) _label="$_label5" ;; esac
    mc_msg "Current $_pos/6: $_label"
    _key="$(mc_read_key)"
    case "$_key" in
      up) _idx=$(( (_idx + 1) % 6 )); _steps=$(( _steps + 1 )) ;;
      down) UI_INDEX="$_idx"; UI_REASON="volume_down"; UI_STEPS="$_steps"; return 0 ;;
      timeout) UI_INDEX="$_idx"; UI_REASON="timeout"; UI_STEPS="$_steps"; return 0 ;;
    esac
  done
  UI_INDEX="$_idx"; UI_REASON="max_steps"; UI_STEPS="$_steps"; return 0
}

rematerialize_thermal_overlay() {
  _polling="$1"
  _profile="$2"

  if ! variant_exists dynamic "$_profile"; then
    msg "! Thermal $_profile blocked on $POLICY_BUILD"
    msg "! Maximum admitted delta: $(policy_max_delta)"
    return 1
  fi

  _validator="$MODDIR/tools/core/patch-thermal-validated.sh"
  if [ ! -s "$_validator" ]; then
    msg "! Validated Thermal materializer missing"
    return 1
  fi
  chmod 0755 "$_validator" 2>/dev/null || true
  if ! sh "$_validator" "$_polling" "$_profile" "$MODDIR"; then
    msg "! Thermal validation failed"
    msg "! Existing settings kept"
    return 1
  fi

  printf '%s\n' "dynamic" > "$MODDIR/guard/selected_profile" 2>/dev/null || true
  printf '%s\n' "yes" > "$MODDIR/guard/action_cycle_pending_reboot" 2>/dev/null || true
  msg "- Validated profile materialized"
  msg "- Reboot required"
  return 0
}

set_polling() {
  if [ "$(cfg_get THERMAL_DISABLED)" = "1" ]; then
    msg "! Thermal features are disabled."
    sleep 2
    return 0
  fi
  cur="$(cfg_get THERMAL_POLLING_MODE)"; case "$cur" in stock) idx=1 ;; *) idx=0 ;; esac
  ui_menu3 "Polling Mode" "Module values" "Stock values" "Back" "$idx"
  [ "$UI_REASON" = "timeout" ] && return 0
  case "$UI_INDEX" in
    0) requested_polling=mod ;;
    1) requested_polling=stock ;;
    *) msg "Back."; return 0 ;;
  esac
  current_profile="$(cfg_get THERMAL_OUTDOOR_PROFILE)"
  [ -n "$current_profile" ] || current_profile=stock
  if rematerialize_thermal_overlay "$requested_polling" "$current_profile"; then
    cfg_set THERMAL_POLLING_MODE "$requested_polling"
    cfg_set THERMAL_POLLING_EFFECTIVE "$requested_polling"
    cfg_set LAST_THERMAL_POLLING_MODE "$requested_polling"
    msg "- Polling: $requested_polling"
  fi
  refresh_status; show_status; msg "Back to Settings."
}

set_thermal_choice() {
  choice="$1"
  case "$choice" in
    outdoor-safe) ack=explicit_user_enable; target=outdoor_safe ;;
    outdoor-plus) ack=explicit_user_enable; target=outdoor_plus ;;
    outdoor-extended) ack=explicit_user_enable_extended; target=outdoor_extended ;;
    *) choice=stock; ack=disabled_or_stock_selected; target=stock ;;
  esac
  cfg_set THERMAL_OUTDOOR_PROFILE "$choice"
  cfg_set THERMAL_OUTDOOR_TARGET "$target"
  cfg_set THERMAL_OUTDOOR_RISK_ACK "$ack"
  cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE action_validated_transaction_v2
  cfg_set THERMAL_OUTDOOR_MAX_ADMITTED_DELTA "$(policy_max_delta)"
  cfg_set THERMAL_OUTDOOR_POLICY_EVIDENCE "$(thermal_outdoor_policy_evidence "$POLICY_DEVICE" "$POLICY_ANDROID" "$POLICY_BUILD")"
  cfg_set LAST_THERMAL_OUTDOOR_PROFILE "$choice"
}

set_thermal() {
  if [ "$(cfg_get THERMAL_DISABLED)" = "1" ]; then
    msg "! Thermal features are disabled."
    sleep 2
    return 0
  fi
  cur="$(cfg_get THERMAL_OUTDOOR_PROFILE)"
  case "$cur" in outdoor-safe) idx=1 ;; outdoor-plus) idx=2 ;; outdoor-extended) idx=3 ;; *) idx=0 ;; esac
  safe_label="$(policy_label outdoor-safe 'Outdoor Safe')"
  plus_label="$(policy_label outdoor-plus 'Outdoor Plus')"
  ext_label="$(policy_label outdoor-extended 'Outdoor Extended')"
  ui_menu5 "Thermal max+$(policy_max_delta)" "Stock" "$safe_label" "$plus_label" "$ext_label" "Back" "$idx"
  [ "$UI_REASON" = "timeout" ] && return 0
  case "$UI_INDEX" in 0) choice=stock ;; 1) choice=outdoor-safe ;; 2) choice=outdoor-plus ;; 3) choice=outdoor-extended ;; *) msg "Back."; return 0 ;; esac
  if ! variant_exists dynamic "$choice"; then
    msg "! $choice is not admitted on $POLICY_BUILD"
    sleep 2
    return 0
  fi
  current_polling="$(cfg_get THERMAL_POLLING_MODE)"
  [ -n "$current_polling" ] || current_polling=mod
  if rematerialize_thermal_overlay "$current_polling" "$choice"; then
    cfg_set THERMAL_SETTINGS_MODE action_settings
    set_thermal_choice "$choice"
    msg "- Thermal: $choice"
  fi
  refresh_status; show_status; msg "Back to Settings."
}

show_eh_event_log() {
  msg ""
  msg "Emerald Hill event log"
  msg "----------------------------------------"
  if [ -r "$EH_EVENT_LOG" ]; then
    tail -n 20 "$EH_EVENT_LOG" 2>/dev/null || true
  else
    msg "No EH events recorded yet."
  fi
  msg "----------------------------------------"
}

set_emerald_hill() {
  if [ "$(cfg_get ENABLE_ZRAM_100P)" != 1 ]; then
    msg "! Enable ZRAM 100% first."
    msg "! Adaptive EH remains the daily default."
    sleep 2
    return 0
  fi

  cur_oc="$(cfg_get ZRAM_EMERALD_OC)"
  [ -n "$cur_oc" ] || cur_oc=0
  case "$cur_oc" in 1) oc_idx=1 ;; *) oc_idx=0 ;; esac
  ui_menu3 "Emerald Hill mode" "Adaptive (daily default)" "EXPERIMENTAL max lock" "Back" "$oc_idx"
  [ "$UI_REASON" = "timeout" ] && return 0

  case "$UI_INDEX" in
    0)
      cfg_set ZRAM_EMERALD_OC 0
      cfg_set ZRAM_EH_RISK_ACK none
      cfg_set LAST_ZRAM_100P enabled_standard
      if [ -s "$EH_CONTROL" ]; then
        MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" ZRAM_EH_CALLER=action_adaptive \
          sh "$EH_CONTROL" restore >/dev/null 2>&1 || true
      fi
      msg "- Emerald Hill: adaptive daily mode"
    ;;
    1)
      cfg_set ENABLE_ZRAM_100P 1
      cfg_set ZRAM_RISK_ACK explicit_user_enable
      cfg_set ZRAM_EMERALD_OC 1
      cfg_set ZRAM_EH_RISK_ACK explicit_user_enable_max_lock
      cfg_set LAST_ZRAM_100P enabled_max_lock
      msg "! EXPERIMENTAL: higher heat and battery use are expected."
      if [ -s "$EH_CONTROL" ] &&
         MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" ZRAM_EH_CALLER=action_experimental_max \
           sh "$EH_CONTROL" apply >/dev/null 2>&1; then
        msg "- Emerald Hill max lock applied and logged"
      else
        msg "! Max lock configured but runtime apply failed"
        msg "! Reboot path remains configured; inspect EH event log"
      fi
    ;;
    *) msg "Back."; return 0 ;;
  esac

  printf '%s
' yes > "$MODDIR/guard/action_cycle_pending_reboot" 2>/dev/null || true
  mark_status_dirty
  refresh_status
  show_status
  msg "Back to Advanced."
}

set_zram() {
  cur_z="$(cfg_get ENABLE_ZRAM_100P)"
  case "$cur_z" in 1) idx=0 ;; *) idx=1 ;; esac
  ui_menu3 "ZRAM 100%" "Enable 100p (adaptive EH)" "Disable" "Back" "$idx"
  [ "$UI_REASON" = "timeout" ] && return 0

  case "$UI_INDEX" in
    0)
      if [ ! -r "$ZRAM_LAYOUT" ] ||
         ! MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$ZRAM_LAYOUT" enable >/dev/null 2>&1; then
        msg "! ZRAM layout materialization failed"
        msg "! Existing configuration kept"
        return 0
      fi
      cfg_set ENABLE_ZRAM_100P 1
      cfg_set ZRAM_RESTART_MMD 1
      cfg_set ZRAM_RISK_ACK explicit_user_enable
      cfg_set ZRAM_EMERALD_OC 0
      cfg_set ZRAM_EH_RISK_ACK none
      cfg_set LAST_ZRAM_100P enabled_standard
      if [ -s "$EH_CONTROL" ]; then
        MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" ZRAM_EH_CALLER=action_zram_enable \
          sh "$EH_CONTROL" restore >/dev/null 2>&1 || true
      fi
      if [ -s "$MODDIR/tools/zram/apply-zram-100p.sh" ]; then
        msg "- Applying runtime properties"
        if ! MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$MODDIR/tools/zram/apply-zram-100p.sh" manual >/dev/null 2>&1; then
          msg "! Runtime apply failed; reboot path remains configured"
        fi
      fi
      printf '%s
' yes > "$MODDIR/guard/action_cycle_pending_reboot" 2>/dev/null || true
      msg "- ZRAM: enabled with adaptive EH"
      msg "- Experimental max lock is under Advanced"
      msg "- Reboot required for layout guarantee"
    ;;
    1)
      if [ ! -r "$ZRAM_LAYOUT" ] ||
         ! MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$ZRAM_LAYOUT" disable >/dev/null 2>&1; then
        msg "! ZRAM layout removal failed"
        msg "! Existing configuration kept"
        return 0
      fi
      if [ -s "$EH_CONTROL" ]; then
        MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" ZRAM_EH_CALLER=action_zram_disable \
          sh "$EH_CONTROL" restore >/dev/null 2>&1 || true
      fi
      cfg_set ENABLE_ZRAM_100P 0
      cfg_set ZRAM_EMERALD_OC 0
      cfg_set ZRAM_RESTART_MMD 0
      cfg_set ZRAM_RISK_ACK disabled_by_user
      cfg_set ZRAM_EH_RISK_ACK disabled_by_user
      cfg_set LAST_ZRAM_100P disabled
      printf '%s
' yes > "$MODDIR/guard/action_cycle_pending_reboot" 2>/dev/null || true
      msg "- ZRAM: disabled"
      msg "- Reboot required"
    ;;
    *) msg "Back."; return 0 ;;
  esac
  refresh_status
  show_status
  msg "Back to Settings."
}

settings_loop() {
  while :; do
    mc_cycle4 "Settings" "Polling Mode" "Thermal Profile" "ZRAM 100%" "Back" 0
    [ "$MC_REASON" = "timeout" ] && return 0
    case "$MC_INDEX" in 0) set_polling ;; 1) set_thermal ;; 2) set_zram ;; *) msg "Back."; return 0 ;; esac
  done
}

ptune_dir() {
  for d in $PTUNE_ROOTS; do
    [ -f "$d/module.prop" ] || continue
    grep -q '^id=ptune$' "$d/module.prop" 2>/dev/null || continue
    echo "$d"; return 0
  done
  return 1
}

ptune_enabled() { d="$1"; [ -n "$d" ] || return 1; [ ! -e "$d/disable" ] && [ ! -e "$d/remove" ]; }
ptune_version_code() { d="$1"; [ -n "$d" ] || return 0; grep -E '^versionCode=' "$d/module.prop" 2>/dev/null | tail -n 1 | sed 's/^versionCode=//'; }
ptune_known_bad() { d="$1"; [ "$(ptune_version_code "$d")" = 200 ]; }
ptune_runtime_bad() {
  d="$1"
  [ "$(ptune_version_code "$d")" = 200 ] || return 1
  [ "$(getprop ro.product.device 2>/dev/null)" = mustang ] || return 1
  [ "$(getprop ro.build.id 2>/dev/null)" = CP1A.260505.005 ]
}

ptune_status() {
  d="$(ptune_dir 2>/dev/null || true)"
  msg "pTune Status"
  if [ -z "$d" ]; then msg "pTune: not installed"; return 0; fi
  msg "pTune: installed"
  if ptune_enabled "$d"; then msg "State: active"; else msg "State: disabled"; fi
  vc="$(ptune_version_code "$d")"
  [ -n "$vc" ] && msg "VersionCode: $vc"
  if ptune_known_bad "$d"; then msg "Bad version: yes"; else msg "Bad version: no"; fi
  if ptune_runtime_bad "$d"; then msg "Runtime block: yes"; else msg "Runtime block: no"; fi
  msg "Override: $(cfg_get PTUNE_OVERRIDE_MENU)"
}

ptune_override_off() {
  cfg_set PTUNE_OVERRIDE_MENU off; cfg_set ALLOW_THERMAL_WITH_PTUNE 0; cfg_set RISK_ACK_PTUNE_THERMAL_COLLISION none; cfg_set LAST_PTUNE_OVERRIDE 0
  mark_status_dirty
  msg "pTune override: OFF"; msg "Reinstall or reflash required"
}

ptune_override_on() {
  d="$(ptune_dir 2>/dev/null || true)"
  if [ -z "$d" ]; then msg "pTune not installed."; ptune_override_off; return 0; fi
  if ! ptune_enabled "$d"; then msg "pTune disabled."; msg "Override not needed."; ptune_override_off; return 0; fi
  if ptune_known_bad "$d"; then msg "Known-bad pTune."; msg "Override blocked."; ptune_override_off; return 0; fi
  ui_menu3 "pTune Risk" "Keep OFF" "Enable risk" "Back" 0
  [ "$UI_REASON" = "timeout" ] && return 0
  case "$UI_INDEX" in
    1) cfg_set PTUNE_OVERRIDE_MENU on; cfg_set ALLOW_THERMAL_WITH_PTUNE 1; cfg_set RISK_ACK_PTUNE_THERMAL_COLLISION I_UNDERSTAND_BOOTLOOP_RISK; cfg_set LAST_PTUNE_OVERRIDE 1; mark_status_dirty; msg "pTune override: ON"; msg "Reinstall or reflash required" ;;
    *) ptune_override_off ;;
  esac
}

update_channel_status() {
  if [ ! -s "$MODDIR/tools/update-channel-switch.sh" ]; then
    msg "Update Channel"
    msg "Switch tool missing"
    return 0
  fi
  sh "$MODDIR/tools/update-channel-switch.sh" status
}

update_channel_loop() {
  while :; do
    update_channel_status
    if [ ! -s "$MODDIR/tools/update-channel-switch.sh" ]; then msg "! Cannot switch update channel."; msg "Switch tool missing."; return 0; fi
    ui_menu3 "Update Channel" "Use Stable" "Use Test" "Back" 2
    [ "$UI_REASON" = "timeout" ] && return 0
    case "$UI_INDEX" in
      0)
        sh "$MODDIR/tools/update-channel-switch.sh" stable
        msg "Stable selected"
        sleep 1
      ;;
      1)
        sh "$MODDIR/tools/update-channel-switch.sh" prerelease
        msg "Test selected"
        sleep 1
      ;;
      *) msg "Back."; return 0 ;;
    esac
  done
}

show_lmkd_evidence() {
  msg ""
  msg "Memory Killer evidence"
  msg "----------------------------------------"
  if [ -r "$LMKD_RELOAD_EVIDENCE" ]; then
    cat "$LMKD_RELOAD_EVIDENCE" 2>/dev/null || true
  else
    msg "No Memory Killer evidence recorded yet."
  fi
  msg "----------------------------------------"
}

set_lmkd_reload() {
  cur="$(cfg_get LMKD_SWAP_LOW_RELOAD)"
  case "$cur" in 1) idx=1 ;; *) idx=0 ;; esac
  ui_menu3 "LMKD 1% reload" "Disabled (stock)" "EXPERIMENTAL 1%" "Back" "$idx"
  [ "$UI_REASON" = "timeout" ] && return 0
  apply="$MODDIR/tools/zram/apply-zram-100p.sh"
  tmp="$CONFIG_DIR/lmkd-action.$$.log"
  case "$UI_INDEX" in
    0)
      cfg_set LMKD_SWAP_LOW_RELOAD 0
      cfg_set LMKD_SWAP_LOW_RISK_ACK none
      cfg_set LAST_LMKD_SWAP_LOW_RELOAD disabled
      if [ -s "$apply" ]; then
        MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$apply" lmkd_restore > "$tmp" 2>&1 || true
        tail -n 3 "$tmp" 2>/dev/null | while IFS= read -r line; do msg "$line"; done
      fi
      msg "- LMKD 1% reload: disabled"
    ;;
    1)
      if [ "$(cfg_get ENABLE_ZRAM_100P)" != 1 ]; then
        msg "! Enable ZRAM 100% before this experiment."
        rm -f "$tmp" 2>/dev/null || true
        sleep 2
        return 0
      fi
      cfg_set LMKD_SWAP_LOW_RELOAD 1
      cfg_set LMKD_SWAP_LOW_RISK_ACK explicit_user_reload
      cfg_set LAST_LMKD_SWAP_LOW_RELOAD enabled
      if [ -s "$apply" ]; then
        MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$apply" manual > "$tmp" 2>&1 || true
        tail -n 4 "$tmp" 2>/dev/null | while IFS= read -r line; do msg "$line"; done
      fi
      msg "! EXPERIMENTAL LMKD 1% reload enabled."
      msg "! AOSP reinit first; full restart only as fallback."
    ;;
    *) rm -f "$tmp" 2>/dev/null || true; msg "Back."; return 0 ;;
  esac
  rm -f "$tmp" 2>/dev/null || true
  mark_status_dirty
  refresh_status
  show_status
  msg "Back to Advanced."
}

advanced_loop() {
  while :; do
    ui_menu6 "Advanced" "Emerald Hill mode" "LMKD 1% reload" "pTune Status" "pTune Override" "Update Channel" "Back" 0
    [ "$UI_REASON" = "timeout" ] && return 0
    case "$UI_INDEX" in
      0) set_emerald_hill ;;
      1) set_lmkd_reload ;;
      2) ptune_status; sleep 2 ;;
      3)
        if [ "$(cfg_get ALLOW_THERMAL_WITH_PTUNE)" = 1 ]; then ptune_override_off; else ptune_override_on; fi
        sleep 2
      ;;
      4) update_channel_loop ;;
      *) msg "Back."; return 0 ;;
    esac
  done
}

toggle_debug_mode() {
  _current="$(cfg_get DEBUG_MODE)"
  [ -n "$_current" ] || _current="$(cfg_get debug_mode)"
  if [ "$_current" = 1 ]; then
    cfg_set DEBUG_MODE 0
    cfg_set debug_mode 0
    cfg_set LAST_DEBUG_MODE silent
    msg "Debug logging: silent"
  else
    cfg_set DEBUG_MODE 1
    cfg_set debug_mode 1
    cfg_set LAST_DEBUG_MODE verbose
    msg "Debug logging: verbose"
  fi
  mark_status_dirty
}

write_dashboard_performance() {
  mkdir -p "$MODDIR/guard" 2>/dev/null || true
  {
    printf '%s\n' 'schema=pixel-thermal-action-dashboard-performance-v1'
    printf '%s\n' "status_refresh_count=$STATUS_REFRESH_COUNT"
    printf '%s\n' "cached_status_print_count=$STATUS_CACHED_PRINT_COUNT"
    printf '%s\n' "main_menu_render_count=$ACTION_MENU_RENDER_COUNT"
    printf '%s\n' 'recursive_meta_backend_find=absent'
    printf '%s\n' 'supported_manifest_validation_cache=enabled'
  } > "$ACTION_DASHBOARD_PERF" 2>/dev/null || true
}

debug_loop() {
  while :; do
    ui_menu6 "Debug" "Feature Status" "Support Snapshot (ZIP)" "EH Event Log" "Memory Killer Evidence" "Debug Logging" "Back" 0
    [ "$UI_REASON" = "timeout" ] && return 0
    case "$UI_INDEX" in
      0) refresh_status; show_status; sleep 2 ;;
      1)
        if [ -s "$MODDIR/tools/bootguard/collect-debug.sh" ]; then
          sh "$MODDIR/tools/bootguard/collect-debug.sh"
        else
          msg "Collector missing"
        fi
        sleep 2
      ;;
      2) show_eh_event_log; sleep 2 ;;
      3) show_lmkd_evidence; sleep 2 ;;
      4) toggle_debug_mode; sleep 1 ;;
      *) msg "Back."; return 0 ;;
    esac
  done
}

action_loop() {
  while :; do
    if [ "$STATUS_DIRTY" = 1 ] || [ "$STATUS_SHOWN" = 0 ]; then
      ensure_status
      show_status
      STATUS_SHOWN=1
    fi
    ACTION_MENU_RENDER_COUNT=$((ACTION_MENU_RENDER_COUNT + 1))
    mc_cycle4 "Action" "Settings" "Debug" "Advanced" "Exit" 0
    [ "$MC_REASON" = "timeout" ] && return 0
    case "$MC_INDEX" in
      0) settings_loop ;;
      1) debug_loop ;;
      2) advanced_loop ;;
      *) msg "Exit."; return 0 ;;
    esac
  done
}

action_loop
write_dashboard_performance
exit 0
