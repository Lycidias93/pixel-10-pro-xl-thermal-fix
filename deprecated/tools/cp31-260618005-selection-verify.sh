#!/usr/bin/env sh
set -eu

root="${1:-.}"
profiles="$root/profiles"
helper="$root/tools/profile-matrix-test9.sh"

say() {
  printf '%s\n' "$*"
}

say "== CP31.260618.005 selection verify =="
say "root=$root"
say "profiles=$profiles"
say "helper=$helper"

if [ ! -s "$helper" ]; then
  say "FAIL helper_missing"
  exit 1
fi

. "$helper"

if ! command -v profile_matrix_base >/dev/null 2>&1; then
  say "FAIL profile_matrix_base_missing"
  exit 2
fi

missing=0
wrong=0
bad_files=0
count=0

for device in frankel blazer mustang rango; do
  expected="${device}-android17-cp31-cp31260618005"
  actual="$(profile_matrix_base "$device" "CP31.260618.005" 2>/dev/null || true)"
  count=$((count + 1))

  if [ "$actual" != "$expected" ]; then
    wrong=$((wrong + 1))
    say "FAIL selection_current_alias device=$device expected=$expected actual=${actual:-none}"
    continue
  fi
  say "PASS selection_current_alias device=$device profile=$actual"

  if [ ! -d "$profiles/$actual" ]; then
    missing=$((missing + 1))
    say "FAIL alias_dir_missing profile=$actual"
    continue
  fi

  for variant in base outdoor-extended outdoor-plus outdoor-safe; do
    case "$variant" in
      base) profile="$actual" ;;
      *) profile="$actual-$variant" ;;
    esac

    if [ ! -d "$profiles/$profile/system/vendor/etc" ]; then
      missing=$((missing + 1))
      say "FAIL alias_variant_dir_missing profile=$profile"
      continue
    fi

    files=0
    for f in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
      if [ -s "$profiles/$profile/system/vendor/etc/$f" ]; then
        files=$((files + 1))
      fi
    done

    if [ "$files" = "3" ]; then
      say "PASS alias_variant_files profile=$profile thermal_files=$files"
    else
      bad_files=$((bad_files + 1))
      say "FAIL alias_variant_files profile=$profile thermal_files=$files"
    fi
  done
done

legacy_kept=0
for d in "$profiles"/*cp31260608007*; do
  [ -d "$d" ] || continue
  legacy_kept=$((legacy_kept + 1))
done

say "selection_devices_checked=$count"
say "selection_wrong=$wrong"
say "selection_missing_alias_dirs=$missing"
say "selection_bad_thermal_file_count=$bad_files"
say "legacy_cp31260608007_dirs_kept=$legacy_kept"

if [ "$wrong" != "0" ] || [ "$missing" != "0" ] || [ "$bad_files" != "0" ]; then
  say "FAIL cp31_260618005_selection_verify"
  exit 3
fi

if [ "$legacy_kept" = "0" ]; then
  say "FAIL legacy_cp31260608007_dirs_not_kept"
  exit 4
fi

say "DECISION selection_strategy=cp31_260618005_prefers_current_alias_legacy_kept"
say "RESULT: CP31_260618005_SELECTION_VERIFY_DONE"
