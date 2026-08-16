#!/system/bin/sh
set -eu

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
BINDIR=${0%/*}
MODDIR="${MODDIR:-${BINDIR%/tools/control}}"
CONFIG_DIR="${THERMAL_CONFIG_DIR:-/data/adb/$ID}"
CONFIG_FILE="${PIXEL_CONFIG_FILE:-$CONFIG_DIR/config.env}"
LOCKDIR="${PIXEL_CONTROL_LOCKDIR:-$CONFIG_DIR/webui-control.lock}"
POLICY_HELPER="$MODDIR/tools/core/outdoor-runtime-policy.sh"
THERMAL_MATERIALIZER="$MODDIR/tools/core/patch-thermal-validated.sh"
ZRAM_LAYOUT="$MODDIR/tools/zram/materialize-zram-choice.sh"
ZRAM_APPLY="$MODDIR/tools/zram/apply-zram-100p.sh"
EH_CONTROL="$MODDIR/tools/zram/emerald-hill-control.sh"
PAGE_CLUSTER="$MODDIR/tools/zram/page-cluster-control.sh"
STATUS_LIB="$MODDIR/tools/debug/status-lib.sh"

[ -r "$POLICY_HELPER" ] && . "$POLICY_HELPER"

cfg_get() {
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^$1=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^$1=//" | tr -d '\r'
}

cfg_set() {
  key="$1"; value="$2"
  mkdir -p "$CONFIG_DIR" 2>/dev/null || true
  touch "$CONFIG_FILE" 2>/dev/null || true
  tmp="$CONFIG_FILE.tmp.$$"
  grep -v "^${key}=" "$CONFIG_FILE" 2>/dev/null > "$tmp" || true
  printf '%s=%s\n' "$key" "$value" >> "$tmp"
  chmod 0600 "$tmp" 2>/dev/null || true
  mv "$tmp" "$CONFIG_FILE"
}

acquire_lock() {
  attempts=0
  while ! mkdir "$LOCKDIR" 2>/dev/null; do
    owner="$(cat "$LOCKDIR/pid" 2>/dev/null || true)"
    case "$owner" in ''|*[!0-9]*) ;; *) kill -0 "$owner" 2>/dev/null && return 1 ;; esac
    rm -rf "$LOCKDIR" 2>/dev/null || true
    attempts=$((attempts + 1))
    [ "$attempts" -lt 2 ] || return 1
  done
  printf '%s\n' "$$" > "$LOCKDIR/pid" 2>/dev/null || true
  trap 'rm -rf "$LOCKDIR" 2>/dev/null || true' EXIT HUP INT TERM
}

release_lock() {
  rm -rf "$LOCKDIR" 2>/dev/null || true
  trap - EXIT HUP INT TERM
}

mark_reboot() {
  mkdir -p "$MODDIR/guard" 2>/dev/null || true
  printf '%s\n' yes > "$MODDIR/guard/action_cycle_pending_reboot" 2>/dev/null || true
}

refresh_status() {
  [ -r "$STATUS_LIB" ] && MODDIR="$MODDIR" sh "$STATUS_LIB" update >/dev/null 2>&1 || true
}

device="${THERMAL_DEVICE:-$(getprop ro.product.device 2>/dev/null || true)}"
android="${THERMAL_ANDROID:-$(getprop ro.build.version.release 2>/dev/null || true)}"
build_id="${THERMAL_BUILD_ID:-$(getprop ro.build.id 2>/dev/null || true)}"
[ -n "$device" ] || device=unknown
[ -n "$android" ] || android=unknown
[ -n "$build_id" ] || build_id=unknown

policy_max_delta() {
  if command -v thermal_outdoor_max_delta >/dev/null 2>&1; then
    thermal_outdoor_max_delta "$device" "$android" "$build_id" 2>/dev/null || printf '%s\n' 0
  else
    printf '%s\n' 0
  fi
}

profile_admitted() {
  profile="$1"
  [ "$(cfg_get THERMAL_DISABLED)" != 1 ] || return 1
  command -v thermal_outdoor_profile_admitted >/dev/null 2>&1 || return 1
  thermal_outdoor_profile_admitted "$profile" "$device" "$android" "$build_id"
}

apply_thermal() {
  polling="$1"; profile="$2"
  case "$polling" in mod|stock) ;; *) return 64 ;; esac
  case "$profile" in stock|outdoor-safe|outdoor-plus|outdoor-extended) ;; *) return 64 ;; esac
  profile_admitted "$profile" || {
    printf 'RESULT: PIXEL_CONTROL_BLOCKED reason=thermal_profile_not_admitted profile=%s build=%s\n' "$profile" "$build_id"
    return 2
  }
  [ -s "$THERMAL_MATERIALIZER" ] || {
    printf '%s\n' 'RESULT: PIXEL_CONTROL_FAIL reason=thermal_materializer_missing'
    return 3
  }
  if ! MODDIR="$MODDIR" sh "$THERMAL_MATERIALIZER" "$polling" "$profile" "$MODDIR"; then
    printf '%s\n' 'RESULT: PIXEL_CONTROL_FAIL reason=thermal_validation_failed'
    return 4
  fi
  cfg_set THERMAL_POLLING_MODE "$polling"
  cfg_set THERMAL_POLLING_EFFECTIVE "$polling"
  cfg_set LAST_THERMAL_POLLING_MODE "$polling"
  cfg_set THERMAL_SETTINGS_MODE webui_settings
  case "$profile" in
    outdoor-safe) ack=explicit_user_enable; target=outdoor_safe ;;
    outdoor-plus) ack=explicit_user_enable; target=outdoor_plus ;;
    outdoor-extended) ack=explicit_user_enable_extended; target=outdoor_extended ;;
    *) ack=disabled_or_stock_selected; target=stock ;;
  esac
  cfg_set THERMAL_OUTDOOR_PROFILE "$profile"
  cfg_set THERMAL_OUTDOOR_TARGET "$target"
  cfg_set THERMAL_OUTDOOR_RISK_ACK "$ack"
  cfg_set THERMAL_OUTDOOR_PROFILE_SOURCE webui_validated_transaction_v1
  cfg_set THERMAL_OUTDOOR_MAX_ADMITTED_DELTA "$(policy_max_delta)"
  if command -v thermal_outdoor_policy_evidence >/dev/null 2>&1; then
    cfg_set THERMAL_OUTDOOR_POLICY_EVIDENCE "$(thermal_outdoor_policy_evidence "$device" "$android" "$build_id")"
  fi
  cfg_set LAST_THERMAL_OUTDOOR_PROFILE "$profile"
  printf '%s\n' dynamic > "$MODDIR/guard/selected_profile" 2>/dev/null || true
  mark_reboot
  refresh_status
  printf 'RESULT: PIXEL_CONTROL_THERMAL_PASS polling=%s profile=%s reboot_required=yes\n' "$polling" "$profile"
}

zram_enable() {
  [ -s "$ZRAM_LAYOUT" ] || return 3
  MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" ZRAM_MATERIALIZE_NOW=0 sh "$ZRAM_LAYOUT" enable >/dev/null 2>&1 || true
  cfg_set ENABLE_ZRAM_100P 1
  cfg_set ZRAM_RESTART_MMD 1
  cfg_set ZRAM_RISK_ACK explicit_user_enable
  cfg_set ZRAM_EMERALD_OC 0
  cfg_set ZRAM_EH_RISK_ACK none
  cfg_set LAST_ZRAM_100P enabled_standard
  cfg_set LMKD_SWAP_LOW_RELOAD 0
  cfg_set LMKD_SWAP_LOW_RISK_ACK none
  cfg_set LAST_LMKD_SWAP_LOW_RELOAD disabled
  if [ -s "$EH_CONTROL" ]; then
    MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" ZRAM_EH_CALLER=webui_zram_enable sh "$EH_CONTROL" restore >/dev/null 2>&1 || true
  fi
  runtime=skipped
  if [ -s "$ZRAM_APPLY" ]; then
    if MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$ZRAM_APPLY" manual >/dev/null 2>&1; then runtime=pass; else runtime=deferred_to_reboot; fi
  fi
  mark_reboot
  refresh_status
  printf 'RESULT: PIXEL_CONTROL_ZRAM_ENABLE_PASS runtime_apply=%s reboot_required=yes lmkd=stock eh=adaptive\n' "$runtime"
}

zram_disable() {
  [ -s "$ZRAM_LAYOUT" ] && MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" ZRAM_MATERIALIZE_NOW=0 sh "$ZRAM_LAYOUT" disable >/dev/null 2>&1 || true
  [ -s "$EH_CONTROL" ] && MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" ZRAM_EH_CALLER=webui_zram_disable sh "$EH_CONTROL" restore >/dev/null 2>&1 || true
  [ -s "$PAGE_CLUSTER" ] && ZRAM_CONFIG_FILE="$CONFIG_FILE" PAGE_CLUSTER_CALLER=webui_zram_disable sh "$PAGE_CLUSTER" restore >/dev/null 2>&1 || true
  cfg_set ENABLE_ZRAM_100P 0
  cfg_set ZRAM_EMERALD_OC 0
  cfg_set ZRAM_RESTART_MMD 0
  cfg_set ZRAM_RISK_ACK disabled_by_user
  cfg_set ZRAM_EH_RISK_ACK disabled_by_user
  cfg_set LAST_ZRAM_100P disabled
  cfg_set LMKD_SWAP_LOW_RELOAD 0
  cfg_set LMKD_SWAP_LOW_RISK_ACK none
  cfg_set LAST_LMKD_SWAP_LOW_RELOAD disabled
  mark_reboot
  refresh_status
  printf '%s\n' 'RESULT: PIXEL_CONTROL_ZRAM_DISABLE_PASS reboot_required=yes lmkd=stock eh=adaptive'
}

eh_adaptive() {
  [ "$(cfg_get ENABLE_ZRAM_100P)" = 1 ] || return 2
  cfg_set ZRAM_EMERALD_OC 0
  cfg_set ZRAM_EH_RISK_ACK none
  cfg_set LAST_ZRAM_100P enabled_standard
  [ -s "$EH_CONTROL" ] && MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" ZRAM_EH_CALLER=webui_adaptive sh "$EH_CONTROL" restore >/dev/null 2>&1 || true
  mark_reboot
  refresh_status
  printf '%s\n' 'RESULT: PIXEL_CONTROL_EH_ADAPTIVE_PASS'
}

eh_max() {
  [ "$(cfg_get ENABLE_ZRAM_100P)" = 1 ] && [ "$(cfg_get ZRAM_RISK_ACK)" = explicit_user_enable ] || {
    printf '%s\n' 'RESULT: PIXEL_CONTROL_BLOCKED reason=zram_required_for_eh_max'
    return 2
  }
  cfg_set ZRAM_EMERALD_OC 1
  cfg_set ZRAM_EH_RISK_ACK explicit_user_enable_max_lock
  cfg_set LAST_ZRAM_100P enabled_max_lock
  runtime=failed
  if [ -s "$EH_CONTROL" ] && MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" ZRAM_EH_CALLER=webui_experimental_max sh "$EH_CONTROL" apply >/dev/null 2>&1; then runtime=pass; fi
  mark_reboot
  refresh_status
  printf 'RESULT: PIXEL_CONTROL_EH_MAX_CONFIGURED runtime_apply=%s reboot_required=yes\n' "$runtime"
}

lmkd_stock() {
  cfg_set LMKD_SWAP_LOW_RELOAD 0
  cfg_set LMKD_SWAP_LOW_RISK_ACK none
  cfg_set LAST_LMKD_SWAP_LOW_RELOAD disabled
  runtime=skipped
  if [ -s "$ZRAM_APPLY" ]; then
    if MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$ZRAM_APPLY" lmkd_restore >/dev/null 2>&1; then runtime=pass; else runtime=best_effort; fi
  fi
  refresh_status
  printf 'RESULT: PIXEL_CONTROL_LMKD_STOCK_PASS runtime_restore=%s\n' "$runtime"
}

lmkd_one_percent() {
  [ "$(cfg_get ENABLE_ZRAM_100P)" = 1 ] && [ "$(cfg_get ZRAM_RISK_ACK)" = explicit_user_enable ] || {
    printf '%s\n' 'RESULT: PIXEL_CONTROL_BLOCKED reason=zram_required_for_lmkd'
    return 2
  }
  cfg_set LMKD_SWAP_LOW_RELOAD 1
  cfg_set LMKD_SWAP_LOW_RISK_ACK explicit_user_reload
  cfg_set LAST_LMKD_SWAP_LOW_RELOAD enabled
  runtime=failed
  if [ -s "$ZRAM_APPLY" ] && MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$ZRAM_APPLY" manual >/dev/null 2>&1; then runtime=pass; fi
  refresh_status
  printf 'RESULT: PIXEL_CONTROL_LMKD_1PCT_CONFIGURED runtime_apply=%s\n' "$runtime"
}

page_cluster_zero() {
  [ -s "$PAGE_CLUSTER" ] || return 3
  PAGE_CLUSTER_CALLER=webui ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$PAGE_CLUSTER" apply-zero
}

page_cluster_stock() {
  [ -s "$PAGE_CLUSTER" ] || return 3
  PAGE_CLUSTER_CALLER=webui ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$PAGE_CLUSTER" restore
}

command="${1:-}"
current_polling() {
  value="$(cfg_get THERMAL_POLLING_MODE)"
  [ -n "$value" ] || value=mod
  printf '%s\n' "$value"
}

current_thermal_profile() {
  value="$(cfg_get THERMAL_OUTDOOR_PROFILE)"
  [ -n "$value" ] || value=stock
  printf '%s\n' "$value"
}

case "$command" in
  polling-mod|polling-stock|thermal-stock|thermal-outdoor-safe|thermal-outdoor-plus|thermal-outdoor-extended|zram-enable|zram-disable|eh-adaptive|eh-max|lmkd-stock|lmkd-1pct|page-cluster-stock|page-cluster-zero) ;;
  *) printf '%s\n' 'usage: pixel-control.sh <declared-command>' >&2; exit 64 ;;
esac

acquire_lock || {
  printf '%s\n' 'RESULT: PIXEL_CONTROL_BLOCKED reason=another_control_operation_running'
  exit 75
}

case "$command" in
  polling-mod) apply_thermal mod "$(current_thermal_profile)" ;;
  polling-stock) apply_thermal stock "$(current_thermal_profile)" ;;
  thermal-stock) apply_thermal "$(current_polling)" stock ;;
  thermal-outdoor-safe) apply_thermal "$(current_polling)" outdoor-safe ;;
  thermal-outdoor-plus) apply_thermal "$(current_polling)" outdoor-plus ;;
  thermal-outdoor-extended) apply_thermal "$(current_polling)" outdoor-extended ;;
  zram-enable) zram_enable ;;
  zram-disable) zram_disable ;;
  eh-adaptive) eh_adaptive ;;
  eh-max) eh_max ;;
  lmkd-stock) lmkd_stock ;;
  lmkd-1pct) lmkd_one_percent ;;
  page-cluster-stock) page_cluster_stock ;;
  page-cluster-zero) page_cluster_zero ;;
esac
release_lock
