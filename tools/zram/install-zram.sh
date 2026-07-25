#!/system/bin/sh
# Install-time ZRAM materializer. Selection is owned by install-options-menu.sh.

thermal_install_zram() {
  zram_fstab_src="$MODPATH/tools/zram/fstab.zram.100p"
  zram_fstab_dst="$active_dir/fstab.zram.100p"
  zram_enabled="$(config_get ENABLE_ZRAM_100P)"

  case "$zram_enabled" in
    1)
      [ -s "$zram_fstab_src" ] || thermal_abort "! ZRAM layout template missing"
      mkdir -p "$active_dir"
      cp -fp "$zram_fstab_src" "$zram_fstab_dst" ||
        thermal_abort "! Failed to materialize active ZRAM fstab"
      chmod 0644 "$zram_fstab_dst" 2>/dev/null || true
      ui_print "- ZRAM selection: enabled"
      ui_print "- Materialized ZRAM 100p layout"
    ;;
    *)
      rm -f "$zram_fstab_dst" 2>/dev/null || true
      config_set ENABLE_ZRAM_100P 0
      config_set ZRAM_RESTART_MMD 0
      config_set ZRAM_RISK_ACK disabled_by_user
      ui_print "- ZRAM selection: disabled"
      ui_print "- No ZRAM fstab materialized"
    ;;
  esac
}
