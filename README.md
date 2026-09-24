# Pixel Thermal & Memory Control

**Dynamic V2 root-module tuning for supported Pixel 10 / 10a, Pixel 9 / 9a and experimental Pixel 11-series devices on Android 17, with guarded stock-derived Thermal controls, optional ZRAM and memory tuning, Bootguard recovery, and a standalone/embedded WebUI.**

Dynamic V2 is the active architecture for the current module line.

[Latest stable — 2.0.4](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.0.4) · [Latest prerelease — 2.1.0-alpha.9](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.1.0-alpha.9) · [All releases](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases) · [Release notes](release-notes/README.md) · [Credits](CREDITS.md) · [Telegram](https://t.me/lycidias93) · [XDA](https://xdaforums.com/t/mod-magisk-pixel-10-pro-xl-a17-thermal-polling-throttle-fix-memory-control-zram-100.4790515/) · [Issues](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/issues)

> [!IMPORTANT]
> **2.0.4 is the current stable release. 2.1.0-alpha.9 is the current public prerelease.**
>
> Stable remains the conservative Pixel 10-family line. Alpha9 is the current vNext line with Pixel 9 / 9a / 10a support, experimental Pixel 11-series support, the standalone/embedded WebUI, guarded memory controls, Pixel 11 recovery controls and sparse Tensor G6 Thermal overlays.

## Current public releases

| Channel | Version | Devices | Main purpose |
|---|---|---|---|
| Stable | [2.0.4](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.0.4) | Pixel 10 family | Dynamic V2 stable line with the current Pixel 10 Thermal materialization fixes |
| Prerelease | [2.1.0-alpha.9](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.1.0-alpha.9) | Pixel 10 / 10a, Pixel 9 / 9a, experimental Pixel 11 family | vNext device expansion, WebUI/runtime controls, guarded memory tuning and sparse Tensor G6 Thermal handling |

Stable and prerelease update channels are independent. Switching channels changes the update metadata path; it does not silently flash another ZIP.

## What changed since Stable 2.0.4

The current prerelease line is a much larger update than the stable hotfix series:

- **Broader Pixel support:** Pixel 9 / 9a and Pixel 10a are admitted as conservative experimental vNext targets, and Pixel 11 / 11 Pro / 11 Pro XL / 11 Pro Fold are admitted with a separate Tensor G6 policy.
- **Standalone WebUI:** Magisk Action launches the authenticated loopback WebUI in the browser. KsuWebUI can host the same interface inside its embedded WebView.
- **Runtime controls in one UI:** Polling, Thermal profiles, ZRAM, Emerald Hill, LMKD, ZRAM page-cluster and logging controls are exposed through guarded typed actions where the target policy permits them.
- **WebUI reliability fixes:** Action startup/lifetime handling, non-mutating dry-runs, mobile viewport/keyboard behavior and cached Inventory navigation were hardened across the alpha line.
- **Installer reliability:** the volume-key selection timeout no longer leaves installation hanging, and Thermal numeric validation is locale-stable.
- **Pixel 11 recovery controls:** HotHysteresis and MaxReleaseStep are independent controls while classic PollingDelay and PassiveDelay remain Stock-only.
- **Sparse Tensor G6 overlays:** Alpha9 materializes only Pixel 11 Thermal files that actually contain an admitted policy change. Untouched graph members remain stock and byte-identical.
- **Stock-no-overlay on Pixel 11:** Stock Thermal + Stock recovery creates no generated Thermal JSON overlay; ZRAM can remain independent.
- **Guarded memory tuning:** ZRAM 100%, Emerald Hill, LMKD 1% and ZRAM page-cluster 0 are integrated behind explicit state/confirmation checks.

See [2.1.0-alpha.9 release notes](release-notes/2.1.0-alpha.9.md) for the current prerelease delta and [Release notes](release-notes/README.md) for history.

## Supported devices

### Stable 2.0.4

Stable targets the Android 17 Pixel 10 family:

| Codename | Device |
|---|---|
| `mustang` | Pixel 10 Pro XL |
| `blazer` | Pixel 10 Pro |
| `frankel` | Pixel 10 |
| `rango` | Pixel 10 Pro Fold |

### Prerelease 2.1.0-alpha.9

Alpha9 carries one Android 17 vNext line with family-specific policy:

| Codename | Device | Current policy |
|---|---|---|
| `mustang` | Pixel 10 Pro XL | standard vNext |
| `blazer` | Pixel 10 Pro | standard vNext |
| `frankel` | Pixel 10 | standard vNext |
| `rango` | Pixel 10 Pro Fold | standard vNext |
| `stallion` | Pixel 10a | experimental · conservative Thermal policy · Outdoor Safe up to +1 °C |
| `tokay` | Pixel 9 | experimental · conservative Thermal policy · Outdoor Safe up to +1 °C |
| `caiman` | Pixel 9 Pro | experimental · conservative Thermal policy · Outdoor Safe up to +1 °C |
| `komodo` | Pixel 9 Pro XL | experimental · conservative Thermal policy · Outdoor Safe up to +1 °C |
| `comet` | Pixel 9 Pro Fold | experimental · conservative Thermal policy · Outdoor Safe up to +1 °C |
| `tegu` | Pixel 9a | experimental · conservative Thermal policy · Outdoor Safe up to +1 °C |
| `cubs` | Pixel 11 | experimental · Stock polling/timing · Outdoor Safe up to +1 °C |
| `grizzly` | Pixel 11 Pro | experimental · Stock polling/timing · Outdoor Safe up to +1 °C |
| `kodiak` | Pixel 11 Pro XL | experimental · Stock polling/timing · Outdoor Safe up to +1 °C |
| `yogi` | Pixel 11 Pro Fold | experimental · Stock polling/timing · Outdoor Safe up to +1 °C |

### Experimental-family boundaries

**Pixel 9 / 9a / 10a**

- local stock-layout validation is mandatory before Thermal materialization;
- Outdoor is capped at **Safe / +1 °C** where admitted;
- pTune Thermal coexistence override is blocked;
- platform/firmware transitions do not justify reusing a stale experimental Thermal overlay.

**Pixel 11 / Tensor G6**

- Thermal handling follows a bounded `Include` graph rooted at `thermal_info_config.json`, rather than the older fixed three-file assumption;
- classic `PollingDelay` and `PassiveDelay` remain **Stock-only**;
- Outdoor Safe is capped at **+1 °C** on the admitted master `VIRTUAL-SKIN` target only;
- derivative/model/charging and emergency/protection objects remain outside the Outdoor allowlist;
- pTune Thermal coexistence override remains blocked;
- Alpha9 uses **sparse overlays**: unchanged Tensor G6 Thermal graph members stay outside the module overlay.

The detailed evidence/state matrix is kept in [docs/vnext-device-test-matrix.md](docs/vnext-device-test-matrix.md).

## Features

### Guarded Thermal control

Dynamic V2 derives supported Thermal materialization from the device's own stock configuration and validates the result before allowing it to become active.

Depending on device family, available controls can include:

- **Polling Mode:** Stock or module polling where admitted. Pixel 11 remains Stock-only.
- **Thermal Profile:** Stock, Outdoor Safe, Outdoor Plus or Outdoor Extended where the family policy admits them.
- **Recovery controls on Pixel 11:** independent HotHysteresis and MaxReleaseStep.
- **Platform-transition protection:** stale or incompatible materialization is rejected instead of blindly reused.

The module does **not** replace the Pixel Thermal HAL, globally disable Android Thermal management, or intentionally remove emergency/shutdown protection.

### ZRAM 100%

Optional ZRAM 100% provides approximately total-RAM compressed-memory capacity, uses `lz77eh` when available, applies the intended memory properties and verifies active swap/non-zero disksize after boot.

### Emerald Hill

- **Adaptive** is the normal daily mode.
- **EXPERIMENTAL max lock** raises the minimum accelerator frequency to the validated maximum OPP and is expected to increase power use and heat.

### LMKD 1%

The experimental LMKD option sets `ro.lmk.swap_free_low_percentage=1`, verifies the property and uses the supported reload/restart path. It does not disable LMKD or prevent Android from killing applications under other memory-pressure conditions.

### ZRAM page-cluster 0

The guarded experimental `page-cluster=0` option is opt-in and requires confirmation.

When explicitly selected, the requested zero state is stored in private module configuration and reapplied only after Bootguard verification and active ZRAM are available after reboot. Selecting Stock clears the persisted request and restores the same-boot baseline when the module owns the write.

## WebUI

The current vNext line provides two supported launch paths:

1. **Module Action / standalone browser:** open the module card and tap **Action**. The module starts the authenticated loopback WebUI and opens the browser.
2. **KsuWebUI:** open the module through KsuWebUI to bootstrap the same loopback interface inside its WebView.

The WebUI provides:

- active feature state and current values;
- cached Inventory views;
- guarded Thermal and memory controls;
- previews/confirmations where required;
- Silent / Verbose logging controls;
- bounded logs and support information;
- clear active, blocked and unavailable states.

Both paths use the same loopback-only control surface. KsuWebUI is a bounded host/bootstrap path, not a second unrestricted root-command backend.

## Root-manager compatibility

The package uses a standard Magisk-style module layout and currently contains installer paths for:

- **Magisk** via `/data/adb/magisk/util_functions.sh`;
- **KernelSU-compatible managers** via `/data/adb/ksu/util_functions.sh`;
- **APatch** via `/data/adb/ap/bin/util_functions.sh`.

The installer also detects Magisk, KernelSU, KernelSU Next, SukiSU-compatible and APatch root environments.

**APatch note:** the package is architecturally compatible and contains an explicit APatch installer path, but APatch has not yet been marked as real-device hardware-validated for this module. If you test it, include a Support Snapshot/logs with the report.

Zygisk is not required for the Thermal/ZRAM functionality described here.

## Installation and updating

### Requirements

- a supported device for the selected channel;
- Android 17;
- Magisk or a compatible root-module manager;
- at least 15% battery for normal installation;
- no unreviewed active pTune conflict;
- a known module-disable/recovery path before experimenting with Thermal or memory settings.

### Stable

Download [2.0.4](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.0.4), install the ZIP from the root-module manager and reboot.

### Prerelease

Download [2.1.0-alpha.9](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.1.0-alpha.9), install the ZIP from the root-module manager and reboot before judging runtime state.

Users already on the prerelease channel can use the normal module update flow because `update-prerelease.json` points to Alpha9.

## Status and support

After reboot, open the module WebUI and check the active feature state.

For a useful support report, create a **Support Snapshot** and include:

- device model/codename;
- Android build ID;
- root implementation;
- module version;
- selected Polling/Thermal/ZRAM/LMKD/Emerald Hill/page-cluster state;
- exact reproduction steps.

Review diagnostic archives before posting them publicly.

For temperature or performance reports, avoid attributing a difference to one subsystem without a matched A/B comparison. On experimental Pixel 11 targets, start from Polling Stock, Thermal Stock, ZRAM disabled, LMKD Stock, Emerald Hill Adaptive, page-cluster Stock and Logging Silent, then change one optional feature at a time under comparable conditions.

## Safety boundaries

- Unknown or unsupported platforms fail closed for Thermal changes.
- Experimental Pixel 9 / 9a / 10a / 11 targets retain the stricter conservative vNext policy.
- Pixel 11 remains on Stock classic polling/timing in Alpha9.
- Pixel 11 Outdoor changes are limited to the admitted exact master `VIRTUAL-SKIN` target.
- pTune conflict protection remains authoritative; Thermal coexistence override is unavailable on experimental targets.
- ZRAM, LMKD, Emerald Hill max lock and page-cluster experiments remain independently controlled.
- Failed validation or a platform transition never justifies blindly mounting an old Thermal overlay.
- Emergency/shutdown Thermal protection is not intentionally disabled.
- The WebUI remains loopback-only.

## Recovery

Normal rollback:

1. Disable or remove the module in the root-module manager.
2. Reboot.

Emergency disable marker:

```sh
su -c 'touch /data/adb/modules/pixel-10-pro-xl-thermal-fix/disable'
su -c reboot
```

Mount-only diagnostic bypass:

```sh
su -c 'touch /data/adb/modules/pixel-10-pro-xl-thermal-fix/skip_mount'
su -c reboot
```

## WebUI foundation and credits

The current prerelease line retains the shared **[Android Root Module Standalone WebUI Template](https://github.com/Lycidias93/android-root-module-webui-template)** foundation introduced during the Alpha4–Alpha7 work. The currently documented consumer baseline is WebUI Core `0.6.6`, including the HUP-safe standalone Action lifetime, Android/Toybox-safe dry-run handling and mobile-input viewport fix.

The shared core documents clean adaptations or design references from:

- **Coolapk-Code9527 / F2FS-Optimizer** — localhost lifecycle and Action-launch concepts;
- **KOWX712 / ksu-webui-demo** — compact vanilla-JavaScript WebUI concepts;
- **barsikus007 / ksu-webui-module-template** — multi-manager packaging/template concepts;
- **AuroraNasa / AMMF2** — logging/theme/localization/component reference concepts;
- **Drizzy07x / Drizzy11 / Supercharger Pixel 9 Series** — readiness, duplicate-action and stale-response regression patterns;
- **AshBorn / AshReXcue / AshLooper** — design reference only for unsaved-change/session diagnostics;
- **Adinata / KsuWebUI** — compatibility/design reference for the embedded WebView host.

The current line also includes contributions, testing and technical input from **Harish / Codecity001**, **Allen Chang**, **JoshuaDoes / pTune**, **marx161** and other community testers.

See [CREDITS.md](CREDITS.md) for detailed attribution, pinned upstream provenance and license boundaries.

## License

See [LICENSE](LICENSE). Shared WebUI upstream provenance and license boundaries are documented in [CREDITS.md](CREDITS.md) and in the shared WebUI template's `UPSTREAMS.md` / `NOTICE` files.
