#!/usr/bin/env python3
from pathlib import Path
import re

README = Path('README.md')
CHANGELOG = Path('CHANGELOG.md')

published_sha = '0544da1363bcde62f087e14744dbcdf9da159c8d50204d2ebe605371077034ea'
published_size = '335993'

s = README.read_text(encoding='utf-8')
old_links = '[Latest stable](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.0.1) · [Latest prerelease](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.0.0-alpha.3-dev.21)'
new_links = '[Latest stable](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.0.2) · [Latest prerelease](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.1.0-alpha.2)'
if s.count(old_links) != 1:
    raise SystemExit('README top release links did not match exactly once')
s = s.replace(old_links, new_links)

important = '''> [!IMPORTANT]\n> **2.0.2 is the current stable release.** It fixes the real August multiline `HotThreshold` materialization failure reproduced from the XDA `mustang / CP2A.260805.005` debug package. The Stable regression now covers Stock, Outdoor Safe, Outdoor Plus and Outdoor Extended while preserving exact-delta validation, fail-closed rollback and the existing 2.0.1 runtime baseline. Pixel 9-series and Pixel 10a remain on the separate 2.1 prerelease line.\n\n## Current release'''
s, n = re.subn(r'> \[!IMPORTANT\]\n> \*\*2\.0\.1 is the current stable release\.\*\*.*?\n\n## Current release', important, s, count=1, flags=re.S)
if n != 1:
    raise SystemExit('README IMPORTANT block did not match exactly once')

table = f'''| Version | `2.0.2` |\n| Version code | `1016242` |\n| Release type | Stable Dynamic V2 multiline materializer hotfix |\n| Tag | `v2.0.2` |\n| Asset | `pixel-10-thermal-memory-control-2.0.2.zip` |\n| Asset size | `{published_size}` bytes |\n| SHA-256 | `{published_sha}` |\n| Regression proof | `mustang / CP2A.260805.005 / Android 17` August multiline fixture, 12 zones / 84 values, all four profiles |'''
s, n = re.subn(r'\| Version \| `2\.0\.1` \|\n\| Version code \| `1016241` \|\n\| Release type \|.*?\n\| Tag \| `v2\.0\.1` \|\n\| Asset \| `pixel-10-thermal-memory-control-2\.0\.1\.zip` \|\n\| Asset size \| `330935` bytes \|\n\| SHA-256 \| `6517cd106acd063e52596d4fc0f2e561cd019cdaa3712e930fcddaf746d4dbaa` \|\n\| Device proof \|.*?\|', table, s, count=1)
if n != 1:
    raise SystemExit('README release table did not match exactly once')

paragraph = '''2.0.2 keeps the complete 2.0.1 Stable Dynamic V2 feature set and closes the remaining August-format gap: both the materializer and the allowed-diff normalizer now handle multiline `HotThreshold` arrays. The XDA failure on `mustang / CP2A.260805.005` was reproduced as a fail-closed `rc=63` and the corrected Stable path now validates all four Thermal profiles, including Outdoor Extended at 12 target zones / 84 threshold values. The published 2.0.2 package retains the independent exact-delta validator, Polling guards, Bootguard recovery and rollback behavior. The earlier 2.0.1 August Stable KernelSU post-reboot proof remains the runtime baseline; 2.0.2 itself is the focused materializer correction.''' 
s, n = re.subn(r'2\.0\.1 keeps the full Dynamic V2 stable feature set.*?the July Stable Magisk regression remained green\.', paragraph, s, count=1, flags=re.S)
if n != 1:
    raise SystemExit('README current release paragraph did not match exactly once')
README.write_text(s, encoding='utf-8')

c = CHANGELOG.read_text(encoding='utf-8')
entry = f'''# 2.0.2\n\nStable Dynamic V2 multiline materializer hotfix. Exact asset: `pixel-10-thermal-memory-control-2.0.2.zip`, SHA-256 `{published_sha}`, {published_size} bytes.\n\n- Fixes the fail-closed `rc=63` reproduced from the XDA `mustang / CP2A.260805.005` install-failure package when the preserved Outdoor profile selected the August multiline `HotThreshold` path.\n- Completes multiline-aware threshold handling in the Stable materializer and in its allowed-diff normalizer; 2.0.1 had already made the independent delta validator multiline-aware.\n- Adds an August-shape regression across Stock, Outdoor Safe, Outdoor Plus and Outdoor Extended, including 12 target zones / 12 arrays / 84 controlled threshold values for the Outdoor path.\n- Keeps controlled Polling replacement, exact per-value delta validation, sentinel preservation, fail-closed rollback, Bootguard and the full 2.0.1 feature set unchanged.\n- This is not a KernelSU migration issue and is not specific to upgrading from 1.5.1; the previous module was correctly preserved when 2.0.1 failed closed.\n- Pixel 9-series and Pixel 10a remain on the separate 2.1 prerelease line.\n\n'''
if c.startswith('# 2.0.2\n'):
    raise SystemExit('CHANGELOG already contains 2.0.2 at top')
CHANGELOG.write_text(entry + c, encoding='utf-8')
