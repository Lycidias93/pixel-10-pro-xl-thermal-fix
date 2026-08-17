#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

grep -Fqx 'core_version=0.3.1' webui.lock
grep -Eq '^template_commit=[0-9a-f]{40}$' webui.lock
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
if grep -Eq 'ksu\.exec|apatch\.exec|magisk\.exec|webui\.exec|Android\.exec|eval\(|new Function' bin/module-control tools/webui/launch.sh tools/control/pixel-control.sh; then
  echo 'FAIL: unrestricted WebUI/root exec bridge found' >&2
  exit 1
fi
grep -Fq 'WEBUI_CORE_DIR' dev_tools/build-release-module.sh
grep -Fq 'webui-server-arm64' dev_tools/build-release-module.sh
printf '%s\n' 'RESULT: PIXEL_WEBUI_INTEGRATION_TEST_PASS'
