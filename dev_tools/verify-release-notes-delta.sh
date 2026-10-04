#!/usr/bin/env bash
set -euo pipefail

notes=${1:?release notes path required}
release_tag=${2:?release tag required}
repo=${GITHUB_REPOSITORY:-Lycidias93/pixel-10-pro-xl-thermal-fix}
previous_tag=${3:-}

[ -f "$notes" ]
[ -f webui.lock ]

if [ -z "$previous_tag" ]; then
  previous_tag="$(gh api "repos/${repo}/releases?per_page=100" \
    --jq ". | map(select(.draft == false and .tag_name != \"$release_tag\")) | sort_by(.published_at) | last | .tag_name // \"\"")"
fi
[ -n "$previous_tag" ]

git rev-parse -q --verify "${previous_tag}^{commit}" >/dev/null
previous_lock="$(git show "${previous_tag}:webui.lock")"
current_lock="$(cat webui.lock)"

if [ "$previous_lock" = "$current_lock" ]; then
  printf 'RESULT: RELEASE_NOTES_DELTA_PASS previous=%s webui_lock_changed=no\n' "$previous_tag"
  exit 0
fi

grep -Fq '## WebUI and shared core' "$notes"
read_lock_key() {
  local key=$1 text=$2
  printf '%s\n' "$text" | sed -n "s/^${key}=//p" | head -n1
}

previous_core_version="$(read_lock_key core_version "$previous_lock")"
current_core_version="$(read_lock_key core_version "$current_lock")"
previous_core_commit="$(read_lock_key template_commit "$previous_lock")"
current_core_commit="$(read_lock_key template_commit "$current_lock")"
template_repo="$(read_lock_key template_repo "$current_lock")"

if [ "$previous_core_version" != "$current_core_version" ]; then
  grep -Fq 'WebUI Core' "$notes"
  grep -Fq "$previous_core_version" "$notes"
  grep -Fq "$current_core_version" "$notes"
fi

if [ "$previous_core_commit" != "$current_core_commit" ]; then
  prev_upstreams="$(mktemp)"
  curr_upstreams="$(mktemp)"
  trap 'rm -f "$prev_upstreams" "$curr_upstreams"' EXIT
  gh api "repos/${template_repo}/contents/UPSTREAMS.md?ref=${previous_core_commit}" --jq .content | tr -d '\n' | base64 -d > "$prev_upstreams"
  gh api "repos/${template_repo}/contents/UPSTREAMS.md?ref=${current_core_commit}" --jq .content | tr -d '\n' | base64 -d > "$curr_upstreams"
  if ! cmp -s "$prev_upstreams" "$curr_upstreams"; then
    grep -Eiq 'upstream' "$notes"
  fi
fi
previous_supercharger="$(read_lock_key supercharger_reference "$previous_lock")"
current_supercharger="$(read_lock_key supercharger_reference "$current_lock")"
previous_ksu="$(read_lock_key ksuwebui_compat_reference "$previous_lock")"
current_ksu="$(read_lock_key ksuwebui_compat_reference "$current_lock")"

if [ "$previous_supercharger" != "$current_supercharger" ]; then
  grep -Eiq 'Supercharger' "$notes"
fi
if [ "$previous_ksu" != "$current_ksu" ]; then
  grep -Eiq 'KsuWebUI' "$notes"
fi

printf 'RESULT: RELEASE_NOTES_DELTA_PASS previous=%s webui_lock_changed=yes core=%s_to_%s\n' \
  "$previous_tag" "$previous_core_version" "$current_core_version"
