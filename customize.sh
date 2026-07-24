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
  *-test.*|*alpha*|*beta*|*rc*|*candidate*) ui_print "Prerelease: $MODULE_VERSION" ;;
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
config_set() {
  key="$1"
  value="$2"
  mkdir -p "$CONFIG_DIR" 2>/dev/null || true
  touch "$CONFIG_FILE" 2>/dev/null || true
  tmp="$CONFIG_FILE.tmp.$$"
  grep -v "^${key}=" "$CONFIG_FILE" 2>/dev/null > "$tmp" || true
  printf '%s=%s\n' "$key" "$value" >> "$tmp"
  mv "$tmp" "$CONFIG_FILE"
  chmod 0600 "$CONFIG_FILE" 2>/dev/null || true
}
# Canary/ZP uses the normal verified dynamic V2 path.

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
# BEGIN PIXEL_THERMAL_VERSION_CHECK_V3
SUPPORTED_JSON="$MODPATH/supported_versions.json"
SUPPORTED_HELPER="$MODPATH/tools/core/supported-build.sh"
[ -r "$SUPPORTED_HELPER" ] || thermal_abort "! supported-build helper missing"
. "$SUPPORTED_HELPER"
thermal_supported_validate_file "$SUPPORTED_JSON" || thermal_abort "! supported_versions.json is invalid"

if ! grep -q "\"$device\"[[:space:]]*:" "$SUPPORTED_JSON"; then
  thermal_abort "! Unsupported device: $device"
fi

THERMAL_INSTALL_ENABLED=0
if thermal_supported_check "$SUPPORTED_JSON" "$device" "$android" "$build_id"; then
  THERMAL_INSTALL_ENABLED=1
  config_set THERMAL_DISABLED 0
  config_set CANARY_DIAGNOSTIC_MODE 0
  ui_print "- Build ID: $build_id (Verified)"
else
  config_set THERMAL_DISABLED 1
  ui_print "! Build ID '$build_id' is not verified for thermal overlay"
  ui_print "- Thermal files will not be installed"
  ui_print "- ZRAM remains available"
fi

android_guard="android${android}_pass"
fingerprint_android_guard="fingerprint_android${android}_pass"
profile_source_android="$android"
profile_source_build="$build_id"
profile_source_incremental="$incremental"
source_report_sha256="dynamic_patching_validated"
build_state="dynamic_${device}_${build_id}_${incremental}"
if [ "$THERMAL_INSTALL_ENABLED" = 1 ]; then
  profile_state="dynamic_verified_${device}_android${android}"
  profile="dynamic/${device}/android${android}"
  profile_materialized=yes
  expected_thermal_files=dynamic_validated
else
  profile_state="thermal_disabled_unsupported_build"
  profile="dynamic/unsupported"
  profile_materialized=no
  expected_thermal_files=0
fi
active_dir="$MODPATH/system/vendor/etc"
# END PIXEL_THERMAL_VERSION_CHECK_V3

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


if [ "$THERMAL_INSTALL_ENABLED" = 1 ]; then
  for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
    [ -s "$MODPATH/system/vendor/etc/$f" ] || thermal_abort "! Failed to materialize active file: $f"
  done
fi

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
if [ "$THERMAL_INSTALL_ENABLED" = 1 ]; then
  ui_print "- Thermal fix applied"
else
  ui_print "- Thermal fix safely disabled for this build"
fi
ui_print "- Android: $android"


# ZRAM_HELPER_CHMOD_V1412_TEST2: keep helper scripts executable for direct Magisk/KSU shell use.
if [ -d "$MODPATH/tools" ]; then
  chmod -R 0755 "$MODPATH/tools" 2>/dev/null || true
fi
