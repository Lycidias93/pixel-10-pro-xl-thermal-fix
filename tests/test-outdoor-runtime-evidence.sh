#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
evidence="$repo_root/tools/core/outdoor-runtime-evidence.tsv"
policy="$repo_root/tools/core/outdoor-runtime-policy.sh"

[[ -s "$evidence" ]]
[[ -s "$policy" ]]
head -n 1 "$evidence" | grep -Fq $'# device\tandroid\tbuild_id\tmax_proven_delta_c\tevidence'
grep -Fq $'mustang\t17\tCP2A.260705.006\t3\tlocal_install_postboot_extended_pass_2026-07-26' "$evidence"
grep -Fq $'mustang\t17\tZP11.260618.005\t1\tallen_clean_flash_safe_boots_plus_infinite_loading_2026-07-26' "$evidence"

awk -F '\t' '
  /^#/ { next }
  NF != 5 { bad=1 }
  $4 !~ /^[0-9]+$/ { bad=1 }
  END { exit bad }
' "$evidence"

# shellcheck disable=SC1090
. "$policy"
[[ "$(thermal_outdoor_max_delta mustang 17 CP2A.260705.006)" = 3 ]]
[[ "$(thermal_outdoor_max_delta mustang 17 ZP11.260618.005)" = 1 ]]
[[ "$(thermal_outdoor_max_delta unknown 17 unknown)" = 0 ]]

printf '%s\n' 'PASS outdoor_runtime_evidence_schema'
printf '%s\n' 'PASS mustang_july_canary_safe_only_boundary_recorded'
printf '%s\n' 'PASS runtime_policy_matches_evidence_matrix'
printf '%s\n' 'RESULT: PIXEL_THERMAL_OUTDOOR_RUNTIME_EVIDENCE_TEST_PASS'
