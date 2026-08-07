#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
transition="$repo_root/tools/core/platform-transition.sh"
bootguard="$repo_root/tools/bootguard/bootguard-lib.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

sh -n "$transition"
sh -n "$bootguard"

make_case() {
  local name="$1"
  local experimental="$2"
  local mod="$tmp/$name/module"
  local data="$tmp/$name/data"
  local cfg="$data/config.env"
  mkdir -p "$mod/system/vendor/etc" "$mod/guard" "$data/originals/mustang/BUILD.NEW/vendor/etc" "$data/validation"
  printf '%s\n' 'version=2.1.0-alpha.1' 'versionCode=1016250' > "$mod/module.prop"
  printf '%s\n' \
    'device=mustang' \
    'android=17' \
    'build_id=BUILD.NEW' \
    'incremental=100' \
    'fingerprint=google/mustang/old' > "$mod/install-state.txt"
  printf '%s\n' "THERMAL_DISABLED=0" "VNEXT_EXPERIMENTAL_PLATFORM=$experimental" > "$cfg"
  printf '%s\n' old > "$mod/system/vendor/etc/thermal_info_config.json"
  printf '%s\n' old > "$mod/system/vendor/etc/thermal_info_config_charge.json"
  printf '%s\n' old > "$mod/system/vendor/etc/thermal_info_config_throttling.json"
  printf '%s\n' old > "$mod/system/vendor/etc/thermal_info_config_lpm.json"
  printf '%s\n' keep > "$mod/system/vendor/etc/unrelated.conf"
  printf '%s\n' stale > "$data/originals/mustang/BUILD.NEW/vendor/etc/cache"
  printf '%s\n' stale > "$data/validation/state.env"
  printf '%s\n' "$mod|$data|$cfg"
}

run_transition_case() {
  local name="$1"
  local experimental="$2"
  local expected_reinstall="$3"
  local tuple
  tuple="$(make_case "$name" "$experimental")"
  local mod="${tuple%%|*}"
  local rest="${tuple#*|}"
  local data="${rest%%|*}"
  local cfg="${rest#*|}"

  MODDIR="$mod" THERMAL_DATA_ROOT="$data" CONFIG_FILE="$cfg" \
  THERMAL_DEVICE=mustang THERMAL_ANDROID=17 THERMAL_BUILD_ID=BUILD.NEW \
  THERMAL_INCREMENTAL=101 THERMAL_FINGERPRINT=google/mustang/new \
    sh "$transition" prepare > "$tmp/$name/transition.out"

  grep -q '^PLATFORM_TRANSITION_REASON=incremental_changed$' "$tmp/$name/transition.out"
  grep -q '^transition_pending=yes$' "$mod/guard/platform-transition.env"
  grep -q '^phase=prepared$' "$mod/guard/platform-transition.env"
  grep -q '^THERMAL_DISABLED=1$' "$cfg"
  grep -q "^REINSTALL_REQUIRED=$expected_reinstall$" "$mod/guard/reinstall_required"
  [[ -f "$mod/system/vendor/etc/unrelated.conf" ]]
  [[ ! -e "$mod/system/vendor/etc/thermal_info_config.json" ]]
  [[ ! -e "$mod/system/vendor/etc/thermal_info_config_charge.json" ]]
  [[ ! -e "$mod/system/vendor/etc/thermal_info_config_throttling.json" ]]
  [[ ! -e "$mod/system/vendor/etc/thermal_info_config_lpm.json" ]]
  [[ ! -e "$data/originals/mustang/BUILD.NEW/vendor/etc/cache" ]]
  [[ ! -e "$data/validation" ]]

  printf '%s\n' 0 > "$mod/guard/fail_count"
  cp "$mod/guard/platform-transition.env" "$mod/guard/pending_boot"
  if MODDIR="$mod" CONFIG_FILE="$cfg" sh "$bootguard" evaluate >/dev/null 2>&1; then
    printf 'FAIL transition_threshold_not_enforced case=%s\n' "$name"
    exit 20
  fi
  [[ -e "$mod/disable" ]]
  [[ -e "$mod/skip_mount" ]]
  grep -q '^automatic_bootguard_fail_count_1$' "$mod/guard/disabled_reason"
}

run_transition_case stable 0 no
run_transition_case experimental 1 yes

printf '%s\n' 'PASS stable_transition_quarantines_dynamic_layout_and_allows_rematerialization'
printf '%s\n' 'PASS experimental_transition_quarantines_dynamic_layout_and_requires_reinstall'
printf '%s\n' 'PASS transition_pending_uses_one_attempt_bootguard_threshold'
printf '%s\n' 'RESULT: VNEXT_OTA_TRANSITION_PASS'
