#!/system/bin/sh
set -eu

OUT_DIR="${OUT_DIR:-/sdcard/Download}"
TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || date 2>/dev/null | tr ' :/' '___')"
DEVICE="$(getprop ro.product.device 2>/dev/null || echo unknown)"
MODEL="$(getprop ro.product.model 2>/dev/null || echo unknown)"
ANDROID="$(getprop ro.build.version.release 2>/dev/null || echo unknown)"
SDK="$(getprop ro.build.version.sdk 2>/dev/null || echo unknown)"
BUILD_ID="$(getprop ro.build.id 2>/dev/null || echo unknown)"
INCREMENTAL="$(getprop ro.build.version.incremental 2>/dev/null || echo unknown)"
FINGERPRINT="$(getprop ro.build.fingerprint 2>/dev/null || echo unknown)"

safe_name() {
  echo "$1" | tr -c 'A-Za-z0-9._-' '_'
}

NAME="pixel10_stock_thermal_debug_$(safe_name "$DEVICE")_$(safe_name "$BUILD_ID")_$(safe_name "$INCREMENTAL")_$TS"
WORK="/data/local/tmp/$NAME"
mkdir -p "$WORK/vendor_etc" "$OUT_DIR"

sha_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1"
  elif [ -x /data/adb/magisk/busybox ] && /data/adb/magisk/busybox sha256sum "$1" >/dev/null 2>&1; then
    /data/adb/magisk/busybox sha256sum "$1"
  else
    echo "sha256sum_unavailable  $1"
  fi
}

capture_shell() {
  out="$1"
  shift
  ( sh -c "$*" ) > "$WORK/$out" 2>&1 || true
}

{
  echo "debug_type=stock_thermal_online"
  echo "debug_time=$(date -Is 2>/dev/null || date 2>/dev/null || true)"
  echo "model=$MODEL"
  echo "device=$DEVICE"
  echo "android=$ANDROID"
  echo "android_sdk=$SDK"
  echo "build_id=$BUILD_ID"
  echo "incremental=$INCREMENTAL"
  echo "fingerprint=$FINGERPRINT"
  echo "verifiedbootstate=$(getprop ro.boot.verifiedbootstate 2>/dev/null || true)"
  echo "vbmeta_device_state=$(getprop ro.boot.vbmeta.device_state 2>/dev/null || true)"
  echo "selinux=$(getenforce 2>/dev/null || true)"
} > "$WORK/props.txt"

copied=0
for f in /vendor/etc/thermal_info_config*.json; do
  [ -f "$f" ] || continue
  cp -p "$f" "$WORK/vendor_etc/" 2>/dev/null || cp "$f" "$WORK/vendor_etc/"
  copied=$((copied + 1))
done

echo "copied_thermal_json_count=$copied" > "$WORK/thermal_copy_state.txt"
if [ "$copied" -eq 0 ]; then
  echo "warning=no_vendor_thermal_info_config_json_files_found" >> "$WORK/thermal_copy_state.txt"
fi

capture_shell vendor_thermal_ls.txt 'ls -lZ /vendor/etc/thermal_info_config*.json 2>/dev/null || ls -l /vendor/etc/thermal_info_config*.json 2>/dev/null || true'
capture_shell vendor_thermal_mountinfo.txt 'grep -E "thermal_info_config(_charge|_throttling)?\\.json" /proc/self/mountinfo 2>/dev/null || true'
capture_shell kernel_cmdline.txt 'cat /proc/cmdline 2>/dev/null || true'
capture_shell magisk_state.txt 'magisk -v 2>/dev/null || true; magisk -V 2>/dev/null || true; ls -la /data/adb/modules 2>/dev/null || true'

{
  echo "== copied thermal JSON SHA256 =="
  for f in "$WORK"/vendor_etc/*; do
    [ -f "$f" ] || continue
    sha_file "$f"
  done
} > "$WORK/thermal_sha256s.txt" 2>&1

{
  echo "== VIRTUAL-SKIN / PollingDelay summary =="
  for f in "$WORK"/vendor_etc/*.json; do
    [ -f "$f" ] || continue
    echo
    echo "-- $(basename "$f") --"
    grep -n 'VIRTUAL-SKIN\|PollingDelay\|"Name"' "$f" 2>/dev/null || true
  done
} > "$WORK/thermal_polling_summary.txt" 2>&1

{
  echo "== thermal config file sizes =="
  ls -l "$WORK"/vendor_etc 2>/dev/null || true
  echo
  echo "== archive guidance =="
  echo "Upload the archive and the matching .sha256 file from $OUT_DIR."
  echo "Do not install the module until this stock evidence has been reviewed."
} > "$WORK/README_STOCK_DEBUG.txt"

ARCHIVE=""
if command -v zip >/dev/null 2>&1; then
  ARCHIVE="$OUT_DIR/$NAME.zip"
  ( cd "$WORK" && zip -qr "$ARCHIVE" . )
elif [ -x /data/adb/magisk/busybox ] && /data/adb/magisk/busybox zip -h >/dev/null 2>&1; then
  ARCHIVE="$OUT_DIR/$NAME.zip"
  ( cd "$WORK" && /data/adb/magisk/busybox zip -qr "$ARCHIVE" . )
else
  ARCHIVE="$OUT_DIR/$NAME.tar.gz"
  ( cd /data/local/tmp && tar -czf "$ARCHIVE" "$NAME" )
fi

sha_file "$ARCHIVE" > "$ARCHIVE.sha256" 2>/dev/null || true

echo "STOCK_THERMAL_DEBUG_ARCHIVE=$ARCHIVE"
echo "STOCK_THERMAL_DEBUG_SHA256=$ARCHIVE.sha256"
echo "RESULT: PIXEL10_STOCK_THERMAL_DEBUG_ONLINE_DONE"
