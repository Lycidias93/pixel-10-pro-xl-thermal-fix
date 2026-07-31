#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import datetime as dt
import hashlib
import json
import os
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Dict, Iterable, List, Tuple

FOCUS_SENSORS = [
    "VIRTUAL-SKIN",
    "VIRTUAL-SKIN-HINT",
    "VIRTUAL-SKIN-SOC",
    "VIRTUAL-SKIN-CPU",
    "VIRTUAL-USB",
    "cellular-emergency",
    "EARLY-WARNING",
    "BG-TASKS",
    "battery",
    "usb",
    "charging",
    "speaker",
]

RELEVANT_FILES = [
    "vendor/etc/thermal_info_config.json",
    "vendor/etc/thermal_info_config_throttling.json",
    "vendor/etc/thermal_info_config_charge.json",
    "vendor/etc/powerhint.json",
    "vendor/etc/task_profiles.json",
    "vendor/build.prop",
]


def read_tsv(path: Path) -> List[dict]:
    if not path.exists() or path.stat().st_size == 0:
        return []
    with path.open("r", encoding="utf-8", errors="replace", newline="") as f:
        return list(csv.DictReader(f, delimiter="\t"))


def write_tsv(path: Path, rows: List[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        path.write_text("", encoding="utf-8")
        return
    fields: List[str] = []
    for r in rows:
        for k in r.keys():
            if k not in fields:
                fields.append(k)
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields, delimiter="\t", extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)


def norm(s: object) -> str:
    return "" if s is None else str(s)


def first_col(rows: List[dict], candidates: Iterable[str]) -> str | None:
    if not rows:
        return None
    keys = set(rows[0].keys())
    for c in candidates:
        if c in keys:
            return c
    low = {k.lower(): k for k in keys}
    for c in candidates:
        if c.lower() in low:
            return low[c.lower()]
    return None


def row_get(r: dict, *candidates: str) -> str:
    for c in candidates:
        if c in r:
            return norm(r.get(c))
    lower = {k.lower(): k for k in r.keys()}
    for c in candidates:
        k = lower.get(c.lower())
        if k:
            return norm(r.get(k))
    return ""


def is_focus_sensor(row: dict) -> bool:
    joined = " ".join(norm(v) for v in row.values())
    return any(pat.lower() in joined.lower() for pat in FOCUS_SENSORS)


def compact_value(row: dict) -> str:
    # Collect values likely to describe thresholds/delays without needing exact schema.
    parts = []
    for key in row.keys():
        lk = key.lower()
        if any(token in lk for token in ["threshold", "delay", "hysteresis", "severity", "callback", "powerhint", "value"]):
            val = norm(row.get(key))
            if val:
                parts.append(f"{key}={val}")
    return "; ".join(parts)


def infer_profile_source_name(source: str) -> tuple[str, str]:
    s = source.lower()
    device = "unknown"
    for d in ["frankel", "blazer", "mustang", "rango"]:
        if d in s:
            device = d
            break
    build = "unknown"
    for b in ["CP2A", "CP21", "CP31"]:
        if b.lower() in s:
            build = b
            break
    return device, build


def main() -> int:
    ap = argparse.ArgumentParser(description="Create a decision-focused report from Pixel 10 A17 vendor matrix TSVs.")
    ap.add_argument("--matrix", required=True, help="Matrix directory, e.g. /ssd1/jdownloader-downloads/a17_vendor_matrix")
    ap.add_argument("--out", required=True, help="Output directory for decision reports")
    args = ap.parse_args()

    matrix = Path(args.matrix)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    inventory = read_tsv(matrix / "inventory.tsv")
    build_props = read_tsv(matrix / "build_props_selected.tsv")
    thermal_key = read_tsv(matrix / "thermal_key_sensors.tsv")
    thermal_delays = read_tsv(matrix / "thermal_delays.tsv")
    zram_props = read_tsv(matrix / "zram_build_props.tsv")
    zram_fstab = read_tsv(matrix / "zram_fstab.tsv")
    file_hash = read_tsv(matrix / "file_hash_groups.tsv")
    missing = read_tsv(matrix / "missing_expected.tsv")
    init_refs = read_tsv(matrix / "init_refs.tsv")

    # Focus extracts.
    focus_key = [r for r in thermal_key if is_focus_sensor(r)]
    focus_delay = [r for r in thermal_delays if is_focus_sensor(r)]
    write_tsv(out / "focus_thermal_key_sensors.tsv", focus_key)
    write_tsv(out / "focus_thermal_delays.tsv", focus_delay)

    # Build source inventory summary.
    inv_lines = []
    device_builds: Dict[str, set] = defaultdict(set)
    for r in inventory:
        src = row_get(r, "source", "name") or row_get(r, "Source")
        device = row_get(r, "device")
        build = row_get(r, "build_family", "build")
        if not device or not build:
            d2, b2 = infer_profile_source_name(src)
            device = device or d2
            build = build or b2
        if device and build:
            device_builds[device].add(build)
        inv_lines.append(r)

    # Hash variance summary.
    hash_focus_rows = []
    for r in file_hash:
        path = row_get(r, "path", "file", "relpath")
        if path in RELEVANT_FILES or "thermal_info_config" in path or "fstab.zram" in path:
            hash_focus_rows.append(r)
    write_tsv(out / "focus_file_hash_groups.tsv", hash_focus_rows)

    # ZRAM compact summary by source.
    z_by_src: Dict[str, Counter] = defaultdict(Counter)
    for r in zram_fstab:
        src = row_get(r, "source")
        fname = row_get(r, "file", "path", "relpath")
        if src and fname:
            z_by_src[src][fname] += 1
    zprop_by_src = defaultdict(list)
    for r in zram_props:
        src = row_get(r, "source")
        key = row_get(r, "key", "prop", "property")
        val = row_get(r, "value")
        if src and key:
            zprop_by_src[src].append(f"{key}={val}")

    # Delay value variance, generic.
    delay_groups = defaultdict(set)
    for r in focus_delay:
        src = row_get(r, "source")
        sensor = row_get(r, "sensor", "name", "Sensor", "Name") or row_get(r, "sensor_name")
        val = compact_value(r) or json.dumps(r, ensure_ascii=False, sort_keys=True)
        if sensor:
            delay_groups[sensor].add(val)
    delay_variance_rows = []
    for sensor, vals in sorted(delay_groups.items()):
        delay_variance_rows.append({"sensor": sensor, "unique_value_count": len(vals), "values": " || ".join(sorted(vals))})
    write_tsv(out / "focus_delay_variance.tsv", delay_variance_rows)

    # Key threshold variance, generic.
    key_groups = defaultdict(set)
    for r in focus_key:
        sensor = row_get(r, "sensor", "name", "Sensor", "Name") or row_get(r, "sensor_name")
        if not sensor:
            # Best effort: find a value containing VIRTUAL/battery/usb.
            for v in r.values():
                sv = norm(v)
                if any(p.lower() in sv.lower() for p in FOCUS_SENSORS):
                    sensor = sv
                    break
        val = compact_value(r) or json.dumps(r, ensure_ascii=False, sort_keys=True)
        if sensor:
            key_groups[sensor].add(val)
    key_variance_rows = []
    for sensor, vals in sorted(key_groups.items()):
        key_variance_rows.append({"sensor": sensor, "unique_value_count": len(vals), "values": " || ".join(sorted(vals))})
    write_tsv(out / "focus_key_sensor_variance.tsv", key_variance_rows)

    # Write markdown report.
    report = out / "decision_report.md"
    lines = []
    lines.append("# Pixel 10 A17 Vendor Decision Report")
    lines.append("")
    lines.append(f"time={dt.datetime.now().astimezone().isoformat(timespec='seconds')}")
    lines.append(f"matrix={matrix}")
    lines.append(f"out={out}")
    lines.append("")

    lines.append("## Coverage")
    lines.append("")
    for device in sorted(device_builds):
        lines.append(f"- {device}: {', '.join(sorted(device_builds[device]))}")
    lines.append("")
    lines.append(f"inventory_rows={len(inventory)}")
    lines.append(f"missing_expected_rows={len(missing)}")
    lines.append(f"thermal_key_rows={len(thermal_key)} focus={len(focus_key)}")
    lines.append(f"thermal_delay_rows={len(thermal_delays)} focus={len(focus_delay)}")
    lines.append(f"zram_fstab_rows={len(zram_fstab)}")
    lines.append(f"zram_prop_rows={len(zram_props)}")
    lines.append(f"init_ref_rows={len(init_refs)}")
    lines.append("")

    lines.append("## Immediate conclusions")
    lines.append("")
    if len(inventory) == 12 and not missing:
        lines.append("- Factory vendor coverage is complete for 4 devices x 3 build families.")
    else:
        lines.append("- Coverage needs review before profile generation.")
    lines.append("- Build-specific profiles are required: do not reuse CP2A profiles for CP21/CP31.")
    lines.append("- Device-specific profiles are required: do not assume frankel/blazer/mustang/rango are identical.")
    lines.append("- ZRAM policy can be generated from common fstab templates, but runtime must still verify mmd/resetprop state.")
    lines.append("- Outdoor-safe should be derived from each device/build default and tuned minimally first.")
    lines.append("")

    lines.append("## File hash variance focus")
    lines.append("")
    for r in hash_focus_rows[:80]:
        path = row_get(r, "path", "file", "relpath")
        uniq = row_get(r, "unique_hashes", "hash_count", "unique_count")
        present = row_get(r, "sources_present", "present", "source_count")
        lines.append(f"- {path}: unique_hashes={uniq or '?'} sources_present={present or '?'}")
    if not hash_focus_rows:
        lines.append("- No file hash focus rows detected; inspect file_hash_groups.tsv manually.")
    lines.append("")

    lines.append("## ZRAM coverage")
    lines.append("")
    for src in sorted(z_by_src):
        lines.append(f"- {src}: fstab_entries={sum(z_by_src[src].values())} props={len(zprop_by_src.get(src, []))}")
    lines.append("")

    lines.append("## Generated files")
    lines.append("")
    for p in sorted(out.iterdir()):
        if p.is_file():
            lines.append(f"- {p}")
    lines.append("")

    report.write_text("\n".join(lines) + "\n", encoding="utf-8")

    # Console summary.
    print("== decision summary ==")
    print(report.read_text(encoding="utf-8"))
    print("RESULT: PIXEL10_A17_MATRIX_DECISION_REPORT_DONE out=" + str(out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
