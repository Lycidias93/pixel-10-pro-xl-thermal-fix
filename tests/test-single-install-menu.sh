#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

grep -q 'install-options-menu.sh' customize.sh
grep -q 'mc_cycle2 "Polling Mode"' tools/menu/install-options-menu.sh
grep -q '"Thermal Profile"' tools/menu/install-options-menu.sh
grep -q 'mc_cycle2 "ZRAM 100%"' tools/menu/install-options-menu.sh
grep -q 'INSTALL_MENU_PROCESS_COUNT 1' tools/menu/install-options-menu.sh

if grep -q 'thermal-outdoor-menu.sh' tools/core/install-thermal-overlay.sh; then
  printf '%s\n' 'FAIL thermal_install_spawns_duplicate_menu'
  exit 1
fi
if grep -q 'zram-menu.sh' tools/zram/install-zram.sh; then
  printf '%s\n' 'FAIL zram_install_spawns_duplicate_menu'
  exit 1
fi

printf '%s\n' 'PASS install_choices_owned_by_single_menu_process'
printf '%s\n' 'PASS thermal_and_zram_install_helpers_are_noninteractive'
printf '%s\n' 'RESULT: PIXEL_THERMAL_SINGLE_INSTALL_MENU_TEST_PASS'
