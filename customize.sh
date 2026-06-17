#!/system/bin/sh
SKIPUNZIP=0
MODULE_ID="pixel-10-pro-xl-thermal-fix"
MODULE_VERSION="1.4.9-universal-test.1"
MODULE_VERSION_CODE="1014901"
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
ui_print "  Pixel 10 Thermal Polling Fix"
ui_print "  Universal prerelease guard_first stock/backend test"
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


CONFIG_DIR="/data/adb/$MODULE_ID"
CONFIG_FILE="$CONFIG_DIR/config.env"
config_get() {
  key="$1"
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^${key}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${key}=//" | tr -d '\r'
}
PTUNE_GUARD_MODE="$(config_get PTUNE_GUARD_MODE)"
[ -n "$PTUNE_GUARD_MODE" ] || PTUNE_GUARD_MODE="strict"
case "$PTUNE_GUARD_MODE" in strict|active_only|off) ;; *) ui_print "! Invalid PTUNE_GUARD_MODE=$PTUNE_GUARD_MODE, using strict"; PTUNE_GUARD_MODE="strict" ;; esac
ALLOW_THERMAL_WITH_PTUNE="$(config_get ALLOW_THERMAL_WITH_PTUNE)"
RISK_ACK_PTUNE_THERMAL_COLLISION="$(config_get RISK_ACK_PTUNE_THERMAL_COLLISION)"
PTUNE_OVERRIDE_ALLOWED=0
PTUNE_OVERRIDE_NAME="none"
PTUNE_RISK_ACK_STATE="not_present"
if [ "$ALLOW_THERMAL_WITH_PTUNE" = "1" ] && [ "$RISK_ACK_PTUNE_THERMAL_COLLISION" = "I_UNDERSTAND_BOOTLOOP_RISK" ]; then
  PTUNE_OVERRIDE_ALLOWED=1
  PTUNE_OVERRIDE_NAME="allow_thermal_with_ptune"
  PTUNE_RISK_ACK_STATE="explicit_user_override"
fi
if [ "$PTUNE_GUARD_MODE" = "off" ] && [ "$PTUNE_OVERRIDE_ALLOWED" != "1" ]; then
  ui_print "! PTUNE_GUARD_MODE=off ignored without risk_ack; using strict"
  PTUNE_GUARD_MODE="strict"
fi
ptune_installed_path() {
  for d in /data/adb/modules/ptune /data/adb/modules_update/ptune; do
    [ -f "$d/module.prop" ] || continue
    grep -q '^id=ptune$' "$d/module.prop" 2>/dev/null || continue
    [ -e "$d/remove" ] && continue
    echo "$d"
    return 0
  done
  return 1
}
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
ptune_known_bad_state() {
  d="$1"
  vc="$(grep -E '^versionCode=' "$d/module.prop" 2>/dev/null | sed 's/^versionCode=//')"
  [ "$vc" = "200" ] && echo "yes_versionCode_200_thermalhal_bootloop_on_mustang_cp1a_260505_005" || echo "no"
}
PTUNE_INSTALLED_PATH="$(ptune_installed_path 2>/dev/null || true)"
PTUNE_ACTIVE_PATH="$(ptune_active_path 2>/dev/null || true)"
PTUNE_KNOWN_BAD="no"
[ -n "$PTUNE_INSTALLED_PATH" ] && PTUNE_KNOWN_BAD="$(ptune_known_bad_state "$PTUNE_INSTALLED_PATH")"
PTUNE_CONFLICT_PATH=""
PTUNE_CONFLICT_REASON="conflict_ptune_active_or_staged"
PTUNE_CONFLICT_MODE="strict_active_skip_mount"
case "$PTUNE_GUARD_MODE" in
  strict) PTUNE_CONFLICT_PATH="$PTUNE_ACTIVE_PATH"; PTUNE_CONFLICT_REASON="conflict_ptune_active_or_staged"; PTUNE_CONFLICT_MODE="strict_active_skip_mount" ;;
  active_only) PTUNE_CONFLICT_PATH="$PTUNE_ACTIVE_PATH"; PTUNE_CONFLICT_REASON="conflict_ptune_active"; PTUNE_CONFLICT_MODE="active_only_skip_mount" ;;
  off) PTUNE_CONFLICT_PATH=""; PTUNE_CONFLICT_REASON="guard_off"; PTUNE_CONFLICT_MODE="guard_off" ;;
esac
if [ -n "$PTUNE_CONFLICT_PATH" ] && [ "$PTUNE_OVERRIDE_ALLOWED" != "1" ]; then
  ui_print "! pTune conflict detected: $PTUNE_CONFLICT_PATH"
  ui_print "! pTune guard mode: $PTUNE_GUARD_MODE -> $PTUNE_CONFLICT_MODE"
  [ "$PTUNE_KNOWN_BAD" = "no" ] || ui_print "! Known bad pTune state: $PTUNE_KNOWN_BAD"
  ui_print "! Keeping this module scriptable but skip_mounted"
  mkdir -p "$MODPATH/guard"
  rm -f "$MODPATH/disable" "$MODPATH/remove"
  touch "$MODPATH/skip_mount"
  echo "$PTUNE_CONFLICT_REASON" > "$MODPATH/guard/disabled_reason"
  echo "$PTUNE_CONFLICT_PATH" > "$MODPATH/guard/conflict_ptune_path"
  echo "$PTUNE_CONFLICT_MODE" > "$MODPATH/guard/conflict_guard_mode"
  rm -f "$MODPATH/guard/guard_override" "$MODPATH/guard/guard_override_source" "$MODPATH/guard/risk_ack" 2>/dev/null || true
  ACTIVE_MODPATH="/data/adb/modules/$MODULE_ID"
  if [ -d "$ACTIVE_MODPATH" ]; then
    mkdir -p "$ACTIVE_MODPATH/guard"
    rm -f "$ACTIVE_MODPATH/disable" "$ACTIVE_MODPATH/remove"
    touch "$ACTIVE_MODPATH/skip_mount"
    echo "$PTUNE_CONFLICT_REASON" > "$ACTIVE_MODPATH/guard/disabled_reason"
    echo "$PTUNE_CONFLICT_PATH" > "$ACTIVE_MODPATH/guard/conflict_ptune_path"
    echo "$PTUNE_CONFLICT_MODE" > "$ACTIVE_MODPATH/guard/conflict_guard_mode"
    rm -f "$ACTIVE_MODPATH/guard/guard_override" "$ACTIVE_MODPATH/guard/guard_override_source" "$ACTIVE_MODPATH/guard/risk_ack" 2>/dev/null || true
  fi
  [ -s "$MODPATH/tools/collect-debug.sh" ] && chmod 0755 "$MODPATH/tools/collect-debug.sh" || true
  [ -s "$MODPATH/tools/pixel_thermal_toggle_debug.sh" ] && chmod 0755 "$MODPATH/tools/pixel_thermal_toggle_debug.sh" || true
[ -s "$MODPATH/tools/compat-check.sh" ] && chmod 0755 "$MODPATH/tools/compat-check.sh" || true
[ -s "$MODPATH/tools/collect-ptune-evidence.sh" ] && chmod 0755 "$MODPATH/tools/collect-ptune-evidence.sh" || true
[ -s "$MODPATH/tools/enable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/enable-ptune-override.sh" || true
[ -s "$MODPATH/tools/disable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/disable-ptune-override.sh" || true
  [ -s "$MODPATH/tools/compat-check.sh" ] && chmod 0755 "$MODPATH/tools/compat-check.sh" || true
  [ -s "$MODPATH/tools/collect-ptune-evidence.sh" ] && chmod 0755 "$MODPATH/tools/collect-ptune-evidence.sh" || true
  [ -s "$MODPATH/tools/enable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/enable-ptune-override.sh" || true
  [ -s "$MODPATH/tools/disable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/disable-ptune-override.sh" || true
  [ -s "$MODPATH/tools/compat-check.sh" ] && chmod 0755 "$MODPATH/tools/compat-check.sh" || true
  [ -s "$MODPATH/tools/collect-ptune-evidence.sh" ] && chmod 0755 "$MODPATH/tools/collect-ptune-evidence.sh" || true
  [ -s "$MODPATH/tools/enable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/enable-ptune-override.sh" || true
  [ -s "$MODPATH/tools/disable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/disable-ptune-override.sh" || true
  cat > "$MODPATH/install-state.txt" <<EOF
module_id=$MODULE_ID
module_version=$MODULE_VERSION
module_version_code=$MODULE_VERSION_CODE
device=$device
profile=skip_mount_by_ptune_guard
profile_state=${PTUNE_CONFLICT_REASON}
build_state=not_materialized_due_ptune_guard
android=$android
android_sdk=$android_sdk
build_id=$build_id
incremental=$incremental
android_guard=not_evaluated_due_ptune_guard
fingerprint_android_guard=not_evaluated_due_ptune_guard
incremental_guard=not_applicable
profile_materialized=no
active_overlay_dir=none
expected_thermal_files=0
config_file=$CONFIG_FILE
config_ptune_guard_mode=$PTUNE_GUARD_MODE
config_allow_thermal_with_ptune=${ALLOW_THERMAL_WITH_PTUNE:-0}
config_override_allowed=$PTUNE_OVERRIDE_ALLOWED
risk_ack=$PTUNE_RISK_ACK_STATE
conflict_guard=ptune_present
conflict_guard_mode=$PTUNE_CONFLICT_MODE
conflict_ptune_path=$PTUNE_CONFLICT_PATH
known_bad_ptune=$PTUNE_KNOWN_BAD
bind_mount_model=no
live_runtime_text_patch_model=no
selinux_overlay_read_policy=installed_but_overlay_skipped_due_ptune_guard
update_json_channel=stable_update_json_remains_1.4.4-universal.1
debug_collector=manual_only_v8_override_materializer_and_ptune_evidence
compat_check_command=su -c /data/adb/modules/$MODULE_ID/tools/compat-check.sh
ptune_evidence_command=su -c /data/adb/modules/$MODULE_ID/tools/collect-ptune-evidence.sh
EOF
  ui_print "Module installed with skip_mount only: $PTUNE_CONFLICT_REASON"
  exit 0
fi
if [ -n "$PTUNE_INSTALLED_PATH" ] && [ "$PTUNE_OVERRIDE_ALLOWED" = "1" ]; then
  ui_print "! OVERRIDE: Thermal overlay allowed while pTune is installed"
  ui_print "! Risk_ack accepted: I_UNDERSTAND_BOOTLOOP_RISK"
  [ "$PTUNE_KNOWN_BAD" = "no" ] || ui_print "! Known bad pTune state: $PTUNE_KNOWN_BAD"
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
          "google/mustang/mustang:17/$A17_STABLE_CP2A_PROFILE_SOURCE_BUILD/$A17_STABLE_CP2A_PROFILE_SOURCE_INCREMENTAL:user/release-keys")
            profile="mustang-android17-stable-cp2a-260605012"; profile_state="android17_stable_cp2a_test_pending_live_verification"; build_state="android17_mustang_cp2a_15430684_factory_profile_pending_runtime"; fingerprint_android_guard="exact_android17_mustang_stable_cp2a_pass"; profile_source_build="$A17_STABLE_CP2A_PROFILE_SOURCE_BUILD"; profile_source_incremental="$A17_STABLE_CP2A_PROFILE_SOURCE_INCREMENTAL"; source_report_sha256="$A17_STABLE_CP2A_SOURCE_REPORT_SHA256"
            case "$incremental" in "$A17_STABLE_CP2A_PROFILE_SOURCE_INCREMENTAL") incremental_guard="incremental_pass" ;; *) abort "! Android 17 stable CP2A Mustang incremental mismatch: $incremental" ;; esac ;;
          "$A17_CP31_EXPECTED_FINGERPRINT")
            profile="mustang-android17-cp31"; profile_state="tester_verified_android17_cp31"; build_state="android17_mustang_cp31_15421345_tester_verified"; fingerprint_android_guard="exact_android17_mustang_cp31_pass"; profile_source_build="$A17_CP31_PROFILE_SOURCE_BUILD"; profile_source_incremental="$A17_CP31_PROFILE_SOURCE_INCREMENTAL"; source_report_sha256="d16d0d985efdf2c9c4c2152b7a9a4c172d00cf647ca2a08b7610d610380ec599"
            case "$incremental" in "$A17_CP31_PROFILE_SOURCE_INCREMENTAL") incremental_guard="incremental_pass" ;; *) abort "! Android 17 CP31 incremental mismatch: $incremental" ;; esac ;;
          "$A17_CP31_QPR1B4_EXPECTED_FINGERPRINT")
            profile="mustang-android17-cp31"; profile_state="android17_cp31_qpr1_beta4_test_pending_live_verification"; build_state="android17_mustang_cp31_15591510_stock_matched_pending_runtime"; fingerprint_android_guard="exact_android17_mustang_cp31_CP31_260522_006_pass"; profile_source_build="$A17_CP31_QPR1B4_PROFILE_SOURCE_BUILD"; profile_source_incremental="$A17_CP31_QPR1B4_PROFILE_SOURCE_INCREMENTAL"; source_report_sha256="stock_debug_cp31_260522006_thermal_hashes_match_known_cp31"
            case "$incremental" in "$A17_CP31_QPR1B4_PROFILE_SOURCE_INCREMENTAL") incremental_guard="incremental_pass" ;; *) abort "! Android 17 CP31 QPR1 Beta 4 incremental mismatch: $incremental" ;; esac ;;
          *":CinnamonBun/$A17_CP21_PROFILE_SOURCE_BUILD/"*|*":17/$A17_CP21_PROFILE_SOURCE_BUILD/"*)
            profile="mustang-android17-cp21"; profile_state="android17_cp21_test_pending_live_verification"; build_state="android17_cp21_mustang_factory_profile_pending_runtime"; fingerprint_android_guard="android17_cp21_build_pass"; profile_source_build="$A17_CP21_PROFILE_SOURCE_BUILD"; profile_source_incremental="$incremental"; incremental_guard="cp21_incremental_recorded_$incremental" ;;
          *) abort "! Unsupported Android 17 Mustang fingerprint/build: $fingerprint" ;;
        esac ;;
      frankel|blazer|rango)
        if [ "$build_id" = "$A17_STABLE_CP2A_PROFILE_SOURCE_BUILD" ] && [ "$incremental" = "$A17_STABLE_CP2A_PROFILE_SOURCE_INCREMENTAL" ]; then
          case "$fingerprint" in google/${device}/${device}:17/$A17_STABLE_CP2A_PROFILE_SOURCE_BUILD/$A17_STABLE_CP2A_PROFILE_SOURCE_INCREMENTAL:user/release-keys) ;; *) abort "! Android 17 stable CP2A ${device} fingerprint mismatch: $fingerprint" ;; esac
          profile="${device}-android17-stable-cp2a-260605012"; profile_state="android17_stable_cp2a_test_pending_live_verification"; build_state="android17_${device}_cp2a_15430684_factory_profile_pending_runtime"; fingerprint_android_guard="exact_android17_${device}_stable_cp2a_pass"; profile_source_build="$A17_STABLE_CP2A_PROFILE_SOURCE_BUILD"; profile_source_incremental="$A17_STABLE_CP2A_PROFILE_SOURCE_INCREMENTAL"; source_report_sha256="$A17_STABLE_CP2A_SOURCE_REPORT_SHA256"; incremental_guard="incremental_pass"
        else
          case "$build_id" in "$A17_CP21_PROFILE_SOURCE_BUILD") ;; *) abort "! Android 17 non-Mustang test requires build_id=$A17_CP21_PROFILE_SOURCE_BUILD or $A17_STABLE_CP2A_PROFILE_SOURCE_BUILD but got $build_id" ;; esac
          case "$fingerprint" in *":CinnamonBun/$A17_CP21_PROFILE_SOURCE_BUILD/"*|*":17/$A17_CP21_PROFILE_SOURCE_BUILD/"*) ;; *) abort "! Android 17 non-Mustang test requires CP21 fingerprint: $fingerprint" ;; esac
          profile="${device}-android17-cp21"; profile_state="android17_cp21_test_pending_live_verification"; build_state="android17_cp21_${device}_factory_profile_pending_runtime"; fingerprint_android_guard="android17_cp21_build_pass"; profile_source_build="$A17_CP21_PROFILE_SOURCE_BUILD"; profile_source_incremental="$incremental"; incremental_guard="cp21_incremental_recorded_$incremental"
        fi ;;
      *) abort "! Unsupported Pixel 10 Android 17 device codename: $device" ;;
    esac
    ;;
  *) abort "! Unsupported Android version: $android. This test build supports Android 16 and guarded Android 17 CP31/CP21/Stable CP2A profiles." ;;
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
ACTIVE_MODPATH="/data/adb/modules/$MODULE_ID"
if [ -d "$ACTIVE_MODPATH" ]; then
  rm -f "$ACTIVE_MODPATH/disable" "$ACTIVE_MODPATH/skip_mount" "$ACTIVE_MODPATH/remove"
  rm -f "$ACTIVE_MODPATH/guard/disabled_reason" "$ACTIVE_MODPATH/guard/conflict_guard_mode" "$ACTIVE_MODPATH/guard/conflict_ptune_path" "$ACTIVE_MODPATH/guard/guard_override" "$ACTIVE_MODPATH/guard/guard_override_source" "$ACTIVE_MODPATH/guard/risk_ack" 2>/dev/null || true
fi
mkdir -p "$MODPATH/guard"
rm -f "$MODPATH/guard/pending_boot" "$MODPATH/guard/fail_count" "$MODPATH/guard/disabled_reason" "$MODPATH/guard/conflict_guard_mode" "$MODPATH/guard/conflict_ptune_path" "$MODPATH/guard/guard_override" "$MODPATH/guard/guard_override_source" "$MODPATH/guard/risk_ack"
if [ -n "$PTUNE_INSTALLED_PATH" ] && [ "$PTUNE_OVERRIDE_ALLOWED" = "1" ]; then
  echo "allow_thermal_with_ptune" > "$MODPATH/guard/guard_override"
  echo "$CONFIG_FILE" > "$MODPATH/guard/guard_override_source"
  echo "explicit_user_override" > "$MODPATH/guard/risk_ack"
  echo "$PTUNE_INSTALLED_PATH" > "$MODPATH/guard/conflict_ptune_path"
  echo "override_allow_mount_with_ptune" > "$MODPATH/guard/conflict_guard_mode"
fi
[ -s "$MODPATH/tools/collect-debug.sh" ] && chmod 0755 "$MODPATH/tools/collect-debug.sh" || true
[ -s "$MODPATH/tools/pixel_thermal_toggle_debug.sh" ] && chmod 0755 "$MODPATH/tools/pixel_thermal_toggle_debug.sh" || true
[ -s "$MODPATH/tools/compat-check.sh" ] && chmod 0755 "$MODPATH/tools/compat-check.sh" || true
[ -s "$MODPATH/tools/collect-ptune-evidence.sh" ] && chmod 0755 "$MODPATH/tools/collect-ptune-evidence.sh" || true
[ -s "$MODPATH/tools/enable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/enable-ptune-override.sh" || true
[ -s "$MODPATH/tools/disable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/disable-ptune-override.sh" || true

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
config_file=$CONFIG_FILE
config_ptune_guard_mode=$PTUNE_GUARD_MODE
config_allow_thermal_with_ptune=${ALLOW_THERMAL_WITH_PTUNE:-0}
config_override_allowed=$PTUNE_OVERRIDE_ALLOWED
risk_ack=$PTUNE_RISK_ACK_STATE
conflict_guard=${PTUNE_INSTALLED_PATH:+ptune_installed}
conflict_guard_mode=${PTUNE_INSTALLED_PATH:+override_allow_mount_with_ptune}
guard_override=$PTUNE_OVERRIDE_NAME
known_bad_ptune=$PTUNE_KNOWN_BAD
profile_materialized=yes
overlay_materializer=customize_guard_first
active_overlay_dir=system/vendor/etc
expected_thermal_files=3
polling_values_changed_by_this_release=source_profile_only
bind_mount_model=no
live_runtime_text_patch_model=no
selinux_overlay_read_policy=hal_thermal_default_system_file_read_only
update_json_channel=stable_update_json_remains_1.4.4-universal.1
debug_collector=manual_only_v8_override_materializer_and_ptune_evidence
debug_collector_command=su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
override_enable_command=su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/enable-ptune-override.sh
override_disable_command=su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/disable-ptune-override.sh
debug_zip_target=/sdcard/Download/pixel_thermal_debug_*.zip
EOF

ui_print "Target guard PASS"
case "$android" in 17|17.*) ui_print "Android 17 guarded profile selected" ;; *) ui_print "Android 16 profile selected" ;; esac
ui_print "Manual debug collector: su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh"
ui_print "No automatic debug collection, no bind mounts, no runtime text patching"
