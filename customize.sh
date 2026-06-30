#!/system/bin/sh
SKIPUNZIP=0
MODULE_ID="pixel-10-pro-xl-thermal-fix"
MODULE_PROP="${MODPATH:-.}/module.prop"
if [ -r "$MODULE_PROP" ]; then
  MODULE_VERSION="$(sed -n 's/^version=//p' "$MODULE_PROP" | head -n 1)"
  MODULE_VERSION_CODE="$(sed -n 's/^versionCode=//p' "$MODULE_PROP" | head -n 1)"
fi
[ -n "$MODULE_VERSION" ] || MODULE_VERSION="1.4.13-universal-test.3"
[ -n "$MODULE_VERSION_CODE" ] || MODULE_VERSION_CODE="1015303"
A16_PROFILE_SOURCE_BUILD="CP1A.260505.005"
A17_CP31_PROFILE_SOURCE_BUILD="CP31.260508.005"
A17_CP31_PROFILE_SOURCE_INCREMENTAL="15421345"
A17_CP31_EXPECTED_FINGERPRINT="google/mustang_beta/mustang:CinnamonBun/CP31.260508.005/15421345:user/release-keys"
A17_CP31_QPR1B4_PROFILE_SOURCE_BUILD="CP31.260522.006"
A17_CP31_QPR1B4_PROFILE_SOURCE_INCREMENTAL="15591510"
A17_CP31_QPR1B4_EXPECTED_FINGERPRINT="google/mustang_beta/mustang:CinnamonBun/CP31.260522.006/15591510:user/release-keys"
A17_CP21_PROFILE_SOURCE_BUILD="CP21.260330.011"
A17_STABLE_CP2A_PROFILE_SOURCE_BUILD="CP2A.260605.012"
A17_STABLE_CP2A_PROFILE_SOURCE_INCREMENTAL="15430684"
A17_STABLE_CP2A_SOURCE_REPORT_SHA256="a17_pixel10_thermal_ptune_magisk_stable_v3_factory_extract"

ui_print "----------------------------------------"
ui_print "  Pixel 10 Thermal & Memory Control"
ui_print "  A17 Thermal Throttle Fix profile installer"
ui_print "----------------------------------------"
ui_print "SELinux read-only ThermalHAL overlay policy included"
ui_print "Stable 1.5 release; stable updateJson now points to 1.5-universal.1"

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
if [ -s "$MODPATH/tools/install-debug.sh" ]; then
  chmod 0755 "$MODPATH/tools/install-debug.sh" 2>/dev/null || true
  . "$MODPATH/tools/install-debug.sh"
else
  ui_print "! Install debug helper missing; autosave disabled"
  thermal_save_install_debug() { :; }
  thermal_collect_debug_on_fail() { :; }
  thermal_abort() { abort "$*"; }
fi
# END PIXEL_THERMAL_INSTALL_DEBUG_AUTOSAVE_V1411



ui_print "- Device: $model ($device)"
ui_print "- Android: $android (SDK $android_sdk) | Build: $build_id"
ui_print "- Root: $root_impl"



CONFIG_DIR="/data/adb/$MODULE_ID"
CONFIG_FILE="$CONFIG_DIR/config.env"
config_get() {
  key="$1"
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^${key}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${key}=//" | tr -d '\r'
}
# BEGIN PIXEL_THERMAL_INSTALL_OPTIONS_MENU_V1413_TEST17
if [ -s "$MODPATH/tools/install-options-menu.sh" ]; then
  chmod 0755 "$MODPATH/tools/menu-cycle.sh" "$MODPATH/tools/install-options-menu.sh" 2>/dev/null || true
  MODULE_ID="$MODULE_ID" MODDIR="$MODPATH" sh "$MODPATH/tools/install-options-menu.sh" install || ui_print "! Install options menu failed nonfatal; using current config/defaults"
else
  ui_print "! Install options menu helper missing; using current config/defaults"
fi
# END PIXEL_THERMAL_INSTALL_OPTIONS_MENU_V1413_TEST17

# BEGIN PIXEL_THERMAL_PTUNE_GUARD_HELPER_V1413_TEST22
if [ -s "$MODPATH/tools/ptune-guard.sh" ]; then
  chmod 0755 "$MODPATH/tools/ptune-guard.sh" 2>/dev/null || true
  . "$MODPATH/tools/ptune-guard.sh"
else
  thermal_abort "! pTune guard helper missing"
fi
# END PIXEL_THERMAL_PTUNE_GUARD_HELPER_V1413_TEST22

if [ -n "$PTUNE_INSTALLED_PATH" ] && [ "$PTUNE_OVERRIDE_ALLOWED" = "1" ]; then
  ui_print "! OVERRIDE: Thermal overlay allowed while pTune is installed"
  ui_print "! Risk_ack accepted: I_UNDERSTAND_BOOTLOOP_RISK"
  [ "$PTUNE_KNOWN_BAD" = "no" ] || ui_print "! Known bad pTune state: $PTUNE_KNOWN_BAD"
fi
case "$android" in
  16|16.*)
    android_guard="android16_pass"
    case "$fingerprint" in *":16/"*) fingerprint_android_guard="fingerprint_android16_pass" ;; *) thermal_abort "! Fingerprint does not identify Android 16 build: $fingerprint" ;; esac
    profile_source_android="16"; profile_source_build="$A16_PROFILE_SOURCE_BUILD"; profile_source_incremental="not_applicable"; source_report_sha256="factory_android16_profile_set"
    case "$build_id" in "$A16_PROFILE_SOURCE_BUILD") build_family="android16_cp1a_260505_005" ;; *) build_family="android16_unverified_build"; ui_print "! Android 16 build differs from source build: $build_id" ;; esac
    case "$device" in
      mustang) profile="mustang"; profile_state="verified_android16_mustang"; case "$fingerprint" in google/mustang/mustang:16/CP1A.260505.005/15081906:user/release-keys) build_state="verified_build" ;; *) build_state="new_or_unverified_mustang_android16_build" ;; esac ;;
      blazer) profile="blazer"; profile_state="verified_android16_blazer"; build_state="${build_family}_blazer_runtime_verified"; ui_print "Blazer Android 16 has runtime PASS evidence" ;;
      frankel) profile="frankel"; profile_state="beta_pending_live_verification"; build_state="${build_family}_frankel_beta"; ui_print "! Frankel Android 16 pending live verification" ;;
      rango) profile="rango"; profile_state="beta_pending_live_verification"; build_state="${build_family}_rango_beta"; ui_print "! Rango Android 16 pending live verification" ;;
      *) thermal_abort "! Unsupported Pixel 10 Android 16 device codename: $device" ;;
    esac
    ;;
  17|17.*)
    android_guard="android17_pass"
    build_guard_mode="android_major_only_unverified_build_allowed"
    profile_source_android="17"
    source_report_sha256="factory_android17_major_guard_test"
    fingerprint_android_guard="android17_major_only_not_exact_build_guard"
    incremental_guard="recorded_unverified_incremental_$incremental"
    case "$device" in
      mustang)
        case "$build_id" in
          CP31.*)
            profile="mustang-android17-cp31"
            profile_state="android17_cp31_major_guard_test_pending_live_verification"
            build_state="android17_mustang_${build_id}_${incremental}_major_guard_test_using_cp31_profile"
            profile_source_build="$A17_CP31_PROFILE_SOURCE_BUILD"
            profile_source_incremental="$A17_CP31_PROFILE_SOURCE_INCREMENTAL"
            ;;
          CP21.*)
            profile="mustang-android17-cp21"
            profile_state="android17_cp21_major_guard_test_pending_live_verification"
            build_state="android17_mustang_${build_id}_${incremental}_major_guard_test_using_cp21_profile"
            profile_source_build="$A17_CP21_PROFILE_SOURCE_BUILD"
            profile_source_incremental="$incremental"
            ;;
          *)
            profile="mustang-android17-stable-cp2a-260605012"
            profile_state="android17_stable_major_guard_test_mustang_runtime_verified_baseline"
            build_state="android17_mustang_${build_id}_${incremental}_major_guard_test_using_cp2a_profile"
            profile_source_build="$A17_STABLE_CP2A_PROFILE_SOURCE_BUILD"
            profile_source_incremental="$A17_STABLE_CP2A_PROFILE_SOURCE_INCREMENTAL"
            source_report_sha256="$A17_STABLE_CP2A_SOURCE_REPORT_SHA256"
            ;;
        esac
        ;;
      blazer|frankel|rango)
        case "$build_id" in
          CP21.*)
            profile="${device}-android17-cp21"
            profile_state="android17_cp21_major_guard_test_pending_live_verification"
            build_state="android17_${device}_${build_id}_${incremental}_major_guard_test_using_cp21_profile"
            profile_source_build="$A17_CP21_PROFILE_SOURCE_BUILD"
            profile_source_incremental="$incremental"
            ;;
          *)
            profile="${device}-android17-stable-cp2a-260605012"
            profile_state="android17_stable_major_guard_test_${device}_pending_live_verification"
            build_state="android17_${device}_${build_id}_${incremental}_major_guard_test_using_cp2a_profile"
            profile_source_build="$A17_STABLE_CP2A_PROFILE_SOURCE_BUILD"
            profile_source_incremental="$A17_STABLE_CP2A_PROFILE_SOURCE_INCREMENTAL"
            source_report_sha256="$A17_STABLE_CP2A_SOURCE_REPORT_SHA256"
            ;;
        esac
        ;;
      *) thermal_abort "! Unsupported Pixel 10 Android 17 device codename: $device" ;;
    esac
    ui_print "! Android 17 build guard relaxed for test build: build=$build_id incremental=$incremental"
    ui_print "! Selected profile by Android major + codename only: $profile"
    ;;
  *) thermal_abort "! Unsupported Android version: $android. This stable build supports Android 16 and guarded Android 17 CP31/CP21/Stable CP2A profiles." ;;
esac

profile_dir="$MODPATH/profiles/$profile/system/vendor/etc"
if [ ! -s "$profile_dir/thermal_info_config_throttling.json" ]; then
  if [ -s "$MODPATH/$profile/thermal_info_config_throttling.json" ]; then
    profile_dir="$MODPATH/$profile"
  elif [ -s "$MODPATH/profiles/$profile/thermal_info_config_throttling.json" ]; then
    profile_dir="$MODPATH/profiles/$profile"
  fi
fi

# BEGIN PIXEL_THERMAL_INSTALL_OVERLAY_HELPER_V1413_TEST27
if [ -s "$MODPATH/tools/install-thermal-overlay.sh" ]; then
  chmod 0755 "$MODPATH/tools/install-thermal-overlay.sh" 2>/dev/null || true
  . "$MODPATH/tools/install-thermal-overlay.sh"
  thermal_install_overlay
else
  thermal_abort "! Thermal overlay install helper missing"
fi
# END PIXEL_THERMAL_INSTALL_OVERLAY_HELPER_V1413_TEST27

# BEGIN PIXEL_THERMAL_POLLING_MODE_V1413_TEST17
if [ -s "$MODPATH/tools/apply-polling-mode.sh" ]; then
  chmod 0755 "$MODPATH/tools/apply-polling-mode.sh" 2>/dev/null || true
  BASE_PROFILE="$base_profile" ACTIVE_DIR="$active_dir" MODDIR="$MODPATH" CONFIG_FILE="$CONFIG_FILE" sh "$MODPATH/tools/apply-polling-mode.sh" install || ui_print "! Polling mode helper failed nonfatal; keeping materialized profile polling"
else
  ui_print "! Polling mode helper missing; keeping materialized profile polling"
fi
# END PIXEL_THERMAL_POLLING_MODE_V1413_TEST17

# BEGIN PIXEL_THERMAL_INSTALL_ZRAM_HELPER_V1413_TEST25
if [ -s "$MODPATH/tools/install-zram.sh" ]; then
  chmod 0755 "$MODPATH/tools/install-zram.sh" 2>/dev/null || true
  . "$MODPATH/tools/install-zram.sh"
  thermal_install_zram
else
  ui_print "! ZRAM install helper missing; keeping existing/safe config"
fi
# END PIXEL_THERMAL_INSTALL_ZRAM_HELPER_V1413_TEST25


for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do [ -s "$active_dir/$f" ] || thermal_abort "! Failed to materialize active file: $f"; done

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
ui_print "- Successfully applied thermal fix for Android $android"


# ZRAM_HELPER_CHMOD_V1412_TEST2: keep helper scripts executable for direct Magisk/KSU shell use.
if [ -d "$MODPATH/tools" ]; then
  chmod 0755 "$MODPATH"/tools/*.sh "$MODPATH"/tools/resetprop-rs 2>/dev/null || true
fi
