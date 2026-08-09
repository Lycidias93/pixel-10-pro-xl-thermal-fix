#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
compat="$repo_root/tools/bootguard/compat-check.sh"
[[ -s "$compat" ]]

grep -Fq 'VALIDATION_DIR="$DATA_ROOT/validation"' "$compat"
grep -Fq 'VALIDATION_STATE="$VALIDATION_DIR/state.env"' "$compat"
grep -Fq 'PATCH_MANIFEST="$VALIDATION_DIR/patch-manifest.tsv"' "$compat"
grep -Fq 'REPORT_MODULE="$VALIDATION_DIR/validation-report.json"' "$compat"
grep -Fq 'REPORT_DATA="$VALIDATION_DIR/validation-report.json"' "$compat"

if grep -Fq 'PATCH_MANIFEST="$GUARD_DIR/patch-manifest.tsv"' "$compat"; then
  echo 'FAIL runtime compat still depends on module legacy patch-manifest alias' >&2
  exit 1
fi
if grep -Fq 'REPORT_MODULE="$M/validation_report.json"' "$compat"; then
  echo 'FAIL runtime compat still depends on module legacy report alias' >&2
  exit 1
fi

printf '%s\n' 'PASS runtime_compat_uses_canonical_validation_evidence'
printf '%s\n' 'RESULT: PIXEL_THERMAL_CANONICAL_VALIDATION_COMPAT_CONTRACT_PASS'
