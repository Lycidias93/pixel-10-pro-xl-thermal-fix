#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
action="$repo_root/tools/action-dashboard.sh"
policy="$repo_root/tools/core/outdoor-runtime-policy.sh"
menu="$repo_root/tools/menu/install-options-menu.sh"

bash -n "$action"
bash -n "$policy"
bash -n "$menu"

grep -Fq 'patch-thermal-validated.sh' "$action"
if grep -Fq 'sh "$MODDIR/tools/core/patch-thermal.sh"' "$action"; then
  printf '%s\n' 'FAIL action_invokes_raw_patcher'
  exit 1
fi
if grep -Fq 'rematerialize_thermal_overlay || true' "$action"; then
  printf '%s\n' 'FAIL action_ignores_materialization_failure'
  exit 1
fi
grep -Fq 'if rematerialize_thermal_overlay "$current_polling" "$choice"; then' "$action"
grep -Fq 'set_thermal_choice "$choice"' "$action"
grep -Fq 'Existing settings kept' "$action"
grep -Fq 'action_validated_transaction_v2' "$action"
grep -Fq 'blocked on $POLICY_BUILD' "$menu"

# Policy truth table.
# shellcheck disable=SC1090
. "$policy"
[[ "$(thermal_outdoor_max_delta mustang 17 CP2A.260705.006)" = 3 ]]
[[ "$(thermal_outdoor_max_delta mustang 17 ZP11.260618.005)" = 1 ]]
[[ "$(thermal_outdoor_max_delta unknown 17 future)" = 0 ]]
thermal_outdoor_profile_admitted outdoor-safe mustang 17 ZP11.260618.005
if thermal_outdoor_profile_admitted outdoor-plus mustang 17 ZP11.260618.005; then
  printf '%s\n' 'FAIL canary_plus_policy_admitted'
  exit 1
fi

printf '%s\n' 'PASS action_uses_validated_transaction'
printf '%s\n' 'PASS action_failure_does_not_commit_requested_profile'
printf '%s\n' 'PASS runtime_evidence_policy_truth_table'
printf '%s\n' 'RESULT: PIXEL_THERMAL_ACTION_TRANSACTION_TEST_PASS'
