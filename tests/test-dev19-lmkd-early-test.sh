#!/usr/bin/env bash
set -euo pipefail
root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
apply="$root/tools/zram/apply-zram-100p.sh"
post_fs="$root/post-fs-data.sh"
service="$root/service.sh"
action="$root/tools/action-dashboard.sh"
menu="$root/tools/menu/install-options-menu.sh"
status="$root/tools/debug/status-lib.sh"
module_prop="$root/module.prop"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/mod/tools/zram" "$tmp/mod/tools" "$tmp/state" "$tmp/bin"
printf '%s\n' test-boot > "$tmp/boot_id"
printf '%s\n' '12.00 34.00' > "$tmp/uptime"
printf '%s\n' 1 > "$tmp/property"
printf '%s\n' running > "$tmp/service"
printf '%s\n' 100 > "$tmp/pid"
: > "$tmp/reinit"
: > "$tmp/reinit_fail"
: > "$tmp/system_resetprop_fail"
printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' 'case "${1:-}" in' '  ro.lmk.swap_free_low_percentage) cat "$PROP_FILE" ;;' '  init.svc.lmkd) cat "$SERVICE_FILE" ;;' '  lmkd.reinit) cat "$REINIT_FILE" ;;' '  *) printf "\\n" ;;' 'esac' > "$tmp/bin/getprop"
printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' 'key="${1:-}"; value="${2:-}"' 'case "$key" in' '  lmkd.reinit) if [ -s "$REINIT_FAIL_FILE" ]; then exit 1; fi; printf "%s\\n" "$value" > "$REINIT_FILE"; : > "$REINIT_FILE" ;;' '  ctl.restart) printf "%s\\n" 200 > "$PID_FILE"; printf "%s\\n" running > "$SERVICE_FILE" ;;' 'esac' > "$tmp/bin/setprop"
printf '%s\n' '#!/usr/bin/env bash' 'cat "$PID_FILE"' > "$tmp/bin/pidof"
printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' '[ -s "$SYSTEM_RESETPROP_FAIL_FILE" ] && exit 1' 'printf "%s\n" "$2" > "$PROP_FILE"' > "$tmp/bin/resetprop"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$tmp/bin/stop"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$tmp/bin/start"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$tmp/bin/sleep"
printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' 'case "$1" in' '  -n) printf "%s\\n" "$3" > "$PROP_FILE" ;;' '  -d) : > "$PROP_FILE" ;;' '  *) exit 2 ;;' 'esac' > "$tmp/mod/tools/resetprop-rs"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$tmp/mod/tools/zram/config-normalize.sh"
chmod +x "$tmp/bin/"* "$tmp/mod/tools/resetprop-rs" "$tmp/mod/tools/zram/config-normalize.sh"

run_apply() {
  MODDIR="$tmp/mod" ZRAM_CONFIG_FILE="$tmp/config.env" \
  LMKD_GETPROP_BIN="$tmp/bin/getprop" LMKD_SETPROP_BIN="$tmp/bin/setprop" \
  LMKD_PIDOF_BIN="$tmp/bin/pidof" LMKD_STOP_BIN="$tmp/bin/stop" LMKD_START_BIN="$tmp/bin/start" LMKD_SLEEP_BIN="$tmp/bin/sleep" \
  LMKD_BOOT_ID_FILE="$tmp/boot_id" LMKD_UPTIME_FILE="$tmp/uptime" LMKD_SYSTEM_RESETPROP_BIN="$tmp/bin/resetprop" \
  PROP_FILE="$tmp/property" SERVICE_FILE="$tmp/service" REINIT_FILE="$tmp/reinit" REINIT_FAIL_FILE="$tmp/reinit_fail" SYSTEM_RESETPROP_FAIL_FILE="$tmp/system_resetprop_fail" PID_FILE="$tmp/pid" \
  sh "$apply" "$1"
}

bash -n "$apply"; bash -n "$post_fs"; bash -n "$service"; bash -n "$action"; bash -n "$menu"; bash -n "$status"
printf '%s\n' 'ENABLE_ZRAM_100P=1' 'ZRAM_RISK_ACK=explicit_user_enable' 'LMKD_SWAP_LOW_RELOAD=1' 'LMKD_SWAP_LOW_RISK_ACK=explicit_user_reload' 'ZRAM_RESTART_MMD=0' > "$tmp/config.env"
printf '%s\n' 10 > "$tmp/property"
run_apply manual > "$tmp/apply.log"
grep -Fq 'LMKD_RELOAD result=success method=aosp_reinit' "$tmp/apply.log"
grep -Fxq 'reload_result=success' "$tmp/lmkd-reload.env"
grep -Fxq 'reload_method=aosp_reinit' "$tmp/lmkd-reload.env"
grep -Fxq 'property_after=1' "$tmp/lmkd-reload.env"
grep -Fxq 'property_writer=magisk_resetprop' "$tmp/lmkd-reload.env"
grep -Fxq 'LMKD_SWAP_LOW_ORIGINAL_VALUE=100p' "$tmp/config.env"
grep -Fq 'if "$SETPROP_BIN" lmkd.reinit 1 2>/dev/null && wait_reinit_ack; then' "$apply"

printf '%s\n' fail > "$tmp/reinit_fail"
printf '%s\n' fail > "$tmp/system_resetprop_fail"
printf '%s\n' 100 > "$tmp/pid"
printf '%s\n' 10 > "$tmp/property"
run_apply manual > "$tmp/fallback.log"
grep -Fq 'LMKD_RELOAD reinit=failed_or_unacknowledged fallback=ctl_restart' "$tmp/fallback.log"
grep -Fq 'LMKD_RELOAD result=success method=ctl_restart' "$tmp/fallback.log"
grep -Fxq 'reload_method=ctl_restart' "$tmp/lmkd-reload.env"
grep -Fxq 'lmkd_pid_before=100' "$tmp/lmkd-reload.env"
grep -Fxq 'lmkd_pid_after=200' "$tmp/lmkd-reload.env"
grep -Fxq 'property_writer=resetprop_rs_fallback' "$tmp/lmkd-reload.env"
: > "$tmp/reinit_fail"

printf '%s\n' 'ENABLE_ZRAM_100P=1' 'ZRAM_RISK_ACK=explicit_user_enable' 'LMKD_SWAP_LOW_RELOAD=0' 'LMKD_SWAP_LOW_RISK_ACK=none' 'LMKD_SWAP_LOW_ORIGINAL_VALUE=100p' 'ZRAM_RESTART_MMD=0' > "$tmp/config.env"
run_apply lmkd_restore > "$tmp/restore.log"
grep -Fxq 100p "$tmp/property"
grep -Fq 'RESULT: ZRAM_APPLY_DONE mode=lmkd_restore' "$tmp/restore.log"

! grep -Fq 'tools/lmkd/' "$post_fs"
! grep -Fq 'tools/lmkd/' "$service"
grep -Fq 'update_manager_badges' "$service"
grep -Fq 'dynamic_description_readback_missing' "$service"
grep -Fq 'LMKD 1% reload' "$action"
grep -Fq 'Memory Killer Evidence' "$action"
grep -Fq 'mc_cycle2 "Memory Killer" "Stock" "EXPERIMENTAL 1%"' "$menu"
grep -Fq 'LMKD_SWAP_LOW_RELOAD' "$status"
grep -Fq 'version=2.1.0-alpha.4-dev.2' "$module_prop"
grep -Fq 'versionCode=1016254' "$module_prop"
[[ ! -e "$root/tools/lmkd/early-swap-low-test.sh" ]]
[[ ! -e "$root/tools/lmkd/verify-early-swap-low-test.sh" ]]

printf '%s\n' 'PASS lmkd_consolidated_in_zram_script'
printf '%s\n' 'PASS aosp_reinit_trigger_must_succeed'
printf '%s\n' 'PASS failed_reinit_uses_verified_restart_fallback'
printf '%s\n' 'PASS runtime_restore_path'
printf '%s\n' 'PASS legacy_helpers_removed'
printf '%s\n' 'PASS manager_status_retry_readback'
printf '%s\n' 'PASS magisk_resetprop_first_with_readback_fallback'
printf '%s\n' 'PASS alpha4_dev_memory_killer_ux_contract'
printf '%s\n' 'RESULT: PIXEL_THERMAL_ALPHA4_DEV_LMKD_RELOAD_PASS'
