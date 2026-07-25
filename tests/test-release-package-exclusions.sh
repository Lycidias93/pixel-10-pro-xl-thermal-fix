#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$(mktemp --suffix=.zip)"
trap 'rm -f "$out"' EXIT HUP INT TERM

"$repo_root/dev_tools/build-release-module.sh" "$out" >/tmp/pixel-thermal-package-test.log
"$repo_root/dev_tools/verify-release-module.sh" "$out"

grep -q 'RESULT: PIXEL_THERMAL_LEAN_PACKAGE_BUILD_PASS' /tmp/pixel-thermal-package-test.log

printf '%s\n' 'PASS release_builder_and_verifier_contract'
printf '%s\n' 'RESULT: PIXEL_THERMAL_RELEASE_PACKAGE_EXCLUSION_TEST_PASS'
