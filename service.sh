#!/system/bin/sh
MODDIR=${0%/*}
LOG="$MODDIR/health.log"

boot_wait=0
while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ] && [ "$boot_wait" -lt 120 ]; do
  sleep 2
  boot_wait=$((boot_wait + 2))
done

# Read-only health evidence. This service never changes thermal values,
# never bind-mounts, and never patches runtime files.
sleep 60

{
  echo "timestamp=$(date +%s 2>/dev/null || echo unknown)"
  echo "module_dir=$MODDIR"
  echo "boot_completed=$(getprop sys.boot_completed 2>/dev/null || echo unknown)"
  echo "health_log_model=read_only_no_runtime_patch"
  echo "mount_check=best_effort_interactive_verify_is_authoritative"
  echo
  echo "== module =="
  if [ -r "$MODDIR/module.prop" ]; then
    cat "$MODDIR/module.prop"
  else
    echo "module_prop=missing"
  fi
  echo
  echo "== install-state =="
  if [ -r "$MODDIR/install-state.txt" ]; then
    cat "$MODDIR/install-state.txt"
  else
    echo "install_state=missing"
  fi
  echo
  echo "== flags =="
  [ ! -e "$MODDIR/disable" ] && echo "disable=absent" || echo "disable=present"
  [ ! -e "$MODDIR/skip_mount" ] && echo "skip_mount=absent" || echo "skip_mount=present"
  [ ! -e "$MODDIR/remove" ] && echo "remove=absent" || echo "remove=present"
  echo
  echo "== overlay-files =="
  for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
    if [ -s "$MODDIR/system/vendor/etc/$f" ]; then
      echo "module_file=present:$f"
      if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$MODDIR/system/vendor/etc/$f" | sed "s#  .*/#  #"
      fi
    else
      echo "module_file=missing:$f"
    fi
  done
  echo
  echo "== active-vendor-files =="
  for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
    if [ -s "/vendor/etc/$f" ]; then
      echo "vendor_file=present:$f"
      if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "/vendor/etc/$f" | sed "s#  .*/#  #"
      fi
    else
      echo "vendor_file=missing:$f"
    fi
  done
  echo
  echo "== mounts-best-effort =="
  for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
    if grep -F "$MODDIR/system/vendor/etc/$f" /proc/self/mountinfo >/dev/null 2>&1; then
      echo "mount_best_effort=present:$f"
    else
      echo "mount_best_effort=not_seen:$f"
    fi
  done
  echo
  echo "== tombstone quick check =="
  find /data/tombstones /data/system/dropbox -maxdepth 1 -type f 2>/dev/null | xargs -r grep -l "thermal\|Thermal" 2>/dev/null | tail -10
  echo
  echo "health_log_complete=yes"
} > "$LOG" 2>&1

exit 0
