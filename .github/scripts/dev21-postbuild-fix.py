#!/usr/bin/env python3
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]


def replace_once(path: str, old: str, new: str) -> None:
    p = ROOT / path
    text = p.read_text(encoding="utf-8")
    if new in text:
        return
    if text.count(old) != 1:
        raise SystemExit(f"guard failed for {path}: {text.count(old)} matches")
    p.write_text(text.replace(old, new, 1), encoding="utf-8")


replace_once(
    "tools/bootguard/bootguard-lib.sh",
    '  if [ "$(pending_transition)" = yes ]; then\n    VERIFY_REASON=platform_transition_pending\n',
    '  if [ "$(kv_get transition_pending "$TRANSITION")" = yes ]; then\n    VERIFY_REASON=platform_transition_pending\n',
)

replace_once(
    "tests/test-dev21-light-boot.sh",
    '[[ ! -e "$mod/guard/pending_boot" ]]\nprintf \'%s\\n\' \'THERMAL_POLLING_MODE=stock\' \'THERMAL_OUTDOOR_PROFILE=stock\' \'THERMAL_DISABLED=0\' > "$state/config.env"\n',
    '[[ ! -e "$mod/guard/pending_boot" ]]\nprintf \'%s\\n\' \'transition_pending=yes\' \'phase=prepared\' \'reason=test_transition\' > "$mod/guard/platform-transition.env"\nMODDIR="$mod" CONFIG_FILE="$state/config.env" GUARD_DIR="$mod/guard" sh "$bootguard" arm-if-needed\n[[ "$(sed -n \'s/^mode=//p\' "$mod/guard/verification-mode.env")" == full ]]\n[[ "$(sed -n \'s/^reason=//p\' "$mod/guard/verification-mode.env")" == platform_transition_pending ]]\nrm -f "$mod/guard/platform-transition.env"\nMODDIR="$mod" CONFIG_FILE="$state/config.env" GUARD_DIR="$mod/guard" sh "$bootguard" success\nprintf \'%s\\n\' \'THERMAL_POLLING_MODE=stock\' \'THERMAL_OUTDOOR_PROFILE=stock\' \'THERMAL_DISABLED=0\' > "$state/config.env"\n',
)

replace_once(
    "tests/test-dev21-light-boot.sh",
    "printf '%s\\n' 'PASS dev21_config_change_rearms_full_bootguard'\n",
    "printf '%s\\n' 'PASS dev21_platform_transition_forces_full_verification'\nprintf '%s\\n' 'PASS dev21_config_change_rearms_full_bootguard'\n",
)

subprocess.run(["bash", "-n", str(ROOT / "tools/bootguard/bootguard-lib.sh")], check=True)
subprocess.run(["bash", str(ROOT / "tests/test-dev21-light-boot.sh")], check=True)
print("RESULT: DEV21_POSTBUILD_HARDENING_PASS")
