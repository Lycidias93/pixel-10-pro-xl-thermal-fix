# V2 Alpha validation plan

Status date: `2026-07-25`.

Public prerelease: `2.0.0-alpha.2` / versionCode `1016211`.

Current development line: `2.0.0-alpha.3-dev` / versionCode `1016212`.

Stable remains `1.5.1-universal.1`; stable `update.json` is unchanged.

## Alpha 2 immutable release state

The published Alpha 2 package remains immutable:

- file: `pixel-10-thermal-memory-control-2.0.0-alpha.2.zip`;
- SHA-256: `3f66c76d65f0de29f0815c663b5dc34c37f0c1b5084e91d4df8e6d5bc939a4c8`;
- size: `2017962` bytes;
- entries: `1514`;
- versionCode: `1016211`.

Do not replace this asset under the same tag. Any package-content change requires a new versionCode, artifact hash, installation, reboot, and runtime verification cycle.

## Correct Dynamic V2 admission model

The exact build list is an evidence registry, not the activation gate.

A build may enter the Thermal path when:

1. its codename is one of the supported Pixel 10 devices;
2. its Android major version is supported;
3. the three local stock thermal files are present and structurally valid;
4. the generated overlay changes only the controlled polling and Outdoor targets;
5. source manifest, patch manifest, validation report, and exact Outdoor delta checks pass.

Build evidence states:

- `exact_verified`: build ID already has exact evidence;
- `dynamic_unverified`: new build ID on a supported platform, admitted only after local stock-derived validation;
- `unsupported_platform`: unknown codename or unsupported Android version; Thermal stays disabled while ZRAM may remain available.

An unlisted Canary or monthly build must not require a GitHub refresh before Action opens. It is validated locally against its own stock files. `CANARY_DIAGNOSTIC_MODE` is not enabled merely because the build ID is new, so the normal Bootguard threshold remains active.

## Feedback and evidence attribution

The two post-Alpha-2 inputs are separate and must not be merged into one tester claim:

- **Allen Chang** supplied the screenshot and installation evidence showing that a July Canary build was classified as unsupported and had Thermal disabled while ZRAM remained active. This is the runtime/evidence input for the dynamic unknown-build admission fix.
- **Harish / Codecity001** supplied the Alpha packaging and performance review: extraction and Action startup were too slow, repository-only directories and files were shipped unnecessarily, and validation code should remain lean without collapsing independent safety boundaries.

No runtime result, screenshot, or installation log from Allen is attributed to Harish. No package-size or validator-consolidation feedback from Harish is attributed to Allen.

## Alpha 3 development scope

Alpha 3 development addresses the post-Alpha-2 feedback:

- remove the Action-time GitHub API/raw download path;
- support unlisted Pixel 10 Android 17 builds through local dynamic validation;
- keep unknown devices, unsupported Android versions, malformed stock layouts, unexpected diffs, and pTune conflicts fail-closed;
- distinguish exact-build evidence from dynamic runtime admission;
- improve Magisk/root observability;
- build a deterministic lean flashable ZIP;
- keep repository-only content out of the module package;
- retain independent patch, exact-delta, and runtime verification stages while removing duplicated admission/network logic.

## Lean release package contract

The release builder packages tracked runtime content and excludes:

- `.git*` and `.github/`;
- `deprecated/`;
- `scratch/`;
- `dev_tools/`;
- `docs/`;
- `tests/`, `test/`, and fixtures;
- evidence, release-work, and build-output directories;
- `RELEASE_NOTES_*`;
- repository README/changelog/credits/verification markdown;
- nested ZIP files and test/fixture helpers inside runtime trees.

The package verifier requires core Magisk/runtime entries, ZIP integrity, no banned paths, no zero-byte files, and an entry-count budget of at most 500.

## Runtime validation boundaries

Independent stages remain intentional:

1. `patch-thermal.sh` creates the stock-derived controlled overlay and manifests;
2. `verify-outdoor-delta.sh` independently checks exact Stock/Safe/Plus/Extended target deltas and preserves quoted `"NAN"` sentinels;
3. `patch-thermal-validated.sh` provides atomic rollback and promotes only validated output;
4. `compat-check.sh` verifies the installed/runtime state and active vendor hashes.

These are separate failure boundaries, not redundant test copies. Consolidation removes duplicated build-admission and network-refresh logic without collapsing the independent safety checks.

## Alpha 3 gate

Before any Alpha 3 public prerelease:

- PR CI passes shell syntax, dynamic unknown-build admission, and full lean package verification;
- the exact generated ZIP is reproducible;
- banned repository-only paths are absent;
- package metadata reports a new versionCode;
- install succeeds on an exact-evidence build;
- install or Action rematerialization succeeds on at least one unlisted supported-platform build using local stock validation;
- reboot completes without unexplained disable or skip-mount state;
- Bootguard, Thermal overlays, exact Outdoor delta, ZRAM, pTune state, and active vendor hashes pass;
- final marker is `RESULT: CG_INSTALLED_RUNTIME_VERIFY_DONE outcome=success workflow_exit_code=0`.

## Stable gate

Before stable promotion:

- mustang, blazer, frankel, and rango support claims are backed by honest runtime evidence or narrowed accordingly;
- dynamic unlisted-build admission has no unexplained Bootguard regression;
- Canary/ZP recovery limitations are documented honestly;
- active pTune coexistence remains opt-in and is not implied by base PASS;
- stable `update.json` changes only in a separate user-confirmed release operation.
