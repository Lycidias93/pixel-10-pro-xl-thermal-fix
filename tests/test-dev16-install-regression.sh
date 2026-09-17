#!/usr/bin/env bash
set -euo pipefail

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
layout="$root/tools/zram/materialize-zram-choice.sh"
install_zram="$root/tools/zram/install-zram.sh"
thermal_install_overlay="$root/tools/core/install-thermal-overlay.sh"
customize="$root/customize.sh"
collector="$root/tools/bootguard/collect-debug-v3.sh"
menu_cycle="$root/tools/menu/menu-cycle.sh"
module_prop="$root/module.prop"

fail() { printf 'FAIL %s\n' "$*"; exit 1; }
pass() { printf 'PASS %s\n' "$*"; }

for file in "$layout" "$install_zram" "$thermal_install_overlay" "$customize" "$collector" "$menu_cycle"; do
  bash -n "$file" || fail "syntax file=$file"
done
pass dev16_shell_syntax

# The installer volume-key reader must bound getevent itself. Wrapping a shell
# pipeline with timeout can leave getevent alive with the command-substitution
# pipe open after the wrapper shell exits, hanging CLI installs indefinitely.
grep -Fq 'timeout "$MC_TIMEOUT_SECONDS" getevent -ql' "$menu_cycle" || fail menu_getevent_direct_timeout_missing
if grep -Fq 'timeout "$MC_TIMEOUT_SECONDS" sh -c' "$menu_cycle"; then
  fail menu_timeout_shell_wrapper_regressed
fi
grep -Fq 'if ! command -v timeout >/dev/null 2>&1; then echo timeout; return 0; fi' "$menu_cycle" || fail menu_timeout_unavailable_fail_safe_missing
pass installer_volume_key_timeout_is_bounded

# Production regression from Harish / grizzly: stock-no-overlay is valid even
# when ZRAM 100% keeps only fstab.zram.100p in system/vendor/etc.
grep -Fq 'stock|hysteresis|max-release-step|combined' "$thermal_install_overlay" || fail pixel11_split_recovery_install_modes_missing
grep -Fq 'THERMAL_MATERIALIZATION_MODE="$patch_materialization"' "$thermal_install_overlay" || fail installer_materialization_mode_not_propagated
grep -Fq 'thermal_verify_materialized_layout || thermal_abort' "$customize" || fail customize_materialization_mode_verifier_missing
if grep -Fq 'for f in $THERMAL_LAYOUT_FILES' "$customize"; then
  fail customize_still_requires_thermal_files_unconditionally
fi
pass installer_stock_no_overlay_contract_bound

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
id="pixel-10-pro-xl-thermal-fix"
adb_root="$tmp/adb"
stage="$adb_root/modules_update/$id"
config="$tmp/config/config.env"
mkdir -p "$stage/tools/zram" "$stage/system/vendor/etc" "$tmp/config" "$tmp/bin"
cp "$layout" "$stage/tools/zram/materialize-zram-choice.sh"

verify_mod="$tmp/verify-mod"
mkdir -p "$verify_mod/system/vendor/etc"
printf '%s\n' zram-only > "$verify_mod/system/vendor/etc/fstab.zram.100p"
thermal_abort() { printf 'fixture_abort %s\n' "$*" >&2; return 1; }
. "$thermal_install_overlay"
MODPATH="$verify_mod"
THERMAL_LAYOUT_FILES='thermal_info_config.json thermal_info_config_common.json'
THERMAL_MATERIALIZATION_MODE=stock-no-overlay
thermal_verify_materialized_layout || fail stock_no_overlay_rejected_zram_only_directory
grep -Fxq zram-only "$verify_mod/system/vendor/etc/fstab.zram.100p" || fail stock_no_overlay_removed_zram_fstab
printf '%s\n' stale-thermal > "$verify_mod/system/vendor/etc/thermal_info_config.json"
if thermal_verify_materialized_layout >/dev/null 2>&1; then
  fail stock_no_overlay_accepted_generated_thermal_file
fi
rm -f "$verify_mod/system/vendor/etc/thermal_info_config.json"
THERMAL_MATERIALIZATION_MODE=overlay
printf '%s\n' active > "$verify_mod/system/vendor/etc/thermal_info_config.json"
printf '%s\n' active > "$verify_mod/system/vendor/etc/thermal_info_config_common.json"
thermal_verify_materialized_layout || fail overlay_mode_rejected_complete_thermal_layout
grep -Fxq zram-only "$verify_mod/system/vendor/etc/fstab.zram.100p" || fail overlay_verifier_mutated_zram_fstab
pass installer_materialization_verifier_preserves_zram_only_stock_overlay

printf '%s\n' template > "$stage/tools/zram/fstab.zram.100p"
printf '%s\n' template > "$stage/system/vendor/etc/fstab.zram.100p"

cat > "$tmp/bin/mv" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
last=""
for arg in "$@"; do last="$arg"; done
printf 'mv destination=%s existed=%s\n' "$last" "$([[ -e "$last" ]] && echo yes || echo no)" >> "$MV_TRACE"
if [[ -e "$last" ]]; then
  printf '%s\n' 'replacement blocked by fixture' >&2
  exit 70
fi
exec /bin/mv "$@"
EOF
chmod +x "$tmp/bin/mv"

run_install_layout() {
  MV_TRACE="$tmp/mv.trace" PATH="$tmp/bin:$PATH" \
    THERMAL_ADB_ROOT="$adb_root" MODDIR="$stage" ZRAM_CONFIG_FILE="$config" \
    ZRAM_MATERIALIZE_NOW=1 ZRAM_MATERIALIZE_CALLER=install-zram \
    sh "$layout" enable
}

run_install_layout > "$tmp/identical.log"
grep -Fq 'action=kept_existing' "$tmp/identical.log"
[[ ! -e "$tmp/mv.trace" ]] || fail identical_layout_attempted_replace
pass preseeded_identical_layout_is_noop

printf '%s\n' stale > "$stage/system/vendor/etc/fstab.zram.100p"
run_install_layout > "$tmp/replace.log"
grep -Fq 'action=materialized' "$tmp/replace.log"
cmp -s "$stage/tools/zram/fstab.zram.100p" "$stage/system/vendor/etc/fstab.zram.100p"
grep -Fq 'existed=no' "$tmp/mv.trace"
pass differing_layout_removed_before_atomic_move

rm -f "$tmp/mv.trace" "$stage/system/vendor/etc/fstab.zram.100p"
run_install_layout > "$tmp/missing.log"
grep -Fq 'action=materialized' "$tmp/missing.log"
cmp -s "$stage/tools/zram/fstab.zram.100p" "$stage/system/vendor/etc/fstab.zram.100p"
pass missing_layout_materializes

grep -Fq 'install-zram-layout.log' "$install_zram"
if grep -Fq 'sh "$thermal_zram_materializer" enable >/dev/null' "$install_zram"; then
  fail install_layout_failure_still_hidden
fi
grep -Fq 'tail -n 4 "$thermal_zram_log"' "$install_zram"
pass install_failure_reason_is_preserved

grep -Fq 'collector_copy_src=' "$collector"
grep -Fq 'collector_copy_dst=' "$collector"
grep -Fq 'collector_tail_src=' "$collector"
grep -Fq 'collector_tree_dst=' "$collector"
if grep -Fq '_src="$1"; _dst="$2"' "$collector"; then
  fail collector_global_destination_collision_present
fi
pass collector_copy_helpers_do_not_overwrite_outer_destination

module_version="$(sed -n 's/^version=//p' "$module_prop" | head -n 1)"
module_version_code="$(sed -n 's/^versionCode=//p' "$module_prop" | head -n 1)"
[[ -n "$module_version" ]] || fail module_version_missing
[[ "$module_version_code" =~ ^[0-9]+$ ]] || fail module_version_code_not_integer
pass module_metadata_well_formed

printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV16_INSTALL_REGRESSION_PASS'
