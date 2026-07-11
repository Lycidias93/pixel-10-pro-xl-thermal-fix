#!/usr/bin/env python3
"""Build a reviewed manifest of Pixel 10 Android factory image URLs.

This tool fetches or reads Android factory-image HTML pages and extracts Google
factory-image ZIP URLs for the supported Pixel 10 G5 devices. It does not
download factory ZIPs. Pair it with pixel10_factory_download.py for the explicit
large-download step.
"""
from __future__ import annotations

import argparse
import csv
import datetime as _dt
import html
import re
import sys
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable
from urllib.parse import urlparse

DEFAULT_DEVICES = ("frankel", "blazer", "mustang", "rango")
DEFAULT_KINDS = ("factory",)
ZIP_RE = re.compile(r"https?://[^\s\"'<>]+?\.zip", re.IGNORECASE)
BUILD_RE = re.compile(r"(?:cp2a|cp21|cp31)\.\d{6}\.\d{3}", re.IGNORECASE)
FILENAME_RE = re.compile(
    r"(?P<device>frankel|blazer|mustang|rango)(?:_beta)?-"
    r"(?P<build>(?:cp2a|cp21|cp31)\.\d{6}\.\d{3})-"
    r"(?P<kind>factory|ota)-(?P<hash>[0-9a-f]{8}|[0-9a-f]+)\.zip$",
    re.IGNORECASE,
)

FIELDS = (
    "device",
    "build",
    "build_family",
    "kind",
    "filename",
    "url",
    "source_page",
    "generated_at",
    "selected",
    "notes",
)


@dataclass(frozen=True)
class Row:
    device: str
    build: str
    build_family: str
    kind: str
    filename: str
    url: str
    source_page: str
    generated_at: str
    selected: str = "yes"
    notes: str = "generated_by_pixel10_factory_manifest"

    def as_dict(self) -> dict[str, str]:
        return {name: getattr(self, name) for name in FIELDS}


def read_source(source: str, timeout: int) -> tuple[str, str]:
    if source.startswith(("http://", "https://")):
        req = urllib.request.Request(source, headers={"User-Agent": "pixel10-factory-manifest/1.0"})
        with urllib.request.urlopen(req, timeout=timeout) as response:  # nosec B310 - explicit user-provided source
            charset = response.headers.get_content_charset() or "utf-8"
            return source, response.read().decode(charset, errors="replace")
    path = Path(source)
    return str(path), path.read_text(encoding="utf-8", errors="replace")


def extract_urls(text: str) -> list[str]:
    text = html.unescape(text)
    urls: list[str] = []
    seen: set[str] = set()
    for match in ZIP_RE.finditer(text):
        url = match.group(0).rstrip(".,);]")
        if url not in seen:
            seen.add(url)
            urls.append(url)
    return urls


def classify_url(url: str, source_page: str, generated_at: str) -> Row | None:
    filename = Path(urlparse(url).path).name
    match = FILENAME_RE.search(filename)
    if not match:
        return None
    device = match.group("device").lower()
    build = match.group("build").upper()
    kind = match.group("kind").lower()
    build_family = build.split(".", 1)[0]
    return Row(
        device=device,
        build=build,
        build_family=build_family,
        kind=kind,
        filename=filename,
        url=url,
        source_page=source_page,
        generated_at=generated_at,
    )


def parse_rows(sources: Iterable[str], timeout: int) -> list[Row]:
    generated_at = _dt.datetime.now(_dt.timezone.utc).isoformat(timespec="seconds")
    rows: list[Row] = []
    seen: set[tuple[str, str, str, str]] = set()
    for source in sources:
        source_page, text = read_source(source, timeout)
        for url in extract_urls(text):
            row = classify_url(url, source_page, generated_at)
            if row is None:
                continue
            key = (row.device, row.build, row.kind, row.url)
            if key in seen:
                continue
            seen.add(key)
            rows.append(row)
    return rows


def filter_rows(rows: Iterable[Row], devices: set[str], builds: set[str], kinds: set[str]) -> list[Row]:
    out: list[Row] = []
    for row in rows:
        if devices and row.device not in devices:
            continue
        if builds and row.build not in builds:
            continue
        if kinds and row.kind not in kinds:
            continue
        out.append(row)
    return sorted(out, key=lambda r: (r.build, r.device, r.kind, r.filename))


def write_tsv(rows: list[Row], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDS, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow(row.as_dict())


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Create a reviewed Pixel 10 factory-image URL manifest.")
    parser.add_argument("--source", action="append", required=True, help="Android factory/OTA page URL or saved HTML file. Repeatable.")
    parser.add_argument("--out", required=True, help="Output TSV manifest path.")
    parser.add_argument("--device", action="append", choices=DEFAULT_DEVICES, help="Device filter. Repeatable. Default: all G5 Pixel 10 devices.")
    parser.add_argument("--build", action="append", help="Build filter, e.g. CP31.260618.005. Repeatable.")
    parser.add_argument("--kind", action="append", choices=("factory", "ota"), help="Image kind. Default: factory only.")
    parser.add_argument("--timeout", type=int, default=45, help="HTTP timeout seconds.")
    args = parser.parse_args(argv)

    devices = set(args.device or DEFAULT_DEVICES)
    builds = {b.upper() for b in (args.build or [])}
    kinds = set(args.kind or DEFAULT_KINDS)

    rows = filter_rows(parse_rows(args.source, args.timeout), devices, builds, kinds)
    if not rows:
        print("FAIL manifest_no_rows", file=sys.stderr)
        return 20
    write_tsv(rows, Path(args.out))
    print(f"manifest_rows={len(rows)}")
    print(f"manifest={args.out}")
    print("RESULT: PIXEL10_FACTORY_MANIFEST_DONE")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
