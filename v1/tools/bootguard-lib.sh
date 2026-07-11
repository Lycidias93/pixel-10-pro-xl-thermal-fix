#!/system/bin/sh
set -eu

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-/data/adb/modules/$ID}"
CONFIG_FILE="${CONFIG_FILE:-/data/adb/$ID/config.env}"
G="$MODDIR/guard"
L="$G/bootguard.log"
mkdir -p "$G" 2>/dev/null || true

log() { echo "$(date -Is 2>/dev/null || date) BOOTGUARD_V2 $*" >> "$L" 2>/dev/null || true; }

cfg_get() {
  k="$1"
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^${k}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${k}=//" | tr -d '\r'
}

num_or_zero() {
  v="$1"
  case "$v" in ''|*[!0-9]*) echo 0 ;; *) echo "$v" ;; esac
}

threshold() {
  t="$(cfg_get BOOTGUARD_FAIL_THRESHOLD)"
  t="$(num_or_zero "$t")"
  [ "$t" -ge 1 ] 2>/dev/null || t=1
  [ "$t" -le 5 ] 2>/dev/null || t=5
  echo "$t"
}

config_hash() {
  if [ -r "$CONFIG_FILE" ]; then sha256sum "$CONFIG_FILE" 2>/dev/null | awk '{print $1}'; else echo missing; fi
}

profile_name() {
  sed -n 's/^profile=//p' "$MODDIR/install-state.txt" 2>/dev/null | tail -n 1
}

overlay_hash() {
  d="$MODDIR/system/vendor/etc"
  for f in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
    [ -s "$d/$f" ] && sha256sum "$d/$f" 2>/dev/null
  done | sha256sum 2>/dev/null | awk '{print $1}'
}

ptune_state() {
  for d in /data/adb/modules_update/ptune /data/adb/modules/ptune; do
    [ -f "$d/module.prop" ] || continue
    grep -q '^id=ptune$' "$d/module.prop" 2>/dev/null || continue
    state=active
    [ -e "$d/disable" ] && state=disabled
    [ -e "$d/remove" ] && state=remove
    vc="$(grep -E '^versionCode=' "$d/module.prop" 2>/dev/null | tail -n 1 | sed 's/^versionCode=//')"
    echo "${d}:${state}:versionCode=${vc:-unknown}"
    return 0
  done
  echo absent
}

write_snapshot() {
  out="$1"
  tmp="$out.tmp.$$"
  {
    echo "timestamp=$(date -Is 2>/dev/null || date)"
    echo "boot_id=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo unknown)"
    echo "device=$(getprop ro.product.device 2>/dev/null || echo unknown)"
    echo "model=$(getprop ro.product.model 2>/dev/null || echo unknown)"
    echo "build_id=$(getprop ro.build.id 2>/dev/null || echo unknown)"
    echo "incremental=$(getprop ro.build.version.incremental 2>/dev/null || echo unknown)"
    echo "fingerprint=$(getprop ro.build.fingerprint 2>/dev/null || echo unknown)"
    echo "module_version=$(grep -E '^version=' "$MODDIR/module.prop" 2>/dev/null | tail -n 1 | sed 's/^version=//')"
    echo "module_version_code=$(grep -E '^versionCode=' "$MODDIR/module.prop" 2>/dev/null | tail -n 1 | sed 's/^versionCode=//')"
    echo "config_sha256=$(config_hash)"
    echo "profile=$(profile_name)"
    echo "overlay_sha256=$(overlay_hash)"
    echo "ptune=$(ptune_state)"
    echo "thermal_profile=$(cfg_get THERMAL_OUTDOOR_PROFILE)"
    echo "thermal_polling=$(cfg_get THERMAL_POLLING_MODE)"
    echo "zram_enabled=$(cfg_get ENABLE_ZRAM_100P)"
    echo "disable=$([ -e "$MODDIR/disable" ] && echo present || echo absent)"
    echo "skip_mount=$([ -e "$MODDIR/skip_mount" ] && echo present || echo absent)"
    echo "remove=$([ -e "$MODDIR/remove" ] && echo present || echo absent)"
  } > "$tmp" 2>/dev/null || true
  mv "$tmp" "$out" 2>/dev/null || true
  chmod 0600 "$out" 2>/dev/null || true
}

preflight() {
  [ -e "$MODDIR/remove" ] && { log "preflight skip remove_present"; return 0; }
  [ -e "$MODDIR/disable" ] && { log "preflight skip disable_present"; return 0; }

  pending="$G/pending_boot"
  fail_file="$G/fail_count"
  last="$G/last_attempt.env"
  thresh="$(threshold)"

  if [ -s "$pending" ]; then
    old="$(cat "$fail_file" 2>/dev/null || echo 0)"
    old="$(num_or_zero "$old")"
    new=$((old + 1))
    echo "$new" > "$fail_file" 2>/dev/null || true
    cp -fp "$pending" "$G/previous_pending_boot" 2>/dev/null || true
    log "previous_pending_detected fail_count=$new threshold=$thresh"
    if [ "$new" -ge "$thresh" ]; then
      echo "bootguard_v2_fail_threshold fail_count=$new threshold=$thresh" > "$G/disabled_reason" 2>/dev/null || true
      echo "bootguard_v2_self_disable" > "$G/conflict_guard_mode" 2>/dev/null || true
      touch "$MODDIR/disable" 2>/dev/null || true
      touch "$MODDIR/skip_mount" 2>/dev/null || true
      log "self_disable_set fail_count=$new threshold=$thresh action=disable_and_skip_mount_next_boot"
      return 0
    fi
  else
    echo 0 > "$fail_file" 2>/dev/null || true
    log "no_previous_pending fail_count=0"
  fi

  write_snapshot "$last"
  cp -fp "$last" "$pending" 2>/dev/null || true
  echo "$(date -Is 2>/dev/null || date)" > "$G/pending_boot_started_at" 2>/dev/null || true
  log "pending_boot_set threshold=$thresh"
}

success() {
  [ -e "$MODDIR/disable" ] && { log "success skip disable_present"; return 0; }
  write_snapshot "$G/last_good.env"
  rm -f "$G/pending_boot" "$G/pending_boot_started_at" 2>/dev/null || true
  echo 0 > "$G/fail_count" 2>/dev/null || true
  echo "$(date -Is 2>/dev/null || date)" > "$G/last_success_at" 2>/dev/null || true
  log "boot_success last_good_updated fail_count=0"
}

status() {
  echo "Bootguard v2 Status"
  echo "pending_boot=$([ -s "$G/pending_boot" ] && echo present || echo absent)"
  echo "fail_count=$(cat "$G/fail_count" 2>/dev/null || echo 0)"
  echo "threshold=$(threshold)"
  echo "disable=$([ -e "$MODDIR/disable" ] && echo present || echo absent)"
  echo "skip_mount=$([ -e "$MODDIR/skip_mount" ] && echo present || echo absent)"
  echo "disabled_reason=$(cat "$G/disabled_reason" 2>/dev/null || echo none)"
  echo "last_success_at=$(cat "$G/last_success_at" 2>/dev/null || echo never)"
  echo "last_good=$([ -s "$G/last_good.env" ] && echo present || echo absent)"
}

clear_state() {
  rm -f "$G/pending_boot" "$G/pending_boot_started_at" "$G/previous_pending_boot" "$G/last_attempt.env" 2>/dev/null || true
  echo 0 > "$G/fail_count" 2>/dev/null || true
  log "state_clear counters_only disable_preserved=$([ -e "$MODDIR/disable" ] && echo yes || echo no)"
  echo "Bootguard counters cleared. disable marker preserved."
}

case "${1:-status}" in
  preflight) preflight ;;
  success) success ;;
  status) status ;;
  clear) clear_state ;;
  snapshot) write_snapshot "${2:-$G/manual_snapshot.env}" ;;
  *) echo "Usage: bootguard-lib.sh preflight|success|status|clear|snapshot [path]"; exit 2 ;;
esac
