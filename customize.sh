#!/system/bin/sh
SKIPUNZIP=0

MODULE_ID="pixel-10-pro-xl-thermal-fix"
MODULE_PROP="${MODPATH:-.}/module.prop"
MODULE_VERSION=""
MODULE_VERSION_CODE=""

if [ -r "$MODULE_PROP" ]; then
  MODULE_VERSION="$(sed -n 's/^version=//p' "$MODULE_PROP" | head -n 1)"
  MODULE_VERSION_CODE="$(sed -n 's/^versionCode=//p' "$MODULE_PROP" | head -n 1)"
fi
[ -n "$MODULE_VERSION" ] || MODULE_VERSION="unknown"
[ -n "$MODULE_VERSION_CODE" ] || MODULE_VERSION_CODE="0"

if [ -s "${MODPATH:-.}/tools/menu/menu-cycle.sh" ]; then
  . "${MODPATH:-.}/tools/menu/menu-cycle.sh"
else
  mc_rule() { ui_print "----------------------------------------"; }
fi

mc_rule
ui_print "  Pixel 10 Thermal & Memory Control"
mc_rule
case "$MODULE_VERSION" in
  *-test.*|*alpha*|*beta*|*rc*|*candidate*) ui_print "Prerelease: $MODULE_VERSION" ;;
  *) ui_print "Release: $MODULE_VERSION" ;;
esac
ui_print "Dynamic stock-derived thermal validation"

model="$(getprop ro.product.model 2>/dev/null || true)"
device="$(getprop ro.product.device 2>/dev/null || true)"
android="$(getprop ro.build.version.release 2>/dev/null || true)"
android_sdk="$(getprop ro.build.version.sdk 2>/dev/null || true)"
build_id="$(getprop ro.build.id 2>/dev/null || true)"
fingerprint="$(getprop ro.build.fingerprint 2>/dev/null || true)"
incremental="$(getprop ro.build.version.incremental 2>/dev/null || true)"

root_impl="unknown"
su_v="$(su -v 2>/dev/null || true)"
su_V="$(su -V 2>/dev/null || true)"
magisk_v="$(magisk -v 2>/dev/null || true)"
case "$su_v $su_V $magisk_v" in
  *SukiSU*|*sukisu*|*ksud*) root_impl="sukisu" ;;
  *KernelSU*Next*|*ksu-next*|*KSU-Next*) root_impl="kernelsu_next" ;;
  *KernelSU*|*ksu*) root_impl="kernelsu" ;;
  *Magisk*|*magisk*|*MAGISKSU*) root_impl="magisk" ;;
  *APatch*|*apatch*) root_impl="apatch" ;;
esac
[ "$root_impl" != unknown ] || [ ! -d /data/adb/magisk ] || root_impl="magisk"

mount_backend_hint="none"
if find /data/adb /debug_ramdisk /sbin -maxdepth 5 \
  \( -iname '*hybrid*mount*' -o -iname '*mountify*' -o -iname '*metamodule*' -o -iname '*meta-module*' \) \
  2>/dev/null | head -1 | grep -q .; then
  mount_backend_hint="overlay_backend_present"
fi
root_backend_guard_mode="log_only_no_block"

if [ -s "$MODPATH/tools/debug/install-debug.sh" ]; then
  chmod 0755 "$MODPATH/tools/debug/install-debug.sh" 2>/dev/null || true
  . "$MODPATH/tools/debug/install-debug.sh"
else
  ui_print "! Install debug missing"
  thermal_save_install_debug() { :; }
  thermal_collect_debug_on_fail() { :; }
  thermal_abort() { abort "$*"; }
fi

ui_print "- Device: ${model:-unknown} (${device:-unknown})"
ui_print "- Android: ${android:-unknown} (SDK ${android_sdk:-unknown})"
ui_print "- Build: ${build_id:-unknown}"
ui_print "- Root: $root_impl"

CONFIG_DIR="/data/adb/$MODULE_ID"
CONFIG_FILE="$CONFIG_DIR/config.env"

config_get() {
  key="$1"
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^${key}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${key}=//" | tr -d '\r'
}

config_set() {
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

if [ -s "$MODPATH/tools/menu/install-options-menu.sh" ]; then
  chmod 0755 "$MODPATH/tools/menu/menu-cycle.sh" "$MODPATH/tools/menu/install-options-menu.sh" 2>/dev/null || true
  MODULE_ID="$MODULE_ID" MODDIR="$MODPATH" sh "$MODPATH/tools/menu/install-options-menu.sh" install ||
    ui_print "! Install options menu failed; using current config/defaults"
else
  ui_print "! Options menu missing"
  ui_print "! Using current/defaults"
fi

if [ -s "$MODPATH/tools/ptune/ptune-guard.sh" ]; then
  chmod 0755 "$MODPATH/tools/ptune/ptune-guard.sh" 2>/dev/null || true
  . "$MODPATH/tools/ptune/ptune-guard.sh"
else
  thermal_abort "! pTune guard helper missing"
fi

if [ -n "${PTUNE_INSTALLED_PATH:-}" ] && [ "${PTUNE_OVERRIDE_ALLOWED:-0}" = "1" ]; then
  ui_print "! pTune override active"
  ui_print "! Thermal coexistence risk acknowledged"
  [ "${PTUNE_KNOWN_BAD:-no}" = "no" ] || ui_print "! Known bad pTune state: $PTUNE_KNOWN_BAD"
fi

SUPPORTED_JSON="$MODPATH/supported_versions.json"
SUPPORTED_HELPER="$MODPATH/tools/core/supported-build.sh"
[ -r "$SUPPORTED_HELPER" ] || thermal_abort "! supported-build helper missing"
. "$SUPPORTED_HELPER"
thermal_supported_validate_file "$SUPPORTED_JSON" || thermal_abort "! supported_versions.json is invalid"

THERMAL_INSTALL_ENABLED=0
build_evidence="unsupported_platform"

if thermal_supported_platform_check "$SUPPORTED_JSON" "$device" "$android"; then
  THERMAL_INSTALL_ENABLED=1
  if thermal_exact_build_check "$SUPPORTED_JSON" "$device" "$android" "$build_id"; then
    build_evidence="exact_verified"
    ui_print "- Build evidence: exact verified"
  else
    build_evidence="dynamic_unverified"
    ui_print "- Build evidence: new/unlisted"
    ui_print "- Admission: local stock structure + diff validation"
  fi
  config_set THERMAL_DISABLED 0
  config_set CANARY_DIAGNOSTIC_MODE 0
else
  config_set THERMAL_DISABLED 1
  ui_print "! Unsupported device or Android version"
  ui_print "- Thermal files will not be installed"
  ui_print "- ZRAM remains available"
fi

config_set THERMAL_BUILD_EVIDENCE "$build_evidence"
config_set THERMAL_BUILD_ID "$build_id"
if [ "$build_evidence" = dynamic_unverified ]; then
  config_set DYNAMIC_UNVERIFIED_BUILD 1
else
  config_set DYNAMIC_UNVERIFIED_BUILD 0
fi

android_guard="android${android}_pass"
fingerprint_android_guard="fingerprint_android${android}_pass"
profile_source_android="$android"
profile_source_build="$build_id"
profile_source_incremental="$incremental"
source_report_sha256="dynamic_patching_validated"
build_state="dynamic_${device}_${build_id}_${incremental}"
build_guard_mode="dynamic_local_validation"

if [ "$THERMAL_INSTALL_ENABLED" = 1 ]; then
  profile_state="dynamic_stock_validated_${build_evidence}"
  profile="dynamic/${device}/android${android}"
  profile_materialized=yes
  expected_thermal_files=dynamic_validated
else
  profile_state="thermal_disabled_unsupported_platform"
  profile="dynamic/unsupported-platform"
  profile_materialized=no
  expected_thermal_files=0
fi
active_dir="$MODPATH/system/vendor/etc"

if [ -s "$MODPATH/tools/core/install-thermal-overlay.sh" ]; then
  chmod 0755 "$MODPATH/tools/core/install-thermal-overlay.sh" 2>/dev/null || true
  . "$MODPATH/tools/core/install-thermal-overlay.sh"
  thermal_install_overlay
else
  thermal_abort "! Thermal overlay install helper missing"
fi

if [ -s "$MODPATH/tools/zram/install-zram.sh" ]; then
  chmod 0755 "$MODPATH/tools/zram/install-zram.sh" 2>/dev/null || true
  . "$MODPATH/tools/zram/install-zram.sh"
  thermal_install_zram
else
  ui_print "! ZRAM helper missing"
  ui_print "! Keeping safe config"
fi

if [ "$THERMAL_INSTALL_ENABLED" = 1 ]; then
  for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
    [ -s "$MODPATH/system/vendor/etc/$f" ] || thermal_abort "! Failed to materialize active file: $f"
  done
fi

if [ -s "$MODPATH/tools/install-finalize.sh" ]; then
  chmod 0755 "$MODPATH/tools/install-finalize.sh" 2>/dev/null || true
  . "$MODPATH/tools/install-finalize.sh"
  thermal_finalize_install
else
  thermal_abort "! Install finalize helper missing"
fi

# Add dynamic evidence without duplicating the finalizer.
if [ -s "$MODPATH/install-state.txt" ]; then
  printf '%s\n' "build_guard_mode=$build_guard_mode" >> "$MODPATH/install-state.txt"
  printf '%s\n' "build_evidence=$build_evidence" >> "$MODPATH/install-state.txt"
fi

thermal_save_install_debug "success" "install_completed"
ui_print "- Target validation: PASS"
if [ "$THERMAL_INSTALL_ENABLED" = 1 ]; then
  ui_print "- Thermal overlay materialized"
else
  ui_print "- Thermal safely disabled for this platform"
fi
ui_print "- Android: $android"

if [ -d "$MODPATH/tools" ]; then
  chmod -R 0755 "$MODPATH/tools" 2>/dev/null || true
fi
