#!/system/bin/sh
SKIPUNZIP=0
MODULE_ID="pixel-10-pro-xl-thermal-fix"
MODULE_VERSION="1.4.1-universal.1"
MODULE_VERSION_CODE="1014101"

ui_print "----------------------------------------"
ui_print "  Pixel 10 Thermal Polling Fix"
ui_print "  Universal-first release"
ui_print "----------------------------------------"
ui_print "Running install-time profile guard"

model="$(getprop ro.product.model)"
device="$(getprop ro.product.device)"
android="$(getprop ro.build.version.release)"
fingerprint="$(getprop ro.build.fingerprint)"
incremental="$(getprop ro.build.version.incremental)"

ui_print "model=$model"
ui_print "device=$device"
ui_print "android=$android"
ui_print "incremental=$incremental"

case "$android" in
  16|16.*) ;;
  *) abort "! Unsupported Android version: $android" ;;
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
  blazer)
    profile="blazer"
    profile_state="beta_pending_live_verification"
    build_state="blazer_beta"
    ui_print "! Blazer profile is beta/pending live ThermalHAL verification"
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
incremental=$incremental
profile_materialized=yes
active_overlay_dir=system/vendor/etc
expected_thermal_files=3
polling_values_changed_by_this_release=no
bind_mount_model=no
live_runtime_text_patch_model=no
update_json_channel=stable_main_update_json
EOF

ui_print "Target guard PASS"
ui_print "Universal-first release: Mustang verified; Blazer beta/pending"
ui_print "No polling values changed by this release"
ui_print "No bind mounts, no runtime text patching"
