#!/system/bin/sh
SKIPUNZIP=0
MODULE_ID="pixel-10-pro-xl-thermal-fix"
MODULE_PROP="${MODPATH:-.}/module.prop"
if [ -r "$MODULE_PROP" ]; then
  MODULE_VERSION="$(sed -n 's/^version=//p' "$MODULE_PROP" | head -n 1)"
  MODULE_VERSION_CODE="$(sed -n 's/^versionCode=//p' "$MODULE_PROP" | head -n 1)"
fi
[ -n "$MODULE_VERSION" ] || MODULE_VERSION="1.5.2-universal-test.7"
[ -n "$MODULE_VERSION_CODE" ] || MODULE_VERSION_CODE="1016207"

ui_print "----------------------------------------"
ui_print "  A17 Thermal Throttle Fix profile installer"
ui_print "----------------------------------------"
ui_print "SELinux read-only policy"
case "$MODULE_VERSION" in
  *-test.*) ui_print "Prerelease: $MODULE_VERSION" ;;
  *) ui_print "Release: $MODULE_VERSION" ;;
esac
ui_print "Stable channel: 1.5.1"

model="$(getprop ro.product.model)"
device="$(getprop ro.product.device)"
android="$(getprop ro.build.version.release)"
android_sdk="$(getprop ro.build.version.sdk)"
build_id="$(getprop ro.build.id)"
fingerprint="$(getprop ro.build.fingerprint)"
incremental="$(getprop ro.build.version.incremental)"

root_impl="unknown"
su_v="$(su -v 2>/dev/null || true)"
su_V="$(su -V 2>/dev/null || true)"
case "$su_v $su_V" in
  *SukiSU*|*sukisu*|*ksud*) root_impl="sukisu" ;;
  *KernelSU*Next*|*ksu-next*|*KSU-Next*) root_impl="kernelsu_next" ;;
  *KernelSU*|*ksu*) root_impl="kernelsu" ;;
  *Magisk*|*magisk*) root_impl="magisk" ;;
  *APatch*|*apatch*) root_impl="apatch" ;;
esac
mount_backend_hint="none"
if find /data/adb /debug_ramdisk /sbin -maxdepth 5 \( -iname '*hybrid*mount*' -o -iname '*mountify*' -o -iname '*metamodule*' -o -iname '*meta-module*' \) 2>/dev/null | head -1 | grep -q .; then
  mount_backend_hint="overlay_backend_present"
fi
root_backend_guard_mode="log_only_no_block"

# BEGIN PIXEL_THERMAL_INSTALL_DEBUG_AUTOSAVE_V1411
if [ -s "$MODPATH/tools/debug/install-debug.sh" ]; then
  chmod 0755 "$MODPATH/tools/debug/install-debug.sh" 2>/dev/null || true
  . "$MODPATH/tools/debug/install-debug.sh"
else
  ui_print "! Install debug missing"
  ui_print "! Autosave disabled"
  thermal_save_install_debug() { :; }
  thermal_collect_debug_on_fail() { :; }
  thermal_abort() { abort "$*"; }
fi
# END PIXEL_THERMAL_INSTALL_DEBUG_AUTOSAVE_V1411



ui_print "- Device: $model ($device)"
ui_print "- Android: $android (SDK $android_sdk)"
ui_print "- Build: $build_id"
ui_print "- Root: $root_impl"



CONFIG_DIR="/data/adb/$MODULE_ID"
CONFIG_FILE="$CONFIG_DIR/config.env"
config_get() {
  key="$1"
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^${key}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${key}=//" | tr -d '\r'
}
# BEGIN PIXEL_THERMAL_EXACT_PROFILE_RESOLVER_V2
RESOLVER="$MODPATH/tools/core/profile-resolver.sh"
SOURCE_VERIFY="$MODPATH/tools/core/profile-source-verify.sh"
[ -r "$RESOLVER" ] || thermal_abort "! Exact profile resolver missing"
[ -x "$SOURCE_VERIFY" ] || thermal_abort "! Profile source verifier missing"
. "$RESOLVER"
thermal_resolve_profile "$MODPATH" "$device" "$android" "$build_id" || thermal_abort "! Unsupported exact profile: $device / $android / $build_id ($THERMAL_RESOLVER_REASON)"
sh "$SOURCE_VERIFY" "$MODPATH" "$device" "$android" "$build_id" >/dev/null || thermal_abort "! Git-backed stock profile verification failed"
android_guard="android${android}_exact_profile_pass"
fingerprint_android_guard="exact_build_profile_pass"
incremental_guard="exact_build_${build_id}"
profile="$THERMAL_PROFILE_REL"
profile_state="exact_git_profile"
build_state="exact_${device}_${build_id}_${incremental}"
profile_source_android="$THERMAL_PROFILE_ANDROID"
profile_source_build="$THERMAL_PROFILE_BUILD_ID"
profile_source_incremental="official_factory_stock"
source_report_sha256="$THERMAL_PROFILE_BUNDLE_SHA256"
profile_dir="$THERMAL_PROFILE_DIR"
active_dir="$MODPATH/system/vendor/etc"
ui_print "- Exact profile: $profile"
ui_print "- Source bundle: $source_report_sha256"
# END PIXEL_THERMAL_EXACT_PROFILE_RESOLVER_V2
# BEGIN PIXEL_THERMAL_INSTALL_OPTIONS_MENU_V1413_TEST17
if [ -s "$MODPATH/tools/menu/install-options-menu.sh" ]; then
  chmod 0755 "$MODPATH/tools/menu/menu-cycle.sh" "$MODPATH/tools/menu/install-options-menu.sh" 2>/dev/null || true
  MODULE_ID="$MODULE_ID" MODDIR="$MODPATH" sh "$MODPATH/tools/menu/install-options-menu.sh" install || ui_print "! Install options menu failed nonfatal; using current config/defaults"
else
  ui_print "! Options menu missing"
  ui_print "! Using current/defaults"
fi
# END PIXEL_THERMAL_INSTALL_OPTIONS_MENU_V1413_TEST17

# BEGIN PIXEL_THERMAL_PTUNE_GUARD_HELPER_V1413_TEST22
if [ -s "$MODPATH/tools/ptune/ptune-guard.sh" ]; then
  chmod 0755 "$MODPATH/tools/ptune/ptune-guard.sh" 2>/dev/null || true
  . "$MODPATH/tools/ptune/ptune-guard.sh"
else
  thermal_abort "! pTune guard helper missing"
fi
# END PIXEL_THERMAL_PTUNE_GUARD_HELPER_V1413_TEST22

if [ -n "$PTUNE_INSTALLED_PATH" ] && [ "$PTUNE_OVERRIDE_ALLOWED" = "1" ]; then
  ui_print "! OVERRIDE active"
ui_print "! Thermal allowed with pTune"
  ui_print "! Risk ack accepted"
  [ "$PTUNE_KNOWN_BAD" = "no" ] || ui_print "! Known bad pTune state: $PTUNE_KNOWN_BAD"
fi

# BEGIN PIXEL_THERMAL_INSTALL_OVERLAY_HELPER_V1413_TEST27
if [ -s "$MODPATH/tools/core/install-thermal-overlay.sh" ]; then
  chmod 0755 "$MODPATH/tools/core/install-thermal-overlay.sh" 2>/dev/null || true
  . "$MODPATH/tools/core/install-thermal-overlay.sh"
  thermal_install_overlay
else
  thermal_abort "! Thermal overlay install helper missing"
fi
# END PIXEL_THERMAL_INSTALL_OVERLAY_HELPER_V1413_TEST27

# Polling mode is handled dynamically inside install-thermal-overlay.sh

# BEGIN PIXEL_THERMAL_INSTALL_ZRAM_HELPER_V1413_TEST25
if [ -s "$MODPATH/tools/zram/install-zram.sh" ]; then
  chmod 0755 "$MODPATH/tools/zram/install-zram.sh" 2>/dev/null || true
  . "$MODPATH/tools/zram/install-zram.sh"
  thermal_install_zram
else
  ui_print "! ZRAM helper missing"
  ui_print "! Keeping safe config"
fi
# END PIXEL_THERMAL_INSTALL_ZRAM_HELPER_V1413_TEST25


materialized_count=0
for source_file in "$THERMAL_PROFILE_ETC"/thermal_info_config*.json; do
  [ -f "$source_file" ] || continue
  f="${source_file##*/}"
  [ -s "$MODPATH/system/vendor/etc/$f" ] || thermal_abort "! Failed to materialize active file: $f"
  materialized_count=$(( materialized_count + 1 ))
done
[ "$materialized_count" -eq "$THERMAL_PROFILE_JSON_COUNT" ] 2>/dev/null || thermal_abort "! Materialized file count mismatch: $materialized_count / $THERMAL_PROFILE_JSON_COUNT"

# BEGIN PIXEL_THERMAL_INSTALL_FINALIZE_HELPER_V1413_TEST24
if [ -s "$MODPATH/tools/install-finalize.sh" ]; then
  chmod 0755 "$MODPATH/tools/install-finalize.sh" 2>/dev/null || true
  . "$MODPATH/tools/install-finalize.sh"
  thermal_finalize_install
else
  thermal_abort "! Install finalize helper missing"
fi
# END PIXEL_THERMAL_INSTALL_FINALIZE_HELPER_V1413_TEST24

thermal_save_install_debug "success" "install_completed"
ui_print "- Target validation: PASS"
ui_print "- Thermal fix applied"
ui_print "- Android: $android"


# ZRAM_HELPER_CHMOD_V1412_TEST2: keep helper scripts executable for direct Magisk/KSU shell use.
if [ -d "$MODPATH/tools" ]; then
  chmod -R 0755 "$MODPATH/tools" 2>/dev/null || true
fi
