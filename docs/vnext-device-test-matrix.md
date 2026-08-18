# vNext 2.1 device validation matrix

This matrix tracks the evidence level for the single vNext Android 17 device-expansion line. Pixel 10, Pixel 10a and Pixel 9-series targets are carried by the same module and the same canonical vNext branch: `vnext-2.1.0-alpha.4`.

It deliberately separates platform admission, real stock-layout evidence and post-reboot runtime verification.

## Evidence states

- `platform_admitted`: the device/codename may enter local stock validation, but no device-specific stock or runtime proof is implied.
- `layout_evidenced`: a real-device support snapshot established the controlled Thermal layout and source inventory.
- `runtime_verified`: install, reboot, Bootguard and active overlay/runtime checks passed on the stated device/build/root combination.

Community tester reports that do not include the required post-boot readiness/runtime package are recorded separately and do not automatically promote a device to `runtime_verified`.

## Current matrix

| Device | Codename | Android | Evidence state | Controlled layout | Runtime/source evidence | Outdoor cap | pTune policy | Next proof |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Pixel 10 Pro XL | `mustang` | 17 | `runtime_verified` alpha.4-dev.1 | `base + charge + throttling` | Corrected Alpha4 dev.1 package passed reinstall → reboot → WebUI self-test/API → Bootguard → Thermal → ZRAM → LMKD → support snapshot on `CP2A.260805.005`; final failures 0, warnings 0 | +3 C | guarded override available | Keep as byte/runtime regression gate for Alpha4 prerelease packaging |
| Pixel 10 Pro | `blazer` | 17 | `platform_admitted` + existing Pixel 10 corpus | `base + charge + throttling` expected/locally validated | Existing Dynamic V2 build registrations; no Alpha4 device run claimed here | +3 C after normal local validation | guarded override available | Alpha4 install/reboot evidence on a real device |
| Pixel 10 | `frankel` | 17 | `platform_admitted` + existing Pixel 10 corpus | `base + charge + throttling` expected/locally validated | Existing Dynamic V2 build registrations; no Alpha4 device run claimed here | +3 C after normal local validation | guarded override available | Alpha4 install/reboot evidence on a real device |
| Pixel 10 Pro Fold | `rango` | 17 | `platform_admitted` + existing Pixel 10 corpus | `base + charge + throttling` expected/locally validated | Existing Dynamic V2 build registrations; no Alpha4 device run claimed here | +3 C after normal local validation | guarded override available | Alpha4 install/reboot evidence on a real device |
| Pixel 10a | `stallion` | 17 | `layout_evidenced` + tester-reported alpha.2 pass | `base + charge + lpm` | Allen Chang support snapshot on `ZP11.260717.006`; 37 stock `PollingDelay=300000` values (23 + 11 + 3). Public alpha.2 also reported working on August Canary with WildKSU + HybridMount, but without the complete post-boot evidence package | +1 C | blocked on experimental target | Post-boot Support Snapshot + readiness/runtime evidence |
| Pixel 9 | `tokay` | 17 | `platform_admitted` | local detection required | Pending | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |
| Pixel 9 Pro | `caiman` | 17 | `platform_admitted` | local detection required | Pending | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |
| Pixel 9 Pro XL | `komodo` | 17 | `platform_admitted` | local detection required | `CP2A.260805.005` is registered in the build map; no runtime-verification claim is made from registration alone | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |
| Pixel 9 Pro Fold | `comet` | 17 | `platform_admitted` | local detection required | Pending | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |
| Pixel 9a | `tegu` | 17 | `platform_admitted` | local detection required | Pending | +1 C | blocked on experimental target | Stock layout + install/reboot evidence |

## Alpha4 Mustang device gate

The corrected Alpha4 dev.1 runtime package completed the final repository-owned device gate on Pixel 10 Pro XL / `mustang`, Android 17 build `CP2A.260805.005`:

1. corrected package reinstall PASS with fail-closed WebUI executable-permission checks;
2. reboot consumed `modules_update` and activated `2.1.0-alpha.4-dev.1` / versionCode `1016253`;
3. WebUI runtime hashes and executable permissions matched the corrected package;
4. standalone WebUI server self-test PASS in 4 seconds;
5. typed status/capabilities API PASS with loopback-only and no arbitrary-shell bridge;
6. Bootguard and vNext readiness PASS;
7. Dynamic Thermal validation PASS with 22/22 polling replacements and active vendor match;
8. ZRAM 100% PASS on `/dev/block/zram0`, disksize `16331833344`, `lz77eh` active;
9. LMKD experimental 1% PASS with current-boot evidence, `magisk_resetprop` writer and running service;
10. Support Snapshot PASS with SHA-256 `a9c9bd7214fa0591bf27f6524b690d3e0e6bf2f59f1dbae18b017d1e09df7158`;
11. final verifier completed with `failure_count=0`, `warning_count=0`, `evidence_collection=complete`;
12. final marker: `RESULT: PIXEL_THERMAL_ALPHA4_FINAL_VERIFY_PASS workflow_exit_code=0`.

Corrected device-tested package SHA-256:

`7d40f28ffdc16f422e3aede08200b6e82297cd0144a6c9dea59cdf0860d7f2a9`

The detailed two-root-cause WebUI history and final evidence are recorded in `docs/evidence/alpha4-webui-device-verification-20260817.md`.

## Previous Alpha.3 Mustang device gate

Alpha.3 previously passed the complete baseline → real Action ZRAM disable → post-disable → real re-enable → post-reenable sequence on Mustang. That historical evidence remains useful for ZRAM/LMKD regression comparison, but Alpha4 dev.1 is now the current runtime-verified Mustang line.

Historical clean Alpha.3 package SHA-256:

`31a3679ba90fc1ea6b4d2267e5ef9b2dfed9c725399a7744bc7b56df04ac8583`

## Pixel 10a field evidence

Pixel 10a remains deliberately below `runtime_verified`. Its real support snapshot established the `base + charge + lpm` source layout, and a public alpha.2 tester report established successful installation/use on an August Canary build with WildKSU + HybridMount. The report did not include the full Support Snapshot/readiness/post-boot evidence contract required for promotion.

## Promotion rule

Experimental Pixel 9 / Pixel 10a targets remain capped at Stock / Outdoor Safe +1 C in the current vNext line. A local materialization pass, build-map entry or tester success report alone is not enough to widen that cap. Higher profiles require explicit device runtime evidence and a later reviewed policy change.

The module writes `guard/support-readiness.env` at install time and refreshes it after boot. `runtime_verified` is only claimed when the active Dynamic overlay and boot/runtime contract are actually verified.
