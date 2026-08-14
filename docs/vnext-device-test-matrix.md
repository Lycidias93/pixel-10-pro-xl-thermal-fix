# vNext 2.1 device validation matrix

This matrix tracks the evidence level for the single vNext Android 17 device-expansion line. Pixel 10, Pixel 10a and Pixel 9-series targets are carried by the same module and the same canonical vNext branch: `vnext-2.1.0-alpha.3`.

It deliberately separates platform admission, real stock-layout evidence and post-reboot runtime verification.

## Evidence states

- `platform_admitted`: the device/codename may enter local stock validation, but no device-specific stock or runtime proof is implied.
- `layout_evidenced`: a real-device support snapshot established the controlled Thermal layout and source inventory.
- `runtime_verified`: install, reboot, Bootguard and active overlay/runtime checks passed on the stated device/build/root combination.

Community tester reports that do not include the required post-boot readiness/runtime package are recorded separately and do not automatically promote a device to `runtime_verified`.

## Current matrix

| Device | Codename | Android | Evidence state | Controlled layout | Runtime/source evidence | Outdoor cap | pTune policy | Next proof |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Pixel 10 Pro XL | `mustang` | 17 | `runtime_verified` alpha.3 | `base + charge + throttling` | Exact alpha.3 package content passed baseline → real Action disable → post-disable → real re-enable → post-reenable on `CP2A.260805.005`; final Support Snapshot PASS, failures 0, warnings 0 | +3 C | guarded override available | Keep as byte-identity regression gate for alpha.3 publication |
| Pixel 10 Pro | `blazer` | 17 | `platform_admitted` + existing Pixel 10 corpus | `base + charge + throttling` expected/locally validated | Existing Dynamic V2 build registrations; no alpha.3 device run claimed here | +3 C after normal local validation | guarded override available | Alpha.3 install/reboot evidence on a real device |
| Pixel 10 | `frankel` | 17 | `platform_admitted` + existing Pixel 10 corpus | `base + charge + throttling` expected/locally validated | Existing Dynamic V2 build registrations; no alpha.3 device run claimed here | +3 C after normal local validation | guarded override available | Alpha.3 install/reboot evidence on a real device |
| Pixel 10 Pro Fold | `rango` | 17 | `platform_admitted` + existing Pixel 10 corpus | `base + charge + throttling` expected/locally validated | Existing Dynamic V2 build registrations; no alpha.3 device run claimed here | +3 C after normal local validation | guarded override available | Alpha.3 install/reboot evidence on a real device |
| Pixel 10a | `stallion` | 17 | `layout_evidenced` + tester-reported alpha.2 pass | `base + charge + lpm` | Allen Chang support snapshot on `ZP11.260717.006`; 37 stock `PollingDelay=300000` values (23 + 11 + 3). Public alpha.2 also reported working on August Canary with WildKSU + HybridMount, but without the complete post-boot evidence package | +1 C | blocked on experimental target | Post-boot Support Snapshot + readiness/P/T/Z/L evidence |
| Pixel 9 | `tokay` | 17 | `platform_admitted` | local detection required | Pending | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |
| Pixel 9 Pro | `caiman` | 17 | `platform_admitted` | local detection required | Pending | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |
| Pixel 9 Pro XL | `komodo` | 17 | `platform_admitted` | local detection required | `CP2A.260805.005` is registered in the build map; no runtime-verification claim is made from registration alone | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |
| Pixel 9 Pro Fold | `comet` | 17 | `platform_admitted` | local detection required | Pending | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |
| Pixel 9a | `tegu` | 17 | `platform_admitted` | local detection required | Pending | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |

## Alpha.3 Mustang device gate

The exact alpha.3 runtime package content passed the complete repository-owned device sequence on Pixel 10 Pro XL / `mustang`, Android 17 build `CP2A.260805.005`:

1. exact-current-candidate baseline PASS;
2. real Magisk Action ZRAM disable without the historical `layout removal failed` / `Existing configuration kept` abort;
3. reboot and `post-disable` PASS with module ZRAM layout absent, stock ZRAM active and Memory Killer off;
4. real Action re-enable to ZRAM 100% adaptive + experimental LMKD 1%;
5. reboot and `post-reenable` PASS;
6. Support Snapshot PASS with `failure_count=0`, `warning_count=0` and `evidence_collection=complete`.

The clean alpha.3 CI is required to reproduce the same package SHA-256 before the source branch can be treated as publication-ready:

`31a3679ba90fc1ea6b4d2267e5ef9b2dfed9c725399a7744bc7b56df04ac8583`

That hash gate prevents documentation/branch cleanup from silently producing a different runtime package than the device-tested one.

## Pixel 10a field evidence

Pixel 10a remains deliberately below `runtime_verified`. Its real support snapshot established the `base + charge + lpm` source layout, and a public alpha.2 tester report established successful installation/use on an August Canary build with WildKSU + HybridMount. The report did not include the full Support Snapshot/readiness/post-boot evidence contract required for promotion.

## Promotion rule

Experimental Pixel 9 / Pixel 10a targets remain capped at Stock / Outdoor Safe +1 C in alpha.3. A local materialization pass, build-map entry or tester success report alone is not enough to widen that cap. Higher profiles require explicit device runtime evidence and a later reviewed policy change.

The module writes `guard/support-readiness.env` at install time and refreshes it after boot. `runtime_verified` is only claimed when the active Dynamic overlay and boot/runtime contract are actually verified.
