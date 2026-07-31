#!/system/bin/sh
# Enable high risk pTune override only after validated Thermal materialization.
set -eu
MODULE_ID="pixel-10-pro-xl-thermal-fix"
MODDIR="${MODDIR:-/data/adb/modules/$MODULE_ID}"
STAGEDIR="/data/adb/modules_update/$MODULE_ID"
CONFIG_DIR="/data/adb/$MODULE_ID"
CONFIG_FILE="$CONFIG_DIR/config.env"
PTUNE_DIR="/data/adb/modules/ptune"

cfg_get() {
  _key="$1"
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^${_key}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${_key}=//" | tr -d '\r'
}

cfg_set() {
  _key="$1"
  _value="$2"
  mkdir -p "$CONFIG_DIR"
  touch "$CONFIG_FILE"
  _tmp="$CONFIG_FILE.tmp.$$"
  grep -v "^${_key}=" "$CONFIG_FILE" 2>/dev/null > "$_tmp" || true
  printf '%s=%s\n' "$_key" "$_value" >> "$_tmp"
  mv "$_tmp" "$CONFIG_FILE"
  chmod 0600 "$CONFIG_FILE" 2>/dev/null || true
}

THERMAL_OUTDOOR_PROFILE="$(cfg_get THERMAL_OUTDOOR_PROFILE)"
THERMAL_POLLING_MODE="$(cfg_get THERMAL_POLLING_MODE)"
[ -n "$THERMAL_OUTDOOR_PROFILE" ] || THERMAL_OUTDOOR_PROFILE=stock
[ -n "$THERMAL_POLLING_MODE" ] || THERMAL_POLLING_MODE=mod

materialize_one() {
  target="$1"
  [ -d "$target" ] || return 0
  validator="$target/tools/core/patch-thermal-validated.sh"
  if [ -s "$validator" ]; then
    chmod 0755 "$validator" 2>/dev/null || true
    sh "$validator" "$THERMAL_POLLING_MODE" "$THERMAL_OUTDOOR_PROFILE" "$target" || {
      echo "ERROR: validated Thermal materialization failed for $target" >&2
      return 1
    }
  else
    echo "ERROR: patch-thermal-validated.sh missing in $target" >&2
    return 1
  fi
}

verify_one() {
  target="$1"
  [ -d "$target" ] || return 0
  ok=1
  for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
    [ -s "$target/system/vendor/etc/$f" ] || ok=0
  done
  [ -s "$target/guard/outdoor-delta-validation.env" ] || ok=0
  [ "$ok" = 1 ] || {
    echo "ERROR: validated override verify failed for $target" >&2
    return 1
  }
}

mark_override_one() {
  target="$1"
  [ -d "$target" ] || return 0
  rm -f "$target/disable" "$target/skip_mount" "$target/remove" 2>/dev/null || true
  mkdir -p "$target/guard"
  echo "allow_thermal_with_ptune" > "$target/guard/guard_override"
  echo "$CONFIG_FILE" > "$target/guard/guard_override_source"
  echo "explicit_user_override" > "$target/guard/risk_ack"
  echo "$PTUNE_DIR" > "$target/guard/conflict_ptune_path"
  echo "override_allow_mount_with_ptune" > "$target/guard/conflict_guard_mode"
  echo "override_profile_materialized=validated_dynamic" > "$target/guard/override_profile_materialized"
}

echo "== enable pTune override =="
date -Is 2>/dev/null || date
[ -d "$MODDIR" ] || { echo "ERROR: active module path missing: $MODDIR" >&2; exit 1; }

echo "selected_profile=$THERMAL_OUTDOOR_PROFILE"
echo "selected_polling=$THERMAL_POLLING_MODE"
echo "config_file=$CONFIG_FILE"
echo "risk_ack=I_UNDERSTAND_BOOTLOOP_RISK"
echo "warning=HIGH_RISK_BOOTLOOP_TEST"

materialize_one "$MODDIR"
materialize_one "$STAGEDIR"
verify_one "$MODDIR"
verify_one "$STAGEDIR"

cfg_set PTUNE_GUARD_MODE strict
cfg_set ALLOW_THERMAL_WITH_PTUNE 1
cfg_set PTUNE_OVERRIDE_MENU on
cfg_set RISK_ACK_PTUNE_THERMAL_COLLISION I_UNDERSTAND_BOOTLOOP_RISK
cfg_set LAST_PTUNE_OVERRIDE 1
mark_override_one "$MODDIR"
mark_override_one "$STAGEDIR"

echo; echo "== config =="; cat "$CONFIG_FILE"
echo; echo "== flags =="
for d in "$STAGEDIR" "$MODDIR" "$PTUNE_DIR"; do
  echo; echo "-- $d"
  [ -f "$d/module.prop" ] && grep -E "^(id=|name=|version=|versionCode=)" "$d/module.prop" || echo absent
  [ -e "$d/disable" ] && echo disable=present || echo disable=absent
  [ -e "$d/remove" ] && echo remove=present || echo remove=absent
  [ -e "$d/skip_mount" ] && echo skip_mount=present || echo skip_mount=absent
done
if [ -x "$MODDIR/tools/bootguard/compat-check.sh" ]; then
  echo; echo "== compat-check =="; sh "$MODDIR/tools/bootguard/compat-check.sh" || true
fi
echo "RESULT: ENABLE_PTUNE_OVERRIDE_DONE profile=$THERMAL_OUTDOOR_PROFILE validation=independent"
