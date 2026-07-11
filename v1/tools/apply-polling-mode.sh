#!/system/bin/sh
set -eu
MODDIR="${MODDIR:-${0%/*}/..}"
CONFIG_FILE="${CONFIG_FILE:-/data/adb/pixel-10-pro-xl-thermal-fix/config.env}"
BASE_PROFILE="${BASE_PROFILE:-}"
ACTIVE_DIR="${ACTIVE_DIR:-}"

cfg_get() { k="$1"; [ -r "$CONFIG_FILE" ] || return 0; grep -E "^${k}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${k}=//" | tr -d '\r'; }
cfg_set() { k="$1"; v="$2"; tmp="${CONFIG_FILE}.tmp.$$"; touch "$CONFIG_FILE" 2>/dev/null || true; grep -v "^${k}=" "$CONFIG_FILE" 2>/dev/null > "$tmp" || true; printf "%s=%s\n" "$k" "$v" >> "$tmp"; mv "$tmp" "$CONFIG_FILE"; chmod 0600 "$CONFIG_FILE" 2>/dev/null || true; }

copy_stock_polling_file() {
  src="$1"; dst="$2"; tmp="${dst}.polling.$$"
  [ -s "$src" ] || return 1
  [ -s "$dst" ] || return 1
  awk '
    FNR==NR { if ($0 ~ /"PollingDelay"[[:space:]]*:/) { p++; srcp[p]=$0 } if ($0 ~ /"PassiveDelay"[[:space:]]*:/) { q++; srcq[q]=$0 } next }
    { line=$0
      if (line ~ /"PollingDelay"[[:space:]]*:/) { pi++; if (pi in srcp) { v=srcp[pi]; sub(/^[^:]*:/, "", v); sub(/:.*/, ":" v, line) } }
      if (line ~ /"PassiveDelay"[[:space:]]*:/) { qi++; if (qi in srcq) { v=srcq[qi]; sub(/^[^:]*:/, "", v); sub(/:.*/, ":" v, line) } }
      print line
    }
  ' "$src" "$dst" > "$tmp" && mv "$tmp" "$dst"
}

mode="$(cfg_get THERMAL_POLLING_MODE)"; [ -n "$mode" ] || mode="mod"
case "$mode" in stock|mod) ;; *) mode="mod" ;; esac
if [ "$mode" = "mod" ]; then cfg_set THERMAL_POLLING_EFFECTIVE mod; echo "- Polling: Mod"; exit 0; fi

base_dir="$MODDIR/profiles/$BASE_PROFILE/system/vendor/etc"; changed=0
for f in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
  if [ -s "$base_dir/$f" ] && [ -s "$ACTIVE_DIR/$f" ]; then copy_stock_polling_file "$base_dir/$f" "$ACTIVE_DIR/$f" && changed=$(( changed + 1 )) || true; fi
done
cfg_set THERMAL_POLLING_EFFECTIVE stock
cfg_set THERMAL_POLLING_STOCK_FILES_CHANGED "$changed"
echo "- Polling: Stock"
exit 0
