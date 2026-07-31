#!/usr/bin/env python3
from pathlib import Path

p = Path(__file__).with_name("dev21-branch-builder.py")
s = p.read_text(encoding="utf-8")
old = '''test = replace_once(test, ': > "$tmp/reinit_fail"\\n', ': > "$tmp/reinit_fail"\\n: > "$tmp/system_resetprop_fail"\\n', "system resetprop fail fixture")'''
new = '''test = test.replace(': > "$tmp/reinit_fail"\\n', ': > "$tmp/reinit_fail"\\n: > "$tmp/system_resetprop_fail"\\n', 1)'''
if old not in s:
    raise SystemExit("guard-fix target missing")
p.write_text(s.replace(old, new, 1), encoding="utf-8")
