#!/usr/bin/env bash
set -euo pipefail

check_channel() {
  local json_file="$1"
  local expected_path="$2"
  local changelog

  test -s "$json_file"
  test -s "$expected_path"

  changelog="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["changelog"])' "$json_file")"
  test "$changelog" = "https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/$expected_path"

  case "$changelog" in
    https://raw.githubusercontent.com/*) ;;
    *)
      printf 'FAIL: %s changelog must be a downloadable raw HTTPS URL\n' "$json_file" >&2
      return 1
      ;;
  esac
}

check_channel update.json release-notes/magisk-stable.md
check_channel update-prerelease.json release-notes/magisk-prerelease.md

printf '%s\n' 'RESULT: PIXEL_THERMAL_UPDATE_JSON_CHANGELOG_CONTRACT_PASS'
