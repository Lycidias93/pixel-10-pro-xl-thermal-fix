#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
evidence="$repo_root/tools/core/outdoor-runtime-evidence.tsv"

[[ -s "$evidence" ]]
head -n 1 "$evidence" | grep -Fq $'# device\tandroid\tbuild_id\tmax_proven_delta_c\tevidence'
grep -Fq $'mustang\t17\tCP2A.260705.006\t3\tlocal_install_postboot_extended_pass_2026-07-26' "$evidence"
grep -Fq $'mustang\t17\tZP11.260618.005\t0\tallen_chang_stock_boots_all_nonstock_black_screen_after_bootanimation_2026-07-26' "$evidence"

awk -F '\t' '
  /^#/ { next }
  NF != 5 { bad=1 }
  $4 !~ /^[0-9]+$/ { bad=1 }
  END { exit bad }
' "$evidence"

printf '%s\n' 'PASS outdoor_runtime_evidence_schema'
printf '%s\n' 'PASS mustang_july_canary_nonstock_failure_recorded'
printf '%s\n' 'RESULT: PIXEL_THERMAL_OUTDOOR_RUNTIME_EVIDENCE_TEST_PASS'
