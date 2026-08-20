#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

grep -Fqx 'core_version=0.6.1' webui.lock
grep -Fqx 'template_commit=6fbd1b018a45fe5b1bebba7aeb9142423eab47fb' webui.lock
grep -Fq 'Drizzy07x/Supercharger_Pixel_9_Series@be76cbe57d01fa475196b7afb3729b9ad19f0a26' webui.lock
grep -Fq 'adivenxnataly/KsuWebUI@20342d280a841f8b317603a7eefb1193a95ab626' webui.lock
for file in bin/module-control tools/webui/launch.sh tools/control/pixel-control.sh tools/zram/page-cluster-control.sh common/repo.json; do test -s "$file"; done
for device in mustang blazer frankel rango stallion tokay caiman komodo comet tegu; do grep -Fq "\"$device\"" supported_versions.json; done
for label in 'Pixel 10a' 'Pixel 9a' 'Pixel 10 Pro XL' 'Pixel 9 Pro Fold'; do grep -Fq "\"$label\"" common/repo.json; done
grep -Fq 'WEBUI_LAUNCHER="$MODDIR/tools/webui/launch.sh"' action.sh
grep -Fq 'opening legacy Action menu' action.sh
grep -Fq '"page-cluster-zero"' bin/module-control
grep -Fq 'confirmation_text":"PAGECLUSTER"' bin/module-control
grep -Fq 'dynamic_stock_thermal_validation' bin/module-control
grep -Fq 'ZRAM_MATERIALIZE_NOW=0' tools/control/pixel-control.sh

# The launcher must tolerate the short fork->exec window before the native
# server becomes identifiable through /proc/$pid/cmdline. Identity remains a
# hard post-ready check and the ready file must belong to the spawned PID.
grep -Fq 'pid_alive "$SERVER_PID" || break' tools/webui/launch.sh
if grep -Fq 'is_our_pid "$SERVER_PID" || break' tools/webui/launch.sh; then
  echo 'FAIL: WebUI launcher still has pre-ready cmdline race' >&2
  exit 1
fi
grep -Fq 'is_our_pid "$SERVER_PID" || fail server_identity_mismatch' tools/webui/launch.sh
grep -Fq '[ "$READY_PID" = "$SERVER_PID" ] || fail server_pid_mismatch' tools/webui/launch.sh

# KsuWebUI is a bootstrap transport only. The Pixel launcher returns the same
# one-time loopback URL without opening another app; all privileged operations
# still go through the standalone typed HTTP API after the WebView redirects.
grep -Fq 'open|--verify|--print-url' tools/webui/launch.sh
grep -Fq 'WEBUI_BOOTSTRAP_URL=' tools/webui/launch.sh
grep -Fq 'bootstrap_transport=embedded_host_redirect' tools/webui/launch.sh
grep -Fq 'RESULT: PIXEL_WEBUI_URL_DONE' tools/webui/launch.sh

# Root-module managers may normalize ZIP modes during staging. The consumer
# must re-assert the executable bits required by the pinned WebUI template.
grep -Fq 'set_perm "$WEBUI_SERVER" 0 0 0755' customize.sh
grep -Fq 'set_perm "$WEBUI_CONTROL" 0 0 0755' customize.sh
grep -Fq '[ -x "$WEBUI_SERVER" ] || thermal_abort "! WebUI server executable permission failed"' customize.sh
grep -Fq '[ -x "$WEBUI_CONTROL" ] || thermal_abort "! WebUI module-control executable permission failed"' customize.sh

# Status is cache-first and exposes machine-readable active/blocked state for
# the shared core instead of forcing the browser to infer configuration.
grep -Fq 'ensure_status_cache() {' bin/module-control
status_body="$(sed -n '/^print_status() {/,/^}/p' bin/module-control)"
printf '%s\n' "$status_body" | grep -Fq 'ensure_status_cache'
printf '%s\n' "$status_body" | grep -Fq '"action_state":{"active"'
printf '%s\n' "$status_body" | grep -Fq 'add_active thermal-outdoor-extended'
printf '%s\n' "$status_body" | grep -Fq 'add_active zram-enable'
printf '%s\n' "$status_body" | grep -Fq "add_blocked lmkd-1pct 'Enable module ZRAM 100% first.'"
if printf '%s\n' "$status_body" | grep -Fxq '  refresh_status'; then
  echo 'FAIL: WebUI status GET performs unconditional full refresh' >&2
  exit 1
fi

# Inventory tab switching must be a cheap view operation. Deep validation is
# owned by boot/service/action flows, not by each browser button click.
inventory_body="$(sed -n '/^print_inventory() {/,/^}/p' bin/module-control)"
printf '%s\n' "$inventory_body" | grep -Fq 'ensure_status_cache'
if printf '%s\n' "$inventory_body" | grep -Fq '      refresh_status'; then
  echo 'FAIL: WebUI inventory button reruns full validation' >&2
  exit 1
fi
grep -Fq 'Latest verified validation evidence' bin/module-control

action_body="$(sed -n '/^run_action_file() {/,/^}/p' bin/module-control)"
printf '%s\n' "$action_body" | grep -Fq 'refresh_status'
if grep -Eq 'ksu\.exec|apatch\.exec|magisk\.exec|webui\.exec|Android\.exec|eval\(|new Function' bin/module-control tools/webui/launch.sh tools/control/pixel-control.sh; then
  echo 'FAIL: unrestricted WebUI/root exec bridge found' >&2
  exit 1
fi

# The package must carry the complete pinned WebUI 0.6.1 asset surface.
for asset in embedded-host-bootstrap.js observability.js observability.css v04.js; do
  grep -Fq "$asset" dev_tools/build-release-module.sh
  grep -Fq "webroot/$asset" dev_tools/verify-release-module.sh
  grep -Fq "webroot/$asset" dev_tools/validate-package.py
done
grep -Fq 'WEBUI_CORE_DIR' dev_tools/build-release-module.sh
grep -Fq 'webui-server-arm64' dev_tools/build-release-module.sh
printf '%s\n' 'RESULT: PIXEL_WEBUI_INTEGRATION_TEST_PASS'
