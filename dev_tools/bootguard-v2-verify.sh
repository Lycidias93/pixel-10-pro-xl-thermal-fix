#!/usr/bin/env sh
set -eu
root="${1:-.}"
say(){ printf '%s\n' "$*"; }
need(){ [ -s "$root/$1" ] || { say "FAIL missing $1"; exit 10; }; }
has(){ grep -q "$2" "$root/$1" 2>/dev/null || { say "FAIL missing_marker file=$1 marker=$2"; exit 11; }; }
say "== bootguard v2 verify =="
say "root=$root"
need tools/bootguard-lib.sh
need tools/last-good-diff.sh
need tools/bootguard-v2-verify.sh
need tools/action-dashboard.sh
need post-fs-data.sh
need service.sh
need docs/bootguard-v2.md
has tools/bootguard-lib.sh "pending_boot"
has tools/bootguard-lib.sh "fail_count"
has tools/bootguard-lib.sh "self_disable_set"
has tools/bootguard-lib.sh "last_good.env"
has tools/last-good-diff.sh "RESULT: LAST_GOOD_DIFF_DONE"
has post-fs-data.sh "BOOTGUARD_V2_PREFLIGHT_START"
has service.sh "BOOTGUARD_V2_SUCCESS_START"
has tools/action-dashboard.sh "boot_crash_tgz"
has tools/action-dashboard.sh "bootguard_status"
has tools/action-dashboard.sh "bootguard_clear"
has docs/bootguard-v2.md "WebUI is intentionally out of scope"
if grep -R -I -n -E "http.server|localhost:|127\.0\.0\.1|web server" "$root/tools/action-dashboard.sh" "$root/docs/bootguard-v2.md" 2>/dev/null; then say "FAIL webui_scope_leak"; exit 20; fi
say "PASS no_webui_scope_leak"
say "RESULT: BOOTGUARD_V2_VERIFY_DONE"
