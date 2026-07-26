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
    if (line ~ /"Name"[[:space:]]*:[[:space:]]*"VIRTUAL-SKIN-HINT"([[:space:]]*[,}]|[[:space:]]*$)/) return "VIRTUAL-SKIN-HINT"
    if (line ~ /"Name"[[:space:]]*:[[:space:]]*"VIRTUAL-SKIN"([[:space:]]*[,}]|[[:space:]]*$)/) return "VIRTUAL-SKIN"
    return ""
  }
  function is_numeric(value) {
    return value ~ /^[+-]?[0-9]+([.][0-9]+)?$/
  }
  function is_sentinel(value) {
    return value == "\"NAN\""
  }
  function decimal_places(value, dot) {
    dot = index(value, ".")
    return dot > 0 ? length(value) - dot : 0
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
      if (++source_seen[name] != 1) bad = 1
      source_target = 1
      source_name = name
      source_target_declarations++
    } else if ($0 ~ /"Name"[[:space:]]*:/) {
      if (source_target) bad = 1
      source_target = 0
      source_name = ""
    }
    if (source_target && $0 ~ /"HotThreshold"[[:space:]]*:/) {
      source_arrays++
      source_array_name[source_arrays] = source_name
      count = parse_threshold($0, parsed)
      if (count != 7) bad = 1
      source_value_count[source_arrays] = count
      for (i = 1; i <= count; i++) {
        source_raw[source_arrays, i] = parsed[i]
        if (is_numeric(parsed[i])) {
          source_kind[source_arrays, i] = "numeric"
          source_value[source_arrays, i] = parsed[i] + 0
          source_scale[source_arrays, i] = decimal_places(parsed[i])
        } else if (is_sentinel(parsed[i])) {
          source_kind[source_arrays, i] = "sentinel"
        } else {
          bad = 1
        }
        if (i == 7 && (!is_numeric(parsed[i]) || (parsed[i] + 0) > 55.0)) bad = 1
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
      if (++output_seen[name] != 1) bad = 1
      output_target = 1
      output_name = name
      output_target_declarations++
    } else if ($0 ~ /"Name"[[:space:]]*:/) {
      if (output_target) bad = 1
      output_target = 0
      output_name = ""
    }
    if (output_target && $0 ~ /"HotThreshold"[[:space:]]*:/) {
      output_arrays++
      if (output_arrays > source_arrays) bad = 1
      if (output_name != source_array_name[output_arrays]) bad = 1
      count = parse_threshold($0, parsed)
      if (count != 7 || count != source_value_count[output_arrays]) bad = 1
      for (i = 1; i <= count; i++) {
        if (i == 7) {
          if (parsed[i] != source_raw[output_arrays, i]) bad = 1
        } else if (source_kind[output_arrays, i] == "numeric") {
          if (!is_numeric(parsed[i])) bad = 1
          if ((parsed[i] + 0) != (source_value[output_arrays, i] + delta)) bad = 1
          if (decimal_places(parsed[i]) != source_scale[output_arrays, i]) bad = 1
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
    if (source_target || output_target) bad = 1
    if (source_target_declarations != source_arrays) bad = 1
    if (output_target_declarations != output_arrays) bad = 1
    if (source_target_declarations != output_target_declarations) bad = 1
    if (source_arrays != output_arrays) bad = 1
    if (source_values != output_values) bad = 1
    if (source_target_declarations != 0) {
      if (source_seen["VIRTUAL-SKIN"] != 1 || source_seen["VIRTUAL-SKIN-HINT"] != 1) bad = 1
      if (output_seen["VIRTUAL-SKIN"] != 1 || output_seen["VIRTUAL-SKIN-HINT"] != 1) bad = 1
    }
    if (bad) exit 1
    printf "%d %d %d\n", source_target_declarations, source_arrays, source_values
  }
' "$SOURCE_FILE" "$OUTPUT_FILE"
