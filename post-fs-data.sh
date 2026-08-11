#!/system/bin/sh
MODDIR=${0%/*}
ID="pixel-10-pro-xl-thermal-fix"
CFG="/data/adb/$ID/config.env"
G="$MODDIR/guard"
L="$G/bootguard.log"
BOOTGUARD="$MODDIR/tools/bootguard/bootguard-lib.sh"
TRANSITION="$MODDIR/tools/core/platform-transition.sh"
AUTO_SWITCH="$MODDIR/tools/core/auto-profile-switch.sh"
ZRAM_LAYOUT="$MODDIR/tools/zram/materialize-zram-choice.sh"
mkdir -p "$G"

log(){ printf '%s %s\n' "$(date -Is 2>/dev/null || date)" "$*" >> "$L"; }
getcfg(){ [ -r "$CFG" ] && grep -E "^$1=" "$CFG" 2>/dev/null | tail -n1 | sed "s/^$1=//" | tr -d '\r'; }
cfg_set(){
  key="$1"; value="$2"
  mkdir -p "${CFG%/*}" 2>/dev/null || true
  touch "$CFG" 2>/dev/null || true
  tmp="$CFG.tmp.$$"
  grep -v "^${key}=" "$CFG" 2>/dev/null > "$tmp" || true
  printf '%s=%s\n' "$key" "$value" >> "$tmp"
  chmod 0600 "$tmp" 2>/dev/null || true
  mv "$tmp" "$CFG"
}

# Evaluate the previous attempt before changing or mounting current files.
if [ -s "$BOOTGUARD" ]; then
  MODDIR="$MODDIR" CONFIG_FILE="$CFG" sh "$BOOTGUARD" evaluate >> "$L" 2>&1 || true
fi
[ -e "$MODDIR/remove" ] && { log "GUARD_BLOCK reason=remove_present source=user_marker action=no_change"; exit 0; }
[ -e "$MODDIR/disable" ] && { log "GUARD_BLOCK reason=bootguard_or_user_disable action=no_mount"; exit 0; }

# Action changes the persistent choice only. post-fs-data is the safe pre-mount
# point that makes the module fstab layout match that choice.
if [ -s "$ZRAM_LAYOUT" ]; then
  if MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CFG" sh "$ZRAM_LAYOUT" reconcile >> "$L" 2>&1; then
    log "ZRAM_LAYOUT_RECONCILE result=success enabled=$(getcfg ENABLE_ZRAM_100P)"
  else
    log "ZRAM_LAYOUT_RECONCILE result=failed action=force_stock"
    cfg_set ENABLE_ZRAM_100P 0
    cfg_set ZRAM_EMERALD_OC 0
    cfg_set ZRAM_RESTART_MMD 0
    cfg_set ZRAM_RISK_ACK disabled_by_guard
    cfg_set ZRAM_EH_RISK_ACK disabled_by_guard
    cfg_set LAST_ZRAM_100P disabled
    cfg_set LMKD_SWAP_LOW_RELOAD 0
    cfg_set LMKD_SWAP_LOW_RISK_ACK none
    cfg_set LAST_LMKD_SWAP_LOW_RELOAD disabled
    rm -f "$MODDIR/system/vendor/etc/fstab.zram.100p" 2>/dev/null || true
    if [ -e "$MODDIR/system/vendor/etc/fstab.zram.100p" ]; then
      touch "$MODDIR/skip_mount"
      log "ZRAM_LAYOUT_RECONCILE result=fail_closed reason=stale_layout_not_removable action=skip_mount"
      exit 0
    fi
  fi
else
  cfg_set ENABLE_ZRAM_100P 0
  cfg_set ZRAM_RISK_ACK disabled_by_guard
  cfg_set LMKD_SWAP_LOW_RELOAD 0
  cfg_set LMKD_SWAP_LOW_RISK_ACK none
  rm -f "$MODDIR/system/vendor/etc/fstab.zram.100p" 2>/dev/null || true
  log "ZRAM_LAYOUT_RECONCILE result=helper_missing action=force_stock"
fi

# Quarantine stale thermal overlays and force a stock recapture whenever the
# platform tuple changed.
if [ -s "$TRANSITION" ]; then
  MODDIR="$MODDIR" CONFIG_FILE="$CFG" sh "$TRANSITION" prepare >> "$L" 2>&1 || {
    rm -f "$MODDIR/system/vendor/etc"/thermal_info_config*.json 2>/dev/null || true
    cfg_set THERMAL_DISABLED 1
    touch "$MODDIR/skip_mount"
    log "PLATFORM_TRANSITION_BLOCK reason=prepare_failed action=skip_mount"
    exit 0
  }
else
  rm -f "$MODDIR/system/vendor/etc"/thermal_info_config*.json 2>/dev/null || true
  cfg_set THERMAL_DISABLED 1
  touch "$MODDIR/skip_mount"
  log "PLATFORM_TRANSITION_BLOCK reason=helper_missing action=skip_mount"
  exit 0
fi

# pTune collision guard remains authoritative.
mode="$(getcfg PTUNE_GUARD_MODE)"; [ -n "$mode" ] || mode=strict
case "$mode" in strict|active_only|off) ;; *) mode=strict;; esac
allow="$(getcfg ALLOW_THERMAL_WITH_PTUNE)"
ack="$(getcfg RISK_ACK_PTUNE_THERMAL_COLLISION)"
override=0
[ "$allow" = 1 ] && [ "$ack" = I_UNDERSTAND_BOOTLOOP_RISK ] && override=1
ptune_active=""; ptune_any=""
for d in /data/adb/modules_update/ptune /data/adb/modules/ptune; do
  [ -f "$d/module.prop" ] || continue
  grep -q '^id=ptune$' "$d/module.prop" 2>/dev/null || continue
  [ -e "$d/remove" ] && continue
  [ -z "$ptune_any" ] && ptune_any="$d"
  case "$d" in
    /data/adb/modules_update/ptune) ptune_active="$d" ;;
    *) [ ! -e "$d/disable" ] && [ -z "$ptune_active" ] && ptune_active="$d" ;;
  esac
done
if [ -n "$ptune_active" ] && [ "$override" != 1 ]; then
  printf '%s\n' ptune_active_or_staged > "$G/disabled_reason"
  printf '%s\n' "$ptune_active" > "$G/conflict_ptune_path"
  printf '%s\n' strict_active_skip_mount > "$G/conflict_guard_mode"
  touch "$MODDIR/skip_mount"
  log "GUARD_BLOCK reason=ptune_active_or_staged source=ptune_state action=set_skip_mount_for_current_mount path=$ptune_active"
  exit 0
fi

if [ -s "$AUTO_SWITCH" ]; then
  MODDIR="$MODDIR" sh "$AUTO_SWITCH" >> "$L" 2>&1 ||
    log "AUTO_SWITCH_WARN reason=helper_nonzero"
else
  rm -f "$MODDIR/system/vendor/etc"/thermal_info_config*.json 2>/dev/null || true
  cfg_set THERMAL_DISABLED 1
  touch "$MODDIR/skip_mount"
  log "AUTO_SWITCH_BLOCK reason=helper_missing action=skip_mount"
  exit 0
fi

[ -e "$MODDIR/skip_mount" ] && { log "GUARD_BLOCK reason=auto_switch_or_ptune_skip_mount action=no_arm"; exit 0; }
[ -e "$MODDIR/disable" ] && { log "GUARD_BLOCK reason=disable_after_auto_switch action=no_arm"; exit 0; }

if [ "$override" = 1 ] && [ -n "$ptune_any" ]; then
  ready=yes
  for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
    [ -s "$MODDIR/system/vendor/etc/$f" ] || ready=no
  done
  if [ "$ready" = yes ]; then
    printf '%s\n' allow_thermal_with_ptune > "$G/guard_override"
    printf '%s\n' "$CFG" > "$G/guard_override_source"
    printf '%s\n' explicit_user_override > "$G/risk_ack"
    printf '%s\n' "$ptune_any" > "$G/conflict_ptune_path"
    printf '%s\n' override_allow_mount_with_ptune > "$G/conflict_guard_mode"
    log "GUARD_ALLOW reason=override_with_overlay_ready source=config action=allow_mount path=$ptune_any"
  else
    printf '%s\n' overlay_missing_under_override > "$G/disabled_reason"
    printf '%s\n' override_blocked_overlay_missing > "$G/conflict_guard_mode"
    touch "$MODDIR/skip_mount"
    log "GUARD_BLOCK reason=override_overlay_missing source=module_overlay action=skip_mount"
    exit 0
  fi
fi

# Arm only after the final current-build overlay/disabled state is known.
if [ -s "$BOOTGUARD" ]; then
  MODDIR="$MODDIR" CONFIG_FILE="$CFG" sh "$BOOTGUARD" arm-if-needed >> "$L" 2>&1 ||
    log "BOOTGUARD_ARM_WARN reason=arm_if_needed_nonzero"
fi
log "GUARD_ALLOW reason=post_fs_data_completed source=state action=mount_current_state"
exit 0
