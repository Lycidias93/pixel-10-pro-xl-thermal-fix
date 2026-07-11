#!/system/bin/sh
# Enable high risk pTune override and materialize the selected Thermal profile.
set -eu
MODULE_ID="pixel-10-pro-xl-thermal-fix"
MODDIR="${MODDIR:-/data/adb/modules/$MODULE_ID}"
STAGEDIR="/data/adb/modules_update/$MODULE_ID"
CONFIG_DIR="/data/adb/$MODULE_ID"
CONFIG_FILE="$CONFIG_DIR/config.env"
PTUNE_DIR="/data/adb/modules/ptune"

config_write() {
  mkdir -p "$CONFIG_DIR"
  {
    echo "PTUNE_GUARD_MODE=strict"
    echo "ALLOW_THERMAL_WITH_PTUNE=1"
    echo "RISK_ACK_PTUNE_THERMAL_COLLISION=I_UNDERSTAND_BOOTLOOP_RISK"
  } > "$CONFIG_FILE"
  chmod 0600 "$CONFIG_FILE" 2>/dev/null || true
}

materialize_one() {
  target="$1"
  [ -d "$target" ] || return 0
  
  THERMAL_OUTDOOR_PROFILE="stock"
  if [ -r "$CONFIG_FILE" ]; then
    THERMAL_OUTDOOR_PROFILE="$(grep -E "^THERMAL_OUTDOOR_PROFILE=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^THERMAL_OUTDOOR_PROFILE=//" | tr -d '\r')"
  fi
  [ -n "$THERMAL_OUTDOOR_PROFILE" ] || THERMAL_OUTDOOR_PROFILE="stock"

  THERMAL_POLLING_MODE="mod"
  if [ -r "$CONFIG_FILE" ]; then
    THERMAL_POLLING_MODE="$(grep -E "^THERMAL_POLLING_MODE=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^THERMAL_POLLING_MODE=//" | tr -d '\r')"
  fi
  [ -n "$THERMAL_POLLING_MODE" ] || THERMAL_POLLING_MODE="mod"

  # Run dynamic patcher orchestrator
  if [ -s "$target/tools/core/patch-thermal.sh" ]; then
    chmod 0755 "$target/tools/core/patch-thermal.sh" 2>/dev/null || true
    sh "$target/tools/core/patch-thermal.sh" "$THERMAL_POLLING_MODE" "$THERMAL_OUTDOOR_PROFILE" "$target" || { echo "ERROR: dynamic patching failed for $target" >&2; return 1; }
  else
    echo "ERROR: patch-thermal.sh missing in $target" >&2; return 1
  fi
  
  rm -f "$target/disable" "$target/skip_mount" "$target/remove" 2>/dev/null || true
  mkdir -p "$target/guard"
  echo "allow_thermal_with_ptune" > "$target/guard/guard_override"
  echo "$CONFIG_FILE" > "$target/guard/guard_override_source"
  echo "explicit_user_override" > "$target/guard/risk_ack"
  echo "$PTUNE_DIR" > "$target/guard/conflict_ptune_path"
  echo "override_allow_mount_with_ptune" > "$target/guard/conflict_guard_mode"
  echo "override_profile_materialized=dynamic" > "$target/guard/override_profile_materialized"
}

verify_one() {
  target="$1"
  [ -d "$target" ] || return 0
  ok=1
  for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do [ -s "$target/system/vendor/etc/$f" ] || ok=0; done
  [ ! -e "$target/skip_mount" ] || ok=0
  [ ! -e "$target/disable" ] || ok=0
  [ "$ok" = 1 ] || { echo "ERROR: override verify failed for $target" >&2; return 1; }
}

echo "== enable pTune override =="
date -Is 2>/dev/null || date
[ -d "$MODDIR" ] || { echo "ERROR: active module path missing: $MODDIR" >&2; exit 1; }
config_write
echo "selected_profile=dynamic"
echo "config_file=$CONFIG_FILE"
echo "risk_ack=I_UNDERSTAND_BOOTLOOP_RISK"
echo "warning=HIGH_RISK_BOOTLOOP_TEST"
materialize_one "$MODDIR"
materialize_one "$STAGEDIR"
verify_one "$MODDIR"
verify_one "$STAGEDIR"
echo; echo "== config =="; cat "$CONFIG_FILE"
echo; echo "== flags =="
for d in "$STAGEDIR" "$MODDIR" "$PTUNE_DIR"; do
  echo; echo "-- $d"
  [ -f "$d/module.prop" ] && grep -E "^(id=|name=|version=|versionCode=)" "$d/module.prop" || echo absent
  [ -e "$d/disable" ] && echo disable=present || echo disable=absent
  [ -e "$d/remove" ] && echo remove=present || echo remove=absent
  [ -e "$d/skip_mount" ] && echo skip_mount=present || echo skip_mount=absent
done
if [ -x "$MODDIR/tools/bootguard/compat-check.sh" ]; then echo; echo "== compat-check =="; sh "$MODDIR/tools/bootguard/compat-check.sh" || true; fi
echo "RESULT: ENABLE_PTUNE_OVERRIDE_DONE profile=dynamic"
