#!/system/bin/sh
MODDIR=${0%/*}
GUARDDIR="$MODDIR/guard"
LOG="$GUARDDIR/bootguard.log"

mkdir -p "$GUARDDIR"

log_line() {
  echo "$(date -Is 2>/dev/null || date) $*" >> "$LOG"
}

disable_wrong_target() {
  reason="$1"
  log_line "DISABLE wrong_target reason=$reason"
  echo "$reason" > "$GUARDDIR/disabled_reason"
  touch "$MODDIR/disable" "$MODDIR/skip_mount"
  sync
}

passive_arm() {
  scope="$1"
  rm -f "$MODDIR/disable" "$MODDIR/skip_mount" "$MODDIR/remove" 2>/dev/null || true
  log_line "PASSIVE_ARM device=$device android=$android build=$build_id incremental=$incremental scope=$scope universal_cp21_test_guard=true"
}

device="$(getprop ro.product.device 2>/dev/null)"
android="$(getprop ro.build.version.release 2>/dev/null)"
build_id="$(getprop ro.build.id 2>/dev/null)"
fingerprint="$(getprop ro.build.fingerprint 2>/dev/null)"
incremental="$(getprop ro.build.version.incremental 2>/dev/null)"

case "$android" in
  16|16.*)
    case "$fingerprint" in
      *":16/"*) ;;
      *) disable_wrong_target "android16_fingerprint_mismatch"; exit 0 ;;
    esac
    case "$device" in
      mustang|frankel|blazer|rango) passive_arm "android16_pixel10_universal"; exit 0 ;;
      *) disable_wrong_target "unsupported_android16_device_$device"; exit 0 ;;
    esac
    ;;
  17|17.*)
    case "$device:$fingerprint:$incremental" in
      mustang:google/mustang_beta/mustang:CinnamonBun/CP31.260508.005/15421345:user/release-keys:15421345) passive_arm "android17_mustang_cp31_15421345_verified"; exit 0 ;;
    esac
    case "$build_id" in
      CP21.260330.011) ;;
      *) disable_wrong_target "unsupported_android17_build_$build_id"; exit 0 ;;
    esac
    case "$device:$fingerprint" in
      frankel:google/frankel_beta/frankel:CinnamonBun/CP21.260330.011/*:user/release-keys) passive_arm "android17_cp21_frankel_test_unverified"; exit 0 ;;
      blazer:google/blazer_beta/blazer:CinnamonBun/CP21.260330.011/*:user/release-keys) passive_arm "android17_cp21_blazer_test_unverified"; exit 0 ;;
      mustang:google/mustang_beta/mustang:CinnamonBun/CP21.260330.011/*:user/release-keys) passive_arm "android17_cp21_mustang_test_unverified"; exit 0 ;;
      rango:google/rango_beta/rango:CinnamonBun/CP21.260330.011/*:user/release-keys) passive_arm "android17_cp21_rango_test_unverified"; exit 0 ;;
      *) disable_wrong_target "unsupported_android17_cp21_fingerprint_$device"; exit 0 ;;
    esac
    ;;
  *)
    disable_wrong_target "unsupported_android_$android"
    exit 0
    ;;
esac
