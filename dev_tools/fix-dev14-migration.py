#!/usr/bin/env python3
# One-shot guard correction; removed by the successful migration.
from pathlib import Path

root = Path(__file__).resolve().parents[1]
target = root / "dev_tools/migrate-dev14.py"
text = target.read_text(encoding="utf-8")
lines = text.splitlines()
prefix = "replace_once('tools/ptune/ptune-install-state-observability-guard.sh'"
filtered = [line for line in lines if not line.startswith(prefix)]
removed = len(lines) - len(filtered)
if removed != 1:
    raise SystemExit(f"guard failed: expected one optional pTune migration anchor, removed={removed}")
target.write_text("\n".join(filtered) + "\n", encoding="utf-8", newline="\n")
Path(__file__).unlink()
print("RESULT: PIXEL_THERMAL_DEV14_MIGRATION_FIX_DONE")
