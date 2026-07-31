#!/usr/bin/env bash
set -euo pipefail

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
early="$root/tools/lmkd/early-swap-low-test.sh"
verify="$root/tools/lmkd/verify-early-swap-low-test.sh"
post_fs="$root/post-fs-data.sh"
service="$root/service.sh"
action="$root/tools/action-dashboard.sh"
install_menu="$root/tools/menu/install-options-menu.sh"
module_prop="$root/module.prop"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/mod/tools" "$tmp/state" "$tmp/bin"
printf '%s\n' test-boot-id > "$tmp/boot_id"
printf '%s\n' '12.34 56.78' > "$tmp/uptime"
printf '%s\n' \
  'MemTotal:       16000000 kB' \
  'MemAvailable:    8000000 kB' \
  'SwapTotal:      16000000 kB' \
  'SwapFree:       12000000 kB' > "$tmp/meminfo"
printf '%s\n' \
  'some avg10=0.10 avg60=0.20 avg300=0.30 total=10' \
  'full avg10=0.00 avg60=0.00 avg300=0.00 total=0' > "$tmp/psi"
: > "$tmp/property"
: > "$tmp/pid"

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'key="${1:-}"' \
  'case "$key" in' \
  '  ro.lmk.swap_free_low_percentage) cat "$LMKD_TEST_PROPERTY_FILE" ;;' \
  '  init.svc.lmkd) printf "%s\\n" running ;;' \
  '  *) printf "%s\\n" "" ;;' \
  'esac' > "$tmp/bin/getprop"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'cat "$LMKD_TEST_PID_FILE"' > "$tmp/bin/pidof"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'test "$1" = -n' \
  'test "$2" = ro.lmk.swap_free_low_percentage' \
  'test "$3" = 1' \
  'printf "%s\\n" 1 > "$LMKD_TEST_PROPERTY_FILE"' > "$tmp/mod/tools/resetprop-rs"
chmod +x "$tmp/bin/getprop" "$tmp/bin/pidof" "$tmp/mod/tools/resetprop-rs"

run_early() {
  MODDIR="$tmp/mod" \
  LMKD_CONFIG_FILE="$tmp/config.env" \
  LMKD_TEST_STATE_DIR="$tmp/state" \
  LMKD_GETPROP_BIN="$tmp/bin/getprop" \
  LMKD_PIDOF_BIN="$tmp/bin/pidof" \
  LMKD_BOOT_ID_FILE="$tmp/boot_id" \
  LMKD_UPTIME_FILE="$tmp/uptime" \
  LMKD_TEST_PROPERTY_FILE="$tmp/property" \
  LMKD_TEST_PID_FILE="$tmp/pid" \
  sh "$early" apply
}

run_verify() {
  LMKD_CONFIG_FILE="$tmp/config.env" \
  LMKD_TEST_STATE_DIR="$tmp/state" \
  LMKD_GETPROP_BIN="$tmp/bin/getprop" \
  LMKD_PIDOF_BIN="$tmp/bin/pidof" \
  LMKD_BOOT_ID_FILE="$tmp/boot_id" \
  LMKD_MEMINFO_FILE="$tmp/meminfo" \
  LMKD_PSI_FILE="$tmp/psi" \
  LMKD_TEST_PROPERTY_FILE="$tmp/property" \
  LMKD_TEST_PID_FILE="$tmp/pid" \
  sh "$verify"
}

bash -n "$early"
bash -n "$verify"
bash -n "$post_fs"
bash -n "$service"
bash -n "$action"
bash -n "$install_menu"

printf '%s\n' \
  'ENABLE_ZRAM_100P=1' \
  'LMKD_EARLY_SWAP_LOW_TEST=0' \
  'LMKD_EARLY_SWAP_LOW_RISK_ACK=none' > "$tmp/config.env"
run_early > "$tmp/disabled.log"
grep -Fq 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_SKIPPED reason=disabled' "$tmp/disabled.log"
grep -Fxq 'apply_state=disabled' "$tmp/state/early-swap-low.env"
[[ ! -s "$tmp/property" ]]

printf '%s\n' \
  'ENABLE_ZRAM_100P=1' \
  'LMKD_EARLY_SWAP_LOW_TEST=1' \
  'LMKD_EARLY_SWAP_LOW_RISK_ACK=explicit_user_test' > "$tmp/config.env"
run_early > "$tmp/apply.log"
grep -Fq 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_APPLY_PASS timing=before_lmkd readback=1 evidence=indirect_timing_only' "$tmp/apply.log"
grep -Fxq 'apply_state=applied_before_lmkd' "$tmp/state/early-swap-low.env"
grep -Fxq 'timing_state=before_lmkd' "$tmp/state/early-swap-low.env"
grep -Fxq 'property_after=1' "$tmp/state/early-swap-low.env"
grep -Fxq 'consumption_proof=not_claimed' "$tmp/state/early-swap-low.env"

printf '%s\n' 4321 > "$tmp/pid"
run_verify > "$tmp/verify.log"
grep -Fq 'RESULT: LMKD_EARLY_SWAP_LOW_POSTBOOT_VERIFY_DONE outcome=success evidence=indirect_timing_only' "$tmp/verify.log"
grep -Fxq 'test_ready=yes' "$tmp/state/postboot.env"
grep -Fxq 'direct_lmkd_consumption_claim=no' "$tmp/state/postboot.env"
grep -Fxq 'consumption_proof=indirect_timing_only' "$tmp/state/postboot.env"

: > "$tmp/property"
printf '%s\n' 777 > "$tmp/pid"
run_early > "$tmp/late.log"
grep -Fq 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_REFUSED reason=lmkd_already_running pid=777' "$tmp/late.log"
grep -Fxq 'apply_state=late_refused' "$tmp/state/early-swap-low.env"
[[ ! -s "$tmp/property" ]]

: > "$tmp/pid"
printf '%s\n' \
  'ENABLE_ZRAM_100P=1' \
  'LMKD_EARLY_SWAP_LOW_TEST=1' \
  'LMKD_EARLY_SWAP_LOW_RISK_ACK=none' > "$tmp/config.env"
run_early > "$tmp/noack.log"
grep -Fq 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_REFUSED reason=explicit_ack_required' "$tmp/noack.log"

printf '%s\n' \
  'ENABLE_ZRAM_100P=0' \
  'LMKD_EARLY_SWAP_LOW_TEST=1' \
  'LMKD_EARLY_SWAP_LOW_RISK_ACK=explicit_user_test' > "$tmp/config.env"
run_early > "$tmp/nozram.log"
grep -Fq 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_REFUSED reason=zram_100p_required' "$tmp/nozram.log"

grep -Fq 'LMKD_EARLY="$MODDIR/tools/lmkd/early-swap-low-test.sh"' "$post_fs"
grep -Fq 'late_mutation_not_allowed' "$early"
if grep -Fq 'resetprop-rs -n ro.lmk.swap_free_low_percentage' "$service" "$root/tools/zram/apply-zram-100p.sh"; then
  printf '%s\n' 'FAIL late_lmkd_write_present'
  exit 1
fi
grep -Fq 'LMKD early test' "$action"
grep -Fq 'LMKD Evidence' "$action"
grep -Fq 'EXPERIMENTAL 1%' "$install_menu"
grep -Fq 'version=2.0.0-alpha.3-dev.19' "$module_prop"
grep -Fq 'versionCode=1016230' "$module_prop"

printf '%s\n' 'PASS dev19_default_disabled'
printf '%s\n' 'PASS dev19_before_lmkd_apply_and_readback'
printf '%s\n' 'PASS dev19_postboot_indirect_evidence_boundary'
printf '%s\n' 'PASS dev19_late_write_refused'
printf '%s\n' 'PASS dev19_ack_and_zram_fail_closed'
printf '%s\n' 'PASS dev19_installer_action_status_wiring'
printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV19_LMKD_TEST_PASS'
