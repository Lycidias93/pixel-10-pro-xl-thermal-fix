#!/system/bin/sh
# Packaged read-only debug collector for install, Action, status and boot failures.
set -u

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
ADB_ROOT="${THERMAL_ADB_ROOT:-/data/adb}"
CALLER_MODDIR="${MODDIR:-$ADB_ROOT/modules/$ID}"
ACTIVE_MOD="$ADB_ROOT/modules/$ID"
STAGED_MOD="$ADB_ROOT/modules_update/$ID"
DATA_ROOT="$ADB_ROOT/$ID"
VENDOR_DIR="${THERMAL_VENDOR_DIR:-/vendor/etc}"
SCHEMA="pixel-thermal-packaged-debug-v3"
SCENARIO="${1:-manual}"
SELECTED_PROFILE="${2:-unknown}"
PREVIOUS_PROFILE="${3:-unknown}"
INSTALL_MODE="${4:-unknown}"
TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"
DEVICE="$(getprop ro.product.device 2>/dev/null || true)"
ANDROID="$(getprop ro.build.version.release 2>/dev/null || true)"
BUILD_ID="$(getprop ro.build.id 2>/dev/null || true)"
INCREMENTAL="$(getprop ro.build.version.incremental 2>/dev/null || true)"
[ -n "$DEVICE" ] || DEVICE=unknown
[ -n "$ANDROID" ] || ANDROID=unknown
[ -n "$BUILD_ID" ] || BUILD_ID=unknown
DEVICE_SLUG="$(printf '%s' "$DEVICE" | tr -c 'A-Za-z0-9._-' '_')"
BUILD_SLUG="$(printf '%s' "$BUILD_ID" | tr -c 'A-Za-z0-9._-' '_')"
SCENARIO_SLUG="$(printf '%s' "$SCENARIO" | tr -c 'A-Za-z0-9._-' '_')"
CACHE_DIR="$DATA_ROOT/originals/$DEVICE/$BUILD_SLUG/vendor/etc"

if [ "$(id -u 2>/dev/null || echo 1)" != 0 ]; then
  printf '%s\n' 'FAILED: root required'
  exit 3
fi

choose_download() {
  for _dir in /sdcard/Download /storage/emulated/0/Download; do
    [ -d "$_dir" ] && [ -w "$_dir" ] && { printf '%s\n' "$_dir"; return 0; }
  done
  printf '%s\n' /data/local/tmp
}

DL="$(choose_download)"
WORK="/data/local/tmp/pixel_thermal_packaged_debug_$TS"
COLLECT="$WORK/pixel_thermal_packaged_debug_$TS"
ARCHIVE_BASE="pixel_thermal_packaged_debug_${DEVICE_SLUG}_${BUILD_SLUG}_${SCENARIO_SLUG}_$TS"
ZIP="$DL/$ARCHIVE_BASE.zip"
TGZ="$DL/$ARCHIVE_BASE.tar.gz"
rm -rf "$WORK" 2>/dev/null || true
mkdir -p "$COLLECT/incident" "$COLLECT/module-active" "$COLLECT/module-staged" \
  "$COLLECT/module-caller" "$COLLECT/persistent" "$COLLECT/stock-source" \
  "$COLLECT/runtime" "$COLLECT/root" "$COLLECT/install-logs" \
  "$COLLECT/current-boot" "$COLLECT/previous-boot" "$COLLECT/pstore" \
  "$COLLECT/tombstones" "$COLLECT/hashes" 2>/dev/null || exit 4

collect_cmd() { collector_cmd_name="$1"; shift; { "$@"; } > "$COLLECT/$collector_cmd_name" 2>&1 || true; }
copy_if_readable() {
  collector_copy_src="$1"
  collector_copy_dst="$2"
  [ -r "$collector_copy_src" ] || return 0
  mkdir -p "${collector_copy_dst%/*}" 2>/dev/null || true
  cp -fp "$collector_copy_src" "$collector_copy_dst" 2>/dev/null || true
}
copy_tail_if_readable() {
  collector_tail_src="$1"
  collector_tail_dst="$2"
  [ -r "$collector_tail_src" ] || return 0
  mkdir -p "${collector_tail_dst%/*}" 2>/dev/null || true
  tail -n 4000 "$collector_tail_src" > "$collector_tail_dst" 2>/dev/null || true
}
copy_tree_files() {
  collector_tree_src="$1"
  collector_tree_dst="$2"
  [ -d "$collector_tree_src" ] || return 0
  mkdir -p "$collector_tree_dst" 2>/dev/null || true
  find "$collector_tree_src" -maxdepth 1 -type f -print 2>/dev/null | while IFS= read -r collector_tree_file; do
    cp -fp "$collector_tree_file" "$collector_tree_dst/${collector_tree_file##*/}" 2>/dev/null || true
  done
}
sha_file() { sha256sum "$1" 2>/dev/null | awk '{print $1}'; }
sha_or_missing() { [ -s "$1" ] && sha_file "$1" || printf '%s\n' missing; }
bytes_or_missing() { [ -s "$1" ] && wc -c < "$1" 2>/dev/null | tr -d ' ' || printf '%s\n' missing; }
prop_value() { [ -r "$1" ] && sed -n "s/^$2=//p" "$1" | head -n 1; }
filter_boot_log() {
  grep -i -E 'pixel-thermal|pixel-10-pro-xl-thermal-fix|thermal|thermalservice|thermal-service|hal_thermal|android.hardware.thermal|bootanim|bootanimation|surfaceflinger|displaypower|displaymanager|hwcomposer|composer|system_server|zygote|watchdog|fatal signal|fatal exception|tombstone|avc: denied|magisk|kernelsu|ksud|sukisu|apatch|mountify|metamodule|overlayfs|magic.?mount|skip_mount|bootguard|black.?screen|loading.?bar|lmkd|lowmemorykiller|swap_free_low_percentage' 2>/dev/null || true
}

MODULE_PROP="$CALLER_MODDIR/module.prop"
[ -r "$MODULE_PROP" ] || MODULE_PROP="$ACTIVE_MOD/module.prop"
MODULE_VERSION="$(prop_value "$MODULE_PROP" version)"
MODULE_VERSION_CODE="$(prop_value "$MODULE_PROP" versionCode)"

{
  printf '%s\n' 'Pixel Thermal packaged debug collector'
  printf '%s\n' "schema=$SCHEMA"
  printf '%s\n' "created=$TS"
  printf '%s\n' "scenario_reported=$SCENARIO"
  printf '%s\n' "selected_profile_reported=$SELECTED_PROFILE"
  printf '%s\n' "previous_profile_reported=$PREVIOUS_PROFILE"
  printf '%s\n' "module_install_mode_reported=$INSTALL_MODE"
  printf '%s\n' "module_version=${MODULE_VERSION:-missing}"
  printf '%s\n' "module_version_code=${MODULE_VERSION_CODE:-missing}"
  printf '%s\n' "caller_moddir=$CALLER_MODDIR"
  printf '%s\n' "device=$DEVICE"
  printf '%s\n' "android=$ANDROID"
  printf '%s\n' "build_id=$BUILD_ID"
  printf '%s\n' "incremental=$INCREMENTAL"
  printf '%s\n' 'privacy=review archive before upload; system and app metadata may be present'
  printf '%s\n' 'upload=send one archive plus approximate failure time and selected transition'
} > "$COLLECT/README_REVIEW_BEFORE_UPLOAD.txt"

{
  printf '%s\n' "schema=$SCHEMA"
  printf '%s\n' "scenario=$SCENARIO"
  printf '%s\n' "selected_profile=$SELECTED_PROFILE"
  printf '%s\n' "previous_profile=$PREVIOUS_PROFILE"
  printf '%s\n' "install_mode=$INSTALL_MODE"
  printf '%s\n' "model=$(getprop ro.product.model 2>/dev/null || true)"
  printf '%s\n' "device=$DEVICE"
  printf '%s\n' "android=$ANDROID"
  printf '%s\n' "sdk=$(getprop ro.build.version.sdk 2>/dev/null || true)"
  printf '%s\n' "build_id=$BUILD_ID"
  printf '%s\n' "incremental=$INCREMENTAL"
  printf '%s\n' "fingerprint=$(getprop ro.build.fingerprint 2>/dev/null || true)"
  printf '%s\n' "bootreason=$(getprop ro.boot.bootreason 2>/dev/null || true)"
  printf '%s\n' "sys_boot_reason=$(getprop sys.boot.reason 2>/dev/null || true)"
  printf '%s\n' "boot_completed=$(getprop sys.boot_completed 2>/dev/null || true)"
  printf '%s\n' "verifiedbootstate=$(getprop ro.boot.verifiedbootstate 2>/dev/null || true)"
  printf '%s\n' "slot_suffix=$(getprop ro.boot.slot_suffix 2>/dev/null || true)"
  printf '%s\n' "uptime=$(cat /proc/uptime 2>/dev/null || true)"
  printf '%s\n' "uname=$(uname -a 2>/dev/null || true)"
} > "$COLLECT/incident/device-and-boot.env"

for _entry in "caller:$CALLER_MODDIR" "active:$ACTIVE_MOD" "staged:$STAGED_MOD"; do
  _view="${_entry%%:*}"; _mod="${_entry#*:}"
  [ -d "$_mod" ] || continue
  case "$_view" in caller) _dst="$COLLECT/module-caller" ;; active) _dst="$COLLECT/module-active" ;; *) _dst="$COLLECT/module-staged" ;; esac
  for _file in module.prop install-state.txt health.log supported_versions.json; do copy_if_readable "$_mod/$_file" "$_dst/$_file"; done
  for _file in guard/last_good.env guard/pending_boot.env guard/action-performance.env guard/manager-status.env guard/manager-status.txt guard/outdoor-delta-validation.env guard/patch-manifest.tsv validation_report.json; do copy_if_readable "$_mod/$_file" "$_dst/$_file"; done
  for _file in action.sh tools/action-dashboard.sh tools/lmkd/early-swap-low-test.sh tools/lmkd/verify-early-swap-low-test.sh tools/core/patch-thermal.sh tools/core/patch-thermal-fix5-core.sh tools/core/patch-thermal-validated.sh tools/core/verify-outdoor-delta.sh tools/core/outdoor-runtime-policy.sh tools/core/validation-state.sh tools/debug/install-debug.sh tools/bootguard/collect-debug-v3.sh; do copy_if_readable "$_mod/$_file" "$_dst/runtime-core/$_file"; done
  for _flag in disable skip_mount remove; do [ -e "$_mod/$_flag" ] && printf '%s\n' present > "$_dst/flag-$_flag.txt" || printf '%s\n' absent > "$_dst/flag-$_flag.txt"; done
  copy_tree_files "$_mod/system/vendor/etc" "$_dst/overlay"
done

copy_if_readable "$DATA_ROOT/config.env" "$COLLECT/persistent/config.env"
copy_tree_files "$DATA_ROOT/validation" "$COLLECT/persistent/validation"
copy_tree_files "$DATA_ROOT/lmkd-test" "$COLLECT/persistent/lmkd-test"
find "$DATA_ROOT/originals" -type f \( -name source-manifest.tsv -o -name thermal_info_config.json -o -name thermal_info_config_charge.json -o -name thermal_info_config_throttling.json \) -print 2>/dev/null | while IFS= read -r _file; do
  _rel="${_file#$DATA_ROOT/}"; copy_if_readable "$_file" "$COLLECT/persistent/$_rel"
done
for _file in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
  copy_if_readable "$CACHE_DIR/$_file" "$COLLECT/stock-source/$_file"
  copy_if_readable "$VENDOR_DIR/$_file" "$COLLECT/runtime/vendor-active-$_file"
done

{
  printf '%s\n' 'view\tfile\tbytes\tsha256'
  for _file in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
    for _view in stock_cache caller_overlay active_overlay staged_overlay active_vendor; do
      case "$_view" in
        stock_cache) _path="$CACHE_DIR/$_file" ;;
        caller_overlay) _path="$CALLER_MODDIR/system/vendor/etc/$_file" ;;
        active_overlay) _path="$ACTIVE_MOD/system/vendor/etc/$_file" ;;
        staged_overlay) _path="$STAGED_MOD/system/vendor/etc/$_file" ;;
        active_vendor) _path="$VENDOR_DIR/$_file" ;;
      esac
      printf '%s\t%s\t%s\t%s\n' "$_view" "$_file" "$(bytes_or_missing "$_path")" "$(sha_or_missing "$_path")"
    done
  done
} > "$COLLECT/hashes/thermal-file-matrix.tsv"

{
  printf '%s\n' 'module_view\tpath\tbytes\tsha256'
  for _entry in "caller:$CALLER_MODDIR" "active:$ACTIVE_MOD" "staged:$STAGED_MOD"; do
    _view="${_entry%%:*}"; _mod="${_entry#*:}"
    for _file in module.prop action.sh tools/action-dashboard.sh tools/lmkd/early-swap-low-test.sh tools/lmkd/verify-early-swap-low-test.sh tools/core/patch-thermal.sh tools/core/patch-thermal-fix5-core.sh tools/core/patch-thermal-validated.sh tools/core/verify-outdoor-delta.sh tools/core/outdoor-runtime-policy.sh tools/debug/install-debug.sh tools/bootguard/collect-debug-v3.sh; do
      _path="$_mod/$_file"
      printf '%s\t%s\t%s\t%s\n' "$_view" "$_file" "$(bytes_or_missing "$_path")" "$(sha_or_missing "$_path")"
    done
  done
} > "$COLLECT/hashes/runtime-core-matrix.tsv"

find /sdcard/Download /storage/emulated/0/Download -maxdepth 1 -type f \( -name 'pixel_thermal_install_*.txt' -o -name 'pixel_thermal_install_*_collect_debug_stdout.txt' \) -print 2>/dev/null | sort -r | head -10 | while IFS= read -r _file; do copy_if_readable "$_file" "$COLLECT/install-logs/${_file##*/}"; done

collect_cmd runtime/mountinfo.txt cat /proc/self/mountinfo
collect_cmd runtime/proc-mounts.txt cat /proc/mounts
collect_cmd runtime/proc-swaps.txt cat /proc/swaps
collect_cmd runtime/processes.txt ps -A
collect_cmd runtime/dumpsys-thermalservice.txt dumpsys thermalservice
collect_cmd runtime/dumpsys-display.txt dumpsys display
collect_cmd runtime/dumpsys-power.txt dumpsys power
collect_cmd runtime/dumpsys-surfaceflinger.txt dumpsys SurfaceFlinger
collect_cmd runtime/service-list.txt service list
collect_cmd runtime/dmesg.txt dmesg
collect_cmd runtime/df.txt df
collect_cmd runtime/selinux.txt getenforce
collect_cmd root/su-version.txt su -v
collect_cmd root/su-version-code.txt su -V
collect_cmd root/modules-list.txt ls -la "$ADB_ROOT/modules"
collect_cmd root/modules-update-list.txt ls -la "$ADB_ROOT/modules_update"

for _cmd in magisk ksud ksu apd apatch mountify; do
  _path="$(command -v "$_cmd" 2>/dev/null || true)"; [ -n "$_path" ] || continue
  { printf '%s\n' "path=$_path"; "$_path" -V 2>&1 || true; "$_path" --version 2>&1 || true; "$_path" version 2>&1 || true; } > "$COLLECT/root/$_cmd-version.txt"
done
for _log in /data/adb/magisk.log /data/adb/magisk/magisk.log /cache/magisk.log /data/cache/magisk.log /data/adb/ksud.log /data/adb/ksu/log /data/adb/ksu/ksud.log /data/adb/ksu/module.log /data/adb/apatch.log; do
  [ -r "$_log" ] || continue; _name="$(printf '%s' "$_log" | tr '/' '_')"; copy_tail_if_readable "$_log" "$COLLECT/root/$_name.txt"
done

logcat -b all -d -v threadtime 2>/dev/null | filter_boot_log > "$COLLECT/current-boot/logcat-filtered.txt" || true
logcat -b crash -d -v threadtime 2>/dev/null > "$COLLECT/current-boot/logcat-crash.txt" || true
logcat -L -b all -d -v threadtime 2>/dev/null | filter_boot_log > "$COLLECT/previous-boot/logcat-last-filtered.txt" || true
logcat -L -b crash -d -v threadtime 2>/dev/null > "$COLLECT/previous-boot/logcat-last-crash.txt" || true
if [ -d /sys/fs/pstore ]; then find /sys/fs/pstore -maxdepth 1 -type f -print 2>/dev/null | while IFS= read -r _file; do copy_if_readable "$_file" "$COLLECT/pstore/${_file##*/}"; done; fi
copy_if_readable /proc/last_kmsg "$COLLECT/previous-boot/last_kmsg.txt"
{ ls -la /data/tombstones 2>/dev/null || true; ls -la /data/anr 2>/dev/null || true; } > "$COLLECT/tombstones/index.txt"
find /data/tombstones -maxdepth 1 -type f -print 2>/dev/null | sort -r | head -5 | while IFS= read -r _file; do grep -i -E 'thermal|surfaceflinger|composer|display|system_server|fatal signal|abort message' "$_file" 2>/dev/null > "$COLLECT/tombstones/${_file##*/}.filtered.txt" || true; done

for _d in "$ADB_ROOT/modules/ptune" "$ADB_ROOT/modules_update/ptune"; do
  [ -f "$_d/module.prop" ] || continue; _name="$(printf '%s' "$_d" | tr '/' '_')"
  { cat "$_d/module.prop" 2>/dev/null || true; for _flag in disable skip_mount remove; do [ -e "$_d/$_flag" ] && printf '%s\n' "$_flag=present" || printf '%s\n' "$_flag=absent"; done; } > "$COLLECT/runtime/ptune$_name.txt"
done

find "$COLLECT" -type f -print 2>/dev/null | sort | while IFS= read -r _file; do printf '%s\t%s\t%s\n' "${_file#$COLLECT/}" "$(wc -c < "$_file" 2>/dev/null | tr -d ' ')" "$(sha_file "$_file")"; done > "$COLLECT/hashes/files.tsv"

archive_zip() {
  for _zip in /data/data/com.termux/files/usr/bin/zip /system/bin/zip /vendor/bin/zip "$(command -v zip 2>/dev/null || true)"; do
    [ -x "$_zip" ] || continue
    (cd "$WORK" && "$_zip" -qr "$ZIP" "${COLLECT##*/}") >/dev/null 2>&1 && return 0
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
if archive_zip; then ARCHIVE="$ZIP"; elif archive_tgz; then ARCHIVE="$TGZ"; else printf '%s\n' 'FAILED: no archive engine available'; printf '%s\n' "Work dir left at: $COLLECT"; exit 5; fi
ARCHIVE_SHA256="$(sha_file "$ARCHIVE")"
ARCHIVE_BYTES="$(wc -c < "$ARCHIVE" 2>/dev/null | tr -d ' ')"
rm -rf "$WORK" 2>/dev/null || true
printf '%s\n' "Created: $ARCHIVE"
printf '%s\n' "ARCHIVE_BYTES=$ARCHIVE_BYTES"
printf '%s\n' "ARCHIVE_SHA256=$ARCHIVE_SHA256"
printf '%s\n' "SCENARIO_RECORDED=$SCENARIO"
printf '%s\n' "SELECTED_PROFILE_RECORDED=$SELECTED_PROFILE"
printf '%s\n' "PREVIOUS_PROFILE_RECORDED=$PREVIOUS_PROFILE"
printf '%s\n' "INSTALL_MODE_RECORDED=$INSTALL_MODE"
printf '%s\n' "MODULE_VERSION_RECORDED=${MODULE_VERSION:-missing}"
printf '%s\n' 'Review README_REVIEW_BEFORE_UPLOAD.txt before sharing.'
printf '%s\n' 'RESULT: PIXEL_THERMAL_PACKAGED_DEBUG_DONE outcome=success workflow_exit_code=0'
exit 0
