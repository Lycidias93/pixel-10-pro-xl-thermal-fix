#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CORE="${WEBUI_CORE_DIR:-$ROOT/.webui-core}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

test -s "$CORE/module/lib/ntfy.sh"
mkdir -p "$TMP/mod/bin" "$TMP/mod/lib" "$TMP/mod/tools/notifications"
cp "$ROOT/bin/module-control" "$TMP/mod/bin/module-control"
cp "$ROOT/tools/notifications/ntfy-notify.sh" "$TMP/mod/tools/notifications/ntfy-notify.sh"
cp "$CORE/module/lib/ntfy.sh" "$TMP/mod/lib/ntfy.sh"
chmod 0755 "$TMP/mod/bin/module-control" "$TMP/mod/tools/notifications/ntfy-notify.sh"
printf '%s\n' 'name=Pixel Thermal Test' 'version=2.1.0-alpha.9' > "$TMP/mod/module.prop"
printf '%s\n' 'fixture-token-value' > "$TMP/token"

cat > "$TMP/fake-curl" <<'CURL'
#!/bin/sh
printf '%s\n' "$*" >> "${NTFY_TEST_CAPTURE:?}"
exit "${NTFY_TEST_RC:-0}"
CURL
chmod 0755 "$TMP/fake-curl"
export CURL_BIN="$TMP/fake-curl" NTFY_TEST_CAPTURE="$TMP/capture" NTFY_TEST_RC=0

cat > "$TMP/config.env" <<CFG
NTFY_ENABLED=1
NTFY_URL=https://ntfy.example.invalid/pixel-thermal-fixture
NTFY_TOPIC=
NTFY_TOKEN_FILE=$TMP/token
NTFY_PRIORITY=default
NTFY_TAGS=package
CFG

status="$(MODULE_DIR="$TMP/mod" PIXEL_CONFIG_FILE="$TMP/config.env" sh "$TMP/mod/bin/module-control" notifications-status)"
grep -Fq '"schema":"root-module-webui.notifications.status.v1"' <<<"$status"
grep -Fq '"enabled":true' <<<"$status"
grep -Fq '"endpoint_configured":true' <<<"$status"
grep -Fq '"lifecycle":["start","success","fail","warn"]' <<<"$status"
! grep -Fq 'fixture-token-value' <<<"$status"
! grep -Fq 'ntfy.example.invalid' <<<"$status"
! grep -Fq "$TMP/token" <<<"$status"

test_result="$(MODULE_DIR="$TMP/mod" PIXEL_CONFIG_FILE="$TMP/config.env" sh "$TMP/mod/bin/module-control" notifications-test)"
grep -Fq '"sent":true' <<<"$test_result"
grep -Fq '"reason":"sent"' <<<"$test_result"
! grep -Fq 'fixture-token-value' <<<"$test_result"
! grep -Fq 'ntfy.example.invalid' <<<"$test_result"

for event in warn success fail; do
  MODDIR="$TMP/mod" PIXEL_CONFIG_FILE="$TMP/config.env" sh "$TMP/mod/tools/notifications/ntfy-notify.sh" "$event" fixture lifecycle_test
done
[[ "$(wc -l < "$TMP/capture")" -eq 4 ]]
grep -Fq 'event=warn component=fixture detail=lifecycle_test' "$TMP/capture"
grep -Fq 'event=success component=fixture detail=lifecycle_test' "$TMP/capture"
grep -Fq 'event=fail component=fixture detail=lifecycle_test' "$TMP/capture"

sed -i 's/^NTFY_ENABLED=1$/NTFY_ENABLED=0/' "$TMP/config.env"
before="$(wc -l < "$TMP/capture")"
MODDIR="$TMP/mod" PIXEL_CONFIG_FILE="$TMP/config.env" sh "$TMP/mod/tools/notifications/ntfy-notify.sh" warn fixture disabled_test
after="$(wc -l < "$TMP/capture")"
[[ "$before" -eq "$after" ]]
disabled="$(MODULE_DIR="$TMP/mod" PIXEL_CONFIG_FILE="$TMP/config.env" sh "$TMP/mod/bin/module-control" notifications-test)"
grep -Fq '"sent":false' <<<"$disabled"
grep -Fq '"reason":"disabled"' <<<"$disabled"

sed -i 's/^NTFY_ENABLED=0$/NTFY_ENABLED=1/' "$TMP/config.env"
export NTFY_TEST_RC=22
failed="$(MODULE_DIR="$TMP/mod" PIXEL_CONFIG_FILE="$TMP/config.env" sh "$TMP/mod/bin/module-control" notifications-test)"
grep -Fq '"sent":false' <<<"$failed"
grep -Fq '"reason":"transport_failed"' <<<"$failed"
MODDIR="$TMP/mod" PIXEL_CONFIG_FILE="$TMP/config.env" sh "$TMP/mod/tools/notifications/ntfy-notify.sh" fail fixture transport_failure

grep -Fq 'notify_event fail action action_failed' "$ROOT/bin/module-control"
grep -Fq 'notify_event success action action_applied' "$ROOT/bin/module-control"
grep -Fq 'warn auto-profile config_drift' "$ROOT/tools/core/auto-profile-switch.sh"
grep -Fq 'success auto-profile config_corrected' "$ROOT/tools/core/auto-profile-switch.sh"
grep -Fq 'fail device-verify verify_failed' "$ROOT/tools/debug/vnext-device-verify.sh"

printf '%s\n' 'RESULT: PIXEL_WEBUI_NTFY_INTEGRATION_PASS'
