#!/usr/bin/env bash
set -euo pipefail

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
layout="$root/tools/zram/materialize-zram-choice.sh"
install_zram="$root/tools/zram/install-zram.sh"
collector="$root/tools/bootguard/collect-debug-v3.sh"
menu_cycle="$root/tools/menu/menu-cycle.sh"
module_prop="$root/module.prop"

fail() { printf 'FAIL %s\n' "$*"; exit 1; }
pass() { printf 'PASS %s\n' "$*"; }

for file in "$layout" "$install_zram" "$collector" "$menu_cycle"; do
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

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/mod/tools/zram" "$tmp/mod/system/vendor/etc" "$tmp/config" "$tmp/bin"
cp "$layout" "$tmp/mod/tools/zram/materialize-zram-choice.sh"
printf '%s\n' template > "$tmp/mod/tools/zram/fstab.zram.100p"
printf '%s\n' template > "$tmp/mod/system/vendor/etc/fstab.zram.100p"

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

MV_TRACE="$tmp/mv.trace" PATH="$tmp/bin:$PATH" MODDIR="$tmp/mod" ZRAM_CONFIG_FILE="$tmp/config/config.env" \
  sh "$layout" enable > "$tmp/identical.log"
grep -Fq 'action=kept_existing' "$tmp/identical.log"
[[ ! -e "$tmp/mv.trace" ]] || fail identical_layout_attempted_replace
pass preseeded_identical_layout_is_noop

printf '%s\n' stale > "$tmp/mod/system/vendor/etc/fstab.zram.100p"
MV_TRACE="$tmp/mv.trace" PATH="$tmp/bin:$PATH" MODDIR="$tmp/mod" ZRAM_CONFIG_FILE="$tmp/config/config.env" \
  sh "$layout" enable > "$tmp/replace.log"
grep -Fq 'action=materialized' "$tmp/replace.log"
cmp -s "$tmp/mod/tools/zram/fstab.zram.100p" "$tmp/mod/system/vendor/etc/fstab.zram.100p"
grep -Fq 'existed=no' "$tmp/mv.trace"
pass differing_layout_removed_before_atomic_move

rm -f "$tmp/mv.trace" "$tmp/mod/system/vendor/etc/fstab.zram.100p"
MV_TRACE="$tmp/mv.trace" PATH="$tmp/bin:$PATH" MODDIR="$tmp/mod" ZRAM_CONFIG_FILE="$tmp/config/config.env" \
  sh "$layout" enable > "$tmp/missing.log"
grep -Fq 'action=materialized' "$tmp/missing.log"
cmp -s "$tmp/mod/tools/zram/fstab.zram.100p" "$tmp/mod/system/vendor/etc/fstab.zram.100p"
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

grep -Fq 'version=2.0.0' "$module_prop"
grep -Fq 'versionCode=1016240' "$module_prop"
pass stable_metadata_preserves_dev16_regression

printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV16_INSTALL_REGRESSION_PASS'
