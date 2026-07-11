#!/usr/bin/env python3
"""Explicit downloader for reviewed Pixel 10 factory-image manifest rows.

The tool refuses to download unless --allow-download is passed. It downloads only
rows with selected=yes and kind=factory unless filters override that selection.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import os
import sys
import tempfile
import time
import urllib.request
from pathlib import Path
from urllib.parse import urlparse

REQUIRED_FIELDS = {"device", "build", "kind", "filename", "url", "selected"}


def read_manifest(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if reader.fieldnames is None:
            raise ValueError("manifest has no header")
        missing = sorted(REQUIRED_FIELDS.difference(reader.fieldnames))
        if missing:
            raise ValueError(f"manifest missing fields: {','.join(missing)}")
        return [row for row in reader if any((value or "").strip() for value in row.values())]


def select_rows(rows: list[dict[str, str]], builds: set[str], devices: set[str], kinds: set[str]) -> list[dict[str, str]]:
    out: list[dict[str, str]] = []
    for row in rows:
        if row.get("selected", "").lower() not in {"yes", "true", "1"}:
            continue
        if builds and row.get("build", "").upper() not in builds:
            continue
        if devices and row.get("device", "").lower() not in devices:
            continue
        if kinds and row.get("kind", "").lower() not in kinds:
            continue
        out.append(row)
    return out


def safe_filename(row: dict[str, str]) -> str:
    filename = row.get("filename") or Path(urlparse(row["url"]).path).name
    if not filename.endswith(".zip") or "/" in filename or "\\" in filename or filename in {"", ".", ".."}:
        raise ValueError(f"unsafe filename: {filename!r}")
    return filename


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def download(url: str, dest: Path, timeout: int) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": "pixel10-factory-download/1.0"})
    tmp_fd, tmp_name = tempfile.mkstemp(prefix=dest.name + ".", suffix=".part", dir=str(dest.parent))
    os.close(tmp_fd)
    tmp = Path(tmp_name)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response, tmp.open("wb") as handle:  # nosec B310 - reviewed manifest URL
            while True:
                chunk = response.read(1024 * 1024)
                if not chunk:
                    break
                handle.write(chunk)
        tmp.replace(dest)
    finally:
        if tmp.exists():
            tmp.unlink()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Download reviewed Pixel 10 factory-image manifest rows.")
    parser.add_argument("--manifest", required=True, help="Reviewed TSV manifest from pixel10_factory_manifest.py.")
    parser.add_argument("--out-dir", required=True, help="Output directory for ZIP files.")
    parser.add_argument("--build", action="append", help="Build filter, e.g. CP31.260618.005. Repeatable.")
    parser.add_argument("--device", action="append", help="Device filter. Repeatable.")
    parser.add_argument("--kind", action="append", choices=("factory", "ota"), default=["factory"], help="Kind filter. Default: factory.")
    parser.add_argument("--allow-download", action="store_true", help="Required safety confirmation for large downloads.")
    parser.add_argument("--dry-run", action="store_true", help="Print planned downloads without downloading.")
    parser.add_argument("--timeout", type=int, default=120, help="HTTP timeout seconds per request.")
    args = parser.parse_args(argv)

    rows = select_rows(
        read_manifest(Path(args.manifest)),
        {b.upper() for b in (args.build or [])},
        {d.lower() for d in (args.device or [])},
        {k.lower() for k in (args.kind or [])},
    )
    if not rows:
        print("FAIL no_selected_rows", file=sys.stderr)
        return 20

    out_dir = Path(args.out_dir)
    print(f"selected_rows={len(rows)}")
    for row in rows:
        filename = safe_filename(row)
        dest = out_dir / row["build"].replace(".", "_").lower() / filename
        print(f"PLAN device={row['device']} build={row['build']} kind={row['kind']} dest={dest} url={row['url']}")
        if args.dry_run:
            continue
        if not args.allow_download:
            print("FAIL allow_download_required", file=sys.stderr)
            return 30
        if dest.exists() and dest.stat().st_size > 0:
            print(f"SKIP existing={dest} bytes={dest.stat().st_size} sha256={sha256_file(dest)}")
            continue
        start = time.time()
        download(row["url"], dest, args.timeout)
        print(f"DONE dest={dest} bytes={dest.stat().st_size} sha256={sha256_file(dest)} seconds={time.time() - start:.1f}")

    print("RESULT: PIXEL10_FACTORY_DOWNLOAD_DONE")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
