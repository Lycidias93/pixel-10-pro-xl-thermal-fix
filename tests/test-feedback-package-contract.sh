#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

test -s tools/zram/fstab.zram.100p
test ! -e system/vendor/etc/fstab.zram.100p
grep -Fq "grep -Fxq 'system/vendor/etc/fstab.zram.100p'" dev_tools/verify-release-module.sh
grep -Fq "package_generated_zram_fstab" dev_tools/validate-package.py
grep -Fq 'PAGE_CLUSTER_CALLER=service_post_boot' service.sh
grep -Fq 'post_bootguard_reapply' tools/zram/page-cluster-control.sh
grep -Fq 'debug-silent' bin/module-control
grep -Fq 'debug-verbose' bin/module-control
grep -Fq 'DEBUG_MODE 0' tools/control/pixel-control.sh
grep -Fq 'DEBUG_MODE 1' tools/control/pixel-control.sh
grep -Fq 'template_commit=dc95d5821fdea323efaf8c4ddc459a0644f8e66d' webui.lock
grep -Fq 'mobile-input-viewport.js' dev_tools/build-release-module.sh
grep -Fq 'cubs:17|grizzly:17|kodiak:17|yogi:17' action.sh
grep -Fq 'cubs:17|grizzly:17|kodiak:17|yogi:17' customize.sh
printf '%s\n' 'RESULT: PIXEL11_FEEDBACK_PACKAGE_CONTRACT_PASS'
