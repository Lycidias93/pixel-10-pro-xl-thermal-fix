#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
inventory="$repo_root/tools/debug/g6-polling-inventory.sh"
layout="$repo_root/tools/core/thermal-layout.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

src="$tmp/stock"
mkdir -p "$src"

cat > "$src/thermal_info_config.json" <<'EOF_ROOT'
{
  "Sensors": [
    {"Name":"VIRTUAL-SKIN","PollingDelay":300000},
    {"Name":"cellular-emergency","PollingDelay":300000}
  ],
  "Include": [
    "thermal_info_config_common.json",
    "thermal_info_config_forecast.json"
  ]
}
EOF_ROOT

cat > "$src/thermal_info_config_common.json" <<'EOF_COMMON'
{
  "Sensors": [
    {"Name":"VIRTUAL-SKIN-MODEL","PollingDelay":300000},
    {"Name":"charging_therm","PollingDelay":7000}
  ]
}
EOF_COMMON

cat > "$src/thermal_info_config_forecast.json" <<'EOF_FORECAST'
{
  "Sensors": [
    {"Name":"FORECAST-UPDATOR","PollingDelay":300000}
  ],
}
EOF_FORECAST

out="$tmp/out.txt"
THERMAL_DEVICE=grizzly \
THERMAL_BUILD_ID=CD1A.fixture \
THERMAL_LAYOUT_HELPER="$layout" \
TMPDIR="$tmp" \
sh "$inventory" "$src" > "$out"

grep -Fq 'G6_POLLING_LAYOUT_FAMILY=include_graph_g6' "$out"
grep -Fq 'G6_POLLING_LAYOUT_COUNT=3' "$out"
grep -Fq 'G6_POLLING_ENTRY_COUNT=5' "$out"
grep -Fq 'G6_POLLING_300000_COUNT=4' "$out"
grep -Fq 'G6_POLLING_UNMAPPED_COUNT=0' "$out"
grep -Fq 'sensor=VIRTUAL-SKIN polling_delay=300000 class=direct_virtual_skin admission=blocked_pending_review' "$out"
grep -Fq 'sensor=cellular-emergency polling_delay=300000 class=safety_or_protection admission=blocked_pending_review' "$out"
grep -Fq 'sensor=VIRTUAL-SKIN-MODEL polling_delay=300000 class=derived_or_model admission=blocked_pending_review' "$out"
grep -Fq 'sensor=charging_therm polling_delay=7000 class=safety_or_protection admission=blocked_pending_review' "$out"
grep -Fq 'sensor=FORECAST-UPDATOR polling_delay=300000 class=derived_or_model admission=blocked_pending_review' "$out"
grep -Fq 'RESULT: G6_POLLING_INVENTORY_PASS device=grizzly files=3 entries=5 stock300000=4 fast_admission=blocked_pending_review' "$out"

bad="$tmp/bad"
mkdir -p "$bad"
cat > "$bad/thermal_info_config.json" <<'EOF_BAD_ROOT'
{
  "PollingDelay": 300000,
  "Include": [
    "thermal_info_config_common.json",
    "thermal_info_config_forecast.json"
  ]
}
EOF_BAD_ROOT
cp "$src/thermal_info_config_common.json" "$bad/thermal_info_config_common.json"
cp "$src/thermal_info_config_forecast.json" "$bad/thermal_info_config_forecast.json"

set +e
THERMAL_DEVICE=grizzly \
THERMAL_BUILD_ID=CD1A.fixture \
THERMAL_LAYOUT_HELPER="$layout" \
TMPDIR="$tmp" \
sh "$inventory" "$bad" > "$tmp/bad-out.txt" 2>&1
rc=$?
set -e
test "$rc" -eq 28
grep -Fq 'G6_POLLING_UNMAPPED_COUNT=1' "$tmp/bad-out.txt"
grep -Fq 'G6_POLLING_INVENTORY=fail' "$tmp/bad-out.txt"
grep -Fq 'G6_POLLING_REASON=unmapped_polling_entries' "$tmp/bad-out.txt"

printf '%s\n' 'RESULT: G6_POLLING_INVENTORY_FIXTURE_PASS'
