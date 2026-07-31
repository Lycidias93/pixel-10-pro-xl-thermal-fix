#!/usr/bin/env bash
set -euo pipefail
TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"
OUT="/storage/emulated/0/Download/pixel_thermal_a17_verify_${TS}.txt"
REPORT_SCRIPT="$HOME/pixel_thermal_debug_report.py"
run_root() {
  su -c "$1" 2>&1 || true
}
{
  echo "== Pixel Thermal A17 tester verify =="
  date 2>/dev/null || true
  echo
  echo "== non-root props =="
  getprop ro.product.model || true
  getprop ro.product.device || true
  getprop ro.build.version.release || true
  getprop ro.build.id || true
  getprop ro.build.version.incremental || true
  getprop ro.build.fingerprint || true
  echo
  echo "== root id =="
  run_root 'id'
  echo
  echo "== module.prop =="
  run_root 'grep -E "^(id|version|versionCode|description|updateJson)=" /data/adb/modules/pixel-10-pro-xl-thermal-fix/module.prop'
  echo
  echo "== install-state =="
  run_root 'cat /data/adb/modules/pixel-10-pro-xl-thermal-fix/install-state.txt'
  echo
  echo "== flags =="
  run_root '[ ! -e /data/adb/modules/pixel-10-pro-xl-thermal-fix/disable ] && echo disable=absent || echo disable=present; [ ! -e /data/adb/modules/pixel-10-pro-xl-thermal-fix/skip_mount ] && echo skip_mount=absent || echo skip_mount=present'
  echo
  echo "== mounts =="
  run_root 'for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do grep -F "/data/adb/modules/pixel-10-pro-xl-thermal-fix/system/vendor/etc/$f" /proc/self/mountinfo >/dev/null && echo "mount=present:$f" || echo "mount=absent:$f"; done'
  echo
  echo "== VIRTUAL-SKIN/PollingDelay lines from active /vendor overlay =="
  run_root 'for f in /vendor/etc/thermal_info_config_throttling.json /vendor/etc/thermal_info_config.json /vendor/etc/thermal_info_config_charge.json; do echo "-- $f"; grep -E "\"Name\": \"VIRTUAL-SKIN|\"PollingDelay\":" "$f" || true; done'
  echo
  echo "== module health.log =="
  run_root 'cat /data/adb/modules/pixel-10-pro-xl-thermal-fix/health.log'
  echo
  echo "== thermal tombstone grep names only =="
  run_root 'for f in /data/tombstones/tombstone_*; do [ -f "$f" ] || continue; if grep -a -E -m1 "thermal|ThermalHAL|android.hardware.thermal" "$f" >/dev/null 2>&1; then ls -l "$f"; fi; done'
  echo
  echo "RESULT: PIXEL_THERMAL_A17_TESTER_VERIFY_DONE"
} > "$OUT" 2>&1

echo "Created: $OUT"
echo "Send this .txt back with the Magisk install log."
if command -v curl >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
  curl -fsSLo "$REPORT_SCRIPT" https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/tools/pixel_thermal_debug_report.py || true
  if [ -s "$REPORT_SCRIPT" ]; then
    python3 "$REPORT_SCRIPT" || true
    echo "If a pixel_thermal_debug_*.zip was created in Download, send that too."
  fi
else
  echo "Optional debug ZIP skipped: install Termux python/curl first if requested."
fi
