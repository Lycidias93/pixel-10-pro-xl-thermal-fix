#!/system/bin/sh
set -eu

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
CONFIG_FILE="${LMKD_CONFIG_FILE:-/data/adb/$ID/config.env}"
STATE_DIR="${LMKD_TEST_STATE_DIR:-/data/adb/$ID/lmkd-test}"
EARLY="$STATE_DIR/early-swap-low.env"
POST="$STATE_DIR/postboot.env"
GETPROP="${LMKD_GETPROP_BIN:-getprop}"
PIDOF="${LMKD_PIDOF_BIN:-pidof}"
BOOT_ID_FILE="${LMKD_BOOT_ID_FILE:-/proc/sys/kernel/random/boot_id}"
MEMINFO_FILE="${LMKD_MEMINFO_FILE:-/proc/meminfo}"
PSI_FILE="${LMKD_PSI_FILE:-/proc/pressure/memory}"

kv_get() {
  key="$1"
  file="$2"
  [ -r "$file" ] || return 0
  grep -E "^${key}=" "$file" 2>/dev/null | tail -n 1 | sed "s/^${key}=//" | tr -d '\r'
}

cfg_get() {
  kv_get "$1" "$CONFIG_FILE"
}

prop_get() {
  "$GETPROP" "$1" 2>/dev/null || true
}

pid_now() {
  "$PIDOF" lmkd 2>/dev/null | awk '{print $1}' || true
}

mem_kb() {
  awk -v key="$1" '$1 == key":" {print $2; exit}' "$MEMINFO_FILE" 2>/dev/null || true
}

enabled="$(cfg_get LMKD_EARLY_SWAP_LOW_TEST)"
ack="$(cfg_get LMKD_EARLY_SWAP_LOW_RISK_ACK)"
[ -n "$enabled" ] || enabled=0
[ -n "$ack" ] || ack=none
mkdir -p "$STATE_DIR" 2>/dev/null || true
chmod 0700 "$STATE_DIR" 2>/dev/null || true

current_boot="$(cat "$BOOT_ID_FILE" 2>/dev/null || printf unknown)"
early_boot="$(kv_get boot_id "$EARLY")"
apply_state="$(kv_get apply_state "$EARLY")"
timing_state="$(kv_get timing_state "$EARLY")"
early_after="$(kv_get property_after "$EARLY")"
current_prop="$(prop_get ro.lmk.swap_free_low_percentage)"
lmkd_pid="$(pid_now)"
lmkd_service="$(prop_get init.svc.lmkd)"
[ -n "$lmkd_service" ] || lmkd_service=unknown

ready=no
reason=disabled
if [ "$enabled" = 1 ] && [ "$ack" = explicit_user_test ]; then
  reason=evidence_incomplete
  if [ "$apply_state" = applied_before_lmkd ] &&
     [ "$timing_state" = before_lmkd ] &&
     [ "$early_after" = 1 ] &&
     [ "$current_prop" = 1 ] &&
     [ "$early_boot" = "$current_boot" ] &&
     [ -n "$lmkd_pid" ]; then
    ready=yes
    reason=early_timing_and_postboot_readback_verified
  fi
fi

psi_some="$(grep '^some ' "$PSI_FILE" 2>/dev/null | head -n 1 || true)"
psi_full="$(grep '^full ' "$PSI_FILE" 2>/dev/null | head -n 1 || true)"
tmp="$POST.tmp.$$"
{
  printf '%s\n' 'schema=pixel-thermal-lmkd-postboot-test-v1'
  printf '%s\n' "boot_id=$current_boot"
  printf '%s\n' "early_boot_id=${early_boot:-missing}"
  printf '%s\n' "boot_id_match=$([ "$early_boot" = "$current_boot" ] && printf yes || printf no)"
  printf '%s\n' "config_enabled=$enabled"
  printf '%s\n' "risk_ack=$ack"
  printf '%s\n' "early_apply_state=${apply_state:-missing}"
  printf '%s\n' "early_timing_state=${timing_state:-missing}"
  printf '%s\n' "early_property_after=${early_after:-unset}"
  printf '%s\n' "current_property=${current_prop:-unset}"
  printf '%s\n' "lmkd_pid=${lmkd_pid:-none}"
  printf '%s\n' "lmkd_service=$lmkd_service"
  printf '%s\n' "mem_total_kb=$(mem_kb MemTotal)"
  printf '%s\n' "mem_available_kb=$(mem_kb MemAvailable)"
  printf '%s\n' "swap_total_kb=$(mem_kb SwapTotal)"
  printf '%s\n' "swap_free_kb=$(mem_kb SwapFree)"
  printf '%s\n' "psi_some=${psi_some:-unavailable}"
  printf '%s\n' "psi_full=${psi_full:-unavailable}"
  printf '%s\n' "test_ready=$ready"
  printf '%s\n' "reason=$reason"
  printf '%s\n' 'consumption_proof=indirect_timing_only'
  printf '%s\n' 'direct_lmkd_consumption_claim=no'
} > "$tmp"
chmod 0600 "$tmp" 2>/dev/null || true
mv "$tmp" "$POST"

if [ "$enabled" != 1 ]; then
  printf '%s\n' 'RESULT: LMKD_EARLY_SWAP_LOW_POSTBOOT_VERIFY_DONE outcome=success state=disabled'
  exit 0
fi
if [ "$ready" = yes ]; then
  printf '%s\n' 'RESULT: LMKD_EARLY_SWAP_LOW_POSTBOOT_VERIFY_DONE outcome=success evidence=indirect_timing_only'
  exit 0
fi
printf '%s\n' "RESULT: LMKD_EARLY_SWAP_LOW_POSTBOOT_VERIFY_DONE outcome=warning reason=$reason evidence=indirect_timing_only"
exit 1
