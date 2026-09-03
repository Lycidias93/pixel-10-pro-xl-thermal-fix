#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

version="$(sed -n 's/^version=//p' module.prop | head -n 1)"
[[ -n "$version" ]] || { printf '%s\n' 'FAIL module_version_missing'; exit 2; }

output="${1:-$repo_root/dist/pixel-thermal-memory-control-${version}.zip}"
mkdir -p "$(dirname "$output")"
output="$(cd "$(dirname "$output")" && pwd)/$(basename "$output")"

stage="$(mktemp -d)"
list_file="$(mktemp)"
cleanup() { rm -rf "$stage" "$list_file"; }
trap cleanup EXIT HUP INT TERM

exclude_path() {
  case "$1" in
    .git*|.github/*|.workflow-baseline|.gitattributes) return 0 ;;
    deprecated/*|scratch/*|dev_tools/*|docs/*|tests/*|test/*|fixtures/*|evidence/*|release/*|release-notes/*|dist/*) return 0 ;;
    RELEASE_NOTES_*|README.md|CHANGELOG.md|CREDITS.md|AGENTS.md|VERIFY_*.md|WORKFLOW_*.md|LICENSE|NOTICE|*.zip) return 0 ;;
    tools/v2-public-alpha2-policy-guard.sh|tools/verify-v2-alpha2-candidate.sh) return 0 ;;
    tools/outdoor-delta-validation-guard.sh) return 0 ;;
    tools/bootguard/bootguard-threshold-policy-guard.sh) return 0 ;;
    tools/ptune/ptune-install-state-observability-guard.sh) return 0 ;;
    tools/debug/collect-outdoor-boot-failure-online.sh|tools/debug/collect-thermal-prerelease-online.sh|tools/debug/collect-thermal-prerelease-online-menu.sh) return 0 ;;
    tools/core/patch-thermal-fix5-core.sh) return 0 ;;
    tools/core/outdoor-runtime-evidence.tsv) return 0 ;;
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

lock_value() { sed -n "s/^$1=//p" webui.lock 2>/dev/null | head -n 1; }
core_dir="${WEBUI_CORE_DIR:-$repo_root/.webui-core}"
expected_core_commit="$(lock_value template_commit)"
expected_core_version="$(lock_value core_version)"
[[ "$expected_core_commit" =~ ^[0-9a-f]{40}$ && -n "$expected_core_version" ]] || {
  printf '%s\n' 'FAIL webui_lock_invalid'; exit 10;
}
[[ -d "$core_dir" && -r "$core_dir/CORE_VERSION" ]] || {
  printf 'FAIL webui_core_missing dir=%s\n' "$core_dir"; exit 11;
}
actual_core_version="$(tr -d '\r\n' < "$core_dir/CORE_VERSION")"
[[ "$actual_core_version" = "$expected_core_version" ]] || {
  printf 'FAIL webui_core_version_mismatch expected=%s actual=%s\n' "$expected_core_version" "$actual_core_version"; exit 12;
}
if [[ -d "$core_dir/.git" ]]; then
  actual_core_commit="$(git -C "$core_dir" rev-parse HEAD)"
  [[ "$actual_core_commit" = "$expected_core_commit" ]] || {
    printf 'FAIL webui_core_commit_mismatch expected=%s actual=%s\n' "$expected_core_commit" "$actual_core_commit"; exit 13;
  }
fi
command -v go >/dev/null 2>&1 || { printf '%s\n' 'FAIL go_missing_for_webui_server'; exit 14; }

mkdir -p "$stage/webroot" "$stage/bin" "$stage/webui-third-party"
webui_assets=(
  index.html embedded-host-bootstrap.js mobile-input-viewport.js app.js app.css
  race-guard.js race-guard.css
  observability.js observability.css
  v03.js v04.js
)
for path in "${webui_assets[@]}"; do
  [[ -s "$core_dir/module/webroot/$path" ]] || { printf 'FAIL webui_core_file_missing path=%s\n' "$path"; exit 15; }
  cp -p "$core_dir/module/webroot/$path" "$stage/webroot/$path"
done
(
  cd "$core_dir"
  CGO_ENABLED=0 GOOS=android GOARCH=arm64 go build -trimpath -buildvcs=false -ldflags='-s -w' -o "$stage/bin/webui-server-arm64" ./server/cmd/webui-server
)
chmod 0755 "$stage/bin/webui-server-arm64" "$stage/bin/module-control" "$stage/tools/webui/launch.sh" "$stage/tools/control/pixel-control.sh" "$stage/tools/zram/page-cluster-control.sh"
printf 'template_repo=%s\ntemplate_commit=%s\ncore_version=%s\n' "$(lock_value template_repo)" "$expected_core_commit" "$expected_core_version" > "$stage/webui-third-party/core-provenance.env"
cp "$core_dir/LICENSE" "$stage/webui-third-party/template.LICENSE"
cp "$core_dir/NOTICE" "$stage/webui-third-party/template.NOTICE"
cp "$core_dir/third_party/licenses/Supercharger_Pixel_9_Series.LICENSE" "$stage/webui-third-party/Supercharger_Pixel_9_Series.LICENSE"
chmod 0644 "$stage/webui-third-party/"*

required=(
  module.prop customize.sh action.sh service.sh supported_versions.json
  META-INF/com/google/android/update-binary
  tools/core/supported-build.sh tools/core/validation-state.sh tools/core/outdoor-runtime-policy.sh
  tools/core/thermal-layout.sh tools/core/patch-thermal-vnext-core.sh tools/core/patch-thermal-validated-vnext.sh tools/core/patch-thermal-validated.sh
  tools/bootguard/compat-check-vnext.sh tools/bootguard/compat-check.sh tools/debug/collect-thermal-online-v5.sh
  tools/webui/launch.sh tools/control/pixel-control.sh tools/zram/page-cluster-control.sh
  bin/module-control bin/webui-server-arm64
  webroot/index.html webroot/embedded-host-bootstrap.js webroot/mobile-input-viewport.js webroot/app.js webroot/app.css
  webroot/race-guard.js webroot/race-guard.css webroot/observability.js webroot/observability.css webroot/v03.js webroot/v04.js
  common/repo.json webui.lock
)
for path in "${required[@]}"; do
  [[ -s "$stage/$path" ]] || { printf 'FAIL required_runtime_file_missing path=%s\n' "$path"; exit 3; }
done

source_date_epoch="${SOURCE_DATE_EPOCH:-}"
if [[ -z "$source_date_epoch" ]]; then source_date_epoch="$(git log -1 --format=%ct -- "${included_paths[@]}")"; fi
[[ "$source_date_epoch" =~ ^[0-9]+$ ]] || { printf 'FAIL source_date_epoch_invalid value=%s\n' "$source_date_epoch"; exit 4; }
find "$stage" -type f -exec touch -d "@$source_date_epoch" {} +
rm -f "$output"
(
  cd "$stage"
  find . -type f -print0 | LC_ALL=C sort -z | xargs -0 zip -X -q "$output"
)

"$repo_root/dev_tools/verify-release-module.sh" "$output"
python3 "$repo_root/dev_tools/validate-package.py" "$output"
printf 'zip=%s\n' "$output"
printf 'webui_core_commit=%s\n' "$expected_core_commit"
printf 'webui_core_version=%s\n' "$expected_core_version"
printf 'source_date_epoch=%s\n' "$source_date_epoch"
printf 'sha256=%s\n' "$(sha256sum "$output" | awk '{print $1}')"
printf 'bytes=%s\n' "$(wc -c < "$output" | tr -d ' ')"
printf 'entries=%s\n' "$(unzip -Z1 "$output" | wc -l | tr -d ' ')"
printf '%s\n' 'RESULT: PIXEL_THERMAL_LEAN_PACKAGE_BUILD_PASS'