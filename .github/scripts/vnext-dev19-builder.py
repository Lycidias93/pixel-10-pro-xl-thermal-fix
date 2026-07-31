#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import re
import shutil
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BRANCH = "repo-maintenance/vnext-dev19-lmkd-v2-cleanup-20260731"


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, content: str) -> None:
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")


def replace_once(path: str, old: str, new: str) -> None:
    content = read(path)
    count = content.count(old)
    if count != 1:
        raise SystemExit(f"replace_once failed path={path} count={count} needle={old[:120]!r}")
    write(path, content.replace(old, new, 1))


def regex_once(path: str, pattern: str, replacement: str) -> None:
    content = read(path)
    updated, count = re.subn(pattern, replacement, content, count=1, flags=re.S)
    if count != 1:
        raise SystemExit(f"regex_once failed path={path} count={count} pattern={pattern!r}")
    write(path, updated)


def prepend_once(path: str, marker: str, block: str) -> None:
    content = read(path)
    if marker in content:
        return
    write(path, block + content)


def update_version_assertions(path: str) -> None:
    content = read(path)
    content = content.replace("version=2.0.0-alpha.3-dev.18", "version=2.0.0-alpha.3-dev.19")
    content = content.replace("versionCode=1016229", "versionCode=1016230")
    content = content.replace("dev18_metadata_preserves_dev16_regression", "dev19_metadata_preserves_dev16_regression")
    content = content.replace("dev18_metadata_preserves_dev17_contract", "dev19_metadata_preserves_dev17_contract")
    content = content.replace("pass dev18_metadata", "pass dev19_metadata")
    write(path, content)


def apply_source_changes() -> None:
    module_prop = read("module.prop")
    if "version=2.0.0-alpha.3-dev.19" in module_prop:
        print("RESULT: VNEXT_DEV19_BUILDER_ALREADY_APPLIED")
        return

    replace_once(
        "module.prop",
        "version=2.0.0-alpha.3-dev.18\nversionCode=1016229\n",
        "version=2.0.0-alpha.3-dev.19\nversionCode=1016230\n",
    )
    replace_once(
        "module.prop",
        "description=V2 Alpha 3 dev.18 source: clearer experimental Emerald Hill max-lock UX, persistent bounded EH event evidence, and V2-to-main promotion readiness.\n",
        "description=V2 Alpha 3 dev.19 source: guarded early-LMKD A/B testing, Dynamic V2-first documentation, and removal of static V1 profile payloads.\n",
    )

    readme = r'''# Pixel 10 Thermal & Memory Control

**Dynamic V2 Magisk module for guarded Pixel 10 Thermal profiles, local stock-derived validation, Bootguard, Action settings, optional ZRAM 100p, and controlled experimental memory tests.**

[Releases](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases) · [Telegram](https://t.me/lycidias93) · [Issues](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/issues) · [Release notes](release-notes/README.md) · [Changelog](CHANGELOG.md) · [Credits](CREDITS.md)

## Current project state

Dynamic V2 is the active source architecture on `main`.

| Lane | Version | State |
|---|---|---|
| Current source | `2.0.0-alpha.3-dev.19` / `1016230` | Unreleased vNext source with guarded LMKD early-boot test |
| Public Alpha | `2.0.0-alpha.3-dev.17` / `1016228` | Latest published and Mustang-verified prerelease |
| Stable update channel | `1.5.1-universal.1` / `1016108` | Legacy public stable package; unchanged |

Source development does not publish a tag, release asset, or update-channel change. `update.json` and `update-prerelease.json` remain separate publication gates.

## Dynamic V2 architecture

V2 does not depend on a repository snapshot for every monthly firmware. It:

1. admits only supported Pixel 10 platform codenames and Android major versions;
2. reads the device's own three stock Thermal configuration files;
3. validates structure and controlled targets locally;
4. creates a constrained overlay that changes only admitted Polling and Outdoor values;
5. verifies manifests, exact deltas, mounted files, active Polling values, and Bootguard state.

Controlled files:

- `thermal_info_config.json`
- `thermal_info_config_charge.json`
- `thermal_info_config_throttling.json`

The module does not replace the stock Thermal HAL and does not disable Android Thermal safety.

## Thermal profiles

| Profile | Controlled Outdoor delta |
|---|---:|
| Stock | `+0 °C` |
| Outdoor Safe | `+1 °C` |
| Outdoor Plus | `+2 °C` |
| Outdoor Extended | `+3 °C` |

Polling Mod changes only admitted `PollingDelay: 300000` values to `5000`. Stock passive-delay behavior while throttling remains untouched.

## ZRAM and Emerald Hill

ZRAM 100p is optional and requires explicit selection. The daily V2 path uses:

- ZRAM near total RAM size;
- `lz77eh` compression when exposed by the platform;
- `vm.swappiness=100`;
- adaptive Emerald Hill devfreq behavior.

The optional Emerald Hill maximum-frequency minimum lock is separate, experimental, and can increase heat and battery use. Apply and restore events are recorded with boot ID, caller, physical node, original minimum, target, readback, and alias count. No permanent screen-on or periodic reapply watcher is used.

## vNext LMKD early-boot test

Dev.19 adds a controlled A/B test for Harish / Codecity001's proposal to expose:

```text
ro.lmk.swap_free_low_percentage=1
```

before LMKD starts.

Safety contract:

- disabled by default;
- requires ZRAM 100p and an explicit experimental acknowledgement;
- applies only from `post-fs-data.sh`;
- refuses a late write when `lmkd` is already running;
- records property value before and after, LMKD PID timing, boot ID, uptime, and readback;
- performs a post-boot verification snapshot with LMKD service state, memory, swap, PSI, and boot-ID continuity;
- labels the result `indirect_timing_only` and never claims direct proof that LMKD consumed the property.

Changing the test in Magisk Action requires a reboot. Disabling it returns the next boot to stock LMKD policy.

## Installation

Requirements:

- supported Pixel 10-series platform;
- supported Android major version;
- Magisk or a compatible tested module backend;
- working module-disable or recovery path;
- at least 15 percent battery.

The single install flow controls:

- Polling Mode;
- Thermal Profile;
- ZRAM 100p;
- Emerald Hill mode;
- experimental LMKD early test;
- pTune override;
- debug logging.

After installation, reboot and run:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/bootguard/compat-check.sh
```

Healthy runtime markers include:

```text
DYNAMIC_MATERIALIZATION_VALID=yes
MODULE_OVERLAY_READY=yes
ACTIVE_VENDOR_MATCH=yes
ACTIVE_POLLING_VALID=yes
SAFE_TO_REBOOT=yes
```

## Magisk Action

Action provides:

- current Polling, Thermal, ZRAM, EH, and LMKD-test status;
- guarded settings changes;
- EH event evidence;
- LMKD early/post-boot evidence;
- debug ZIP creation;
- Bootguard and pTune status;
- update-channel selection.

## Debug evidence

Create a packaged debug archive:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/bootguard/collect-debug.sh
```

The collector includes current configuration, validation state, install-state, active overlays, Bootguard, ZRAM, EH, LMKD-test snapshots, pTune state, and relevant current/previous-boot diagnostics. Review archives before public upload.

## Bootguard and rollback

Normal rollback:

1. Disable or remove the module in Magisk.
2. Reboot.

Emergency disable:

```sh
su -c 'touch /data/adb/modules/pixel-10-pro-xl-thermal-fix/disable'
su -c reboot
```

Mount-only emergency bypass:

```sh
su -c 'touch /data/adb/modules/pixel-10-pro-xl-thermal-fix/skip_mount'
su -c reboot
```

## V1 end of life

The static V1 profile model is EOL. Static profile payloads are removed from the current source tree because Dynamic V2 no longer consumes them. Historical V1 packages, tags, release assets, and Git history remain the rollback and research archive.

See [V1 EOL](docs/V1_EOL.md).

## Branch model

- `main`: canonical Dynamic V2 source;
- `v2`: retained protected rollback/reference branch;
- short-lived `repo-maintenance/*` branches: deleted after verified merge;
- obsolete V1, prerelease, release-work, and experimental branches: removed once verified as superseded and free of open PRs.

## Evidence boundaries

A repository test does not replace device proof. A PASS on Mustang does not automatically prove Blazer, Frankel, or Rango. New build, codename, pTune, LMKD, and high-risk EH claims require fresh on-device evidence.

## Documentation

- [V2 Alpha validation plan](docs/v2-alpha-validation-plan.md)
- [Release notes](release-notes/README.md)
- [Changelog](CHANGELOG.md)
- [Credits](CREDITS.md)

## Credits

Created by **Lycidias93**, based on earlier work by **marx161**. V2 engineering and testing includes contributions and feedback from **Harish / Codecity001**, **Allen Chang**, **JoshuaDoes**, and existing project contributors.

## License

See [LICENSE](LICENSE).
'''
    write("README.md", readme)

    changelog = r'''# 2.0.0-alpha.3-dev.19

Unreleased Dynamic V2 vNext source; no tag, release asset, or update-channel change.

- Adds an opt-in early `ro.lmk.swap_free_low_percentage=1` A/B test in `post-fs-data`.
- Requires ZRAM 100p plus an explicit LMKD experimental acknowledgement.
- Refuses late mutation when LMKD is already running.
- Records early timing/readback evidence and a post-boot memory, swap, PSI, service, and boot-ID snapshot.
- Explicitly labels LMKD evidence as indirect timing proof, not direct consumption proof.
- Adds installer, Action, status, install-state, and packaged-debug observability for the test.
- Rewrites the README around Dynamic V2 as the active architecture.
- Removes static V1 profile payloads from the current tree while retaining tags, releases, and Git history.
- Audits and removes obsolete branches, retaining only `main` and `v2` as long-lived branches.

'''
    prepend_once("CHANGELOG.md", "# 2.0.0-alpha.3-dev.19", changelog)

    write(
        "release-notes/2.0.0-alpha.3-dev.19.md",
        r'''# 2.0.0-alpha.3-dev.19

Unreleased Dynamic V2 vNext source. This file does not authorize a tag, release, asset, or update-channel change.

## LMKD early-boot A/B test

- Default: disabled.
- Prerequisite: ZRAM 100p enabled.
- Risk acknowledgement: `explicit_user_test`.
- Apply stage: `post-fs-data` only.
- Requested value: `ro.lmk.swap_free_low_percentage=1`.
- Late-write policy: refuse if `lmkd` already has a PID.
- Early evidence: boot ID, epoch, uptime, property before/after, LMKD PID before, timing state, and resetprop readback.
- Post-boot evidence: boot-ID continuity, LMKD PID/service state, property value, memory totals, swap totals, and memory PSI.
- Claim boundary: `indirect_timing_only`; direct LMKD consumption is not claimed.

## V2 documentation and V1 retirement

- README now describes Dynamic V2 as the active source architecture.
- Static V1 profile payloads are removed from the current tree.
- Historical tags, releases, assets, and Git history remain available.
- `main` remains canonical and `v2` remains the protected rollback/reference branch.

## Branch cleanup

Obsolete branches were compared against `main`, checked for open PRs, and scheduled for deletion under the user-approved cleanup. Exact results are recorded in `docs/branch-cleanup-20260731.md`.
''',
    )

    notes_index = read("release-notes/README.md")
    if "2.0.0-alpha.3-dev.19" not in notes_index:
        notes_index = notes_index.replace(
            "## V2 alpha line\n\n",
            "## V2 alpha line\n\n- [2.0.0-alpha.3-dev.19](2.0.0-alpha.3-dev.19.md) — unreleased guarded LMKD early-test and V2 cleanup source.\n",
            1,
        )
        write("release-notes/README.md", notes_index)

    write(
        "docs/V1_EOL.md",
        r'''# V1 static profile line — end of life

Dynamic V2 is the active source architecture.

## Current-tree policy

Static profile payloads have been removed from the current `main` tree because V2 does not consume them for admission, materialization, validation, or packaging.

The removal does not delete history:

- V1 tags remain available;
- published V1 release assets remain available;
- Git history retains the former profile snapshots;
- the stable update channel remains on its published package until a separate explicit release decision.

## Active model

Dynamic V2 reads the device's own three controlled stock Thermal files, validates their structure, creates a constrained local overlay, and verifies the active runtime result.

## Rollback

Source-tree cleanup does not remove historical packages. Reverting the V2 source promotion or installing a historical release remains possible through normal Git and release history.
''',
    )

    old_profiles = ROOT / "deprecated/profiles"
    if old_profiles.exists():
        shutil.rmtree(old_profiles)

    write(
        "docs/branch-cleanup-20260731.md",
        r'''# Branch cleanup — 2026-07-31

Long-lived branches retained:

- `main` — canonical Dynamic V2 source;
- `v2` — protected rollback/reference branch.

The repository had no open pull requests before cleanup.

Branches approved for deletion after comparison with `main`:

| Branch | Comparison | Reason |
|---|---:|---|
| `Profiles_work` | ahead 0, behind 425 | fully contained and obsolete V1 profile work |
| `prerelease/v1413-test8-cp31-outdoor-safe-20260626-071606` | ahead 1, behind 514 | static V1 prerelease experiment superseded by Dynamic V2 and historical release records |
| `release/v1.5.2-universal-v2-alpha.1` | ahead 0, behind 368 | fully contained release branch |
| `repo-maintenance/release-v2-alpha3-dev6-user-go-20260727` | ahead 32, behind 184 | obsolete one-shot dev.6 release tooling; published history exists |
| `repo-maintenance/release-v2-alpha3-dev8-user-go-20260728` | ahead 16, behind 149 | obsolete one-shot dev.8 release tooling; published history exists |
| `repo-maintenance/v2-outdoor-runtime-evidence-guard-dev4-20260726` | ahead 1, behind 230 | old documentation branch superseded by current validation docs |
| `repo-maintenance/v2-zram-eh-dev12-20260730` | ahead 15, behind 123 | old EH implementation superseded by dev.18/dev.19 |
| `v2-perf` | ahead 5, behind 123 | old performance experiment superseded by current Action/runtime code |
| `v2-v` | ahead 1, behind 242 | old Canary patch experiment superseded by current Dynamic V2 validation model |

Deletion is fail-closed when a branch has an open PR, is `main`/`v2`, or the API does not confirm the exact ref.
''',
    )

    write(
        "tools/lmkd/early-swap-low-test.sh",
        r'''#!/system/bin/sh
set -eu

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-/data/adb/modules/$ID}"
CONFIG_FILE="${LMKD_CONFIG_FILE:-/data/adb/$ID/config.env}"
STATE_DIR="${LMKD_TEST_STATE_DIR:-/data/adb/$ID/lmkd-test}"
STATE_FILE="$STATE_DIR/early-swap-low.env"
EVENT_LOG="$STATE_DIR/events.log"
RESET="${LMKD_RESET_BIN:-$MODDIR/tools/resetprop-rs}"
GETPROP="${LMKD_GETPROP_BIN:-getprop}"
PIDOF="${LMKD_PIDOF_BIN:-pidof}"
BOOT_ID_FILE="${LMKD_BOOT_ID_FILE:-/proc/sys/kernel/random/boot_id}"
UPTIME_FILE="${LMKD_UPTIME_FILE:-/proc/uptime}"
MODE="${1:-apply}"

cfg_get() {
  key="$1"
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^${key}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${key}=//" | tr -d '\r'
}

prop_get() {
  "$GETPROP" "$1" 2>/dev/null || true
}

lmkd_pid() {
  "$PIDOF" lmkd 2>/dev/null | awk '{print $1}' || true
}

uptime_ms() {
  awk '{printf "%d\n", $1 * 1000}' "$UPTIME_FILE" 2>/dev/null || printf '%s\n' 0
}

write_state() {
  apply_state="$1"
  timing_state="$2"
  before="$3"
  after="$4"
  pid_before="$5"
  detail="$6"
  mkdir -p "$STATE_DIR" 2>/dev/null || true
  chmod 0700 "$STATE_DIR" 2>/dev/null || true
  tmp="$STATE_FILE.tmp.$$"
  {
    printf '%s\n' 'schema=pixel-thermal-lmkd-early-test-v1'
    printf '%s\n' "boot_id=$(cat "$BOOT_ID_FILE" 2>/dev/null || printf unknown)"
    printf '%s\n' "epoch=$(date +%s 2>/dev/null || printf unknown)"
    printf '%s\n' "uptime_ms=$(uptime_ms)"
    printf '%s\n' "mode=$MODE"
    printf '%s\n' "requested_property=ro.lmk.swap_free_low_percentage"
    printf '%s\n' 'requested_value=1'
    printf '%s\n' "config_enabled=${enabled:-0}"
    printf '%s\n' "risk_ack=${ack:-none}"
    printf '%s\n' "zram_enabled=${zram_enabled:-0}"
    printf '%s\n' "property_before=${before:-unset}"
    printf '%s\n' "property_after=${after:-unset}"
    printf '%s\n' "lmkd_pid_before=${pid_before:-none}"
    printf '%s\n' "apply_state=$apply_state"
    printf '%s\n' "timing_state=$timing_state"
    printf '%s\n' 'consumption_proof=not_claimed'
    printf '%s\n' "detail=$detail"
  } > "$tmp"
  chmod 0600 "$tmp" 2>/dev/null || true
  mv "$tmp" "$STATE_FILE"
  printf '%s\n' "epoch=$(date +%s 2>/dev/null || printf unknown) boot_id=$(cat "$BOOT_ID_FILE" 2>/dev/null || printf unknown) apply_state=$apply_state timing_state=$timing_state property_before=${before:-unset} property_after=${after:-unset} lmkd_pid_before=${pid_before:-none} detail=$detail" >> "$EVENT_LOG" 2>/dev/null || true
  chmod 0600 "$EVENT_LOG" 2>/dev/null || true
  if [ -r "$EVENT_LOG" ] && [ "$(wc -l < "$EVENT_LOG" 2>/dev/null | tr -d ' ')" -gt 64 ] 2>/dev/null; then
    tail -n 64 "$EVENT_LOG" > "$EVENT_LOG.tmp.$$" 2>/dev/null || true
    chmod 0600 "$EVENT_LOG.tmp.$$" 2>/dev/null || true
    mv "$EVENT_LOG.tmp.$$" "$EVENT_LOG" 2>/dev/null || true
  fi
}

enabled="$(cfg_get LMKD_EARLY_SWAP_LOW_TEST)"
ack="$(cfg_get LMKD_EARLY_SWAP_LOW_RISK_ACK)"
zram_enabled="$(cfg_get ENABLE_ZRAM_100P)"
[ -n "$enabled" ] || enabled=0
[ -n "$ack" ] || ack=none
[ -n "$zram_enabled" ] || zram_enabled=0
before="$(prop_get ro.lmk.swap_free_low_percentage)"
pid_before="$(lmkd_pid)"

if [ "$enabled" != 1 ]; then
  write_state disabled stock_default "$before" "$before" "$pid_before" config_disabled
  printf '%s\n' 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_SKIPPED reason=disabled'
  exit 0
fi

if [ "$ack" != explicit_user_test ]; then
  write_state refused missing_ack "$before" "$before" "$pid_before" explicit_ack_required
  printf '%s\n' 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_REFUSED reason=explicit_ack_required'
  exit 0
fi

if [ "$zram_enabled" != 1 ]; then
  write_state refused zram_disabled "$before" "$before" "$pid_before" zram_100p_required
  printf '%s\n' 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_REFUSED reason=zram_100p_required'
  exit 0
fi

if [ -n "$pid_before" ]; then
  write_state late_refused lmkd_already_running "$before" "$before" "$pid_before" late_mutation_not_allowed
  printf '%s\n' "RESULT: LMKD_EARLY_SWAP_LOW_TEST_REFUSED reason=lmkd_already_running pid=$pid_before"
  exit 0
fi

if [ ! -x "$RESET" ]; then
  write_state failed before_lmkd "$before" "$before" none resetprop_missing
  printf '%s\n' "RESULT: LMKD_EARLY_SWAP_LOW_TEST_FAIL reason=resetprop_missing path=$RESET"
  exit 2
fi

if ! "$RESET" -n ro.lmk.swap_free_low_percentage 1; then
  after="$(prop_get ro.lmk.swap_free_low_percentage)"
  write_state failed before_lmkd "$before" "$after" none resetprop_failed
  printf '%s\n' 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_FAIL reason=resetprop_failed'
  exit 3
fi

after="$(prop_get ro.lmk.swap_free_low_percentage)"
if [ "$after" != 1 ]; then
  write_state failed before_lmkd "$before" "$after" none readback_mismatch
  printf '%s\n' "RESULT: LMKD_EARLY_SWAP_LOW_TEST_FAIL reason=readback_mismatch actual=${after:-unset}"
  exit 4
fi

write_state applied_before_lmkd before_lmkd "$before" "$after" none indirect_timing_only
printf '%s\n' 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_APPLY_PASS timing=before_lmkd readback=1 evidence=indirect_timing_only'
exit 0
''',
    )

    write(
        "tools/lmkd/verify-early-swap-low-test.sh",
        r'''#!/system/bin/sh
set -eu

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
CONFIG_FILE="${LMKD_CONFIG_FILE:-/data/adb/$ID/config.env}"
STATE_DIR="${LMKD_TEST_STATE_DIR:-/data/adb/$ID/lmkd-test}"
EARLY="$STATE_DIR/early-swap-low.env"
POST="$STATE_DIR/postboot.env"
GETPROP="${LMKD_GETPROP_BIN:-getprop}"
PIDOF="${LMKD_PIDOF_BIN:-pidof}"
BOOT_ID_FILE="${LMKD_BOOT_ID_FILE:-/proc/sys/kernel/random/boot_id}"
MEMINFO_FILE="${LMKD_MEMINFO_FILE:-/proc/meminfo}"
PSI_FILE="${LMKD_PSI_FILE:-/proc/pressure/memory}"

kv_get() {
  key="$1"
  file="$2"
  [ -r "$file" ] || return 0
  grep -E "^${key}=" "$file" 2>/dev/null | tail -n 1 | sed "s/^${key}=//" | tr -d '\r'
}

cfg_get() {
  kv_get "$1" "$CONFIG_FILE"
}

prop_get() {
  "$GETPROP" "$1" 2>/dev/null || true
}

pid_now() {
  "$PIDOF" lmkd 2>/dev/null | awk '{print $1}' || true
}

mem_kb() {
  awk -v key="$1" '$1 == key":" {print $2; exit}' "$MEMINFO_FILE" 2>/dev/null || true
}

enabled="$(cfg_get LMKD_EARLY_SWAP_LOW_TEST)"
ack="$(cfg_get LMKD_EARLY_SWAP_LOW_RISK_ACK)"
[ -n "$enabled" ] || enabled=0
[ -n "$ack" ] || ack=none
mkdir -p "$STATE_DIR" 2>/dev/null || true
chmod 0700 "$STATE_DIR" 2>/dev/null || true

current_boot="$(cat "$BOOT_ID_FILE" 2>/dev/null || printf unknown)"
early_boot="$(kv_get boot_id "$EARLY")"
apply_state="$(kv_get apply_state "$EARLY")"
timing_state="$(kv_get timing_state "$EARLY")"
early_after="$(kv_get property_after "$EARLY")"
current_prop="$(prop_get ro.lmk.swap_free_low_percentage)"
lmkd_pid="$(pid_now)"
lmkd_service="$(prop_get init.svc.lmkd)"
[ -n "$lmkd_service" ] || lmkd_service=unknown

ready=no
reason=disabled
if [ "$enabled" = 1 ] && [ "$ack" = explicit_user_test ]; then
  reason=evidence_incomplete
  if [ "$apply_state" = applied_before_lmkd ] &&
     [ "$timing_state" = before_lmkd ] &&
     [ "$early_after" = 1 ] &&
     [ "$current_prop" = 1 ] &&
     [ "$early_boot" = "$current_boot" ] &&
     [ -n "$lmkd_pid" ]; then
    ready=yes
    reason=early_timing_and_postboot_readback_verified
  fi
fi

psi_some="$(grep '^some ' "$PSI_FILE" 2>/dev/null | head -n 1 || true)"
psi_full="$(grep '^full ' "$PSI_FILE" 2>/dev/null | head -n 1 || true)"
tmp="$POST.tmp.$$"
{
  printf '%s\n' 'schema=pixel-thermal-lmkd-postboot-test-v1'
  printf '%s\n' "boot_id=$current_boot"
  printf '%s\n' "early_boot_id=${early_boot:-missing}"
  printf '%s\n' "boot_id_match=$([ "$early_boot" = "$current_boot" ] && printf yes || printf no)"
  printf '%s\n' "config_enabled=$enabled"
  printf '%s\n' "risk_ack=$ack"
  printf '%s\n' "early_apply_state=${apply_state:-missing}"
  printf '%s\n' "early_timing_state=${timing_state:-missing}"
  printf '%s\n' "early_property_after=${early_after:-unset}"
  printf '%s\n' "current_property=${current_prop:-unset}"
  printf '%s\n' "lmkd_pid=${lmkd_pid:-none}"
  printf '%s\n' "lmkd_service=$lmkd_service"
  printf '%s\n' "mem_total_kb=$(mem_kb MemTotal)"
  printf '%s\n' "mem_available_kb=$(mem_kb MemAvailable)"
  printf '%s\n' "swap_total_kb=$(mem_kb SwapTotal)"
  printf '%s\n' "swap_free_kb=$(mem_kb SwapFree)"
  printf '%s\n' "psi_some=${psi_some:-unavailable}"
  printf '%s\n' "psi_full=${psi_full:-unavailable}"
  printf '%s\n' "test_ready=$ready"
  printf '%s\n' "reason=$reason"
  printf '%s\n' 'consumption_proof=indirect_timing_only'
  printf '%s\n' 'direct_lmkd_consumption_claim=no'
} > "$tmp"
chmod 0600 "$tmp" 2>/dev/null || true
mv "$tmp" "$POST"

if [ "$enabled" != 1 ]; then
  printf '%s\n' 'RESULT: LMKD_EARLY_SWAP_LOW_POSTBOOT_VERIFY_DONE outcome=success state=disabled'
  exit 0
fi
if [ "$ready" = yes ]; then
  printf '%s\n' 'RESULT: LMKD_EARLY_SWAP_LOW_POSTBOOT_VERIFY_DONE outcome=success evidence=indirect_timing_only'
  exit 0
fi
printf '%s\n' "RESULT: LMKD_EARLY_SWAP_LOW_POSTBOOT_VERIFY_DONE outcome=warning reason=$reason evidence=indirect_timing_only"
exit 1
''',
    )

    replace_once(
        "post-fs-data.sh",
        'AUTO_SWITCH="$MODDIR/tools/core/auto-profile-switch.sh"\n',
        'AUTO_SWITCH="$MODDIR/tools/core/auto-profile-switch.sh"\nLMKD_EARLY="$MODDIR/tools/lmkd/early-swap-low-test.sh"\n',
    )
    replace_once(
        "post-fs-data.sh",
        '[ -e "$MODDIR/disable" ] && { log "GUARD_BLOCK reason=bootguard_or_user_disable action=no_mount"; exit 0; }\n\n# post-fs-data runs before Magisk module mounts.',
        '[ -e "$MODDIR/disable" ] && { log "GUARD_BLOCK reason=bootguard_or_user_disable action=no_mount"; exit 0; }\n\n# The LMKD experiment is fail-closed, opt-in, and early-only. It never blocks\n# Thermal mounting or Bootguard when its evidence helper fails.\nif [ -r "$LMKD_EARLY" ]; then\n  MODDIR="$MODDIR" LMKD_CONFIG_FILE="$CFG" sh "$LMKD_EARLY" apply >> "$L" 2>&1 ||\n    log "LMKD_EARLY_TEST_WARN reason=helper_nonzero action=continue_stock_or_recorded_state"\nelse\n  log "LMKD_EARLY_TEST_WARN reason=helper_missing action=continue_stock"\nfi\n\n# post-fs-data runs before Magisk module mounts.',
    )

    replace_once(
        "service.sh",
        'EH_CONTROL="$MODDIR/tools/zram/emerald-hill-control.sh"\n',
        'EH_CONTROL="$MODDIR/tools/zram/emerald-hill-control.sh"\nLMKD_VERIFY="$MODDIR/tools/lmkd/verify-early-swap-low-test.sh"\n',
    )
    replace_once(
        "service.sh",
        "printf '%s\\n' 'lmk_swap_low_policy=stock_unmodified' >> \"$H\"\n",
        "printf '%s\\n' 'lmk_swap_low_policy=resolved_after_config' >> \"$H\"\n",
    )
    replace_once(
        "service.sh",
        'if [ -f "$CONFIG_FILE" ]; then\n  . "$CONFIG_FILE" 2>/dev/null || true\nfi\n\n# Standard lz77eh ZRAM properties may be prepared early.',
        'if [ -f "$CONFIG_FILE" ]; then\n  . "$CONFIG_FILE" 2>/dev/null || true\nfi\nif [ "${LMKD_EARLY_SWAP_LOW_TEST:-0}" = 1 ] && [ "${LMKD_EARLY_SWAP_LOW_RISK_ACK:-}" = explicit_user_test ]; then\n  printf "%s\\n" "lmk_swap_low_policy=experimental_early_post_fs_data_test" >> "$H"\nelse\n  printf "%s\\n" "lmk_swap_low_policy=stock_unmodified" >> "$H"\nfi\n\n# Standard lz77eh ZRAM properties may be prepared early.',
    )
    replace_once(
        "service.sh",
        "fi\n\n# Android may rewrite selected ZRAM properties after early service startup.",
        "fi\n\nif [ -r \"$LMKD_VERIFY\" ]; then\n  MODDIR=\"$MODDIR\" LMKD_CONFIG_FILE=\"$CONFIG_FILE\" sh \"$LMKD_VERIFY\" >> \"$H\" 2>&1 ||\n    printf '%s\\n' 'SERVICE_LMKD_TEST result=postboot_evidence_warning_nonfatal' >> \"$H\"\nfi\n\n# Android may rewrite selected ZRAM properties after early service startup.",
    )
    replace_once(
        "service.sh",
        "# Reapply exactly once after verified boot. LMKD remains stock and this mode\n# never restarts mmd.\n",
        "# Reapply exactly once after verified boot. This path never mutates the LMKD\n# property; the optional experiment is restricted to post-fs-data.\n",
    )
    replace_once(
        "service.sh",
        "printf '%s\\n' 'SERVICE_ZRAM_POST_BOOT result=zram_properties_reapplied_no_mmd_restart lmk_policy=stock_unmodified' >> \"$H\"",
        "printf '%s\\n' \"SERVICE_ZRAM_POST_BOOT result=zram_properties_reapplied_no_mmd_restart lmk_policy=${LMKD_EARLY_SWAP_LOW_TEST:-0}\" >> \"$H\"",
    )

    replace_once(
        "tools/zram/apply-zram-100p.sh",
        '# Runtime-only ZRAM properties. LMKD policy remains owned by the platform because\n# a late ro.lmk override is not proven to be consumed without an explicit LMKD\n# property reload.\n',
        '# Runtime-only ZRAM properties. This helper never writes the LMKD property.\n# The optional experiment is restricted to post-fs-data and records separate evidence.\n',
    )
    replace_once(
        "tools/zram/apply-zram-100p.sh",
        'lmk_swap_low_actual="$(getprop ro.lmk.swap_free_low_percentage 2>/dev/null || true)"\nlog "ZRAM_LMK_SWAP_LOW policy=stock_unmodified actual=${lmk_swap_low_actual:-unset}"\n',
        'lmk_swap_low_actual="$(getprop ro.lmk.swap_free_low_percentage 2>/dev/null || true)"\nlmk_swap_low_policy=stock_unmodified\nif [ "${LMKD_EARLY_SWAP_LOW_TEST:-0}" = 1 ] && [ "${LMKD_EARLY_SWAP_LOW_RISK_ACK:-}" = explicit_user_test ]; then\n  lmk_swap_low_policy=experimental_early_post_fs_data_test\nfi\nlog "ZRAM_LMK_SWAP_LOW policy=$lmk_swap_low_policy actual=${lmk_swap_low_actual:-unset} late_write=absent"\n',
    )
    replace_once(
        "tools/zram/apply-zram-100p.sh",
        'lmk_swap_low_policy=stock_unmodified lmk_swap_low_actual=${lmk_swap_low_actual:-unset}',
        'lmk_swap_low_policy=$lmk_swap_low_policy lmk_swap_low_actual=${lmk_swap_low_actual:-unset}',
    )

    replace_once(
        "tools/menu/install-options-menu.sh",
        '    LAST_ZRAM_100P \\\n    THERMAL_OUTDOOR_PROFILE',
        '    LAST_ZRAM_100P \\\n    LAST_LMKD_EARLY_SWAP_LOW_TEST \\\n    LMKD_EARLY_SWAP_LOW_TEST \\\n    THERMAL_OUTDOOR_PROFILE',
    )
    replace_once(
        "tools/menu/install-options-menu.sh",
        'record_ptune_presence() {\n',
        r'''apply_lmkd_test() {
  case "$1" in
    1|enabled)
      cfg_set LMKD_EARLY_SWAP_LOW_TEST 1
      cfg_set LMKD_EARLY_SWAP_LOW_RISK_ACK explicit_user_test
      cfg_set LAST_LMKD_EARLY_SWAP_LOW_TEST enabled
    ;;
    *)
      cfg_set LMKD_EARLY_SWAP_LOW_TEST 0
      cfg_set LMKD_EARLY_SWAP_LOW_RISK_ACK none
      cfg_set LAST_LMKD_EARLY_SWAP_LOW_TEST disabled
    ;;
  esac
}

record_ptune_presence() {
''',
    )
    replace_once(
        "tools/menu/install-options-menu.sh",
        '  mc_msg "ZRAM: $(zram_summary_label)"\n  mc_msg "pTune: $(cfg_get PTUNE_OVERRIDE_MENU)"',
        '  mc_msg "ZRAM: $(zram_summary_label)"\n  mc_msg "LMKD early test: $(cfg_get LAST_LMKD_EARLY_SWAP_LOW_TEST)"\n  mc_msg "pTune: $(cfg_get PTUNE_OVERRIDE_MENU)"',
    )
    replace_once(
        "tools/menu/install-options-menu.sh",
        '  apply_zram "$_zram"\n\n  mark_single_pass_complete',
        '  apply_zram "$_zram"\n\n  _lmkd="$(cfg_get LAST_LMKD_EARLY_SWAP_LOW_TEST)"\n  [ -n "$_lmkd" ] || _lmkd=disabled\n  apply_lmkd_test "$_lmkd"\n\n  mark_single_pass_complete',
    )
    replace_once(
        "tools/menu/install-options-menu.sh",
        'current_ptune=0\n',
        'lmkd_index=0\nmc_cycle2 "LMKD early test" "Disabled (stock)" "EXPERIMENTAL 1%" "$lmkd_index"\n[ "$MC_INDEX" = 1 ] && apply_lmkd_test 1 || apply_lmkd_test 0\n\ncurrent_ptune=0\n',
    )

    replace_once(
        "tools/action-dashboard.sh",
        'EH_EVENT_LOG="$CONFIG_DIR/zram-eh/events.log"\n',
        'EH_EVENT_LOG="$CONFIG_DIR/zram-eh/events.log"\nLMKD_EARLY="$MODDIR/tools/lmkd/early-swap-low-test.sh"\nLMKD_EARLY_EVIDENCE="$CONFIG_DIR/lmkd-test/early-swap-low.env"\nLMKD_POST_EVIDENCE="$CONFIG_DIR/lmkd-test/postboot.env"\n',
    )

    ui6 = r'''ui_menu6() {
  _title="$1"; _label0="$2"; _label1="$3"; _label2="$4"; _label3="$5"; _label4="$6"; _label5="$7"; _idx="${8:-0}"; _steps=0
  case "$_idx" in 0|1|2|3|4|5) ;; *) _idx=0 ;; esac
  mc_head "$_title"; mc_msg "1 $_label0"; mc_msg "2 $_label1"; mc_msg "3 $_label2"; mc_msg "4 $_label3"; mc_msg "5 $_label4"; mc_msg "6 $_label5"; mc_foot
  while [ "$_steps" -le 18 ]; do
    _pos=$(( _idx + 1 ))
    case "$_idx" in 0) _label="$_label0" ;; 1) _label="$_label1" ;; 2) _label="$_label2" ;; 3) _label="$_label3" ;; 4) _label="$_label4" ;; *) _label="$_label5" ;; esac
    mc_msg "Current $_pos/6: $_label"
    _key="$(mc_read_key)"
    case "$_key" in
      up) _idx=$(( (_idx + 1) % 6 )); _steps=$(( _steps + 1 )) ;;
      down) UI_INDEX="$_idx"; UI_REASON="volume_down"; UI_STEPS="$_steps"; return 0 ;;
      timeout) UI_INDEX="$_idx"; UI_REASON="timeout"; UI_STEPS="$_steps"; return 0 ;;
    esac
  done
  UI_INDEX="$_idx"; UI_REASON="max_steps"; UI_STEPS="$_steps"; return 0
}'''
    regex_once(
        "tools/action-dashboard.sh",
        r"ui_menu5\(\) \{.*?\n\}\n\nrematerialize_thermal_overlay\(\)",
        lambda_match(ui6, "rematerialize_thermal_overlay()"),
    )

    lmkd_functions = r'''show_lmkd_evidence() {
  msg ""
  msg "LMKD early-test evidence"
  msg "----------------------------------------"
  if [ -r "$LMKD_EARLY_EVIDENCE" ]; then
    cat "$LMKD_EARLY_EVIDENCE" 2>/dev/null || true
  else
    msg "No early evidence recorded yet."
  fi
  if [ -r "$LMKD_POST_EVIDENCE" ]; then
    msg ""
    msg "Post-boot snapshot"
    cat "$LMKD_POST_EVIDENCE" 2>/dev/null || true
  else
    msg "No post-boot snapshot recorded yet."
  fi
  msg "----------------------------------------"
}

set_lmkd_early_test() {
  cur="$(cfg_get LMKD_EARLY_SWAP_LOW_TEST)"
  case "$cur" in 1) idx=1 ;; *) idx=0 ;; esac
  ui_menu3 "LMKD early test" "Disabled (stock)" "EXPERIMENTAL 1%" "Back" "$idx"
  [ "$UI_REASON" = "timeout" ] && return 0
  case "$UI_INDEX" in
    0)
      cfg_set LMKD_EARLY_SWAP_LOW_TEST 0
      cfg_set LMKD_EARLY_SWAP_LOW_RISK_ACK none
      cfg_set LAST_LMKD_EARLY_SWAP_LOW_TEST disabled
      msg "- LMKD early test: disabled"
      msg "- Next boot uses stock policy"
    ;;
    1)
      if [ "$(cfg_get ENABLE_ZRAM_100P)" != 1 ]; then
        msg "! Enable ZRAM 100% before this experiment."
        sleep 2
        return 0
      fi
      cfg_set LMKD_EARLY_SWAP_LOW_TEST 1
      cfg_set LMKD_EARLY_SWAP_LOW_RISK_ACK explicit_user_test
      cfg_set LAST_LMKD_EARLY_SWAP_LOW_TEST enabled
      msg "! EXPERIMENTAL early LMKD property test enabled."
      msg "! Evidence is indirect timing/readback only."
    ;;
    *) msg "Back."; return 0 ;;
  esac
  printf '%s\n' yes > "$MODDIR/guard/action_cycle_pending_reboot" 2>/dev/null || true
  mark_status_dirty
  refresh_status
  show_status
  msg "- Reboot required"
  msg "Back to Advanced."
}
'''
    content = read("tools/action-dashboard.sh")
    if "set_lmkd_early_test()" not in content:
        content = content.replace("advanced_loop() {", lmkd_functions + "\nadvanced_loop() {", 1)
        write("tools/action-dashboard.sh", content)

    advanced = r'''advanced_loop() {
  while :; do
    ui_menu6 "Advanced" "Emerald Hill mode" "LMKD early test" "pTune Status" "pTune Override" "Update Channel" "Back" 0
    [ "$UI_REASON" = "timeout" ] && return 0
    case "$UI_INDEX" in
      0) set_emerald_hill ;;
      1) set_lmkd_early_test ;;
      2) ptune_status; sleep 2 ;;
      3)
        if [ "$(cfg_get ALLOW_THERMAL_WITH_PTUNE)" = 1 ]; then ptune_override_off; else ptune_override_on; fi
        sleep 2
      ;;
      4) update_channel_loop ;;
      *) msg "Back."; return 0 ;;
    esac
  done
}'''
    regex_once(
        "tools/action-dashboard.sh",
        r"advanced_loop\(\) \{.*?\n\}\n\ntoggle_debug_mode\(\)",
        advanced + "\n\ntoggle_debug_mode()",
    )

    debug = r'''debug_loop() {
  while :; do
    ui_menu6 "Debug" "Status" "Collect ZIP" "EH Event Log" "LMKD Evidence" "Debug Logging" "Back" 0
    [ "$UI_REASON" = "timeout" ] && return 0
    case "$UI_INDEX" in
      0) refresh_status; show_status; sleep 2 ;;
      1)
        if [ -s "$MODDIR/tools/bootguard/collect-debug.sh" ]; then
          sh "$MODDIR/tools/bootguard/collect-debug.sh"
        else
          msg "Collector missing"
        fi
        sleep 2
      ;;
      2) show_eh_event_log; sleep 2 ;;
      3) show_lmkd_evidence; sleep 2 ;;
      4) toggle_debug_mode; sleep 1 ;;
      *) msg "Back."; return 0 ;;
    esac
  done
}'''
    regex_once(
        "tools/action-dashboard.sh",
        r"debug_loop\(\) \{.*?\n\}\n\naction_loop\(\)",
        debug + "\n\naction_loop()",
    )

    menu_cycle = read("tools/menu/menu-cycle.sh")
    menu_cycle = menu_cycle.replace(
        '    "Advanced") echo "Emerald Hill, pTune, and update-channel tools." ;;',
        '    "Advanced") echo "Emerald Hill, LMKD, pTune, and update-channel tools." ;;',
    )
    if '"LMKD early test")' not in menu_cycle:
        menu_cycle = menu_cycle.replace(
            '    "EH Event Log") echo "Show bounded apply and restore evidence." ;;',
            '    "EH Event Log") echo "Show bounded apply and restore evidence." ;;\n    "LMKD early test") echo "Guarded reboot-only experimental early property test." ;;\n    "LMKD Evidence") echo "Show early timing and post-boot LMKD snapshots." ;;',
        )
    write("tools/menu/menu-cycle.sh", menu_cycle)

    status_block = r'''  lmk_test_enabled="$(cfg_get LMKD_EARLY_SWAP_LOW_TEST)"
  lmk_test_ack="$(cfg_get LMKD_EARLY_SWAP_LOW_RISK_ACK)"
  [ -n "$lmk_test_enabled" ] || lmk_test_enabled=0
  [ -n "$lmk_test_ack" ] || lmk_test_ack=none
  lmk_early_file="$DATA_ROOT/lmkd-test/early-swap-low.env"
  lmk_post_file="$DATA_ROOT/lmkd-test/postboot.env"
  lmk_apply_state="$(kv_get apply_state "$lmk_early_file")"
  lmk_timing_state="$(kv_get timing_state "$lmk_early_file")"
  lmk_property_after="$(kv_get property_after "$lmk_early_file")"
  lmk_test_ready="$(kv_get test_ready "$lmk_post_file")"
  lmk_consumption_proof="$(kv_get consumption_proof "$lmk_post_file")"
  [ -n "$lmk_consumption_proof" ] || lmk_consumption_proof=not_claimed
  lmk_icon="$OFF"
  lmk_state=stock_disabled
  lmk_value=stock
  if [ "$lmk_test_enabled" = 1 ] && [ "$lmk_test_ack" = explicit_user_test ]; then
    lmk_icon="$WARN"
    lmk_state=experimental_reboot_or_evidence_pending
    lmk_value=test-pending
    if [ "$lmk_test_ready" = yes ]; then
      lmk_icon="$OK"
      lmk_state=early_timing_postboot_readback_verified
      lmk_value=test-active
    elif [ "$lmk_apply_state" = late_refused ]; then
      lmk_icon="$BAD"
      lmk_state=late_write_refused
      lmk_value=test-refused
    elif [ "$lmk_apply_state" = failed ]; then
      lmk_icon="$BAD"
      lmk_state=early_apply_failed
      lmk_value=test-failed
    fi
  fi

'''
    content = read("tools/debug/status-lib.sh")
    if "lmk_test_enabled=" not in content:
        content = content.replace('  case "$thermal_value" in\n', status_block + '  case "$thermal_value" in\n', 1)
        content = content.replace(
            'desc="description=P:$polling_icon $polling_value | T:$thermal_icon $thermal_value | Z:$zram_icon $zram_value | Action: settings/debug"',
            'desc="description=P:$polling_icon $polling_value | T:$thermal_icon $thermal_value | Z:$zram_icon $zram_value | L:$lmk_icon $lmk_value | Action: settings/debug"',
            1,
        )
        content = content.replace(
            '    printf \'%s\\n\' "ZRAM_VALUE=$zram_value"\n',
            '    printf \'%s\\n\' "ZRAM_VALUE=$zram_value"\n    printf \'%s\\n\' "LMKD_TEST_ICON=$lmk_icon"\n    printf \'%s\\n\' "LMKD_TEST_STATE=$lmk_state"\n    printf \'%s\\n\' "LMKD_TEST_ENABLED=$lmk_test_enabled"\n    printf \'%s\\n\' "LMKD_TEST_ACK=$lmk_test_ack"\n    printf \'%s\\n\' "LMKD_TEST_APPLY_STATE=${lmk_apply_state:-missing}"\n    printf \'%s\\n\' "LMKD_TEST_TIMING_STATE=${lmk_timing_state:-missing}"\n    printf \'%s\\n\' "LMKD_TEST_PROPERTY_AFTER=${lmk_property_after:-unset}"\n    printf \'%s\\n\' "LMKD_TEST_READY=${lmk_test_ready:-no}"\n    printf \'%s\\n\' "LMKD_TEST_CONSUMPTION_PROOF=$lmk_consumption_proof"\n    printf \'%s\\n\' "LMKD_TEST_VALUE=$lmk_value"\n',
            1,
        )
        content = content.replace(
            '    printf \'%s\\n\' "ZRAM:    $zram_icon  $zram_state"\n',
            '    printf \'%s\\n\' "ZRAM:    $zram_icon  $zram_state"\n    printf \'%s\\n\' "LMKD:    $lmk_icon  $lmk_state"\n',
            1,
        )
        write("tools/debug/status-lib.sh", content)

    replace_once(
        "tools/install-finalize.sh",
        '  [ -s "$MODPATH/tools/ptune/disable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/ptune/disable-ptune-override.sh" || true\n',
        '  [ -s "$MODPATH/tools/ptune/disable-ptune-override.sh" ] && chmod 0755 "$MODPATH/tools/ptune/disable-ptune-override.sh" || true\n  [ -s "$MODPATH/tools/lmkd/early-swap-low-test.sh" ] && chmod 0755 "$MODPATH/tools/lmkd/early-swap-low-test.sh" || true\n  [ -s "$MODPATH/tools/lmkd/verify-early-swap-low-test.sh" ] && chmod 0755 "$MODPATH/tools/lmkd/verify-early-swap-low-test.sh" || true\n',
    )
    replace_once(
        "tools/install-finalize.sh",
        '    printf \'%s\\n\' "zram_eh_risk_ack=$(config_get ZRAM_EH_RISK_ACK)"\n',
        '    printf \'%s\\n\' "zram_eh_risk_ack=$(config_get ZRAM_EH_RISK_ACK)"\n    printf \'%s\\n\' "lmkd_early_swap_low_test=$(config_get LMKD_EARLY_SWAP_LOW_TEST)"\n    printf \'%s\\n\' "lmkd_early_swap_low_risk_ack=$(config_get LMKD_EARLY_SWAP_LOW_RISK_ACK)"\n    printf \'%s\\n\' "lmkd_test_evidence_dir=$CONFIG_DIR/lmkd-test"\n    printf \'%s\\n\' "lmkd_consumption_claim=indirect_timing_only"\n',
    )

    collector = read("tools/bootguard/collect-debug-v3.sh")
    collector = collector.replace(
        "black.?screen|loading.?bar'",
        "black.?screen|loading.?bar|lmkd|lowmemorykiller|swap_free_low_percentage'",
    )
    collector = collector.replace(
        "tools/action-dashboard.sh tools/core/",
        "tools/action-dashboard.sh tools/lmkd/early-swap-low-test.sh tools/lmkd/verify-early-swap-low-test.sh tools/core/",
    )
    collector = collector.replace(
        'copy_tree_files "$DATA_ROOT/validation" "$COLLECT/persistent/validation"\n',
        'copy_tree_files "$DATA_ROOT/validation" "$COLLECT/persistent/validation"\ncopy_tree_files "$DATA_ROOT/lmkd-test" "$COLLECT/persistent/lmkd-test"\n',
        1,
    )
    write("tools/bootguard/collect-debug-v3.sh", collector)

    test_script = r'''#!/usr/bin/env bash
set -euo pipefail

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
early="$root/tools/lmkd/early-swap-low-test.sh"
verify="$root/tools/lmkd/verify-early-swap-low-test.sh"
post_fs="$root/post-fs-data.sh"
service="$root/service.sh"
action="$root/tools/action-dashboard.sh"
install_menu="$root/tools/menu/install-options-menu.sh"
module_prop="$root/module.prop"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/mod/tools" "$tmp/state" "$tmp/bin"
printf '%s\n' test-boot-id > "$tmp/boot_id"
printf '%s\n' '12.34 56.78' > "$tmp/uptime"
printf '%s\n' \
  'MemTotal:       16000000 kB' \
  'MemAvailable:    8000000 kB' \
  'SwapTotal:      16000000 kB' \
  'SwapFree:       12000000 kB' > "$tmp/meminfo"
printf '%s\n' \
  'some avg10=0.10 avg60=0.20 avg300=0.30 total=10' \
  'full avg10=0.00 avg60=0.00 avg300=0.00 total=0' > "$tmp/psi"
printf '%s\n' '' > "$tmp/property"
printf '%s\n' '' > "$tmp/pid"

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'key="${1:-}"' \
  'case "$key" in' \
  '  ro.lmk.swap_free_low_percentage) cat "$LMKD_TEST_PROPERTY_FILE" ;;' \
  '  init.svc.lmkd) printf "%s\\n" running ;;' \
  '  *) printf "%s\\n" "" ;;' \
  'esac' > "$tmp/bin/getprop"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'cat "$LMKD_TEST_PID_FILE"' > "$tmp/bin/pidof"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'test "$1" = -n' \
  'test "$2" = ro.lmk.swap_free_low_percentage' \
  'test "$3" = 1' \
  'printf "%s\\n" 1 > "$LMKD_TEST_PROPERTY_FILE"' > "$tmp/mod/tools/resetprop-rs"
chmod +x "$tmp/bin/getprop" "$tmp/bin/pidof" "$tmp/mod/tools/resetprop-rs"

run_early() {
  MODDIR="$tmp/mod" \
  LMKD_CONFIG_FILE="$tmp/config.env" \
  LMKD_TEST_STATE_DIR="$tmp/state" \
  LMKD_GETPROP_BIN="$tmp/bin/getprop" \
  LMKD_PIDOF_BIN="$tmp/bin/pidof" \
  LMKD_BOOT_ID_FILE="$tmp/boot_id" \
  LMKD_UPTIME_FILE="$tmp/uptime" \
  LMKD_TEST_PROPERTY_FILE="$tmp/property" \
  LMKD_TEST_PID_FILE="$tmp/pid" \
  sh "$early" apply
}

run_verify() {
  LMKD_CONFIG_FILE="$tmp/config.env" \
  LMKD_TEST_STATE_DIR="$tmp/state" \
  LMKD_GETPROP_BIN="$tmp/bin/getprop" \
  LMKD_PIDOF_BIN="$tmp/bin/pidof" \
  LMKD_BOOT_ID_FILE="$tmp/boot_id" \
  LMKD_MEMINFO_FILE="$tmp/meminfo" \
  LMKD_PSI_FILE="$tmp/psi" \
  LMKD_TEST_PROPERTY_FILE="$tmp/property" \
  LMKD_TEST_PID_FILE="$tmp/pid" \
  sh "$verify"
}

bash -n "$early"
bash -n "$verify"
bash -n "$post_fs"
bash -n "$service"
bash -n "$action"
bash -n "$install_menu"

printf '%s\n' \
  'ENABLE_ZRAM_100P=1' \
  'LMKD_EARLY_SWAP_LOW_TEST=0' \
  'LMKD_EARLY_SWAP_LOW_RISK_ACK=none' > "$tmp/config.env"
run_early > "$tmp/disabled.log"
grep -Fq 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_SKIPPED reason=disabled' "$tmp/disabled.log"
grep -Fxq 'apply_state=disabled' "$tmp/state/early-swap-low.env"
[[ ! -s "$tmp/property" ]]

printf '%s\n' \
  'ENABLE_ZRAM_100P=1' \
  'LMKD_EARLY_SWAP_LOW_TEST=1' \
  'LMKD_EARLY_SWAP_LOW_RISK_ACK=explicit_user_test' > "$tmp/config.env"
run_early > "$tmp/apply.log"
grep -Fq 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_APPLY_PASS timing=before_lmkd readback=1 evidence=indirect_timing_only' "$tmp/apply.log"
grep -Fxq 'apply_state=applied_before_lmkd' "$tmp/state/early-swap-low.env"
grep -Fxq 'timing_state=before_lmkd' "$tmp/state/early-swap-low.env"
grep -Fxq 'property_after=1' "$tmp/state/early-swap-low.env"
grep -Fxq 'consumption_proof=not_claimed' "$tmp/state/early-swap-low.env"

printf '%s\n' 4321 > "$tmp/pid"
run_verify > "$tmp/verify.log"
grep -Fq 'RESULT: LMKD_EARLY_SWAP_LOW_POSTBOOT_VERIFY_DONE outcome=success evidence=indirect_timing_only' "$tmp/verify.log"
grep -Fxq 'test_ready=yes' "$tmp/state/postboot.env"
grep -Fxq 'direct_lmkd_consumption_claim=no' "$tmp/state/postboot.env"
grep -Fxq 'consumption_proof=indirect_timing_only' "$tmp/state/postboot.env"

printf '%s\n' '' > "$tmp/property"
printf '%s\n' 777 > "$tmp/pid"
run_early > "$tmp/late.log"
grep -Fq 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_REFUSED reason=lmkd_already_running pid=777' "$tmp/late.log"
grep -Fxq 'apply_state=late_refused' "$tmp/state/early-swap-low.env"
[[ ! -s "$tmp/property" ]]

printf '%s\n' '' > "$tmp/pid"
printf '%s\n' \
  'ENABLE_ZRAM_100P=1' \
  'LMKD_EARLY_SWAP_LOW_TEST=1' \
  'LMKD_EARLY_SWAP_LOW_RISK_ACK=none' > "$tmp/config.env"
run_early > "$tmp/noack.log"
grep -Fq 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_REFUSED reason=explicit_ack_required' "$tmp/noack.log"

printf '%s\n' \
  'ENABLE_ZRAM_100P=0' \
  'LMKD_EARLY_SWAP_LOW_TEST=1' \
  'LMKD_EARLY_SWAP_LOW_RISK_ACK=explicit_user_test' > "$tmp/config.env"
run_early > "$tmp/nozram.log"
grep -Fq 'RESULT: LMKD_EARLY_SWAP_LOW_TEST_REFUSED reason=zram_100p_required' "$tmp/nozram.log"

grep -Fq 'LMKD_EARLY="$MODDIR/tools/lmkd/early-swap-low-test.sh"' "$post_fs"
grep -Fq 'late_mutation_not_allowed' "$early"
if grep -Fq 'resetprop-rs -n ro.lmk.swap_free_low_percentage' "$service" "$root/tools/zram/apply-zram-100p.sh"; then
  printf '%s\n' 'FAIL late_lmkd_write_present'
  exit 1
fi
grep -Fq 'LMKD early test' "$action"
grep -Fq 'LMKD Evidence' "$action"
grep -Fq 'EXPERIMENTAL 1%' "$install_menu"
grep -Fq 'version=2.0.0-alpha.3-dev.19' "$module_prop"
grep -Fq 'versionCode=1016230' "$module_prop"

printf '%s\n' 'PASS dev19_default_disabled'
printf '%s\n' 'PASS dev19_before_lmkd_apply_and_readback'
printf '%s\n' 'PASS dev19_postboot_indirect_evidence_boundary'
printf '%s\n' 'PASS dev19_late_write_refused'
printf '%s\n' 'PASS dev19_ack_and_zram_fail_closed'
printf '%s\n' 'PASS dev19_installer_action_status_wiring'
printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV19_LMKD_TEST_PASS'
'''
    write("tests/test-dev19-lmkd-early-test.sh", test_script)

    for path in (
        "tests/test-dev14-eh-safety.sh",
        "tests/test-dev16-install-regression.sh",
        "tests/test-dev17-state-preservation.sh",
    ):
        update_version_assertions(path)

    dev18 = read("tests/test-dev18-eh-observability.sh")
    dev18 = dev18.replace('ui_menu5 "Advanced" "Emerald Hill mode"', 'ui_menu6 "Advanced" "Emerald Hill mode"')
    dev18 = dev18.replace('ui_menu5 "Debug" "Status" "Collect ZIP" "EH Event Log"', 'ui_menu6 "Debug" "Status" "Collect ZIP" "EH Event Log"')
    dev18 = re.sub(
        r'if grep -Fq \'ro\.lmk\.swap_free_low_percentage\' "\$post_fs"; then\n  printf \'%s\\n\' \'FAIL dev18_unverified_early_lmk_override_present\'\n  exit 1\nfi\n',
        'grep -Fq \'LMKD_EARLY="$MODDIR/tools/lmkd/early-swap-low-test.sh"\' "$post_fs"\n',
        dev18,
    )
    dev18 = dev18.replace("PASS dev18_stock_lmk_default_preserved", "PASS dev18_stock_default_preserved_by_explicit_lmk_gate")
    dev18 = dev18.replace("version=2.0.0-alpha.3-dev.18", "version=2.0.0-alpha.3-dev.19")
    dev18 = dev18.replace("versionCode=1016229", "versionCode=1016230")
    write("tests/test-dev18-eh-observability.sh", dev18)

    dev15 = read("tests/test-dev15-menu-matrix.sh")
    dev15 = dev15.replace(
        '  \'Debug Logging" "Silent" "Verbose"\'; do',
        '  \'LMKD early test" "Disabled (stock)" "EXPERIMENTAL 1%"\' \\\n  \'Debug Logging" "Silent" "Verbose"\'; do',
    )
    dev15 = dev15.replace(
        '  \'ui_menu3 "ZRAM 100%" "Enable 100p (adaptive EH)" "Disable" "Back"\' \\\n  \'ui_menu3 "Emerald Hill mode"',
        '  \'ui_menu3 "ZRAM 100%" "Enable 100p (adaptive EH)" "Disable" "Back"\' \\\n  \'ui_menu3 "Emerald Hill mode"',
    )
    dev15 = dev15.replace(
        '  \'ui_menu5 "Debug" "Status" "Collect ZIP" "EH Event Log" "Debug Logging" "Back"\' \\\n  \'ui_menu5 "Advanced" "Emerald Hill mode" "pTune Status" "pTune Override" "Update Channel" "Back"\'',
        '  \'ui_menu6 "Debug" "Status" "Collect ZIP" "EH Event Log" "LMKD Evidence" "Debug Logging" "Back"\' \\\n  \'ui_menu6 "Advanced" "Emerald Hill mode" "LMKD early test" "pTune Status" "pTune Override" "Update Channel" "Back"\'',
    )
    dev15 = dev15.replace("version=2.0.0-alpha.3-dev.18", "version=2.0.0-alpha.3-dev.19")
    dev15 = dev15.replace("versionCode=1016229", "versionCode=1016230")
    dev15 = dev15.replace("pass dev18_metadata_and_current_wording", "pass dev19_metadata_and_current_wording")
    dev15 = dev15.replace("ROUTE installer: zram disabled/adaptive/max-lock", "ROUTE installer: zram disabled/adaptive/max-lock and lmkd test disabled/experimental")
    dev15 = dev15.replace("ROUTE action debug: status/collect/eh-log/toggle/back", "ROUTE action debug: status/collect/eh-log/lmkd-evidence/toggle/back")
    dev15 = dev15.replace("ROUTE action advanced: eh/ptune-status/ptune-override/update-channel/back", "ROUTE action advanced: eh/lmkd/ptune-status/ptune-override/update-channel/back")
    write("tests/test-dev15-menu-matrix.sh", dev15)

    for path in (
        "tools/lmkd/early-swap-low-test.sh",
        "tools/lmkd/verify-early-swap-low-test.sh",
        "tests/test-dev19-lmkd-early-test.sh",
    ):
        os.chmod(ROOT / path, 0o755)

    print("RESULT: VNEXT_DEV19_BUILDER_DONE")


def lambda_match(block: str, next_function: str) -> str:
    return block + "\n\n" + next_function


def api_request(method: str, url: str, token: str) -> tuple[int, str]:
    request = urllib.request.Request(
        url,
        method=method,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "pixel-thermal-vnext-cleanup",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return response.status, response.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read().decode("utf-8", errors="replace")


def cleanup_branches() -> None:
    token = os.environ.get("GH_TOKEN", "")
    repo = os.environ.get("GITHUB_REPOSITORY", "Lycidias93/pixel-10-pro-xl-thermal-fix")
    owner = repo.split("/", 1)[0]
    if not token:
        raise SystemExit("GH_TOKEN missing")

    branches = [
        "Profiles_work",
        "prerelease/v1413-test8-cp31-outdoor-safe-20260626-071606",
        "release/v1.5.2-universal-v2-alpha.1",
        "repo-maintenance/release-v2-alpha3-dev6-user-go-20260727",
        "repo-maintenance/release-v2-alpha3-dev8-user-go-20260728",
        "repo-maintenance/v2-outdoor-runtime-evidence-guard-dev4-20260726",
        "repo-maintenance/v2-zram-eh-dev12-20260730",
        "v2-perf",
        "v2-v",
    ]

    failures: list[str] = []
    for branch in branches:
        if branch in {"main", "v2", BRANCH}:
            failures.append(f"protected_or_current:{branch}")
            continue
        head = urllib.parse.quote(f"{owner}:{branch}", safe="")
        pulls_url = f"https://api.github.com/repos/{repo}/pulls?state=open&head={head}&per_page=10"
        status, body = api_request("GET", pulls_url, token)
        if status != 200:
            failures.append(f"pr_check_http_{status}:{branch}")
            continue
        if json.loads(body):
            failures.append(f"open_pr:{branch}")
            continue
        ref = urllib.parse.quote(branch, safe="")
        ref_url = f"https://api.github.com/repos/{repo}/git/refs/heads/{ref}"
        status, _ = api_request("GET", ref_url, token)
        if status == 404:
            print(f"BRANCH_CLEANUP already_absent branch={branch}")
            continue
        if status != 200:
            failures.append(f"ref_check_http_{status}:{branch}")
            continue
        status, body = api_request("DELETE", ref_url, token)
        if status != 204:
            failures.append(f"delete_http_{status}:{branch}:{body[:120]}")
            continue
        print(f"BRANCH_CLEANUP deleted branch={branch}")

    if failures:
        for failure in failures:
            print(f"BRANCH_CLEANUP_FAIL {failure}")
        raise SystemExit(1)
    print("RESULT: OBSOLETE_BRANCH_CLEANUP_DONE outcome=success retained=main,v2")


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "apply"
    if mode == "cleanup-branches":
        cleanup_branches()
    elif mode == "apply":
        apply_source_changes()
    else:
        raise SystemExit(f"unknown mode={mode}")
