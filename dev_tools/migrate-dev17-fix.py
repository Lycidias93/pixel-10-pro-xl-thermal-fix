#!/usr/bin/env python3
from pathlib import Path

path = Path(__file__).resolve().parents[1] / "tools/install-finalize.sh"
content = path.read_text(encoding="utf-8")
old = '    printf \'%s\\n\' "fingerprint=$fingerprint"\n'
new = '    printf \'%s\\n\' "fingerprint=${fingerprint:-unknown}"\n'
if content.count(old) != 1:
    raise SystemExit(f"guard failed fingerprint_line_count={content.count(old)}")
path.write_text(content.replace(old, new, 1), encoding="utf-8")
print("RESULT: PIXEL_THERMAL_DEV17_FINGERPRINT_GUARD_APPLIED")
