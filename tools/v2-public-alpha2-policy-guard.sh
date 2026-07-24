#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
SUPPORTED="$ROOT/supported_versions.json"
OPTIONS="$ROOT/tools/menu/install-options-menu.sh"
CUSTOMIZE="$ROOT/customize.sh"
HELPER="$ROOT/tools/core/supported-build.sh"
fail=0

pass() { printf 'PASS %s\n' "$*"; }
err() { printf 'FAIL %s\n' "$*"; fail=1; }

for file in "$SUPPORTED" "$OPTIONS" "$CUSTOMIZE" "$HELPER"; do
  [[ -s "$file" ]] && pass "file_present=${file#$ROOT/}" || err "file_missing=${file#$ROOT/}"
done

for script in "$OPTIONS" "$CUSTOMIZE" "$HELPER"; do
  bash -n "$script" && pass "syntax=${script#$ROOT/}" || err "syntax=${script#$ROOT/}"
done

if grep -Fq 'cfg_set THERMAL_POLLING_MODE mod' "$OPTIONS"; then
  pass fresh_polling_mod_default
else
  err fresh_polling_mod_default
fi

if grep -Fq 'cfg_set ENABLE_ZRAM_100P 1; cfg_set ZRAM_RESTART_MMD 1' "$OPTIONS"; then
  pass fresh_zram_100p_default
else
  err fresh_zram_100p_default
fi

if grep -Fq '*-test.*|*alpha*|*beta*|*rc*|*candidate*) ui_print "Prerelease: $MODULE_VERSION"' "$CUSTOMIZE"; then
  pass prerelease_classifier
else
  err prerelease_classifier
fi

if awk '
  /"supported_android_versions"[[:space:]]*:/ { in_versions=1; next }
  in_versions && /\]/ { in_versions=0 }
  in_versions && /"17"/ { seen17=1 }
  in_versions && /"16"/ { seen16=1 }
  END { exit !(seen17 && !seen16) }
' "$SUPPORTED"
then
  pass android17_only
else
  err android17_only
fi

. "$HELPER"

for case_row in \
  'mustang 17 CP2A.260705.006' \
  'blazer 17 CP2A.260705.006' \
  'frankel 17 CP2A.260705.006' \
  'rango 17 CP2A.260705.006' \
  'blazer 17 ZP11.260618.005' \
  'frankel 17 ZP11.260618.005'
do
  set -- $case_row
  if thermal_supported_check "$SUPPORTED" "$1" "$2" "$3"; then
    pass "supported_matrix=$1/$2/$3"
  else
    err "supported_matrix=$1/$2/$3"
  fi
done

if thermal_supported_check "$SUPPORTED" mustang 16 CP2A.260705.006; then
  err android16_unexpectedly_supported
else
  pass android16_fail_closed
fi

if thermal_supported_check "$SUPPORTED" unknown 17 CP2A.260705.006; then
  err unknown_device_unexpectedly_supported
else
  pass unknown_device_fail_closed
fi

if thermal_supported_check "$SUPPORTED" mustang 17 UNKNOWN.BUILD; then
  err unknown_build_unexpectedly_supported
else
  pass unknown_build_fail_closed
fi

if [[ "$fail" -eq 0 ]]; then
  printf 'RESULT: V2_PUBLIC_ALPHA2_POLICY_GUARD_PASS rc=0\n'
else
  printf 'RESULT: V2_PUBLIC_ALPHA2_POLICY_GUARD_FAIL rc=1\n'
  exit 1
fi
