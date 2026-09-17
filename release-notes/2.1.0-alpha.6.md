# Pixel Thermal & Memory Control 2.1.0-alpha.6

This is a **public vNext prerelease**. Stable users can remain on 2.0.4; use Alpha6 if you intentionally want the newer device support, WebUI fixes and guarded vNext controls.

## New in 2.1.0-alpha.6

- **Experimental Pixel 11-series support is now included** for Pixel 11, Pixel 11 Pro, Pixel 11 Pro XL and Pixel 11 Pro Fold on Android 17. The module follows each device's stock Thermal include graph instead of assuming the older fixed file layout.
- **Pixel 11 Thermal tuning remains deliberately conservative.** Polling stays Stock-only, Outdoor Safe is capped at +1 °C where admitted, pTune Thermal coexistence override remains blocked, and firmware transitions require reinstall while this support is experimental.
- **Magisk Action no longer loses the standalone WebUI when the Action shell exits.** The loopback server remains alive for the browser session, fixing the immediate `ERR_CONNECTION_REFUSED` failure seen after opening the Action WebUI.
- **Stale `skip_mount` state is recovered safely.** Action rematerializes and validates the intended Thermal/Polling layout instead of leaving a valid requested state pending behind an old marker.
- **Pixel 11 memory-control feedback is incorporated.** An explicitly selected ZRAM page-cluster `0` state is preserved for guarded reapplication after verified boot.
- **WebUI usability is improved** with Silent/Verbose logging controls and mobile input handling that keeps confirmation fields visible above the Android software keyboard.

## Pixel 11 support

| Device | Codename | Current Alpha6 policy |
| --- | --- | --- |
| Pixel 11 | `cubs` | Experimental · Stock polling · Outdoor Safe up to +1 °C |
| Pixel 11 Pro | `grizzly` | Experimental · Stock polling · Outdoor Safe up to +1 °C |
| Pixel 11 Pro XL | `kodiak` | Experimental · Stock polling · Outdoor Safe up to +1 °C |
| Pixel 11 Pro Fold | `yogi` | Experimental · Stock polling · Outdoor Safe up to +1 °C |

## Compatibility and safety

- Alpha6 keeps the existing Android 17 vNext support for Pixel 10 / 10a and Pixel 9 / 9a families while adding the experimental Pixel 11 line above.
- Pixel 11 faster polling is **not** enabled in this prerelease. Stock polling remains the admitted policy.
- Pixel 11 Outdoor changes target only the admitted exact skin sensor path; derivative/model/charging and emergency-related Thermal sensors are not broadened by this release.
- Experimental LMKD 1%, Emerald Hill max lock and ZRAM page-cluster 0 remain opt-in and require explicit confirmation.
- The WebUI remains loopback-only and uses the same guarded control surface for standalone browser and embedded KsuWebUI launch paths.
- Stable and prerelease update channels remain separate.

## Updating

Users already on the prerelease channel can update through the normal module update flow after the prerelease channel metadata is promoted. A reboot is required after flashing before judging the new runtime state.

## Credits

- **Harish / Codecity001** — Pixel testing, Tensor G6/Pixel 11 feedback and continued review of the Thermal and memory-control paths.
- **Allen Chang** — Canary/device evidence and Thermal-profile feedback.
- **marx161** — original project foundation and earlier module work.
- **Lycidias93** — integration, validation and release maintenance.
- Shared WebUI foundation: **[Android Root Module Standalone WebUI Template](https://github.com/Lycidias93/android-root-module-webui-template)**.
