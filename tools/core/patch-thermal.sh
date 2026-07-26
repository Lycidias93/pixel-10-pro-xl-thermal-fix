#!/system/bin/sh
# Dynamic V2 thermal patcher with build-keyed stock cache and atomic promotion.
set -eu

POLLING_MODE="${1:-mod}"
OUTDOOR_PROFILE="${2:-stock}"
MODPATH="${3:-/data/adb/modules/pixel-10-pro-xl-thermal-fix}"
ID="pixel-10-pro-xl-thermal-fix"
DATA_ROOT="${THERMAL_DATA_ROOT:-/data/adb/$ID}"
TARGET_DIR="$MODPATH/system/vendor/etc"
TARGET_PARENT="$MODPATH/system/vendor"
GUARD_DIR="$MODPATH/guard"
HELPER="$MODPATH/tools/core/supported-build.sh"

[ -r "$HELPER" ] || {
  printf '%s\n' "PATCH_THERMAL=fail"
  printf '%s\n' "PATCH_THERMAL_REASON=supported_helper_missing"
  exit 20
}
. "$HELPER"

case "$POLLING_MODE" in stock|mod) ;; *) printf '%s\n' "PATCH_THERMAL=fail"; printf '%s\n' "PATCH_THERMAL_REASON=invalid_polling_mode"; exit 21 ;; esac
case "$OUTDOOR_PROFILE" in stock|outdoor-safe|outdoor-plus|outdoor-extended) ;; *) printf '%s\n' "PATCH_THERMAL=fail"; printf '%s\n' "PATCH_THERMAL_REASON=invalid_outdoor_profile"; exit 22 ;; esac

DEVICE="${THERMAL_DEVICE:-$(getprop ro.product.device 2>/dev/null || true)}"
BUILD_ID="${THERMAL_BUILD_ID:-$(getprop ro.build.id 2>/dev/null || true)}"
[ -n "$DEVICE" ] || DEVICE=unknown
[ -n "$BUILD_ID" ] || BUILD_ID=unknown
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

CONTROLLED_FILES="
thermal_info_config.json
thermal_info_config_charge.json
thermal_info_config_throttling.json
"
REQUIRED_FILES="
thermal_info_config.json
thermal_info_config_charge.json
thermal_info_config_throttling.json
"

cleanup() {
  rc="$?"
  rm -rf "$CACHE_STAGE" "$PATCH_STAGE" 2>/dev/null || true
  rm -f "$PATCH_MANIFEST_TMP" "$REPORT_TMP" 2>/dev/null || true
  if [ "$PROMOTED" -eq 0 ] && [ -d "$TARGET_OLD" ] && [ ! -d "$TARGET_DIR" ]; then
    mv "$TARGET_OLD" "$TARGET_DIR" 2>/dev/null || true
  fi
  if [ "$CACHE_PROMOTED" -eq 0 ] && [ -d "$CACHE_OLD" ] && [ ! -d "$CACHE_DIR" ]; then
    mv "$CACHE_OLD" "$CACHE_DIR" 2>/dev/null || true
  fi
  rm -rf "$TARGET_OLD" "$CACHE_OLD" 2>/dev/null || true
  return "$rc"
}
trap cleanup EXIT HUP INT TERM

fail() {
  rc="$1"
  shift
  printf '%s\n' "PATCH_THERMAL=fail"
  printf '%s\n' "PATCH_THERMAL_REASON=$*"
  exit "$rc"
}

sha_file() {
  sha256sum "$1" 2>/dev/null | awk '{print $1}'
}
bytes_file() {
  wc -c < "$1" 2>/dev/null | tr -d ' '
}
count_polling_value() {
  file="$1"
  value="$2"
  awk -v value="$value" '
    {
      line = $0
      pattern = "\"PollingDelay\"[[:space:]]*:[[:space:]]*" value "([^0-9]|$)"
      while (match(line, pattern)) {
        total++
        line = substr(line, RSTART + RLENGTH)
      }
    }
    END { print total + 0 }
  ' "$file"
}
count_lowercase_polling() {
  grep -o '"pollingDelay"[[:space:]]*:' "$1" 2>/dev/null | wc -l | tr -d ' '
}
is_controlled_name() {
  case " $CONTROLLED_FILES " in *"
$1
"*) return 0 ;; *) return 1 ;; esac
}
is_required_name() {
  case " $REQUIRED_FILES " in *"
$1
"*) return 0 ;; *) return 1 ;; esac
}
normalize_allowed() {
  src="$1"
  dst="$2"
  awk '
    function normalize_poll(line, token) {
      while (match(line, /"PollingDelay"[[:space:]]*:[[:space:]]*(300000|5000)/)) {
        token = substr(line, RSTART, RLENGTH)
        sub(/[0-9][0-9]*$/, "__POLLING_VALUE__", token)
        line = substr(line, 1, RSTART - 1) token substr(line, RSTART + RLENGTH)
      }
      return line
    }
    function target_name(line) {
      if (line ~ /"Name"[[:space:]]*:[[:space:]]*"VIRTUAL-SKIN-HINT"([[:space:]]*[,}]|[[:space:]]*$)/) return "VIRTUAL-SKIN-HINT"
      if (line ~ /"Name"[[:space:]]*:[[:space:]]*"VIRTUAL-SKIN"([[:space:]]*[,}]|[[:space:]]*$)/) return "VIRTUAL-SKIN"
      return ""
    }
    BEGIN { target = "" }
    {
      line = $0
      name = target_name(line)
      if (name != "") {
        target = name
      } else if (line ~ /"Name"[[:space:]]*:/) {
        target = ""
      }
      line = normalize_poll(line)
      if (target != "" && line ~ /"HotThreshold"[[:space:]]*:/) {
        start = index(line, "[")
        finish = index(line, "]")
        if (start > 0 && finish > start) {
          line = substr(line, 1, start) "__HOTTHRESHOLD__" substr(line, finish)
        }
        target = ""
      }
      print line
    }
  ' "$src" > "$dst"
}
patch_one() {
  src="$1"
  dst="$2"
  awk -v delta="$DELTA" -v poll_mode="$POLLING_MODE" '
    function trim(value) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      return value
    }
    function target_name(line) {
      if (line ~ /"Name"[[:space:]]*:[[:space:]]*"VIRTUAL-SKIN-HINT"([[:space:]]*[,}]|[[:space:]]*$)/) return "VIRTUAL-SKIN-HINT"
      if (line ~ /"Name"[[:space:]]*:[[:space:]]*"VIRTUAL-SKIN"([[:space:]]*[,}]|[[:space:]]*$)/) return "VIRTUAL-SKIN"
      return ""
    }
    function is_numeric(value) {
      return value ~ /^[+-]?[0-9]+([.][0-9]+)?$/
    }
    function decimal_places(value, dot) {
      dot = index(value, ".")
      return dot > 0 ? length(value) - dot : 0
    }
    function add_delta_preserving_scale(value, amount, places) {
      places = decimal_places(value)
      return sprintf("%.*f", places, (value + 0) + amount)
    }
    BEGIN { target = ""; bad = 0 }
    {
      line = $0
      name = target_name(line)
      if (name != "") {
        if (++seen[name] != 1) bad = 1
        target = name
      } else if (line ~ /"Name"[[:space:]]*:/) {
        if (target != "") bad = 1
        target = ""
      }

      if (poll_mode == "mod") {
        while (match(line, /"PollingDelay"[[:space:]]*:[[:space:]]*300000/)) {
          token = substr(line, RSTART, RLENGTH)
          sub(/300000$/, "5000", token)
          line = substr(line, 1, RSTART - 1) token substr(line, RSTART + RLENGTH)
        }
      }

      if (target != "" && line ~ /"HotThreshold"[[:space:]]*:/) {
        start = index(line, "[")
        finish = index(line, "]")
        if (start < 1 || finish <= start) {
          bad = 1
        } else {
          prefix = substr(line, 1, start)
          suffix = substr(line, finish)
          content = substr(line, start + 1, finish - start - 1)
          n = split(content, elements, ",")
          if (n != 7) bad = 1
          rebuilt = ""
          for (i = 1; i <= n; i++) {
            elem = trim(elements[i])
            if (i == 7) {
              if (!is_numeric(elem) || (elem + 0) > 55.0) bad = 1
            } else if (elem == "\"NAN\"") {
              # Sentinel remains byte-equivalent.
            } else if (is_numeric(elem)) {
              if (delta != 0) elem = add_delta_preserving_scale(elem, delta)
            } else {
              bad = 1
            }
            rebuilt = rebuilt elem
            if (i < n) rebuilt = rebuilt ", "
          }
          line = prefix rebuilt suffix
          arrays[target]++
        }
        target = ""
      }
      print line
    }
    END {
      if (target != "") bad = 1
      for (name in seen) if (arrays[name] != 1) bad = 1
      if (bad) exit 70
    }
  ' "$src" > "$dst"
}

DELTA=0
case "$OUTDOOR_PROFILE" in
  outdoor-safe) DELTA=1 ;;
  outdoor-plus) DELTA=2 ;;
  outdoor-extended) DELTA=3 ;;
esac

mkdir -p "$DATA_ROOT" "$CACHE_PARENT" "$TARGET_PARENT" "$GUARD_DIR"

cache_valid=1
[ -s "$MANIFEST" ] || cache_valid=0
if [ "$cache_valid" -eq 1 ]; then
  manifest_rows=0
  tab="$(printf '\t')"
  while IFS="$tab" read -r file expected_sha expected_bytes poll300000; do
    [ "$file" = file ] && continue
    [ -n "$file" ] || continue
    is_controlled_name "$file" || cache_valid=0
    cache_file="$CACHE_DIR/$file"
    [ -s "$cache_file" ] || cache_valid=0
    if [ -s "$cache_file" ]; then
      [ "$(sha_file "$cache_file")" = "$expected_sha" ] || cache_valid=0
      [ "$(bytes_file "$cache_file")" = "$expected_bytes" ] || cache_valid=0
      [ "$(count_polling_value "$cache_file" 300000)" = "$poll300000" ] || cache_valid=0
      [ "$(count_polling_value "$cache_file" 5000)" = 0 ] || cache_valid=0
      [ "$(count_polling_value "$cache_file" 30000)" = 0 ] || cache_valid=0
      [ "$(count_lowercase_polling "$cache_file")" = 0 ] || cache_valid=0
      thermal_json_tolerant_validate "$cache_file" || cache_valid=0
    fi
    manifest_rows=$(( manifest_rows + 1 ))
  done < "$MANIFEST"
  [ "$manifest_rows" -ge 3 ] || cache_valid=0
fi

if [ "$cache_valid" -ne 1 ]; then
  rm -rf "$CACHE_STAGE" "$CACHE_OLD"
  mkdir -p "$CACHE_STAGE"

  SOURCE_DIR="${THERMAL_SOURCE_DIR:-}"
  if [ -z "$SOURCE_DIR" ]; then
    for candidate in \
      /data/adb/magisk/mirror/vendor/etc \
      /data/adb/magisk/mirror/system/vendor/etc \
      /sbin/.magisk/mirror/vendor/etc \
      /sbin/.magisk/mirror/system/vendor/etc \
      /vendor/etc \
      /system/vendor/etc; do
      if [ -r "$candidate/thermal_info_config.json" ] &&
         [ -r "$candidate/thermal_info_config_charge.json" ] &&
         [ -r "$candidate/thermal_info_config_throttling.json" ]; then
        SOURCE_DIR="$candidate"
        break
      fi
    done
  fi
  [ -n "$SOURCE_DIR" ] || fail 30 stock_source_missing

  for required in $REQUIRED_FILES; do
    [ -s "$SOURCE_DIR/$required" ] || fail 31 "required_stock_file_missing_$required"
  done

  printf '%s\n' "file	sha256	bytes	polling_300000" > "$CACHE_STAGE/source-manifest.tsv"
  source_files=0
  source_polling_total=0
  for file in $CONTROLLED_FILES; do
    source_file="$SOURCE_DIR/$file"
    [ -f "$source_file" ] || continue

    if [ "$SOURCE_DIR" = /vendor/etc ] || [ "$SOURCE_DIR" = /system/vendor/etc ]; then
      module_file="$TARGET_DIR/$file"
      if [ -s "$module_file" ] && [ "$(sha_file "$source_file")" = "$(sha_file "$module_file")" ]; then
        fail 32 "active_overlay_detected_without_valid_cache_$file"
      fi
    fi

    thermal_json_tolerant_validate "$source_file" || fail 33 "source_structure_invalid_$file"
    poll300000="$(count_polling_value "$source_file" 300000)"
    poll5000="$(count_polling_value "$source_file" 5000)"
    poll30000="$(count_polling_value "$source_file" 30000)"
    lower="$(count_lowercase_polling "$source_file")"
    [ "$poll5000" = 0 ] || fail 34 "patched_source_5000_rejected_$file"
    [ "$poll30000" = 0 ] || fail 35 "source_30000_rejected_$file"
    [ "$lower" = 0 ] || fail 36 "source_lowercase_polling_rejected_$file"

    cp -fp "$source_file" "$CACHE_STAGE/$file"
    sha="$(sha_file "$CACHE_STAGE/$file")"
    bytes="$(bytes_file "$CACHE_STAGE/$file")"
    printf '%s\t%s\t%s\t%s\n' "$file" "$sha" "$bytes" "$poll300000" >> "$CACHE_STAGE/source-manifest.tsv"
    source_files=$(( source_files + 1 ))
    source_polling_total=$(( source_polling_total + poll300000 ))
  done
  [ "$source_files" -ge 3 ] || fail 37 "source_inventory_too_small_$source_files"
  if [ "$POLLING_MODE" = mod ]; then
    [ "$source_polling_total" -gt 0 ] || fail 38 no_source_polling_300000
  fi

  if [ -d "$CACHE_DIR" ]; then mv "$CACHE_DIR" "$CACHE_OLD"; fi
  mv "$CACHE_STAGE" "$CACHE_DIR" || fail 39 cache_promotion_failed
  CACHE_PROMOTED=1
  rm -rf "$CACHE_OLD"
fi

rm -rf "$PATCH_STAGE" "$TARGET_OLD"
mkdir -p "$PATCH_STAGE"

if [ -d "$TARGET_DIR" ]; then
  for existing in "$TARGET_DIR"/*; do
    [ -e "$existing" ] || continue
    name="${existing##*/}"
    case "$name" in thermal_info_config*.json) continue ;; esac
    cp -fpR "$existing" "$PATCH_STAGE/"
  done
fi

printf '%s\n' "file	source_sha256	output_sha256	source_polling_300000	replacements	output_polling_300000	output_polling_5000	allowed_diff" > "$PATCH_MANIFEST_TMP"
printf '%s\n' '{' > "$REPORT_TMP"
printf '%s\n' '  "schema": "pixel-thermal-dynamic-validation-v4",' >> "$REPORT_TMP"
printf '  "device": "%s",\n' "$DEVICE" >> "$REPORT_TMP"
printf '  "build_id": "%s",\n' "$BUILD_ID" >> "$REPORT_TMP"
printf '  "polling_mode": "%s",\n' "$POLLING_MODE" >> "$REPORT_TMP"
printf '  "outdoor_profile": "%s",\n' "$OUTDOOR_PROFILE" >> "$REPORT_TMP"
printf '%s\n' '  "outdoor_target_contract": "exact_virtual_skin_pair_v2",' >> "$REPORT_TMP"
printf '%s\n' '  "emergency_index_policy": "index6_stock_unchanged_max55",' >> "$REPORT_TMP"
printf '%s\n' '  "numeric_format_policy": "preserve_decimal_scale",' >> "$REPORT_TMP"
printf '%s\n' '  "files": {' >> "$REPORT_TMP"

tab="$(printf '\t')"
first_json=1
source_files=0
source_polling_total=0
replacement_total=0
output_300000_total=0
output_5000_total=0

while IFS="$tab" read -r file source_sha source_bytes source_polling; do
  [ "$file" = file ] && continue
  [ -n "$file" ] || continue
  source_file="$CACHE_DIR/$file"
  output_file="$PATCH_STAGE/$file"
  if ! patch_one "$source_file" "$output_file"; then
    fail 40 "outdoor_target_contract_invalid_$file"
  fi
  thermal_json_tolerant_validate "$output_file" || fail 41 "output_structure_invalid_$file"

  output_sha="$(sha_file "$output_file")"
  output300000="$(count_polling_value "$output_file" 300000)"
  output5000="$(count_polling_value "$output_file" 5000)"
  output30000="$(count_polling_value "$output_file" 30000)"
  output_lower="$(count_lowercase_polling "$output_file")"
  [ "$output30000" = 0 ] || fail 42 "output_30000_rejected_$file"
  [ "$output_lower" = 0 ] || fail 43 "output_lowercase_polling_rejected_$file"

  if [ "$POLLING_MODE" = mod ]; then
    [ "$output300000" = 0 ] || fail 44 "remaining_300000_$file"
    [ "$output5000" = "$source_polling" ] || fail 45 "replacement_count_${file}_${output5000}_expected_${source_polling}"
    replacements="$source_polling"
  else
    [ "$output300000" = "$source_polling" ] || fail 46 "stock_300000_changed_$file"
    [ "$output5000" = 0 ] || fail 47 "stock_contains_5000_$file"
    replacements=0
  fi

  norm_source="$GUARD_DIR/.norm-source.$$"
  norm_output="$GUARD_DIR/.norm-output.$$"
  normalize_allowed "$source_file" "$norm_source"
  normalize_allowed "$output_file" "$norm_output"
  cmp -s "$norm_source" "$norm_output" || fail 48 "unallowed_byte_change_$file"
  rm -f "$norm_source" "$norm_output"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$file" "$source_sha" "$output_sha" "$source_polling" "$replacements" \
    "$output300000" "$output5000" yes >> "$PATCH_MANIFEST_TMP"

  if [ "$first_json" -eq 0 ]; then printf '%s\n' '    ,' >> "$REPORT_TMP"; fi
  first_json=0
  printf '    "%s": {\n' "$file" >> "$REPORT_TMP"
  printf '      "source_sha256": "%s",\n' "$source_sha" >> "$REPORT_TMP"
  printf '      "output_sha256": "%s",\n' "$output_sha" >> "$REPORT_TMP"
  printf '      "source_polling_300000": %s,\n' "$source_polling" >> "$REPORT_TMP"
  printf '      "replacements": %s,\n' "$replacements" >> "$REPORT_TMP"
  printf '      "output_polling_300000": %s,\n' "$output300000" >> "$REPORT_TMP"
  printf '      "output_polling_5000": %s,\n' "$output5000" >> "$REPORT_TMP"
  printf '%s\n' '      "validation": "passed"' >> "$REPORT_TMP"
  printf '%s\n' '    }' >> "$REPORT_TMP"

  source_files=$(( source_files + 1 ))
  source_polling_total=$(( source_polling_total + source_polling ))
  replacement_total=$(( replacement_total + replacements ))
  output_300000_total=$(( output_300000_total + output300000 ))
  output_5000_total=$(( output_5000_total + output5000 ))
done < "$MANIFEST"

for required in $REQUIRED_FILES; do
  [ -s "$PATCH_STAGE/$required" ] || fail 49 "required_output_missing_$required"
done

printf '%s\n' '  },' >> "$REPORT_TMP"
printf '%s\n' '  "totals": {' >> "$REPORT_TMP"
printf '    "source_files": %s,\n' "$source_files" >> "$REPORT_TMP"
printf '    "source_polling_300000": %s,\n' "$source_polling_total" >> "$REPORT_TMP"
printf '    "replacements": %s,\n' "$replacement_total" >> "$REPORT_TMP"
printf '    "output_polling_300000": %s,\n' "$output_300000_total" >> "$REPORT_TMP"
printf '    "output_polling_5000": %s\n' "$output_5000_total" >> "$REPORT_TMP"
printf '%s\n' '  },' >> "$REPORT_TMP"
printf '%s\n' '  "validation": "passed"' >> "$REPORT_TMP"
printf '%s\n' '}' >> "$REPORT_TMP"
thermal_json_tolerant_validate "$REPORT_TMP" || fail 50 validation_report_invalid

if [ "$POLLING_MODE" = mod ]; then
  [ "$replacement_total" = "$source_polling_total" ] || fail 51 total_replacement_mismatch
  [ "$output_300000_total" = 0 ] || fail 52 total_remaining_300000
  [ "$output_5000_total" = "$source_polling_total" ] || fail 53 total_5000_mismatch
else
  [ "$replacement_total" = 0 ] || fail 54 stock_replacements_nonzero
  [ "$output_300000_total" = "$source_polling_total" ] || fail 55 stock_total_300000_changed
  [ "$output_5000_total" = 0 ] || fail 56 stock_total_5000_nonzero
fi

if [ -d "$TARGET_DIR" ]; then mv "$TARGET_DIR" "$TARGET_OLD"; fi
mv "$PATCH_STAGE" "$TARGET_DIR" || fail 57 target_atomic_promotion_failed
PROMOTED=1
rm -rf "$TARGET_OLD"

mv "$PATCH_MANIFEST_TMP" "$PATCH_MANIFEST"
mv "$REPORT_TMP" "$REPORT_MODULE"
cp -fp "$REPORT_MODULE" "$REPORT_DATA"
chmod 0644 "$PATCH_MANIFEST" "$REPORT_MODULE" "$REPORT_DATA" 2>/dev/null || true

printf '%s\n' "PATCH_THERMAL=pass"
printf '%s\n' "PATCH_THERMAL_DEVICE=$DEVICE"
printf '%s\n' "PATCH_THERMAL_BUILD_ID=$BUILD_ID"
printf '%s\n' "PATCH_THERMAL_SOURCE_CACHE=$CACHE_DIR"
printf '%s\n' "PATCH_THERMAL_FILES=$source_files"
printf '%s\n' "PATCH_THERMAL_SOURCE_300000=$source_polling_total"
printf '%s\n' "PATCH_THERMAL_REPLACEMENTS=$replacement_total"
printf '%s\n' "PATCH_THERMAL_OUTPUT_5000=$output_5000_total"
printf '%s\n' 'PATCH_THERMAL_TARGET_CONTRACT=exact_virtual_skin_pair_v2'
printf '%s\n' 'PATCH_THERMAL_EMERGENCY_INDEX=index6_stock_unchanged_max55'
printf '%s\n' 'PATCH_THERMAL_NUMERIC_FORMAT=preserve_decimal_scale'
printf '%s\n' "PATCH_THERMAL_MANIFEST=$PATCH_MANIFEST"
printf '%s\n' "PATCH_THERMAL_REPORT=$REPORT_MODULE"
trap - EXIT HUP INT TERM
exit 0
