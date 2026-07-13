#!/system/bin/sh
# Dynamic V2 debug collector: source cache, manifests, reports and active values.

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
ADB_ROOT="${THERMAL_ADB_ROOT:-/data/adb}"
MODDIR="${MODDIR:-$ADB_ROOT/modules/$ID}"
DATA_ROOT="${THERMAL_DATA_ROOT:-$ADB_ROOT/$ID}"
VENDOR_DIR="${THERMAL_VENDOR_DIR:-/vendor/etc}"
TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"
DEVICE="${THERMAL_DEVICE:-$(getprop ro.product.device 2>/dev/null || true)}"
ANDROID="${THERMAL_ANDROID:-$(getprop ro.build.version.release 2>/dev/null || true)}"
BUILD_ID="${THERMAL_BUILD_ID:-$(getprop ro.build.id 2>/dev/null || true)}"
[ -n "$DEVICE" ] || DEVICE=unknown
[ -n "$ANDROID" ] || ANDROID=unknown
[ -n "$BUILD_ID" ] || BUILD_ID=unknown
BUILD_SLUG="$(printf '%s' "$BUILD_ID" | tr -c 'A-Za-z0-9._-' '_')"
CACHE_DIR="$DATA_ROOT/originals/$DEVICE/$BUILD_SLUG/vendor/etc"
SOURCE_MANIFEST="$CACHE_DIR/source-manifest.tsv"

choose_download() {
  if [ -n "${THERMAL_DOWNLOAD_DIR:-}" ]; then
    printf '%s\n' "$THERMAL_DOWNLOAD_DIR"
    return 0
  fi
  for d in /sdcard/Download /storage/emulated/0/Download; do
    if [ -d "$d" ] && [ -w "$d" ]; then
      printf '%s\n' "$d"
      return 0
    fi
  done
  printf '%s\n' /storage/emulated/0/Download
}

DL="$(choose_download)"
mkdir -p "$DL" 2>/dev/null || true
WORK="$MODDIR/manual-debug-work-$TS"
COLLECT="$WORK/pixel_thermal_debug_$TS"
ZIP="$DL/pixel_thermal_debug_$TS.zip"

mkdir -p \
  "$COLLECT/module" \
  "$COLLECT/manifests" \
  "$COLLECT/reports" \
  "$COLLECT/source-cache" \
  "$COLLECT/module-overlay" \
  "$COLLECT/vendor-active" 2>/dev/null || true

collect_cmd() {
  _name="$1"
  shift
  { "$@"; } > "$COLLECT/$_name" 2>&1 || true
}

copy_if_readable() {
  _src="$1"
  _dst="$2"
  if [ -r "$_src" ]; then
    cp -fp "$_src" "$_dst" 2>/dev/null || true
  fi
}

sha_file() {
  sha256sum "$1" 2>/dev/null | awk '{print $1}'
}

count_polling_value() {
  _file="$1"
  _value="$2"
  [ -r "$_file" ] || {
    printf '%s\n' 0
    return 0
  }
  awk -v value="$_value" '
    {
      line=$0
      pattern="\"PollingDelay\"[[:space:]]*:[[:space:]]*" value "([^0-9]|$)"
      while (match(line, pattern)) {
        total++
        line=substr(line,RSTART+RLENGTH)
      }
    }
    END { print total+0 }
  ' "$_file"
}

collect_props() {
  printf '%s\n' "device=$DEVICE"
  printf '%s\n' "android=$ANDROID"
  printf '%s\n' "build_id=$BUILD_ID"
  printf '%s\n' "build_slug=$BUILD_SLUG"
  printf '%s\n' "model=$(getprop ro.product.model 2>/dev/null || true)"
  printf '%s\n' "sdk=$(getprop ro.build.version.sdk 2>/dev/null || true)"
  printf '%s\n' "incremental=$(getprop ro.build.version.incremental 2>/dev/null || true)"
  printf '%s\n' "fingerprint=$(getprop ro.build.fingerprint 2>/dev/null || true)"
  printf '%s\n' "verifiedbootstate=$(getprop ro.boot.verifiedbootstate 2>/dev/null || true)"
}

collect_flags() {
  for f in disable skip_mount remove; do
    if [ -e "$MODDIR/$f" ]; then
      printf '%s\n' "$f=present"
    else
      printf '%s\n' "$f=absent"
    fi
  done
}

collect_inventory() {
  _dir="$1"
  if [ ! -d "$_dir" ]; then
    printf '%s\n' "directory_missing=$_dir"
    return 0
  fi
  find "$_dir" -maxdepth 1 -type f -print 2>/dev/null | sort | while IFS= read -r file; do
    printf '%s\t%s\t%s\n' \
      "${file##*/}" \
      "$(wc -c < "$file" 2>/dev/null | tr -d ' ')" \
      "$(sha_file "$file")"
  done
}

collect_polling_matrix() {
  printf '%s\n' "origin	file	polling_300000	polling_5000	sha256"
  for origin in source overlay active; do
    case "$origin" in
      source) dir="$CACHE_DIR" ;;
      overlay) dir="$MODDIR/system/vendor/etc" ;;
      active) dir="$VENDOR_DIR" ;;
    esac
    for file in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
      path="$dir/$file"
      if [ -s "$path" ]; then
        printf '%s\t%s\t%s\t%s\t%s\n' \
          "$origin" \
          "$file" \
          "$(count_polling_value "$path" 300000)" \
          "$(count_polling_value "$path" 5000)" \
          "$(sha_file "$path")"
      else
        printf '%s\t%s\t%s\t%s\t%s\n' "$origin" "$file" missing missing missing
      fi
    done
  done
}

collect_mounts() {
  grep -E 'thermal_info_config(_charge|_throttling)?\.json|pixel-10-pro-xl-thermal-fix' /proc/self/mountinfo 2>/dev/null || true
}

collect_thermal_runtime() {
  ps -A 2>/dev/null | grep -i thermal || true
  printf '%s\n' ""
  printf '%s\n' "thermal_service_pid=$(pidof android.hardware.thermal-service.pixel 2>/dev/null || true)"
  printf '%s\n' "vendor_thermal_pid=$(pidof vendor.google.thermal 2>/dev/null || true)"
}

collect_root_backend() {
  su -v 2>/dev/null || true
  su -V 2>/dev/null || true
  printf '%s\n' ""
  find "$ADB_ROOT" /debug_ramdisk /sbin -maxdepth 5 \
    \( -iname '*mountify*' -o -iname '*metamodule*' -o -iname '*meta-module*' \) \
    2>/dev/null | sort | head -80
  for p in "$ADB_ROOT"/modules/*/module.prop "$ADB_ROOT"/modules_update/*/module.prop; do
    [ -f "$p" ] || continue
    if grep -Eiq 'mountify|metamodule|meta module|meta-module' "$p"; then
      printf '%s\n' "-- $p"
      grep -E '^(id|name|version|versionCode|description)=' "$p" 2>/dev/null || true
    fi
  done
}

collect_ptune() {
  for d in "$ADB_ROOT/modules/ptune" "$ADB_ROOT/modules_update/ptune"; do
    printf '%s\n' "== $d =="
    if [ -f "$d/module.prop" ]; then
      grep -E '^(id|name|version|versionCode|description)=' "$d/module.prop" 2>/dev/null || true
      [ -e "$d/disable" ] && printf '%s\n' disable=present || printf '%s\n' disable=absent
      [ -e "$d/remove" ] && printf '%s\n' remove=present || printf '%s\n' remove=absent
      [ -e "$d/skip_mount" ] && printf '%s\n' skip_mount=present || printf '%s\n' skip_mount=absent
    else
      printf '%s\n' present=no
    fi
  done
}

collect_zram() {
  printf '%s\n' "== config =="
  cat "$DATA_ROOT/config.env" 2>/dev/null || true
  printf '%s\n' ""
  printf '%s\n' "== props =="
  for key in \
    mmd.zram.enabled \
    mmd.zram.size \
    vendor.zram.size \
    persist.device_config.vendor_system_native_boot.zram_size \
    persist.vendor.boot.zram.size; do
    printf '%s\n' "$key=$(getprop "$key" 2>/dev/null || true)"
  done
  printf '%s\n' ""
  printf '%s\n' "== swaps =="
  cat /proc/swaps 2>/dev/null || true
  printf '%s\n' ""
  printf '%s\n' "== zram sysfs =="
  for file in \
    /sys/block/zram0/disksize \
    /sys/block/zram0/comp_algorithm \
    /sys/block/zram0/backing_dev \
    /sys/block/zram0/mm_stat; do
    printf '%s\n' "-- $file"
    cat "$file" 2>/dev/null || true
  done
}

{
  printf '%s\n' "Pixel Thermal Dynamic V2 debug package"
  printf '%s\n' "created=$TS"
  printf '%s\n' "device=$DEVICE"
  printf '%s\n' "android=$ANDROID"
  printf '%s\n' "build_id=$BUILD_ID"
  printf '%s\n' "source_cache=$CACHE_DIR"
  printf '%s\n' "controlled_files=thermal_info_config.json,thermal_info_config_charge.json,thermal_info_config_throttling.json"
  printf '%s\n' "command=su -c $MODDIR/tools/bootguard/collect-debug.sh"
  printf '%s\n' "upload=ZIP plus install/action log"
} > "$COLLECT/README_UPLOAD_THIS.txt"

collect_cmd props.txt collect_props
collect_cmd module_flags.txt collect_flags
collect_cmd source_inventory.txt collect_inventory "$CACHE_DIR"
collect_cmd overlay_inventory.txt collect_inventory "$MODDIR/system/vendor/etc"
collect_cmd active_inventory.txt collect_inventory "$VENDOR_DIR"
collect_cmd polling_matrix.tsv collect_polling_matrix
collect_cmd mountinfo_thermal.txt collect_mounts
collect_cmd thermal_processes.txt collect_thermal_runtime
collect_cmd root_backend.txt collect_root_backend
collect_cmd ptune_status.txt collect_ptune
collect_cmd zram_status.txt collect_zram

if [ -r "$MODDIR/tools/bootguard/compat-check.sh" ]; then
  sh "$MODDIR/tools/bootguard/compat-check.sh" > "$COLLECT/compat_check.txt" 2>&1 || true
else
  printf '%s\n' compat_check_missing > "$COLLECT/compat_check.txt"
fi

if [ -r "$MODDIR/tools/debug/status-lib.sh" ]; then
  sh "$MODDIR/tools/debug/status-lib.sh" collect > "$COLLECT/status_collect.txt" 2>&1 || true
  sh "$MODDIR/tools/debug/status-lib.sh" print > "$COLLECT/status_print.txt" 2>&1 || true
else
  printf '%s\n' status_lib_missing > "$COLLECT/status_collect.txt"
  printf '%s\n' status_lib_missing > "$COLLECT/status_print.txt"
fi

logcat -d -t 1200 2>/dev/null |
  grep -i -E 'avc: denied|hal_thermal_default|thermal-service.pixel|ThermalHAL|pixel-10-pro-xl-thermal-fix' \
  > "$COLLECT/logcat_thermal_tail.txt" 2>/dev/null || true

logcat -d -b crash -t 800 2>/dev/null > "$COLLECT/logcat_crash.txt" 2>/dev/null || true
ls -la /sys/fs/pstore > "$COLLECT/pstore_index.txt" 2>&1 || true

copy_if_readable "$MODDIR/module.prop" "$COLLECT/module/module.prop"
copy_if_readable "$MODDIR/install-state.txt" "$COLLECT/module/install-state.txt"
copy_if_readable "$MODDIR/health.log" "$COLLECT/module/health.log"
copy_if_readable "$DATA_ROOT/config.env" "$COLLECT/module/config.env"
copy_if_readable "$DATA_ROOT/supported_versions.remote.env" "$COLLECT/module/supported_versions.remote.env"
copy_if_readable "$MODDIR/supported_versions.json" "$COLLECT/module/supported_versions.json"
copy_if_readable "$SOURCE_MANIFEST" "$COLLECT/manifests/source-manifest.tsv"
copy_if_readable "$MODDIR/guard/patch-manifest.tsv" "$COLLECT/manifests/patch-manifest.tsv"
copy_if_readable "$MODDIR/validation_report.json" "$COLLECT/reports/module-validation_report.json"
copy_if_readable "$DATA_ROOT/validation_report.json" "$COLLECT/reports/data-validation_report.json"
copy_if_readable "$MODDIR/guard/manager-status.env" "$COLLECT/reports/manager-status.env"
copy_if_readable "$MODDIR/guard/manager-status.txt" "$COLLECT/reports/manager-status.txt"

for file in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
  copy_if_readable "$CACHE_DIR/$file" "$COLLECT/source-cache/$file"
  copy_if_readable "$MODDIR/system/vendor/etc/$file" "$COLLECT/module-overlay/$file"
  copy_if_readable "$VENDOR_DIR/$file" "$COLLECT/vendor-active/$file"
done

(
  cd "$COLLECT" 2>/dev/null || exit 0
  find . -type f -print 2>/dev/null | sort | while IFS= read -r file; do
    sha256sum "$file" 2>/dev/null || true
  done
) > "$COLLECT/sha256sums.txt"

make_zip_python() {
  _py="$1"
  [ -x "$_py" ] || return 1
  {
    printf '%s\n' "import os, sys, zipfile"
    printf '%s\n' "src, out = sys.argv[1], sys.argv[2]"
    printf '%s\n' "base = os.path.basename(src.rstrip('/'))"
    printf '%s\n' "with zipfile.ZipFile(out, 'w', compression=zipfile.ZIP_DEFLATED) as z:"
    printf '%s\n' "    for root, dirs, files in os.walk(src):"
    printf '%s\n' "        dirs.sort(); files.sort()"
    printf '%s\n' "        for name in files:"
    printf '%s\n' "            path = os.path.join(root, name)"
    printf '%s\n' "            arc = os.path.join(base, os.path.relpath(path, src))"
    printf '%s\n' "            z.write(path, arc)"
  } > "$WORK/make_zip.py"
  HOME="${HOME:-/data/data/com.termux/files/home}" \
    PREFIX="${PREFIX:-/data/data/com.termux/files/usr}" \
    "$_py" "$WORK/make_zip.py" "$COLLECT" "$ZIP" >/dev/null 2>&1
}

ZIP_ENGINE=""
make_archive() {
  _parent="$(dirname "$COLLECT")"
  _base="$(basename "$COLLECT")"

  for zip_bin in \
    /data/data/com.termux/files/usr/bin/zip \
    /system/bin/zip \
    /vendor/bin/zip \
    "$(command -v zip 2>/dev/null || true)"; do
    [ -n "$zip_bin" ] || continue
    if [ -x "$zip_bin" ] &&
       (cd "$_parent" && "$zip_bin" -qr "$ZIP" "$_base") >/dev/null 2>&1; then
      ZIP_ENGINE="zip:$zip_bin"
      return 0
    fi
  done

  for py in \
    /data/data/com.termux/files/usr/bin/python3 \
    /system/bin/python3 \
    /vendor/bin/python3 \
    "$(command -v python3 2>/dev/null || true)"; do
    [ -n "$py" ] || continue
    if make_zip_python "$py"; then
      ZIP_ENGINE="python:$py"
      return 0
    fi
  done

  return 1
}

rm -f "$ZIP" 2>/dev/null || true
if ! make_archive; then
  printf '%s\n' "FAILED: no ZIP engine available"
  printf '%s\n' "Work dir left at: $COLLECT"
  exit 1
fi

printf '%s\n' "zip_engine=$ZIP_ENGINE" > "$COLLECT/zip-engine.txt"
rm -f "$ZIP" 2>/dev/null || true
if ! make_archive || [ ! -s "$ZIP" ]; then
  printf '%s\n' "FAILED: ZIP rebuild failed"
  printf '%s\n' "Work dir left at: $COLLECT"
  exit 1
fi

ZIP_SHA256="$(sha256sum "$ZIP" 2>/dev/null | awk '{print $1}')"
rm -rf "$WORK" 2>/dev/null || true
printf '%s\n' "Created: $ZIP"
printf '%s\n' "ZIP_SHA256=$ZIP_SHA256"
printf '%s\n' "Upload ZIP + install/action log."
exit 0
