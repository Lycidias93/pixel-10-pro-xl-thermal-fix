# V2 Alpha validation plan

Status date: `2026-07-26`.

Public prerelease: `2.0.0-alpha.2` / versionCode `1016211`.

Previous runtime-proven rollback baseline: `2.0.0-alpha.3-dev` / versionCode `1016212`.

Current runtime-proven development baseline: `2.0.0-alpha.3-dev.2` / versionCode `1016213`.

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

## Alpha 3 development rollback baseline

The lean `2.0.0-alpha.3-dev / 1016212` package passed installation and post-reboot verification on Mustang and remains the known-good rollback anchor for the next refactor.

Its proof included exact active vendor hashes, Stock delta `0`, Polling Mod, ZRAM 100p with `lz77eh`, pTune installed-disabled, healthy Bootguard, no Action network-refresh path, and the final installed-runtime marker with zero failures and zero warnings.

## Alpha 3 dev.2 runtime PASS

The exact `2.0.0-alpha.3-dev.2 / 1016213` package passed installation and post-reboot verification on:

- device: Pixel 10 Pro XL (`mustang`);
- Android: `17`;
- build: `CP2A.260705.006`;
- incremental: `15641320`;
- build evidence: `exact_verified`;
- Thermal: Stock, exact delta `0`;
- Polling: Mod;
- ZRAM: 100p with active `lz77eh` swap;
- pTune: installed-disabled.

Exact package binding:

- file: `pixel-10-thermal-memory-control-2.0.0-alpha.3-dev.2.zip`;
- SHA-256: `3590bf96d55fd577326b240301d660fffbdef48513bdbf73cc1305fdb1f6d13b`;
- size: `303616` bytes;
- tested V2 merge commit: `fe9adf225c7401cb73520705b60a945e88c44bac`.

Installer proof:

- selected Magisk package path was hash- and size-bound to the exact test ZIP;
- battery was `100` percent and installer elapsed time was `35` seconds;
- all five choices were collected by one install-menu process;
- Thermal and ZRAM materializers were noninteractive;
- 22 controlled PollingDelay values changed from `300000` to `5000`;
- canonical validation state was created under `/data/adb/pixel-10-pro-xl-thermal-fix/validation/`;
- historical report paths were symlinks only.

Post-reboot proof:

- `modules_update` consumed and active module metadata exact;
- all canonical validation files and hashes matched `state.env` and `install-state.txt`;
- all five historical validation paths resolved to canonical files as symlinks;
- three active `/vendor/etc` hashes equalled the module overlays;
- source, patch, validation, exact-delta, and active-polling checks passed;
- Outdoor validation reported 3 files, 2 target zones, 2 arrays, and 14 values;
- Bootguard pending absent, fail count `0`, threshold `2`, last-good present;
- ZRAM runtime near 100 percent RAM and no service failure marker;
- Action contained no network-refresh path and exposed performance instrumentation;
- Thermal service responsive and no recent fatal Thermal pattern;
- final marker: `RESULT: CG_INSTALLED_RUNTIME_VERIFY_DONE outcome=success workflow_exit_code=0`;
- verifier summary: `checks_failed=0`, `warnings=0`.

Full evidence: [2.0.0-alpha.3-dev.2 Mustang runtime evidence](runtime-evidence/2.0.0-alpha.3-dev.2-mustang.md).

## Attribution boundary

- **Allen Chang** supplied the July Canary screenshot and installation evidence that exposed the incorrect exact-build activation gate.
- **Harish / Codecity001** supplied the separate package/performance review: slow extraction, slow Action startup, repository-only files in the flashable ZIP, repeated install questions, duplicated validation outputs, and validator-organization feedback.

These inputs must not be cross-attributed.

## Alpha 3 next refactor contract

The `2.0.0-alpha.3-dev.2 / 1016213` line changes package and installer architecture and has now passed its fresh install/reboot cycle on Mustang.

### Single install menu

`install-options-menu.sh` is the sole install-time owner for:

- Polling Mode;
- Thermal Profile;
- ZRAM;
- pTune override;
- Debug logging.

`install-thermal-overlay.sh` and `install-zram.sh` are noninteractive materializers. The Action-only Thermal and ZRAM menus remain available for later runtime changes.

### Canonical validation state

Canonical persistent validation data lives under:

`/data/adb/pixel-10-pro-xl-thermal-fix/validation/`

It contains:

- `validation-report.json`;
- `outdoor-delta-validation.env`;
- `patch-manifest.tsv`;
- `state.env` with schema and hashes.

Historical paths remain compatibility symlinks only. Independent copies are prohibited. `$MODPATH/guard/` remains focused on Bootguard and compatibility markers.

### Lean package and repository layout

The deterministic flashable ZIP excludes:

- `.git*` and `.github/`;
- `deprecated/`, `scratch/`, `dev_tools/`, `docs/`, tests and fixtures;
- `release/` and `release-notes/`;
- root `RELEASE_NOTES_*` files;
- repository README/changelog/credits/verification markdown;
- release-only Alpha 2 policy/candidate helpers;
- nested ZIP files.

Repository release notes live under `release-notes/`. CI rejects new root-level `RELEASE_NOTES_*` files.

### Performance budgets

CI records and preserves:

- release ZIP bytes and entry count;
- deterministic build duration;
- `action.sh` and `customize.sh` bytes;
- install-menu process budget.

Current hard budgets are:

- at most `60` ZIP entries;
- at most `450000` ZIP bytes;
- at most `12000` bytes for `action.sh`;
- exactly one install-menu process.

The tested dev.2 artifact contained `48` entries and `303616` bytes. Its CI build completed in approximately `338` milliseconds on the recorded runner.

## Runtime validation boundaries

Independent stages remain intentional:

1. `patch-thermal.sh` creates the stock-derived controlled overlay and manifests;
2. `verify-outdoor-delta.sh` independently checks exact Stock/Safe/Plus/Extended target deltas and preserves quoted `"NAN"` sentinels;
3. `patch-thermal-validated.sh` provides rollback and promotes only validated output into the canonical validation state;
4. `compat-check.sh` verifies the installed/runtime state and active vendor hashes.

These are separate failure boundaries, not redundant test copies. Consolidation removes duplicate menus, duplicate persistent reports, build-admission duplication, and network-refresh logic without collapsing independent safety checks.

## Remaining public Alpha 3 gate

Already complete:

- PR CI passed shell syntax, dynamic unknown-build admission, menu deduplication, validation-state SoT, Outdoor runtime matrix, Bootguard/pTune policies, release-note layout, and full lean package verification;
- exact generated ZIP was hash-bound and installed;
- banned repository-only paths were absent;
- package metadata used the new versionCode;
- exact-evidence Mustang installation and reboot passed;
- canonical validation files and all compatibility symlinks passed;
- Bootguard, Thermal overlays, exact Outdoor delta, ZRAM, pTune state, active vendor hashes, and final installed-runtime marker passed.

Still required before any public Alpha 3 prerelease:

- install or Action rematerialization must succeed on at least one unlisted supported-platform build using `dynamic_unverified` local stock validation;
- that run must complete a reboot/runtime check without unexplained disable, skip-mount, validation-state, or active-vendor mismatch;
- public release notes must accurately distinguish exact Mustang proof from unlisted-build dynamic proof;
- release/tag/asset/channel writes require a separate fresh user-confirmed release operation.

## Stable gate

Before stable promotion:

- mustang, blazer, frankel, and rango support claims are backed by honest runtime evidence or narrowed accordingly;
- dynamic unlisted-build admission has no unexplained Bootguard regression;
- Canary/ZP recovery limitations are documented honestly;
- active pTune coexistence remains opt-in and is not implied by base PASS;
- stable `update.json` changes only in a separate user-confirmed release operation.
