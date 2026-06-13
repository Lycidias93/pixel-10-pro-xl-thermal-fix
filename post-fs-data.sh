#!/system/bin/sh
MODDIR=${0%/*}
GUARDDIR="$MODDIR/guard"
LOG="$GUARDDIR/bootguard.log"
mkdir -p "$GUARDDIR"
log_line() { echo "$(date -Is 2>/dev/null || date) $*" >> "$LOG"; }
disable_wrong_target() { reason="$1"; log_line "DISABLE wrong_target reason=$reason"; echo "$reason" > "$GUARDDIR/disabled_reason"; touch "$MODDIR/disable" "$MODDIR/skip_mount"; sync; }
soft_conflict_ptune() { path="$1"; log_line "SOFT_CONFLICT pTune path=$path action=skip_mount_only"; echo "conflict_ptune_active" > "$GUARDDIR/disabled_reason"; echo "$path" > "$GUARDDIR/conflict_ptune_path"; echo "soft_skip_mount_only" > "$GUARDDIR/conflict_guard_mode"; rm -f "$MODDIR/disable" "$MODDIR/remove" 2>/dev/null || true; touch "$MODDIR/skip_mount"; sync; }
passive_arm() { scope="$1"; rm -f "$MODDIR/disable" "$MODDIR/skip_mount" "$MODDIR/remove" 2>/dev/null || true; log_line "PASSIVE_ARM device=$device android=$android build=$build_id incremental=$incremental scope=$scope universal_guard=true selinux_policy=thermal_hal_system_file_read_only"; }

ptune_active_path() {
  for d in /data/adb/modules/ptune /data/adb/modules_update/ptune; do
    [ -f "$d/module.prop" ] || continue
    grep -q '^id=ptune$' "$d/module.prop" 2>/dev/null || continue
    [ -e "$d/remove" ] && continue
    [ -e "$d/disable" ] && continue
    echo "$d"
    return 0
  done
  return 1
}
device="$(getprop ro.product.device 2>/dev/null)"
android="$(getprop ro.build.version.release 2>/dev/null)"
build_id="$(getprop ro.build.id 2>/dev/null)"
fingerprint="$(getprop ro.build.fingerprint 2>/dev/null)"
incremental="$(getprop ro.build.version.incremental 2>/dev/null)"

ptune_conflict="$(ptune_active_path 2>/dev/null || true)"
if [ -n "$ptune_conflict" ]; then
  soft_conflict_ptune "$ptune_conflict"
  exit 0
fi
case "$android" in
  16|16.*)
    case "$fingerprint" in *":16/"*) ;; *) disable_wrong_target "android16_fingerprint_mismatch"; exit 0 ;; esac
    case "$device" in mustang|frankel|blazer|rango) passive_arm "android16_pixel10_universal"; exit 0 ;; *) disable_wrong_target "unsupported_android16_device_$device"; exit 0 ;; esac ;;
  17|17.*)
    case "$device" in
      mustang)
        case "$fingerprint" in
          google/mustang_beta/mustang:CinnamonBun/CP31.260508.005/15421345:user/release-keys) case "$incremental" in 15421345) passive_arm "android17_mustang_cp31_15421345"; exit 0 ;; *) disable_wrong_target "unsupported_android17_cp31_incremental_$incremental"; exit 0 ;; esac ;;
          *":CinnamonBun/CP21.260330.011/"*|*":17/CP21.260330.011/"*) passive_arm "android17_mustang_cp21_guarded_pending"; exit 0 ;;
          *) disable_wrong_target "unsupported_android17_mustang_fingerprint"; exit 0 ;;
        esac ;;
      frankel|blazer|rango)
        case "$build_id" in CP21.260330.011) ;; *) disable_wrong_target "unsupported_android17_cp21_build_$build_id"; exit 0 ;; esac
        case "$fingerprint" in *":CinnamonBun/CP21.260330.011/"*|*":17/CP21.260330.011/"*) passive_arm "android17_${device}_cp21_guarded_pending"; exit 0 ;; *) disable_wrong_target "unsupported_android17_cp21_fingerprint"; exit 0 ;; esac ;;
      *) disable_wrong_target "unsupported_android17_device_$device"; exit 0 ;;
    esac ;;
  *) disable_wrong_target "unsupported_android_$android"; exit 0 ;;
esac
