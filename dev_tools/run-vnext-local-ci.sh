#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

expected_branch="vnext-2.1.0-alpha.4"
expected_version="2.1.0-alpha.4-dev.2"
expected_workflow_blob="a0be2f8f9b35fa29e456b632661e035d718f3a0f"
expected_core_commit="7cf49cafb99664dc2772679bf12c4a8e693b46e8"
expected_core_version="0.6.0"
workflow_file=".github/workflows/vnext-2.1-ci.yml"
core_dir="${WEBUI_CORE_DIR:-$repo_root/.webui-core}"

say() { printf '%s\n' "$*"; }
fail() { say "FAIL $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || fail "missing_command=$1"; }

for cmd in git bash sh python3 node go zip unzip sha256sum grep sed awk tr sort xargs chmod; do
  need "$cmd"
done

[ -r "$workflow_file" ] || fail "workflow_missing=$workflow_file"
actual_workflow_blob="$(git hash-object "$workflow_file")"
[ "$actual_workflow_blob" = "$expected_workflow_blob" ] || fail "workflow_contract_drift expected=$expected_workflow_blob actual=$actual_workflow_blob"

branch="$(git branch --show-current 2>/dev/null || true)"
[ "$branch" = "$expected_branch" ] || fail "unexpected_branch=$branch expected=$expected_branch"

# The pinned WebUI core is intentionally checked out as a nested Git repository
# at .webui-core by both GitHub Actions and the quota-independent local runner.
# Ignore exactly that declared build input while remaining fail-closed for every
# other tracked or untracked working-tree change.
dirty_status="$(git status --porcelain --untracked-files=all | grep -Ev '^\?\? \.webui-core(/|$)' || true)"
[ -z "$dirty_status" ] || {
  printf '%s\n' "$dirty_status" >&2
  fail "working_tree_dirty"
}

version="$(sed -n 's/^version=//p' module.prop | head -n 1)"
[ "$version" = "$expected_version" ] || fail "unexpected_version=$version expected=$expected_version"

[ -d "$core_dir/.git" ] || fail "webui_core_git_missing=$core_dir"
core_head="$(git -C "$core_dir" rev-parse HEAD)"
[ "$core_head" = "$expected_core_commit" ] || fail "webui_core_commit_mismatch expected=$expected_core_commit actual=$core_head"
core_version="$(tr -d '\r\n' < "$core_dir/CORE_VERSION")"
[ "$core_version" = "$expected_core_version" ] || fail "webui_core_version_mismatch expected=$expected_core_version actual=$core_version"
[ "$(sed -n 's/^template_commit=//p' webui.lock)" = "$expected_core_commit" ] || fail "webui_lock_commit_mismatch"
[ "$(sed -n 's/^core_version=//p' webui.lock)" = "$expected_core_version" ] || fail "webui_lock_version_mismatch"

say '== pinned WebUI core =='
(
  cd "$core_dir"
  ./scripts/verify.sh
)
node --test "$core_dir/scripts/webui-race-regression.test.mjs"

say '== shell/python syntax =='
for file in \
  customize.sh action.sh post-fs-data.sh service.sh bin/module-control \
  tools/webui/launch.sh tools/control/pixel-control.sh tools/zram/page-cluster-control.sh \
  tools/core/thermal-layout.sh tools/core/patch-thermal.sh tools/core/patch-thermal-vnext-core.sh \
  tools/core/patch-thermal-validated.sh tools/core/patch-thermal-validated-vnext.sh \
  tools/bootguard/compat-check.sh tools/bootguard/compat-check-vnext.sh \
  tools/menu/menu-cycle.sh tools/menu/install-options-menu.sh tools/menu/zram-menu.sh tools/ptune/ptune-guard.sh \
  tools/debug/vnext-readiness-summary.sh tools/debug/vnext-device-verify.sh \
  tools/debug/status-lib.sh tools/debug/status-cached-print.sh tools/debug/collect-thermal-online-v5.sh \
  tools/core/platform-transition.sh tools/zram/materialize-zram-choice.sh \
  tools/zram/config-normalize.sh tools/zram/disable-zram-100p.sh; do
  sh -n "$file"
done
bash -n dev_tools/build-release-module.sh
bash -n dev_tools/verify-release-module.sh
bash -n dev_tools/run-vnext-local-ci.sh
python3 -m py_compile dev_tools/validate-package.py

say '== vNext regressions =='
for test_file in \
  tests/test-vnext-layouts.sh \
  tests/test-outdoor-delta-validation-runtime.sh \
  tests/test-vnext-ota-transition.sh \
  tests/test-vnext-alpha3-hardening.sh \
  tests/test-vnext-alpha3-zram-defer-contract.sh \
  tests/test-vnext-device-verify-contract.sh \
  tests/test-dev15-menu-matrix.sh \
  tests/test-dev16-install-regression.sh \
  tests/test-dev19-lmkd-early-test.sh \
  tests/test-dynamic-build-admission.sh \
  tests/test-single-install-menu.sh \
  tests/test-zram-eh-dev12.sh \
  tests/test-page-cluster-control.sh \
  tests/test-webui-integration.sh; do
  bash "$test_file"
done

say '== device family matrix =='
for device in mustang blazer frankel rango stallion tokay caiman komodo comet tegu; do
  grep -Fq "\"$device\"" supported_versions.json || fail "device_matrix_missing=$device"
done
grep -Fq 'tokay:17|caiman:17|komodo:17|comet:17|tegu:17|stallion:17' customize.sh || fail 'experimental_device_policy_missing'
printf '%s\n' 'RESULT: VNEXT_SINGLE_DEVICE_FAMILY_MATRIX_PASS'

say '== build device-test candidate =='
chmod +x dev_tools/build-release-module.sh dev_tools/verify-release-module.sh dev_tools/validate-package.py
rm -rf dist
mkdir -p dist
zip_path="dist/pixel-thermal-memory-control-${version}.zip"
WEBUI_CORE_DIR="$core_dir" dev_tools/build-release-module.sh "$zip_path" | tee dist/build-metadata.txt
dev_tools/verify-release-module.sh "$zip_path"
python3 dev_tools/validate-package.py "$zip_path"
sha256sum "$zip_path" | tee dist/device-test.sha256.txt
unzip -Z1 "$zip_path" | sort > dist/package-entries.txt
for asset in \
  bin/webui-server-arm64 \
  webroot/app.js webroot/app.css \
  webroot/race-guard.js webroot/race-guard.css \
  webroot/observability.js webroot/observability.css \
  webroot/v03.js webroot/v04.js; do
  grep -Fxq "$asset" dist/package-entries.txt || fail "package_asset_missing=$asset"
done
printf '%s\n' 'RESULT: VNEXT_WEBUI_DEVICE_TEST_PACKAGE_PASS'

candidate_sha="$(sha256sum "$zip_path" | awk '{print $1}')"
candidate_bytes="$(wc -c < "$zip_path" | tr -d ' ')"
repo_head="$(git rev-parse HEAD)"
say "repo_head=$repo_head"
say "workflow_blob=$actual_workflow_blob"
say "webui_core_commit=$core_head"
say "webui_core_version=$core_version"
say "candidate=$zip_path"
say "candidate_sha256=$candidate_sha"
say "candidate_bytes=$candidate_bytes"
say 'RESULT: PIXEL_THERMAL_VNEXT_LOCAL_CI_PASS workflow_exit_code=0'
