#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
helper="$repo_root/tools/core/validation-state.sh"
[[ -s "$helper" ]]

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT HUP INT TERM

data_root="$work/data"
moddir="$work/module"
incoming="$work/incoming"
mkdir -p "$data_root" "$moddir/guard" "$incoming"

printf '%s\n' '{"validation":"passed"}' > "$incoming/validation-report.json"
printf '%s\n' 'validation=passed' > "$incoming/outdoor-delta-validation.env"
printf '%s\n' $'file\tsha256' > "$incoming/patch-manifest.tsv"

export THERMAL_DATA_ROOT="$data_root"
export THERMAL_VALIDATION_DIR="$data_root/validation"
source "$helper"

thermal_validation_publish \
  "$incoming/validation-report.json" \
  "$THERMAL_VALIDATION_REPORT" \
  0644
thermal_validation_publish \
  "$incoming/outdoor-delta-validation.env" \
  "$THERMAL_VALIDATION_DELTA" \
  0644
thermal_validation_publish \
  "$incoming/patch-manifest.tsv" \
  "$THERMAL_VALIDATION_PATCH_MANIFEST" \
  0644
thermal_validation_write_state mustang CP2A.260705.006 mod stock
thermal_validation_refresh_legacy_links "$moddir"

[[ -f "$THERMAL_VALIDATION_REPORT" && ! -L "$THERMAL_VALIDATION_REPORT" ]]
[[ -f "$THERMAL_VALIDATION_DELTA" && ! -L "$THERMAL_VALIDATION_DELTA" ]]
[[ -f "$THERMAL_VALIDATION_PATCH_MANIFEST" && ! -L "$THERMAL_VALIDATION_PATCH_MANIFEST" ]]
[[ -f "$THERMAL_VALIDATION_STATE" && ! -L "$THERMAL_VALIDATION_STATE" ]]

grep -Fxq 'schema=pixel-thermal-validation-state-v1' "$THERMAL_VALIDATION_STATE"
grep -Fxq 'legacy_paths=symlinks_only' "$THERMAL_VALIDATION_STATE"
grep -Fxq 'validation=passed' "$THERMAL_VALIDATION_STATE"

legacy_paths=(
  "$moddir/validation_report.json"
  "$data_root/validation_report.json"
  "$moddir/guard/patch-manifest.tsv"
  "$moddir/guard/outdoor-delta-validation.env"
  "$data_root/outdoor-delta-validation.env"
)
for path in "${legacy_paths[@]}"; do
  [[ -L "$path" ]]
  [[ -e "$path" ]]
done

[[ "$(readlink "$moddir/validation_report.json")" = "$THERMAL_VALIDATION_REPORT" ]]
[[ "$(readlink "$data_root/validation_report.json")" = "$THERMAL_VALIDATION_REPORT" ]]
[[ "$(readlink "$moddir/guard/patch-manifest.tsv")" = "$THERMAL_VALIDATION_PATCH_MANIFEST" ]]
[[ "$(readlink "$moddir/guard/outdoor-delta-validation.env")" = "$THERMAL_VALIDATION_DELTA" ]]
[[ "$(readlink "$data_root/outdoor-delta-validation.env")" = "$THERMAL_VALIDATION_DELTA" ]]

[[ "$(sha256sum "$moddir/validation_report.json" | awk '{print $1}')" = "$(sha256sum "$THERMAL_VALIDATION_REPORT" | awk '{print $1}')" ]]
[[ "$(sha256sum "$moddir/guard/outdoor-delta-validation.env" | awk '{print $1}')" = "$(sha256sum "$THERMAL_VALIDATION_DELTA" | awk '{print $1}')" ]]

printf '%s\n' 'PASS canonical_validation_files_are_regular'
printf '%s\n' 'PASS legacy_validation_paths_are_resolving_symlinks'
printf '%s\n' 'PASS legacy_and_canonical_hashes_match'
printf '%s\n' 'RESULT: PIXEL_THERMAL_VALIDATION_STATE_RUNTIME_TEST_PASS'
