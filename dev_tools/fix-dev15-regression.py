#!/usr/bin/env python3
from pathlib import Path

path = Path(__file__).resolve().parents[1] / "tests/test-dev14-eh-safety.sh"
text = path.read_text(encoding="utf-8")
replacements = {
    "grep -Fq 'polling_index=1' \"$install_menu\"": "grep -Fq 'polling_index=0' \"$install_menu\"",
    "grep -Fq 'zram_index=0' \"$install_menu\"": "grep -Fq 'zram_index=1' \"$install_menu\"",
    "grep -Fq 'debug_index=0' \"$install_menu\"": "grep -Fq 'debug_index=1' \"$install_menu\"",
    "grep -Fq 'version=2.0.0-alpha.3-dev.14' \"$module_prop\"": "grep -Fq 'version=2.0.0-alpha.3-dev.15' \"$module_prop\"",
    "grep -Fq 'versionCode=1016225' \"$module_prop\"": "grep -Fq 'versionCode=1016226' \"$module_prop\"",
    "printf '%s\\n' 'PASS dev14_safe_fresh_defaults'": "printf '%s\\n' 'PASS dev15_daily_fresh_defaults'",
}
for old, new in replacements.items():
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"guard failed: expected one regression anchor, found {count}: {old}")
    text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8", newline="\n")
Path(__file__).unlink()
print("RESULT: PIXEL_THERMAL_DEV15_REGRESSION_ALIGNMENT_DONE")
