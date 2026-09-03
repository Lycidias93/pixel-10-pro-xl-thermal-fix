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
| Pixel 11 | `cubs` | 17 | `platform_admitted` | bounded Include graph from `thermal_info_config.json` | No device-specific stock export/runtime package yet | **Stock only** | +1 C, exact `VIRTUAL-SKIN` only | blocked on experimental target | Stock graph + install/reboot + runtime package |
| Pixel 11 Pro | `grizzly` | 17 | `runtime_verified` | bounded Include graph from `thermal_info_config.json` | Harish stock archive established the 10-file Thermal graph plus standalone `thermal_powerbudgets.json` and 35/35 stock `PollingDelay=300000` values. Exact PR #194 candidate SHA-256 `461b150d6ebfc59dbb905fb0f29070c010a938a4b23dd490210e65a7ef83ff3f` then passed on `CD1A.260714.001.A9`: module active, no disable/skip_mount/remove flags, Bootguard `full_pass`, readiness `runtime_verified`, active 10-file G6 overlay validated, 35/35 `300000` preserved and 0 `5000`. Final support bundle SHA-256 `8499968ceebfa12915b4ba01574114945484972482297e14e82df42e060e895d` also records ZRAM active and persisted `page-cluster=0` reconciled after verified boot; WebUI Silent/Verbose and mobile-input fixes were tester-confirmed. | **Stock only**; runtime acceptance does not widen polling | +1 C, exact `VIRTUAL-SKIN` only | blocked on experimental target | Run the read-only G6 polling inventory against the accepted stock cache and bind all 35 delays to exact sensor objects before selecting any tiny experimental faster-polling allowlist; that later runtime change requires a separate exact-head hardware test |
| Pixel 11 Pro XL | `kodiak` | 17 | `platform_admitted` | bounded Include graph from `thermal_info_config.json` | No device-specific stock export/runtime package yet | **Stock only** | +1 C, exact `VIRTUAL-SKIN` only | blocked on experimental target | Stock graph + install/reboot + runtime package |
| Pixel 11 Pro Fold | `yogi` | 17 | `platform_admitted` | bounded Include graph from `thermal_info_config.json` | No device-specific stock export/runtime package yet | **Stock only** | +1 C, exact `VIRTUAL-SKIN` only | blocked on experimental target | Stock graph + install/reboot + runtime package |

## Pixel 11 initial safety envelope

Pixel 11 support does not reuse the old three-file assumption. The vNext materializer resolves a bounded Include closure rooted at `thermal_info_config.json`, accepts only known Thermal-config basenames under the local vendor Thermal directory, rejects missing includes and cycles, hashes/caches every controlled source file, and validates that only admitted bytes changed.

The initial Tensor G6 policy is deliberately narrower than Pixel 9/10:

1. stock Thermal polling is mandatory; `300000 → 5000` remains blocked. The `grizzly` runtime pass verifies the Stock-only implementation but does not itself admit faster polling;
2. Outdoor Safe is capped at `+1 C` and may change only the exact `VIRTUAL-SKIN` sensor;
3. `cellular-emergency`, `VIRTUAL-SKIN-*` derivative/model/charging sensors and `OVER-35C` sensors are not Outdoor targets on Pixel 11;
4. pTune coexistence override is blocked;
5. automatic OTA profile switching is disabled and firmware transitions require reinstall while Pixel 11 remains experimental;
6. local graph/materialization validation is not a runtime-verification claim.

The Pixel 11 Pro source archive established the new graph layout and the continued 300-second stock polling behavior. Runtime acceptance is tracked separately and is now complete for the exact PR #194 candidate on `grizzly` / build `CD1A.260714.001.A9`.

## Selective G6 polling evidence gate

Before any Pixel 11 faster-polling policy is implemented, `tools/debug/g6-polling-inventory.sh` provides a read-only object-level inventory from the module's cached stock G6 Include graph. It reports the source file, nearest enclosing sensor `Name`, exact `PollingDelay`, and a coarse review classification for every polling entry. Every row remains `blocked_pending_review`; the diagnostic does not change stock files, module configuration, the active overlay, or runtime state.

The inventory fails closed when the device is not Tensor G6, the stock cache/layout cannot be resolved, no polling entries are present, or any `PollingDelay` cannot be mapped to a sensor object. The classification is review context only, not an allowlist: `direct_virtual_skin`, `safety_or_protection`, `derived_or_model`, and `unclassified` all remain blocked until the exact object map is reviewed together with runtime behavior.

A future faster-polling experiment must therefore start from the exact inventory, select the smallest justified object allowlist, keep all non-selected and safety/protection objects at stock cadence, and repeat exact-head `grizzly` installation/reboot/Bootguard/readiness/Thermal verification. Merely unblocking the existing global `mod` path is not an accepted Tensor G6 implementation because that path would otherwise replace every admitted stock `300000` occurrence.

## 2026-09-03 tester-feedback acceptance

Harish reported four behavior/UX issues after the first Pixel 11 candidate: `page-cluster=0` did not survive reboot, the WebUI lacked a Silent/Verbose logging control, the Android keyboard could cover the confirmation field, and the ZIP contained a duplicate ZRAM fstab path. He also reported that battery temperature appeared to remain around 36 C longer with the module installed.

The follow-up changed the page-cluster post-boot path and the pinned WebUI Core, so runtime acceptance of the earlier PR #192 candidate was invalidated. The clean PR #194 integration was rebuilt from the Alpha5 target, passed exact-head CI run `33711788431`, and produced candidate SHA-256 `461b150d6ebfc59dbb905fb0f29070c010a938a4b23dd490210e65a7ef83ff3f`.

Fresh Pixel 11 Pro hardware evidence on `grizzly` then closed the runtime gate: the module remained active after reboot with no disable/skip_mount/remove flags, Bootguard reported `full_pass`, readiness reached `runtime_verified`, the 10-file `include_graph_g6` overlay remained validated with Stock polling, and the final ZRAM test recorded `ZRAM_PAGE_CLUSTER_MODE=zero`, `RESULT: PAGE_CLUSTER_ZERO_PASS ... persistence=post_bootguard_reapply`, `RESULT: PAGE_CLUSTER_RECONCILE_PASS desired=zero action=applied`, and `SERVICE_PAGE_CLUSTER result=reconciled_after_verified_boot`. Harish directly confirmed the requested final check set worked and Codecity001 reviewed the integration as ready to proceed. PR #194 was merged into `vnext-2.1.0-alpha.5` as `4bf8d16dcf38f5eb7e87f19a97c1c388d51f34b6`.

The duplicate fstab was package hygiene debt but only 74 bytes; measured candidate size remains dominated by the standalone WebUI server rather than duplicate text files.

The temperature observation remains `reported_unisolated`: the accepted Pixel 11 candidate preserves stock Thermal polling, and the available captures do not provide a matched long-window A/B attribution. Any temperature investigation continues separately from this acceptance, starting with Polling Stock + Thermal Stock + ZRAM disabled + LMKD Stock + Emerald Hill Adaptive + page-cluster Stock + Logging Silent and changing one optional feature at a time under comparable conditions.

## Existing Mustang runtime gate

The corrected Alpha4 dev.1 runtime package completed the final repository-owned device gate on Pixel 10 Pro XL / `mustang`, Android 17 build `CP2A.260805.005`: reinstall, reboot, WebUI runtime/API, Bootguard, Dynamic Thermal validation, ZRAM, LMKD and Support Snapshot all passed with zero final failures/warnings. That historical evidence remains the stable Pixel 10 regression anchor; it does not promote newly added Pixel 11 targets.

## Promotion rule

Experimental Pixel 9 / Pixel 10a / Pixel 11 targets remain capped at Stock / Outdoor Safe +1 C. Pixel 11 additionally remains Stock-polling-only. A local materialization pass, build-map entry, static stock archive, tester success report, single-device Stock-policy runtime pass, or read-only polling inventory does not automatically widen those limits. Higher Thermal profiles or Pixel 11 faster polling require a reviewed object-level policy change plus targeted device evidence on the exact final candidate.

The module writes `guard/support-readiness.env` at install time and refreshes it after boot. `runtime_verified` is only claimed when the active Dynamic overlay and boot/runtime contract are actually verified.
