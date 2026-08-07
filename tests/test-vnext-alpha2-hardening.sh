#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
menu="$repo_root/tools/menu/install-options-menu.sh"
guard="$repo_root/tools/ptune/ptune-guard.sh"
readiness="$repo_root/tools/debug/vnext-readiness-summary.sh"
policy="$repo_root/tools/core/outdoor-runtime-policy.sh"
customize="$repo_root/customize.sh"
service="$repo_root/service.sh"
module_prop="$repo_root/module.prop"
update_meta="$repo_root/update-prerelease.json"
matrix="$repo_root/docs/vnext-device-test-matrix.md"

for file in "$menu" "$guard" "$readiness" "$policy" "$customize" "$service"; do
  sh -n "$file"
done

grep -Fq 'thermal_outdoor_experimental_platform' "$menu"
for device in tokay caiman komodo comet tegu stallion; do
  grep -Fq "$device:17" "$policy"
  grep -Fq "$device:17" "$guard"
  grep -Fq "$device:17" "$readiness"
  grep -Fq "\`$device\`" "$matrix"
done

grep -Fq 'PTUNE_OVERRIDE_POLICY blocked_experimental_platform' "$menu"
grep -Fq 'pTune Override: unavailable on experimental vNext target' "$menu"
grep -Fq 'PTUNE_OVERRIDE_NAME="blocked_experimental_platform"' "$guard"
grep -Fq 'PTUNE_OVERRIDE_ALLOWED=0' "$guard"
grep -Fq 'pTune coexistence is blocked on experimental Pixel 9 / Pixel 10a targets' "$guard"
grep -Fq 'config_set PTUNE_OVERRIDE_POLICY blocked_experimental_platform' "$customize"
grep -Fq 'config_set ALLOW_THERMAL_WITH_PTUNE 0' "$customize"

grep -Fq 'schema=pixel-thermal-vnext-readiness-v1' "$readiness"
grep -Fq 'readiness_state=runtime_verified' "$readiness"
grep -Fq 'readiness_state=install_ready_reboot_pending' "$readiness"
grep -Fq 'guard/support-readiness.env' "$customize"
grep -Fq 'support-readiness.env' "$service"
grep -Fq 'VNEXT_READINESS state=' "$service"

grep -Fq 'version=2.1.0-alpha.2' "$module_prop"
grep -Fq 'versionCode=1016251' "$module_prop"
grep -Fq '"version": "2.1.0-alpha.2"' "$update_meta"
grep -Fq 'pixel-thermal-memory-control-2.1.0-alpha.2.zip' "$update_meta"

grep -Fq 'layout_evidenced' "$matrix"
grep -Fq 'platform_admitted' "$matrix"
grep -Fq 'runtime_verified' "$matrix"
grep -Fq '37 stock `PollingDelay=300000` values' "$matrix"
grep -Fq '23 + 11 + 3' "$matrix"

printf '%s\n' 'PASS experimental_ptune_override_hidden_and_guard_blocked'
printf '%s\n' 'PASS install_and_postboot_readiness_state_wired'
printf '%s\n' 'PASS device_evidence_matrix_explicit'
printf '%s\n' 'PASS alpha2_release_identity_wired'
printf '%s\n' 'RESULT: VNEXT_ALPHA2_HARDENING_PASS'
