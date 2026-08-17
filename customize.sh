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
ui_print "  Pixel Thermal & Memory Control"
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

# Magisk/KernelSU/APatch installers may normalize ZIP file modes while staging.
# Re-assert executable permissions for the standalone WebUI runtime exactly as
# required by the pinned shared WebUI template. Fail closed if the package is
# incomplete or the permission readback does not become executable.
WEBUI_SERVER="$MODPATH/bin/webui-server-arm64"
WEBUI_CONTROL="$MODPATH/bin/module-control"
[ -s "$WEBUI_SERVER" ] || thermal_abort "! WebUI server missing from package"
[ -s "$WEBUI_CONTROL" ] || thermal_abort "! WebUI module-control missing from package"
set_perm "$WEBUI_SERVER" 0 0 0755
set_perm "$WEBUI_CONTROL" 0 0 0755
[ -x "$WEBUI_SERVER" ] || thermal_abort "! WebUI server executable permission failed"
[ -x "$WEBUI_CONTROL" ] || thermal_abort "! WebUI module-control executable permission failed"

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

ZRAM_NORMALIZE="$MODPATH/tools/zram/config-normalize.sh"
if [ -s "$ZRAM_NORMALIZE" ]; then
  chmod 0755 "$ZRAM_NORMALIZE" 2>/dev/null || true
  ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$ZRAM_NORMALIZE" >/dev/null 2>&1 ||
    ui_print "! ZRAM config normalization failed; optional EH lock remains unavailable"
fi

if [ -s "$MODPATH/tools/menu/install-options-menu.sh" ]; then
  chmod 0755 "$MODPATH/tools/menu/menu-cycle.sh" "$MODPATH/tools/menu/install-options-menu.sh" 2>/dev/null || true
  MODULE_ID="$MODULE_ID" MODDIR="$MODPATH" sh "$MODPATH/tools/menu/install-options-menu.sh" install ||
    ui_print "! Install options menu failed; using current config/defaults"
else
  ui_print "! Options menu missing"
  ui_print "! Using current/defaults"
fi

if [ -s "$ZRAM_NORMALIZE" ]; then
  ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$ZRAM_NORMALIZE" >/dev/null 2>&1 || true
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
LAYOUT_HELPER="$MODPATH/tools/core/thermal-layout.sh"
[ -r "$SUPPORTED_HELPER" ] || thermal_abort "! supported-build helper missing"
[ -r "$LAYOUT_HELPER" ] || thermal_abort "! thermal-layout helper missing"
. "$SUPPORTED_HELPER"
. "$LAYOUT_HELPER"
thermal_supported_validate_file "$SUPPORTED_JSON" || thermal_abort "! supported_versions.json is invalid"

THERMAL_INSTALL_ENABLED=0
build_evidence="unsupported_platform"
vnext_experimental=0
case "$device:$android" in
  tokay:17|caiman:17|komodo:17|comet:17|tegu:17|stallion:17) vnext_experimental=1 ;;
esac

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
  if [ "$vnext_experimental" = 1 ]; then
    config_set CANARY_DIAGNOSTIC_MODE 1
    config_set AUTO_PROFILE_SWITCH 0
    config_set VNEXT_EXPERIMENTAL_PLATFORM 1
    config_set VNEXT_OTA_POLICY reinstall_required_after_transition
    config_set PTUNE_OVERRIDE_POLICY blocked_experimental_platform
    config_set ALLOW_THERMAL_WITH_PTUNE 0
    config_set RISK_ACK_PTUNE_THERMAL_COLLISION none
    ui_print "! vNext experimental platform"
    ui_print "- Full Bootguard verification is forced"
    ui_print "- Outdoor profile is capped conservatively"
    ui_print "- pTune coexistence override is blocked"
    ui_print "- Firmware transitions require reinstall"
  else
    config_set CANARY_DIAGNOSTIC_MODE 0
    config_set AUTO_PROFILE_SWITCH 1
    config_set VNEXT_EXPERIMENTAL_PLATFORM 0
    config_set VNEXT_OTA_POLICY automatic_stock_rematerialization
  fi
else
  config_set THERMAL_DISABLED 1
  config_set CANARY_DIAGNOSTIC_MODE 0
  config_set AUTO_PROFILE_SWITCH 0
  config_set VNEXT_EXPERIMENTAL_PLATFORM 0
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
build_guard_mode="dynamic_local_validation_vnext"

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
  if ! thermal_layout_load_env "$MODPATH/guard/thermal-layout.env"; then
    thermal_abort "! Failed to load validated Thermal layout"
  fi
  ui_print "- Thermal layout: $THERMAL_LAYOUT_FAMILY"
  for f in $THERMAL_LAYOUT_FILES; do
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

if [ -s "$MODPATH/install-state.txt" ]; then
  printf '%s\n' "build_guard_mode=$build_guard_mode" >> "$MODPATH/install-state.txt"
  printf '%s\n' "build_evidence=$build_evidence" >> "$MODPATH/install-state.txt"
  if [ "$THERMAL_INSTALL_ENABLED" = 1 ]; then
    printf '%s\n' "thermal_layout_family=$THERMAL_LAYOUT_FAMILY" >> "$MODPATH/install-state.txt"
    printf '%s\n' "thermal_layout_files=$THERMAL_LAYOUT_FILES_CSV" >> "$MODPATH/install-state.txt"
  fi
  printf '%s\n' "vnext_experimental_platform=$vnext_experimental" >> "$MODPATH/install-state.txt"
fi

READINESS_HELPER="$MODPATH/tools/debug/vnext-readiness-summary.sh"
if [ -s "$READINESS_HELPER" ]; then
  chmod 0755 "$READINESS_HELPER" 2>/dev/null || true
  READINESS_FILE="$MODPATH/guard/support-readiness.env"
  MODDIR="$MODPATH" THERMAL_DEVICE="$device" THERMAL_ANDROID="$android" THERMAL_BUILD_ID="$build_id" sh "$READINESS_HELPER" > "$READINESS_FILE" 2>/dev/null || true
  readiness_state="$(sed -n 's/^readiness_state=//p' "$READINESS_FILE" 2>/dev/null | tail -n 1)"
  [ -n "$readiness_state" ] && ui_print "- Readiness: $readiness_state"
fi

thermal_save_install_debug "success" "install_completed"
ui_print "- Target validation: PASS"
if [ "$THERMAL_INSTALL_ENABLED" = 1 ]; then
  ui_print "- Thermal overlay materialized"
else
  ui_print "- Thermal safely disabled for this platform"
fi
ui_print "- Android: $android"

if [ "$(config_get INSTALL_SUPPORT_SNAPSHOT)" = 1 ]; then
  SUPPORT_COLLECTOR="$MODPATH/tools/debug/collect-thermal-online-v5.sh"
  ui_print ""
  ui_print "- Support Snapshot: collecting read-only support package"
  if [ -s "$SUPPORT_COLLECTOR" ]; then
    chmod 0755 "$SUPPORT_COLLECTOR" 2>/dev/null || true
    SUPPORT_LOG="$MODPATH/guard/install-support-snapshot.log"
    if sh "$SUPPORT_COLLECTOR" support > "$SUPPORT_LOG" 2>&1; then
      tail -n 8 "$SUPPORT_LOG" 2>/dev/null | while IFS= read -r line; do ui_print "- $line"; done
    else
      ui_print "! Support Snapshot failed nonfatally"
      tail -n 5 "$SUPPORT_LOG" 2>/dev/null | while IFS= read -r line; do ui_print "! $line"; done
    fi
  else
    ui_print "! Support Snapshot collector missing"
  fi
fi

if [ -d "$MODPATH/tools" ]; then
  chmod -R 0755 "$MODPATH/tools" 2>/dev/null || true
fi
