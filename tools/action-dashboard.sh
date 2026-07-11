#!/system/bin/sh
ID="${ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-/data/adb/modules/$ID}"
CONFIG_DIR="/data/adb/$ID"
CONFIG_FILE="$CONFIG_DIR/config.env"

MENU_CYCLE_AVAILABLE=0
[ -s "$MODDIR/tools/menu-cycle.sh" ] && . "$MODDIR/tools/menu-cycle.sh" && MENU_CYCLE_AVAILABLE=1
[ -s "$MODDIR/tools/profile-matrix-test9.sh" ] && . "$MODDIR/tools/profile-matrix-test9.sh" || true

msg() {
  if command -v ui_print >/dev/null 2>&1; then ui_print "$*"; else echo "$*"; fi
}

if [ "$MENU_CYCLE_AVAILABLE" != "1" ]; then
  msg "! Action menu unavailable"
  if [ -s "$MODDIR/tools/status-lib.sh" ]; then
    sh "$MODDIR/tools/status-lib.sh" print || true
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
  p="$(sed -n 's/^profile=//p' "$MODDIR/install-state.txt" 2>/dev/null | tail -n 1)"
  [ -n "$p" ] || p="$(cat "$MODDIR/guard/selected_profile" 2>/dev/null | head -n 1)"
  [ -n "$p" ] || p="unknown"
  strip_outdoor_suffix "$p"
}

variant_exists() {
  base="$1"
  variant="$2"
  case "$variant" in stock|base) return 0 ;; esac
  case "$variant" in
    outdoor-safe|outdoor-plus|outdoor-extended)
      if command -v profile_matrix_variant >/dev/null 2>&1; then
        path="$(profile_matrix_variant "$base" "$variant" 2>/dev/null || true)"
        [ -n "$path" ] && [ -s "$MODDIR/profiles/$path/system/vendor/etc/thermal_info_config_throttling.json" ] && return 0
      fi
      [ -s "$MODDIR/profiles/$base-$variant/system/vendor/etc/thermal_info_config_throttling.json" ]
    ;;
    *) return 1 ;;
  esac
}

selected_variant_profile() {
  base="$1"
  choice="$(cfg_get THERMAL_OUTDOOR_PROFILE)"
  case "$choice" in
    outdoor-safe|outdoor-plus|outdoor-extended)
      if variant_exists "$base" "$choice"; then
        if command -v profile_matrix_variant >/dev/null 2>&1; then
          profile_matrix_variant "$base" "$choice" 2>/dev/null || echo "$base"
        else
          echo "$base-$choice"
        fi
      else
        echo "$base"
      fi
    ;;
    *) echo "$base" ;;
  esac
}

refresh_status() {
  if [ -s "$MODDIR/tools/status-lib.sh" ]; then
    sh "$MODDIR/tools/status-lib.sh" update >/dev/null 2>&1 || true
  fi
}

show_status() {
  msg ""
  msg "----------------------------------------"
  msg "Pixel 10 Thermal & Memory Control"
  msg "----------------------------------------"
  if [ -s "$MODDIR/tools/status-lib.sh" ]; then
    sh "$MODDIR/tools/status-lib.sh" print
  else
    msg "! status-lib missing"
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

ui_menu5() {
  _title="$1"; _label0="$2"; _label1="$3"; _label2="$4"; _label3="$5"; _label4="$6"; _idx="${7:-0}"; _steps=0
  case "$_idx" in 0|1|2|3|4) ;; *) _idx=0 ;; esac
  mc_head "$_title"; mc_msg "1 $_label0"; mc_msg "2 $_label1"; mc_msg "3 $_label2"; mc_msg "4 $_label3"; mc_msg "5 $_label4"; mc_foot
  while [ "$_steps" -le 15 ]; do
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

rematerialize_thermal_overlay() {
  base="$(current_base_profile)"
  if [ "$base" = "unknown" ] || [ ! -d "$MODDIR/profiles/$base/system/vendor/etc" ]; then
    msg "! Cannot determine profile."; msg "! Run Debug ZIP."; return 1
  fi
  selected="$(selected_variant_profile "$base")"
  profile_dir="$MODDIR/profiles/$selected/system/vendor/etc"
  active_dir="$MODDIR/system/vendor/etc"
  for f in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
    if [ ! -s "$profile_dir/$f" ]; then msg "! Missing profile file."; msg "$f"; return 1; fi
  done
  mkdir -p "$active_dir" "$MODDIR/guard" 2>/dev/null || true
  rm -f "$active_dir"/thermal_info_config*.json 2>/dev/null || true
  cp -fp "$profile_dir"/thermal_info_config*.json "$active_dir"/ || return 1
  chmod 0644 "$active_dir"/thermal_info_config*.json 2>/dev/null || true
  if [ -s "$MODDIR/tools/apply-polling-mode.sh" ]; then
    BASE_PROFILE="$base" ACTIVE_DIR="$active_dir" MODDIR="$MODDIR" CONFIG_FILE="$CONFIG_FILE" sh "$MODDIR/tools/apply-polling-mode.sh" action 2>/dev/null || true
  fi
  printf '%s\n' "$selected" > "$MODDIR/guard/selected_profile" 2>/dev/null || true
  printf '%s\n' "yes" > "$MODDIR/guard/action_cycle_pending_reboot" 2>/dev/null || true
  msg "- Profile saved"; msg "- Selected profile:"; msg "$selected"; msg "- Reboot recommended"; msg "- Vendor mount refresh"; return 0
}

set_polling() {
  cur="$(cfg_get THERMAL_POLLING_MODE)"; case "$cur" in stock) idx=1 ;; *) idx=0 ;; esac
  ui_menu3 "Polling Mode" "Module values" "Stock values" "Back" "$idx"
  [ "$UI_REASON" = "timeout" ] && return 0
  case "$UI_INDEX" in
    0) cfg_set THERMAL_POLLING_MODE mod; cfg_set LAST_THERMAL_POLLING_MODE mod; msg "- Polling: mod" ;;
    1) cfg_set THERMAL_POLLING_MODE stock; cfg_set LAST_THERMAL_POLLING_MODE stock; msg "- Polling: stock" ;;
    *) msg "Back."; return 0 ;;
  esac
  rematerialize_thermal_overlay || true
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
  cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE action_settings_menu
  cfg_set LAST_THERMAL_OUTDOOR_PROFILE "$choice"
}

set_thermal() {
  base="$(current_base_profile)"
  if [ "$base" = "unknown" ]; then msg "! Base profile unknown."; msg "Run Debug ZIP."; return 0; fi
  cur="$(cfg_get THERMAL_OUTDOOR_PROFILE)"
  case "$cur" in outdoor-safe) idx=1 ;; outdoor-plus) idx=2 ;; outdoor-extended) idx=3 ;; *) idx=0 ;; esac
  ui_menu5 "Thermal Profile" "Stock" "Outdoor Safe" "Outdoor Plus" "Outdoor Extended" "Back" "$idx"
  [ "$UI_REASON" = "timeout" ] && return 0
  case "$UI_INDEX" in 0) choice=stock ;; 1) choice=outdoor-safe ;; 2) choice=outdoor-plus ;; 3) choice=outdoor-extended ;; *) msg "Back."; return 0 ;; esac
  if ! variant_exists "$base" "$choice"; then msg "! Profile missing."; msg "Using Stock"; choice=stock; fi
  cfg_set THERMAL_SETTINGS_MODE action_settings
  set_thermal_choice "$choice"
  msg "- Thermal: $choice"
  rematerialize_thermal_overlay || true
  refresh_status; show_status; msg "Back to Settings."
}

set_zram() {
  cur="$(cfg_get ENABLE_ZRAM_100P)"; case "$cur" in 1) idx=0 ;; *) idx=1 ;; esac
  ui_menu3 "ZRAM 100%" "Enable 100p" "Disable" "Back" "$idx"
  [ "$UI_REASON" = "timeout" ] && return 0
  case "$UI_INDEX" in
    0)
      cfg_set ENABLE_ZRAM_100P 1; cfg_set ZRAM_RESTART_MMD 1; cfg_set ZRAM_RISK_ACK explicit_user_enable; cfg_set LAST_ZRAM_100P enabled
      msg "- ZRAM: enabled"
      if [ -s "$MODDIR/tools/apply-zram-100p.sh" ]; then msg "- Applying runtime props"; MODDIR="$MODDIR" sh "$MODDIR/tools/apply-zram-100p.sh" manual >/dev/null 2>&1 || true; fi
    ;;
    1)
      cfg_set ENABLE_ZRAM_100P 0; cfg_set ZRAM_RESTART_MMD 0; cfg_set ZRAM_RISK_ACK disabled_by_user; cfg_set LAST_ZRAM_100P disabled
      msg "- ZRAM: disabled"; msg "- Reboot recommended"
    ;;
    *) msg "Back."; return 0 ;;
  esac
  refresh_status; show_status; msg "Back to Settings."
}

settings_loop() {
  while :; do
    mc_cycle4 "Settings" "Polling Mode" "Thermal Profile" "ZRAM 100%" "Back" 0
    [ "$MC_REASON" = "timeout" ] && return 0
    case "$MC_INDEX" in 0) set_polling ;; 1) set_thermal ;; 2) set_zram ;; *) msg "Back."; return 0 ;; esac
  done
}

ptune_dir() {
  for d in /data/adb/modules/ptune /data/adb/modules_update/ptune; do
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
    1) cfg_set PTUNE_OVERRIDE_MENU on; cfg_set ALLOW_THERMAL_WITH_PTUNE 1; cfg_set RISK_ACK_PTUNE_THERMAL_COLLISION I_UNDERSTAND_BOOTLOOP_RISK; cfg_set LAST_PTUNE_OVERRIDE 1; msg "pTune override: ON"; msg "Reinstall or reflash required" ;;
    *) ptune_override_off ;;
  esac
}

update_channel_status() {
    if [ ! -s "$MODDIR/tools/update-channel-switch.sh" ]; then msg "! Cannot switch update channel."; msg "Switch tool missing."; return 0; fi
  if [ -s "$MODDIR/tools/update-channel-switch.sh" ]; then
    sh "$MODDIR/tools/update-channel-switch.sh" status
  else
    msg "Update Channel"
    msg "Switch tool missing"
  fi
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
        msg "Back to Update Channel."
      ;;
      1)
        sh "$MODDIR/tools/update-channel-switch.sh" test
        msg "Back to Update Channel."
      ;;
      *)
        msg "Back."
        return 0
      ;;
    esac
  done
}

advanced_loop() {
  while :; do
    ui_menu5 "Advanced" "pTune Status" "Update Channel" "pTune Override OFF" "pTune Override ON" "Back" 0
    [ "$UI_REASON" = "timeout" ] && return 0
    case "$UI_INDEX" in
      0) ptune_status; msg "Back to Advanced." ;;
      1) update_channel_loop; msg "Back to Advanced." ;;
      2) ptune_override_off; msg "Back to Advanced." ;;
      3) ptune_override_on; msg "Back to Advanced." ;;
      *) msg "Back."; return 0 ;;
    esac
  done
}

debug_zip() {
  show_status
  msg "Creating debug ZIP..."
  if [ -s "$MODDIR/tools/collect-debug.sh" ]; then
    out="$(sh "$MODDIR/tools/collect-debug.sh" 2>&1 || true)"
    path="$(printf '%s\n' "$out" | sed -n 's/^Created: //p' | tail -n 1)"
    [ -n "$path" ] || path="$(printf '%s\n' "$out" | grep -E '/sdcard/Download/pixel_thermal_debug_.*\.zip|/storage/emulated/0/Download/pixel_thermal_debug_.*\.zip' | tail -n 1)"
    msg "Debug ZIP created"
    if [ -n "$path" ]; then file="${path##*/}"; msg "Folder: Download"; msg "File:"; msg "$file"; fi
    msg "Upload ZIP + install log."
  else
    msg "! collect-debug missing"
  fi
  msg "Back to Action."
}


boot_crash_tgz() {
  show_status
  msg "Creating boot crash TGZ..."
  if [ -s "$MODDIR/tools/boot-crash-log-collect.sh" ]; then
    out="$(sh "$MODDIR/tools/boot-crash-log-collect.sh" 2>&1 || true)"
    path="$(printf '%s
' "$out" | sed -n 's/^Created: //p' | tail -n 1)"
    msg "Boot crash archive done"
    if [ -n "$path" ]; then file="${path##*/}"; msg "Folder: Download"; msg "File:"; msg "$file"; fi
    msg "Upload TGZ + install log."
  else
    msg "! boot-crash collector missing"
  fi
  msg "Back to Debug."
}

bootguard_status() {
  msg "Bootguard"
  if [ -s "$MODDIR/tools/bootguard-lib.sh" ]; then
    MODDIR="$MODDIR" CONFIG_FILE="$CONFIG_FILE" sh "$MODDIR/tools/bootguard-lib.sh" status || true
  else
    msg "! bootguard missing"
  fi
  if [ -s "$MODDIR/tools/last-good-diff.sh" ]; then
    MODDIR="$MODDIR" CONFIG_FILE="$CONFIG_FILE" sh "$MODDIR/tools/last-good-diff.sh" || true
  fi
  msg "Back to Debug."
}

bootguard_clear() {
  ui_menu3 "Clear Counters" "Keep State" "Reset Counters" "Back" 0
  [ "$UI_REASON" = "timeout" ] && return 0
  case "$UI_INDEX" in
    1)
      if [ -s "$MODDIR/tools/bootguard-lib.sh" ]; then
        MODDIR="$MODDIR" CONFIG_FILE="$CONFIG_FILE" sh "$MODDIR/tools/bootguard-lib.sh" clear || true
      fi
      msg "Counters cleared"
      msg "Disable preserved"
    ;;
    *) msg "No change." ;;
  esac
  msg "Back to Debug."
}

debug_loop() {
  while :; do
    ui_menu5 "Debug" "Debug ZIP" "Boot Crash Archive" "Bootguard" "Clear Counters" "Back" 0
    [ "$UI_REASON" = "timeout" ] && return 0
    case "$UI_INDEX" in
      0) debug_zip ;;
      1) boot_crash_tgz ;;
      2) bootguard_status ;;
      3) bootguard_clear ;;
      *) msg "Back."; return 0 ;;
    esac
  done
}


action_loop() {
  first=1
  while :; do
    if [ "$first" = "1" ]; then refresh_status; show_status; first=0; fi
    ui_menu5 "Action" "Status" "Settings" "Debug" "Advanced" "Exit" 0
    [ "$UI_REASON" = "timeout" ] && exit 0
    case "$UI_INDEX" in
      0) refresh_status; show_status; msg "Back to Action." ;;
      1) settings_loop ;;
      2) debug_loop ;;
      3) advanced_loop ;;
      *) msg "Exit."; exit 0 ;;
    esac
  done
}

if ! command -v getevent >/dev/null 2>&1; then refresh_status; show_status; exit 0; fi
action_loop
exit 0
