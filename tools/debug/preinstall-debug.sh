#!/system/bin/sh
set -eu
mode="${1:-manual}"
dev="$(getprop ro.product.device 2>/dev/null || echo unknown)"
bid="$(getprop ro.build.id 2>/dev/null || echo unknown)"
ts="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"
D="/sdcard/Download/pixel_thermal_canary_diagnostic_${dev}_${bid}_$ts"
mkdir -p "$D" 2>/dev/null || exit 0
{
  echo "debug_type=pixel_thermal_canary_diagnostic"
  echo "mode=$mode"
  echo "time=$(date -Is 2>/dev/null || date 2>/dev/null || true)"
  echo "module_version=${MODULE_VERSION:-unknown}"
  echo "module_version_code=${MODULE_VERSION_CODE:-unknown}"
  echo
  echo "== props =="
  getprop ro.product.model
  getprop ro.product.device
  getprop ro.build.version.release
  getprop ro.build.version.sdk
  getprop ro.build.id
  getprop ro.build.version.incremental
  getprop ro.build.fingerprint
  echo
  echo "== root =="
  su -v 2>&1 || true
  su -V 2>&1 || true
  magisk -v 2>&1 || true
  magisk -V 2>&1 || true
  echo
  echo "== kernel =="
  uname -a 2>&1 || true
  echo
  echo "== mounts summary =="
  mount 2>&1 | grep -i -E "kernelsu|magisk|overlay|thermal|zram|vendor" || true
  echo
  echo "== vendor thermal files =="
  ls -la /vendor/etc/thermal_info_config*.json 2>&1 || true
  sha256sum /vendor/etc/thermal_info_config*.json 2>&1 || true
  echo
  echo "== pstore =="
  ls -la /sys/fs/pstore 2>&1 || true
} > "$D/device.txt" 2>&1 || true
cp -f /vendor/etc/thermal_info_config*.json "$D/" 2>/dev/null || true
cp -f /sys/fs/pstore/* "$D/" 2>/dev/null || true
logcat -d -t 800 > "$D/logcat_preinstall.txt" 2>/dev/null || true
tar -czf "$D.tgz" -C "$(dirname "$D")" "$(basename "$D")" 2>/dev/null || true
echo "$D.tgz"
