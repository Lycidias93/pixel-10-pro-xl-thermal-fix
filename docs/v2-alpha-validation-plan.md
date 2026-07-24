# V2 Alpha validation plan

Status date: `2026-07-24`.

Public prerelease line before publication: `1.5.2-universal-v2-alpha.1`.

Release-ready exact package: `2.0.0-alpha.2` / versionCode `1016211`.

Stable line remains `1.5.1-universal.1`; stable `update.json` is unchanged.

## Alpha 2 release gate

The exact corrected package has completed the Alpha 2 release gate on Mustang.

Verified package:

- File: `pixel-10-thermal-memory-control-2.0.0-alpha.2.zip`
- SHA-256: `3f66c76d65f0de29f0815c663b5dc34c37f0c1b5084e91d4df8e6d5bc939a4c8`
- Size: `2017962` bytes
- Entries: `1514`
- Tested source head: `392e7f634f3d2b4fcd676b8ec08337f85f5c4399`
- V2 merge commit: `ff2ea8bb3f908d9df89a4c947d2852834b75d9fa`

Completed checks:

1. Combined policy, syntax, Bootguard, pTune-state, and Outdoor fixture guards passed at the exact source head.
2. Stock, Safe, Plus, and Extended passed the corrected real-layout delta matrix, including quoted `"NAN"` preservation and legitimate zero-target files.
3. Two independent ZIP builds were binary-identical.
4. ZIP integrity, required paths, version metadata, and exclusion of Git metadata and disable markers passed.
5. The exact ZIP installed on Mustang with Stock Outdoor, Polling Mod, ZRAM 100p, pTune installed-disabled, and no active KPatch module.
6. The first reboot completed without unexplained disable or skip-mount state.
7. Postboot verification ended with `RESULT: CG_INSTALLED_RUNTIME_VERIFY_DONE outcome=success workflow_exit_code=0`.

## Exact Mustang runtime PASS

| Field | Evidence |
|---|---|
| Device | Pixel 10 Pro XL (`mustang`) |
| Android/build | Android 17 / `CP2A.260705.006` / incremental `15641320` |
| Module | `2.0.0-alpha.2` / `1016211` active; `modules_update` consumed |
| Markers | `disable`, `skip_mount`, and `remove` absent |
| Thermal | Stock Outdoor; Polling Mod; all three runtime overlay hashes match |
| Delta report | 3 files, 2 target zones, 2 arrays, 14 values, delta 0, validation passed |
| Bootguard | pending absent; fail count 0; threshold 2; last-good present |
| ZRAM properties | all nine requested properties exact |
| ZRAM runtime | `16331833344` bytes; `lz77eh`; `/dev/block/zram0` active swap |
| pTune | installed-disabled; no conflict |
| KPatch | no active module |

## Changes completed since public Alpha 1

- Polling Mod and ZRAM 100p are fresh-install defaults.
- Stock Outdoor remains the initial thermal profile and pTune override remains off.
- V2 activation is Android 17-only and unknown devices/builds fail closed.
- Alpha, beta, rc, candidate, and test builds are correctly classified as prereleases.
- Normal Bootguard minimum is 2; minimum 1 is Canary-only.
- pTune absent, installed-disabled, active-blocked, and active-explicit-override states are reported separately.
- Installation and Action rematerialization use the validated thermal wrapper.
- Outdoor Stock/Safe/Plus/Extended require exact `+0/+1/+2/+3` target deltas.
- Quoted `"NAN"` sentinels remain unchanged.
- Legitimate zero-target stock files are accepted.
- Target accounting follows actual `HotThreshold` arrays.
- Malformed, missing, reordered, renamed, or unexpectedly changed arrays fail closed and roll back.

## Corrected incident history

The first exact Alpha 2 attempt used versionCode `1016210`. It reached real Mustang Stock materialization, but the initial validator incorrectly required target arrays in every file and rejected quoted `"NAN"` values. Magisk did not stage the module, and the outer installer restored the complete pre-install snapshot.

The corrected validator and package use versionCode `1016211`. The corrected ZIP then completed reproducible build, installation, reboot, and runtime verification.

The earlier Alpha 1 disable incident proved an over-sensitive Bootguard path because normal installs accepted threshold `1`. It did not prove that Polling Mod caused the interrupted boot. Alpha 2 restores threshold `2` for normal installs.

## Evidence boundaries after Alpha 2

- Mustang exact-package base runtime: PASS.
- Blazer Android 17 community runtime: PASS; exact build ID and normalized debug evidence remain follow-up.
- Frankel and rango: exact-build runtime evidence still required before stable support claims.
- Canary/ZP: recovery-gated; no normal runtime claim.
- Outdoor Safe, Plus, and Extended: exact real-layout validation PASS; installed Alpha 2 Action-path exercise remains a Beta 1 gate.
- Active pTune coexistence: advanced/experimental; exact release proof covers pTune installed-disabled.

## Alpha 2 publication sequence

Publication remains fail-closed and ordered:

1. Create the prerelease tag at the exact tested V2 tree.
2. Upload only `pixel-10-thermal-memory-control-2.0.0-alpha.2.zip`.
3. Verify the public asset SHA-256 equals `3f66c76d65f0de29f0815c663b5dc34c37f0c1b5084e91d4df8e6d5bc939a4c8`.
4. Publish the matching release notes.
5. Only then promote `update-prerelease.json` to Alpha 2.
6. Re-read the public JSON and release asset after publication.
7. Keep stable `update.json` unchanged.

Do not replace an asset under the same tag. Any content change requires a new versionCode, a new artifact hash, and fresh exact-package verification.

## Beta 1 gate

Proceed to Beta 1 only when all of the following are true:

- Mustang and Blazer base thermal paths remain runtime PASS.
- Safe, Plus, and Extended are exercised through the installed Alpha 2 Action flow with exact reports and rollback behavior.
- ZRAM 100p remains healthy as the fresh default.
- Bootguard shows no regression or unexplained disable.
- Blazer evidence is normalized with exact build metadata.
- pTune state observability remains regression-tested.
- no other blocking defect requires another Alpha package.

## Stable gate

Before stable promotion:

- frankel and rango each need exact-build runtime evidence, or they must be removed from stable support claims;
- Canary/ZP remains excluded unless its exact build and recovery-backed runtime path pass;
- active pTune coexistence remains opt-in risk and is not implied by base PASS;
- stable `update.json` changes only in a separate release operation after final stable verification.

## Non-goals for the current Alpha cycle

- WebUI;
- automatic ZIP download or unattended installation;
- thermal safety disablement;
- unsupported device/build activation;
- widening the dynamic patch scope beyond base, charge, and throttling without new evidence.
