#!/system/bin/sh
# Pixel 10 Thermal & Memory Control - install-time ZRAM helper.
# Extracted from customize.sh for Test25.

thermal_install_zram() {
  zram_fstab_src="$MODPATH/tools/fstab.zram.100p"
  if [ -s "$zram_fstab_src" ]; then
    mkdir -p "$active_dir"
    cp -fp "$zram_fstab_src" "$active_dir/fstab.zram.100p" || thermal_abort "! Failed to materialize active ZRAM fstab"
    chmod 0644 "$active_dir/fstab.zram.100p" 2>/dev/null || true
    ui_print "- Materialized ZRAM fstab layout"
  else
    ui_print "! ZRAM layout template missing"
  fi

  if [ -s "$MODPATH/tools/zram-menu.sh" ]; then
    chmod 0755 "$MODPATH/tools/zram-menu.sh" 2>/dev/null || true
    MODDIR="$MODPATH" sh "$MODPATH/tools/zram-menu.sh" install || ui_print "! ZRAM menu failed nonfatal; keeping existing/safe config"
  else
    ui_print "! ZRAM menu helper missing; keeping existing/safe config"
  fi
}
