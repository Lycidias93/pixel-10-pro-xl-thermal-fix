# V2 Alpha validation plan

Status date: `2026-07-17`.

Public line: `1.5.2-universal-v2-alpha.1`.

This is the living validation status after the public Alpha 1 release. The tagged release notes remain the historical record of what was known at release time and are not rewritten.

## Confirmed V2 runtime PASS

| Device | Build evidence | Base mode | Source |
|---|---|---|---|
| Pixel 10 Pro XL (`mustang`) | Android 17 / `CP2A.260705.006` | Stock Thermal, Polling Mod, pTune off, module ZRAM off | Full install, reboot, active-vendor, PollingDelay, Magisk and Bootguard verification |
| Pixel 10 Pro (`blazer`) | Android 17 stable; exact build ID still to attach | Community runtime PASS | Harish / Codecity001 confirmation |

The missing exact Blazer build ID and debug bundle are evidence-hardening follow-up. They do not revoke the confirmed PASS.

## Immediate execution order

1. Attach the exact Blazer build ID and, when available, its runtime/debug summary.
2. Reinstall the public Alpha 1 asset on Mustang and repeat the base reboot/runtime check.
3. Validate V2 Outdoor Safe, Outdoor Plus and Outdoor Extended sequentially on Mustang, returning to Stock between tests when needed.
4. Test module ZRAM 100p separately only after the V2 thermal base path is green.
5. Collect frankel and rango runtime evidence on exact supported builds.
6. Test Canary/ZP only with an exact supported build and a confirmed recovery path.

Do not combine a new Outdoor profile, pTune coexistence and ZRAM 100p in the same first test. One variable per validation step keeps failures attributable.

## Alpha 2 versus Beta 1 decision

Create **Alpha 2** when any test requires a code, guard, installer, Action UX, compatibility-matrix or module-metadata change.

Proceed to **Beta 1** without an Alpha 2 only when all of the following are true:

- the public Alpha 1 ZIP is reproducible on Mustang after install and reboot;
- Mustang and Blazer base thermal paths remain runtime PASS;
- at least the intended V2 Outdoor path is runtime-verified on Mustang;
- ZRAM 100p is verified separately with the V2 thermal path;
- Bootguard shows no regression or unexplained disable;
- Blazer evidence is normalized with exact build metadata;
- no blocking defect requires a new Alpha package.

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
