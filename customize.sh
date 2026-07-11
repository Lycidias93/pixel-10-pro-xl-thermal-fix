#!/system/bin/sh
SKIPUNZIP=0
MODULE_ID="pixel-10-pro-xl-thermal-fix"
MODULE_PROP="${MODPATH:-.}/module.prop"
if [ -r "$MODULE_PROP" ]; then
  MODULE_VERSION="$(sed -n 's/^version=//p' "$MODULE_PROP" | head -n 1)"
  MODULE_VERSION_CODE="$(sed -n 's/^versionCode=//p' "$MODULE_PROP" | head -n 1)"
fi
[ -n "$MODULE_VERSION" ] || MODULE_VERSION="1.5.2-universal-test.3"
[ -n "$MODULE_VERSION_CODE" ] || MODULE_VERSION_CODE="1016203"

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
# BEGIN CANARY_DIAGNOSTIC_NO_OVERLAY_V152T7
case "$build_id:$fingerprint" in
  ZP*:*|*:*/ZP*|*:CANARY/*)
    ui_print "! Canary/ZP diagnostic mode"
    ui_print "! No thermal overlay, no ZRAM, no Outdoor profile"
    android_guard="android17_canary_diagnostic_pass"
    fingerprint_android_guard="canary_zp_diagnostic_guard"
    incremental_guard="canary_zp_recorded_$incremental"
    profile="diagnostic/no-overlay"
    profile_state="canary_zp_diagnostic_no_overlay_no_zram"
    build_state="canary_zp_${device}_${build_id}_${incremental}_diagnostic_no_overlay_no_zram"
    profile_source_android="17"
    profile_source_build="none_diagnostic"
    profile_source_incremental="none_diagnostic"
    source_report_sha256="canary_diagnostic_no_overlay_no_zram"
    profile_dir="none"
    active_dir="none"
    PTUNE_GUARD_MODE="diagnostic"
    PTUNE_INSTALLED_PATH="unset"
    PTUNE_ACTIVE_PATH="unset"
    PTUNE_CONFLICT_PATH="unset"
    PTUNE_CONFLICT_MODE="diagnostic_no_overlay"
    PTUNE_OVERRIDE_ALLOWED="0"
    PTUNE_KNOWN_BAD="not_checked_diagnostic"
    PTUNE_RISK_ACK_STATE="not_applicable_diagnostic"
    PTUNE_OVERRIDE_NAME="none"
    THERMAL_OUTDOOR_PROFILE="stock"
    mkdir -p "$CONFIG_DIR" "$MODPATH/guard"
    {
      echo "DEBUG_MODE=1"
      echo "debug_mode=1"
      echo "ENABLE_ZRAM_100P=0"
      echo "ZRAM_RESTART_MMD=0"
      echo "ZRAM_RISK_ACK=diagnostic_disabled"
      echo "THERMAL_OUTDOOR_PROFILE=stock"
      echo "THERMAL_OUTDOOR_TARGET=stock"
      echo "THERMAL_SETTINGS_MODE=canary_diagnostic"
      echo "THERMAL_POLLING_MODE=stock"
      echo "THERMAL_POLLING_EFFECTIVE=stock"
      echo "BOOTGUARD_FAIL_THRESHOLD=1"
      echo "CANARY_DIAGNOSTIC_MODE=1"
    } > "$CONFIG_FILE"
    rm -rf "$MODPATH/system"
    if [ -s "$MODPATH/tools/debug/preinstall-debug.sh" ]; then
      chmod 0755 "$MODPATH/tools/debug/preinstall-debug.sh" 2>/dev/null || true
      MODULE_VERSION="$MODULE_VERSION" MODULE_VERSION_CODE="$MODULE_VERSION_CODE" sh "$MODPATH/tools/debug/preinstall-debug.sh" install || true
    fi
    {
      echo "module_id=$MODULE_ID"
      echo "module_version=$MODULE_VERSION"
      echo "module_version_code=$MODULE_VERSION_CODE"
      echo "device=$device"
      echo "profile=$profile"
      echo "profile_state=$profile_state"
      echo "build_state=$build_state"
      echo "android=$android"
      echo "android_sdk=$android_sdk"
      echo "build_id=$build_id"
      echo "incremental=$incremental"
      echo "android_guard=$android_guard"
      echo "fingerprint_android_guard=$fingerprint_android_guard"
      echo "incremental_guard=$incremental_guard"
      echo "profile_source_android=$profile_source_android"
      echo "profile_source_build=$profile_source_build"
      echo "profile_source_incremental=$profile_source_incremental"
      echo "source_report_sha256=$source_report_sha256"
      echo "profile_materialized=no"
      echo "overlay_materializer=canary_diagnostic_no_overlay_v152t7"
      echo "active_overlay_dir=none"
      echo
      echo "zram_fstab_materialized=no"
      echo "zram_feature=disabled_canary_diagnostic"
      echo "zram_apply_stage=disabled"
      echo "thermal_outdoor_profile=stock"
      echo "thermal_outdoor_target=stock"
      echo "thermal_polling_mode=stock"
      echo "thermal_polling_effective=stock"
      echo "debug_collector=canary_preinstall_debug_v152t7"
      echo "debug_zip_target=/sdcard/Download/pixel_thermal_canary_diagnostic_*.tgz"
    } > "$MODPATH/install-state.txt"
    thermal_save_install_debug "success" "canary_diagnostic_no_overlay_no_zram"
    ui_print "- Diagnostic install-state written"
    ui_print "- Debug TGZ: /sdcard/Download/pixel_thermal_canary_diagnostic_*.tgz"
    ui_print "- Reboot test: safe diagnostic, no overlay"
    exit 0
  ;;
esac
# END CANARY_DIAGNOSTIC_NO_OVERLAY_V152T7
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
# BEGIN PIXEL_THERMAL_VERSION_CHECK_V2
SUPPORTED_JSON="$MODPATH/supported_versions.json"
if [ ! -f "$SUPPORTED_JSON" ]; then
  thermal_abort "! Central database (supported_versions.json) is missing!"
fi

# Verify device
if ! grep -q "\"$device\"[[:space:]]*:" "$SUPPORTED_JSON"; then
  thermal_abort "! Unsupported device: $device"
fi

# Verify Android version
if ! grep -q "\"$android\"" "$SUPPORTED_JSON" && ! grep -q "\"$android_sdk\"" "$SUPPORTED_JSON"; then
  thermal_abort "! Unsupported Android version: $android (SDK $android_sdk)"
fi

# Verify build ID (warning if unverified, but allow install)
if grep -q "\"$build_id\"" "$SUPPORTED_JSON"; then
  ui_print "- Build ID: $build_id (Verified)"
else
  ui_print "! Warning: Build ID '$build_id' is unverified for this module."
  ui_print "! Installation will proceed, but you might encounter issues."
fi

android_guard="android${android}_pass"
fingerprint_android_guard="fingerprint_android${android}_pass"
profile_source_android="$android"
profile_source_build="$build_id"
profile_source_incremental="$incremental"
source_report_sha256="dynamic_patching_active"
build_state="dynamic_${device}_${build_id}_${incremental}"
profile_state="dynamic_${device}_android${android}"
profile="dynamic/${device}/android${android}"
active_dir="$MODPATH/system/vendor/etc"
# END PIXEL_THERMAL_VERSION_CHECK_V2

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


for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do [ -s "$MODPATH/system/vendor/etc/$f" ] || thermal_abort "! Failed to materialize active file: $f"; done

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
