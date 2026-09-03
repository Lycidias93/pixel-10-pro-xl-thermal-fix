# vNext 2.1 device validation matrix

This matrix tracks the evidence level for the Android 17 vNext device-expansion line. Pixel 10, Pixel 10a, Pixel 9-series and the experimental Pixel 11-series targets are carried by the same module line.

It deliberately separates platform admission, real stock-layout evidence and post-reboot runtime verification.

## Evidence states

- `platform_admitted`: the device/codename may enter local stock validation, but no device-specific stock or runtime proof is implied.
- `layout_evidenced`: a real-device support snapshot or stock export established the Thermal layout and source inventory.
- `runtime_verified`: install, reboot, Bootguard and active overlay/runtime checks passed on the stated device/build/root combination.

Community tester reports that do not include the required post-boot readiness/runtime package are recorded separately and do not automatically promote a device to `runtime_verified`.

## Current matrix

| Device | Codename | Android | Evidence state | Controlled layout | Runtime/source evidence | Polling policy | Outdoor cap | pTune policy | Next proof |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Pixel 10 Pro XL | `mustang` | 17 | `runtime_verified` | `base + charge + throttling` | Corrected Alpha4 dev.1 package passed reinstall → reboot → WebUI self-test/API → Bootguard → Thermal → ZRAM → LMKD → support snapshot on `CP2A.260805.005`; final failures 0, warnings 0 | Stock or module 5 s | +3 C | guarded override available | Keep as byte/runtime regression gate |
| Pixel 10 Pro | `blazer` | 17 | `platform_admitted` + existing Pixel 10 corpus | `base + charge + throttling` expected/locally validated | Existing Dynamic V2 build registrations | Stock or module 5 s | +3 C after normal local validation | guarded override available | Current vNext install/reboot evidence |
| Pixel 10 | `frankel` | 17 | `platform_admitted` + existing Pixel 10 corpus | `base + charge + throttling` expected/locally validated | Existing Dynamic V2 build registrations | Stock or module 5 s | +3 C after normal local validation | guarded override available | Current vNext install/reboot evidence |
| Pixel 10 Pro Fold | `rango` | 17 | `platform_admitted` + existing Pixel 10 corpus | `base + charge + throttling` expected/locally validated | Existing Dynamic V2 build registrations | Stock or module 5 s | +3 C after normal local validation | guarded override available | Current vNext install/reboot evidence |
| Pixel 10a | `stallion` | 17 | `layout_evidenced` + tester-reported alpha.2 pass | `base + charge + lpm` | Allen Chang support snapshot on `ZP11.260717.006`; 37 stock `PollingDelay=300000` values. Public alpha.2 also reported working on August Canary with WildKSU + HybridMount, without the complete post-boot evidence package | Stock or module 5 s | +1 C | blocked on experimental target | Post-boot Support Snapshot + readiness/runtime evidence |
| Pixel 9 | `tokay` | 17 | `platform_admitted` | local detection required | Pending | Stock or module 5 s | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |
| Pixel 9 Pro | `caiman` | 17 | `platform_admitted` | local detection required | Pending | Stock or module 5 s | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |
| Pixel 9 Pro XL | `komodo` | 17 | `platform_admitted` | local detection required | `CP2A.260805.005` registered; registration alone is not runtime verification | Stock or module 5 s | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |
| Pixel 9 Pro Fold | `comet` | 17 | `platform_admitted` | local detection required | Pending | Stock or module 5 s | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |
| Pixel 9a | `tegu` | 17 | `platform_admitted` | local detection required | Pending | Stock or module 5 s | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |
| Pixel 11 | `cubs` | 17 | `platform_admitted` | bounded Include graph from `thermal_info_config.json` | No device-specific stock export/runtime package yet | **Stock only** pending runtime evidence | +1 C, exact `VIRTUAL-SKIN` only | blocked on experimental target | Stock graph + install/reboot + runtime package |
| Pixel 11 Pro | `grizzly` | 17 | `layout_evidenced`, runtime pending | bounded Include graph from `thermal_info_config.json` | Harish stock Thermal archive: 10 `thermal_info_config*.json` files plus `thermal_powerbudgets.json`; 35/35 `PollingDelay=300000`; no legacy `thermal_info_config_throttling.json`; archive SHA-256 `3445fe4d45c69e5be40ab331bbaf3fd3047a3bab5eff17a1dfda9a7b6690c7ca`. Exact build ID was not present. Tester later confirmed module mounting after correcting the root/kernel mount setup, but also reported an unisolated battery-temperature difference and feedback issues that changed the candidate afterward. | **Stock only** pending runtime evidence | +1 C, exact `VIRTUAL-SKIN` only | blocked on experimental target | New exact-head install → reboot → Bootguard/readiness → matched heat baseline → WebUI/page-cluster checks → Support Snapshot |
| Pixel 11 Pro XL | `kodiak` | 17 | `platform_admitted` | bounded Include graph from `thermal_info_config.json` | No device-specific stock export/runtime package yet | **Stock only** pending runtime evidence | +1 C, exact `VIRTUAL-SKIN` only | blocked on experimental target | Stock graph + install/reboot + runtime package |
| Pixel 11 Pro Fold | `yogi` | 17 | `platform_admitted` | bounded Include graph from `thermal_info_config.json` | No device-specific stock export/runtime package yet | **Stock only** pending runtime evidence | +1 C, exact `VIRTUAL-SKIN` only | blocked on experimental target | Stock graph + install/reboot + runtime package |

## Pixel 11 initial safety envelope

Pixel 11 support does not reuse the old three-file assumption. The vNext materializer resolves a bounded Include closure rooted at `thermal_info_config.json`, accepts only known Thermal-config basenames under the local vendor Thermal directory, rejects missing includes and cycles, hashes/caches every controlled source file, and validates that only admitted bytes changed.

The initial Tensor G6 policy is deliberately narrower than Pixel 9/10:

1. stock Thermal polling is mandatory; `300000 → 5000` remains blocked until real-device runtime evidence exists;
2. Outdoor Safe is capped at `+1 C` and may change only the exact `VIRTUAL-SKIN` sensor;
3. `cellular-emergency`, `VIRTUAL-SKIN-*` derivative/model/charging sensors and `OVER-35C` sensors are not Outdoor targets on Pixel 11;
4. pTune coexistence override is blocked;
5. automatic OTA profile switching is disabled and firmware transitions require reinstall while Pixel 11 remains experimental;
6. local graph/materialization validation is not a runtime-verification claim.

The Pixel 11 Pro source archive is sufficient to establish the new graph layout and the continued 300-second stock polling behavior. It is not sufficient to claim that an exact module head has booted safely on hardware.

## 2026-09-03 tester-feedback retest boundary

Harish reported four behavior/UX issues after the first Pixel 11 candidate: `page-cluster=0` did not survive reboot, the WebUI lacked a Silent/Verbose logging control, the Android keyboard could cover the confirmation field, and the ZIP contained a duplicate ZRAM fstab path. He also reported that battery temperature appeared to remain around 36 C longer with the module installed.

The follow-up code changes the page-cluster post-boot path and the pinned WebUI Core, so any runtime acceptance of the earlier PR #192 candidate is invalid for final integration. The duplicate fstab was package hygiene debt but only 74 bytes; measured candidate size remains dominated by the standalone WebUI server rather than duplicate text files.

The temperature observation remains `reported_unisolated`: the earlier candidate preserved Pixel 11 stock Thermal polling, while optional ZRAM, LMKD and verbose debug settings could also be active. Final device testing starts from Polling Stock + Thermal Stock + ZRAM disabled + LMKD Stock + Emerald Hill Adaptive + page-cluster Stock + Logging Silent, then changes one optional feature at a time under comparable conditions.

## Existing Mustang runtime gate

The corrected Alpha4 dev.1 runtime package completed the final repository-owned device gate on Pixel 10 Pro XL / `mustang`, Android 17 build `CP2A.260805.005`: reinstall, reboot, WebUI runtime/API, Bootguard, Dynamic Thermal validation, ZRAM, LMKD and Support Snapshot all passed with zero final failures/warnings. That historical evidence remains the stable Pixel 10 regression anchor; it does not promote newly added Pixel 11 targets.

## Promotion rule

Experimental Pixel 9 / Pixel 10a / Pixel 11 targets remain capped at Stock / Outdoor Safe +1 C. Pixel 11 additionally remains Stock-polling-only. A local materialization pass, build-map entry, static stock archive or tester success report alone is not enough to widen those limits. Higher Thermal profiles or Pixel 11 5-second polling require explicit device runtime evidence and a later reviewed policy change.

The module writes `guard/support-readiness.env` at install time and refreshes it after boot. `runtime_verified` is only claimed when the active Dynamic overlay and boot/runtime contract are actually verified.
