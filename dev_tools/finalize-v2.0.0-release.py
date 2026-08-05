#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path

VERSION = "2.0.0"
VERSION_CODE = 1016240
TAG = "v2.0.0"
ASSET = "pixel-10-thermal-memory-control-2.0.0.zip"
ASSET_BYTES = 330660
ASSET_SHA256 = "b22eb7a5b761711c204db1ea4e375eed1cf9f1cfc39a852411e47db4481348fa"
RELEASE_URL = f"https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/{TAG}"
ASSET_URL = f"https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/download/{TAG}/{ASSET}"


def read(path: str) -> str:
    return Path(path).read_text(encoding="utf-8")


def write(path: str, content: str) -> None:
    Path(path).write_text(content.rstrip() + "\n", encoding="utf-8")


def require_once(content: str, needle: str, label: str) -> None:
    count = content.count(needle)
    if count != 1:
        raise SystemExit(f"expected exactly one {label}, found {count}")


module_prop = read("module.prop")
for expected in (
    "version=2.0.0",
    "versionCode=1016240",
    "updateJson=https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/update.json",
):
    if expected not in module_prop:
        raise SystemExit(f"module.prop gate failed: {expected}")

readme = read("README.md")
require_once(readme, "## Current release", "Current release heading")
require_once(readme, "## What the module is designed to do", "design heading")

link_line = (
    f"[Latest stable]({RELEASE_URL}) · "
    "[Latest prerelease](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.0.0-alpha.3-dev.21) · "
    "[All releases](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases) · "
    "[Telegram](https://t.me/lycidias93) · "
    "[Issues](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/issues) · "
    "[Release notes](release-notes/README.md) · [Changelog](CHANGELOG.md) · [Credits](CREDITS.md)"
)
readme, link_count = re.subn(r"^\[Latest prerelease\].*$", link_line, readme, count=1, flags=re.MULTILINE)
if link_count != 1:
    raise SystemExit(f"README latest-link replacement count={link_count}")

notice_start = readme.index("> [!IMPORTANT]")
current_heading = readme.index("## Current release", notice_start)
notice = (
    "> [!IMPORTANT]\n"
    "> **2.0.0 is the current stable release.** It passed repository CI and exact-package verification on a Pixel 10 Pro XL (`mustang`) running Android 17 build `CP2A.260705.006`. Experimental Emerald Hill and LMKD controls remain opt-in."
)
readme = readme[:notice_start] + notice + "\n\n" + readme[current_heading:]

current_heading = readme.index("## Current release")
design_heading = readme.index("## What the module is designed to do", current_heading)
current_section = f"""## Current release

| Item | Value |
|---|---|
| Version | `{VERSION}` |
| Version code | `{VERSION_CODE}` |
| Release type | Stable, device-verified Dynamic V2 |
| Tag | `{TAG}` |
| Asset | `{ASSET}` |
| Asset size | `{ASSET_BYTES}` bytes |
| SHA-256 | `{ASSET_SHA256}` |
| Device proof | `mustang / CP2A.260705.006 / Android 17` |

2.0.0 promotes Dynamic V2 to stable with stock-derived thermal materialization, guarded Polling and Outdoor profiles, optional ZRAM 100%, adaptive or experimental Emerald Hill control, the optional LMKD 1% reload path, Bootguard recovery, lightweight unchanged boots, and automatic P/T/Z/L manager badges.

The stable and test update paths remain independent. Selecting a channel changes only the active update metadata path; it does not download or flash a ZIP.

"""
readme = readme[:current_heading] + current_section + readme[design_heading:]
readme = readme.replace("Dev.21", "2.0.0")
readme, install_count = re.subn(
    r"^1\. Download the ZIP from .*?$",
    f"1. Download `{ASSET}` from the [2.0.0 stable release]({RELEASE_URL}).",
    readme,
    count=1,
    flags=re.MULTILINE,
)
if install_count != 1:
    raise SystemExit(f"README install-link replacement count={install_count}")
write("README.md", readme)

changelog = read("CHANGELOG.md")
stable_entry = f"""# 2.0.0

Stable Dynamic V2 release. Exact asset: `{ASSET}`, SHA-256 `{ASSET_SHA256}`, {ASSET_BYTES} bytes.

- Promotes the stock-derived Dynamic V2 architecture from the device-tested prerelease line to stable.
- Verifies the exact package on Pixel 10 Pro XL (`mustang`) with Android 17 build `CP2A.260705.006`.
- Records full first-boot Bootguard verification with an active validated vendor overlay and signed last-good state.
- Ships Polling Mod with 22/22 controlled values active at `5000` and four Thermal choices through Outdoor Extended `+3 °C`.
- Provides optional ZRAM 100% with `lz77eh`, `vm.swappiness=100`, active-swap and non-zero-disksize verification.
- Keeps Emerald Hill adaptive by default and gates the experimental maximum-frequency minimum lock separately.
- Provides the optional LMKD 1% policy with readback-verified property writing and targeted AOSP reinit evidence.
- Refreshes P/T/Z/L manager badges after verified boot and Action changes.
- Retains pTune conflict protection, firmware-transition rematerialization, bounded Bootguard recovery, and a lean package without development-only files or hash sidecars.

"""
if not changelog.startswith("# 2.0.0\n"):
    changelog = stable_entry + changelog
write("CHANGELOG.md", changelog)

update = {
    "version": VERSION,
    "versionCode": VERSION_CODE,
    "zipUrl": ASSET_URL,
    "changelog": (
        "Stable Dynamic V2: stock-derived guarded Thermal overlays, Polling Mod, four Outdoor profiles, optional ZRAM 100%, "
        "adaptive or experimental Emerald Hill control, optional readback-verified LMKD 1% reload, Bootguard recovery, "
        "lightweight unchanged boots, automatic P/T/Z/L badges, and exact Mustang Android 17 device verification."
    ),
}
write("update.json", json.dumps(update, indent=2, ensure_ascii=False))

release_notes = f"""# 2.0.0

2.0.0 is the first stable release of the device-tested Dynamic V2 line.

## Exact public asset

- Asset: `{ASSET}`
- Size: `{ASSET_BYTES}` bytes
- SHA-256: `{ASSET_SHA256}`
- Package entries: `56`
- The public asset reuses the exact locally verified candidate bytes without rebuilding and without a separate hash sidecar.

## Device verification

The exact package passed on a Pixel 10 Pro XL (`mustang`) running Android 17 build `CP2A.260705.006`:

- installation completed with exact package identity and Dynamic V2 local validation;
- first boot used `boot_verification_mode=full`;
- Bootguard reported `BOOTGUARD_RUNTIME_VERIFICATION=full_pass` and `active_dynamic_overlay_verified`;
- all three active `/vendor/etc` Thermal files matched the validated overlays;
- Polling Mod was active for all `22/22` controlled values at `5000`;
- Outdoor Extended validated `12` target zones and `84` threshold values at the admitted `+3 °C` delta;
- ZRAM 100% was active with `lz77eh`, a non-zero `16,331,829,248`-byte disksize, active swap, and `vm.swappiness=100`;
- LMKD property write and targeted AOSP reinit completed successfully with readback `1`;
- P/T/Z/L manager badges were all green;
- module `disable`, `skip_mount`, and `remove` flags were absent.

## Dynamic thermal architecture

- Builds guarded overlays from each device's own stock Thermal configuration.
- Admits supported Pixel 10 codenames on Android 17 and validates monthly or Canary builds locally.
- Limits modifications to the admitted Polling and Outdoor targets in three controlled Thermal files.
- Fails closed when source structure, exact deltas, manifests, active mounts, or runtime evidence do not validate.
- Quarantines stale overlays and rematerializes them after firmware or platform transitions.

## Thermal controls

- Polling Mode can preserve stock values or change admitted `PollingDelay` values from `300000` to `5000`.
- Thermal profiles include Stock, Outdoor Safe, Outdoor Plus, and Outdoor Extended.
- The fixed five-choice Action menu applies and persists all four profiles plus Back.

## Memory controls

- Optional ZRAM sizing at approximately 100% of physical RAM with `lz77eh` where supported and `vm.swappiness=100`.
- Adaptive Emerald Hill operation for daily use plus a separately acknowledged experimental maximum-frequency minimum lock.
- Optional LMKD 1% swap-free policy with Magisk `resetprop` first, readback verification, fallback handling, targeted reload, and bounded evidence.
- Independent pTune conflict detection and an explicit high-risk coexistence override.

## Boot and recovery

- Bootguard records pending and signed last-good state and can disable or skip the overlay after bounded failures.
- Install, update, firmware/configuration changes, pending transitions, debug mode, or invalid evidence trigger full verification.
- Unchanged verified normal boots can use the lightweight path while retaining automatic escalation.
- Magisk P/T/Z/L badges refresh without a permanent watcher.
- Module removal cleans both the Magisk module path and persistent module state.

## Repository verification

All six release-candidate workflows passed on the exact candidate head, covering the lean package contract, installer state, Dynamic V2 admission, Thermal and Outdoor transactions, ZRAM and Emerald Hill, LMKD, Bootguard, pTune, Action routing, and full/light boot behavior.
"""
write("release-notes/2.0.0.md", release_notes)

index = read("release-notes/README.md")
stable_index = "## Stable\n- [2.0.0](2.0.0.md) — stable device-verified Dynamic V2 release with exact Mustang package proof.\n\n"
if "- [2.0.0](2.0.0.md)" not in index:
    marker = "## V2 alpha line\n"
    require_once(index, marker, "release-note alpha heading")
    index = index.replace(marker, stable_index + marker, 1)
write("release-notes/README.md", index)

print("RESULT: FINALIZE_V200_PUBLIC_METADATA_PASS")
