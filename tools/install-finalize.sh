#!/system/bin/sh
# Pixel 10 Thermal & Memory Control - install finalization helper.

ptune_install_state_classify() {
  if [ -z "${PTUNE_INSTALLED_PATH:-}" ]; then
    PTUNE_INSTALL_STATE="absent"
    PTUNE_INSTALL_CONFLICT_GUARD="none"
    PTUNE_INSTALL_CONFLICT_MODE="ptune_absent"
    PTUNE_INSTALL_CONFLICT_PATH=""
    PTUNE_INSTALL_OVERRIDE_ACTIVE=0
  elif [ -z "${PTUNE_ACTIVE_PATH:-}" ]; then
    PTUNE_INSTALL_STATE="installed_disabled"
    PTUNE_INSTALL_CONFLICT_GUARD="ptune_installed_disabled"
    PTUNE_INSTALL_CONFLICT_MODE="installed_disabled_no_conflict"
    PTUNE_INSTALL_CONFLICT_PATH="$PTUNE_INSTALLED_PATH"
    PTUNE_INSTALL_OVERRIDE_ACTIVE=0
  elif [ "${PTUNE_OVERRIDE_ALLOWED:-0}" = "1" ]; then
    PTUNE_INSTALL_STATE="active_explicit_override"
    PTUNE_INSTALL_CONFLICT_GUARD="ptune_active"
    PTUNE_INSTALL_CONFLICT_MODE="override_allow_mount_with_ptune"
    PTUNE_INSTALL_CONFLICT_PATH="$PTUNE_ACTIVE_PATH"
    PTUNE_INSTALL_OVERRIDE_ACTIVE=1
  else
    PTUNE_INSTALL_STATE="active_blocked"
    PTUNE_INSTALL_CONFLICT_GUARD="ptune_active"
    PTUNE_INSTALL_CONFLICT_MODE="${PTUNE_CONFLICT_MODE:-strict_active_skip_mount}"
    PTUNE_INSTALL_CONFLICT_PATH="$PTUNE_ACTIVE_PATH"
    PTUNE_INSTALL_OVERRIDE_ACTIVE=0
  fi
}

install_sha() {
  [ -s "$1" ] || return 0
  sha256sum "$1" 2>/dev/null | awk '{print $1}'
}

thermal_finalize_install() {
  ptune_install_state_classify

  rm -f "$MODPATH/disable" "$MODPATH/skip_mount" "$MODPATH/remove"

  ACTIVE_MODPATH="/data/adb/modules/$MODULE_ID"
  if [ -d "$ACTIVE_MODPATH" ]; then
    rm -f "$ACTIVE_MODPATH/disable" "$ACTIVE_MODPATH/skip_mount" "$ACTIVE_MODPATH/remove"
    rm -f \
      "$ACTIVE_MODPATH/guard/disabled_reason" \
      "$ACTIVE_MODPATH/guard/conflict_guard_mode" \
      "$ACTIVE_MODPATH/guard/conflict_ptune_path" \
      "$ACTIVE_MODPATH/guard/guard_override" \
      "$ACTIVE_MODPATH/guard/guard_override_source" \
      "$ACTIVE_MODPATH/guard/risk_ack" \
      "$ACTIVE_MODPATH/guard/ptune_risk_ack" \
      "$ACTIVE_MODPATH/guard/zram_risk_ack" \
      "$ACTIVE_MODPATH/guard/zram_eh_risk_ack" 2>/dev/null || true
  fi

  mkdir -p "$MODPATH/guard"
  rm -f \
    "$MODPATH/guard/pending_boot" \
    "$MODPATH/guard/fail_count" \
    "$MODPATH/guard/disabled_reason" \
    "$MODPATH/guard/conflict_guard_mode" \
    "$MODPATH/guard/conflict_ptune_path" \
    "$MODPATH/guard/guard_override" \
    "$MODPATH/guard/guard_override_source" \
    "$MODPATH/guard/risk_ack" \
    "$MODPATH/guard/ptune_risk_ack" \
    "$MODPATH/guard/zram_risk_ack" \
    "$MODPATH/guard/zram_eh_risk_ack"

  if [ "$PTUNE_INSTALL_OVERRIDE_ACTIVE" = "1" ]; then
    printf '%s\n' "allow_thermal_with_ptune" > "$MODPATH/guard/guard_override"
    printf '%s\n' "$CONFIG_FILE" > "$MODPATH/guard/guard_override_source"
    printf '%s\n' "explicit_user_override" > "$MODPATH/guard/ptune_risk_ack"
    printf '%s\n' "$PTUNE_INSTALL_CONFLICT_PATH" > "$MODPATH/guard/conflict_ptune_path"
    printf '%s\n' "$PTUNE_INSTALL_CONFLICT_MODE" > "$MODPATH/guard/conflict_guard_mode"
  fi

  printf '%s\n' "${PTUNE_RISK_ACK_STATE:-unset}" > "$MODPATH/guard/ptune_risk_ack"
  printf '%s\n' "$(config_get ZRAM_RISK_ACK)" > "$MODPATH/guard/zram_risk_ack"
  printf '%s\n' "$(config_get ZRAM_EH_RISK_ACK)" > "$MODPATH/guard/zram_eh_risk_ack"

  [ -s "$MODPATH/tools/bootguard/collect-debug.sh" ] && chmod 0755 "$MODPATH/tools/bootguard/collect-debug.sh" || true
  [ -s "$MODPATH/tools/debug/pixel_thermal_toggle_debug.sh" ] && chmod 0755 "$MODPATH/tools/debug/pixel_thermal_toggle_debug.sh" || true
  [ -s "$MODPATH/tools/bootguard/compat-check.sh" ] && chmod 0755 "$MODPATH/tools/bootguard/compat-check.sh" || true
  [ -s "$MODPATH/tools/ptune/collect-ptune-evidence.sh" ] && chmod 0755 "$MODPATH/tools/ptune/collect-ptune-evidence.sh" || true
  [ -s "$MODPATH/tools/ptune/enable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/ptune/enable-ptune-override.sh" || true
  [ -s "$MODPATH/tools/ptune/disable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/ptune/disable-ptune-override.sh" || true
  [ -s "$MODPATH/tools/lmkd/early-swap-low-test.sh" ] && chmod 0755 "$MODPATH/tools/lmkd/early-swap-low-test.sh" || true
  [ -s "$MODPATH/tools/lmkd/verify-early-swap-low-test.sh" ] && chmod 0755 "$MODPATH/tools/lmkd/verify-early-swap-low-test.sh" || true
  [ -s "$MODPATH/tools/resetprop-rs" ] && chmod 0755 "$MODPATH/tools/resetprop-rs" || true

  validation_dir="$CONFIG_DIR/validation"
  validation_state_file="$validation_dir/state.env"
  validation_report="$validation_dir/validation-report.json"
  validation_delta="$validation_dir/outdoor-delta-validation.env"
  validation_manifest="$validation_dir/patch-manifest.tsv"

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
    printf '%s\n' "fingerprint=${fingerprint:-unknown}"
    printf '%s\n' "install_state_schema=pixel-thermal-install-state-v2"
    printf '%s\n' "install_state_owner=install-finalize-preserved-by-auto-profile-switch"
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
    printf '%s\n' "ptune_risk_ack=$PTUNE_RISK_ACK_STATE"
    printf '%s\n' "zram_risk_ack=$(config_get ZRAM_RISK_ACK)"
    printf '%s\n' "zram_eh_risk_ack=$(config_get ZRAM_EH_RISK_ACK)"
    printf '%s\n' "lmkd_early_swap_low_test=$(config_get LMKD_EARLY_SWAP_LOW_TEST)"
    printf '%s\n' "lmkd_early_swap_low_risk_ack=$(config_get LMKD_EARLY_SWAP_LOW_RISK_ACK)"
    printf '%s\n' "lmkd_test_evidence_dir=$CONFIG_DIR/lmkd-test"
    printf '%s\n' "lmkd_consumption_claim=indirect_timing_only"
    printf '%s\n' "ptune_state=$PTUNE_INSTALL_STATE"
    printf '%s\n' "ptune_installed_path=${PTUNE_INSTALLED_PATH:-none}"
    printf '%s\n' "ptune_active_path=${PTUNE_ACTIVE_PATH:-none}"
    printf '%s\n' "conflict_guard=$PTUNE_INSTALL_CONFLICT_GUARD"
    printf '%s\n' "conflict_guard_mode=$PTUNE_INSTALL_CONFLICT_MODE"
    printf '%s\n' "conflict_ptune_path=${PTUNE_INSTALL_CONFLICT_PATH:-none}"
    printf '%s\n' "guard_override=$([ "$PTUNE_INSTALL_OVERRIDE_ACTIVE" = 1 ] && printf '%s' "$PTUNE_OVERRIDE_NAME" || printf '%s' none)"
    printf '%s\n' "known_bad_ptune=$PTUNE_KNOWN_BAD"
    printf '%s\n' "profile_materialized=${profile_materialized:-yes}"
    printf '%s\n' "overlay_materializer=dynamic_safety_v3"
    printf '%s\n' "active_overlay_dir=system/vendor/etc"
    printf '%s\n' ""
    printf '%s\n' "install_menu_model=single_process_v1"
    printf '%s\n' "install_menu_process_count=$(config_get INSTALL_MENU_PROCESS_COUNT)"
    printf '%s\n' "install_options_confirmed=$(config_get INSTALL_OPTIONS_CONFIRMED)"
    printf '%s\n' ""
    printf '%s\n' "validation_state_schema=pixel-thermal-validation-state-v1"
    printf '%s\n' "validation_state_dir=$validation_dir"
    printf '%s\n' "validation_state_file=$validation_state_file"
    printf '%s\n' "validation_state_sha256=$(install_sha "$validation_state_file")"
    printf '%s\n' "validation_report=$validation_report"
    printf '%s\n' "validation_report_sha256=$(install_sha "$validation_report")"
    printf '%s\n' "outdoor_delta_report=$validation_delta"
    printf '%s\n' "outdoor_delta_report_sha256=$(install_sha "$validation_delta")"
    printf '%s\n' "patch_manifest=$validation_manifest"
    printf '%s\n' "patch_manifest_sha256=$(install_sha "$validation_manifest")"
    printf '%s\n' "validation_legacy_paths=symlinks_only"
    printf '%s\n' ""
    printf '%s\n' "zram_fstab_template=tools/zram/fstab.zram.100p"
    printf '%s\n' "zram_fstab_materialized=$([ -s "$active_dir/fstab.zram.100p" ] && echo yes || echo no)"
    printf '%s\n' "zram_feature=single_install_menu_optional_100p"
    printf '%s\n' "zram_install_materializer=noninteractive_install_zram_v1"
    printf '%s\n' "zram_apply_stage=boot_early"
    printf '%s\n' "zram_apply_helper=tools/zram/apply-zram-100p.sh"
    printf '%s\n' "zram_resetprop_required=yes"
    printf '%s\n' "zram_resetprop_executable=$([ -x "$MODPATH/tools/resetprop-rs" ] && echo yes || echo no)"
    printf '%s\n' "zram_resetprop_mode=resetprop-rs_-n"
    printf '%s\n' "zram_mmd_restart_policy=outside_boot_early_only"
    printf '%s\n' "zram_backup_state_model=none_in_memory_only_props"
    printf '%s\n' "thermal_outdoor_feature=single_install_menu_full_profiles_v1"
    printf '%s\n' "thermal_outdoor_profile=$THERMAL_OUTDOOR_PROFILE"
    printf '%s\n' "thermal_polling_mode=$(config_get THERMAL_POLLING_MODE)"
    printf '%s\n' "thermal_polling_effective=$(config_get THERMAL_POLLING_EFFECTIVE)"
    printf '%s\n' "ptune_override_menu=$(config_get PTUNE_OVERRIDE_MENU)"
    printf '%s\n' "last_thermal_outdoor_profile=$(config_get LAST_THERMAL_OUTDOOR_PROFILE)"
    printf '%s\n' "last_thermal_polling_mode=$(config_get LAST_THERMAL_POLLING_MODE)"
    printf '%s\n' "last_ptune_override=$(config_get LAST_PTUNE_OVERRIDE)"
    printf '%s\n' "debug_mode=$(config_get DEBUG_MODE)"
    printf '%s\n' "last_debug_mode=$(config_get LAST_DEBUG_MODE)"
    printf '%s\n' ""
    printf '%s\n' "expected_thermal_files=${expected_thermal_files:-dynamic_validated}"
    printf '%s\n' "polling_values_changed_by_this_release=stock_300000_to_mod_5000_only"
    printf '%s\n' "bind_mount_model=no"
    printf '%s\n' "live_runtime_text_patch_model=no"
    printf '%s\n' "selinux_overlay_read_policy=hal_thermal_default_system_file_read_only"
    printf '%s\n' "update_json_channel=stable_update_json_1.5.1-universal.1_public_stable"
    printf '%s\n' "debug_collector=manual_or_auto_on_install_fail_v1411"
    printf '%s\n' "debug_collector_command=su -c /data/adb/modules/$MODULE_ID/tools/bootguard/collect-debug.sh"
    printf '%s\n' "override_enable_command=su -c /data/adb/modules/$MODULE_ID/tools/ptune/enable-ptune-override.sh"
    printf '%s\n' "override_disable_command=su -c /data/adb/modules/$MODULE_ID/tools/ptune/disable-ptune-override.sh"
    printf '%s\n' "debug_zip_target=/sdcard/Download/pixel_thermal_debug_*.zip"
  } > "$MODPATH/install-state.txt"
}
