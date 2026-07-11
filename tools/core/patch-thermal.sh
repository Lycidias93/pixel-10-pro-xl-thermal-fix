#!/system/bin/sh
# Pixel 10 Thermal Fix - Dynamic JSON Patcher
# POSIX compliant awk stream editing for toybox/toolbox compatibility.
set -eu

INPUT_FILE="$1"
OUTPUT_FILE="$2"
POLLING_MODE="${3:-mod}"      # "stock" or "mod"
OUTDOOR_PROFILE="${4:-stock}" # "stock", "outdoor-safe", "outdoor-plus", "outdoor-extended"

if [ ! -r "$INPUT_FILE" ]; then
  echo "Error: Input file '$INPUT_FILE' not readable" >&2
  exit 1
fi

# Determine temperature delta
delta=0
case "$OUTDOOR_PROFILE" in
  outdoor-safe) delta=1 ;;
  outdoor-plus) delta=2 ;;
  outdoor-extended) delta=3 ;;
  *) delta=0 ;;
esac

# Execute awk patching
awk -v delta="$delta" -v poll_mode="$POLLING_MODE" '
  BEGIN {
    in_target = 0
  }
  # Identify target sensor name block
  /"Name"[[:space:]]*:[[:space:]]*"VIRTUAL-SKIN"/ || /"Name"[[:space:]]*:[[:space:]]*"VIRTUAL-SKIN-HINT"/ {
    in_target = 1
  }
  # Reset state if we find a different sensor Name
  /"Name"[[:space:]]*:/ && !(/"VIRTUAL-SKIN"/ || /"VIRTUAL-SKIN-HINT"/) {
    in_target = 0
  }
  # Replace PollingDelay if polling mode is mod
  {
    if (poll_mode == "mod") {
      gsub(/"PollingDelay"[[:space:]]*:[[:space:]]*300000/, "\"PollingDelay\": 5000")
      gsub(/"PollingDelay"[[:space:]]*:[[:space:]]*300000,/, "\"PollingDelay\": 5000,")
    }
  }
  # Patch HotThreshold if we are in target sensor
  in_target && /"HotThreshold"[[:space:]]*:/ {
    start = index($0, "[")
    end = index($0, "]")
    if (start > 0 && end > start && delta != 0) {
      prefix = substr($0, 1, start)
      suffix = substr($0, end)
      array_content = substr($0, start + 1, end - start - 1)
      
      n = split(array_content, elements, ",")
      new_array = ""
      for (i = 1; i <= n; i++) {
        elem = elements[i]
        # Trim leading/trailing whitespace
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", elem)
        
        # Check if numeric (integer or decimal float)
        if (elem ~ /^[+-]?[0-9.]+$/) {
          val = elem + delta
          new_array = new_array val
        } else {
          new_array = new_array elem
        }
        if (i < n) {
          new_array = new_array ", "
        }
      }
      $0 = prefix new_array suffix
    }
    in_target = 0 # reset after patching HotThreshold
  }
  {
    print
  }
' "$INPUT_FILE" > "$OUTPUT_FILE"
