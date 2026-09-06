#!/system/bin/sh
# Layout-aware vNext Thermal materializer for Pixel 9/10/11 families.
set -eu

POLLING_MODE="${1:-mod}"
OUTDOOR_PROFILE="${2:-stock}"
MODPATH="${3:-/data/adb/modules/pixel-10-pro-xl-thermal-fix}"
PIXEL11_HYSTERESIS_MODE="${4:-stock}"
PIXEL11_PASSIVE_MODE="${5:-stock}"
ID="pixel-10-pro-xl-thermal-fix"
DATA_ROOT="${THERMAL_DATA_ROOT:-/data/adb/$ID}"
TARGET_DIR="$MODPATH/system/vendor/etc"
TARGET_PARENT="$MODPATH/system/vendor"
GUARD_DIR="$MODPATH/guard"
SUPPORTED_HELPER="$MODPATH/tools/core/supported-build.sh"
LAYOUT_HELPER="$MODPATH/tools/core/thermal-layout.sh"
G6_CONTROLS_HELPER="$MODPATH/tools/core/patch-g6-performance-controls.sh"
LAYOUT_ENV="$GUARD_DIR/thermal-layout.env"

[ -r "$SUPPORTED_HELPER" ] || { printf '%s\n' PATCH_THERMAL=fail PATCH_THERMAL_REASON=supported_helper_missing; exit 20; }
[ -r "$LAYOUT_HELPER" ] || { printf '%s\n' PATCH_THERMAL=fail PATCH_THERMAL_REASON=layout_helper_missing; exit 20; }
. "$SUPPORTED_HELPER"
. "$LAYOUT_HELPER"

case "$POLLING_MODE" in stock|mod) ;; *) printf '%s\n' PATCH_THERMAL=fail PATCH_THERMAL_REASON=invalid_polling_mode; exit 21 ;; esac
case "$OUTDOOR_PROFILE" in stock|outdoor-safe|outdoor-plus|outdoor-extended) ;; *) printf '%s\n' PATCH_THERMAL=fail PATCH_THERMAL_REASON=invalid_outdoor_profile; exit 22 ;; esac
case "$PIXEL11_HYSTERESIS_MODE" in stock|mod) ;; *) printf '%s\n' PATCH_THERMAL=fail PATCH_THERMAL_REASON=invalid_pixel11_hysteresis_mode; exit 23 ;; esac
case "$PIXEL11_PASSIVE_MODE" in stock|mod) ;; *) printf '%s\n' PATCH_THERMAL=fail PATCH_THERMAL_REASON=invalid_pixel11_passive_mode; exit 23 ;; esac

DEVICE="${THERMAL_DEVICE:-$(getprop ro.product.device 2>/dev/null || true)}"
BUILD_ID="${THERMAL_BUILD_ID:-$(getprop ro.build.id 2>/dev/null || true)}"
[ -n "$DEVICE" ] || DEVICE=unknown
[ -n "$BUILD_ID" ] || BUILD_ID=unknown
DEVICE_FAMILY="$(thermal_device_family "$DEVICE")"
if [ "$DEVICE_FAMILY" != pixel11 ] && { [ "$PIXEL11_HYSTERESIS_MODE" != stock ] || [ "$PIXEL11_PASSIVE_MODE" != stock ]; }; then
  printf '%s\n' PATCH_THERMAL=fail PATCH_THERMAL_REASON=pixel11_controls_requested_on_non_pixel11
  exit 23
fi
if [ "$DEVICE_FAMILY" = pixel11 ] && { [ "$PIXEL11_HYSTERESIS_MODE" != stock ] || [ "$PIXEL11_PASSIVE_MODE" != stock ]; }; then
  [ -r "$G6_CONTROLS_HELPER" ] || { printf '%s\n' PATCH_THERMAL=fail PATCH_THERMAL_REASON=g6_controls_helper_missing; exit 23; }
fi
thermal_layout_polling_mode_admitted "$DEVICE" "$POLLING_MODE" || {
  printf '%s\n' PATCH_THERMAL=fail
  printf '%s\n' PATCH_THERMAL_REASON=polling_mode_not_admitted_for_platform
  printf '%s\n' "PATCH_THERMAL_POLLING_REQUESTED=$POLLING_MODE"
  printf '%s\n' 'PATCH_THERMAL_POLLING_MAX=stock'
  exit 24
}
OUTDOOR_POLICY="$(thermal_layout_outdoor_policy "$DEVICE")"
BUILD_SLUG="$(printf '%s' "$BUILD_ID" | tr -c 'A-Za-z0-9._-' '_')"
CACHE_DIR="$DATA_ROOT/originals/$DEVICE/$BUILD_SLUG/vendor/etc"
CACHE_PARENT="$DATA_ROOT/originals/$DEVICE/$BUILD_SLUG/vendor"
CACHE_STAGE="$CACHE_PARENT/.etc.stage.$$"
CACHE_OLD="$CACHE_PARENT/.etc.old.$$"
PATCH_STAGE="$TARGET_PARENT/.etc.stage.$$"
TARGET_OLD="$TARGET_PARENT/.etc.old.$$"
MANIFEST="$CACHE_DIR/source-manifest.tsv"
PATCH_MANIFEST_TMP="$GUARD_DIR/.patch-manifest.tsv.$$"
PATCH_MANIFEST="$GUARD_DIR/patch-manifest.tsv"
REPORT_TMP="$GUARD_DIR/.validation-report.json.$$"
REPORT_MODULE="$MODPATH/validation_report.json"
REPORT_DATA="$DATA_ROOT/validation_report.json"
PROMOTED=0
CACHE_PROMOTED=0

cleanup() {
  _rc="$?"
  rm -rf "$CACHE_STAGE" "$PATCH_STAGE" 2>/dev/null || true
  rm -f "$PATCH_MANIFEST_TMP" "$REPORT_TMP" "$GUARD_DIR/.norm-source.$$" "$GUARD_DIR/.norm-output.$$" 2>/dev/null || true
  if [ "$PROMOTED" -eq 0 ] && [ -d "$TARGET_OLD" ] && [ ! -d "$TARGET_DIR" ]; then mv "$TARGET_OLD" "$TARGET_DIR" 2>/dev/null || true; fi
  if [ "$CACHE_PROMOTED" -eq 0 ] && [ -d "$CACHE_OLD" ] && [ ! -d "$CACHE_DIR" ]; then mv "$CACHE_OLD" "$CACHE_DIR" 2>/dev/null || true; fi
  rm -rf "$TARGET_OLD" "$CACHE_OLD" 2>/dev/null || true
  return "$_rc"
}
trap cleanup EXIT HUP INT TERM

fail() { _rc="$1"; shift; printf '%s\n' PATCH_THERMAL=fail "PATCH_THERMAL_REASON=$*"; exit "$_rc"; }
sha_file() { sha256sum "$1" 2>/dev/null | awk '{print $1}'; }
bytes_file() { wc -c < "$1" 2>/dev/null | tr -d ' '; }
count_polling_value() {
  _f="$1"; _v="$2"
  awk -v value="$_v" '{ line=$0; p="\"PollingDelay\"[[:space:]]*:[[:space:]]*" value "([^0-9]|$)"; while (match(line,p)) { n++; line=substr(line,RSTART+RLENGTH) } } END { print n+0 }' "$_f"
}
count_lowercase_polling() { grep -o '"pollingDelay"[[:space:]]*:' "$1" 2>/dev/null | wc -l | tr -d ' '; }

normalize_allowed() {
  _src="$1"; _dst="$2"; _file="${3:-unknown}"
  _g6_controls=no
  if [ "$DEVICE_FAMILY" = pixel11 ] && [ "$_file" = thermal_info_config_common.json ] &&
     { [ "$PIXEL11_HYSTERESIS_MODE" = mod ] || [ "$PIXEL11_PASSIVE_MODE" = mod ]; }; then
    _g6_controls=yes
  fi
  awk -v policy="$OUTDOOR_POLICY" -v g6_controls="$_g6_controls" '
    function sensor_name(line, name) {
      if (line !~ /"Name"[[:space:]]*:/) return ""
      if (!match(line, /"Name"[[:space:]]*:[[:space:]]*"[^"]+"/)) return ""
      name=substr(line,RSTART,RLENGTH); sub(/^.*:[[:space:]]*"/,"",name); sub(/"$/,"",name); return name
    }
    function target_allowed(name) {
      if (policy == "g6_exact_virtual_skin") return name == "VIRTUAL-SKIN"
      return (index(name,"VIRTUAL-SKIN") == 1 && name !~ /OVER-35C/) || name == "cellular-emergency"
    }
    function g6_target(name) {
      return name=="VIRTUAL-SKIN" || name=="VIRTUAL-SKIN-HINT" ||
        name=="VIRTUAL-SKIN-CPU-LIGHT-ODPM" || name=="VIRTUAL-SKIN-CPU-MID" ||
        name=="VIRTUAL-SKIN-CPU-ODPM" || name=="VIRTUAL-SKIN-CPU-HIGH" ||
        name=="VIRTUAL-SKIN-SOC"
    }
    function g6_mrs_target(name) {
      return name=="VIRTUAL-SKIN-CPU-LIGHT-ODPM" || name=="VIRTUAL-SKIN-CPU-MID" ||
        name=="VIRTUAL-SKIN-CPU-ODPM" || name=="VIRTUAL-SKIN-CPU-HIGH" ||
        name=="VIRTUAL-SKIN-SOC"
    }
    function normalize_poll(line, token) {
      while (match(line, /"PollingDelay"[[:space:]]*:[[:space:]]*(300000|5000)/)) {
        token=substr(line,RSTART,RLENGTH); sub(/[0-9][0-9]*$/, "__POLLING_VALUE__", token); line=substr(line,1,RSTART-1) token substr(line,RSTART+RLENGTH)
      }
      return line
    }
    function mask_numbers(text, marker, out) {
      out=""
      while (match(text, /[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)/)) { out=out substr(text,1,RSTART-1) marker; text=substr(text,RSTART+RLENGTH) }
      return out text
    }
    function normalize_scalar(line, key, marker, out, token) {
      scalar_pattern="\"" key "\"[[:space:]]*:[[:space:]]*[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+)"
      out=""
      while (match(line,scalar_pattern)) {
        token=substr(line,RSTART,RLENGTH)
        sub(/[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+)$/,marker,token)
        out=out substr(line,1,RSTART-1) token
        line=substr(line,RSTART+RLENGTH)
      }
      return out line
    }
    BEGIN { target=0; in_hot=0; current=""; in_g6_hys=0 }
    {
      line=$0
      if (!in_hot && line ~ /"Name"[[:space:]]*:/) {
        current=sensor_name(line)
        target=target_allowed(current)
      }
      line=normalize_poll(line)

      if (g6_controls=="yes" && in_g6_hys) {
        closing=index(line,"]")
        if (closing>0) { line=mask_numbers(substr(line,1,closing-1),"__G6_HYS_VALUE__") substr(line,closing); in_g6_hys=0 }
        else line=mask_numbers(line,"__G6_HYS_VALUE__")
      } else if (g6_controls=="yes" && g6_target(current) && line ~ /"HotHysteresis"[[:space:]]*:/) {
        field_pos=index(line,"\"HotHysteresis\"")
        field_tail=substr(line,field_pos)
        rel_open=index(field_tail,"[")
        open=rel_open>0 ? field_pos+rel_open-1 : 0
        if (open>0) {
          rest=substr(line,open+1); closing=index(rest,"]")
          if (closing>0) line=substr(line,1,open) mask_numbers(substr(rest,1,closing-1),"__G6_HYS_VALUE__") substr(rest,closing)
          else { line=substr(line,1,open) mask_numbers(rest,"__G6_HYS_VALUE__"); in_g6_hys=1 }
        }
      }
      if (g6_controls=="yes" && g6_mrs_target(current)) line=normalize_scalar(line,"MaxReleaseStep","__G6_MRS_VALUE__")
      if (g6_controls=="yes" && g6_target(current)) line=normalize_scalar(line,"PassiveDelay","__G6_PASSIVE_VALUE__")

      if (in_hot) {
        closing=index(line,"]")
        if (closing>0) { line=mask_numbers(substr(line,1,closing-1),"__HOT_VALUE__") substr(line,closing); in_hot=0; target=0 }
        else line=mask_numbers(line,"__HOT_VALUE__")
      } else if (target && line ~ /"HotThreshold"[[:space:]]*:/) {
        open=index(line,"[")
        if (open>0) {
          rest=substr(line,open+1); closing=index(rest,"]")
          if (closing>0) { line=substr(line,1,open) mask_numbers(substr(rest,1,closing-1),"__HOT_VALUE__") substr(rest,closing); target=0 }
          else { line=substr(line,1,open) mask_numbers(rest,"__HOT_VALUE__"); in_hot=1 }
        }
      }
      print line
    }
  ' "$_src" > "$_dst"
}

patch_one() {
  _src="$1"; _dst="$2"; _file="$3"
  _base="${_dst}.base.$$"
  awk -v delta="$DELTA" -v poll_mode="$POLLING_MODE" -v policy="$OUTDOOR_POLICY" '
    function sensor_name(line, name) {
      if (line !~ /"Name"[[:space:]]*:/) return ""
      if (!match(line, /"Name"[[:space:]]*:[[:space:]]*"[^"]+"/)) return ""
      name=substr(line,RSTART,RLENGTH); sub(/^.*:[[:space:]]*"/,"",name); sub(/"$/,"",name); return name
    }
    function target_allowed(name) {
      if (policy == "g6_exact_virtual_skin") return name == "VIRTUAL-SKIN"
      return (index(name,"VIRTUAL-SKIN") == 1 && name !~ /OVER-35C/) || name == "cellular-emergency"
    }
    function adjust_numbers(text, out, tok, dot, dec, fmt, v) {
      if (delta==0) return text
      out=""
      while (match(text, /[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)/)) {
        tok=substr(text,RSTART,RLENGTH); v=tok+delta
        if (tok ~ /[.]/) { dot=index(tok,"."); dec=length(tok)-dot; fmt="%." dec "f"; tok=sprintf(fmt,v) }
        else if (v==int(v)) tok=sprintf("%d",v); else tok=sprintf("%.1f",v)
        out=out substr(text,1,RSTART-1) tok; text=substr(text,RSTART+RLENGTH)
      }
      return out text
    }
    function patch_poll(line, token) {
      if (poll_mode != "mod") return line
      while (match(line, /"PollingDelay"[[:space:]]*:[[:space:]]*300000/)) { token=substr(line,RSTART,RLENGTH); sub(/300000$/, "5000", token); line=substr(line,1,RSTART-1) token substr(line,RSTART+RLENGTH) }
      return line
    }
    BEGIN { target=0; in_hot=0 }
    {
      line=$0
      if (!in_hot && line ~ /"Name"[[:space:]]*:/) target=target_allowed(sensor_name(line))
      line=patch_poll(line)
      if (in_hot) {
        closing=index(line,"]")
        if (closing>0) { line=adjust_numbers(substr(line,1,closing-1)) substr(line,closing); in_hot=0; target=0 }
        else line=adjust_numbers(line)
      } else if (target && line ~ /"HotThreshold"[[:space:]]*:/) {
        open=index(line,"[")
        if (open>0) {
          rest=substr(line,open+1); closing=index(rest,"]")
          if (closing>0) { line=substr(line,1,open) adjust_numbers(substr(rest,1,closing-1)) substr(rest,closing); target=0 }
          else { line=substr(line,1,open) adjust_numbers(rest); in_hot=1 }
        }
      }
      print line
    }
  ' "$_src" > "$_base" || return 1

  if [ "$DEVICE_FAMILY" = pixel11 ] && [ "$_file" = thermal_info_config_common.json ] &&
     { [ "$PIXEL11_HYSTERESIS_MODE" = mod ] || [ "$PIXEL11_PASSIVE_MODE" = mod ]; }; then
    _metrics="$GUARD_DIR/.g6-controls-metrics.$$"
    rm -f "$_metrics"
    if ! sh "$G6_CONTROLS_HELPER" "$_base" "$_dst" "$PIXEL11_HYSTERESIS_MODE" "$PIXEL11_PASSIVE_MODE" "$_metrics"; then
      rm -f "$_base" "$_metrics"
      return 1
    fi
    pixel11_hys_arrays="$(sed -n 's/^PIXEL11_HYSTERESIS_ARRAYS=//p' "$_metrics" | tail -n 1)"
    pixel11_mrs_targets="$(sed -n 's/^PIXEL11_MRS_TARGETS=//p' "$_metrics" | tail -n 1)"
    pixel11_passive_targets="$(sed -n 's/^PIXEL11_PASSIVE_TARGETS=//p' "$_metrics" | tail -n 1)"
    pixel11_hys_changes="$(sed -n 's/^PIXEL11_HYSTERESIS_CHANGES=//p' "$_metrics" | tail -n 1)"
    pixel11_mrs_changes="$(sed -n 's/^PIXEL11_MRS_CHANGES=//p' "$_metrics" | tail -n 1)"
    pixel11_passive_changes="$(sed -n 's/^PIXEL11_PASSIVE_CHANGES=//p' "$_metrics" | tail -n 1)"
    rm -f "$_base" "$_metrics"
  else
    mv "$_base" "$_dst"
  fi
}

DELTA=0
case "$OUTDOOR_PROFILE" in outdoor-safe) DELTA=1 ;; outdoor-plus) DELTA=2 ;; outdoor-extended) DELTA=3 ;; esac
mkdir -p "$DATA_ROOT" "$CACHE_PARENT" "$TARGET_PARENT" "$GUARD_DIR"

cache_valid=1
[ -s "$MANIFEST" ] || cache_valid=0
if [ "$cache_valid" -eq 1 ]; then
  thermal_layout_detect "$CACHE_DIR" "$DEVICE" || cache_valid=0
fi
if [ "$cache_valid" -eq 1 ]; then thermal_layout_manifest_matches "$MANIFEST" || cache_valid=0; fi
if [ "$cache_valid" -eq 1 ]; then
  _rows=0; _tab="$(printf '\t')"
  while IFS="$_tab" read -r file expected_sha expected_bytes poll300000 extra; do
    [ "$file" = file ] && continue
    [ -n "$file" ] || continue
    [ -z "$extra" ] || cache_valid=0
    cf="$CACHE_DIR/$file"; [ -s "$cf" ] || { cache_valid=0; continue; }
    [ "$(sha_file "$cf")" = "$expected_sha" ] || cache_valid=0
    [ "$(bytes_file "$cf")" = "$expected_bytes" ] || cache_valid=0
    [ "$(count_polling_value "$cf" 300000)" = "$poll300000" ] || cache_valid=0
    [ "$(count_polling_value "$cf" 5000)" = 0 ] || cache_valid=0
    [ "$(count_polling_value "$cf" 30000)" = 0 ] || cache_valid=0
    [ "$(count_lowercase_polling "$cf")" = 0 ] || cache_valid=0
    thermal_json_tolerant_validate "$cf" || cache_valid=0
    _rows=$((_rows + 1))
  done < "$MANIFEST"
  [ "$_rows" -eq "$THERMAL_LAYOUT_COUNT" ] 2>/dev/null || cache_valid=0
fi

if [ "$cache_valid" -ne 1 ]; then
  rm -rf "$CACHE_STAGE" "$CACHE_OLD"; mkdir -p "$CACHE_STAGE"
  SOURCE_DIR="${THERMAL_SOURCE_DIR:-}"
  if [ -n "$SOURCE_DIR" ]; then
    thermal_layout_detect "$SOURCE_DIR" "$DEVICE" || fail 30 source_layout_unsupported_or_ambiguous
  else
    for candidate in /data/adb/magisk/mirror/vendor/etc /data/adb/magisk/mirror/system/vendor/etc /sbin/.magisk/mirror/vendor/etc /sbin/.magisk/mirror/system/vendor/etc /vendor/etc /system/vendor/etc; do
      if thermal_layout_detect "$candidate" "$DEVICE"; then SOURCE_DIR="$candidate"; break; fi
    done
  fi
  [ -n "$SOURCE_DIR" ] || fail 30 stock_source_missing_or_layout_unsupported
  printf 'file\tsha256\tbytes\tpolling_300000\n' > "$CACHE_STAGE/source-manifest.tsv"
  source_files=0; source_polling_total=0
  for file in $THERMAL_LAYOUT_FILES; do
    sf="$SOURCE_DIR/$file"; [ -s "$sf" ] || fail 31 "required_stock_file_missing_$file"
    if [ "$SOURCE_DIR" = /vendor/etc ] || [ "$SOURCE_DIR" = /system/vendor/etc ]; then
      mf="$TARGET_DIR/$file"
      if [ -s "$mf" ] && [ "$(sha_file "$sf")" = "$(sha_file "$mf")" ]; then fail 32 "active_overlay_detected_without_valid_cache_$file"; fi
    fi
    thermal_json_tolerant_validate "$sf" || fail 33 "source_structure_invalid_$file"
    p300="$(count_polling_value "$sf" 300000)"; p5="$(count_polling_value "$sf" 5000)"; p30="$(count_polling_value "$sf" 30000)"; low="$(count_lowercase_polling "$sf")"
    [ "$p5" = 0 ] || fail 34 "patched_source_5000_rejected_$file"
    [ "$p30" = 0 ] || fail 35 "source_30000_rejected_$file"
    [ "$low" = 0 ] || fail 36 "source_lowercase_polling_rejected_$file"
    cp -fp "$sf" "$CACHE_STAGE/$file"
    printf '%s\t%s\t%s\t%s\n' "$file" "$(sha_file "$CACHE_STAGE/$file")" "$(bytes_file "$CACHE_STAGE/$file")" "$p300" >> "$CACHE_STAGE/source-manifest.tsv"
    source_files=$((source_files + 1)); source_polling_total=$((source_polling_total + p300))
  done
  [ "$source_files" -eq "$THERMAL_LAYOUT_COUNT" ] 2>/dev/null || fail 37 "source_inventory_invalid_${source_files}_expected_${THERMAL_LAYOUT_COUNT}"
  if [ "$POLLING_MODE" = mod ]; then [ "$source_polling_total" -gt 0 ] || fail 38 no_source_polling_300000; fi
  if [ -d "$CACHE_DIR" ]; then mv "$CACHE_DIR" "$CACHE_OLD"; fi
  mv "$CACHE_STAGE" "$CACHE_DIR" || fail 39 cache_promotion_failed
  CACHE_PROMOTED=1; rm -rf "$CACHE_OLD"
  MANIFEST="$CACHE_DIR/source-manifest.tsv"
else
  source_polling_total=0
fi

thermal_layout_detect "$CACHE_DIR" "$DEVICE" || fail 29 cached_layout_invalid
thermal_layout_manifest_matches "$MANIFEST" || fail 29 cached_manifest_layout_mismatch

rm -rf "$PATCH_STAGE" "$TARGET_OLD"; mkdir -p "$PATCH_STAGE"
if [ -d "$TARGET_DIR" ]; then
  for existing in "$TARGET_DIR"/*; do
    [ -e "$existing" ] || continue
    name="${existing##*/}"
    case "$name" in thermal_info_config*.json) continue ;; esac
    cp -fpR "$existing" "$PATCH_STAGE/"
  done
fi

printf 'file\tsource_sha256\toutput_sha256\tsource_polling_300000\treplacements\toutput_polling_300000\toutput_polling_5000\tallowed_diff\n' > "$PATCH_MANIFEST_TMP"
printf '%s\n' '{' > "$REPORT_TMP"
printf '%s\n' '  "schema": "pixel-thermal-dynamic-validation-v5",' >> "$REPORT_TMP"
printf '  "device": "%s",\n' "$DEVICE" >> "$REPORT_TMP"
printf '  "build_id": "%s",\n' "$BUILD_ID" >> "$REPORT_TMP"
printf '  "layout_family": "%s",\n' "$THERMAL_LAYOUT_FAMILY" >> "$REPORT_TMP"
printf '  "layout_count": %s,\n' "$THERMAL_LAYOUT_COUNT" >> "$REPORT_TMP"
printf '  "polling_mode": "%s",\n' "$POLLING_MODE" >> "$REPORT_TMP"
printf '  "polling_policy": "%s",\n' "$(thermal_layout_is_g6_device "$DEVICE" && printf '%s' classic_polling_stock_family_controls || printf '%s' stock_or_mod)" >> "$REPORT_TMP"
printf '  "pixel11_hysteresis_mode": "%s",\n' "$PIXEL11_HYSTERESIS_MODE" >> "$REPORT_TMP"
printf '  "pixel11_passive_mode": "%s",\n' "$PIXEL11_PASSIVE_MODE" >> "$REPORT_TMP"
printf '  "outdoor_policy": "%s",\n' "$OUTDOOR_POLICY" >> "$REPORT_TMP"
printf '  "outdoor_profile": "%s",\n' "$OUTDOOR_PROFILE" >> "$REPORT_TMP"
printf '%s\n' '  "files": {' >> "$REPORT_TMP"

_tab="$(printf '\t')"; first_json=1; source_files=0; source_polling_total=0; replacement_total=0; output_300000_total=0; output_5000_total=0
pixel11_hys_arrays=0; pixel11_mrs_targets=0; pixel11_passive_targets=0
pixel11_hys_changes=0; pixel11_mrs_changes=0; pixel11_passive_changes=0
while IFS="$_tab" read -r file source_sha source_bytes source_polling; do
  [ "$file" = file ] && continue
  [ -n "$file" ] || continue
  sf="$CACHE_DIR/$file"; of="$PATCH_STAGE/$file"
  patch_one "$sf" "$of" "$file" || fail 40 "pixel11_control_patch_invalid_$file"
  thermal_json_tolerant_validate "$of" || fail 40 "output_structure_invalid_$file"
  osh="$(sha_file "$of")"; o300="$(count_polling_value "$of" 300000)"; o5="$(count_polling_value "$of" 5000)"; o30="$(count_polling_value "$of" 30000)"; olow="$(count_lowercase_polling "$of")"
  [ "$o30" = 0 ] || fail 41 "output_30000_rejected_$file"
  [ "$olow" = 0 ] || fail 42 "output_lowercase_polling_rejected_$file"
  if [ "$POLLING_MODE" = mod ]; then
    [ "$o300" = 0 ] || fail 43 "remaining_300000_$file"
    [ "$o5" = "$source_polling" ] || fail 44 "replacement_count_${file}_${o5}_expected_${source_polling}"
    replacements="$source_polling"
  else
    [ "$o300" = "$source_polling" ] || fail 45 "stock_300000_changed_$file"
    [ "$o5" = 0 ] || fail 46 "stock_contains_5000_$file"
    replacements=0
  fi
  ns="$GUARD_DIR/.norm-source.$$"; no="$GUARD_DIR/.norm-output.$$"
  normalize_allowed "$sf" "$ns" "$file"; normalize_allowed "$of" "$no" "$file"
  cmp -s "$ns" "$no" || fail 47 "unallowed_byte_change_$file"
  rm -f "$ns" "$no"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$file" "$source_sha" "$osh" "$source_polling" "$replacements" "$o300" "$o5" yes >> "$PATCH_MANIFEST_TMP"
  [ "$first_json" -eq 1 ] || printf '%s\n' '    ,' >> "$REPORT_TMP"; first_json=0
  printf '    "%s": {\n' "$file" >> "$REPORT_TMP"
  printf '      "source_sha256": "%s",\n' "$source_sha" >> "$REPORT_TMP"
  printf '      "output_sha256": "%s",\n' "$osh" >> "$REPORT_TMP"
  printf '      "source_polling_300000": %s,\n' "$source_polling" >> "$REPORT_TMP"
  printf '      "replacements": %s,\n' "$replacements" >> "$REPORT_TMP"
  printf '      "output_polling_300000": %s,\n' "$o300" >> "$REPORT_TMP"
  printf '      "output_polling_5000": %s,\n' "$o5" >> "$REPORT_TMP"
  printf '%s\n' '      "validation": "passed"' '    }' >> "$REPORT_TMP"
  source_files=$((source_files + 1)); source_polling_total=$((source_polling_total + source_polling)); replacement_total=$((replacement_total + replacements)); output_300000_total=$((output_300000_total + o300)); output_5000_total=$((output_5000_total + o5))
done < "$MANIFEST"

[ "$source_files" -eq "$THERMAL_LAYOUT_COUNT" ] 2>/dev/null || fail 48 "output_layout_count_${source_files}_expected_${THERMAL_LAYOUT_COUNT}"
for file in $THERMAL_LAYOUT_FILES; do [ -s "$PATCH_STAGE/$file" ] || fail 48 "required_output_missing_$file"; done

if [ "$DEVICE_FAMILY" = pixel11 ] && { [ "$PIXEL11_HYSTERESIS_MODE" = mod ] || [ "$PIXEL11_PASSIVE_MODE" = mod ]; }; then
  [ "$pixel11_hys_arrays" = 7 ] || fail 58 "pixel11_hysteresis_inventory_${pixel11_hys_arrays}_expected_7"
  [ "$pixel11_mrs_targets" = 32 ] || fail 58 "pixel11_mrs_inventory_${pixel11_mrs_targets}_expected_32"
  [ "$pixel11_passive_targets" = 7 ] || fail 58 "pixel11_passive_inventory_${pixel11_passive_targets}_expected_7"
  if [ "$PIXEL11_HYSTERESIS_MODE" = mod ]; then
    [ "$pixel11_hys_changes" = 15 ] || fail 58 "pixel11_hysteresis_changes_${pixel11_hys_changes}_expected_15"
    [ "$pixel11_mrs_changes" = 32 ] || fail 58 "pixel11_mrs_changes_${pixel11_mrs_changes}_expected_32"
  else
    [ "$pixel11_hys_changes" = 0 ] || fail 58 pixel11_stock_hysteresis_changed
    [ "$pixel11_mrs_changes" = 0 ] || fail 58 pixel11_stock_mrs_changed
  fi
  if [ "$PIXEL11_PASSIVE_MODE" = mod ]; then
    [ "$pixel11_passive_changes" = 7 ] || fail 58 "pixel11_passive_changes_${pixel11_passive_changes}_expected_7"
  else
    [ "$pixel11_passive_changes" = 0 ] || fail 58 pixel11_stock_passive_changed
  fi
fi

printf '%s\n' '  },' '  "totals": {' >> "$REPORT_TMP"
printf '    "source_files": %s,\n' "$source_files" >> "$REPORT_TMP"
printf '    "source_polling_300000": %s,\n' "$source_polling_total" >> "$REPORT_TMP"
printf '    "replacements": %s,\n' "$replacement_total" >> "$REPORT_TMP"
printf '    "output_polling_300000": %s,\n' "$output_300000_total" >> "$REPORT_TMP"
printf '    "output_polling_5000": %s\n' "$output_5000_total" >> "$REPORT_TMP"
printf '%s\n' '  },' '  "validation": "passed"' '}' >> "$REPORT_TMP"
thermal_json_tolerant_validate "$REPORT_TMP" || fail 49 validation_report_invalid
if [ "$POLLING_MODE" = mod ]; then
  [ "$replacement_total" = "$source_polling_total" ] || fail 50 total_replacement_mismatch
  [ "$output_300000_total" = 0 ] || fail 51 total_remaining_300000
  [ "$output_5000_total" = "$source_polling_total" ] || fail 52 total_5000_mismatch
else
  [ "$replacement_total" = 0 ] || fail 53 stock_replacements_nonzero
  [ "$output_300000_total" = "$source_polling_total" ] || fail 54 stock_total_300000_changed
  [ "$output_5000_total" = 0 ] || fail 55 stock_total_5000_nonzero
fi

if [ -d "$TARGET_DIR" ]; then mv "$TARGET_DIR" "$TARGET_OLD"; fi
mv "$PATCH_STAGE" "$TARGET_DIR" || fail 56 target_atomic_promotion_failed
PROMOTED=1; rm -rf "$TARGET_OLD"
mv "$PATCH_MANIFEST_TMP" "$PATCH_MANIFEST"
mv "$REPORT_TMP" "$REPORT_MODULE"
cp -fp "$REPORT_MODULE" "$REPORT_DATA"
thermal_layout_write_env "$LAYOUT_ENV" "$DEVICE" "$BUILD_ID" || fail 57 layout_state_publish_failed
chmod 0644 "$PATCH_MANIFEST" "$REPORT_MODULE" "$REPORT_DATA" 2>/dev/null || true
printf '%s\n' PATCH_THERMAL=pass "PATCH_THERMAL_DEVICE=$DEVICE" "PATCH_THERMAL_BUILD_ID=$BUILD_ID" "PATCH_THERMAL_LAYOUT_FAMILY=$THERMAL_LAYOUT_FAMILY" "PATCH_THERMAL_LAYOUT_FILES=$THERMAL_LAYOUT_FILES_CSV" "PATCH_THERMAL_SOURCE_CACHE=$CACHE_DIR" "PATCH_THERMAL_FILES=$source_files" "PATCH_THERMAL_SOURCE_300000=$source_polling_total" "PATCH_THERMAL_REPLACEMENTS=$replacement_total" "PATCH_THERMAL_OUTPUT_5000=$output_5000_total" "PATCH_THERMAL_PIXEL11_HYSTERESIS_MODE=$PIXEL11_HYSTERESIS_MODE" "PATCH_THERMAL_PIXEL11_PASSIVE_MODE=$PIXEL11_PASSIVE_MODE" "PATCH_THERMAL_PIXEL11_HYSTERESIS_CHANGES=$pixel11_hys_changes" "PATCH_THERMAL_PIXEL11_MRS_CHANGES=$pixel11_mrs_changes" "PATCH_THERMAL_PIXEL11_PASSIVE_CHANGES=$pixel11_passive_changes" "PATCH_THERMAL_MANIFEST=$PATCH_MANIFEST" "PATCH_THERMAL_REPORT=$REPORT_MODULE"
trap - EXIT HUP INT TERM
exit 0
