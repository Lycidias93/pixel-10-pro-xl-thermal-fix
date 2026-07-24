#!/system/bin/sh
MODDIR=${0%/*}
ID="pixel-10-pro-xl-thermal-fix"
CONFIG_DIR="/data/adb/$ID"
CONFIG_FILE="$CONFIG_DIR/config.env"
SUPPORTED_HELPER="$MODDIR/tools/core/supported-build.sh"
SUPPORTED_JSON="$MODDIR/supported_versions.json"

cfg_get() {
  key="$1"
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^${key}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${key}=//" | tr -d '\r'
}
cfg_set() {
  key="$1"
  value="$2"
  mkdir -p "$CONFIG_DIR" 2>/dev/null || true
  touch "$CONFIG_FILE" 2>/dev/null || true
  tmp="$CONFIG_FILE.tmp.$$"
  grep -v "^${key}=" "$CONFIG_FILE" 2>/dev/null > "$tmp" || true
  printf '%s=%s\n' "$key" "$value" >> "$tmp"
  mv "$tmp" "$CONFIG_FILE"
  chmod 0600 "$CONFIG_FILE" 2>/dev/null || true
}
msg() {
  if command -v ui_print >/dev/null 2>&1; then ui_print "$*"; else echo "$*"; fi
}
remove_thermal_overlay() {
  rm -f "$MODDIR/system/vendor/etc"/thermal_info_config*.json 2>/dev/null || true
}
update_install_state_build() {
  [ -f "$MODDIR/install-state.txt" ] || return 0
  tmp="$MODDIR/install-state.txt.tmp.$$"
  grep -v -E '^(build_id|profile_materialized|expected_thermal_files)=' "$MODDIR/install-state.txt" > "$tmp" 2>/dev/null || true
  printf '%s\n' "build_id=$CURRENT_BUILD" >> "$tmp"
  printf '%s\n' "profile_materialized=yes" >> "$tmp"
  printf '%s\n' "expected_thermal_files=dynamic_validated" >> "$tmp"
  mv "$tmp" "$MODDIR/install-state.txt"
}

[ -r "$SUPPORTED_HELPER" ] || {
  msg "! supported-build helper missing"
  cfg_set THERMAL_DISABLED 1
  remove_thermal_overlay
}
[ -r "$SUPPORTED_HELPER" ] && . "$SUPPORTED_HELPER"

CURRENT_DEVICE="$(getprop ro.product.device 2>/dev/null || true)"
CURRENT_ANDROID="$(getprop ro.build.version.release 2>/dev/null || true)"
CURRENT_BUILD="$(getprop ro.build.id 2>/dev/null || true)"
INSTALLED_BUILD="none"
[ -r "$MODDIR/install-state.txt" ] &&
  INSTALLED_BUILD="$(grep -E '^build_id=' "$MODDIR/install-state.txt" 2>/dev/null | tail -n 1 | cut -d= -f2 | tr -d '\r')"
[ -n "$INSTALLED_BUILD" ] || INSTALLED_BUILD=none

is_supported=0
if [ -r "$SUPPORTED_HELPER" ] &&
   thermal_supported_check "$SUPPORTED_JSON" "$CURRENT_DEVICE" "$CURRENT_ANDROID" "$CURRENT_BUILD"; then
  is_supported=1
fi

if [ "$is_supported" -eq 0 ] && [ -r "$SUPPORTED_HELPER" ]; then
  msg "- Build not supported locally; checking immutable V2 commit..."
  if thermal_supported_refresh_for_current "$MODDIR" "$CURRENT_DEVICE" "$CURRENT_ANDROID" "$CURRENT_BUILD" "$ID" >/dev/null 2>&1; then
    msg "- Support database refreshed and verified"
    is_supported=1
  else
    msg "! Build remains unsupported or network verification failed"
  fi
fi

needs_materialize=0
[ "$CURRENT_BUILD" = "$INSTALLED_BUILD" ] || needs_materialize=1
[ "$(cfg_get THERMAL_DISABLED)" = 1 ] && needs_materialize=1
for required in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
  [ -s "$MODDIR/system/vendor/etc/$required" ] || needs_materialize=1
done

if [ "$is_supported" -eq 1 ]; then
  if [ "$needs_materialize" -eq 1 ]; then
    msg "- Verified build; materializing and validating thermal overlay"
    polling="$(cfg_get THERMAL_POLLING_MODE)"
    outdoor="$(cfg_get THERMAL_OUTDOOR_PROFILE)"
    [ -n "$polling" ] || polling=mod
    [ -n "$outdoor" ] || outdoor=stock
    if [ -s "$MODDIR/tools/core/patch-thermal-validated.sh" ] &&
       sh "$MODDIR/tools/core/patch-thermal-validated.sh" "$polling" "$outdoor" "$MODDIR"; then
      cfg_set THERMAL_DISABLED 0
      cfg_set CANARY_DIAGNOSTIC_MODE 0
      rm -f "$MODDIR/skip_mount" "$MODDIR/guard/disabled_reason" 2>/dev/null || true
      update_install_state_build
      msg "- Thermal materialization and outdoor delta validation passed"
    else
      remove_thermal_overlay
      cfg_set THERMAL_DISABLED 1
      msg "! Thermal materialization or outdoor delta validation failed; ZRAM remains available"
    fi
  fi
else
  remove_thermal_overlay
  cfg_set THERMAL_DISABLED 1
  msg "! Thermal disabled for unsupported build"
  msg "- ZRAM remains available"
fi

if [ -s "$MODDIR/tools/action-dashboard.sh" ]; then
  sh "$MODDIR/tools/action-dashboard.sh"
elif [ -s "$MODDIR/tools/menu/zram-menu.sh" ]; then
  sh "$MODDIR/tools/menu/zram-menu.sh" action
else
  msg "! Action helpers missing"
  exit 1
fi
