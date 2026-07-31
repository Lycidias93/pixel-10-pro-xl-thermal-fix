#!/system/bin/sh
set -eu

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-/data/adb/modules/$ID}"
CONFIG_FILE="${LMKD_CONFIG_FILE:-/data/adb/$ID/config.env}"
STATE_DIR="${LMKD_TEST_STATE_DIR:-/data/adb/$ID/lmkd-test}"
STATE_FILE="$STATE_DIR/early-swap-low.env"
EVENT_LOG="$STATE_DIR/events.log"
RESET="${LMKD_RESET_BIN:-$MODDIR/tools/resetprop-rs}"
GETPROP="${LMKD_GETPROP_BIN:-getprop}"
PIDOF="${LMKD_PIDOF_BIN:-pidof}"
BOOT_ID_FILE="${LMKD_BOOT_ID_FILE:-/proc/sys/kernel/random/boot_id}"
UPTIME_FILE="${LMKD_UPTIME_FILE:-/proc/uptime}"
MODE="${1:-apply}"

cfg_get() {
  key="$1"
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^${key}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${key}=//" | tr -d '\r'
}

prop_get() {
  "$GETPROP" "$1" 2>/dev/null || true
}

lmkd_pid() {
  "$PIDOF" lmkd 2>/dev/null | awk '{print $1}' || true
}

uptime_ms() {
  awk '{printf "%d\n", $1 * 1000}' "$UPTIME_FILE" 2>/dev/null || printf '%s\n' 0
}

write_state() {
  apply_state="$1"
  timing_state="$2"
  before="$3"
  after="$4"
  pid_before="$5"
  detail="$6"
  mkdir -p "$STATE_DIR" 2>/dev/null || true
  chmod 0700 "$STATE_DIR" 2>/dev/null || true
  tmp="$STATE_FILE.tmp.$$"
  {
    printf '%s\n' 'schema=pixel-thermal-lmkd-early-test-v1'
    printf '%s\n' "boot_id=$(cat "$BOOT_ID_FILE" 2>/dev/null || printf unknown)"
    printf '%s\n' "epoch=$(date +%s 2>/dev/null || printf unknown)"
    printf '%s\n' "uptime_ms=$(uptime_ms)"
    printf '%s\n' "mode=$MODE"
    printf '%s\n' "requested_property=ro.lmk.swap_free_low_percentage"
    printf '%s\n' 'requested_value=1'
    printf '%s\n' "config_enabled=${enabled:-0}"
    printf '%s\n' "risk_ack=${ack:-none}"
    printf '%s\n' "zram_enabled=${zram_enabled:-0}"
    printf '%s\n' "property_before=${before:-unset}"
    printf '%s\n' "property_after=${after:-unset}"
    printf '%s\n' "lmkd_pid_before=${pid_before:-none}"
    printf '%s\n' "apply_state=$apply_state"
    printf '%s\n' "timing_state=$timing_state"
    printf '%s\n' 'consumption_proof=not_claimed'
    printf '%s\n' "detail=$detail"
  } > "$tmp"
  chmod 0600 "$tmp" 2>/dev/null || true
  mv "$tmp" "$STATE_FILE"
  printf '%s\n' "epoch=$(date +%s 2>/dev/null || printf unknown) boot_id=$(cat "$BOOT_ID_FILE" 2>/dev/null || printf unknown) apply_state=$apply_state timing_state=$timing_state property_before=${before:-unset} property_after=${after:-unset} lmkd_pid_before=${pid_before:-none} detail=$detail" >> "$EVENT_LOG" 2>/dev/null || true
  chmod 0600 "$EVENT_LOG" 2>/dev/null || true
  if [ -r "$EVENT_LOG" ] && [ "$(wc -l < "$EVENT_LOG" 2>/dev/null | tr -d ' ')" -gt 64 ] 2>/dev/null; then
    tail -n 64 "$EVENT_LOG" > "$EVENT_LOG.tmp.$$" 2>/dev/null || true
    chmod 0600 "$EVENT_LOG.tmp.$$" 2>/dev/null || true
    mv "$EVENT_LOG.tmp.$$" "$EVENT_LOG" 2>/dev/null || true
  fi
}

enabled="$(cfg_get LMKD_EARLY_SWAP_LOW_TEST)"
ack="$(cfg_get LMKD_EARLY_SWAP_LOW_RISK_ACK)"
zram_enabled="$(cfg_get ENABLE_ZRAM_100P)"
[ -n "$enabled" ] || enabled=0
[ -n "$ack" ] || ack=none
[ -n "$zram_enabled" ] || zram_enabled=0
before="$(prop_get ro.lmk.swap_free_low_percentage)"
pid_before="$(lmkd_pid)"

if [ "$enabled" != 1 ]; then
  write_state disabled stock_default "$before" "$before" "$pid_before" config_disabled
  printf '%s\n' 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_SKIPPED reason=disabled'
  exit 0
fi

if [ "$ack" != explicit_user_test ]; then
  write_state refused missing_ack "$before" "$before" "$pid_before" explicit_ack_required
  printf '%s\n' 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_REFUSED reason=explicit_ack_required'
  exit 0
fi

if [ "$zram_enabled" != 1 ]; then
  write_state refused zram_disabled "$before" "$before" "$pid_before" zram_100p_required
  printf '%s\n' 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_REFUSED reason=zram_100p_required'
  exit 0
fi

if [ -n "$pid_before" ]; then
  write_state late_refused lmkd_already_running "$before" "$before" "$pid_before" late_mutation_not_allowed
  printf '%s\n' "RESULT: LMKD_EARLY_SWAP_LOW_TEST_REFUSED reason=lmkd_already_running pid=$pid_before"
  exit 0
fi

if [ ! -x "$RESET" ]; then
  write_state failed before_lmkd "$before" "$before" none resetprop_missing
  printf '%s\n' "RESULT: LMKD_EARLY_SWAP_LOW_TEST_FAIL reason=resetprop_missing path=$RESET"
  exit 2
fi

if ! "$RESET" -n ro.lmk.swap_free_low_percentage 1; then
  after="$(prop_get ro.lmk.swap_free_low_percentage)"
  write_state failed before_lmkd "$before" "$after" none resetprop_failed
  printf '%s\n' 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_FAIL reason=resetprop_failed'
  exit 3
fi

after="$(prop_get ro.lmk.swap_free_low_percentage)"
if [ "$after" != 1 ]; then
  write_state failed before_lmkd "$before" "$after" none readback_mismatch
  printf '%s\n' "RESULT: LMKD_EARLY_SWAP_LOW_TEST_FAIL reason=readback_mismatch actual=${after:-unset}"
  exit 4
fi

write_state applied_before_lmkd before_lmkd "$before" "$after" none indirect_timing_only
printf '%s\n' 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_APPLY_PASS timing=before_lmkd readback=1 evidence=indirect_timing_only'
exit 0
