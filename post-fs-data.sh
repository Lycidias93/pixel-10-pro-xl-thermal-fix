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
  log_line "PASSIVE_ARM device=$device android=$android build=$build_id incremental=$incremental scope=$scope universal_guard=true"
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
    case "$device" in
      mustang) ;;
      *) disable_wrong_target "unsupported_android17_device_$device"; exit 0 ;;
    esac
    case "$fingerprint" in
      google/mustang_beta/mustang:CinnamonBun/CP31.260508.005/15421345:user/release-keys) ;;
      *) disable_wrong_target "unsupported_android17_fingerprint"; exit 0 ;;
    esac
    case "$incremental" in
      15421345) passive_arm "android17_mustang_cp31_15421345"; exit 0 ;;
      *) disable_wrong_target "unsupported_android17_incremental_$incremental"; exit 0 ;;
    esac
    ;;
  *)
    disable_wrong_target "unsupported_android_$android"
    exit 0
    ;;
esac
