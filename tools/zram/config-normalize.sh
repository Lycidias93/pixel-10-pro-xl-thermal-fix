#!/system/bin/sh
# Normalize Dev.14 ZRAM settings and migrate every legacy Emerald Hill lock
# state to the safe adaptive hardware-acceleration default.
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

enabled="$(cfg_get ENABLE_ZRAM_100P)"
oc="$(cfg_get ZRAM_EMERALD_OC)"
last="$(cfg_get LAST_ZRAM_100P)"
eh_ack="$(cfg_get ZRAM_EH_RISK_ACK)"
migrated=none

case "$enabled" in 0|1) ;; *) enabled='' ;; esac
case "$oc" in 0|1) ;; *) oc=0; cfg_set ZRAM_EMERALD_OC 0 ;; esac
case "$eh_ack" in explicit_user_enable_max_lock|none|disabled_by_user) ;; *) eh_ack=none; cfg_set ZRAM_EH_RISK_ACK none ;; esac

# Dev.13 used LAST_ZRAM_100P=enabled without a dedicated EH acknowledgement.
# It is always migrated to adaptive so an old duplicate baseline cannot relock.
if [ "$last" = enabled ]; then
  last=enabled_standard
  oc=0
  eh_ack=none
  cfg_set LAST_ZRAM_100P enabled_standard
  cfg_set ZRAM_EMERALD_OC 0
  cfg_set ZRAM_EH_RISK_ACK none
  migrated=legacy_enabled_to_adaptive
fi

case "$last" in
  disabled|enabled_standard|enabled_max_lock) ;;
  *)
    case "$enabled" in
      1) last=enabled_standard; cfg_set LAST_ZRAM_100P enabled_standard ;;
      0) last=disabled; cfg_set LAST_ZRAM_100P disabled ;;
      *) last='' ;;
    esac
  ;;
esac

if [ "$oc" = 1 ]; then
  if [ "$last" != enabled_max_lock ] || [ "$eh_ack" != explicit_user_enable_max_lock ]; then
    oc=0
    eh_ack=none
    [ "$enabled" = 1 ] && last=enabled_standard
    cfg_set ZRAM_EMERALD_OC 0
    cfg_set ZRAM_EH_RISK_ACK none
    [ "$enabled" = 1 ] && cfg_set LAST_ZRAM_100P enabled_standard
    migrated=unauthorized_lock_to_adaptive
  fi
else
  if [ "$last" = enabled_max_lock ]; then
    last=enabled_standard
    cfg_set LAST_ZRAM_100P enabled_standard
    migrated=inconsistent_choice_to_adaptive
  fi
  if [ "$eh_ack" = explicit_user_enable_max_lock ]; then
    eh_ack=none
    cfg_set ZRAM_EH_RISK_ACK none
  fi
fi

case "$(cfg_get ZRAM_EH_TARGET_FREQ)" in
  max) ;;
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


# Dev.20 consolidates LMKD handling into apply-zram-100p.sh. Migrate the old
# early-test choice once, then disable the obsolete keys and evidence path.
lmkd_reload="$(cfg_get LMKD_SWAP_LOW_RELOAD)"
lmkd_reload_ack="$(cfg_get LMKD_SWAP_LOW_RISK_ACK)"
old_lmkd_enabled="$(cfg_get LMKD_EARLY_SWAP_LOW_TEST)"
old_lmkd_ack="$(cfg_get LMKD_EARLY_SWAP_LOW_RISK_ACK)"
if [ -z "$lmkd_reload" ]; then
  if [ "$old_lmkd_enabled" = 1 ] && [ "$old_lmkd_ack" = explicit_user_test ]; then
    lmkd_reload=1
    lmkd_reload_ack=explicit_user_reload
    cfg_set LAST_LMKD_SWAP_LOW_RELOAD enabled
  else
    lmkd_reload=0
    lmkd_reload_ack=none
    cfg_set LAST_LMKD_SWAP_LOW_RELOAD disabled
  fi
  cfg_set LMKD_SWAP_LOW_RELOAD "$lmkd_reload"
  cfg_set LMKD_SWAP_LOW_RISK_ACK "$lmkd_reload_ack"
fi
case "$lmkd_reload" in 0|1) ;; *) lmkd_reload=0; cfg_set LMKD_SWAP_LOW_RELOAD 0 ;; esac
case "$lmkd_reload_ack" in explicit_user_reload|none) ;; *) lmkd_reload_ack=none; cfg_set LMKD_SWAP_LOW_RISK_ACK none ;; esac
cfg_set LMKD_EARLY_SWAP_LOW_TEST 0
cfg_set LMKD_EARLY_SWAP_LOW_RISK_ACK none
cfg_set LAST_LMKD_EARLY_SWAP_LOW_TEST disabled
rm -rf "${CONFIG_FILE%/*}/lmkd-test" 2>/dev/null || true

printf '%s\n' "RESULT: ZRAM_CONFIG_NORMALIZE_DONE oc=$oc last=${last:-unset} eh_ack=${eh_ack:-none} migrated=$migrated target=$(cfg_get ZRAM_EH_TARGET_FREQ) thp=$(cfg_get ZRAM_THP_MODE) swappiness=$(cfg_get ZRAM_SWAPPINESS) lmkd_reload=$lmkd_reload lmkd_ack=$lmkd_reload_ack"
exit 0
