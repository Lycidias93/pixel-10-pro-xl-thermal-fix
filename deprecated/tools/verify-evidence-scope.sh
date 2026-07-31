#!/usr/bin/env sh
set -eu
# VERIFY_EVIDENCE_SCOPE_TEST2_MARKER version_152_test2
# VERIFY_EVIDENCE_SCOPE_TEST1_MARKER runtime_version_152_test1

mode="${1:-runtime}"
target="${2:-/data/adb/modules/pixel-10-pro-xl-thermal-fix}"

say() {
  printf '%s\n' "$*"
}

exists_file() {
  if [ -s "$1" ]; then
    say "PASS file_present $1"
    return 0
  fi
  say "WARN file_absent $1"
  return 1
}

grep_file() {
  pattern="$1"
  file="$2"
  label="$3"
  if [ -s "$file" ] && grep -Eq "$pattern" "$file"; then
    say "PASS $label"
    return 0
  fi
  say "WARN $label"
  return 1
}

version_scope_check() {
  prefix="$1"
  prop="$2"
  version="$(sed -n 's/^version=//p' "$prop" 2>/dev/null | head -n 1)"
  code="$(sed -n 's/^versionCode=//p' "$prop" 2>/dev/null | head -n 1)"
  case "$version:$code" in
    1.5.1-universal.1:1016108)
      say "PASS ${prefix}_version_151"
    ;;
    1.5.2-universal-test.1:1016201)
      say "PASS ${prefix}_version_152_test1"
    ;;
    1.5.2-universal-test.2:1016202)
      say "PASS ${prefix}_version_152_test2"
    ;;
    1.5.2-universal-test.3:1016203)
      say "PASS ${prefix}_version_152_test3"
    ;;
    1.5.2-universal-test.4:1016204)
      say "PASS ${prefix}_version_152_test4"
    ;;
    *)
      say "WARN ${prefix}_version_unexpected version=$version code=$code"
    ;;
  esac
}

runtime_mode() {
  mod="$target"
  say "== evidence scope: runtime =="
  say "target=$mod"

  exists_file "$mod/module.prop" || return 1
  exists_file "$mod/update.json" || true
  exists_file "$mod/tools/status-lib.sh" || true
  exists_file "$mod/tools/compat-check.sh" || true
  exists_file "$mod/tools/profile-matrix-verify.sh" || true
  exists_file "$mod/tools/ui-text-guard.sh" || true
  exists_file "$mod/guard/manager-status.env" || true
  exists_file "$mod/CHANGELOG.md" || true
  exists_file "$mod/RELEASE_NOTES_v1.5.1-universal.1.md" || true
  exists_file "$mod/docs/stable-candidate-1.5.1-cp31-260618005.md" || true

  if [ -s "$mod/customize.sh" ]; then
    say "INFO customize_scope=runtime_present"
  else
    say "INFO customize_scope=install_only_absent_at_runtime"
  fi

  if [ -s "$mod/README.md" ]; then
    say "INFO readme_scope=runtime_present"
  else
    say "INFO readme_scope=repo_or_zip_doc_absent_at_runtime"
  fi

  version_scope_check runtime "$mod/module.prop"
  grep_file 'Action: settings/debug' "$mod/module.prop" "runtime_action_text" || true
  grep_file 'Runtime-proven on .*mustang' "$mod/CHANGELOG.md" "runtime_doc_honest_mustang" || true
  grep_file 'Factory-basis covered for all G5 Pixel 10 devices' "$mod/CHANGELOG.md" "runtime_doc_factory_basis_all_g5" || true

  if grep -R "CP31.260608.007.*current QPR1 basis" -n "$mod/CHANGELOG.md" "$mod/RELEASE_NOTES_v1.5.1-universal.1.md" "$mod/docs" 2>/dev/null | grep -v "Do not advertise"; then
    say "FAIL runtime_stale_current_basis_claim"
    return 2
  fi
  say "PASS runtime_no_stale_current_basis_claim"

  say "RESULT: VERIFY_EVIDENCE_SCOPE_RUNTIME_DONE"
}

repo_mode() {
  repo="$target"
  say "== evidence scope: repo =="
  say "target=$repo"

  exists_file "$repo/module.prop" || return 1
  exists_file "$repo/customize.sh" || true
  exists_file "$repo/README.md" || true
  exists_file "$repo/CHANGELOG.md" || true
  exists_file "$repo/RELEASE_NOTES_v1.5.1-universal.1.md" || true
  exists_file "$repo/docs/vnext-1.5.2-planning.md" || true
  exists_file "$repo/tools/verify-evidence-scope.sh" || true

  version_scope_check repo "$repo/module.prop"
  grep_file '(Release|Prerelease): [$]MODULE_VERSION' "$repo/customize.sh" "repo_installer_release_wording" || true
  grep_file 'Stable channel: 1\.5\.1' "$repo/customize.sh" "repo_installer_stable_channel_151" || true
  grep_file 'Runtime-proven on .*mustang' "$repo/README.md" "repo_readme_honest_mustang" || true
  grep_file 'Factory-basis covered for all G5 Pixel 10 devices' "$repo/README.md" "repo_readme_factory_basis_all_g5" || true

  if grep -R "CP31.260608.007.*current QPR1 basis" -n "$repo/README.md" "$repo/CHANGELOG.md" "$repo/RELEASE_NOTES_v1.5.1-universal.1.md" "$repo/docs" 2>/dev/null | grep -v "Do not advertise"; then
    say "FAIL repo_stale_current_basis_claim"
    return 2
  fi
  say "PASS repo_no_stale_current_basis_claim"

  say "RESULT: VERIFY_EVIDENCE_SCOPE_REPO_DONE"
}

zip_mode() {
  zip_dir="$target"
  say "== evidence scope: zip =="
  say "target=$zip_dir"

  exists_file "$zip_dir/module.prop" || return 1
  exists_file "$zip_dir/customize.sh" || true
  exists_file "$zip_dir/README.md" || true
  exists_file "$zip_dir/CHANGELOG.md" || true
  exists_file "$zip_dir/RELEASE_NOTES_v1.5.1-universal.1.md" || true
  exists_file "$zip_dir/tools/status-lib.sh" || true
  exists_file "$zip_dir/tools/verify-evidence-scope.sh" || true

  version_scope_check zip "$zip_dir/module.prop"
  grep_file '(Release|Prerelease): [$]MODULE_VERSION' "$zip_dir/customize.sh" "zip_installer_release_wording" || true
  grep_file 'Stable channel: 1\.5\.1' "$zip_dir/customize.sh" "zip_installer_stable_channel_151" || true
  grep_file 'Runtime-proven on .*mustang' "$zip_dir/README.md" "zip_readme_honest_mustang" || true
  grep_file 'Factory-basis covered for all G5 Pixel 10 devices' "$zip_dir/README.md" "zip_readme_factory_basis_all_g5" || true

  if grep -R "CP31.260608.007.*current QPR1 basis" -n "$zip_dir/README.md" "$zip_dir/CHANGELOG.md" "$zip_dir/RELEASE_NOTES_v1.5.1-universal.1.md" "$zip_dir/docs" 2>/dev/null | grep -v "Do not advertise"; then
    say "FAIL zip_stale_current_basis_claim"
    return 2
  fi
  say "PASS zip_no_stale_current_basis_claim"

  say "RESULT: VERIFY_EVIDENCE_SCOPE_ZIP_DONE"
}

case "$mode" in
  runtime) runtime_mode ;;
  repo) repo_mode ;;
  zip) zip_mode ;;
  *)
    say "Usage: $0 runtime [module_path]"
    say "       $0 repo [repo_path]"
    say "       $0 zip [unzipped_zip_dir]"
    exit 64
    ;;
esac
