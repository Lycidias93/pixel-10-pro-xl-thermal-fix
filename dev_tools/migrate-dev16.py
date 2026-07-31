#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


def write(path, content):
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")


def replace_once(path, old, new, label):
    content = read(path)
    count = content.count(old)
    if count != 1:
        raise SystemExit(f"guard failed {label}: expected=1 actual={count}")
    write(path, content.replace(old, new, 1))


collector_path = "tools/bootguard/collect-debug-v3.sh"
replace_once(
    collector_path,
    'collect_cmd() { _name="$1"; shift; { "$@"; } > "$COLLECT/$_name" 2>&1 || true; }',
    'collect_cmd() { collector_cmd_name="$1"; shift; { "$@"; } > "$COLLECT/$collector_cmd_name" 2>&1 || true; }',
    "collector_cmd_scope",
)
replace_once(
    collector_path,
    '''copy_if_readable() {\n  _src="$1"; _dst="$2"\n  [ -r "$_src" ] || return 0\n  mkdir -p "${_dst%/*}" 2>/dev/null || true\n  cp -fp "$_src" "$_dst" 2>/dev/null || true\n}''',
    '''copy_if_readable() {\n  collector_copy_src="$1"\n  collector_copy_dst="$2"\n  [ -r "$collector_copy_src" ] || return 0\n  mkdir -p "${collector_copy_dst%/*}" 2>/dev/null || true\n  cp -fp "$collector_copy_src" "$collector_copy_dst" 2>/dev/null || true\n}''',
    "collector_copy_scope",
)
replace_once(
    collector_path,
    '''copy_tail_if_readable() {\n  _src="$1"; _dst="$2"\n  [ -r "$_src" ] || return 0\n  mkdir -p "${_dst%/*}" 2>/dev/null || true\n  tail -n 4000 "$_src" > "$_dst" 2>/dev/null || true\n}''',
    '''copy_tail_if_readable() {\n  collector_tail_src="$1"\n  collector_tail_dst="$2"\n  [ -r "$collector_tail_src" ] || return 0\n  mkdir -p "${collector_tail_dst%/*}" 2>/dev/null || true\n  tail -n 4000 "$collector_tail_src" > "$collector_tail_dst" 2>/dev/null || true\n}''',
    "collector_tail_scope",
)
replace_once(
    collector_path,
    '''copy_tree_files() {\n  _src="$1"; _dst="$2"\n  [ -d "$_src" ] || return 0\n  mkdir -p "$_dst" 2>/dev/null || true\n  find "$_src" -maxdepth 1 -type f -print 2>/dev/null | while IFS= read -r _file; do\n    cp -fp "$_file" "$_dst/${_file##*/}" 2>/dev/null || true\n  done\n}''',
    '''copy_tree_files() {\n  collector_tree_src="$1"\n  collector_tree_dst="$2"\n  [ -d "$collector_tree_src" ] || return 0\n  mkdir -p "$collector_tree_dst" 2>/dev/null || true\n  find "$collector_tree_src" -maxdepth 1 -type f -print 2>/dev/null | while IFS= read -r collector_tree_file; do\n    cp -fp "$collector_tree_file" "$collector_tree_dst/${collector_tree_file##*/}" 2>/dev/null || true\n  done\n}''',
    "collector_tree_scope",
)

replace_once("module.prop", "version=2.0.0-alpha.3-dev.15", "version=2.0.0-alpha.3-dev.16", "module_version")
replace_once("module.prop", "versionCode=1016226", "versionCode=1016227", "module_version_code")
replace_once(
    "module.prop",
    "description=V2 Alpha 3 dev.15: daily install defaults, complete menu-route verification, transactional ZRAM layout changes, preserved pTune config, and stock LMK policy across every helper path.",
    "description=V2 Alpha 3 dev.16: Magisk-safe idempotent ZRAM staging, explicit layout failure evidence, fixed packaged-debug paths, and preserved dev.15 daily defaults/menu coverage.",
    "module_description",
)

for path in ("tests/test-dev14-eh-safety.sh", "tests/test-dev15-menu-matrix.sh"):
    replace_once(path, "version=2.0.0-alpha.3-dev.15", "version=2.0.0-alpha.3-dev.16", f"{path}_version")
    replace_once(path, "versionCode=1016226", "versionCode=1016227", f"{path}_version_code")
replace_once(
    "tests/test-dev15-menu-matrix.sh",
    "pass dev15_metadata_and_current_wording",
    "pass dev16_metadata_and_current_wording",
    "test15_label",
)

changelog = read("CHANGELOG.md")
write(
    "CHANGELOG.md",
    """# 2.0.0-alpha.3-dev.16\n\n- Keeps dev.15 daily install defaults and the complete installer/Action route matrix.\n- Treats the already packaged identical ZRAM fstab as an idempotent no-op during Magisk staging.\n- Verifies temporary and final ZRAM layout content before committing a replacement.\n- Preserves detailed ZRAM materializer failure evidence in `guard/install-zram-layout.log`.\n- Fixes packaged-debug helper variable collisions that compounded destination paths.\n- Adds a regression fixture that blocks replacement of existing files to reproduce the Mustang install failure.\n\n""" + changelog,
)

replace_once(
    "README.md",
    "| Current `v2` source | `2.0.0-alpha.3-dev.15` / `1016226` | Private defaults/menu corrective test build; device verification required |",
    "| Current `v2` source | `2.0.0-alpha.3-dev.16` / `1016227` | Private Magisk-staging/debug-collector corrective test build; device verification required |",
    "readme_current",
)
replace_once(
    "README.md",
    "| Previous private build | `2.0.0-alpha.3-dev.14` / `1016225` | EH safety correction installed successfully; superseded by the menu/defaults audit |",
    "| Previous private build | `2.0.0-alpha.3-dev.15` / `1016226` | Mustang install reached validated Thermal output but failed at an unnecessary ZRAM fstab replacement |",
    "readme_previous",
)
replace_once(
    "release-notes/README.md",
    "## V2 alpha line\n\n",
    "## V2 alpha line\n\n- [2.0.0-alpha.3-dev.16](2.0.0-alpha.3-dev.16.md) — private Magisk staging and packaged-debug correction preserving the dev.15 defaults/menu work.\n",
    "release_index",
)
write(
    "release-notes/2.0.0-alpha.3-dev.16.md",
    """# 2.0.0 Alpha 3 Dev 16\n\nPrivate corrective test build; no tag, public release asset, or update-channel change.\n\n## Live failure input\n\nThe exact dev.15 package reached successful Mustang Thermal validation with Polling Mod, Outdoor Extended, ZRAM 100 percent, adaptive Emerald Hill, pTune override off and verbose logging. Installation then stopped while replacing an already identical `fstab.zram.100p` inside the Magisk staging tree.\n\nThe automatic packaged-debug archive was created, but its module-view copy loop compounded destination paths because shell helper variables overwrote the outer destination variable.\n\n## Corrections\n\n- Keeps the intended dev.15 Fresh defaults and all menu-route coverage.\n- Detects an already identical packaged ZRAM layout and keeps it without a replacement operation.\n- Verifies temporary and final layout content before any changed layout is committed.\n- Removes a differing destination before the final move, avoiding replacement semantics rejected by the observed staging environment.\n- Stores and prints the exact ZRAM materializer result when installation fails.\n- Uses collision-free packaged-debug helper variable names.\n- Adds regression coverage for identical, differing and absent staged layouts plus the collector-variable failure.\n\nFresh Mustang installation and post-reboot verification remain mandatory before any release decision.\n""",
)

print("RESULT: PIXEL_THERMAL_DEV16_MIGRATION_DONE")
