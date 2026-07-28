#!/usr/bin/env bash
set -euo pipefail
umask 077

for name in \
  REPOSITORY TARGET_COMMIT TAG_NAME RELEASE_TITLE RELEASE_KIND \
  ASSET_NAME ASSET_SHA256 ASSET_BYTES ASSET_ENTRIES \
  ARTIFACT_RUN_ID ARTIFACT_ID ARTIFACT_NAME ARTIFACT_DIGEST ARTIFACT_HEAD_SHA \
  VERSION VERSION_CODE NOTES_REF NOTES_PATH POST_PUBLISH_PR; do
  [[ -n "${!name:-}" ]] || {
    printf 'FAILED: required_coordinate_missing name=%s\n' "$name"
    exit 2
  }
done

STATUS_FILE="release-proof/alpha3-dev8-publication-status.txt"
mkdir -p "${STATUS_FILE%/*}"
: > "$STATUS_FILE"
STAGE=init
CREATED_RELEASE_ID=""
PUBLISHED=0

record() {
  printf '%s\n' "$*" | tee -a "$STATUS_FILE"
}

cleanup() {
  rc="$?"
  trap - EXIT
  if [[ "$rc" -ne 0 ]]; then
    if [[ -n "$CREATED_RELEASE_ID" && "$PUBLISHED" -eq 0 ]]; then
      gh api --method DELETE "repos/$REPOSITORY/releases/$CREATED_RELEASE_ID" >/dev/null 2>&1 || true
      if gh api "repos/$REPOSITORY/git/ref/tags/$TAG_NAME" >/dev/null 2>&1; then
        gh api --method DELETE "repos/$REPOSITORY/git/refs/tags/$TAG_NAME" >/dev/null 2>&1 || true
      fi
      record 'rollback=prepublish_draft_and_tag_cleanup_attempted'
    fi
    record "publish_stage=$STAGE"
    record 'outcome=failure'
    record "workflow_exit_code=$rc"
    record "RESULT: PIXEL_THERMAL_DEV8_PRERELEASE_PUBLISH_DONE outcome=failure workflow_exit_code=$rc"
  fi
  exit "$rc"
}
trap cleanup EXIT

record 'schema=pixel-thermal-dev8-prerelease-publication-v3'
record "repository=$REPOSITORY"
record "target_commit=$TARGET_COMMIT"
record "tag=$TAG_NAME"
record "release_title=$RELEASE_TITLE"
record "release_kind=$RELEASE_KIND"
record "asset_name=$ASSET_NAME"
record "asset_sha256_expected=$ASSET_SHA256"
record "asset_bytes_expected=$ASSET_BYTES"
record "asset_entries_expected=$ASSET_ENTRIES"
record "artifact_run_id=$ARTIFACT_RUN_ID"
record "artifact_id=$ARTIFACT_ID"
record "artifact_name=$ARTIFACT_NAME"
record "artifact_digest=$ARTIFACT_DIGEST"
record "artifact_head_sha=$ARTIFACT_HEAD_SHA"
record "version=$VERSION"
record "version_code=$VERSION_CODE"
record "notes_ref=$NOTES_REF"
record "notes_path=$NOTES_PATH"
record "post_publish_pr=$POST_PUBLISH_PR"

STAGE=preflight
record "phase=$STAGE"
test "$RELEASE_KIND" = prerelease
test "$GITHUB_REPOSITORY" = "$REPOSITORY"
gh auth status --hostname github.com >/dev/null
test "$(gh api "repos/$REPOSITORY" --jq .full_name)" = "$REPOSITORY"
git cat-file -e "$TARGET_COMMIT^{commit}"
git cat-file -e "$NOTES_REF^{commit}"

artifact_dir="$RUNNER_TEMP/release-artifact"
artifact_json="$RUNNER_TEMP/artifact.json"
asset_path="$artifact_dir/$ASSET_NAME"
notes_file="$RUNNER_TEMP/release-notes.md"
verify_script="$RUNNER_TEMP/verify-release-module.sh"
release_json="$RUNNER_TEMP/release.json"
asset_json="$RUNNER_TEMP/asset.json"
release_body="$RUNNER_TEMP/release-body.md"
tag_json="$RUNNER_TEMP/tag.json"
downloaded_asset="$RUNNER_TEMP/public-$ASSET_NAME"

STAGE=artifact_metadata_verify
record "phase=$STAGE"
gh api "repos/$REPOSITORY/actions/artifacts/$ARTIFACT_ID" > "$artifact_json"
test "$(jq -r .name "$artifact_json")" = "$ARTIFACT_NAME"
test "$(jq -r .expired "$artifact_json")" = false
test "$(jq -r .workflow_run.id "$artifact_json")" = "$ARTIFACT_RUN_ID"
test "$(jq -r .workflow_run.head_sha "$artifact_json")" = "$ARTIFACT_HEAD_SHA"
test "$(jq -r .digest "$artifact_json")" = "$ARTIFACT_DIGEST"

STAGE=artifact_download_and_package_verify
record "phase=$STAGE"
rm -rf "$artifact_dir"
mkdir -p "$artifact_dir"
gh run download "$ARTIFACT_RUN_ID" --repo "$REPOSITORY" --name "$ARTIFACT_NAME" --dir "$artifact_dir"
test -s "$asset_path"
git show "$TARGET_COMMIT:dev_tools/verify-release-module.sh" > "$verify_script"
bash "$verify_script" "$asset_path"
test "$(sha256sum "$asset_path" | awk '{print $1}')" = "$ASSET_SHA256"
test "$(wc -c < "$asset_path" | tr -d ' ')" = "$ASSET_BYTES"
test "$(unzip -Z1 "$asset_path" | wc -l | tr -d ' ')" = "$ASSET_ENTRIES"
test "$(unzip -p "$asset_path" module.prop | sed -n 's/^version=//p' | head -n 1)" = "$VERSION"
test "$(unzip -p "$asset_path" module.prop | sed -n 's/^versionCode=//p' | head -n 1)" = "$VERSION_CODE"
record 'package_verification=pass'

STAGE=notes_and_channel_boundary
record "phase=$STAGE"
git show "$NOTES_REF:$NOTES_PATH" > "$notes_file"
test -s "$notes_file"
grep -Fq '# 2.0.0 Alpha 3 Dev 8' "$notes_file"
grep -Fq 'This public prerelease supersedes Dev.6 on the prerelease update channel.' "$notes_file"
stable_before="$(git show "$TARGET_COMMIT:update.json" | sha256sum | awk '{print $1}')"
prerelease_before="$(git show "$TARGET_COMMIT:update-prerelease.json" | jq -r .version)"
test "$prerelease_before" = '2.0.0-alpha.3-dev.6'

STAGE=collision_check
record "phase=$STAGE"
release_exists=0
tag_exists=0
if gh api "repos/$REPOSITORY/releases/tags/$TAG_NAME" > "$release_json" 2>/dev/null; then release_exists=1; fi
if gh api "repos/$REPOSITORY/git/ref/tags/$TAG_NAME" > "$tag_json" 2>/dev/null; then tag_exists=1; fi
drafts="$(gh api "repos/$REPOSITORY/releases?per_page=100" | jq --arg tag "$TAG_NAME" '[.[] | select(.tag_name == $tag and .draft == true)] | length')"
test "$release_exists" -eq 0
test "$tag_exists" -eq 0
test "$drafts" -eq 0
record 'collision=absent'

STAGE=draft_create
record "phase=$STAGE"
jq -n \
  --arg tag "$TAG_NAME" \
  --arg target "$TARGET_COMMIT" \
  --arg name "$RELEASE_TITLE" \
  --rawfile body "$notes_file" \
  '{tag_name:$tag,target_commitish:$target,name:$name,body:$body,draft:true,prerelease:true}' \
  > "$RUNNER_TEMP/create-release.json"
gh api --method POST "repos/$REPOSITORY/releases" --input "$RUNNER_TEMP/create-release.json" > "$release_json"
CREATED_RELEASE_ID="$(jq -r .id "$release_json")"
test -n "$CREATED_RELEASE_ID"
test "$CREATED_RELEASE_ID" != null

STAGE=asset_upload
record "phase=$STAGE"
upload_base="$(jq -r .upload_url "$release_json" | sed 's/{?name,label}$//')"
curl --fail --silent --show-error --request POST \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H 'Accept: application/vnd.github+json' \
  -H 'Content-Type: application/zip' \
  --data-binary "@$asset_path" \
  "$upload_base?name=$ASSET_NAME" > "$asset_json"
test "$(jq -r .name "$asset_json")" = "$ASSET_NAME"
test "$(jq -r .size "$asset_json")" = "$ASSET_BYTES"

STAGE=draft_verify
record "phase=$STAGE"
gh api "repos/$REPOSITORY/releases/$CREATED_RELEASE_ID" > "$release_json"
test "$(jq -r .draft "$release_json")" = true
test "$(jq -r .prerelease "$release_json")" = true
test "$(jq -r .tag_name "$release_json")" = "$TAG_NAME"
test "$(jq -r .name "$release_json")" = "$RELEASE_TITLE"
test "$(jq -r .target_commitish "$release_json")" = "$TARGET_COMMIT"
test "$(jq '[.assets[] | select(.name == env.ASSET_NAME)] | length' "$release_json")" = 1
test "$(jq -r '.assets[] | select(.name == env.ASSET_NAME) | .size' "$release_json")" = "$ASSET_BYTES"
jq -j .body "$release_json" > "$release_body"
cmp -s "$notes_file" "$release_body"
record 'draft_verification=pass'

STAGE=publish
record "phase=$STAGE"
jq -n --arg name "$RELEASE_TITLE" --rawfile body "$notes_file" \
  '{draft:false,prerelease:true,name:$name,body:$body}' > "$RUNNER_TEMP/publish-release.json"
gh api --method PATCH "repos/$REPOSITORY/releases/$CREATED_RELEASE_ID" \
  --input "$RUNNER_TEMP/publish-release.json" > "$release_json"
PUBLISHED=1

STAGE=public_verify
record "phase=$STAGE"
gh api "repos/$REPOSITORY/releases/tags/$TAG_NAME" > "$release_json"
test "$(jq -r .draft "$release_json")" = false
test "$(jq -r .prerelease "$release_json")" = true
test "$(jq -r .tag_name "$release_json")" = "$TAG_NAME"
test "$(jq -r .name "$release_json")" = "$RELEASE_TITLE"
test "$(jq '[.assets[] | select(.name == env.ASSET_NAME)] | length' "$release_json")" = 1
test "$(jq -r '.assets[] | select(.name == env.ASSET_NAME) | .size' "$release_json")" = "$ASSET_BYTES"
gh api "repos/$REPOSITORY/git/ref/tags/$TAG_NAME" > "$tag_json"
test "$(jq -r .object.sha "$tag_json")" = "$TARGET_COMMIT"
jq -j .body "$release_json" > "$release_body"
cmp -s "$notes_file" "$release_body"
public_url="$(jq -r '.assets[] | select(.name == env.ASSET_NAME) | .browser_download_url' "$release_json")"
test -n "$public_url"
env -u GH_TOKEN -u GITHUB_TOKEN curl --fail --location --retry 3 --output "$downloaded_asset" "$public_url"
public_sha256="$(sha256sum "$downloaded_asset" | awk '{print $1}')"
public_bytes="$(wc -c < "$downloaded_asset" | tr -d ' ')"
test "$public_sha256" = "$ASSET_SHA256"
test "$public_bytes" = "$ASSET_BYTES"

git fetch origin v2 >/dev/null
stable_after="$(git show origin/v2:update.json | sha256sum | awk '{print $1}')"
prerelease_after="$(git show origin/v2:update-prerelease.json | jq -r .version)"
test "$stable_after" = "$stable_before"
test "$prerelease_after" = '2.0.0-alpha.3-dev.6'

STAGE=success
record 'public_verification=pass'
record "release_url=$(jq -r .html_url "$release_json")"
record "tag_target=$(jq -r .object.sha "$tag_json")"
record "asset_sha256_public=$public_sha256"
record "asset_bytes_public=$public_bytes"
record "stable_channel_sha256=$stable_after"
record "prerelease_channel_before_merge=$prerelease_after"
record 'outcome=success'
record 'workflow_exit_code=0'
record 'RESULT: PIXEL_THERMAL_DEV8_PRERELEASE_PUBLISH_DONE outcome=success workflow_exit_code=0'
trap - EXIT
