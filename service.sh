#!/system/bin/sh
MODDIR=${0%/*}
ID="pixel-10-pro-xl-thermal-fix"
G="$MODDIR/guard"
L="$G/bootguard.log"
H="$MODDIR/health.log"
CONFIG_FILE="/data/adb/$ID/config.env"
NORMALIZE="$MODDIR/tools/zram/config-normalize.sh"
ZRAM_APPLY="$MODDIR/tools/zram/apply-zram-100p.sh"
EH_CONTROL="$MODDIR/tools/zram/emerald-hill-control.sh"
VERIFY_MODE_FILE="$G/verification-mode.env"
READINESS="$MODDIR/tools/debug/vnext-readiness-summary.sh"
mkdir -p "$G"

printf 'timestamp_start=%s\n' "$(date +%s 2>/dev/null || echo unknown)" > "$H"
printf '%s\n' 'health_log_model=verified_runtime_guard_plus_zram_100p_eh_lmkd_reload_v8' >> "$H"
printf '%s\n' 'lmk_swap_low_policy=resolved_after_config' >> "$H"

[ -r "$NORMALIZE" ] && ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$NORMALIZE" >> "$H" 2>&1 || true
if [ -f "$CONFIG_FILE" ]; then
  . "$CONFIG_FILE" 2>/dev/null || true
fi
if [ "${LMKD_SWAP_LOW_RELOAD:-0}" = 1 ] && [ "${LMKD_SWAP_LOW_RISK_ACK:-}" = explicit_user_reload ]; then
  printf "%s\n" "lmk_swap_low_policy=experimental_reload_1pct" >> "$H"
else
  printf "%s\n" "lmk_swap_low_policy=stock_unmodified" >> "$H"
fi

# Standard lz77eh ZRAM properties may be prepared early. The optional Emerald
# Hill maximum-frequency minimum lock is deferred until Bootguard verifies the
# completed Android boot and active Thermal runtime.
if [ "${ENABLE_ZRAM_100P:-0}" = 1 ] && [ "${ZRAM_RISK_ACK:-}" = explicit_user_enable ]; then
  printf '%s SERVICE_ZRAM action=apply mode=boot_early resetprop=required mmd_restart=skip eh=deferred lmk_reload=%s\n' \
    "$(date -Is 2>/dev/null || date)" "${LMKD_SWAP_LOW_RELOAD:-0}" >> "$L"
  if [ -r "$ZRAM_APPLY" ]; then
    sh "$ZRAM_APPLY" boot_early >> "$H" 2>&1 ||
      printf '%s\n' 'SERVICE_ZRAM result=apply_failed_nonfatal' >> "$H"
  else
    printf '%s\n' 'SERVICE_ZRAM result=apply_script_absent' >> "$H"
  fi
else
  printf '%s SERVICE_ZRAM action=skip enabled=%s ack=%s\n' \
    "$(date -Is 2>/dev/null || date)" "${ENABLE_ZRAM_100P:-0}" "${ZRAM_RISK_ACK:-unset}" >> "$L"
fi

printf '%s SERVICE_START action=runtime_apply optional_zram_supported=true\n' "$(date -Is 2>/dev/null || date)" >> "$L"
while [ "$(getprop sys.boot_completed 2>/dev/null)" != 1 ]; do
  sleep 1
done

verify_mode="$(sed -n 's/^mode=//p' "$VERIFY_MODE_FILE" 2>/dev/null | tail -n 1)"
verify_reason="$(sed -n 's/^reason=//p' "$VERIFY_MODE_FILE" 2>/dev/null | tail -n 1)"
[ "$verify_mode" = fast ] || verify_mode=full
[ -n "$verify_reason" ] || verify_reason=missing_or_invalid_mode_state
if [ "$verify_mode" = full ]; then
  sleep "${BOOTGUARD_SUCCESS_SETTLE_SECONDS:-30}"
else
  sleep "${LIGHT_BOOT_SETTLE_SECONDS:-5}"
fi
printf 'boot_verification_mode=%s\nboot_verification_reason=%s\n' "$verify_mode" "$verify_reason" >> "$H"

{
  printf 'timestamp_complete=%s\n' "$(date +%s 2>/dev/null || echo unknown)"
  printf 'boot_completed=%s\n' "$(getprop sys.boot_completed 2>/dev/null || echo unknown)"
  printf 'boot_id=%s\n' "$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo unknown)"
  printf '\n== flags ==\n'
  [ -e "$MODDIR/disable" ] && printf '%s\n' disable=present || printf '%s\n' disable=absent
  [ -e "$MODDIR/skip_mount" ] && printf '%s\n' skip_mount=present || printf '%s\n' skip_mount=absent
  [ -e "$MODDIR/remove" ] && printf '%s\n' remove=present || printf '%s\n' remove=absent
  printf '%s\n' health_log_complete=yes
} >> "$H" 2>&1

bootguard_verified=0
if [ "$verify_mode" = fast ]; then
  bootguard_verified=1
  printf '%s\n' 'BOOTGUARD_RUNTIME_VERIFICATION=fast_trusted_unchanged_state' >> "$H"
elif [ -s "$MODDIR/tools/bootguard/bootguard-lib.sh" ]; then
  if MODDIR="$MODDIR" CONFIG_FILE="$CONFIG_FILE" sh "$MODDIR/tools/bootguard/bootguard-lib.sh" success-verify >> "$H" 2>&1; then
    bootguard_verified=1
    printf '%s\n' 'BOOTGUARD_RUNTIME_VERIFICATION=full_pass' >> "$H"
  else
    printf '%s\n' 'BOOTGUARD_RUNTIME_VERIFICATION=full_deferred_pending_preserved' >> "$H"
  fi
fi

if [ -s "$READINESS" ]; then
  readiness_tmp="$G/support-readiness.env.tmp.$$"
  if MODDIR="$MODDIR" sh "$READINESS" > "$readiness_tmp" 2>/dev/null; then
    mv "$readiness_tmp" "$G/support-readiness.env" 2>/dev/null || rm -f "$readiness_tmp" 2>/dev/null || true
  else
    rm -f "$readiness_tmp" 2>/dev/null || true
  fi
  readiness_state="$(sed -n 's/^readiness_state=//p' "$G/support-readiness.env" 2>/dev/null | tail -n 1)"
  readiness_reason="$(sed -n 's/^compat_reason=//p' "$G/support-readiness.env" 2>/dev/null | tail -n 1)"
  printf '%s\n' "VNEXT_READINESS state=${readiness_state:-missing} reason=${readiness_reason:-missing}" >> "$H"
fi

# Android may rewrite selected ZRAM properties after early service startup.
# Reapply exactly once after verified boot. The consolidated ZRAM helper also
# applies the opt-in LMKD policy and skips a reload already verified this boot.
if [ "$bootguard_verified" = 1 ] &&
   [ "${ENABLE_ZRAM_100P:-0}" = 1 ] &&
   [ "${ZRAM_RISK_ACK:-}" = explicit_user_enable ]; then
  if [ -r "$ZRAM_APPLY" ] && sh "$ZRAM_APPLY" boot_verified >> "$H" 2>&1; then
    printf '%s\n' "SERVICE_ZRAM_POST_BOOT result=zram_properties_reapplied_no_mmd_restart lmk_policy=${LMKD_SWAP_LOW_RELOAD:-0}" >> "$H"
  else
    printf '%s\n' 'SERVICE_ZRAM_POST_BOOT result=reapply_failed_nonfatal' >> "$H"
  fi
fi

# The lock is a post-verification enhancement, never a boot prerequisite.
# Any failure restores adaptive devfreq and remains nonfatal.
if [ -r "$EH_CONTROL" ]; then
  if [ "$bootguard_verified" = 1 ] &&
     [ "${ENABLE_ZRAM_100P:-0}" = 1 ] &&
     [ "${ZRAM_EMERALD_OC:-0}" = 1 ] &&
     [ "${LAST_ZRAM_100P:-}" = enabled_max_lock ] &&
     [ "${ZRAM_RISK_ACK:-}" = explicit_user_enable ] &&
     [ "${ZRAM_EH_RISK_ACK:-}" = explicit_user_enable_max_lock ]; then
    if MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$EH_CONTROL" apply >> "$H" 2>&1; then
      printf '%s\n' 'SERVICE_ZRAM_EH result=max_frequency_minimum_lock_active' >> "$H"
    else
      MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$EH_CONTROL" restore >> "$H" 2>&1 || true
      printf '%s\n' 'SERVICE_ZRAM_EH result=apply_failed_adaptive_fallback' >> "$H"
    fi
  else
    MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$EH_CONTROL" restore >> "$H" 2>&1 || true
    printf '%s\n' "SERVICE_ZRAM_EH result=adaptive bootguard_verified=$bootguard_verified requested=${ZRAM_EMERALD_OC:-0} eh_ack=${ZRAM_EH_RISK_ACK:-none}" >> "$H"
  fi
fi

cfg_fast() {
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^$1=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^$1=//" | tr -d '\r'
}

kv_fast() {
  [ -r "$2" ] || return 0
  grep -E "^$1=" "$2" 2>/dev/null | tail -n 1 | sed "s/^$1=//" | tr -d '\r'
}

write_manager_description() {
  desc="$1"
  attempt=1
  while [ "$attempt" -le 3 ]; do
    tmp="$MODDIR/module.prop.tmp.$$"
    awk -v d="description=$desc" 'BEGIN{done=0} /^description=/{print d; done=1; next} {print} END{if(done==0) print d}' "$MODDIR/module.prop" > "$tmp" 2>/dev/null && mv "$tmp" "$MODDIR/module.prop" 2>/dev/null || rm -f "$tmp" 2>/dev/null || true
    actual="$(sed -n 's/^description=//p' "$MODDIR/module.prop" 2>/dev/null | tail -n 1)"
    if [ "$actual" = "$desc" ]; then
      printf '%s\n' "MANAGER_BADGES result=verified mode=$verify_mode attempt=$attempt description=$desc" >> "$H"
      return 0
    fi
    sleep 2
    attempt=$((attempt + 1))
  done
  printf '%s\n' "MANAGER_BADGES result=failed mode=$verify_mode reason=dynamic_description_readback_missing" >> "$H"
  return 1
}

update_manager_badges_full() {
  status_lib="$MODDIR/tools/debug/status-lib.sh"
  [ -s "$status_lib" ] || return 1
  sh "$status_lib" update >> "$H" 2>&1 || true
  desc="$(sed -n 's/^description=//p' "$MODDIR/module.prop" 2>/dev/null | tail -n 1)"
  case "$desc" in P:*' | T:'*' | Z:'*' | L:'*) write_manager_description "$desc" ;; *) return 1 ;; esac
}

update_manager_badges_fast() {
  green='🟢'; yellow='🟡'; red='🔴'; white='⚪'
  polling="$(cfg_fast THERMAL_POLLING_MODE)"; [ -n "$polling" ] || polling=mod
  profile="$(cfg_fast THERMAL_OUTDOOR_PROFILE)"; [ -n "$profile" ] || profile=stock
  thermal_disabled="$(cfg_fast THERMAL_DISABLED)"; [ -n "$thermal_disabled" ] || thermal_disabled=0
  if [ "$thermal_disabled" = 1 ]; then
    p_icon="$red"; p_value=disabled; t_icon="$red"; t_value=disabled
  else
    if [ "$polling" = stock ]; then
      p_icon="$white"; p_value=stock
    elif grep -Eq '"PollingDelay"[[:space:]]*:[[:space:]]*5000([^0-9]|$)' /vendor/etc/thermal_info_config.json /vendor/etc/thermal_info_config_charge.json /vendor/etc/thermal_info_config_throttling.json 2>/dev/null; then
      p_icon="$green"; p_value=5000
    else
      p_icon="$yellow"; p_value=mod-pending
    fi
    if [ "$profile" = stock ]; then t_icon="$white"; t_value=stock; else t_icon="$green"; t_value="$profile"; fi
  fi

  z_enabled="$(cfg_fast ENABLE_ZRAM_100P)"; z_ack="$(cfg_fast ZRAM_RISK_ACK)"
  if [ "$z_enabled" = 1 ] && [ "$z_ack" = explicit_user_enable ]; then
    z_icon="$yellow"; z_value=100p-pending
    if grep -Eq '(^|[[:space:]])/dev/block/zram[0-9]+[[:space:]]' /proc/swaps 2>/dev/null && [ "$(cat /sys/block/zram0/disksize 2>/dev/null || printf 0)" -gt 0 ] 2>/dev/null; then z_icon="$green"; z_value=100p; fi
  else
    z_icon="$white"; z_value=off
  fi

  l_enabled="$(cfg_fast LMKD_SWAP_LOW_RELOAD)"; l_ack="$(cfg_fast LMKD_SWAP_LOW_RISK_ACK)"
  l_state="${CONFIG_FILE%/*}/lmkd-reload.env"
  if [ "$l_enabled" = 1 ] && [ "$l_ack" = explicit_user_reload ]; then
    l_icon="$yellow"; l_value=reload-pending
    if [ "$(kv_fast reload_result "$l_state")" = success ] && [ "$(kv_fast property_after "$l_state")" = 1 ] && [ "$(kv_fast lmkd_service_after "$l_state")" = running ]; then l_icon="$green"; l_value=1pct-active; fi
  else
    l_icon="$white"; l_value=stock
  fi
  [ "$t_value" = outdoor-extended ] && t_value=outdoor-ext
  write_manager_description "P:$p_icon $p_value | T:$t_icon $t_value | Z:$z_icon $z_value | L:$l_icon $l_value | Action: settings/debug"
}

if [ "$verify_mode" = fast ]; then
  update_manager_badges_fast || true
else
  update_manager_badges_full || true
fi
exit 0
