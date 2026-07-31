#!/system/bin/sh
set -eu
ID="${ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-/data/adb/modules/$ID}"
echo "== ZRAM runtime KB verify =="
if [ -s "$MODDIR/module.prop" ]; then grep -nE "^(version|versionCode|description)=" "$MODDIR/module.prop" || true; fi
swap_line="$(grep "/dev/block/zram0" /proc/swaps | head -n 1 || true)"
if [ -z "$swap_line" ]; then echo "FAIL zram_swap_missing"; exit 20; fi
printf "%s\n" "$swap_line"
set -- $swap_line
swap_kb="$3"
used_kb="$4"
mem_line="$(grep "^MemTotal:" /proc/meminfo | head -n 1)"
set -- $mem_line
mem_kb="$2"
swap_pct="$((swap_kb * 100 / mem_kb))"
echo "mem_kb=$mem_kb"
echo "swap_kb=$swap_kb"
echo "used_kb=$used_kb"
echo "swap_pct=$swap_pct"
test "$swap_pct" -ge 95
test "$swap_pct" -le 105
echo "PASS zram_runtime_near_100p_proc_swaps_kb"
echo "RESULT: PIXEL10_ZRAM_KB_VERIFY_PASS"
