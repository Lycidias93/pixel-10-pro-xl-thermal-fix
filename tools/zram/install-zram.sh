#!/system/bin/sh
# Install-time ZRAM materializer. Selection is owned by install-options-menu.sh.

thermal_install_zram() {
  zram_materializer="$MODPATH/tools/zram/materialize-zram-choice.sh"
  zram_enabled="$(config_get ENABLE_ZRAM_100P)"

  [ -r "$zram_materializer" ] || thermal_abort "! ZRAM materializer missing"

  case "$zram_enabled" in
    1)
      MODDIR="$MODPATH" ZRAM_ACTIVE_DIR="$active_dir" ZRAM_CONFIG_FILE="$CONFIG_FILE" \
        sh "$zram_materializer" enable >/dev/null ||
        thermal_abort "! Failed to materialize active ZRAM fstab"
      ui_print "- ZRAM selection: enabled"
      ui_print "- Materialized ZRAM 100p layout"
    ;;
    *)
      MODDIR="$MODPATH" ZRAM_ACTIVE_DIR="$active_dir" ZRAM_CONFIG_FILE="$CONFIG_FILE" \
        sh "$zram_materializer" disable >/dev/null ||
        thermal_abort "! Failed to remove active ZRAM fstab"
      config_set ENABLE_ZRAM_100P 0
      config_set ZRAM_EMERALD_OC 0
      config_set ZRAM_RESTART_MMD 0
      config_set ZRAM_RISK_ACK disabled_by_user
      config_set ZRAM_EH_RISK_ACK disabled_by_user
      config_set LAST_ZRAM_100P disabled
      ui_print "- ZRAM selection: disabled"
      ui_print "- No ZRAM fstab materialized"
    ;;
  esac
}
