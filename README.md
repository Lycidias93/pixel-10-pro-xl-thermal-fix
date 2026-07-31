# Pixel 10 Thermal & Memory Control

**Dynamic V2 Magisk module for guarded Pixel 10 Thermal profiles, local stock-derived validation, Bootguard, Action settings, optional ZRAM 100p, and controlled experimental memory tests.**

[Releases](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases) · [Telegram](https://t.me/lycidias93) · [Issues](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/issues) · [Release notes](release-notes/README.md) · [Changelog](CHANGELOG.md) · [Credits](CREDITS.md)

## Current project state

Dynamic V2 is the active source architecture on `main`.

| Lane | Version | State |
|---|---|---|
| Current source | `2.0.0-alpha.3-dev.20` / `1016231` | Unreleased vNext source with consolidated LMKD reload and badge reliability fix |
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

## vNext LMKD 1% reload experiment

Dev.20 replaces the ineffective post-fs-data experiment with one consolidated function inside `tools/zram/apply-zram-100p.sh`.

When explicitly enabled with ZRAM 100p, the module sets:

```text
ro.lmk.swap_free_low_percentage=1
```

It then prefers Android's targeted `lmkd.reinit` contract. If that trigger is unavailable or does not acknowledge, it falls back to a verified `ctl.restart lmkd` / stop-start cycle. The same path works during boot and when toggled from Magisk Action.

Safety contract:

- disabled by default;
- requires ZRAM 100p and explicit acknowledgement;
- no separate LMKD runtime helper scripts;
- records property readback, reload method, service state and PID evidence;
- remembers the original property for a controlled runtime restore;
- does not claim a direct internal-value probe beyond the AOSP reinit/start contract.

Dev.20 also verifies the final P/T/Z/L manager description after boot and retries the write when readback is still static.

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
- experimental LMKD 1% reload;
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
