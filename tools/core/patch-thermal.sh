#!/system/bin/sh
# Pixel 10 thermal materializer: exact Git profile -> verified atomic overlay.
set -eu

POLLING_MODE="${1:-mod}"
OUTDOOR_PROFILE="${2:-stock}"
MODPATH="${3:-/data/adb/modules/pixel-10-pro-xl-thermal-fix}"
DEVICE="${4:-$(getprop ro.product.device 2>/dev/null || true)}"
ANDROID="${5:-$(getprop ro.build.version.release 2>/dev/null || true)}"
BUILD_ID="${6:-$(getprop ro.build.id 2>/dev/null || true)}"
ID="pixel-10-pro-xl-thermal-fix"
DATA_ROOT="${THERMAL_DATA_ROOT:-/data/adb/$ID}"
CONFIG_DIR="$DATA_ROOT"
CONFIG_FILE="$CONFIG_DIR/config.env"
RESOLVER="$MODPATH/tools/core/profile-resolver.sh"
SOURCE_VERIFY="$MODPATH/tools/core/profile-source-verify.sh"
TARGET_PARENT="$MODPATH/system/vendor"
TARGET_DIR="$TARGET_PARENT/etc"
STAGE_DIR="$TARGET_PARENT/.etc.profile-stage.$$"
OLD_DIR="$TARGET_PARENT/.etc.profile-old.$$"
GUARD_DIR="$MODPATH/guard"
VALIDATION_TMP=""
PROMOTED=0

fail() {
  _pt_rc="$1"
  shift
  printf '%s\n' "PATCH_THERMAL=fail" >&2
  printf '%s\n' "PATCH_THERMAL_REASON=$*" >&2
  exit "$_pt_rc"
}

cleanup() {
  if [ "$PROMOTED" != "1" ] && [ -d "$OLD_DIR" ] && [ ! -e "$TARGET_DIR" ]; then
    mv "$OLD_DIR" "$TARGET_DIR" 2>/dev/null || true
  fi
  rm -rf "$STAGE_DIR" 2>/dev/null || true
  [ -n "${VALIDATION_TMP:-}" ] && rm -f "$VALIDATION_TMP" 2>/dev/null || true
}
trap cleanup EXIT HUP INT TERM

case "$POLLING_MODE" in mod|stock) ;; *) fail 20 "invalid_polling_mode_$POLLING_MODE" ;; esac
case "$OUTDOOR_PROFILE" in stock|outdoor-safe|outdoor-plus|outdoor-extended) ;; *) fail 21 "invalid_outdoor_profile_$OUTDOOR_PROFILE" ;; esac
[ -r "$RESOLVER" ] || fail 22 resolver_missing
[ -x "$SOURCE_VERIFY" ] || fail 23 source_verifier_missing
. "$RESOLVER"
thermal_resolve_profile "$MODPATH" "$DEVICE" "$ANDROID" "$BUILD_ID" || fail 24 "resolver_$THERMAL_RESOLVER_REASON"
sh "$SOURCE_VERIFY" "$MODPATH" "$DEVICE" "$ANDROID" "$BUILD_ID" >/dev/null || fail 25 source_verification_failed

case "$OUTDOOR_PROFILE" in
  outdoor-safe) DELTA=1 ;;
  outdoor-plus) DELTA=2 ;;
  outdoor-extended) DELTA=3 ;;
  *) DELTA=0 ;;
esac

count_polling_value() {
  _cp_file="$1"
  _cp_value="$2"
  awk -v wanted="$_cp_value" '
    {
      rest=$0
      while (match(rest, /"PollingDelay"[[:space:]]*:[[:space:]]*[0-9]+/)) {
        token=substr(rest, RSTART, RLENGTH)
        sub(/^.*:[[:space:]]*/, "", token)
        if (token == wanted) count++
        rest=substr(rest, RSTART + RLENGTH)
      }
    }
    END { print count + 0 }
  ' "$_cp_file"
}

cfg_set() {
  _cs_key="$1"
  _cs_value="$2"
  mkdir -p "$CONFIG_DIR"
  touch "$CONFIG_FILE"
  _cs_tmp="$CONFIG_FILE.tmp.$$"
  grep -v "^${_cs_key}=" "$CONFIG_FILE" 2>/dev/null > "$_cs_tmp" || true
  printf '%s=%s\n' "$_cs_key" "$_cs_value" >> "$_cs_tmp"
  mv "$_cs_tmp" "$CONFIG_FILE"
  chmod 0600 "$CONFIG_FILE" 2>/dev/null || true
}

rm -rf "$STAGE_DIR" "$OLD_DIR"
mkdir -p "$STAGE_DIR" "$GUARD_DIR" "$TARGET_PARENT"

# Preserve non-thermal overlay files such as fstab.zram.100p.
if [ -d "$TARGET_DIR" ]; then
  for _pt_existing in "$TARGET_DIR"/*; do
    [ -e "$_pt_existing" ] || continue
    _pt_name="${_pt_existing##*/}"
    case "$_pt_name" in thermal_info_config*.json) continue ;; esac
    cp -fp "$_pt_existing" "$STAGE_DIR/$_pt_name"
  done
fi

ORIGINALS_DIR="$DATA_ROOT/originals/$THERMAL_PROFILE_DEVICE/$THERMAL_PROFILE_BUILD_SLUG/vendor/etc"
mkdir -p "$ORIGINALS_DIR"
MANIFEST_TMP="$GUARD_DIR/.patch-manifest.tsv.$$"
VALIDATION_TMP="$GUARD_DIR/.validation-report.json.$$"
VALIDATION_MODULE="$MODPATH/validation_report.json"
VALIDATION_DATA="$DATA_ROOT/validation_report.json"
printf '%s\n' 'file\tsource_sha256\toutput_sha256\tsource_polling_300000\tpolling_replacements\toutput_polling_300000\toutput_polling_5000\thotthreshold_values_changed' > "$MANIFEST_TMP"
VALIDATION_FIRST=1
{
  printf '%s\n' '{'
  printf '  "schema": "pixel-thermal-exact-profile-validation-v2",\n'
  printf '  "resolver_status": "%s",\n' "$THERMAL_RESOLVER_STATUS"
  printf '  "profile": "%s",\n' "$THERMAL_PROFILE_REL"
  printf '  "device": "%s",\n' "$THERMAL_PROFILE_DEVICE"
  printf '  "build_id": "%s",\n' "$THERMAL_PROFILE_BUILD_ID"
  printf '  "polling_mode": "%s",\n' "$POLLING_MODE"
  printf '  "outdoor_profile": "%s",\n' "$OUTDOOR_PROFILE"
  printf '%s\n' '  "files": {'
} > "$VALIDATION_TMP"

SOURCE_FILES=0
SOURCE_POLLING_TOTAL=0
REPLACEMENTS_TOTAL=0
OUTPUT_POLLING_300000_TOTAL=0
OUTPUT_POLLING_5000_TOTAL=0
HOT_VALUES_TOTAL=0

for src_file in "$THERMAL_PROFILE_ETC"/thermal_info_config*.json; do
  [ -f "$src_file" ] || continue
  file="${src_file##*/}"
  out_file="$STAGE_DIR/$file"
  orig_file="$ORIGINALS_DIR/$file"
  stats_file="$STAGE_DIR/.stats.$file"
  source_polling="$(count_polling_value "$src_file" 300000)"
  source_sha="$(sha256sum "$src_file" | awk '{print $1}')"

  cp -fp "$src_file" "$orig_file"
  orig_sha="$(sha256sum "$orig_file" | awk '{print $1}')"
  [ "$orig_sha" = "$source_sha" ] || fail 26 "original_copy_sha_mismatch_$file"

  awk -v poll_mode="$POLLING_MODE" -v delta="$DELTA" -v stats="$stats_file" '
    function patch_polling(line,    result, rest, token) {
      result=""
      rest=line
      while (match(rest, /"PollingDelay"[[:space:]]*:[[:space:]]*300000([^0-9]|$)/)) {
        token=substr(rest, RSTART, RLENGTH)
        sub(/300000/, "5000", token)
        result=result substr(rest, 1, RSTART - 1) token
        rest=substr(rest, RSTART + RLENGTH)
        polling_changes++
      }
      return result rest
    }
    BEGIN { in_target=0; polling_changes=0; hot_values_changed=0 }
    /"Name"[[:space:]]*:[[:space:]]*"VIRTUAL-SKIN"/ || /"Name"[[:space:]]*:[[:space:]]*"VIRTUAL-SKIN-HINT"/ { in_target=1 }
    /"Name"[[:space:]]*:/ && !(/"VIRTUAL-SKIN"/ || /"VIRTUAL-SKIN-HINT"/) { in_target=0 }
    {
      if (poll_mode == "mod") $0=patch_polling($0)
    }
    in_target && /"HotThreshold"[[:space:]]*:/ {
      start=index($0, "[")
      end=index($0, "]")
      if (start > 0 && end > start && delta != 0) {
        prefix=substr($0, 1, start)
        suffix=substr($0, end)
        array_content=substr($0, start + 1, end - start - 1)
        n=split(array_content, elements, ",")
        new_array=""
        for (i=1; i<=n; i++) {
          elem=elements[i]
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", elem)
          if (elem ~ /^[+-]?[0-9]+([.][0-9]+)?$/) {
            elem=(elem + delta)
            hot_values_changed++
          }
          new_array=new_array elem
          if (i < n) new_array=new_array ", "
        }
        $0=prefix new_array suffix
      }
      in_target=0
    }
    { print }
    END { print polling_changes "\t" hot_values_changed > stats }
  ' "$src_file" > "$out_file"
  chmod 0644 "$out_file" 2>/dev/null || true

  IFS="$(printf '\t')" read -r replacements hot_values < "$stats_file"
  rm -f "$stats_file"
  output_polling_300000="$(count_polling_value "$out_file" 300000)"
  output_polling_5000="$(count_polling_value "$out_file" 5000)"
  output_sha="$(sha256sum "$out_file" | awk '{print $1}')"

  case "$POLLING_MODE" in
    mod)
      [ "$replacements" -eq "$source_polling" ] 2>/dev/null || fail 27 "replacement_count_${file}_${replacements}_expected_${source_polling}"
      [ "$output_polling_300000" -eq 0 ] 2>/dev/null || fail 28 "remaining_300000_$file"
      [ "$output_polling_5000" -eq "$source_polling" ] 2>/dev/null || fail 29 "output_5000_${file}_${output_polling_5000}_expected_${source_polling}"
    ;;
    stock)
      [ "$replacements" -eq 0 ] 2>/dev/null || fail 30 "stock_mode_replaced_polling_$file"
      [ "$output_polling_300000" -eq "$source_polling" ] 2>/dev/null || fail 31 "stock_polling_changed_$file"
      [ "$output_polling_5000" -eq 0 ] 2>/dev/null || fail 32 "stock_mode_contains_5000_$file"
    ;;
  esac

  if [ "$DELTA" -eq 0 ] 2>/dev/null; then
    cmp -s "$src_file" "$out_file" || {
      [ "$POLLING_MODE" = "mod" ] || fail 33 "stock_output_not_byte_identical_$file"
      [ "$source_polling" -gt 0 ] 2>/dev/null || fail 34 "unplanned_diff_without_polling_$file"
    }
  elif [ "$source_polling" -eq 0 ] 2>/dev/null && [ "$hot_values" -eq 0 ] 2>/dev/null; then
    cmp -s "$src_file" "$out_file" || fail 35 "unplanned_diff_$file"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$file" "$source_sha" "$output_sha" "$source_polling" "$replacements" "$output_polling_300000" "$output_polling_5000" "$hot_values" >> "$MANIFEST_TMP"
  if [ "$VALIDATION_FIRST" -eq 0 ]; then printf '%s\n' '    ,' >> "$VALIDATION_TMP"; fi
  VALIDATION_FIRST=0
  {
    printf '    "%s": {\n' "$file"
    printf '      "original_sha256": "%s",\n' "$source_sha"
    printf '      "original_polling_count": %s,\n' "$source_polling"
    printf '      "patched_sha256": "%s",\n' "$output_sha"
    printf '      "patched_polling_count": %s,\n' "$output_polling_5000"
    printf '      "polling_replacements": %s,\n' "$replacements"
    printf '      "remaining_polling_300000": %s,\n' "$output_polling_300000"
    printf '      "hotthreshold_values_changed": %s,\n' "$hot_values"
    printf '      "validation": "passed"\n'
    printf '%s\n' '    }'
  } >> "$VALIDATION_TMP"
  SOURCE_FILES=$(( SOURCE_FILES + 1 ))
  SOURCE_POLLING_TOTAL=$(( SOURCE_POLLING_TOTAL + source_polling ))
  REPLACEMENTS_TOTAL=$(( REPLACEMENTS_TOTAL + replacements ))
  OUTPUT_POLLING_300000_TOTAL=$(( OUTPUT_POLLING_300000_TOTAL + output_polling_300000 ))
  OUTPUT_POLLING_5000_TOTAL=$(( OUTPUT_POLLING_5000_TOTAL + output_polling_5000 ))
  HOT_VALUES_TOTAL=$(( HOT_VALUES_TOTAL + hot_values ))
done

[ "$SOURCE_FILES" -eq "$THERMAL_PROFILE_JSON_COUNT" ] 2>/dev/null || fail 36 "source_file_count_${SOURCE_FILES}_expected_${THERMAL_PROFILE_JSON_COUNT}"
[ "$SOURCE_POLLING_TOTAL" -eq "$THERMAL_PROFILE_POLLING_300000" ] 2>/dev/null || fail 37 "source_polling_${SOURCE_POLLING_TOTAL}_expected_${THERMAL_PROFILE_POLLING_300000}"
if [ "$POLLING_MODE" = "mod" ]; then
  [ "$REPLACEMENTS_TOTAL" -eq "$THERMAL_PROFILE_POLLING_300000" ] 2>/dev/null || fail 38 "total_replacements_${REPLACEMENTS_TOTAL}_expected_${THERMAL_PROFILE_POLLING_300000}"
  [ "$OUTPUT_POLLING_300000_TOTAL" -eq 0 ] 2>/dev/null || fail 39 remaining_polling_300000
  [ "$OUTPUT_POLLING_5000_TOTAL" -eq "$THERMAL_PROFILE_POLLING_300000" ] 2>/dev/null || fail 40 "total_5000_${OUTPUT_POLLING_5000_TOTAL}_expected_${THERMAL_PROFILE_POLLING_300000}"
else
  [ "$REPLACEMENTS_TOTAL" -eq 0 ] 2>/dev/null || fail 41 stock_mode_total_replacements_nonzero
  [ "$OUTPUT_POLLING_5000_TOTAL" -eq 0 ] 2>/dev/null || fail 42 stock_mode_total_5000_nonzero
fi

{
  printf '%s\n' '  },'
  printf '%s\n' '  "totals": {'
  printf '    "source_files": %s,\n' "$SOURCE_FILES"
  printf '    "source_polling_300000": %s,\n' "$SOURCE_POLLING_TOTAL"
  printf '    "polling_replacements": %s,\n' "$REPLACEMENTS_TOTAL"
  printf '    "output_polling_300000": %s,\n' "$OUTPUT_POLLING_300000_TOTAL"
  printf '    "output_polling_5000": %s,\n' "$OUTPUT_POLLING_5000_TOTAL"
  printf '    "hotthreshold_values_changed": %s\n' "$HOT_VALUES_TOTAL"
  printf '%s\n' '  },'
  printf '%s\n' '  "validation": "passed"'
  printf '%s\n' '}'
} >> "$VALIDATION_TMP"

if [ -e "$TARGET_DIR" ]; then mv "$TARGET_DIR" "$OLD_DIR"; fi
mv "$STAGE_DIR" "$TARGET_DIR"
PROMOTED=1
rm -rf "$OLD_DIR"
mv "$MANIFEST_TMP" "$GUARD_DIR/patch-manifest.tsv"
mkdir -p "$DATA_ROOT"
mv "$VALIDATION_TMP" "$VALIDATION_MODULE"
cp -fp "$VALIDATION_MODULE" "$VALIDATION_DATA"
chmod 0644 "$VALIDATION_MODULE" "$VALIDATION_DATA" 2>/dev/null || true

{
  printf '%s\n' "resolver_status=$THERMAL_RESOLVER_STATUS"
  printf '%s\n' "resolver_reason=$THERMAL_RESOLVER_REASON"
  printf '%s\n' "device=$THERMAL_PROFILE_DEVICE"
  printf '%s\n' "android=$THERMAL_PROFILE_ANDROID"
  printf '%s\n' "build_id=$THERMAL_PROFILE_BUILD_ID"
  printf '%s\n' "channel=$THERMAL_PROFILE_CHANNEL"
  printf '%s\n' "family=$THERMAL_PROFILE_FAMILY"
  printf '%s\n' "build_slug=$THERMAL_PROFILE_BUILD_SLUG"
  printf '%s\n' "profile_rel=$THERMAL_PROFILE_REL"
  printf '%s\n' "profile_source_etc=$THERMAL_PROFILE_ETC"
  printf '%s\n' "profile_bundle_sha256=$THERMAL_PROFILE_BUNDLE_SHA256"
  printf '%s\n' "expected_thermal_json=$THERMAL_PROFILE_JSON_COUNT"
  printf '%s\n' "expected_polling_300000=$THERMAL_PROFILE_POLLING_300000"
  printf '%s\n' "polling_mode=$POLLING_MODE"
  printf '%s\n' "outdoor_profile=$OUTDOOR_PROFILE"
  printf '%s\n' "outdoor_delta=$DELTA"
  printf '%s\n' "polling_replacements=$REPLACEMENTS_TOTAL"
  printf '%s\n' "hotthreshold_values_changed=$HOT_VALUES_TOTAL"
} > "$GUARD_DIR/profile-source.env"
printf '%s\n' "$THERMAL_PROFILE_REL" > "$GUARD_DIR/selected_profile"

if [ "$POLLING_MODE" = "mod" ]; then cfg_set THERMAL_POLLING_EFFECTIVE 5000; else cfg_set THERMAL_POLLING_EFFECTIVE 300000; fi
cfg_set THERMAL_PROFILE_REL "$THERMAL_PROFILE_REL"
cfg_set THERMAL_PROFILE_BUILD_ID "$THERMAL_PROFILE_BUILD_ID"
cfg_set THERMAL_PROFILE_CHANNEL "$THERMAL_PROFILE_CHANNEL"

printf '%s\n' "PATCH_THERMAL=pass"
printf '%s\n' "PROFILE_SOURCE=$THERMAL_PROFILE_REL"
printf '%s\n' "PROFILE_BUILD_ID=$THERMAL_PROFILE_BUILD_ID"
printf '%s\n' "PROFILE_CHANNEL=$THERMAL_PROFILE_CHANNEL"
printf '%s\n' "THERMAL_JSON_COUNT=$SOURCE_FILES"
printf '%s\n' "POLLING_SOURCE_300000=$SOURCE_POLLING_TOTAL"
printf '%s\n' "POLLING_REPLACEMENTS=$REPLACEMENTS_TOTAL"
printf '%s\n' "POLLING_OUTPUT_5000=$OUTPUT_POLLING_5000_TOTAL"
printf '%s\n' "HOTTHRESHOLD_VALUES_CHANGED=$HOT_VALUES_TOTAL"
printf '%s\n' "PATCH_MANIFEST=$GUARD_DIR/patch-manifest.tsv"
trap - EXIT HUP INT TERM
exit 0
