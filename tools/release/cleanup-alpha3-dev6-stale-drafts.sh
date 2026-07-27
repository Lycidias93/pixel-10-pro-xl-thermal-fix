#!/usr/bin/env bash
set -euo pipefail
umask 077

all_releases="$RUNNER_TEMP/all-releases-cleanup.json"
notes_file="$RUNNER_TEMP/cleanup-notes.md"
draft_file="$RUNNER_TEMP/cleanup-draft.json"
body_file="$RUNNER_TEMP/cleanup-body.md"

git show "$NOTES_REF:$NOTES_PATH" > "$notes_file"
gh api "repos/$REPOSITORY/releases?per_page=100" > "$all_releases"

count="$(jq --arg tag "$TAG_NAME" '[.[] | select(.tag_name == $tag and .draft == true)] | length' "$all_releases")"
printf 'stale_draft_count=%s\n' "$count"

index=0
while [[ "$index" -lt "$count" ]]; do
  jq --arg tag "$TAG_NAME" --argjson index "$index" '[.[] | select(.tag_name == $tag and .draft == true)][$index]' "$all_releases" > "$draft_file"
  id="$(jq -r .id "$draft_file")"
  test -n "$id"
  test "$id" != null
  test "$(jq -r .draft "$draft_file")" = true
  test "$(jq -r .prerelease "$draft_file")" = true
  test "$(jq -r .tag_name "$draft_file")" = "$TAG_NAME"
  test "$(jq -r .name "$draft_file")" = "$RELEASE_TITLE"
  test "$(jq '[.assets[] | select(.name == env.ASSET_NAME)] | length' "$draft_file")" = 1
  test "$(jq -r '.assets[] | select(.name == env.ASSET_NAME) | .size' "$draft_file")" = "$ASSET_BYTES"
  jq -j .body "$draft_file" > "$body_file"
  cmp -s "$notes_file" "$body_file"
  printf 'verified_stale_draft_id=%s target=%s\n' "$id" "$(jq -r .target_commitish "$draft_file")"
  gh api --method DELETE "repos/$REPOSITORY/releases/$id" >/dev/null 2>&1 || true
  index=$((index + 1))
done

if gh api "repos/$REPOSITORY/git/ref/tags/$TAG_NAME" >/dev/null 2>&1; then
  printf '%s\n' 'FAIL unexpected_tag_exists_during_draft_cleanup'
  exit 1
fi

remaining=-1
attempt=1
while [[ "$attempt" -le 10 ]]; do
  remaining="$(gh api "repos/$REPOSITORY/releases?per_page=100" | jq --arg tag "$TAG_NAME" '[.[] | select(.tag_name == $tag and .draft == true)] | length')"
  [[ "$remaining" -eq 0 ]] && break
  sleep 1
  attempt=$((attempt + 1))
done
test "$remaining" -eq 0
printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV6_STALE_DRAFT_CLEANUP_PASS'
