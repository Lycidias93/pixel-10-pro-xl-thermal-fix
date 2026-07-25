#!/system/bin/sh

thermal_install_overlay() {
  [ -n "${MODPATH:-}" ] || thermal_abort "! MODPATH missing for overlay install"
  [ -n "${device:-}" ] || thermal_abort "! device missing for overlay install"
  [ -n "${build_id:-}" ] || thermal_abort "! build_id missing for overlay install"

  if [ "${THERMAL_INSTALL_ENABLED:-1}" != "1" ]; then
    rm -f "$MODPATH/system/vendor/etc"/thermal_info_config*.json 2>/dev/null || true
    ui_print "! Thermal overlay skipped for unsupported platform"
    ui_print "- ZRAM installation remains available"
    return 0
  fi

  THERMAL_OUTDOOR_PROFILE="$(config_get THERMAL_OUTDOOR_PROFILE)"
  case "$THERMAL_OUTDOOR_PROFILE" in
    stock|outdoor-safe|outdoor-plus|outdoor-extended) ;;
    *)
      THERMAL_OUTDOOR_PROFILE=stock
      config_set THERMAL_OUTDOOR_PROFILE stock
      config_set THERMAL_OUTDOOR_TARGET stock
      config_set THERMAL_OUTDOOR_RISK_ACK disabled_or_stock_selected
      ui_print "! Invalid thermal selection; fallback: stock"
    ;;
  esac

  THERMAL_POLLING_MODE="$(config_get THERMAL_POLLING_MODE)"
  case "$THERMAL_POLLING_MODE" in
    stock|mod) ;;
    *)
      THERMAL_POLLING_MODE=mod
      config_set THERMAL_POLLING_MODE mod
      config_set THERMAL_POLLING_EFFECTIVE mod
      ui_print "! Invalid polling selection; fallback: mod"
    ;;
  esac

  ui_print "- Install selections already confirmed"
  ui_print "- Polling mode: $THERMAL_POLLING_MODE"
  ui_print "- Thermal profile: $THERMAL_OUTDOOR_PROFILE"
  ui_print "- Materializing and validating thermal overlay..."

  [ -s "$MODPATH/tools/core/patch-thermal-validated.sh" ] ||
    thermal_abort "! Validated dynamic patcher wrapper missing"

  chmod 0755 \
    "$MODPATH/tools/core/patch-thermal.sh" \
    "$MODPATH/tools/core/verify-outdoor-delta.sh" \
    "$MODPATH/tools/core/validation-state.sh" \
    "$MODPATH/tools/core/patch-thermal-validated.sh" 2>/dev/null || true

  sh "$MODPATH/tools/core/patch-thermal-validated.sh" \
    "$THERMAL_POLLING_MODE" \
    "$THERMAL_OUTDOOR_PROFILE" \
    "$MODPATH" ||
    thermal_abort "! Dynamic patching or validation failed"
}
