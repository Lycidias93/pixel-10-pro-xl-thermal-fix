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
printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' 'case "${1:-}" in' '  ro.lmk.swap_free_low_percentage) cat "$PROP_FILE" ;;' '  init.svc.lmkd) cat "$SERVICE_FILE" ;;' '  lmkd.reinit) cat "$REINIT_FILE" ;;' '  *) printf "\\n" ;;' 'esac' > "$tmp/bin/getprop"
printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' 'key="${1:-}"; value="${2:-}"' 'case "$key" in' '  lmkd.reinit) printf "%s\\n" "$value" > "$REINIT_FILE"; : > "$REINIT_FILE" ;;' '  ctl.restart) printf "%s\\n" 200 > "$PID_FILE"; printf "%s\\n" running > "$SERVICE_FILE" ;;' 'esac' > "$tmp/bin/setprop"
printf '%s\n' '#!/usr/bin/env bash' 'cat "$PID_FILE"' > "$tmp/bin/pidof"
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
  LMKD_BOOT_ID_FILE="$tmp/boot_id" LMKD_UPTIME_FILE="$tmp/uptime" \
  PROP_FILE="$tmp/property" SERVICE_FILE="$tmp/service" REINIT_FILE="$tmp/reinit" PID_FILE="$tmp/pid" \
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
grep -Fxq 'LMKD_SWAP_LOW_ORIGINAL_VALUE=100p' "$tmp/config.env"

printf '%s\n' 'ENABLE_ZRAM_100P=1' 'ZRAM_RISK_ACK=explicit_user_enable' 'LMKD_SWAP_LOW_RELOAD=0' 'LMKD_SWAP_LOW_RISK_ACK=none' 'LMKD_SWAP_LOW_ORIGINAL_VALUE=100p' 'ZRAM_RESTART_MMD=0' > "$tmp/config.env"
run_apply lmkd_restore > "$tmp/restore.log"
grep -Fxq 100p "$tmp/property"
grep -Fq 'RESULT: ZRAM_APPLY_DONE mode=lmkd_restore' "$tmp/restore.log"

! grep -Fq 'tools/lmkd/' "$post_fs"
! grep -Fq 'tools/lmkd/' "$service"
grep -Fq 'update_manager_badges' "$service"
grep -Fq 'dynamic_description_readback_missing' "$service"
grep -Fq 'LMKD 1% reload' "$action"
grep -Fq 'LMKD Reload Evidence' "$action"
grep -Fq 'LMKD 1% reload' "$menu"
grep -Fq 'LMKD_SWAP_LOW_RELOAD' "$status"
grep -Fq 'version=2.0.0-alpha.3-dev.20' "$module_prop"
grep -Fq 'versionCode=1016231' "$module_prop"
[[ ! -e "$root/tools/lmkd/early-swap-low-test.sh" ]]
[[ ! -e "$root/tools/lmkd/verify-early-swap-low-test.sh" ]]

printf '%s\n' 'PASS dev20_lmkd_consolidated_in_zram_script'
printf '%s\n' 'PASS dev20_aosp_reinit_first_with_restart_fallback'
printf '%s\n' 'PASS dev20_runtime_restore_path'
printf '%s\n' 'PASS dev20_legacy_helpers_removed'
printf '%s\n' 'PASS dev20_manager_badge_retry_readback'
printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV20_LMKD_RELOAD_PASS'
