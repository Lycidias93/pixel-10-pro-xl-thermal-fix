#!/system/bin/sh
thermal_install_overlay() {
  [ -n "${MODPATH:-}" ] || thermal_abort "! MODPATH missing for overlay install"
  [ -n "${profile:-}" ] || thermal_abort "! profile missing for overlay install"
  [ -n "${profile_dir:-}" ] || thermal_abort "! profile_dir missing for overlay install"
  [ -n "${device:-}" ] || thermal_abort "! device missing for overlay install"
  [ -n "${build_id:-}" ] || thermal_abort "! build_id missing for overlay install"
  [ -n "${profile_state:-}" ] || thermal_abort "! profile_state missing for overlay install"
  [ -n "${build_state:-}" ] || thermal_abort "! build_state missing for overlay install"

  [ -s "$MODPATH/tools/profile-matrix-test9.sh" ] && . "$MODPATH/tools/profile-matrix-test9.sh"
  if command -v profile_matrix_base >/dev/null 2>&1; then
    matrix_profile="$(profile_matrix_base "$device" "$build_id" 2>/dev/null || true)"
    if [ -n "$matrix_profile" ] && [ -s "$MODPATH/profiles/$matrix_profile/system/vendor/etc/thermal_info_config_throttling.json" ]; then
      profile="$matrix_profile"
      profile_dir="$MODPATH/profiles/$profile/system/vendor/etc"
      ui_print "- A17 profile: $device / $build_id"
    fi
  fi

  base_profile="$profile"
  if [ -s "$MODPATH/tools/thermal-outdoor-menu.sh" ]; then
    chmod 0755 "$MODPATH/tools/thermal-outdoor-menu.sh" 2>/dev/null || true
    BASE_PROFILE="$base_profile" MODDIR="$MODPATH" sh "$MODPATH/tools/thermal-outdoor-menu.sh" install || ui_print "! Thermal outdoor menu failed nonfatal; keeping stock profile"
  else
    ui_print "! Thermal outdoor menu helper missing; keeping stock profile"
  fi

  THERMAL_OUTDOOR_PROFILE="$(config_get THERMAL_OUTDOOR_PROFILE)"
  [ -n "$THERMAL_OUTDOOR_PROFILE" ] || THERMAL_OUTDOOR_PROFILE="stock"

  case "$THERMAL_OUTDOOR_PROFILE" in
    outdoor-safe|outdoor-plus|outdoor-extended)
      outdoor_profile="$base_profile-$THERMAL_OUTDOOR_PROFILE"
      outdoor_profile_dir="$MODPATH/profiles/$outdoor_profile/system/vendor/etc"
      if [ -s "$outdoor_profile_dir/thermal_info_config_throttling.json" ] && [ -s "$outdoor_profile_dir/thermal_info_config.json" ] && [ -s "$outdoor_profile_dir/thermal_info_config_charge.json" ]; then
        profile="$outdoor_profile"
        profile_dir="$outdoor_profile_dir"
        case "$THERMAL_OUTDOOR_PROFILE" in
          outdoor-safe) outdoor_state_token="outdoor_safe_test25" ;;
          outdoor-plus) outdoor_state_token="outdoor_plus_test25" ;;
          outdoor-extended) outdoor_state_token="outdoor_extended_test25" ;;
        esac
        profile_state="${profile_state}_${outdoor_state_token}"
        build_state="${build_state}_${outdoor_state_token}"
        ui_print "- Thermal: $THERMAL_OUTDOOR_PROFILE"
      else
        ui_print "! Thermal Outdoor Profile missing for $outdoor_profile; keeping stock"
        THERMAL_OUTDOOR_PROFILE="stock_missing_profile"
      fi
    ;;
    *)
      ui_print "- Thermal Outdoor Profile: stock"
    ;;
  esac

  active_dir="$MODPATH/system/vendor/etc"

  for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
    [ -s "$profile_dir/$f" ] || thermal_abort "! Missing profile file: $profile_dir/$f"
  done
  [ -r /vendor/etc/thermal_info_config_throttling.json ] || thermal_abort "! Stock thermal throttling config not readable"
  grep -q "VIRTUAL-SKIN" /vendor/etc/thermal_info_config_throttling.json || thermal_abort "! Expected stock thermal marker missing"

  ui_print "- Thermal: ${THERMAL_OUTDOOR_PROFILE:-stock}"
  ui_print "- Materializing active thermal overlay..."

  rm -rf "$active_dir"
  mkdir -p "$active_dir"
  cp -fp "$profile_dir"/*.json "$active_dir"/
  chmod 0644 "$active_dir"/*.json 2>/dev/null || true
}
