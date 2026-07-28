#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
action_root="$repo_root/action.sh"
action="$repo_root/tools/action-dashboard.sh"
policy="$repo_root/tools/core/outdoor-runtime-policy.sh"
menu="$repo_root/tools/menu/install-options-menu.sh"
menu_cycle="$repo_root/tools/menu/menu-cycle.sh"
auto_switch="$repo_root/tools/core/auto-profile-switch.sh"
ptune_override="$repo_root/tools/ptune/enable-ptune-override.sh"
compat="$repo_root/tools/bootguard/compat-check.sh"
supported="$repo_root/tools/core/supported-build.sh"
cached_status="$repo_root/tools/debug/status-cached-print.sh"
supported_json="$repo_root/supported_versions.json"

for file in "$action_root" "$action" "$policy" "$menu" "$menu_cycle" "$auto_switch" "$ptune_override" "$compat" "$supported" "$cached_status"; do
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

grep -Fq 'thermal_supported_probe "$SUPPORTED_JSON" "$CURRENT_DEVICE" "$CURRENT_ANDROID" "$CURRENT_BUILD"' "$action_root"
if grep -Fq 'thermal_supported_platform_check "$SUPPORTED_JSON" "$CURRENT_DEVICE" "$CURRENT_ANDROID"' "$action_root"; then
  printf '%s\n' 'FAIL action_repeats_supported_manifest_probes'
  exit 1
fi

grep -Fq 'status-cached-print.sh' "$action"
grep -Fq 'ensure_status' "$action"
grep -Fq 'status_refresh_count=' "$action"
grep -Fq 'STATUS_SHOWN=0' "$action"
main_loop="$(sed -n '/^action_loop() {/,/^}/p' "$action")"
if grep -Fq 'refresh_status' <<<"$main_loop"; then
  printf '%s\n' 'FAIL action_main_loop_refreshes_every_render'
  exit 1
fi
grep -Fq 'if [ "$STATUS_DIRTY" = 1 ] || [ "$STATUS_SHOWN" = 0 ]; then' <<<"$main_loop"
grep -Fq 'STATUS_SHOWN=1' <<<"$main_loop"
[[ "$(grep -Fc 'ensure_status' <<<"$main_loop")" = 1 ]] || {
  printf '%s\n' 'FAIL action_main_loop_ensure_status_count'
  exit 1
}
[[ "$(grep -Fc 'show_status' <<<"$main_loop")" = 1 ]] || {
  printf '%s\n' 'FAIL action_main_loop_show_status_count'
  exit 1
}
if grep -Fq 'pixel_thermal_toggle_debug.sh' "$action"; then
  printf '%s\n' 'FAIL action_calls_obsolete_toggle_collector'
  exit 1
fi
grep -Fq 'cfg_set DEBUG_MODE' "$action"

update_channel_status_body="$(sed -n '/^update_channel_status() {/,/^}/p' "$action")"
[[ "$(grep -Fc 'sh "$MODDIR/tools/update-channel-switch.sh" status' <<<"$update_channel_status_body")" = 1 ]] || {
  printf '%s\n' 'FAIL update_channel_status_duplicate_or_missing_call'
  exit 1
}

if grep -Fq 'find "$ADB_ROOT" /debug_ramdisk /sbin' "$compat"; then
  printf '%s\n' 'FAIL compat_recursive_backend_search_present'
  exit 1
fi
grep -Fq 'meta_backend_probe_mode=module_prop_shallow' "$compat"
grep -Fq 'META_BACKEND_PROBE_MODE=$meta_backend_probe_mode' "$compat"

grep -Fq 'THERMAL_SUPPORTED_VALIDATE_CACHE_FILE=' "$supported"
grep -Fq 'thermal_supported_probe()' "$supported"

# shellcheck disable=SC1090
. "$supported"
thermal_supported_probe "$supported_json" mustang 17 CP2A.260705.006
[[ "$THERMAL_SUPPORTED_DEVICE_OK:$THERMAL_SUPPORTED_ANDROID_OK:$THERMAL_SUPPORTED_BUILD_OK" = 1:1:1 ]]
thermal_supported_probe "$supported_json" blazer 17 UNLISTED.DEV10.TEST
[[ "$THERMAL_SUPPORTED_DEVICE_OK:$THERMAL_SUPPORTED_ANDROID_OK:$THERMAL_SUPPORTED_BUILD_OK" = 1:1:0 ]]
if thermal_supported_probe "$supported_json" unsupported 17 UNLISTED.DEV10.TEST; then
  printf '%s\n' 'FAIL unsupported_device_admitted'
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
printf '%s\n' 'PASS action_status_refresh_is_dirty_cached'
printf '%s\n' 'PASS action_status_render_is_initial_or_dirty_only'
printf '%s\n' 'PASS action_submenu_return_skips_status_rerender'
printf '%s\n' 'PASS compat_backend_probe_is_shallow'
printf '%s\n' 'PASS supported_manifest_validation_is_cached'
printf '%s\n' 'PASS obsolete_action_toggle_collector_call_absent'
printf '%s\n' 'PASS duplicate_update_channel_status_call_absent'
printf '%s\n' 'RESULT: PIXEL_THERMAL_ACTION_TRANSACTION_TEST_PASS'
