#!/system/bin/sh
set -eu
root="${1:-.}"
profiles="$root/profiles"
rc=0
count=0
[ -d "$profiles" ] || { echo "FAIL profiles_missing"; exit 1; }
for d in "$profiles"/*/system/vendor/etc; do
  [ -d "$d" ] || continue
  count=$((count + 1))
  name="${d%/system/vendor/etc}"
  name="${name##*/}"
  files="$(find "$d" -maxdepth 1 -type f -name 'thermal_info_config*.json' 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$files" -lt 3 ]; then
    echo "FAIL profile=$name thermal_files=$files"
    rc=1
    continue
  fi
  for f in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
    if [ ! -s "$d/$f" ]; then
      echo "FAIL profile=$name missing=$f"
      rc=1
    fi
  done
  echo "PASS profile=$name thermal_files=$files"
done
if [ "$count" -eq 0 ]; then
  echo "FAIL no_profiles_checked"
  exit 1
fi
if [ "$rc" = "0" ]; then
  echo "PROFILE_MATRIX_VERIFY_PASS count=$count"
fi
exit "$rc"
