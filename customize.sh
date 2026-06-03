#!/system/bin/sh
SKIPUNZIP=0
MODULE_ID="pixel-10-pro-xl-thermal-fix"
MODULE_VERSION="1.4.3-universal-test.1"
MODULE_VERSION_CODE="1014301"
A16_PROFILE_SOURCE_ANDROID="16"
A16_PROFILE_SOURCE_BUILD="CP1A.260505.005"
A17_PROFILE_SOURCE_ANDROID="17"
A17_PROFILE_SOURCE_BUILD="CP31.260508.005"
A17_PROFILE_SOURCE_INCREMENTAL="15421345"
A17_EXPECTED_FINGERPRINT="google/mustang_beta/mustang:CinnamonBun/CP31.260508.005/15421345:user/release-keys"

ui_print "----------------------------------------"
ui_print "  Pixel 10 Thermal Polling Fix"
ui_print "  Universal test profile guard"
ui_print "----------------------------------------"
ui_print "Running install-time profile guard"

model="$(getprop ro.product.model)"
device="$(getprop ro.product.device)"
android="$(getprop ro.build.version.release)"
android_sdk="$(getprop ro.build.version.sdk)"
build_id="$(getprop ro.build.id)"
fingerprint="$(getprop ro.build.fingerprint)"
incremental="$(getprop ro.build.version.incremental)"

ui_print "model=$model"
ui_print "device=$device"
ui_print "android=$android"
ui_print "android_sdk=$android_sdk"
ui_print "build_id=$build_id"
ui_print "incremental=$incremental"

case "$android" in
  16|16.*)
    android_guard="android16_pass"
    case "$fingerprint" in
      *":16/"*) fingerprint_android_guard="fingerprint_android16_pass" ;;
      *) abort "! Fingerprint does not identify Android 16 build: $fingerprint" ;;
    esac
    profile_source_android="$A16_PROFILE_SOURCE_ANDROID"
    profile_source_build="$A16_PROFILE_SOURCE_BUILD"
    profile_source_incremental="not_applicable"
    source_report_sha256="factory_android16_profile_set"
    case "$build_id" in
      "$A16_PROFILE_SOURCE_BUILD") build_family="android16_cp1a_260505_005" ;;
      *)
        build_family="android16_unverified_build"
        ui_print "! Android 16 build differs from factory evidence build: build_id=$build_id source=$A16_PROFILE_SOURCE_BUILD"
        ui_print "! Continue only as beta/unverified unless this build is later factory-dumped and documented"
        ;;
    esac
    case "$device" in
      mustang)
        profile="mustang"
        profile_state="verified_android16"
        case "$fingerprint" in
          google/mustang/mustang:16/CP1A.260505.005/15081906:user/release-keys) build_state="verified_build" ;;
          *) build_state="new_or_unverified_mustang_android16_build"; ui_print "! Mustang Android 16 build not fork-verified yet: $fingerprint" ;;
        esac
        ;;
      frankel)
        profile="frankel"; profile_state="beta_pending_live_verification"; build_state="${build_family}_frankel_beta"; ui_print "! Frankel profile is beta/pending live ThermalHAL verification" ;;
      blazer)
        profile="blazer"; profile_state="beta_pending_live_verification"; build_state="${build_family}_blazer_beta"; ui_print "! Blazer profile is beta/pending live ThermalHAL verification" ;;
      rango)
        profile="rango"; profile_state="beta_pending_live_verification"; build_state="${build_family}_rango_beta"; ui_print "! Rango profile is beta/pending live ThermalHAL verification" ;;
      *) abort "! Unsupported Pixel 10 Android 16 device codename: $device" ;;
    esac
    ;;
  17|17.*)
    android_guard="android17_pass"
    case "$device" in
      mustang) profile="mustang-android17-cp31"; profile_state="tester_verified_android17_cp31" ;;
      *) abort "! Android 17 is currently supported only for Pixel 10 Pro XL / mustang in this test build. device=$device" ;;
    esac
    case "$fingerprint" in
      "$A17_EXPECTED_FINGERPRINT") fingerprint_android_guard="exact_android17_mustang_cp31_pass"; build_state="android17_mustang_cp31_15421345_tester_verified" ;;
      *) abort "! Android 17 fingerprint mismatch. Expected $A17_EXPECTED_FINGERPRINT but got $fingerprint" ;;
    esac
    case "$incremental" in
      "$A17_PROFILE_SOURCE_INCREMENTAL") incremental_guard="incremental_pass" ;;
      *) abort "! Android 17 incremental mismatch. Expected $A17_PROFILE_SOURCE_INCREMENTAL but got $incremental" ;;
    esac
    profile_source_android="$A17_PROFILE_SOURCE_ANDROID"
    profile_source_build="$A17_PROFILE_SOURCE_BUILD"
    profile_source_incremental="$A17_PROFILE_SOURCE_INCREMENTAL"
    source_report_sha256="d16d0d985efdf2c9c4c2152b7a9a4c172d00cf647ca2a08b7610d610380ec599"
    ;;
  *)
    abort "! Unsupported Android version: $android. This test build supports Android 16 profiles and Android 17 Mustang CP31 only."
    ;;
esac

profile_dir="$MODPATH/profiles/$profile/system/vendor/etc"
active_dir="$MODPATH/system/vendor/etc"

for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
  [ -s "$profile_dir/$f" ] || abort "! Missing profile file: $profile/$f"
done

[ -r /vendor/etc/thermal_info_config_throttling.json ] || abort "! Stock thermal throttling config not readable"
case "$android" in
  17|17.*) grep -q "VIRTUAL-SKIN-OVER-35C-TRIGGER" /vendor/etc/thermal_info_config_throttling.json || abort "! Expected Android 17 Mustang stock marker missing" ;;
  *) grep -q "VIRTUAL-SKIN" /vendor/etc/thermal_info_config_throttling.json || abort "! Expected stock thermal marker missing" ;;
esac

ui_print "selected_profile=$profile"
ui_print "profile_state=$profile_state"
ui_print "build_state=$build_state"
ui_print "profile_source_android=$profile_source_android"
ui_print "profile_source_build=$profile_source_build"
ui_print "profile_source_incremental=$profile_source_incremental"
ui_print "Materializing selected profile into active Magisk overlay path"

rm -rf "$active_dir"
mkdir -p "$active_dir"
cp -fp "$profile_dir"/*.json "$active_dir"/
for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
  [ -s "$active_dir/$f" ] || abort "! Failed to materialize active file: $f"
done

rm -f "$MODPATH/disable" "$MODPATH/skip_mount" "$MODPATH/remove"
mkdir -p "$MODPATH/guard"
rm -f "$MODPATH/guard/pending_boot" "$MODPATH/guard/fail_count" "$MODPATH/guard/disabled_reason"
[ -s "$MODPATH/tools/collect-debug.sh" ] && chmod 0755 "$MODPATH/tools/collect-debug.sh" || true

cat > "$MODPATH/install-state.txt" <<EOF
module_id=$MODULE_ID
module_version=$MODULE_VERSION
module_version_code=$MODULE_VERSION_CODE
device=$device
profile=$profile
profile_state=$profile_state
build_state=$build_state
android=$android
android_sdk=$android_sdk
build_id=$build_id
incremental=$incremental
android_guard=$android_guard
fingerprint_android_guard=$fingerprint_android_guard
incremental_guard=${incremental_guard:-not_applicable}
profile_source_android=$profile_source_android
profile_source_build=$profile_source_build
profile_source_incremental=$profile_source_incremental
source_report_sha256=$source_report_sha256
profile_materialized=yes
active_overlay_dir=system/vendor/etc
expected_thermal_files=3
polling_values_changed_by_this_release=source_profile_only
bind_mount_model=no
live_runtime_text_patch_model=no
update_json_channel=stable_main_update_json_unchanged
debug_collector=manual_only
debug_collector_command=su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
debug_zip_target=/sdcard/Download/pixel_thermal_debug_*.zip
EOF

ui_print "Target guard PASS"
case "$android" in
  17|17.*) ui_print "Android 17 Mustang CP31 tester-verified profile selected" ;;
  *) ui_print "Android 16 profile selected" ;;
esac
ui_print "Manual debug collector: su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh"
ui_print "No automatic debug collection, no bind mounts, no runtime text patching"
