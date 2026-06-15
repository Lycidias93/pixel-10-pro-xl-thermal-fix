#!/system/bin/sh
ID="pixel-10-pro-xl-thermal-fix"; M="/data/adb/modules/$ID"; CFG="/data/adb/$ID/config.env"
getcfg(){ [ -r "$CFG" ] && grep -E "^$1=" "$CFG" 2>/dev/null | tail -n1 | sed "s/^$1=//" | tr -d '\r'; }
flag(){ [ -e "$1" ] && echo present || echo absent; }
hash(){ sha256sum "$1" 2>/dev/null | cut -d" " -f1; }
ready=yes; match=yes; for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do [ -s "$M/system/vendor/etc/$f" ] || ready=no; a="$(hash /vendor/etc/$f)"; o="$(hash $M/system/vendor/etc/$f)"; [ -n "$a" ] && [ "$a" = "$o" ] || match=no; done
pany=""; pact=""; pstate=absent; for d in /data/adb/modules_update/ptune /data/adb/modules/ptune; do [ -f "$d/module.prop" ] || continue; grep -q '^id=ptune$' "$d/module.prop" 2>/dev/null || continue; [ -e "$d/remove" ] && continue; [ -z "$pany" ] && pany="$d"; case "$d" in /data/adb/modules_update/ptune) pstate=staged_update; pact="$d";; *) if [ -e "$d/disable" ]; then [ "$pstate" = absent ] && pstate=installed_disabled; else pstate=installed_enabled; [ -z "$pact" ] && pact="$d"; fi;; esac; done
pt_inst=no; [ -n "$pany" ] && pt_inst=yes; pt_en=no; [ -n "$pact" ] && pt_en=yes
known=no; if [ -n "$pany" ]; then vc="$(grep -E '^versionCode=' "$pany/module.prop" 2>/dev/null | sed 's/^versionCode=//')"; [ "$(getprop ro.product.device)" = mustang ] && [ "$(getprop ro.build.id)" = CP1A.260505.005 ] && [ "$vc" = 200 ] && known=yes_versionCode_200_thermalhal_bootloop_on_mustang_cp1a_260505_005; fi
mode="$(getcfg PTUNE_GUARD_MODE)"; [ -n "$mode" ] || mode=strict; allow="$(getcfg ALLOW_THERMAL_WITH_PTUNE)"; ack="$(getcfg RISK_ACK_PTUNE_THERMAL_COLLISION)"; ov=no; [ "$allow" = 1 ] && [ "$ack" = I_UNDERSTAND_BOOTLOOP_RISK ] && ov=yes
td="$(flag $M/disable)"; ts="$(flag $M/skip_mount)"; tr="$(flag $M/remove)"
meta=no; for p in /data/adb/modules/*/module.prop; do [ -f "$p" ] || continue; grep -Eiq '^(id|name)=.*(metamodule|meta module|meta-module)' "$p" && meta=yes; done
warn=no; [ "$ready" = yes ] && [ "$ts" = absent ] && [ "$match" = no ] && warn=yes_overlay_ready_but_vendor_not_matched
exp=thermal_active_allowed; safe=yes; reason=no_active_ptune_conflict; [ "$tr" = present ] && exp=module_remove_authoritative reason=remove_present; [ "$td" = present ] && exp=module_disable_authoritative reason=disable_present; [ "$ts" = present ] && [ "$td" = absent ] && [ "$tr" = absent ] && exp=module_skip_mount_authoritative reason=skip_mount_present; if [ "$td" = absent ] && [ "$tr" = absent ] && [ "$ts" = absent ]; then [ "$pt_en" = yes ] && [ "$ov" != yes ] && exp=thermal_skip_mount_required reason=ptune_active_or_staged safe=no; [ "$ready" = no ] && safe=no reason=${reason}_overlay_missing; fi
cat <<EOF
PTUNE_INSTALLED=$pt_inst
PTUNE_ENABLED=$pt_en
PTUNE_STATE=$pstate
PTUNE_PATH=${pany:-none}
PTUNE_KNOWN_BAD=$known
CONFIG_FILE=$CFG
PTUNE_GUARD_MODE=$mode
ALLOW_THERMAL_WITH_PTUNE=${allow:-0}
RISK_ACK_VALID=$ov
THERMAL_DISABLE=$td
THERMAL_SKIP_MOUNT=$ts
THERMAL_REMOVE=$tr
THERMAL_EXPECTED=$exp
MODULE_OVERLAY_READY=$ready
ACTIVE_VENDOR_MATCH=$match
METAMODULE_INSTALLED=$meta
VENDOR_OVERLAY_BACKEND_WARN=$warn
SAFE_TO_REBOOT=$safe
REASON=$reason
EOF
