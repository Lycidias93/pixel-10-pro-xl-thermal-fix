#!/system/bin/sh
set -eu

SOURCE_FILE="${1:-}"
OUTPUT_FILE="${2:-}"
EXPECTED_DELTA="${3:-}"

[ -s "$SOURCE_FILE" ] || exit 2
[ -s "$OUTPUT_FILE" ] || exit 3
case "$EXPECTED_DELTA" in
  0|1|2|3) ;;
  *) exit 4 ;;
esac

awk -v delta="$EXPECTED_DELTA" '
  function trim(value) {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
    return value
  }
  function target_name(line) {
    if (line ~ /"Name"[[:space:]]*:[[:space:]]*"VIRTUAL-SKIN-HINT"/) return "VIRTUAL-SKIN-HINT"
    if (line ~ /"Name"[[:space:]]*:[[:space:]]*"VIRTUAL-SKIN"/) return "VIRTUAL-SKIN"
    return ""
  }
  function is_numeric(value) {
    return value ~ /^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)([eE][+-]?[0-9]+)?$/
  }
  function is_sentinel(value) {
    return value == "\"NAN\""
  }
  function parse_threshold(line, values,    start, finish, content, count, i) {
    start = index(line, "[")
    finish = index(line, "]")
    if (start < 1 || finish <= start) return -1
    content = substr(line, start + 1, finish - start - 1)
    count = split(content, values, ",")
    for (i = 1; i <= count; i++) values[i] = trim(values[i])
    return count
  }
  FNR == NR {
    name = target_name($0)
    if (name != "") {
      source_target = 1
      source_name = name
    } else if ($0 ~ /"Name"[[:space:]]*:/) {
      source_target = 0
      source_name = ""
    }
    if (source_target && $0 ~ /"HotThreshold"[[:space:]]*:/) {
      source_arrays++
      source_zones++
      source_array_name[source_arrays] = source_name
      count = parse_threshold($0, parsed)
      if (count < 1) bad = 1
      source_value_count[source_arrays] = count
      for (i = 1; i <= count; i++) {
        if (is_numeric(parsed[i])) {
          source_kind[source_arrays, i] = "numeric"
          source_value[source_arrays, i] = parsed[i] + 0
        } else if (is_sentinel(parsed[i])) {
          source_kind[source_arrays, i] = "sentinel"
          source_raw[source_arrays, i] = parsed[i]
        } else {
          bad = 1
        }
        source_values++
      }
      source_target = 0
      source_name = ""
    }
    next
  }
  {
    name = target_name($0)
    if (name != "") {
      output_target = 1
      output_name = name
    } else if ($0 ~ /"Name"[[:space:]]*:/) {
      output_target = 0
      output_name = ""
    }
    if (output_target && $0 ~ /"HotThreshold"[[:space:]]*:/) {
      output_arrays++
      output_zones++
      if (output_arrays > source_arrays) bad = 1
      if (output_name != source_array_name[output_arrays]) bad = 1
      count = parse_threshold($0, parsed)
      if (count < 1 || count != source_value_count[output_arrays]) bad = 1
      for (i = 1; i <= count; i++) {
        if (source_kind[output_arrays, i] == "numeric") {
          if (!is_numeric(parsed[i])) bad = 1
          if ((parsed[i] + 0) != (source_value[output_arrays, i] + delta)) bad = 1
        } else if (source_kind[output_arrays, i] == "sentinel") {
          if (parsed[i] != source_raw[output_arrays, i]) bad = 1
        } else {
          bad = 1
        }
        output_values++
      }
      output_target = 0
      output_name = ""
    }
  }
  END {
    if (source_arrays < 1 || source_values < 1) bad = 1
    if (source_zones != source_arrays) bad = 1
    if (output_zones != output_arrays) bad = 1
    if (source_arrays != output_arrays) bad = 1
    if (source_values != output_values) bad = 1
    if (bad) exit 1
    printf "%d %d %d\n", source_zones, source_arrays, source_values
  }
' "$SOURCE_FILE" "$OUTPUT_FILE"
