#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

mkdir -p "$tmp/sys/block/zram0" "$tmp/devfreq" "$tmp/state" "$tmp/data" "$tmp/bin"

# ---------------------------------------------------------------------------
# Test 1: Dynamic algorithm resolution in materialize-zram-choice.sh
# ---------------------------------------------------------------------------
layout="$repo_root/tools/zram/materialize-zram-choice.sh"
bash -n "$layout"

# 1A: sysfs contains lz77eh
printf '%s\n' '[lz77eh] lz4 zstd' > "$tmp/sys/block/zram0/comp_algorithm"
res="$(ZRAM_SYS="$tmp/sys/block/zram0" sh "$layout" algorithm)"
[[ "$res" = "lz77eh" ]] || { echo "FAIL 1A expected lz77eh got $res"; exit 1; }

# 1B: sysfs contains Tensor G6 telemetry: deflate zstd lz4hc [lz4] lzo lzo-rle
printf '%s\n' 'deflate zstd lz4hc [lz4] lzo lzo-rle' > "$tmp/sys/block/zram0/comp_algorithm"
res="$(ZRAM_SYS="$tmp/sys/block/zram0" sh "$layout" algorithm)"
[[ "$res" = "lz4" ]] || { echo "FAIL 1B expected lz4 got $res"; exit 1; }

# 1C: sysfs contains neither lz77eh nor lz4, preserves active bracketed algo
printf '%s\n' 'deflate [zstd] lzo' > "$tmp/sys/block/zram0/comp_algorithm"
res="$(ZRAM_SYS="$tmp/sys/block/zram0" sh "$layout" algorithm)"
[[ "$res" = "zstd" ]] || { echo "FAIL 1C expected zstd got $res"; exit 1; }

# 1D: sysfs unreadable, fallback by device
rm -f "$tmp/sys/block/zram0/comp_algorithm"
res="$(ZRAM_SYS="$tmp/sys/block/zram0" THERMAL_DEVICE=grizzly sh "$layout" algorithm)"
[[ "$res" = "lz4" ]] || { echo "FAIL 1D-grizzly expected lz4 got $res"; exit 1; }
res="$(ZRAM_SYS="$tmp/sys/block/zram0" THERMAL_DEVICE=cubs sh "$layout" algorithm)"
[[ "$res" = "lz4" ]] || { echo "FAIL 1D-cubs expected lz4 got $res"; exit 1; }
res="$(ZRAM_SYS="$tmp/sys/block/zram0" THERMAL_DEVICE=mustang sh "$layout" algorithm)"
[[ "$res" = "lz77eh" ]] || { echo "FAIL 1D-mustang expected lz77eh got $res"; exit 1; }

printf '%s\n' 'PASS materialize_algorithm_resolution'

# ---------------------------------------------------------------------------
# Test 2: Dynamic negotiation in apply-zram-100p.sh sets mmd.zram.comp_algorithm
# ---------------------------------------------------------------------------
apply="$repo_root/tools/zram/apply-zram-100p.sh"
bash -n "$apply"

# Mock resetprop and getprop to record property writes and supply device identity
cat > "$tmp/bin/resetprop-mock" <<'MOCK'
#!/bin/sh
if [ "$1" = "-n" ]; then
  shift
fi
echo "$1=$2" >> "$RESETPROP_LOG"
MOCK
chmod +x "$tmp/bin/resetprop-mock"
ln -sf "$tmp/bin/resetprop-mock" "$tmp/bin/resetprop"
ln -sf "$tmp/bin/resetprop-mock" "$tmp/bin/setprop"

cat > "$tmp/bin/getprop-mock" <<'MOCK'
#!/bin/sh
case "$1" in
  ro.product.device) printf '%s\n' "${THERMAL_DEVICE:-grizzly}" ;;
  ro.lmk.swap_free_low_percentage) printf '%s\n' "" ;;
  *) printf '\n' ;;
esac
MOCK
chmod +x "$tmp/bin/getprop-mock"
ln -sf "$tmp/bin/getprop-mock" "$tmp/bin/getprop"

cat > "$tmp/bin/stop" <<'MOCK'
#!/bin/sh
exit 0
MOCK
chmod +x "$tmp/bin/stop"
cat > "$tmp/bin/start" <<'MOCK'
#!/bin/sh
exit 0
MOCK
chmod +x "$tmp/bin/start"

# 2A: Tensor G6 (grizzly) with [lz4] sysfs node
printf '%s\n' 'deflate zstd lz4hc [lz4] lzo lzo-rle' > "$tmp/sys/block/zram0/comp_algorithm"
config_g6="$tmp/data/config_g6.env"
printf '%s\n' 'ENABLE_ZRAM_100P=1' 'ZRAM_RISK_ACK=explicit_user_enable' 'LAST_ZRAM_100P=enabled_standard' > "$config_g6"
export RESETPROP_LOG="$tmp/props_g6.log"
: > "$RESETPROP_LOG"

PATH="$tmp/bin:$PATH" \
MODDIR="$repo_root" \
ZRAM_RESTART_MMD=0 \
ZRAM_RESETPROP_BIN="$tmp/bin/resetprop-mock" \
LMKD_SYSTEM_RESETPROP_BIN="$tmp/bin/resetprop-mock" \
LMKD_GETPROP_BIN="$tmp/bin/getprop-mock" \
LMKD_SETPROP_BIN="$tmp/bin/resetprop-mock" \
ZRAM_SYS="$tmp/sys/block/zram0" \
ZRAM_CONFIG_FILE="$config_g6" \
THERMAL_DEVICE=grizzly \
sh "$apply" manual > "$tmp/apply_g6.log" 2>&1 || true

# Assert runtime execution wrote mmd.zram.comp_algorithm=lz4 via resetprop
grep -Fq 'mmd.zram.comp_algorithm=lz4' "$RESETPROP_LOG" || {
  echo "FAIL apply-zram-100p did not record mmd.zram.comp_algorithm=lz4 in props log";
  cat "$tmp/apply_g6.log";
  exit 1;
}

# Ensure apply-zram-100p.sh has resolve_zram_algorithm and does not hardcode prop_set ... lz77eh
! grep -Eq 'prop_set[[:space:]]+mmd\.zram\.comp_algorithm[[:space:]]+lz77eh' "$apply" || {
  echo "FAIL apply-zram-100p still hardcodes lz77eh"; exit 1;
}
grep -Fq 'TARGET_ALGO="$(resolve_zram_algorithm)"' "$apply"
grep -Fq 'prop_set mmd.zram.comp_algorithm "$TARGET_ALGO"' "$apply"

printf '%s\n' 'PASS apply_zram_dynamic_negotiation'

# ---------------------------------------------------------------------------
# Test 3: reinit-zram-100p.sh dynamic negotiation
# ---------------------------------------------------------------------------
reinit="$repo_root/tools/zram/reinit-zram-100p.sh"
bash -n "$reinit"
! grep -Eq 'setprop[[:space:]]+mmd\.zram\.comp_algorithm[[:space:]]+lz77eh' "$reinit" || {
  echo "FAIL reinit-zram-100p still hardcodes lz77eh prop"; exit 1;
}
! grep -Eq "printf 'lz77eh\\\\n' > \"\\\$ZRAM_SYS/comp_algorithm\"" "$reinit" || {
  echo "FAIL reinit-zram-100p still hardcodes lz77eh sysfs write"; exit 1;
}
grep -Fq 'target_algo="$(resolve_zram_algorithm)"' "$reinit"
grep -Fq 'setprop mmd.zram.comp_algorithm "$target_algo"' "$reinit"
grep -Fq 'printf '\''%s\n'\'' "$target_algo" > "$ZRAM_SYS/comp_algorithm"' "$reinit"

printf '%s\n' 'PASS reinit_zram_dynamic_negotiation'

# ---------------------------------------------------------------------------
# Test 4: Emerald Hill Hardware Presence Gating in emerald-hill-control.sh
# ---------------------------------------------------------------------------
eh_ctrl="$repo_root/tools/zram/emerald-hill-control.sh"
bash -n "$eh_ctrl"

# 4A: On Tensor G6 (grizzly), EH is unsupported
out="$(THERMAL_DEVICE=grizzly sh "$eh_ctrl" supported 2>&1 || true)"
grep -Fq 'RESULT: ZRAM_EH_SUPPORTED supported=no reason=no_eh_hardware' <<<"$out"

status_g6="$(ZRAM_EH_STATE_DIR="$tmp/state_g6" THERMAL_DEVICE=grizzly sh "$eh_ctrl" status)"
grep -Fq 'state=unsupported' <<<"$status_g6"
grep -Fq 'detail=Unsupported / N/A (No EH Hardware)' <<<"$status_g6"

apply_g6="$(ZRAM_EH_STATE_DIR="$tmp/state_g6" THERMAL_DEVICE=grizzly sh "$eh_ctrl" apply 2>&1 || true)"
grep -Fq 'RESULT: ZRAM_EH_APPLY_REFUSED reason=eh_hardware_unsupported' <<<"$apply_g6"

restore_g6="$(ZRAM_EH_STATE_DIR="$tmp/state_g6" THERMAL_DEVICE=grizzly sh "$eh_ctrl" restore 2>&1 || true)"
grep -Fq 'RESULT: ZRAM_EH_RESTORE_DONE nodes=0 aliases_skipped=0 reason=unsupported_no_hardware' <<<"$restore_g6"

# 4B: On a device where lz77eh is absent from sysfs and no devfreq node exists, EH is unsupported
printf '%s\n' 'deflate zstd lz4hc [lz4] lzo lzo-rle' > "$tmp/sys/block/zram0/comp_algorithm"
out_no_eh="$(ZRAM_SYS="$tmp/sys/block/zram0" ZRAM_EH_DEVFREQ_ROOTS="$tmp/devfreq/*" THERMAL_DEVICE=generic sh "$eh_ctrl" supported 2>&1 || true)"
grep -Fq 'RESULT: ZRAM_EH_SUPPORTED supported=no reason=no_eh_hardware' <<<"$out_no_eh"

# 4C: On Mustang / device with fake devfreq node, EH is supported
mkdir -p "$tmp/devfreq/17000000.eh"
printf '%s\n' 200000000 > "$tmp/devfreq/17000000.eh/min_freq"
printf '%s\n' 1066000000 > "$tmp/devfreq/17000000.eh/max_freq"
printf '%s\n' emerald-hill > "$tmp/devfreq/17000000.eh/name"

out_mustang="$(ZRAM_EH_DEVFREQ_ROOTS="$tmp/devfreq/*" THERMAL_DEVICE=mustang sh "$eh_ctrl" supported 2>&1)"
grep -Fq 'RESULT: ZRAM_EH_SUPPORTED supported=yes' <<<"$out_mustang"

printf '%s\n' 'PASS emerald_hill_hardware_gating'

# ---------------------------------------------------------------------------
# Test 5: pixel-control.sh blocks EH actions on Tensor G6
# ---------------------------------------------------------------------------
control="$repo_root/tools/control/pixel-control.sh"
bash -n "$control"

ctrl_eh_max="$(THERMAL_DEVICE=grizzly THERMAL_CONFIG_DIR="$tmp/data" PIXEL_CONFIG_FILE="$config_g6" sh "$control" eh-max 2>&1 || true)"
grep -Fq 'RESULT: PIXEL_CONTROL_BLOCKED reason=eh_hardware_unsupported' <<<"$ctrl_eh_max"

ctrl_eh_adaptive="$(THERMAL_DEVICE=grizzly THERMAL_CONFIG_DIR="$tmp/data" PIXEL_CONFIG_FILE="$config_g6" sh "$control" eh-adaptive 2>&1 || true)"
grep -Fq 'RESULT: PIXEL_CONTROL_BLOCKED reason=eh_hardware_unsupported' <<<"$ctrl_eh_adaptive"

printf '%s\n' 'PASS pixel_control_eh_blocked_on_g6'

# ---------------------------------------------------------------------------
# Test 6: service.sh skips EH lock on unsupported hardware
# ---------------------------------------------------------------------------
service="$repo_root/service.sh"
bash -n "$service"
grep -Fq 'SERVICE_ZRAM_EH result=skipped_unsupported_hardware' "$service"

printf '%s\n' 'PASS service_skips_unsupported_eh'

# ---------------------------------------------------------------------------
# Test 7: bin/module-control status reports actual compressor & blocks EH
# ---------------------------------------------------------------------------
mod_ctrl="$repo_root/bin/module-control"
bash -n "$mod_ctrl"
grep -Fq '"zram_active_algorithm":"%s"' "$mod_ctrl"
grep -Fq '"emerald_hill_state":"%s"' "$mod_ctrl"
grep -Fq 'add_blocked eh-adaptive '\''Emerald Hill hardware acceleration is not present on this device (No EH Hardware).' "$mod_ctrl"
grep -Fq 'add_blocked eh-max '\''Emerald Hill hardware acceleration is not present on this device (No EH Hardware).' "$mod_ctrl"

printf '%s\n' 'PASS module_control_status_and_gating'

# ---------------------------------------------------------------------------
# Test 8: status-lib.sh parses active bracketed compressor & reports EH state
# ---------------------------------------------------------------------------
status_lib="$repo_root/tools/debug/status-lib.sh"
bash -n "$status_lib"
grep -Fq 'ZRAM_ACTIVE_ALGO=$zram_active_algo' "$status_lib"
grep -Fq 'ZRAM_PROP_ALGO=$zram_prop_algo' "$status_lib"
grep -Fq 'EMERALD_HILL_STATE=$eh_state' "$status_lib"
grep -Fq 'EMERALD_HILL_DISPLAY=$eh_display' "$status_lib"

printf '%s\n' 'PASS status_lib_active_compressor_reporting'

printf '%s\n' 'RESULT: ZRAM_ALGORITHM_NEGOTIATION_TEST_PASS'
