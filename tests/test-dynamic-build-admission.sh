#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
helper="$repo_root/tools/core/supported-build.sh"
json="$repo_root/supported_versions.json"

[[ -s "$helper" && -s "$json" ]]
# shellcheck disable=SC1090
. "$helper"

thermal_supported_validate_file "$json"
thermal_supported_platform_check "$json" mustang 17
thermal_supported_platform_check "$json" blazer 17
thermal_supported_platform_check "$json" frankel 17
thermal_supported_platform_check "$json" rango 17

thermal_exact_build_check "$json" mustang 17 CP2A.260705.006

unknown_build="ZP99.269912.999"
thermal_supported_check "$json" mustang 17 "$unknown_build"
[[ "$THERMAL_BUILD_EVIDENCE" = unverified ]]
! thermal_exact_build_check "$json" mustang 17 "$unknown_build"
[[ "$(thermal_build_evidence_state "$json" mustang 17 "$unknown_build")" = dynamic_unverified ]]

! thermal_supported_platform_check "$json" unknown-device 17
! thermal_supported_platform_check "$json" mustang 18
[[ "$(thermal_build_evidence_state "$json" unknown-device 17 "$unknown_build")" = unsupported_platform ]]

printf '%s\n' 'PASS exact_build_is_evidence_not_activation_gate'
printf '%s\n' 'PASS unknown_build_admitted_on_supported_platform'
printf '%s\n' 'PASS unknown_device_and_android_fail_closed'
printf '%s\n' 'RESULT: PIXEL_THERMAL_DYNAMIC_BUILD_ADMISSION_TEST_PASS'
