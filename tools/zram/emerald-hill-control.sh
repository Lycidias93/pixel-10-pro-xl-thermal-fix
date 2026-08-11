#!/system/bin/sh
# Optional Emerald Hill devfreq maximum-frequency minimum lock for lz77eh ZRAM.
# This never requests a frequency above the kernel-exposed maximum OPP.
# It can increase power and heat by preventing adaptive downclocking.
set -eu

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-/data/adb/modules/$ID}"
CONFIG_FILE="${ZRAM_CONFIG_FILE:-/data/adb/$ID/config.env}"
STATE_DIR="${ZRAM_EH_STATE_DIR:-${CONFIG_FILE%/*}/zram-eh}"
BASELINE_FILE="$STATE_DIR/baseline.tsv"
STATUS_FILE="$STATE_DIR/status.env"
EVENT_LOG="${ZRAM_EH_EVENT_LOG:-$STATE_DIR/events.log}"
EVENT_MAX_LINES="${ZRAM_EH_EVENT_MAX_LINES:-256}"
NORMALIZE="$MODDIR/tools/zram/config-normalize.sh"
ROOTS="${ZRAM_EH_DEVFREQ_ROOTS:-/sys/class/devfreq/* /sys/devices/platform/*/devfreq/*}"
MODE="${1:-status}"

STATUS_PATH=none
STATUS_ORIGINAL_MIN=none
STATUS_OBSERVED_MAX=none
STATUS_ALIASES_SKIPPED=0
RESTORE_NODES=0
RESTORE_ALIASES_SKIPPED=0
RESTORE_FAILED=0


event_count() {
  event_name="$1"
  [ -r "$EVENT_LOG" ] || { printf '%s\n' 0; return 0; }
  grep -c " event=$event_name " "$EVENT_LOG" 2>/dev/null || printf '%s\n' 0
}

event_append() {
  event_name="$1"
  outcome="$2"
  path="$3"
  original_min="$4"
  observed_max="$5"
  target="$6"
  readback="$7"
  nodes="$8"
  aliases="$9"
  detail="${10}"

  mkdir -p "$STATE_DIR" 2>/dev/null || true
  chmod 0700 "$STATE_DIR" 2>/dev/null || true
  epoch="$(date +%s 2>/dev/null || printf unknown)"
  boot_id="$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || printf unknown)"
  caller="${ZRAM_EH_CALLER:-$MODE}"
  printf '%s\n' \
    "epoch=$epoch boot_id=$boot_id caller=$caller event=$event_name outcome=$outcome path=$path original_min=$original_min observed_max=$observed_max target=$target readback=$readback nodes=$nodes aliases_skipped=$aliases detail=$detail" \
    >> "$EVENT_LOG" 2>/dev/null || true
  chmod 0600 "$EVENT_LOG" 2>/dev/null || true

  case "$EVENT_MAX_LINES" in ''|*[!0-9]*) EVENT_MAX_LINES=256 ;; esac
  [ "$EVENT_MAX_LINES" -ge 32 ] 2>/dev/null || EVENT_MAX_LINES=32
  line_count="$(wc -l < "$EVENT_LOG" 2>/dev/null | tr -d '[:space:]')"
  case "$line_count" in ''|*[!0-9]*) line_count=0 ;; esac
  if [ "$line_count" -gt "$EVENT_MAX_LINES" ] 2>/dev/null; then
    tmp="$EVENT_LOG.tmp.$$"
    tail -n "$EVENT_MAX_LINES" "$EVENT_LOG" > "$tmp" 2>/dev/null || true
    chmod 0600 "$tmp" 2>/dev/null || true
    mv "$tmp" "$EVENT_LOG" 2>/dev/null || true
  fi
}

cfg_get() {
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^$1=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^$1=//" | tr -d '\r'
}

is_uint() {
  case "$1" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac
}

canonical_dir() {
  dir="$1"
  resolved="$(readlink -f "$dir" 2>/dev/null || true)"
  if [ -n "$resolved" ]; then
    printf '%s\n' "$resolved"
    return 0
  fi
  (CDPATH= cd -- "$dir" 2>/dev/null && pwd -P) || printf '%s\n' "$dir"
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
    printf '%s\n' 'schema=pixel-zram-eh-status-v2'
    printf '%s\n' "state=$state"
    printf '%s\n' "detail=$detail"
    printf '%s\n' "nodes=$nodes"
    printf '%s\n' "aliases_skipped=$STATUS_ALIASES_SKIPPED"
    printf '%s\n' "path=$STATUS_PATH"
    printf '%s\n' "original_min=$STATUS_ORIGINAL_MIN"
    printf '%s\n' "observed_max=$STATUS_OBSERVED_MAX"
    printf '%s\n' "target=$target"
    printf '%s\n' 'apply_mode=one_shot_post_bootguard'
    printf '%s\n' "configured=$(cfg_get ZRAM_EMERALD_OC)"
    printf '%s\n' "eh_risk_ack=$(cfg_get ZRAM_EH_RISK_ACK)"
    printf '%s\n' "last_choice=$(cfg_get LAST_ZRAM_100P)"
    printf '%s\n' "zram_enabled=$(cfg_get ENABLE_ZRAM_100P)"
    printf '%s\n' "event_log=$EVENT_LOG"
    printf '%s\n' "apply_events=$(event_count apply)"
    printf '%s\n' "restore_events=$(event_count restore)"
    printf '%s\n' "updated_epoch=$(date +%s 2>/dev/null || printf unknown)"
  } > "$tmp"
  chmod 0600 "$tmp" 2>/dev/null || true
  mv "$tmp" "$STATUS_FILE"
}

restore_file() {
  source_file="$1"
  RESTORE_NODES=0
  RESTORE_ALIASES_SKIPPED=0
  RESTORE_FAILED=0
  [ -s "$source_file" ] || return 0

  seen="$STATE_DIR/restore-seen.tmp.$$"
  : > "$seen"
  tab="$(printf '\t')"

  while IFS="$tab" read -r c1 c2 c3 c4 c5 extra; do
    [ "$c1" = path ] && continue
    [ -n "$c1" ] || continue

    if [ -n "$c5" ]; then
      dir="$c1"
      identity="$c2"
      original_min="$c3"
    else
      dir="$c1"
      identity="$(canonical_dir "$dir")"
      original_min="$c2"
    fi

    if [ -n "$extra" ] || ! is_uint "$original_min" || [ ! -w "$dir/min_freq" ]; then
      RESTORE_FAILED=$((RESTORE_FAILED + 1))
      continue
    fi

    [ -n "$identity" ] || identity="$(canonical_dir "$dir")"
    if grep -Fqx "$identity" "$seen" 2>/dev/null; then
      RESTORE_ALIASES_SKIPPED=$((RESTORE_ALIASES_SKIPPED + 1))
      continue
    fi
    printf '%s\n' "$identity" >> "$seen"

    if printf '%s\n' "$original_min" > "$dir/min_freq" 2>/dev/null &&
       [ "$(cat "$dir/min_freq" 2>/dev/null || true)" = "$original_min" ]; then
      RESTORE_NODES=$((RESTORE_NODES + 1))
    else
      RESTORE_FAILED=$((RESTORE_FAILED + 1))
    fi
  done < "$source_file"

  rm -f "$seen" 2>/dev/null || true
  [ "$RESTORE_FAILED" -eq 0 ] 2>/dev/null
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
     [ "${LAST_ZRAM_100P:-}" != enabled_max_lock ] ||
     [ "${ZRAM_RISK_ACK:-}" != explicit_user_enable ] ||
     [ "${ZRAM_EH_RISK_ACK:-}" != explicit_user_enable_max_lock ]; then
    STATUS_ALIASES_SKIPPED=0
    event_append apply refused none none none none none 0 0 explicit_max_lock_choice_missing
    status_write adaptive not_explicitly_authorized 0 none
    printf '%s\n' 'RESULT: ZRAM_EH_APPLY_REFUSED reason=explicit_max_lock_choice_missing'
    return 3
  fi

  requested="${ZRAM_EH_TARGET_FREQ:-max}"
  case "$requested" in
    max) ;;
    *)
      is_uint "$requested" || {
        status_write failed invalid_target 0 "$requested"
        printf '%s\n' "RESULT: ZRAM_EH_APPLY_FAIL reason=invalid_target target=$requested"
        return 4
      }
    ;;
  esac

  mkdir -p "$STATE_DIR" 2>/dev/null || true
  chmod 0700 "$STATE_DIR" 2>/dev/null || true
  tmp="$BASELINE_FILE.tmp.$$"
  seen="$STATE_DIR/apply-seen.tmp.$$"
  printf 'path\tcanonical_path\toriginal_min\tobserved_max\ttarget\n' > "$tmp"
  : > "$seen"

  nodes=0
  aliases_skipped=0
  target_summary=none
  first_path=none
  first_original=none
  first_max=none

  for dir in $ROOTS; do
    is_eh_node "$dir" || continue
    identity="$(canonical_dir "$dir")"
    if grep -Fqx "$identity" "$seen" 2>/dev/null; then
      aliases_skipped=$((aliases_skipped + 1))
      continue
    fi
    printf '%s\n' "$identity" >> "$seen"

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
        rm -f "$tmp" "$seen" 2>/dev/null || true
        STATUS_ALIASES_SKIPPED="$aliases_skipped"
        status_write failed target_above_kernel_max "$nodes" "$target"
        printf '%s\n' "RESULT: ZRAM_EH_APPLY_FAIL reason=target_above_kernel_max target=$target max=$observed_max"
        return 5
      }
    fi

    frequency_available "$dir" "$target" || {
      restore_file "$tmp" >/dev/null 2>&1 || true
      rm -f "$tmp" "$seen" 2>/dev/null || true
      STATUS_ALIASES_SKIPPED="$aliases_skipped"
      status_write failed target_not_available "$nodes" "$target"
      printf '%s\n' "RESULT: ZRAM_EH_APPLY_FAIL reason=target_not_available path=$dir target=$target"
      return 6
    }

    printf '%s\t%s\t%s\t%s\t%s\n' "$dir" "$identity" "$original_min" "$observed_max" "$target" >> "$tmp"
    if ! printf '%s\n' "$target" > "$dir/min_freq" 2>/dev/null ||
       [ "$(cat "$dir/min_freq" 2>/dev/null || true)" != "$target" ]; then
      restore_file "$tmp" >/dev/null 2>&1 || true
      rm -f "$tmp" "$seen" 2>/dev/null || true
      STATUS_ALIASES_SKIPPED="$aliases_skipped"
      status_write failed write_or_verify_failed "$nodes" "$target"
      printf '%s\n' "RESULT: ZRAM_EH_APPLY_FAIL reason=write_or_verify_failed path=$dir target=$target"
      return 7
    fi

    nodes=$((nodes + 1))
    target_summary="$target"
    if [ "$first_path" = none ]; then
      first_path="$dir"
      first_original="$original_min"
      first_max="$observed_max"
    fi
  done

  rm -f "$seen" 2>/dev/null || true

  if [ "$nodes" -eq 0 ] 2>/dev/null; then
    rm -f "$tmp" 2>/dev/null || true
    STATUS_ALIASES_SKIPPED="$aliases_skipped"
    event_append apply failure none none none none none 0 "$aliases_skipped" no_matching_devfreq_node
    status_write unsupported no_matching_devfreq_node 0 none
    printf '%s\n' 'RESULT: ZRAM_EH_APPLY_FAIL reason=no_matching_devfreq_node'
    return 8
  fi

  mv "$tmp" "$BASELINE_FILE"
  chmod 0600 "$BASELINE_FILE" 2>/dev/null || true
  STATUS_ALIASES_SKIPPED="$aliases_skipped"
  STATUS_PATH="$first_path"
  STATUS_ORIGINAL_MIN="$first_original"
  STATUS_OBSERVED_MAX="$first_max"
  readback="$(cat "$first_path/min_freq" 2>/dev/null || printf unknown)"
  event_append apply success "$first_path" "$first_original" "$first_max" "$target_summary" "$readback" "$nodes" "$aliases_skipped" max_frequency_minimum_lock_verified
  status_write active max_frequency_minimum_lock_verified "$nodes" "$target_summary"
  printf '%s\n' "RESULT: ZRAM_EH_APPLY_DONE nodes=$nodes aliases_skipped=$aliases_skipped target=$target_summary policy=kernel_exposed_opp_only"
  return 0
}

restore_lock() {
  if [ ! -s "$BASELINE_FILE" ]; then
    STATUS_ALIASES_SKIPPED=0
    event_append restore no_op none none none none none 0 0 no_baseline
    status_write adaptive no_baseline 0 none
    printf '%s\n' 'RESULT: ZRAM_EH_RESTORE_DONE nodes=0 aliases_skipped=0 reason=no_baseline'
    return 0
  fi

  if restore_file "$BASELINE_FILE"; then
    rm -f "$BASELINE_FILE" 2>/dev/null || true
    STATUS_ALIASES_SKIPPED="$RESTORE_ALIASES_SKIPPED"
    event_append restore success none none none none none "$RESTORE_NODES" "$RESTORE_ALIASES_SKIPPED" baseline_restored
    status_write adaptive baseline_restored "$RESTORE_NODES" none
    printf '%s\n' "RESULT: ZRAM_EH_RESTORE_DONE nodes=$RESTORE_NODES aliases_skipped=$RESTORE_ALIASES_SKIPPED"
    return 0
  fi

  STATUS_ALIASES_SKIPPED="$RESTORE_ALIASES_SKIPPED"
  event_append restore failure none none none none none "$RESTORE_NODES" "$RESTORE_ALIASES_SKIPPED" baseline_restore_incomplete
  status_write failed baseline_restore_incomplete "$RESTORE_NODES" none
  printf '%s\n' "RESULT: ZRAM_EH_RESTORE_FAIL reason=baseline_restore_incomplete restored=$RESTORE_NODES failed=$RESTORE_FAILED aliases_skipped=$RESTORE_ALIASES_SKIPPED"
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
