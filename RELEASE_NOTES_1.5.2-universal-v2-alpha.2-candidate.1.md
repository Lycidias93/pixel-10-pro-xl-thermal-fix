# 1.5.2-universal-v2-alpha.2-candidate.1

Internal validation candidate. This is not a GitHub release, tag, or update-channel promotion.

## Included corrections

- Restores the normal Bootguard minimum threshold to `2`.
- Keeps threshold `1` only when `CANARY_DIAGNOSTIC_MODE=1`.
- Exposes the effective Bootguard threshold minimum in status and logs.
- Corrects pTune install-state observability for:
  - pTune absent;
  - pTune installed but disabled;
  - pTune active and blocked;
  - pTune active with explicit override.
- Writes pTune override marker files only when pTune is actually active and the explicit override is effective.

## Incident boundary

Mustang evidence showed the installed public Alpha 1 with both `disable` and `skip_mount`. The marker time preceded the relevant Boot-Watch reports, so those reports observed the disabled state rather than proving they created it. The Alpha 1 Bootguard accepted threshold `1` globally, although the V2 intent reserved that setting for Canary/ZP diagnostics.

This candidate does not claim that Polling Mod caused the interrupted boot. It corrects the proven over-sensitive self-disable path and the already-tracked pTune reporting defect.

## Controlled Mustang validation

- Device: Pixel 10 Pro XL (`mustang`).
- Build: Android 17 / `CP2A.260705.006` / incremental `15641320`.
- KPatch Next remains disabled.
- Boot image remains unpatched.
- pTune remains installed-disabled.
- Module ZRAM remains disabled.
- Start with Stock Thermal and Polling Mod only.
- Install the candidate, perform one controlled reboot, and verify Bootguard, active overlay hashes, polling values, Termux startup, and module markers.
- Do not combine Outdoor, pTune override, ZRAM, KPatch, or another boot-image change in the first candidate test.

## Channel and publication boundary

- Stable `update.json` remains unchanged.
- `update-prerelease.json` remains on public Alpha 1.
- No release, tag, asset upload, or unattended installation is part of this candidate preparation.
