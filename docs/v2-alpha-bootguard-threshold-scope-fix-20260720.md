# V2 Alpha Bootguard threshold-scope correction

Date: 2026-07-20
Target branch: `v2`

## Incident evidence

Mustang / Android 17 / `CP2A.260705.006` recovered with the thermal module carrying both `disable` and `skip_mount` markers. The markers shared mtime `2026-07-19T19:36:23+0200`.

The external `/data/adb/boot-watch/.../ashlooper_intervention/disabled_modules.txt` records were later observations. The first relevant record was written at `19:39:29`, and later boots repeated the same marker mtime. Older hits referenced Pixel Regional Restrictions Disabler and were unrelated.

Bootguard logs showed `threshold=1`. The V2 Bootguard source accepted minimum `1` globally, although the changelog contract says minimum `1` belongs only to Canary/ZP diagnostic mode and normal builds keep the earlier behavior.

## Root cause

The test.7 Canary hardening leaked into the common threshold function. A normal supported V2 Alpha install with a retained `BOOTGUARD_FAIL_THRESHOLD=1` could therefore self-disable after one unfinished pending-boot cycle.

This explains the paired markers: Bootguard v2 writes both `disable` and `skip_mount` when the effective threshold is reached. It does not prove that polling caused the interrupted boot; it proves that the normal-build Bootguard reaction was more aggressive than documented.

## Correction

- Normal supported installs enforce minimum threshold `2`.
- `CANARY_DIAGNOSTIC_MODE=1` may still use minimum threshold `1`.
- Bootguard status and logs expose the effective minimum.
- Existing configuration value `1` is safely normalized at runtime for non-Canary installs; no destructive config migration is required.

## Runtime boundary

The currently installed Alpha 1 remains disabled. Do not remove its markers or resume Outdoor testing until a corrected Alpha 2 candidate is built, installed with KPatch/boot-image changes kept out of the test, rebooted once, and verified.

## Validation

Repository guard: `tools/bootguard/bootguard-threshold-policy-guard.sh`

Required follow-up:

1. source guard and shell syntax PASS;
2. build corrected V2 Alpha candidate without publishing;
3. install on Mustang with one-variable test scope;
4. verify effective `threshold_minimum=2`, pending clears after boot success, and no new disable markers;
5. only then continue Outdoor Safe validation.
