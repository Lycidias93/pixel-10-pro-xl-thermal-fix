#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
action="$repo_root/tools/action-dashboard.sh"
policy="$repo_root/tools/core/outdoor-runtime-policy.sh"
menu="$repo_root/tools/menu/install-options-menu.sh"
menu_cycle="$repo_root/tools/menu/menu-cycle.sh"
auto_switch="$repo_root/tools/core/auto-profile-switch.sh"
ptune_override="$repo_root/tools/ptune/enable-ptune-override.sh"

for file in "$action" "$policy" "$menu" "$menu_cycle" "$auto_switch" "$ptune_override"; do
  bash -n "$file"
done

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

grep -Fq 'patch-thermal-validated.sh' "$auto_switch"
grep -Fq 'patch-thermal-validated.sh' "$ptune_override"
if grep -Fq '> "$CONFIG_FILE"' "$ptune_override"; then
  printf '%s\n' 'FAIL ptune_override_clobbers_config'
  exit 1
fi
if grep -Fq '</dev/tty' "$menu_cycle"; then
  printf '%s\n' 'FAIL ksu_action_forces_dev_tty'
  exit 1
fi

# shellcheck disable=SC1090
. "$policy"
[[ "$(thermal_outdoor_max_delta mustang 17 CP2A.260705.006)" = 3 ]]
[[ "$(thermal_outdoor_max_delta mustang 17 ZP11.260618.005)" = 3 ]]
thermal_outdoor_profile_admitted outdoor-extended mustang 17 ZP11.260618.005

printf '%s\n' 'PASS action_uses_validated_transaction'
printf '%s\n' 'PASS action_failure_does_not_commit_requested_profile'
printf '%s\n' 'PASS auto_switch_and_ptune_use_validated_materializer'
printf '%s\n' 'PASS ksu_action_width_detection_has_no_forced_dev_tty'
printf '%s\n' 'PASS fix5_canary_extended_policy_admitted'
printf '%s\n' 'RESULT: PIXEL_THERMAL_ACTION_TRANSACTION_TEST_PASS'
