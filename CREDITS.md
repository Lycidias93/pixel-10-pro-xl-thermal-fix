# Credits

Pixel Thermal & Memory Control is maintained by **Lycidias93**, based on earlier work by **marx161**, with substantial testing, implementation feedback and technical input from community contributors.

## Alpha5 / current vNext line

- **Lycidias93** — integration, Dynamic V2 safety model, Mustang device verification, release maintenance, standalone/embedded WebUI consumer integration and fail-closed runtime/recovery behavior.
- **Harish / Codecity001** — extensive Pixel 10 Pro / `blazer` testing and logs; Dynamic V2 three-file patch-scope work; ZRAM, LMKD, Action/WebUI UX and installer feedback; PR #70 resetprop-rs / `boot_early` work; profile-layout direction and continued runtime review.
- **Allen Chang** — Canary/device screenshots, stock Thermal files, installation/failure evidence, profile feedback and runtime verification that helped harden Dynamic V2 admission and Outdoor handling.
- **JoshuaDoes / pTune** — original Emerald Hill and ZRAM technical concepts later safety-adapted by this module, including devfreq behavior, ZRAM timing and memory-control implementation guidance.
- **marx161** — original project foundation and earlier module work.

## Shared WebUI foundation used by Alpha5

Alpha5 consumes the first-party **[Android Root Module Standalone WebUI Template](https://github.com/Lycidias93/android-root-module-webui-template)** from `Lycidias93/android-root-module-webui-template`, pinned to:

- template commit `6fbd1b018a45fe5b1bebba7aeb9142423eab47fb`;
- WebUI Core `0.6.1`.

The shared core provides the standalone localhost browser transport, one-time bootstrap/session model, typed allowlisted API, capability-driven UI, bounded jobs/logs/inventory, action-state handling and the bounded embedded-host bootstrap used by compatible KsuWebUI hosts.

### Public upstream projects referenced by the shared WebUI core

#### Coolapk-Code9527 — F2FS-Optimizer

- Source: `Coolapk-Code9527/F2FS-Optimizer`
- Pinned source: `651b66b14087b5d60e4b9d3fd69de899a8cd43b8`
- Role: localhost lifecycle, Action launch, idle-timeout, temporary-state and atomic-configuration concepts.
- License: MIT.
- Integration boundary: clean reimplementation informed by upstream.

#### KOWX712 — ksu-webui-demo

- Source: `KOWX712/ksu-webui-demo`
- Pinned source: `5ff958423202e9af7675e83e8ce57a34d80ddcd9`
- Role: compact vanilla-JavaScript layout and root-module WebUI compatibility concepts.
- License: MIT.
- Integration boundary: clean reimplementation informed by upstream.

#### barsikus007 — ksu-webui-module-template

- Source: `barsikus007/ksu-webui-module-template`
- Pinned source: `4ec624e2514043064d3b50ff5ec585acff4ffc97`
- Role: packaging, multi-manager structure and template/CI concepts.
- License: MIT.
- Integration boundary: clean reimplementation informed by upstream.

#### AuroraNasa — AMMF2

- Source: `Aurora-Nasa-1/AMMF2`
- Pinned source: `98d2ef7d0491f6524cee09c958ef239338b49d3c`
- Role: logging, theme, localization and reusable-component reference concepts.
- License: MIT.
- Integration boundary: reference only in the shared-core provenance record.

#### Drizzy07x / Drizzy11 — Supercharger Pixel 9 Series

- Source: `Drizzy07x/Supercharger_Pixel_9_Series`
- Pinned source: `be76cbe57d01fa475196b7afb3729b9ad19f0a26`
- Role: WebUI readiness/busy-state handling, duplicate-action prevention, task-completion and stale/out-of-order response regression patterns.
- License: MIT.
- Integration boundary: clean generic adaptation; Supercharger Thermal profiles, Pixel 9 tuning, VM/network tweaks, IRQ masks, GPU floors, app optimizer, maintenance-domain logic and unrestricted root-manager JavaScript execution are not imported by this module.

#### AshBorn — AshReXcue / AshLooper

- Source: `RipperHybrid/AshLooper`
- Pinned source: `6db87ffba007560eff443a0330037cd6a2563c2b`
- Role: design-review inspiration for unsaved-change awareness, session activity diagnostics and raw-state inspection.
- License: GPL-3.0.
- Integration boundary: **design reference only**. No AshLooper/AshReXcue JavaScript, CSS, shell code, assets or other GPL-covered implementation is copied or imported into the MIT shared WebUI core or this module.

#### Adinata — KsuWebUI

- Source: `adivenxnataly/KsuWebUI`
- Pinned source: `20342d280a841f8b317603a7eefb1193a95ab626`
- Role: compatibility/design reference for the embedded root-module WebView host, including the `mui.kernelsu.org` asset origin, KernelSU-compatible JavaScript bridge and loopback-network environment.
- License: GPL-3.0.
- Integration boundary: **compatibility/design reference only**. No KsuWebUI Kotlin, Java, XML, JavaScript, assets or other GPL-covered implementation is copied or imported. The shared MIT core independently implements a bounded bootstrap-only handoff to its existing authenticated loopback server.

The shared template retains the relevant provenance and license notices in its `UPSTREAMS.md`, `NOTICE` and `third_party/licenses/` material. Upstream authors do not endorse this project.

## Pixel 9 Thermal-profile inspiration

Earlier Pixel 9 thermal-mod research also informed conservative Outdoor-profile analysis:

- **nokia5700black** — Pixel 9 Pro XL ThermalThrottling-mod inspiration.
- **JohnTheFarm3r** — Pixel 9 Pro XL thermal-throttling modifier inspiration.
- **Rana260492** — Pixel 9 Pro XL Android 15/16 thermal-throttling modifier inspiration.

Reference threads:

- https://xdaforums.com/t/mod-thermal-throttling-modifier-pixel-9-pro-xl.4690006/
- https://xdaforums.com/t/mod-throttling-mod-for-march-15-16-android-9-pro-xl.4735878/

The Pixel 10/9 vNext implementation does not copy the referenced mods' 5-minute polling delay, USB, charge, battery, speaker, shutdown or emergency changes. Their work was used as comparative inspiration while this module keeps its own guarded stock-derived policy.

## Earlier Dynamic V2 / Alpha 3 work

- **Harish / Codecity001** — real-world Pixel 10 Pro logging, installation/reboot/runtime testing, three-file Dynamic V2 patch scope, Action-dashboard optimization feedback, ZRAM and LMKD work, and profile-layout concepts.
- **Allen Chang** — Canary stock Thermal evidence and failure reports that helped move exact build IDs from a hard activation gate to evidence while retaining local stock validation.
- **JoshuaDoes / pTune** — Emerald Hill and ZRAM foundation concepts, later wrapped in this module's independent validation, restore and Bootguard boundaries.
- **Lycidias93** — Mustang install/reboot/active-vendor/Polling/ZRAM/LMKD verification, fail-closed integration and release binding.

## Earlier ZRAM / manager UX work

- **Harish / Codecity001** — install/runtime testing, ZRAM debug logs, Volume-key selection, Action UX recommendations and PR #65 log-cleanup/debug-gating work.
- **JoshuaDoes** — ZRAM 100% technical input, mmd restart/timing context and resetprop behavior guidance.
- **Allen Chang** — manager status / Action UX ideas, QPR testing, screenshots and runtime feedback.

## Attribution boundary

External projects are credited for the specific ideas, tests or implementation patterns described above. Where the shared WebUI core says “clean reimplementation” or “design reference only,” that boundary is intentional. Imported or redistributed license material remains governed by its original license; design inspiration is independently expressed in this project's implementation.
