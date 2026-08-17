#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HELPER="$ROOT/tools/zram/page-cluster-control.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/state"
printf 'ENABLE_ZRAM_100P=1\nZRAM_RISK_ACK=explicit_user_enable\n' > "$TMP/config.env"
printf '3' > "$TMP/page-cluster"
printf 'Filename Type Size Used Priority\n/dev/block/zram0 partition 1024 0 -2\n' > "$TMP/swaps"
printf 'boot-test-1\n' > "$TMP/boot_id"

env ZRAM_CONFIG_FILE="$TMP/config.env" PAGE_CLUSTER_STATE_DIR="$TMP/state" PAGE_CLUSTER_PATH="$TMP/page-cluster" PAGE_CLUSTER_SWAPS_FILE="$TMP/swaps" PAGE_CLUSTER_BOOT_ID_FILE="$TMP/boot_id" PAGE_CLUSTER_CALLER=test sh "$HELPER" apply-zero | grep -F 'RESULT: PAGE_CLUSTER_ZERO_PASS'
test "$(cat "$TMP/page-cluster")" = 0
grep -Fqx 'baseline=3' "$TMP/state/status.env"
grep -Fqx 'applied_by_module=yes' "$TMP/state/status.env"
grep -Fqx 'zram_swap_active=yes' "$TMP/state/status.env"

env ZRAM_CONFIG_FILE="$TMP/config.env" PAGE_CLUSTER_STATE_DIR="$TMP/state" PAGE_CLUSTER_PATH="$TMP/page-cluster" PAGE_CLUSTER_SWAPS_FILE="$TMP/swaps" PAGE_CLUSTER_BOOT_ID_FILE="$TMP/boot_id" PAGE_CLUSTER_CALLER=test sh "$HELPER" restore | grep -F 'RESULT: PAGE_CLUSTER_RESTORE_PASS'
test "$(cat "$TMP/page-cluster")" = 3
grep -Fqx 'applied_by_module=no' "$TMP/state/status.env"

printf 'Filename Type Size Used Priority\n/data/local/tmp/swapfile file 1024 0 -2\n' > "$TMP/swaps"
if env ZRAM_CONFIG_FILE="$TMP/config.env" PAGE_CLUSTER_STATE_DIR="$TMP/state" PAGE_CLUSTER_PATH="$TMP/page-cluster" PAGE_CLUSTER_SWAPS_FILE="$TMP/swaps" PAGE_CLUSTER_BOOT_ID_FILE="$TMP/boot_id" sh "$HELPER" apply-zero > "$TMP/non-zram.log" 2>&1; then
  echo 'FAIL: page-cluster zero unexpectedly allowed with non-ZRAM swap only' >&2
  exit 1
fi
grep -Fq 'RESULT: PAGE_CLUSTER_ZERO_BLOCKED reason=no_active_zram_swap' "$TMP/non-zram.log"
test "$(cat "$TMP/page-cluster")" = 3

printf 'Filename Type Size Used Priority\n/dev/block/zram0 partition 1024 0 -2\n' > "$TMP/swaps"
printf 'ENABLE_ZRAM_100P=0\nZRAM_RISK_ACK=disabled_by_user\n' > "$TMP/config.env"
if env ZRAM_CONFIG_FILE="$TMP/config.env" PAGE_CLUSTER_STATE_DIR="$TMP/state" PAGE_CLUSTER_PATH="$TMP/page-cluster" PAGE_CLUSTER_SWAPS_FILE="$TMP/swaps" PAGE_CLUSTER_BOOT_ID_FILE="$TMP/boot_id" sh "$HELPER" apply-zero >/dev/null 2>&1; then
  echo 'FAIL: page-cluster zero unexpectedly allowed without ZRAM' >&2
  exit 1
fi

printf '%s\n' 'RESULT: PAGE_CLUSTER_CONTROL_TEST_PASS'
