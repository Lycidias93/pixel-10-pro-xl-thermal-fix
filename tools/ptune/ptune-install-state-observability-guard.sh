#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd -P)"
FINALIZE="$ROOT/tools/install-finalize.sh"
PTUNE_GUARD="$ROOT/tools/ptune/ptune-guard.sh"

fail=0
pass() { printf 'PASS %s\n' "$*"; }
err() { printf 'FAIL %s\n' "$*"; fail=1; }

[[ -s "$FINALIZE" ]] || err "finalize_missing=$FINALIZE"
[[ -s "$PTUNE_GUARD" ]] || err "ptune_guard_missing=$PTUNE_GUARD"
bash -n "$FINALIZE" && pass finalize_syntax || err finalize_syntax
bash -n "$PTUNE_GUARD" && pass ptune_guard_syntax || err ptune_guard_syntax

for required in \
  'ptune_install_state_classify()' \
  'PTUNE_INSTALL_STATE="absent"' \
  'PTUNE_INSTALL_STATE="installed_disabled"' \
  'PTUNE_INSTALL_STATE="active_explicit_override"' \
  'PTUNE_INSTALL_STATE="active_blocked"' \
  'if [ "$PTUNE_INSTALL_OVERRIDE_ACTIVE" = "1" ]' \
  'printf '\''%s\n'\'' "ptune_state=$PTUNE_INSTALL_STATE"' \
  'printf '\''%s\n'\'' "conflict_guard_mode=$PTUNE_INSTALL_CONFLICT_MODE"'
do
  grep -Fq "$required" "$FINALIZE" && pass "finalize_contract=$required" || err "finalize_contract_missing=$required"
done

for required in \
  'printf '\''%s\n'\'' "ptune_state=active_blocked"' \
  'printf '\''%s\n'\'' "conflict_guard=ptune_active"' \
  'printf '\''%s\n'\'' "guard_override=none"'
do
  grep -Fq "$required" "$PTUNE_GUARD" && pass "blocked_contract=$required" || err "blocked_contract_missing=$required"
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

config_get() { return 0; }
MODULE_ID=pixel-10-pro-xl-thermal-fix
MODULE_VERSION=2.0.0-alpha.3-dev.2
MODULE_VERSION_CODE=1016213
device=mustang
profile=dynamic/mustang/android17
profile_state=dynamic_stock_validated_exact_verified
build_state=dynamic_mustang_CP2A.260705.006_15641320
android=17
android_sdk=37
build_id=CP2A.260705.006
incremental=15641320
android_guard=android17_pass
fingerprint_android_guard=fingerprint_android17_pass
profile_source_android=17
profile_source_build=CP2A.260705.006
profile_source_incremental=15641320
source_report_sha256=dynamic_patching_validated
CONFIG_DIR="$TMP/data"
CONFIG_FILE="$CONFIG_DIR/config.env"
mkdir -p "$CONFIG_DIR"
PTUNE_GUARD_MODE=strict
ALLOW_THERMAL_WITH_PTUNE=0
PTUNE_RISK_ACK_STATE=not_present
PTUNE_KNOWN_BAD=no
PTUNE_OVERRIDE_NAME=none
THERMAL_OUTDOOR_PROFILE=stock
expected_thermal_files=dynamic_validated

source "$FINALIZE"

run_case() {
  name="$1"
  installed="$2"
  active="$3"
  allowed="$4"
  expected_state="$5"
  expected_mode="$6"
  expected_override="$7"

  MODPATH="$TMP/$name"
  active_dir="$MODPATH/system/vendor/etc"
  mkdir -p "$active_dir"
  PTUNE_INSTALLED_PATH="$installed"
  PTUNE_ACTIVE_PATH="$active"
  PTUNE_OVERRIDE_ALLOWED="$allowed"
  PTUNE_OVERRIDE_NAME=none
  [ "$allowed" = 1 ] && PTUNE_OVERRIDE_NAME=allow_thermal_with_ptune

  thermal_finalize_install

  grep -Fxq "ptune_state=$expected_state" "$MODPATH/install-state.txt" || { err "$name state"; return; }
  grep -Fxq "conflict_guard_mode=$expected_mode" "$MODPATH/install-state.txt" || { err "$name mode"; return; }

  if [ "$expected_override" = present ]; then
    [[ -s "$MODPATH/guard/guard_override" ]] || { err "$name override_missing"; return; }
  else
    [[ ! -e "$MODPATH/guard/guard_override" ]] || { err "$name unexpected_override"; return; }
  fi
  pass "matrix_case=$name"
}

run_case absent "" "" 0 absent ptune_absent absent
run_case installed_disabled /data/adb/modules/ptune "" 0 installed_disabled installed_disabled_no_conflict absent
run_case installed_disabled_config_ack /data/adb/modules/ptune "" 1 installed_disabled installed_disabled_no_conflict absent
run_case active_override /data/adb/modules/ptune /data/adb/modules/ptune 1 active_explicit_override override_allow_mount_with_ptune present

if [[ "$fail" -eq 0 ]]; then
  printf 'RESULT: PTUNE_INSTALL_STATE_OBSERVABILITY_GUARD_PASS rc=0\n'
else
  printf 'RESULT: PTUNE_INSTALL_STATE_OBSERVABILITY_GUARD_FAIL rc=1\n'
  exit 1
fi
