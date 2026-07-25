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
  tools/core/patch-thermal-validated.sh
  tools/bootguard/compat-check.sh
)
for path in "${required[@]}"; do
  grep -Fxq "$path" "$entries_file" || {
    printf 'FAIL required_entry_missing path=%s\n' "$path"
    exit 3
  }
done

banned_regex='(^|/)(deprecated|scratch|dev_tools|docs|tests|test|fixtures|evidence|release|dist)/|(^|/)\.git|(^|/)RELEASE_NOTES_|(^|/)(README|CHANGELOG|CREDITS|VERIFY_[^/]*)\.md$|\.zip$|(^|/)(test-[^/]*|[^/]*-test|[^/]*-fixture|[^/]*-fixtures)\.sh$'
if grep -E "$banned_regex" "$entries_file"; then
  printf '%s\n' 'FAIL banned_release_entry_present'
  exit 4
fi

entry_count="$(wc -l < "$entries_file" | tr -d ' ')"
case "$entry_count" in ''|*[!0-9]*) exit 5 ;; esac
[[ "$entry_count" -le 500 ]] || {
  printf 'FAIL release_entry_count_too_high entries=%s max=500\n' "$entry_count"
  exit 6
}

zero_entries="$(unzip -l "$zip_path" | awk 'NR>3 && $1 == 0 && $4 !~ /\/$/ {n++} END {print n+0}')"
[[ "$zero_entries" = 0 ]] || {
  printf 'FAIL zero_byte_release_entries count=%s\n' "$zero_entries"
  exit 7
}

printf 'PASS zip_integrity\n'
printf 'PASS required_runtime_entries\n'
printf 'PASS banned_repo_only_entries_absent\n'
printf 'PASS release_entry_budget entries=%s max=500\n' "$entry_count"
printf 'PASS zero_byte_release_entries_absent\n'
printf '%s\n' 'RESULT: PIXEL_THERMAL_LEAN_PACKAGE_VERIFY_PASS'
