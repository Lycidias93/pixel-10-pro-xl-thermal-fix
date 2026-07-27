#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
policy="$repo_root/tools/core/outdoor-runtime-policy.sh"
evidence="$repo_root/tools/core/outdoor-runtime-evidence.tsv"

bash -n "$policy"
[[ -s "$evidence" ]]
# shellcheck disable=SC1090
. "$policy"

[[ "$(thermal_outdoor_max_delta mustang 17 CP2A.260705.006)" = 3 ]]
[[ "$(thermal_outdoor_max_delta mustang 17 ZP11.260618.005)" = 3 ]]
[[ "$(thermal_outdoor_max_delta unknown 17 future)" = 0 ]]
thermal_outdoor_profile_admitted outdoor-extended mustang 17 CP2A.260705.006
thermal_outdoor_profile_admitted outdoor-extended mustang 17 ZP11.260618.005
if thermal_outdoor_profile_admitted outdoor-safe unknown 17 future; then
  printf '%s\n' 'FAIL unknown_tuple_nonstock_admitted'
  exit 1
fi

grep -Fq $'mustang\t17\tCP2A.260705.006\t3\tdev6_postboot_extended_12zones_84values_pass_2026-07-27' "$evidence"
grep -Fq $'mustang\t17\tZP11.260618.005\t3\tallen_fix5_clean_flash_stock_safe_plus_extended_boot_2026-07-26' "$evidence"
grep -Fq 'dev6_postboot_extended_12zones_84values_pass_2026-07-27' "$policy"
grep -Fq 'allen_fix5_clean_flash_all_profiles_boot_2026-07-26' "$policy"

printf '%s\n' 'PASS stable_dev6_extended_runtime_evidence'
printf '%s\n' 'PASS canary_fix5_all_profiles_runtime_evidence'
printf '%s\n' 'PASS unknown_tuple_stock_only'
printf '%s\n' 'RESULT: PIXEL_THERMAL_OUTDOOR_RUNTIME_EVIDENCE_TEST_PASS'
