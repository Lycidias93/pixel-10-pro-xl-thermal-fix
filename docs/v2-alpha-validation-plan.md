# V2 Alpha validation plan

Status date: `2026-07-23`.

Public line: `1.5.2-universal-v2-alpha.1`.

Prepared unpublished package basis: `2.0.0-alpha.2` / versionCode `1016211`.

This is the living validation status after the public Alpha 1 release. Tagged release notes remain the historical record of what was known at release time and are not rewritten.

## Confirmed V2 runtime PASS

| Device | Build evidence | Base mode | Source |
|---|---|---|---|
| Pixel 10 Pro XL (`mustang`) | Android 17 / `CP2A.260705.006` / incremental `15641320` | Public Alpha 1 ZIP, Stock Thermal, Polling Mod, pTune disabled, module ZRAM disabled | Public asset reinstall and reboot; three active vendor files matched; 22 active `PollingDelay` values were `5000`; Bootguard last-good PASS; debug ZIP SHA-256 `e7a4ff853bbc7f31b6d406286b32ec9a30eac91fbdf7d8964a788417b77a7d1b` |
| Pixel 10 Pro (`blazer`) | Android 17 stable; exact build ID still to attach | Community runtime PASS | Harish / Codecity001 confirmation |

Mustang subsequently passed the staged Outdoor Safe, Outdoor Plus, Outdoor Extended, and separate ZRAM 100p validation sequence. These results support Alpha 2 preparation but do not replace a fresh install and reboot test of the exact final `2.0.0-alpha.2` ZIP.

The missing exact Blazer build ID and debug bundle remain evidence-hardening follow-up. They do not revoke the confirmed community PASS.

## Alpha 1 disable incident

Mustang later showed the installed public Alpha 1 with both `disable` and `skip_mount`. The marker timestamp preceded the relevant Boot-Watch reports, so those reports observed the disabled state rather than proving that Boot-Watch created it.

Bootguard was configured with threshold `1`. The V2 intent reserved that minimum for Canary/ZP diagnostics, but the shared helper accepted it for normal installs as well. Alpha 2 restores a normal minimum of `2` and keeps minimum `1` only for `CANARY_DIAGNOSTIC_MODE=1`.

This proves an over-sensitive self-disable path. It does not prove that Polling Mod caused the interrupted boot.

## Current Alpha 2 preparation state

The working branch now includes:

- Android 17-only V2 support declaration with unknown device/build fail-closed behavior;
- Polling Mod and ZRAM 100p as fresh-install defaults;
- corrected prerelease classification;
- Bootguard threshold policy and pTune install-state observability fixes;
- validated install and Action rematerialization wrappers;
- exact Outdoor threshold checks for Stock `+0`, Safe `+1`, Plus `+2`, and Extended `+3`;
- exact preservation of quoted `"NAN"` threshold sentinels while numeric values alone receive the requested delta;
- target-array accounting aligned to the dynamic patcher's real scope instead of requiring every repeated target label to contain a threshold array;
- rollback when validated target arrays are malformed, missing, reordered, or changed unexpectedly;
- combined policy, Bootguard, pTune, Outdoor fixture, syntax, and candidate guards passing.

The external verification run ended with `rc=128` only after all module guards had passed, because its final display step referenced a missing local `origin/v2` remote-tracking ref. This was a verifier presentation defect, not a module or guard failure.

The first exact `2.0.0-alpha.2` package attempt used versionCode `1016210`. It reached real Mustang Stock thermal materialization but the initial exact-delta validator rejected legitimate production structure and quoted `"NAN"` values. Magisk did not stage the module. The outer installer reported failure and restored the complete pre-install module and configuration snapshot. The corrected package basis is versionCode `1016211`.

## Immediate execution order

1. Run the corrected branch and fixture guards at the exact current branch head.
2. Exercise Stock, Safe, Plus, and Extended through the corrected validated wrapper against the real Mustang build-keyed stock cache in a private read-only workspace.
3. Build a reproducible `2.0.0-alpha.2` / `1016211` ZIP from the verified branch and record its SHA-256.
4. Install the exact ZIP on Mustang with Polling Mod, Stock Outdoor, and ZRAM 100p; keep pTune disabled or absent and avoid unrelated boot-image changes.
5. Perform one controlled reboot and verify Bootguard, module markers, active overlay values, exact Outdoor validation report, ZRAM runtime size/properties, Termux startup, and thermal crash state.
6. Exercise Outdoor Safe, Plus, and Extended through the installed Action path and confirm each report remains exact and rollback-safe.
7. Attach the exact Blazer build ID and, when available, its runtime/debug summary.
8. Collect frankel and rango runtime evidence on exact supported builds.
9. Test Canary/ZP only with an exact supported build and a confirmed recovery path.
10. Only after the exact package passes, update `update-prerelease.json`, create the GitHub prerelease, upload the verified ZIP, and publish the matching tag in a separate explicit release operation.

Do not combine pTune activation, KPatch, another boot-image change, or unsupported device/build activation with the first corrected exact-package test.

## Alpha 2 required fixes

Alpha 2 is required before Beta 1 for the following corrected defects and release-readiness gaps:

1. `install-state.txt` reported `conflict_guard_mode=override_allow_mount_with_ptune` whenever pTune was merely installed, even when it was disabled and no override was active.
2. Bootguard minimum threshold `1`, intended for Canary/ZP diagnostics, was accepted globally and could self-disable a normal build after one unresolved pending boot.
3. Prerelease display recognized only the old `test` pattern.
4. The support declaration included Android 16 despite the verified V2 Alpha matrix being Android 17.
5. Outdoor generation allowed the expected diff class but did not independently prove exact target-array counts and `+0/+1/+2/+3` values.
6. The first exact-delta implementation assumed every repeated target label had one numeric-only threshold array; real Mustang files include legitimate unpaired target labels and quoted `"NAN"` sentinels.

The current branch addresses all six in code and guards. The sixth fix still needs the real-cache read-only matrix and corrected package runtime proof.

## Alpha 2 versus Beta 1 decision

Create **Alpha 2** after the corrected exact package passes its Mustang install/reboot/runtime verification.

Proceed to **Beta 1** only when all of the following are true:

- Mustang and Blazer base thermal paths remain runtime PASS;
- the exact public Alpha 2 ZIP passes controlled Mustang install and reboot without unexplained disable;
- the intended V2 Outdoor path is runtime-verified through the installed Alpha 2 Action flow;
- ZRAM 100p is verified as the Alpha 2 fresh default;
- Bootguard shows no regression or unexplained disable;
- Blazer evidence is normalized with exact build metadata;
- pTune install-state observability remains corrected and regression-tested;
- no other blocking defect requires another Alpha package.

## Stable gate

Before promotion to stable:

- frankel and rango each need runtime evidence, or they must be removed from the stable supported claims;
- Canary/ZP stays excluded unless its exact build and recovery-backed runtime path pass;
- pTune coexistence remains opt-in risk and is not implied by base PASS;
- stable `update.json` changes only in a separate release operation after final package verification.

## Non-goals for the current Alpha cycle

- WebUI;
- automatic ZIP download or unattended installation;
- thermal safety disablement;
- unsupported device/build activation;
- widening the dynamic patch scope beyond base, charge, and throttling without new evidence.
