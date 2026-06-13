#!/system/bin/sh
SKIPUNZIP=0
MODULE_ID="pixel-10-pro-xl-thermal-fix"
MODULE_VERSION="1.4.5-universal-test.2"
MODULE_VERSION_CODE="1014502"
A16_PROFILE_SOURCE_BUILD="CP1A.260505.005"
A17_CP31_PROFILE_SOURCE_BUILD="CP31.260508.005"
A17_CP31_PROFILE_SOURCE_INCREMENTAL="15421345"
A17_CP31_EXPECTED_FINGERPRINT="google/mustang_beta/mustang:CinnamonBun/CP31.260508.005/15421345:user/release-keys"
A17_CP21_PROFILE_SOURCE_BUILD="CP21.260330.011"

ui_print "----------------------------------------"
ui_print "  Pixel 10 Thermal Polling Fix"
ui_print "  Universal prerelease soft conflict guard"
ui_print "----------------------------------------"
ui_print "SELinux read-only ThermalHAL overlay policy included"
ui_print "Stable updateJson remains on 1.4.4-universal.1"

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

PTUNE_CONFLICT_PATH="$(ptune_active_path 2>/dev/null || true)"
if [ -n "$PTUNE_CONFLICT_PATH" ]; then
  ui_print "! pTune active/staged module detected: $PTUNE_CONFLICT_PATH"
  ui_print "! Soft-disabling ThermalHAL overlay while keeping this module scriptable for boot checks"
  mkdir -p "$MODPATH/guard"
  rm -f "$MODPATH/disable" "$MODPATH/remove"
  touch "$MODPATH/skip_mount"
  echo "conflict_ptune_active" > "$MODPATH/guard/disabled_reason"
  echo "$PTUNE_CONFLICT_PATH" > "$MODPATH/guard/conflict_ptune_path"
  echo "soft_skip_mount_only" > "$MODPATH/guard/conflict_guard_mode"
  [ -s "$MODPATH/tools/collect-debug.sh" ] && chmod 0755 "$MODPATH/tools/collect-debug.sh" || true
  [ -s "$MODPATH/tools/pixel_thermal_toggle_debug.sh" ] && chmod 0755 "$MODPATH/tools/pixel_thermal_toggle_debug.sh" || true
  cat > "$MODPATH/install-state.txt" <<EOF
module_id=$MODULE_ID
module_version=$MODULE_VERSION
module_version_code=$MODULE_VERSION_CODE
device=$device
profile=soft_disabled_by_ptune_conflict
profile_state=soft_disabled_conflict_ptune_active
build_state=not_materialized_due_ptune_conflict
android=$android
android_sdk=$android_sdk
build_id=$build_id
incremental=$incremental
android_guard=not_evaluated_due_ptune_conflict
fingerprint_android_guard=not_evaluated_due_ptune_conflict
incremental_guard=not_applicable
profile_materialized=no
active_overlay_dir=none
expected_thermal_files=0
conflict_guard=ptune_active
conflict_guard_mode=soft_skip_mount_only
conflict_ptune_path=$PTUNE_CONFLICT_PATH
bind_mount_model=no
live_runtime_text_patch_model=no
selinux_overlay_read_policy=installed_but_overlay_skipped
update_json_channel=stable_update_json_remains_1.4.4-universal.1
debug_collector=manual_only_v4_ptune_soft_conflict
EOF
  ui_print "Module installed with skip_mount only: conflict_ptune_active"
  exit 0
fi

case "$android" in
  16|16.*)
    android_guard="android16_pass"
    case "$fingerprint" in *":16/"*) fingerprint_android_guard="fingerprint_android16_pass" ;; *) abort "! Fingerprint does not identify Android 16 build: $fingerprint" ;; esac
    profile_source_android="16"; profile_source_build="$A16_PROFILE_SOURCE_BUILD"; profile_source_incremental="not_applicable"; source_report_sha256="factory_android16_profile_set"
    case "$build_id" in "$A16_PROFILE_SOURCE_BUILD") build_family="android16_cp1a_260505_005" ;; *) build_family="android16_unverified_build"; ui_print "! Android 16 build differs from source build: $build_id" ;; esac
    case "$device" in
      mustang) profile="mustang"; profile_state="verified_android16_mustang"; case "$fingerprint" in google/mustang/mustang:16/CP1A.260505.005/15081906:user/release-keys) build_state="verified_build" ;; *) build_state="new_or_unverified_mustang_android16_build" ;; esac ;;
      blazer) profile="blazer"; profile_state="verified_android16_blazer"; build_state="${build_family}_blazer_runtime_verified"; ui_print "Blazer Android 16 has runtime PASS evidence" ;;
      frankel) profile="frankel"; profile_state="beta_pending_live_verification"; build_state="${build_family}_frankel_beta"; ui_print "! Frankel Android 16 pending live verification" ;;
      rango) profile="rango"; profile_state="beta_pending_live_verification"; build_state="${build_family}_rango_beta"; ui_print "! Rango Android 16 pending live verification" ;;
      *) abort "! Unsupported Pixel 10 Android 16 device codename: $device" ;;
    esac
    ;;
  17|17.*)
    android_guard="android17_pass"
    profile_source_android="17"; source_report_sha256="factory_android17_profile_set"
    case "$device" in
      mustang)
        case "$fingerprint" in
          "$A17_CP31_EXPECTED_FINGERPRINT")
            profile="mustang-android17-cp31"; profile_state="tester_verified_android17_cp31"; build_state="android17_mustang_cp31_15421345_tester_verified"; fingerprint_android_guard="exact_android17_mustang_cp31_pass"; profile_source_build="$A17_CP31_PROFILE_SOURCE_BUILD"; profile_source_incremental="$A17_CP31_PROFILE_SOURCE_INCREMENTAL"; source_report_sha256="d16d0d985efdf2c9c4c2152b7a9a4c172d00cf647ca2a08b7610d610380ec599"
            case "$incremental" in "$A17_CP31_PROFILE_SOURCE_INCREMENTAL") incremental_guard="incremental_pass" ;; *) abort "! Android 17 CP31 incremental mismatch: $incremental" ;; esac ;;
          *":CinnamonBun/$A17_CP21_PROFILE_SOURCE_BUILD/"*|*":17/$A17_CP21_PROFILE_SOURCE_BUILD/"*)
            profile="mustang-android17-cp21"; profile_state="android17_cp21_test_pending_live_verification"; build_state="android17_cp21_mustang_factory_profile_pending_runtime"; fingerprint_android_guard="android17_cp21_build_pass"; profile_source_build="$A17_CP21_PROFILE_SOURCE_BUILD"; profile_source_incremental="$incremental"; incremental_guard="cp21_incremental_recorded_$incremental" ;;
          *) abort "! Unsupported Android 17 Mustang fingerprint/build: $fingerprint" ;;
        esac ;;
      frankel|blazer|rango)
        case "$build_id" in "$A17_CP21_PROFILE_SOURCE_BUILD") ;; *) abort "! Android 17 non-Mustang test requires build_id=$A17_CP21_PROFILE_SOURCE_BUILD but got $build_id" ;; esac
        case "$fingerprint" in *":CinnamonBun/$A17_CP21_PROFILE_SOURCE_BUILD/"*|*":17/$A17_CP21_PROFILE_SOURCE_BUILD/"*) ;; *) abort "! Android 17 non-Mustang test requires CP21 fingerprint: $fingerprint" ;; esac
        profile="${device}-android17-cp21"; profile_state="android17_cp21_test_pending_live_verification"; build_state="android17_cp21_${device}_factory_profile_pending_runtime"; fingerprint_android_guard="android17_cp21_build_pass"; profile_source_build="$A17_CP21_PROFILE_SOURCE_BUILD"; profile_source_incremental="$incremental"; incremental_guard="cp21_incremental_recorded_$incremental" ;;
      *) abort "! Unsupported Pixel 10 Android 17 device codename: $device" ;;
    esac
    ;;
  *) abort "! Unsupported Android version: $android. This test build supports Android 16 and guarded Android 17 CP31/CP21 profiles." ;;
esac

profile_dir="$MODPATH/profiles/$profile/system/vendor/etc"
active_dir="$MODPATH/system/vendor/etc"
for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do [ -s "$profile_dir/$f" ] || abort "! Missing profile file: $profile/$f"; done
[ -r /vendor/etc/thermal_info_config_throttling.json ] || abort "! Stock thermal throttling config not readable"
grep -q "VIRTUAL-SKIN" /vendor/etc/thermal_info_config_throttling.json || abort "! Expected stock thermal marker missing"

ui_print "selected_profile=$profile"
ui_print "profile_state=$profile_state"
ui_print "build_state=$build_state"
ui_print "profile_source_android=$profile_source_android"
ui_print "profile_source_build=$profile_source_build"
ui_print "profile_source_incremental=$profile_source_incremental"
ui_print "Materializing selected profile into active Magisk overlay path"

rm -rf "$active_dir"; mkdir -p "$active_dir"
cp -fp "$profile_dir"/*.json "$active_dir"/
chmod 0644 "$active_dir"/*.json 2>/dev/null || true
for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do [ -s "$active_dir/$f" ] || abort "! Failed to materialize active file: $f"; done

rm -f "$MODPATH/disable" "$MODPATH/skip_mount" "$MODPATH/remove"
mkdir -p "$MODPATH/guard"
rm -f "$MODPATH/guard/pending_boot" "$MODPATH/guard/fail_count" "$MODPATH/guard/disabled_reason"
[ -s "$MODPATH/tools/collect-debug.sh" ] && chmod 0755 "$MODPATH/tools/collect-debug.sh" || true
[ -s "$MODPATH/tools/pixel_thermal_toggle_debug.sh" ] && chmod 0755 "$MODPATH/tools/pixel_thermal_toggle_debug.sh" || true

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
selinux_overlay_read_policy=hal_thermal_default_system_file_read_only
update_json_channel=stable_update_json_remains_1.4.4-universal.1
debug_collector=manual_only_v4_ptune_soft_conflict
debug_collector_command=su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
debug_zip_target=/sdcard/Download/pixel_thermal_debug_*.zip
EOF

ui_print "Target guard PASS"
case "$android" in 17|17.*) ui_print "Android 17 guarded profile selected" ;; *) ui_print "Android 16 profile selected" ;; esac
ui_print "Manual debug collector: su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh"
ui_print "No automatic debug collection, no bind mounts, no runtime text patching"
