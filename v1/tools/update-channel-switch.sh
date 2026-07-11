#!/system/bin/sh
set -eu

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-/data/adb/modules/$ID}"
CONFIG_DIR="/data/adb/$ID"
CONFIG_FILE="$CONFIG_DIR/config.env"

STABLE_URL="https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/update.json"
TEST_URL="https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/update-prerelease.json"

say() {
  printf '%s\n' "$*"
}

msg() {
  if command -v ui_print >/dev/null 2>&1; then ui_print "$*"; else say "$*"; fi
}

cfg_set() {
  k="$1"
  v="$2"
  mkdir -p "$CONFIG_DIR" 2>/dev/null || true
  touch "$CONFIG_FILE" 2>/dev/null || true
  tmp="$CONFIG_FILE.tmp.$$"
  grep -v "^${k}=" "$CONFIG_FILE" 2>/dev/null > "$tmp" || true
  printf '%s=%s\n' "$k" "$v" >> "$tmp"
  mv "$tmp" "$CONFIG_FILE"
  chmod 0600 "$CONFIG_FILE" 2>/dev/null || true
}

json_value() {
  key="$1"
  file="$2"
  [ -s "$file" ] || return 0
  grep -E ""$key"" "$file" 2>/dev/null | head -n 1 | sed "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\{0,1\}\([^\",]*\)\"\{0,1\}.*/\1/"
}

current_url() {
  sed -n 's/^updateJson=//p' "$MODDIR/module.prop" 2>/dev/null | tail -n 1
}

channel_for_url() {
  u="$1"
  case "$u" in
    *update-prerelease.json*) say "test" ;;
    *update.json*) say "stable" ;;
    "") say "missing" ;;
    *) say "custom" ;;
  esac
}

set_update_json() {
  url="$1"
  [ -s "$MODDIR/module.prop" ] || { msg "module.prop missing"; exit 10; }
  tmp="$MODDIR/module.prop.tmp.$$"
  awk -v url="$url" '
    BEGIN { done=0 }
    /^updateJson=/ { print "updateJson=" url; done=1; next }
    { print }
    END { if (done == 0) print "updateJson=" url }
  ' "$MODDIR/module.prop" > "$tmp"
  mv "$tmp" "$MODDIR/module.prop"
  chmod 0644 "$MODDIR/module.prop" 2>/dev/null || true
}

status_channel() {
  u="$(current_url)"
  ch="$(channel_for_url "$u")"
  installed="$(sed -n 's/^version=//p' "$MODDIR/module.prop" 2>/dev/null | head -n 1)"
  stable_v="$(json_value version "$MODDIR/update.json")"
  test_v="$(json_value version "$MODDIR/update-prerelease.json")"

  msg "Update Channel"
  msg "Active: $ch"
  [ -n "$installed" ] && msg "Installed: $installed"
  [ -n "$stable_v" ] && msg "Stable JSON: $stable_v"
  [ -n "$test_v" ] && msg "Test JSON: $test_v"
  msg "Mode: path switch"
  msg "No ZIP download"; msg "Refresh Magisk update check"
}

set_stable() {
  set_update_json "$STABLE_URL"
  cfg_set UPDATE_CHANNEL stable
  msg "Switched: stable"
  msg "Magisk path updated"
  msg "No ZIP download"; msg "Refresh Magisk update check"
}

set_test() {
  set_update_json "$TEST_URL"
  cfg_set UPDATE_CHANNEL test
  msg "Switched: test"
  msg "Magisk path updated"
  msg "No ZIP download"; msg "Refresh Magisk update check"
}

case "${1:-status}" in
  status) status_channel ;;
  stable) set_stable ;;
  test|prerelease) set_test ;;
  *)
    say "Usage: $0 status|stable|test"
    exit 64
  ;;
esac
