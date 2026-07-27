#!/system/bin/sh
# Read-only online collector for Pixel 10 Thermal prerelease failures.
# Writes one reviewable archive to Download and temporary files under /data/local/tmp.
set -u

ID="pixel-10-pro-xl-thermal-fix"
SCHEMA="pixel-thermal-prerelease-debug-v3"
EXPECTED_VERSION="2.0.0-alpha.3-dev.6"
EXPECTED_VERSION_CODE="1016217"
EXPECTED_TAG="v2.0.0-alpha.3-dev.6"
EXPECTED_TARGET_COMMIT="fb9caca5ca7a1f147945a500afd586dd3cd0d4d6"
EXPECTED_ASSET="pixel-10-thermal-memory-control-2.0.0-alpha.3-dev.6.zip"
EXPECTED_ASSET_SHA256="b6c7d14edc49ddded30094b984b66c0dac40d436360461bb55e5fd630148a0b9"
EXPECTED_ASSET_BYTES="307127"

SCENARIO="${1:-unknown}"
SELECTED_PROFILE="${2:-unknown}"
PREVIOUS_PROFILE="${3:-unknown}"
INSTALL_MODE="${4:-unknown}"
ADB_ROOT="${THERMAL_ADB_ROOT:-/data/adb}"
ACTIVE_MOD="$ADB_ROOT/modules/$ID"
STAGED_MOD="$ADB_ROOT/modules_update/$ID"
DATA_ROOT="$ADB_ROOT/$ID"
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
PROFILE_SLUG="$(printf '%s' "$SELECTED_PROFILE" | tr -c 'A-Za-z0-9._-' '_')"
CACHE_DIR="$DATA_ROOT/originals/$DEVICE/$BUILD_SLUG/vendor/etc"

case "$SCENARIO" in
  clean-install|action-switch|boot-failure|status-red|install-failure|unknown) ;;
  *) printf '%s\n' "FAILED: invalid scenario '$SCENARIO'"; exit 2 ;;
esac
case "$SELECTED_PROFILE" in
  stock|outdoor-safe|outdoor-plus|outdoor-extended|unknown) ;;
  *) printf '%s\n' "FAILED: invalid selected profile '$SELECTED_PROFILE'"; exit 2 ;;
esac
case "$PREVIOUS_PROFILE" in
  none|stock|outdoor-safe|outdoor-plus|outdoor-extended|unknown) ;;
  *) printf '%s\n' "FAILED: invalid previous profile '$PREVIOUS_PROFILE'"; exit 2 ;;
esac
case "$INSTALL_MODE" in
  clean|upgrade|dirty|unknown) ;;
  *) printf '%s\n' "FAILED: invalid install mode '$INSTALL_MODE'"; exit 2 ;;
esac

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
WORK="/data/local/tmp/pixel_thermal_prerelease_debug_$TS"
COLLECT="$WORK/pixel_thermal_prerelease_debug_$TS"
ARCHIVE_BASE="pixel_thermal_prerelease_debug_${DEVICE_SLUG}_${BUILD_SLUG}_${SCENARIO_SLUG}_${PROFILE_SLUG}_$TS"
ZIP="$DL/$ARCHIVE_BASE.zip"
TGZ="$DL/$ARCHIVE_BASE.tar.gz"

rm -rf "$WORK" 2>/dev/null || true
mkdir -p "$COLLECT/incident" "$COLLECT/module-active" "$COLLECT/module-staged" \
  "$COLLECT/persistent" "$COLLECT/stock-source" "$COLLECT/runtime" "$COLLECT/root" \
  "$COLLECT/install-logs" "$COLLECT/current-boot" "$COLLECT/previous-boot" \
  "$COLLECT/pstore" "$COLLECT/tombstones" "$COLLECT/hashes" 2>/dev/null || exit 4

collect_cmd() { _name="$1"; shift; { "$@"; } > "$COLLECT/$_name" 2>&1 || true; }
copy_if_readable() {
  _src="$1"; _dst="$2"
  [ -r "$_src" ] || return 0
  mkdir -p "${_dst%/*}" 2>/dev/null || true
  cp -fp "$_src" "$_dst" 2>/dev/null || true
}
copy_tail_if_readable() {
  _src="$1"; _dst="$2"
  [ -r "$_src" ] || return 0
  mkdir -p "${_dst%/*}" 2>/dev/null || true
  tail -n 4000 "$_src" > "$_dst" 2>/dev/null || true
}
copy_tree_files() {
  _src="$1"; _dst="$2"; [ -d "$_src" ] || return 0
  mkdir -p "$_dst" 2>/dev/null || true
  find "$_src" -maxdepth 1 -type f -print 2>/dev/null | while IFS= read -r _file; do
    cp -fp "$_file" "$_dst/${_file##*/}" 2>/dev/null || true
  done
}
sha_file() { sha256sum "$1" 2>/dev/null | awk '{print $1}'; }
sha_or_missing() { [ -s "$1" ] && sha_file "$1" || printf '%s\n' missing; }
bytes_or_missing() { [ -s "$1" ] && wc -c < "$1" 2>/dev/null | tr -d ' ' || printf '%s\n' missing; }
prop_value() { [ -r "$1" ] && sed -n "s/^$2=//p" "$1" | head -n 1; }
thermal_set_complete() {
  [ -r "$1/thermal_info_config.json" ] &&
  [ -r "$1/thermal_info_config_charge.json" ] &&
  [ -r "$1/thermal_info_config_throttling.json" ]
}
filter_boot_log() {
  grep -i -E 'pixel-thermal|pixel-10-pro-xl-thermal-fix|thermal|thermalservice|thermal-service|hal_thermal|android.hardware.thermal|bootanim|bootanimation|surfaceflinger|displaypower|displaymanager|hwcomposer|composer|system_server|zygote|watchdog|fatal signal|fatal exception|tombstone|avc: denied|magisk|kernelsu|ksud|sukisu|apatch|mountify|metamodule|overlayfs|magic.?mount|skip_mount|bootguard|black.?screen|loading.?bar' 2>/dev/null || true
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
  _kind="${_candidate%%:*}"; _dir="${_candidate#*:}"
  if thermal_set_complete "$_dir"; then STOCK_SOURCE_KIND="$_kind"; STOCK_SOURCE_DIR="$_dir"; break; fi
done
case "$STOCK_SOURCE_KIND" in
  magisk_mirror_*|legacy_magisk_mirror_*|persistent_original_cache) STOCK_SOURCE_TRUST=known_stock_source ;;
  active_vendor_fallback) STOCK_SOURCE_TRUST=active_view_may_be_overlaid ;;
  *) STOCK_SOURCE_TRUST=missing ;;
esac

{
  printf '%s\n' 'Pixel 10 Thermal prerelease online debug collector'
  printf '%s\n' "schema=$SCHEMA"
  printf '%s\n' "created=$TS"
  printf '%s\n' "scenario_reported=$SCENARIO"
  printf '%s\n' "selected_profile_reported=$SELECTED_PROFILE"
  printf '%s\n' "previous_profile_reported=$PREVIOUS_PROFILE"
  printf '%s\n' "module_install_mode_reported=$INSTALL_MODE"
  printf '%s\n' "expected_version=$EXPECTED_VERSION"
  printf '%s\n' "expected_version_code=$EXPECTED_VERSION_CODE"
  printf '%s\n' "expected_tag=$EXPECTED_TAG"
  printf '%s\n' "expected_target_commit=$EXPECTED_TARGET_COMMIT"
  printf '%s\n' "expected_asset=$EXPECTED_ASSET"
  printf '%s\n' "expected_asset_sha256=$EXPECTED_ASSET_SHA256"
  printf '%s\n' "expected_asset_bytes=$EXPECTED_ASSET_BYTES"
  printf '%s\n' "device=$DEVICE"
  printf '%s\n' "android=$ANDROID"
  printf '%s\n' "build_id=$BUILD_ID"
  printf '%s\n' "incremental=$INCREMENTAL"
  printf '%s\n' "stock_source_kind=$STOCK_SOURCE_KIND"
  printf '%s\n' "stock_source_path=$STOCK_SOURCE_DIR"
  printf '%s\n' "stock_source_trust=$STOCK_SOURCE_TRUST"
  printf '%s\n' 'privacy=review archive before upload; filtered logs can still contain device and app metadata'
  printf '%s\n' 'upload=send one archive plus approximate failure time and a short description of the selected transition'
} > "$COLLECT/README_REVIEW_BEFORE_UPLOAD.txt"

{
  printf '%s\n' "scenario_reported=$SCENARIO"
  printf '%s\n' "selected_profile_reported=$SELECTED_PROFILE"
  printf '%s\n' "previous_profile_reported=$PREVIOUS_PROFILE"
  printf '%s\n' "module_install_mode_reported=$INSTALL_MODE"
  printf '%s\n' "collection_time=$TS"
  printf '%s\n' "device=$DEVICE"
  printf '%s\n' "model=$(getprop ro.product.model 2>/dev/null || true)"
  printf '%s\n' "android=$ANDROID"
  printf '%s\n' "sdk=$(getprop ro.build.version.sdk 2>/dev/null || true)"
  printf '%s\n' "build_id=$BUILD_ID"
  printf '%s\n' "incremental=$INCREMENTAL"
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
} > "$COLLECT/stock-source/source.env"
if [ -n "$STOCK_SOURCE_DIR" ]; then
  for _file in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
    copy_if_readable "$STOCK_SOURCE_DIR/$_file" "$COLLECT/stock-source/$_file"
  done
fi

for _mod in "$ACTIVE_MOD" "$STAGED_MOD"; do
  [ -d "$_mod" ] || continue
  [ "$_mod" = "$ACTIVE_MOD" ] && _dst="$COLLECT/module-active" || _dst="$COLLECT/module-staged"
  for _file in module.prop install-state.txt health.log supported_versions.json; do copy_if_readable "$_mod/$_file" "$_dst/$_file"; done
  for _file in guard/last_good.env guard/pending_boot.env guard/action-performance.env guard/manager-status.env guard/manager-status.txt guard/outdoor-delta-validation.env guard/patch-manifest.tsv validation_report.json; do
    copy_if_readable "$_mod/$_file" "$_dst/$_file"
  done
  for _file in action.sh tools/action-dashboard.sh tools/core/patch-thermal.sh tools/core/patch-thermal-fix5-core.sh tools/core/patch-thermal-validated.sh tools/core/verify-outdoor-delta.sh tools/core/outdoor-runtime-policy.sh tools/core/validation-state.sh; do
    copy_if_readable "$_mod/$_file" "$_dst/runtime-core/$_file"
  done
  for _flag in disable skip_mount remove; do [ -e "$_mod/$_flag" ] && printf '%s\n' present > "$_dst/flag-$_flag.txt" || printf '%s\n' absent > "$_dst/flag-$_flag.txt"; done
  copy_tree_files "$_mod/system/vendor/etc" "$_dst/overlay"
done

copy_if_readable "$DATA_ROOT/config.env" "$COLLECT/persistent/config.env"
copy_tree_files "$DATA_ROOT/validation" "$COLLECT/persistent/validation"
find "$DATA_ROOT/originals" -type f \( -name source-manifest.tsv -o -name thermal_info_config.json -o -name thermal_info_config_charge.json -o -name thermal_info_config_throttling.json \) -print 2>/dev/null | while IFS= read -r _file; do
  _rel="${_file#$DATA_ROOT/}"; _dst="$COLLECT/persistent/$_rel"; mkdir -p "${_dst%/*}" 2>/dev/null || true; cp -fp "$_file" "$_dst" 2>/dev/null || true
done
for _file in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do copy_if_readable "/vendor/etc/$_file" "$COLLECT/runtime/vendor-active-$_file"; done

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
      printf '%s\t%s\t%s\t%s\n' "$_view" "$_file" "$(bytes_or_missing "$_path")" "$(sha_or_missing "$_path")"
    done
  done
} > "$COLLECT/hashes/thermal-file-matrix.tsv"

{
  printf '%s\n' 'module_view\tpath\tbytes\tsha256'
  for _view in active staged; do
    [ "$_view" = active ] && _mod="$ACTIVE_MOD" || _mod="$STAGED_MOD"
    for _file in module.prop action.sh tools/action-dashboard.sh tools/core/patch-thermal.sh tools/core/patch-thermal-fix5-core.sh tools/core/patch-thermal-validated.sh tools/core/verify-outdoor-delta.sh tools/core/outdoor-runtime-policy.sh; do
      _path="$_mod/$_file"
      printf '%s\t%s\t%s\t%s\n' "$_view" "$_file" "$(bytes_or_missing "$_path")" "$(sha_or_missing "$_path")"
    done
  done
} > "$COLLECT/hashes/runtime-core-matrix.tsv"

ACTIVE_VERSION="$(prop_value "$ACTIVE_MOD/module.prop" version)"
ACTIVE_VERSION_CODE="$(prop_value "$ACTIVE_MOD/module.prop" versionCode)"
STAGED_VERSION="$(prop_value "$STAGED_MOD/module.prop" version)"
STAGED_VERSION_CODE="$(prop_value "$STAGED_MOD/module.prop" versionCode)"
{
  printf '%s\n' "expected_version=$EXPECTED_VERSION"
  printf '%s\n' "expected_version_code=$EXPECTED_VERSION_CODE"
  printf '%s\n' "active_version=${ACTIVE_VERSION:-missing}"
  printf '%s\n' "active_version_code=${ACTIVE_VERSION_CODE:-missing}"
  printf '%s\n' "staged_version=${STAGED_VERSION:-missing}"
  printf '%s\n' "staged_version_code=${STAGED_VERSION_CODE:-missing}"
  [ "$ACTIVE_VERSION" = "$EXPECTED_VERSION" ] && printf '%s\n' 'active_version_match=yes' || printf '%s\n' 'active_version_match=no'
  [ "$ACTIVE_VERSION_CODE" = "$EXPECTED_VERSION_CODE" ] && printf '%s\n' 'active_version_code_match=yes' || printf '%s\n' 'active_version_code_match=no'
} > "$COLLECT/incident/release-binding.env"

for _candidate in "$DL/$EXPECTED_ASSET" "/sdcard/Download/$EXPECTED_ASSET" "/storage/emulated/0/Download/$EXPECTED_ASSET"; do
  [ -s "$_candidate" ] || continue
  printf 'path=%s\nsha256=%s\nbytes=%s\n' "$_candidate" "$(sha_file "$_candidate")" "$(wc -c < "$_candidate" | tr -d ' ')" > "$COLLECT/incident/local-release-asset.env"
  break
done

find /sdcard/Download /storage/emulated/0/Download -maxdepth 1 -type f \( -name 'pixel_thermal_install_*.txt' -o -name 'pixel_thermal_install_*_collect_debug_stdout.txt' \) -print 2>/dev/null | sort -r | head -10 | while IFS= read -r _file; do
  copy_if_readable "$_file" "$COLLECT/install-logs/${_file##*/}"
done

collect_cmd runtime/mountinfo.txt cat /proc/self/mountinfo
collect_cmd runtime/proc-mounts.txt cat /proc/mounts
collect_cmd runtime/proc-swaps.txt cat /proc/swaps
collect_cmd runtime/processes.txt ps -A
collect_cmd runtime/getprop.txt getprop
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
collect_cmd root/adb-root-list.txt ls -la "$ADB_ROOT"

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
if [ -d /sys/fs/pstore ]; then find /sys/fs/pstore -maxdepth 1 -type f -print 2>/dev/null | while IFS= read -r _file; do cp -fp "$_file" "$COLLECT/pstore/${_file##*/}" 2>/dev/null || true; done; fi
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
    [ -x "$_zip" ] || continue; (cd "$WORK" && "$_zip" -qr "$ZIP" "${COLLECT##*/}") >/dev/null 2>&1 && return 0
  done
  return 1
}
archive_tgz() {
  for _tar in /system/bin/tar /vendor/bin/tar "$(command -v tar 2>/dev/null || true)"; do
    [ -x "$_tar" ] || continue; (cd "$WORK" && "$_tar" -czf "$TGZ" "${COLLECT##*/}") >/dev/null 2>&1 && return 0
  done
  return 1
}
rm -f "$ZIP" "$TGZ" 2>/dev/null || true
ARCHIVE=""
if archive_zip; then ARCHIVE="$ZIP"; elif archive_tgz; then ARCHIVE="$TGZ"; else printf '%s\n' 'FAILED: no archive engine available'; exit 5; fi
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
printf '%s\n' "EXPECTED_PRERELEASE=$EXPECTED_VERSION"
printf '%s\n' "STOCK_SOURCE_KIND=$STOCK_SOURCE_KIND"
printf '%s\n' "STOCK_SOURCE_TRUST=$STOCK_SOURCE_TRUST"
printf '%s\n' 'Review README_REVIEW_BEFORE_UPLOAD.txt, then send the archive plus approximate failure time.'
printf '%s\n' 'RESULT: PIXEL_THERMAL_PRERELEASE_DEBUG_DONE outcome=success workflow_exit_code=0'
exit 0
