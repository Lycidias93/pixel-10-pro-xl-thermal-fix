# Pixel Thermal & Memory Control

**Dynamic V2 root-module tuning for supported Pixel 10 / 10a and Pixel 9 / 9a devices on Android 17, with guarded stock-derived Thermal profiles, optional ZRAM and memory controls, Bootguard recovery, and a standalone/embedded WebUI.**

[Latest stable — 2.0.4](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.0.4) · [Latest prerelease — 2.1.0-alpha.5](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.1.0-alpha.5) · [All releases](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases) · [Release notes](release-notes/README.md) · [Credits](CREDITS.md) · [Telegram](https://t.me/lycidias93) · [Issues](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/issues)

> [!IMPORTANT]
> **2.0.4 remains the current stable release. 2.1.0-alpha.5 is the current public prerelease.** Stable users can remain on 2.0.4. Alpha5 is for users who intentionally want the expanded Pixel 9 / 9a / 10a vNext line and the newer WebUI controls.
>
> The current vNext development branch additionally carries **experimental Pixel 11-series code** and post-Alpha5 tester-feedback fixes. That work is not part of the already-published Alpha5 ZIP until a later prerelease is explicitly published.

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

### Public prerelease 2.1.0-alpha.5

The published Alpha5 package carries one Android 17 vNext line for:

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

### vNext development: Pixel 11 series

The current vNext development code admits these Android 17 targets for **experimental device testing**:

| Codename | Device | Initial policy |
|---|---|---|
| `cubs` | Pixel 11 | bounded Include-graph validation; Stock polling only; Outdoor Safe `+1 °C` max |
| `grizzly` | Pixel 11 Pro | bounded Include-graph validation; Stock polling only; Outdoor Safe `+1 °C` max |
| `kodiak` | Pixel 11 Pro XL | bounded Include-graph validation; Stock polling only; Outdoor Safe `+1 °C` max |
| `yogi` | Pixel 11 Pro Fold | bounded Include-graph validation; Stock polling only; Outdoor Safe `+1 °C` max |

Pixel 11 no longer uses the legacy fixed `base + charge + throttling` assumption. vNext resolves a bounded Thermal `Include` graph starting at `thermal_info_config.json`, validates every referenced local Thermal file, rejects missing references/cycles, caches the exact stock graph and permits only the declared byte-level transformations.

The initial Tensor G6 safety envelope is intentionally narrow. Module 5-second polling remains blocked until real-device runtime evidence exists. Outdoor Safe may adjust only the exact `VIRTUAL-SKIN` sensor; derivative/model/charging `VIRTUAL-SKIN-*` sensors, `cellular-emergency` and `OVER-35C` sensors are left untouched. pTune Thermal coexistence override remains blocked and firmware transitions require reinstall while the target is experimental.

The available Pixel 11 Pro stock Thermal archive establishes the graph-layout change and confirms that stock still contains 300-second polling values, but it does **not** count as post-boot module verification. Tester feedback also confirmed that the module can mount once the root/kernel mount backend is correctly configured. Neither observation replaces exact-candidate runtime acceptance. See [the vNext device validation matrix](docs/vnext-device-test-matrix.md).

Current post-Alpha5 feedback work keeps all Pixel 11 polling values Stock-only, persists an explicitly selected `page-cluster=0` state for guarded post-Bootguard reapplication, exposes Silent/Verbose logging controls in the WebUI, and consumes the shared mobile-input viewport fix so the Android software keyboard does not cover confirmation fields. These changes require a newly built exact-head device retest; an older Pixel 11 candidate cannot satisfy the final gate.

## What the module changes

The module combines guarded Thermal and memory controls while retaining fail-closed behavior.

### Thermal

The Dynamic V2 path derives supported overlays from the device's own stock Thermal configuration, validates the generated result, and only then allows it to become active.

User-selectable controls include:

- **Polling Mode:** module values or stock values where the device policy admits both. Pixel 11 development targets currently remain Stock-only.
- **Thermal Profile:** Stock, Outdoor Safe, Outdoor Plus or Outdoor Extended where the device policy allows it.
- **Firmware transition handling:** stale overlays are rejected and rematerialized from current stock evidence rather than blindly reused; experimental Pixel 11 targets require reinstall after a transition.

The module does **not** replace the Pixel Thermal HAL, globally disable Android thermal management, or intentionally alter emergency/shutdown protections.

### ZRAM 100%

Optional ZRAM 100% provides approximately total-RAM compressed-memory capacity, uses `lz77eh` when available, sets the intended memory properties, and verifies active swap/non-zero disksize after boot.

### Emerald Hill

- **Adaptive** is the normal daily mode.
- **EXPERIMENTAL max lock** raises the minimum accelerator frequency to the validated maximum OPP and is expected to use more power and create more heat.

### LMKD 1%

The experimental LMKD option sets `ro.lmk.swap_free_low_percentage=1`, verifies the property, and uses the supported reload/restart path. It does not disable LMKD and does not prevent Android from killing applications for other memory-pressure reasons.

### ZRAM page-cluster

Published Alpha5 exposes the guarded experimental `page-cluster 0` action through the WebUI. It is opt-in and requires explicit confirmation. If the device stock value is already `0`, leaving the action on Stock avoids taking ownership of an unnecessary runtime write.

Current vNext development additionally persists the explicit zero selection in private module configuration. After a reboot, the module waits for Bootguard verification and active ZRAM before reapplying `0`; choosing Stock clears the persisted zero request and restores the same-boot baseline when the module owns it. The write remains a guarded ZRAM experiment, not an unconditional early-boot sysctl mutation.

## Alpha5 / vNext WebUI

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

Current vNext development also exposes **Logging · Silent** and **Logging · Verbose** as typed actions using the same debug configuration as the installer. Silent suppresses optional verbose diagnostics but does not disable required bounded Bootguard/health/support evidence. The shared WebUI Core pin includes a mobile `visualViewport` guard that keeps the focused confirmation/text control visible when the Android software keyboard reduces the usable viewport.

Both launch paths converge on the same standalone localhost server and typed allowlisted control surface. KsuWebUI is used only for the bounded bootstrap step; normal WebUI operations do not expose an unrestricted shell/JavaScript command bridge.

If standalone browser startup cannot complete safely, the module retains the legacy Action path as a fallback instead of silently bypassing launcher checks.

## Installation and updating

### Requirements

- supported device for the selected channel/build;
- Android 17;
- Magisk or a compatible root-module manager;
- at least 15% battery for normal module installation;
- no unreviewed active pTune conflict;
- a known module-disable/recovery path before experimenting with Thermal or memory settings.

### Stable

Download the latest stable package from [v2.0.4](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.0.4), install it from the module manager, and reboot.

### Prerelease

Download the Alpha5 package from [v2.1.0-alpha.5](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.1.0-alpha.5), install it from the module manager, and reboot before judging the new runtime state.

Users already on the prerelease channel can use the normal module update flow because `update-prerelease.json` points to Alpha5. Pixel 11 development support and the post-Alpha5 tester-feedback fixes are not delivered by that already-published update metadata until a later prerelease is explicitly published.

## Status and support

After reboot, use the module WebUI through either launch path to check the active feature state. For a support report, create a **Support Snapshot** from the module UI and include the device model, Android/build ID, module version, selected settings and exact reproduction steps.

The support snapshot is intended to collect bounded diagnostic evidence. Review any archive before posting it publicly.

A reported temperature difference with the module enabled is not attributed to Thermal or another subsystem without a matched A/B run. For Pixel 11 feedback testing, begin with Polling Stock, Thermal Stock, ZRAM disabled, LMKD Stock, Emerald Hill Adaptive, page-cluster Stock and Logging Silent, then enable one optional feature at a time under comparable ambient/charging/screen/radio conditions.

## Safety boundaries

- Unknown or unsupported platforms fail closed for Thermal changes.
- Experimental Pixel 9 / 9a / 10a / 11 targets use the stricter conservative vNext policy.
- Pixel 11 development targets keep Stock Thermal polling until runtime evidence explicitly admits a faster polling policy.
- Pixel 11 Outdoor changes target only exact `VIRTUAL-SKIN`; emergency, derivative/model/charging and `OVER-35C` sensors are not included in the initial Outdoor allowlist.
- pTune conflict protection remains authoritative; coexistence override is unavailable on experimental targets.
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

Published Alpha5 and the current vNext development line consume the shared **[Android Root Module Standalone WebUI Template](https://github.com/Lycidias93/android-root-module-webui-template)** maintained by Lycidias93, using WebUI Core `0.6.1`. Current vNext development pins the post-Alpha5 mobile-input fix at template commit `e7aa23ebb36be9b9075c66693d045a19413af8b1`; this pin change requires a fresh candidate/device WebUI audit before release acceptance.

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
