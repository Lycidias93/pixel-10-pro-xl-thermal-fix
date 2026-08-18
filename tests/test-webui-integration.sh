#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

grep -Fqx 'core_version=0.6.0' webui.lock
grep -Fqx 'template_commit=cb991dc8d7d982defbe5e34c5c0e0908efa9b236' webui.lock
grep -Fq 'Drizzy07x/Supercharger_Pixel_9_Series@be76cbe57d01fa475196b7afb3729b9ad19f0a26' webui.lock
for file in bin/module-control tools/webui/launch.sh tools/control/pixel-control.sh tools/zram/page-cluster-control.sh common/repo.json; do test -s "$file"; done
for device in mustang blazer frankel rango stallion tokay caiman komodo comet tegu; do grep -Fq "\"$device\"" supported_versions.json; done
for label in 'Pixel 10a' 'Pixel 9a' 'Pixel 10 Pro XL' 'Pixel 9 Pro Fold'; do grep -Fq "\"$label\"" common/repo.json; done
grep -Fq 'WEBUI_LAUNCHER="$MODDIR/tools/webui/launch.sh"' action.sh
grep -Fq 'opening legacy Action menu' action.sh
grep -Fq '"page-cluster-zero"' bin/module-control
grep -Fq 'confirmation_text":"PAGECLUSTER"' bin/module-control
grep -Fq 'dynamic_stock_thermal_validation' bin/module-control
grep -Fq 'ZRAM_MATERIALIZE_NOW=0' tools/control/pixel-control.sh

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

# The package must carry the complete pinned WebUI 0.6 asset surface.
for asset in observability.js observability.css v04.js; do
  grep -Fq "$asset" dev_tools/build-release-module.sh
  grep -Fq "webroot/$asset" dev_tools/verify-release-module.sh
  grep -Fq "webroot/$asset" dev_tools/validate-package.py
done
grep -Fq 'WEBUI_CORE_DIR' dev_tools/build-release-module.sh
grep -Fq 'webui-server-arm64' dev_tools/build-release-module.sh
printf '%s\n' 'RESULT: PIXEL_WEBUI_INTEGRATION_TEST_PASS'
