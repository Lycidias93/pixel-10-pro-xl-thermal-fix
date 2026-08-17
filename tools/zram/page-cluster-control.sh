#!/system/bin/sh
set -eu

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
CONFIG_FILE="${ZRAM_CONFIG_FILE:-/data/adb/$ID/config.env}"
STATE_DIR="${PAGE_CLUSTER_STATE_DIR:-/data/adb/$ID/page-cluster}"
STATUS_FILE="$STATE_DIR/status.env"
EVENT_LOG="$STATE_DIR/events.log"
PAGE_CLUSTER_PATH="${PAGE_CLUSTER_PATH:-/proc/sys/vm/page-cluster}"
SWAPS_FILE="${PAGE_CLUSTER_SWAPS_FILE:-/proc/swaps}"
BOOT_ID_FILE="${PAGE_CLUSTER_BOOT_ID_FILE:-/proc/sys/kernel/random/boot_id}"
CALLER="${PAGE_CLUSTER_CALLER:-unknown}"

cfg_get() {
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^$1=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^$1=//" | tr -d '\r'
}

boot_id() {
  [ -r "$BOOT_ID_FILE" ] && tr -d '\r\n' < "$BOOT_ID_FILE" 2>/dev/null || printf '%s' unknown
}

current_value() {
  [ -r "$PAGE_CLUSTER_PATH" ] && tr -d '\r\n' < "$PAGE_CLUSTER_PATH" 2>/dev/null || true
}

active_zram_swap() {
  [ -r "$SWAPS_FILE" ] || return 1
  first=1
  while IFS= read -r line; do
    if [ "$first" = 1 ]; then
      first=0
      continue
    fi
    [ -n "$line" ] || continue
    set -- $line
    swap_path="${1:-}"
    case "$swap_path" in
      /dev/block/zram[0-9]*|/dev/zram[0-9]*|zram[0-9]*) return 0 ;;
    esac
  done < "$SWAPS_FILE"
  return 1
}

write_status() {
  result="$1"
  mode="$2"
  baseline="$3"
  before="$4"
  after="$5"
  applied="$6"
  mkdir -p "$STATE_DIR" 2>/dev/null || true
  tmp="$STATUS_FILE.tmp.$$"
  {
    printf '%s\n' 'schema=pixel-thermal-page-cluster-v1'
    printf 'boot_id=%s\n' "$(boot_id)"
    printf 'caller=%s\n' "$CALLER"
    printf 'result=%s\n' "$result"
    printf 'mode=%s\n' "$mode"
    printf 'path=%s\n' "$PAGE_CLUSTER_PATH"
    printf 'baseline=%s\n' "${baseline:-unknown}"
    printf 'before=%s\n' "${before:-unknown}"
    printf 'after=%s\n' "${after:-unknown}"
    printf 'applied_by_module=%s\n' "$applied"
    printf 'zram_swap_active=%s\n' "$(active_zram_swap && printf yes || printf no)"
  } > "$tmp"
  chmod 0600 "$tmp" 2>/dev/null || true
  mv "$tmp" "$STATUS_FILE"
  printf '%s event=%s mode=%s caller=%s before=%s after=%s baseline=%s boot_id=%s\n' \
    "$(date -Is 2>/dev/null || date)" "$result" "$mode" "$CALLER" "${before:-unknown}" "${after:-unknown}" "${baseline:-unknown}" "$(boot_id)" >> "$EVENT_LOG" 2>/dev/null || true
  chmod 0600 "$EVENT_LOG" 2>/dev/null || true
}

status_field() {
  key="$1"
  [ -r "$STATUS_FILE" ] || return 0
  sed -n "s/^${key}=//p" "$STATUS_FILE" 2>/dev/null | tail -n 1
}

show_status() {
  current="$(current_value)"
  stamped_boot="$(status_field boot_id)"
  current_boot="$(boot_id)"
  applied="$(status_field applied_by_module)"
  effective=stock
  if [ "$stamped_boot" = "$current_boot" ] && [ "$applied" = yes ] && [ "$current" = 0 ]; then
    effective=experimental_zero
  fi
  printf 'PAGE_CLUSTER_PATH=%s\n' "$PAGE_CLUSTER_PATH"
  printf 'PAGE_CLUSTER_CURRENT=%s\n' "${current:-unavailable}"
  printf 'PAGE_CLUSTER_EFFECTIVE=%s\n' "$effective"
  printf 'PAGE_CLUSTER_EVIDENCE_BOOT=%s\n' "${stamped_boot:-none}"
  printf 'PAGE_CLUSTER_CURRENT_BOOT=%s\n' "$current_boot"
  printf 'PAGE_CLUSTER_APPLIED_BY_MODULE=%s\n' "${applied:-no}"
  printf 'PAGE_CLUSTER_ZRAM_SWAP_ACTIVE=%s\n' "$(active_zram_swap && printf yes || printf no)"
}

apply_zero() {
  if [ "$(cfg_get ENABLE_ZRAM_100P)" != 1 ] || [ "$(cfg_get ZRAM_RISK_ACK)" != explicit_user_enable ]; then
    write_status blocked zram_required '' "$(current_value)" "$(current_value)" no
    printf '%s\n' 'RESULT: PAGE_CLUSTER_ZERO_BLOCKED reason=zram_not_explicitly_enabled'
    return 2
  fi
  if ! active_zram_swap; then
    write_status blocked active_zram_required '' "$(current_value)" "$(current_value)" no
    printf '%s\n' 'RESULT: PAGE_CLUSTER_ZERO_BLOCKED reason=no_active_zram_swap'
    return 3
  fi
  [ -e "$PAGE_CLUSTER_PATH" ] && [ -w "$PAGE_CLUSTER_PATH" ] || {
    write_status blocked path_unavailable '' "$(current_value)" "$(current_value)" no
    printf '%s\n' 'RESULT: PAGE_CLUSTER_ZERO_BLOCKED reason=path_unavailable'
    return 4
  }

  before="$(current_value)"
  case "$before" in ''|*[!0-9]*)
    write_status blocked invalid_baseline '' "$before" "$before" no
    printf '%s\n' 'RESULT: PAGE_CLUSTER_ZERO_BLOCKED reason=invalid_baseline'
    return 5
  ;; esac

  baseline="$before"
  stamped_boot="$(status_field boot_id)"
  if [ "$stamped_boot" = "$(boot_id)" ] && [ "$(status_field applied_by_module)" = yes ]; then
    old_baseline="$(status_field baseline)"
    case "$old_baseline" in ''|*[!0-9]*) ;; *) baseline="$old_baseline" ;; esac
  fi

  if ! printf '%s' 0 > "$PAGE_CLUSTER_PATH" 2>/dev/null; then
    write_status failed experimental_zero "$baseline" "$before" "$(current_value)" no
    printf '%s\n' 'RESULT: PAGE_CLUSTER_ZERO_FAIL reason=write_rejected'
    return 6
  fi
  after="$(current_value)"
  if [ "$after" != 0 ]; then
    printf '%s' "$baseline" > "$PAGE_CLUSTER_PATH" 2>/dev/null || true
    write_status failed experimental_zero "$baseline" "$before" "$(current_value)" no
    printf '%s\n' 'RESULT: PAGE_CLUSTER_ZERO_FAIL reason=readback_mismatch'
    return 7
  fi

  write_status pass experimental_zero "$baseline" "$before" "$after" yes
  printf 'RESULT: PAGE_CLUSTER_ZERO_PASS before=%s after=%s baseline=%s\n' "$before" "$after" "$baseline"
}

restore_stock() {
  before="$(current_value)"
  stamped_boot="$(status_field boot_id)"
  current_boot="$(boot_id)"
  applied="$(status_field applied_by_module)"
  baseline="$(status_field baseline)"

  if [ "$stamped_boot" = "$current_boot" ] && [ "$applied" = yes ]; then
    case "$baseline" in ''|*[!0-9]*)
      write_status failed stock "$baseline" "$before" "$before" yes
      printf '%s\n' 'RESULT: PAGE_CLUSTER_RESTORE_FAIL reason=baseline_missing'
      return 8
    ;; esac
    [ -e "$PAGE_CLUSTER_PATH" ] && [ -w "$PAGE_CLUSTER_PATH" ] || {
      write_status failed stock "$baseline" "$before" "$before" yes
      printf '%s\n' 'RESULT: PAGE_CLUSTER_RESTORE_FAIL reason=path_unavailable'
      return 9
    }
    printf '%s' "$baseline" > "$PAGE_CLUSTER_PATH" 2>/dev/null || {
      write_status failed stock "$baseline" "$before" "$(current_value)" yes
      printf '%s\n' 'RESULT: PAGE_CLUSTER_RESTORE_FAIL reason=write_rejected'
      return 10
    }
    after="$(current_value)"
    if [ "$after" != "$baseline" ]; then
      write_status failed stock "$baseline" "$before" "$after" yes
      printf '%s\n' 'RESULT: PAGE_CLUSTER_RESTORE_FAIL reason=readback_mismatch'
      return 11
    fi
    write_status pass stock "$baseline" "$before" "$after" no
    printf 'RESULT: PAGE_CLUSTER_RESTORE_PASS before=%s after=%s baseline=%s\n' "$before" "$after" "$baseline"
    return 0
  fi

  write_status pass stock '' "$before" "$before" no
  printf 'RESULT: PAGE_CLUSTER_RESTORE_PASS before=%s after=%s baseline=not_owned_this_boot\n' "${before:-unavailable}" "${before:-unavailable}"
}

case "${1:-status}" in
  status) show_status ;;
  apply-zero) apply_zero ;;
  restore) restore_stock ;;
  *) printf '%s\n' 'usage: page-cluster-control.sh {status|apply-zero|restore}' >&2; exit 64 ;;
esac
