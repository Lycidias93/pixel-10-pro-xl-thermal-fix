#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FILES = [
    "tests/test-dev18-eh-observability.sh",
    "tests/test-dev17-state-preservation.sh",
    "tests/test-dev16-install-regression.sh",
    "tests/test-dev15-menu-matrix.sh",
    "tests/test-dev14-eh-safety.sh",
]

for relative in FILES:
    path = ROOT / relative
    text = path.read_text(encoding="utf-8")
    old_version = text.count("version=2.0.0-alpha.3-dev.20")
    old_code = text.count("versionCode=1016231")
    text = text.replace("version=2.0.0-alpha.3-dev.20", "version=2.0.0-alpha.3-dev.21")
    text = text.replace("versionCode=1016231", "versionCode=1016232")
    if old_version == 0 and "version=2.0.0-alpha.3-dev.21" not in text:
        raise SystemExit(f"missing version anchor: {relative}")
    if old_code == 0 and "versionCode=1016232" not in text:
        raise SystemExit(f"missing versionCode anchor: {relative}")
    path.write_text(text, encoding="utf-8")

print("RESULT: DEV21_LEGACY_VERSION_ANCHORS_UPDATED")
