#!/system/bin/sh
# Public read-only toggle/debug collector for Pixel 10 Thermal Polling Fix.
# Intended use from Termux:
#   cd /sdcard/Download
#   curl -fsSLO https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/tools/pixel_thermal_toggle_debug.sh
#   su -c 'sh /sdcard/Download/pixel_thermal_toggle_debug.sh'
# This script does not delete, disable, enable, mount or patch anything.

MOD_ID="${MOD_ID:-pixel-10-pro-xl-thermal-fix}"
DL1="/sdcard/Download"
DL2="/storage/emulated/0/Download"
TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"

choose_download() {
  for d in "$DL1" "$DL2"; do
    if [ -d "$d" ] && [ -w "$d" ]; then echo "$d"; return 0; fi
  done
  echo "$DL2"
}

DL="$(choose_download)"
mkdir -p "$DL" 2>/dev/null || true
OUT="$DL/pixel_thermal_toggle_debug_${TS}.txt"

section() { echo; echo "== $1 =="; }
dump_tail() { f="$1"; n="${2:-250}"; echo "-- $f"; if [ -f "$f" ]; then tail -n "$n" "$f" 2>/dev/null || cat "$f" 2>/dev/null || true; else echo "missing"; fi; echo; }

{
  section "readme"
  echo "Pixel 10 Thermal Polling Fix toggle/debug report"
  echo "Created: $TS"
  echo "Script: tools/pixel_thermal_toggle_debug.sh"
  echo "Mode: read-only; no files are changed"
  echo "Please review this file before posting publicly."

  section "identity"
  date 2>/dev/null || true
  id 2>/dev/null || true
  uname -a 2>/dev/null || true

  section "device props"
  for p in ro.product.model ro.product.device ro.product.name ro.build.version.release ro.build.version.sdk ro.build.id ro.build.version.incremental ro.build.fingerprint ro.boot.verifiedbootstate ro.boot.vbmeta.device_state; do
    echo "$p=$(getprop "$p" 2>/dev/null || true)"
  done

  section "magisk"
  magisk -v 2>/dev/null || echo "magisk -v unavailable"
  magisk -V 2>/dev/null || echo "magisk -V unavailable"
  command -v magisk 2>/dev/null || true
  command -v su 2>/dev/null || true

  section "target module dirs"
  for d in "/data/adb/modules/$MOD_ID" "/data/adb/modules_update/$MOD_ID"; do
    echo "-- $d"
    if [ -d "$d" ]; then
      ls -la "$d" 2>/dev/null || true
      echo; echo "-- flags"
      for f in disable skip_mount remove update; do
        if [ -e "$d/$f" ]; then ls -la "$d/$f" 2>/dev/null || true; else echo "$f=absent"; fi
      done
      echo; echo "-- module.prop"; cat "$d/module.prop" 2>/dev/null || true
      echo; echo "-- install-state.txt"; cat "$d/install-state.txt" 2>/dev/null || true
      echo; echo "-- health.log"; tail -n 120 "$d/health.log" 2>/dev/null || true
    else
      echo "missing"
    fi
    echo
  done

  section "all visible module flag files"
  find /data/adb/modules /data/adb/modules_update -maxdepth 2 \( -name disable -o -name skip_mount -o -name remove -o -name update \) -print -exec ls -la {} \; 2>/dev/null || true

  section "ashlooper ashrexcue candidates"
  for a in /data/adb/modules/AshLooper /data/adb/modules/AshReXcue /data/adb/modules/ashlooper /data/adb/modules/ashrexcue /data/adb/modules_update/AshLooper /data/adb/modules_update/AshReXcue; do
    echo "-- $a"
    if [ -d "$a" ]; then
      ls -la "$a" 2>/dev/null || true
      echo; echo "-- module.prop"; cat "$a/module.prop" 2>/dev/null || true
      echo; echo "-- settings.prop"; cat "$a/settings.prop" 2>/dev/null || true
      echo; echo "-- log/settings-like files"
      find "$a" -maxdepth 2 -type f \( -name "*log*" -o -name "*settings*" -o -name "*.prop" \) -print 2>/dev/null | sort | while read f; do echo "--- $f"; tail -n 120 "$f" 2>/dev/null || true; done
    else
      echo "missing"
    fi
    echo
  done

  section "mountinfo thermal"
  grep -E "pixel-10-pro-xl-thermal-fix|thermal_info_config(_charge|_throttling)?\.json" /proc/self/mountinfo 2>/dev/null || true

  section "active thermal file hashes"
  for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
    echo "-- $f"
    sha256sum "/vendor/etc/$f" 2>/dev/null || echo "active_unreadable:/vendor/etc/$f"
    for d in "/data/adb/modules/$MOD_ID" "/data/adb/modules_update/$MOD_ID"; do sha256sum "$d/system/vendor/etc/$f" 2>/dev/null || true; done
  done

  section "thermal processes"
  ps -A 2>/dev/null | grep -i thermal || true
  pidof android.hardware.thermal-service.pixel 2>/dev/null || true
  pidof vendor.google.thermal 2>/dev/null || true

  section "thermal tombstone index"
  for f in /data/tombstones/tombstone_*; do
    [ -f "$f" ] || continue
    if grep -a -E -m1 "thermal|ThermalHAL|android.hardware.thermal" "$f" >/dev/null 2>&1; then
      ls -l "$f"
      grep -a -E -m3 "Cmdline:|pid:|thermal|ThermalHAL|android.hardware.thermal" "$f" || true
      echo
    fi
  done

  section "magisk logs"
  dump_tail /cache/magisk.log 250
  dump_tail /data/adb/magisk.log 250
  dump_tail /data/adb/magisk/magisk.log 250

  section "done"
  echo "Created: $OUT"
} > "$OUT" 2>&1

echo "Created: $OUT"
echo "Please upload this file after reviewing it for private data."
