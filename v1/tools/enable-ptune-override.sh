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

select_profile() {
  device="$(getprop ro.product.device 2>/dev/null)"
  android="$(getprop ro.build.version.release 2>/dev/null)"
  build_id="$(getprop ro.build.id 2>/dev/null)"
  fingerprint="$(getprop ro.build.fingerprint 2>/dev/null)"
  case "$android" in
    16|16.*)
      case "$fingerprint" in *":16/"*) ;; *) echo "ERROR: android16 fingerprint mismatch: $fingerprint" >&2; return 1 ;; esac
      case "$device" in mustang) profile="mustang" ;; blazer) profile="blazer" ;; frankel) profile="frankel" ;; rango) profile="rango" ;; *) echo "ERROR: unsupported Android 16 device: $device" >&2; return 1 ;; esac ;;
    17|17.*)
      case "$device" in
        mustang)
          case "$fingerprint" in
            google/mustang_beta/mustang:CinnamonBun/CP31.260508.005/15421345:user/release-keys) profile="mustang-android17-cp31" ;;
            google/mustang_beta/mustang:CinnamonBun/CP31.260522.006/15591510:user/release-keys) profile="mustang-android17-cp31" ;;
            *":CinnamonBun/CP21.260330.011/"*|*":17/CP21.260330.011/"*) profile="mustang-android17-cp21" ;;
            *) echo "ERROR: unsupported Android 17 mustang fingerprint: $fingerprint" >&2; return 1 ;;
          esac ;;
        frankel|blazer|rango)
          case "$build_id" in CP21.260330.011) ;; *) echo "ERROR: unsupported Android 17 CP21 build: $build_id" >&2; return 1 ;; esac
          case "$fingerprint" in *":CinnamonBun/CP21.260330.011/"*|*":17/CP21.260330.011/"*) profile="${device}-android17-cp21" ;; *) echo "ERROR: unsupported Android 17 CP21 fingerprint: $fingerprint" >&2; return 1 ;; esac ;;
        *) echo "ERROR: unsupported Android 17 device: $device" >&2; return 1 ;;
      esac ;;
    *) echo "ERROR: unsupported Android version: $android" >&2; return 1 ;;
  esac
  echo "$profile"
}

materialize_one() {
  target="$1"; profile="$2"
  [ -d "$target" ] || return 0
  profile_dir="$target/profiles/$profile/system/vendor/etc"
  active_dir="$target/system/vendor/etc"
  for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
    [ -s "$profile_dir/$f" ] || { echo "ERROR: missing profile file: $profile/$f in $target" >&2; return 1; }
  done
  rm -rf "$active_dir"; mkdir -p "$active_dir"
  cp -fp "$profile_dir"/*.json "$active_dir"/
  chmod 0644 "$active_dir"/*.json 2>/dev/null || true
  rm -f "$target/disable" "$target/skip_mount" "$target/remove" 2>/dev/null || true
  mkdir -p "$target/guard"
  echo "allow_thermal_with_ptune" > "$target/guard/guard_override"
  echo "$CONFIG_FILE" > "$target/guard/guard_override_source"
  echo "explicit_user_override" > "$target/guard/risk_ack"
  echo "$PTUNE_DIR" > "$target/guard/conflict_ptune_path"
  echo "override_allow_mount_with_ptune" > "$target/guard/conflict_guard_mode"
  echo "override_profile_materialized=$profile" > "$target/guard/override_profile_materialized"
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
profile="$(select_profile)"
echo "selected_profile=$profile"
echo "config_file=$CONFIG_FILE"
echo "risk_ack=I_UNDERSTAND_BOOTLOOP_RISK"
echo "warning=HIGH_RISK_BOOTLOOP_TEST"
materialize_one "$MODDIR" "$profile"
materialize_one "$STAGEDIR" "$profile"
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
if [ -x "$MODDIR/tools/compat-check.sh" ]; then echo; echo "== compat-check =="; sh "$MODDIR/tools/compat-check.sh" || true; fi
echo "RESULT: ENABLE_PTUNE_OVERRIDE_DONE profile=$profile"
