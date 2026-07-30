#!/system/bin/sh
# Disable pTune override without discarding unrelated module configuration.
set -eu

MODULE_ID="pixel-10-pro-xl-thermal-fix"
MODDIR="${MODDIR:-/data/adb/modules/$MODULE_ID}"
STAGEDIR="${STAGEDIR:-/data/adb/modules_update/$MODULE_ID}"
CONFIG_DIR="${THERMAL_CONFIG_DIR:-/data/adb/$MODULE_ID}"
CONFIG_FILE="$CONFIG_DIR/config.env"
PTUNE_ROOTS="${PTUNE_MODULE_ROOTS:-/data/adb/modules/ptune /data/adb/modules_update/ptune}"

cfg_set() {
  key="$1"
  value="$2"
  mkdir -p "$CONFIG_DIR"
  touch "$CONFIG_FILE"
  tmp="$CONFIG_FILE.tmp.$$"
  grep -v "^${key}=" "$CONFIG_FILE" 2>/dev/null > "$tmp" || true
  printf '%s=%s\n' "$key" "$value" >> "$tmp"
  chmod 0600 "$tmp" 2>/dev/null || true
  mv "$tmp" "$CONFIG_FILE"
}

cfg_set PTUNE_GUARD_MODE strict
cfg_set ALLOW_THERMAL_WITH_PTUNE 0
cfg_set PTUNE_OVERRIDE_MENU off
cfg_set RISK_ACK_PTUNE_THERMAL_COLLISION none
cfg_set LAST_PTUNE_OVERRIDE 0

ptune_present=0
ptune_path=none
for p in $PTUNE_ROOTS; do
  [ -f "$p/module.prop" ] || continue
  grep -q '^id=ptune$' "$p/module.prop" 2>/dev/null || continue
  [ -e "$p/remove" ] && continue
  ptune_present=1
  ptune_path="$p"
  break
done

for d in "$MODDIR" "$STAGEDIR"; do
  [ -d "$d" ] || continue
  rm -f "$d/disable" "$d/remove" 2>/dev/null || true
  mkdir -p "$d/guard"
  rm -f \
    "$d/guard/guard_override" \
    "$d/guard/guard_override_source" \
    "$d/guard/risk_ack" \
    "$d/guard/ptune_risk_ack" \
    "$d/guard/override_profile_materialized" 2>/dev/null || true

  if [ "$ptune_present" = 1 ]; then
    touch "$d/skip_mount"
    printf '%s\n' conflict_ptune_installed > "$d/guard/disabled_reason"
    printf '%s\n' strict_presence_skip_mount > "$d/guard/conflict_guard_mode"
    printf '%s\n' "$ptune_path" > "$d/guard/conflict_ptune_path"
  else
    rm -f \
      "$d/skip_mount" \
      "$d/guard/disabled_reason" \
      "$d/guard/conflict_guard_mode" \
      "$d/guard/conflict_ptune_path" 2>/dev/null || true
  fi
done

printf '%s\n' "PTUNE_OVERRIDE_DISABLED=yes"
printf '%s\n' "PTUNE_PRESENT=$ptune_present"
printf '%s\n' "CONFIG_FILE=$CONFIG_FILE"
if [ -x "$MODDIR/tools/bootguard/compat-check.sh" ]; then
  sh "$MODDIR/tools/bootguard/compat-check.sh" || true
fi
printf '%s\n' "RESULT: DISABLE_PTUNE_OVERRIDE_DONE config_preserved=yes"
