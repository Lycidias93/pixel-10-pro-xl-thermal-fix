#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
policy="$repo_root/tools/core/outdoor-runtime-policy.sh"
evidence="$repo_root/tools/core/outdoor-runtime-evidence.tsv"

bash -n "$policy"
[[ -s "$evidence" ]]
# shellcheck disable=SC1090
. "$policy"

for device in mustang blazer frankel rango; do
  [[ "$(thermal_outdoor_max_delta "$device" 17 future-build)" = 3 ]]
  thermal_outdoor_profile_admitted outdoor-extended "$device" 17 future-build
done

[[ "$(thermal_outdoor_max_delta unknown 17 future)" = 0 ]]
[[ "$(thermal_outdoor_max_delta mustang 18 future)" = 0 ]]
if thermal_outdoor_profile_admitted outdoor-safe unknown 17 future; then
  printf '%s\n' 'FAIL unsupported_device_nonstock_admitted'
  exit 1
fi
if thermal_outdoor_profile_admitted outdoor-safe mustang 18 future; then
  printf '%s\n' 'FAIL unsupported_android_nonstock_admitted'
  exit 1
fi

[[ "$(thermal_outdoor_policy_evidence mustang 17 CP2A.260705.006)" = dev6_postboot_extended_12zones_84values_pass_2026-07-27 ]]
[[ "$(thermal_outdoor_policy_evidence mustang 17 ZP11.260618.005)" = allen_fix5_clean_flash_all_profiles_boot_2026-07-26 ]]
[[ "$(thermal_outdoor_policy_evidence blazer 17 CP2A.260705.006)" = harish_fix5_extended_13zones_91values_pass_2026-07-26 ]]
[[ "$(thermal_outdoor_policy_evidence frankel 17 future-build)" = supported_platform_local_stock_validation_required ]]
[[ "$(thermal_outdoor_policy_evidence unknown 17 future-build)" = unsupported_platform_stock_only ]]

grep -Fq $'mustang\t17\tCP2A.260705.006\t3\tdev6_postboot_extended_12zones_84values_pass_2026-07-27' "$evidence"
grep -Fq $'mustang\t17\tZP11.260618.005\t3\tallen_fix5_clean_flash_stock_safe_plus_extended_boot_2026-07-26' "$evidence"
grep -Fq $'blazer\t17\tCP2A.260705.006\t3\tharish_fix5_extended_13zones_91values_pass_2026-07-26' "$evidence"

printf '%s\n' 'PASS supported_pixel10_android17_profiles_admitted_to_local_validation'
printf '%s\n' 'PASS exact_build_ids_are_evidence_not_activation_gates'
printf '%s\n' 'PASS unsupported_platform_stock_only'
printf '%s\n' 'RESULT: PIXEL_THERMAL_OUTDOOR_RUNTIME_EVIDENCE_TEST_PASS'
