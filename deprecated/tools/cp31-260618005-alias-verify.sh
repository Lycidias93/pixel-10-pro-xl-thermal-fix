#!/usr/bin/env sh
set -eu

root="${1:-.}"
profiles="$root/profiles"
old="cp31260608007"
new="cp31260618005"
expected="${EXPECTED_CP31_260618005_ALIASES:-16}"

say() {
  printf '%s\n' "$*"
}

file_path() {
  d="$1"
  f="$2"
  if [ -s "$d/system/vendor/etc/$f" ]; then
    printf '%s\n' "$d/system/vendor/etc/$f"
  elif [ -s "$d/$f" ]; then
    printf '%s\n' "$d/$f"
  else
    printf '%s\n' ""
  fi
}

sha_file() {
  sha256sum "$1" | awk '{print $1}'
}

say "== CP31.260618.005 alias verify =="
say "root=$root"
say "profiles=$profiles"

if [ ! -d "$profiles" ]; then
  say "FAIL profiles_dir_missing"
  exit 1
fi

legacy_count=0
alias_count=0
missing_alias=0
missing_file=0
mismatch=0

for src in "$profiles"/*cp31-cp31260608007*; do
  [ -d "$src" ] || continue
  legacy_count=$((legacy_count + 1))
  src_name="$(basename "$src")"
  dst_name="$(printf '%s' "$src_name" | sed "s/$old/$new/g")"
  dst="$profiles/$dst_name"

  if [ ! -d "$dst" ]; then
    say "FAIL alias_missing source=$src_name alias=$dst_name"
    missing_alias=$((missing_alias + 1))
    continue
  fi

  alias_count=$((alias_count + 1))
  say "PASS alias_present source=$src_name alias=$dst_name"

  for f in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
    sp="$(file_path "$src" "$f")"
    dp="$(file_path "$dst" "$f")"
    if [ -z "$sp" ] || [ -z "$dp" ]; then
      say "FAIL alias_file_missing alias=$dst_name file=$f"
      missing_file=$((missing_file + 1))
      continue
    fi
    ss="$(sha_file "$sp")"
    ds="$(sha_file "$dp")"
    if [ "$ss" = "$ds" ]; then
      say "PASS alias_file_sha_match alias=$dst_name file=$f sha256=$ds"
    else
      say "FAIL alias_file_sha_mismatch source=$src_name alias=$dst_name file=$f src_sha256=$ss alias_sha256=$ds"
      mismatch=$((mismatch + 1))
    fi
  done
done

current_count=0
for dst in "$profiles"/*cp31-cp31260618005*; do
  [ -d "$dst" ] || continue
  current_count=$((current_count + 1))
done

say "cp31_legacy_alias_sources=$legacy_count"
say "cp31_current_alias_dirs=$current_count"
say "cp31_alias_pairs_verified=$alias_count"
say "cp31_missing_alias=$missing_alias"
say "cp31_missing_alias_file=$missing_file"
say "cp31_alias_file_mismatch=$mismatch"

if [ "$legacy_count" != "$expected" ]; then
  say "FAIL unexpected_legacy_source_count expected=$expected actual=$legacy_count"
  exit 2
fi
if [ "$current_count" != "$expected" ]; then
  say "FAIL unexpected_current_alias_count expected=$expected actual=$current_count"
  exit 3
fi
if [ "$missing_alias" != "0" ] || [ "$missing_file" != "0" ] || [ "$mismatch" != "0" ]; then
  say "FAIL cp31_alias_verify_failed"
  exit 4
fi

say "DECISION alias_strategy=cp31260618005_aliases_added_legacy_kept"
say "RESULT: CP31_260618005_ALIAS_VERIFY_DONE"
