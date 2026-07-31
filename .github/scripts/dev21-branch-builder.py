#!/usr/bin/env python3
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, content: str) -> None:
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"guard failed: {label}: expected 1 occurrence, found {count}")
    return text.replace(old, new, 1)


module_prop = read("module.prop")
if "version=2.0.0-alpha.3-dev.21" in module_prop:
    print("Dev.21 already built")
    raise SystemExit(0)
module_prop = replace_once(module_prop, "version=2.0.0-alpha.3-dev.20", "version=2.0.0-alpha.3-dev.21", "module version")
module_prop = replace_once(module_prop, "versionCode=1016231", "versionCode=1016232", "module versionCode")
module_prop = replace_once(
    module_prop,
    "description=V2 Alpha 3 dev.20 source: consolidated LMKD 1% reload in the ZRAM path, AOSP reinit-first fallback restart, and reliable automatic status badges.",
    "description=V2 Alpha 3 dev.21 test: Magisk resetprop-first LMKD write with readback fallback, lightweight unchanged-boot path, and preserved Bootguard escalation.",
    "module description",
)
write("module.prop", module_prop)

apply = read("tools/zram/apply-zram-100p.sh")
apply = replace_once(
    apply,
    'RESET="$MODDIR/tools/resetprop-rs"\n',
    'RESET="$MODDIR/tools/resetprop-rs"\nSYSTEM_RESETPROP="${LMKD_SYSTEM_RESETPROP_BIN:-resetprop}"\n',
    "system resetprop variable",
)
apply = replace_once(
    apply,
    'LMKD_ACK="${LMKD_SWAP_LOW_RISK_ACK:-none}"\n',
    'LMKD_ACK="${LMKD_SWAP_LOW_RISK_ACK:-none}"\nLMKD_PROPERTY_WRITER=none\n',
    "writer state",
)
apply = replace_once(
    apply,
    '    printf \'property_after=%s\\n\' "${after:-unset}"\n',
    '    printf \'property_after=%s\\n\' "${after:-unset}"\n    printf \'property_writer=%s\\n\' "${LMKD_PROPERTY_WRITER:-none}"\n',
    "writer evidence",
)
marker = "apply_lmkd_policy() {\n"
writer_func = r'''set_lmkd_property_1() {
  LMKD_PROPERTY_WRITER=none
  if command -v "$SYSTEM_RESETPROP" >/dev/null 2>&1; then
    "$SYSTEM_RESETPROP" ro.lmk.swap_free_low_percentage 1 >/dev/null 2>&1 || true
    if [ "$(prop_get ro.lmk.swap_free_low_percentage)" = 1 ]; then
      LMKD_PROPERTY_WRITER=magisk_resetprop
      return 0
    fi
  fi

  "$RESET" -n ro.lmk.swap_free_low_percentage 1 >/dev/null 2>&1 || true
  if [ "$(prop_get ro.lmk.swap_free_low_percentage)" = 1 ]; then
    LMKD_PROPERTY_WRITER=resetprop_rs_fallback
    return 0
  fi
  return 1
}

'''
apply = replace_once(apply, marker, writer_func + marker, "insert LMKD writer")
old_writer = r'''  remember_original_lmkd_value "$before"
  if command -v resetprop >/dev/null 2>&1; then
    resetprop ro.lmk.swap_free_low_percentage 1 2>/dev/null || "$RESET" ro.lmk.swap_free_low_percentage 1 2>/dev/null || true
  else
    "$RESET" ro.lmk.swap_free_low_percentage 1 2>/dev/null || true
  fi
  after="$(prop_get ro.lmk.swap_free_low_percentage)"
  [ "$after" = 1 ] || {
    write_lmkd_state failed property_readback "$before" "$after" "$(lmkd_pid)" "$(lmkd_pid)" "$(lmkd_service)" "$(lmkd_service)" readback_mismatch
    return 1
  }
'''
new_writer = r'''  remember_original_lmkd_value "$before"
  if ! set_lmkd_property_1; then
    after="$(prop_get ro.lmk.swap_free_low_percentage)"
    write_lmkd_state failed property_readback "$before" "$after" "$(lmkd_pid)" "$(lmkd_pid)" "$(lmkd_service)" "$(lmkd_service)" both_property_writers_failed_readback
    return 1
  fi
  after="$(prop_get ro.lmk.swap_free_low_percentage)"
  log "LMKD_PROPERTY_WRITE result=success writer=$LMKD_PROPERTY_WRITER property_after=$after"
'''
apply = replace_once(apply, old_writer, new_writer, "LMKD writer implementation")
write("tools/zram/apply-zram-100p.sh", apply)

bootguard = read("tools/bootguard/bootguard-lib.sh")
bootguard = replace_once(
    bootguard,
    'TRANSITION="$G/platform-transition.env"\n',
    'TRANSITION="$G/platform-transition.env"\nVERIFY_MODE="$G/verification-mode.env"\nVERIFY_REASON=unknown\n',
    "verification mode path",
)
bootguard = replace_once(
    bootguard,
    '  printf \'%s\\n\' "thermal_disabled=$(getcfg THERMAL_DISABLED)"\n  printf \'%s\\n\' "patch_manifest_sha256=$(sha_file "$G/patch-manifest.tsv")"\n',
    '  printf \'%s\\n\' "thermal_disabled=$(getcfg THERMAL_DISABLED)"\n  printf \'%s\\n\' "config_sha256=$(sha_file "$CONFIG_FILE")"\n  printf \'%s\\n\' "patch_manifest_sha256=$(sha_file "$G/patch-manifest.tsv")"\n',
    "config signature",
)
snapshot_end = '''  printf '%s\\n' "overlay_throttling_sha256=$(sha_file "$MODDIR/system/vendor/etc/thermal_info_config_throttling.json")"
}
'''
boot_policy = r'''  printf '%s\n' "overlay_throttling_sha256=$(sha_file "$MODDIR/system/vendor/etc/thermal_info_config_throttling.json")"
}

snapshot_signature() {
  snapshot | grep -v '^timestamp=' | sha256sum 2>/dev/null | awk '{print $1}'
}

needs_full_verify() {
  VERIFY_REASON=unchanged_verified_state
  debug="$(getcfg DEBUG_MODE)"
  [ -n "$debug" ] || debug="$(getcfg debug_mode)"
  canary="$(getcfg CANARY_DIAGNOSTIC_MODE)"
  if [ "$debug" = 1 ] || [ "$canary" = 1 ]; then
    VERIFY_REASON=debug_or_canary
    return 0
  fi
  if [ "$(pending_transition)" = yes ]; then
    VERIFY_REASON=platform_transition_pending
    return 0
  fi
  if [ "$(counter_get)" -gt 0 ] 2>/dev/null; then
    VERIFY_REASON=previous_pending_boot
    return 0
  fi
  if [ ! -s "$LG" ]; then
    VERIFY_REASON=no_last_good
    return 0
  fi
  previous="$(kv_get state_signature "$LG")"
  current="$(snapshot_signature)"
  if [ -z "$previous" ] || [ -z "$current" ] || [ "$previous" != "$current" ]; then
    VERIFY_REASON=state_signature_changed
    return 0
  fi
  return 1
}

arm_if_needed() {
  mkdir -p "$G"
  if needs_full_verify; then
    {
      printf '%s\n' mode=full
      printf 'reason=%s\n' "$VERIFY_REASON"
    } > "$VERIFY_MODE"
    chmod 0600 "$VERIFY_MODE" 2>/dev/null || true
    log "BOOTGUARD_MODE mode=full reason=$VERIFY_REASON"
    arm
  else
    rm -f "$P"
    {
      printf '%s\n' mode=fast
      printf '%s\n' reason=unchanged_verified_state
    } > "$VERIFY_MODE"
    chmod 0600 "$VERIFY_MODE" 2>/dev/null || true
    log 'BOOTGUARD_MODE mode=fast reason=unchanged_verified_state action=no_full_verify'
  fi
}
'''
bootguard = replace_once(bootguard, snapshot_end, boot_policy, "boot verification policy")
old_success = r'''success() {
  snapshot > "$LG"
  chmod 0600 "$LG" 2>/dev/null || true
  rm -f "$P"
  counter_set 0
  rm -f "$G/disabled_reason"
  log "BOOTGUARD_SUCCESS build=$(build_id)"
}
'''
new_success = r'''success() {
  tmp="$LG.tmp.$$"
  snapshot > "$tmp"
  printf 'state_signature=%s\n' "$(snapshot_signature)" >> "$tmp"
  chmod 0600 "$tmp" 2>/dev/null || true
  mv "$tmp" "$LG"
  rm -f "$P"
  counter_set 0
  rm -f "$G/disabled_reason"
  log "BOOTGUARD_SUCCESS build=$(build_id) state_signature=$(kv_get state_signature "$LG")"
}
'''
bootguard = replace_once(bootguard, old_success, new_success, "signed last-good state")
bootguard = replace_once(
    bootguard,
    '  arm) arm ;;\n  preflight) evaluate && arm ;;\n',
    '  arm) arm ;;\n  arm-if-needed) arm_if_needed ;;\n  needs-full-verify) if needs_full_verify; then printf \'mode=full\\nreason=%s\\n\' "$VERIFY_REASON"; else printf \'mode=fast\\nreason=%s\\n\' "$VERIFY_REASON"; fi ;;\n  preflight) evaluate && arm_if_needed ;;\n',
    "bootguard commands",
)
write("tools/bootguard/bootguard-lib.sh", bootguard)

post_fs = read("post-fs-data.sh")
post_fs = replace_once(
    post_fs,
    '  MODDIR="$MODDIR" CONFIG_FILE="$CFG" sh "$BOOTGUARD" arm >> "$L" 2>&1 ||\n    log "BOOTGUARD_ARM_WARN reason=arm_nonzero"\n',
    '  MODDIR="$MODDIR" CONFIG_FILE="$CFG" sh "$BOOTGUARD" arm-if-needed >> "$L" 2>&1 ||\n    log "BOOTGUARD_ARM_WARN reason=arm_if_needed_nonzero"\n',
    "conditional bootguard arm",
)
write("post-fs-data.sh", post_fs)

service = read("service.sh")
service = replace_once(
    service,
    'EH_CONTROL="$MODDIR/tools/zram/emerald-hill-control.sh"\n',
    'EH_CONTROL="$MODDIR/tools/zram/emerald-hill-control.sh"\nVERIFY_MODE_FILE="$G/verification-mode.env"\n',
    "service verification mode",
)
old_boot = r'''printf '%s SERVICE_START action=verified_runtime_health optional_zram_supported=true\n' "$(date -Is 2>/dev/null || date)" >> "$L"
while [ "$(getprop sys.boot_completed 2>/dev/null)" != 1 ]; do
  sleep 1
done

sleep "${BOOTGUARD_SUCCESS_SETTLE_SECONDS:-30}"

{
  printf 'timestamp_complete=%s\n' "$(date +%s 2>/dev/null || echo unknown)"
  printf 'boot_completed=%s\n' "$(getprop sys.boot_completed 2>/dev/null || echo unknown)"
  printf 'boot_id=%s\n' "$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo unknown)"
  printf '\n== flags ==\n'
  [ -e "$MODDIR/disable" ] && printf '%s\n' disable=present || printf '%s\n' disable=absent
  [ -e "$MODDIR/skip_mount" ] && printf '%s\n' skip_mount=present || printf '%s\n' skip_mount=absent
  [ -e "$MODDIR/remove" ] && printf '%s\n' remove=present || printf '%s\n' remove=absent
  printf '\n== mounts ==\n'
  grep -E "$ID|/vendor/etc/thermal_info_config|/vendor/etc/fstab.zram.100p" /proc/mounts 2>/dev/null || true
  printf '%s\n' health_log_complete=yes
} >> "$H" 2>&1

bootguard_verified=0
if [ -s "$MODDIR/tools/bootguard/bootguard-lib.sh" ]; then
  if MODDIR="$MODDIR" CONFIG_FILE="$CONFIG_FILE" sh "$MODDIR/tools/bootguard/bootguard-lib.sh" success-verify >> "$H" 2>&1; then
    bootguard_verified=1
    printf '%s\n' 'BOOTGUARD_RUNTIME_VERIFICATION=pass' >> "$H"
  else
    printf '%s\n' 'BOOTGUARD_RUNTIME_VERIFICATION=deferred_pending_preserved' >> "$H"
  fi
fi
'''
new_boot = r'''printf '%s SERVICE_START action=runtime_apply optional_zram_supported=true\n' "$(date -Is 2>/dev/null || date)" >> "$L"
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
'''
service = replace_once(service, old_boot, new_boot, "light boot service path")
old_badges = service[service.index("update_manager_badges() {"):]
new_badges = r'''cfg_fast() {
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
'''
service = service[:service.index("update_manager_badges() {")] + new_badges
write("service.sh", service)

test = read("tests/test-dev19-lmkd-early-test.sh")
test = replace_once(test, ': > "$tmp/reinit_fail"\n', ': > "$tmp/reinit_fail"\n: > "$tmp/system_resetprop_fail"\n', "system resetprop fail fixture")
test = replace_once(
    test,
    "printf '%s\\n' '#!/usr/bin/env bash' 'cat \"$PID_FILE\"' > \"$tmp/bin/pidof\"\n",
    "printf '%s\\n' '#!/usr/bin/env bash' 'cat \"$PID_FILE\"' > \"$tmp/bin/pidof\"\nprintf '%s\\n' '#!/usr/bin/env bash' 'set -euo pipefail' '[ -s \"$SYSTEM_RESETPROP_FAIL_FILE\" ] && exit 1' 'printf \"%s\\n\" \"$2\" > \"$PROP_FILE\"' > \"$tmp/bin/resetprop\"\n",
    "system resetprop mock",
)
test = replace_once(
    test,
    '  LMKD_BOOT_ID_FILE="$tmp/boot_id" LMKD_UPTIME_FILE="$tmp/uptime" \\\n  PROP_FILE="$tmp/property" SERVICE_FILE="$tmp/service" REINIT_FILE="$tmp/reinit" REINIT_FAIL_FILE="$tmp/reinit_fail" PID_FILE="$tmp/pid" \\\n',
    '  LMKD_BOOT_ID_FILE="$tmp/boot_id" LMKD_UPTIME_FILE="$tmp/uptime" LMKD_SYSTEM_RESETPROP_BIN="$tmp/bin/resetprop" \\\n  PROP_FILE="$tmp/property" SERVICE_FILE="$tmp/service" REINIT_FILE="$tmp/reinit" REINIT_FAIL_FILE="$tmp/reinit_fail" SYSTEM_RESETPROP_FAIL_FILE="$tmp/system_resetprop_fail" PID_FILE="$tmp/pid" \\\n',
    "system resetprop env",
)
test = replace_once(test, 'chmod +x "$tmp/bin/"* "$tmp/mod/tools/resetprop-rs"', 'chmod +x "$tmp/bin/"* "$tmp/mod/tools/resetprop-rs"', "chmod guard")
test = replace_once(test, "grep -Fxq 'property_after=1' \"$tmp/lmkd-reload.env\"\n", "grep -Fxq 'property_after=1' \"$tmp/lmkd-reload.env\"\ngrep -Fxq 'property_writer=magisk_resetprop' \"$tmp/lmkd-reload.env\"\n", "system writer assertion")
test = replace_once(test, 'printf \'%s\\n\' fail > "$tmp/reinit_fail"\n', 'printf \'%s\\n\' fail > "$tmp/reinit_fail"\nprintf \'%s\\n\' fail > "$tmp/system_resetprop_fail"\n', "fallback writer activation")
test = replace_once(test, "grep -Fxq 'lmkd_pid_after=200' \"$tmp/lmkd-reload.env\"\n", "grep -Fxq 'lmkd_pid_after=200' \"$tmp/lmkd-reload.env\"\ngrep -Fxq 'property_writer=resetprop_rs_fallback' \"$tmp/lmkd-reload.env\"\n", "fallback writer assertion")
test = replace_once(test, "grep -Fq 'version=2.0.0-alpha.3-dev.20' \"$module_prop\"\ngrep -Fq 'versionCode=1016231' \"$module_prop\"\n", "grep -Fq 'version=2.0.0-alpha.3-dev.21' \"$module_prop\"\ngrep -Fq 'versionCode=1016232' \"$module_prop\"\n", "Dev.21 version assertions")
test = replace_once(test, "printf '%s\\n' 'PASS dev20_lmkd_consolidated_in_zram_script'", "printf '%s\\n' 'PASS dev21_lmkd_consolidated_in_zram_script'", "pass label")
test = replace_once(test, "printf '%s\\n' 'RESULT: PIXEL_THERMAL_DEV20_LMKD_RELOAD_PASS'", "printf '%s\\n' 'PASS dev21_magisk_resetprop_first_with_readback_fallback'\nprintf '%s\\n' 'RESULT: PIXEL_THERMAL_DEV21_LMKD_RELOAD_PASS'", "result label")
write("tests/test-dev19-lmkd-early-test.sh", test)

light_test = r'''#!/usr/bin/env bash
set -euo pipefail
root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
bootguard="$root/tools/bootguard/bootguard-lib.sh"
service="$root/service.sh"
post_fs="$root/post-fs-data.sh"
apply="$root/tools/zram/apply-zram-100p.sh"
module_prop="$root/module.prop"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mod="$tmp/mod"
state="$tmp/state"
mkdir -p "$mod/guard" "$mod/system/vendor/etc" "$state"
cp "$module_prop" "$mod/module.prop"
printf '%s\n' 'THERMAL_POLLING_MODE=mod' 'THERMAL_OUTDOOR_PROFILE=stock' 'THERMAL_DISABLED=0' > "$state/config.env"
printf '%s\n' '{}' > "$mod/validation_report.json"
printf '%s\n' x > "$mod/guard/patch-manifest.tsv"
printf '%s\n' '{}' > "$mod/system/vendor/etc/thermal_info_config.json"
printf '%s\n' '{}' > "$mod/system/vendor/etc/thermal_info_config_charge.json"
printf '%s\n' '{}' > "$mod/system/vendor/etc/thermal_info_config_throttling.json"

MODDIR="$mod" CONFIG_FILE="$state/config.env" GUARD_DIR="$mod/guard" sh "$bootguard" arm-if-needed
[[ "$(sed -n 's/^mode=//p' "$mod/guard/verification-mode.env")" == full ]]
[[ -e "$mod/guard/pending_boot" ]]
MODDIR="$mod" CONFIG_FILE="$state/config.env" GUARD_DIR="$mod/guard" sh "$bootguard" success
[[ -s "$mod/guard/last_good.env" ]]
grep -Eq '^state_signature=[0-9a-f]{64}$' "$mod/guard/last_good.env"
MODDIR="$mod" CONFIG_FILE="$state/config.env" GUARD_DIR="$mod/guard" sh "$bootguard" arm-if-needed
[[ "$(sed -n 's/^mode=//p' "$mod/guard/verification-mode.env")" == fast ]]
[[ ! -e "$mod/guard/pending_boot" ]]
printf '%s\n' 'THERMAL_POLLING_MODE=stock' 'THERMAL_OUTDOOR_PROFILE=stock' 'THERMAL_DISABLED=0' > "$state/config.env"
MODDIR="$mod" CONFIG_FILE="$state/config.env" GUARD_DIR="$mod/guard" sh "$bootguard" arm-if-needed
[[ "$(sed -n 's/^mode=//p' "$mod/guard/verification-mode.env")" == full ]]
[[ -e "$mod/guard/pending_boot" ]]

bash -n "$bootguard"
bash -n "$service"
bash -n "$post_fs"
bash -n "$apply"
grep -Fq 'arm-if-needed' "$post_fs"
grep -Fq 'BOOTGUARD_RUNTIME_VERIFICATION=fast_trusted_unchanged_state' "$service"
grep -Fq 'update_manager_badges_fast' "$service"
grep -Fq 'update_manager_badges_full' "$service"
grep -Fq 'LMKD_SYSTEM_RESETPROP_BIN' "$apply"
grep -Fq 'property_writer=magisk_resetprop' "$root/tests/test-dev19-lmkd-early-test.sh"
grep -Fq 'version=2.0.0-alpha.3-dev.21' "$module_prop"
grep -Fq 'versionCode=1016232' "$module_prop"

printf '%s\n' 'PASS dev21_first_or_changed_boot_requires_full_verification'
printf '%s\n' 'PASS dev21_unchanged_boot_uses_fast_path_without_pending_boot'
printf '%s\n' 'PASS dev21_config_change_rearms_full_bootguard'
printf '%s\n' 'PASS dev21_fast_badges_avoid_full_compat_scan'
printf '%s\n' 'PASS dev21_magisk_resetprop_writer_is_evidenced'
printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV21_LIGHT_BOOT_PASS'
'''
write("tests/test-dev21-light-boot.sh", light_test)

notes = '''# 2.0.0-alpha.3-dev.21 (test source)\n\nDev.21 is an unreleased device-test build.\n\n## LMKD property writer\n\n- Keep `resetprop-rs` for normal ZRAM properties.\n- Set `ro.lmk.swap_free_low_percentage=1` with Magisk's system `resetprop` first.\n- Verify the property readback.\n- Fall back to `resetprop-rs` only when the system writer is unavailable or its readback is not `1`.\n- Record `property_writer=magisk_resetprop|resetprop_rs_fallback` in LMKD Reload Evidence.\n\n## Lightweight normal boots\n\nFull Dynamic V2 compatibility verification now runs only when needed: first install, module update, firmware/build change, configuration or overlay change, pending platform transition, previous pending boot, debug/canary mode, or missing/invalid last-good evidence.\n\nAn unchanged verified boot skips the full compatibility scan. It only loads the selected state, applies ZRAM/LMKD/EH, performs lightweight live readbacks, refreshes the P/T/Z/L badges, and exits. Bootguard still escalates automatically whenever the signed state changes.\n\n## Required device checks\n\n1. Dirty-flash Dev.21 and reboot.\n2. Verify the first Dev.21 boot reports `boot_verification_mode=full`.\n3. Reboot again without changing settings and verify `boot_verification_mode=fast`.\n4. Confirm badges return automatically without opening Action.\n5. Confirm LMKD Reload Evidence reports property `1`, a successful reload, and the property writer used.\n6. Remove the module in Magisk, reboot, and verify both `/data/adb/modules/pixel-10-pro-xl-thermal-fix` and `/data/adb/pixel-10-pro-xl-thermal-fix` are absent.\n'''
write("release-notes/2.0.0-alpha.3-dev.21.md", notes)

readme = read("README.md")
readme = replace_once(
    readme,
    '| Current source | `2.0.0-alpha.3-dev.20` / `1016231` | Unreleased vNext source with consolidated LMKD reload and badge reliability fix |',
    '| Current source | `2.0.0-alpha.3-dev.21` / `1016232` | Unreleased test source with LMKD writer fallback evidence and lightweight unchanged boots |',
    "README current source",
)
readme = replace_once(
    readme,
    'Dev.20 also verifies the final P/T/Z/L manager description after boot and retries the write when readback is still static.\n',
    'Dev.20 also verifies the final P/T/Z/L manager description after boot and retries the write when readback is still static.\n\nDev.21 keeps `resetprop-rs` for ZRAM properties but uses Magisk system `resetprop` first for the single LMKD property, with readback-controlled fallback and writer evidence. It also replaces the full compatibility scan on every unchanged boot with a signed-state gate: first/changed/debug/transition boots run full verification, while unchanged verified boots perform only runtime apply, lightweight readbacks and badge refresh.\n',
    "README Dev.21 summary",
)
write("README.md", readme)

subprocess.run(["bash", "-n", str(ROOT / "tools/zram/apply-zram-100p.sh")], check=True)
subprocess.run(["bash", "-n", str(ROOT / "tools/bootguard/bootguard-lib.sh")], check=True)
subprocess.run(["bash", "-n", str(ROOT / "post-fs-data.sh")], check=True)
subprocess.run(["bash", "-n", str(ROOT / "service.sh")], check=True)
subprocess.run(["bash", str(ROOT / "tests/test-dev19-lmkd-early-test.sh")], check=True)
subprocess.run(["bash", str(ROOT / "tests/test-dev21-light-boot.sh")], check=True)
print("RESULT: DEV21_BRANCH_BUILD_PASS")
