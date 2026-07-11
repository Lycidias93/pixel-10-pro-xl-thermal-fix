#!/system/bin/sh
# Verify the exact Git-backed stock profile before materialization.
set -u

MODDIR="${1:-/data/adb/modules/pixel-10-pro-xl-thermal-fix}"
DEVICE="${2:-$(getprop ro.product.device 2>/dev/null || true)}"
ANDROID="${3:-$(getprop ro.build.version.release 2>/dev/null || true)}"
BUILD_ID="${4:-$(getprop ro.build.id 2>/dev/null || true)}"
RESOLVER="$MODDIR/tools/core/profile-resolver.sh"
INVENTORY="$MODDIR/profiles/manifests/thermal-stock-inventory.tsv"

fail() {
  _psv_rc="$1"
  shift
  printf '%s\n' "PROFILE_SOURCE_VERIFY=fail"
  printf '%s\n' "PROFILE_SOURCE_VERIFY_REASON=$*"
  exit "$_psv_rc"
}

[ -r "$RESOLVER" ] || fail 20 resolver_missing
. "$RESOLVER"
thermal_resolve_profile "$MODDIR" "$DEVICE" "$ANDROID" "$BUILD_ID" || fail 21 "resolver_$THERMAL_RESOLVER_REASON"
[ -r "$INVENTORY" ] || fail 22 inventory_missing

TAB="$(printf '\t')"
matched=0
verified=0
polling_total=0
polling_files=0

while IFS="$TAB" read -r channel family build device rel bytes expected_sha strict_json tolerant_json poll_total poll_300000 poll_5000 poll_lower poll_30000; do
  [ "$channel" = "channel" ] && continue
  [ "$channel" = "$THERMAL_PROFILE_CHANNEL" ] || continue
  [ "$build" = "$THERMAL_PROFILE_BUILD_ID" ] || continue
  [ "$device" = "$THERMAL_PROFILE_DEVICE" ] || continue
  case "$rel" in
    "$THERMAL_PROFILE_REL"/system/vendor/etc/thermal_info_config*.json) ;;
    *) fail 23 "inventory_path_outside_profile_$rel" ;;
  esac
  matched=$(( matched + 1 ))
  source_file="$MODDIR/$rel"
  [ -s "$source_file" ] || fail 24 "source_file_missing_$rel"
  actual_sha="$(sha256sum "$source_file" 2>/dev/null | awk '{print $1}')"
  [ "$actual_sha" = "$expected_sha" ] || fail 25 "source_sha_mismatch_$rel"
  [ "$poll_5000" = "0" ] || fail 26 "stock_contains_5000_$rel"
  [ "$poll_lower" = "0" ] || fail 27 "stock_contains_lowercase_pollingdelay_$rel"
  [ "$poll_30000" = "0" ] || fail 28 "stock_contains_30000_$rel"
  polling_total=$(( polling_total + poll_300000 ))
  [ "$poll_300000" -eq 0 ] 2>/dev/null || polling_files=$(( polling_files + 1 ))
  verified=$(( verified + 1 ))
done < "$INVENTORY"

[ "$matched" -eq "$THERMAL_PROFILE_JSON_COUNT" ] 2>/dev/null || fail 29 "inventory_count_${matched}_expected_${THERMAL_PROFILE_JSON_COUNT}"
[ "$verified" -eq "$THERMAL_PROFILE_JSON_COUNT" ] 2>/dev/null || fail 30 "verified_count_${verified}_expected_${THERMAL_PROFILE_JSON_COUNT}"
[ "$polling_total" -eq "$THERMAL_PROFILE_POLLING_300000" ] 2>/dev/null || fail 31 "polling_count_${polling_total}_expected_${THERMAL_PROFILE_POLLING_300000}"
[ "$polling_files" -eq "$THERMAL_PROFILE_POLLING_FILES" ] 2>/dev/null || fail 32 "polling_file_count_${polling_files}_expected_${THERMAL_PROFILE_POLLING_FILES}"

actual_files=0
for source_file in "$THERMAL_PROFILE_ETC"/thermal_info_config*.json; do
  [ -f "$source_file" ] || continue
  actual_files=$(( actual_files + 1 ))
done
[ "$actual_files" -eq "$THERMAL_PROFILE_JSON_COUNT" ] 2>/dev/null || fail 33 "profile_directory_count_${actual_files}_expected_${THERMAL_PROFILE_JSON_COUNT}"

printf '%s\n' "PROFILE_SOURCE_VERIFY=pass"
printf '%s\n' "PROFILE_SOURCE=$THERMAL_PROFILE_REL"
printf '%s\n' "PROFILE_SOURCE_FILES=$verified"
printf '%s\n' "PROFILE_SOURCE_POLLING_300000=$polling_total"
printf '%s\n' "PROFILE_SOURCE_POLLING_FILES=$polling_files"
printf '%s\n' "PROFILE_SOURCE_BUNDLE_SHA256=$THERMAL_PROFILE_BUNDLE_SHA256"
exit 0
