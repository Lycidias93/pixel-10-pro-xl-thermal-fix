#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_once(path: str, old: str, new: str) -> None:
    file_path = ROOT / path
    content = file_path.read_text(encoding="utf-8")
    if new in content and old not in content:
        return
    count = content.count(old)
    if count != 1:
        raise SystemExit(f"guard failed path={path} expected_once actual={count}")
    file_path.write_text(content.replace(old, new, 1), encoding="utf-8")


replace_once(
    "README.md",
    """| Public Alpha prerelease | `2.0.0-alpha.3-dev.10` / `1016221` | Latest public Alpha; Mustang install, postboot, Thermal, ZRAM and Action verification PASS |
| Current `v2` source | `2.0.0-alpha.3-dev.17` / `1016228` | Private install-state preservation and choice-aware verification build; device verification required |
| Previous private build | `2.0.0-alpha.3-dev.16` / `1016227` | Mustang install and core runtime passed; superseded because boot-time state refresh truncated install observability |

The public prerelease is bound to tag `v2.0.0-alpha.3-dev.10`, asset `pixel-10-thermal-memory-control-2.0.0-alpha.3-dev.10.zip`, SHA-256 `49b58b8393090d057ba4ff80006615fc4805a74c92ee19d41d44200e7fe4f83a`, and size `310221` bytes.

Stable `update.json` remains unchanged. `update-prerelease.json` points to dev.10. Development commits never publish a tag, asset, or update-channel change by themselves.
""",
    """| Public Alpha prerelease | `2.0.0-alpha.3-dev.17` / `1016228` | Latest public Alpha; exact Mustang install, postboot, Thermal, ZRAM, Emerald Hill, Bootguard, and install-state verification PASS |
| Current `v2` source | `2.0.0-alpha.3-dev.17` / `1016228` | Source of the current public Alpha tag; cumulative changes since dev.10 |
| Previous public Alpha | `2.0.0-alpha.3-dev.10` / `1016221` | Superseded public Action-responsiveness prerelease |

The public prerelease is bound to tag `v2.0.0-alpha.3-dev.17`, asset `pixel-10-thermal-memory-control-2.0.0-alpha.3-dev.17.zip`, SHA-256 `3ce56a95fe9d4c2eedcdcad95e985f73296f17bc3afd22eba35c2598416c1662`, and size `324527` bytes.

Stable `update.json` remains unchanged. `update-prerelease.json` points to dev.17. Development commits never publish a tag, asset, or update-channel change by themselves.
""",
)

replace_once(
    "CHANGELOG.md",
    """# 2.0.0-alpha.3-dev.17

- Preserves complete install-time evidence while merging current boot/runtime state.
""",
    """# 2.0.0-alpha.3-dev.17

Public Alpha prerelease with the cumulative changes since public dev.10. Exact asset: `pixel-10-thermal-memory-control-2.0.0-alpha.3-dev.17.zip`, SHA-256 `3ce56a95fe9d4c2eedcdcad95e985f73296f17bc3afd22eba35c2598416c1662`, 324527 bytes.

- Preserves complete install-time evidence while merging current boot/runtime state.
""",
)

print("RESULT: PIXEL_THERMAL_DEV17_PUBLIC_METADATA_APPLIED")
