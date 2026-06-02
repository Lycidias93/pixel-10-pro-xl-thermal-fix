#!/system/bin/sh
SKIPUNZIP=0
MODULE_ID="pixel-10-pro-xl-thermal-fix"
MODULE_VERSION="1.4.2-universal-test.1"
MODULE_VERSION_CODE="1014201"
SUPPORTED_ANDROID_MAJOR="16"
PROFILE_SOURCE_ANDROID="16"
PROFILE_SOURCE_BUILD="CP1A.260505.005"

ui_print "----------------------------------------"
ui_print "  Pixel 10 Thermal Polling Fix"
ui_print "  Android 16 profile guard"
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
    ;;
  *)
    abort "! Unsupported Android version: $android. This profile set is Android 16 only; Android 17 requires separate factory evidence and profiles."
    ;;
esac

case "$fingerprint" in
  *":16/"*)
    fingerprint_android_guard="fingerprint_android16_pass"
    ;;
  *)
    abort "! Fingerprint does not identify Android 16 build: $fingerprint"
    ;;
esac

case "$build_id" in
  "$PROFILE_SOURCE_BUILD")
    build_family="android16_cp1a_260505_005"
    ;;
  *)
    build_family="android16_unverified_build"
    ui_print "! Android 16 build differs from factory evidence build: build_id=$build_id source=$PROFILE_SOURCE_BUILD"
    ui_print "! Continue only as beta/unverified unless this build is later factory-dumped and documented"
    ;;
esac

case "$device" in
  mustang)
    profile="mustang"
    profile_state="verified"
    case "$fingerprint" in
      google/mustang/mustang:16/CP1A.260505.005/15081906:user/release-keys)
        build_state="verified_build"
        ;;
      *)
        build_state="new_or_unverified_mustang_build"
        ui_print "! Mustang build not fork-verified yet: $fingerprint"
        ;;
    esac
    ;;
  frankel)
    profile="frankel"
    profile_state="beta_pending_live_verification"
    build_state="${build_family}_frankel_beta"
    ui_print "! Frankel profile is beta/pending live ThermalHAL verification"
    ;;
  blazer)
    profile="blazer"
    profile_state="beta_pending_live_verification"
    build_state="${build_family}_blazer_beta"
    ui_print "! Blazer profile is beta/pending live ThermalHAL verification"
    ;;
  rango)
    profile="rango"
    profile_state="beta_pending_live_verification"
    build_state="${build_family}_rango_beta"
    ui_print "! Rango profile is beta/pending live ThermalHAL verification"
    ;;
  *)
    abort "! Unsupported Pixel 10 device codename: $device"
    ;;
esac

profile_dir="$MODPATH/profiles/$profile/system/vendor/etc"
active_dir="$MODPATH/system/vendor/etc"

for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
  [ -s "$profile_dir/$f" ] || abort "! Missing profile file: $profile/$f"
done

if [ ! -r /vendor/etc/thermal_info_config_throttling.json ]; then
  abort "! Stock thermal throttling config not readable"
fi

if ! grep -q "VIRTUAL-SKIN" /vendor/etc/thermal_info_config_throttling.json; then
  abort "! Expected stock thermal marker missing"
fi

ui_print "selected_profile=$profile"
ui_print "profile_state=$profile_state"
ui_print "build_state=$build_state"
ui_print "profile_source_android=$PROFILE_SOURCE_ANDROID"
ui_print "profile_source_build=$PROFILE_SOURCE_BUILD"
ui_print "Materializing selected profile into active Magisk overlay path"

rm -rf "$active_dir"
mkdir -p "$active_dir"
cp -fp "$profile_dir"/*.json "$active_dir"/

for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
  [ -s "$active_dir/$f" ] || abort "! Failed to materialize active file: $f"
done

ui_print "Resetting stale module flags for this intentional install/update"
rm -f "$MODPATH/disable" "$MODPATH/skip_mount" "$MODPATH/remove"
mkdir -p "$MODPATH/guard"
rm -f "$MODPATH/guard/pending_boot" "$MODPATH/guard/fail_count" "$MODPATH/guard/disabled_reason"

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
profile_source_android=$PROFILE_SOURCE_ANDROID
profile_source_build=$PROFILE_SOURCE_BUILD
profile_materialized=yes
active_overlay_dir=system/vendor/etc
expected_thermal_files=3
polling_values_changed_by_this_release=source_profile_only
bind_mount_model=no
live_runtime_text_patch_model=no
update_json_channel=stable_main_update_json
EOF

ui_print "Target guard PASS"
ui_print "Android 16 profile guard PASS"
ui_print "Mustang verified; Frankel/Blazer/Rango beta/pending"
ui_print "Android 17 requires separate factory evidence/profile set"
ui_print "No bind mounts, no runtime text patching"
