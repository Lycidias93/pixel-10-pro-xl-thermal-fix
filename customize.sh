#!/system/bin/sh
SKIPUNZIP=0
MODULE_ID="pixel-10-pro-xl-thermal-fix"
MODULE_VERSION="1.4.4-universal-test.1"
MODULE_VERSION_CODE="1014401"
A16_PROFILE_SOURCE_ANDROID="16"
A16_PROFILE_SOURCE_BUILD="CP1A.260505.005"
A17_CP31_PROFILE_SOURCE_ANDROID="17"
A17_CP31_PROFILE_SOURCE_BUILD="CP31.260508.005"
A17_CP31_PROFILE_SOURCE_INCREMENTAL="15421345"
A17_CP31_EXPECTED_FINGERPRINT="google/mustang_beta/mustang:CinnamonBun/CP31.260508.005/15421345:user/release-keys"
A17_CP21_PROFILE_SOURCE_ANDROID="17"
A17_CP21_PROFILE_SOURCE_BUILD="CP21.260330.011"

ui_print "----------------------------------------"
ui_print "  Pixel 10 Thermal Polling Fix"
ui_print "  Universal A17 CP21 test guard"
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
        profile_state="verified_android16_mustang"
        verification_state="PASS_ANDROID16_MUSTANG"
        case "$fingerprint" in
          google/mustang/mustang:16/CP1A.260505.005/15081906:user/release-keys) build_state="verified_build" ;;
          *) build_state="new_or_unverified_mustang_android16_build"; ui_print "! Mustang Android 16 build not fork-verified yet: $fingerprint" ;;
        esac
        ;;
      frankel)
        profile="frankel"; profile_state="beta_pending_live_verification"; verification_state="PENDING_ANDROID16_FRANKEL"; build_state="${build_family}_frankel_beta"; ui_print "! Frankel Android 16 profile is beta/pending live ThermalHAL verification" ;;
      blazer)
        profile="blazer"; profile_state="tester_verified_android16_blazer"; verification_state="PASS_ANDROID16_BLAZER"; build_state="${build_family}_blazer_tester_verified"; ui_print "! Blazer Android 16 PASS is tester-verified; continue reporting debug ZIPs for new builds" ;;
      rango)
        profile="rango"; profile_state="beta_pending_live_verification"; verification_state="PENDING_ANDROID16_RANGO"; build_state="${build_family}_rango_beta"; ui_print "! Rango Android 16 profile is beta/pending live ThermalHAL verification" ;;
      *) abort "! Unsupported Pixel 10 Android 16 device codename: $device" ;;
    esac
    ;;
  17|17.*)
    android_guard="android17_pass"
    case "$fingerprint" in
      *":CinnamonBun/"*) fingerprint_family_guard="fingerprint_android17_cinnamonbun_pass" ;;
      *) abort "! Fingerprint does not identify Android 17 CinnamonBun build: $fingerprint" ;;
    esac
    case "$device" in
      mustang)
        case "$fingerprint" in
          "$A17_CP31_EXPECTED_FINGERPRINT")
            profile="mustang-android17-cp31"
            profile_state="tester_verified_android17_cp31"
            verification_state="PASS_ANDROID17_MUSTANG_CP31"
            fingerprint_android_guard="exact_android17_mustang_cp31_pass"
            build_state="android17_mustang_cp31_15421345_tester_verified"
            case "$incremental" in
              "$A17_CP31_PROFILE_SOURCE_INCREMENTAL") incremental_guard="incremental_pass" ;;
              *) abort "! Android 17 Mustang CP31 incremental mismatch. Expected $A17_CP31_PROFILE_SOURCE_INCREMENTAL but got $incremental" ;;
            esac
            profile_source_android="$A17_CP31_PROFILE_SOURCE_ANDROID"
            profile_source_build="$A17_CP31_PROFILE_SOURCE_BUILD"
            profile_source_incremental="$A17_CP31_PROFILE_SOURCE_INCREMENTAL"
            source_report_sha256="d16d0d985efdf2c9c4c2152b7a9a4c172d00cf647ca2a08b7610d610380ec599"
            ;;
          google/mustang_beta/mustang:CinnamonBun/CP21.260330.011/*:user/release-keys)
            profile="mustang-android17-cp21"
            profile_state="test_unverified_android17_cp21"
            verification_state="PENDING_ANDROID17_MUSTANG_CP21"
            fingerprint_android_guard="pattern_android17_mustang_cp21_pass"
            incremental_guard="cp21_incremental_unverified_$incremental"
            build_state="android17_cp21_mustang_test_unverified"
            profile_source_android="$A17_CP21_PROFILE_SOURCE_ANDROID"
            profile_source_build="$A17_CP21_PROFILE_SOURCE_BUILD"
            profile_source_incremental="cp21_beta_device_incremental_unverified"
            source_report_sha256="factory_android17_cp21_pending_evidence"
            ui_print "! Android 17 Mustang CP21 is enabled for test only; CP31 is the only Android 17 Mustang PASS build"
            ;;
          *) abort "! Unsupported Android 17 Mustang fingerprint/build: $fingerprint" ;;
        esac
        ;;
      frankel|blazer|rango)
        case "$build_id" in
          "$A17_CP21_PROFILE_SOURCE_BUILD") ;;
          *) abort "! Android 17 $device requires CP21 test build $A17_CP21_PROFILE_SOURCE_BUILD. Current build_id=$build_id" ;;
        esac
        case "$device:$fingerprint" in
          frankel:google/frankel_beta/frankel:CinnamonBun/CP21.260330.011/*:user/release-keys) ;;
          blazer:google/blazer_beta/blazer:CinnamonBun/CP21.260330.011/*:user/release-keys) ;;
          rango:google/rango_beta/rango:CinnamonBun/CP21.260330.011/*:user/release-keys) ;;
          *) abort "! Android 17 CP21 fingerprint mismatch for $device: $fingerprint" ;;
        esac
        profile="$device-android17-cp21"
        profile_state="test_unverified_android17_cp21"
        verification_state="PENDING_ANDROID17_${device}_CP21"
        fingerprint_android_guard="pattern_android17_${device}_cp21_pass"
        incremental_guard="cp21_incremental_unverified_$incremental"
        build_state="android17_cp21_${device}_test_unverified"
        profile_source_android="$A17_CP21_PROFILE_SOURCE_ANDROID"
        profile_source_build="$A17_CP21_PROFILE_SOURCE_BUILD"
        profile_source_incremental="cp21_beta_device_incremental_unverified"
        source_report_sha256="factory_android17_cp21_pending_evidence"
        ui_print "! Android 17 $device CP21 profile is enabled for TEST only and is NOT runtime PASS yet"
        ;;
      *) abort "! Unsupported Pixel 10 Android 17 device codename: $device" ;;
    esac
    ;;
  *)
    abort "! Unsupported Android version: $android. This universal test build supports Android 16 Pixel 10 profiles and Android 17 CP31/CP21 guarded profiles only."
    ;;
esac

profile_dir="$MODPATH/profiles/$profile/system/vendor/etc"
active_dir="$MODPATH/system/vendor/etc"

for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
  [ -s "$profile_dir/$f" ] || abort "! Missing profile file: $profile/$f"
done

[ -r /vendor/etc/thermal_info_config_throttling.json ] || abort "! Stock thermal throttling config not readable"
case "$android" in
  17|17.*) grep -q "VIRTUAL-SKIN" /vendor/etc/thermal_info_config_throttling.json || abort "! Expected Android 17 stock VIRTUAL-SKIN marker missing" ;;
  *) grep -q "VIRTUAL-SKIN" /vendor/etc/thermal_info_config_throttling.json || abort "! Expected stock thermal marker missing" ;;
esac

ui_print "selected_profile=$profile"
ui_print "profile_state=$profile_state"
ui_print "verification_state=$verification_state"
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
verification_state=$verification_state
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
update_json_channel=stable_update_json_stays_on_1.4.3-universal.2
release_channel=prerelease_universal_test
passed_matrix=android16_mustang_android16_blazer_android17_mustang_cp31
pending_matrix=android16_frankel_android16_rango_android17_cp21_frankel_blazer_mustang_rango
debug_collector=manual_only
debug_collector_command=su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
debug_zip_target=/sdcard/Download/pixel_thermal_debug_*.zip
EOF

ui_print "Target guard PASS"
case "$verification_state" in
  PASS_*) ui_print "Runtime PASS scope selected: $verification_state" ;;
  *) ui_print "TEST/PENDING scope selected: $verification_state - upload debug ZIP after reboot" ;;
esac
ui_print "Manual debug collector: su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh"
ui_print "No automatic debug collection, no bind mounts, no runtime text patching"
