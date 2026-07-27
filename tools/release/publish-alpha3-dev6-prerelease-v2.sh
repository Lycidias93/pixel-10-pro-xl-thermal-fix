#!/usr/bin/env bash
set -euo pipefail
umask 077

ARTIFACT_RUN_ID=30273152148
ARTIFACT_NAME=pixel-thermal-alpha3-next-de9d0e2626e29c2d702bcc9b0295081d6667f392
STATUS_DIR="$GITHUB_WORKSPACE/release-proof"
STATUS_FILE="$STATUS_DIR/alpha3-dev6-publication-status.txt"
STAGE=init
CREATED_RELEASE_ID=""
PUBLISHED=0
mkdir -p "$STATUS_DIR"

release_json="$RUNNER_TEMP/release-v2.json"
releases_json="$RUNNER_TEMP/releases-v2.json"
tag_json="$RUNNER_TEMP/tag-v2.json"
notes_file="$RUNNER_TEMP/notes-v2.md"
body_file="$RUNNER_TEMP/body-v2.md"
asset_dir="$RUNNER_TEMP/artifact-v2"
asset_path="$RUNNER_TEMP/$ASSET_NAME"
public_asset="$RUNNER_TEMP/public-$ASSET_NAME"
run_json="$RUNNER_TEMP/run-v2.json"

fetch_release() {
  gh api "repos/$REPOSITORY/releases?per_page=100" > "$releases_json"
  local count
  count="$(jq --arg tag "$TAG_NAME" '[.[] | select(.tag_name == $tag)] | length' "$releases_json")"
  test "$count" -le 1
  if [[ "$count" -eq 1 ]]; then
    jq --arg tag "$TAG_NAME" '.[] | select(.tag_name == $tag)' "$releases_json" > "$release_json"
    return 0
  fi
  : > "$release_json"
  return 1
}

write_status() {
  local outcome="$1"
  local workflow_rc="$2"
  set +e
  local release_found=no tag_found=no
  local release_url=unavailable release_draft=unavailable release_prerelease=unavailable
  local release_name=unavailable release_tag=unavailable tag_sha=unavailable
  local asset_count=0 asset_bytes=unavailable body_match=unavailable
  local public_sha=unavailable public_bytes=unavailable
  local stable_match=unavailable prerelease_version=unavailable

  if fetch_release; then
    release_found=yes
    release_url="$(jq -r .html_url "$release_json")"
    release_draft="$(jq -r .draft "$release_json")"
    release_prerelease="$(jq -r .prerelease "$release_json")"
    release_name="$(jq -r .name "$release_json")"
    release_tag="$(jq -r .tag_name "$release_json")"
    asset_count="$(jq '[.assets[] | select(.name == env.ASSET_NAME)] | length' "$release_json")"
    asset_bytes="$(jq -r '.assets[] | select(.name == env.ASSET_NAME) | .size' "$release_json" 2>/dev/null || printf unavailable)"
    if [[ -s "$notes_file" ]]; then
      jq -j .body "$release_json" > "$body_file"
      if cmp -s "$notes_file" "$body_file"; then body_match=PASS; else body_match=FAIL; fi
    fi
    if [[ "$release_draft" = false && "$asset_count" = 1 ]]; then
      local url
      url="$(jq -r '.assets[] | select(.name == env.ASSET_NAME) | .browser_download_url' "$release_json")"
      if curl --fail --location --retry 3 --output "$public_asset" "$url" >/dev/null 2>&1; then
        public_sha="$(sha256sum "$public_asset" | awk '{print $1}')"
        public_bytes="$(wc -c < "$public_asset" | tr -d ' ')"
      fi
    fi
  fi
  if gh api "repos/$REPOSITORY/git/ref/tags/$TAG_NAME" > "$tag_json" 2>/dev/null; then
    tag_found=yes
    tag_sha="$(jq -r .object.sha "$tag_json")"
  fi
  git fetch origin v2 >/dev/null 2>&1
  local stable_expected stable_actual
  stable_expected="$(git show "$NOTES_REF:update.json" | sha256sum | awk '{print $1}')"
  stable_actual="$(git show origin/v2:update.json | sha256sum | awk '{print $1}')"
  if [[ "$stable_expected" = "$stable_actual" ]]; then stable_match=PASS; else stable_match=FAIL; fi
  prerelease_version="$(git show origin/v2:update-prerelease.json | jq -r .version)"

  {
    printf 'workflow_rc=%s\n' "$workflow_rc"
    printf 'publish_stage=%s\n' "$STAGE"
    printf 'release_found=%s\n' "$release_found"
    printf 'tag_found=%s\n' "$tag_found"
    printf 'release_url=%s\n' "$release_url"
    printf 'release_draft=%s\n' "$release_draft"
    printf 'release_prerelease=%s\n' "$release_prerelease"
    printf 'release_name=%s\n' "$release_name"
    printf 'release_tag=%s\n' "$release_tag"
    printf 'tag_sha=%s\n' "$tag_sha"
    printf 'asset_count=%s\n' "$asset_count"
    printf 'asset_bytes=%s\n' "$asset_bytes"
    printf 'body_match=%s\n' "$body_match"
    printf 'public_download_sha256=%s\n' "$public_sha"
    printf 'public_download_bytes=%s\n' "$public_bytes"
    printf 'stable_channel_match=%s\n' "$stable_match"
    printf 'prerelease_channel_before_merge=%s\n' "$prerelease_version"
    printf 'post_publish_pr=%s\n' "$POST_PUBLISH_PR"
    if [[ "$outcome" = success ]]; then
      printf '%s\n' 'public_download_hash=PASS'
      printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV6_PRERELEASE_PUBLISH_DONE outcome=success workflow_exit_code=0'
    else
      printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV6_PRERELEASE_PUBLISH_STOP outcome=failure workflow_exit_code=1'
    fi
  } > "$STATUS_FILE"
  set -e
}

cleanup() {
  local rc="$?"
  trap - EXIT
  if [[ "$rc" -ne 0 && -n "$CREATED_RELEASE_ID" && "$PUBLISHED" -eq 0 ]]; then
    gh api --method DELETE "repos/$REPOSITORY/releases/$CREATED_RELEASE_ID" >/dev/null 2>&1 || true
    if gh api "repos/$REPOSITORY/git/ref/tags/$TAG_NAME" >/dev/null 2>&1; then
      gh api --method DELETE "repos/$REPOSITORY/git/refs/tags/$TAG_NAME" >/dev/null 2>&1 || true
    fi
  fi
  if [[ "$rc" -eq 0 ]]; then write_status success 0; else write_status failure "$rc"; fi
  exit "$rc"
}
trap cleanup EXIT

STAGE=preflight
test "$GITHUB_REPOSITORY" = "$REPOSITORY"
gh auth status --hostname github.com >/dev/null
test "$(gh api "repos/$REPOSITORY" --jq .full_name)" = "$REPOSITORY"
git cat-file -e "$TARGET_COMMIT^{commit}"
git cat-file -e "$NOTES_REF^{commit}"

STAGE=artifact
rm -rf "$asset_dir" "$asset_path" "$public_asset"
mkdir -p "$asset_dir"
gh api "repos/$REPOSITORY/actions/runs/$ARTIFACT_RUN_ID" > "$run_json"
test "$(jq -r .head_sha "$run_json")" = "$TARGET_COMMIT"
test "$(jq -r .conclusion "$run_json")" = success
gh run download "$ARTIFACT_RUN_ID" --repo "$REPOSITORY" --name "$ARTIFACT_NAME" --dir "$asset_dir"
install -m 0600 "$asset_dir/$ASSET_NAME" "$asset_path"

test "$(sha256sum "$asset_path" | awk '{print $1}')" = "$ASSET_SHA256"
test "$(wc -c < "$asset_path" | tr -d ' ')" = "$ASSET_BYTES"
test "$(unzip -Z1 "$asset_path" | wc -l | tr -d ' ')" = "$ASSET_ENTRIES"
test "$(unzip -p "$asset_path" module.prop | sed -n 's/^version=//p' | head -n 1)" = "$VERSION"
test "$(unzip -p "$asset_path" module.prop | sed -n 's/^versionCode=//p' | head -n 1)" = "$VERSION_CODE"

STAGE=notes
git show "$NOTES_REF:$NOTES_PATH" > "$notes_file"
grep -Fq "$ASSET_SHA256" "$notes_file"
grep -Fq "$TARGET_COMMIT" "$notes_file"

STAGE=channel_preflight
test "$(git show "$NOTES_REF:update-prerelease.json" | jq -r .version)" = 2.0.0-alpha.3-dev.2
stable_expected="$(git show "$NOTES_REF:update.json" | sha256sum | awk '{print $1}')"
git fetch origin v2 >/dev/null
test "$(git show origin/v2:update.json | sha256sum | awk '{print $1}')" = "$stable_expected"
test "$(git show origin/v2:update-prerelease.json | jq -r .version)" = 2.0.0-alpha.3-dev.2

STAGE=collision
release_exists=0
tag_exists=0
if fetch_release; then release_exists=1; fi
if gh api "repos/$REPOSITORY/git/ref/tags/$TAG_NAME" > "$tag_json" 2>/dev/null; then tag_exists=1; fi

if [[ "$release_exists" -eq 0 && "$tag_exists" -eq 0 ]]; then
  STAGE=draft_create
  gh release create "$TAG_NAME" "$asset_path#$ASSET_NAME" --repo "$REPOSITORY" --target "$TARGET_COMMIT" --title "$RELEASE_TITLE" --notes-file "$notes_file" --prerelease --draft

  STAGE=draft_verify
  fetch_release
  CREATED_RELEASE_ID="$(jq -r .id "$release_json")"
  test "$(jq -r .draft "$release_json")" = true
  test "$(jq -r .prerelease "$release_json")" = true
  test "$(jq -r .tag_name "$release_json")" = "$TAG_NAME"
  test "$(jq -r .name "$release_json")" = "$RELEASE_TITLE"
  test "$(jq '[.assets[] | select(.name == env.ASSET_NAME)] | length' "$release_json")" = 1
  test "$(jq -r '.assets[] | select(.name == env.ASSET_NAME) | .size' "$release_json")" = "$ASSET_BYTES"
  jq -j .body "$release_json" > "$body_file"
  cmp -s "$notes_file" "$body_file"

  STAGE=publish
  jq -n --arg name "$RELEASE_TITLE" --rawfile body "$notes_file" '{draft:false, prerelease:true, name:$name, body:$body}' > "$RUNNER_TEMP/publish-v2.json"
  gh api --method PATCH "repos/$REPOSITORY/releases/$CREATED_RELEASE_ID" --input "$RUNNER_TEMP/publish-v2.json" > "$release_json"
  PUBLISHED=1
else
  STAGE=collision_exact_verify
  test "$release_exists" -eq 1
  test "$tag_exists" -eq 1
fi

STAGE=public_verify
gh api "repos/$REPOSITORY/releases/tags/$TAG_NAME" > "$release_json"
test "$(jq -r .draft "$release_json")" = false
test "$(jq -r .prerelease "$release_json")" = true
test "$(jq -r .name "$release_json")" = "$RELEASE_TITLE"
test "$(jq '[.assets[] | select(.name == env.ASSET_NAME)] | length' "$release_json")" = 1
test "$(jq -r '.assets[] | select(.name == env.ASSET_NAME) | .size' "$release_json")" = "$ASSET_BYTES"
gh api "repos/$REPOSITORY/git/ref/tags/$TAG_NAME" > "$tag_json"
test "$(jq -r .object.sha "$tag_json")" = "$TARGET_COMMIT"
jq -j .body "$release_json" > "$body_file"
cmp -s "$notes_file" "$body_file"

url="$(jq -r '.assets[] | select(.name == env.ASSET_NAME) | .browser_download_url' "$release_json")"
curl --fail --location --retry 3 --output "$public_asset" "$url"
test "$(sha256sum "$public_asset" | awk '{print $1}')" = "$ASSET_SHA256"
test "$(wc -c < "$public_asset" | tr -d ' ')" = "$ASSET_BYTES"

STAGE=final_channel_verify
git fetch origin v2 >/dev/null
test "$(git show origin/v2:update.json | sha256sum | awk '{print $1}')" = "$stable_expected"
test "$(git show origin/v2:update-prerelease.json | jq -r .version)" = 2.0.0-alpha.3-dev.2

STAGE=success
trap - EXIT
write_status success 0
