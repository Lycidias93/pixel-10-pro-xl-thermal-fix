#!/system/bin/sh
MODDIR=${0%/*}
CONFIG_DIR="/data/adb/pixel-10-pro-xl-thermal-fix"
CONFIG_FILE="$CONFIG_DIR/config.env"

cfg_set() {
  k="$1"
  v="$2"
  mkdir -p "$CONFIG_DIR" 2>/dev/null || true
  touch "$CONFIG_FILE" 2>/dev/null || true
  tmp="$CONFIG_FILE.tmp.$$"
  grep -v "^${k}=" "$CONFIG_FILE" 2>/dev/null > "$tmp" || true
  printf '%s=%s\n' "$k" "$v" >> "$tmp"
  mv "$tmp" "$CONFIG_FILE"
  chmod 0600 "$CONFIG_FILE" 2>/dev/null || true
}

msg() {
  if command -v ui_print >/dev/null 2>&1; then
    ui_print "$*"
  else
    echo "$*"
  fi
}

check_supported() {
  local dev="$(getprop ro.product.device)"
  local android="$(getprop ro.build.version.release)"
  local bid="$1"
  local json="$MODDIR/supported_versions.json"
  [ -f "$json" ] || return 1
  
  local res
  res=$(awk -v dev="$dev" -v android="$android" -v bid="$bid" '
    BEGIN { found_dev = 0; found_android = 0; supported = 0 }
    index($0, "\"" dev "\"") && index($0, "{") { found_dev = 1; next }
    found_dev && index($0, "\"" android "\"") && index($0, "[") { found_android = 1; next }
    found_android && index($0, "]") { found_android = 0 }
    found_dev && !found_android && index($0, "}") { found_dev = 0 }
    found_dev && found_android && index($0, "\"" bid "\"") { supported = 1; exit }
    END { print supported }
  ' "$json")
  [ "$res" = "1" ]
}

curr_bid="$(getprop ro.build.id)"
inst_bid="none"
if [ -f "$MODDIR/install-state.txt" ]; then
  inst_bid="$(grep -E "^build_id=" "$MODDIR/install-state.txt" 2>/dev/null | tail -n 1 | cut -d= -f2 | tr -d '\r')"
fi
[ -n "$inst_bid" ] || inst_bid="none"

if [ "$curr_bid" != "$inst_bid" ]; then
  msg "OTA / Build change detected: current='$curr_bid', installed='$inst_bid'"
  
  # Check if current build is supported locally
  is_supported=0
  if check_supported "$curr_bid"; then
    is_supported=1
  fi
  
  if [ "$is_supported" -eq 0 ]; then
    msg "Build ID '$curr_bid' is not in local database. Checking for updates..."
    
    TMP_JSON="/data/local/tmp/supported_versions_download.json"
    rm -f "$TMP_JSON"
    
    download_supported_versions() {
      url="https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/refs/heads/v2/supported_versions.json"
      dest="$1"
      if command -v curl >/dev/null 2>&1; then
        curl -fsSL --connect-timeout 5 --max-time 10 "$url" -o "$dest"
        return $?
      elif command -v wget >/dev/null 2>&1; then
        wget -T 5 -t 1 "$url" -O "$dest"
        return $?
      elif [ -x /data/adb/magisk/busybox ]; then
        /data/adb/magisk/busybox wget -T 5 -t 1 "$url" -O "$dest"
        return $?
      else
        return 1
      fi
    }
    
    if download_supported_versions "$TMP_JSON" && [ -s "$TMP_JSON" ]; then
      msg "- Update successful! Applying new supported_versions.json..."
      cp -p "$TMP_JSON" "$MODDIR/supported_versions.json" 2>/dev/null || true
      rm -f "$TMP_JSON"
      
      # Check again with updated json
      if check_supported "$curr_bid"; then
        is_supported=1
      fi
    else
      rm -f "$TMP_JSON"
      msg "! Warning: Internet connection is not established and cannot verify '$curr_bid'."
    fi
  fi
  
  if [ "$is_supported" -eq 1 ]; then
    msg "- Build ID '$curr_bid' is verified. Sourcing and patching thermal files..."
    
    # Read config values
    config_get() {
      key="$1"
      [ -r "$CONFIG_FILE" ] || return 0
      grep -E "^${key}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${key}=//" | tr -d '\r'
    }
    
    THERMAL_POLLING_MODE="$(config_get THERMAL_POLLING_MODE)"
    [ -n "$THERMAL_POLLING_MODE" ] || THERMAL_POLLING_MODE="mod"
    THERMAL_OUTDOOR_PROFILE="$(config_get THERMAL_OUTDOOR_PROFILE)"
    [ -n "$THERMAL_OUTDOOR_PROFILE" ] || THERMAL_OUTDOOR_PROFILE="stock"
    
    # Run patching
    if [ -s "$MODDIR/tools/core/patch-thermal.sh" ]; then
      chmod 0755 "$MODDIR/tools/core/patch-thermal.sh" 2>/dev/null || true
      if sh "$MODDIR/tools/core/patch-thermal.sh" "$THERMAL_POLLING_MODE" "$THERMAL_OUTDOOR_PROFILE" "$MODDIR"; then
        msg "- Patching complete."
        # Update build_id in install-state.txt
        if [ -f "$MODDIR/install-state.txt" ]; then
          tmp_f="$MODDIR/install-state.txt.tmp"
          grep -v "^build_id=" "$MODDIR/install-state.txt" > "$tmp_f" 2>/dev/null || true
          echo "build_id=$curr_bid" >> "$tmp_f"
          mv "$tmp_f" "$MODDIR/install-state.txt"
        fi
        cfg_set THERMAL_DISABLED 0
      else
        msg "! Warning: Patching validation failed. Thermal files removed."
        rm -rf /data/adb/modules/pixel*/system/vendor/etc/thermal_info_config*
        cfg_set THERMAL_DISABLED 1
      fi
    else
      msg "! Warning: patch-thermal.sh is missing."
      cfg_set THERMAL_DISABLED 1
    fi
  else
    msg "----------------------------------------"
    msg "Disclaimer: Build ID '$curr_bid' is unsupported or offline."
    msg "Thermal files will not be patched."
    msg "Only ZRAM optimization is available."
    msg "----------------------------------------"
    sleep 3
    
    # Remove modded files to keep device safe
    rm -rf /data/adb/modules/pixel*/system/vendor/etc/thermal_info_config*
    cfg_set THERMAL_DISABLED 1
  fi
else
  # Build IDs match. Ensure THERMAL_DISABLED is 0 if files exist.
  has_files=0
  for f in thermal_info_config.json thermal_info_config_throttling.json; do
    if [ -s "$MODDIR/system/vendor/etc/$f" ]; then
      has_files=1
    fi
  done
  
  config_get() {
    key="$1"
    [ -r "$CONFIG_FILE" ] || return 0
    grep -E "^${key}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${key}=//" | tr -d '\r'
  }
  
  if [ "$has_files" -eq 1 ]; then
    cfg_set THERMAL_DISABLED 0
  else
    if [ "$(config_get THERMAL_DISABLED)" != "1" ]; then
      cfg_set THERMAL_DISABLED 0
    fi
  fi
fi

# Proceed to load the dashboard as normal
if [ -s "$MODDIR/tools/action-dashboard.sh" ]; then
  sh "$MODDIR/tools/action-dashboard.sh"
elif [ -s "$MODDIR/tools/menu/zram-menu.sh" ]; then
  sh "$MODDIR/tools/menu/zram-menu.sh" action
else
  echo "Action helpers missing."
  exit 1
fi
