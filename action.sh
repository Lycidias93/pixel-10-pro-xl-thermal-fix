#!/system/bin/sh
set -eu

MODDIR=${0%/*}
ID="pixel-10-pro-xl-thermal-fix"
CONFIG_DIR="/data/adb/$ID"
CONFIG_FILE="$CONFIG_DIR/config.env"
SUPPORTED_HELPER="$MODDIR/tools/core/supported-build.sh"
SUPPORTED_JSON="$MODDIR/supported_versions.json"
INSTALL_STATE="$MODDIR/install-state.txt"

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
  evidence="$1"
  [ -f "$INSTALL_STATE" ] || return 0
  tmp="$INSTALL_STATE.tmp.$$"
  grep -v -E '^(build_id|profile|profile_state|build_guard_mode|build_evidence|profile_materialized|expected_thermal_files)=' "$INSTALL_STATE" > "$tmp" 2>/dev/null || true
  printf '%s\n' "build_id=$CURRENT_BUILD" >> "$tmp"
  printf '%s\n' "profile=dynamic/$CURRENT_DEVICE/android$CURRENT_ANDROID" >> "$tmp"
  printf '%s\n' "profile_state=dynamic_stock_validated" >> "$tmp"
  printf '%s\n' "build_guard_mode=dynamic_local_validation" >> "$tmp"
  printf '%s\n' "build_evidence=$evidence" >> "$tmp"
  printf '%s\n' "profile_materialized=yes" >> "$tmp"
  printf '%s\n' "expected_thermal_files=dynamic_validated" >> "$tmp"
  mv "$tmp" "$INSTALL_STATE"
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
[ -r "$INSTALL_STATE" ] &&
  INSTALLED_BUILD="$(grep -E '^build_id=' "$INSTALL_STATE" 2>/dev/null | tail -n 1 | cut -d= -f2- | tr -d '\r')"
[ -n "$INSTALLED_BUILD" ] || INSTALLED_BUILD=none

platform_supported=0
build_evidence=unsupported_platform
if [ -r "$SUPPORTED_HELPER" ] &&
   thermal_supported_platform_check "$SUPPORTED_JSON" "$CURRENT_DEVICE" "$CURRENT_ANDROID"; then
  platform_supported=1
  if thermal_exact_build_check "$SUPPORTED_JSON" "$CURRENT_DEVICE" "$CURRENT_ANDROID" "$CURRENT_BUILD"; then
    build_evidence=exact_verified
  else
    build_evidence=dynamic_unverified
  fi
fi

cfg_set THERMAL_BUILD_EVIDENCE "$build_evidence"
cfg_set THERMAL_BUILD_ID "$CURRENT_BUILD"
if [ "$build_evidence" = dynamic_unverified ]; then
  cfg_set DYNAMIC_UNVERIFIED_BUILD 1
else
  cfg_set DYNAMIC_UNVERIFIED_BUILD 0
fi

needs_materialize=0
[ "$CURRENT_BUILD" = "$INSTALLED_BUILD" ] || needs_materialize=1
[ "$(cfg_get THERMAL_DISABLED)" = 1 ] && needs_materialize=1
for required in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
  [ -s "$MODDIR/system/vendor/etc/$required" ] || needs_materialize=1
done

if [ "$platform_supported" -eq 1 ]; then
  case "$build_evidence" in
    exact_verified) msg "- Build evidence: exact verified" ;;
    dynamic_unverified) msg "- New build detected; using local stock validation" ;;
  esac

  if [ "$needs_materialize" -eq 1 ]; then
    msg "- Materializing three stock-derived thermal overlays"
    polling="$(cfg_get THERMAL_POLLING_MODE)"
    outdoor="$(cfg_get THERMAL_OUTDOOR_PROFILE)"
    [ -n "$polling" ] || polling=mod
    [ -n "$outdoor" ] || outdoor=stock

    if [ -s "$MODDIR/tools/core/patch-thermal-validated.sh" ] &&
       sh "$MODDIR/tools/core/patch-thermal-validated.sh" "$polling" "$outdoor" "$MODDIR"; then
      cfg_set THERMAL_DISABLED 0
      cfg_set CANARY_DIAGNOSTIC_MODE 0
      rm -f "$MODDIR/skip_mount" "$MODDIR/guard/disabled_reason" 2>/dev/null || true
      update_install_state_build "$build_evidence"
      msg "- Local structure, diff and Outdoor validation passed"
    else
      remove_thermal_overlay
      cfg_set THERMAL_DISABLED 1
      msg "! Stock layout could not be validated"
      msg "! Thermal disabled; ZRAM remains available"
    fi
  fi
else
  remove_thermal_overlay
  cfg_set THERMAL_DISABLED 1
  msg "! Unsupported device or Android version"
  msg "- Device: ${CURRENT_DEVICE:-unknown}"
  msg "- Android: ${CURRENT_ANDROID:-unknown}"
  msg "- Build: ${CURRENT_BUILD:-unknown}"
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
