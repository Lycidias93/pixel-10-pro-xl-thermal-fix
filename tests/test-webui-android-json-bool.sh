#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/sed" <<'SED'
#!/bin/sh
for arg in "$@"; do case "$arg" in *'\|'*) exit 0 ;; esac; done
exec /bin/sed "$@"
SED
chmod +x "$TMP/bin/sed"
func="$(sed -n '/^json_bool() {/,/^}/p' "$ROOT/bin/module-control")"
printf '%s\n%s\n' '#!/bin/sh' "$func" > "$TMP/probe.sh"
printf '%s\n' 'json_bool dry_run "$1"' >> "$TMP/probe.sh"
printf '%s\n' '{"name":"debug-verbose","dry_run":true}' > "$TMP/true.json"
printf '%s\n' '{"name":"debug-verbose","dry_run":false}' > "$TMP/false.json"
[[ "$(PATH="$TMP/bin:/usr/bin:/bin" sh "$TMP/probe.sh" "$TMP/true.json")" == true ]]
[[ "$(PATH="$TMP/bin:/usr/bin:/bin" sh "$TMP/probe.sh" "$TMP/false.json")" == false ]]
! grep -Fq '\(true\|false\)' "$ROOT/bin/module-control"
printf '%s\n' 'RESULT: PIXEL_WEBUI_ANDROID_JSON_BOOL_PASS'
