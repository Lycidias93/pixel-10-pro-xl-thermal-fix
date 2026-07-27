#!/usr/bin/env bash
set -euo pipefail

status_dir="$GITHUB_WORKSPACE/release-proof"
status_file="$status_dir/alpha3-dev6-publication-status.txt"
proof_file="$RUNNER_TEMP/publication-proof.txt"
mkdir -p "$status_dir"
rm -f "$status_file" "$proof_file"

set +e
bash tools/release/publish-alpha3-dev6-prerelease.sh
publish_rc="$?"
set -e

release_json="$RUNNER_TEMP/post-release.json"
tag_json="$RUNNER_TEMP/post-tag.json"
body_file="$RUNNER_TEMP/post-body.md"
notes_file="$RUNNER_TEMP/post-notes.md"
downloaded="$RUNNER_TEMP/post-public-$ASSET_NAME"
verify_rc=0

release_found=no
tag_found=no
if gh api "repos/$REPOSITORY/releases/tags/$TAG_NAME" > "$release_json" 2>/dev/null; then
  release_found=yes
else
  verify_rc=1
fi
if gh api "repos/$REPOSITORY/git/ref/tags/$TAG_NAME" > "$tag_json" 2>/dev/null; then
  tag_found=yes
else
  verify_rc=1
fi

release_url=unavailable
release_draft=unavailable
release_prerelease=unavailable
release_name=unavailable
release_tag=unavailable
tag_sha=unavailable
asset_count=0
asset_bytes=unavailable
body_match=unavailable
public_download_hash=unavailable
public_download_bytes=unavailable
stable_channel_match=unavailable
prerelease_channel_before_merge=unavailable

if [[ "$release_found" = yes ]]; then
  release_url="$(jq -r .html_url "$release_json")"
  release_draft="$(jq -r .draft "$release_json")"
  release_prerelease="$(jq -r .prerelease "$release_json")"
  release_name="$(jq -r .name "$release_json")"
  release_tag="$(jq -r .tag_name "$release_json")"
  asset_count="$(jq '[.assets[] | select(.name == env.ASSET_NAME)] | length' "$release_json")"
  asset_bytes="$(jq -r '.assets[] | select(.name == env.ASSET_NAME) | .size' "$release_json" 2>/dev/null || printf unavailable)"
  [[ "$release_draft" = false ]] || verify_rc=1
  [[ "$release_prerelease" = true ]] || verify_rc=1
  [[ "$release_name" = "$RELEASE_TITLE" ]] || verify_rc=1
  [[ "$release_tag" = "$TAG_NAME" ]] || verify_rc=1
  [[ "$asset_count" = 1 ]] || verify_rc=1
  [[ "$asset_bytes" = "$ASSET_BYTES" ]] || verify_rc=1

  git show "$NOTES_REF:$NOTES_PATH" > "$notes_file"
  gh api "repos/$REPOSITORY/releases/tags/$TAG_NAME" --jq .body > "$body_file"
  if cmp -s "$notes_file" "$body_file"; then
    body_match=PASS
  else
    body_match=FAIL
    verify_rc=1
  fi

  public_url="$(jq -r '.assets[] | select(.name == env.ASSET_NAME) | .browser_download_url' "$release_json" 2>/dev/null || true)"
  if [[ -n "$public_url" && "$public_url" != null ]]; then
    if curl --fail --location --retry 3 --output "$downloaded" "$public_url"; then
      public_download_hash="$(sha256sum "$downloaded" | awk '{print $1}')"
      public_download_bytes="$(wc -c < "$downloaded" | tr -d ' ')"
      [[ "$public_download_hash" = "$ASSET_SHA256" ]] || verify_rc=1
      [[ "$public_download_bytes" = "$ASSET_BYTES" ]] || verify_rc=1
    else
      public_download_hash=DOWNLOAD_FAILED
      verify_rc=1
    fi
  else
    verify_rc=1
  fi
fi

if [[ "$tag_found" = yes ]]; then
  tag_sha="$(jq -r .object.sha "$tag_json")"
  [[ "$tag_sha" = "$TARGET_COMMIT" ]] || verify_rc=1
fi

git fetch origin v2 >/dev/null
stable_expected="$(git show "$NOTES_REF:update.json" | sha256sum | awk '{print $1}')"
stable_actual="$(git show origin/v2:update.json | sha256sum | awk '{print $1}')"
if [[ "$stable_actual" = "$stable_expected" ]]; then
  stable_channel_match=PASS
else
  stable_channel_match=FAIL
  verify_rc=1
fi
prerelease_channel_before_merge="$(git show origin/v2:update-prerelease.json | jq -r .version)"
[[ "$prerelease_channel_before_merge" = '2.0.0-alpha.3-dev.2' ]] || verify_rc=1

{
  printf 'publish_script_rc=%s\n' "$publish_rc"
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
  printf 'public_download_sha256=%s\n' "$public_download_hash"
  printf 'public_download_bytes=%s\n' "$public_download_bytes"
  printf 'stable_channel_match=%s\n' "$stable_channel_match"
  printf 'prerelease_channel_before_merge=%s\n' "$prerelease_channel_before_merge"
  printf 'post_publish_pr=%s\n' "$POST_PUBLISH_PR"
  printf 'verification_rc=%s\n' "$verify_rc"
} | tee "$status_file"

if [[ "$verify_rc" -eq 0 ]]; then
  cp "$status_file" "$proof_file"
  printf '%s\n' 'public_download_hash=PASS' | tee -a "$status_file" "$proof_file"
  printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV6_PRERELEASE_PUBLISH_DONE outcome=success workflow_exit_code=0' | tee -a "$status_file" "$proof_file"
  exit 0
fi

printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV6_PRERELEASE_PUBLISH_STOP outcome=failure workflow_exit_code=1' | tee -a "$status_file"
exit 1
