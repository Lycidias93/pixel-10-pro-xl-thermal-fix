#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/config.env" <<'CFG'
THERMAL_POLLING_MODE=mod
NTFY_ENABLED=1
NTFY_URL=https://ntfy.example.invalid/private-topic
NTFY_TOPIC=private-topic
NTFY_TOKEN_FILE=/data/adb/private/ntfy.token
NTFY_PRIORITY=high
NTFY_TAGS=package,warning
CFG

sh "$ROOT/tools/debug/copy-config-redacted.sh" "$TMP/config.env" "$TMP/redacted.env"
grep -Fxq 'THERMAL_POLLING_MODE=mod' "$TMP/redacted.env"
grep -Fxq 'NTFY_ENABLED=1' "$TMP/redacted.env"
grep -Fxq 'NTFY_PRIORITY=high' "$TMP/redacted.env"
grep -Fxq 'NTFY_TAGS=package,warning' "$TMP/redacted.env"
grep -Fxq 'NTFY_URL=<redacted>' "$TMP/redacted.env"
grep -Fxq 'NTFY_TOPIC=<redacted>' "$TMP/redacted.env"
grep -Fxq 'NTFY_TOKEN_FILE=<redacted>' "$TMP/redacted.env"
! grep -Fq 'private-topic' "$TMP/redacted.env"
! grep -Fq '/data/adb/private/ntfy.token' "$TMP/redacted.env"

for f in   tools/bootguard/collect-debug-v3.sh   tools/debug/collect-outdoor-boot-failure-online.sh   tools/debug/collect-thermal-online-v5.sh   tools/debug/collect-thermal-prerelease-online.sh   tools/debug/zram-debug.sh; do
  grep -Fq 'copy-config-redacted.sh' "$ROOT/$f"
done
! grep -Fq 'cat "$CONFIG_FILE"' "$ROOT/tools/debug/zram-debug.sh"
printf '%s\n' 'RESULT: PIXEL_NTFY_CONFIG_REDACTION_PASS'
