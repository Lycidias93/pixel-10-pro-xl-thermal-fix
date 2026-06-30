#!/system/bin/sh
# Pixel 10 Thermal & Memory Control - install finalization helper.
# Extracted from customize.sh for Test24.
# Defines thermal_finalize_install and writes install-state without heredoc syntax.

thermal_finalize_install() {
  rm -f "$MODPATH/disable" "$MODPATH/skip_mount" "$MODPATH/remove"

  ACTIVE_MODPATH="/data/adb/modules/$MODULE_ID"
  if [ -d "$ACTIVE_MODPATH" ]; then
    rm -f "$ACTIVE_MODPATH/disable" "$ACTIVE_MODPATH/skip_mount" "$ACTIVE_MODPATH/remove"
    rm -f "$ACTIVE_MODPATH/guard/disabled_reason" "$ACTIVE_MODPATH/guard/conflict_guard_mode" "$ACTIVE_MODPATH/guard/conflict_ptune_path" "$ACTIVE_MODPATH/guard/guard_override" "$ACTIVE_MODPATH/guard/guard_override_source" "$ACTIVE_MODPATH/guard/risk_ack" 2>/dev/null || true
  fi

  mkdir -p "$MODPATH/guard"
  rm -f "$MODPATH/guard/pending_boot" "$MODPATH/guard/fail_count" "$MODPATH/guard/disabled_reason" "$MODPATH/guard/conflict_guard_mode" "$MODPATH/guard/conflict_ptune_path" "$MODPATH/guard/guard_override" "$MODPATH/guard/guard_override_source" "$MODPATH/guard/risk_ack"

  if [ -n "$PTUNE_INSTALLED_PATH" ] && [ "$PTUNE_OVERRIDE_ALLOWED" = "1" ]; then
    printf '%s\n' "allow_thermal_with_ptune" > "$MODPATH/guard/guard_override"
    printf '%s\n' "$CONFIG_FILE" > "$MODPATH/guard/guard_override_source"
    printf '%s\n' "explicit_user_override" > "$MODPATH/guard/risk_ack"
    printf '%s\n' "$PTUNE_INSTALLED_PATH" > "$MODPATH/guard/conflict_ptune_path"
    printf '%s\n' "override_allow_mount_with_ptune" > "$MODPATH/guard/conflict_guard_mode"
  fi

  [ -s "$MODPATH/tools/collect-debug.sh" ] && chmod 0755 "$MODPATH/tools/collect-debug.sh" || true
  [ -s "$MODPATH/tools/pixel_thermal_toggle_debug.sh" ] && chmod 0755 "$MODPATH/tools/pixel_thermal_toggle_debug.sh" || true
  [ -s "$MODPATH/tools/compat-check.sh" ] && chmod 0755 "$MODPATH/tools/compat-check.sh" || true
  [ -s "$MODPATH/tools/collect-ptune-evidence.sh" ] && chmod 0755 "$MODPATH/tools/collect-ptune-evidence.sh" || true
  [ -s "$MODPATH/tools/enable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/enable-ptune-override.sh" || true
  [ -s "$MODPATH/tools/disable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/disable-ptune-override.sh" || true
  [ -s "$MODPATH/tools/resetprop-rs" ] && chmod 0755 "$MODPATH/tools/resetprop-rs" || true

  {
    printf '%s\n' "module_id=$MODULE_ID"
    printf '%s\n' "module_version=$MODULE_VERSION"
    printf '%s\n' "module_version_code=$MODULE_VERSION_CODE"
    printf '%s\n' "device=$device"
    printf '%s\n' "profile=$profile"
    printf '%s\n' "profile_state=$profile_state"
    printf '%s\n' "build_state=$build_state"
    printf '%s\n' "android=$android"
    printf '%s\n' "android_sdk=$android_sdk"
    printf '%s\n' "build_id=$build_id"
    printf '%s\n' "incremental=$incremental"
    printf '%s\n' "android_guard=$android_guard"
    printf '%s\n' "fingerprint_android_guard=$fingerprint_android_guard"
    printf '%s\n' "incremental_guard=${incremental_guard:-not_applicable}"
    printf '%s\n' "profile_source_android=$profile_source_android"
    printf '%s\n' "profile_source_build=$profile_source_build"
    printf '%s\n' "profile_source_incremental=$profile_source_incremental"
    printf '%s\n' "source_report_sha256=$source_report_sha256"
    printf '%s\n' "config_file=$CONFIG_FILE"
    printf '%s\n' "config_ptune_guard_mode=$PTUNE_GUARD_MODE"
    printf '%s\n' "config_allow_thermal_with_ptune=${ALLOW_THERMAL_WITH_PTUNE:-0}"
    printf '%s\n' "config_override_allowed=$PTUNE_OVERRIDE_ALLOWED"
    printf '%s\n' "risk_ack=$PTUNE_RISK_ACK_STATE"
    printf '%s\n' "conflict_guard=${PTUNE_INSTALLED_PATH:+ptune_installed}"
    printf '%s\n' "conflict_guard_mode=${PTUNE_INSTALLED_PATH:+override_allow_mount_with_ptune}"
    printf '%s\n' "guard_override=$PTUNE_OVERRIDE_NAME"
    printf '%s\n' "known_bad_ptune=$PTUNE_KNOWN_BAD"
    printf '%s\n' "profile_materialized=yes"
    printf '%s\n' "overlay_materializer=install_finalize_helper_v1413_test24"
    printf '%s\n' "active_overlay_dir=system/vendor/etc"
    printf '%s\n' ""
    printf '%s\n' "zram_fstab_template=tools/fstab.zram.100p"
    printf '%s\n' "zram_fstab_materialized=$([ -s "$active_dir/fstab.zram.100p" ] && echo yes || echo no)"
    printf '%s\n' "zram_feature=optional_volume_key_menu_v1412_stable"
    printf '%s\n' "zram_install_materializer=install_zram_helper_v1413_test25"
    printf '%s\n' "zram_apply_stage=boot_early"
    printf '%s\n' "zram_apply_helper=tools/apply-zram-100p.sh"
    printf '%s\n' "zram_resetprop_required=yes"
    printf '%s\n' "zram_resetprop_executable=$([ -x "$MODPATH/tools/resetprop-rs" ] && echo yes || echo no)"
    printf '%s\n' "zram_resetprop_mode=resetprop-rs_-n"
    printf '%s\n' "zram_mmd_restart_policy=outside_boot_early_only"
    printf '%s\n' "zram_backup_state_model=none_in_memory_only_props"
    printf '%s\n' "thermal_outdoor_feature=optional_full_options_menu_v1413_test25"
    printf '%s\n' "thermal_outdoor_profile=$THERMAL_OUTDOOR_PROFILE"
    printf '%s\n' "thermal_outdoor_target=$(config_get THERMAL_OUTDOOR_TARGET)"
    printf '%s\n' "thermal_settings_mode=$(config_get THERMAL_SETTINGS_MODE)"
    printf '%s\n' "thermal_safety_level=$(config_get THERMAL_SAFETY_LEVEL)"
    printf '%s\n' "thermal_conflict=$(config_get THERMAL_CONFLICT)"
    printf '%s\n' "thermal_conflict_path=$(config_get THERMAL_CONFLICT_PATH)"
    printf '%s\n' "thermal_max_profile=$(config_get THERMAL_MAX_PROFILE)"
    printf '%s\n' "thermal_polling_mode=$(config_get THERMAL_POLLING_MODE)"
    printf '%s\n' "thermal_polling_effective=$(config_get THERMAL_POLLING_EFFECTIVE)"
    printf '%s\n' "thermal_polling_conflict=$(config_get THERMAL_POLLING_CONFLICT)"
    printf '%s\n' "ptune_override_menu=$(config_get PTUNE_OVERRIDE_MENU)"
    printf '%s\n' "last_thermal_outdoor_profile=$(config_get LAST_THERMAL_OUTDOOR_PROFILE)"
    printf '%s\n' "last_thermal_polling_mode=$(config_get LAST_THERMAL_POLLING_MODE)"
    printf '%s\n' "last_thermal_safety_level=$(config_get LAST_THERMAL_SAFETY_LEVEL)"
    printf '%s\n' "last_ptune_override=$(config_get LAST_PTUNE_OVERRIDE)"
    printf '%s\n' ""
    printf '%s\n' "expected_thermal_files=3"
    printf '%s\n' "polling_values_changed_by_this_release=source_profile_or_optional_outdoor_g4_adapted_test"
    printf '%s\n' "bind_mount_model=no"
    printf '%s\n' "live_runtime_text_patch_model=no"
    printf '%s\n' "selinux_overlay_read_policy=hal_thermal_default_system_file_read_only"
    printf '%s\n' "update_json_channel=stable_update_json_1.5-universal.1_public_stable"
    printf '%s\n' "debug_collector=manual_or_auto_on_install_fail_v1411"
    printf '%s\n' "debug_collector_command=su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh"
    printf '%s\n' "override_enable_command=su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/enable-ptune-override.sh"
    printf '%s\n' "override_disable_command=su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/disable-ptune-override.sh"
    printf '%s\n' "debug_zip_target=/sdcard/Download/pixel_thermal_debug_*.zip"
  } > "$MODPATH/install-state.txt"
}
