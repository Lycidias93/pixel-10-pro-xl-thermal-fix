#!/usr/bin/env sh
set -eu
root="${1:-.}"
say(){ printf '%s\n' "$*"; }
has(){ [ -s "$1" ] && grep -q "$2" "$1"; }
say "== anti-bootloop audit =="
say "root=$root"
[ -s "$root/service.sh" ] || { say "FAIL service_missing"; exit 10; }
[ -s "$root/tools/collect-debug.sh" ] || { say "FAIL collect_debug_missing"; exit 11; }
[ -s "$root/tools/boot-crash-log-collect.sh" ] || { say "FAIL boot_crash_collector_missing"; exit 12; }
has "$root/service.sh" "health.log" && say "PASS service_health_log_present" || say "WARN service_health_log_absent"
has "$root/service.sh" "sys.boot_completed" && say "PASS service_boot_completed_probe_present" || say "WARN service_boot_completed_probe_absent"
has "$root/service.sh" "bootguard.log" && say "PASS service_bootguard_log_present" || say "WARN service_bootguard_log_absent"
has "$root/tools/collect-debug.sh" "boot_crash_context" && say "PASS collect_debug_boot_crash_context_present" || say "WARN collect_debug_boot_crash_context_absent"
has "$root/tools/boot-crash-log-collect.sh" "logcat_boot_tail" && say "PASS standalone_boot_crash_logcat_present" || say "WARN standalone_boot_crash_logcat_absent"
has "$root/tools/boot-crash-log-collect.sh" "pstore" && say "PASS standalone_pstore_probe_present" || say "WARN standalone_pstore_probe_absent"
auto_disable="absent"
if grep -E 'touch .*/disable|> .*/disable|/disable' "$root/service.sh" "$root/post-fs-data.sh" "$root/tools/bootguard-lib.sh" >/dev/null 2>&1 && grep -E 'fail_count|pending_boot|boot_fail|bootloop|self_disable' "$root/service.sh" "$root/post-fs-data.sh" "$root/tools/bootguard-lib.sh" >/dev/null 2>&1; then
  auto_disable="present"
fi
say "anti_bootloop_auto_disable=$auto_disable"
if [ "$auto_disable" = "absent" ]; then
  say "DECISION anti_bootloop_status=audit_only_no_self_disable"
  say "NEXT implement_guarded_self_disable_only_after_boot_crash_root_cause"
else
  say "DECISION anti_bootloop_status=self_disable_logic_present_review_required"
fi
say "RESULT: ANTI_BOOTLOOP_AUDIT_DONE auto_disable=$auto_disable"
