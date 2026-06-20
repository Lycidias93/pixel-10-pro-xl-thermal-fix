#!/system/bin/sh
ID="pixel-10-pro-xl-thermal-fix"
MODDIR="${MODDIR:-$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)}"
G="$MODDIR/guard"
L="$G/auto-profile-switch.log"
STATE="$MODDIR/install-state.txt"
CFG="/data/adb/$ID/config.env"
mkdir -p "$G"
log(){ echo "$(date -Is 2>/dev/null || date) $*" >> "$L"; }
getcfg(){ [ -r "$CFG" ] && grep -E "^$1=" "$CFG" 2>/dev/null | tail -n1 | sed "s/^$1=//" | tr -d '\r'; }
getstate(){ [ -r "$STATE" ] && grep -E "^$1=" "$STATE" 2>/dev/null | tail -n1 | sed "s/^$1=//" | tr -d '\r'; }
sha_file(){ sha256sum "$1" 2>/dev/null | awk '{print $1}'; }
prop(){ getprop "$1" 2>/dev/null || true; }

AUTO="$(getcfg AUTO_PROFILE_SWITCH)"
[ -n "$AUTO" ] || AUTO=1
case "$AUTO" in 1|yes|true|on|enabled) ;; *) log "AUTO_SWITCH_SKIP reason=config_disabled value=$AUTO"; echo config_disabled > "$G/auto_profile_switch_state"; exit 0 ;; esac

DEVICE="$(prop ro.product.device)"
ANDROID="$(prop ro.build.version.release)"
SDK="$(prop ro.build.version.sdk)"
BUILD_ID="$(prop ro.build.id)"
FINGERPRINT="$(prop ro.build.fingerprint)"
INCREMENTAL="$(prop ro.build.version.incremental)"

A16_BUILD="CP1A.260505.005"
A17_CP31_BUILD="CP31.260508.005"
A17_CP31_INC="15421345"
A17_CP31_FP="google/mustang_beta/mustang:CinnamonBun/CP31.260508.005/15421345:user/release-keys"
A17_CP31_QPR1B4_BUILD="CP31.260522.006"
A17_CP31_QPR1B4_INC="15591510"
A17_CP31_QPR1B4_FP="google/mustang_beta/mustang:CinnamonBun/CP31.260522.006/15591510:user/release-keys"
A17_CP21_BUILD="CP21.260330.011"
A17_STABLE_BUILD="CP2A.260605.012"
A17_STABLE_INC="15430684"

PROFILE=""
PROFILE_STATE=""
BUILD_STATE=""
GUARD=""
SOURCE_BUILD=""
SOURCE_INC=""

case "$ANDROID" in
  16|16.*)
    case "$DEVICE" in mustang|blazer|frankel|rango) ;; *) GUARD="unsupported_android16_device_$DEVICE" ;; esac
    if [ -z "$GUARD" ]; then
      if [ "$BUILD_ID" != "$A16_BUILD" ]; then
        GUARD="unsupported_android16_build_$BUILD_ID"
      else
        PROFILE="$DEVICE"
        PROFILE_STATE="auto_android16_${DEVICE}_cp1a"
        BUILD_STATE="android16_${DEVICE}_cp1a_260505005_auto_switch"
        SOURCE_BUILD="$A16_BUILD"
        SOURCE_INC="not_applicable"
      fi
    fi
  ;;
  17|17.*)
    case "$DEVICE" in
      mustang)
        case "$FINGERPRINT" in
          google/mustang/mustang:17/$A17_STABLE_BUILD/$A17_STABLE_INC:user/release-keys)
            PROFILE="mustang-android17-stable-cp2a-260605012"; PROFILE_STATE="auto_android17_stable_cp2a_mustang"; BUILD_STATE="android17_mustang_cp2a_15430684_auto_switch"; SOURCE_BUILD="$A17_STABLE_BUILD"; SOURCE_INC="$A17_STABLE_INC" ;;
          "$A17_CP31_FP")
            [ "$INCREMENTAL" = "$A17_CP31_INC" ] || GUARD="android17_cp31_incremental_mismatch_$INCREMENTAL"
            PROFILE="mustang-android17-cp31"; PROFILE_STATE="auto_android17_cp31_mustang"; BUILD_STATE="android17_mustang_cp31_15421345_auto_switch"; SOURCE_BUILD="$A17_CP31_BUILD"; SOURCE_INC="$A17_CP31_INC" ;;
          "$A17_CP31_QPR1B4_FP")
            [ "$INCREMENTAL" = "$A17_CP31_QPR1B4_INC" ] || GUARD="android17_cp31_qpr1b4_incremental_mismatch_$INCREMENTAL"
            PROFILE="mustang-android17-cp31"; PROFILE_STATE="auto_android17_cp31_qpr1b4_mustang"; BUILD_STATE="android17_mustang_cp31_15591510_auto_switch"; SOURCE_BUILD="$A17_CP31_QPR1B4_BUILD"; SOURCE_INC="$A17_CP31_QPR1B4_INC" ;;
          *:CinnamonBun/$A17_CP21_BUILD/*|*:17/$A17_CP21_BUILD/*)
            PROFILE="mustang-android17-cp21"; PROFILE_STATE="auto_android17_cp21_mustang"; BUILD_STATE="android17_mustang_cp21_auto_switch"; SOURCE_BUILD="$A17_CP21_BUILD"; SOURCE_INC="$INCREMENTAL" ;;
          *) GUARD="unsupported_android17_mustang_fingerprint" ;;
        esac
      ;;
      frankel|blazer|rango)
        if [ "$BUILD_ID" = "$A17_STABLE_BUILD" ] && [ "$INCREMENTAL" = "$A17_STABLE_INC" ]; then
          case "$FINGERPRINT" in google/${DEVICE}/${DEVICE}:17/$A17_STABLE_BUILD/$A17_STABLE_INC:user/release-keys) ;; *) GUARD="android17_stable_${DEVICE}_fingerprint_mismatch" ;; esac
          PROFILE="${DEVICE}-android17-stable-cp2a-260605012"; PROFILE_STATE="auto_android17_stable_cp2a_${DEVICE}"; BUILD_STATE="android17_${DEVICE}_cp2a_15430684_auto_switch"; SOURCE_BUILD="$A17_STABLE_BUILD"; SOURCE_INC="$A17_STABLE_INC"
        elif [ "$BUILD_ID" = "$A17_CP21_BUILD" ]; then
          case "$FINGERPRINT" in *:CinnamonBun/$A17_CP21_BUILD/*|*:17/$A17_CP21_BUILD/*) ;; *) GUARD="android17_cp21_${DEVICE}_fingerprint_mismatch" ;; esac
          PROFILE="${DEVICE}-android17-cp21"; PROFILE_STATE="auto_android17_cp21_${DEVICE}"; BUILD_STATE="android17_cp21_${DEVICE}_auto_switch"; SOURCE_BUILD="$A17_CP21_BUILD"; SOURCE_INC="$INCREMENTAL"
        else
          GUARD="unsupported_android17_${DEVICE}_build_$BUILD_ID"
        fi
      ;;
      *) GUARD="unsupported_android17_device_$DEVICE" ;;
    esac
  ;;
  *) GUARD="unsupported_android_$ANDROID" ;;
esac

if [ -n "$GUARD" ] || [ -z "$PROFILE" ]; then
  echo "unsupported_or_incompatible_build" > "$G/auto_profile_switch_state"
  echo "$GUARD" > "$G/auto_profile_switch_reason"
  echo PROFILE_STALE_AFTER_OTA=yes > "$G/profile_stale_after_ota"
  echo REINSTALL_REQUIRED=yes > "$G/reinstall_required"
  touch "$MODDIR/skip_mount"
  log "AUTO_SWITCH_BLOCK reason=$GUARD action=set_skip_mount device=$DEVICE android=$ANDROID build=$BUILD_ID incremental=$INCREMENTAL"
  exit 0
fi

PROFILE_DIR="$MODDIR/profiles/$PROFILE/system/vendor/etc"
ACTIVE_DIR="$MODDIR/system/vendor/etc"
for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
  if [ ! -s "$PROFILE_DIR/$f" ]; then
    echo missing_profile_file > "$G/auto_profile_switch_state"
    echo "$PROFILE/$f" > "$G/auto_profile_switch_reason"
    touch "$MODDIR/skip_mount"
    log "AUTO_SWITCH_BLOCK reason=missing_profile_file file=$PROFILE/$f action=set_skip_mount"
    exit 0
  fi
done

if [ -r /vendor/etc/thermal_info_config_throttling.json ]; then
  grep -q "VIRTUAL-SKIN" /vendor/etc/thermal_info_config_throttling.json 2>/dev/null || log "AUTO_SWITCH_WARN reason=stock_marker_missing_or_overlay_already_active"
else
  log "AUTO_SWITCH_WARN reason=stock_thermal_unreadable"
fi

OLD_PROFILE="$(getstate profile)"
OLD_ANDROID="$(getstate android)"
OLD_BUILD="$(getstate build_id)"
OLD_INC="$(getstate incremental)"
NEED=0
[ "$OLD_PROFILE" = "$PROFILE" ] || NEED=1
[ "$OLD_ANDROID" = "$ANDROID" ] || NEED=1
[ "$OLD_BUILD" = "$BUILD_ID" ] || NEED=1
[ "$OLD_INC" = "$INCREMENTAL" ] || NEED=1

for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
  a="$(sha_file "$ACTIVE_DIR/$f")"
  b="$(sha_file "$PROFILE_DIR/$f")"
  [ -n "$a" ] && [ "$a" = "$b" ] || NEED=1
done

if [ "$NEED" = 0 ]; then
  echo current_profile_valid > "$G/auto_profile_switch_state"
  echo "$PROFILE" > "$G/selected_profile"
  log "AUTO_SWITCH_PASS reason=current_profile_valid profile=$PROFILE device=$DEVICE android=$ANDROID build=$BUILD_ID incremental=$INCREMENTAL"
  exit 0
fi

mkdir -p "$ACTIVE_DIR"
for f in thermal_info_config_throttling.json thermal_info_config.json thermal_info_config_charge.json; do
  if [ -e "$ACTIVE_DIR/$f" ]; then
    cat "$PROFILE_DIR/$f" > "$ACTIVE_DIR/$f" || { log "AUTO_SWITCH_BLOCK reason=write_failed file=$f"; touch "$MODDIR/skip_mount"; exit 0; }
  else
    cp -fp "$PROFILE_DIR/$f" "$ACTIVE_DIR/$f" || { log "AUTO_SWITCH_BLOCK reason=copy_failed file=$f"; touch "$MODDIR/skip_mount"; exit 0; }
  fi
  chmod 0644 "$ACTIVE_DIR/$f" 2>/dev/null || true
done

rm -f "$MODDIR/skip_mount" "$G/disabled_reason" "$G/profile_stale_after_ota" "$G/reinstall_required" 2>/dev/null || true
{
  echo "module_id=$ID"
  echo "module_version=$(grep -E '^version=' "$MODDIR/module.prop" 2>/dev/null | head -n1 | sed 's/^version=//')"
  echo "module_version_code=$(grep -E '^versionCode=' "$MODDIR/module.prop" 2>/dev/null | head -n1 | sed 's/^versionCode=//')"
  echo "device=$DEVICE"
  echo "android=$ANDROID"
  echo "android_sdk=$SDK"
  echo "build_id=$BUILD_ID"
  echo "incremental=$INCREMENTAL"
  echo "profile=$PROFILE"
  echo "profile_state=$PROFILE_STATE"
  echo "build_state=$BUILD_STATE"
  echo "profile_source_build=$SOURCE_BUILD"
  echo "profile_source_incremental=$SOURCE_INC"
  echo "auto_profile_switch=yes"
  echo "auto_profile_switch_state=materialized"
  echo "auto_profile_switch_at=$(date -Is 2>/dev/null || date)"
  echo "profile_materialized=yes"
  echo "expected_thermal_files=3"
  echo "update_json_channel=stable_update_json_remains_1.4.4-universal.1"
} > "$STATE"
echo materialized > "$G/auto_profile_switch_state"
echo "$PROFILE" > "$G/selected_profile"
log "AUTO_SWITCH_DONE old_profile=${OLD_PROFILE:-none} new_profile=$PROFILE old_android=${OLD_ANDROID:-none} new_android=$ANDROID old_build=${OLD_BUILD:-none} new_build=$BUILD_ID old_incremental=${OLD_INC:-none} new_incremental=$INCREMENTAL"
exit 0
