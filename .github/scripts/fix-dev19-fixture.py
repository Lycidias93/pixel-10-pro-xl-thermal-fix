#!/usr/bin/env python3
from pathlib import Path

path = Path("tests/test-dev19-lmkd-early-test.sh")
content = path.read_text(encoding="utf-8")
replacements = (
    ("printf '%s\\n' '' > \"$tmp/property\"", ": > \"$tmp/property\"", 2),
    ("printf '%s\\n' '' > \"$tmp/pid\"", ": > \"$tmp/pid\"", 2),
)
for old, new, expected in replacements:
    actual = content.count(old)
    if actual != expected:
        raise SystemExit(f"fixture replacement count mismatch expected={expected} actual={actual} needle={old}")
    content = content.replace(old, new)
path.write_text(content, encoding="utf-8")
print("RESULT: DEV19_LMKD_FIXTURE_ZERO_LENGTH_FIX_DONE")
