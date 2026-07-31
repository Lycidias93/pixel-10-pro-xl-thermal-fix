#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, content: str) -> None:
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")


def replace_once(path: str, old: str, new: str) -> None:
    content = read(path)
    count = content.count(old)
    if count != 1:
        raise SystemExit(f"replace_once failed path={path} count={count} needle={old[:80]!r}")
    write(path, content.replace(old, new, 1))


def regex_once(path: str, pattern: str, replacement: str) -> None:
    content = read(path)
    updated, count = re.subn(pattern, replacement, content, count=1, flags=re.S)
    if count != 1:
        raise SystemExit(f"regex_once failed path={path} count={count} pattern={pattern!r}")
    write(path, updated)


replace_once(
    "module.prop",
    "version=2.0.0-alpha.3-dev.17\nversionCode=1016228\n",
    "version=2.0.0-alpha.3-dev.18\nversionCode=1016229\n",
)
replace_once(
    "module.prop",
    "description=V2 Alpha 3 dev.17: preserves complete install evidence across boot-time profile refreshes, records runtime state separately, and verifies intentional Thermal profile choices.\n",
    "description=V2 Alpha 3 dev.18 source: clearer experimental Emerald Hill max-lock UX, persistent bounded EH event evidence, and V2-to-main promotion readiness.\n",
)

replace_once(
    "tools/action-dashboard.sh",
    'ZRAM_LAYOUT="$MODDIR/tools/zram/materialize-zram-choice.sh"\n',
    'ZRAM_LAYOUT="$MODDIR/tools/zram/materialize-zram-choice.sh"\nEH_CONTROL="$MODDIR/tools/zram/emerald-hill-control.sh"\nEH_EVENT_LOG="$CONFIG_DIR/zram-eh/events.log"\n',
)

new_zram_block = r'''show_eh_event_log() {
  msg ""
  msg "Emerald Hill event log"
  msg "----------------------------------------"
  if [ -r "$EH_EVENT_LOG" ]; then
    tail -n 20 "$EH_EVENT_LOG" 2>/dev/null || true
  else
    msg "No EH events recorded yet."
  fi
  msg "----------------------------------------"
}

set_emerald_hill() {
  if [ "$(cfg_get ENABLE_ZRAM_100P)" != 1 ]; then
    msg "! Enable ZRAM 100% first."
    msg "! Adaptive EH remains the daily default."
    sleep 2
    return 0
  fi

  cur_oc="$(cfg_get ZRAM_EMERALD_OC)"
  [ -n "$cur_oc" ] || cur_oc=0
  case "$cur_oc" in 1) oc_idx=1 ;; *) oc_idx=0 ;; esac
  ui_menu3 "Emerald Hill mode" "Adaptive (daily default)" "EXPERIMENTAL max lock" "Back" "$oc_idx"
  [ "$UI_REASON" = "timeout" ] && return 0

  case "$UI_INDEX" in
    0)
      cfg_set ZRAM_EMERALD_OC 0
      cfg_set ZRAM_EH_RISK_ACK none
      cfg_set LAST_ZRAM_100P enabled_standard
      if [ -s "$EH_CONTROL" ]; then
        MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" ZRAM_EH_CALLER=action_adaptive \
          sh "$EH_CONTROL" restore >/dev/null 2>&1 || true
      fi
      msg "- Emerald Hill: adaptive daily mode"
    ;;
    1)
      cfg_set ENABLE_ZRAM_100P 1
      cfg_set ZRAM_RISK_ACK explicit_user_enable
      cfg_set ZRAM_EMERALD_OC 1
      cfg_set ZRAM_EH_RISK_ACK explicit_user_enable_max_lock
      cfg_set LAST_ZRAM_100P enabled_max_lock
      msg "! EXPERIMENTAL: higher heat and battery use are expected."
      if [ -s "$EH_CONTROL" ] &&
         MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" ZRAM_EH_CALLER=action_experimental_max \
           sh "$EH_CONTROL" apply >/dev/null 2>&1; then
        msg "- Emerald Hill max lock applied and logged"
      else
        msg "! Max lock configured but runtime apply failed"
        msg "! Reboot path remains configured; inspect EH event log"
      fi
    ;;
    *) msg "Back."; return 0 ;;
  esac

  printf '%s\n' yes > "$MODDIR/guard/action_cycle_pending_reboot" 2>/dev/null || true
  mark_status_dirty
  refresh_status
  show_status
  msg "Back to Advanced."
}

set_zram() {
  cur_z="$(cfg_get ENABLE_ZRAM_100P)"
  case "$cur_z" in 1) idx=0 ;; *) idx=1 ;; esac
  ui_menu3 "ZRAM 100%" "Enable 100p (adaptive EH)" "Disable" "Back" "$idx"
  [ "$UI_REASON" = "timeout" ] && return 0

  case "$UI_INDEX" in
    0)
      if [ ! -r "$ZRAM_LAYOUT" ] ||
         ! MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$ZRAM_LAYOUT" enable >/dev/null 2>&1; then
        msg "! ZRAM layout materialization failed"
        msg "! Existing configuration kept"
        return 0
      fi
      cfg_set ENABLE_ZRAM_100P 1
      cfg_set ZRAM_RESTART_MMD 1
      cfg_set ZRAM_RISK_ACK explicit_user_enable
      cfg_set ZRAM_EMERALD_OC 0
      cfg_set ZRAM_EH_RISK_ACK none
      cfg_set LAST_ZRAM_100P enabled_standard
      if [ -s "$EH_CONTROL" ]; then
        MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" ZRAM_EH_CALLER=action_zram_enable \
          sh "$EH_CONTROL" restore >/dev/null 2>&1 || true
      fi
      if [ -s "$MODDIR/tools/zram/apply-zram-100p.sh" ]; then
        msg "- Applying runtime properties"
        if ! MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$MODDIR/tools/zram/apply-zram-100p.sh" manual >/dev/null 2>&1; then
          msg "! Runtime apply failed; reboot path remains configured"
        fi
      fi
      printf '%s\n' yes > "$MODDIR/guard/action_cycle_pending_reboot" 2>/dev/null || true
      msg "- ZRAM: enabled with adaptive EH"
      msg "- Experimental max lock is under Advanced"
      msg "- Reboot required for layout guarantee"
    ;;
    1)
      if [ ! -r "$ZRAM_LAYOUT" ] ||
         ! MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$ZRAM_LAYOUT" disable >/dev/null 2>&1; then
        msg "! ZRAM layout removal failed"
        msg "! Existing configuration kept"
        return 0
      fi
      if [ -s "$EH_CONTROL" ]; then
        MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" ZRAM_EH_CALLER=action_zram_disable \
          sh "$EH_CONTROL" restore >/dev/null 2>&1 || true
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
}'''

regex_once(
    "tools/action-dashboard.sh",
    r"set_zram\(\) \{.*?\n\}\n\nsettings_loop\(\)",
    new_zram_block + "\n\nsettings_loop()",
)

new_advanced = r'''advanced_loop() {
  while :; do
    ui_menu5 "Advanced" "Emerald Hill mode" "pTune Status" "pTune Override" "Update Channel" "Back" 0
    [ "$UI_REASON" = "timeout" ] && return 0
    case "$UI_INDEX" in
      0) set_emerald_hill ;;
      1) ptune_status; sleep 2 ;;
      2)
        if [ "$(cfg_get ALLOW_THERMAL_WITH_PTUNE)" = 1 ]; then ptune_override_off; else ptune_override_on; fi
        sleep 2
      ;;
      3) update_channel_loop ;;
      *) msg "Back."; return 0 ;;
    esac
  done
}'''
regex_once(
    "tools/action-dashboard.sh",
    r"advanced_loop\(\) \{.*?\n\}\n\ntoggle_debug_mode\(\)",
    new_advanced + "\n\ntoggle_debug_mode()",
)

new_debug = r'''debug_loop() {
  while :; do
    ui_menu5 "Debug" "Status" "Collect ZIP" "EH Event Log" "Debug Logging" "Back" 0
    [ "$UI_REASON" = "timeout" ] && return 0
    case "$UI_INDEX" in
      0) refresh_status; show_status; sleep 2 ;;
      1)
        if [ -s "$MODDIR/tools/bootguard/collect-debug.sh" ]; then
          sh "$MODDIR/tools/bootguard/collect-debug.sh"
        else
          msg "Collector missing"
        fi
        sleep 2
      ;;
      2) show_eh_event_log; sleep 2 ;;
      3) toggle_debug_mode; sleep 1 ;;
      *) msg "Back."; return 0 ;;
    esac
  done
}'''
regex_once(
    "tools/action-dashboard.sh",
    r"debug_loop\(\) \{.*?\n\}\n\naction_loop\(\)",
    new_debug + "\n\naction_loop()",
)

replace_once(
    "tools/menu/menu-cycle.sh",
    '    "Emerald Hill mode") echo "Adaptive daily mode or maximum-frequency minimum lock." ;;\n',
    '    "Emerald Hill mode") echo "Adaptive daily mode or EXPERIMENTAL max lock." ;;\n',
)
replace_once(
    "tools/menu/menu-cycle.sh",
    '    "Advanced") echo "pTune and update-channel tools." ;;\n',
    '    "Advanced") echo "Emerald Hill, pTune, and update-channel tools." ;;\n',
)
replace_once(
    "tools/menu/menu-cycle.sh",
    '    "Debug Logging") echo "Minimal or full debug evidence." ;;\n',
    '    "EH Event Log") echo "Show bounded apply and restore evidence." ;;\n    "Debug Logging") echo "Minimal or full debug evidence." ;;\n',
)

for path in ("tools/menu/install-options-menu.sh", "tools/action-dashboard.sh"):
    content = read(path)
    content = content.replace("Max lock (more power/heat)", "EXPERIMENTAL max lock (heat/battery)")
    content = content.replace("Adaptive (recommended)", "Adaptive (daily default)")
    write(path, content)

replace_once(
    "tools/zram/emerald-hill-control.sh",
    'STATUS_FILE="$STATE_DIR/status.env"\n',
    'STATUS_FILE="$STATE_DIR/status.env"\nEVENT_LOG="${ZRAM_EH_EVENT_LOG:-$STATE_DIR/events.log}"\nEVENT_MAX_LINES="${ZRAM_EH_EVENT_MAX_LINES:-256}"\n',
)

event_helpers = r'''
event_count() {
  event_name="$1"
  [ -r "$EVENT_LOG" ] || { printf '%s\n' 0; return 0; }
  grep -c " event=$event_name " "$EVENT_LOG" 2>/dev/null || printf '%s\n' 0
}

event_append() {
  event_name="$1"
  outcome="$2"
  path="$3"
  original_min="$4"
  observed_max="$5"
  target="$6"
  readback="$7"
  nodes="$8"
  aliases="$9"
  detail="${10}"

  mkdir -p "$STATE_DIR" 2>/dev/null || true
  chmod 0700 "$STATE_DIR" 2>/dev/null || true
  epoch="$(date +%s 2>/dev/null || printf unknown)"
  boot_id="$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || printf unknown)"
  caller="${ZRAM_EH_CALLER:-$MODE}"
  printf '%s\n' \
    "epoch=$epoch boot_id=$boot_id caller=$caller event=$event_name outcome=$outcome path=$path original_min=$original_min observed_max=$observed_max target=$target readback=$readback nodes=$nodes aliases_skipped=$aliases detail=$detail" \
    >> "$EVENT_LOG" 2>/dev/null || true
  chmod 0600 "$EVENT_LOG" 2>/dev/null || true

  case "$EVENT_MAX_LINES" in ''|*[!0-9]*) EVENT_MAX_LINES=256 ;; esac
  [ "$EVENT_MAX_LINES" -ge 32 ] 2>/dev/null || EVENT_MAX_LINES=32
  line_count="$(wc -l < "$EVENT_LOG" 2>/dev/null | tr -d '[:space:]')"
  case "$line_count" in ''|*[!0-9]*) line_count=0 ;; esac
  if [ "$line_count" -gt "$EVENT_MAX_LINES" ] 2>/dev/null; then
    tmp="$EVENT_LOG.tmp.$$"
    tail -n "$EVENT_MAX_LINES" "$EVENT_LOG" > "$tmp" 2>/dev/null || true
    chmod 0600 "$tmp" 2>/dev/null || true
    mv "$tmp" "$EVENT_LOG" 2>/dev/null || true
  fi
}
'''
replace_once(
    "tools/zram/emerald-hill-control.sh",
    'cfg_get() {\n',
    event_helpers + '\ncfg_get() {\n',
)

replace_once(
    "tools/zram/emerald-hill-control.sh",
    '    printf \'%s\\n\' "zram_enabled=$(cfg_get ENABLE_ZRAM_100P)"\n    printf \'%s\\n\' "updated_epoch=$(date +%s 2>/dev/null || printf unknown)"\n',
    '    printf \'%s\\n\' "zram_enabled=$(cfg_get ENABLE_ZRAM_100P)"\n'
    '    printf \'%s\\n\' "event_log=$EVENT_LOG"\n'
    '    printf \'%s\\n\' "apply_events=$(event_count apply)"\n'
    '    printf \'%s\\n\' "restore_events=$(event_count restore)"\n'
    '    printf \'%s\\n\' "updated_epoch=$(date +%s 2>/dev/null || printf unknown)"\n',
)

replace_once(
    "tools/zram/emerald-hill-control.sh",
    '    STATUS_ALIASES_SKIPPED=0\n    status_write adaptive not_explicitly_authorized 0 none\n    printf \'%s\\n\' \'RESULT: ZRAM_EH_APPLY_REFUSED reason=explicit_max_lock_choice_missing\'\n',
    '    STATUS_ALIASES_SKIPPED=0\n'
    '    event_append apply refused none none none none none 0 0 explicit_max_lock_choice_missing\n'
    '    status_write adaptive not_explicitly_authorized 0 none\n'
    '    printf \'%s\\n\' \'RESULT: ZRAM_EH_APPLY_REFUSED reason=explicit_max_lock_choice_missing\'\n',
)

replace_once(
    "tools/zram/emerald-hill-control.sh",
    '    status_write unsupported no_matching_devfreq_node 0 none\n    printf \'%s\\n\' \'RESULT: ZRAM_EH_APPLY_FAIL reason=no_matching_devfreq_node\'\n',
    '    event_append apply failure none none none none none 0 "$aliases_skipped" no_matching_devfreq_node\n'
    '    status_write unsupported no_matching_devfreq_node 0 none\n'
    '    printf \'%s\\n\' \'RESULT: ZRAM_EH_APPLY_FAIL reason=no_matching_devfreq_node\'\n',
)

replace_once(
    "tools/zram/emerald-hill-control.sh",
    '  status_write active max_frequency_minimum_lock_verified "$nodes" "$target_summary"\n  printf \'%s\\n\' "RESULT: ZRAM_EH_APPLY_DONE nodes=$nodes aliases_skipped=$aliases_skipped target=$target_summary policy=kernel_exposed_opp_only"\n',
    '  readback="$(cat "$first_path/min_freq" 2>/dev/null || printf unknown)"\n'
    '  event_append apply success "$first_path" "$first_original" "$first_max" "$target_summary" "$readback" "$nodes" "$aliases_skipped" max_frequency_minimum_lock_verified\n'
    '  status_write active max_frequency_minimum_lock_verified "$nodes" "$target_summary"\n'
    '  printf \'%s\\n\' "RESULT: ZRAM_EH_APPLY_DONE nodes=$nodes aliases_skipped=$aliases_skipped target=$target_summary policy=kernel_exposed_opp_only"\n',
)

replace_once(
    "tools/zram/emerald-hill-control.sh",
    '    STATUS_ALIASES_SKIPPED=0\n    status_write adaptive no_baseline 0 none\n    printf \'%s\\n\' \'RESULT: ZRAM_EH_RESTORE_DONE nodes=0 aliases_skipped=0 reason=no_baseline\'\n',
    '    STATUS_ALIASES_SKIPPED=0\n'
    '    event_append restore no_op none none none none none 0 0 no_baseline\n'
    '    status_write adaptive no_baseline 0 none\n'
    '    printf \'%s\\n\' \'RESULT: ZRAM_EH_RESTORE_DONE nodes=0 aliases_skipped=0 reason=no_baseline\'\n',
)

replace_once(
    "tools/zram/emerald-hill-control.sh",
    '    STATUS_ALIASES_SKIPPED="$RESTORE_ALIASES_SKIPPED"\n    status_write adaptive baseline_restored "$RESTORE_NODES" none\n    printf \'%s\\n\' "RESULT: ZRAM_EH_RESTORE_DONE nodes=$RESTORE_NODES aliases_skipped=$RESTORE_ALIASES_SKIPPED"\n',
    '    STATUS_ALIASES_SKIPPED="$RESTORE_ALIASES_SKIPPED"\n'
    '    event_append restore success none none none none none "$RESTORE_NODES" "$RESTORE_ALIASES_SKIPPED" baseline_restored\n'
    '    status_write adaptive baseline_restored "$RESTORE_NODES" none\n'
    '    printf \'%s\\n\' "RESULT: ZRAM_EH_RESTORE_DONE nodes=$RESTORE_NODES aliases_skipped=$RESTORE_ALIASES_SKIPPED"\n',
)

replace_once(
    "tools/zram/emerald-hill-control.sh",
    '  STATUS_ALIASES_SKIPPED="$RESTORE_ALIASES_SKIPPED"\n  status_write failed baseline_restore_incomplete "$RESTORE_NODES" none\n',
    '  STATUS_ALIASES_SKIPPED="$RESTORE_ALIASES_SKIPPED"\n'
    '  event_append restore failure none none none none none "$RESTORE_NODES" "$RESTORE_ALIASES_SKIPPED" baseline_restore_incomplete\n'
    '  status_write failed baseline_restore_incomplete "$RESTORE_NODES" none\n',
)

replace_once(
    "tests/test-dev14-eh-safety.sh",
    "grep -Fq 'Max lock (more power/heat)' \"$install_menu\"\ngrep -Fq 'Adaptive (recommended)' \"$action_dashboard\"\n",
    "grep -Fq 'EXPERIMENTAL max lock (heat/battery)' \"$install_menu\"\n"
    "grep -Fq 'Adaptive (daily default)' \"$action_dashboard\"\n",
)
replace_once(
    "tests/test-dev14-eh-safety.sh",
    "grep -Fq 'version=2.0.0-alpha.3-dev.17' \"$module_prop\"\ngrep -Fq 'versionCode=1016228' \"$module_prop\"\n",
    "grep -Fq 'version=2.0.0-alpha.3-dev.18' \"$module_prop\"\n"
    "grep -Fq 'versionCode=1016229' \"$module_prop\"\n",
)

dev18_test = r'''#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
control="$repo_root/tools/zram/emerald-hill-control.sh"
dashboard="$repo_root/tools/action-dashboard.sh"
service="$repo_root/service.sh"
post_fs="$repo_root/post-fs-data.sh"
module_prop="$repo_root/module.prop"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/physical/eh-device" "$tmp/class" "$tmp/platform/soc/devfreq" "$tmp/state" "$tmp/data"

printf '%s\n' 200000000 > "$tmp/physical/eh-device/min_freq"
printf '%s\n' 1066000000 > "$tmp/physical/eh-device/max_freq"
printf '%s\n' '200000000 400000000 800000000 1066000000' > "$tmp/physical/eh-device/available_frequencies"
ln -s ../physical/eh-device "$tmp/class/eh_freq"
ln -s ../../../physical/eh-device "$tmp/platform/soc/devfreq/eh_freq"

config="$tmp/data/config.env"
printf '%s\n' \
  'ENABLE_ZRAM_100P=1' \
  'ZRAM_RISK_ACK=explicit_user_enable' \
  'ZRAM_EH_RISK_ACK=explicit_user_enable_max_lock' \
  'LAST_ZRAM_100P=enabled_max_lock' \
  'ZRAM_EMERALD_OC=1' \
  'ZRAM_EH_TARGET_FREQ=max' > "$config"

bash -n "$control"
bash -n "$dashboard"

MODDIR="$repo_root" \
ZRAM_CONFIG_FILE="$config" \
ZRAM_EH_STATE_DIR="$tmp/state" \
ZRAM_EH_DEVFREQ_ROOTS="$tmp/class/* $tmp/platform/*/devfreq/*" \
ZRAM_EH_CALLER=dev18_test_apply \
sh "$control" apply > "$tmp/apply.log"

grep -Fq 'RESULT: ZRAM_EH_APPLY_DONE nodes=1 aliases_skipped=1 target=1066000000' "$tmp/apply.log"
grep -Fq 'caller=dev18_test_apply event=apply outcome=success' "$tmp/state/events.log"
grep -Fq 'original_min=200000000' "$tmp/state/events.log"
grep -Fq 'target=1066000000' "$tmp/state/events.log"
grep -Fq 'readback=1066000000' "$tmp/state/events.log"
grep -Fq 'apply_events=1' "$tmp/state/status.env"

MODDIR="$repo_root" \
ZRAM_CONFIG_FILE="$config" \
ZRAM_EH_STATE_DIR="$tmp/state" \
ZRAM_EH_DEVFREQ_ROOTS="$tmp/class/* $tmp/platform/*/devfreq/*" \
ZRAM_EH_CALLER=dev18_test_restore \
sh "$control" restore > "$tmp/restore.log"

grep -Fq 'RESULT: ZRAM_EH_RESTORE_DONE nodes=1 aliases_skipped=0' "$tmp/restore.log"
grep -Fq 'caller=dev18_test_restore event=restore outcome=success' "$tmp/state/events.log"
grep -Fq 'restore_events=1' "$tmp/state/status.env"
[[ "$(cat "$tmp/physical/eh-device/min_freq")" = 200000000 ]]

grep -Fq 'Experimental max lock is under Advanced' "$dashboard"
grep -Fq 'ui_menu5 "Advanced" "Emerald Hill mode"' "$dashboard"
grep -Fq 'ui_menu5 "Debug" "Status" "Collect ZIP" "EH Event Log"' "$dashboard"
grep -Fq 'EXPERIMENTAL max lock' "$dashboard"
grep -Fq 'Adaptive (daily default)' "$dashboard"

if grep -Fq 'while :; do' "$service"; then
  printf '%s\n' 'FAIL dev18_unbounded_service_watcher_present'
  exit 1
fi
if grep -Fq 'ro.lmk.swap_free_low_percentage' "$post_fs"; then
  printf '%s\n' 'FAIL dev18_unverified_early_lmk_override_present'
  exit 1
fi

grep -Fq 'version=2.0.0-alpha.3-dev.18' "$module_prop"
grep -Fq 'versionCode=1016229' "$module_prop"

printf '%s\n' 'PASS dev18_eh_apply_restore_event_log'
printf '%s\n' 'PASS dev18_eh_advanced_ux'
printf '%s\n' 'PASS dev18_no_unbounded_watcher'
printf '%s\n' 'PASS dev18_stock_lmk_default_preserved'
printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV18_EH_OBSERVABILITY_TEST_PASS'
'''
write("tests/test-dev18-eh-observability.sh", dev18_test)

dev18_workflow = r'''name: V2 Dev.18 EH observability regression

on:
  pull_request:
    branches:
      - main
      - v2
  workflow_dispatch:

permissions:
  contents: read

jobs:
  dev18-eh-observability:
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Dev.18 shell and runtime fixtures
        shell: bash
        run: |
          set -euo pipefail
          bash -n tests/test-dev18-eh-observability.sh
          bash -n tools/zram/emerald-hill-control.sh
          bash -n tools/action-dashboard.sh
          bash tests/test-dev18-eh-observability.sh
'''
write(".github/workflows/v2-dev18-eh-observability.yml", dev18_workflow)

for path in (
    ".github/workflows/v2-dev14-runtime-ci.yml",
    ".github/workflows/v2-dev16-install-regression.yml",
    ".github/workflows/v2-dev17-state-preservation.yml",
    ".github/workflows/v2-lean-package-ci.yml",
):
    content = read(path)
    old = "  pull_request:\n    branches:\n      - v2\n"
    if old not in content:
        raise SystemExit(f"workflow trigger not found path={path}")
    content = content.replace(
        old,
        "  pull_request:\n    branches:\n      - main\n      - v2\n",
        1,
    )
    write(path, content)

replace_once(
    "README.md",
    "| Current `v2` source | `2.0.0-alpha.3-dev.17` / `1016228` | Source of the current public Alpha tag; cumulative changes since dev.10 |\n",
    "| Current V2 source | `2.0.0-alpha.3-dev.18` / `1016229` | Unreleased source hardening for EH UX/evidence and `main` promotion; no tag or channel change |\n",
)
replace_once(
    "README.md",
    "Stable `update.json` remains unchanged. `update-prerelease.json` points to dev.17. Development commits never publish a tag, asset, or update-channel change by themselves.\n",
    "Stable `update.json` remains unchanged. `update-prerelease.json` points to dev.17. Development commits never publish a tag, asset, or update-channel change by themselves.\n\n"
    "`main` is being promoted to the Dynamic V2 source line. Static V1 profile snapshots remain only under `deprecated/profiles/` as historical rollback and research evidence; they are no longer an active extraction or maintenance contract.\n",
)
replace_once(
    "README.md",
    "## Dev.13 live-verification result\n",
    "## Dev.18 source hardening\n\n"
    "- keeps adaptive Emerald Hill as the daily default;\n"
    "- moves the optional maximum-frequency minimum lock into Advanced and labels it experimental;\n"
    "- records bounded persistent apply/restore evidence with boot ID, caller, node, original minimum, observed maximum, target and readback;\n"
    "- exposes the recent EH event log from Debug;\n"
    "- preserves the one-shot post-Bootguard model and does not add an unbounded screen-on watcher;\n"
    "- keeps stock LMK policy. The proposed early `ro.lmk.swap_free_low_percentage=1` path is documented for future controlled validation but is not enabled without device proof.\n\n"
    "## Dev.13 live-verification result\n",
)

replace_once(
    "CHANGELOG.md",
    "# 2.0.0-alpha.3-dev.17\n",
    "# 2.0.0-alpha.3-dev.18\n\n"
    "Unreleased V2 source hardening and `main` promotion preparation; no tag, release asset, or update-channel change.\n\n"
    "- Keeps adaptive Emerald Hill as the daily default.\n"
    "- Moves the optional max-frequency minimum lock to Advanced and labels it experimental because higher heat and battery use are expected.\n"
    "- Adds a bounded persistent EH event log with boot ID, caller, original minimum, observed maximum, target, readback, node count and alias count.\n"
    "- Exposes recent EH events from the Debug menu.\n"
    "- Retains one-shot post-Bootguard application and rejects an unbounded service watcher.\n"
    "- Preserves stock LMK policy; Harish's early post-fs-data LMKD proposal is retained as a future validation candidate, not a default claim.\n"
    "- Makes V2 CI run for both `v2` and `main` pull requests and marks static V1 profiles EOL.\n\n"
    "# 2.0.0-alpha.3-dev.17\n",
)

dev18_notes = r'''# 2.0.0-alpha.3-dev.18

Unreleased source hardening for Dynamic V2 and the controlled `v2` to `main` promotion.

## Emerald Hill

- Adaptive Emerald Hill remains the daily default.
- The optional maximum-frequency minimum lock is moved to **Advanced** and explicitly labelled **EXPERIMENTAL**.
- Enabling ZRAM no longer hides the EH choice behind a second enable action.
- A bounded persistent event log records:
  - boot ID and epoch;
  - caller and action;
  - physical path and alias count;
  - original minimum and observed maximum;
  - requested target and readback;
  - apply/restore outcome.
- The recent event log is visible from **Debug**.
- No unbounded screen-on or 60-second watcher is introduced. Application remains one-shot after Bootguard, with explicit manual Action changes also logged.

## LMKD evidence boundary

Harish / Codecity001 proposed writing `ro.lmk.swap_free_low_percentage=1` in `post-fs-data.sh` before LMKD starts. The timing argument is technically plausible, but the repository does not yet have fresh device proof that LMKD consumed the value or that the policy is safe across the supported Pixel 10 family.

Therefore dev.18:

- keeps stock LMK policy;
- does not restore the previous late unverified override;
- records the early-write proposal as a future controlled validation candidate;
- requires explicit device evidence before any runtime implementation or claim.

## Thermal polling evidence

The community discussion confirms that `polling_delay` and `passive_delay` serve different states. The module continues to change only the controlled polling values. It does not reduce the stock 7000 ms passive delay used while throttling, because that recovery interval helps prevent rapid throttle/unthrottle oscillation.

## Branch promotion

- `v2` includes the three former `main`-only governance and merged-branch-cleanup commits.
- V2 CI runs on pull requests to both `v2` and `main`.
- Static V1 profile snapshots are EOL and retained only under `deprecated/profiles/`.
- Stable `update.json`, the public dev.17 prerelease, tags and release assets remain unchanged.
'''
write("release-notes/2.0.0-alpha.3-dev.18.md", dev18_notes)

replace_once(
    "release-notes/README.md",
    "## V2 alpha line\n\n",
    "## V2 alpha line\n\n"
    "- [2.0.0-alpha.3-dev.18](2.0.0-alpha.3-dev.18.md) — unreleased EH UX/evidence hardening and controlled `v2` to `main` promotion preparation.\n",
)

v1_eol = r'''# V1 static profile line — end of active maintenance

The Dynamic V2 source line supersedes the static V1 profile model.

## Effective state

- `main` is the canonical Dynamic V2 source branch after the controlled promotion.
- `v2` remains protected during the transition and as a rollback/reference branch.
- Stable `update.json` remains on the last verified stable package until a separate explicit stable release decision.
- The public prerelease channel remains on the last published and verified prerelease until a separate release GO.

## Static profile policy

Files under `deprecated/profiles/` are retained as historical evidence only.

They are no longer:

- extracted for every monthly firmware;
- maintained as the activation source of truth;
- required for supported-build admission;
- packaged as the active Thermal source.

Dynamic V2 instead reads and validates the device's own three controlled stock Thermal files, creates a local constrained overlay, and verifies the active result.

## Rollback

Historical tags and release assets remain available. Promotion of source branches does not delete old releases or change an update channel.
'''
write("docs/V1_EOL.md", v1_eol)

for path in (
    ".github/scripts/dev18-branch-builder.py",
    ".github/workflows/dev18-branch-builder.yml",
):
    target = ROOT / path
    if target.exists():
        target.unlink()

print("RESULT: DEV18_BRANCH_BUILDER_DONE")
