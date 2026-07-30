#!/system/bin/sh
# Normalize Dev.12 ZRAM performance settings without creating remembered choices.
set -eu

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
CONFIG_FILE="${ZRAM_CONFIG_FILE:-/data/adb/$ID/config.env}"

cfg_get() {
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^$1=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^$1=//" | tr -d '\r'
}

cfg_set() {
  key="$1"
  value="$2"
  mkdir -p "${CONFIG_FILE%/*}" 2>/dev/null || true
  touch "$CONFIG_FILE" 2>/dev/null || true
  tmp="$CONFIG_FILE.tmp.$$"
  grep -v "^${key}=" "$CONFIG_FILE" 2>/dev/null > "$tmp" || true
  printf '%s=%s\n' "$key" "$value" >> "$tmp"
  chmod 0600 "$tmp" 2>/dev/null || true
  mv "$tmp" "$CONFIG_FILE"
}

oc="$(cfg_get ZRAM_EMERALD_OC)"
last="$(cfg_get LAST_ZRAM_100P)"

case "$oc" in
  0|1) ;;
  *)
    cfg_set ZRAM_EMERALD_OC 0
    oc=0
  ;;
esac

# A max-frequency lock is valid only when the dedicated menu choice was saved.
# Legacy/missing state is downgraded to adaptive hardware acceleration.
if [ "$oc" = 1 ] && [ "$last" != enabled ]; then
  cfg_set ZRAM_EMERALD_OC 0
  oc=0
fi

case "$(cfg_get ZRAM_EH_TARGET_FREQ)" in
  ''|*[!0-9]*) cfg_set ZRAM_EH_TARGET_FREQ max ;;
esac

case "$(cfg_get ZRAM_THP_MODE)" in
  stock|always|madvise|never) ;;
  *) cfg_set ZRAM_THP_MODE stock ;;
esac

swappiness="$(cfg_get ZRAM_SWAPPINESS)"
case "$swappiness" in
  ''|*[!0-9]*) cfg_set ZRAM_SWAPPINESS 100 ;;
  *)
    if [ "$swappiness" -gt 200 ] 2>/dev/null; then
      cfg_set ZRAM_SWAPPINESS 100
    fi
  ;;
esac

printf '%s\n' "RESULT: ZRAM_CONFIG_NORMALIZE_DONE oc=$oc target=$(cfg_get ZRAM_EH_TARGET_FREQ) thp=$(cfg_get ZRAM_THP_MODE) swappiness=$(cfg_get ZRAM_SWAPPINESS)"
exit 0
