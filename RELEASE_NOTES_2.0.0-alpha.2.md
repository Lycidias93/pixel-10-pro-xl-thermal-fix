# 2.0.0-alpha.2

Unpublished V2 Alpha 2 package basis. This is not yet a GitHub release, tag, asset upload, or prerelease-channel promotion.

## Included changes

- Keeps Polling Mod and ZRAM 100p as the fresh-install defaults.
- Restricts the V2 Alpha support declaration to Android 17 and fails closed for unknown devices or builds.
- Correctly identifies alpha, beta, release-candidate, candidate, and test builds as prereleases.
- Restores the normal Bootguard minimum threshold to `2` while retaining threshold `1` only for explicit Canary diagnostics.
- Distinguishes pTune absent, installed-disabled, active-blocked, and active-explicit-override states.
- Routes installation and Action rematerialization through the validated thermal wrapper.
- Verifies exact Outdoor threshold deltas for Stock (`+0`), Safe (`+1`), Plus (`+2`), and Extended (`+3`).
- Preserves quoted `"NAN"` threshold sentinels while applying deltas only to numeric values.
- Counts only target zones that actually expose a `HotThreshold` array, matching the dynamic patcher's real scope instead of requiring every repeated target label to own an array.
- Rolls back generated thermal overlays when validated target arrays are malformed, missing, reordered, or changed by an unexpected delta.

## Verified preparation state

The repository policy, Bootguard, pTune-state, Outdoor-delta fixture matrix, syntax, and combined Alpha 2 candidate guards pass on the working branch.

The first exact-package Mustang install attempt stopped during real-stock Outdoor validation because the initial validator rejected legitimate production structure and quoted `"NAN"` sentinels. The installer did not stage the module and successfully restored the complete pre-install snapshot. The corrected package revision is versionCode `1016211` and still requires a fresh reproducible build, install, reboot, and post-boot verification before publication.

Prior Mustang runtime evidence remains valid context, but it does not replace verification of the corrected exact `2.0.0-alpha.2` ZIP.

## Final package verification

The corrected package test uses:

- Polling Mod enabled;
- ZRAM 100p enabled;
- Stock Outdoor profile;
- pTune installed-disabled or absent;
- KPatch and unrelated boot-image changes disabled.

Before another install, the corrected validator must pass Stock, Safe, Plus, and Extended against the real Mustang build-keyed stock cache in a private read-only test workspace.

After reboot, verify Bootguard state, module markers, active thermal overlay values, Outdoor delta report, ZRAM runtime size and properties, Termux startup, and absence of thermal crashes.

## Publication boundary

- `update-prerelease.json` remains on public Alpha 1 until the corrected exact package passes final verification.
- Stable `update.json` remains unchanged.
- No release, tag, ZIP asset, update-channel promotion, or unattended installation is part of this preparation commit.
- Blazer evidence still needs exact build metadata; frankel and rango still need exact-build runtime evidence; Canary/ZP remains recovery-gated.
