#!/system/bin/sh
# Dynamic V2 runtime compatibility, manifest and active-value verifier.

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
ADB_ROOT="${THERMAL_ADB_ROOT:-/data/adb}"
M="${MODDIR:-$ADB_ROOT/modules/$ID}"
DATA_ROOT="${THERMAL_DATA_ROOT:-$ADB_ROOT/$ID}"
CFG="$DATA_ROOT/config.env"
VENDOR_DIR="${THERMAL_VENDOR_DIR:-/vendor/etc}"
OVERLAY_DIR="$M/system/vendor/etc"
GUARD_DIR="$M/guard"
SUPPORTED_JSON="$M/supported_versions.json"
SUPPORTED_HELPER="$M/tools/core/supported-build.sh"

DEVICE="${THERMAL_DEVICE:-$(getprop ro.product.device 2>/dev/null || true)}"
ANDROID="${THERMAL_ANDROID:-$(getprop ro.build.version.release 2>/dev/null || true)}"
BUILD_ID="${THERMAL_BUILD_ID:-$(getprop ro.build.id 2>/dev/null || true)}"
[ -n "$DEVICE" ] || DEVICE=unknown
[ -n "$ANDROID" ] || ANDROID=unknown
[ -n "$BUILD_ID" ] || BUILD_ID=unknown
BUILD_SLUG="$(printf '%s' "$BUILD_ID" | tr -c 'A-Za-z0-9._-' '_')"

CACHE_DIR="$DATA_ROOT/originals/$DEVICE/$BUILD_SLUG/vendor/etc"
SOURCE_MANIFEST="$CACHE_DIR/source-manifest.tsv"
PATCH_MANIFEST="$GUARD_DIR/patch-manifest.tsv"
REPORT_MODULE="$M/validation_report.json"
REPORT_DATA="$DATA_ROOT/validation_report.json"

CONTROLLED_FILES="
thermal_info_config.json
thermal_info_config_charge.json
thermal_info_config_throttling.json
"

getcfg() {
  [ -r "$CFG" ] || return 0
  grep -E "^$1=" "$CFG" 2>/dev/null | tail -n 1 | sed "s/^$1=//" | tr -d '\r'
}

flag() {
  [ -e "$1" ] && printf '%s\n' present || printf '%s\n' absent
}

sha_file() {
  [ -s "$1" ] || return 0
  sha256sum "$1" 2>/dev/null | awk '{print $1}'
}

bytes_file() {
  [ -s "$1" ] || return 0
  wc -c < "$1" 2>/dev/null | tr -d ' '
}

count_polling_value() {
  _file="$1"
  _value="$2"
  [ -r "$_file" ] || {
    printf '%s\n' 0
    return 0
  }
  awk -v value="$_value" '
    {
      line = $0
      pattern = "\"PollingDelay\"[[:space:]]*:[[:space:]]*" value "([^0-9]|$)"
      while (match(line, pattern)) {
        total++
        line = substr(line, RSTART + RLENGTH)
      }
    }
    END { print total + 0 }
  ' "$_file"
}

count_lowercase_polling() {
  [ -r "$1" ] || {
    printf '%s\n' 0
    return 0
  }
  grep -o '"pollingDelay"[[:space:]]*:' "$1" 2>/dev/null | wc -l | tr -d ' '
}

is_controlled() {
  case "$1" in
    thermal_info_config.json|thermal_info_config_charge.json|thermal_info_config_throttling.json) return 0 ;;
    *) return 1 ;;
  esac
}

source_field() {
  _file="$1"
  _column="$2"
  awk -F '	' -v f="$_file" -v c="$_column" '$1 == f { print $c; exit }' "$SOURCE_MANIFEST" 2>/dev/null
}

report_total() {
  _key="$1"
  awk -v key="$_key" '
    index($0, "\"totals\"") { in_totals = 1; next }
    in_totals && index($0, "\"" key "\"") {
      line = $0
      sub(".*\"" key "\"[[:space:]]*:[[:space:]]*", "", line)
      sub("[^0-9].*", "", line)
      print line
      exit
    }
  ' "$REPORT_MODULE" 2>/dev/null
}

thermal_json_tolerant_validate_fallback() {
  _file="$1"
  [ -s "$_file" ] || return 1
  awk '
    BEGIN { braces=0; brackets=0; in_string=0; escaped=0; bad=0; first=""; last="" }
    {
      line=$0
      for (i=1; i<=length(line); i++) {
        c=substr(line,i,1)
        if (c !~ /[[:space:]]/) {
          if (first=="") first=c
          last=c
        }
        if (in_string) {
          if (escaped) escaped=0
          else if (c=="\\") escaped=1
          else if (c=="\"") in_string=0
          continue
        }
        if (c=="\"") { in_string=1; continue }
        if (c=="{") braces++
        else if (c=="}") { braces--; if (braces<0) bad=1 }
        else if (c=="[") brackets++
        else if (c=="]") { brackets--; if (brackets<0) bad=1 }
      }
    }
    END {
      if (bad || in_string || escaped || braces != 0 || brackets != 0) exit 1
      if (first != "{" || last != "}") exit 1
    }
  ' "$_file"
}

if [ -r "$SUPPORTED_HELPER" ]; then
  . "$SUPPORTED_HELPER"
fi
if ! command -v thermal_json_tolerant_validate >/dev/null 2>&1; then
  thermal_json_tolerant_validate() {
    thermal_json_tolerant_validate_fallback "$1"
  }
fi

exact_supported=no
if [ -r "$SUPPORTED_HELPER" ] &&
   [ -r "$SUPPORTED_JSON" ] &&
   command -v thermal_supported_check >/dev/null 2>&1 &&
   thermal_supported_check "$SUPPORTED_JSON" "$DEVICE" "$ANDROID" "$BUILD_ID"; then
  exact_supported=yes
fi

source_manifest_valid=yes
source_cache_valid=yes
source_rows=0
source_polling_total=0
source_seen_base=no
source_seen_charge=no
source_seen_throttling=no
expected_source_header="$(printf 'file\tsha256\tbytes\tpolling_300000')"

if [ ! -s "$SOURCE_MANIFEST" ]; then
  source_manifest_valid=no
  source_cache_valid=no
else
  source_header="$(head -n 1 "$SOURCE_MANIFEST" 2>/dev/null)"
  [ "$source_header" = "$expected_source_header" ] || source_manifest_valid=no

  tab="$(printf '\t')"
  while IFS="$tab" read -r file expected_sha expected_bytes expected_polling extra; do
    [ "$file" = file ] && continue
    [ -n "$file" ] || continue
    source_rows=$((source_rows + 1))

    if ! is_controlled "$file" || [ -n "$extra" ]; then
      source_manifest_valid=no
      source_cache_valid=no
      continue
    fi

    case "$file" in
      thermal_info_config.json)
        [ "$source_seen_base" = no ] || source_manifest_valid=no
        source_seen_base=yes
      ;;
      thermal_info_config_charge.json)
        [ "$source_seen_charge" = no ] || source_manifest_valid=no
        source_seen_charge=yes
      ;;
      thermal_info_config_throttling.json)
        [ "$source_seen_throttling" = no ] || source_manifest_valid=no
        source_seen_throttling=yes
      ;;
    esac

    source_file="$CACHE_DIR/$file"
    if [ ! -s "$source_file" ] ||
       ! thermal_json_tolerant_validate "$source_file"; then
      source_cache_valid=no
      continue
    fi

    case "$expected_sha" in
      ????????????????????????????????????????????????????????????????) ;;
      *) source_manifest_valid=no; source_cache_valid=no ;;
    esac
    case "$expected_bytes:$expected_polling" in
      *[!0-9:]*|:*|*:) source_manifest_valid=no; source_cache_valid=no ;;
    esac

    [ "$(sha_file "$source_file")" = "$expected_sha" ] || source_cache_valid=no
    [ "$(bytes_file "$source_file")" = "$expected_bytes" ] || source_cache_valid=no
    [ "$(count_polling_value "$source_file" 300000)" = "$expected_polling" ] || source_cache_valid=no
    [ "$(count_polling_value "$source_file" 5000)" = 0 ] || source_cache_valid=no
    [ "$(count_polling_value "$source_file" 30000)" = 0 ] || source_cache_valid=no
    [ "$(count_lowercase_polling "$source_file")" = 0 ] || source_cache_valid=no

    case "$expected_polling" in
      ''|*[!0-9]*) ;;
      *) source_polling_total=$((source_polling_total + expected_polling)) ;;
    esac
  done < "$SOURCE_MANIFEST"
fi

[ "$source_rows" -eq 3 ] 2>/dev/null || source_manifest_valid=no
[ "$source_seen_base" = yes ] || source_manifest_valid=no
[ "$source_seen_charge" = yes ] || source_manifest_valid=no
[ "$source_seen_throttling" = yes ] || source_manifest_valid=no
[ "$source_manifest_valid" = yes ] || source_cache_valid=no

overlay_inventory_valid=yes
overlay_inventory_count="$(find "$OVERLAY_DIR" -maxdepth 1 -type f -name 'thermal_info_config*.json' 2>/dev/null | wc -l | tr -d ' ')"
[ "$overlay_inventory_count" = 3 ] || overlay_inventory_valid=no
for path in "$OVERLAY_DIR"/thermal_info_config*.json; do
  [ -e "$path" ] || continue
  is_controlled "${path##*/}" || overlay_inventory_valid=no
done

patch_manifest_valid=yes
patch_rows=0
patch_seen_base=no
patch_seen_charge=no
patch_seen_throttling=no
patch_source_polling_total=0
patch_replacement_total=0
overlay_polling_300000=0
overlay_polling_5000=0
expected_patch_header="$(printf 'file\tsource_sha256\toutput_sha256\tsource_polling_300000\treplacements\toutput_polling_300000\toutput_polling_5000\tallowed_diff')"
polling_mode="$(getcfg THERMAL_POLLING_MODE)"
[ -n "$polling_mode" ] || polling_mode=mod
outdoor_profile="$(getcfg THERMAL_OUTDOOR_PROFILE)"
[ -n "$outdoor_profile" ] || outdoor_profile=stock

if [ ! -s "$PATCH_MANIFEST" ]; then
  patch_manifest_valid=no
else
  patch_header="$(head -n 1 "$PATCH_MANIFEST" 2>/dev/null)"
  [ "$patch_header" = "$expected_patch_header" ] || patch_manifest_valid=no

  tab="$(printf '\t')"
  while IFS="$tab" read -r file source_sha output_sha source_polling replacements output300000 output5000 allowed extra; do
    [ "$file" = file ] && continue
    [ -n "$file" ] || continue
    patch_rows=$((patch_rows + 1))

    if ! is_controlled "$file" || [ -n "$extra" ]; then
      patch_manifest_valid=no
      continue
    fi

    case "$file" in
      thermal_info_config.json)
        [ "$patch_seen_base" = no ] || patch_manifest_valid=no
        patch_seen_base=yes
      ;;
      thermal_info_config_charge.json)
        [ "$patch_seen_charge" = no ] || patch_manifest_valid=no
        patch_seen_charge=yes
      ;;
      thermal_info_config_throttling.json)
        [ "$patch_seen_throttling" = no ] || patch_manifest_valid=no
        patch_seen_throttling=yes
      ;;
    esac

    case "$source_polling:$replacements:$output300000:$output5000" in
      *[!0-9:]*|:*|*:) patch_manifest_valid=no; continue ;;
    esac

    module_file="$OVERLAY_DIR/$file"
    [ -s "$module_file" ] || patch_manifest_valid=no
    if [ -s "$module_file" ]; then
      thermal_json_tolerant_validate "$module_file" || patch_manifest_valid=no
      [ "$(sha_file "$module_file")" = "$output_sha" ] || patch_manifest_valid=no
      [ "$(count_polling_value "$module_file" 300000)" = "$output300000" ] || patch_manifest_valid=no
      [ "$(count_polling_value "$module_file" 5000)" = "$output5000" ] || patch_manifest_valid=no
      [ "$(count_polling_value "$module_file" 30000)" = 0 ] || patch_manifest_valid=no
      [ "$(count_lowercase_polling "$module_file")" = 0 ] || patch_manifest_valid=no
    fi

    [ "$(source_field "$file" 2)" = "$source_sha" ] || patch_manifest_valid=no
    [ "$(source_field "$file" 4)" = "$source_polling" ] || patch_manifest_valid=no
    [ "$allowed" = yes ] || patch_manifest_valid=no

    case "$polling_mode" in
      mod)
        [ "$replacements" = "$source_polling" ] || patch_manifest_valid=no
        [ "$output300000" = 0 ] || patch_manifest_valid=no
        [ "$output5000" = "$source_polling" ] || patch_manifest_valid=no
      ;;
      stock)
        [ "$replacements" = 0 ] || patch_manifest_valid=no
        [ "$output300000" = "$source_polling" ] || patch_manifest_valid=no
        [ "$output5000" = 0 ] || patch_manifest_valid=no
      ;;
      *) patch_manifest_valid=no ;;
    esac

    patch_source_polling_total=$((patch_source_polling_total + source_polling))
    patch_replacement_total=$((patch_replacement_total + replacements))
    overlay_polling_300000=$((overlay_polling_300000 + output300000))
    overlay_polling_5000=$((overlay_polling_5000 + output5000))
  done < "$PATCH_MANIFEST"
fi

[ "$patch_rows" -eq 3 ] 2>/dev/null || patch_manifest_valid=no
[ "$patch_seen_base" = yes ] || patch_manifest_valid=no
[ "$patch_seen_charge" = yes ] || patch_manifest_valid=no
[ "$patch_seen_throttling" = yes ] || patch_manifest_valid=no
[ "$overlay_inventory_valid" = yes ] || patch_manifest_valid=no
[ "$source_manifest_valid" = yes ] || patch_manifest_valid=no
[ "$source_cache_valid" = yes ] || patch_manifest_valid=no
[ "$patch_source_polling_total" = "$source_polling_total" ] || patch_manifest_valid=no

validation_report_valid=yes
if [ ! -s "$REPORT_MODULE" ] ||
   ! thermal_json_tolerant_validate "$REPORT_MODULE"; then
  validation_report_valid=no
else
  grep -q '"schema"[[:space:]]*:[[:space:]]*"pixel-thermal-dynamic-validation-v3"' "$REPORT_MODULE" || validation_report_valid=no
  grep -q "\"device\"[[:space:]]*:[[:space:]]*\"$DEVICE\"" "$REPORT_MODULE" || validation_report_valid=no
  grep -q "\"build_id\"[[:space:]]*:[[:space:]]*\"$BUILD_ID\"" "$REPORT_MODULE" || validation_report_valid=no
  grep -q "\"polling_mode\"[[:space:]]*:[[:space:]]*\"$polling_mode\"" "$REPORT_MODULE" || validation_report_valid=no
  grep -q "\"outdoor_profile\"[[:space:]]*:[[:space:]]*\"$outdoor_profile\"" "$REPORT_MODULE" || validation_report_valid=no
  [ "$(grep -c '"validation"[[:space:]]*:[[:space:]]*"passed"' "$REPORT_MODULE" 2>/dev/null)" -ge 4 ] 2>/dev/null || validation_report_valid=no

  [ "$(report_total source_files)" = 3 ] || validation_report_valid=no
  [ "$(report_total source_polling_300000)" = "$source_polling_total" ] || validation_report_valid=no
  [ "$(report_total replacements)" = "$patch_replacement_total" ] || validation_report_valid=no
  [ "$(report_total output_polling_300000)" = "$overlay_polling_300000" ] || validation_report_valid=no
  [ "$(report_total output_polling_5000)" = "$overlay_polling_5000" ] || validation_report_valid=no
fi

if [ ! -s "$REPORT_DATA" ] ||
   [ "$(sha_file "$REPORT_DATA")" != "$(sha_file "$REPORT_MODULE")" ]; then
  validation_report_valid=no
fi

module_overlay_ready=no
if [ "$overlay_inventory_valid" = yes ] &&
   [ "$patch_rows" -eq 3 ] 2>/dev/null; then
  module_overlay_ready=yes
fi

materialization_valid=no
if [ "$exact_supported" = yes ] &&
   [ "$source_manifest_valid" = yes ] &&
   [ "$source_cache_valid" = yes ] &&
   [ "$patch_manifest_valid" = yes ] &&
   [ "$validation_report_valid" = yes ] &&
   [ "$module_overlay_ready" = yes ]; then
  materialization_valid=yes
fi

active_match=yes
active_checked=0
active_polling_300000=0
active_polling_5000=0
for file in $CONTROLLED_FILES; do
  module_file="$OVERLAY_DIR/$file"
  active_file="$VENDOR_DIR/$file"
  if [ ! -s "$module_file" ] || [ ! -s "$active_file" ]; then
    active_match=no
    continue
  fi
  active_checked=$((active_checked + 1))
  [ "$(sha_file "$module_file")" = "$(sha_file "$active_file")" ] || active_match=no
  active_polling_300000=$((active_polling_300000 + $(count_polling_value "$active_file" 300000)))
  active_polling_5000=$((active_polling_5000 + $(count_polling_value "$active_file" 5000)))
  [ "$(count_polling_value "$active_file" 30000)" = 0 ] || active_match=no
  [ "$(count_lowercase_polling "$active_file")" = 0 ] || active_match=no
done
[ "$active_checked" -eq 3 ] 2>/dev/null || active_match=no

active_polling_valid=pending
if [ "$active_match" = yes ]; then
  active_polling_valid=yes
  case "$polling_mode" in
    mod)
      [ "$active_polling_300000" = 0 ] || active_polling_valid=no
      [ "$active_polling_5000" = "$source_polling_total" ] || active_polling_valid=no
    ;;
    stock)
      [ "$active_polling_300000" = "$source_polling_total" ] || active_polling_valid=no
      [ "$active_polling_5000" = 0 ] || active_polling_valid=no
    ;;
    *) active_polling_valid=no ;;
  esac
fi

pany=""
pact=""
pstate=absent
for d in "$ADB_ROOT/modules_update/ptune" "$ADB_ROOT/modules/ptune"; do
  [ -f "$d/module.prop" ] || continue
  grep -q '^id=ptune$' "$d/module.prop" 2>/dev/null || continue
  [ -e "$d/remove" ] && continue
  [ -z "$pany" ] && pany="$d"
  case "$d" in
    */modules_update/ptune) pstate=staged_update; pact="$d" ;;
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
pt_inst=no
[ -n "$pany" ] && pt_inst=yes
pt_en=no
[ -n "$pact" ] && pt_en=yes

known=no
known_version=no
known_runtime=no
if [ -n "$pany" ]; then
  vc="$(grep -E '^versionCode=' "$pany/module.prop" 2>/dev/null | sed 's/^versionCode=//')"
  if [ "$vc" = 200 ]; then
    known=yes_versionCode_200
    known_version=yes_versionCode_200
  fi
  if [ "$DEVICE" = mustang ] &&
     [ "$BUILD_ID" = CP1A.260505.005 ] &&
     [ "$vc" = 200 ]; then
    known_runtime=yes_thermalhal_bootloop_on_mustang_cp1a_260505_005
  fi
fi

mode="$(getcfg PTUNE_GUARD_MODE)"
[ -n "$mode" ] || mode=strict
case "$mode" in strict|active_only|off) ;; *) mode=strict ;; esac
allow="$(getcfg ALLOW_THERMAL_WITH_PTUNE)"
ack="$(getcfg RISK_ACK_PTUNE_THERMAL_COLLISION)"
override=no
[ "$allow" = 1 ] &&
  [ "$ack" = I_UNDERSTAND_BOOTLOOP_RISK ] &&
  override=yes

td="$(flag "$M/disable")"
ts="$(flag "$M/skip_mount")"
tr="$(flag "$M/remove")"
thermal_cfg_disabled="$(getcfg THERMAL_DISABLED)"
[ -n "$thermal_cfg_disabled" ] || thermal_cfg_disabled=0

root_impl="${THERMAL_ROOT_IMPL:-unknown}"
if [ "$root_impl" = unknown ]; then
  su_v="$(su -v 2>/dev/null || true)"
  su_V="$(su -V 2>/dev/null || true)"
  case "$su_v $su_V" in
    *KernelSU*Next*|*ksu-next*|*KSU-Next*) root_impl=kernelsu_next ;;
    *KernelSU*|*ksu*) root_impl=kernelsu ;;
    *Magisk*|*magisk*) root_impl=magisk ;;
    *APatch*|*apatch*) root_impl=apatch ;;
  esac
fi

meta_backend=no
meta_backend_kind=none
meta_backend_version=unknown
probe_files="$(find "$ADB_ROOT" /debug_ramdisk /sbin -maxdepth 5 \( -iname '*mountify*' -o -iname '*metamodule*' -o -iname '*meta-module*' \) 2>/dev/null | head -20)"
if [ -n "$probe_files" ]; then
  meta_backend=yes
  case "$probe_files" in *mountify*) meta_backend_kind=mountify ;; *) meta_backend_kind=metamodule ;; esac
fi
for p in "$ADB_ROOT"/modules/*/module.prop "$ADB_ROOT"/modules_update/*/module.prop; do
  [ -f "$p" ] || continue
  if grep -Eiq '^(id|name)=.*(mountify|metamodule|meta module|meta-module)' "$p"; then
    meta_backend=yes
    if grep -Eiq 'mountify' "$p"; then
      meta_backend_kind=mountify
    else
      meta_backend_kind=metamodule_module
    fi
    v="$(grep -E '^version=' "$p" 2>/dev/null | head -n 1 | sed 's/^version=//')"
    [ -n "$v" ] && meta_backend_version="$v"
  fi
done
if [ "$meta_backend" = no ] && [ "$root_impl" = kernelsu_next ]; then
  meta_backend=unknown_integrated_possible
  meta_backend_kind=kernelsu_next_integrated_probe_missing
fi

auto_state=none
selected_profile=unknown
build_guard_mode=unknown
auto_reason=none
reinstall_required=no
profile_stale_after_ota=no
[ -r "$GUARD_DIR/auto_profile_switch_state" ] && auto_state="$(head -n 1 "$GUARD_DIR/auto_profile_switch_state" 2>/dev/null)"
[ -r "$GUARD_DIR/selected_profile" ] && selected_profile="$(head -n 1 "$GUARD_DIR/selected_profile" 2>/dev/null)"
[ -r "$M/install-state.txt" ] && build_guard_mode="$(grep -E '^build_guard_mode=' "$M/install-state.txt" 2>/dev/null | tail -n 1 | sed 's/^build_guard_mode=//' | tr -d '\r')"
[ -r "$GUARD_DIR/auto_profile_switch_reason" ] && auto_reason="$(head -n 1 "$GUARD_DIR/auto_profile_switch_reason" 2>/dev/null)"
[ -r "$GUARD_DIR/reinstall_required" ] && reinstall_required="$(sed 's/^REINSTALL_REQUIRED=//' "$GUARD_DIR/reinstall_required" 2>/dev/null | head -n 1)"
[ -r "$GUARD_DIR/profile_stale_after_ota" ] && profile_stale_after_ota="$(sed 's/^PROFILE_STALE_AFTER_OTA=//' "$GUARD_DIR/profile_stale_after_ota" 2>/dev/null | head -n 1)"
[ -n "$build_guard_mode" ] || build_guard_mode=unknown

warn=no
if [ "$module_overlay_ready" = yes ] &&
   [ "$ts" = absent ] &&
   [ "$active_match" = no ]; then
  if [ "$meta_backend" = yes ]; then
    warn=yes_meta_backend_present_vendor_not_matched
  elif [ "$meta_backend" = unknown_integrated_possible ]; then
    warn=yes_kernelsu_next_backend_not_detected_vendor_not_matched
  else
    warn=yes_overlay_ready_but_vendor_not_matched_backend_unknown
  fi
fi

thermal_overlay_count="$overlay_inventory_count"
exp=thermal_active_allowed
safe=yes
reason=dynamic_materialization_valid

if [ "$tr" = present ]; then
  exp=module_remove_authoritative
  reason=remove_present
elif [ "$td" = present ]; then
  exp=module_disable_authoritative
  reason=disable_present
elif [ "$ts" = present ]; then
  exp=module_skip_mount_authoritative
  reason=skip_mount_present
elif [ "$pt_en" = yes ] && [ "$override" != yes ]; then
  exp=thermal_skip_mount_required
  safe=no
  reason=ptune_active_or_staged
elif [ "$exact_supported" != yes ]; then
  exp=thermal_disabled_unsupported_build
  if [ "$thermal_cfg_disabled" = 1 ] && [ "$thermal_overlay_count" = 0 ]; then
    safe=yes
    reason=unsupported_build_thermal_disabled
  else
    safe=no
    reason=unsupported_build_overlay_not_disabled
  fi
elif [ "$thermal_cfg_disabled" = 1 ]; then
  exp=thermal_disabled_by_guard
  if [ "$thermal_overlay_count" = 0 ]; then
    safe=yes
    reason=supported_build_thermal_disabled_overlay_absent
  else
    safe=no
    reason=supported_build_disabled_but_overlay_present
  fi
elif [ "$materialization_valid" != yes ]; then
  safe=no
  reason=dynamic_materialization_invalid
elif [ "$active_match" = yes ] && [ "$active_polling_valid" != yes ]; then
  safe=no
  reason=active_polling_values_invalid
elif [ "$active_match" = yes ]; then
  safe=yes
  reason=active_dynamic_overlay_verified
else
  safe=yes
  reason=dynamic_overlay_valid_reboot_pending
fi

{
  printf '%s\n' "DEVICE=$DEVICE"
  printf '%s\n' "ANDROID=$ANDROID"
  printf '%s\n' "BUILD_ID=$BUILD_ID"
  printf '%s\n' "BUILD_SLUG=$BUILD_SLUG"
  printf '%s\n' "EXACT_BUILD_SUPPORTED=$exact_supported"
  printf '%s\n' "DYNAMIC_CONTROLLED_FILES=3"
  printf '%s\n' "DYNAMIC_SOURCE_CACHE=$CACHE_DIR"
  printf '%s\n' "DYNAMIC_SOURCE_MANIFEST=$SOURCE_MANIFEST"
  printf '%s\n' "DYNAMIC_SOURCE_MANIFEST_VALID=$source_manifest_valid"
  printf '%s\n' "DYNAMIC_SOURCE_CACHE_VALID=$source_cache_valid"
  printf '%s\n' "DYNAMIC_SOURCE_ROWS=$source_rows"
  printf '%s\n' "DYNAMIC_SOURCE_POLLING_300000=$source_polling_total"
  printf '%s\n' "DYNAMIC_PATCH_MANIFEST=$PATCH_MANIFEST"
  printf '%s\n' "DYNAMIC_PATCH_MANIFEST_VALID=$patch_manifest_valid"
  printf '%s\n' "DYNAMIC_PATCH_ROWS=$patch_rows"
  printf '%s\n' "DYNAMIC_REPLACEMENTS=$patch_replacement_total"
  printf '%s\n' "DYNAMIC_OVERLAY_POLLING_300000=$overlay_polling_300000"
  printf '%s\n' "DYNAMIC_OVERLAY_POLLING_5000=$overlay_polling_5000"
  printf '%s\n' "DYNAMIC_VALIDATION_REPORT=$REPORT_MODULE"
  printf '%s\n' "DYNAMIC_VALIDATION_REPORT_VALID=$validation_report_valid"
  printf '%s\n' "DYNAMIC_MATERIALIZATION_VALID=$materialization_valid"
  printf '%s\n' "POLLING_MODE=$polling_mode"
  printf '%s\n' "OUTDOOR_PROFILE=$outdoor_profile"
  printf '%s\n' "ACTIVE_POLLING_VALID=$active_polling_valid"
  printf '%s\n' "ACTIVE_POLLING_300000=$active_polling_300000"
  printf '%s\n' "ACTIVE_POLLING_5000=$active_polling_5000"
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
  printf '%s\n' "RISK_ACK_VALID=$override"
  printf '%s\n' "THERMAL_CONFIG_DISABLED=$thermal_cfg_disabled"
  printf '%s\n' "THERMAL_DISABLE=$td"
  printf '%s\n' "THERMAL_SKIP_MOUNT=$ts"
  printf '%s\n' "THERMAL_REMOVE=$tr"
  printf '%s\n' "THERMAL_EXPECTED=$exp"
  printf '%s\n' "AUTO_PROFILE_SWITCH_STATE=$auto_state"
  printf '%s\n' "AUTO_SELECTED_PROFILE=$selected_profile"
  printf '%s\n' "AUTO_SWITCH_REASON=$auto_reason"
  printf '%s\n' "BUILD_GUARD_MODE=$build_guard_mode"
  printf '%s\n' "PROFILE_STALE_AFTER_OTA=$profile_stale_after_ota"
  printf '%s\n' "REINSTALL_REQUIRED=$reinstall_required"
  printf '%s\n' "MODULE_OVERLAY_READY=$module_overlay_ready"
  printf '%s\n' "THERMAL_CHECKED_FILES=$patch_rows"
  printf '%s\n' "ACTIVE_VENDOR_MATCH=$active_match"
  printf '%s\n' "ACTIVE_VENDOR_CHECKED_FILES=$active_checked"
  printf '%s\n' "ROOT_IMPL=$root_impl"
  printf '%s\n' "META_BACKEND_PRESENT=$meta_backend"
  printf '%s\n' "META_BACKEND_KIND=$meta_backend_kind"
  printf '%s\n' "META_BACKEND_VERSION=$meta_backend_version"
  printf '%s\n' "METAMODULE_INSTALLED=$meta_backend"
  printf '%s\n' "VENDOR_OVERLAY_BACKEND_WARN=$warn"
  printf '%s\n' "SAFE_TO_REBOOT=$safe"
  printf '%s\n' "REASON=$reason"
}
