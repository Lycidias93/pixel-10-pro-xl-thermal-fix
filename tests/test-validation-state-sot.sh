#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

grep -q 'THERMAL_VALIDATION_DIR=.*validation' tools/core/validation-state.sh
grep -q 'legacy_paths=symlinks_only' tools/core/validation-state.sh
grep -q 'thermal_validation_refresh_legacy_links' tools/core/patch-thermal-validated.sh
grep -q 'PATCH_THERMAL_LEGACY_PATHS=symlinks_only' tools/core/patch-thermal-validated.sh

if grep -q 'cp -fp "\$DELTA_REPORT" "\$DELTA_REPORT_DATA"' tools/core/patch-thermal-validated.sh; then
  printf '%s\n' 'FAIL duplicate_delta_report_copy_still_present'
  exit 1
fi
if grep -q 'cp -fp "\$REPORT_MODULE" "\$REPORT_DATA"' tools/core/patch-thermal-validated.sh; then
  printf '%s\n' 'FAIL duplicate_validation_report_copy_still_present_in_wrapper'
  exit 1
fi

printf '%s\n' 'PASS canonical_validation_directory_declared'
printf '%s\n' 'PASS legacy_validation_paths_are_symlinks_only'
printf '%s\n' 'RESULT: PIXEL_THERMAL_VALIDATION_STATE_SOT_TEST_PASS'
