#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(path):
    return (ROOT / path).read_text(encoding="utf-8")

def write(path, text):
    target = ROOT / path
    target.write_text(text, encoding="utf-8", newline="\n")

def replace_once(path, old, new):
    text = read(path)
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"guard failed: {path}: expected one anchor, found {count}")
    write(path, text.replace(old, new, 1))

def replace_between(path, start, end, replacement):
    text = read(path)
    if text.count(start) != 1 or text.count(end) != 1:
        raise SystemExit(f"guard failed: {path}: marker mismatch")
    before, tail = text.split(start, 1)
    _, after = tail.split(end, 1)
    write(path, before + replacement + end + after)

replace_once("tools/menu/install-options-menu.sh",
             'CONFIG_DIR="/data/adb/$MODULE_ID"\n',
             'CONFIG_DIR="${THERMAL_CONFIG_DIR:-/data/adb/$MODULE_ID}"\n')
replace_once("tools/menu/install-options-menu.sh",
             'current_polling=stock\npolling_index=1\n',
             'current_polling=mod\npolling_index=0\n')
replace_once("tools/menu/install-options-menu.sh",
             'current_zram=0\nzram_index=0\n',
             'current_zram=1\nzram_index=1\n')
replace_once("tools/menu/install-options-menu.sh",
             'current_debug=0\ndebug_index=0\n',
             'current_debug=1\ndebug_index=1\n')

replace_once("tools/menu/menu-cycle.sh",
             '    "Emerald Hill OC") echo "Enable 1.066GHz hardware ZRAM boost." ;;\n'
             '    "ZRAM 100% Options") echo "Disabled, Standard, or 1.066GHz OC." ;;\n',
             '    "Emerald Hill mode") echo "Adaptive daily mode or maximum-frequency minimum lock." ;;\n'
             '    "ZRAM 100% Options") echo "Disabled, adaptive, or maximum lock." ;;\n')

replace_once("action.sh",
             'CONFIG_DIR="/data/adb/$ID"\n',
             'CONFIG_DIR="${THERMAL_CONFIG_DIR:-/data/adb/$ID}"\n')

replace_once("tools/action-dashboard.sh",
             'CONFIG_DIR="/data/adb/$ID"\nCONFIG_FILE="$CONFIG_DIR/config.env"\n',
             'CONFIG_DIR="${THERMAL_CONFIG_DIR:-/data/adb/$ID}"\n'
             'CONFIG_FILE="$CONFIG_DIR/config.env"\n'
             'ZRAM_LAYOUT="$MODDIR/tools/zram/materialize-zram-choice.sh"\n'
             'PTUNE_ROOTS="${PTUNE_MODULE_ROOTS:-/data/adb/modules/ptune /data/adb/modules_update/ptune}"\n')
replace_once("tools/action-dashboard.sh",
             '  for d in /data/adb/modules/ptune /data/adb/modules_update/ptune; do\n',
             '  for d in $PTUNE_ROOTS; do\n')
replace_between("tools/action-dashboard.sh", "set_zram() {\n", "settings_loop() {\n", r'''set_zram() {
  cur_z="$(cfg_get ENABLE_ZRAM_100P)"
  case "$cur_z" in 1) idx=0 ;; *) idx=1 ;; esac
  ui_menu3 "ZRAM 100%" "Enable 100p" "Disable" "Back" "$idx"
  [ "$UI_REASON" = "timeout" ] && return 0

  case "$UI_INDEX" in
    0)
      cur_oc="$(cfg_get ZRAM_EMERALD_OC)"
      [ -n "$cur_oc" ] || cur_oc=0
      case "$cur_oc" in 1) oc_idx=1 ;; *) oc_idx=0 ;; esac
      ui_menu3 "Emerald Hill mode" "Adaptive (recommended)" "Max lock (more power/heat)" "Back" "$oc_idx"
      [ "$UI_REASON" = "timeout" ] && return 0
      case "$UI_INDEX" in
        0) zram_choice=enabled_standard ;;
        1) zram_choice=enabled_max_lock ;;
        *) msg "Back."; return 0 ;;
      esac

      if [ ! -r "$ZRAM_LAYOUT" ] ||
         ! MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$ZRAM_LAYOUT" enable >/dev/null 2>&1; then
        msg "! ZRAM layout materialization failed"
        msg "! Existing configuration kept"
        return 0
      fi

      cfg_set ENABLE_ZRAM_100P 1
      cfg_set ZRAM_RESTART_MMD 1
      cfg_set ZRAM_RISK_ACK explicit_user_enable
      case "$zram_choice" in
        enabled_max_lock)
          cfg_set ZRAM_EMERALD_OC 1
          cfg_set ZRAM_EH_RISK_ACK explicit_user_enable_max_lock
          cfg_set LAST_ZRAM_100P enabled_max_lock
          msg "- ZRAM: enabled (EH max lock; more power/heat)"
        ;;
        *)
          cfg_set ZRAM_EMERALD_OC 0
          cfg_set ZRAM_EH_RISK_ACK none
          cfg_set LAST_ZRAM_100P enabled_standard
          msg "- ZRAM: enabled (adaptive EH)"
        ;;
      esac

      if [ -s "$MODDIR/tools/zram/apply-zram-100p.sh" ]; then
        msg "- Applying runtime properties"
        if ! MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$MODDIR/tools/zram/apply-zram-100p.sh" manual >/dev/null 2>&1; then
          msg "! Runtime apply failed; reboot path remains configured"
        fi
      fi
      printf '%s\n' yes > "$MODDIR/guard/action_cycle_pending_reboot" 2>/dev/null || true
      msg "- Reboot required for layout guarantee"
    ;;
    1)
      if [ ! -r "$ZRAM_LAYOUT" ] ||
         ! MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$ZRAM_LAYOUT" disable >/dev/null 2>&1; then
        msg "! ZRAM layout removal failed"
        msg "! Existing configuration kept"
        return 0
      fi
      cfg_set ENABLE_ZRAM_100P 0
      cfg_set ZRAM_EMERALD_OC 0
      cfg_set ZRAM_RESTART_MMD 0
      cfg_set ZRAM_RISK_ACK disabled_by_user
      cfg_set ZRAM_EH_RISK_ACK disabled_by_user
      cfg_set LAST_ZRAM_100P disabled
      printf '%s\n' yes > "$MODDIR/guard/action_cycle_pending_reboot" 2>/dev/null || true
      msg "- ZRAM: disabled"
      msg "- Reboot required"
    ;;
    *) msg "Back."; return 0 ;;
  esac
  refresh_status
  show_status
  msg "Back to Settings."
}

''')
replace_once("tools/action-dashboard.sh",
             '    msg "Debug logging: verbose"\n  fi\n}\n',
             '    msg "Debug logging: verbose"\n  fi\n  mark_status_dirty\n}\n')

replace_once("tools/zram/reinit-zram-100p.sh",
             '  setprop persist.vendor.boot.zram.size 100p\n  setprop ro.lmk.swap_free_low_percentage 1\n',
             '  setprop persist.vendor.boot.zram.size 100p\n  printf \'%s\\n\' \'lmk_swap_low_policy=stock_unmodified\'\n')
replace_once("tools/zram/reinit-zram-100p.sh",
             '     [ "${LAST_ZRAM_100P:-}" = enabled ] &&\n'
             '     [ "${ZRAM_RISK_ACK:-}" = explicit_user_enable ]; then\n',
             '     [ "${LAST_ZRAM_100P:-}" = enabled_max_lock ] &&\n'
             '     [ "${ZRAM_RISK_ACK:-}" = explicit_user_enable ] &&\n'
             '     [ "${ZRAM_EH_RISK_ACK:-}" = explicit_user_enable_max_lock ]; then\n')

replace_once("tools/menu/zram-menu.sh",
             'CONFIG_DIR="/data/adb/pixel-10-pro-xl-thermal-fix"\n',
             'CONFIG_DIR="${THERMAL_CONFIG_DIR:-/data/adb/pixel-10-pro-xl-thermal-fix}"\n')
replace_once("tools/menu/zram-menu.sh",
             'NORMALIZE="$MODDIR/tools/zram/config-normalize.sh"\n',
             'NORMALIZE="$MODDIR/tools/zram/config-normalize.sh"\n'
             'LAYOUT="$MODDIR/tools/zram/materialize-zram-choice.sh"\n')
replace_once("tools/menu/zram-menu.sh",
             'enable_zram() { cfg_set ENABLE_ZRAM_100P 1; cfg_set ZRAM_EMERALD_OC 0; cfg_set ZRAM_RESTART_MMD 1; cfg_set ZRAM_RISK_ACK explicit_user_enable; cfg_set LAST_ZRAM_100P enabled_standard; msg "- Selected: ZRAM enabled (adaptive EH)"; }\n'
             'disable_zram() { cfg_set ENABLE_ZRAM_100P 0; cfg_set ZRAM_EMERALD_OC 0; cfg_set ZRAM_RESTART_MMD 0; cfg_set ZRAM_RISK_ACK disabled_by_user; cfg_set LAST_ZRAM_100P disabled; msg "- Selected: ZRAM disabled"; }\n',
             'enable_zram() { MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$LAYOUT" enable >/dev/null; cfg_set ENABLE_ZRAM_100P 1; cfg_set ZRAM_EMERALD_OC 0; cfg_set ZRAM_RESTART_MMD 1; cfg_set ZRAM_RISK_ACK explicit_user_enable; cfg_set ZRAM_EH_RISK_ACK none; cfg_set LAST_ZRAM_100P enabled_standard; msg "- Selected: ZRAM enabled (adaptive EH)"; msg "- Reboot required for layout guarantee"; }\n'
             'disable_zram() { MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$LAYOUT" disable >/dev/null; cfg_set ENABLE_ZRAM_100P 0; cfg_set ZRAM_EMERALD_OC 0; cfg_set ZRAM_RESTART_MMD 0; cfg_set ZRAM_RISK_ACK disabled_by_user; cfg_set ZRAM_EH_RISK_ACK disabled_by_user; cfg_set LAST_ZRAM_100P disabled; msg "- Selected: ZRAM disabled"; msg "- Reboot required"; }\n')
replace_once("tools/menu/zram-menu.sh",
             '    enabled)\n'
             '    cfg_set ENABLE_ZRAM_100P 1\n'
             '    cfg_set ZRAM_EMERALD_OC 1\n'
             '    cfg_set ZRAM_RESTART_MMD 1\n'
             '    cfg_set ZRAM_RISK_ACK explicit_user_enable\n'
             '    cfg_set LAST_ZRAM_100P enabled\n'
             '    zram_choice="enable_eh_max"\n',
             '    enabled_max_lock)\n'
             '    MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$LAYOUT" enable >/dev/null\n'
             '    cfg_set ENABLE_ZRAM_100P 1\n'
             '    cfg_set ZRAM_EMERALD_OC 1\n'
             '    cfg_set ZRAM_RESTART_MMD 1\n'
             '    cfg_set ZRAM_RISK_ACK explicit_user_enable\n'
             '    cfg_set ZRAM_EH_RISK_ACK explicit_user_enable_max_lock\n'
             '    cfg_set LAST_ZRAM_100P enabled_max_lock\n'
             '    zram_choice="enable_eh_max"\n')

replace_once("tools/install-finalize.sh",
             '    printf \'%s\\n\' "last_ptune_override=$(config_get LAST_PTUNE_OVERRIDE)"\n',
             '    printf \'%s\\n\' "last_ptune_override=$(config_get LAST_PTUNE_OVERRIDE)"\n'
             '    printf \'%s\\n\' "debug_mode=$(config_get DEBUG_MODE)"\n'
             '    printf \'%s\\n\' "last_debug_mode=$(config_get LAST_DEBUG_MODE)"\n')

replace_once("release-notes/README.md",
             '## V2 alpha line\n\n',
             '## V2 alpha line\n\n'
             '- [2.0.0-alpha.3-dev.15](2.0.0-alpha.3-dev.15.md) — private menu/defaults corrective build with transactional ZRAM layout changes and full route-matrix verification.\n')

replace_once("README.md",
             '| Current `v2` source | `2.0.0-alpha.3-dev.14` / `1016225` | Private corrective test build; device verification required |\n'
             '| Previous private build | `2.0.0-alpha.3-dev.13` / `1016224` | Superseded after the live EH alias/restore and LMK-observability findings |\n',
             '| Current `v2` source | `2.0.0-alpha.3-dev.15` / `1016226` | Private defaults/menu corrective test build; device verification required |\n'
             '| Previous private build | `2.0.0-alpha.3-dev.14` / `1016225` | EH safety correction installed successfully; superseded by the menu/defaults audit |\n')
replace_once("README.md",
             'Fresh choices that start from Stock Polling, Stock Thermal, ZRAM disabled, EH disabled and pTune override off;',
             'Fresh choices that start from Polling Mod, Stock Thermal, ZRAM 100 percent with adaptive EH, verbose logging and pTune override off;')

replace_once("CHANGELOG.md",
             '# 2.0.0-alpha.3-dev.14\n',
             '# 2.0.0-alpha.3-dev.15\n\n'
             '- Makes Polling Mod, adaptive ZRAM 100p and verbose logging the Fresh install defaults.\n'
             '- Adds complete installer/Action menu route verification including Back and timeout behavior.\n'
             '- Makes ZRAM layout changes transactional across Action, install and standalone helpers.\n'
             '- Preserves unrelated config when disabling pTune override.\n'
             '- Removes stale LMK/EH behavior from the manual reinit and fallback menu paths.\n\n'
             '# 2.0.0-alpha.3-dev.14\n')

ci = read(".github/workflows/v2-lean-package-ci.yml")
if ci.count('          bash -n tests/test-zram-eh-dev12.sh\n') != 1:
    raise SystemExit("guard failed: CI syntax anchor")
ci = ci.replace('          bash -n tests/test-zram-eh-dev12.sh\n',
                '          bash -n tests/test-zram-eh-dev12.sh\n'
                '          bash -n tests/test-dev15-menu-matrix.sh\n', 1)
if ci.count('      - name: Outdoor runtime evidence policy\n') != 1:
    raise SystemExit("guard failed: CI step anchor")
ci = ci.replace('      - name: Outdoor runtime evidence policy\n',
                '      - name: Dev.15 menu and helper route matrix\n'
                '        shell: bash\n'
                '        run: |\n'
                '          set -euo pipefail\n'
                '          bash tests/test-dev15-menu-matrix.sh\n\n'
                '      - name: Outdoor runtime evidence policy\n', 1)
write(".github/workflows/v2-lean-package-ci.yml", ci)

print("RESULT: PIXEL_THERMAL_DEV15_MIGRATION_DONE")
