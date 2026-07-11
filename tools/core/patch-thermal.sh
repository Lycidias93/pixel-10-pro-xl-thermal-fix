#!/system/bin/sh
# Pixel 10 Thermal Fix - Dynamic JSON Patcher Orchestrator
# POSIX compliant awk stream editing for toolbox compatibility.
set -eu

POLLING_MODE="${1:-mod}"      # "stock" or "mod"
OUTDOOR_PROFILE="${2:-stock}" # "stock", "outdoor-safe", "outdoor-plus", "outdoor-extended"
MODPATH="${3:-/data/adb/modules/pixel-10-pro-xl-thermal-fix}"

ORIGINALS_DIR="/data/adb/pixel-10-pro-xl-thermal-fix/originals"
TARGET_DIR="$MODPATH/system/vendor/etc"

# Create directories
mkdir -p "$ORIGINALS_DIR"
mkdir -p "$TARGET_DIR"

# Determine temperature delta
delta=0
case "$OUTDOOR_PROFILE" in
  outdoor-safe) delta=1 ;;
  outdoor-plus) delta=2 ;;
  outdoor-extended) delta=3 ;;
  *) delta=0 ;;
esac

# List of files to check and process
FILES="
thermal_info_config.json
thermal_info_config_bg_tasks_throttling.json
thermal_info_config_charge.json
thermal_info_config_earlywarnings.json
thermal_info_config_lpm.json
thermal_info_config_stats.json
thermal_info_config_throttling.json
"

# Find source directory
SRC_DIR=""
for d in /vendor/etc /system/vendor/etc; do
  if [ -r "$d/thermal_info_config_throttling.json" ]; then
    SRC_DIR="$d"
    break
  fi
done

if [ -z "$SRC_DIR" ]; then
  echo "Error: Stock thermal files not found in /vendor/etc or /system/vendor/etc" >&2
  exit 1
fi

echo "- Source directory: $SRC_DIR"
echo "- Polling mode: $POLLING_MODE"
echo "- Outdoor profile: $OUTDOOR_PROFILE"

for f in $FILES; do
  src_file="$SRC_DIR/$f"
  if [ ! -r "$src_file" ]; then
    # Some files might not exist on all builds, skip them silently
    echo "  (Skipping non-existent/unreadable file: $f)"
    continue
  fi
  
  # 1. Copy stock file to originals temp directory
  orig_file="$ORIGINALS_DIR/$f"
  cp -fp "$src_file" "$orig_file"
  
  # 2. Run awk patch from originals to target directory
  out_file="$TARGET_DIR/$f"
  echo "  Processing: $f -> $out_file"
  
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
        gsub(/"PollingDelay":300000/, "\"PollingDelay\":5000")
        gsub(/"PollingDelay": 300000/, "\"PollingDelay\": 5000")
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
  ' "$orig_file" > "$out_file"
  
  chmod 0644 "$out_file" 2>/dev/null || true
done

echo "Dynamic patching complete!"
