#!/system/bin/sh
ID="pixel-10-pro-xl-thermal-fix"
M="/data/adb/modules/$ID"
CFG="/data/adb/$ID/config.env"

getcfg(){ [ -r "$CFG" ] && grep -E "^$1=" "$CFG" 2>/dev/null | tail -n1 | sed "s/^$1=//" | tr -d '\r'; }
flag(){ [ -e "$1" ] && echo present || echo absent; }
sha_file(){ sha256sum "$1" 2>/dev/null | awk '{print $1}'; }

ready=yes
match=yes
checked=0
for p in "$M"/system/vendor/etc/thermal_info_config*.json; do
  [ -f "$p" ] || continue
  checked=$((checked + 1))
  f="${p##*/}"
  [ -s "$p" ] || ready=no
  a="$(sha_file "/vendor/etc/$f")"
  o="$(sha_file "$p")"
  [ -n "$a" ] && [ -n "$o" ] && [ "$a" = "$o" ] || match=no
done
if [ "$checked" -eq 0 ] 2>/dev/null; then
  ready=no
  match=no
fi

pany=""
pact=""
pstate=absent
for d in /data/adb/modules_update/ptune /data/adb/modules/ptune; do
  [ -f "$d/module.prop" ] || continue
  grep -q '^id=ptune$' "$d/module.prop" 2>/dev/null || continue
  [ -e "$d/remove" ] && continue
  [ -z "$pany" ] && pany="$d"
  case "$d" in
    /data/adb/modules_update/ptune) pstate=staged_update; pact="$d" ;;
    *)
      if [ -e "$d/disable" ]; then
        [ "$pstate" = absent ] && pstate=installed_disabled
      else
        pstate=installed_enabled
        [ -z "$pact" ] && pact="$d"
      fi
    ;;
  esac
done
pt_inst=no; [ -n "$pany" ] && pt_inst=yes
pt_en=no; [ -n "$pact" ] && pt_en=yes

known=no
known_version=no
known_runtime=no
if [ -n "$pany" ]; then
  vc="$(grep -E '^versionCode=' "$pany/module.prop" 2>/dev/null | sed 's/^versionCode=//')"
  if [ "$vc" = 200 ]; then
    known=yes_versionCode_200
    known_version=yes_versionCode_200
  fi
  if [ "$(getprop ro.product.device)" = mustang ] && [ "$(getprop ro.build.id)" = CP1A.260505.005 ] && [ "$vc" = 200 ]; then
    known_runtime=yes_thermalhal_bootloop_on_mustang_cp1a_260505_005
  fi
fi

mode="$(getcfg PTUNE_GUARD_MODE)"; [ -n "$mode" ] || mode=strict
case "$mode" in strict|active_only|off) ;; *) mode=strict ;; esac
allow="$(getcfg ALLOW_THERMAL_WITH_PTUNE)"
ack="$(getcfg RISK_ACK_PTUNE_THERMAL_COLLISION)"
ov=no
[ "$allow" = 1 ] && [ "$ack" = I_UNDERSTAND_BOOTLOOP_RISK ] && ov=yes

td="$(flag "$M/disable")"
ts="$(flag "$M/skip_mount")"
tr="$(flag "$M/remove")"

root_impl=unknown
su_v="$(su -v 2>/dev/null || true)"
su_V="$(su -V 2>/dev/null || true)"
case "$su_v $su_V" in
  *KernelSU*Next*|*ksu-next*|*KSU-Next*) root_impl=kernelsu_next ;;
  *KernelSU*|*ksu*) root_impl=kernelsu ;;
  *Magisk*|*magisk*) root_impl=magisk ;;
  *APatch*|*apatch*) root_impl=apatch ;;
esac

meta_backend=no
meta_backend_kind=none
meta_backend_version=unknown
probe_files="$(find /data/adb /debug_ramdisk /sbin -maxdepth 5 \( -iname '*mountify*' -o -iname '*metamodule*' -o -iname '*meta-module*' \) 2>/dev/null | head -20)"
if [ -n "$probe_files" ]; then
  meta_backend=yes
  case "$probe_files" in *mountify*) meta_backend_kind=mountify ;; *) meta_backend_kind=metamodule ;; esac
fi

for p in /data/adb/modules/*/module.prop /data/adb/modules_update/*/module.prop; do
  [ -f "$p" ] || continue
  if grep -Eiq '^(id|name)=.*(mountify|metamodule|meta module|meta-module)' "$p"; then
    meta_backend=yes
    if grep -Eiq 'mountify' "$p"; then meta_backend_kind=mountify; else meta_backend_kind=metamodule_module; fi
    v="$(grep -E '^version=' "$p" 2>/dev/null | head -n1 | sed 's/^version=//')"
    [ -n "$v" ] && meta_backend_version="$v"
  fi
done

if [ "$meta_backend" = no ] && [ "$root_impl" = kernelsu_next ]; then
  meta_backend=unknown_integrated_possible
  meta_backend_kind=kernelsu_next_integrated_probe_missing
fi

auto_state="none"
selected_profile="unknown"
build_guard_mode="unknown"
auto_reason="none"
reinstall_required="no"
profile_stale_after_ota="no"
[ -r "$M/guard/auto_profile_switch_state" ] && auto_state="$(cat "$M/guard/auto_profile_switch_state" 2>/dev/null | head -n1)"
[ -r "$M/guard/selected_profile" ] && selected_profile="$(cat "$M/guard/selected_profile" 2>/dev/null | head -n1)"
[ -r "$M/install-state.txt" ] && build_guard_mode="$(grep -E "^build_guard_mode=" "$M/install-state.txt" 2>/dev/null | tail -n1 | sed "s/^build_guard_mode=//" | tr -d "\r")"
[ -r "$M/guard/auto_profile_switch_reason" ] && auto_reason="$(cat "$M/guard/auto_profile_switch_reason" 2>/dev/null | head -n1)"
[ -r "$M/guard/reinstall_required" ] && reinstall_required="$(cat "$M/guard/reinstall_required" 2>/dev/null | sed 's/^REINSTALL_REQUIRED=//' | head -n1)"
[ -r "$M/guard/profile_stale_after_ota" ] && profile_stale_after_ota="$(cat "$M/guard/profile_stale_after_ota" 2>/dev/null | sed 's/^PROFILE_STALE_AFTER_OTA=//' | head -n1)"

warn=no
if [ "$ready" = yes ] && [ "$ts" = absent ] && [ "$match" = no ]; then
  if [ "$meta_backend" = yes ]; then
    warn=yes_meta_backend_present_vendor_not_matched
  elif [ "$meta_backend" = unknown_integrated_possible ]; then
    warn=yes_kernelsu_next_backend_not_detected_vendor_not_matched
  else
    warn=yes_overlay_ready_but_vendor_not_matched_backend_unknown
  fi
fi

exp=thermal_active_allowed
safe=yes
reason=no_active_ptune_conflict
[ "$tr" = present ] && exp=module_remove_authoritative reason=remove_present
[ "$td" = present ] && exp=module_disable_authoritative reason=disable_present
[ "$ts" = present ] && [ "$td" = absent ] && [ "$tr" = absent ] && exp=module_skip_mount_authoritative reason=skip_mount_present
if [ "$td" = absent ] && [ "$tr" = absent ] && [ "$ts" = absent ]; then
  [ "$pt_en" = yes ] && [ "$ov" != yes ] && exp=thermal_skip_mount_required reason=ptune_active_or_staged safe=no
  [ "$ready" = no ] && safe=no reason=${reason}_overlay_missing
fi

{
  printf '%s\n' "PTUNE_INSTALLED=$pt_inst"
  printf '%s\n' "PTUNE_ENABLED=$pt_en"
  printf '%s\n' "PTUNE_STATE=$pstate"
  printf '%s\n' "PTUNE_PATH=${pany:-none}"
  printf '%s\n' "PTUNE_KNOWN_BAD=$known"
  printf '%s\n' "PTUNE_KNOWN_BAD_VERSION=$known_version"
  printf '%s\n' "PTUNE_KNOWN_BAD_RUNTIME=$known_runtime"
  printf '%s\n' "CONFIG_FILE=$CFG"
  printf '%s\n' "PTUNE_GUARD_MODE=$mode"
  printf '%s\n' "ALLOW_THERMAL_WITH_PTUNE=${allow:-0}"
  printf '%s\n' "RISK_ACK_VALID=$ov"
  printf '%s\n' "THERMAL_DISABLE=$td"
  printf '%s\n' "THERMAL_SKIP_MOUNT=$ts"
  printf '%s\n' "THERMAL_REMOVE=$tr"
  printf '%s\n' "THERMAL_EXPECTED=$exp"
  printf '%s\n' "AUTO_PROFILE_SWITCH_STATE=$auto_state"
  printf '%s\n' "AUTO_SELECTED_PROFILE=$selected_profile"
  printf '%s\n' "AUTO_SWITCH_REASON=$auto_reason"
  printf '%s\n' "BUILD_GUARD_MODE=${build_guard_mode:-unknown}"
  printf '%s\n' "PROFILE_STALE_AFTER_OTA=$profile_stale_after_ota"
  printf '%s\n' "REINSTALL_REQUIRED=$reinstall_required"
  printf '%s\n' "MODULE_OVERLAY_READY=$ready"
  printf '%s\n' "THERMAL_CHECKED_FILES=$checked"
  printf '%s\n' "ACTIVE_VENDOR_MATCH=$match"
  printf '%s\n' "ROOT_IMPL=$root_impl"
  printf '%s\n' "META_BACKEND_PRESENT=$meta_backend"
  printf '%s\n' "META_BACKEND_KIND=$meta_backend_kind"
  printf '%s\n' "META_BACKEND_VERSION=$meta_backend_version"
  printf '%s\n' "METAMODULE_INSTALLED=$meta_backend"
  printf '%s\n' "VENDOR_OVERLAY_BACKEND_WARN=$warn"
  printf '%s\n' "SAFE_TO_REBOOT=$safe"
  printf '%s\n' "REASON=$reason"
}
