# Pixel Thermal & Memory Control

**Dynamic V2 root-module tuning for supported Pixel 10 / 10a and Pixel 9 / 9a devices on Android 17, with guarded stock-derived Thermal profiles, optional ZRAM and memory controls, Bootguard recovery, and a standalone/embedded WebUI.**

[Latest stable — 2.0.4](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.0.4) · [Latest prerelease — 2.1.0-alpha.5](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.1.0-alpha.5) · [All releases](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases) · [Release notes](release-notes/README.md) · [Credits](CREDITS.md) · [Telegram](https://t.me/lycidias93) · [Issues](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/issues)

> [!IMPORTANT]
> **2.0.4 remains the current stable release. 2.1.0-alpha.5 is the current public prerelease.** Stable users can remain on 2.0.4. Alpha5 is for users who intentionally want the expanded Pixel 9 / 9a / 10a vNext line and the newer WebUI controls.

## Current public releases

| Channel | Version | Main purpose |
|---|---|---|
| Stable | `2.0.4` | Pixel 10-family Dynamic V2 stable line with current Thermal materialization hotfixes |
| Prerelease | `2.1.0-alpha.5` | Standalone browser + KsuWebUI embedded WebUI, expanded Pixel 9 / 9a / 10a support line, clearer controls and current vNext reliability fixes |

Stable and prerelease update channels are independent. Switching channel changes only the module update metadata path; it does not automatically flash a ZIP.

## Alpha5 highlights

Alpha5 includes all user-facing Alpha4 changes and adds embedded KsuWebUI support:

- **KsuWebUI can open the module WebUI directly inside its WebView**, without the previous `404 Not Found` / disconnected state.
- **Magisk Action and KsuWebUI work in parallel.** Magisk Action opens the standalone WebUI in the default browser; KsuWebUI keeps it inside its own WebView. Both use the same guarded localhost API.
- **Magisk Action opens a standalone browser WebUI** for normal control and status work.
- **Active settings are shown directly** instead of requiring users to infer state from the old text dashboard.
- **Polling, Thermal, ZRAM, Emerald Hill, LMKD and ZRAM page-cluster controls** are exposed through typed guarded actions.
- **Inventory switching is fast and cache-first**, avoiding repeated deep validation just to change views.
- **The intermittent `server_not_ready` Action startup failure is fixed.**
- **The installer volume-key timeout hang is fixed.**
- **Thermal numeric validation is locale-stable**, including devices using non-English system locales.
- **Mobile layout, action cards, tabs and blocked/active states are clearer** on narrow screens.

See [2.1.0-alpha.5 release notes](release-notes/2.1.0-alpha.5.md) for the cumulative public changelog.

## Supported devices

### Stable 2.0.4

Stable currently targets the Android 17 Pixel 10 family:

| Codename | Device |
|---|---|
| `mustang` | Pixel 10 Pro XL |
| `blazer` | Pixel 10 Pro |
| `frankel` | Pixel 10 |
| `rango` | Pixel 10 Pro Fold |

### Prerelease 2.1.0-alpha.5

Alpha5 carries one Android 17 vNext line for:

| Codename | Device | vNext policy |
|---|---|---|
| `mustang` | Pixel 10 Pro XL | standard vNext |
| `blazer` | Pixel 10 Pro | standard vNext |
| `frankel` | Pixel 10 | standard vNext |
| `rango` | Pixel 10 Pro Fold | standard vNext |
| `stallion` | Pixel 10a | experimental, conservative Thermal policy |
| `tokay` | Pixel 9 | experimental, conservative Thermal policy |
| `caiman` | Pixel 9 Pro | experimental, conservative Thermal policy |
| `komodo` | Pixel 9 Pro XL | experimental, conservative Thermal policy |
| `comet` | Pixel 9 Pro Fold | experimental, conservative Thermal policy |
| `tegu` | Pixel 9a | experimental, conservative Thermal policy |

Pixel 9-series and Pixel 10a targets remain intentionally conservative: local stock-layout validation is mandatory, pTune Thermal coexistence override is blocked on those experimental targets, and their current admitted Outdoor increase is capped at `+1 °C` where applicable.

## What the module changes

The module combines guarded Thermal and memory controls while retaining fail-closed behavior.

### Thermal

The Dynamic V2 path derives supported overlays from the device's own stock Thermal configuration, validates the generated result, and only then allows it to become active.

User-selectable controls include:

- **Polling Mode:** module values or stock values.
- **Thermal Profile:** Stock, Outdoor Safe, Outdoor Plus or Outdoor Extended where the device policy allows it.
- **Firmware transition handling:** stale overlays are rejected and rematerialized from current stock evidence rather than blindly reused.

The module does **not** replace the Pixel Thermal HAL, globally disable Android thermal management, or intentionally alter emergency/shutdown protections.

### ZRAM 100%

Optional ZRAM 100% provides approximately total-RAM compressed-memory capacity, uses `lz77eh` when available, sets the intended memory properties, and verifies active swap/non-zero disksize after boot.

### Emerald Hill

- **Adaptive** is the normal daily mode.
- **EXPERIMENTAL max lock** raises the minimum accelerator frequency to the validated maximum OPP and is expected to use more power and create more heat.

### LMKD 1%

The experimental LMKD option sets `ro.lmk.swap_free_low_percentage=1`, verifies the property, and uses the supported reload/restart path. It does not disable LMKD and does not prevent Android from killing applications for other memory-pressure reasons.

### ZRAM page-cluster

Alpha5 exposes the guarded experimental `page-cluster 0` action through the WebUI. It is opt-in and requires explicit confirmation. If the device stock value is already `0`, leaving the action on Stock avoids taking ownership of an unnecessary runtime write.

## Alpha5 WebUI

There are two supported launch paths:

1. **Magisk Action:** open the module card and tap **Action**. The module starts its loopback WebUI and opens the default browser.
2. **KsuWebUI:** open the module from the KsuWebUI app. Its WebView bootstraps the same authenticated loopback WebUI and stays inside KsuWebUI.

The interface provides:

- current feature status and active values;
- fast cached Inventory views;
- guarded controls for supported runtime/configuration actions;
- preview/confirmation for actions that require it;
- bounded logs and support information;
- clear active, blocked and unavailable states.

Both launch paths converge on the same standalone localhost server and typed allowlisted control surface. KsuWebUI is used only for the bounded bootstrap step; normal WebUI operations do not expose an unrestricted shell/JavaScript command bridge.

If standalone browser startup cannot complete safely, the module retains the legacy Action path as a fallback instead of silently bypassing launcher checks.

## Installation and updating

### Requirements

- supported device for the selected channel;
- Android 17;
- Magisk or a compatible root-module manager;
- at least 15% battery for normal module installation;
- no unreviewed active pTune conflict;
- a known module-disable/recovery path before experimenting with Thermal or memory settings.

### Stable

Download the latest stable package from [v2.0.4](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.0.4), install it from the module manager, and reboot.

### Prerelease

Download the Alpha5 package from [v2.1.0-alpha.5](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.1.0-alpha.5), install it from the module manager, and reboot before judging the new runtime state.

Users already on the prerelease channel can use the normal module update flow because `update-prerelease.json` points to Alpha5.

## Status and support

After reboot, use the Alpha5 WebUI through either launch path to check the active feature state. For a support report, create a **Support Snapshot** from the module UI and include the device model, Android/build ID, module version, selected settings and exact reproduction steps.

The support snapshot is intended to collect bounded diagnostic evidence. Review any archive before posting it publicly.

## Safety boundaries

- Unknown or unsupported platforms fail closed for Thermal changes.
- Experimental Pixel 9 / 9a / 10a targets use the stricter conservative vNext policy.
- pTune conflict protection remains authoritative.
- ZRAM, LMKD, Emerald Hill max lock and page-cluster experiments remain independently controlled and reversible where the platform permits it.
- A failed validation or incompatible firmware transition does not justify blindly mounting an old Thermal overlay.
- The module does not silently disable emergency/shutdown Thermal protection.
- WebUI network scope remains loopback-only.

## Recovery

Normal rollback:

1. Disable or remove the module in the root-module manager.
2. Reboot.

Emergency Magisk disable:

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

Alpha5 consumes the shared **[Android Root Module Standalone WebUI Template](https://github.com/Lycidias93/android-root-module-webui-template)** maintained by Lycidias93, pinned to WebUI Core `0.6.1`.

That shared core documents clean adaptations or design references from:

- **Coolapk-Code9527 / F2FS-Optimizer** — localhost lifecycle and Action-launch concepts;
- **KOWX712 / ksu-webui-demo** — compact vanilla-JavaScript WebUI concepts;
- **barsikus007 / ksu-webui-module-template** — multi-manager packaging/template concepts;
- **AuroraNasa / AMMF2** — logging/theme/localization/component reference concepts;
- **Drizzy07x / Drizzy11 / Supercharger Pixel 9 Series** — readiness, duplicate-action and stale-response regression patterns;
- **AshBorn / AshReXcue / AshLooper** — design reference only for unsaved-change/session diagnostics; no GPL-covered implementation is imported;
- **Adinata / KsuWebUI** — compatibility/design reference for its embedded WebView host; no GPL-covered KsuWebUI implementation is imported.

The Alpha5 module also includes contributions, testing and technical input from **Harish / Codecity001**, **Allen Chang**, **JoshuaDoes / pTune**, **marx161** and other community testers. See [CREDITS.md](CREDITS.md) for detailed attribution and license/provenance boundaries.

## License

See [LICENSE](LICENSE). Shared WebUI upstream provenance and license boundaries are documented in [CREDITS.md](CREDITS.md) and in the shared WebUI template's `UPSTREAMS.md` / `NOTICE` files.
