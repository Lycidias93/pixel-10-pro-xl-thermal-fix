#!/usr/bin/env bash
set -euo pipefail

zip_path="${1:-}"
[[ -n "$zip_path" && -s "$zip_path" ]] || {
  printf '%s\n' 'FAIL zip_missing_or_empty'
  exit 2
}

unzip -tq "$zip_path" >/dev/null
entries_file="$(mktemp)"
trap 'rm -f "$entries_file"' EXIT HUP INT TERM
unzip -Z1 "$zip_path" > "$entries_file"

required=(
  module.prop
  customize.sh
  action.sh
  service.sh
  supported_versions.json
  META-INF/com/google/android/update-binary
  tools/core/supported-build.sh
  tools/core/validation-state.sh
  tools/core/outdoor-runtime-policy.sh
  tools/core/thermal-layout.sh
  tools/core/patch-thermal-vnext-core.sh
  tools/core/patch-thermal-validated-vnext.sh
  tools/core/patch-thermal-validated.sh
  tools/bootguard/compat-check-vnext.sh
  tools/bootguard/compat-check.sh
  tools/debug/collect-thermal-online-v5.sh
)
for path in "${required[@]}"; do
  grep -Fxq "$path" "$entries_file" || {
    printf 'FAIL required_entry_missing path=%s\n' "$path"
    exit 3
  }
done

grep -Fxq 'tools/core/patch-thermal-fix5-core.sh' "$entries_file" && {
  printf '%s\n' 'FAIL superseded_fix5_core_packaged'
  exit 4
}

banned_regex='(^|/)(deprecated|scratch|dev_tools|docs|tests|test|fixtures|evidence|release|release-notes|dist)/|(^|/)\.git|(^|/)RELEASE_NOTES_|(^|/)(README|CHANGELOG|CREDITS|AGENTS|VERIFY_[^/]*)\.md$|(^|/)tools/(v2-public-alpha2-policy-guard|verify-v2-alpha2-candidate|outdoor-delta-validation-guard)\.sh$|(^|/)tools/bootguard/bootguard-threshold-policy-guard\.sh$|(^|/)tools/ptune/ptune-install-state-observability-guard\.sh$|\.zip$|(^|/)(test-[^/]*|[^/]*-test|[^/]*-fixture|[^/]*-fixtures)\.sh$'
if grep -E "$banned_regex" "$entries_file"; then
  printf '%s\n' 'FAIL banned_release_entry_present'
  exit 4
fi

entry_count="$(wc -l < "$entries_file" | tr -d ' ')"
case "$entry_count" in ''|*[!0-9]*) exit 5 ;; esac
[[ "$entry_count" -le 62 ]] || {
  printf 'FAIL release_entry_count_too_high entries=%s max=62\n' "$entry_count"
  exit 6
}

zip_bytes="$(wc -c < "$zip_path" | tr -d ' ')"
case "$zip_bytes" in ''|*[!0-9]*) exit 7 ;; esac
[[ "$zip_bytes" -le 480000 ]] || {
  printf 'FAIL release_zip_too_large bytes=%s max=480000\n' "$zip_bytes"
  exit 8
}

zero_entries="$(unzip -l "$zip_path" | awk 'NR>3 && $1 == 0 && $4 !~ /\/$/ {n++} END {print n+0}')"
[[ "$zero_entries" = 0 ]] || {
  printf 'FAIL zero_byte_release_entries count=%s\n' "$zero_entries"
  exit 9
}

printf 'PASS zip_integrity\n'
printf 'PASS required_runtime_entries\n'
printf 'PASS superseded_fix5_core_absent\n'
printf 'PASS banned_repo_only_entries_absent\n'
printf 'PASS release_entry_budget entries=%s max=62\n' "$entry_count"
printf 'PASS release_size_budget bytes=%s max=480000\n' "$zip_bytes"
printf 'PASS zero_byte_release_entries_absent\n'
printf '%s\n' 'RESULT: PIXEL_THERMAL_LEAN_PACKAGE_VERIFY_PASS'
