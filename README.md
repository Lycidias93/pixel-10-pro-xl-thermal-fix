# Pixel 10 Thermal & Memory Control

**Magisk module for guarded Pixel 10 thermal profiles, local dynamic build admission, Action settings, Bootguard, and optional ZRAM 100p.**

[Download latest release](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/latest) · [Telegram](https://t.me/lycidias93) · [Issues](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/issues) · [Release notes](release-notes/README.md) · [Changelog](CHANGELOG.md) · [Credits](CREDITS.md)

## Channels and current development

| Lane | Version | Status |
|---|---|---|
| Stable | `1.5.1-universal.1` / `1016108` | Public stable channel |
| Public prerelease | `2.0.0-alpha.3-dev.2` / `1016213` | Public lean development prerelease; exact Mustang install/postboot PASS |
| Previous rollback baseline | `2.0.0-alpha.3-dev` / `1016212` | Runtime-proven Mustang rollback anchor |

The public prerelease is bound to tag `v2.0.0-alpha.3-dev.2`, asset `pixel-10-thermal-memory-control-2.0.0-alpha.3-dev.2.zip`, SHA-256 `3590bf96d55fd577326b240301d660fffbdef48513bdbf73cc1305fdb1f6d13b`, and size `303616` bytes. Stable `update.json` remains unchanged. Channel changes use separate release operations and are never implied by development commits.

Living status and evidence boundaries: [V2 Alpha validation plan](docs/v2-alpha-validation-plan.md).

## Dynamic V2 admission model

The exact build list is an **evidence registry**, not the activation gate.

Thermal materialization may proceed when:

1. the device codename belongs to the supported Pixel 10 platform set;
2. the Android major version is supported;
3. the device's own three stock thermal files are readable and structurally valid;
4. the generated overlay changes only the controlled Polling and Outdoor targets;
5. source manifest, patch manifest, exact-delta validation, and active-runtime checks pass.

Evidence states:

- `exact_verified`: exact build evidence already exists;
- `dynamic_unverified`: an unlisted build on a supported platform passes local stock-derived validation;
- `unsupported_platform`: unknown codename or unsupported Android version; Thermal stays disabled while ZRAM may remain available.

No GitHub API or raw-file refresh is required before Action opens or before an unlisted supported-platform build can be validated.

## Controlled runtime scope

Only these stock-derived thermal files are controlled:

- `thermal_info_config.json`
- `thermal_info_config_charge.json`
- `thermal_info_config_throttling.json`

Available thermal profiles:

| Profile | Controlled Outdoor delta |
|---|---:|
| Stock | `+0 °C` |
| Outdoor Safe | `+1 °C` |
| Outdoor Plus | `+2 °C` |
| Outdoor Extended | `+3 °C` |

Polling Mod replaces only matching controlled `PollingDelay: 300000` values with `5000`. The independent validator rejects unexpected byte changes, malformed target arrays, wrong deltas, lowercase polling keys, unsupported polling values, or incomplete source/overlay inventories.

The module does **not** disable Android thermal safety, replace the stock Thermal HAL, overclock the device, or provide a benchmark/FPS unlock.

## Installation flow

### Requirements

- Supported Pixel 10-series platform.
- Supported Android major version.
- Magisk or a compatible tested module backend.
- A working module-disable or recovery path.
- At least 15 percent battery for module installation.

### Single-pass install choices

`install-options-menu.sh` asks once for:

- Polling Mode
- Thermal Profile
- ZRAM 100p
- pTune override
- Debug logging

Thermal and ZRAM install helpers consume the confirmed configuration without spawning duplicate install submenus. Separate Thermal and ZRAM menus remain available through Magisk Action for later changes.

### Install and verify

1. Install the exact test or release ZIP through Magisk.
2. Review the selected options and generated install autosave.
3. Reboot.
4. Run the installed compatibility verifier.
5. Confirm Bootguard, active vendor hashes, Polling values, Thermal service, ZRAM, and pTune state.

Primary installed verifier:

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
REASON=active_dynamic_overlay_verified
```

## Canonical validation state

Persistent validation evidence is canonical under:

```text
/data/adb/pixel-10-pro-xl-thermal-fix/validation/
```

Files:

- `validation-report.json`
- `outdoor-delta-validation.env`
- `patch-manifest.tsv`
- `state.env`

`state.env` records schema, build/profile coordinates, canonical paths, hashes, and final validation state. Historical module/data locations remain compatibility symlinks only; independent persistent copies are not allowed.

`$MODPATH/guard/` remains focused on Bootguard, compatibility, manager status, Action timing, and other runtime guard markers.

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

## ZRAM 100p

ZRAM 100p is optional and requires explicit user selection. The verified runtime path uses:

- active `/dev/block/zram0` swap near total RAM size;
- `lz77eh` compression;
- boot-early property application;
- no persistent backup of transient in-memory properties.

The exact public prerelease `2.0.0-alpha.3-dev.2 / 1016213` passed with ZRAM 100p active on Mustang.

## pTune coexistence

pTune coexistence remains advanced and experimental.

- pTune absent: no conflict.
- pTune installed-disabled: no active conflict.
- pTune active without explicit override: Thermal mounting is blocked.
- pTune active with explicit acknowledgement: advanced risk path only.

Known-bad pTune version metadata remains visible even when pTune is safely disabled.

## Action dashboard

Magisk Action provides:

- current P/T/Z status;
- Polling changes;
- Thermal profile changes;
- ZRAM changes;
- debug ZIP creation;
- Bootguard status;
- pTune status and explicit override controls;
- update-channel selection.

Action admission and rematerialization are local. `guard/action-performance.env` records startup-to-dashboard time and materialization duration without a network refresh.

## Debug evidence

Create a debug ZIP:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/bootguard/collect-debug.sh
```

The install autosave records, when available:

- package path, SHA-256, and bytes;
- battery and power state;
- install duration;
- device/build/root/backend information;
- selected options and pTune guard state;
- overlay, guard, validation, and install-state inventories.

Review debug output before posting it publicly. Remove tokens, personal paths, private hostnames, private IP addresses, MAC addresses, and unrelated logs.

## Runtime evidence status

### Exact Mustang public-prerelease baseline

`2.0.0-alpha.3-dev.2 / 1016213` passed installation and post-reboot verification on:

- Pixel 10 Pro XL (`mustang`)
- Android `17`
- build `CP2A.260705.006`
- incremental `15641320`
- Stock Thermal, exact delta `0`
- Polling Mod
- ZRAM 100p with active `lz77eh`
- pTune installed-disabled
- Bootguard pending absent, fail count `0`, threshold `2`, last-good present
- all three active `/vendor/etc` hashes equal the generated overlays
- canonical validation hashes and compatibility symlinks exact
- `checks_failed=0`, `warnings=0`

The published release body and tag target were verified, and a fresh public asset download reproduced exactly `303616` bytes and SHA-256 `3590bf96d55fd577326b240301d660fffbdef48513bdbf73cc1305fdb1f6d13b`.

### Remaining evidence work

- Blazer: community Android 17 runtime PASS; exact normalized evidence should be hardened.
- Frankel and rango: exact runtime evidence still required before broad stable claims.
- Unlisted supported-platform builds: local dynamic validation is supported; an external `dynamic_unverified` install/postboot proof remains an evidence gap, disclosed in the prerelease notes.
- Active pTune coexistence is not covered by the base PASS.

A PASS on one codename does not automatically verify every other Pixel 10 model.

## Lean release package contract

The deterministic flashable ZIP excludes repository-only content, including:

- `.git*`, `.github/`
- `deprecated/`, `scratch/`, `dev_tools/`, `docs/`
- tests, fixtures, evidence, release work, and build output
- `release-notes/` and root `RELEASE_NOTES_*`
- repository README, changelog, credits, verification markdown
- release-only Alpha 2 policy/candidate helpers
- nested ZIP files

Current CI budgets:

- no more than `60` ZIP entries;
- no more than `450000` bytes;
- no more than `12000` bytes for `action.sh`;
- exactly one install-menu process.

CI builds twice for binary reproducibility, verifies ZIP integrity and required runtime entries, records package/performance metrics, and uploads only a temporary test artifact. Public release publication remains a separate user-confirmed operation.

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
