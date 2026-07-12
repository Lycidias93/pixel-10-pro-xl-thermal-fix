#!/system/bin/sh
thermal_install_overlay() {
  [ -n "${MODPATH:-}" ] || thermal_abort "! MODPATH missing for overlay install"
  [ -n "${device:-}" ] || thermal_abort "! device missing for overlay install"
  [ -n "${build_id:-}" ] || thermal_abort "! build_id missing for overlay install"

  if [ "${THERMAL_INSTALL_ENABLED:-1}" != "1" ]; then
    rm -f "$MODPATH/system/vendor/etc"/thermal_info_config*.json 2>/dev/null || true
    ui_print "! Thermal overlay skipped for unsupported build"
    ui_print "- ZRAM installation remains available"
    return 0
  fi

  if [ -s "$MODPATH/tools/menu/thermal-outdoor-menu.sh" ]; then
    chmod 0755 "$MODPATH/tools/menu/thermal-outdoor-menu.sh" 2>/dev/null || true
    BASE_PROFILE="dynamic" MODDIR="$MODPATH" sh "$MODPATH/tools/menu/thermal-outdoor-menu.sh" install ||
      ui_print "! Thermal outdoor menu failed nonfatal; keeping stock profile"
  else
    ui_print "! Outdoor menu missing; keeping stock profile"
  fi

  THERMAL_OUTDOOR_PROFILE="$(config_get THERMAL_OUTDOOR_PROFILE)"
  [ -n "$THERMAL_OUTDOOR_PROFILE" ] || THERMAL_OUTDOOR_PROFILE=stock
  THERMAL_POLLING_MODE="$(config_get THERMAL_POLLING_MODE)"
  [ -n "$THERMAL_POLLING_MODE" ] || THERMAL_POLLING_MODE=mod

  ui_print "- Polling mode: $THERMAL_POLLING_MODE"
  ui_print "- Thermal profile: $THERMAL_OUTDOOR_PROFILE"
  ui_print "- Materializing validated thermal overlay..."

  [ -s "$MODPATH/tools/core/patch-thermal.sh" ] ||
    thermal_abort "! Dynamic patcher core script missing"
  chmod 0755 "$MODPATH/tools/core/patch-thermal.sh" 2>/dev/null || true
  sh "$MODPATH/tools/core/patch-thermal.sh" "$THERMAL_POLLING_MODE" "$THERMAL_OUTDOOR_PROFILE" "$MODPATH" ||
    thermal_abort "! Dynamic patching failed"
}
