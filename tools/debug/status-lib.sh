#!/system/bin/sh
# P/T/Z manager status backed by Dynamic V2 manifests and active values.

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
ADB_ROOT="${THERMAL_ADB_ROOT:-/data/adb}"
MODDIR="${MODDIR:-$ADB_ROOT/modules/$ID}"
DATA_ROOT="${THERMAL_DATA_ROOT:-$ADB_ROOT/$ID}"
CONFIG_FILE="$DATA_ROOT/config.env"
STATUS_FILE="$MODDIR/guard/manager-status.env"
STATUS_TXT="$MODDIR/guard/manager-status.txt"

OK="🟢"
WARN="🟡"
BAD="🔴"
OFF="⚪"

cfg_get() {
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^$1=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^$1=//" | tr -d '\r'
}

prop_get() {
  getprop "$1" 2>/dev/null || true
}

kv_get() {
  [ -r "$2" ] || return 0
  grep -E "^$1=" "$2" 2>/dev/null | tail -n 1 | sed "s/^$1=//" | tr -d '\r'
}

compat_dump() {
  if [ -r "$MODDIR/tools/bootguard/compat-check.sh" ]; then
    sh "$MODDIR/tools/bootguard/compat-check.sh" 2>/dev/null || true
  fi
}

status_collect() {
  mkdir -p "$MODDIR/guard" 2>/dev/null || true
  tmp="$MODDIR/guard/manager-status.compat.$$"
  compat_dump > "$tmp" 2>/dev/null || true

  platform_supported="$(kv_get PLATFORM_SUPPORTED "$tmp")"
  build_evidence="$(kv_get BUILD_EVIDENCE "$tmp")"
  transition_pending="$(kv_get PLATFORM_TRANSITION_PENDING "$tmp")"
  transition_phase="$(kv_get PLATFORM_TRANSITION_PHASE "$tmp")"
  transition_reason="$(kv_get PLATFORM_TRANSITION_REASON "$tmp")"
  source_manifest_valid="$(kv_get DYNAMIC_SOURCE_MANIFEST_VALID "$tmp")"
  source_cache_valid="$(kv_get DYNAMIC_SOURCE_CACHE_VALID "$tmp")"
  patch_manifest_valid="$(kv_get DYNAMIC_PATCH_MANIFEST_VALID "$tmp")"
  report_valid="$(kv_get DYNAMIC_VALIDATION_REPORT_VALID "$tmp")"
  materialization_valid="$(kv_get DYNAMIC_MATERIALIZATION_VALID "$tmp")"
  overlay_ready="$(kv_get MODULE_OVERLAY_READY "$tmp")"
  active_match="$(kv_get ACTIVE_VENDOR_MATCH "$tmp")"
  active_polling_valid="$(kv_get ACTIVE_POLLING_VALID "$tmp")"
  safe_to_reboot="$(kv_get SAFE_TO_REBOOT "$tmp")"
  thermal_expected="$(kv_get THERMAL_EXPECTED "$tmp")"
  compat_reason="$(kv_get REASON "$tmp")"
  vendor_warn="$(kv_get VENDOR_OVERLAY_BACKEND_WARN "$tmp")"
  selected_profile="$(kv_get AUTO_SELECTED_PROFILE "$tmp")"
  source_polling="$(kv_get DYNAMIC_SOURCE_POLLING_300000 "$tmp")"
  replacements="$(kv_get DYNAMIC_REPLACEMENTS "$tmp")"
  overlay_300000="$(kv_get DYNAMIC_OVERLAY_POLLING_300000 "$tmp")"
  overlay_5000="$(kv_get DYNAMIC_OVERLAY_POLLING_5000 "$tmp")"
  active_300000="$(kv_get ACTIVE_POLLING_300000 "$tmp")"
  active_5000="$(kv_get ACTIVE_POLLING_5000 "$tmp")"

  [ -n "$platform_supported" ] || platform_supported=unknown
  [ -n "$build_evidence" ] || build_evidence=unknown
  [ -n "$transition_pending" ] || transition_pending=no
  [ -n "$transition_phase" ] || transition_phase=absent
  [ -n "$transition_reason" ] || transition_reason=none
  [ -n "$materialization_valid" ] || materialization_valid=unknown
  [ -n "$overlay_ready" ] || overlay_ready=unknown
  [ -n "$active_match" ] || active_match=unknown
  [ -n "$active_polling_valid" ] || active_polling_valid=unknown
  [ -n "$safe_to_reboot" ] || safe_to_reboot=unknown
  [ -n "$thermal_expected" ] || thermal_expected=unknown
  [ -n "$compat_reason" ] || compat_reason=unknown
  [ -n "$selected_profile" ] || selected_profile="$(sed -n 's/^profile=//p' "$MODDIR/install-state.txt" 2>/dev/null | tail -n 1)"
  [ -n "$selected_profile" ] || selected_profile=dynamic

  polling_mode="$(cfg_get THERMAL_POLLING_MODE)"
  [ -n "$polling_mode" ] || polling_mode="$(kv_get POLLING_MODE "$tmp")"
  [ -n "$polling_mode" ] || polling_mode=mod
  thermal_profile="$(cfg_get THERMAL_OUTDOOR_PROFILE)"
  [ -n "$thermal_profile" ] || thermal_profile="$(kv_get OUTDOOR_PROFILE "$tmp")"
  [ -n "$thermal_profile" ] || thermal_profile=stock
  thermal_disabled="$(cfg_get THERMAL_DISABLED)"
  [ -n "$thermal_disabled" ] || thermal_disabled=0

  source_icon="$BAD"
  source_state=invalid
  if [ "$platform_supported" = no ] && [ "$thermal_disabled" = 1 ]; then
    source_icon="$WARN"
    source_state=unsupported_platform_thermal_disabled
  elif [ "$platform_supported" = yes ] &&
       [ "$source_manifest_valid" = yes ] &&
       [ "$source_cache_valid" = yes ] &&
       [ "$patch_manifest_valid" = yes ] &&
       [ "$report_valid" = yes ]; then
    source_icon="$OK"
    source_state=dynamic_manifests_verified
  fi

  polling_icon="$BAD"
  polling_state=problem
  polling_value="$polling_mode"
  if [ "$thermal_disabled" = 1 ]; then
    polling_icon="$BAD"
    polling_state=disabled_by_platform_guard
    polling_value=disabled
  elif [ "$materialization_valid" != yes ]; then
    polling_icon="$BAD"
    polling_state=dynamic_materialization_invalid
  elif [ "$safe_to_reboot" != yes ]; then
    polling_icon="$BAD"
    polling_state="unsafe_${compat_reason}"
  else
    case "$polling_mode" in
      stock)
        polling_value=stock
        if [ "$active_match" = yes ] && [ "$active_polling_valid" = yes ]; then
          polling_icon="$OFF"
          polling_state=stock_active_verified
        else
          polling_icon="$WARN"
          polling_state=stock_validated_needs_reboot
        fi
      ;;
      mod)
        if [ "$active_match" = yes ] && [ "$active_polling_valid" = yes ]; then
          polling_icon="$OK"
          polling_state=active_polling_verified
          polling_value=5000
        else
          polling_icon="$WARN"
          polling_state=validated_needs_reboot
          polling_value=mod-pending
        fi
      ;;
      *)
        polling_icon="$BAD"
        polling_state=unknown_polling_mode
      ;;
    esac
  fi

  thermal_icon="$BAD"
  thermal_state=problem
  thermal_value="$thermal_profile"
  if [ "$thermal_disabled" = 1 ]; then
    thermal_icon="$BAD"
    thermal_state=disabled_by_platform_guard
  elif [ "$materialization_valid" != yes ]; then
    thermal_icon="$BAD"
    thermal_state=dynamic_materialization_invalid
  elif [ "$safe_to_reboot" != yes ]; then
    thermal_icon="$BAD"
    thermal_state="unsafe_${compat_reason}"
  else
    case "$thermal_profile" in
      stock)
        thermal_value=stock
        if [ "$active_match" = yes ]; then
          thermal_icon="$OFF"
          thermal_state=stock_profile_active
        else
          thermal_icon="$WARN"
          thermal_state=stock_profile_validated_needs_reboot
        fi
      ;;
      outdoor-safe|outdoor-plus|outdoor-extended)
        if [ "$active_match" = yes ]; then
          thermal_icon="$OK"
          thermal_state=custom_profile_active
        else
          thermal_icon="$WARN"
          thermal_state=custom_profile_validated_needs_reboot
        fi
      ;;
      *)
        thermal_icon="$BAD"
        thermal_state=unknown_thermal_profile
      ;;
    esac
  fi

  zram_enabled="$(cfg_get ENABLE_ZRAM_100P)"
  zram_ack="$(cfg_get ZRAM_RISK_ACK)"
  [ -n "$zram_enabled" ] || zram_enabled=0
  zram_prop_vendor="$(prop_get vendor.zram.size)"
  zram_prop_mmd="$(prop_get mmd.zram.size)"
  zram_prop_enabled="$(prop_get mmd.zram.enabled)"
  zram_mod_fstab=no
  zram_vendor_fstab=no
  zram_swap_active=no
  zram_runtime_active=no
  zram_disk_size=0
  zram_disk_positive=no
  [ -s "$MODDIR/system/vendor/etc/fstab.zram.100p" ] && zram_mod_fstab=yes
  [ -r "${THERMAL_VENDOR_DIR:-/vendor/etc}/fstab.zram.100p" ] && zram_vendor_fstab=yes
  grep -E '(^|[[:space:]])/dev/block/zram[0-9]+[[:space:]]' /proc/swaps 2>/dev/null | tail -n 1 >/dev/null && zram_swap_active=yes
  if [ -r /sys/block/zram0/disksize ]; then
    zram_disk_size="$(cat /sys/block/zram0/disksize 2>/dev/null | tr -d '\r' | head -n 1)"
  fi
  case "$zram_disk_size" in
    ''|0|*[!0-9]*) zram_disk_positive=no ;;
    *) zram_disk_positive=yes ;;
  esac
  if [ "$zram_swap_active" = yes ] && [ "$zram_disk_positive" = yes ]; then
    zram_runtime_active=yes
  fi
  zram_apply_fail=no
  grep -E 'ZRAM_APPLY_FAIL|SERVICE_ZRAM result=apply_failed' "$MODDIR/health.log" "$MODDIR/guard/bootguard.log" 2>/dev/null | tail -n 1 >/dev/null && zram_apply_fail=yes

  zram_icon="$OFF"
  zram_state=disabled
  case "$zram_enabled:$zram_ack" in
    1:explicit_user_enable)
      if [ "$zram_runtime_active" = yes ]; then
        zram_icon="$OK"
        zram_state=runtime_active
      elif [ "$zram_apply_fail" = yes ]; then
        zram_icon="$BAD"
        zram_state=enabled_but_apply_failed
      elif [ "$zram_prop_vendor" = 100p ] || [ "$zram_prop_mmd" = 100% ]; then
        zram_icon="$WARN"
        zram_state=runtime_props_set_swap_waiting
      elif [ "$zram_mod_fstab" = yes ]; then
        zram_icon="$WARN"
        zram_state=enabled_needs_reboot_or_runtime_apply
      else
        zram_icon="$BAD"
        zram_state=enabled_but_fstab_missing
      fi
    ;;
    1:*)
      zram_icon="$WARN"
      zram_state=enabled_but_ack_missing_or_unknown
    ;;
    *)
      zram_icon="$OFF"
      zram_state=disabled
    ;;
  esac

  if [ "$zram_enabled" = 1 ]; then
    zram_value=100p
    [ "$zram_runtime_active" = yes ] || zram_value=100p-pending
  else
    zram_value=off
  fi

  lmk_test_enabled="$(cfg_get LMKD_EARLY_SWAP_LOW_TEST)"
  lmk_test_ack="$(cfg_get LMKD_EARLY_SWAP_LOW_RISK_ACK)"
  [ -n "$lmk_test_enabled" ] || lmk_test_enabled=0
  [ -n "$lmk_test_ack" ] || lmk_test_ack=none
  lmk_early_file="$DATA_ROOT/lmkd-test/early-swap-low.env"
  lmk_post_file="$DATA_ROOT/lmkd-test/postboot.env"
  lmk_apply_state="$(kv_get apply_state "$lmk_early_file")"
  lmk_timing_state="$(kv_get timing_state "$lmk_early_file")"
  lmk_property_after="$(kv_get property_after "$lmk_early_file")"
  lmk_test_ready="$(kv_get test_ready "$lmk_post_file")"
  lmk_consumption_proof="$(kv_get consumption_proof "$lmk_post_file")"
  [ -n "$lmk_consumption_proof" ] || lmk_consumption_proof=not_claimed
  lmk_icon="$OFF"
  lmk_state=stock_disabled
  lmk_value=stock
  if [ "$lmk_test_enabled" = 1 ] && [ "$lmk_test_ack" = explicit_user_test ]; then
    lmk_icon="$WARN"
    lmk_state=experimental_reboot_or_evidence_pending
    lmk_value=test-pending
    if [ "$lmk_test_ready" = yes ]; then
      lmk_icon="$OK"
      lmk_state=early_timing_postboot_readback_verified
      lmk_value=test-active
    elif [ "$lmk_apply_state" = late_refused ]; then
      lmk_icon="$BAD"
      lmk_state=late_write_refused
      lmk_value=test-refused
    elif [ "$lmk_apply_state" = failed ]; then
      lmk_icon="$BAD"
      lmk_state=early_apply_failed
      lmk_value=test-failed
    fi
  fi

  case "$thermal_value" in
    outdoor-extended) thermal_value=outdoor-ext ;;
  esac

  desc="description=P:$polling_icon $polling_value | T:$thermal_icon $thermal_value | Z:$zram_icon $zram_value | L:$lmk_icon $lmk_value | Action: settings/debug"

  {
    printf '%s\n' "SOURCE_ICON=$source_icon"
    printf '%s\n' "SOURCE_STATE=$source_state"
    printf '%s\n' "PLATFORM_SUPPORTED=$platform_supported"
    printf '%s\n' "BUILD_EVIDENCE=$build_evidence"
    printf '%s\n' "PLATFORM_TRANSITION_PENDING=$transition_pending"
    printf '%s\n' "PLATFORM_TRANSITION_PHASE=$transition_phase"
    printf '%s\n' "PLATFORM_TRANSITION_REASON=$transition_reason"
    printf '%s\n' "SOURCE_MANIFEST_VALID=$source_manifest_valid"
    printf '%s\n' "SOURCE_CACHE_VALID=$source_cache_valid"
    printf '%s\n' "PATCH_MANIFEST_VALID=$patch_manifest_valid"
    printf '%s\n' "VALIDATION_REPORT_VALID=$report_valid"
    printf '%s\n' "MATERIALIZATION_VALID=$materialization_valid"
    printf '%s\n' "POLLING_ICON=$polling_icon"
    printf '%s\n' "POLLING_STATE=$polling_state"
    printf '%s\n' "POLLING_MODE=$polling_mode"
    printf '%s\n' "POLLING_EFFECTIVE=$polling_value"
    printf '%s\n' "SOURCE_POLLING_300000=$source_polling"
    printf '%s\n' "REPLACEMENTS=$replacements"
    printf '%s\n' "OVERLAY_POLLING_300000=$overlay_300000"
    printf '%s\n' "OVERLAY_POLLING_5000=$overlay_5000"
    printf '%s\n' "ACTIVE_POLLING_VALID=$active_polling_valid"
    printf '%s\n' "ACTIVE_POLLING_300000=$active_300000"
    printf '%s\n' "ACTIVE_POLLING_5000=$active_5000"
    printf '%s\n' "THERMAL_ICON=$thermal_icon"
    printf '%s\n' "THERMAL_STATE=$thermal_state"
    printf '%s\n' "THERMAL_PROFILE=$thermal_profile"
    printf '%s\n' "SELECTED_PROFILE=$selected_profile"
    printf '%s\n' "ZRAM_ICON=$zram_icon"
    printf '%s\n' "ZRAM_STATE=$zram_state"
    printf '%s\n' "ZRAM_ENABLED=$zram_enabled"
    printf '%s\n' "ZRAM_ACK=$zram_ack"
    printf '%s\n' "ZRAM_VENDOR_PROP=$zram_prop_vendor"
    printf '%s\n' "ZRAM_MMD_PROP=$zram_prop_mmd"
    printf '%s\n' "ZRAM_MMD_ENABLED=$zram_prop_enabled"
    printf '%s\n' "ZRAM_SWAP_ACTIVE=$zram_swap_active"
    printf '%s\n' "ZRAM_RUNTIME_ACTIVE=$zram_runtime_active"
    printf '%s\n' "ZRAM_DISKSIZE=$zram_disk_size"
    printf '%s\n' "MODULE_OVERLAY_READY=$overlay_ready"
    printf '%s\n' "ACTIVE_VENDOR_MATCH=$active_match"
    printf '%s\n' "SAFE_TO_REBOOT=$safe_to_reboot"
    printf '%s\n' "THERMAL_EXPECTED=$thermal_expected"
    printf '%s\n' "COMPAT_REASON=$compat_reason"
    printf '%s\n' "VENDOR_OVERLAY_BACKEND_WARN=$vendor_warn"
    printf '%s\n' "POLLING_VALUE=$polling_value"
    printf '%s\n' "THERMAL_VALUE=$thermal_value"
    printf '%s\n' "ZRAM_VALUE=$zram_value"
    printf '%s\n' "LMKD_TEST_ICON=$lmk_icon"
    printf '%s\n' "LMKD_TEST_STATE=$lmk_state"
    printf '%s\n' "LMKD_TEST_ENABLED=$lmk_test_enabled"
    printf '%s\n' "LMKD_TEST_ACK=$lmk_test_ack"
    printf '%s\n' "LMKD_TEST_APPLY_STATE=${lmk_apply_state:-missing}"
    printf '%s\n' "LMKD_TEST_TIMING_STATE=${lmk_timing_state:-missing}"
    printf '%s\n' "LMKD_TEST_PROPERTY_AFTER=${lmk_property_after:-unset}"
    printf '%s\n' "LMKD_TEST_READY=${lmk_test_ready:-no}"
    printf '%s\n' "LMKD_TEST_CONSUMPTION_PROOF=$lmk_consumption_proof"
    printf '%s\n' "LMKD_TEST_VALUE=$lmk_value"
    printf '%s\n' "MANAGER_DESCRIPTION=$desc"
  } > "$STATUS_FILE" 2>/dev/null || true

  {
    printf '%s\n' "Pixel 10 Thermal & Memory Control"
    printf '%s\n' "Source:  $source_icon  $source_state"
    printf '%s\n' "Polling: $polling_icon  $polling_state"
    printf '%s\n' "Thermal: $thermal_icon  $thermal_state"
    printf '%s\n' "ZRAM:    $zram_icon  $zram_state"
    printf '%s\n' "LMKD:    $lmk_icon  $lmk_state"
    printf '%s\n' ""
    printf '%s\n' "profile=$thermal_profile"
    printf '%s\n' "source_polling_300000=$source_polling"
    printf '%s\n' "replacements=$replacements"
    printf '%s\n' "overlay_polling_5000=$overlay_5000"
    printf '%s\n' "active_polling_5000=$active_5000"
    printf '%s\n' "materialization_valid=$materialization_valid"
    printf '%s\n' "active_vendor_match=$active_match"
    printf '%s\n' "active_polling_valid=$active_polling_valid"
    printf '%s\n' "safe_to_reboot=$safe_to_reboot"
    printf '%s\n' "reason=$compat_reason"
  } > "$STATUS_TXT" 2>/dev/null || true

  rm -f "$tmp" 2>/dev/null || true
  printf '%s\n' "$desc"
}

status_update_description() {
  desc="$(status_collect | tail -n 1)"
  mp="$MODDIR/module.prop"
  [ -w "$mp" ] || return 0
  tmp="$mp.tmp.$$"
  awk -v d="$desc" 'BEGIN{done=0} /^description=/{print d; done=1; next} {print} END{if(done==0) print d}' "$mp" > "$tmp" 2>/dev/null &&
    mv "$tmp" "$mp" 2>/dev/null ||
    rm -f "$tmp" 2>/dev/null ||
    true
  printf '%s\n' "$desc"
}

status_print() {
  status_collect >/dev/null 2>&1 || true
  get_status_kv() {
    grep -E "^$1=" "$STATUS_FILE" 2>/dev/null | tail -n 1 | sed "s/^$1=//"
  }
  printf '%s\n' "Status"
  printf '%s\n' "Source:  $(get_status_kv SOURCE_ICON) $(get_status_kv SOURCE_STATE)"
  printf '%s\n' "Polling: $(get_status_kv POLLING_ICON) $(get_status_kv POLLING_STATE)"
  printf '%s\n' "Thermal: $(get_status_kv THERMAL_ICON) $(get_status_kv THERMAL_STATE)"
  printf '%s\n' "ZRAM:    $(get_status_kv ZRAM_ICON) $(get_status_kv ZRAM_STATE)"
  printf '%s\n' ""
  printf '%s\n' "Source 300000: $(get_status_kv SOURCE_POLLING_300000)"
  printf '%s\n' "Replacements:  $(get_status_kv REPLACEMENTS)"
  printf '%s\n' "Overlay 5000:  $(get_status_kv OVERLAY_POLLING_5000)"
  printf '%s\n' "Active 5000:   $(get_status_kv ACTIVE_POLLING_5000)"
  printf '%s\n' "Materialized:  $(get_status_kv MATERIALIZATION_VALID)"
  printf '%s\n' "Vendor match:  $(get_status_kv ACTIVE_VENDOR_MATCH)"
  printf '%s\n' "Active values: $(get_status_kv ACTIVE_POLLING_VALID)"
  printf '%s\n' "Reboot safe:   $(get_status_kv SAFE_TO_REBOOT)"
  printf '%s\n' "Reason:        $(get_status_kv COMPAT_REASON)"
}

case "${1:-print}" in
  update) status_update_description ;;
  collect) status_collect ;;
  print|status) status_print ;;
  *) status_print ;;
esac

exit 0
