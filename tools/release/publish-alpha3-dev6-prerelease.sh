#!/usr/bin/env bash
set -euo pipefail
umask 077

ARTIFACT_RUN_ID="${ARTIFACT_RUN_ID:-30273152148}"
ARTIFACT_NAME="${ARTIFACT_NAME:-pixel-thermal-alpha3-next-de9d0e2626e29c2d702bcc9b0295081d6667f392}"
STAGE_FILE="$RUNNER_TEMP/publish-stage.txt"
stage() {
  printf '%s\n' "$1" > "$STAGE_FILE"
}

created_release=0
published_release=0
cleanup() {
  rc="$?"
  trap - EXIT
  if [[ "$rc" -ne 0 && "$created_release" -eq 1 && "$published_release" -eq 0 ]]; then
    gh release delete "$TAG_NAME" --repo "$REPOSITORY" --yes --cleanup-tag >/dev/null 2>&1 || true
    printf '%s\n' 'ROLLBACK prepublish_draft_and_tag_cleanup_attempted'
  fi
  exit "$rc"
}
trap cleanup EXIT

required=(
  REPOSITORY TARGET_COMMIT TAG_NAME RELEASE_TITLE RELEASE_KIND ASSET_NAME
  ASSET_SHA256 ASSET_BYTES ASSET_ENTRIES VERSION VERSION_CODE NOTES_REF
  NOTES_PATH POST_PUBLISH_PR RUNNER_TEMP GITHUB_REPOSITORY
)
for name in "${required[@]}"; do
  test -n "${!name:-}"
done

stage preflight_auth
test "$GITHUB_REPOSITORY" = "$REPOSITORY"
gh auth status --hostname github.com >/dev/null
test "$(gh api "repos/$REPOSITORY" --jq .full_name)" = "$REPOSITORY"
git cat-file -e "$TARGET_COMMIT^{commit}"
git cat-file -e "$NOTES_REF^{commit}"

artifact_dir="$RUNNER_TEMP/dev6-ci-artifact"
asset_path="$RUNNER_TEMP/$ASSET_NAME"
notes_file="$RUNNER_TEMP/release-notes.md"
release_json="$RUNNER_TEMP/release.json"
release_body="$RUNNER_TEMP/release-body.md"
downloaded_asset="$RUNNER_TEMP/public-$ASSET_NAME"
proof_file="$RUNNER_TEMP/publication-proof.txt"
tag_json="$RUNNER_TEMP/tag-ref.json"
run_json="$RUNNER_TEMP/artifact-run.json"

rm -rf "$artifact_dir" "$asset_path" "$notes_file" "$release_json" "$release_body" "$downloaded_asset" "$proof_file" "$tag_json" "$run_json"
mkdir -p "$artifact_dir"

stage artifact_run_verify
gh api "repos/$REPOSITORY/actions/runs/$ARTIFACT_RUN_ID" > "$run_json"
test "$(jq -r .head_sha "$run_json")" = "$TARGET_COMMIT"
test "$(jq -r .status "$run_json")" = completed
test "$(jq -r .conclusion "$run_json")" = success

stage artifact_download
gh run download "$ARTIFACT_RUN_ID" --repo "$REPOSITORY" --name "$ARTIFACT_NAME" --dir "$artifact_dir"
test -f "$artifact_dir/$ASSET_NAME"
install -m 0600 "$artifact_dir/$ASSET_NAME" "$asset_path"

stage notes_verify
git show "$NOTES_REF:$NOTES_PATH" > "$notes_file"
test -s "$notes_file"
grep -Fq '# 2.0.0 Alpha 3 Dev 6' "$notes_file"
grep -Fq "$ASSET_SHA256" "$notes_file"
grep -Fq "$TARGET_COMMIT" "$notes_file"

stage asset_verify
test "$(sha256sum "$asset_path" | awk '{print $1}')" = "$ASSET_SHA256"
test "$(wc -c < "$asset_path" | tr -d ' ')" = "$ASSET_BYTES"
test "$(unzip -Z1 "$asset_path" | wc -l | tr -d ' ')" = "$ASSET_ENTRIES"
test "$(unzip -p "$asset_path" module.prop | sed -n 's/^version=//p' | head -n 1)" = "$VERSION"
test "$(unzip -p "$asset_path" module.prop | sed -n 's/^versionCode=//p' | head -n 1)" = "$VERSION_CODE"

stable_before="$(git show "$NOTES_REF:update.json" | sha256sum | awk '{print $1}')"
prerelease_before="$(git show "$NOTES_REF:update-prerelease.json" | jq -r .version)"
test "$prerelease_before" = '2.0.0-alpha.3-dev.2'

stage collision_check
release_exists=0
tag_exists=0
if gh api "repos/$REPOSITORY/releases/tags/$TAG_NAME" > "$release_json" 2>/dev/null; then
  release_exists=1
fi
if gh api "repos/$REPOSITORY/git/ref/tags/$TAG_NAME" > "$tag_json" 2>/dev/null; then
  tag_exists=1
fi

if [[ "$release_exists" -eq 1 || "$tag_exists" -eq 1 ]]; then
  stage existing_public_verify
  test "$release_exists" -eq 1
  test "$tag_exists" -eq 1
  test "$(jq -r .draft "$release_json")" = false
  test "$(jq -r .prerelease "$release_json")" = true
  test "$(jq -r .tag_name "$release_json")" = "$TAG_NAME"
  test "$(jq -r .name "$release_json")" = "$RELEASE_TITLE"
  test "$(jq -r .object.sha "$tag_json")" = "$TARGET_COMMIT"
else
  stage draft_create
  gh release create "$TAG_NAME" "$asset_path#$ASSET_NAME" --repo "$REPOSITORY" --target "$TARGET_COMMIT" --title "$RELEASE_TITLE" --notes-file "$notes_file" --prerelease --draft
  created_release=1

  stage draft_verify
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

  stage publish
  release_id="$(jq -r .id "$release_json")"
  jq -n --arg name "$RELEASE_TITLE" --rawfile body "$notes_file" '{draft:false, prerelease:true, name:$name, body:$body}' > "$RUNNER_TEMP/publish.json"
  gh api --method PATCH "repos/$REPOSITORY/releases/$release_id" --input "$RUNNER_TEMP/publish.json" > "$release_json"
  published_release=1
fi

stage public_metadata_verify
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

stage public_download_verify
public_url="$(jq -r '.assets[] | select(.name == env.ASSET_NAME) | .browser_download_url' "$release_json")"
test -n "$public_url"
curl --fail --location --retry 3 --output "$downloaded_asset" "$public_url"
test "$(sha256sum "$downloaded_asset" | awk '{print $1}')" = "$ASSET_SHA256"
test "$(wc -c < "$downloaded_asset" | tr -d ' ')" = "$ASSET_BYTES"

stage channel_boundary_verify
git fetch origin v2 >/dev/null
stable_after="$(git show origin/v2:update.json | sha256sum | awk '{print $1}')"
test "$stable_after" = "$stable_before"
prerelease_after="$(git show origin/v2:update-prerelease.json | jq -r .version)"
test "$prerelease_after" = '2.0.0-alpha.3-dev.2'

stage proof_write
release_url="$(jq -r .html_url "$release_json")"
{
  printf 'repository_full_name=%s\n' "$REPOSITORY"
  printf 'release_url=%s\n' "$release_url"
  printf 'tag_name=%s\n' "$TAG_NAME"
  printf 'target_commit_sha=%s\n' "$TARGET_COMMIT"
  printf 'release_title=%s\n' "$RELEASE_TITLE"
  printf 'release_kind=%s\n' "$RELEASE_KIND"
  printf 'asset_name=%s\n' "$ASSET_NAME"
  printf 'asset_sha256=%s\n' "$ASSET_SHA256"
  printf 'asset_bytes=%s\n' "$ASSET_BYTES"
  printf 'version=%s\n' "$VERSION"
  printf 'version_code=%s\n' "$VERSION_CODE"
  printf 'release_notes_ref=%s\n' "$NOTES_REF"
  printf 'release_notes_path=%s\n' "$NOTES_PATH"
  printf 'stable_channel_sha256=%s\n' "$stable_after"
  printf 'prerelease_channel_before_merge=%s\n' "$prerelease_after"
  printf 'post_publish_pr=%s\n' "$POST_PUBLISH_PR"
  printf '%s\n' 'public_download_hash=PASS'
  printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV6_PRERELEASE_PUBLISH_DONE outcome=success workflow_exit_code=0'
} | tee "$proof_file"

stage success
trap - EXIT
