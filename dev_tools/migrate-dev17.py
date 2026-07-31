#!/usr/bin/env python3
from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, content: str) -> None:
    (ROOT / path).write_text(content, encoding="utf-8")


def replace_once(path: str, old: str, new: str) -> None:
    content = read(path)
    count = content.count(old)
    if count != 1:
        raise SystemExit(f"guard failed path={path} expected_once actual={count}")
    write(path, content.replace(old, new, 1))


def replace_regex_once(path: str, pattern: str, replacement: str) -> None:
    content = read(path)
    updated, count = re.subn(pattern, replacement, content, count=1, flags=re.S)
    if count != 1:
        raise SystemExit(f"regex guard failed path={path} actual={count}")
    write(path, updated)


replace_once(
    "tools/core/auto-profile-switch.sh",
    '''ID="pixel-10-pro-xl-thermal-fix"
MODDIR="${MODDIR:-$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)}"
G="$MODDIR/guard"
L="$G/auto-profile-switch.log"
STATE="$MODDIR/install-state.txt"
CFG="/data/adb/$ID/config.env"
''',
    '''ID="${ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)}"
G="$MODDIR/guard"
L="$G/auto-profile-switch.log"
STATE="${THERMAL_INSTALL_STATE_FILE:-$MODDIR/install-state.txt}"
DATA_ROOT="${THERMAL_DATA_ROOT:-/data/adb/$ID}"
CFG="${THERMAL_CONFIG_FILE:-$DATA_ROOT/config.env}"
''',
)

new_state_block = r'''state_set(){
  aps_key="$1"
  aps_value="$2"
  mkdir -p "${STATE%/*}" 2>/dev/null || true
  touch "$STATE" 2>/dev/null || true
  aps_tmp="$STATE.tmp.$$"
  grep -v "^${aps_key}=" "$STATE" 2>/dev/null > "$aps_tmp" || true
  printf '%s=%s\n' "$aps_key" "$aps_value" >> "$aps_tmp"
  chmod 0644 "$aps_tmp" 2>/dev/null || true
  mv "$aps_tmp" "$STATE"
}
state_profile_state_for_runtime(){
  aps_runtime="$1"
  aps_evidence="$2"
  case "$aps_runtime:$aps_evidence" in
    dynamic_local_validated:exact_verified) printf '%s\n' dynamic_stock_validated_exact_verified ;;
    *) printf '%s\n' "$aps_runtime" ;;
  esac
}
write_state(){
  aps_profile="$1"
  aps_runtime_state="$2"
  aps_platform_supported="$3"
  aps_build_evidence="$4"
  aps_polling="$(getcfg THERMAL_POLLING_MODE)"
  aps_outdoor="$(getcfg THERMAL_OUTDOOR_PROFILE)"
  aps_settings_mode="$(getcfg THERMAL_SETTINGS_MODE)"
  aps_last_outdoor="$(getcfg LAST_THERMAL_OUTDOOR_PROFILE)"
  aps_last_polling="$(getcfg LAST_THERMAL_POLLING_MODE)"
  aps_ptune_menu="$(getcfg PTUNE_OVERRIDE_MENU)"
  aps_last_ptune="$(getcfg LAST_PTUNE_OVERRIDE)"
  aps_zram_enabled="$(getcfg ENABLE_ZRAM_100P)"
  aps_zram_ack="$(getcfg ZRAM_RISK_ACK)"
  aps_zram_eh_ack="$(getcfg ZRAM_EH_RISK_ACK)"
  aps_debug_mode="$(getcfg DEBUG_MODE)"
  aps_last_debug="$(getcfg LAST_DEBUG_MODE)"
  aps_ptune_ack="$(cat "$G/ptune_risk_ack" 2>/dev/null || true)"
  [ -n "$aps_polling" ] || aps_polling=mod
  [ -n "$aps_outdoor" ] || aps_outdoor=stock
  [ -n "$aps_settings_mode" ] || aps_settings_mode=unknown
  [ -n "$aps_last_outdoor" ] || aps_last_outdoor="$aps_outdoor"
  [ -n "$aps_last_polling" ] || aps_last_polling="$aps_polling"
  [ -n "$aps_ptune_menu" ] || aps_ptune_menu=off
  [ -n "$aps_last_ptune" ] || aps_last_ptune=0
  [ -n "$aps_zram_enabled" ] || aps_zram_enabled=0
  [ -n "$aps_zram_ack" ] || aps_zram_ack=unset
  [ -n "$aps_zram_eh_ack" ] || aps_zram_eh_ack=unset
  [ -n "$aps_debug_mode" ] || aps_debug_mode=0
  [ -n "$aps_last_debug" ] || aps_last_debug=silent
  [ -n "$aps_ptune_ack" ] || aps_ptune_ack=not_present
  aps_zram_materialized=no
  if [ "$aps_zram_enabled" = 1 ] && [ -s "$MODDIR/system/vendor/etc/fstab.zram.100p" ]; then
    aps_zram_materialized=yes
  fi
  aps_profile_state="$(state_profile_state_for_runtime "$aps_runtime_state" "$aps_build_evidence")"

  state_set install_state_schema pixel-thermal-install-state-v2
  state_set install_state_owner install-finalize-preserved-by-auto-profile-switch
  state_set module_id "$ID"
  state_set module_version "$(grep -E '^version=' "$MODDIR/module.prop" 2>/dev/null | head -n 1 | sed 's/^version=//')"
  state_set module_version_code "$(grep -E '^versionCode=' "$MODDIR/module.prop" 2>/dev/null | head -n 1 | sed 's/^versionCode=//')"
  state_set device "$DEVICE"
  state_set android "$ANDROID"
  state_set android_sdk "$SDK"
  state_set build_id "$BUILD_ID"
  state_set incremental "$INCREMENTAL"
  state_set fingerprint "$FINGERPRINT"
  state_set profile "$aps_profile"
  state_set profile_state "$aps_profile_state"
  state_set profile_state_contract dynamic_stock_derived_validation_v2
  state_set runtime_profile_state "$aps_runtime_state"
  state_set runtime_profile_state_contract dynamic_local_validation_v1
  state_set platform_supported "$aps_platform_supported"
  state_set build_evidence "$aps_build_evidence"
  state_set build_state "dynamic_${DEVICE}_${BUILD_ID}_${INCREMENTAL}"
  state_set build_guard_mode dynamic_local_validation
  state_set profile_source_build "$BUILD_ID"
  state_set profile_source_incremental "$INCREMENTAL"
  state_set profile_source_fingerprint "$FINGERPRINT"
  state_set auto_profile_switch yes
  state_set auto_profile_switch_state "$aps_runtime_state"
  state_set auto_profile_switch_at "$(date -Is 2>/dev/null || date)"
  state_set profile_materialized "$([ "$aps_runtime_state" = dynamic_local_validated ] && printf yes || printf no)"
  state_set expected_thermal_files "$([ "$aps_runtime_state" = dynamic_local_validated ] && printf dynamic_validated || printf absent)"
  state_set thermal_polling_effective "$aps_polling"
  state_set thermal_outdoor_profile "$aps_outdoor"
  state_set thermal_settings_mode "$aps_settings_mode"
  state_set last_thermal_outdoor_profile "$aps_last_outdoor"
  state_set last_thermal_polling_mode "$aps_last_polling"
  state_set ptune_override_menu "$aps_ptune_menu"
  state_set last_ptune_override "$aps_last_ptune"
  state_set ptune_risk_ack "$aps_ptune_ack"
  state_set zram_fstab_materialized "$aps_zram_materialized"
  state_set zram_enabled "$aps_zram_enabled"
  state_set zram_risk_ack "$aps_zram_ack"
  state_set zram_eh_risk_ack "$aps_zram_eh_ack"
  state_set debug_mode "$aps_debug_mode"
  state_set last_debug_mode "$aps_last_debug"
  state_set runtime_selection_source config.env
}
'''

replace_regex_once(
    "tools/core/auto-profile-switch.sh",
    r"write_state\(\)\{.*?\n\}\n\nif \[ ! -r \"\$SUPPORTED_HELPER\" \]; then",
    new_state_block + '\nif [ ! -r "$SUPPORTED_HELPER" ]; then',
)

replace_once(
    "tools/core/auto-profile-switch.sh",
    '''  [ "$(getstate profile_state)" = dynamic_local_validated ] || state_refresh=1
  [ "$(getstate profile_state_contract)" = dynamic_local_validation_v1 ] || state_refresh=1
  [ "$(getstate platform_supported)" = yes ] || state_refresh=1
''',
    '''  expected_profile_state="$(state_profile_state_for_runtime dynamic_local_validated "$BUILD_EVIDENCE")"
  [ "$(getstate profile_state)" = "$expected_profile_state" ] || state_refresh=1
  [ "$(getstate profile_state_contract)" = dynamic_stock_derived_validation_v2 ] || state_refresh=1
  [ "$(getstate runtime_profile_state)" = dynamic_local_validated ] || state_refresh=1
  [ "$(getstate runtime_profile_state_contract)" = dynamic_local_validation_v1 ] || state_refresh=1
  [ "$(getstate platform_supported)" = yes ] || state_refresh=1
''',
)

replace_once(
    "tools/core/auto-profile-switch.sh",
    '''  [ "$(getstate zram_enabled)" = "$ZRAM_ENABLED" ] || state_refresh=1
  [ "$(getstate zram_fstab_materialized)" = "$ZRAM_MATERIALIZED" ] || state_refresh=1
  [ "$(getstate runtime_selection_source)" = config.env ] || state_refresh=1
''',
    '''  [ "$(getstate thermal_settings_mode)" = "$(getcfg THERMAL_SETTINGS_MODE)" ] || state_refresh=1
  [ "$(getstate zram_enabled)" = "$ZRAM_ENABLED" ] || state_refresh=1
  [ "$(getstate zram_fstab_materialized)" = "$ZRAM_MATERIALIZED" ] || state_refresh=1
  [ "$(getstate zram_risk_ack)" = "$(getcfg ZRAM_RISK_ACK)" ] || state_refresh=1
  [ "$(getstate zram_eh_risk_ack)" = "$(getcfg ZRAM_EH_RISK_ACK)" ] || state_refresh=1
  [ "$(getstate debug_mode)" = "$(getcfg DEBUG_MODE)" ] || state_refresh=1
  [ "$(getstate last_debug_mode)" = "$(getcfg LAST_DEBUG_MODE)" ] || state_refresh=1
  [ "$(getstate runtime_selection_source)" = config.env ] || state_refresh=1
''',
)

replace_once(
    "tools/install-finalize.sh",
    '''    printf '%s\\n' "incremental=$incremental"
    printf '%s\\n' "android_guard=$android_guard"
''',
    '''    printf '%s\\n' "incremental=$incremental"
    printf '%s\\n' "fingerprint=$fingerprint"
    printf '%s\\n' "install_state_schema=pixel-thermal-install-state-v2"
    printf '%s\\n' "install_state_owner=install-finalize-preserved-by-auto-profile-switch"
    printf '%s\\n' "android_guard=$android_guard"
''',
)

replace_once(
    "module.prop",
    '''version=2.0.0-alpha.3-dev.16
versionCode=1016227
''',
    '''version=2.0.0-alpha.3-dev.17
versionCode=1016228
''',
)
replace_once(
    "module.prop",
    'description=V2 Alpha 3 dev.16: Magisk-safe idempotent ZRAM staging, explicit layout failure evidence, fixed packaged-debug paths, and preserved dev.15 daily defaults/menu coverage.\n',
    'description=V2 Alpha 3 dev.17: preserves complete install evidence across boot-time profile refreshes, records runtime state separately, and verifies intentional Thermal profile choices.\n',
)

for path in ("tests/test-dev14-eh-safety.sh", "tests/test-dev15-menu-matrix.sh"):
    replace_once(path, "version=2.0.0-alpha.3-dev.16", "version=2.0.0-alpha.3-dev.17")
    replace_once(path, "versionCode=1016227", "versionCode=1016228")
replace_once("tests/test-dev15-menu-matrix.sh", "pass dev16_metadata_and_current_wording", "pass dev17_metadata_and_current_wording")

replace_once(
    "CHANGELOG.md",
    "# 2.0.0-alpha.3-dev.16\n",
    '''# 2.0.0-alpha.3-dev.17

- Preserves complete install-time evidence while merging current boot/runtime state.
- Separates canonical `profile_state` from `runtime_profile_state` instead of replacing one contract with the other.
- Keeps intentional Thermal choices such as Outdoor Extended valid in post-reboot verification.
- Preserves pTune, ZRAM, Emerald Hill and debug observability across auto-profile refreshes.
- Makes unchanged subsequent boots idempotent.
- Adds a cumulative next-public-prerelease changelog covering every private change since public dev.10.

# 2.0.0-alpha.3-dev.16
''',
)

replace_once(
    "README.md",
    '| Current `v2` source | `2.0.0-alpha.3-dev.16` / `1016227` | Private Magisk-staging/debug-collector corrective test build; device verification required |\n| Previous private build | `2.0.0-alpha.3-dev.15` / `1016226` | Mustang install reached validated Thermal output but failed at an unnecessary ZRAM fstab replacement |\n',
    '| Current `v2` source | `2.0.0-alpha.3-dev.17` / `1016228` | Private install-state preservation and choice-aware verification build; device verification required |\n| Previous private build | `2.0.0-alpha.3-dev.16` / `1016227` | Mustang install and core runtime passed; superseded because boot-time state refresh truncated install observability |\n',
)

replace_once(
    "release-notes/README.md",
    "## V2 alpha line\n\n",
    "## V2 alpha line\n\n- [Next public prerelease — cumulative changes since dev.10](public-prerelease-next-since-dev.10.md) — draft release changelog and gate; not a release authorization.\n- [2.0.0-alpha.3-dev.17](2.0.0-alpha.3-dev.17.md) — private install-state preservation and choice-aware verification correction.\n",
)

replace_once(
    "tests/test-dev17-state-preservation.sh",
    '''for file in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
  printf '%s\\n' validated > "$mod/system/vendor/etc/$file"
done
''',
    '''for file in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
  printf '%s\\n' validated > "$mod/system/vendor/etc/$file"
done
printf '%s\\n' zram > "$mod/system/vendor/etc/fstab.zram.100p"
''',
)

workflow = read(".github/workflows/v2-lean-package-ci.yml")
workflow = workflow.replace(
    "          bash -n tests/test-dev15-menu-matrix.sh\n",
    "          bash -n tests/test-dev15-menu-matrix.sh\n          bash -n tests/test-dev16-install-regression.sh\n          bash -n tests/test-dev17-state-preservation.sh\n",
    1,
)
workflow = workflow.replace(
    '''      - name: Dev.15 menu and helper route matrix
        shell: bash
        run: |
          set -euo pipefail
          bash tests/test-dev15-menu-matrix.sh
''',
    '''      - name: Dev.15 through Dev.17 corrective regressions
        shell: bash
        run: |
          set -euo pipefail
          bash tests/test-dev15-menu-matrix.sh
          bash tests/test-dev16-install-regression.sh
          bash tests/test-dev17-state-preservation.sh
''',
    1,
)
write(".github/workflows/v2-lean-package-ci.yml", workflow)

print("RESULT: PIXEL_THERMAL_DEV17_MIGRATION_APPLIED")
