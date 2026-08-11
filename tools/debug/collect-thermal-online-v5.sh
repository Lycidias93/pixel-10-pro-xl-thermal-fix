#!/system/bin/sh
# Read-only online collector for Pixel Thermal runtime failures and platform-support planning.
# Helper functions run in subshells so scratch variables cannot corrupt caller state.
set -u

ID="pixel-10-pro-xl-thermal-fix"
SCHEMA="pixel-thermal-online-debug-v5"
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

slug() (
  printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'
)

choose_download() (
  for c_dir in /sdcard/Download /storage/emulated/0/Download; do
    [ -d "$c_dir" ] && [ -w "$c_dir" ] && { printf '%s\n' "$c_dir"; exit 0; }
  done
  printf '%s\n' /data/local/tmp
)

sha_file() (
  c_path="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$c_path" 2>/dev/null | awk '{print $1}'
  elif [ -x /data/adb/magisk/busybox ]; then
    /data/adb/magisk/busybox sha256sum "$c_path" 2>/dev/null | awk '{print $1}'
  else
    printf '%s\n' unavailable
  fi
)

bytes_file() (
  wc -c < "$1" 2>/dev/null | tr -d ' '
)

copy_file() (
  c_src="$1"
  c_dst="$2"
  c_limit="${3:-4194304}"
  [ -r "$c_src" ] || exit 0
  c_bytes="$(bytes_file "$c_src")"
  case "$c_bytes" in ''|*[!0-9]*) exit 0 ;; esac
  [ "$c_bytes" -le "$c_limit" ] || exit 0
  mkdir -p "${c_dst%/*}" 2>/dev/null || exit 0
  cp -fp "$c_src" "$c_dst" 2>/dev/null || cat "$c_src" > "$c_dst" 2>/dev/null || true
)

copy_tail() (
  c_src="$1"
  c_dst="$2"
  [ -r "$c_src" ] || exit 0
  mkdir -p "${c_dst%/*}" 2>/dev/null || exit 0
  tail -n 4000 "$c_src" > "$c_dst" 2>/dev/null || true
)

collect_cmd() (
  c_name="$1"
  shift
  mkdir -p "${COLLECT}/${c_name%/*}" 2>/dev/null || true
  { "$@"; } > "$COLLECT/$c_name" 2>&1 || true
)

prop_value() (
  c_file="$1"
  c_key="$2"
  [ -r "$c_file" ] || exit 0
  sed -n "s/^${c_key}=//p" "$c_file" | head -n 1
)

filter_boot_log() {
  grep -i -E 'pixel-thermal|pixel-10-pro-xl-thermal-fix|thermal|thermalservice|thermal-service|hal_thermal|android.hardware.thermal|bootguard|skip_mount|magisk|kernelsu|ksud|sukisu|apatch|overlayfs|magic.?mount|lmkd|lowmemorykiller|fatal signal|fatal exception|watchdog|tombstone|avc: denied' 2>/dev/null || true
}

legacy_complete() (
  c_root="$1"
  [ -r "$c_root/thermal_info_config.json" ] &&
  [ -r "$c_root/thermal_info_config_charge.json" ] &&
  [ -r "$c_root/thermal_info_config_throttling.json" ]
)

label_root() (
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
)

metric_file() (
  c_label="$1"
  c_orig="$2"
  c_copy="$3"
  [ -r "$c_copy" ] || exit 0
  c_total="$(grep -Eo '"PollingDelay"[[:space:]]*:[[:space:]]*[0-9]+' "$c_copy" 2>/dev/null | wc -l | tr -d ' ')"
  c_300000="$(grep -Eo '"PollingDelay"[[:space:]]*:[[:space:]]*300000([^0-9]|$)' "$c_copy" 2>/dev/null | wc -l | tr -d ' ')"
  c_5000="$(grep -Eo '"PollingDelay"[[:space:]]*:[[:space:]]*5000([^0-9]|$)' "$c_copy" 2>/dev/null | wc -l | tr -d ' ')"
  c_30000="$(grep -Eo '"PollingDelay"[[:space:]]*:[[:space:]]*30000([^0-9]|$)' "$c_copy" 2>/dev/null | wc -l | tr -d ' ')"
  c_hot="$(grep -Eo '"HotThreshold"[[:space:]]*:' "$c_copy" 2>/dev/null | wc -l | tr -d ' ')"
  c_targets="$(grep -E '"Name"[[:space:]]*:[[:space:]]*"(VIRTUAL-SKIN|cellular-emergency)"' "$c_copy" 2>/dev/null | wc -l | tr -d ' ')"
  c_values="$(grep -Eo '"PollingDelay"[[:space:]]*:[[:space:]]*[0-9]+' "$c_copy" 2>/dev/null | sed -E 's/.*:[[:space:]]*//' | sort -n | uniq -c | awk 'BEGIN{f=1}{if(!f)printf ",";printf "%s:%s",$2,$1;f=0}END{print ""}')"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$c_label" "$c_orig" "${c_total:-0}" "${c_300000:-0}" "${c_5000:-0}" "${c_30000:-0}" "${c_hot:-0}" "${c_targets:-0}" "${c_values:-none}" >> "$COLLECT/thermal/metrics.tsv"
  grep -Eo '"[A-Za-z0-9_]*(Delay|Interval)[A-Za-z0-9_]*"[[:space:]]*:[[:space:]]*[0-9]+' "$c_copy" 2>/dev/null | sed -E 's/^"([^"]+)"[[:space:]]*:[[:space:]]*([0-9]+)$/\1 \2/' | sort | uniq -c | while read -r c_count c_key c_value; do
    [ -n "$c_key" ] || continue
    printf '%s\t%s\t%s\t%s\t%s\n' "$c_label" "$c_orig" "$c_key" "$c_value" "$c_count" >> "$COLLECT/thermal/delay-key-values.tsv"
  done
)

inventory_root() (
  c_root="$1"
  c_class="$2"
  c_label="$(label_root "$c_root")"
  c_present=no
  c_legacy=no
  [ -d "$c_root" ] && c_present=yes
  legacy_complete "$c_root" && c_legacy=yes
  printf '%s\t%s\t%s\t%s\t%s\n' "$c_label" "$c_root" "$c_present" "$c_legacy" "$c_class" >> "$COLLECT/thermal/source-candidates.tsv"
  [ "$c_present" = yes ] || exit 0
  find "$c_root" -maxdepth 3 -type f \( -name 'thermal_info_config*.json' -o -name '*thermal*.rc' -o -name '*thermal*.xml' \) -print 2>/dev/null | sort | head -80 | while IFS= read -r c_file; do
    c_rel="${c_file#$c_root/}"
    c_dst="$COLLECT/thermal/sources/$c_label/$c_rel"
    copy_file "$c_file" "$c_dst" 4194304
    [ -r "$c_dst" ] || continue
    printf '%s\t%s\t%s\t%s\t%s\n' "$c_label" "$c_file" "thermal/sources/$c_label/$c_rel" "$(bytes_file "$c_dst")" "$(sha_file "$c_dst")" >> "$COLLECT/thermal/inventory.tsv"
    case "$c_file" in *.json) metric_file "$c_label" "$c_file" "$c_dst" ;; esac
  done
)

archive_zip() (
  for c_zip in /data/data/com.termux/files/usr/bin/zip /system/bin/zip /vendor/bin/zip "$(command -v zip 2>/dev/null || true)"; do
    [ -x "$c_zip" ] || continue
    (cd "$WORK" && "$c_zip" -qr "$ZIP" "${COLLECT##*/}") >/dev/null 2>&1 && exit 0
  done
  exit 1
)

archive_7z() (
  for c_7z in /data/data/com.termux/files/usr/bin/7z /system/bin/7z "$(command -v 7z 2>/dev/null || true)"; do
    [ -x "$c_7z" ] || continue
    (cd "$WORK" && "$c_7z" a -tzip -mx=5 "$ZIP" "${COLLECT##*/}" >/dev/null 2>&1) && exit 0
  done
  exit 1
)

archive_tgz() (
  for c_tar in /system/bin/tar /vendor/bin/tar /data/data/com.termux/files/usr/bin/tar "$(command -v tar 2>/dev/null || true)"; do
    [ -x "$c_tar" ] || continue
    (cd "$WORK" && "$c_tar" -czf "$TGZ" "${COLLECT##*/}") >/dev/null 2>&1 && exit 0
  done
  exit 1
)

DL="$(choose_download)"
DEVICE_SLUG="$(slug "$DEVICE")"
BUILD_SLUG="$(slug "$BUILD_ID")"
WORK="/data/local/tmp/pixel_thermal_online_debug_$TS"
COLLECT="$WORK/pixel_thermal_online_debug_$TS"
BASE="pixel_thermal_online_debug_${MODE}_${DEVICE_SLUG}_${BUILD_SLUG}_$TS"
ZIP="$DL/$BASE.zip"
TGZ="$DL/$BASE.tar.gz"
rm -rf "$WORK" 2>/dev/null || true
mkdir -p "$COLLECT/device" "$COLLECT/hardware" "$COLLECT/thermal/sources" "$COLLECT/thermal/runtime" "$COLLECT/modules" "$COLLECT/persistent" "$COLLECT/runtime" "$COLLECT/root" "$COLLECT/hashes" "$COLLECT/logs" "$COLLECT/pstore" "$COLLECT/tombstones" 2>/dev/null || exit 4

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
    printf '%s\n' 'privacy=runtime mode includes filtered system/root logs; review archive before sharing'
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
  for p_name in ro.product.device ro.product.vendor.device ro.product.board ro.board.platform ro.hardware ro.boot.hardware ro.boot.hardware.platform ro.boot.hardware.sku ro.soc.manufacturer ro.soc.model ro.product.first_api_level ro.vendor.api_level; do
    printf '%s=%s\n' "$p_name" "$(getprop "$p_name" 2>/dev/null || true)"
  done
} > "$COLLECT/hardware/platform-properties.env"
collect_cmd hardware/cpuinfo-filtered.txt sh -c "grep -E '^(processor|Hardware|model name|Features|CPU implementer|CPU part)' /proc/cpuinfo 2>/dev/null"

printf '%s\n' 'label\troot\tpresent\tlegacy_3_of_3\tclass' > "$COLLECT/thermal/source-candidates.tsv"
printf '%s\n' 'label\toriginal\tarchive_relative\tbytes\tsha256' > "$COLLECT/thermal/inventory.tsv"
printf '%s\n' 'label\tfile\tPollingDelay_total\tv300000\tv5000\tv30000\tHotThreshold\ttarget_names\tvalues' > "$COLLECT/thermal/metrics.tsv"
printf '%s\n' 'label\tfile\tkey\tvalue\tcount' > "$COLLECT/thermal/delay-key-values.tsv"

inventory_root /data/adb/magisk/mirror/vendor/etc stock_mirror
inventory_root /data/adb/magisk/mirror/system/vendor/etc stock_mirror
inventory_root /sbin/.magisk/mirror/vendor/etc stock_mirror
inventory_root /sbin/.magisk/mirror/system/vendor/etc stock_mirror
inventory_root /vendor/etc active_or_stock
inventory_root /system/vendor/etc active_or_stock
inventory_root /odm/etc partition
inventory_root /product/etc partition
inventory_root /system_ext/etc partition

for view_name in active staged; do
  if [ "$view_name" = active ]; then module_root="$ACTIVE_MOD"; else module_root="$STAGED_MOD"; fi
  [ -d "$module_root" ] || continue
  module_dst="$COLLECT/modules/$view_name"
  mkdir -p "$module_dst" 2>/dev/null || true
  for module_file in module.prop install-state.txt supported_versions.json health.log guard/manager-status.env guard/manager-status.txt guard/last_good.env guard/pending_boot.env guard/outdoor-delta-validation.env guard/patch-manifest.tsv validation_report.json; do
    copy_file "$module_root/$module_file" "$module_dst/$module_file" 4194304
  done
  for module_flag in disable skip_mount remove; do
    if [ -e "$module_root/$module_flag" ]; then printf '%s\n' present > "$module_dst/flag-$module_flag.txt"; else printf '%s\n' absent > "$module_dst/flag-$module_flag.txt"; fi
  done
  find "$module_root/system/vendor/etc" -maxdepth 1 -type f -name 'thermal_info_config*.json' -print 2>/dev/null | while IFS= read -r overlay_file; do
    copy_file "$overlay_file" "$module_dst/overlay/${overlay_file##*/}" 4194304
  done
done

copy_file "$DATA_ROOT/config.env" "$COLLECT/persistent/config.env" 1048576
find "$DATA_ROOT/validation" -maxdepth 1 -type f -print 2>/dev/null | while IFS= read -r validation_file; do
  copy_file "$validation_file" "$COLLECT/persistent/validation/${validation_file##*/}" 4194304
done

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
  for root_log in /data/adb/magisk.log /data/adb/magisk/magisk.log /data/adb/ksud.log /data/adb/ksu/log /data/adb/ksu/ksud.log /data/adb/apatch.log; do
    [ -r "$root_log" ] || continue
    root_log_name="$(printf '%s' "$root_log" | tr '/' '_')"
    copy_tail "$root_log" "$COLLECT/logs/$root_log_name.txt"
  done
  if [ -d /sys/fs/pstore ]; then
    find /sys/fs/pstore -maxdepth 1 -type f -print 2>/dev/null | while IFS= read -r pstore_file; do
      copy_file "$pstore_file" "$COLLECT/pstore/${pstore_file##*/}" 4194304
    done
  fi
  { ls -la /data/tombstones 2>/dev/null || true; ls -la /data/anr 2>/dev/null || true; } > "$COLLECT/tombstones/index.txt"
fi

LEGACY_LAYOUT=no
legacy_complete /vendor/etc && LEGACY_LAYOUT=yes
DISCOVERED_VENDOR_JSON="$(find /vendor/etc -maxdepth 1 -type f -name 'thermal_info_config*.json' -print 2>/dev/null | sed 's#.*/##' | sort | paste -sd, - 2>/dev/null || true)"
[ -n "$DISCOVERED_VENDOR_JSON" ] || DISCOVERED_VENDOR_JSON=none
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
  printf '%s\n' "discovered_vendor_thermal_json=$DISCOVERED_VENDOR_JSON"
  printf '%s\n' 'decision_gate=compare_layout_delay_keys_targets_and_runtime_before_device_allowlist_or_module_family_change'
  printf '%s\n' 'support_enabled_by_this_run=no'
} > "$COLLECT/summary.env"

find "$COLLECT" -type f -print 2>/dev/null | sort | while IFS= read -r hash_file; do
  printf '%s\t%s\t%s\n' "${hash_file#$COLLECT/}" "$(bytes_file "$hash_file")" "$(sha_file "$hash_file")"
done > "$COLLECT/hashes/files.tsv"

rm -f "$ZIP" "$TGZ" 2>/dev/null || true
ARCHIVE=""
if archive_zip; then ARCHIVE="$ZIP"; elif archive_7z; then ARCHIVE="$ZIP"; elif archive_tgz; then ARCHIVE="$TGZ"; else
  printf '%s\n' 'FAILED: no archive engine available (zip, 7z, or tar required)'
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
printf '%s\n' 'RESULT: PIXEL_THERMAL_ONLINE_DEBUG_V5_DONE outcome=success workflow_exit_code=0'
exit 0
