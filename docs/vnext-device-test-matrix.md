# vNext 2.1 device validation matrix

This matrix tracks the evidence level for the vNext Android 17 device expansion. It deliberately separates platform admission, stock-layout evidence and post-reboot runtime verification.

## Evidence states

- `platform_admitted`: device/codename is allowed to enter local stock validation, but no device-specific stock or runtime proof is implied.
- `layout_evidenced`: a real-device support snapshot established the controlled Thermal layout and source inventory.
- `runtime_verified`: install, reboot, Bootguard and active overlay/runtime checks passed on the stated device/build/root combination.

## Current matrix

| Device | Codename | Android | Evidence state | Controlled layout | Known source evidence | Runtime evidence | Outdoor cap | pTune policy | Next proof |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Pixel 10 Pro XL | `mustang` | 17 | `runtime_verified` baseline | `base + charge + throttling` | Existing Dynamic V2 Pixel 10 stock/runtime corpus | August Stable `CP2A.260805.005` runtime regression plus existing 2.0.1 baseline evidence | +3 C | guarded override available | Keep as regression gate for vNext changes |
| Pixel 10a | `stallion` | 17 | `layout_evidenced` | `base + charge + lpm` | Allen Chang support snapshot on `ZP11.260717.006`; 37 stock `PollingDelay=300000` values across selected files (23 + 11 + 3) | Pending | +1 C | blocked on experimental target | Install alpha, reboot, send Support Snapshot and P/T/Z/L/runtime verification |
| Pixel 9 | `tokay` | 17 | `platform_admitted` | local detection required | Pending | Pending | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |
| Pixel 9 Pro | `caiman` | 17 | `platform_admitted` | local detection required | Pending | Pending | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |
| Pixel 9 Pro XL | `komodo` | 17 | `platform_admitted` | local detection required | Pending | Pending | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |
| Pixel 9 Pro Fold | `comet` | 17 | `platform_admitted` | local detection required | Pending | Pending | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |
| Pixel 9a | `tegu` | 17 | `platform_admitted` | local detection required | Pending | Pending | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |

## Promotion rule

Experimental Pixel 9 / Pixel 10a targets remain capped at Stock / Outdoor Safe +1 C in this prerelease. A local materialization pass is not enough to widen that cap. Higher profiles require explicit device runtime evidence and a later policy change.

The module writes `guard/support-readiness.env` at install time and refreshes it after boot. `runtime_verified` is only reported when the active Dynamic overlay is verified by the compatibility/runtime contract; otherwise the readiness state remains pending or requires attention.

Pixel 9 devices are not exact-verified merely because their codenames are admitted. Pixel 10a currently has layout evidence, not post-reboot Thermal runtime verification.
