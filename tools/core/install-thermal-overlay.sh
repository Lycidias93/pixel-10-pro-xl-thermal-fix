#!/system/bin/sh
thermal_install_overlay() {
  [ -n "${MODPATH:-}" ] || thermal_abort "! MODPATH missing for overlay install"
  [ -n "${device:-}" ] || thermal_abort "! device missing for overlay install"
  [ -n "${android:-}" ] || thermal_abort "! android missing for overlay install"
  [ -n "${build_id:-}" ] || thermal_abort "! build_id missing for overlay install"

  RESOLVER="$MODPATH/tools/core/profile-resolver.sh"
  SOURCE_VERIFY="$MODPATH/tools/core/profile-source-verify.sh"
  [ -r "$RESOLVER" ] || thermal_abort "! Exact profile resolver missing"
  [ -x "$SOURCE_VERIFY" ] || thermal_abort "! Profile source verifier missing"
  . "$RESOLVER"
  thermal_resolve_profile "$MODPATH" "$device" "$android" "$build_id" || thermal_abort "! Unsupported exact profile: $device / $android / $build_id ($THERMAL_RESOLVER_REASON)"
  sh "$SOURCE_VERIFY" "$MODPATH" "$device" "$android" "$build_id" >/dev/null || thermal_abort "! Git-backed stock profile verification failed"

  if [ -s "$MODPATH/tools/menu/thermal-outdoor-menu.sh" ]; then
    chmod 0755 "$MODPATH/tools/menu/thermal-outdoor-menu.sh" 2>/dev/null || true
    BASE_PROFILE="$THERMAL_PROFILE_REL" MODDIR="$MODPATH" sh "$MODPATH/tools/menu/thermal-outdoor-menu.sh" install || ui_print "! Thermal outdoor menu failed nonfatal; keeping stock profile"
  else
    ui_print "! Outdoor menu missing; keeping stock profile"
  fi

  THERMAL_OUTDOOR_PROFILE="$(config_get THERMAL_OUTDOOR_PROFILE)"
  [ -n "$THERMAL_OUTDOOR_PROFILE" ] || THERMAL_OUTDOOR_PROFILE="stock"
  THERMAL_POLLING_MODE="$(config_get THERMAL_POLLING_MODE)"
  [ -n "$THERMAL_POLLING_MODE" ] || THERMAL_POLLING_MODE="mod"

  ui_print "- Profile source: $THERMAL_PROFILE_REL"
  ui_print "- Polling mode: $THERMAL_POLLING_MODE"
  ui_print "- Thermal profile: $THERMAL_OUTDOOR_PROFILE"
  ui_print "- Materializing verified thermal overlay..."

  if [ -s "$MODPATH/tools/core/patch-thermal.sh" ]; then
    chmod 0755 "$MODPATH/tools/core/patch-thermal.sh" 2>/dev/null || true
    sh "$MODPATH/tools/core/patch-thermal.sh" "$THERMAL_POLLING_MODE" "$THERMAL_OUTDOOR_PROFILE" "$MODPATH" "$device" "$android" "$build_id" || thermal_abort "! Verified profile materialization failed"
  else
    thermal_abort "! Thermal patcher core script missing"
  fi
}
