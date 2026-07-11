#!/system/bin/sh
ID="${ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-/data/adb/modules/$ID}"
CONFIG_DIR="/data/adb/$ID"
CONFIG_FILE="$CONFIG_DIR/config.env"
STATUS_FILE="$MODDIR/guard/manager-status.env"
STATUS_TXT="$MODDIR/guard/manager-status.txt"

OK="🟢"
WARN="🟡"
BAD="🔴"
OFF="⚪"

cfg_get() {
  k="$1"
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^${k}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${k}=//" | tr -d '\r'
}

prop_get() {
  getprop "$1" 2>/dev/null || true
}

compat_dump() {
  if [ -x "$MODDIR/tools/bootguard/compat-check.sh" ] || [ -r "$MODDIR/tools/bootguard/compat-check.sh" ]; then
    sh "$MODDIR/tools/bootguard/compat-check.sh" 2>/dev/null || true
  fi
}

kv_get() {
  k="$1"
  f="$2"
  [ -r "$f" ] || return 0
  grep -E "^${k}=" "$f" 2>/dev/null | tail -n 1 | sed "s/^${k}=//" | tr -d '\r'
}

status_collect() {
  mkdir -p "$MODDIR/guard" 2>/dev/null || true
  tmp="$MODDIR/guard/manager-status.compat.$$"
  compat_dump > "$tmp" 2>/dev/null || true

  overlay_ready="$(kv_get MODULE_OVERLAY_READY "$tmp")"
  active_match="$(kv_get ACTIVE_VENDOR_MATCH "$tmp")"
  safe_to_reboot="$(kv_get SAFE_TO_REBOOT "$tmp")"
  thermal_disable="$(kv_get THERMAL_DISABLE "$tmp")"
  thermal_skip_mount="$(kv_get THERMAL_SKIP_MOUNT "$tmp")"
  vendor_warn="$(kv_get VENDOR_OVERLAY_BACKEND_WARN "$tmp")"
  selected_profile="$(kv_get AUTO_SELECTED_PROFILE "$tmp")"

  [ -n "$overlay_ready" ] || overlay_ready="unknown"
  [ -n "$active_match" ] || active_match="unknown"
  [ -n "$safe_to_reboot" ] || safe_to_reboot="unknown"
  [ -n "$thermal_disable" ] || thermal_disable="unknown"
  [ -n "$thermal_skip_mount" ] || thermal_skip_mount="unknown"
  [ -n "$vendor_warn" ] || vendor_warn="unknown"
  [ -n "$selected_profile" ] || selected_profile="$(sed -n 's/^profile=//p' "$MODDIR/install-state.txt" 2>/dev/null | tail -n 1)"
  [ -n "$selected_profile" ] || selected_profile="unknown"

  polling_mode="$(cfg_get THERMAL_POLLING_MODE)"
  polling_effective="$(cfg_get THERMAL_POLLING_EFFECTIVE)"
  [ -n "$polling_mode" ] || polling_mode="$(sed -n 's/^thermal_polling_mode=//p' "$MODDIR/install-state.txt" 2>/dev/null | tail -n 1)"
  [ -n "$polling_effective" ] || polling_effective="$(sed -n 's/^thermal_polling_effective=//p' "$MODDIR/install-state.txt" 2>/dev/null | tail -n 1)"
  [ -n "$polling_mode" ] || polling_mode="mod"

  thermal_profile="$(cfg_get THERMAL_OUTDOOR_PROFILE)"
  [ -n "$thermal_profile" ] || thermal_profile="$(sed -n 's/^thermal_outdoor_profile=//p' "$MODDIR/install-state.txt" 2>/dev/null | tail -n 1)"
  [ -n "$thermal_profile" ] || thermal_profile="stock"

  zram_enabled="$(cfg_get ENABLE_ZRAM_100P)"
  zram_ack="$(cfg_get ZRAM_RISK_ACK)"
  [ -n "$zram_enabled" ] || zram_enabled="0"
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
  [ -r "/vendor/etc/fstab.zram.100p" ] && zram_vendor_fstab=yes
  grep -E '(^|[[:space:]])/dev/block/zram[0-9]+[[:space:]]' /proc/swaps 2>/dev/null | tail -n 1 >/dev/null && zram_swap_active=yes
  if [ -r /sys/block/zram0/disksize ]; then
    zram_disk_size="$(cat /sys/block/zram0/disksize 2>/dev/null | tr -d '\r' | head -n 1)"
  fi
  case "$zram_disk_size" in
    ''|0|*[!0-9]*) zram_disk_positive=no ;;
    *) zram_disk_positive=yes ;;
  esac
  if [ "$zram_swap_active" = "yes" ] && [ "$zram_disk_positive" = "yes" ]; then
    zram_runtime_active=yes
  fi
  zram_apply_fail=no
  grep -E "ZRAM_APPLY_FAIL|SERVICE_ZRAM result=apply_failed" "$MODDIR/health.log" "$MODDIR/guard/bootguard.log" 2>/dev/null | tail -n 1 >/dev/null && zram_apply_fail=yes

  polling_icon="$OFF"
  polling_state="off_or_stock"
  case "$polling_mode" in
    stock)
      polling_icon="$OFF"
      polling_state="stock_values_selected"
    ;;
    *)
      if [ "$thermal_disable" = "present" ] || [ "$thermal_skip_mount" = "present" ]; then
        polling_icon="$BAD"
        polling_state="module_disabled_or_skip_mount"
      elif [ "$overlay_ready" = "yes" ] && [ "$active_match" = "yes" ] && [ "$safe_to_reboot" = "yes" ]; then
        polling_icon="$OK"
        polling_state="active_vendor_match"
      elif [ "$overlay_ready" = "yes" ]; then
        polling_icon="$WARN"
        polling_state="configured_needs_reboot_or_manager_refresh"
      else
        polling_icon="$BAD"
        polling_state="expected_but_overlay_missing"
      fi
    ;;
  esac

  thermal_icon="$OFF"
  thermal_state="stock_or_no_custom_profile"
  case "$thermal_profile" in
    outdoor-safe|outdoor-plus|outdoor-extended)
      if [ "$thermal_disable" = "present" ] || [ "$thermal_skip_mount" = "present" ]; then
        thermal_icon="$BAD"
        thermal_state="module_disabled_or_skip_mount"
      elif [ "$overlay_ready" = "yes" ] && [ "$active_match" = "yes" ] && [ "$safe_to_reboot" = "yes" ]; then
        thermal_icon="$OK"
        thermal_state="custom_profile_active"
      elif [ "$overlay_ready" = "yes" ]; then
        thermal_icon="$WARN"
        thermal_state="custom_profile_configured_needs_reboot_or_refresh"
      else
        thermal_icon="$BAD"
        thermal_state="custom_profile_expected_but_missing"
      fi
    ;;
    *)
      thermal_icon="$OFF"
      thermal_state="stock_profile_selected"
    ;;
  esac

  zram_icon="$OFF"
  zram_state="disabled"
  case "$zram_enabled:$zram_ack" in
    1:explicit_user_enable)
      if [ "$zram_runtime_active" = "yes" ]; then
        zram_icon="$OK"
        zram_state="runtime_active"
      elif [ "$zram_apply_fail" = "yes" ]; then
        zram_icon="$BAD"
        zram_state="enabled_but_apply_failed"
      elif [ "$zram_prop_vendor" = "100p" ] || [ "$zram_prop_mmd" = "100%" ]; then
        zram_icon="$WARN"
        zram_state="runtime_props_set_swap_waiting"
      elif [ "$zram_mod_fstab" = "yes" ]; then
        zram_icon="$WARN"
        zram_state="enabled_needs_reboot_or_runtime_apply"
      else
        zram_icon="$BAD"
        zram_state="enabled_but_fstab_missing"
      fi
    ;;
    1:*)
      zram_icon="$WARN"
      zram_state="enabled_but_ack_missing_or_unknown"
    ;;
    *)
      zram_icon="$OFF"
      zram_state="disabled"
    ;;
  esac

  polling_value="$polling_effective"
  [ -n "$polling_value" ] || polling_value="$polling_mode"
  [ -n "$polling_value" ] || polling_value="unknown"
  thermal_value="$thermal_profile"
  case "$thermal_value" in
    outdoor-extended) thermal_value="outdoor-ext" ;;
    outdoor-plus) thermal_value="outdoor-plus" ;;
    outdoor-safe) thermal_value="outdoor-safe" ;;
    ''|stock|stock_profile_selected) thermal_value="stock" ;;
  esac
  if [ "$zram_enabled" = "1" ]; then
    zram_value="100p"
    [ "$zram_runtime_active" = "yes" ] || zram_value="100p-pending"
  else
    zram_value="off"
  fi
  desc="description=P:$polling_icon $polling_value | T:$thermal_icon $thermal_value | Z:$zram_icon $zram_value | Action: settings/debug"

  {
    printf '%s\n' "POLLING_ICON=$polling_icon"
    printf '%s\n' "POLLING_STATE=$polling_state"
    printf '%s\n' "POLLING_MODE=$polling_mode"
    printf '%s\n' "POLLING_EFFECTIVE=$polling_effective"
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
    printf '%s\n' "VENDOR_OVERLAY_BACKEND_WARN=$vendor_warn"
    printf '%s\n' "POLLING_VALUE=$polling_value"
    printf '%s\n' "THERMAL_VALUE=$thermal_value"
    printf '%s\n' "ZRAM_VALUE=$zram_value"
    printf '%s\n' "MANAGER_DESCRIPTION=$desc"
  } > "$STATUS_FILE" 2>/dev/null || true

  {
    printf '%s\n' "Pixel 10 Thermal & Memory Control"
    printf '%s\n' "Polling: $polling_icon  $polling_state"
    printf '%s\n' "Thermal: $thermal_icon  $thermal_state"
    printf '%s\n' "ZRAM:    $zram_icon  $zram_state"
    printf '%s\n' ""
    printf '%s\n' "profile=$thermal_profile"
    printf '%s\n' "selected_profile=$selected_profile"
    printf '%s\n' "overlay_ready=$overlay_ready"
    printf '%s\n' "active_vendor_match=$active_match"
    printf '%s\n' "safe_to_reboot=$safe_to_reboot"
  } > "$STATUS_TXT" 2>/dev/null || true

  rm -f "$tmp" 2>/dev/null || true
  printf '%s\n' "$desc"
}

status_update_description() {
  desc="$(status_collect | tail -n 1)"
  mp="$MODDIR/module.prop"
  [ -w "$mp" ] || return 0
  tmp="$mp.tmp.$$"
  awk -v d="$desc" 'BEGIN{done=0} /^description=/{print d; done=1; next} {print} END{if(done==0) print d}' "$mp" > "$tmp" 2>/dev/null && mv "$tmp" "$mp" 2>/dev/null || rm -f "$tmp" 2>/dev/null || true
  printf '%s\n' "$desc"
}

status_word() {
  case "$1" in
    active_vendor_match|custom_profile_active|runtime_active|runtime_props_active) echo active ;;
    configured_needs_reboot_or_manager_refresh|custom_profile_configured_needs_reboot_or_refresh|enabled_needs_reboot_or_runtime_apply|runtime_props_set_swap_waiting) echo pending ;;
    disabled|stock_profile_selected|stock_values_selected|off_or_stock|stock_or_no_custom_profile) echo off ;;
    *) echo "$1" ;;
  esac
}

status_print() {
  status_collect >/dev/null 2>&1 || true
  get_status_kv() {
    _k="$1"
    grep -E "^${_k}=" "$STATUS_FILE" 2>/dev/null | tail -n 1 | sed "s/^${_k}=//"
  }
  short_state() {
    case "$1" in
      active_vendor_match|custom_profile_active|runtime_active) echo active ;;
      *pending*|*waiting*|*refresh*|*reboot*) echo pending ;;
      *failed*|*missing*|*problem*) echo problem ;;
      stock_profile_selected|stock_values_selected|disabled|off_or_stock|stock_or_no_custom_profile) echo off ;;
      *) echo "$1" ;;
    esac
  }
  pi="$(get_status_kv POLLING_ICON)"
  ti="$(get_status_kv THERMAL_ICON)"
  zi="$(get_status_kv ZRAM_ICON)"
  ps="$(short_state "$(get_status_kv POLLING_STATE)")"
  ts="$(short_state "$(get_status_kv THERMAL_STATE)")"
  zs="$(short_state "$(get_status_kv ZRAM_STATE)")"
  prof="$(get_status_kv THERMAL_PROFILE)"
  vendor="$(get_status_kv ACTIVE_VENDOR_MATCH)"
  reboot="$(get_status_kv SAFE_TO_REBOOT)"
  overlay="$(get_status_kv MODULE_OVERLAY_READY)"
  [ "$vendor" = yes ] && vendor=match
  [ "$reboot" = yes ] && reboot=safe
  printf '%s\n' "Status"
  printf '%s\n' "Polling: $pi $ps"
  printf '%s\n' "Thermal: $ti $ts"
  printf '%s\n' "ZRAM:    $zi $zs"
  printf '%s\n' ""
  printf '%s\n' "Profile: $prof"
  printf '%s\n' "Overlay: $overlay"
  printf '%s\n' "Vendor: $vendor"
  printf '%s\n' "Reboot: $reboot"
  printf '%s\n' ""
  printf '%s\n' "Legend"
  printf '%s\n' "🟢 active"
  printf '%s\n' "🟡 pending"
  printf '%s\n' "🔴 problem"
  printf '%s\n' "⚪ off"
}

case "${1:-print}" in
  update) status_update_description ;;
  collect) status_collect ;;
  print|status) status_print ;;
  *) status_print ;;
esac

exit 0
