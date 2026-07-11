#!/system/bin/sh
# Exact Git-backed Pixel thermal profile resolver.
# Source this file and call thermal_resolve_profile, or execute it directly.

thermal_resolver_reset() {
  THERMAL_RESOLVER_STATUS="fail"
  THERMAL_RESOLVER_REASON="unresolved"
  THERMAL_PROFILE_DEVICE=""
  THERMAL_PROFILE_ANDROID=""
  THERMAL_PROFILE_BUILD_ID=""
  THERMAL_PROFILE_CHANNEL=""
  THERMAL_PROFILE_FAMILY=""
  THERMAL_PROFILE_BUILD_SLUG=""
  THERMAL_PROFILE_REL=""
  THERMAL_PROFILE_DIR=""
  THERMAL_PROFILE_ETC=""
  THERMAL_PROFILE_META=""
  THERMAL_PROFILE_JSON_COUNT="0"
  THERMAL_PROFILE_POLLING_300000="0"
  THERMAL_PROFILE_POLLING_FILES="0"
  THERMAL_PROFILE_BUNDLE_SHA256=""
}

thermal_resolve_profile() {
  thermal_resolver_reset
  _tr_moddir="$1"
  _tr_device="$2"
  _tr_android="$3"
  _tr_build="$4"
  _tr_map="$_tr_moddir/profiles/profile-map.tsv"
  _tr_tab="$(printf '\t')"

  [ -n "$_tr_moddir" ] || { THERMAL_RESOLVER_REASON="moddir_missing"; return 20; }
  [ -n "$_tr_device" ] || { THERMAL_RESOLVER_REASON="device_missing"; return 21; }
  [ -n "$_tr_android" ] || { THERMAL_RESOLVER_REASON="android_missing"; return 22; }
  [ -n "$_tr_build" ] || { THERMAL_RESOLVER_REASON="build_missing"; return 23; }
  [ -r "$_tr_map" ] || { THERMAL_RESOLVER_REASON="profile_map_missing"; return 24; }

  _tr_matches=0
  while IFS="$_tr_tab" read -r _tr_dev _tr_and _tr_bid _tr_channel _tr_family _tr_slug _tr_rel _tr_count _tr_poll _tr_poll_files _tr_bundle; do
    [ "$_tr_dev" = "device" ] && continue
    [ "$_tr_dev" = "$_tr_device" ] || continue
    [ "$_tr_and" = "$_tr_android" ] || continue
    [ "$_tr_bid" = "$_tr_build" ] || continue
    _tr_matches=$(( _tr_matches + 1 ))
    THERMAL_PROFILE_DEVICE="$_tr_dev"
    THERMAL_PROFILE_ANDROID="$_tr_and"
    THERMAL_PROFILE_BUILD_ID="$_tr_bid"
    THERMAL_PROFILE_CHANNEL="$_tr_channel"
    THERMAL_PROFILE_FAMILY="$_tr_family"
    THERMAL_PROFILE_BUILD_SLUG="$_tr_slug"
    THERMAL_PROFILE_REL="$_tr_rel"
    THERMAL_PROFILE_DIR="$_tr_moddir/$_tr_rel"
    THERMAL_PROFILE_ETC="$THERMAL_PROFILE_DIR/system/vendor/etc"
    THERMAL_PROFILE_META="$THERMAL_PROFILE_DIR/profile-meta.json"
    THERMAL_PROFILE_JSON_COUNT="$_tr_count"
    THERMAL_PROFILE_POLLING_300000="$_tr_poll"
    THERMAL_PROFILE_POLLING_FILES="$_tr_poll_files"
    THERMAL_PROFILE_BUNDLE_SHA256="$_tr_bundle"
  done < "$_tr_map"

  [ "$_tr_matches" -eq 1 ] 2>/dev/null || {
    if [ "$_tr_matches" -eq 0 ] 2>/dev/null; then
      THERMAL_RESOLVER_REASON="exact_profile_not_found"
      return 25
    fi
    THERMAL_RESOLVER_REASON="ambiguous_profile_map"
    return 26
  }

  [ -d "$THERMAL_PROFILE_ETC" ] || { THERMAL_RESOLVER_REASON="profile_etc_missing"; return 27; }
  [ -r "$THERMAL_PROFILE_META" ] || { THERMAL_RESOLVER_REASON="profile_meta_missing"; return 28; }
  case "$THERMAL_PROFILE_JSON_COUNT" in ''|*[!0-9]*|0) THERMAL_RESOLVER_REASON="invalid_profile_json_count"; return 29 ;; esac
  case "$THERMAL_PROFILE_POLLING_300000" in ''|*[!0-9]*) THERMAL_RESOLVER_REASON="invalid_polling_count"; return 30 ;; esac
  case "$THERMAL_PROFILE_BUNDLE_SHA256" in
    [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]*) ;;
    *) THERMAL_RESOLVER_REASON="invalid_bundle_sha256"; return 31 ;;
  esac
  [ "${#THERMAL_PROFILE_BUNDLE_SHA256}" -eq 64 ] 2>/dev/null || { THERMAL_RESOLVER_REASON="invalid_bundle_sha256_length"; return 32; }

  THERMAL_RESOLVER_STATUS="pass"
  THERMAL_RESOLVER_REASON="exact_match"
  return 0
}

thermal_resolve_current_profile() {
  _trc_moddir="$1"
  _trc_device="${2:-$(getprop ro.product.device 2>/dev/null || true)}"
  _trc_android="${3:-$(getprop ro.build.version.release 2>/dev/null || true)}"
  _trc_build="${4:-$(getprop ro.build.id 2>/dev/null || true)}"
  thermal_resolve_profile "$_trc_moddir" "$_trc_device" "$_trc_android" "$_trc_build"
}

thermal_resolver_print() {
  printf '%s\n' "RESOLVER_STATUS=$THERMAL_RESOLVER_STATUS"
  printf '%s\n' "RESOLVER_REASON=$THERMAL_RESOLVER_REASON"
  printf '%s\n' "PROFILE_DEVICE=$THERMAL_PROFILE_DEVICE"
  printf '%s\n' "PROFILE_ANDROID=$THERMAL_PROFILE_ANDROID"
  printf '%s\n' "PROFILE_BUILD_ID=$THERMAL_PROFILE_BUILD_ID"
  printf '%s\n' "PROFILE_CHANNEL=$THERMAL_PROFILE_CHANNEL"
  printf '%s\n' "PROFILE_FAMILY=$THERMAL_PROFILE_FAMILY"
  printf '%s\n' "PROFILE_BUILD_SLUG=$THERMAL_PROFILE_BUILD_SLUG"
  printf '%s\n' "PROFILE_REL=$THERMAL_PROFILE_REL"
  printf '%s\n' "PROFILE_DIR=$THERMAL_PROFILE_DIR"
  printf '%s\n' "PROFILE_ETC=$THERMAL_PROFILE_ETC"
  printf '%s\n' "PROFILE_JSON_COUNT=$THERMAL_PROFILE_JSON_COUNT"
  printf '%s\n' "PROFILE_POLLING_300000=$THERMAL_PROFILE_POLLING_300000"
  printf '%s\n' "PROFILE_POLLING_FILES=$THERMAL_PROFILE_POLLING_FILES"
  printf '%s\n' "PROFILE_BUNDLE_SHA256=$THERMAL_PROFILE_BUNDLE_SHA256"
}

case "${0##*/}" in
  profile-resolver.sh)
    _tr_cli_moddir="${4:-/data/adb/modules/pixel-10-pro-xl-thermal-fix}"
    thermal_resolve_profile "$_tr_cli_moddir" "${1:-}" "${2:-}" "${3:-}" || {
      _tr_cli_rc=$?
      thermal_resolver_print
      exit "$_tr_cli_rc"
    }
    thermal_resolver_print
  ;;
esac
