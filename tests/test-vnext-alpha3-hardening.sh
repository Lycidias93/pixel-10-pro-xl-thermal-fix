#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
menu="$repo_root/tools/menu/install-options-menu.sh"
guard="$repo_root/tools/ptune/ptune-guard.sh"
readiness="$repo_root/tools/debug/vnext-readiness-summary.sh"
policy="$repo_root/tools/core/outdoor-runtime-policy.sh"
customize="$repo_root/customize.sh"
service="$repo_root/service.sh"
status="$repo_root/tools/debug/status-lib.sh"
module_prop="$repo_root/module.prop"
update_meta="$repo_root/update-prerelease.json"
supported="$repo_root/supported_versions.json"
matrix="$repo_root/docs/vnext-device-test-matrix.md"

for file in "$menu" "$guard" "$readiness" "$policy" "$customize" "$service" "$status"; do
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
grep -Fq 'config_set PTUNE_OVERRIDE_POLICY blocked_experimental_platform' "$customize"
grep -Fq 'config_set ALLOW_THERMAL_WITH_PTUNE 0' "$customize"

grep -Fq 'schema=pixel-thermal-vnext-readiness-v1' "$readiness"
grep -Fq 'readiness_state=runtime_verified' "$readiness"
grep -Fq 'support-readiness.env' "$service"
grep -Fq 'VNEXT_READINESS state=' "$service"

grep -Fq 'version=2.1.0-alpha.4' "$module_prop"
grep -Fq 'versionCode=1016254' "$module_prop"
# A promoted public prerelease must bind its branch-local release metadata to
# the same public version before the publisher is allowed to create the tag.
grep -Fq '"version": "2.1.0-alpha.4"' "$update_meta"
grep -Fq '"versionCode": 1016254' "$update_meta"
grep -Fq '/v2.1.0-alpha.4/pixel-thermal-memory-control-2.1.0-alpha.4.zip' "$update_meta"

grep -Fq '"komodo": {' "$supported"
grep -Fq '"CP2A.260805.005"' "$supported"
grep -Fq 'desc="description=Polling ' "$status"
! grep -Fq 'description=P:' "$status"
grep -Fq 'mc_cycle2 "Memory Killer" "Stock" "EXPERIMENTAL 1%"' "$menu"
grep -Fq 'cfg_set LMKD_SWAP_LOW_RELOAD 0' "$menu"

grep -Fq 'layout_evidenced' "$matrix"
grep -Fq 'runtime_verified' "$matrix"

printf '%s\n' 'PASS experimental_ptune_override_guarded'
printf '%s\n' 'PASS vnext_readiness_state_wired'
printf '%s\n' 'PASS alpha4_public_release_identity_bound'
printf '%s\n' 'PASS komodo_august_runtime_evidence_recorded'
printf '%s\n' 'PASS readable_status_and_zram_gated_memory_killer'
printf '%s\n' 'RESULT: VNEXT_ALPHA4_PUBLIC_HARDENING_PASS'
