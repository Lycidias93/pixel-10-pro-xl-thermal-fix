#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
verify="$root/tools/debug/vnext-device-verify.sh"

bash -n "$verify"

grep -Fq 'verifier_version=v1' "$verify"
grep -Fq 'baseline|post-disable|post-reenable' "$verify"
grep -Fq 'evidence_collection=' "$verify"
grep -Fq 'verdict=' "$verify"
grep -Fq 'failure_count=' "$verify"
grep -Fq 'warning_count=' "$verify"
grep -Fq 'RESULT: PIXEL_THERMAL_VNEXT_DEVICE_VERIFY_PASS' "$verify"
grep -Fq 'RESULT: PIXEL_THERMAL_VNEXT_DEVICE_VERIFY_FAIL' "$verify"
grep -Fq 'RESULT: PIXEL_THERMAL_VNEXT_DEVICE_VERIFY_STOP' "$verify"

grep -Fq "awk 'NR > 1 && \$1 ~ /\\/zram[0-9]+$/ { print \$1 }' /proc/swaps" "$verify"
grep -Fq 'sysfs="/sys/block/$name"' "$verify"
! grep -Fq '/sys/block/zram0/disksize' "$verify"

grep -Fq 'memory_killer_mode=experimental_1_percent' "$verify"
grep -Fq 'memory_killer_mode=stock' "$verify"
grep -Fq 'stock_zram_runtime_observation=' "$verify"
grep -Fq 'Support Snapshot' "$verify"

# Non-safety runtime failures must aggregate rather than call stop_now.
! grep -Eq 'stop_now (zram|memory_killer|bootguard|vnext|support_)' "$verify"

printf '%s\n' 'PASS repository_owned_phase_aware_verifier'
printf '%s\n' 'PASS dynamic_zram_instance_discovery'
printf '%s\n' 'PASS config_aware_memory_killer_matrix'
printf '%s\n' 'PASS collect_all_non_safety_failures'
printf '%s\n' 'RESULT: VNEXT_DEVICE_VERIFY_CONTRACT_PASS'
