#!/system/bin/sh
# Install-time ZRAM materializer. Selection is owned by install-options-menu.sh.

thermal_install_zram() {
  thermal_zram_materializer="$MODPATH/tools/zram/materialize-zram-choice.sh"
  thermal_zram_enabled="$(config_get ENABLE_ZRAM_100P)"
  thermal_zram_log="$MODPATH/guard/install-zram-layout.log"

  [ -r "$thermal_zram_materializer" ] || thermal_abort "! ZRAM materializer missing"
  mkdir -p "$MODPATH/guard" 2>/dev/null || true

  case "$thermal_zram_enabled" in
    1)
      if ! MODDIR="$MODPATH" ZRAM_ACTIVE_DIR="$active_dir" ZRAM_CONFIG_FILE="$CONFIG_FILE" \
        sh "$thermal_zram_materializer" enable > "$thermal_zram_log" 2>&1; then
        tail -n 4 "$thermal_zram_log" 2>/dev/null | while IFS= read -r thermal_zram_line; do
          ui_print "! $thermal_zram_line"
        done
        thermal_abort "! Failed to materialize active ZRAM fstab"
      fi
      thermal_zram_result="$(tail -n 1 "$thermal_zram_log" 2>/dev/null || true)"
      [ -n "$thermal_zram_result" ] && ui_print "- $thermal_zram_result"
      ui_print "- ZRAM selection: enabled"
      ui_print "- Materialized ZRAM 100p layout"
    ;;
    *)
      if ! MODDIR="$MODPATH" ZRAM_ACTIVE_DIR="$active_dir" ZRAM_CONFIG_FILE="$CONFIG_FILE" \
        sh "$thermal_zram_materializer" disable > "$thermal_zram_log" 2>&1; then
        tail -n 4 "$thermal_zram_log" 2>/dev/null | while IFS= read -r thermal_zram_line; do
          ui_print "! $thermal_zram_line"
        done
        thermal_abort "! Failed to remove active ZRAM fstab"
      fi
      config_set ENABLE_ZRAM_100P 0
      config_set ZRAM_EMERALD_OC 0
      config_set ZRAM_RESTART_MMD 0
      config_set ZRAM_RISK_ACK disabled_by_user
      config_set ZRAM_EH_RISK_ACK disabled_by_user
      config_set LAST_ZRAM_100P disabled
      thermal_zram_result="$(tail -n 1 "$thermal_zram_log" 2>/dev/null || true)"
      [ -n "$thermal_zram_result" ] && ui_print "- $thermal_zram_result"
      ui_print "- ZRAM selection: disabled"
      ui_print "- No ZRAM fstab materialized"
    ;;
  esac
}
