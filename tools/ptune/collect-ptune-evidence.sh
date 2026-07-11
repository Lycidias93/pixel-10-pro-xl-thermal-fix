#!/system/bin/sh
OUT_BASE="/sdcard/Download"
[ -d "$OUT_BASE" ] && [ -w "$OUT_BASE" ] || OUT_BASE="/storage/emulated/0/Download"
TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"
OUT="$OUT_BASE/ptune_thermal_evidence_$TS"
mkdir -p "$OUT" 2>/dev/null || true
collect() { name="$1"; shift; { "$@"; } > "$OUT/$name" 2>&1 || true; }
collect props.txt sh -c 'getprop ro.product.model; getprop ro.product.device; getprop ro.build.version.release; getprop ro.build.version.sdk; getprop ro.build.id; getprop ro.build.version.incremental; getprop ro.build.fingerprint; getprop sys.boot_completed; getprop ro.boot.bootreason; getprop sys.boot.reason; cat /proc/uptime 2>/dev/null || true'
collect module_flags.txt sh -c 'for d in /data/adb/modules/ptune /data/adb/modules_update/ptune /data/adb/modules/pixel-10-pro-xl-thermal-fix; do echo; echo -- $d; [ -f $d/module.prop ] && grep -E "^(id=|name=|version=|versionCode=|description=)" $d/module.prop || echo absent; [ -e $d/disable ] && echo disable=present || echo disable=absent; [ -e $d/remove ] && echo remove=present || echo remove=absent; [ -e $d/skip_mount ] && echo skip_mount=present || echo skip_mount=absent; done'
collect config.txt sh -c 'cat /data/adb/pixel-10-pro-xl-thermal-fix/config.env 2>/dev/null || echo config_missing_default_strict'
collect compat_check.txt sh -c 'if [ -x /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/compat-check.sh ]; then /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/compat-check.sh; else echo compat_check_missing; fi'
collect ptune_files.txt sh -c 'find /data/adb/modules/ptune /data/adb/modules_update/ptune -maxdepth 5 -type f 2>/dev/null | sort; echo; find /data/adb/modules/ptune /data/adb/modules_update/ptune -path "*/vendor/etc/thermal_info_config*.json" -type f -exec sha256sum {} \; 2>/dev/null | sort'
collect active_vendor_hashes.txt sh -c 'for f in /vendor/etc/thermal_info_config*.json; do [ -f $f ] && sha256sum $f; done'
collect mountinfo_thermal.txt sh -c 'grep -Ei "thermal_info_config|/data/adb/modules/ptune|pixel-10-pro-xl-thermal-fix" /proc/self/mountinfo 2>/dev/null || true'
collect thermal_processes.txt sh -c 'ps -A 2>/dev/null | grep -Ei "thermal|surfaceflinger|composer" || true'
collect tombstone_list.txt sh -c 'ls -lt /data/tombstones/tombstone_[0-9][0-9] 2>/dev/null | head -32 || true'
for f in $(ls -1t /data/tombstones/tombstone_[0-9][0-9] 2>/dev/null | head -12); do cp -a "$f" "$OUT/" 2>/dev/null || true; done
{
  for f in "$OUT"/tombstone_[0-9][0-9]; do
    [ -f "$f" ] || continue
    echo
    echo "==== $f ===="
    sed -n '1,180p' "$f" | grep -Ei 'Timestamp|Cmdline|pid:|tid:|uid:|signal|Abort message|thermal|surfaceflinger|power|hal|backtrace|fatal|crash' || true
  done
} > "$OUT/tombstone_headers.txt" 2>&1
collect logcat_focus.txt sh -c 'logcat -d -t 2500 2>/dev/null | grep -Ei "thermal-service.pixel|ThermalHAL|could not be initialized|surfaceflinger|ptune|Pixel Tune|tombstone|fatal|crash|bootloop|ashlooper|crashrecovery|avc|denied|shutdown|reboot" | tail -800 || true'
cd "$OUT_BASE" || exit 1
ZIP="${OUT}.zip"
if command -v zip >/dev/null 2>&1; then
  zip -r "$ZIP" "$(basename "$OUT")" >/dev/null
else
  toybox zip -r "$ZIP" "$(basename "$OUT")" >/dev/null 2>&1 || true
fi
if [ -s "$ZIP" ]; then
  sha256sum "$ZIP" > "$ZIP.sha256" 2>/dev/null || true
  echo "archive=$ZIP"
  cat "$ZIP.sha256" 2>/dev/null || true
  echo "RESULT: PTUNE_THERMAL_EVIDENCE_DONE"
  exit 0
fi
echo "FAILED: could not create evidence ZIP; workdir=$OUT"
exit 1
