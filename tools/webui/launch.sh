#!/system/bin/sh
set -u
umask 077

SCRIPT_DIR=${0%/*}
MODDIR="${MODULE_DIR:-${SCRIPT_DIR%/tools/webui}}"
PROP="$MODDIR/module.prop"
MODULE_ID=$(sed -n 's/^id=//p' "$PROP" 2>/dev/null | head -n 1)
case "$MODULE_ID" in
  ""|*[!A-Za-z0-9._-]*)
    echo "ERROR: invalid module id"
    echo "RESULT: PIXEL_WEBUI_OPEN_FAILED outcome=command_failed command_exit_code=1 workflow_exit_code=1 reason=invalid_module_id"
    exit 1
    ;;
esac

SERVER="$MODDIR/bin/webui-server-arm64"
CONTROL="$MODDIR/bin/module-control"
STATE_DIR="/data/adb/$MODULE_ID"
RUNTIME_DIR="/data/local/tmp/${MODULE_ID}-webui"
PID_FILE="$RUNTIME_DIR/server.pid"
READY_FILE="$RUNTIME_DIR/server.ready.json"
TOKEN_FILE="$RUNTIME_DIR/bootstrap.token"
LOG_FILE="$RUNTIME_DIR/server.log"
SERVER_PID=""

is_our_pid() {
  pid=$1
  case "$pid" in ""|*[!0-9]*) return 1 ;; esac
  [ -r "/proc/$pid/cmdline" ] || return 1
  tr '\000' ' ' < "/proc/$pid/cmdline" 2>/dev/null | grep -Fq "$SERVER"
}

stop_server() {
  [ -f "$PID_FILE" ] || return 0
  old_pid=$(cat "$PID_FILE" 2>/dev/null || true)
  if is_our_pid "$old_pid"; then
    kill "$old_pid" 2>/dev/null || true
    count=0
    while is_our_pid "$old_pid" && [ "$count" -lt 20 ]; do
      count=$((count + 1)); sleep 0.1
    done
    is_our_pid "$old_pid" && kill -9 "$old_pid" 2>/dev/null || true
  fi
  rm -f "$PID_FILE" "$READY_FILE" "$TOKEN_FILE"
}

fail() {
  reason=$1
  if [ -n "$SERVER_PID" ] && is_our_pid "$SERVER_PID"; then kill "$SERVER_PID" 2>/dev/null || true; fi
  rm -f "$PID_FILE" "$READY_FILE" "$TOKEN_FILE"
  echo "ERROR: $reason"
  echo "RESULT: PIXEL_WEBUI_OPEN_FAILED outcome=command_failed command_exit_code=1 workflow_exit_code=1 reason=$reason"
  exit 1
}

make_token() {
  if [ -r /proc/sys/kernel/random/uuid ]; then
    first=$(sed 's/-//g' < /proc/sys/kernel/random/uuid)
    second=$(sed 's/-//g' < /proc/sys/kernel/random/uuid)
    printf '%s%s\n' "$first" "$second"; return 0
  fi
  if [ -r /dev/urandom ]; then
    od -An -N32 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n'; printf '\n'; return 0
  fi
  return 1
}

[ -x "$SERVER" ] || fail server_binary_missing
[ -x "$CONTROL" ] || fail module_control_missing
[ -r "$MODDIR/webroot/index.html" ] || fail webroot_missing
mkdir -p "$STATE_DIR" "$RUNTIME_DIR"
chmod 0700 "$STATE_DIR" "$RUNTIME_DIR" 2>/dev/null || true

if [ "${1:-}" = "--verify" ]; then
  "$SERVER" -self-test -webroot "$MODDIR/webroot" -control "$CONTROL" -module-dir "$MODDIR" -state-dir "$STATE_DIR" -runtime-dir "$RUNTIME_DIR" -idle-timeout 15m -session-ttl 15m -job-timeout 30m -max-jobs 2 || fail server_self_test_failed
  echo "RESULT: PIXEL_WEBUI_VERIFY_DONE outcome=success command_exit_code=0 workflow_exit_code=0"
  exit 0
fi

stop_server
rm -f "$LOG_FILE"
TOKEN=$(make_token) || fail secure_token_generation_failed
case "$TOKEN" in *[!0-9a-f]*|"") fail secure_token_generation_failed ;; esac
[ "${#TOKEN}" -ge 64 ] || fail secure_token_generation_failed
printf '%s\n' "$TOKEN" > "$TOKEN_FILE"
chmod 0600 "$TOKEN_FILE"

"$SERVER" -listen 127.0.0.1:0 -webroot "$MODDIR/webroot" -control "$CONTROL" -module-dir "$MODDIR" -state-dir "$STATE_DIR" -runtime-dir "$RUNTIME_DIR" -token-file "$TOKEN_FILE" -state-file "$READY_FILE" -pid-file "$PID_FILE" -idle-timeout "${WEBUI_IDLE_TIMEOUT:-15m}" -session-ttl "${WEBUI_SESSION_TTL:-15m}" -job-timeout "${WEBUI_JOB_TIMEOUT:-30m}" -max-jobs "${WEBUI_MAX_JOBS:-2}" >> "$LOG_FILE" 2>&1 &
SERVER_PID=$!
printf '%s\n' "$SERVER_PID" > "$PID_FILE"
chmod 0600 "$PID_FILE"

count=0
while [ "$count" -lt 75 ]; do
  [ -s "$READY_FILE" ] && break
  is_our_pid "$SERVER_PID" || break
  count=$((count + 1)); sleep 0.2
done
[ -s "$READY_FILE" ] || { tail -n 20 "$LOG_FILE" 2>/dev/null || true; fail server_not_ready; }
PORT=$(sed -n 's/.*"port":[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$READY_FILE" | head -n 1)
case "$PORT" in ""|*[!0-9]*) fail invalid_server_port ;; esac
[ "$PORT" -ge 1024 ] && [ "$PORT" -le 65535 ] || fail invalid_server_port
CURRENT_USER=$(am get-current-user 2>/dev/null | tr -cd '0-9')
[ -n "$CURRENT_USER" ] || CURRENT_USER=0
URL="http://127.0.0.1:$PORT/bootstrap?token=$TOKEN"
am start --user "$CURRENT_USER" -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "$URL" >/dev/null 2>&1 || fail browser_launch_failed
unset TOKEN URL
echo "WebUI opened in the default browser."
echo "browser_port=$PORT"
echo "server_scope=loopback_only"
echo "RESULT: PIXEL_WEBUI_OPEN_DONE outcome=success command_exit_code=0 workflow_exit_code=0"
