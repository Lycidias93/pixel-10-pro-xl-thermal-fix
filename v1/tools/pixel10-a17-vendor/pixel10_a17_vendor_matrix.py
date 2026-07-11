#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

IMPORTANT_SENSOR_RE = re.compile(
    r"VIRTUAL-SKIN|VIRTUAL-USB|BG[-_]?TASK|EARLY|SHUTDOWN|EMERGENCY|battery|charging|usb|speaker|CPU|GPU|TPU|SOC|skin",
    re.I,
)
ZRAM_RE = re.compile(r"zram|lmk|swap|mmd\.zram|vendor\.zram|ro\.zram", re.I)
POLL_RE = re.compile(r"PollingDelay|PassiveDelay|Delay|Trigger|Threshold|Hysteresis", re.I)


def parse_source(name: str) -> tuple[str, str, str]:
    # Examples:
    # blazer-cp2a.260605.012
    # blazer_beta-cp21.260330.011
    device = name.split("_beta-")[0].split("-")[0]
    m = re.search(r"(cp2a|cp21|cp31)\.", name, re.I)
    build_family = m.group(1).upper() if m else "UNKNOWN"
    build_id_m = re.search(r"((?:cp2a|cp21|cp31)\.\d+\.\d+)", name, re.I)
    build_id = build_id_m.group(1).upper() if build_id_m else "UNKNOWN"
    return device, build_family, build_id


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except FileNotFoundError:
        return ""


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def write_tsv(path: Path, rows: list[dict[str, Any]], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields, delimiter="\t", extrasaction="ignore")
        w.writeheader()
        for row in rows:
            w.writerow({k: "" if row.get(k) is None else row.get(k) for k in fields})


def iter_dicts(x: Any):
    if isinstance(x, dict):
        yield x
        for v in x.values():
            yield from iter_dicts(v)
    elif isinstance(x, list):
        for v in x:
            yield from iter_dicts(v)


def compact(value: Any, max_len: int = 500) -> str:
    if value is None:
        return ""
    if isinstance(value, (list, dict)):
        s = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    else:
        s = str(value)
    s = s.replace("\n", "\\n")
    return s[:max_len]


def load_json(path: Path) -> Any | None:
    try:
        return json.loads(read_text(path))
    except Exception:
        return None


def main() -> int:
    ap = argparse.ArgumentParser(description="Analyze Pixel 10 A17 vendor extracts for thermal/zram/polling coverage")
    ap.add_argument("--extract", default="/ssd1/jdownloader-downloads/a17_vendor_extract")
    ap.add_argument("--out", default="/ssd1/jdownloader-downloads/a17_vendor_matrix")
    args = ap.parse_args()

    root = Path(args.extract)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    sources = sorted([p for p in root.iterdir() if p.is_dir() and (p / "vendor").is_dir()])
    if not sources:
        print(f"FAIL no_sources extract={root}")
        return 2

    inventory_rows: list[dict[str, Any]] = []
    build_rows: list[dict[str, Any]] = []
    thermal_file_rows: list[dict[str, Any]] = []
    thermal_sensor_rows: list[dict[str, Any]] = []
    key_sensor_rows: list[dict[str, Any]] = []
    delay_rows: list[dict[str, Any]] = []
    zram_fstab_rows: list[dict[str, Any]] = []
    zram_prop_rows: list[dict[str, Any]] = []
    init_ref_rows: list[dict[str, Any]] = []
    missing_rows: list[dict[str, Any]] = []
    file_rows: list[dict[str, Any]] = []

    expected = [
        "vendor/build.prop",
        "vendor/etc/thermal_info_config.json",
        "vendor/etc/thermal_info_config_throttling.json",
        "vendor/etc/thermal_info_config_charge.json",
        "vendor/etc/powerhint.json",
        "vendor/etc/task_profiles.json",
        "vendor/etc/init/pixel-mm-gki.rc",
        "vendor/etc/init/init.pixel-mm-gs.rc",
        "vendor/etc/init/pixel-zram-comp-algorithm-experiment.rc",
        "vendor/etc/init/android.hardware.thermal-service.pixel.rc",
        "vendor/etc/init/pixel-thermal-symlinks.rc",
        "vendor/etc/init/android.hardware.power-service.pixel-libperfmgr.rc",
    ]

    for src in sources:
        name = src.name
        device, build_family, build_id = parse_source(name)
        vendor = src / "vendor"
        all_files = sorted([p for p in vendor.rglob("*") if p.is_file()])
        extracted_txt = read_text(src / "meta" / "extracted_files.txt")
        missed_count = len([ln for ln in extracted_txt.splitlines() if ln.startswith("MISS ")])
        zram_count = len(list((vendor / "etc").glob("fstab.zram*")))
        thermal_count = len(list((vendor / "etc").glob("thermal_info_config*.json")))
        inventory_rows.append({
            "source": name,
            "device": device,
            "build_family": build_family,
            "build_id": build_id,
            "file_count": len(all_files),
            "thermal_json_count": thermal_count,
            "zram_fstab_count": zram_count,
            "missed_count": missed_count,
            "path": str(src),
        })

        for rel in expected:
            p = src / rel
            if not p.exists() or p.stat().st_size == 0:
                missing_rows.append({"source": name, "device": device, "build_family": build_family, "missing": rel})

        bp = vendor / "build.prop"
        if bp.exists():
            for ln in read_text(bp).splitlines():
                if not ln or ln.startswith("#") or "=" not in ln:
                    continue
                k, v = ln.split("=", 1)
                if any(k.startswith(prefix) for prefix in ["ro.product", "ro.build", "ro.vendor", "vendor.", "mmd.", "persist.vendor", "ro.zram", "ro.lmk"]):
                    build_rows.append({
                        "source": name, "device": device, "build_family": build_family, "key": k, "value": v
                    })
                if ZRAM_RE.search(ln):
                    zram_prop_rows.append({
                        "source": name, "device": device, "build_family": build_family, "file": "vendor/build.prop", "line": ln
                    })

        for p in all_files:
            rel = p.relative_to(src).as_posix()
            file_rows.append({
                "source": name, "device": device, "build_family": build_family,
                "relpath": rel, "size": p.stat().st_size, "sha256": sha256(p)
            })

            if p.name.startswith("thermal_info_config") and p.suffix == ".json":
                data = load_json(p)
                status = "json_ok" if data is not None else "json_fail"
                thermal_file_rows.append({
                    "source": name, "device": device, "build_family": build_family,
                    "file": rel, "status": status, "size": p.stat().st_size, "sha256": sha256(p)
                })
                if data is not None:
                    for d in iter_dicts(data):
                        sensor = d.get("Name") or d.get("Sensor") or d.get("Type")
                        has_thermal_fields = any(k in d for k in [
                            "HotThreshold", "ColdThreshold", "HotHysteresis", "ColdHysteresis", "PollingDelay", "PassiveDelay", "SendCallback", "SendPowerHint", "BindedCdevInfo"
                        ])
                        if sensor and has_thermal_fields:
                            row = {
                                "source": name, "device": device, "build_family": build_family, "file": rel,
                                "sensor": str(sensor),
                                "hot_threshold": compact(d.get("HotThreshold")),
                                "cold_threshold": compact(d.get("ColdThreshold")),
                                "hot_hysteresis": compact(d.get("HotHysteresis")),
                                "cold_hysteresis": compact(d.get("ColdHysteresis")),
                                "polling_delay": compact(d.get("PollingDelay")),
                                "passive_delay": compact(d.get("PassiveDelay")),
                                "send_callback": compact(d.get("SendCallback")),
                                "send_power_hint": compact(d.get("SendPowerHint")),
                                "binded_cdev": compact(d.get("BindedCdevInfo"), 1000),
                            }
                            thermal_sensor_rows.append(row)
                            if IMPORTANT_SENSOR_RE.search(str(sensor)):
                                key_sensor_rows.append(row)
                            if d.get("PollingDelay") is not None or d.get("PassiveDelay") is not None:
                                delay_rows.append(row)

            if p.name.startswith("fstab.zram"):
                for i, ln in enumerate(read_text(p).splitlines(), 1):
                    if ln.strip() and not ln.lstrip().startswith("#"):
                        zram_fstab_rows.append({
                            "source": name, "device": device, "build_family": build_family,
                            "file": rel, "line_no": i, "line": ln
                        })

            if rel.startswith("vendor/etc/init/") and p.suffix == ".rc":
                for i, ln in enumerate(read_text(p).splitlines(), 1):
                    if ZRAM_RE.search(ln) or re.search(r"thermal|power|ptune|perfmgr", ln, re.I):
                        init_ref_rows.append({
                            "source": name, "device": device, "build_family": build_family,
                            "file": rel, "line_no": i, "line": ln.strip()
                        })

    hash_groups: list[dict[str, Any]] = []
    by_rel: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in file_rows:
        by_rel[row["relpath"]].append(row)
    for rel, rows in sorted(by_rel.items()):
        hashes = sorted(set(r["sha256"] for r in rows))
        by_hash = defaultdict(list)
        for r in rows:
            by_hash[r["sha256"]].append(f"{r['source']}")
        hash_groups.append({
            "relpath": rel,
            "sources_present": len(rows),
            "unique_hashes": len(hashes),
            "hash_groups": " | ".join(f"{h[:12]}:{','.join(sorted(v))}" for h, v in sorted(by_hash.items())),
        })

    write_tsv(out / "inventory.tsv", inventory_rows, ["source", "device", "build_family", "build_id", "file_count", "thermal_json_count", "zram_fstab_count", "missed_count", "path"])
    write_tsv(out / "build_props_selected.tsv", build_rows, ["source", "device", "build_family", "key", "value"])
    write_tsv(out / "thermal_files.tsv", thermal_file_rows, ["source", "device", "build_family", "file", "status", "size", "sha256"])
    write_tsv(out / "thermal_sensors.tsv", thermal_sensor_rows, ["source", "device", "build_family", "file", "sensor", "hot_threshold", "cold_threshold", "hot_hysteresis", "cold_hysteresis", "polling_delay", "passive_delay", "send_callback", "send_power_hint", "binded_cdev"])
    write_tsv(out / "thermal_key_sensors.tsv", key_sensor_rows, ["source", "device", "build_family", "file", "sensor", "hot_threshold", "cold_threshold", "hot_hysteresis", "cold_hysteresis", "polling_delay", "passive_delay", "send_callback", "send_power_hint", "binded_cdev"])
    write_tsv(out / "thermal_delays.tsv", delay_rows, ["source", "device", "build_family", "file", "sensor", "hot_threshold", "polling_delay", "passive_delay"])
    write_tsv(out / "zram_fstab.tsv", zram_fstab_rows, ["source", "device", "build_family", "file", "line_no", "line"])
    write_tsv(out / "zram_build_props.tsv", zram_prop_rows, ["source", "device", "build_family", "file", "line"])
    write_tsv(out / "init_refs.tsv", init_ref_rows, ["source", "device", "build_family", "file", "line_no", "line"])
    write_tsv(out / "file_hash_groups.tsv", hash_groups, ["relpath", "sources_present", "unique_hashes", "hash_groups"])
    write_tsv(out / "missing_expected.tsv", missing_rows, ["source", "device", "build_family", "missing"])

    # Compact key report for terminal.
    devices = sorted(set(r["device"] for r in inventory_rows))
    fams = sorted(set(r["build_family"] for r in inventory_rows))
    miss_count = len(missing_rows)
    summary = []
    summary.append("# Pixel 10 A17 Vendor Matrix")
    summary.append("")
    summary.append(f"extract={root}")
    summary.append(f"out={out}")
    summary.append(f"sources={len(inventory_rows)} devices={','.join(devices)} builds={','.join(fams)}")
    summary.append(f"thermal_sensor_rows={len(thermal_sensor_rows)} key_sensor_rows={len(key_sensor_rows)} delay_rows={len(delay_rows)}")
    summary.append(f"zram_fstab_rows={len(zram_fstab_rows)} zram_prop_rows={len(zram_prop_rows)} init_ref_rows={len(init_ref_rows)} missing_expected={miss_count}")
    summary.append("")
    summary.append("## Inventory")
    for r in inventory_rows:
        summary.append(f"- {r['source']}: files={r['file_count']} thermal_json={r['thermal_json_count']} zram_fstab={r['zram_fstab_count']} missed={r['missed_count']}")
    summary.append("")
    summary.append("## Hash variance")
    for r in hash_groups:
        if int(r["unique_hashes"]) > 1 and any(k in r["relpath"] for k in ["thermal_info", "fstab.zram", "build.prop", "powerhint", "task_profiles", "/init/"]):
            summary.append(f"- {r['relpath']}: unique_hashes={r['unique_hashes']} sources_present={r['sources_present']}")
    summary.append("")
    summary.append("## Outputs")
    for fn in [
        "inventory.tsv", "build_props_selected.tsv", "thermal_files.tsv", "thermal_sensors.tsv", "thermal_key_sensors.tsv", "thermal_delays.tsv", "zram_fstab.tsv", "zram_build_props.tsv", "init_refs.tsv", "file_hash_groups.tsv", "missing_expected.tsv",
    ]:
        summary.append(f"- {out / fn}")
    (out / "summary.md").write_text("\n".join(summary) + "\n", encoding="utf-8")

    print("== summary ==")
    print("\n".join(summary[:80]))
    print(f"RESULT: PIXEL10_A17_VENDOR_MATRIX_DONE out={out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
