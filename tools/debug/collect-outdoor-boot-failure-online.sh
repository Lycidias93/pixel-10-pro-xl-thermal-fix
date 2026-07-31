#!/system/bin/sh
# Online-first collector for non-stock Thermal boot failures.
# Read-only against module/runtime state; writes one archive to Download.
set -u

ID="pixel-10-pro-xl-thermal-fix"
FAILED_PROFILE="${1:-unknown}"
INSTALL_MODE="${2:-unknown}"
ADB_ROOT="${THERMAL_ADB_ROOT:-/data/adb}"
ACTIVE_MOD="$ADB_ROOT/modules/$ID"
STAGED_MOD="$ADB_ROOT/modules_update/$ID"
DATA_ROOT="$ADB_ROOT/$ID"
TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"
DEVICE="$(getprop ro.product.device 2>/dev/null || true)"
ANDROID="$(getprop ro.build.version.release 2>/dev/null || true)"
BUILD_ID="$(getprop ro.build.id 2>/dev/null || true)"
[ -n "$DEVICE" ] || DEVICE=unknown
[ -n "$ANDROID" ] || ANDROID=unknown
[ -n "$BUILD_ID" ] || BUILD_ID=unknown
BUILD_SLUG="$(printf '%s' "$BUILD_ID" | tr -c 'A-Za-z0-9._-' '_')"
DEVICE_SLUG="$(printf '%s' "$DEVICE" | tr -c 'A-Za-z0-9._-' '_')"
PROFILE_SLUG="$(printf '%s' "$FAILED_PROFILE" | tr -c 'A-Za-z0-9._-' '_')"
CACHE_DIR="$DATA_ROOT/originals/$DEVICE/$BUILD_SLUG/vendor/etc"

case "$FAILED_PROFILE" in
  stock|outdoor-safe|outdoor-plus|outdoor-extended|unknown) ;;
  *)
    printf '%s\n' "FAILED: invalid profile '$FAILED_PROFILE'"
    printf '%s\n' 'Allowed: stock, outdoor-safe, outdoor-plus, outdoor-extended, unknown'
    exit 2
  ;;
esac

case "$INSTALL_MODE" in
  clean|upgrade|unknown) ;;
  *)
    printf '%s\n' "FAILED: invalid install mode '$INSTALL_MODE'"
    printf '%s\n' 'Allowed: clean, upgrade, unknown'
    exit 2
  ;;
esac

if [ "$(id -u 2>/dev/null || echo 1)" != 0 ]; then
  printf '%s\n' 'FAILED: root required'
  printf '%s\n' 'Run through su -c.'
  exit 3
fi

choose_download() {
  for _dir in /sdcard/Download /storage/emulated/0/Download; do
    if [ -d "$_dir" ] && [ -w "$_dir" ]; then
      printf '%s\n' "$_dir"
      return 0
    fi
  done
  printf '%s\n' /data/local/tmp
}

DL="$(choose_download)"
WORK="/data/local/tmp/pixel_thermal_outdoor_boot_debug_$TS"
COLLECT="$WORK/pixel_thermal_outdoor_boot_debug_$TS"
ARCHIVE_BASE="pixel_thermal_outdoor_boot_debug_${DEVICE_SLUG}_${BUILD_SLUG}_${PROFILE_SLUG}_$TS"
ZIP="$DL/$ARCHIVE_BASE.zip"
TGZ="$DL/$ARCHIVE_BASE.tar.gz"

rm -rf "$WORK" 2>/dev/null || true
mkdir -p \
  "$COLLECT/incident" \
  "$COLLECT/module-active" \
  "$COLLECT/module-staged" \
  "$COLLECT/persistent" \
  "$COLLECT/stock-source" \
  "$COLLECT/runtime" \
  "$COLLECT/previous-boot" \
  "$COLLECT/current-boot" \
  "$COLLECT/pstore" \
  "$COLLECT/tombstones" \
  "$COLLECT/hashes" 2>/dev/null || {
    printf '%s\n' "FAILED: cannot create $WORK"
    exit 4
  }

collect_cmd() {
  _name="$1"
  shift
  { "$@"; } > "$COLLECT/$_name" 2>&1 || true
}

copy_if_readable() {
  _src="$1"
  _dst="$2"
  if [ -r "$_src" ]; then
    mkdir -p "${_dst%/*}" 2>/dev/null || true
    cp -fp "$_src" "$_dst" 2>/dev/null || true
  fi
}

copy_tree_files() {
  _src="$1"
  _dst="$2"
  [ -d "$_src" ] || return 0
  mkdir -p "$_dst" 2>/dev/null || true
  find "$_src" -maxdepth 1 -type f -print 2>/dev/null | while IFS= read -r _file; do
    cp -fp "$_file" "$_dst/${_file##*/}" 2>/dev/null || true
  done
}

sha_file() {
  sha256sum "$1" 2>/dev/null | awk '{print $1}'
}

sha_or_missing() {
  if [ -s "$1" ]; then
    sha_file "$1"
  else
    printf '%s\n' missing
  fi
}

bytes_or_missing() {
  if [ -s "$1" ]; then
    wc -c < "$1" 2>/dev/null | tr -d ' '
  else
    printf '%s\n' missing
  fi
}

thermal_set_complete() {
  _dir="$1"
  [ -r "$_dir/thermal_info_config.json" ] &&
    [ -r "$_dir/thermal_info_config_charge.json" ] &&
    [ -r "$_dir/thermal_info_config_throttling.json" ]
}

filter_boot_log() {
  grep -i -E \
    'pixel-thermal|thermal|thermalservice|thermal-service|hal_thermal|android.hardware.thermal|bootanim|bootanimation|surfaceflinger|displaypower|displaymanager|hwcomposer|composer|system_server|zygote|watchdog|fatal signal|fatal exception|tombstone|avc: denied|magisk|mountify|metamodule|pixel-10-pro-xl-thermal-fix|skip_mount|bootguard|black.?screen' \
    2>/dev/null || true
}

STOCK_SOURCE_DIR=""
STOCK_SOURCE_KIND=missing
for _candidate in \
  "magisk_mirror_vendor:$ADB_ROOT/magisk/mirror/vendor/etc" \
  "magisk_mirror_system_vendor:$ADB_ROOT/magisk/mirror/system/vendor/etc" \
  "legacy_magisk_mirror_vendor:/sbin/.magisk/mirror/vendor/etc" \
  "legacy_magisk_mirror_system_vendor:/sbin/.magisk/mirror/system/vendor/etc" \
  "persistent_original_cache:$CACHE_DIR" \
  "active_vendor_fallback:/vendor/etc"; do
  _kind="${_candidate%%:*}"
  _dir="${_candidate#*:}"
  if thermal_set_complete "$_dir"; then
    STOCK_SOURCE_KIND="$_kind"
    STOCK_SOURCE_DIR="$_dir"
    break
  fi
done

STOCK_SOURCE_TRUST=unknown
case "$STOCK_SOURCE_KIND" in
  magisk_mirror_*|legacy_magisk_mirror_*|persistent_original_cache) STOCK_SOURCE_TRUST=known_stock_source ;;
  active_vendor_fallback) STOCK_SOURCE_TRUST=active_view_may_be_overlaid ;;
  *) STOCK_SOURCE_TRUST=missing ;;
esac

{
  printf '%s\n' 'Pixel Thermal Outdoor boot-failure collector'
  printf '%s\n' 'schema=pixel-thermal-outdoor-boot-debug-v2'
  printf '%s\n' "created=$TS"
  printf '%s\n' "failed_profile_reported=$FAILED_PROFILE"
  printf '%s\n' "module_install_mode_reported=$INSTALL_MODE"
  printf '%s\n' "device=$DEVICE"
  printf '%s\n' "android=$ANDROID"
  printf '%s\n' "build_id=$BUILD_ID"
  printf '%s\n' "stock_source_kind=$STOCK_SOURCE_KIND"
  printf '%s\n' "stock_source_path=$STOCK_SOURCE_DIR"
  printf '%s\n' "stock_source_trust=$STOCK_SOURCE_TRUST"
  printf '%s\n' "active_module=$ACTIVE_MOD"
  printf '%s\n' "staged_module=$STAGED_MOD"
  printf '%s\n' "persistent_data=$DATA_ROOT"
  printf '%s\n' 'collection_model=recovered_boot_previous_log_plus_pstore_plus_stock_sources'
  printf '%s\n' 'privacy=review archive before upload; filtered system logs can still contain device metadata'
  printf '%s\n' 'upload=single archive plus exact failed profile, install mode and approximate failure time'
} > "$COLLECT/README_REVIEW_BEFORE_UPLOAD.txt"

{
  printf '%s\n' "failed_profile_reported=$FAILED_PROFILE"
  printf '%s\n' "module_install_mode_reported=$INSTALL_MODE"
  printf '%s\n' "collection_time=$TS"
  printf '%s\n' "device=$DEVICE"
  printf '%s\n' "model=$(getprop ro.product.model 2>/dev/null || true)"
  printf '%s\n' "android=$ANDROID"
  printf '%s\n' "sdk=$(getprop ro.build.version.sdk 2>/dev/null || true)"
  printf '%s\n' "build_id=$BUILD_ID"
  printf '%s\n' "incremental=$(getprop ro.build.version.incremental 2>/dev/null || true)"
  printf '%s\n' "fingerprint=$(getprop ro.build.fingerprint 2>/dev/null || true)"
  printf '%s\n' "bootreason=$(getprop ro.boot.bootreason 2>/dev/null || true)"
  printf '%s\n' "sys_boot_reason=$(getprop sys.boot.reason 2>/dev/null || true)"
  printf '%s\n' "bootmode=$(getprop ro.bootmode 2>/dev/null || true)"
  printf '%s\n' "boot_completed=$(getprop sys.boot_completed 2>/dev/null || true)"
  printf '%s\n' "verifiedbootstate=$(getprop ro.boot.verifiedbootstate 2>/dev/null || true)"
  printf '%s\n' "slot_suffix=$(getprop ro.boot.slot_suffix 2>/dev/null || true)"
  printf '%s\n' "uptime=$(cat /proc/uptime 2>/dev/null || true)"
  printf '%s\n' "uname=$(uname -a 2>/dev/null || true)"
} > "$COLLECT/incident/device-and-boot.env"

{
  printf '%s\n' "kind=$STOCK_SOURCE_KIND"
  printf '%s\n' "path=$STOCK_SOURCE_DIR"
  printf '%s\n' "trust=$STOCK_SOURCE_TRUST"
  printf '%s\n' "device=$DEVICE"
  printf '%s\n' "build_id=$BUILD_ID"
} > "$COLLECT/stock-source/source.env"

if [ -n "$STOCK_SOURCE_DIR" ]; then
  for _file in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
    copy_if_readable "$STOCK_SOURCE_DIR/$_file" "$COLLECT/stock-source/$_file"
  done
fi

for _mod in "$ACTIVE_MOD" "$STAGED_MOD"; do
  [ -d "$_mod" ] || continue
  case "$_mod" in
    "$ACTIVE_MOD") _dst="$COLLECT/module-active" ;;
    *) _dst="$COLLECT/module-staged" ;;
  esac
  copy_if_readable "$_mod/module.prop" "$_dst/module.prop"
  copy_if_readable "$_mod/install-state.txt" "$_dst/install-state.txt"
  copy_if_readable "$_mod/health.log" "$_dst/health.log"
  copy_if_readable "$_mod/guard/last_good.env" "$_dst/guard-last_good.env"
  copy_if_readable "$_mod/guard/action-performance.env" "$_dst/action-performance.env"
  copy_if_readable "$_mod/guard/manager-status.env" "$_dst/manager-status.env"
  copy_if_readable "$_mod/guard/manager-status.txt" "$_dst/manager-status.txt"
  copy_if_readable "$_mod/supported_versions.json" "$_dst/supported_versions.json"
  for _flag in disable skip_mount remove; do
    if [ -e "$_mod/$_flag" ]; then
      printf '%s\n' present > "$_dst/flag-$_flag.txt"
    else
      printf '%s\n' absent > "$_dst/flag-$_flag.txt"
    fi
  done
  copy_tree_files "$_mod/system/vendor/etc" "$_dst/overlay"
done

copy_if_readable "$DATA_ROOT/config.env" "$COLLECT/persistent/config.env"
copy_if_readable "$DATA_ROOT/validation/state.env" "$COLLECT/persistent/validation-state.env"
copy_if_readable "$DATA_ROOT/validation/validation-report.json" "$COLLECT/persistent/validation-report.json"
copy_if_readable "$DATA_ROOT/validation/outdoor-delta-validation.env" "$COLLECT/persistent/outdoor-delta-validation.env"
copy_if_readable "$DATA_ROOT/validation/patch-manifest.tsv" "$COLLECT/persistent/patch-manifest.tsv"

find "$DATA_ROOT/originals" -type f \( \
  -name 'source-manifest.tsv' -o \
  -name 'thermal_info_config.json' -o \
  -name 'thermal_info_config_charge.json' -o \
  -name 'thermal_info_config_throttling.json' \
\) -print 2>/dev/null | while IFS= read -r _file; do
  _rel="${_file#$DATA_ROOT/}"
  _dst="$COLLECT/persistent/$_rel"
  mkdir -p "${_dst%/*}" 2>/dev/null || true
  cp -fp "$_file" "$_dst" 2>/dev/null || true
done

for _file in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
  copy_if_readable "/vendor/etc/$_file" "$COLLECT/runtime/vendor-active-$_file"
done

{
  printf '%s\n' 'view\tfile\tbytes\tsha256'
  for _file in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
    for _view in stock_source persistent_cache module_overlay staged_overlay active_vendor; do
      case "$_view" in
        stock_source) _path="$COLLECT/stock-source/$_file" ;;
        persistent_cache) _path="$CACHE_DIR/$_file" ;;
        module_overlay) _path="$ACTIVE_MOD/system/vendor/etc/$_file" ;;
        staged_overlay) _path="$STAGED_MOD/system/vendor/etc/$_file" ;;
        active_vendor) _path="/vendor/etc/$_file" ;;
      esac
      printf '%s\t%s\t%s\t%s\n' \
        "$_view" \
        "$_file" \
        "$(bytes_or_missing "$_path")" \
        "$(sha_or_missing "$_path")"
    done
  done
} > "$COLLECT/hashes/thermal-file-matrix.tsv"

collect_cmd runtime/mountinfo.txt cat /proc/self/mountinfo
collect_cmd runtime/proc-swaps.txt cat /proc/swaps
collect_cmd runtime/processes.txt ps -A
collect_cmd runtime/getprop.txt getprop
collect_cmd runtime/dumpsys-thermalservice.txt dumpsys thermalservice
collect_cmd runtime/dumpsys-display.txt dumpsys display
collect_cmd runtime/dumpsys-power.txt dumpsys power
collect_cmd runtime/dumpsys-surfaceflinger.txt dumpsys SurfaceFlinger
collect_cmd runtime/dmesg.txt dmesg
collect_cmd runtime/su-version.txt su -v
collect_cmd runtime/su-version-code.txt su -V

logcat -b all -d -v threadtime 2>/dev/null | filter_boot_log > "$COLLECT/current-boot/logcat-filtered.txt" || true
logcat -b crash -d -v threadtime 2>/dev/null > "$COLLECT/current-boot/logcat-crash.txt" || true

# Android logcat -L reads previous-boot pstore logs when supported.
logcat -L -b all -d -v threadtime 2>/dev/null | filter_boot_log > "$COLLECT/previous-boot/logcat-last-filtered.txt" || true
logcat -L -b crash -d -v threadtime 2>/dev/null > "$COLLECT/previous-boot/logcat-last-crash.txt" || true

if [ -d /sys/fs/pstore ]; then
  find /sys/fs/pstore -maxdepth 1 -type f -print 2>/dev/null | while IFS= read -r _file; do
    cp -fp "$_file" "$COLLECT/pstore/${_file##*/}" 2>/dev/null || true
  done
fi
copy_if_readable /proc/last_kmsg "$COLLECT/previous-boot/last_kmsg.txt"

{
  ls -la /data/tombstones 2>/dev/null || true
  ls -la /data/anr 2>/dev/null || true
} > "$COLLECT/tombstones/index.txt"

find /data/tombstones -maxdepth 1 -type f -print 2>/dev/null | sort -r | head -5 | while IFS= read -r _file; do
  grep -i -E 'thermal|surfaceflinger|composer|display|system_server|fatal signal|abort message' "$_file" 2>/dev/null \
    > "$COLLECT/tombstones/${_file##*/}.filtered.txt" || true
done

for _log in \
  /data/adb/magisk.log \
  /data/adb/magisk/magisk.log \
  /cache/magisk.log \
  /data/cache/magisk.log; do
  [ -r "$_log" ] || continue
  tail -n 2000 "$_log" > "$COLLECT/runtime/magisk-${_log##*/}.txt" 2>/dev/null || true
done

for _d in "$ADB_ROOT/modules/ptune" "$ADB_ROOT/modules_update/ptune"; do
  [ -f "$_d/module.prop" ] || continue
  _name="$(printf '%s' "$_d" | tr '/' '_')"
  {
    cat "$_d/module.prop" 2>/dev/null || true
    for _flag in disable skip_mount remove; do
      [ -e "$_d/$_flag" ] && printf '%s\n' "$_flag=present" || printf '%s\n' "$_flag=absent"
    done
  } > "$COLLECT/runtime/ptune$_name.txt"
done

find "$COLLECT" -type f -print 2>/dev/null | sort | while IFS= read -r _file; do
  printf '%s\t%s\t%s\n' \
    "${_file#$COLLECT/}" \
    "$(wc -c < "$_file" 2>/dev/null | tr -d ' ')" \
    "$(sha_file "$_file")"
done > "$COLLECT/hashes/files.tsv"

archive_zip() {
  for _zip in \
    /data/data/com.termux/files/usr/bin/zip \
    /system/bin/zip \
    /vendor/bin/zip \
    "$(command -v zip 2>/dev/null || true)"; do
    [ -x "$_zip" ] || continue
    (cd "$WORK" && "$_zip" -qr "$ZIP" "${COLLECT##*/}") >/dev/null 2>&1 && return 0
  done
  return 1
}

archive_python() {
  for _py in \
    /data/data/com.termux/files/usr/bin/python3 \
    /system/bin/python3 \
    /vendor/bin/python3 \
    "$(command -v python3 2>/dev/null || true)"; do
    [ -x "$_py" ] || continue
    _make="$WORK/make_zip.py"
    {
      printf '%s\n' 'import os, sys, zipfile'
      printf '%s\n' 'src, out = sys.argv[1], sys.argv[2]'
      printf '%s\n' 'base = os.path.basename(src.rstrip("/"))'
      printf '%s\n' 'with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_DEFLATED) as z:'
      printf '%s\n' '    for root, dirs, files in os.walk(src):'
      printf '%s\n' '        dirs.sort(); files.sort()'
      printf '%s\n' '        for name in files:'
      printf '%s\n' '            path = os.path.join(root, name)'
      printf '%s\n' '            z.write(path, os.path.join(base, os.path.relpath(path, src)))'
    } > "$_make"
    "$_py" "$_make" "$COLLECT" "$ZIP" >/dev/null 2>&1 && return 0
  done
  return 1
}

archive_tgz() {
  for _tar in /system/bin/tar /vendor/bin/tar "$(command -v tar 2>/dev/null || true)"; do
    [ -x "$_tar" ] || continue
    (cd "$WORK" && "$_tar" -czf "$TGZ" "${COLLECT##*/}") >/dev/null 2>&1 && return 0
  done
  return 1
}

rm -f "$ZIP" "$TGZ" 2>/dev/null || true
ARCHIVE=""
if archive_zip || archive_python; then
  ARCHIVE="$ZIP"
elif archive_tgz; then
  ARCHIVE="$TGZ"
else
  printf '%s\n' 'FAILED: no archive engine available'
  printf '%s\n' "Collected directory left at: $COLLECT"
  exit 5
fi

ARCHIVE_SHA256="$(sha_file "$ARCHIVE")"
ARCHIVE_BYTES="$(wc -c < "$ARCHIVE" 2>/dev/null | tr -d ' ')"
rm -rf "$WORK" 2>/dev/null || true

printf '%s\n' "Created: $ARCHIVE"
printf '%s\n' "ARCHIVE_BYTES=$ARCHIVE_BYTES"
printf '%s\n' "ARCHIVE_SHA256=$ARCHIVE_SHA256"
printf '%s\n' "FAILED_PROFILE_RECORDED=$FAILED_PROFILE"
printf '%s\n' "INSTALL_MODE_RECORDED=$INSTALL_MODE"
printf '%s\n' "STOCK_SOURCE_KIND=$STOCK_SOURCE_KIND"
printf '%s\n' "STOCK_SOURCE_TRUST=$STOCK_SOURCE_TRUST"
printf '%s\n' 'Review README_REVIEW_BEFORE_UPLOAD.txt, then send the archive plus approximate failure time.'
printf '%s\n' 'RESULT: PIXEL_THERMAL_OUTDOOR_BOOT_DEBUG_DONE outcome=success workflow_exit_code=0'
exit 0
