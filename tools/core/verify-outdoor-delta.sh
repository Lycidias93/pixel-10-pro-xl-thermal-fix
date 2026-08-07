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
  function trim(v) {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
    return v
  }
  function target_name(line,    name) {
    if ((line ~ /"Name"[[:space:]]*:[[:space:]]*"VIRTUAL-SKIN/ ||
         line ~ /"Name"[[:space:]]*:[[:space:]]*"cellular-emergency/) &&
        line !~ /OVER-35C/) {
      match(line, /"Name"[[:space:]]*:[[:space:]]*"[^"]+"/)
      name = substr(line, RSTART, RLENGTH)
      sub(/^.*:[[:space:]]*"/, "", name)
      sub(/"$/, "", name)
      return name
    }
    return ""
  }
  function is_numeric(v) {
    return v ~ /^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)([eE][+-]?[0-9]+)?$/
  }
  function is_sentinel(v) {
    return toupper(v) == "\"NAN\""
  }
  function clear_parsed(    k) {
    for (k in parsed) delete parsed[k]
  }
  function append_buf(buf, part) {
    return buf == "" ? part : buf "\n" part
  }
  function record_source(name, buf,    n, i) {
    clear_parsed()
    n = split(buf, parsed, ",")
    if (n < 1) {
      bad = 1
      return
    }
    source_arrays++
    source_name[source_arrays] = name
    source_count[source_arrays] = n
    for (i = 1; i <= n; i++) {
      parsed[i] = trim(parsed[i])
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
  }
  function compare_output(name, buf,    n, i, expected) {
    clear_parsed()
    n = split(buf, parsed, ",")
    if (n < 1) {
      bad = 1
      return
    }
    output_arrays++
    if (output_arrays > source_arrays) bad = 1
    if (name != source_name[output_arrays]) bad = 1
    if (n != source_count[output_arrays]) bad = 1
    for (i = 1; i <= n; i++) {
      parsed[i] = trim(parsed[i])
      if (source_kind[output_arrays, i] == "numeric") {
        if (!is_numeric(parsed[i])) {
          bad = 1
        } else {
          expected = source_value[output_arrays, i] + delta
          if ((parsed[i] + 0) != expected) bad = 1
        }
      } else if (source_kind[output_arrays, i] == "sentinel") {
        if (parsed[i] != source_raw[output_arrays, i]) bad = 1
      } else {
        bad = 1
      }
      output_values++
    }
  }
  function consume_source(line,    name, open, closing, rest, part) {
    if (!source_in_array) {
      name = target_name(line)
      if (name != "") {
        source_target = 1
        current_source_name = name
      } else if (line ~ /"Name"[[:space:]]*:/) {
        source_target = 0
        current_source_name = ""
      }
      if (source_target && line ~ /"HotThreshold"[[:space:]]*:/) {
        source_declarations++
        open = index(line, "[")
        if (open < 1) {
          bad = 1
          return
        }
        source_in_array = 1
        source_array_name = current_source_name
        source_buf = ""
        rest = substr(line, open + 1)
        closing = index(rest, "]")
        if (closing > 0) {
          part = substr(rest, 1, closing - 1)
          source_buf = append_buf(source_buf, part)
          record_source(source_array_name, source_buf)
          source_in_array = 0
          source_target = 0
          current_source_name = ""
          source_buf = ""
        } else {
          source_buf = append_buf(source_buf, rest)
        }
      }
      return
    }
    closing = index(line, "]")
    if (closing > 0) {
      part = substr(line, 1, closing - 1)
      source_buf = append_buf(source_buf, part)
      record_source(source_array_name, source_buf)
      source_in_array = 0
      source_target = 0
      current_source_name = ""
      source_buf = ""
    } else {
      source_buf = append_buf(source_buf, line)
    }
  }
  function consume_output(line,    name, open, closing, rest, part) {
    if (!output_in_array) {
      name = target_name(line)
      if (name != "") {
        output_target = 1
        current_output_name = name
      } else if (line ~ /"Name"[[:space:]]*:/) {
        output_target = 0
        current_output_name = ""
      }
      if (output_target && line ~ /"HotThreshold"[[:space:]]*:/) {
        output_declarations++
        open = index(line, "[")
        if (open < 1) {
          bad = 1
          return
        }
        output_in_array = 1
        output_array_name = current_output_name
        output_buf = ""
        rest = substr(line, open + 1)
        closing = index(rest, "]")
        if (closing > 0) {
          part = substr(rest, 1, closing - 1)
          output_buf = append_buf(output_buf, part)
          compare_output(output_array_name, output_buf)
          output_in_array = 0
          output_target = 0
          current_output_name = ""
          output_buf = ""
        } else {
          output_buf = append_buf(output_buf, rest)
        }
      }
      return
    }
    closing = index(line, "]")
    if (closing > 0) {
      part = substr(line, 1, closing - 1)
      output_buf = append_buf(output_buf, part)
      compare_output(output_array_name, output_buf)
      output_in_array = 0
      output_target = 0
      current_output_name = ""
      output_buf = ""
    } else {
      output_buf = append_buf(output_buf, line)
    }
  }

  FNR == NR {
    consume_source($0)
    next
  }
  {
    consume_output($0)
  }
  END {
    if (source_in_array || output_in_array) bad = 1
    if (source_declarations != source_arrays) bad = 1
    if (output_declarations != output_arrays) bad = 1
    if (source_declarations != output_declarations) bad = 1
    if (source_arrays != output_arrays) bad = 1
    if (source_values != output_values) bad = 1
    if (bad) exit 1
    printf "%d %d %d\n", source_declarations, source_arrays, source_values
  }
' "$SOURCE_FILE" "$OUTPUT_FILE"
