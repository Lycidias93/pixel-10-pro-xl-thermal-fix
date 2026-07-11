#!/system/bin/sh
# Pixel 10 Thermal Fix - Dynamic JSON Patcher Orchestrator
# POSIX compliant awk stream editing for toolbox compatibility.
set -eu

POLLING_MODE="${1:-mod}"      # "stock" or "mod"
OUTDOOR_PROFILE="${2:-stock}" # "stock", "outdoor-safe", "outdoor-plus", "outdoor-extended"
MODPATH="${3:-/data/adb/modules/pixel-10-pro-xl-thermal-fix}"

ORIGINALS_DIR="/data/adb/pixel-10-pro-xl-thermal-fix/originals"
PATCHED_TEMP_DIR="/data/adb/pixel-10-pro-xl-thermal-fix/patched_temp"
TARGET_DIR="$MODPATH/system/vendor/etc"

# Ensure directories are clean
# 7. Make sure the original files dir is clean or removed and recreated when starting a new patching process.
rm -rf "$ORIGINALS_DIR" "$PATCHED_TEMP_DIR"
mkdir -p "$ORIGINALS_DIR" "$PATCHED_TEMP_DIR"
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

get_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" 2>/dev/null | awk '{print $1}'
  elif [ -x /data/adb/magisk/busybox ]; then
    /data/adb/magisk/busybox sha256sum "$1" 2>/dev/null | awk '{print $1}'
  else
    echo "unknown"
  fi
}

count_polling_delays() {
  file="$1"
  pattern="$2"
  awk -v pat="$pattern" '
    BEGIN { total = 0 }
    {
      s = $0
      while (match(s, pat)) {
        total++
        s = substr(s, RSTART + RLENGTH)
      }
    }
    END { print total }
  ' "$file"
}

# Initialize verification
valid_files=""
validation_failed=0

# JSON report builder
json_content="{"
first_file=1

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
  
  # Compute original hash & count (only checking "PollingDelay": 300000 / "PollingDelay":300000)
  sha_orig=$(get_sha256 "$orig_file")
  count_orig=$(count_polling_delays "$orig_file" '"PollingDelay"[[:space:]]*:[[:space:]]*300000')
  
  # 2. Run awk patch from originals to temp directory
  temp_out_file="$PATCHED_TEMP_DIR/$f"
  echo "  Processing: $f -> $temp_out_file"
  
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
  ' "$orig_file" > "$temp_out_file"
  
  # Compute modded hash & count (checking "PollingDelay": 5000 / "PollingDelay":5000)
  sha_mod=$(get_sha256 "$temp_out_file")
  count_mod=$(count_polling_delays "$temp_out_file" '"PollingDelay"[[:space:]]*:[[:space:]]*5000')
  
  # Verification check
  file_status="passed"
  if [ "$POLLING_MODE" = "mod" ]; then
    if [ "$count_orig" -ne "$count_mod" ]; then
      echo "  [VALIDATION FAILED] $f: Original 300000 count ($count_orig) does not match patched 5000 count ($count_mod)!" >&2
      file_status="failed"
      validation_failed=1
    fi
  fi
  
  # Append to JSON string
  if [ "$first_file" -eq 1 ]; then
    first_file=0
  else
    json_content="$json_content,"
  fi
  
  json_content="$json_content
  \"$f\": {
    \"original_sha256\": \"$sha_orig\",
    \"original_polling_count\": $count_orig,
    \"patched_sha256\": \"$sha_mod\",
    \"patched_polling_count\": $count_mod,
    \"validation\": \"$file_status\"
  }"
  
  valid_files="$valid_files $f"
done

json_content="$json_content
}"

# Write report
echo "$json_content" > "$MODPATH/validation_report.json"
mkdir -p "/data/adb/pixel-10-pro-xl-thermal-fix" 2>/dev/null || true
echo "$json_content" > "/data/adb/pixel-10-pro-xl-thermal-fix/validation_report.json" 2>/dev/null || true

# Validate status
if [ "$validation_failed" -ne 0 ]; then
  echo "Error: Verification failed for one or more files! Not moving files to target directory." >&2
  rm -rf "$PATCHED_TEMP_DIR"
  exit 1
fi

echo "Validation passed! Moving patched files to $TARGET_DIR..."
for f in $valid_files; do
  cp -fp "$PATCHED_TEMP_DIR/$f" "$TARGET_DIR/$f"
  chmod 0644 "$TARGET_DIR/$f" 2>/dev/null || true
done

# Cleanup temp dir
rm -rf "$PATCHED_TEMP_DIR"

echo "Dynamic patching complete!"

