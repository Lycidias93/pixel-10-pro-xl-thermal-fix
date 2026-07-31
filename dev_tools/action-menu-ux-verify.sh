#!/system/bin/sh
set -eu
cd "${0%/*}/.." || exit 1
echo "== Action menu UX verify =="
for f in action.sh tools/action-dashboard.sh tools/menu-cycle.sh tools/profile-matrix-test9.sh tools/update-channel-switch.sh; do
  sh -n "$f"
  echo "PASS sh_n $f"
done
if grep -RIn --exclude=action-menu-ux-verify.sh "Channelannel" tools CHANGELOG.md README.md 2>/dev/null; then
  echo "FAIL typo Channelannel"
  exit 20
fi
grep -q "profile_matrix_variant" tools/action-dashboard.sh
grep -q "Update Channel" tools/action-dashboard.sh
grep -q "Thermal Profile" tools/action-dashboard.sh
grep -q "Outdoor Extended" tools/action-dashboard.sh
grep -q "ZRAM 100%" tools/action-dashboard.sh
grep -q "pTune Override ON" tools/action-dashboard.sh
grep -q "Boot Crash Archive" tools/action-dashboard.sh
grep -q "Reset Counters" tools/action-dashboard.sh
grep -q "Cannot switch update channel" tools/action-dashboard.sh
grep -q "Refresh Magisk update check" tools/update-channel-switch.sh
if [ -s README.md ]; then
  grep -q "Action menu quick guide" README.md
  grep -q "Outdoor profile temperature deltas" README.md
  echo "PASS readme_runtime_or_zip_present"
else
  echo "INFO readme_absent_runtime_optional"
fi
. tools/profile-matrix-test9.sh
base="$(profile_matrix_base mustang CP2A.260605.012)"
p="$(profile_matrix_variant "$base" outdoor-extended)"
test "$p" = "mustang/17/cp2a/cp2a260605012/outdoor-extended"
test -s "profiles/$p/system/vendor/etc/thermal_info_config_throttling.json"
echo "PASS nested_mustang_cp2a_outdoor_extended=$p"
echo "RESULT: PIXEL10_ACTION_MENU_UX_VERIFY_PASS"
