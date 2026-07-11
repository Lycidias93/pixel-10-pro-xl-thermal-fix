#!/system/bin/sh
set -eu
ID="${ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-/data/adb/modules/$ID}"
DL="/sdcard/Download"
[ -d "$DL" ] && [ -w "$DL" ] || DL="/storage/emulated/0/Download"
TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"
WORK="$DL/pixel_thermal_boot_crash_work_$TS"
OUT="$WORK/pixel_thermal_boot_crash_$TS"
ARCHIVE="$DL/pixel_thermal_boot_crash_$TS.tgz"
mkdir -p "$OUT/module" "$OUT/pstore" "$OUT/tombstones" 2>/dev/null || true

run() {
  name="$1"
  shift
  { "$@"; } > "$OUT/$name" 2>&1 || true
}

copy_one() {
  src="$1"
  dst="$2"
  [ -r "$src" ] || return 0
  base="$(printf '%s\n' "$src" | sed 's#[/: ]#_#g')"
  cp -fp "$src" "$dst/$base" 2>/dev/null || true
}

{
  echo "Pixel Thermal boot crash package"
  echo "Created: $TS"
  echo "Module ID: $ID"
  echo "Upload this archive plus Magisk install log."
  echo "Logs can contain device identifiers."
} > "$OUT/README_UPLOAD_THIS.txt"

run props.txt sh -c 'getprop ro.product.model; getprop ro.product.device; getprop ro.build.version.release; getprop ro.build.version.sdk; getprop ro.build.id; getprop ro.build.version.incremental; getprop ro.build.fingerprint'
run magisk_su.txt sh -c 'su -v 2>/dev/null || true; su -V 2>/dev/null || true; magisk -V 2>/dev/null || true; magisk -v 2>/dev/null || true'
run module_paths.txt sh -c 'for d in /data/adb/modules/pixel-10-pro-xl-thermal-fix /data/adb/modules_update/pixel-10-pro-xl-thermal-fix; do echo "== $d =="; ls -la "$d" 2>/dev/null || true; [ -s "$d/module.prop" ] && grep -E "^(id|name|version|versionCode|description|updateJson)=" "$d/module.prop" || true; [ -e "$d/disable" ] && echo disable=present || echo disable=absent; [ -e "$d/remove" ] && echo remove=present || echo remove=absent; [ -e "$d/skip_mount" ] && echo skip_mount=present || echo skip_mount=absent; done'
run module_health.txt sh -c 'for d in /data/adb/modules/pixel-10-pro-xl-thermal-fix /data/adb/modules_update/pixel-10-pro-xl-thermal-fix; do echo "== $d =="; cat "$d/health.log" 2>/dev/null || true; cat "$d/guard/bootguard.log" 2>/dev/null || true; cat "$d/install-state.txt" 2>/dev/null || true; done'
run ptune_modules.txt sh -c 'for d in /data/adb/modules/ptune /data/adb/modules_update/ptune; do echo "== $d =="; ls -la "$d" 2>/dev/null || true; [ -s "$d/module.prop" ] && grep -E "^(id|name|version|versionCode|description)=" "$d/module.prop" || true; done'
run active_mounts.txt sh -c 'grep -E "pixel-10-pro-xl-thermal-fix|thermal_info_config|fstab.zram.100p" /proc/mounts 2>/dev/null || true; grep -E "pixel-10-pro-xl-thermal-fix|thermal_info_config|fstab.zram.100p" /proc/self/mountinfo 2>/dev/null || true'
run zram_state.txt sh -c 'cat /proc/swaps 2>/dev/null || true; cat /sys/block/zram0/disksize 2>/dev/null || true; grep -E "ZRAM|zram|Swap" /proc/meminfo 2>/dev/null || true'
run logcat_boot_tail.txt sh -c 'logcat -d -b all -t 12000 2>/dev/null || true'
run logcat_crash_tail.txt sh -c 'logcat -d -b crash -t 2000 2>/dev/null || true'
run logcat_thermal_magisk_tail.txt sh -c 'logcat -d -b all -t 12000 2>/dev/null | grep -i -E "pixel-10-pro-xl-thermal-fix|thermal|ThermalHAL|avc: denied|Magisk|zygote|crash|tombstone|fatal" || true'
run dmesg_tail.txt sh -c 'dmesg 2>/dev/null | tail -n 1200 || true'
run boot_time.txt sh -c 'date -Is 2>/dev/null || date; cat /proc/uptime 2>/dev/null || true; cat /proc/sys/kernel/random/boot_id 2>/dev/null || true'

for f in /sys/fs/pstore/* /proc/last_kmsg /data/adb/magisk.log /cache/magisk.log; do copy_one "$f" "$OUT/pstore"; done
for f in /data/tombstones/tombstone_*; do
  [ -r "$f" ] || continue
  grep -a -E -m1 'thermal|ThermalHAL|pixel-10-pro-xl-thermal-fix|zygote|crash|fatal' "$f" >/dev/null 2>&1 && copy_one "$f" "$OUT/tombstones"
done
for d in /data/adb/modules/pixel-10-pro-xl-thermal-fix /data/adb/modules_update/pixel-10-pro-xl-thermal-fix; do
  [ -d "$d" ] || continue
  for f in module.prop install-state.txt health.log guard/bootguard.log guard/disabled_reason; do copy_one "$d/$f" "$OUT/module"; done
done

if tar -czf "$ARCHIVE" -C "$WORK" "$(basename "$OUT")" >/dev/null 2>&1 && [ -s "$ARCHIVE" ]; then
  sha256sum "$ARCHIVE" > "$ARCHIVE.sha256" 2>/dev/null || true
  rm -rf "$WORK" 2>/dev/null || true
  echo "Created: $ARCHIVE"
  echo "RESULT: BOOT_CRASH_LOG_COLLECT_DONE archive=$ARCHIVE"
else
  echo "WARN archive_failed workdir=$OUT"
  echo "RESULT: BOOT_CRASH_LOG_COLLECT_DONE archive=none workdir=$OUT"
fi
