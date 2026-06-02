#!/system/bin/sh
MODDIR="${0%/*}"
LOG="$MODDIR/health.log"

until [ "$(getprop sys.boot_completed)" = "1" ]; do
  sleep 2
done
sleep 20

{
  echo "timestamp=$(date +%s 2>/dev/null || echo unknown)"
  echo "module_dir=$MODDIR"
  echo "== module =="
  grep -E "^(id|name|version|versionCode|description|updateJson)=" "$MODDIR/module.prop" 2>/dev/null || true
  echo "== install-state =="
  cat "$MODDIR/install-state.txt" 2>/dev/null || echo "install_state=missing"
  echo "== flags =="
  [ ! -e "$MODDIR/disable" ] && echo "disable=absent" || echo "disable=present"
  [ ! -e "$MODDIR/skip_mount" ] && echo "skip_mount=absent" || echo "skip_mount=present"
  echo "== mounts =="
  for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
    if grep -F "$MODDIR/system/vendor/etc/$f" /proc/self/mountinfo >/dev/null 2>&1; then
      echo "mount=present:$f"
    else
      echo "mount=absent:$f"
    fi
  done
  echo "== tombstone quick check =="
  ls -t /data/tombstones/tombstone_* 2>/dev/null | head -5 | while read -r t; do
    grep -l -i "thermal" "$t" 2>/dev/null || true
  done
  echo "health_log_model=read_only_no_runtime_patch"
} > "$LOG" 2>&1
