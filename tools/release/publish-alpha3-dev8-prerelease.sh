#!/usr/bin/env bash
set -euo pipefail
umask 077

: "${REPOSITORY:?}"
: "${TARGET_COMMIT:?}"
: "${TAG_NAME:?}"
: "${RELEASE_TITLE:?}"
: "${RELEASE_KIND:?}"
: "${ASSET_NAME:?}"
: "${ASSET_SHA256:?}"
: "${ASSET_BYTES:?}"
: "${ASSET_ENTRIES:?}"
: "${VERSION:?}"
: "${VERSION_CODE:?}"
: "${NOTES_REF:?}"
: "${NOTES_PATH:?}"
: "${POST_PUBLISH_PR:?}"

STATUS_FILE="release-proof/alpha3-dev8-publication-status.txt"
mkdir -p "${STATUS_FILE%/*}"
: > "$STATUS_FILE"
created_release=0
published_release=0

record() {
  printf '%s\n' "$*" | tee -a "$STATUS_FILE"
}

cleanup() {
  rc="$?"
  if [[ "$rc" -ne 0 ]]; then
    if [[ "$created_release" -eq 1 && "$published_release" -eq 0 ]]; then
      gh release delete "$TAG_NAME" --repo "$REPOSITORY" --yes --cleanup-tag >/dev/null 2>&1 || true
      record "rollback=prepublish_draft_and_tag_cleanup_attempted"
    fi
    record "outcome=failure"
    record "workflow_exit_code=$rc"
    record "RESULT: PIXEL_THERMAL_DEV8_PRERELEASE_PUBLISH_DONE outcome=failure workflow_exit_code=$rc"
  fi
}
trap cleanup EXIT

record "schema=pixel-thermal-dev8-prerelease-publication-v1"
record "repository=$REPOSITORY"
record "target_commit=$TARGET_COMMIT"
record "tag=$TAG_NAME"
record "release_title=$RELEASE_TITLE"
record "release_kind=$RELEASE_KIND"
record "asset_name=$ASSET_NAME"
record "asset_sha256_expected=$ASSET_SHA256"
record "asset_bytes_expected=$ASSET_BYTES"
record "asset_entries_expected=$ASSET_ENTRIES"
record "version=$VERSION"
record "version_code=$VERSION_CODE"
record "notes_ref=$NOTES_REF"
record "notes_path=$NOTES_PATH"
record "post_publish_pr=$POST_PUBLISH_PR"

record 'phase=preflight'
test "$RELEASE_KIND" = prerelease
test "$GITHUB_REPOSITORY" = "$REPOSITORY"
gh auth status --hostname github.com >/dev/null
test "$(gh api "repos/$REPOSITORY" --jq .full_name)" = "$REPOSITORY"
git cat-file -e "$TARGET_COMMIT^{commit}"
git cat-file -e "$NOTES_REF^{commit}"

source_dir="${RUNNER_WORKSPACE:-${GITHUB_WORKSPACE%/*}}/pixel-thermal-dev8-release-source"
asset_path="$RUNNER_TEMP/$ASSET_NAME"
notes_file="$RUNNER_TEMP/release-notes.md"
release_json="$RUNNER_TEMP/release.json"
release_body="$RUNNER_TEMP/release-body.md"
tag_json="$RUNNER_TEMP/tag.json"
downloaded_asset="$RUNNER_TEMP/public-$ASSET_NAME"

record 'phase=source_and_notes'
rm -rf "$source_dir"
git worktree add --detach "$source_dir" "$TARGET_COMMIT" >/dev/null
git show "$NOTES_REF:$NOTES_PATH" > "$notes_file"
test -s "$notes_file"
grep -Fq '# 2.0.0 Alpha 3 Dev 8' "$notes_file"
grep -Fq 'This public prerelease supersedes Dev.6 on the prerelease update channel.' "$notes_file"

record 'phase=build_and_verify'
chmod +x "$source_dir/dev_tools/build-release-module.sh" "$source_dir/dev_tools/verify-release-module.sh"
(
  cd "$source_dir"
  bash dev_tools/build-release-module.sh "$asset_path"
)
bash "$source_dir/dev_tools/verify-release-module.sh" "$asset_path"

test "$(sha256sum "$asset_path" | awk '{print $1}')" = "$ASSET_SHA256"
test "$(wc -c < "$asset_path" | tr -d ' ')" = "$ASSET_BYTES"
test "$(unzip -Z1 "$asset_path" | wc -l | tr -d ' ')" = "$ASSET_ENTRIES"
test "$(unzip -p "$asset_path" module.prop | sed -n 's/^version=//p' | head -n 1)" = "$VERSION"
test "$(unzip -p "$asset_path" module.prop | sed -n 's/^versionCode=//p' | head -n 1)" = "$VERSION_CODE"

record 'phase=channel_boundary_preflight'
stable_before="$(git show "$TARGET_COMMIT:update.json" | sha256sum | awk '{print $1}')"
prerelease_before="$(git show "$TARGET_COMMIT:update-prerelease.json" | jq -r .version)"
test "$prerelease_before" = '2.0.0-alpha.3-dev.6'

record 'phase=collision_check'
if gh api "repos/$REPOSITORY/releases/tags/$TAG_NAME" >/dev/null 2>&1; then
  record 'collision=release_exists'
  exit 40
fi
if gh api "repos/$REPOSITORY/git/ref/tags/$TAG_NAME" >/dev/null 2>&1; then
  record 'collision=tag_exists'
  exit 41
fi
record 'collision=absent'

record 'phase=create_draft'
gh release create "$TAG_NAME" "$asset_path#$ASSET_NAME" \
  --repo "$REPOSITORY" \
  --target "$TARGET_COMMIT" \
  --title "$RELEASE_TITLE" \
  --notes-file "$notes_file" \
  --prerelease \
  --draft
created_release=1

record 'phase=verify_draft'
gh api "repos/$REPOSITORY/releases/tags/$TAG_NAME" > "$release_json"
test "$(jq -r .draft "$release_json")" = true
test "$(jq -r .prerelease "$release_json")" = true
test "$(jq -r .tag_name "$release_json")" = "$TAG_NAME"
test "$(jq -r .name "$release_json")" = "$RELEASE_TITLE"
test "$(jq -r .target_commitish "$release_json")" = "$TARGET_COMMIT"
test "$(jq '[.assets[] | select(.name == env.ASSET_NAME)] | length' "$release_json")" = 1
test "$(jq -r '.assets[] | select(.name == env.ASSET_NAME) | .size' "$release_json")" = "$ASSET_BYTES"
gh api "repos/$REPOSITORY/releases/tags/$TAG_NAME" --jq .body > "$release_body"
cmp -s "$notes_file" "$release_body"
gh api "repos/$REPOSITORY/git/ref/tags/$TAG_NAME" > "$tag_json"
test "$(jq -r .object.sha "$tag_json")" = "$TARGET_COMMIT"
record 'draft_verification=pass'

record 'phase=publish'
release_id="$(jq -r .id "$release_json")"
jq -n --arg name "$RELEASE_TITLE" --rawfile body "$notes_file" \
  '{draft:false, prerelease:true, name:$name, body:$body}' > "$RUNNER_TEMP/publish.json"
gh api --method PATCH "repos/$REPOSITORY/releases/$release_id" \
  --input "$RUNNER_TEMP/publish.json" > "$release_json"
published_release=1

record 'phase=public_metadata_verify'
gh api "repos/$REPOSITORY/releases/tags/$TAG_NAME" > "$release_json"
test "$(jq -r .draft "$release_json")" = false
test "$(jq -r .prerelease "$release_json")" = true
test "$(jq -r .tag_name "$release_json")" = "$TAG_NAME"
test "$(jq -r .name "$release_json")" = "$RELEASE_TITLE"
test "$(jq '[.assets[] | select(.name == env.ASSET_NAME)] | length' "$release_json")" = 1
test "$(jq -r '.assets[] | select(.name == env.ASSET_NAME) | .size' "$release_json")" = "$ASSET_BYTES"
gh api "repos/$REPOSITORY/git/ref/tags/$TAG_NAME" > "$tag_json"
test "$(jq -r .object.sha "$tag_json")" = "$TARGET_COMMIT"
gh api "repos/$REPOSITORY/releases/tags/$TAG_NAME" --jq .body > "$release_body"
cmp -s "$notes_file" "$release_body"

record 'phase=public_download_verify'
public_url="$(jq -r '.assets[] | select(.name == env.ASSET_NAME) | .browser_download_url' "$release_json")"
test -n "$public_url"
env -u GH_TOKEN -u GITHUB_TOKEN curl --fail --location --retry 3 --output "$downloaded_asset" "$public_url"
public_sha256="$(sha256sum "$downloaded_asset" | awk '{print $1}')"
public_bytes="$(wc -c < "$downloaded_asset" | tr -d ' ')"
test "$public_sha256" = "$ASSET_SHA256"
test "$public_bytes" = "$ASSET_BYTES"

record 'phase=channel_boundary_postverify'
git fetch origin v2 >/dev/null
stable_after="$(git show origin/v2:update.json | sha256sum | awk '{print $1}')"
prerelease_after="$(git show origin/v2:update-prerelease.json | jq -r .version)"
test "$stable_after" = "$stable_before"
test "$prerelease_after" = '2.0.0-alpha.3-dev.6'

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
