#!/system/bin/sh
MODDIR=${0%/*}; ID="pixel-10-pro-xl-thermal-fix"; CFG="/data/adb/$ID/config.env"; G="$MODDIR/guard"; L="$G/bootguard.log"; mkdir -p "$G"
log(){ echo "$(date -Is 2>/dev/null || date) $*" >> "$L"; }
getcfg(){ [ -r "$CFG" ] && grep -E "^$1=" "$CFG" 2>/dev/null | tail -n1 | sed "s/^$1=//" | tr -d '\r'; }
mode="$(getcfg PTUNE_GUARD_MODE)"; [ -n "$mode" ] || mode=strict; case "$mode" in strict|active_only|off) ;; *) mode=strict;; esac
allow="$(getcfg ALLOW_THERMAL_WITH_PTUNE)"; ack="$(getcfg RISK_ACK_PTUNE_THERMAL_COLLISION)"; override=0; [ "$allow" = 1 ] && [ "$ack" = I_UNDERSTAND_BOOTLOOP_RISK ] && override=1
[ -e "$MODDIR/remove" ] && { log "GUARD_BLOCK reason=remove_present source=user_marker action=no_change"; exit 0; }
[ -e "$MODDIR/disable" ] && { log "GUARD_BLOCK reason=disable_present source=user_marker action=no_change"; exit 0; }
[ -e "$MODDIR/skip_mount" ] && { log "GUARD_BLOCK reason=skip_mount_present source=user_marker action=no_change"; exit 0; }
ptune_active=""; ptune_any=""
for d in /data/adb/modules_update/ptune /data/adb/modules/ptune; do [ -f "$d/module.prop" ] || continue; grep -q '^id=ptune$' "$d/module.prop" 2>/dev/null || continue; [ -e "$d/remove" ] && continue; [ -z "$ptune_any" ] && ptune_any="$d"; case "$d" in /data/adb/modules_update/ptune) ptune_active="$d";; *) [ ! -e "$d/disable" ] && [ -z "$ptune_active" ] && ptune_active="$d";; esac; done
if [ -n "$ptune_active" ] && [ "$override" != 1 ]; then echo ptune_active_or_staged > "$G/disabled_reason"; echo "$ptune_active" > "$G/conflict_ptune_path"; echo strict_active_skip_mount > "$G/conflict_guard_mode"; touch "$MODDIR/skip_mount"; log "GUARD_BLOCK reason=ptune_active_or_staged source=ptune_state action=set_skip_mount_for_next_boot path=$ptune_active"; exit 0; fi
if [ "$override" = 1 ] && [ -n "$ptune_any" ]; then ready=yes; for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do [ -s "$MODDIR/system/vendor/etc/$f" ] || ready=no; done; if [ "$ready" = yes ]; then echo allow_thermal_with_ptune > "$G/guard_override"; echo "$CFG" > "$G/guard_override_source"; echo explicit_user_override > "$G/risk_ack"; echo "$ptune_any" > "$G/conflict_ptune_path"; echo override_allow_mount_with_ptune > "$G/conflict_guard_mode"; log "GUARD_ALLOW reason=override_with_overlay_ready source=config action=allow_mount path=$ptune_any"; else echo overlay_missing_under_override > "$G/disabled_reason"; echo override_blocked_overlay_missing > "$G/conflict_guard_mode"; touch "$MODDIR/skip_mount"; log "GUARD_BLOCK reason=override_overlay_missing source=module_overlay action=set_skip_mount_for_next_boot"; fi; exit 0; fi
log "GUARD_ALLOW reason=no_active_ptune_conflict source=state action=passive"
exit 0
