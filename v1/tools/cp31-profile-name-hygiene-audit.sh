#!/usr/bin/env sh
set -eu

root="${1:-.}"
profiles="$root/profiles"

say() {
  printf '%s\n' "$*"
}

count_files() {
  d="$1"
  c=0
  for f in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
    if [ -s "$d/system/vendor/etc/$f" ]; then
      c=$((c + 1))
    elif [ -s "$d/$f" ]; then
      c=$((c + 1))
    fi
  done
  printf '%s' "$c"
}

say "== CP31 profile-name hygiene audit =="
say "root=$root"
say "profiles=$profiles"

if [ ! -d "$profiles" ]; then
  say "FAIL profiles_dir_missing"
  exit 1
fi

total_cp31=0
old_named=0
new_named=0
generic_named=0
bad_files=0

for d in "$profiles"/*cp31*; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  files="$(count_files "$d")"
  total_cp31=$((total_cp31 + 1))

  case "$name" in
    *cp31260608007*) old_named=$((old_named + 1)); class="compat_legacy_cp31260608007_name" ;;
    *cp31260618005*) new_named=$((new_named + 1)); class="current_cp31260618005_name" ;;
    *cp31*) generic_named=$((generic_named + 1)); class="generic_cp31_name" ;;
    *) class="unknown" ;;
  esac

  if [ "$files" = "3" ]; then
    say "PASS cp31_profile name=$name class=$class thermal_files=$files"
  else
    bad_files=$((bad_files + 1))
    say "FAIL cp31_profile name=$name class=$class thermal_files=$files"
  fi
done

say "cp31_total=$total_cp31"
say "cp31_legacy_cp31260608007_named=$old_named"
say "cp31_current_cp31260618005_named=$new_named"
say "cp31_generic_named=$generic_named"
say "cp31_bad_thermal_file_count=$bad_files"

if [ "$total_cp31" = "0" ]; then
  say "FAIL no_cp31_profiles_found"
  exit 2
fi

if [ "$bad_files" != "0" ]; then
  say "FAIL cp31_bad_thermal_file_count"
  exit 3
fi

if [ "$old_named" != "0" ] && [ "$new_named" = "0" ]; then
  say "DECISION suggested_strategy=add_cp31260618005_aliases_without_removing_legacy_names"
elif [ "$old_named" != "0" ] && [ "$new_named" != "0" ]; then
  say "DECISION suggested_strategy=keep_aliases_and_verify_selection_order"
else
  say "DECISION suggested_strategy=monitor_no_legacy_alias_action_required"
fi

say "RESULT: CP31_PROFILE_NAME_HYGIENE_AUDIT_DONE"
