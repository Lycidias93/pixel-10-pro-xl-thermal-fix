#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

mapfile -t root_notes < <(find . -maxdepth 1 -type f -name 'RELEASE_NOTES_*' -printf '%f\n' | LC_ALL=C sort)
if ((${#root_notes[@]})); then
  printf '%s\n' 'FAIL root_release_notes_present'
  printf '%s\n' "${root_notes[@]}"
  exit 1
fi

[[ -d release-notes ]] || {
  printf '%s\n' 'FAIL release_notes_directory_missing'
  exit 2
}
find release-notes -maxdepth 1 -type f -name '*.md' | grep -q .

printf '%s\n' 'PASS release_notes_live_under_release_notes_directory'
printf '%s\n' 'RESULT: PIXEL_THERMAL_RELEASE_NOTES_LAYOUT_TEST_PASS'
