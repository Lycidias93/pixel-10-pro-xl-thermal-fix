#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd -P)"
TARGET="$ROOT/tools/bootguard/bootguard-lib.sh"

fail=0
pass() { printf 'PASS %s\n' "$*"; }
err() { printf 'FAIL %s\n' "$*"; fail=1; }

[[ -s "$TARGET" ]] || { err "target_missing=$TARGET"; printf 'RESULT: BOOTGUARD_THRESHOLD_POLICY_GUARD_FAIL rc=1\n'; exit 1; }
bash -n "$TARGET" && pass 'bootguard_syntax' || err 'bootguard_syntax'

grep -Fq 'threshold_minimum()' "$TARGET" && pass 'threshold_minimum_helper' || err 'threshold_minimum_helper_missing'
grep -Fq 'minimum=2' "$TARGET" && pass 'normal_minimum_two' || err 'normal_minimum_two_missing'
grep -Fq 'CANARY_DIAGNOSTIC_MODE' "$TARGET" && pass 'canary_scope_present' || err 'canary_scope_missing'
grep -Fq '[ "$canary" = 1 ] && minimum=1' "$TARGET" && pass 'canary_only_minimum_one' || err 'canary_only_minimum_one_missing'
grep -Fq 'threshold_minimum=$(threshold_minimum)' "$TARGET" && pass 'status_observability' || err 'status_observability_missing'
grep -Fq 'effective_pending_threshold()' "$TARGET" && pass 'effective_pending_threshold_helper' || err 'effective_pending_threshold_helper_missing'
grep -Fq 'pending_transition()' "$TARGET" && pass 'transition_pending_helper' || err 'transition_pending_helper_missing'
grep -Fq "printf '%s\n' 1" "$TARGET" && pass 'ota_transition_threshold_one' || err 'ota_transition_threshold_one_missing'
grep -Fq 'success-verify)' "$TARGET" && pass 'verified_success_entrypoint' || err 'verified_success_entrypoint_missing'
grep -Fq 'thermalservice_unresponsive_second_probe' "$TARGET" && pass 'thermalservice_double_probe' || err 'thermalservice_double_probe_missing'

if grep -Fq '[ "$t" -ge 1 ]' "$TARGET"; then
  err 'unconditional_minimum_one_present'
else
  pass 'no_unconditional_minimum_one'
fi

if [[ "$fail" -eq 0 ]]; then
  printf 'RESULT: BOOTGUARD_THRESHOLD_POLICY_GUARD_PASS rc=0\n'
else
  printf 'RESULT: BOOTGUARD_THRESHOLD_POLICY_GUARD_FAIL rc=1\n'
  exit 1
fi
