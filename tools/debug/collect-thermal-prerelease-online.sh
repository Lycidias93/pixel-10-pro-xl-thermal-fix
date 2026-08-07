#!/system/bin/sh
# Read-only online collector for Pixel Thermal runtime failures and platform-support planning.
# Works from a private executable path and writes one reviewable archive to Download.
set -u

ID="pixel-10-pro-xl-thermal-fix"
SCHEMA="pixel-thermal-online-debug-v4"
MODE="${1:-support}"
ADB_ROOT="${THERMAL_ADB_ROOT:-/data/adb}"
ACTIVE_MOD="$ADB_ROOT/modules/$ID"
STAGED_MOD="$ADB_ROOT/modules_update/$ID"
DATA_ROOT="$ADB_ROOT/$ID"
TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"
DEVICE="$(getprop ro.product.device 2>/dev/null || true)"
MODEL="$(getprop ro.product.model 2>/dev/null || true)"
ANDROID="$(getprop ro.build.version.release 2>/dev/null || true)"
BUILD_ID="$(getprop ro.build.id 2>/dev/null || true)"
INCREMENTAL="$(getprop ro.build.version.incremental 2>/dev/null || true)"
SOC_MODEL="$(getprop ro.soc.model 2>/dev/null || true)"
BOARD_PLATFORM="$(getprop ro.board.platform 2>/dev/null || true)"
[ -n "$DEVICE" ] || DEVICE=unknown
[ -n "$MODEL" ] || MODEL=unknown
[ -n "$ANDROID" ] || ANDROID=unknown
[ -n "$BUILD_ID" ] || BUILD_ID=unknown
[ -n "$SOC_MODEL" ] || SOC_MODEL=unknown
[ -n "$BOARD_PLATFORM" ] || BOARD_PLATFORM=unknown

case "$MODE" in
  support|runtime) ;;
  *) printf '%s\n' "FAILED: invalid mode '$MODE' (use support or runtime)"; exit 2 ;;
esac

if [ "$(id -u 2>/dev/null || echo 1)" != 0 ]; then
  printf '%s\n' 'FAILED: root required'
  exit 3
fi

slug() { printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'; }
choose_download() {
  for _dir in /sdcard/Download /storage/emulated/0/Download; do
    [ -d "$_dir" ] && [ -w "$_dir" ] && { printf '%s\n' "$_dir"; return 0; }
  done
  printf '%s\n' /data/local/tmp
}
sha_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" 2>/dev/null | awk '{print $1}'
  elif [ -x /data/adb/magisk/busybox ]; then
    /data/adb/magisk/busybox sha256sum "$1" 2>/dev/null | awk '{print $1}'
  else
    printf '%s\n' unavailable
  fi
}
bytes_file() { wc -c < "$1" 2>/dev/null | tr -d ' '; }
copy_if_readable() {
  _src="$1"; _dst="$2"; _limit="${3:-4194304}"
  [ -r "$_src" ] || return 0
  _bytes="$(bytes_file "$_src")"
  case "$_bytes" in ''|*[!0-9]*) return 0 ;; esac
  [ "$_bytes" -le "$_limit" ] || return 0
  mkdir -p "${_dst%/*}" 2>/dev/null || true
  cp -fp "$_src" "$_dst" 2>/dev/null || cat "$_src" > "$_dst" 2>/dev/null || true
}
copy_tail_if_readable() {
  _src="$1"; _dst="$2"; [ -r "$_src" ] || return 0
  mkdir -p "${_dst%/*}" 2>/dev/null || true
  tail -n 4000 "$_src" > "$_dst" 2>/dev/null || true
}
collect_cmd() { _name="$1"; shift; { "$@"; } > "$COLLECT/$_name" 2>&1 || true; }
prop_value() { [ -r "$1" ] && sed -n "s/^$2=//p" "$1" | head -n 1; }
filter_boot_log() {
  grep -i -E 'pixel-thermal|pixel-10-pro-xl-thermal-fix|thermal|thermalservice|thermal-service|hal_thermal|android.hardware.thermal|bootguard|skip_mount|magisk|kernelsu|ksud|sukisu|apatch|overlayfs|magic.?mount|lmkd|lowmemorykiller|fatal signal|fatal exception|watchdog|tombstone|avc: denied' 2>/dev/null || true
}

DL="$(choose_download)"
DEVICE_SLUG="$(slug "$DEVICE")"
BUILD_SLUG="$(slug "$BUILD_ID")"
WORK="/data/local/tmp/pixel_thermal_online_debug_$TS"
COLLECT="$WORK/pixel_thermal_online_debug_$TS"
BASE="pixel_thermal_online_debug_${MODE}_${DEVICE_SLUG}_${BUILD_SLUG}_$TS"
ZIP="$DL/$BASE.zip"
TGZ="$DL/$BASE.tar.gz"
rm -rf "$WORK" 2>/dev/null || true
mkdir -p "$COLLECT/device" "$COLLECT/hardware" "$COLLECT/thermal/sources" \
  "$COLLECT/thermal/runtime" "$COLLECT/modules" "$COLLECT/persistent" \
  "$COLLECT/runtime" "$COLLECT/root" "$COLLECT/hashes" "$COLLECT/logs" \
  "$COLLECT/pstore" "$COLLECT/tombstones" 2>/dev/null || exit 4

MODULE_PROP="$ACTIVE_MOD/module.prop"
MODULE_VERSION="$(prop_value "$MODULE_PROP" version)"
MODULE_VERSION_CODE="$(prop_value "$MODULE_PROP" versionCode)"

{
  printf '%s\n' "schema=$SCHEMA"
  printf '%s\n' "mode=$MODE"
  printf '%s\n' "created=$TS"
  printf '%s\n' "device=$DEVICE"
  printf '%s\n' "model=$MODEL"
  printf '%s\n' "android=$ANDROID"
  printf '%s\n' "build_id=$BUILD_ID"
  printf '%s\n' "incremental=$INCREMENTAL"
  printf '%s\n' "soc_model=$SOC_MODEL"
  printf '%s\n' "board_platform=$BOARD_PLATFORM"
  printf '%s\n' "module_version=${MODULE_VERSION:-missing}"
  printf '%s\n' "module_version_code=${MODULE_VERSION_CODE:-missing}"
  if [ "$MODE" = support ]; then
    printf '%s\n' 'privacy=support mode excludes logcat dmesg tombstone contents account lists and app lists'
  else
    printf '%s\n' 'privacy=runtime mode includes filtered system logs; review archive before sharing'
  fi
  printf '%s\n' 'modification=none; collector does not enable Thermal/Polling or change module configuration'
} > "$COLLECT/README_REVIEW_BEFORE_UPLOAD.txt"

{
  printf '%s\n' "model=$MODEL"
  printf '%s\n' "device=$DEVICE"
  printf '%s\n' "android=$ANDROID"
  printf '%s\n' "sdk=$(getprop ro.build.version.sdk 2>/dev/null || true)"
  printf '%s\n' "build_id=$BUILD_ID"
  printf '%s\n' "incremental=$INCREMENTAL"
  printf '%s\n' "security_patch=$(getprop ro.build.version.security_patch 2>/dev/null || true)"
  printf '%s\n' "battery_level=$(dumpsys battery 2>/dev/null | sed -n 's/^[[:space:]]*level: //p' | head -n 1)"
  printf '%s\n' "selinux=$(getenforce 2>/dev/null || true)"
  printf '%s\n' "kernel_release=$(uname -r 2>/dev/null || true)"
} > "$COLLECT/device/device.env"

{
  for _p in ro.product.device ro.product.vendor.device ro.product.board ro.board.platform ro.hardware ro.boot.hardware ro.boot.hardware.platform ro.boot.hardware.sku ro.soc.manufacturer ro.soc.model ro.product.first_api_level ro.vendor.api_level; do
    printf '%s=%s\n' "$_p" "$(getprop "$_p" 2>/dev/null || true)"
  done
} > "$COLLECT/hardware/platform-properties.env"
collect_cmd hardware/cpuinfo-filtered.txt sh -c "grep -E '^(processor|Hardware|model name|Features|CPU implementer|CPU part)' /proc/cpuinfo 2>/dev/null"

printf '%s\n' 'label\troot\tpresent\tlegacy_3_of_3\tclass' > "$COLLECT/thermal/source-candidates.tsv"
printf '%s\n' 'label\toriginal\tarchive_relative\tbytes\tsha256' > "$COLLECT/thermal/inventory.tsv"
printf '%s\n' 'label\tfile\tPollingDelay_total\tv300000\tv5000\tv30000\tHotThreshold\ttarget_names\tvalues' > "$COLLECT/thermal/metrics.tsv"
printf '%s\n' 'label\tfile\tkey\tvalue\tcount' > "$COLLECT/thermal/delay-key-values.tsv"

legacy_complete() {
  [ -r "$1/thermal_info_config.json" ] && [ -r "$1/thermal_info_config_charge.json" ] && [ -r "$1/thermal_info_config_throttling.json" ]
}
label_root() {
  case "$1" in
    /data/adb/magisk/mirror/vendor/etc) printf '%s\n' magisk_mirror_vendor ;;
    /data/adb/magisk/mirror/system/vendor/etc) printf '%s\n' magisk_mirror_system_vendor ;;
    /sbin/.magisk/mirror/vendor/etc) printf '%s\n' legacy_magisk_mirror_vendor ;;
    /sbin/.magisk/mirror/system/vendor/etc) printf '%s\n' legacy_magisk_mirror_system_vendor ;;
    /vendor/etc) printf '%s\n' live_vendor ;;
    /system/vendor/etc) printf '%s\n' live_system_vendor ;;
    /odm/etc) printf '%s\n' odm ;;
    /product/etc) printf '%s\n' product ;;
    /system_ext/etc) printf '%s\n' system_ext ;;
    *) slug "$1" ;;
  esac
}
metric_file() {
  _label="$1"; _orig="$2"; _copy="$3"; [ -r "$_copy" ] || return 0
  _total="$(grep -Eo '"PollingDelay"[[:space:]]*:[[:space:]]*[0-9]+' "$_copy" 2>/dev/null | wc -l | tr -d ' ')"
  _a="$(grep -Eo '"PollingDelay"[[:space:]]*:[[:space:]]*300000([^0-9]|$)' "$_copy" 2>/dev/null | wc -l | tr -d ' ')"
  _b="$(grep -Eo '"PollingDelay"[[:space:]]*:[[:space:]]*5000([^0-9]|$)' "$_copy" 2>/dev/null | wc -l | tr -d ' ')"
  _c="$(grep -Eo '"PollingDelay"[[:space:]]*:[[:space:]]*30000([^0-9]|$)' "$_copy" 2>/dev/null | wc -l | tr -d ' ')"
  _hot="$(grep -Eo '"HotThreshold"[[:space:]]*:' "$_copy" 2>/dev/null | wc -l | tr -d ' ')"
  _targets="$(grep -E '"Name"[[:space:]]*:[[:space:]]*"(VIRTUAL-SKIN|cellular-emergency)' "$_copy" 2>/dev/null | wc -l | tr -d ' ')"
  _values="$(grep -Eo '"PollingDelay"[[:space:]]*:[[:space:]]*[0-9]+' "$_copy" 2>/dev/null | sed -E 's/.*:[[:space:]]*//' | sort -n | uniq -c | awk 'BEGIN{f=1}{if(!f)printf ",";printf "%s:%s",$2,$1;f=0}END{print ""}')"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$_label" "$_orig" "${_total:-0}" "${_a:-0}" "${_b:-0}" "${_c:-0}" "${_hot:-0}" "${_targets:-0}" "${_values:-none}" >> "$COLLECT/thermal/metrics.tsv"
  grep -Eo '"[A-Za-z0-9_]*(Delay|Interval)[A-Za-z0-9_]*"[[:space:]]*:[[:space:]]*[0-9]+' "$_copy" 2>/dev/null | sed -E 's/^"([^"]+)"[[:space:]]*:[[:space:]]*([0-9]+)$/\1 \2/' | sort | uniq -c | while read -r _count _key _value; do
    [ -n "$_key" ] || continue
    printf '%s\t%s\t%s\t%s\t%s\n' "$_label" "$_orig" "$_key" "$_value" "$_count" >> "$COLLECT/thermal/delay-key-values.tsv"
  done
}
inventory_root() {
  _root="$1"; _class="$2"; _label="$(label_root "$_root")"
  _present=no; _legacy=no
  [ -d "$_root" ] && _present=yes
  legacy_complete "$_root" && _legacy=yes
  printf '%s\t%s\t%s\t%s\t%s\n' "$_label" "$_root" "$_present" "$_legacy" "$_class" >> "$COLLECT/thermal/source-candidates.tsv"
  [ "$_present" = yes ] || return 0
  find "$_root" -maxdepth 3 -type f \( -name 'thermal_info_config*.json' -o -name '*thermal*.rc' -o -name '*thermal*.xml' \) -print 2>/dev/null | sort | head -80 | while IFS= read -r _file; do
    _rel="${_file#$_root/}"
    _dst="$COLLECT/thermal/sources/$_label/$_rel"
    copy_if_readable "$_file" "$_dst" 4194304
    [ -r "$_dst" ] || continue
    printf '%s\t%s\t%s\t%s\t%s\n' "$_label" "$_file" "thermal/sources/$_label/$_rel" "$(bytes_file "$_dst")" "$(sha_file "$_dst")" >> "$COLLECT/thermal/inventory.tsv"
    case "$_file" in *.json) metric_file "$_label" "$_file" "$_dst" ;; esac
  done
}

inventory_root /data/adb/magisk/mirror/vendor/etc stock_mirror
inventory_root /data/adb/magisk/mirror/system/vendor/etc stock_mirror
inventory_root /sbin/.magisk/mirror/vendor/etc stock_mirror
inventory_root /sbin/.magisk/mirror/system/vendor/etc stock_mirror
inventory_root /vendor/etc active_or_stock
inventory_root /system/vendor/etc active_or_stock
inventory_root /odm/etc partition
inventory_root /product/etc partition
inventory_root /system_ext/etc partition

for _view in active staged; do
  [ "$_view" = active ] && _mod="$ACTIVE_MOD" || _mod="$STAGED_MOD"
  [ -d "$_mod" ] || continue
  _dst="$COLLECT/modules/$_view"
  mkdir -p "$_dst" 2>/dev/null || true
  for _file in module.prop install-state.txt supported_versions.json health.log guard/manager-status.env guard/manager-status.txt guard/last_good.env guard/pending_boot.env guard/outdoor-delta-validation.env guard/patch-manifest.tsv validation_report.json; do
    copy_if_readable "$_mod/$_file" "$_dst/$_file" 4194304
  done
  for _flag in disable skip_mount remove; do [ -e "$_mod/$_flag" ] && printf '%s\n' present > "$_dst/flag-$_flag.txt" || printf '%s\n' absent > "$_dst/flag-$_flag.txt"; done
  find "$_mod/system/vendor/etc" -maxdepth 1 -type f -name 'thermal_info_config*.json' -print 2>/dev/null | while IFS= read -r _file; do copy_if_readable "$_file" "$_dst/overlay/${_file##*/}" 4194304; done
 done

copy_if_readable "$DATA_ROOT/config.env" "$COLLECT/persistent/config.env" 1048576
find "$DATA_ROOT/validation" -maxdepth 1 -type f -print 2>/dev/null | while IFS= read -r _file; do copy_if_readable "$_file" "$COLLECT/persistent/validation/${_file##*/}" 4194304; done
collect_cmd thermal/runtime/dumpsys-thermalservice.txt dumpsys thermalservice
collect_cmd thermal/runtime/service-list.txt service list
collect_cmd runtime/mountinfo-filtered.txt sh -c "grep -Ei 'thermal|/vendor|/odm|pixel-10-pro-xl-thermal-fix|pixel.?9|stallion' /proc/self/mountinfo 2>/dev/null"
collect_cmd runtime/proc-swaps.txt cat /proc/swaps
collect_cmd root/su-version.txt su -v
collect_cmd root/su-version-code.txt su -V

if [ "$MODE" = runtime ]; then
  collect_cmd runtime/dmesg.txt dmesg
  logcat -b all -d -v threadtime 2>/dev/null | filter_boot_log > "$COLLECT/logs/logcat-filtered.txt" || true
  logcat -b crash -d -v threadtime 2>/dev/null > "$COLLECT/logs/logcat-crash.txt" || true
  for _log in /data/adb/magisk.log /data/adb/magisk/magisk.log /data/adb/ksud.log /data/adb/ksu/log /data/adb/ksu/ksud.log /data/adb/apatch.log; do
    [ -r "$_log" ] || continue
    _name="$(printf '%s' "$_log" | tr '/' '_')"
    copy_tail_if_readable "$_log" "$COLLECT/logs/$_name.txt"
  done
  if [ -d /sys/fs/pstore ]; then find /sys/fs/pstore -maxdepth 1 -type f -print 2>/dev/null | while IFS= read -r _file; do copy_if_readable "$_file" "$COLLECT/pstore/${_file##*/}" 4194304; done; fi
  { ls -la /data/tombstones 2>/dev/null || true; ls -la /data/anr 2>/dev/null || true; } > "$COLLECT/tombstones/index.txt"
fi

LEGACY_LAYOUT=no
if legacy_complete /vendor/etc || legacy_complete /system/vendor/etc; then LEGACY_LAYOUT=yes; fi
DISCOVERED="$(find /vendor/etc /system/vendor/etc -maxdepth 1 -type f -name 'thermal_info_config*.json' -print 2>/dev/null | sed 's#.*/##' | sort -u | tr '\n' ',' | sed 's/,$//')"
{
  printf '%s\n' "schema=$SCHEMA"
  printf '%s\n' "mode=$MODE"
  printf '%s\n' "device=$DEVICE"
  printf '%s\n' "model=$MODEL"
  printf '%s\n' "android=$ANDROID"
  printf '%s\n' "build_id=$BUILD_ID"
  printf '%s\n' "soc_model=$SOC_MODEL"
  printf '%s\n' "board_platform=$BOARD_PLATFORM"
  printf '%s\n' "legacy_controlled_3_file_layout=$LEGACY_LAYOUT"
  printf '%s\n' "discovered_vendor_thermal_json=${DISCOVERED:-none}"
  printf '%s\n' 'decision_gate=compare_layout_delay_keys_targets_and_runtime_before_device_allowlist_or_module_family_change'
  printf '%s\n' 'support_enabled_by_this_run=no'
} > "$COLLECT/summary.env"

find "$COLLECT" -type f -print 2>/dev/null | sort | while IFS= read -r _file; do printf '%s\t%s\t%s\n' "${_file#$COLLECT/}" "$(bytes_file "$_file")" "$(sha_file "$_file")"; done > "$COLLECT/hashes/files.tsv"

archive_zip() {
  for _zip in /data/data/com.termux/files/usr/bin/zip /system/bin/zip /vendor/bin/zip "$(command -v zip 2>/dev/null || true)"; do
    [ -x "$_zip" ] || continue
    (cd "$WORK" && "$_zip" -qr "$ZIP" "${COLLECT##*/}") >/dev/null 2>&1 && return 0
  done
  if command -v 7z >/dev/null 2>&1; then
    (cd "$WORK" && 7z a -tzip -mx=5 "$ZIP" "${COLLECT##*/}" >/dev/null 2>&1) && return 0
  fi
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
if archive_zip; then
  ARCHIVE="$ZIP"
elif archive_tgz; then
  ARCHIVE="$TGZ"
else
  printf '%s\n' 'FAILED: no archive engine available'
  printf '%s\n' "Work dir left at: $COLLECT"
  exit 5
fi
ARCHIVE_SHA256="$(sha_file "$ARCHIVE")"
ARCHIVE_BYTES="$(bytes_file "$ARCHIVE")"
rm -rf "$WORK" 2>/dev/null || true
printf '%s\n' "Created: $ARCHIVE"
printf '%s\n' "ARCHIVE_BYTES=$ARCHIVE_BYTES"
printf '%s\n' "ARCHIVE_SHA256=$ARCHIVE_SHA256"
printf '%s\n' "MODE_RECORDED=$MODE"
printf '%s\n' "DEVICE_RECORDED=$DEVICE"
printf '%s\n' "BUILD_RECORDED=$BUILD_ID"
printf '%s\n' 'Review README_REVIEW_BEFORE_UPLOAD.txt before sharing.'
printf '%s\n' 'RESULT: PIXEL_THERMAL_ONLINE_DEBUG_DONE outcome=success workflow_exit_code=0'
exit 0
