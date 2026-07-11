#!/usr/bin/env sh
set -eu

root="${1:-.}"

say() {
  printf '%s\n' "$*"
}

fail() {
  say "FAIL $1"
  exit "${2:-1}"
}

[ -s "$root/module.prop" ] || fail "module_prop_missing" 10
[ -s "$root/update.json" ] || fail "stable_update_json_missing" 11
[ -s "$root/update-prerelease.json" ] || fail "prerelease_update_json_missing" 12
[ -s "$root/tools/update-channel-switch.sh" ] || fail "switch_tool_missing" 13
[ -s "$root/tools/action-dashboard.sh" ] || fail "action_dashboard_missing" 14

grep -q '^version=1.5.2-universal-test.4$' "$root/module.prop" || fail "module_version_not_test4" 20
grep -q '^versionCode=1016204$' "$root/module.prop" || fail "module_code_not_test4" 21
grep -q 'updateJson=.*update.json$' "$root/module.prop" || fail "module_default_not_stable" 22

grep -q '"version": "1.5.1-universal.1"' "$root/update.json" || fail "stable_version_changed" 30
grep -q '"versionCode": 1016108' "$root/update.json" || fail "stable_code_changed" 31

grep -q '"version": "1.5.2-universal-test.4"' "$root/update-prerelease.json" || fail "test_version_missing" 40
grep -q '"versionCode": 1016204' "$root/update-prerelease.json" || fail "test_code_missing" 41
grep -q 'releases/download/v1.5.2-universal-test.4' "$root/update-prerelease.json" || fail "test_zip_url_missing" 42

grep -q 'update_channel_loop' "$root/tools/action-dashboard.sh" || fail "menu_loop_missing" 50
grep -q 'Use Stable' "$root/tools/action-dashboard.sh" || fail "use_stable_missing" 51
grep -q 'Use Test' "$root/tools/action-dashboard.sh" || fail "use_test_missing" 52
grep -q 'update-channel-switch.sh' "$root/tools/action-dashboard.sh" || fail "switch_tool_reference_missing" 53

grep -q 'No ZIP download' "$root/tools/update-channel-switch.sh" || fail "no_download_text_missing" 60
grep -q 'update-prerelease.json' "$root/tools/update-channel-switch.sh" || fail "test_json_path_missing" 61

say "PASS stable_update_json_unchanged"
say "PASS prerelease_update_json_present"
say "PASS action_menu_channel_switch_present"
say "PASS switch_changes_update_json_path_only"
say "RESULT: UPDATE_CHANNEL_SWITCH_VERIFY_DONE"
