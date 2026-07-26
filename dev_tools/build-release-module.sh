#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

version="$(sed -n 's/^version=//p' module.prop | head -n 1)"
[[ -n "$version" ]] || {
  printf '%s\n' 'FAIL module_version_missing'
  exit 2
}

output="${1:-$repo_root/dist/pixel-10-thermal-memory-control-${version}.zip}"
mkdir -p "$(dirname "$output")"
output="$(cd "$(dirname "$output")" && pwd)/$(basename "$output")"

stage="$(mktemp -d)"
list_file="$(mktemp)"
cleanup() {
  rm -rf "$stage" "$list_file"
}
trap cleanup EXIT HUP INT TERM

exclude_path() {
  case "$1" in
    .git*|.github/*|.workflow-baseline|.gitattributes) return 0 ;;
    deprecated/*|scratch/*|dev_tools/*|docs/*|tests/*|test/*|fixtures/*|evidence/*|release/*|release-notes/*|dist/*) return 0 ;;
    RELEASE_NOTES_*|README.md|CHANGELOG.md|CREDITS.md|VERIFY_*.md|WORKFLOW_*.md|LICENSE|*.zip) return 0 ;;
    tools/v2-public-alpha2-policy-guard.sh|tools/verify-v2-alpha2-candidate.sh) return 0 ;;
    tools/outdoor-delta-validation-guard.sh) return 0 ;;
    tools/bootguard/bootguard-threshold-policy-guard.sh) return 0 ;;
    tools/ptune/ptune-install-state-observability-guard.sh) return 0 ;;
    tools/debug/collect-outdoor-boot-failure-online.sh) return 0 ;;
    */tests/*|*/test/*|*/fixtures/*|*/scratch/*|*/deprecated/*) return 0 ;;
    */test-*.sh|*/*-test.sh|*/*-fixture.sh|*/*-fixtures.sh|*/*fixture*.json) return 0 ;;
  esac
  return 1
}

included_paths=()
while IFS= read -r -d '' path; do
  exclude_path "$path" && continue
  [[ -f "$path" ]] || continue
  printf '%s\0' "$path" >> "$list_file"
  included_paths+=("$path")
  mkdir -p "$stage/$(dirname "$path")"
  cp -p "$path" "$stage/$path"
done < <(git ls-files -z)

required=(
  module.prop
  customize.sh
  action.sh
  service.sh
  supported_versions.json
  META-INF/com/google/android/update-binary
  tools/core/supported-build.sh
  tools/core/validation-state.sh
  tools/core/patch-thermal-validated.sh
  tools/bootguard/compat-check.sh
)
for path in "${required[@]}"; do
  [[ -s "$stage/$path" ]] || {
    printf 'FAIL required_runtime_file_missing path=%s\n' "$path"
    exit 3
  }
done

source_date_epoch="${SOURCE_DATE_EPOCH:-}"
if [[ -z "$source_date_epoch" ]]; then
  source_date_epoch="$(git log -1 --format=%ct -- "${included_paths[@]}")"
fi
[[ "$source_date_epoch" =~ ^[0-9]+$ ]] || {
  printf 'FAIL source_date_epoch_invalid value=%s\n' "$source_date_epoch"
  exit 4
}

find "$stage" -type f -exec touch -d "@$source_date_epoch" {} +
rm -f "$output"

(
  cd "$stage"
  find . -type f -print0 \
    | LC_ALL=C sort -z \
    | xargs -0 zip -X -q "$output"
)

"$repo_root/dev_tools/verify-release-module.sh" "$output"

printf 'zip=%s\n' "$output"
printf 'source_date_epoch=%s\n' "$source_date_epoch"
printf 'sha256=%s\n' "$(sha256sum "$output" | awk '{print $1}')"
printf 'bytes=%s\n' "$(wc -c < "$output" | tr -d ' ')"
printf 'entries=%s\n' "$(unzip -Z1 "$output" | wc -l | tr -d ' ')"
printf '%s\n' 'RESULT: PIXEL_THERMAL_LEAN_PACKAGE_BUILD_PASS'
