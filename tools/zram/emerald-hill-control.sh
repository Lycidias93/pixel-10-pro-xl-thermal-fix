#!/system/bin/sh
# Optional Emerald Hill devfreq max-frequency lock for lz77eh ZRAM.
# This does not request a frequency above the kernel-exposed maximum OPP.
# It pins the user minimum to an admitted frequency and can increase power/heat.
set -eu

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-/data/adb/modules/$ID}"
CONFIG_FILE="${ZRAM_CONFIG_FILE:-/data/adb/$ID/config.env}"
STATE_DIR="${ZRAM_EH_STATE_DIR:-/data/adb/$ID/zram-eh}"
BASELINE_FILE="$STATE_DIR/baseline.tsv"
STATUS_FILE="$STATE_DIR/status.env"
NORMALIZE="$MODDIR/tools/zram/config-normalize.sh"
ROOTS="${ZRAM_EH_DEVFREQ_ROOTS:-/sys/class/devfreq/* /sys/devices/platform/*/devfreq/*}"
MODE="${1:-status}"

cfg_get() {
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^$1=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^$1=//" | tr -d '\r'
}

is_uint() {
  case "$1" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac
}

is_eh_node() {
  dir="$1"
  [ -d "$dir" ] || return 1
  [ -r "$dir/min_freq" ] || return 1
  [ -w "$dir/min_freq" ] || return 1
  [ -r "$dir/max_freq" ] || return 1
  label="${dir##*/} $(cat "$dir/name" 2>/dev/null || true)"
  lower="$(printf '%s' "$label" | tr 'A-Z' 'a-z')"
  case "$lower" in
    *emerald*|*lz77*|eh|eh.*|*.eh|*.eh.*|eh_freq|eh_freq\ *|eh-freq|eh-freq\ *|*eh-devfreq*) return 0 ;;
    *) return 1 ;;
  esac
}

frequency_available() {
  dir="$1"
  target="$2"
  file="$dir/available_frequencies"
  [ -s "$file" ] || return 0
  for value in $(cat "$file" 2>/dev/null || true); do
    [ "$value" = "$target" ] && return 0
  done
  return 1
}

status_write() {
  state="$1"
  detail="$2"
  nodes="$3"
  target="$4"
  mkdir -p "$STATE_DIR" 2>/dev/null || true
  tmp="$STATUS_FILE.tmp.$$"
  {
    printf '%s\n' 'schema=pixel-zram-eh-status-v1'
    printf '%s\n' "state=$state"
    printf '%s\n' "detail=$detail"
    printf '%s\n' "nodes=$nodes"
    printf '%s\n' "target=$target"
    printf '%s\n' "configured=$(cfg_get ZRAM_EMERALD_OC)"
    printf '%s\n' "last_choice=$(cfg_get LAST_ZRAM_100P)"
    printf '%s\n' "zram_enabled=$(cfg_get ENABLE_ZRAM_100P)"
    printf '%s\n' "updated_epoch=$(date +%s 2>/dev/null || printf unknown)"
  } > "$tmp"
  chmod 0600 "$tmp" 2>/dev/null || true
  mv "$tmp" "$STATUS_FILE"
}

restore_file() {
  source_file="$1"
  restored=0
  failed=0
  [ -s "$source_file" ] || return 0
  tab="$(printf '\t')"
  while IFS="$tab" read -r dir original_min observed_max target extra; do
    [ "$dir" = path ] && continue
    [ -n "$dir" ] || continue
    if [ -n "$extra" ] || ! is_uint "$original_min" || [ ! -w "$dir/min_freq" ]; then
      failed=$((failed + 1))
      continue
    fi
    if printf '%s\n' "$original_min" > "$dir/min_freq" 2>/dev/null &&
       [ "$(cat "$dir/min_freq" 2>/dev/null || true)" = "$original_min" ]; then
      restored=$((restored + 1))
    else
      failed=$((failed + 1))
    fi
  done < "$source_file"
  [ "$failed" -eq 0 ] 2>/dev/null
}

normalize_config() {
  if [ -r "$NORMALIZE" ]; then
    ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$NORMALIZE" >/dev/null 2>&1 || true
  fi
}

apply_lock() {
  normalize_config
  [ -r "$CONFIG_FILE" ] && . "$CONFIG_FILE" 2>/dev/null || true

  if [ "${ENABLE_ZRAM_100P:-0}" != 1 ] ||
     [ "${ZRAM_EMERALD_OC:-0}" != 1 ] ||
     [ "${LAST_ZRAM_100P:-}" != enabled ] ||
     [ "${ZRAM_RISK_ACK:-}" != explicit_user_enable ]; then
    status_write adaptive not_explicitly_authorized 0 none
    printf '%s\n' 'RESULT: ZRAM_EH_APPLY_REFUSED reason=explicit_choice_missing'
    return 3
  fi

  requested="${ZRAM_EH_TARGET_FREQ:-max}"
  case "$requested" in max) ;; *) is_uint "$requested" || {
    status_write failed invalid_target 0 "$requested"
    printf '%s\n' "RESULT: ZRAM_EH_APPLY_FAIL reason=invalid_target target=$requested"
    return 4
  } ;; esac

  mkdir -p "$STATE_DIR" 2>/dev/null || true
  chmod 0700 "$STATE_DIR" 2>/dev/null || true
  tmp="$BASELINE_FILE.tmp.$$"
  printf 'path\toriginal_min\tobserved_max\ttarget\n' > "$tmp"
  nodes=0
  target_summary=none

  for dir in $ROOTS; do
    is_eh_node "$dir" || continue
    original_min="$(cat "$dir/min_freq" 2>/dev/null || true)"
    observed_max="$(cat "$dir/max_freq" 2>/dev/null || true)"
    is_uint "$original_min" || continue
    is_uint "$observed_max" || continue
    [ "$observed_max" -gt 0 ] 2>/dev/null || continue

    if [ "$requested" = max ]; then
      target="$observed_max"
    else
      target="$requested"
      [ "$target" -le "$observed_max" ] 2>/dev/null || {
        restore_file "$tmp" >/dev/null 2>&1 || true
        rm -f "$tmp" 2>/dev/null || true
        status_write failed target_above_kernel_max "$nodes" "$target"
        printf '%s\n' "RESULT: ZRAM_EH_APPLY_FAIL reason=target_above_kernel_max target=$target max=$observed_max"
        return 5
      }
    fi

    frequency_available "$dir" "$target" || {
      restore_file "$tmp" >/dev/null 2>&1 || true
      rm -f "$tmp" 2>/dev/null || true
      status_write failed target_not_available "$nodes" "$target"
      printf '%s\n' "RESULT: ZRAM_EH_APPLY_FAIL reason=target_not_available path=$dir target=$target"
      return 6
    }

    printf '%s\t%s\t%s\t%s\n' "$dir" "$original_min" "$observed_max" "$target" >> "$tmp"
    if ! printf '%s\n' "$target" > "$dir/min_freq" 2>/dev/null ||
       [ "$(cat "$dir/min_freq" 2>/dev/null || true)" != "$target" ]; then
      restore_file "$tmp" >/dev/null 2>&1 || true
      rm -f "$tmp" 2>/dev/null || true
      status_write failed write_or_verify_failed "$nodes" "$target"
      printf '%s\n' "RESULT: ZRAM_EH_APPLY_FAIL reason=write_or_verify_failed path=$dir target=$target"
      return 7
    fi
    nodes=$((nodes + 1))
    target_summary="$target"
  done

  if [ "$nodes" -eq 0 ] 2>/dev/null; then
    rm -f "$tmp" 2>/dev/null || true
    status_write unsupported no_matching_devfreq_node 0 none
    printf '%s\n' 'RESULT: ZRAM_EH_APPLY_FAIL reason=no_matching_devfreq_node'
    return 8
  fi

  mv "$tmp" "$BASELINE_FILE"
  chmod 0600 "$BASELINE_FILE" 2>/dev/null || true
  status_write active max_frequency_lock_verified "$nodes" "$target_summary"
  printf '%s\n' "RESULT: ZRAM_EH_APPLY_DONE nodes=$nodes target=$target_summary policy=kernel_exposed_opp_only"
  return 0
}

restore_lock() {
  if [ ! -s "$BASELINE_FILE" ]; then
    status_write adaptive no_baseline 0 none
    printf '%s\n' 'RESULT: ZRAM_EH_RESTORE_DONE nodes=0 reason=no_baseline'
    return 0
  fi

  if restore_file "$BASELINE_FILE"; then
    nodes=$(( $(wc -l < "$BASELINE_FILE" 2>/dev/null || printf 1) - 1 ))
    [ "$nodes" -ge 0 ] 2>/dev/null || nodes=0
    rm -f "$BASELINE_FILE" 2>/dev/null || true
    status_write adaptive baseline_restored "$nodes" none
    printf '%s\n' "RESULT: ZRAM_EH_RESTORE_DONE nodes=$nodes"
    return 0
  fi

  status_write failed baseline_restore_incomplete 0 none
  printf '%s\n' 'RESULT: ZRAM_EH_RESTORE_FAIL reason=baseline_restore_incomplete'
  return 9
}

show_status() {
  [ -r "$STATUS_FILE" ] && cat "$STATUS_FILE" || {
    status_write unknown not_evaluated 0 none
    cat "$STATUS_FILE"
  }
  return 0
}

case "$MODE" in
  apply) apply_lock ;;
  restore|disable) restore_lock ;;
  status) show_status ;;
  *)
    printf '%s\n' "RESULT: ZRAM_EH_CONTROL_FAIL reason=invalid_mode mode=$MODE"
    exit 2
  ;;
esac
