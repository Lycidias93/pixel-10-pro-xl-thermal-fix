#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
import time
import zipfile
from pathlib import Path

DEFAULT_FILES = [
    "/build.prop",
    "/etc/thermal_info_config.json",
    "/etc/thermal_info_config_throttling.json",
    "/etc/thermal_info_config_charge.json",
    "/etc/thermal_info_config_aa_throttling.json",
    "/etc/thermal_info_config_bg_tasks_throttling.json",
    "/etc/thermal_info_config_lpm.json",
    "/etc/thermal_info_config_stats.json",
    "/etc/thermal_info_config_vt.json",
    "/etc/thermal_info_config_wingboard.json",
    "/etc/thermal_info_config_earlywarnings.json",
    "/etc/powerhint.json",
    "/etc/task_profiles.json",
    "/etc/fstab.zram.2g",
    "/etc/fstab.zram.3g",
    "/etc/fstab.zram.4g",
    "/etc/fstab.zram.5g",
    "/etc/fstab.zram.6g",
    "/etc/fstab.zram.40p",
    "/etc/fstab.zram.50p",
    "/etc/fstab.zram.50p-1g",
    "/etc/fstab.zram.50p-2g",
    "/etc/fstab.zram.60p",
    "/etc/init/pixel-mm-gki.rc",
    "/etc/init/init.pixel-mm-gs.rc",
    "/etc/init/pixel-zram-comp-algorithm-experiment.rc",
    "/etc/init/android.hardware.thermal-service.pixel.rc",
    "/etc/init/pixel-thermal-symlinks.rc",
    "/etc/init/android.hardware.power-service.pixel-libperfmgr.rc",
    "/etc/init/pixel-bgtasks-experiment.rc",
]

REQUIRED = [
    "vendor/build.prop",
    "vendor/etc/thermal_info_config.json",
    "vendor/etc/thermal_info_config_throttling.json",
    "vendor/etc/thermal_info_config_charge.json",
]


def run_debugfs(img: Path, command: str, stdout_path: Path | None = None, stderr_path: Path | None = None) -> subprocess.CompletedProcess:
    stdout = subprocess.PIPE if stdout_path is None else stdout_path.open("wb")
    stderr = subprocess.PIPE if stderr_path is None else stderr_path.open("ab")
    try:
        return subprocess.run(["debugfs", "-R", command, str(img)], stdout=stdout, stderr=stderr, check=False)
    finally:
        if stdout_path is not None:
            stdout.close()
        if stderr_path is not None:
            stderr.close()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def safe_rel(vendor_path: str) -> Path:
    p = vendor_path.lstrip("/")
    return Path("vendor") / p


def extract_vendor_img(zip_path: Path, image_path: Path) -> None:
    with zipfile.ZipFile(zip_path) as zf:
        names = zf.namelist()
        if "vendor.img" not in names:
            raise RuntimeError(f"vendor.img missing in {zip_path}")
        with zf.open("vendor.img") as src, image_path.open("wb") as dst:
            shutil.copyfileobj(src, dst, length=8 * 1024 * 1024)


def parse_name(source_dir: str) -> tuple[str, str]:
    # examples:
    # frankel-cp2a.260605.012
    # frankel_beta-cp31.260608.007
    lower = source_dir.lower()
    device = lower.split("_")[0].split("-")[0]
    build = "unknown"
    for token in ["cp2a", "cp21", "cp31"]:
        if token in lower:
            build = token.upper()
            break
    return device, build


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract Pixel 10 A17 module-relevant vendor files from factory image ZIPs.")
    parser.add_argument("--base", default="/ssd1/jdownloader-downloads/a17")
    parser.add_argument("--out", default="/ssd1/jdownloader-downloads/a17_vendor_extract")
    parser.add_argument("--tmp", default="/ssd1/jdownloader-downloads/a17_vendor_extract_tmp")
    parser.add_argument("--keep-img", action="store_true")
    args = parser.parse_args()

    base = Path(args.base)
    out = Path(args.out)
    tmp = Path(args.tmp)

    if not base.is_dir():
        print(f"FAIL base_missing {base}")
        return 2
    if shutil.which("debugfs") is None:
        print("FAIL debugfs_missing")
        return 3

    tmp.mkdir(parents=True, exist_ok=True)
    out.mkdir(parents=True, exist_ok=True)

    zips = sorted(base.glob("*/image-*.zip"))
    print("== context ==")
    print(f"time={time.strftime('%Y-%m-%dT%H:%M:%S%z')}")
    print(f"base={base}")
    print(f"out={out}")
    print(f"zip_count={len(zips)}")
    print()

    if len(zips) != 12:
        print(f"WARN expected_12_image_zips got={len(zips)}")

    total_fail = 0
    matrix_rows = []

    for idx, zip_path in enumerate(zips, 1):
        source_name = zip_path.parent.name
        device, build = parse_name(source_name)
        dest = out / source_name
        meta = dest / "meta"
        img = tmp / f"{source_name}.vendor.img"

        print(f"## {idx}/{len(zips)} {source_name}")
        if dest.exists():
            shutil.rmtree(dest)
        (dest / "vendor" / "etc" / "init").mkdir(parents=True, exist_ok=True)
        meta.mkdir(parents=True, exist_ok=True)

        (meta / "source.txt").write_text(
            f"source_zip={zip_path}\nsource_dir={zip_path.parent}\ndevice={device}\nbuild_family={build}\nextract_time={time.strftime('%Y-%m-%dT%H:%M:%S%z')}\n",
            encoding="utf-8",
        )

        try:
            extract_vendor_img(zip_path, img)
            (meta / "vendor_img_sha256.txt").write_text(sha256_file(img) + "\n", encoding="utf-8")
            (meta / "vendor_img_size.txt").write_text(str(img.stat().st_size) + "\n", encoding="utf-8")

            run_debugfs(img, "ls -p /etc", meta / "etc_listing.txt", meta / "debugfs_ls.err")
            run_debugfs(img, "ls -p /etc/init", meta / "etc_init_listing.txt", meta / "debugfs_ls.err")

            extracted = []
            missed = []
            err = meta / "debugfs_dump.err"
            if err.exists():
                err.unlink()

            for vendor_path in DEFAULT_FILES:
                rel = safe_rel(vendor_path)
                target = dest / rel
                target.parent.mkdir(parents=True, exist_ok=True)
                proc = run_debugfs(img, f"dump -p {vendor_path} {target}", None, err)
                if proc.returncode == 0 and target.exists() and target.stat().st_size > 0:
                    extracted.append(str(rel))
                else:
                    if target.exists():
                        target.unlink()
                    missed.append(str(rel))

            (meta / "extracted_files.txt").write_text("\n".join(f"OK {x}" for x in extracted) + ("\n" if extracted else ""), encoding="utf-8")
            (meta / "missed_files.txt").write_text("\n".join(f"MISS {x}" for x in missed) + ("\n" if missed else ""), encoding="utf-8")

            manifest_lines = []
            sha_lines = []
            for f in sorted((dest / "vendor").rglob("*")):
                if f.is_file():
                    rel = f.relative_to(dest)
                    manifest_lines.append(f"{rel}\t{f.stat().st_size}")
                    sha_lines.append(f"{sha256_file(f)}  {rel}")
            (meta / "file_manifest.tsv").write_text("\n".join(manifest_lines) + "\n", encoding="utf-8")
            (meta / "sha256sum.txt").write_text("\n".join(sha_lines) + "\n", encoding="utf-8")

            req_status = {r: ((dest / r).exists() and (dest / r).stat().st_size > 0) for r in REQUIRED}
            zram_count = len(list((dest / "vendor" / "etc").glob("fstab.zram*")))
            pass_status = all(req_status.values())
            if pass_status:
                print(f"EXTRACT_PASS {source_name} zram_fstab_count={zram_count} files={len(extracted)}")
            else:
                total_fail += 1
                missing_required = [r for r, ok in req_status.items() if not ok]
                print(f"EXTRACT_FAIL {source_name} missing_required={','.join(missing_required)}")

            matrix_rows.append([source_name, device, build, "PASS" if pass_status else "FAIL", str(zram_count), str(len(extracted)), str(len(missed))])

        except Exception as exc:
            total_fail += 1
            print(f"EXTRACT_EXCEPTION {source_name} {type(exc).__name__}: {exc}")
            matrix_rows.append([source_name, device, build, "EXCEPTION", "0", "0", "0"])
        finally:
            if not args.keep_img and img.exists():
                img.unlink()

    matrix = out / "module_vendor_extract_matrix.tsv"
    matrix.write_text(
        "source\tdevice\tbuild_family\tstatus\tzram_fstab_count\textracted_count\tmissed_count\n" +
        "\n".join("\t".join(row) for row in matrix_rows) + "\n",
        encoding="utf-8",
    )

    print()
    print("== matrix ==")
    print(matrix.read_text(encoding="utf-8"), end="")
    print(f"out={out}")
    if total_fail:
        print(f"RESULT: PIXEL10_A17_VENDOR_RELEVANT_EXTRACT_FAIL failures={total_fail}")
        return 10
    print("RESULT: PIXEL10_A17_VENDOR_RELEVANT_EXTRACT_DONE")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
