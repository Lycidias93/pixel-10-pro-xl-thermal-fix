#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def replace_once(path: str, old: str, new: str) -> None:
    target = ROOT / path
    text = target.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"FAIL replace_once path={path} old={old[:48]!r} count={count}")
    target.write_text(text.replace(old, new, 1), encoding="utf-8")


def replace_all(path: str, old: str, new: str, minimum: int = 1) -> None:
    target = ROOT / path
    text = target.read_text(encoding="utf-8")
    count = text.count(old)
    if count < minimum:
        raise SystemExit(f"FAIL replace_all path={path} old={old!r} count={count} minimum={minimum}")
    target.write_text(text.replace(old, new), encoding="utf-8")


compat = "tools/bootguard/compat-check.sh"
replace_all(compat, "exact_supported", "platform_supported")
replace_once(
    compat,
    "platform_supported=no\n",
    "platform_supported=no\nbuild_evidence=unsupported_platform\n",
)
replace_once(
    compat,
    "  platform_supported=yes\nfi\n",
    '''  platform_supported=yes
  if command -v thermal_build_evidence_state >/dev/null 2>&1; then
    build_evidence="$(thermal_build_evidence_state "$SUPPORTED_JSON" "$DEVICE" "$ANDROID" "$BUILD_ID")"
  else
    build_evidence=dynamic_unverified
  fi
fi
''',
)
for old, new in (
    ("thermal_disabled_unsupported_build", "thermal_disabled_unsupported_platform"),
    ("unsupported_build_thermal_disabled", "unsupported_platform_thermal_disabled"),
    ("unsupported_build_overlay_not_disabled", "unsupported_platform_overlay_not_disabled"),
    ("supported_build_thermal_disabled_overlay_absent", "supported_platform_thermal_disabled_overlay_absent"),
    ("supported_build_disabled_but_overlay_present", "supported_platform_disabled_but_overlay_present"),
    ("thermal_disabled_by_guard", "thermal_disabled_by_platform_guard"),
):
    replace_all(compat, old, new)

replace_once(
    compat,
    '''profile_stale_after_ota=no
[ -r "$GUARD_DIR/auto_profile_switch_state" ] && auto_state="$(head -n 1 "$GUARD_DIR/auto_profile_switch_state" 2>/dev/null)"
''',
    '''profile_stale_after_ota=no
transition_pending=no
transition_phase=absent
transition_reason=none
[ -r "$GUARD_DIR/auto_profile_switch_state" ] && auto_state="$(head -n 1 "$GUARD_DIR/auto_profile_switch_state" 2>/dev/null)"
''',
)
replace_once(
    compat,
    '''[ -r "$GUARD_DIR/profile_stale_after_ota" ] && profile_stale_after_ota="$(sed 's/^PROFILE_STALE_AFTER_OTA=//' "$GUARD_DIR/profile_stale_after_ota" 2>/dev/null | head -n 1)"
[ -n "$build_guard_mode" ] || build_guard_mode=unknown
''',
    '''[ -r "$GUARD_DIR/profile_stale_after_ota" ] && profile_stale_after_ota="$(sed 's/^PROFILE_STALE_AFTER_OTA=//' "$GUARD_DIR/profile_stale_after_ota" 2>/dev/null | head -n 1)"
if [ -r "$GUARD_DIR/platform-transition.env" ]; then
  transition_pending="$(grep -E '^transition_pending=' "$GUARD_DIR/platform-transition.env" 2>/dev/null | tail -n 1 | sed 's/^transition_pending=//')"
  transition_phase="$(grep -E '^phase=' "$GUARD_DIR/platform-transition.env" 2>/dev/null | tail -n 1 | sed 's/^phase=//')"
  transition_reason="$(grep -E '^reason=' "$GUARD_DIR/platform-transition.env" 2>/dev/null | tail -n 1 | sed 's/^reason=//')"
fi
[ -n "$build_guard_mode" ] || build_guard_mode=unknown
''',
)
replace_once(
    compat,
    r'''  printf '%s\n' "EXACT_BUILD_SUPPORTED=$platform_supported"
  printf '%s\n' "DYNAMIC_CONTROLLED_FILES=3"
''',
    r'''  printf '%s\n' "PLATFORM_SUPPORTED=$platform_supported"
  printf '%s\n' "BUILD_EVIDENCE=$build_evidence"
  printf '%s\n' "DYNAMIC_CONTROLLED_FILES=3"
''',
)
replace_once(
    compat,
    r'''  printf '%s\n' "BUILD_GUARD_MODE=$build_guard_mode"
  printf '%s\n' "PROFILE_STALE_AFTER_OTA=$profile_stale_after_ota"
''',
    r'''  printf '%s\n' "BUILD_GUARD_MODE=$build_guard_mode"
  printf '%s\n' "PLATFORM_TRANSITION_PENDING=$transition_pending"
  printf '%s\n' "PLATFORM_TRANSITION_PHASE=$transition_phase"
  printf '%s\n' "PLATFORM_TRANSITION_REASON=$transition_reason"
  printf '%s\n' "PROFILE_STALE_AFTER_OTA=$profile_stale_after_ota"
''',
)

status = "tools/debug/status-lib.sh"
replace_all(status, "exact_supported", "platform_supported")
replace_all(status, "EXACT_BUILD_SUPPORTED", "PLATFORM_SUPPORTED")
for old, new in (
    ("unsupported_build_thermal_disabled", "unsupported_platform_thermal_disabled"),
    ("disabled_by_build_guard", "disabled_by_platform_guard"),
):
    replace_all(status, old, new)
replace_once(
    status,
    '''  platform_supported="$(kv_get PLATFORM_SUPPORTED "$tmp")"
  source_manifest_valid="$(kv_get DYNAMIC_SOURCE_MANIFEST_VALID "$tmp")"
''',
    '''  platform_supported="$(kv_get PLATFORM_SUPPORTED "$tmp")"
  build_evidence="$(kv_get BUILD_EVIDENCE "$tmp")"
  transition_pending="$(kv_get PLATFORM_TRANSITION_PENDING "$tmp")"
  transition_phase="$(kv_get PLATFORM_TRANSITION_PHASE "$tmp")"
  transition_reason="$(kv_get PLATFORM_TRANSITION_REASON "$tmp")"
  source_manifest_valid="$(kv_get DYNAMIC_SOURCE_MANIFEST_VALID "$tmp")"
''',
)
replace_once(
    status,
    '''  [ -n "$platform_supported" ] || platform_supported=unknown
  [ -n "$materialization_valid" ] || materialization_valid=unknown
''',
    '''  [ -n "$platform_supported" ] || platform_supported=unknown
  [ -n "$build_evidence" ] || build_evidence=unknown
  [ -n "$transition_pending" ] || transition_pending=no
  [ -n "$transition_phase" ] || transition_phase=absent
  [ -n "$transition_reason" ] || transition_reason=none
  [ -n "$materialization_valid" ] || materialization_valid=unknown
''',
)
replace_once(
    status,
    r'''    printf '%s\n' "PLATFORM_SUPPORTED=$platform_supported"
    printf '%s\n' "SOURCE_MANIFEST_VALID=$source_manifest_valid"
''',
    r'''    printf '%s\n' "PLATFORM_SUPPORTED=$platform_supported"
    printf '%s\n' "BUILD_EVIDENCE=$build_evidence"
    printf '%s\n' "PLATFORM_TRANSITION_PENDING=$transition_pending"
    printf '%s\n' "PLATFORM_TRANSITION_PHASE=$transition_phase"
    printf '%s\n' "PLATFORM_TRANSITION_REASON=$transition_reason"
    printf '%s\n' "SOURCE_MANIFEST_VALID=$source_manifest_valid"
''',
)

threshold_guard = "tools/bootguard/bootguard-threshold-policy-guard.sh"
replace_once(
    threshold_guard,
    '''grep -Fq 'threshold_minimum=$(threshold_minimum)' "$TARGET" && pass 'status_observability' || err 'status_observability_missing'
''',
    r'''grep -Fq 'threshold_minimum=$(threshold_minimum)' "$TARGET" && pass 'status_observability' || err 'status_observability_missing'
grep -Fq 'effective_pending_threshold()' "$TARGET" && pass 'effective_pending_threshold_helper' || err 'effective_pending_threshold_helper_missing'
grep -Fq 'pending_transition()' "$TARGET" && pass 'transition_pending_helper' || err 'transition_pending_helper_missing'
grep -Fq "printf '%s\n' 1" "$TARGET" && pass 'ota_transition_threshold_one' || err 'ota_transition_threshold_one_missing'
grep -Fq 'success-verify)' "$TARGET" && pass 'verified_success_entrypoint' || err 'verified_success_entrypoint_missing'
grep -Fq 'thermalservice_unresponsive_second_probe' "$TARGET" && pass 'thermalservice_double_probe' || err 'thermalservice_double_probe_missing'
''',
)

transaction_test = "tests/test-action-thermal-transaction.sh"
replace_once(
    transaction_test,
    r'''printf '%s\n' 'PASS duplicate_update_channel_status_call_absent'
printf '%s\n' 'RESULT: PIXEL_THERMAL_ACTION_TRANSACTION_TEST_PASS'
''',
    r'''printf '%s\n' 'PASS duplicate_update_channel_status_call_absent'
bash "$repo_root/tests/test-ota-transition-bootguard.sh"
printf '%s\n' 'RESULT: PIXEL_THERMAL_ACTION_TRANSACTION_TEST_PASS'
''',
)

print("RESULT: APPLY_VNEXT_OTA_HARDENING_DONE")
