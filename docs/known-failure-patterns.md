# Known failure patterns


<!-- UNIVERSAL_RELEASE_AUTOMATION_KNOWN_FAILURES_20260602_START -->
## Universal release automation known failures

Scope: Pixel 10 Thermal Polling Fix universal-first release workflow.

Do not repeat these false-stop patterns:

1. Dynamic install-state source generation
   - Symptom: publish preflight expects literal `module_version=1.4.1-universal.1` in `customize.sh`.
   - Correct handling: accept dynamic generation from `module.prop` if live post-reboot verify shows `install-state.txt` with final `module_version=1.4.1-universal.1` and no `rc1` label.

2. v-prefixed release documentation filenames
   - Symptom: automation looks for `docs/verify-1.4.1-universal.1.md`.
   - Correct handling: accept repo naming `docs/verify-v1.4.1-universal.1.md` and `docs/release-scope-v1.4.1-universal.1.json`.

3. JSON semantic marker versus Markdown sentence
   - Symptom: JSON release-scope does not contain literal sentence `No polling values changed by this release`.
   - Correct handling: validate semantic fields such as `polling_values_changed_by_this_release=false/no` in JSON; keep exact sentence checks for Markdown files.

4. Sortify archive relocation
   - Symptom: final ZIP missing from `/storage/emulated/0/Download` shortly before publish.
   - Correct handling: resolver must check `/storage/emulated/0/Sortify/Archives` and `/sdcard/Sortify/Archives`, restore the ZIP to Download, and regenerate/copy `.sha256`.

5. Universal source-tree layout
   - Symptom: `git add system/vendor/etc` fails after universal profile migration.
   - Correct handling: active source payload under `system/vendor/etc` must be absent; use `profiles/mustang/...` and `profiles/blazer/...`.

6. Public-support marker exactness
   - Symptom: repeated aborts for equivalent wording such as `Mustang verified`, `Blazer beta/pending`, or external inspiration boundaries.
   - Correct handling: normalize markers once in docs, then gate Markdown exactly and JSON semantically.

Invariant:
- No thermal/profile JSON value changes.
- No bind-mount runtime model.
- No live text patching.
- `update.json` switches only after release asset exists.
- GitHub connector is read-only; public writes run locally via `git`/`gh` on Pixel.
<!-- UNIVERSAL_RELEASE_AUTOMATION_KNOWN_FAILURES_20260602_END -->

<!-- PIXEL10_ANDROID16_MINIMAL_POLLING_FAILURES_20260602_START -->
## Pixel 10 Android 16 minimal polling profile failure patterns

1. Existing Blazer profile has non-polling deltas
   - Symptom: factory comparison shows cdev, PIDInfo, threshold, frequency, or power-rail differences.
   - Rule: Do not use existing `profiles/blazer` as a source template for other devices.

2. Factory maps are evidence, not live verification
   - Symptom: `frankel`, `blazer`, or `rango` profiles exist but no owner post-reboot verify is present.
   - Rule: Keep those profiles beta/pending until install, staging, overlay, semantic sensor, and ThermalHAL tombstone checks pass.

3. Minimal profile generation must only change allowed polling fields
   - Symptom: generated profile differs from factory JSON outside `PollingDelay`/`PollingDelayMs`.
   - Rule: Stop the build; do not release.

4. Stable update channel must not move before release assets exist
   - Symptom: `update.json` points to a tag before ZIP/SHA assets exist.
   - Rule: release asset first, update channel last.
<!-- PIXEL10_ANDROID16_MINIMAL_POLLING_FAILURES_20260602_END -->

<!-- ANDROID17_PROFILE_REUSE_FAILURE_20260602_START -->
## Android 17 profile reuse failure pattern

Scope: Pixel 10 thermal profile sets.

Failure pattern:
- Android 16 factory thermal JSON files are reused on Android 17.
- The module installs without checking `ro.build.version.release` or fingerprint Android major.
- Result can be wrong sensor definitions, changed virtual-skin maps, ThermalHAL instability, or ineffective overlay behavior.

Rule:
- Android 16 profiles must hard-abort on non-Android-16 devices.
- Android 17 needs a separate factory image dump, separate profile set, and separate live verification.
- Do not infer Android 17 `VIRTUAL-SKIN` maps from Android 16 profiles.
<!-- ANDROID17_PROFILE_REUSE_FAILURE_20260602_END -->
