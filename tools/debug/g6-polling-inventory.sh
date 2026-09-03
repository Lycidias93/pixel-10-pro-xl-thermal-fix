#!/system/bin/sh
# Read-only Tensor G6 Thermal polling inventory.
# Maps every PollingDelay to the nearest enclosing sensor Name without
# changing stock files, module configuration, or runtime state.
set -eu

ID="pixel-10-pro-xl-thermal-fix"
MODDIR="${THERMAL_MODDIR:-/data/adb/modules/$ID}"
DATA_ROOT="${THERMAL_DATA_ROOT:-/data/adb/$ID}"
LAYOUT_HELPER="${THERMAL_LAYOUT_HELPER:-$MODDIR/tools/core/thermal-layout.sh}"

DEVICE="${THERMAL_DEVICE:-$(getprop ro.product.device 2>/dev/null || true)}"
BUILD_ID="${THERMAL_BUILD_ID:-$(getprop ro.build.id 2>/dev/null || true)}"
SOURCE_DIR="${1:-${THERMAL_SOURCE_DIR:-}}"

[ -n "$DEVICE" ] || DEVICE=unknown
[ -n "$BUILD_ID" ] || BUILD_ID=unknown
[ -r "$LAYOUT_HELPER" ] || {
  printf '%s\n' G6_POLLING_INVENTORY=fail G6_POLLING_REASON=thermal_layout_helper_missing
  exit 20
}
. "$LAYOUT_HELPER"

thermal_layout_is_g6_device "$DEVICE" || {
  printf '%s\n' G6_POLLING_INVENTORY=fail G6_POLLING_REASON=not_tensor_g6_device "G6_POLLING_DEVICE=$DEVICE"
  exit 21
}

if [ -z "$SOURCE_DIR" ]; then
  BUILD_SLUG="$(printf '%s' "$BUILD_ID" | tr -c 'A-Za-z0-9._-' '_')"
  SOURCE_DIR="$DATA_ROOT/originals/$DEVICE/$BUILD_SLUG/vendor/etc"
fi

[ -d "$SOURCE_DIR" ] || {
  printf '%s\n' G6_POLLING_INVENTORY=fail G6_POLLING_REASON=stock_cache_missing "G6_POLLING_SOURCE_DIR=$SOURCE_DIR"
  exit 22
}

thermal_layout_detect "$SOURCE_DIR" "$DEVICE" || {
  printf '%s\n' G6_POLLING_INVENTORY=fail G6_POLLING_REASON=layout_detection_failed
  exit 23
}
[ "${THERMAL_LAYOUT_FAMILY:-}" = include_graph_g6 ] || {
  printf '%s\n' G6_POLLING_INVENTORY=fail G6_POLLING_REASON=unexpected_layout_family "G6_POLLING_LAYOUT_FAMILY=${THERMAL_LAYOUT_FAMILY:-unknown}"
  exit 24
}

TMP_BASE="${TMPDIR:-/data/local/tmp}"
[ -d "$TMP_BASE" ] && [ -w "$TMP_BASE" ] || TMP_BASE=/data/local/tmp
TMP_FILE="$TMP_BASE/g6-polling-inventory.$$"
cleanup() { rm -f "$TMP_FILE" 2>/dev/null || true; }
trap cleanup EXIT HUP INT TERM

awk '
function basename_of(path, out) {
  out=path
  sub(/^.*\//, "", out)
  return out
}
function classify(name, upper) {
  upper=toupper(name)
  if (name == "VIRTUAL-SKIN") return "direct_virtual_skin"
  if (upper ~ /(EMERGENCY|SHUTDOWN|WARNING|OVER-35C|CHARG|USB)/) return "safety_or_protection"
  if (upper ~ /(MODEL|PREDICTION|FORECAST|LEGACY|ODPM|VIRTUAL-SKIN-)/) return "derived_or_model"
  return "unclassified"
}
function nearest_name(d, i) {
  for (i=d; i>=1; i--) if (obj_name[i] != "") return obj_name[i]
  return ""
}
function clear_deeper(d, i) {
  for (i=d+1; i<=max_depth; i++) delete obj_name[i]
  if (max_depth > d) max_depth=d
}
FNR == 1 {
  depth=0
  max_depth=0
  delete obj_name
}
{
  text=$0
  pos=1
  while (pos <= length(text)) {
    rest=substr(text,pos)
    ch=substr(text,pos,1)

    if (ch == "{") {
      depth++
      if (depth > max_depth) max_depth=depth
      pos++
      continue
    }
    if (ch == "}") {
      delete obj_name[depth]
      depth--
      if (depth < 0) depth=0
      clear_deeper(depth)
      pos++
      continue
    }
    if (match(rest, /^"Name"[[:space:]]*:[[:space:]]*"[^"]*"/)) {
      token=substr(rest,RSTART,RLENGTH)
      value=token
      sub(/^"Name"[[:space:]]*:[[:space:]]*"/, "", value)
      sub(/"$/, "", value)
      obj_name[depth]=value
      pos += RLENGTH
      continue
    }
    if (match(rest, /^"PollingDelay"[[:space:]]*:[[:space:]]*[0-9]+/)) {
      token=substr(rest,RSTART,RLENGTH)
      value=token
      sub(/^"PollingDelay"[[:space:]]*:[[:space:]]*/, "", value)
      sensor=nearest_name(depth)
      if (sensor == "") {
        sensor="__UNMAPPED__"
        unmapped++
      }
      class=classify(sensor)
      total++
      if (value == 300000) p300++
      printf "ROW\t%s\t%s\t%s\t%s\tblocked_pending_review\n", basename_of(FILENAME), sensor, value, class
      pos += RLENGTH
      continue
    }
    pos++
  }
}
END {
  printf "SUMMARY\t%d\t%d\t%d\n", total+0, p300+0, unmapped+0
}
' $(
  for file in $THERMAL_LAYOUT_FILES; do
    printf '%s\n' "$SOURCE_DIR/$file"
  done
) > "$TMP_FILE"

SUMMARY="$(awk -F '\t' '$1=="SUMMARY"{print $2 "\t" $3 "\t" $4}' "$TMP_FILE")"
[ -n "$SUMMARY" ] || {
  printf '%s\n' G6_POLLING_INVENTORY=fail G6_POLLING_REASON=summary_missing
  exit 25
}
TAB="$(printf '\t')"
OLD_IFS="$IFS"
IFS="$TAB"
set -- $SUMMARY
IFS="$OLD_IFS"
ENTRY_COUNT="${1:-0}"
P300_COUNT="${2:-0}"
UNMAPPED_COUNT="${3:-0}"

printf '%s\n' \
  'G6_POLLING_INVENTORY_SCHEMA=v1' \
  "G6_POLLING_DEVICE=$DEVICE" \
  "G6_POLLING_BUILD_ID=$BUILD_ID" \
  "G6_POLLING_LAYOUT_FAMILY=$THERMAL_LAYOUT_FAMILY" \
  "G6_POLLING_LAYOUT_COUNT=$THERMAL_LAYOUT_COUNT" \
  'G6_POLLING_FAST_ADMISSION=blocked_pending_review' \
  'G6_POLLING_COLUMNS=file,sensor,polling_delay,class,admission'

awk -F '\t' '$1=="ROW"{printf "G6_POLLING_ROW file=%s sensor=%s polling_delay=%s class=%s admission=%s\n",$2,$3,$4,$5,$6}' "$TMP_FILE"

printf '%s\n' \
  "G6_POLLING_ENTRY_COUNT=$ENTRY_COUNT" \
  "G6_POLLING_300000_COUNT=$P300_COUNT" \
  "G6_POLLING_UNMAPPED_COUNT=$UNMAPPED_COUNT"

case "$ENTRY_COUNT" in ''|*[!0-9]*) exit 26 ;; esac
case "$P300_COUNT" in ''|*[!0-9]*) exit 26 ;; esac
case "$UNMAPPED_COUNT" in ''|*[!0-9]*) exit 26 ;; esac
[ "$ENTRY_COUNT" -gt 0 ] 2>/dev/null || {
  printf '%s\n' G6_POLLING_INVENTORY=fail G6_POLLING_REASON=no_polling_entries
  exit 27
}
[ "$UNMAPPED_COUNT" -eq 0 ] 2>/dev/null || {
  printf '%s\n' G6_POLLING_INVENTORY=fail G6_POLLING_REASON=unmapped_polling_entries
  exit 28
}

printf 'RESULT: G6_POLLING_INVENTORY_PASS device=%s files=%s entries=%s stock300000=%s fast_admission=blocked_pending_review\n' \
  "$DEVICE" "$THERMAL_LAYOUT_COUNT" "$ENTRY_COUNT" "$P300_COUNT"
