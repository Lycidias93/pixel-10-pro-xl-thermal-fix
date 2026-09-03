#!/system/bin/sh
set -eu

MODDIR=${0%/*}
ID="pixel-10-pro-xl-thermal-fix"
CONFIG_DIR="${THERMAL_CONFIG_DIR:-/data/adb/$ID}"
CONFIG_FILE="$CONFIG_DIR/config.env"
SUPPORTED_HELPER="$MODDIR/tools/core/supported-build.sh"
SUPPORTED_JSON="$MODDIR/supported_versions.json"
LAYOUT_HELPER="$MODDIR/tools/core/thermal-layout.sh"
LAYOUT_ENV="$MODDIR/guard/thermal-layout.env"
INSTALL_STATE="$MODDIR/install-state.txt"
ACTION_PERF="$MODDIR/guard/action-performance.env"
ZRAM_NORMALIZE="$MODDIR/tools/zram/config-normalize.sh"
WEBUI_LAUNCHER="$MODDIR/tools/webui/launch.sh"

now_ms() {
  awk '{printf "%d\n", $1 * 1000}' /proc/uptime 2>/dev/null || printf '%s\n' 0
}

ACTION_STARTED_MS="$(now_ms)"
MATERIALIZE_STARTED_MS=0
MATERIALIZE_FINISHED_MS=0

cfg_get() {
  key="$1"
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^${key}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${key}=//" | tr -d '\r'
}

cfg_set() {
  key="$1"; value="$2"
  mkdir -p "$CONFIG_DIR" 2>/dev/null || true
  touch "$CONFIG_FILE" 2>/dev/null || true
  tmp="$CONFIG_FILE.tmp.$$"
  grep -v "^${key}=" "$CONFIG_FILE" 2>/dev/null > "$tmp" || true
  printf '%s=%s\n' "$key" "$value" >> "$tmp"
  mv "$tmp" "$CONFIG_FILE"
  chmod 0600 "$CONFIG_FILE" 2>/dev/null || true
}

msg() { if command -v ui_print >/dev/null 2>&1; then ui_print "$*"; else echo "$*"; fi; }
remove_thermal_overlay() { rm -f "$MODDIR/system/vendor/etc"/thermal_info_config*.json 2>/dev/null || true; }

update_install_state_build() {
  evidence="$1"
  [ -f "$INSTALL_STATE" ] || return 0
  tmp="$INSTALL_STATE.tmp.$$"
  grep -v -E '^(build_id|profile|profile_state|build_guard_mode|build_evidence|profile_materialized|expected_thermal_files|thermal_layout_family|thermal_layout_files|vnext_experimental_platform)=' "$INSTALL_STATE" > "$tmp" 2>/dev/null || true
  printf '%s\n' "build_id=$CURRENT_BUILD" >> "$tmp"
  printf '%s\n' "profile=dynamic/$CURRENT_DEVICE/android$CURRENT_ANDROID" >> "$tmp"
  printf '%s\n' "profile_state=dynamic_stock_validated_$evidence" >> "$tmp"
  printf '%s\n' "build_guard_mode=dynamic_local_validation_vnext" >> "$tmp"
  printf '%s\n' "build_evidence=$evidence" >> "$tmp"
  printf '%s\n' "profile_materialized=yes" >> "$tmp"
  printf '%s\n' "expected_thermal_files=dynamic_validated" >> "$tmp"
  printf '%s\n' "thermal_layout_family=${THERMAL_LAYOUT_FAMILY:-unknown}" >> "$tmp"
  printf '%s\n' "thermal_layout_files=${THERMAL_LAYOUT_FILES_CSV:-unknown}" >> "$tmp"
  printf '%s\n' "vnext_experimental_platform=$vnext_experimental" >> "$tmp"
  mv "$tmp" "$INSTALL_STATE"
}

write_action_performance() {
  action_finished_ms="$(now_ms)"
  startup_ms=unknown
  materialize_ms=0
  case "$ACTION_STARTED_MS:$action_finished_ms" in *[!0-9:]*|:*|*:) ;; *) startup_ms=$((action_finished_ms - ACTION_STARTED_MS)) ;; esac
  if [ "$MATERIALIZE_STARTED_MS" -gt 0 ] 2>/dev/null && [ "$MATERIALIZE_FINISHED_MS" -ge "$MATERIALIZE_STARTED_MS" ] 2>/dev/null; then materialize_ms=$((MATERIALIZE_FINISHED_MS - MATERIALIZE_STARTED_MS)); fi
  mkdir -p "$MODDIR/guard" 2>/dev/null || true
  {
    printf '%s\n' 'schema=pixel-thermal-action-performance-v2'
    printf '%s\n' "startup_to_dashboard_ms=$startup_ms"
    printf '%s\n' "materialize_required=$needs_materialize"
    printf '%s\n' "materialize_ms=$materialize_ms"
    printf '%s\n' "build_evidence=$build_evidence"
    printf '%s\n' "vnext_experimental_platform=$vnext_experimental"
    printf '%s\n' 'network_refresh=absent'
    printf '%s\n' "action_bytes=$(wc -c < "$MODDIR/action.sh" 2>/dev/null | tr -d ' ')"
  } > "$ACTION_PERF" 2>/dev/null || true
  msg "- Action prep: ${startup_ms} ms"
}

if [ -r "$ZRAM_NORMALIZE" ]; then ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$ZRAM_NORMALIZE" >/dev/null 2>&1 || true; fi

[ -r "$SUPPORTED_HELPER" ] || { msg "! supported-build helper missing"; cfg_set THERMAL_DISABLED 1; remove_thermal_overlay; }
[ -r "$LAYOUT_HELPER" ] || { msg "! thermal-layout helper missing"; cfg_set THERMAL_DISABLED 1; remove_thermal_overlay; }
[ -r "$SUPPORTED_HELPER" ] && . "$SUPPORTED_HELPER"
[ -r "$LAYOUT_HELPER" ] && . "$LAYOUT_HELPER"

CURRENT_DEVICE="$(getprop ro.product.device 2>/dev/null || true)"
CURRENT_ANDROID="$(getprop ro.build.version.release 2>/dev/null || true)"
CURRENT_BUILD="$(getprop ro.build.id 2>/dev/null || true)"
INSTALLED_BUILD="none"
[ -r "$INSTALL_STATE" ] && INSTALLED_BUILD="$(grep -E '^build_id=' "$INSTALL_STATE" 2>/dev/null | tail -n 1 | cut -d= -f2- | tr -d '\r')"
[ -n "$INSTALLED_BUILD" ] || INSTALLED_BUILD=none

vnext_experimental=0
case "$CURRENT_DEVICE:$CURRENT_ANDROID" in tokay:17|caiman:17|komodo:17|comet:17|tegu:17|stallion:17|cubs:17|grizzly:17|kodiak:17|yogi:17) vnext_experimental=1 ;; esac

platform_supported=0
build_evidence=unsupported_platform
if [ -r "$SUPPORTED_HELPER" ] && thermal_supported_probe "$SUPPORTED_JSON" "$CURRENT_DEVICE" "$CURRENT_ANDROID" "$CURRENT_BUILD"; then
  platform_supported=1
  if [ "$THERMAL_SUPPORTED_BUILD_OK" = 1 ]; then build_evidence=exact_verified; else build_evidence=dynamic_unverified; fi
fi

cfg_set THERMAL_BUILD_EVIDENCE "$build_evidence"
cfg_set THERMAL_BUILD_ID "$CURRENT_BUILD"
if [ "$build_evidence" = dynamic_unverified ]; then cfg_set DYNAMIC_UNVERIFIED_BUILD 1; else cfg_set DYNAMIC_UNVERIFIED_BUILD 0; fi
if [ "$vnext_experimental" = 1 ]; then
  cfg_set CANARY_DIAGNOSTIC_MODE 1
  cfg_set AUTO_PROFILE_SWITCH 0
  cfg_set VNEXT_EXPERIMENTAL_PLATFORM 1
else
  cfg_set CANARY_DIAGNOSTIC_MODE 0
  cfg_set AUTO_PROFILE_SWITCH 1
  cfg_set VNEXT_EXPERIMENTAL_PLATFORM 0
fi

needs_materialize=0
[ "$CURRENT_BUILD" = "$INSTALLED_BUILD" ] || needs_materialize=1
[ "$(cfg_get THERMAL_DISABLED)" = 1 ] && needs_materialize=1
if ! thermal_layout_load_env "$LAYOUT_ENV" 2>/dev/null; then
  needs_materialize=1
else
  for required in $THERMAL_LAYOUT_FILES; do [ -s "$MODDIR/system/vendor/etc/$required" ] || needs_materialize=1; done
fi

experimental_reinstall_required=0
if [ "$vnext_experimental" = 1 ] && grep -q '^REINSTALL_REQUIRED=yes$' "$MODDIR/guard/reinstall_required" 2>/dev/null; then experimental_reinstall_required=1; fi

if [ "$platform_supported" -eq 1 ]; then
  case "$build_evidence" in exact_verified) msg "- Build evidence: exact verified" ;; dynamic_unverified) msg "- New build detected; using local stock validation" ;; esac

  if [ "$experimental_reinstall_required" = 1 ]; then
    remove_thermal_overlay
    cfg_set THERMAL_DISABLED 1
    msg "! Experimental platform changed firmware"
    msg "! Reinstall this prerelease before re-enabling Thermal"
  elif [ "$needs_materialize" -eq 1 ]; then
    MATERIALIZE_STARTED_MS="$(now_ms)"
    msg "- Materializing stock-derived Thermal layout"
    polling="$(cfg_get THERMAL_POLLING_MODE)"
    outdoor="$(cfg_get THERMAL_OUTDOOR_PROFILE)"
    [ -n "$polling" ] || polling=mod
    [ -n "$outdoor" ] || outdoor=stock

    if [ -s "$MODDIR/tools/core/patch-thermal-validated.sh" ] && sh "$MODDIR/tools/core/patch-thermal-validated.sh" "$polling" "$outdoor" "$MODDIR"; then
      MATERIALIZE_FINISHED_MS="$(now_ms)"
      thermal_layout_load_env "$LAYOUT_ENV" || { remove_thermal_overlay; cfg_set THERMAL_DISABLED 1; msg "! Layout state invalid after materialization"; }
      layout_count="${THERMAL_LAYOUT_COUNT:-0}"
      layout_count_valid=0
      case "$layout_count" in ''|*[!0-9]*) ;; *) [ "$layout_count" -ge 3 ] 2>/dev/null && layout_count_valid=1 || true ;; esac
      if [ "$layout_count_valid" = 1 ]; then
        cfg_set THERMAL_DISABLED 0
        rm -f "$MODDIR/skip_mount" "$MODDIR/guard/disabled_reason" 2>/dev/null || true
        update_install_state_build "$build_evidence"
        msg "- Local structure, diff and Outdoor validation passed"
        msg "- Layout: $THERMAL_LAYOUT_FAMILY ($layout_count files)"
      else
        remove_thermal_overlay
        cfg_set THERMAL_DISABLED 1
        msg "! Layout count invalid after materialization"
      fi
    else
      MATERIALIZE_FINISHED_MS="$(now_ms)"
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

write_action_performance

if [ -x "$WEBUI_LAUNCHER" ]; then
  msg "- Opening standalone WebUI"
  if MODULE_DIR="$MODDIR" sh "$WEBUI_LAUNCHER"; then
    exit 0
  fi
  msg "! WebUI launch failed; opening legacy Action menu"
fi

# The legacy volume-key dashboard remains the rollback/fallback path. Action is
# runtime/config-only for ZRAM layout decisions.
if [ -s "$MODDIR/tools/action-dashboard.sh" ]; then
  ZRAM_MATERIALIZE_NOW=0 ZRAM_MATERIALIZE_CALLER=action-dashboard sh "$MODDIR/tools/action-dashboard.sh"
elif [ -s "$MODDIR/tools/menu/zram-menu.sh" ]; then
  ZRAM_MATERIALIZE_NOW=0 ZRAM_MATERIALIZE_CALLER=action-zram-menu sh "$MODDIR/tools/menu/zram-menu.sh" action
else
  msg "! Action helpers missing"
  exit 1
fi