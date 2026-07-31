# Pixel 10 Thermal & Memory Control

**Magisk module for guarded Pixel 10 thermal profiles, local dynamic build admission, Action settings, Bootguard, and optional ZRAM 100p.**

[Download latest release](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/latest) · [Telegram](https://t.me/lycidias93) · [Issues](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/issues) · [Release notes](release-notes/README.md) · [Changelog](CHANGELOG.md) · [Credits](CREDITS.md)

## Channels and current Alpha status

| Lane | Version | Status |
|---|---|---|
| Stable | `1.5.1-universal.1` / `1016108` | Public stable channel; unchanged |
| Public Alpha prerelease | `2.0.0-alpha.3-dev.10` / `1016221` | Latest public Alpha; Mustang install, postboot, Thermal, ZRAM and Action verification PASS |
| Current `v2` source | `2.0.0-alpha.3-dev.15` / `1016226` | Private defaults/menu corrective test build; device verification required |
| Previous private build | `2.0.0-alpha.3-dev.14` / `1016225` | EH safety correction installed successfully; superseded by the menu/defaults audit |

The public prerelease is bound to tag `v2.0.0-alpha.3-dev.10`, asset `pixel-10-thermal-memory-control-2.0.0-alpha.3-dev.10.zip`, SHA-256 `49b58b8393090d057ba4ff80006615fc4805a74c92ee19d41d44200e7fe4f83a`, and size `310221` bytes.

Stable `update.json` remains unchanged. `update-prerelease.json` points to dev.10. Development commits never publish a tag, asset, or update-channel change by themselves.

Living status and evidence boundaries: [V2 Alpha validation plan](docs/v2-alpha-validation-plan.md).

## Dev.13 live-verification result

Dev.13 successfully proved the main runtime path on Mustang Stable `CP2A.260705.006 / 15641320`:

- dynamic local Thermal validation and materialization;
- Polling Mod with all 22 controlled values active;
- Outdoor Extended with validated `+3 °C` controlled delta;
- all three active Vendor Thermal files matching the module overlays;
- ZRAM near 100 percent of RAM with active `lz77eh`;
- `vm.swappiness=100`;
- Bootguard and Thermal service health;
- complete post-OTA runtime state refresh.

Live verification also found two issues that block publication:

1. Mustang exposes the same Emerald Hill devfreq device through two sysfs aliases. Dev.13 counted and recorded both paths, allowing a duplicate baseline entry and an unsafe restore sequence.
2. The attempted `ro.lmk.swap_free_low_percentage=1` post-boot override was not readable or proven effective. The module must not claim that LMKD accepted the value.

For that reason, dev.13 is **not a release candidate**. The optional Emerald Hill maximum-frequency lock is not the everyday default. The normal adaptive hardware-accelerated ZRAM path remains the intended daily configuration.

## Dev.14 corrective implementation

Dev.14 implements:

- physical Emerald Hill node deduplication across sysfs aliases;
- one authoritative baseline per physical device;
- migration-safe and readback-verified restore behavior, including old dev.13 duplicate baselines;
- adaptive Emerald Hill operation as the safe default;
- ZRAM 100p and `lz77eh` independent from the optional maximum-frequency minimum lock;
- Fresh choices that start from Polling Mod, Stock Thermal, ZRAM 100 percent with adaptive EH, verbose logging and pTune override off;
- separate pTune, ZRAM and EH risk acknowledgements;
- stock LMK policy without an unverified override claim;
- EH status schema v2 and regression fixtures for physical alias paths.

Dev.14 still requires exact package construction, installation, reboot, and fresh on-device verification before any release decision.

## Dynamic V2 admission model

The exact build list is an **evidence registry**, not the activation gate.

Thermal materialization may proceed when:

1. the device codename belongs to the supported Pixel 10 platform set;
2. the Android major version is supported;
3. the device's own three stock Thermal files are readable and structurally valid;
4. the generated overlay changes only controlled Polling and Outdoor targets;
5. source manifest, patch manifest, exact-delta validation, and active-runtime checks pass.

Evidence states:

- `exact_verified`: exact build evidence already exists;
- `dynamic_unverified`: an unlisted build on a supported platform passes local stock-derived validation;
- `unsupported_platform`: unknown codename or unsupported Android version; Thermal stays disabled while independent ZRAM functionality may remain available.

No GitHub API or raw-file refresh is required before Action opens or before a supported unlisted build can be validated.

## Controlled Thermal scope

Only these stock-derived files are controlled:

- `thermal_info_config.json`
- `thermal_info_config_charge.json`
- `thermal_info_config_throttling.json`

Available profiles:

| Profile | Controlled Outdoor delta |
|---|---:|
| Stock | `+0 °C` |
| Outdoor Safe | `+1 °C` |
| Outdoor Plus | `+2 °C` |
| Outdoor Extended | `+3 °C` |

Polling Mod replaces only matching controlled `PollingDelay: 300000` values with `5000`. The independent validator rejects unexpected byte changes, malformed target arrays, wrong deltas, unsupported polling values, or incomplete source/overlay inventories.

The module does **not** disable Android Thermal safety or replace the stock Thermal HAL.

## ZRAM and Emerald Hill

ZRAM 100p is optional and requires explicit user selection. The current verified daily path uses:

- active `/dev/block/zram0` swap near total RAM size;
- `lz77eh` compression;
- `vm.swappiness=100`;
- adaptive Emerald Hill devfreq behavior;
- no persistent backup of transient in-memory properties.

The optional Emerald Hill tuning does not request a frequency above the kernel-exposed maximum. A maximum-frequency minimum lock can nevertheless increase power use and heat because the accelerator can no longer downclock while the lock is active. It is experimental and is not the normal daily recommendation.

ZRAM capacity and `lz77eh` provide the main multitasking path. The optional EH lock only targets compression/decompression latency; it does not create additional RAM.

## Installation flow

### Requirements

- Supported Pixel 10-series platform.
- Supported Android major version.
- Magisk or a compatible tested module backend.
- A working module-disable or recovery path.
- At least 15 percent battery for installation.

### Install choices

The single installer menu controls:

- Polling Mode;
- Thermal Profile;
- ZRAM 100p;
- optional Emerald Hill behavior on builds that provide it;
- pTune override;
- debug logging.

Thermal and ZRAM helpers consume the confirmed configuration without duplicate install submenus. Separate settings remain available through Magisk Action.

### Install and verify

1. Install the exact test or release ZIP through Magisk.
2. Review the selected options and install autosave.
3. Reboot.
4. Run the installed compatibility verifier.
5. Confirm Bootguard, active Vendor hashes, Polling values, Thermal service, ZRAM, EH state, and pTune state.

Primary installed verifier:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/bootguard/compat-check.sh
```

Healthy Thermal runtime markers include:

```text
DYNAMIC_MATERIALIZATION_VALID=yes
MODULE_OVERLAY_READY=yes
ACTIVE_VENDOR_MATCH=yes
ACTIVE_POLLING_VALID=yes
SAFE_TO_REBOOT=yes
REASON=active_dynamic_overlay_verified
```

## Canonical validation state

Persistent validation evidence is canonical under:

```text
/data/adb/pixel-10-pro-xl-thermal-fix/validation/
```

Important files:

- `validation-report.json`
- `outdoor-delta-validation.env`
- `patch-manifest.tsv`
- `state.env`

`state.env` records schema, build/profile coordinates, canonical paths, hashes, and final validation state. Historical locations remain compatibility links only.

## Bootguard and rollback

Normal Bootguard minimum threshold: `2`.

Threshold `1` is reserved for explicit Canary diagnostic recovery mode and is not enabled merely because a build is unlisted.

Normal rollback:

1. Disable or remove the module in Magisk.
2. Reboot.

Emergency root-shell disable:

```sh
su -c 'touch /data/adb/modules/pixel-10-pro-xl-thermal-fix/disable'
su -c reboot
```

Mount-only emergency bypass:

```sh
su -c 'touch /data/adb/modules/pixel-10-pro-xl-thermal-fix/skip_mount'
su -c reboot
```

## pTune coexistence

pTune coexistence remains advanced and experimental.

- pTune absent: no conflict.
- pTune installed-disabled: no active conflict.
- pTune active without explicit override: Thermal mounting is blocked.
- pTune active with explicit acknowledgement: advanced risk path only.

Known-bad pTune version metadata remains visible even when pTune is safely disabled.

## Action dashboard

Magisk Action provides:

- current Polling, Thermal and ZRAM status;
- guarded settings changes;
- debug ZIP creation;
- Bootguard status;
- pTune status and explicit override controls;
- update-channel selection.

Action admission and rematerialization are local. The dev.9/dev.10 performance work avoids repeated full scans, caches validated state, and suppresses unnecessary status re-rendering when returning from read-only submenus.

## Debug evidence

Create a debug ZIP:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/bootguard/collect-debug.sh
```

The collector and install autosave include, when available:

- package path, SHA-256, bytes, battery, and power state;
- device/build/root/backend information;
- selected options and risk acknowledgements;
- overlay, validation, Bootguard, ZRAM, EH, pTune, and install-state evidence;
- current and previous boot diagnostics.

Review debug output before posting it publicly. Remove tokens, personal paths, private hostnames, private IP addresses, MAC addresses, and unrelated logs.

## Runtime evidence status

### Public Alpha baseline

The exact public dev.10 package passed installation and postboot verification on:

- Pixel 10 Pro XL (`mustang`);
- Android `17`;
- build `CP2A.260705.006` / incremental `15641320`;
- Outdoor Extended with exact `+3 °C` controlled delta;
- Polling Mod;
- ZRAM 100p with active `lz77eh`;
- pTune installed-disabled;
- Bootguard healthy;
- all three active Vendor files matching generated overlays;
- Action read-only cycle with one refresh, one status print, and two menu renders;
- zero failed checks and zero warnings.

### Current private evidence boundary

Dev.13 extended the verified Mustang path to OTA rematerialization state and exact `eh_freq` admission, but the live alias/restore and LMK-observability findings prevented release. Dev.14 contains the corrective implementation; its repository tests do not replace fresh Mustang installation and post-reboot proof.

### Remaining evidence work

- dev.14 exact Mustang installation and post-reboot verification;
- Blazer exact normalized evidence hardening;
- Frankel and rango runtime evidence;
- external `dynamic_unverified` install/postboot proof on a supported unlisted build;
- active pTune coexistence evidence.

A PASS on one codename does not automatically verify every Pixel 10 model.

## Lean release package contract

The deterministic flashable ZIP excludes repository-only content, including:

- `.git*`, `.github/`, docs, tests, fixtures, and evidence;
- deprecated, scratch, development, and release-work files;
- repository README, changelog, credits, and release notes;
- nested ZIP files.

Current CI budgets:

- no more than `60` ZIP entries;
- no more than `450000` bytes;
- no more than `12000` bytes for `action.sh`;
- exactly one install-menu process.

CI builds twice for reproducibility, verifies ZIP integrity and required runtime entries, records package/performance metrics, and uploads only a temporary test artifact. Public publication remains a separate user-confirmed operation.

## Repository documentation

- [Release notes index](release-notes/README.md)
- [V2 Alpha validation plan](docs/v2-alpha-validation-plan.md)
- [Changelog](CHANGELOG.md)
- [Credits](CREDITS.md)

## Credits

Created by **Lycidias93**, based on earlier work by **marx161**.

The V2 line includes engineering, testing, runtime evidence, UX, and package feedback from **Harish / Codecity001**, **Allen Chang**, **JoshuaDoes**, and the existing project contributors. Detailed attribution is maintained in [CREDITS.md](CREDITS.md).

## License

See [LICENSE](LICENSE).
