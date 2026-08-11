#!/system/bin/sh
set -eu

MODULE_ID="${MODULE_ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-${0%/*}/..}"
CONFIG_DIR="${THERMAL_CONFIG_DIR:-/data/adb/$MODULE_ID}"
CONFIG_FILE="$CONFIG_DIR/config.env"

mkdir -p "$CONFIG_DIR" 2>/dev/null || true
touch "$CONFIG_FILE" 2>/dev/null || true
chmod 0600 "$CONFIG_FILE" 2>/dev/null || true

[ -s "$MODDIR/tools/menu/menu-cycle.sh" ] && . "$MODDIR/tools/menu/menu-cycle.sh" || exit 0
POLICY_HELPER="$MODDIR/tools/core/outdoor-runtime-policy.sh"
[ -s "$POLICY_HELPER" ] && . "$POLICY_HELPER" || exit 23

POLICY_DEVICE="${THERMAL_DEVICE:-$(getprop ro.product.device 2>/dev/null || true)}"
POLICY_ANDROID="${THERMAL_ANDROID:-$(getprop ro.build.version.release 2>/dev/null || true)}"
POLICY_BUILD="${THERMAL_BUILD_ID:-$(getprop ro.build.id 2>/dev/null || true)}"
[ -n "$POLICY_DEVICE" ] || POLICY_DEVICE=unknown
[ -n "$POLICY_ANDROID" ] || POLICY_ANDROID=unknown
[ -n "$POLICY_BUILD" ] || POLICY_BUILD=unknown
POLICY_MAX_DELTA="$(thermal_outdoor_max_delta "$POLICY_DEVICE" "$POLICY_ANDROID" "$POLICY_BUILD")" || POLICY_MAX_DELTA=0
POLICY_EVIDENCE="$(thermal_outdoor_policy_evidence "$POLICY_DEVICE" "$POLICY_ANDROID" "$POLICY_BUILD")" || POLICY_EVIDENCE=stock_only_no_nonstock_runtime_evidence
POLICY_EXPERIMENTAL=no
if thermal_outdoor_experimental_platform "$POLICY_DEVICE" "$POLICY_ANDROID"; then
  POLICY_EXPERIMENTAL=yes
fi

cfg_get() {
  _key="$1"
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^${_key}=" "$CONFIG_FILE" 2>/dev/null \
    | tail -n 1 \
    | sed "s/^${_key}=//" \
    | tr -d '\r'
}

cfg_set() {
  _key="$1"
  _value="$2"
  _tmp="${CONFIG_FILE}.tmp.$$"
  touch "$CONFIG_FILE" 2>/dev/null || true
  grep -v "^${_key}=" "$CONFIG_FILE" 2>/dev/null > "$_tmp" || true
  printf '%s=%s\n' "$_key" "$_value" >> "$_tmp"
  mv "$_tmp" "$CONFIG_FILE"
  chmod 0600 "$CONFIG_FILE" 2>/dev/null || true
}

ptune_present() {
  for _dir in /data/adb/modules/ptune /data/adb/modules_update/ptune; do
    [ -f "$_dir/module.prop" ] || continue
    grep -q '^id=ptune$' "$_dir/module.prop" 2>/dev/null || continue
    [ -e "$_dir/remove" ] && continue
    printf '%s\n' "$_dir"
    return 0
  done
  return 1
}

has_remembered() {
  for _key in \
    LAST_THERMAL_OUTDOOR_PROFILE \
    LAST_THERMAL_POLLING_MODE \
    LAST_PTUNE_OVERRIDE \
    LAST_DEBUG_MODE \
    LAST_ZRAM_100P \
    LAST_LMKD_SWAP_LOW_RELOAD \
    LAST_INSTALL_SUPPORT_SNAPSHOT \
    LMKD_SWAP_LOW_RELOAD \
    INSTALL_SUPPORT_SNAPSHOT \
    THERMAL_OUTDOOR_PROFILE \
    THERMAL_POLLING_MODE \
    ENABLE_ZRAM_100P; do
    [ -n "$(cfg_get "$_key")" ] && return 0
  done
  return 1
}

normalize_profile() {
  case "$1" in
    outdoor-safe|outdoor-plus|outdoor-extended) printf '%s\n' "$1" ;;
    *) printf '%s\n' stock ;;
  esac
}

cap_profile() {
  _requested="$(normalize_profile "$1")"
  _delta="$(thermal_outdoor_profile_delta "$_requested")" || _delta=0
  if [ "$_delta" -le "$POLICY_MAX_DELTA" ]; then
    printf '%s\n' "$_requested"
  else
    thermal_outdoor_profile_for_delta "$POLICY_MAX_DELTA" 2>/dev/null || printf '%s\n' stock
  fi
}

profile_policy_label() {
  _delta="$1"
  _label="$2"
  if [ "$_delta" -le "$POLICY_MAX_DELTA" ]; then
    printf '%s\n' "$_label"
  else
    printf '%s\n' "$_label blocked"
  fi
}

profile_target() {
  case "$1" in
    outdoor-safe) printf '%s\n' outdoor_safe ;;
    outdoor-plus) printf '%s\n' outdoor_plus ;;
    outdoor-extended) printf '%s\n' outdoor_extended ;;
    *) printf '%s\n' stock ;;
  esac
}

profile_risk() {
  case "$1" in
    outdoor-safe|outdoor-plus) printf '%s\n' explicit_user_enable ;;
    outdoor-extended) printf '%s\n' explicit_user_enable_extended ;;
    *) printf '%s\n' disabled_or_stock_selected ;;
  esac
}

profile_at() {
  case "$1" in
    1) printf '%s\n' outdoor-safe ;;
    2) printf '%s\n' outdoor-plus ;;
    3) printf '%s\n' outdoor-extended ;;
    *) printf '%s\n' stock ;;
  esac
}

profile_label() {
  case "$1" in
    outdoor-safe) printf '%s\n' 'Outdoor Safe' ;;
    outdoor-plus) printf '%s\n' 'Outdoor Plus' ;;
    outdoor-extended) printf '%s\n' 'Outdoor Extended' ;;
    *) printf '%s\n' 'Stock thermal' ;;
  esac
}

apply_profile() {
  _requested="$(normalize_profile "$1")"
  _profile="$(cap_profile "$_requested")"
  if [ "$_profile" != "$_requested" ]; then
    mc_msg "! $_requested blocked on $POLICY_BUILD"
    mc_msg "! Using $_profile (max delta $POLICY_MAX_DELTA)"
  fi
  cfg_set THERMAL_OUTDOOR_REQUESTED_PROFILE "$_requested"
  cfg_set THERMAL_OUTDOOR_PROFILE "$_profile"
  cfg_set THERMAL_OUTDOOR_TARGET "$(profile_target "$_profile")"
  cfg_set THERMAL_OUTDOOR_RISK_ACK "$(profile_risk "$_profile")"
  cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE install_options_runtime_policy_v3
  cfg_set THERMAL_OUTDOOR_MAX_ADMITTED_DELTA "$POLICY_MAX_DELTA"
  cfg_set THERMAL_OUTDOOR_POLICY_EVIDENCE "$POLICY_EVIDENCE"
  cfg_set LAST_THERMAL_OUTDOOR_PROFILE "$_profile"
}

apply_polling() {
  case "$1" in stock) _polling=stock ;; *) _polling=mod ;; esac
  cfg_set THERMAL_POLLING_MODE "$_polling"
  cfg_set THERMAL_POLLING_EFFECTIVE "$_polling"
  cfg_set LAST_THERMAL_POLLING_MODE "$_polling"
}

apply_ptune() {
  if [ "$POLICY_EXPERIMENTAL" = yes ]; then
    cfg_set PTUNE_OVERRIDE_MENU off
    cfg_set ALLOW_THERMAL_WITH_PTUNE 0
    cfg_set RISK_ACK_PTUNE_THERMAL_COLLISION none
    cfg_set LAST_PTUNE_OVERRIDE 0
    cfg_set PTUNE_OVERRIDE_POLICY blocked_experimental_platform
    return 0
  fi
  cfg_set PTUNE_OVERRIDE_POLICY available_guarded
  case "$1" in
    1)
      cfg_set PTUNE_OVERRIDE_MENU on
      cfg_set ALLOW_THERMAL_WITH_PTUNE 1
      cfg_set RISK_ACK_PTUNE_THERMAL_COLLISION I_UNDERSTAND_BOOTLOOP_RISK
      cfg_set LAST_PTUNE_OVERRIDE 1
    ;;
    *)
      cfg_set PTUNE_OVERRIDE_MENU off
      cfg_set ALLOW_THERMAL_WITH_PTUNE 0
      cfg_set RISK_ACK_PTUNE_THERMAL_COLLISION none
      cfg_set LAST_PTUNE_OVERRIDE 0
    ;;
  esac
}

apply_debug() {
  case "$1" in
    0|silent)
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
}

apply_support_snapshot() {
  case "$1" in
    1|enabled|collect)
      cfg_set INSTALL_SUPPORT_SNAPSHOT 1
      cfg_set LAST_INSTALL_SUPPORT_SNAPSHOT enabled
    ;;
    *)
      cfg_set INSTALL_SUPPORT_SNAPSHOT 0
      cfg_set LAST_INSTALL_SUPPORT_SNAPSHOT disabled
    ;;
  esac
}

apply_zram() {
  case "$1" in
    0|disabled)
      cfg_set ENABLE_ZRAM_100P 0
      cfg_set ZRAM_EMERALD_OC 0
      cfg_set ZRAM_RESTART_MMD 0
      cfg_set ZRAM_RISK_ACK disabled_by_user
      cfg_set ZRAM_EH_RISK_ACK disabled_by_user
      cfg_set LAST_ZRAM_100P disabled
      cfg_set LMKD_SWAP_LOW_RELOAD 0
      cfg_set LMKD_SWAP_LOW_RISK_ACK none
      cfg_set LAST_LMKD_SWAP_LOW_RELOAD disabled
    ;;
    enabled_max_lock)
      cfg_set ENABLE_ZRAM_100P 1
      cfg_set ZRAM_EMERALD_OC 1
      cfg_set ZRAM_RESTART_MMD 1
      cfg_set ZRAM_RISK_ACK explicit_user_enable
      cfg_set ZRAM_EH_RISK_ACK explicit_user_enable_max_lock
      cfg_set LAST_ZRAM_100P enabled_max_lock
    ;;
    *)
      cfg_set ENABLE_ZRAM_100P 1
      cfg_set ZRAM_EMERALD_OC 0
      cfg_set ZRAM_RESTART_MMD 1
      cfg_set ZRAM_RISK_ACK explicit_user_enable
      cfg_set ZRAM_EH_RISK_ACK none
      cfg_set LAST_ZRAM_100P enabled_standard
    ;;
  esac
}

apply_lmkd_reload() {
  case "$1" in
    1|enabled)
      if [ "$(cfg_get ENABLE_ZRAM_100P)" != 1 ] || [ "$(cfg_get ZRAM_RISK_ACK)" != explicit_user_enable ]; then
        cfg_set LMKD_SWAP_LOW_RELOAD 0
        cfg_set LMKD_SWAP_LOW_RISK_ACK none
        cfg_set LAST_LMKD_SWAP_LOW_RELOAD disabled
        return 0
      fi
      cfg_set LMKD_SWAP_LOW_RELOAD 1
      cfg_set LMKD_SWAP_LOW_RISK_ACK explicit_user_reload
      cfg_set LAST_LMKD_SWAP_LOW_RELOAD enabled
    ;;
    *)
      cfg_set LMKD_SWAP_LOW_RELOAD 0
      cfg_set LMKD_SWAP_LOW_RISK_ACK none
      cfg_set LAST_LMKD_SWAP_LOW_RELOAD disabled
    ;;
  esac
}

record_ptune_presence() {
  _ptune_path="$(ptune_present 2>/dev/null || true)"
  if [ -n "$_ptune_path" ]; then
    cfg_set PTUNE_CONFLICT present
    cfg_set PTUNE_CONFLICT_PATH "$_ptune_path"
  else
    cfg_set PTUNE_CONFLICT none
    cfg_set PTUNE_CONFLICT_PATH none
  fi
}

mark_single_pass_complete() {
  cfg_set INSTALL_OPTIONS_MENU_VERSION single_pass_v2
  cfg_set INSTALL_MENU_PROCESS_COUNT 1
  cfg_set INSTALL_OPTIONS_CONFIRMED 1
}

zram_summary_label() {
  _z="$(cfg_get LAST_ZRAM_100P)"
  case "$_z" in
    disabled) printf '%s\n' 'disabled' ;;
    enabled_max_lock) printf '%s\n' 'enabled (EH max lock; more power/heat)' ;;
    *) printf '%s\n' 'enabled (adaptive; recommended)' ;;
  esac
}

print_summary() {
  mc_msg ""
  mc_msg "Install choices"
  mc_msg "Polling: $(cfg_get THERMAL_POLLING_MODE)"
  mc_msg "Thermal: $(profile_label "$(cfg_get THERMAL_OUTDOOR_PROFILE)")"
  mc_msg "Thermal max delta: $POLICY_MAX_DELTA"
  mc_msg "ZRAM: $(zram_summary_label)"
  if [ "$(cfg_get ENABLE_ZRAM_100P)" = 1 ]; then
    mc_msg "Memory Killer 1%: $(cfg_get LAST_LMKD_SWAP_LOW_RELOAD)"
  else
    mc_msg "Memory Killer: unavailable (ZRAM disabled)"
  fi
  mc_msg "pTune: $(cfg_get PTUNE_OVERRIDE_MENU)"
  mc_msg "pTune policy: $(cfg_get PTUNE_OVERRIDE_POLICY)"
  mc_msg "Debug: $(cfg_get LAST_DEBUG_MODE)"
  mc_msg "Support snapshot: $(cfg_get LAST_INSTALL_SUPPORT_SNAPSHOT)"
  mc_msg "Single menu process: yes"
  mc_msg "----------------------------------------"
}

apply_last_settings() {
  cfg_set THERMAL_SETTINGS_MODE last
  cfg_set USE_LAST_FALLBACK none
  record_ptune_presence

  _profile="$(cfg_get LAST_THERMAL_OUTDOOR_PROFILE)"
  [ -n "$_profile" ] || _profile="$(cfg_get THERMAL_OUTDOOR_PROFILE)"
  apply_profile "$_profile"

  _polling="$(cfg_get LAST_THERMAL_POLLING_MODE)"
  [ -n "$_polling" ] || _polling="$(cfg_get THERMAL_POLLING_MODE)"
  apply_polling "$_polling"

  _ptune="$(cfg_get LAST_PTUNE_OVERRIDE)"
  [ -n "$_ptune" ] || _ptune="$(cfg_get ALLOW_THERMAL_WITH_PTUNE)"
  apply_ptune "$_ptune"

  _debug="$(cfg_get LAST_DEBUG_MODE)"
  [ -n "$_debug" ] || _debug="$(cfg_get DEBUG_MODE)"
  apply_debug "$_debug"

  _snapshot="$(cfg_get LAST_INSTALL_SUPPORT_SNAPSHOT)"
  [ -n "$_snapshot" ] || _snapshot=disabled
  apply_support_snapshot "$_snapshot"

  _zram="$(cfg_get LAST_ZRAM_100P)"
  [ -n "$_zram" ] || _zram="$(cfg_get ENABLE_ZRAM_100P)"
  apply_zram "$_zram"

  if [ "$(cfg_get ENABLE_ZRAM_100P)" = 1 ] && [ "$(cfg_get ZRAM_RISK_ACK)" = explicit_user_enable ]; then
    _lmkd="$(cfg_get LAST_LMKD_SWAP_LOW_RELOAD)"
    [ -n "$_lmkd" ] || _lmkd=disabled
    apply_lmkd_reload "$_lmkd"
  else
    apply_lmkd_reload 0
  fi

  mark_single_pass_complete
  mc_msg ""
  mc_msg "Use last settings"
  print_summary
  exit 0
}

remember_index=1
has_remembered && remember_index=0
mc_cycle2 "Remember Settings" "Use last" "Fresh choices" "$remember_index"

if [ "$MC_INDEX" = 0 ] && has_remembered; then
  apply_last_settings
fi

if [ "$MC_INDEX" = 0 ]; then
  cfg_set USE_LAST_FALLBACK no_saved_settings
  mc_msg ""
  mc_msg "No saved settings"
  mc_msg "Opening fresh choices"
fi

cfg_set THERMAL_SETTINGS_MODE fresh
record_ptune_presence

polling_index=0
mc_cycle2 "Polling Mode" "Mod values" "Stock values" "$polling_index"
[ "$MC_INDEX" = 1 ] && apply_polling stock || apply_polling mod

safe_label="$(profile_policy_label 1 'Outdoor Safe')"
plus_label="$(profile_policy_label 2 'Outdoor Plus')"
ext_label="$(profile_policy_label 3 'Outdoor Ext')"
mc_cycle4 \
  "Thermal Profile max+$POLICY_MAX_DELTA" \
  "Stock" \
  "$safe_label" \
  "$plus_label" \
  "$ext_label" \
  0
apply_profile "$(profile_at "$MC_INDEX")"

zram_index=1
mc_cycle2 "ZRAM 100%" "Disabled" "Enabled" "$zram_index"
if [ "$MC_INDEX" = 0 ]; then
  apply_zram disabled
else
  oc_index=0
  mc_cycle2 "Emerald Hill mode" "Adaptive (daily default)" "EXPERIMENTAL max lock (heat/battery)" "$oc_index"
  if [ "$MC_INDEX" = 0 ]; then
    apply_zram enabled_standard
  else
    apply_zram enabled_max_lock
  fi

  lmkd_index=0
  mc_cycle2 "Memory Killer" "Stock" "EXPERIMENTAL 1%" "$lmkd_index"
  [ "$MC_INDEX" = 1 ] && apply_lmkd_reload 1 || apply_lmkd_reload 0
fi

if [ "$POLICY_EXPERIMENTAL" = yes ]; then
  apply_ptune 0
  mc_msg "pTune Override: unavailable on experimental vNext target"
else
  ptune_index=1
  mc_cycle2 "pTune Override" "Override ON" "Override OFF" "$ptune_index"
  [ "$MC_INDEX" = 0 ] && apply_ptune 1 || apply_ptune 0
fi

debug_index=1
mc_cycle2 "Debug Logging" "Silent" "Verbose" "$debug_index"
[ "$MC_INDEX" = 0 ] && apply_debug 0 || apply_debug 1

snapshot_index=0
mc_cycle2 "Support Snapshot (read-only)" "Skip" "Collect after install" "$snapshot_index"
[ "$MC_INDEX" = 1 ] && apply_support_snapshot 1 || apply_support_snapshot 0

mark_single_pass_complete
print_summary
exit 0
