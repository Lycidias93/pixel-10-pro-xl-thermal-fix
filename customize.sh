#!/system/bin/sh
SKIPUNZIP=0
MODULE_ID="pixel-10-pro-xl-thermal-fix"
MODULE_VERSION="1.4.12-universal-test.5"
MODULE_VERSION_CODE="1015205"
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
ui_print "  Universal test auto install debug autosave"
ui_print "----------------------------------------"
ui_print "SELinux read-only ThermalHAL overlay policy included"
ui_print "Prerelease test; stable updateJson remains 1.4.10-universal.3"

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
thermal_sanitize_name() {
  echo "${1:-unknown}" | tr -c 'A-Za-z0-9._-' '_'
}
thermal_choose_download_dir() {
  for d in /sdcard/Download /storage/emulated/0/Download; do
    if [ -d "$d" ] && [ -w "$d" ]; then echo "$d"; return 0; fi
  done
  echo /storage/emulated/0/Download
}
THERMAL_INSTALL_DEBUG_TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"
THERMAL_INSTALL_DEBUG_DIR="$(thermal_choose_download_dir)"
THERMAL_INSTALL_DEBUG_BASE="pixel_thermal_install_$(thermal_sanitize_name "$MODULE_VERSION")_$(thermal_sanitize_name "$device")_$(thermal_sanitize_name "$build_id")_$(thermal_sanitize_name "$incremental")_$THERMAL_INSTALL_DEBUG_TS"
THERMAL_INSTALL_DEBUG_LOG="$THERMAL_INSTALL_DEBUG_DIR/${THERMAL_INSTALL_DEBUG_BASE}.txt"
THERMAL_INSTALL_DEBUG_COLLECT_STDOUT="$THERMAL_INSTALL_DEBUG_DIR/${THERMAL_INSTALL_DEBUG_BASE}_collect_debug_stdout.txt"

thermal_save_install_debug() {
  result="${1:-unknown}"
  reason="${2:-none}"
  mkdir -p "$THERMAL_INSTALL_DEBUG_DIR" 2>/dev/null || true
  {
    echo "debug_type=pixel_thermal_install_autosave"
    echo "result=$result"
    echo "reason=$reason"
    echo "time=$(date -Is 2>/dev/null || date 2>/dev/null || true)"
    echo "module_id=$MODULE_ID"
    echo "module_version=$MODULE_VERSION"
    echo "module_version_code=$MODULE_VERSION_CODE"
    echo "modpath=$MODPATH"
    echo
    echo "== device =="
    echo "model=$model"
    echo "device=$device"
    echo "android=$android"
    echo "android_sdk=$android_sdk"
    echo "build_id=$build_id"
    echo "incremental=$incremental"
    echo "fingerprint=$fingerprint"
    echo
    echo "== root / backend =="
    echo "root_impl=${root_impl:-unknown}"
    echo "mount_backend_hint=${mount_backend_hint:-unknown}"
    echo "root_backend_guard_mode=${root_backend_guard_mode:-unknown}"
    echo
    echo "== selected profile =="
    echo "profile=${profile:-unset}"
    echo "profile_state=${profile_state:-unset}"
    echo "build_state=${build_state:-unset}"
    echo "android_guard=${android_guard:-unset}"
    echo "fingerprint_android_guard=${fingerprint_android_guard:-unset}"
    echo "incremental_guard=${incremental_guard:-unset}"
    echo "profile_source_build=${profile_source_build:-unset}"
    echo "profile_source_incremental=${profile_source_incremental:-unset}"
    echo "profile_dir=${profile_dir:-unset}"
    echo "active_dir=${active_dir:-unset}"
    echo
    echo "== pTune guard =="
    echo "PTUNE_GUARD_MODE=${PTUNE_GUARD_MODE:-unset}"
    echo "PTUNE_INSTALLED_PATH=${PTUNE_INSTALLED_PATH:-unset}"
    echo "PTUNE_ACTIVE_PATH=${PTUNE_ACTIVE_PATH:-unset}"
    echo "PTUNE_CONFLICT_PATH=${PTUNE_CONFLICT_PATH:-unset}"
    echo "PTUNE_CONFLICT_MODE=${PTUNE_CONFLICT_MODE:-unset}"
    echo "PTUNE_OVERRIDE_ALLOWED=${PTUNE_OVERRIDE_ALLOWED:-unset}"
    echo "PTUNE_KNOWN_BAD=${PTUNE_KNOWN_BAD:-unset}"
    echo
    echo "== relevant files =="
    ls -la "$MODPATH" 2>/dev/null || true
    echo
    echo "== guard dir =="
    ls -la "$MODPATH/guard" 2>/dev/null || true
    echo
    echo "== profile dir =="
    [ -n "${profile_dir:-}" ] && ls -la "$profile_dir" 2>/dev/null || true
    echo
    echo "== active overlay dir =="
    [ -n "${active_dir:-}" ] && ls -la "$active_dir" 2>/dev/null || true
    echo
    echo "== install-state =="
    cat "$MODPATH/install-state.txt" 2>/dev/null || true
    echo
    echo "== su / magisk =="
    su -v 2>/dev/null || true
    su -V 2>/dev/null || true
    magisk -v 2>/dev/null || true
    magisk -V 2>/dev/null || true
    echo
    echo "== recent thermal logcat =="
    logcat -d -t 300 2>/dev/null | grep -i -E "thermal|ThermalHAL|android.hardware.thermal|pixel-10-pro-xl-thermal-fix|Magisk|KernelSU|SukiSU|APatch" || true
  } > "$THERMAL_INSTALL_DEBUG_LOG" 2>&1 || true
  ui_print "Install debug autosave: $THERMAL_INSTALL_DEBUG_LOG"
}

thermal_collect_debug_on_fail() {
  [ -s "$MODPATH/tools/collect-debug.sh" ] || return 0
  MODDIR="$MODPATH" sh "$MODPATH/tools/collect-debug.sh" > "$THERMAL_INSTALL_DEBUG_COLLECT_STDOUT" 2>&1 || true
  ui_print "Install-fail collect-debug stdout: $THERMAL_INSTALL_DEBUG_COLLECT_STDOUT"
}

thermal_abort() {
  reason="$*"
  thermal_save_install_debug "fail" "$reason"
  thermal_collect_debug_on_fail
  abort "$reason"
}
# END PIXEL_THERMAL_INSTALL_DEBUG_AUTOSAVE_V1411



ui_print "model=$model"
ui_print "device=$device"
ui_print "android=$android"
ui_print "android_sdk=$android_sdk"
ui_print "build_id=$build_id"
ui_print "incremental=$incremental"
ui_print "root_impl=$root_impl"
ui_print "mount_backend_hint=$mount_backend_hint"
ui_print "root_backend_guard_mode=$root_backend_guard_mode"


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
[ -s "$MODPATH/tools/auto-profile-switch.sh" ] && chmod 0755 "$MODPATH/tools/auto-profile-switch.sh" || true
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
update_json_channel=stable_update_json_1.4.11-universal.1_test_manual_install_only
debug_collector=manual_or_auto_on_install_fail_v1411
compat_check_command=su -c /data/adb/modules/$MODULE_ID/tools/compat-check.sh
ptune_evidence_command=su -c /data/adb/modules/$MODULE_ID/tools/collect-ptune-evidence.sh
EOF
  thermal_save_install_debug "skip_mount" "$PTUNE_CONFLICT_REASON"
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
active_dir="$MODPATH/system/vendor/etc"
ui_print "profile_dir=$profile_dir"
for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do [ -s "$profile_dir/$f" ] || thermal_abort "! Missing profile file: $profile_dir/$f"; done
[ -r /vendor/etc/thermal_info_config_throttling.json ] || thermal_abort "! Stock thermal throttling config not readable"
grep -q "VIRTUAL-SKIN" /vendor/etc/thermal_info_config_throttling.json || thermal_abort "! Expected stock thermal marker missing"

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

# BEGIN PIXEL_THERMAL_ZRAM_FSTAB_PRESERVE_V1412_TEST4
zram_fstab_src=""
for zram_fstab_candidate in "$MODPATH/tools/fstab.zram.100p" "$MODPATH/system/vendor/etc/fstab.zram.100p"; do
  if [ -s "$zram_fstab_candidate" ]; then
    zram_fstab_src="$zram_fstab_candidate"
    break
  fi
done
if [ -n "$zram_fstab_src" ]; then
  cp -fp "$zram_fstab_src" "$active_dir/fstab.zram.100p" || thermal_abort "! Failed to materialize active ZRAM fstab"
  chmod 0644 "$active_dir/fstab.zram.100p" 2>/dev/null || true
  ui_print "zram_fstab_materialized=yes"
else
  ui_print "! zram_fstab_materialized=no template_missing"
fi
# END PIXEL_THERMAL_ZRAM_FSTAB_PRESERVE_V1412_TEST4

for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do [ -s "$active_dir/$f" ] || thermal_abort "! Failed to materialize active file: $f"; done

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

zram_fstab_template=tools/fstab.zram.100p
zram_fstab_materialized=$([ -s "$active_dir/fstab.zram.100p" ] && echo yes || echo no)
zram_feature=optional_disabled_by_default_v1412_test4

expected_thermal_files=3
polling_values_changed_by_this_release=source_profile_only
bind_mount_model=no
live_runtime_text_patch_model=no
selinux_overlay_read_policy=hal_thermal_default_system_file_read_only
update_json_channel=stable_update_json_1.4.11-universal.1_test_manual_install_only
debug_collector=manual_or_auto_on_install_fail_v1411
debug_collector_command=su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
override_enable_command=su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/enable-ptune-override.sh
override_disable_command=su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/disable-ptune-override.sh
debug_zip_target=/sdcard/Download/pixel_thermal_debug_*.zip
EOF

thermal_save_install_debug "success" "install_completed"
ui_print "Target guard PASS"
case "$android" in 17|17.*) ui_print "Android 17 guarded profile selected" ;; *) ui_print "Android 16 profile selected" ;; esac
ui_print "Manual debug collector: su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh"
ui_print "Automatic install-fail debug autosave enabled; no bind mounts, no runtime text patching"

# ZRAM_HELPER_CHMOD_V1412_TEST2: keep helper scripts executable for direct Magisk/KSU shell use.
if [ -d "$MODPATH/tools" ]; then
  chmod 0755 "$MODPATH"/tools/*.sh 2>/dev/null || true
fi
