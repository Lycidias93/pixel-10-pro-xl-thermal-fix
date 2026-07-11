#!/system/bin/sh
ID="pixel-10-pro-xl-thermal-fix"; M="/data/adb/modules/$ID"; U="/data/adb/modules_update/$ID"; P="/data/adb/modules/ptune"; PU="/data/adb/modules_update/ptune"
be(){ n="$(date +%s 2>/dev/null || echo 0)"; u="$(cut -d. -f1 /proc/uptime 2>/dev/null || echo 0)"; [ "$n" -gt 0 ] 2>/dev/null && echo $((n-u)) || echo 0; }
fail(){ echo "$1"; exit "${2:-20}"; }
echo "boot_id=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo unknown)"; echo "boot_epoch=$(be)"
[ -d "$U" ] && fail RESULT_STOCK_EXPORT_BLOCKED_MODULES_UPDATE_PRESENT 21
[ -d "$PU" ] && fail RESULT_STOCK_EXPORT_BLOCKED_PTUNE_STAGED_UPDATE 22
[ -d "$P" ] && [ ! -e "$P/disable" ] && fail RESULT_STOCK_EXPORT_BLOCKED_PTUNE_ACTIVE 23
grep -Eiq 'pixel-10-pro-xl-thermal-fix|/vendor/etc/thermal_info_config' /proc/mounts 2>/dev/null && fail RESULT_STOCK_EXPORT_BLOCKED_ACTIVE_MOUNTS 24
if [ -d "$M" ]; then [ -e "$M/disable" ] || fail RESULT_STOCK_EXPORT_BLOCKED_THERMAL_FIX_PRESENT 25; [ -e "$M/skip_mount" ] || fail RESULT_STOCK_EXPORT_BLOCKED_THERMAL_FIX_PRESENT 26; b="$(be)"; for f in "$M/disable" "$M/skip_mount"; do mt="$(stat -c %Y "$f" 2>/dev/null || echo 0)"; [ "$b" -gt 0 ] 2>/dev/null && [ "$mt" -ge "$b" ] 2>/dev/null && fail RESULT_NEED_REBOOT_BEFORE_STOCK_EXPORT 27; done; fi
echo RESULT_STOCK_EXPORT_GUARD_PASS
