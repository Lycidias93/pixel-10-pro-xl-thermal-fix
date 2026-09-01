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

  LAYOUT_HELPER="$MODPATH/tools/core/thermal-layout.sh"
  [ -r "$LAYOUT_HELPER" ] || thermal_abort "! Thermal layout helper missing"
  . "$LAYOUT_HELPER"

  if thermal_layout_is_g6_device "$device"; then
    # Pixel 11 is intentionally admitted as an experimental vNext platform.
    # Keep the same fail-closed policies as Pixel 9/10a and additionally pin
    # Thermal polling to stock until real-device runtime evidence exists.
    vnext_experimental=1
    config_set CANARY_DIAGNOSTIC_MODE 1
    config_set AUTO_PROFILE_SWITCH 0
    config_set VNEXT_EXPERIMENTAL_PLATFORM 1
    config_set VNEXT_OTA_POLICY reinstall_required_after_transition
    config_set PTUNE_OVERRIDE_POLICY blocked_experimental_platform
    config_set ALLOW_THERMAL_WITH_PTUNE 0
    config_set RISK_ACK_PTUNE_THERMAL_COLLISION none
    config_set VNEXT_G6_GRAPH_PLATFORM 1
    config_set THERMAL_POLLING_POLICY stock_only_pending_runtime_evidence
    ui_print "! Pixel 11 vNext experimental platform"
    ui_print "- Include-graph Thermal validation is required"
    ui_print "- Polling remains stock pending runtime evidence"
    ui_print "- Outdoor Safe is limited to the exact VIRTUAL-SKIN sensor"
    ui_print "- pTune coexistence override is blocked"
    ui_print "- Firmware transitions require reinstall"
  else
    config_set VNEXT_G6_GRAPH_PLATFORM 0
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
  if thermal_layout_is_g6_device "$device" && [ "$THERMAL_POLLING_MODE" != stock ]; then
    THERMAL_POLLING_MODE=stock
    config_set THERMAL_POLLING_MODE stock
    config_set THERMAL_POLLING_EFFECTIVE stock
    config_set LAST_THERMAL_POLLING_MODE stock
    ui_print "! Pixel 11 polling override deferred; using stock"
  fi

  ui_print "- Install selections already confirmed"
  ui_print "- Polling mode: $THERMAL_POLLING_MODE"
  ui_print "- Thermal profile: $THERMAL_OUTDOOR_PROFILE"
  ui_print "- Materializing and validating thermal overlay..."

  [ -s "$MODPATH/tools/core/patch-thermal-validated.sh" ] || thermal_abort "! Validated dynamic patcher wrapper missing"
  chmod 0755 "$MODPATH/tools/core/patch-thermal.sh" "$MODPATH/tools/core/verify-outdoor-delta.sh" "$MODPATH/tools/core/validation-state.sh" "$MODPATH/tools/core/patch-thermal-validated.sh" 2>/dev/null || true

  patch_output="$MODPATH/guard/install-patch-output.$$"
  mkdir -p "$MODPATH/guard" 2>/dev/null || true
  if sh "$MODPATH/tools/core/patch-thermal-validated.sh" "$THERMAL_POLLING_MODE" "$THERMAL_OUTDOOR_PROFILE" "$MODPATH" > "$patch_output" 2>&1; then
    patch_source="$(sed -n 's/^PATCH_THERMAL_SOURCE_300000=//p' "$patch_output" | tail -n 1)"
    patch_replacements="$(sed -n 's/^PATCH_THERMAL_REPLACEMENTS=//p' "$patch_output" | tail -n 1)"
    patch_delta="$(sed -n 's/^PATCH_THERMAL_DELTA_EXPECTED=//p' "$patch_output" | tail -n 1)"
    patch_files="$(sed -n 's/^PATCH_THERMAL_DELTA_FILES=//p' "$patch_output" | tail -n 1)"
    patch_zones="$(sed -n 's/^PATCH_THERMAL_DELTA_TARGET_ZONES=//p' "$patch_output" | tail -n 1)"
    patch_values="$(sed -n 's/^PATCH_THERMAL_DELTA_THRESHOLD_VALUES=//p' "$patch_output" | tail -n 1)"
    [ -n "$patch_source" ] || patch_source=unknown
    [ -n "$patch_replacements" ] || patch_replacements=unknown
    [ -n "$patch_delta" ] || patch_delta=unknown
    [ -n "$patch_files" ] || patch_files=unknown
    [ -n "$patch_zones" ] || patch_zones=unknown
    [ -n "$patch_values" ] || patch_values=unknown
    ui_print "- Thermal validation: PASS"
    ui_print "- Polling changes: $patch_replacements/$patch_source"
    ui_print "- Outdoor delta: +${patch_delta} C"
    ui_print "- Scope: $patch_files files, $patch_zones zones, $patch_values values"
    ui_print "- Validation state: canonical"
    rm -f "$patch_output" 2>/dev/null || true
  else
    patch_rc="$?"
    ui_print "! Dynamic patching or validation failed"
    ui_print "! Last validator lines:"
    tail -n 12 "$patch_output" 2>/dev/null | while IFS= read -r patch_line; do ui_print "! $patch_line"; done
    rm -f "$patch_output" 2>/dev/null || true
    thermal_abort "! Dynamic patching or validation failed (rc=$patch_rc)"
  fi
}
