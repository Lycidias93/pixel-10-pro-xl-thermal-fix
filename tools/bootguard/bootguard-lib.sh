#!/system/bin/sh
# Bootguard v3: evaluate the previous attempt early, arm the finalized current
# overlay late, and clear pending state only after verified runtime health.
set -eu

MODDIR="${MODDIR:-${0%/*}/../..}"
CONFIG_FILE="${CONFIG_FILE:-/data/adb/pixel-10-pro-xl-thermal-fix/config.env}"
G="${GUARD_DIR:-$MODDIR/guard}"
P="$G/pending_boot"
C="$G/fail_count"
L="$G/bootguard.log"
LG="$G/last_good.env"
LA="$G/last_attempt.env"
TRANSITION="$G/platform-transition.env"
COMPAT_HELPER="${BOOTGUARD_COMPAT_HELPER:-$MODDIR/tools/bootguard/compat-check.sh}"
TRANSITION_HELPER="${BOOTGUARD_TRANSITION_HELPER:-$MODDIR/tools/core/platform-transition.sh}"
mkdir -p "$G"

now() { date -Is 2>/dev/null || date; }
log() { printf '%s %s\n' "$(now)" "$*" >> "$L"; }

getcfg() {
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^$1=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^$1=//" | tr -d '\r'
}

kv_get() {
  [ -r "$2" ] || return 0
  grep -E "^$1=" "$2" 2>/dev/null | tail -n 1 | sed "s/^$1=//" | tr -d '\r'
}

counter_get() {
  value=0
  [ -r "$C" ] && value="$(cat "$C" 2>/dev/null || printf '%s\n' 0)"
  case "$value" in ''|*[!0-9]*) value=0 ;; esac
  printf '%s\n' "$value"
}

counter_set() {
  printf '%s\n' "$1" > "$C"
  chmod 0600 "$C" 2>/dev/null || true
}

threshold_minimum() {
  minimum=2
  canary="$(getcfg CANARY_DIAGNOSTIC_MODE)"
  [ "$canary" = 1 ] && minimum=1
  printf '%s\n' "$minimum"
}

threshold() {
  minimum="$(threshold_minimum)"
  value="$(getcfg BOOTGUARD_FAIL_THRESHOLD)"
  case "$value" in ''|*[!0-9]*) value="$minimum" ;; esac
  [ "$value" -ge "$minimum" ] 2>/dev/null || value="$minimum"
  [ "$value" -le 5 ] 2>/dev/null || value=5
  printf '%s\n' "$value"
}

pending_transition() {
  value="$(kv_get transition_pending "$P")"
  [ "$value" = yes ] && printf '%s\n' yes || printf '%s\n' no
}

effective_pending_threshold() {
  if [ "$(pending_transition)" = yes ]; then
    printf '%s\n' 1
  else
    threshold
  fi
}

build_id() {
  value="${THERMAL_BUILD_ID:-$(getprop ro.build.id 2>/dev/null || true)}"
  [ -n "$value" ] || value=unknown
  printf '%s\n' "$value"
}

android_version() {
  value="${THERMAL_ANDROID:-$(getprop ro.build.version.release 2>/dev/null || true)}"
  [ -n "$value" ] || value=unknown
  printf '%s\n' "$value"
}

device_name() {
  value="${THERMAL_DEVICE:-$(getprop ro.product.device 2>/dev/null || true)}"
  [ -n "$value" ] || value=unknown
  printf '%s\n' "$value"
}

module_version() {
  grep -E '^version=' "$MODDIR/module.prop" 2>/dev/null | head -n 1 | sed 's/^version=//' || true
}

module_version_code() {
  grep -E '^versionCode=' "$MODDIR/module.prop" 2>/dev/null | head -n 1 | sed 's/^versionCode=//' || true
}

sha_file() {
  [ -s "$1" ] || return 0
  sha256sum "$1" 2>/dev/null | awk '{print $1}'
}

snapshot() {
  transition_pending="$(kv_get transition_pending "$TRANSITION")"
  transition_phase="$(kv_get phase "$TRANSITION")"
  transition_reason="$(kv_get reason "$TRANSITION")"
  [ -n "$transition_pending" ] || transition_pending=no
  [ -n "$transition_phase" ] || transition_phase=none
  [ -n "$transition_reason" ] || transition_reason=none

  printf '%s\n' 'schema=pixel-thermal-bootguard-v3'
  printf '%s\n' "timestamp=$(now)"
  printf '%s\n' "device=$(device_name)"
  printf '%s\n' "android=$(android_version)"
  printf '%s\n' "build_id=$(build_id)"
  printf '%s\n' "module_version=$(module_version)"
  printf '%s\n' "module_version_code=$(module_version_code)"
  printf '%s\n' "transition_pending=$transition_pending"
  printf '%s\n' "transition_phase=$transition_phase"
  printf '%s\n' "transition_reason=$transition_reason"
  printf '%s\n' "polling_mode=$(getcfg THERMAL_POLLING_MODE)"
  printf '%s\n' "outdoor_profile=$(getcfg THERMAL_OUTDOOR_PROFILE)"
  printf '%s\n' "thermal_disabled=$(getcfg THERMAL_DISABLED)"
  printf '%s\n' "patch_manifest_sha256=$(sha_file "$G/patch-manifest.tsv")"
  printf '%s\n' "validation_report_sha256=$(sha_file "$MODDIR/validation_report.json")"
  printf '%s\n' "overlay_base_sha256=$(sha_file "$MODDIR/system/vendor/etc/thermal_info_config.json")"
  printf '%s\n' "overlay_charge_sha256=$(sha_file "$MODDIR/system/vendor/etc/thermal_info_config_charge.json")"
  printf '%s\n' "overlay_throttling_sha256=$(sha_file "$MODDIR/system/vendor/etc/thermal_info_config_throttling.json")"
}

evaluate() {
  [ -e "$MODDIR/remove" ] && { log 'BOOTGUARD_EVALUATE_SKIP reason=remove_present'; return 0; }
  [ -e "$MODDIR/disable" ] && { log 'BOOTGUARD_EVALUATE_SKIP reason=disable_present'; return 0; }

  if [ -e "$P" ]; then
    count="$(counter_get)"
    count=$((count + 1))
    counter_set "$count"
    limit="$(effective_pending_threshold)"
    transition="$(pending_transition)"
    cp -fp "$P" "$G/previous_failed_attempt.env" 2>/dev/null || true
    log "BOOTGUARD_PREVIOUS_PENDING fail_count=$count threshold=$limit transition_pending=$transition"
    if [ "$count" -ge "$limit" ]; then
      printf '%s\n' "automatic_bootguard_fail_count_${count}" > "$G/disabled_reason"
      touch "$MODDIR/disable" "$MODDIR/skip_mount"
      rm -f "$P"
      log "BOOTGUARD_DISABLE fail_count=$count threshold=$limit transition_pending=$transition action=disable_and_skip_mount"
      return 10
    fi
    rm -f "$P"
  else
    counter_set 0
    log 'BOOTGUARD_EVALUATE_PASS previous_pending=absent'
  fi
  return 0
}

arm() {
  [ -e "$MODDIR/remove" ] && { log 'BOOTGUARD_ARM_SKIP reason=remove_present'; return 0; }
  [ -e "$MODDIR/disable" ] && { log 'BOOTGUARD_ARM_SKIP reason=disable_present'; return 0; }
  [ -e "$MODDIR/skip_mount" ] && { log 'BOOTGUARD_ARM_SKIP reason=skip_mount_present'; return 0; }
  snapshot > "$LA"
  chmod 0600 "$LA" 2>/dev/null || true
  cp -fp "$LA" "$P"
  chmod 0600 "$P" 2>/dev/null || true
  log "BOOTGUARD_ARM build=$(build_id) transition_pending=$(kv_get transition_pending "$P")"
}

success() {
  snapshot > "$LG"
  chmod 0600 "$LG" 2>/dev/null || true
  rm -f "$P"
  counter_set 0
  rm -f "$G/disabled_reason"
  log "BOOTGUARD_SUCCESS build=$(build_id)"
}

thermalservice_check() {
  if [ "${BOOTGUARD_SKIP_THERMAL_SERVICE_CHECK:-0}" = 1 ]; then
    return 0
  fi
  dumpsys thermalservice >/dev/null 2>&1
}

success_verify() {
  boot_completed="${BOOTGUARD_BOOT_COMPLETED:-$(getprop sys.boot_completed 2>/dev/null || true)}"
  if [ "$boot_completed" != 1 ]; then
    printf '%s\n' 'BOOTGUARD_SUCCESS_VERIFY=deferred'
    printf '%s\n' 'BOOTGUARD_SUCCESS_VERIFY_REASON=boot_not_completed'
    log 'BOOTGUARD_SUCCESS_VERIFY_DEFER reason=boot_not_completed'
    return 20
  fi

  verify="$G/bootguard-success-compat.env"
  if [ ! -r "$COMPAT_HELPER" ] || ! sh "$COMPAT_HELPER" > "$verify" 2>/dev/null; then
    printf '%s\n' 'BOOTGUARD_SUCCESS_VERIFY=deferred'
    printf '%s\n' 'BOOTGUARD_SUCCESS_VERIFY_REASON=compat_check_failed'
    log 'BOOTGUARD_SUCCESS_VERIFY_DEFER reason=compat_check_failed'
    return 21
  fi

  safe="$(kv_get SAFE_TO_REBOOT "$verify")"
  expected="$(kv_get THERMAL_EXPECTED "$verify")"
  reason="$(kv_get REASON "$verify")"
  if [ "$safe" != yes ]; then
    printf '%s\n' 'BOOTGUARD_SUCCESS_VERIFY=deferred'
    printf '%s\n' "BOOTGUARD_SUCCESS_VERIFY_REASON=compat_unsafe_${reason:-unknown}"
    log "BOOTGUARD_SUCCESS_VERIFY_DEFER reason=compat_unsafe_${reason:-unknown}"
    return 22
  fi
  if [ "$expected" = thermal_active_allowed ] &&
     [ "$reason" != active_dynamic_overlay_verified ]; then
    printf '%s\n' 'BOOTGUARD_SUCCESS_VERIFY=deferred'
    printf '%s\n' "BOOTGUARD_SUCCESS_VERIFY_REASON=active_overlay_not_verified_${reason:-unknown}"
    log "BOOTGUARD_SUCCESS_VERIFY_DEFER reason=active_overlay_not_verified_${reason:-unknown}"
    return 23
  fi

  thermalservice_check || {
    printf '%s\n' 'BOOTGUARD_SUCCESS_VERIFY=deferred'
    printf '%s\n' 'BOOTGUARD_SUCCESS_VERIFY_REASON=thermalservice_unresponsive_first_probe'
    log 'BOOTGUARD_SUCCESS_VERIFY_DEFER reason=thermalservice_unresponsive_first_probe'
    return 24
  }
  sleep "${BOOTGUARD_SECOND_PROBE_DELAY_SECONDS:-5}"
  thermalservice_check || {
    printf '%s\n' 'BOOTGUARD_SUCCESS_VERIFY=deferred'
    printf '%s\n' 'BOOTGUARD_SUCCESS_VERIFY_REASON=thermalservice_unresponsive_second_probe'
    log 'BOOTGUARD_SUCCESS_VERIFY_DEFER reason=thermalservice_unresponsive_second_probe'
    return 25
  }

  success
  if [ -r "$TRANSITION_HELPER" ]; then
    MODDIR="$MODDIR" CONFIG_FILE="$CONFIG_FILE" sh "$TRANSITION_HELPER" complete >> "$L" 2>&1 || true
  fi
  printf '%s\n' 'BOOTGUARD_SUCCESS_VERIFY=pass'
  printf '%s\n' "BOOTGUARD_SUCCESS_VERIFY_REASON=${reason:-verified}"
  log "BOOTGUARD_SUCCESS_VERIFY_PASS reason=${reason:-verified}"
}

status() {
  printf '%s\n' 'Bootguard v3 Status'
  printf '%s\n' "pending_boot=$([ -e "$P" ] && printf present || printf absent)"
  printf '%s\n' "pending_transition=$(pending_transition)"
  printf '%s\n' "fail_count=$(counter_get)"
  printf '%s\n' "threshold=$(threshold)"
  printf '%s\n' "threshold_minimum=$(threshold_minimum)"
  printf '%s\n' "effective_pending_threshold=$(effective_pending_threshold)"
  printf '%s\n' "disable=$([ -e "$MODDIR/disable" ] && printf present || printf absent)"
  printf '%s\n' "skip_mount=$([ -e "$MODDIR/skip_mount" ] && printf present || printf absent)"
  printf '%s\n' "disabled_reason=$([ -r "$G/disabled_reason" ] && cat "$G/disabled_reason" || printf none)"
  printf '%s\n' "last_success_at=$([ -r "$LG" ] && kv_get timestamp "$LG" || printf none)"
  printf '%s\n' "last_good=$([ -r "$LG" ] && printf present || printf absent)"
  printf '%s\n' "transition_phase=$([ -r "$TRANSITION" ] && kv_get phase "$TRANSITION" || printf absent)"
}

case "${1:-status}" in
  evaluate) evaluate ;;
  arm) arm ;;
  preflight) evaluate && arm ;;
  success) success ;;
  success-verify) success_verify ;;
  status) status ;;
  reset) rm -f "$P" "$C" "$G/previous_failed_attempt.env"; log 'BOOTGUARD_RESET';;
  *) printf '%s\n' "BOOTGUARD_ERROR=unknown_command_${1:-empty}"; exit 2 ;;
esac
