# V2 Alpha validation plan

Status date: `2026-07-20`.

Public line: `1.5.2-universal-v2-alpha.1`.

Current internal candidate: `1.5.2-universal-v2-alpha.2-candidate.1`.

This is the living validation status after the public Alpha 1 release. The tagged release notes remain the historical record of what was known at release time and are not rewritten.

## Confirmed V2 runtime PASS

| Device | Build evidence | Base mode | Source |
|---|---|---|---|
| Pixel 10 Pro XL (`mustang`) | Android 17 / `CP2A.260705.006` / incremental `15641320` | Public Alpha 1 ZIP, Stock Thermal, Polling Mod, pTune disabled, module ZRAM disabled | Public asset reinstall and reboot; three active vendor files matched; 22 active `PollingDelay` values were `5000`; Bootguard last-good PASS; debug ZIP SHA-256 `e7a4ff853bbc7f31b6d406286b32ec9a30eac91fbdf7d8964a788417b77a7d1b` |
| Pixel 10 Pro (`blazer`) | Android 17 stable; exact build ID still to attach | Community runtime PASS | Harish / Codecity001 confirmation |

The missing exact Blazer build ID and debug bundle are evidence-hardening follow-up. They do not revoke the confirmed PASS.

## Alpha 1 disable incident

Mustang later showed the installed public Alpha 1 with both `disable` and `skip_mount`. The marker timestamp preceded the relevant Boot-Watch reports, so those reports observed the disabled state rather than proving that Boot-Watch created it.

Bootguard was configured with threshold `1`. The V2 intent reserved that minimum for Canary/ZP diagnostics, but the shared helper accepted it for normal installs as well. Candidate 1 restores a normal minimum of `2` and keeps minimum `1` only for `CANARY_DIAGNOSTIC_MODE=1`.

This proves an over-sensitive self-disable path. It does not prove that Polling Mod caused the interrupted boot. The installed Alpha 1 remains disabled until it is replaced by the controlled candidate install.

## Immediate execution order

1. Build and statically verify `1.5.2-universal-v2-alpha.2-candidate.1` from the exact merged V2 source.
2. Install Candidate 1 on Mustang with KPatch disabled, boot image unpatched, pTune installed-disabled, module ZRAM disabled, Stock Thermal and Polling Mod only.
3. Perform one controlled reboot and verify Bootguard, module markers, active overlay hashes, polling values and Termux startup.
4. Return to Stock before continuing Outdoor Safe, Outdoor Plus and Outdoor Extended validation.
5. Test module ZRAM 100p separately only after the V2 thermal profile path is green.
6. Attach the exact Blazer build ID and, when available, its runtime/debug summary.
7. Collect frankel and rango runtime evidence on exact supported builds.
8. Test Canary/ZP only with an exact supported build and a confirmed recovery path.

Do not combine a new Outdoor profile, pTune coexistence and ZRAM 100p in the same first test. One variable per validation step keeps failures attributable.

## Alpha 2 required fixes

Alpha 2 is required before Beta 1 for two corrected defects:

1. `install-state.txt` reported `conflict_guard_mode=override_allow_mount_with_ptune` whenever pTune was merely installed, even when it was disabled and no override was active. Runtime safety was not affected: the compat check correctly reported `PTUNE_ENABLED=no`, `ALLOW_THERMAL_WITH_PTUNE=0`, `RISK_ACK_VALID=no` and active overlay verification PASS.
2. The Bootguard minimum threshold of `1`, intended for Canary/ZP diagnostics, was accepted globally and could self-disable a normal build after one unresolved pending boot.

Candidate 1 now distinguishes at least: pTune absent, installed-disabled, active-blocked and active-explicit-override. Override marker files are written only for an actually active pTune path with explicit override.

## Alpha 2 versus Beta 1 decision

Create **Alpha 2** when any test requires a code, guard, installer, Action UX, compatibility-matrix or module-metadata change. The pTune observability and Bootguard threshold corrections satisfy this condition.

Proceed to **Beta 1** after Alpha 2 only when all of the following are true:

- the public Alpha 1 ZIP remains reproducible on Mustang after install and reboot;
- Mustang and Blazer base thermal paths remain runtime PASS;
- Candidate 1 passes the controlled Mustang install and reboot sequence without unexplained disable;
- the intended V2 Outdoor path is runtime-verified on Mustang;
- ZRAM 100p is verified separately with the V2 thermal path;
- Bootguard shows no regression or unexplained disable;
- Blazer evidence is normalized with exact build metadata;
- pTune install-state observability is corrected and regression-tested;
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
- widening the dynamic patch scope beyond base, charge and throttling without new evidence.
