#!/system/bin/sh
# Manual debug collector for Pixel 10 Thermal Polling Fix.
# Run after reboot:
#   su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
MODDIR="${MODDIR:-/data/adb/modules/pixel-10-pro-xl-thermal-fix}"
DOWNLOAD="/sdcard/Download"
ALT_DOWNLOAD="/storage/emulated/0/Download"
TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"

choose_download() {
  for d in "$DOWNLOAD" "$ALT_DOWNLOAD"; do
    if [ -d "$d" ] && [ -w "$d" ]; then echo "$d"; return 0; fi
  done
  echo "$ALT_DOWNLOAD"
}

DL="$(choose_download)"
mkdir -p "$DL" 2>/dev/null || true
WORK="$MODDIR/manual-debug-work-$TS"
COLLECT="$WORK/pixel_thermal_debug_$TS"
ZIP="$DL/pixel_thermal_debug_$TS.zip"
mkdir -p "$COLLECT" "$COLLECT/module" "$COLLECT/vendor-active" "$COLLECT/module-overlay" "$COLLECT/profile" 2>/dev/null || true

collect_file() {
  name="$1"; shift
  { "$@"; } > "$COLLECT/$name" 2>&1 || true
}
copy_if_readable() {
  src="$1"; dst="$2"
  if [ -r "$src" ]; then cp -fp "$src" "$dst" 2>/dev/null || true; fi
}
make_zip_python() {
  py="$1"
  [ -x "$py" ] || return 1
  cat > "$WORK/make_zip.py" <<'PYZIP'
import os, sys, zipfile
src, out = sys.argv[1], sys.argv[2]
base = os.path.basename(src.rstrip('/'))
with zipfile.ZipFile(out, 'w', compression=zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk(src):
        dirs.sort(); files.sort()
        for f in files:
            p = os.path.join(root, f)
            arc = os.path.join(base, os.path.relpath(p, src))
            z.write(p, arc)
PYZIP
  HOME=/data/data/com.termux/files/home PREFIX=/data/data/com.termux/files/usr LD_LIBRARY_PATH=/data/data/com.termux/files/usr/lib "$py" "$WORK/make_zip.py" "$COLLECT" "$ZIP" >/dev/null 2>&1
}
make_archive() {
  parent="$(dirname "$COLLECT")"
  base="$(basename "$COLLECT")"
  for py in /data/data/com.termux/files/usr/bin/python3 /system/bin/python3 /vendor/bin/python3 python3; do
    if make_zip_python "$py"; then echo "zip_engine=python:$py" > "$COLLECT/zip-engine.txt"; return 0; fi
  done
  for z in /data/data/com.termux/files/usr/bin/zip /system/bin/zip /vendor/bin/zip zip; do
    if command -v "$z" >/dev/null 2>&1 || [ -x "$z" ]; then
      ( cd "$parent" && "$z" -qr "$ZIP" "$base" ) >/dev/null 2>&1 && echo "zip_engine=$z" > "$COLLECT/zip-engine.txt" && return 0
    fi
  done
  if command -v toybox >/dev/null 2>&1 && toybox 2>/dev/null | tr ' ' '\n' | grep -qx zip; then
    ( cd "$parent" && toybox zip -qr "$ZIP" "$base" ) >/dev/null 2>&1 && echo "zip_engine=toybox" > "$COLLECT/zip-engine.txt" && return 0
  fi
  if [ -x /data/adb/magisk/busybox ] && /data/adb/magisk/busybox 2>/dev/null | tr ' ' '\n' | grep -qx zip; then
    ( cd "$parent" && /data/adb/magisk/busybox zip -qr "$ZIP" "$base" ) >/dev/null 2>&1 && echo "zip_engine=magisk-busybox" > "$COLLECT/zip-engine.txt" && return 0
  fi
  return 1
}

cat > "$COLLECT/README_UPLOAD_THIS.txt" <<EOF
Pixel Thermal debug package
Created: $TS
Command: su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
Upload this ZIP plus the Magisk install log or install screenshot.
EOF

collect_file props.txt sh -c 'getprop ro.product.model; getprop ro.product.device; getprop ro.build.version.release; getprop ro.build.version.sdk; getprop ro.build.id; getprop ro.build.version.incremental; getprop ro.build.fingerprint; getprop ro.boot.verifiedbootstate; getprop ro.boot.vbmeta.device_state'
collect_file module_flags.txt sh -c '[ ! -e "$0/disable" ] && echo disable=absent || echo disable=present; [ ! -e "$0/skip_mount" ] && echo skip_mount=absent || echo skip_mount=present; [ ! -e "$0/remove" ] && echo remove=absent || echo remove=present' "$MODDIR"
collect_file ptune_status.txt sh -c 'for d in /data/adb/modules/ptune /data/adb/modules_update/ptune; do echo "== $d =="; if [ -e "$d" ]; then echo present=yes; [ -f "$d/module.prop" ] && grep -E "^(id|name|version|versionCode|description)=" "$d/module.prop" || true; [ -e "$d/disable" ] && echo disable=present || echo disable=absent; [ -e "$d/remove" ] && echo remove=present || echo remove=absent; [ -e "$d/skip_mount" ] && echo skip_mount=present || echo skip_mount=absent; else echo present=no; fi; done'
collect_file config_env.txt sh -c 'cat /data/adb/pixel-10-pro-xl-thermal-fix/config.env 2>/dev/null || echo config_missing_default_strict'
collect_file compat_check.txt sh -c 'if [ -x "$0/tools/compat-check.sh" ]; then "$0/tools/compat-check.sh"; else echo compat_check_missing; fi' "$MODDIR"
collect_file ptune_known_bad_summary.txt sh -c 'for d in /data/adb/modules/ptune /data/adb/modules_update/ptune; do [ -f "$d/module.prop" ] || continue; echo "-- $d"; grep -E "^(id=|name=|version=|versionCode=)" "$d/module.prop"; vc="$(grep -E "^versionCode=" "$d/module.prop" | sed "s/^versionCode=//")"; [ "$vc" = "200" ] && echo known_bad=yes_versionCode_200_thermalhal_bootloop_on_mustang_cp1a_260505_005 || echo known_bad=no; done'
collect_file module_conflict_guard.txt sh -c 'echo "== guard files =="; ls -la "$0/guard" 2>/dev/null || true; echo; echo "== disabled_reason =="; cat "$0/guard/disabled_reason" 2>/dev/null || true; echo; echo "== conflict_ptune_path =="; cat "$0/guard/conflict_ptune_path" 2>/dev/null || true; echo; echo "== conflict_guard_mode =="; cat "$0/guard/conflict_guard_mode" 2>/dev/null || true' "$MODDIR"
collect_file active_thermal_owner_guess.txt sh -c 'echo "== active thermal mountinfo =="; grep -E "thermal_info_config(_charge|_throttling)?\.json" /proc/self/mountinfo || true; echo; echo "== module overlay hashes =="; for d in /data/adb/modules/pixel-10-pro-xl-thermal-fix /data/adb/modules/ptune /data/adb/modules_update/ptune; do echo "-- $d"; [ -d "$d" ] || { echo absent; continue; }; find "$d" -path "*/vendor/etc/thermal_info_config*.json" -type f -exec sha256sum {} \; 2>/dev/null | sort || true; done; echo; echo "== active vendor hashes =="; for f in /vendor/etc/thermal_info_config*.json; do [ -f "$f" ] && sha256sum "$f" 2>/dev/null || true; done'
collect_file module_ls.txt ls -la "$MODDIR"
collect_file time_context.txt sh -c 'echo debug_time_iso="$(date -Is 2>/dev/null || date)"; echo uptime="$(cat /proc/uptime 2>/dev/null || true)"; echo module_dir="$0"; echo; echo "== module file mtimes =="; for f in "$0/module.prop" "$0/install-state.txt" "$0/sepolicy.rule" "$0/post-fs-data.sh"; do [ -e "$f" ] && ls -l "$f"; done' "$MODDIR"
collect_file selinux_contexts.txt sh -c 'echo "getenforce=$(getenforce 2>/dev/null || true)"; echo; echo "== active vendor contexts =="; ls -Zd /vendor/etc /vendor/etc/thermal_info_config*.json 2>/dev/null || true; echo; echo "== module overlay contexts =="; ls -Zd "$0" "$0/system" "$0/system/vendor" "$0/system/vendor/etc" "$0/system/vendor/etc/"*.json "$0/sepolicy.rule" 2>/dev/null || true; echo; echo "== sepolicy.rule =="; cat "$0/sepolicy.rule" 2>/dev/null || true' "$MODDIR"
collect_file avc_thermal_denials.txt sh -c 'logcat -d -t 1200 2>/dev/null | grep -i -E "avc: denied|hal_thermal_default|thermal-service.pixel|ThermalHAL" | grep -i -E "avc|denied|hal_thermal_default|ThermalHAL could not|thermal-service.pixel" || true'

collect_file mountinfo_thermal.txt sh -c 'echo "== overlay hash equivalence =="; for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do active="$(sha256sum "/vendor/etc/$f" 2>/dev/null | awk "{print \$1}")"; overlay="$(sha256sum "$0/system/vendor/etc/$f" 2>/dev/null | awk "{print \$1}")"; profile="$(find "$0/profiles" -path "*/system/vendor/etc/$f" -type f -exec sha256sum {} \; 2>/dev/null | awk "{print \$1}" | grep -Fx "$active" | head -n 1)"; if [ -n "$active" ] && [ "$active" = "$overlay" ] && [ -n "$profile" ]; then echo "overlay_hash_match=present:$f"; else echo "overlay_hash_match=missing_or_mismatch:$f active=$active overlay=$overlay matching_profile=$profile"; fi; done; echo; echo "== raw thermal mountinfo =="; grep -E "thermal_info_config(_charge|_throttling)?\.json" /proc/self/mountinfo || true' "$MODDIR"
collect_file active_vendor_polling_summary.txt sh -c 'for f in /vendor/etc/thermal_info_config_throttling.json /vendor/etc/thermal_info_config.json /vendor/etc/thermal_info_config_charge.json; do echo "-- $f"; grep -n -E "Name.*VIRTUAL-SKIN|PollingDelay" "$f" || true; done'
collect_file module_overlay_polling_summary.txt sh -c 'for f in "$0"/system/vendor/etc/thermal_info_config_throttling.json "$0"/system/vendor/etc/thermal_info_config.json "$0"/system/vendor/etc/thermal_info_config_charge.json; do echo "-- $f"; grep -n -E "Name.*VIRTUAL-SKIN|PollingDelay" "$f" || true; done' "$MODDIR"
collect_file thermal_processes.txt sh -c 'ps -A 2>/dev/null | grep -i thermal || true; echo; pidof android.hardware.thermal-service.pixel 2>/dev/null || true; pidof vendor.google.thermal 2>/dev/null || true'
BOOT_EPOCH="$(now=$(date +%s 2>/dev/null || echo 0); up=$(cut -d. -f1 /proc/uptime 2>/dev/null || echo 0); if [ "$now" -gt 0 ] 2>/dev/null; then echo $((now-up)); else echo 0; fi)"
collect_file thermal_tombstone_index.txt sh -c 'boot="$0"; for f in /data/tombstones/tombstone_*; do [ -f "$f" ] || continue; if grep -a -E -m1 "thermal|ThermalHAL|android.hardware.thermal" "$f" >/dev/null 2>&1; then m="$(stat -c %Y "$f" 2>/dev/null || echo 0)"; fresh="unknown"; if [ "$boot" -gt 0 ] 2>/dev/null && [ "$m" -gt 0 ] 2>/dev/null; then if [ "$m" -ge "$boot" ]; then fresh="yes_after_boot"; else fresh="old_before_boot"; fi; fi; echo "file=$f mtime_epoch=$m fresh=$fresh"; ls -l "$f"; grep -a -E -m5 "Cmdline:|pid:|Timestamp:|thermal|ThermalHAL|android.hardware.thermal" "$f" || true; echo; fi; done' "$BOOT_EPOCH"
collect_file logcat_thermal_tail.txt sh -c 'logcat -d -t 400 2>/dev/null | grep -i -E "thermal|pixel-10-pro-xl-thermal-fix|Magisk" || true'
collect_file checks.txt sh -c 'grep -E "^(id|version|versionCode|description|updateJson)=" "$0/module.prop" 2>/dev/null || true; echo; cat "$0/install-state.txt" 2>/dev/null || true' "$MODDIR"

copy_if_readable "$MODDIR/module.prop" "$COLLECT/module/module.prop"
copy_if_readable "$MODDIR/install-state.txt" "$COLLECT/module/install-state.txt"
copy_if_readable "$MODDIR/health.log" "$COLLECT/module/health.log"
copy_if_readable "$MODDIR/profile-info.json" "$COLLECT/module/profile-info.json"
copy_if_readable "/data/adb/pixel-10-pro-xl-thermal-fix/config.env" "$COLLECT/module/config.env"
copy_if_readable "$MODDIR/sepolicy.rule" "$COLLECT/module/sepolicy.rule"
for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
  copy_if_readable "/vendor/etc/$f" "$COLLECT/vendor-active/$f"
  copy_if_readable "$MODDIR/system/vendor/etc/$f" "$COLLECT/module-overlay/$f"
  p="$(find "$MODDIR/profiles" -path "*/system/vendor/etc/$f" -type f 2>/dev/null | head -n 1)"
  [ -n "$p" ] && copy_if_readable "$p" "$COLLECT/profile/$f"
done
collect_file sha256sums.txt sh -c 'cd "$0" && find . -type f -print | sort | while read f; do sha256sum "$f" 2>/dev/null || true; done' "$COLLECT"

make_archive || true
if [ -s "$ZIP" ]; then
  # rebuild once so zip-engine.txt is included
  rm -f "$ZIP" 2>/dev/null || true
  make_archive || true
fi
if [ -s "$ZIP" ]; then
  sha256sum "$ZIP" > "$ZIP.sha256" 2>/dev/null || true
  rm -rf "$WORK" 2>/dev/null || true
  echo "Created: $ZIP"
  echo "Upload this ZIP plus the Magisk install log or install screenshot."
  exit 0
fi

echo "FAILED: no ZIP engine available. Install Termux python and run again."
echo "Work dir left at: $COLLECT"
exit 1
